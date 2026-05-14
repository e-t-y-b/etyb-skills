# Task Execution Cycle — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Step 1: Read the Task Spec](#1-step-1-read-the-task-spec)
2. [Step 2: Identify the Required Expert](#2-step-2-identify-the-required-expert)
3. [Step 3: Set Up Context](#3-step-3-set-up-context)
4. [Step 4: Execute with TDD](#4-step-4-execute-with-tdd)
5. [Step 5: Run Verification Protocol](#5-step-5-run-verification-protocol)
6. [Step 6: Update the Plan Artifact](#6-step-6-update-the-plan-artifact)
7. [Step 7: Commit](#7-step-7-commit)
8. [Execution Modes](#8-execution-modes)
9. [Task Handoff Patterns](#9-task-handoff-patterns)
10. [Cycle Timing and Rhythm](#10-cycle-timing-and-rhythm)
11. [Anti-Patterns](#11-anti-patterns)
12. [Examples](#12-examples)

---

## 1. Step 1: Read the Task Spec

Before touching any code, fully understand what the task requires. Every task in the plan artifact has structured information. Extract all of it.

### What to Extract from the Task Row

```markdown
| # | Task | Status | Expert | Dependencies | Verified By | Gate |
|---|------|--------|--------|--------------|-------------|------|
| 7 | Implement password reset flow | pending | backend-architect | Task 4 (auth service), Task 6 (email service) | — | Implement |
```

From this row, extract:

| Field | Value | Implication |
|-------|-------|-------------|
| Task ID | 7 | Reference this in commits and logs |
| Description | Implement password reset flow | The deliverable |
| Status | pending | Ready to start (not blocked) |
| Expert | backend-architect | Load this skill for execution |
| Dependencies | Task 4, Task 6 | Verify these are `done` before starting |
| Verified By | — | Needs verification after completion |
| Gate | Implement | Confirms we're in the right phase |

### What Does the Task Require?

Go beyond the task row. Check the plan artifact for additional context:

1. **Acceptance criteria** — Does the plan or a linked document define what "done" looks like for this task?
2. **Architectural constraints** — Does the decision log contain decisions that affect how this task should be implemented?
3. **Risk notes** — Does the risk register mention anything relevant to this task?
4. **Prior task outputs** — What did the dependency tasks produce? Read their completion reports.

### What Files Are Involved?

Determine the scope of the change:

1. **Existing files to modify** — which source files, config files, or test files need changes?
2. **New files to create** — does the task require new modules, components, or configurations?
3. **Test files** — which test files will contain the tests for this task?
4. **Related files** — which files need to be read for context but won't be modified?

### What Is the Expected Deliverable?

State the concrete output before starting:

```
Task 7 deliverable:
- POST /api/auth/reset-password endpoint
- ResetPasswordService with token generation, email dispatch, token validation
- Database migration for password_reset_tokens table
- Unit tests for ResetPasswordService (happy path, expired token, invalid token)
- Integration test for full reset flow
```

If you cannot state the deliverable clearly, the task spec is insufficient. This is a blocker — see `references/blocker-management.md`.

### Dependency Verification

Before starting, confirm all dependencies are satisfied:

```
Task 7 dependencies:
- Task 4 (auth service): DONE — AuthService exists at src/services/auth.ts
- Task 6 (email service): DONE — EmailService exists at src/services/email.ts
  - Completion report confirms sendEmail() is tested and working
```

If any dependency is not `done`, do NOT start this task. Mark it `blocked` with the reason.

---

## 2. Step 2: Identify the Required Expert

Each task is assigned an expert in the plan. Load that expert's knowledge before executing.

### Expert Resolution

The plan specifies which expert skill to use. Common mappings:

| Task Type | Primary Expert | Supporting Experts |
|-----------|---------------|-------------------|
| API endpoint implementation | `backend-architect` | `security-engineer` (if auth-related) |
| React component | `frontend-architect` | `qa-engineer` (component testing) |
| Database schema change | `database-architect` | `backend-architect` (migration code) |
| CI/CD pipeline | `devops-engineer` | `sre-engineer` (monitoring hooks) |
| Authentication flow | `backend-architect` + `security-engineer` | mandatory per ETYB rules |
| Mobile screen | `mobile-architect` | `frontend-architect` (shared patterns) |
| ML model integration | `ai-ml-engineer` | `backend-architect` (serving layer) |

### Loading the Expert

To "load the expert" means:

1. **Read their SKILL.md** — understand their approach, patterns, and anti-patterns
2. **Check scale-aware guidance** — what do they recommend at this project's scale?
3. **Read relevant references** — if the task is complex, read the expert's detailed reference files
4. **Check their response format** — align your execution with how they structure their work

### When the Plan Doesn't Specify an Expert

If the task row has no assigned expert:

1. Classify the task by type (frontend, backend, database, infrastructure, etc.)
2. Consult ETYB's team registry for the appropriate skill
3. Check mandatory expert rules — does this change type require specific experts?
4. Assign the expert and update the plan artifact

### Multi-Expert Tasks

Some tasks require multiple experts. Handle this by:

1. Identify the **primary expert** — the one who does most of the implementation
2. Identify **supporting experts** — those who review or contribute specific pieces
3. Execute with the primary expert's guidance
4. Request supporting expert review during verification (step 5)

---

## 3. Step 3: Set Up Context

Before writing any code, establish the full context needed for execution.

### Load the Expert Skill

Read the assigned expert's SKILL.md. Extract:

- **Approach patterns** — how they structure implementations of this type
- **Scale-aware recommendations** — what's appropriate for this project's size
- **Anti-patterns to avoid** — common mistakes for this type of work
- **Testing patterns** — how they recommend testing this type of code

### Read Relevant Source Files

Understand the existing codebase:

1. **Files that will be modified** — read them fully, understand their current state
2. **Adjacent files** — read modules that interact with the files you'll modify
3. **Test files** — read existing tests to understand the testing patterns in use
4. **Configuration** — read relevant config files (database config, API routes, etc.)

### Load Test Strategy

If `qa-engineer` produced a test strategy at the Plan gate, read it:

1. **What types of tests** are specified for this task? (unit, integration, E2E)
2. **What framework** is specified? (Jest, pytest, Go test, etc.)
3. **What coverage expectations** exist?
4. **What test patterns** does the strategy recommend? (mocking strategy, test data approach)

If no test strategy exists, apply sensible defaults:
- Unit tests for business logic
- Integration tests for API endpoints
- The testing framework already in use in the project

### Check Architectural Constraints

Read the plan's decision log for constraints that affect this task:

```
Decision Log Entry:
- Decision: Use JWT for auth tokens (not session cookies)
- Date: 2024-01-15
- Rationale: Stateless architecture, multi-service setup
- Affects: All auth-related tasks including Task 7
```

These constraints are not suggestions — they are architectural decisions already made. Do not revisit them during execution unless the task reveals they are unworkable (which becomes a new decision log entry).

### Prepare the Working Context

Before writing any code, you should have:

| Context Item | Source | Loaded? |
|-------------|--------|---------|
| Task spec and acceptance criteria | Plan artifact | Required |
| Expert skill knowledge | Expert's SKILL.md | Required |
| Relevant source files | Project codebase | Required |
| Test strategy | qa-engineer Plan gate output | If available |
| Architectural constraints | Decision log | If relevant |
| Prior task outputs | Dependency completion reports | If dependencies exist |

If any required context is missing, identify it before proceeding. Missing context is a setup failure, not a task failure.

---

## 4. Step 4: Execute with TDD

Implementation follows TDD discipline. `tdd-protocol` is active for every code-producing task.

### TDD Integration

The execution follows the red-green-refactor cycle within the task:

1. **Identify the first behavior** — what is the simplest behavior this task needs?
2. **RED** — write a failing test for that behavior
3. **Verify RED** — run the test, confirm it fails for the right reason
4. **GREEN** — write minimal code to make the test pass
5. **Verify GREEN** — run ALL tests, confirm everything passes
6. **REFACTOR** — clean up code and tests
7. **Verify REFACTOR** — run ALL tests again
8. **Next behavior** — repeat until all task behaviors are implemented

### Aligning TDD with the Test Strategy

If `qa-engineer` defined a test strategy:

| Strategy Says | TDD Cycle Does |
|--------------|----------------|
| "Unit tests for business logic" | RED phase writes unit tests for business logic functions |
| "Integration tests for API endpoints" | After unit TDD cycles, write integration tests for the endpoint |
| "Mock external services" | Use mocks in unit tests, real services in integration tests |
| "80% coverage on critical paths" | TDD naturally achieves this; verify at the end |

### What Counts as "Executed"

A task is fully executed when:

- [ ] All behaviors specified in the task are implemented
- [ ] Every behavior has at least one test
- [ ] All tests pass (not just the new ones — ALL tests)
- [ ] Code follows the patterns established in the codebase
- [ ] No linting errors or type errors
- [ ] The implementation satisfies any architectural constraints from the decision log

### When Execution Gets Stuck

If implementation hits a wall during TDD:

1. **Test won't go green after 3 attempts** — the design may be wrong. Check with the expert's guidance for alternative approaches.
2. **New test breaks existing tests** — there's a conflict. Check if architectural constraints need updating.
3. **Task scope is larger than expected** — the task may need splitting. Document this and check `references/blocker-management.md`.

---

## 5. Step 5: Run Verification Protocol

After execution, verify the work by answering the 5 questions. This is mandatory — no exceptions.

### The 5 Verification Questions

Answer each question concretely. Vague answers are not acceptable.

#### Question 1: What Was Done?

**Bad:** "Implemented the password reset flow."
**Good:** "Added POST /api/auth/reset-password endpoint in src/routes/auth.ts. Created ResetPasswordService in src/services/reset-password.ts with methods: generateToken(), sendResetEmail(), validateToken(), resetPassword(). Added password_reset_tokens table migration in migrations/003_reset_tokens.sql."

#### Question 2: How Was It Verified?

**Bad:** "Tested it."
**Good:** "Ran `npm test -- --grep 'ResetPassword'` — 8 tests pass. Ran `npm run test:integration` — full reset flow test passes. Manually tested with curl: POST /api/auth/reset-password with valid email returns 200, invalid email returns 404, expired token returns 410."

#### Question 3: What Tests Prove It?

**Bad:** "Tests pass."
**Good:**
```
- [x] unit: ResetPasswordService.generateToken — creates valid JWT with 1h expiry
- [x] unit: ResetPasswordService.generateToken — token contains user ID
- [x] unit: ResetPasswordService.validateToken — valid token returns user
- [x] unit: ResetPasswordService.validateToken — expired token throws ExpiredTokenError
- [x] unit: ResetPasswordService.validateToken — tampered token throws InvalidTokenError
- [x] unit: ResetPasswordService.resetPassword — updates password hash
- [x] unit: ResetPasswordService.resetPassword — invalidates used token
- [x] integration: POST /api/auth/reset-password — full flow
```

#### Question 4: What Edge Cases Were Considered?

**Bad:** "Thought about edge cases."
**Good:**
- Expired token (1h TTL) — returns 410 Gone with clear message
- Token reuse — tokens are single-use, deleted after password reset
- Concurrent reset requests — latest token wins, previous tokens invalidated
- Non-existent email — returns 200 (prevents email enumeration)
- Rate limiting — not implemented yet, tracked as risk R7

#### Question 5: What Could Go Wrong?

**Bad:** "Nothing should go wrong."
**Good:**
- No rate limiting on reset endpoint — attacker could spam reset emails (tracked as R7)
- Token stored in plain text — acceptable for short-lived tokens, but should use hashed storage for production (tracked as R8)
- Email delivery failure — no retry mechanism; user must request again
- Clock skew between services could cause premature token expiry in distributed setup

### Verification Failure

If you cannot satisfactorily answer questions 2 or 3:

1. **Stop** — the task is not done
2. **Identify what's missing** — which verification is lacking?
3. **Go back and verify** — run the tests, execute the manual checks
4. **Only then complete verification** — when you have real evidence

---

## 6. Step 6: Update the Plan Artifact

After verification passes, update the plan artifact. Every task completion mutates the plan.

### Task Status Update

```markdown
| # | Task | Status | Expert | Dependencies | Verified By |
|---|------|--------|--------|--------------|-------------|
| 7 | Implement password reset flow | done | backend-architect | Task 4, Task 6 | plan-execution-protocol |
```

Change `pending` or `in-progress` to `done`. Set `Verified By` to indicate verification was performed.

### Decision Log Updates

If any decisions were made during execution, add them:

```markdown
## Decision Log

| # | Date | Decision | Rationale | Affects |
|---|------|----------|-----------|---------|
| D5 | 2024-01-20 | Return 200 for non-existent email on reset | Prevents email enumeration attack | Task 7, security posture |
```

### Risk Register Updates

If any new risks were discovered during execution:

```markdown
## Risk Register

| # | Risk | Probability | Impact | Mitigation | Status |
|---|------|-------------|--------|------------|--------|
| R7 | No rate limiting on password reset | High | Medium | Add rate limiter in Verify gate | Open |
| R8 | Reset tokens stored unhashed | Medium | Low | Acceptable for short TTL; hash for production | Accepted |
```

### New Task Discovery

If execution revealed work that wasn't in the plan:

1. Add the new task to the task breakdown
2. Assign it an expert
3. Place it in the appropriate gate
4. Estimate its effort
5. Note it in the decision log with rationale

```markdown
| # | Task | Status | Expert | Dependencies | Verified By | Gate |
|---|------|--------|--------|--------------|-------------|------|
| 12 | Add rate limiting to auth endpoints | pending | backend-architect | Task 7 | — | Verify |
```

---

## 7. Step 7: Commit

Every completed task gets its own commit. The commit represents a verified, tested, plan-tracked unit of work.

### Commit Requirements

| Requirement | Rationale |
|-------------|-----------|
| All tests pass | The commit is a known-good state |
| Commit message references the plan | Traceability from code to plan |
| Commit message references the task | Traceability from code to task |
| Small and focused | One task = one commit (split if task is large) |
| No unrelated changes | The commit is only about this task |

### Commit Message Format

```
[Plan:{plan-name}] Task #{task_id}: {task_description}

- {summary of what was implemented}
- {key decisions made, if any}
- Tests: {N} new, all passing
- Refs: {any relevant links or notes}
```

**Example:**

```
[Plan:user-auth] Task #7: Implement password reset flow

- Added POST /api/auth/reset-password endpoint
- Created ResetPasswordService with token generation and validation
- Added password_reset_tokens migration
- Decision: return 200 for non-existent emails (anti-enumeration)
- Tests: 8 new (7 unit, 1 integration), all passing
- Risk: no rate limiting yet (R7)
```

### When to Split Commits

If a task is large enough that multiple logical units of work exist:

1. Commit after each TDD cycle group (related behaviors)
2. Each commit should still pass all tests
3. The final commit for the task includes the verification report
4. All commits reference the same task ID

---

## 8. Execution Modes

### Inline Execution

Execute the task within the current session. You are the runtime — you load the expert skill, follow their guidance, write the code, run the tests, verify.

**When to use inline:**
- Task is simple (under 30 minutes, fewer than 3 files)
- Task depends on context from a just-completed task
- Task modifies shared code that other in-progress work touches
- You need tight iteration with the user

**Inline execution flow:**
```
1. Read expert SKILL.md
2. Read relevant source files
3. Begin TDD cycle
4. Execute red-green-refactor within the current session
5. Verify (5 questions)
6. Update plan
7. Commit
```

### Subagent Execution

Dispatch the task to a separate session via `subagent-protocol`. The subagent receives full context and executes independently.

**When to use subagent:**
- Task is independent (no shared files with in-progress tasks)
- Task is in an isolated domain (own module, own tests)
- Multiple tasks can run in parallel
- Task is complex enough to benefit from a dedicated session

**Subagent dispatch format:**
```markdown
## Subagent Task: #{task_id} — {description}

**Expert:** {skill to load}
**Plan:** {plan artifact location}
**Context Files:** {list of files to read}
**Test Strategy:** {relevant section from qa-engineer strategy}
**Constraints:** {relevant decision log entries}
**Deliverable:** {expected output}
**Verification:** Complete the 5 verification questions upon completion
```

**After subagent completion:**
1. Read the subagent's completion report
2. Verify their 5-question answers are satisfactory
3. Run all tests locally to confirm (trust but verify)
4. Update the plan artifact
5. Commit if not already committed by the subagent

### Hybrid Execution

The most common mode. Use inline for simple or dependent tasks, subagent for complex or independent ones.

**Hybrid decision per task:**
```
For each pending task in the current gate:
  1. Is it simple AND dependent? → Queue for inline
  2. Is it complex AND independent? → Dispatch to subagent
  3. Is it complex AND dependent? → Queue for inline (needs context)
  4. Is it simple AND independent? → Either (prefer inline for less overhead)
```

**Managing hybrid execution:**
- Track which tasks are dispatched to subagents
- Don't start inline tasks that share files with subagent tasks
- When a subagent completes, verify and update before starting dependent tasks
- If a subagent task blocks, handle it in the blocker management protocol

---

## 9. Task Handoff Patterns

### Sequential Handoff

Task B depends on Task A. Task A's output is Task B's input.

```
Task A (done) → Completion report → Task B reads report → Task B starts
```

The completion report is the handoff artifact. Task B should read:
- Task A's verification answers
- Files Task A created or modified
- Decisions Task A made (from decision log)

### Parallel Handoff

Tasks C and D are independent. Both can execute simultaneously.

```
Task C (subagent) ──┐
                    ├──► Both done → Continue with Task E (depends on both)
Task D (subagent) ──┘
```

The plan artifact is the coordination mechanism. When both C and D are `done`, Task E's dependencies are satisfied.

### Expert Handoff

Task switches from one expert to another (e.g., backend → frontend).

```
Task 8 (backend-architect): Create API endpoint
  ↓ Completion report includes: endpoint URL, request/response schema, auth requirements
Task 9 (frontend-architect): Build UI that calls the endpoint
  ↓ Reads Task 8's completion report for API contract
```

The handoff artifact is the completion report plus any API contracts, schemas, or interface definitions produced.

---

## 10. Cycle Timing and Rhythm

### Expected Durations

| Task Complexity | Expected Duration | TDD Cycles | Commit Count |
|----------------|-------------------|------------|--------------|
| Simple (config change, small function) | 15-30 minutes | 1-2 | 1 |
| Medium (API endpoint, component) | 30-90 minutes | 3-5 | 2-3 |
| Complex (service, multi-file feature) | 90-180 minutes | 5-10 | 3-5 |
| Very Complex (subsystem) | Should be split into smaller tasks | — | — |

### Warning Signs

| Signal | What It Means | Action |
|--------|--------------|--------|
| Task taking > 2x expected duration | Task may be too large or hitting a blocker | Consider splitting or investigate blocker |
| More than 3 TDD cycles without progress | Design issue or unclear requirements | Step back, re-read task spec, consider escalation |
| Verification answers are vague | Insufficient testing or understanding | Go back and add specific tests |
| No commits for > 2 hours | Work is not being chunked properly | Commit what you have, reassess approach |

---

## 11. Anti-Patterns

### Task Execution Anti-Patterns

| Anti-Pattern | What Happens | Correct Approach |
|-------------|-------------|-----------------|
| **Spec-and-sprint** | Read task, immediately start coding without context setup | Complete all 3 setup steps before writing any code |
| **Test-after theater** | Write all code first, then add tests to check the "test" box | Activate TDD — failing test first, every time |
| **Verification handwave** | "It works" without specific evidence | Answer all 5 questions with concrete details |
| **Plan drift** | Complete tasks without updating the plan artifact | Update the plan immediately after every task |
| **Silent decisions** | Make implementation choices without logging them | Every choice that affects future tasks goes in the decision log |
| **Commit batching** | Do 3 tasks, then commit everything at once | One task = one commit (or one commit per TDD cycle group) |
| **Context skipping** | Start execution without reading source files or test strategy | Full context setup before any execution |
| **Parallel panic** | Try to work on multiple tasks at once | One task at a time. Always. |

### Recovery from Anti-Patterns

If you catch yourself in an anti-pattern:

1. **Stop** — don't continue the anti-pattern
2. **Assess** — what's the current state? What did you skip?
3. **Backfill** — do the skipped step (write the test, update the plan, commit)
4. **Resume** — continue from the correct point in the cycle

---

## 12. Examples

### Example: Simple Task (Inline)

```
Plan: e-commerce-mvp
Gate: Implement
Task: #5 — Add product price validation

1. READ SPEC: Task #5 requires price validation on Product model.
   Acceptance: price must be > 0, max 2 decimal places, max $999,999.99
   Dependencies: Task #3 (Product model) — DONE
   Expert: backend-architect

2. IDENTIFY EXPERT: backend-architect — read SKILL.md for validation patterns

3. SET UP CONTEXT:
   - Read src/models/product.ts (existing Product model from Task #3)
   - Read src/models/__tests__/product.test.ts (existing tests)
   - Test strategy: unit tests with Jest (from qa-engineer)

4. EXECUTE WITH TDD:
   RED: test("rejects price <= 0") — fails (no validation exists)
   GREEN: add if (price <= 0) throw — test passes
   RED: test("rejects more than 2 decimal places") — fails
   GREEN: add decimal check — test passes
   RED: test("rejects price > 999999.99") — fails
   GREEN: add max check — test passes
   REFACTOR: extract validatePrice() helper, clean up test descriptions

5. VERIFY:
   (a) Added validatePrice() in src/models/product.ts with 3 validations
   (b) Ran npm test -- --grep "price" — 3 new tests pass, all 47 tests pass
   (c) Tests: rejects-zero, rejects-decimals, rejects-max — all pass
   (d) Edge cases: 0, negative, $0.001, $999,999.99, $1,000,000
   (e) Risk: no currency validation (assumes USD) — logged as R4

6. UPDATE PLAN: Task #5 → done, R4 added to risk register

7. COMMIT: [Plan:e-commerce-mvp] Task #5: Add product price validation
```

### Example: Complex Task (Subagent)

```
Plan: saas-platform
Gate: Implement
Task: #11 — Implement Stripe webhook handler

1. READ SPEC: Task #11 requires webhook handler for subscription events.
   Events: customer.subscription.created, updated, deleted, invoice.paid, payment_failed
   Dependencies: Task #8 (Stripe integration) — DONE, Task #9 (Subscription model) — DONE
   Expert: backend-architect + fintech-architect (mandatory per Expert Mandating)

2. DISPATCH TO SUBAGENT:
   Expert: backend-architect (primary), fintech-architect (supporting)
   Context: src/services/stripe.ts, src/models/subscription.ts, Plan decisions D3 (idempotency keys)
   Deliverable: Webhook endpoint, event handlers, idempotency, signature verification
   Verification: Complete 5 questions, all tests pass

3. SUBAGENT COMPLETES — read completion report
4. VERIFY subagent's 5-question answers — satisfactory
5. Run all tests locally — 12 new tests, all 156 pass
6. UPDATE PLAN: Task #11 → done, Decision D8 added (retry policy for failed webhooks)
7. COMMIT: [Plan:saas-platform] Task #11: Implement Stripe webhook handler
```
