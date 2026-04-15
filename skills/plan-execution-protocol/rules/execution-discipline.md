# Execution Discipline Rules

Hard constraints for plan execution. These are non-negotiable when an active plan exists.

## Absolute Rules

1. **NEVER work on more than one task at a time.** One task in-progress. Complete it, verify it, update the plan, commit. Then pick the next task. Parallel execution is handled by subagents, not by multitasking within a session.

2. **NEVER skip the verification step after completing a task.** Every completed task must answer the 5 verification questions with concrete, specific answers. "It works" is not verification. "All tests pass" without naming the tests is not verification.

3. **NEVER advance to the next gate without all current gate tasks being done or explicitly dropped.** A gate transition requires every task in the gate to be `done`, `dropped` (with decision log entry), or resolved from `blocked`. No partial gate transitions.

4. **ALWAYS update the plan artifact after completing a task.** Task status, decision log entries, risk register entries, and new task discoveries — all go into the plan immediately. A plan that doesn't reflect reality is worse than no plan.

5. **ALWAYS commit after completing a task with all tests passing.** Every task produces a commit. The commit message references the plan and task ID. The commit represents a verified, tested, green state.

6. **NEVER guess past a blocker.** If a task is blocked, document the blocker, skip to the next unblocked task, or escalate. Never assume what a blocked dependency will produce. Never assume the blocker will resolve itself. Never proceed with incomplete information.

7. **ALWAYS document plan mutations in the decision log.** New tasks added, tasks dropped, scope changes, re-estimation, task splitting — every mutation to the plan is a decision, and decisions are logged with rationale.

## Process Rules

8. **Read the plan artifact before starting any work session.** Understand the current gate, the next task, any blockers, and any risks. Orient before executing.

9. **Activate tdd-protocol for every code-producing task.** No exceptions. The failing test comes before the implementation. This is not optional even under time pressure.

10. **Follow the escalation ladder for blockers.** L1 (self-resolve, 15 min) before L2 (debugging protocol, 30 min) before L3 (specialist) before L4 (user). Do not skip levels. Do not stay stuck beyond the time box.

11. **Produce a gate completion report before requesting any gate transition.** The orchestrator needs evidence to approve the transition. The completion report is that evidence.

12. **If a gate fails twice, escalate to the user.** Do not loop. Two failures means something structural is wrong that the execution loop alone cannot fix.
