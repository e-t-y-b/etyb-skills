# Hooks — Advisory Enforcement on Claude Code

Hooks are shell scripts that Claude Code runs on lifecycle events (tool use, session
start, end of turn). They run outside the LLM: whether a hook fires is decided by the
runtime, not by the model. Their stdout is injected back into the conversation.

**Wiring comes from plugin installation, and only from plugin installation.** Installing
the `etyb` plugin registers `hooks/hooks.json` at the plugin root; Claude Code resolves
`${CLAUDE_PLUGIN_ROOT}` to wherever the plugin was installed and runs the referenced
scripts. Nothing is written to `.claude/settings.json` — this repo does not ship one, and
you should not expect to find ETYB hooks there.

## Enforcement model: advisory, not blocking

Every ETYB hook script **always exits 0**. When a discipline gap is detected, the script
prints `{"systemMessage": "..."}` on stdout, which Claude Code surfaces as a warning in
the conversation. No ETYB hook ever blocks a tool call, a merge, or a commit.

The division of labor:

- **The hook** provides deterministic *visibility* — it fires on every matching event,
  regardless of what the model was planning to say.
- **The model (you)** does the actual *enforcement* — when a hook warning appears, treat
  it as a system-level signal from the user's environment: stop, fix the gap it names
  (missing test, missing review evidence, failing test run), then proceed.

## The Six Hooks

| Event | Matcher / filter | Script (relative to plugin root) | What it does |
|-------|------------------|----------------------------------|--------------|
| `PreToolUse` | `Edit\|Write` | `skills/etyb/references/protocols/tdd-protocol/hooks/pre-edit-check.sh` | **TDD** — warns when a source file is about to be edited and no corresponding test file exists |
| `PreToolUse` | `Bash` + `"if": "Bash(git merge*)"` | `skills/etyb/references/protocols/git-workflow-protocol/hooks/pre-merge-verify.sh` | **Branch safety** — warns on merges into protected branches (main/master/develop/release) without passing-test evidence in `.etyb/test-log.jsonl` |
| `PostToolUse` | `Edit\|Write` | `skills/etyb/references/protocols/plan-execution-protocol/hooks/post-edit-log.sh` | **Plan traceability** — appends each edit to `.etyb/edit-log.jsonl` with timestamp, task, and plan context |
| `PostToolUse` | `Bash` | `skills/etyb/references/protocols/tdd-protocol/hooks/post-test-log.sh` | **Verification evidence** — logs test-command results to `.etyb/test-log.jsonl`; warns when a test run failed |
| `Stop` | — | `skills/etyb/references/protocols/review-protocol/hooks/pre-commit-review-check.sh` | **Review** — end-of-turn sweep; warns when staged changes exist without review evidence |
| `SessionStart` | — | `hooks/session-start-memory.sh` | **Memory** — stub today (reads stdin, exits 0 silently); M4-T2 replaces it with repo memory-summary injection |

Protocol hook scripts live alongside the protocol skills they enforce; the SessionStart
stub lives in `hooks/` at the plugin root next to `hooks.json`.

## The Real Wiring — `hooks/hooks.json`

Current Claude Code plugin hook schema: each event maps to an array of matcher groups,
and each group carries a `hooks` array of handler objects.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/skills/etyb/references/protocols/tdd-protocol/hooks/pre-edit-check.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/skills/etyb/references/protocols/git-workflow-protocol/hooks/pre-merge-verify.sh",
            "if": "Bash(git merge*)",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/skills/etyb/references/protocols/plan-execution-protocol/hooks/post-edit-log.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/skills/etyb/references/protocols/tdd-protocol/hooks/post-test-log.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/skills/etyb/references/protocols/review-protocol/hooks/pre-commit-review-check.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/session-start-memory.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Schema notes:

- `matcher` is an exact/`|`-separated or regex match **over tool names only**
  (`"Edit|Write"`, `"Bash"`). It cannot express command-content filters.
- `"if"` sits on the **handler object** and takes permission-rule syntax
  (`"Bash(git merge*)"`) to filter by tool input. The pre-merge hook uses it so the
  script only runs for `git merge` commands; the script also independently no-ops on
  non-merge payloads, so the filter is an optimization, not a correctness requirement.
- `timeout` is in **seconds**. All ETYB hooks are local greps/file checks, so they get
  5–10s.
- `${CLAUDE_PLUGIN_ROOT}` makes the paths install-location independent.

## Hook script contract

Every script follows the same shape (rewritten in M2-T3 for the stdin-JSON contract):

1. Read the full hook payload JSON from **stdin** (`payload=$(cat)`).
2. Extract fields with `jq` (`.tool_input.file_path`, `.tool_input.command`,
   `.tool_response.exit_code`, `.hook_event_name`, `.cwd`).
3. On a discipline gap, emit `{"systemMessage": "..."}` (built with `jq -n` so hostile
   file names can't inject JSON).
4. **Exit 0 unconditionally.**

**Missing-`jq` degradation:** each script starts with
`command -v jq >/dev/null 2>&1 || exit 0`. On a machine without `jq`, the payload can't
be parsed, so the hook silently no-ops rather than erroring — an advisory hook must never
break the session. The cost is that all hook warnings and `.etyb/*.jsonl` logging are
disabled until `jq` is installed; the disciplines fall back to model-trusted enforcement.

## What this means for ETYB

- **Hook warnings are signals, not blocks.** If the pre-merge hook warns, the merge
  already went through (or is about to). Do not treat the warning as "the runtime stopped
  me" — treat it as "the runtime caught me." Run the verify, do the review, add the test.
- **Do not claim hooks block anything.** They don't. Never tell a user "the hook will
  prevent that commit."
- **Read hook output.** A `systemMessage` from a hook is environment-level feedback;
  weigh it above your own optimism about the state of the work.
- **If hooks aren't firing**, the likely causes are: the plugin isn't installed (wiring
  only exists via plugin installation), or `jq` is missing (silent no-op by design). Fall
  back to enforcing the protocol by instruction and tell the user which of the two gaps
  you suspect.
