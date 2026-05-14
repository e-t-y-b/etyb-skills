# Gate Transitions — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Gate Exit Verification](#1-gate-exit-verification)
2. [Gate Completion Report](#2-gate-completion-report)
3. [Blocking Conditions](#3-blocking-conditions)
4. [Inter-Gate Handoff Artifacts](#4-inter-gate-handoff-artifacts)
5. [Plan Mutation During Execution](#5-plan-mutation-during-execution)
6. [Gate Failure Handling](#6-gate-failure-handling)
7. [Scale-Aware Gate Transitions](#7-scale-aware-gate-transitions)
8. [Gate Transition Checklist](#8-gate-transition-checklist)
9. [Anti-Patterns](#9-anti-patterns)
10. [Examples](#10-examples)

---

## 1. Gate Exit Verification

When all tasks in a gate are marked `done` (or explicitly `dropped`), the gate is ready for exit verification. Do NOT advance to the next gate without completing this checklist.

### Gate Exit Checklist

Before requesting a gate transition, verify ALL of the following:

| # | Check | How to Verify | Fail Action |
|---|-------|--------------|-------------|
| 1 | All tasks in this gate are `done` or `dropped` | Scan the plan artifact task table | Complete remaining tasks |
| 2 | All `done` tasks have verification reports | Each task has 5-question answers | Run verification for unverified tasks |
| 3 | All tests pass | Run the full test suite | Fix failing tests |
| 4 | No unresolved blockers in this gate | Check the blockers section | Resolve or escalate blockers |
| 5 | Mandatory expert reviews complete | Check ETYB's mandatory expert rules | Request missing reviews |
| 6 | Decision log is current | All decisions made during execution are logged | Document missing decisions |
| 7 | Risk register is current | All risks discovered during execution are logged | Document missing risks |
| 8 | No scope items deferred without documentation | All `dropped` tasks have decision log entries | Document or reinstate |

### Per-Gate Exit Criteria

Each gate has specific exit criteria beyond the universal checklist:

**Design Gate Exit:**
- Architecture decisions documented in decision log
- API contracts defined (if applicable)
- Security review complete (if mandatory per expert rules)
- Data model defined (if applicable)
- Integration points identified

**Plan Gate Exit:**
- All tasks identified and estimated
- Dependencies mapped — no circular dependencies
- Test strategy defined by `qa-engineer`
- Risk register populated with at least top-3 risks
- Expert assignments complete for all tasks
- Critical path identified

**Implement Gate Exit:**
- All implementation tasks done with verification
- Unit tests passing — coverage meets test strategy targets
- Code follows established conventions
- No new security findings unaddressed
- All code changes committed with plan references

**Verify Gate Exit:**
- Integration and E2E tests passing
- Code review complete by `code-reviewer`
- Security review complete by `security-engineer` (if mandatory)
- Performance testing done (if specified in test strategy)
- Documentation updated (if applicable)

**Ship Gate Exit:**
- Staging deployment successful
- Monitoring and alerting configured
- Runbook created (for critical paths)
- Rollback plan defined
- Stakeholders notified

---

## 2. Gate Completion Report

When requesting a gate transition, produce a completion report for ETYB.

### Report Format

```markdown
## Gate Completion Report: {Gate Name}

**Plan:** {plan name}
**Gate:** {gate name}
**Status:** Ready for transition / Not ready
**Date:** {YYYY-MM-DD}

### Tasks Completed

| # | Task | Expert | Status | Verification |
|---|------|--------|--------|-------------|
| 4 | Implement auth service | backend-architect | done | 5Q complete |
| 5 | Add price validation | backend-architect | done | 5Q complete |
| 6 | Implement email service | backend-architect | done | 5Q complete |
| 7 | Implement password reset | backend-architect | done | 5Q complete |

**Total:** {N} tasks completed, {M} dropped

### Decisions Made During This Gate

| # | Decision | Rationale |
|---|----------|-----------|
| D5 | Return 200 for non-existent email on reset | Anti-enumeration security |
| D6 | Use JWT for reset tokens with 1h TTL | Stateless, time-bounded |

### Risks Identified During This Gate

| # | Risk | Priority | Status |
|---|------|----------|--------|
| R7 | No rate limiting on auth endpoints | High | Open — scheduled for Verify gate |
| R8 | Reset tokens stored unhashed | Medium | Accepted — short TTL mitigates |

### Verification Evidence

- **Test suite:** {N} total tests, all passing
- **New tests this gate:** {M}
- **Code review:** {status — pending/complete/not required at this gate}
- **Security review:** {status — pending/complete/not required at this gate}

### Blocking Conditions Check

- [ ] All tasks `done` or `dropped`
- [ ] All verification reports complete
- [ ] All tests passing
- [ ] No unresolved blockers
- [ ] Mandatory reviews complete
- [ ] Decision log current
- [ ] Risk register current

### Recommendation

{Ready to advance to {next gate} / Not ready — {specific items needed}}
```

### Who Reviews the Report

The gate completion report goes to the `etyb`, which makes the final pass/fail decision. The execution protocol produces the evidence; ETYB evaluates it.

| Your Role | ETYB's Role |
|-----------|-------------------|
| Produce the completion report | Review the report against gate criteria |
| Verify all tasks are done | Verify mandatory experts have signed off |
| Identify any gaps | Decide whether gaps block the transition |
| Recommend advance or hold | Make the final pass/fail call |

---

## 3. Blocking Conditions

Conditions that MUST prevent gate advancement. These are non-negotiable.

### Hard Blocks (Never Advance)

| Condition | Why It Blocks | Resolution |
|-----------|--------------|------------|
| Tasks with status `in-progress` | Incomplete work in the gate | Complete or move to `blocked`/`dropped` |
| Tasks with status `blocked` and no workaround | Unresolved impediments | Resolve blocker or drop task with justification |
| Failing tests | Broken functionality | Fix tests before advancing |
| Missing mandatory expert review | ETYB requires it | Request the review |
| `dropped` task without decision log entry | Unexplained scope reduction | Document why it was dropped |
| Unresolved P1 risk | High-impact risk without mitigation | Address or accept with documented justification |

### Soft Blocks (Evaluate Case-by-Case)

| Condition | When It Blocks | When It Doesn't |
|-----------|---------------|-----------------|
| Missing optional expert review | If the gate involves their domain | If no changes in their domain |
| P2 risk without mitigation | If it could become P1 in the next gate | If it has a clear deferred timeline |
| Incomplete documentation | At Verify gate (docs are part of verify) | At Implement gate (docs can wait) |
| Performance not benchmarked | If perf is a stated requirement | If perf testing is planned for Verify |

### How to Handle Tasks Not Completed

Not every task will be completed within a gate. Handle each case:

| Scenario | Action | Documentation |
|----------|--------|--------------|
| Task is done | Normal — include in completion report | Verification report |
| Task is blocked (resolvable) | Resolve before requesting gate transition | Blocker resolution in plan |
| Task is blocked (unresolvable in this gate) | Move to next gate if appropriate, or drop | Decision log entry |
| Task is no longer needed | Mark as `dropped` | Decision log entry explaining why |
| Task was underestimated | Split: done portion marked done, remainder as new task | New task in plan + decision log |

---

## 4. Inter-Gate Handoff Artifacts

Each gate transition produces artifacts that the next gate consumes. These artifacts are the contract between gates.

### Design to Plan

| Artifact | Content | Consumed By |
|----------|---------|-------------|
| Architecture decisions | Technology choices, patterns, constraints | `project-planner` for task breakdown |
| API contracts | OpenAPI specs, GraphQL schemas, gRPC protos | `project-planner` for interface tasks |
| Data model | Entity relationships, schema design | `project-planner` for database tasks |
| Security requirements | Auth approach, data classification, threat model | `project-planner` for security tasks |
| Integration map | External services, third-party APIs, system boundaries | `project-planner` for integration tasks |

**Handoff check:** Can `project-planner` break down ALL implementation work from these artifacts? If any area is vague, Design gate is not complete.

### Plan to Implement

| Artifact | Content | Consumed By |
|----------|---------|-------------|
| Task breakdown | All tasks with estimates, dependencies, expert assignments | `plan-execution-protocol` for execution |
| Test strategy | Test types, frameworks, coverage targets per task | `tdd-protocol` + domain experts |
| Risk register | Identified risks with mitigations | `plan-execution-protocol` for awareness |
| Dependency graph | Task ordering and parallelization opportunities | `plan-execution-protocol` for scheduling |
| Decision log | All Design decisions that constrain implementation | Domain experts during execution |

**Handoff check:** Can `plan-execution-protocol` pick up the first task and start executing? If any task is unclear, Plan gate is not complete.

### Implement to Verify

| Artifact | Content | Consumed By |
|----------|---------|-------------|
| Code changes | All implementation code committed | `code-reviewer` for review |
| Test results | Unit test suite passing with coverage report | `qa-engineer` for verification |
| Task completion reports | 5-question verification for each task | `code-reviewer` + `security-engineer` |
| Decision log updates | Decisions made during implementation | Reviewers for context |
| Risk register updates | New risks discovered during implementation | Security and QA review |

**Handoff check:** Can `code-reviewer` review all changes with full context? If completion reports are missing or vague, Implement gate is not complete.

### Verify to Ship

| Artifact | Content | Consumed By |
|----------|---------|-------------|
| Review approvals | Code review sign-off from `code-reviewer` | `devops-engineer` for deploy confidence |
| Security sign-off | Security review approval from `security-engineer` | `devops-engineer` + `sre-engineer` |
| QA sign-off | Test results, coverage, E2E results | `devops-engineer` for deploy decision |
| Updated documentation | API docs, architecture docs, user docs | `technical-writer` for final review |
| Performance results | Load test results, benchmark data | `sre-engineer` for monitoring setup |

**Handoff check:** Can `devops-engineer` deploy with confidence? If any sign-off is missing, Verify gate is not complete.

---

## 5. Plan Mutation During Execution

Plans change during execution. This is normal and expected. The key is that every mutation is documented and controlled.

### New Tasks Discovered

When execution reveals work not in the original plan:

1. **Add the task** to the plan's task breakdown
2. **Estimate effort** — how much additional work is this?
3. **Assign to a gate** — does it belong in the current gate or a future one?
4. **Assign an expert** — who should execute it?
5. **Map dependencies** — does it block or get blocked by other tasks?
6. **Add a decision log entry** — why was this task added?

```markdown
## Decision Log Entry: D9

**Date:** 2024-01-22
**Decision:** Added Task #12 (rate limiting on auth endpoints)
**Rationale:** Discovered during Task #7 execution that auth endpoints have no rate limiting.
  Risk R7 identifies this as High priority. Adding to Verify gate.
**Impact:** +1 task in Verify gate, estimated 2 hours
```

### Scope Changes

When the scope of a task or the plan changes:

1. **Document what changed** and why
2. **Update affected tasks** — modify descriptions, estimates, dependencies
3. **Assess impact** — does the change affect the critical path? Gate boundaries?
4. **Add a decision log entry** — capture the change decision
5. **Notify if significant** — if the change affects timeline or cost, escalate to user

### Re-Estimation

When estimates prove wrong:

1. **Update the task effort** in the plan
2. **Check cascading impact** — does the re-estimate affect gate boundaries or critical path?
3. **Add a decision log entry** if the re-estimate is significant (> 50% change)
4. **Don't anchor** — update honestly, don't adjust the estimate to match what you said before

### Task Splitting

When a task is too large (discovered during execution):

1. **Mark the completed portion** as a new task (done) — Task A
2. **Create a new task** for the remaining work — Task B
3. **Update dependencies** — anything depending on the original task now depends on Task B
4. **Re-estimate** Task B independently (not "remaining time from original estimate")
5. **Add a decision log entry** explaining the split

**Example:**
```
Original: Task #7 — Implement password reset flow (8 hours)
Split into:
  Task #7a — Implement token generation and validation (done, 4 hours actual)
  Task #7b — Implement email integration and reset endpoint (pending, estimated 5 hours)
  Decision D7: Split Task #7 — scope larger than estimated, email integration
  requires custom template rendering not originally anticipated.
```

---

## 6. Gate Failure Handling

Sometimes a gate transition is requested but ETYB rejects it. Handle this gracefully.

### When a Gate Fails

1. **Identify which criteria failed** — ETYB will specify
2. **Create remediation tasks** — specific tasks to address each failure
3. **Add remediation tasks to the current gate** — not the next gate
4. **Execute the remediation tasks** using the normal execution loop
5. **Re-request gate transition** when remediation is complete

### Remediation Task Format

```markdown
| # | Task | Status | Expert | Dependencies | Gate | Remediation For |
|---|------|--------|--------|--------------|------|-----------------|
| R1 | Fix failing integration test for order API | pending | backend-architect | — | Implement | Gate failure: tests not passing |
| R2 | Address security finding in auth middleware | pending | security-engineer | — | Implement | Gate failure: security review |
```

### The Two-Failure Rule

If a gate fails twice (after the first remediation cycle), escalate to the user:

```markdown
## Gate Failure Escalation: {Gate Name}

**Failure count:** 2

### First Failure
- **Criteria failed:** {list}
- **Remediation attempted:** {list of remediation tasks and outcomes}

### Second Failure
- **Criteria failed:** {list — same or different from first?}
- **What's not working:** {analysis of why remediation isn't sufficient}

### Recommendation
{Options for the user:}
1. {Specific additional remediation with higher effort}
2. {Adjust gate criteria (if overly strict for the project scale)}
3. {Re-scope the work in this gate}
```

Do NOT loop indefinitely. Two failures means something structural is wrong — a blocker, a misunderstanding, or an unrealistic criterion.

### Common Gate Failure Causes

| Cause | Typical Gate | Resolution |
|-------|-------------|------------|
| Tests failing | Implement | Fix the tests — they indicate real issues |
| Missing code review | Verify | Request `code-reviewer` sign-off |
| Security findings | Verify | Address findings or accept with documented risk |
| Performance not met | Verify | Optimize or adjust the performance target |
| Documentation missing | Verify | Write the missing docs or defer with decision log |
| Deployment failed | Ship | Debug the deployment, fix configuration |
| Monitoring not configured | Ship | Set up monitoring before deploying |

---

## 7. Scale-Aware Gate Transitions

Gate transitions scale with project complexity:

### Startup Scale

- **Gate collapsing:** Design + Plan may collapse into one gate. Implement gate stands alone. Verify + Ship may collapse.
- **Completion report:** Brief — task list with status, key decisions, main risks. One paragraph per section.
- **Transition speed:** Same-session transitions. No waiting for formal reviews.
- **Mandatory reviews:** Only `security-engineer` if touching auth/PII. Other reviews are optional.

### Growth Scale

- **All 5 gates active** but transitions are lightweight
- **Completion report:** Standard format with all sections but brief entries
- **Transition speed:** Within the same day. Reviews can be async.
- **Mandatory reviews:** Per ETYB rules. Code review at Verify is mandatory.

### Scale

- **All 5 gates active** with formal transitions
- **Completion report:** Full format with detailed evidence
- **Transition speed:** May take 1-2 days for reviews to complete
- **Mandatory reviews:** All per ETYB rules. Multiple reviewers may be needed.
- **Parallel gate work:** Subteams may be in different gates on different tasks

### Enterprise Scale

- **All 5 gates active** with audited transitions
- **Completion report:** Full format with compliance evidence
- **Transition speed:** Scheduled transition reviews (e.g., weekly gate review meeting)
- **Mandatory reviews:** All per ETYB rules plus compliance checks
- **Approval workflow:** Gate transitions require documented approval

---

## 8. Gate Transition Checklist

Use this checklist when preparing to request a gate transition:

```markdown
## Pre-Transition Checklist: {Current Gate} → {Next Gate}

### Task Completion
- [ ] All tasks in {current gate} are `done` or `dropped`
- [ ] No tasks are `in-progress`
- [ ] `dropped` tasks have decision log entries

### Verification
- [ ] All `done` tasks have 5-question verification reports
- [ ] Verification answers are concrete (not vague)
- [ ] All tests pass (full suite, not just new tests)

### Reviews
- [ ] Mandatory expert reviews complete (per ETYB rules)
- [ ] Review findings addressed or documented as accepted risks

### Documentation
- [ ] Decision log is up to date
- [ ] Risk register is up to date
- [ ] New tasks discovered during execution are in the plan

### Handoff Artifacts
- [ ] All artifacts needed by the next gate are produced (see Section 4)
- [ ] Artifacts are accessible and complete

### Blockers
- [ ] No open blockers in this gate
- [ ] All resolved blockers are documented

### Ready?
- [ ] Gate completion report is drafted
- [ ] Recommendation is clear (advance / hold)
```

---

## 9. Anti-Patterns

| Anti-Pattern | What Happens | Correct Approach |
|-------------|-------------|-----------------|
| **Gate rushing** | All tasks are "done" but verification is sloppy | Every task needs real verification before gate transition |
| **Gate skipping** | Jump from Implement to Ship without Verify | Gates are sequential. No skipping (except scale-aware collapsing) |
| **Perpetual gate** | Gate never completes because new tasks keep appearing | Time-box the gate. New tasks go to a future gate unless critical. |
| **Rubber-stamp transition** | Complete the checklist without actually checking | Verify each checklist item with evidence |
| **Silent handoff** | Advance to next gate without producing handoff artifacts | Every transition produces the artifacts the next gate needs |
| **Gate cycling** | Fail → remediate → fail → remediate → ... | Two-failure rule: escalate after second failure |
| **Scope smuggling** | Add tasks to a gate after it was "complete" | New tasks go to a future gate. Only remediation tasks add to current gate. |
| **Partial advance** | Some tasks advance to next gate, others stay | A gate transition advances ALL work. Don't split a gate. |

---

## 10. Examples

### Example: Implement Gate Completion

```markdown
## Gate Completion Report: Implement

**Plan:** user-auth-system
**Gate:** Implement
**Status:** Ready for transition
**Date:** 2024-01-25

### Tasks Completed

| # | Task | Expert | Status | Verification |
|---|------|--------|--------|-------------|
| 4 | Implement auth service | backend-architect | done | 5Q complete |
| 5 | Add input validation | backend-architect | done | 5Q complete |
| 6 | Implement email service | backend-architect | done | 5Q complete |
| 7 | Implement password reset | backend-architect | done | 5Q complete |
| 8 | Implement session management | backend-architect | done | 5Q complete |

**Total:** 5 tasks completed, 0 dropped

### Decisions Made
| # | Decision | Rationale |
|---|----------|-----------|
| D5 | Return 200 for non-existent email on reset | Anti-enumeration |
| D6 | JWT for reset tokens, 1h TTL | Stateless |
| D7 | Split Task 7 into 7a/7b | Scope larger than estimated |

### Risks Identified
| # | Risk | Priority | Status |
|---|------|----------|--------|
| R7 | No rate limiting | High | Open — Verify gate |
| R8 | Unhashed reset tokens | Medium | Accepted |

### Verification Evidence
- Test suite: 156 total tests, all passing
- New tests this gate: 43
- Code review: pending (required at Verify gate)
- Security review: pending (required at Verify gate)

### Blocking Conditions: All Clear
- [x] All tasks done
- [x] All verifications complete
- [x] All tests passing
- [x] No unresolved blockers
- [x] Decision log current
- [x] Risk register current

### Recommendation
Ready to advance to Verify gate. Code review and security review are
the priority for Verify — R7 (rate limiting) should be addressed as the
first Verify task.
```

### Example: Gate Failure and Remediation

```
Gate Transition Request: Implement → Verify
ETYB Response: REJECTED

Reasons:
1. Task #6 integration test is flaky (fails 1 in 5 runs)
2. Security-engineer flagged SQL injection risk in Task #5 validation

Remediation Tasks Created:
| # | Task | Expert | Gate | Remediation For |
|---|------|--------|------|-----------------|
| R1 | Fix flaky email service integration test | backend-architect | Implement | Flaky test |
| R2 | Parameterize all SQL queries in validation | security-engineer | Implement | SQL injection |

Execute R1 and R2, then re-request gate transition.
```
