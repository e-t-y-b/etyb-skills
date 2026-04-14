# Blocker Management — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Blocker Detection](#1-blocker-detection)
2. [Blocker Handling Protocol](#2-blocker-handling-protocol)
3. [Blocker Types and Responses](#3-blocker-types-and-responses)
4. [Blocker Escalation](#4-blocker-escalation)
5. [Blocker Resolution](#5-blocker-resolution)
6. [Common Blocker Patterns](#6-common-blocker-patterns)
7. [Blocker Documentation Format](#7-blocker-documentation-format)
8. [Blocker Metrics and Health](#8-blocker-metrics-and-health)
9. [Scale-Aware Blocker Handling](#9-scale-aware-blocker-handling)
10. [Anti-Patterns](#10-anti-patterns)

---

## 1. Blocker Detection

A task is blocked when it cannot make forward progress. Detecting blockers early prevents wasted effort and keeps the execution loop moving.

### Blocker Categories

| Category | Signal | Example |
|----------|--------|---------|
| **Missing dependency** | A predecessor task is not `done` | Task 7 needs Task 4's output, but Task 4 is still `in-progress` |
| **Unclear specification** | Task spec is ambiguous, incomplete, or contradictory | "Implement the notification system" — what notifications? What channels? What triggers? |
| **External dependency** | Waiting for something outside the plan's control | Third-party API key not provisioned, staging environment not ready, design approval pending |
| **Technical blocker** | Implementation approach doesn't work | Chosen library has a breaking bug, architecture doesn't support the requirement, performance constraint can't be met |
| **Test failure** | Prerequisite tests are failing before task begins | CI is red from a previous task's regression, flaky tests blocking the suite |
| **Resource blocker** | Required expertise or access is unavailable | No one available with the domain knowledge, missing database credentials |
| **Scope ambiguity** | Task scope has grown beyond original estimate | "Add search" turned into "add full-text search with facets, autocomplete, and spell correction" |

### Detection Timing

Check for blockers at these points in the execution cycle:

| Point | What to Check |
|-------|--------------|
| **Before starting a task** | Are all dependencies `done`? Is the spec clear? Is the context loadable? |
| **During execution** | Is the approach working? Are tests passing? Is the scope as expected? |
| **During verification** | Can you answer the 5 questions? Are all tests green? |
| **During plan update** | Did execution reveal blockers for downstream tasks? |

### Early Detection Questions

Before starting any task, ask:

1. Are all dependency tasks marked `done` with passing verification?
2. Can I state the deliverable in one clear sentence?
3. Do I have access to all files, services, and credentials needed?
4. Is the test suite green before I start (no pre-existing failures)?
5. Has the task's estimated scope held, or has new information expanded it?

If any answer is "no," investigate before starting. An ounce of detection prevents a pound of wasted effort.

---

## 2. Blocker Handling Protocol

When a blocker is detected, follow this protocol exactly. Do not improvise.

### Step 1: Mark the Task as BLOCKED

Update the plan artifact immediately:

```markdown
| # | Task | Status | Expert | Dependencies | Verified By | Blocker |
|---|------|--------|--------|--------------|-------------|---------|
| 7 | Implement password reset | blocked | backend-architect | Task 4, Task 6 | — | B3: Email service API not returning tokens |
```

### Step 2: Document the Blocker

Add a blocker entry with full context:

```markdown
## Blocker: B3

**Task:** #7 — Implement password reset flow
**Detected:** 2024-01-20
**Type:** Technical
**Description:** EmailService.sendResetEmail() returns void instead of the message ID needed for tracking. The email service (Task 6) completion report doesn't mention message tracking.
**Impact:** Cannot implement email delivery confirmation or retry logic
**What Would Unblock It:** EmailService needs to return a message ID from the email provider. Requires modifying Task 6's implementation.
**Workaround Available:** Could implement without delivery tracking and add it later. Would leave a gap in the verification evidence.
```

### Step 3: Check for Other Unblocked Tasks

Do NOT stop working. Check the plan for other tasks that can proceed:

```
Remaining tasks in Implement gate:
- Task 7: BLOCKED (B3)
- Task 8: pending — dependencies met, not blocked → START THIS
- Task 9: pending — depends on Task 7 → CANNOT START
- Task 10: pending — no dependencies → CAN START AFTER Task 8
```

### Step 4: Work on the Next Unblocked Task

Switch to the next available unblocked task. The execution loop continues — a blocked task does not stop the whole plan.

### Step 5: Escalate if Nothing Else to Do

If all remaining tasks are blocked:

1. Produce a blocker summary report
2. Present it to the user with proposed resolutions
3. Wait for direction — do not guess past the blockers

**Critical rule: NEVER guess past a blocker. NEVER assume it will resolve itself.**

Guessing introduces silent errors. A task that proceeds past an unresolved blocker produces unverifiable output. The verification protocol will catch it, but by then effort has been wasted.

---

## 3. Blocker Types and Responses

Each blocker type has a different response strategy.

### Technical Blockers (Fixable)

The implementation approach doesn't work, but there's a path to resolution.

**Response protocol:**
1. Apply the debugging protocol: Reproduce, Isolate, Hypothesize, Test, Verify
2. Time-box the debugging: 15 minutes for initial investigation
3. If resolved: unblock the task, document the fix, continue
4. If not resolved in 15 minutes: escalate to a different specialist
5. If not resolved after specialist consultation: mark as blocked, document attempts

**Examples:**
- Library has a bug → find workaround or use alternative
- API returns unexpected format → adjust parsing or contact API owner
- Performance requirement not met → profile, optimize, or reconsider approach

### External Blockers (Wait)

Something outside the plan's control is preventing progress.

**Response protocol:**
1. Document the external dependency and who owns it
2. Set a clear "check back" time — when to re-evaluate
3. Skip to other tasks — keep the execution loop moving
4. If the external dependency has no timeline, escalate to user
5. Do NOT build workarounds that assume the external dependency will look a certain way

**Examples:**
- Third-party API key not provisioned → document, skip, check back in 24h
- Design approval pending → document, skip to non-design-dependent tasks
- Staging environment not ready → document, continue with local development

### Scope Blockers (Needs Decision)

The task scope has changed or is unclear, requiring a decision before proceeding.

**Response protocol:**
1. Identify the decision needed — what are the options?
2. Present options with tradeoffs to the user
3. Do NOT make scope decisions unilaterally — the user or orchestrator decides
4. Wait for direction before proceeding
5. Once decided, add to the decision log and update task scope

**Examples:**
- "Add search" could mean full-text search or basic filter → present both options
- Task scope grew from 2 hours to 2 days → needs re-estimation and possibly splitting
- Conflicting requirements discovered → needs stakeholder resolution

### Dependency Blockers (Ordering)

A task depends on another task that isn't done yet.

**Response protocol:**
1. Verify the dependency is real — can the task truly not proceed without it?
2. If the dependency is soft (nice-to-have context, not hard requirement):
   - Proceed with the task, note the missing context
   - Verify extra carefully at the end
3. If the dependency is hard (requires output from the other task):
   - Check if the dependency task can be prioritized
   - Check if tasks can be re-ordered to unblock
   - If neither: skip to other tasks, come back later
4. If circular dependency detected: escalate immediately (see Common Patterns)

**Dependency hardness test:**

| Question | Hard Dependency | Soft Dependency |
|----------|----------------|-----------------|
| Can I write ANY code without the dependency? | No | Yes, most of it |
| Would my output change based on the dependency's output? | Yes, fundamentally | Slightly, if at all |
| Can I stub/mock the dependency? | Not meaningfully | Yes, with reasonable assumptions |

---

## 4. Blocker Escalation

Escalation is not failure — it is the protocol working correctly. Blockers escalate when local resolution attempts fail.

### Escalation Levels

| Level | When | Action | Time Box |
|-------|------|--------|----------|
| **L1: Self-resolve** | First encounter with the blocker | Apply debugging protocol. Try the obvious fix. Check documentation. | 15 minutes |
| **L2: Debugging protocol** | L1 failed | Systematic debugging: reproduce, hypothesize, test one variable. | 30 minutes |
| **L3: Specialist escalation** | L2 failed | Bring in a different expert skill. The blocker may be outside the current expert's domain. | Until specialist responds |
| **L4: User escalation** | L3 failed or blocker is non-technical | Escalate to the user with full context: what's blocked, what was tried, what's needed. | Until user responds |

### Escalation Report Format

When escalating, provide:

```markdown
## Blocker Escalation: B{id}

**Task:** #{task_id} — {description}
**Blocker Type:** {Technical | External | Scope | Dependency}
**Escalation Level:** {L2 | L3 | L4}

### What's Blocked
{Clear description of what can't proceed}

### What Was Tried
1. {Attempt 1 — what was done, what happened}
2. {Attempt 2 — what was done, what happened}
3. {Attempt 3 — what was done, what happened}

### What's Needed
{Specific action or decision that would unblock this}

### Impact
- **Tasks blocked downstream:** {list of tasks that depend on this one}
- **Gate impact:** {does this block the gate transition?}
- **Timeline impact:** {estimated delay if not resolved}

### Proposed Resolution
{Your recommendation for how to resolve, with tradeoffs if multiple options exist}
```

### When NOT to Escalate

- The blocker is easily fixable with more effort — try harder first
- You haven't actually tried to resolve it — L1 is mandatory before L2
- The blocker is a scope decision you can make yourself (e.g., naming conventions)
- The test suite is flaky — fix the flakiness, don't escalate it as a blocker

---

## 5. Blocker Resolution

When a blocker is resolved — either through fixing, decision, or workaround — follow the resolution protocol.

### Resolution Steps

1. **Verify the resolution** — confirm the blocker is actually unresolved
   - If technical: run the code, confirm it works
   - If external: confirm the dependency is available
   - If scope: confirm the decision is documented
   - If dependency: confirm the dependency task is `done`

2. **Update the plan artifact**
   ```markdown
   ## Blocker: B3 — RESOLVED

   **Resolved:** 2024-01-21
   **Resolution:** Modified EmailService to return message ID. Task 6 updated and re-verified.
   **Impact on plan:** None — Task 7 can proceed as originally scoped.
   ```

3. **Unblock the task** — change status from `blocked` to `pending`

4. **Resume the task** — pick it up in the normal execution loop

5. **Check downstream** — are any other tasks that were waiting on this one now unblocked?

### Resolution Types

| Resolution Type | What Happened | Plan Impact |
|----------------|---------------|-------------|
| **Fixed** | The blocker was resolved directly | Minimal — task resumes as planned |
| **Workaround** | An alternative approach was found | Decision log entry explaining the workaround; risk register entry if it introduces tech debt |
| **Descoped** | The blocked work was removed from scope | Decision log entry; downstream tasks may need updating |
| **Deferred** | The blocked work was moved to a future gate or phase | Task moves to a later gate; dependency chain updated |
| **Accepted** | The risk was accepted and work proceeds despite the limitation | Risk register entry; verification step must note the limitation |

### Post-Resolution Verification

After resuming a previously blocked task, verify extra carefully:

1. Re-read the task spec — has anything changed while it was blocked?
2. Check if context has evolved — other tasks completed while this was blocked may affect it
3. Re-verify dependencies — are the dependency outputs still valid?
4. Proceed with normal execution cycle

---

## 6. Common Blocker Patterns

These patterns appear frequently. Recognize them early.

### Circular Dependencies

**Pattern:** Task A needs Task B's output, and Task B needs Task A's output.

**Detection:** Dependency graph has a cycle. Following the dependency chain leads back to the starting task.

**Resolution:**
1. Identify the shared interface between A and B
2. Extract the interface definition as a new Task 0 (no dependencies)
3. Both A and B depend on Task 0 instead of each other
4. Task 0: "Define the contract between A and B" — produces interface/schema/API contract
5. A and B implement against the contract independently

**Example:**
- Task A: "Implement order service" — needs payment service API
- Task B: "Implement payment service" — needs order model
- Task 0 (new): "Define order-payment API contract" — produces OpenAPI spec
- Task A implements against the spec
- Task B implements against the spec
- Neither blocks the other

### Unclear Acceptance Criteria

**Pattern:** The task says what to build but not what "done" looks like.

**Detection:** You cannot write a concrete test for the task because you don't know what to assert.

**Resolution:**
1. Draft acceptance criteria based on your understanding
2. Present to user for confirmation: "I'm interpreting this task as requiring X, Y, Z. Is that correct?"
3. Once confirmed, add the criteria to the plan artifact
4. Only then begin execution

**Rule:** Never start a task you can't write a test for. If you can't test it, you can't verify it.

### Missing Test Data

**Pattern:** Tests need specific data (database records, API responses, file fixtures) that doesn't exist.

**Detection:** Test setup requires data that hasn't been created or seeded.

**Resolution:**
1. Create test fixtures as part of the task (not a separate task)
2. Use factories or builders for test data generation
3. For integration tests: create seed scripts or test database setup
4. Document the test data approach in the task's verification report

### Environment Issues

**Pattern:** The development environment is missing something the task needs (database, service, tool).

**Detection:** Code works in concept but can't be tested because the environment is incomplete.

**Resolution:**
1. Check if the environment issue was supposed to be handled by a prior task
2. If yes: the prior task has a gap — create a remediation sub-task
3. If no: add environment setup as a prerequisite task
4. For CI: ensure the CI environment matches what the task needs

### Scope Creep During Execution

**Pattern:** While implementing, you discover the task is much larger than estimated.

**Detection:** You're on your 5th TDD cycle and the task is maybe half done. Or you've been working for 2x the estimated time.

**Resolution:**
1. Stop and assess — what's left to do?
2. Split the task: define what's done so far as Task A (mark done), create Task B for the remainder
3. Update the plan with the split — new task, new estimate, same gate
4. Add a decision log entry explaining the split
5. Continue with Task B or move to another task as appropriate

---

## 7. Blocker Documentation Format

### In the Plan Artifact

Blockers are tracked in the task table and in a dedicated blockers section.

**Task table notation:**
```markdown
| # | Task | Status | Blocker |
|---|------|--------|---------|
| 7 | Implement password reset | blocked | B3 |
```

**Blockers section:**
```markdown
## Active Blockers

| ID | Task | Type | Description | Detected | Status |
|----|------|------|-------------|----------|--------|
| B3 | #7 | Technical | EmailService missing message ID return | 2024-01-20 | Open |
| B4 | #9 | Dependency | Depends on blocked Task #7 | 2024-01-20 | Open |

## Resolved Blockers

| ID | Task | Type | Description | Detected | Resolved | Resolution |
|----|------|------|-------------|----------|----------|------------|
| B1 | #3 | External | Database credentials not provisioned | 2024-01-18 | 2024-01-18 | Provisioned by DevOps team |
| B2 | #5 | Scope | Unclear validation requirements | 2024-01-19 | 2024-01-19 | User confirmed: positive, max 2 decimals, max $999,999.99 |
```

---

## 8. Blocker Metrics and Health

Track blocker metrics to identify systemic issues:

| Metric | Healthy | Unhealthy | Action |
|--------|---------|-----------|--------|
| Blockers per gate | 0-2 | 3+ | Plan may need better dependency analysis |
| Average resolution time | < 1 day | > 2 days | Escalation may be too slow |
| Blockers caused by unclear specs | 0-1 | 2+ | Planning gate needs improvement |
| Blockers caused by technical issues | 0-1 | 3+ | Architecture may need review |
| Cascading blockers (one blocks many) | Rare | Frequent | Critical path not well managed |

### Health Check

At the end of each gate, review blocker metrics:

```markdown
## Blocker Health: {Gate Name}

**Total blockers encountered:** {N}
**Resolved:** {N}
**Still open:** {N}
**Average resolution time:** {duration}
**Root causes:**
- Unclear specs: {N}
- Technical: {N}
- Dependencies: {N}
- External: {N}

**Systemic issues identified:**
- {If spec blockers are frequent: planning gate needs more rigor}
- {If technical blockers are frequent: architecture review needed}
- {If dependency blockers are frequent: task ordering needs improvement}
```

---

## 9. Scale-Aware Blocker Handling

| Scale | Blocker Approach |
|-------|-----------------|
| **Startup** | Quick resolution. Most blockers are scope or technical — resolve them inline. Escalation is fast (talk to the person next to you). Don't over-document. |
| **Growth** | Structured documentation. Blockers start causing cascading delays. Track them in the plan artifact. Resolve within the session if possible, escalate by end of day. |
| **Scale** | Formal tracking. Blockers affect multiple teams. Resolution requires coordination. Assign owners to blockers. Daily blocker review in standup. |
| **Enterprise** | Audited tracking. Blockers have SLA for resolution. Escalation paths are documented. Blocker trends inform process improvement. |

---

## 10. Anti-Patterns

| Anti-Pattern | What Happens | Correct Approach |
|-------------|-------------|-----------------|
| **Guessing past the blocker** | Assume what the blocked dependency will produce and code against the assumption | NEVER. Wait for the dependency or get confirmation |
| **Blocker denial** | "It's not really blocked, I'll figure it out" — then spend hours stuck | If forward progress stops for 15 minutes, it's a blocker. Mark it. |
| **Blocker hoarding** | Mark tasks as blocked but don't document why or try to resolve | Document immediately. Try L1 resolution immediately. |
| **Escalation avoidance** | "I don't want to bother anyone" — stay stuck for hours | Escalation is the protocol working. Escalate at the right level. |
| **Heroic resolution** | Spend 4 hours resolving a blocker that should have been escalated at 30 minutes | Follow the time boxes. L1 = 15 min, L2 = 30 min. |
| **Silent unblocking** | Blocker resolves but plan isn't updated | Always update the plan when a blocker resolves. |
| **Workaround without documentation** | Implement a workaround but don't note it anywhere | Decision log entry + risk register entry for every workaround. |
