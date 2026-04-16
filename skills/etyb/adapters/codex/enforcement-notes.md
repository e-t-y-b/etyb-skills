# Enforcement Notes — Partial Runtime Enforcement on Codex

Codex now exposes project-scoped lifecycle hooks, custom agents, and per-skill metadata. ETYB uses those surfaces where they are real today, and falls back to model-trusted discipline where they are not.

## The Rule

When `core/always-on-protocols.md` says a platform may add runtime guardrails, read it literally on Codex: some ETYB rules now have genuine prompt/Bash/stop interception. Everything outside those surfaces is still enforced by instruction.

## Per-Protocol Fallback

| Protocol | Claude enforcement | Codex runtime + fallback |
|----------|-------------------|----------------|
| **Prompt gate discipline** | Hook + model | `UserPromptSubmit` can block obvious "skip the gate / skip review / skip tests" prompts. If a skip request gets through, push back manually. |
| **TDD** — no source without failing test first | `pre-edit-check` hook | Still model-trusted for edit ordering. Before editing a source file, write the failing test first, confirm it fails, then edit source. |
| **Review** — no commit without review | `pre-commit-review-check` hook | `PreToolUse` can remind on `git commit`, but review evidence is still model-trusted. Prefer `etyb_reviewer` or `code-reviewer` before commit. |
| **Branch safety** — no merge with red tests | `pre-merge-verify` hook | `PreToolUse` can block merge commands until a recent passing Bash test command has been observed. You still need to choose and run the right test suite yourself. |
| **TDD evidence** — log test results | `post-test-log` hook | `PostToolUse` records the latest Bash test outcome and can warn or continue the turn with verification context after failures. |
| **Plan traceability** — log edits against plan | `post-edit-log` hook | Still model-trusted. Update `.etyb/plans/` after meaningful edits because Codex does not intercept Write/Edit today. |
| **End-of-turn verification** | Hook + model | `Stop` can force one more verification pass if the latest observed test failed or you are claiming completion without recent Bash verification evidence. |

## Concrete Verification Pattern (do this on Codex)

Before declaring any Tier 3+ task complete:

1. **Run the tests yourself.** Not "tests should pass" — run them. Read the output. Cite the pass count in the response.
2. **Run the review yourself.** Load `skills/code-reviewer/SKILL.md` and apply it to the diff. Produce findings.
3. **Update the plan artifact.** Move the task to `verified`, add the evidence.
4. **Only then say "done."**

The 5-question verification protocol in `references/verification-protocol.md` applies verbatim — Codex users now get a partial hook safety net, but not full deterministic coverage.

## Subagents — What Actually Works

Codex has a project-scoped custom-agent system separate from skills. ETYB uses `.codex/agents/` for bounded parallel work and independent review, but those agents are still a separate runtime surface rather than something embedded directly inside a SKILL.md file.

**What this enables now:**
- `etyb_explorer` for read-only code path mapping and ownership tracing
- `etyb_planner` for updating `.etyb/plans/` and gate state
- `etyb_reviewer` for independent correctness / regression / security review
- `etyb_docs_researcher` for primary-source doc verification

**What still does not become equivalent to Claude:**
- Hooks do not intercept Write/Edit, MCP, WebSearch, or other non-Bash tools today.
- Hook coverage is experimental and currently disabled on Windows.
- The user can still bypass model-trusted steps by editing files outside ETYB-mediated work.

**Practical advice:** if a plan genuinely needs parallel tracks, tell the user. Offer:
- **Option A** — execute tracks sequentially in this session (safer, slower)
- **Option B** — dispatch bounded custom agents (`etyb_explorer`, `etyb_reviewer`, etc.) where the runtime supports it
- **Option C** — break the work into per-track sub-plans the user can run in parallel Codex sessions (fastest, requires coordination discipline)

## Plan Artifacts on Codex

There is no Codex-native plan mode. Always use `.etyb/plans/{name}.md` per `core/gates.md`. Ignore any pointer to `adapters/codex/plan-mode.md` — no such file exists because there's nothing platform-specific to add.

## When A User Asks You To Skip

Codex can now block obvious skip-the-process prompts and some merge attempts, but you still need to say no when the user tries to step outside the covered surfaces.

Response template:

> Review before commit is an always-on discipline in ETYB (see `core/always-on-protocols.md` §3). Codex can remind and guard some Bash flows here, but review completion is still not automatic. Let me run `etyb_reviewer` or `code-reviewer` on the diff first — it takes 30 seconds and catches the issues that make commits expensive to revert.

Do not offer to "skip this one time." The protocol is the product.

## What You Cannot Do

- You cannot make a Codex user's environment strictly equivalent to Claude Code.
- You cannot fake missing hook coverage by prompting harder. Model compliance is real but probabilistic; runtime hooks are deterministic only within their actual surface.
- You cannot prevent a user from bypassing model-trusted gates by editing files directly in their editor. The gates apply to ETYB-mediated work.

Be honest about these limits when relevant. Overclaiming erodes trust.
