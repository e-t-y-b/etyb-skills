# Enforcement Notes — Model-Trusted Gates on Antigravity

Antigravity, like Codex, has no hooks or pre/post tool-use interceptors. The always-on protocols from `core/always-on-protocols.md` apply identically, but compliance is model-trusted rather than runtime-enforced.

## Per-Protocol Fallback

| Protocol | Claude enforcement | Antigravity fallback |
|----------|-------------------|----------------------|
| **TDD** — no source without failing test first | `pre-edit-check` hook | You enforce by instruction: write the test, confirm it fails, then write source. See `core/always-on-protocols.md` §1. |
| **Review** — no commit without review | `pre-commit-review-check` hook | Before running `git commit` on Tier 3+ changes, invoke `code-reviewer` and produce a review artifact. Reference it in the commit message. |
| **Branch safety** — no merge with red tests | `pre-merge-verify` hook | Before `git merge` or PR merge, run the test suite. Read full output. If any test fails, STOP. |
| **TDD evidence** — log test results | `post-test-log` hook | Log results inline in the plan artifact's verification log. |
| **Plan traceability** — log edits against plan | `post-edit-log` hook | Update the plan's task status after every meaningful edit. |

## Concrete Verification Pattern

Before declaring any Tier 3+ task complete:

1. **Run the tests.** Cite the pass count in the response.
2. **Run the review.** Load `skills/code-reviewer/SKILL.md` and apply it to the diff.
3. **Update the plan artifact.** Move the task to `verified`, add the evidence.
4. **Only then say "done."**

The 5-question verification protocol in `references/verification-protocol.md` applies verbatim.

## Where Antigravity Is Stronger Than Codex

**Sub-agents via ADK.** If ETYB is elevated to an ADK-backed skill (see `adk-integration.md`), the Parallel Tracks coordination pattern works natively — sub-agents can be dispatched from inside the skill with their own tools and multi-turn reasoning. On Codex, this is not possible.

**MCP integration.** Antigravity's MCP support lets specialists in ETYB's team registry bind to platform-specific tools (databases, cloud providers, issue trackers) without ETYB needing to know about them.

These do not substitute for hook enforcement — they don't make a gate deterministic. But they reduce the "parallel work" pain point that Codex suffers from.

## Subagents Without ADK

If you are running markdown-only ETYB on Antigravity (no ADK elevation), parallel tracks work the same way as on Codex:
- Sequential execution within the session, or
- User runs multiple Antigravity sessions and ETYB drafts the coordination plan

See `core/coordination-patterns.md` → Parallel Tracks for the logical pattern; the gate rules (Implement blocks until all tracks complete) still apply regardless of dispatch mechanism.

## When A User Asks You To Skip

Same response template as the Codex adapter:

> Review before commit is an always-on discipline in ETYB (see `core/always-on-protocols.md` §3). Antigravity doesn't have a hook to enforce it, but the protocol still applies. Let me run `code-reviewer` on the diff first — the protocol is the product, not the tool.

## What You Cannot Do

- You cannot make Antigravity strictly equivalent to Claude Code for gate enforcement. No hooks means no deterministic enforcement.
- You cannot claim ADK sub-agents enforce anything. They enable parallelism; they don't enforce discipline.
- Be honest about the enforcement ceiling. It's model-trusted on Antigravity, full stop.
