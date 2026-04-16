# Enforcement Notes — Model-Trusted Gates on Antigravity

Antigravity, like Codex, has no shipped hook surface in this repo. The always-on protocols from `core/always-on-protocols.md` apply identically, but compliance is model-trusted rather than runtime-enforced.

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

## What Stays True On Antigravity

**Portable plans.** Keep plan artifacts in `.etyb/plans/`. This repo does not add an Antigravity-native plan integration layer.

**Markdown-first parallel work.** Decompose the work, document the track boundaries, and execute sequentially in one session or across multiple human-coordinated sessions.

**MCP is optional.** If the user's Antigravity environment exposes MCP tools, ETYB can use them. ETYB does not require them.

## Subagents Without ADK

If you are running ETYB on Antigravity as shipped in this repo, parallel tracks work the same way as the markdown-first path on Codex:
- Sequential execution within the session, or
- User runs multiple Antigravity sessions and ETYB drafts the coordination plan

See `core/coordination-patterns.md` → Parallel Tracks for the logical pattern; the gate rules (Implement blocks until all tracks complete) still apply regardless of dispatch mechanism.

## When A User Asks You To Skip

Same response template as the Codex adapter:

> Review before commit is an always-on discipline in ETYB (see `core/always-on-protocols.md` §3). Antigravity doesn't have a hook to enforce it, but the protocol still applies. Let me run `code-reviewer` on the diff first — the protocol is the product, not the tool.

## What You Cannot Do

- You cannot make Antigravity strictly equivalent to Claude Code for gate enforcement. No hooks means no deterministic enforcement.
- You cannot claim ADK sub-agents are available in this repo's shipped runtime. They are documented as a future path only.
- Be honest about the enforcement ceiling. It's model-trusted on Antigravity, full stop.
