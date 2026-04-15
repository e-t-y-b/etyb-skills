# Engineering Culture — Always-On Protocols

These are non-negotiable engineering disciplines. They apply to ALL work, ALL tiers, ALL gates. They are your organization's culture, not optional tools. When you need the detailed HOW, read the protocol's SKILL.md and references.

## 1. TDD Discipline (always on)

NO production code without a failing test first. Red-green-refactor on every change.

<!-- PLATFORM-SPECIFIC: claude — hook enforcement -->
Hooks enforce this deterministically (pre-edit-check, post-test-log).
<!-- /PLATFORM-SPECIFIC -->

→ Deep knowledge: `skills/tdd-protocol/SKILL.md` + `skills/tdd-protocol/references/`

## 2. Verification Discipline (always on)

Evidence before claims, always. Run commands fresh, read full output, verify exit codes. Never say "done" without proof. The 5-question protocol applies to EVERY completion.
→ Deep knowledge: `skills/etyb/references/verification-protocol.md`

## 3. Review Discipline (always on)

No performative agreement. Evaluate every finding on its merits. Push back with evidence when the reviewer is wrong. Request reviews with focused context.

<!-- PLATFORM-SPECIFIC: claude — hook enforcement -->
Hook enforces review-before-commit.
<!-- /PLATFORM-SPECIFIC -->

→ Deep knowledge: `skills/review-protocol/SKILL.md` + `skills/review-protocol/references/`

## 4. Plan Execution Discipline (always on when a plan exists)

One task at a time. Verify before advancing. Update the plan after every task. Never skip tasks or jump gates.
→ Deep knowledge: `skills/plan-execution-protocol/SKILL.md` + references

## 5. Brainstorm-First Discipline (always on for ambiguous requests)

Explore the problem space before the solution space. Never jump to implementation on an ambiguous request. Produce a design brief before entering the Design gate.
→ Deep knowledge: `skills/brainstorm-protocol/SKILL.md` + references

## 6. Branch Safety Discipline (always on)

Never merge or PR without green tests compared against baseline.

<!-- PLATFORM-SPECIFIC: claude — hook enforcement -->
Hook enforces test-before-merge deterministically.
<!-- /PLATFORM-SPECIFIC -->

→ Deep knowledge: `skills/git-workflow-protocol/SKILL.md` + references

## 7. Subagent Coordination Discipline (always on for parallel work)

One agent per independent domain. No shared mutable state. Two-stage review for all subagent output.
→ Deep knowledge: `skills/subagent-protocol/SKILL.md` + references

## 8. Self-Improvement Discipline (always on)

No skill change without a failing eval first. The system gets better over time.
→ Deep knowledge: `skills/skill-evolution-protocol/SKILL.md` + references

## 9. Debugging Discipline (always on during troubleshooting)

Root cause first. One variable at a time. 3-failure escalation.
→ Deep knowledge: `skills/etyb/references/debugging-protocol.md`

## Debugging Protocol Activation

When tests fail repeatedly or the user reports persistent bugs during an active plan, activate the debugging protocol.

### Activation Triggers

| Trigger | Action |
|---------|--------|
| Same test fails 3+ times after different fix attempts | Activate debugging protocol |
| User reports a bug that can't be reproduced | Activate debugging protocol |
| Implementation is stuck — root cause unknown | Activate debugging protocol |
| Post-deployment issue discovered | Activate debugging protocol |

### Activation Steps

1. **Transition the plan** — add a "Debugging" section to the plan artifact
2. **Record the symptom** — clear, specific description of what's failing
3. **Follow the debugging loop** — Reproduce → Hypothesize → Test ONE variable → Verify
4. **Track hypotheses** — log each hypothesis, test, and result in the plan artifact
5. **Apply the 3-failure escalation rule** — after 3 failed hypotheses, escalate to a different specialist
6. **Identify the right debugger** — route based on where the symptom appears (see debugging protocol reference)

### Escalation During Debugging

| After N Failed Attempts | Action |
|------------------------|--------|
| 1-2 | Refine hypothesis, continue with current expert |
| 3 | Escalate to a different specialist or pair-debug |
| 5+ | Step back entirely, re-gather evidence, consider that fundamental assumptions are wrong |

### Post-Debug Actions

After resolving the bug:
1. Write a regression test (part of the fix, not optional)
2. File a completion report using the verification protocol
3. Update the plan artifact — was the root cause a process gap?
4. If process gap identified, create a follow-up task to fix the process

> **Reference:** See `skills/etyb/references/debugging-protocol.md` for the complete debugging methodology, hypothesis-driven debugging, root cause verification, and decision trees.
