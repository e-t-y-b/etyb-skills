# TDD Enforcement Rules

Hard constraints for TDD discipline. These are non-negotiable during implementation.

## Absolute Rules

1. **NEVER write production code before a failing test exists.** If there is no failing test, there is no reason to write code. The test defines the requirement. The code fulfills it.

2. **NEVER skip the "verify RED" step.** Run the test. Watch it fail. Read the failure message. Confirm it fails because the behavior is absent, not because of a typo, missing import, or configuration error.

3. **NEVER skip the "verify GREEN" step.** Run ALL tests after writing implementation code — not just the new test. A change that makes one test pass while breaking another is not GREEN.

4. **NEVER merge code with 0% test coverage on changed lines.** Every changed line of production code must be exercised by at least one test. If a line can't be tested, document why.

5. **NEVER write more production code than the failing test requires.** The GREEN step means MINIMAL code. Resist the urge to add error handling, edge cases, or optimizations that no test demands yet.

6. **NEVER commit a RED state to the main branch.** Every commit on main must have all tests passing. RED commits are acceptable on feature branches only if the team explicitly opts into that practice.

## Process Rules

7. **If qa-engineer defined a test strategy at Plan gate, the TDD cycle must align with that strategy.** The test types, frameworks, and coverage targets from the plan are your marching orders. TDD is the execution; the plan is the specification.

8. **After 3 consecutive red-green-refactor cycles, pause and check:** Are you testing behavior or implementation? Tests that describe WHAT the code does survive refactoring. Tests that describe HOW the code works break on every change.

9. **Commit after each green-refactor cycle.** Do not batch multiple cycles into a single commit. Small, frequent commits create a bisectable history and show TDD evidence.

10. **When a bug is found in production, write a failing test that reproduces it BEFORE writing the fix.** The regression test ensures the bug never returns. Fixing without a test is just hoping.

## Escalation Rules

11. **If you cannot make a test green without breaking another test after 3 attempts, escalate.** Provide: the new test, the implementation attempts, and which existing tests broke. This likely indicates a design issue, not a TDD issue.

12. **If a developer refuses TDD after evidence-based discussion, escalate to the orchestrator.** TDD is a protocol, not a suggestion. Exceptions require documented justification.

## Exceptions (Documented Only)

The following are the ONLY acceptable exceptions to TDD, and each must be documented:

- **Framework boilerplate** that is never modified (e.g., `main()` entry point, generated code)
- **Pure configuration files** with no logic (but config WITH logic must be tested)
- **Third-party generated code** that is not manually edited
- **Spike/exploratory code** that is explicitly marked as throwaway and will be deleted before the TDD implementation begins

Every exception must be noted in the commit message or PR description with the reason.
