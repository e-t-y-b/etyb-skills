# Hooks — Deterministic Enforcement on Claude Code

Hooks are shell scripts declared in `.claude/settings.json` that fire on tool-use events. They run outside the LLM and their output is injected into the conversation — the model cannot decide to skip them.

ETYB's process protocols wire up five hooks to enforce the always-on disciplines from `core/always-on-protocols.md`.

## The Five Hooks

| Hook | Fires On | Enforces | Protocol Skill |
|------|----------|----------|----------------|
| `pre-edit-check` | `PreToolUse` — `Edit`, `Write` | **TDD** — warns if editing source code without a corresponding test file | `skills/tdd-protocol/` |
| `post-test-log` | `PostToolUse` — `Bash` | **TDD** — logs test results for verification evidence | `skills/tdd-protocol/` |
| `pre-commit-review-check` | `PreToolUse` — `Bash` (git commit) | **Review** — warns if committing without review evidence | `skills/review-protocol/` |
| `pre-merge-verify` | `PreToolUse` — `Bash` (git merge) | **Branch Safety** — blocks merge if tests fail | `skills/git-workflow-protocol/` |
| `post-edit-log` | `PostToolUse` — `Edit`, `Write` | **Plan Execution** — logs edits for plan traceability | `skills/plan-execution-protocol/` |

Hook scripts live alongside the protocol skills they enforce, e.g. `skills/tdd-protocol/hooks/pre-edit-check.sh`.

## Current `.claude/settings.json` Wiring

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write", "hook": "skills/tdd-protocol/hooks/pre-edit-check.sh" },
      { "matcher": "Bash", "hook": "skills/git-workflow-protocol/hooks/pre-merge-verify.sh" },
      { "matcher": "Bash", "hook": "skills/review-protocol/hooks/pre-commit-review-check.sh" }
    ],
    "PostToolUse": [
      { "matcher": "Bash", "hook": "skills/tdd-protocol/hooks/post-test-log.sh" },
      { "matcher": "Edit|Write", "hook": "skills/plan-execution-protocol/hooks/post-edit-log.sh" }
    ]
  }
}
```

## What This Means For ETYB

When ETYB's core tells you "TDD is always on" or "never merge without green tests," on Claude Code those statements are enforced by the runtime, not by the model's compliance.

**Practical implications:**

- **Do not promise to skip a hook.** You cannot. If a user asks you to "just commit without review this one time," the hook will still fire. Route around it by doing the review, not by trying to bypass.
- **Read hook output.** When a hook message appears in the conversation (as a `<user-prompt-submit-hook>` or tool-result content), treat it as a system-level constraint from the user's environment.
- **If a hook blocks you, do not retry the same action.** The hook is surfacing a real gap — usually missing tests, missing review, or failing tests. Fix the gap, then try again.
- **Hooks are part of the project, not of ETYB.** If a user clones this repo, `.claude/settings.json` brings the hooks with them. This is how the engineering culture travels with the code.

## When a Hook Is Missing or Disabled

If you detect that a protocol hook is missing (e.g. `pre-edit-check` is not in `.claude/settings.json`), the corresponding discipline falls back to model-trusted enforcement — you enforce it by reading the protocol skill and applying it yourself. Flag the gap to the user: "This project doesn't have the TDD hook wired up — I'll apply TDD by instruction, but consider adding the hook for deterministic enforcement."
