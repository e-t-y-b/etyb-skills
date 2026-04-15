# Enforcement Notes — Model-Trusted Gates on Codex

Codex does not expose hooks, lifecycle events, or pre/post tool-use interceptors. Every always-on protocol from `core/always-on-protocols.md` must be enforced by you, the model, applying the instruction.

## The Rule

When `core/always-on-protocols.md` says *"Hook enforces X,"* read it as *"you enforce X by instruction."* The discipline is identical. The enforcement mechanism is weaker.

## Per-Protocol Fallback

| Protocol | Claude enforcement | Codex fallback |
|----------|-------------------|----------------|
| **TDD** — no source without failing test first | `pre-edit-check` hook | Before editing a source file, state: "writing test first per TDD." Write the test. Confirm it fails. Only then edit source. If you catch yourself editing source without a test, STOP and revert to test-first. |
| **Review** — no commit without review | `pre-commit-review-check` hook | Before running `git commit` on Tier 3+ changes, invoke `code-reviewer` via `Read skills/code-reviewer/SKILL.md` and produce a review artifact. Reference it in the commit. |
| **Branch safety** — no merge with red tests | `pre-merge-verify` hook | Before `git merge` or `gh pr merge`, run the test suite. Read full output. If any test fails, STOP. Do not merge. |
| **TDD evidence** — log test results | `post-test-log` hook | Whenever you run tests, save results inline in the plan artifact's verification log. |
| **Plan traceability** — log edits against plan | `post-edit-log` hook | Update the plan's task status after every meaningful edit. |

## Concrete Verification Pattern (do this on Codex)

Before declaring any Tier 3+ task complete:

1. **Run the tests yourself.** Not "tests should pass" — run them. Read the output. Cite the pass count in the response.
2. **Run the review yourself.** Load `skills/code-reviewer/SKILL.md` and apply it to the diff. Produce findings.
3. **Update the plan artifact.** Move the task to `verified`, add the evidence.
4. **Only then say "done."**

The 5-question verification protocol in `references/verification-protocol.md` applies verbatim — Codex users get the same discipline, without the hook safety net.

## Subagents — What Actually Works

Codex has a "Subagents" concept separate from skills. As of the current spec, Subagents are not invokable from within a skill's instructions. This is different from Claude Code, where the Agent tool is callable from anywhere.

**What this breaks:**
- `core/coordination-patterns.md` → Parallel Tracks assumes you can dispatch independent specialists as subagents. On Codex, you execute tracks sequentially within the same session, or ask the user to open parallel Codex sessions manually.
- Two-stage review (implementer + independent reviewer) collapses into one session. Mitigate by explicitly changing context between the two — e.g., close the plan, re-open only the diff and acceptance criteria, then apply `code-reviewer`.

**What still works:**
- All five coordination patterns conceptually (Sequential, Parallel Tracks, Hub-and-Spoke, Domain-Augmented, Incident Response). The gate enforcement rule (Implement gate blocks until all tracks complete) is preserved.
- Parallel work across multiple Codex sessions if the user runs them. ETYB can draft the track assignments; the user dispatches them.

**Practical advice:** if a plan genuinely needs parallel tracks, tell the user. Offer:
- **Option A** — execute tracks sequentially in this session (safer, slower)
- **Option B** — break the plan into per-track sub-plans the user can run in parallel Codex sessions (faster, requires coordination discipline on their end)

## Plan Artifacts on Codex

There is no Codex-native plan mode. Always use `.etyb/plans/{name}.md` per `core/gates.md`. Ignore any pointer to `adapters/codex/plan-mode.md` — no such file exists because there's nothing platform-specific to add.

## When A User Asks You To Skip

On Claude Code, if a user says "commit without review," the hook fires anyway. On Codex, you have to say no.

Response template:

> Review before commit is an always-on discipline in ETYB (see `core/always-on-protocols.md` §3). I don't have a hook to enforce it on this platform, but the protocol still applies. Let me run `code-reviewer` on the diff first — it takes 30 seconds and catches the issues that make commits expensive to revert.

Do not offer to "skip this one time." The protocol is the product.

## What You Cannot Do

- You cannot make a Codex user's environment strictly equivalent to Claude Code.
- You cannot fake hooks by instructing the model harder. Model compliance is real but probabilistic; hooks are deterministic.
- You cannot prevent a user from bypassing model-trusted gates by editing files directly in their editor. The gates apply to ETYB-mediated work.

Be honest about these limits when relevant. Overclaiming erodes trust.
