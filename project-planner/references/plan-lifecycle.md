# Plan Lifecycle — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Plan Artifact Format Specification](#1-plan-artifact-format-specification)
2. [Plan Creation Workflow](#2-plan-creation-workflow)
3. [Plan Update Patterns](#3-plan-update-patterns)
4. [Claude Plan Mode Integration](#4-claude-plan-mode-integration)
5. [Gate Readiness Assessment Methodology](#5-gate-readiness-assessment-methodology)
6. [Progress Tracking Metrics](#6-progress-tracking-metrics)
7. [Risk Escalation Criteria and Process](#7-risk-escalation-criteria-and-process)
8. [Plan Templates](#8-plan-templates)
9. [Good vs Bad Plans](#9-good-vs-bad-plans)

---

## 1. Plan Artifact Format Specification

### File Location and Naming

Plan artifacts live at:

```
.etyb/plans/{plan-name}.md
```

**Naming rules:**
- Lowercase, hyphenated, descriptive of the work being done
- No dates in filenames — dates are tracked in metadata
- Use the project or feature name, not the ticket number
- Maximum 50 characters

**Good names:**
- `user-auth-migration.md`
- `payment-gateway-integration.md`
- `api-v2-redesign.md`
- `multi-tenant-isolation.md`

**Bad names:**
- `plan.md` (not descriptive)
- `JIRA-1234.md` (ticket number, not the work)
- `sprint-42-work.md` (temporal, not descriptive)
- `johns-project.md` (person, not the work)

### Metadata Block

Every plan artifact starts with a metadata section:

```markdown
## Metadata
- **Created:** {YYYY-MM-DD}
- **Last Updated:** {YYYY-MM-DD}
- **Tier:** {3 or 4}
- **Scale:** {Startup | Growth | Scale | Enterprise}
- **Status:** {Draft | Active | Blocked | Complete | Abandoned}
- **Owner:** {Primary orchestrating skill}
- **Domain:** {If applicable — e-commerce, fintech, healthcare, etc.}
```

**Status lifecycle:**

```
Draft → Active → Complete
         ↓  ↑
       Blocked
         
Draft → Abandoned
Active → Abandoned
```

| Status | Meaning | Who Sets It |
|--------|---------|-------------|
| **Draft** | Plan skeleton created, not yet populated with tasks | `orchestrator` creates, `project-planner` transitions to Active after population |
| **Active** | Work is in progress across one or more gates | `project-planner` or `orchestrator` |
| **Blocked** | Work stopped due to unresolved issues — requires intervention | Any expert who encounters a blocker |
| **Complete** | All gates passed, work shipped and verified | `orchestrator` after Ship gate passes |
| **Abandoned** | Work intentionally stopped — reason must be logged in Decision Log | `orchestrator` with user agreement |

### Context Section

The Context section provides the "why" behind the plan:

```markdown
## Context
{1-3 sentences: what problem this plan solves and why it matters now.
Include the key constraint or driver — deadline, compliance requirement,
user feedback, technical debt limit reached, etc.}
```

**Good context:**
> We need to migrate from cookie-based sessions to JWT tokens before the mobile app launch on 2026-06-01. The mobile team cannot use cookies, and the API must serve both web and mobile clients with a unified auth mechanism.

**Bad context:**
> We need to update the auth system. (Why? When? What's driving this?)

### Phase Gates Table

```markdown
## Phase Gates

| Gate | Status | Entry Date | Exit Date | Blocking Issues |
|------|--------|------------|-----------|-----------------|
| Design | {not-started / in-progress / passed / failed} | | | |
| Plan | {not-started / in-progress / passed / failed} | | | |
| Implement | {not-started / in-progress / passed / failed} | | | |
| Verify | {not-started / in-progress / passed / failed} | | | |
| Ship | {not-started / in-progress / passed / failed} | | | |
```

**Status progression:**

```
not-started → in-progress → passed
                           ↘ failed → in-progress → passed
```

**Rules:**
- Only one gate should be `in-progress` at a time (except collapsed gates at startup scale)
- `not-started` gates cannot have entry dates
- `passed` gates must have both entry and exit dates
- `failed` gates must have a Blocking Issues entry explaining the failure
- The Blocking Issues column references specific task IDs or risk IDs

### Task Breakdown Tables

Each phase has its own task breakdown table:

```markdown
### Phase: {Phase Name}
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| {prefix}{N} | {Clear, actionable task description} | {skill-name} | {status} | {What this task produces} | {skill-name that checks it} |
```

**Task ID prefixes:**

| Prefix | Phase |
|--------|-------|
| D | Design |
| P | Plan |
| I | Implement |
| V | Verify |
| S | Ship |

**Task status values:**

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in-progress` | Actively being worked on |
| `done` | Completed and verified |
| `blocked` | Cannot proceed — dependency or issue |
| `dropped` | Removed from scope (must have Decision Log entry) |

**Task naming rules:**
- Start with a verb: "Define", "Implement", "Test", "Deploy", "Review", "Document"
- Be specific: "Implement order creation endpoint with validation" not "Do backend work"
- Include scope: "Write unit tests for payment service" not "Write tests"
- Keep under 80 characters

**Multi-expert tasks:**
When a task requires collaboration, designate a lead and supporting expert(s):

```markdown
| I3 | Implement payment webhook handler | `backend-architect` (lead), `security-engineer` (support) | in-progress | Webhook endpoint with signature verification | `qa-engineer` |
```

### Decision Log

```markdown
## Decision Log
| # | Date | Decision | Options Considered | Rationale | Decided By |
|---|------|----------|-------------------|-----------|------------|
```

**When to add an entry:**
- Architecture choice made (technology, pattern, approach)
- Scope change (feature added, removed, or modified)
- Non-functional requirement set (SLA, performance target)
- Security model selection
- Significant tradeoff accepted

**When NOT to add an entry:**
- Standard implementation details (variable names, code formatting)
- Test organization choices
- Build tool configuration
- Obvious, non-contentious choices

### Risk Register

```markdown
## Risk Register
| # | Risk | Probability | Impact | Mitigation | Owner | Status |
|---|------|------------|--------|------------|-------|--------|
```

**Probability:** Low (<20%), Medium (20-60%), High (>60%)
**Impact:** Low (hours delay), Medium (days delay), High (weeks delay or critical incident)
**Status:** `open`, `mitigating`, `mitigated`, `occurred`, `closed`

> **Reference:** See `orchestrator/references/process-architecture.md` §6 for the full risk assessment framework, priority matrix, and domain-specific risk templates.

---

## 2. Plan Creation Workflow

### Step-by-Step: From Orchestrator Handoff to Complete Plan

The orchestrator creates the plan skeleton. You fill it with substance. Here is the exact workflow:

### Step 1: Receive the Skeleton

The orchestrator provides:
- Tier classification (3 or 4)
- Scale classification (Startup / Growth / Scale / Enterprise)
- Domain (if applicable)
- Initial context statement
- Mandatory experts identified from process-architecture rules
- Architecture artifacts from the Design gate (if Design has already passed)

### Step 2: Read the Context

Before writing a single task:
1. Read the plan's Context section — understand what's being built and why
2. Read any architecture artifacts produced during the Design gate
3. Read the Decision Log — understand decisions already made
4. Identify the scope boundaries — what's in, what's explicitly out

### Step 3: Break Down Phases into Tasks

For each phase (Design, Plan, Implement, Verify, Ship):

1. **Identify all concrete deliverables** — what must exist when this phase is done
2. **Decompose deliverables into tasks** — each task should be completable in 1-3 days
3. **Apply vertical slicing** — tasks should be thin end-to-end slices, not horizontal layers (see `references/sprint-planner.md` §1)
4. **Name tasks clearly** — start with a verb, be specific, include scope

**Task quantity guidelines by tier:**

| Phase | Tier 3 Tasks | Tier 4 Tasks |
|-------|-------------|-------------|
| Design | 2-5 | 5-10 |
| Plan | 2-4 | 4-8 |
| Implement | 5-10 | 10-25 |
| Verify | 3-6 | 6-12 |
| Ship | 2-4 | 4-8 |
| **Total** | **14-29** | **29-63** |

### Step 4: Estimate Effort

Apply the estimation method appropriate for the team's context:

| Scale | Recommended Method | Rationale |
|-------|-------------------|-----------|
| Startup | T-shirt sizes (S/M/L/XL) or no estimate | Speed over precision. Small team knows the codebase. |
| Growth | Story points (Fibonacci) or bucket sizing | Team needs shared language for capacity planning. |
| Scale | Hour ranges with confidence intervals | Multiple teams need concrete capacity planning. |
| Enterprise | PERT three-point estimates | Stakeholder reporting requires quantified uncertainty. |

**Estimation rules:**
- Never estimate a task you don't understand — spike first
- No task should be larger than XL / 13 points / 5 days — split it
- Include testing effort in every implementation task estimate
- Add 15-30% buffer for integration and unexpected issues at Tier 4

### Step 5: Map Dependencies

For each task, identify:
1. **Hard dependencies** — must be done before this task can start (blocks)
2. **Soft dependencies** — would benefit from being done first but not strictly blocking
3. **Critical path** — the longest chain of hard dependencies determines minimum timeline

Mark dependencies in the task table or in a separate dependency section:

```markdown
### Dependencies
- I1 → I3 (API contract must exist before frontend can consume it)
- I2 → I4 (database schema must be migrated before data access layer)
- D1 → all I-tasks (architecture must be finalized before implementation)
```

### Step 6: Assign Experts

For each task, assign:
1. **Assigned Expert** — the skill that does the work
2. **Verified By** — the skill that checks the work (never the same as Assigned for critical tasks)

Follow the orchestrator's expert assignment conventions:

| Work Type | Assigned To | Verified By |
|-----------|------------|-------------|
| Architecture | `system-architect` | `code-reviewer` or domain architect |
| Frontend code | `frontend-architect` | `qa-engineer` + `code-reviewer` |
| Backend code | `backend-architect` | `qa-engineer` + `code-reviewer` |
| Database changes | `database-architect` | `backend-architect` + `security-engineer` |
| Security concerns | `security-engineer` | `code-reviewer` |
| Infrastructure | `devops-engineer` | `sre-engineer` |
| Documentation | `technical-writer` | Assigned domain expert |

**Mandatory experts** (from orchestrator's rules) are non-negotiable assignments. If the orchestrator mandated `security-engineer` at the Design gate, they must be assigned to relevant Design tasks.

### Step 7: Populate the Risk Register

Identify risks using these sources:
1. **Domain-specific risk templates** from `orchestrator/references/process-architecture.md` §6
2. **Dependency risks** — external APIs, third-party services, team availability
3. **Technical risks** — unfamiliar technology, complex migrations, performance unknowns
4. **Scope risks** — unclear requirements, shifting priorities
5. **Timeline risks** — deadlines, dependencies on other teams

**Minimum risks by tier:**

| Tier | Minimum Risks |
|------|--------------|
| Tier 3 | 3 risks |
| Tier 4 | 5-10 risks |

### Step 8: Define Milestones

Set milestones that align with gate boundaries:

```markdown
### Milestones
| Milestone | Target Date | Gate Alignment | Criteria |
|-----------|------------|----------------|----------|
| Architecture approved | {date} | Design gate pass | All Design exit criteria met |
| Plan reviewed | {date} | Plan gate pass | All tasks estimated and assigned |
| Core implementation complete | {date} | Implement gate pass | All I-tasks done, unit tests passing |
| Quality verified | {date} | Verify gate pass | All tests passing, reviews complete |
| Production deployment | {date} | Ship gate pass | Deployed, monitored, stable |
```

For Tier 4 plans, add interim milestones within phases (e.g., "API layer complete", "Database migration tested").

### Step 9: Return the Populated Plan

Once all sections are filled:
1. Set the plan Status to `Active`
2. Set the first appropriate gate to `in-progress` with an entry date
3. Produce the Plan Population Complete summary (see SKILL.md Response Format)
4. The orchestrator reviews your work against gate requirements

---

## 3. Plan Update Patterns

### Update Triggers

The plan is a living document. It changes whenever the project reality changes.

| Trigger | Who Initiates | What Changes |
|---------|--------------|-------------|
| Task completed | Assigned expert | Task status → `done`, Verified By signs off |
| New task discovered | `project-planner` or any expert | New row added to task breakdown, estimate provided |
| Estimate revised | `project-planner` | Effort column updated, Decision Log entry if variance > 50% |
| Dependency changed | `project-planner` | Dependency column updated, critical path reassessed |
| Risk materialized | Any expert | Risk status → `occurred`, mitigation activated |
| Risk identified | Any expert | New Risk Register entry |
| Scope change | `orchestrator` + `project-planner` | Tasks added/removed, Decision Log entry, milestone impact assessed |
| Blocker found | Affected expert | Task status → `blocked`, Blocking Issues column updated |
| Gate transition | `orchestrator` | Gate status updated, entry/exit dates set |
| Sprint boundary | `project-planner` | Progress snapshot, velocity update, forecast revision |

### How to Update Without Disrupting Flow

Plan updates should be **lightweight and atomic** — change what needs to change, nothing more:

1. **Task status update:** Change one cell in the task table. No ceremony needed.
2. **New task discovered:** Add a row to the correct phase table. Estimate if possible, mark `pending`.
3. **Estimate revision:** Update the effort cell. If the revision is significant (>50% change), add a Decision Log entry explaining why.
4. **Scope change:** This is the only update that requires coordination with the `orchestrator`. Add/remove tasks, add a Decision Log entry, reassess milestones.

### Update Frequency

| Plan Element | Update Frequency |
|-------------|-----------------|
| Task status | As it changes (real-time) |
| Risk register | At every gate transition + when new risks emerge |
| Decision log | When decisions are made (not retroactively) |
| Milestones | When scope or estimates change significantly |
| Phase gates | At gate transitions only |

### Avoiding Plan Staleness

A stale plan is worse than no plan — it creates false confidence. Watch for these signals:

| Staleness Signal | Action |
|-----------------|--------|
| Last Updated date > 5 days old during active work | Review and update immediately |
| Tasks in `in-progress` for > 1 sprint with no updates | Check with assigned expert — is work actually happening? |
| Risk register unchanged since Plan gate | Review risks — has reality changed? |
| Decision Log has no entries during Implement phase | Are decisions being made without documentation? |
| Milestones passed without gate status updates | Sync plan with actual state |

---

## 4. Claude Plan Mode Integration

### Detection

Claude Code has a built-in plan mode that creates plan files in `.claude/plans/`. When active, you annotate Claude's plan rather than creating a separate `.etyb/plans/` file.

**Detection signals (check in order):**
1. Claude explicitly states it is in plan mode
2. The conversation context shows plan mode was entered
3. A plan file exists in `.claude/plans/`

If **any** signal is detected → annotate Claude's plan
If **no** signals detected → create `.etyb/plans/` artifact

### Annotating a Claude Plan

When Claude plan mode is active, add process architecture sections as annotations within the Claude plan:

```markdown
## Process Architecture Annotations

### Gate Status
| Gate | Status | Notes |
|------|--------|-------|
| Design | passed | Architecture reviewed by system-architect |
| Plan | in-progress | Task breakdown 80% complete |
| Implement | not-started | |
| Verify | not-started | |
| Ship | not-started | |

### Expert Assignments
- `security-engineer`: mandatory (auth change) — Design, Verify
- `qa-engineer`: mandatory (code-producing task) — Plan
- `backend-architect`: lead implementer — Implement
- `code-reviewer`: mandatory (Tier 3+) — Ship

### Task Breakdown
{Use the same table format as .etyb/plans/ artifacts}

### Decision Log
{Use the same format}

### Risk Register
{Use the same format}
```

### Mapping Gate Status to Plan Checkboxes

Claude plan mode uses checkboxes (`- [ ]` / `- [x]`). Map gate concepts to checkboxes:

```markdown
## Implementation Plan

- [x] Design phase
  - [x] Define architecture (system-architect) ← Gate: Design
  - [x] Security threat model (security-engineer)
  - [x] API contract definition
- [ ] Plan phase ← Gate: Plan (in-progress)
  - [x] Task breakdown complete
  - [ ] Effort estimates finalized
  - [ ] Test strategy defined (qa-engineer)
- [ ] Implementation phase ← Gate: Implement (not-started)
  - [ ] Backend API implementation
  - [ ] Frontend integration
  - [ ] Database migration
- [ ] Verification ← Gate: Verify (not-started)
  - [ ] Integration tests
  - [ ] Code review
  - [ ] Security review
- [ ] Ship ← Gate: Ship (not-started)
  - [ ] Staging deployment
  - [ ] Production deployment
```

### Dual Plan Resolution

If both a Claude plan and `.etyb/plans/` artifact exist:

| Situation | Action |
|-----------|--------|
| Claude plan is canonical | Merge `.etyb/plans/` content into Claude plan annotations, delete `.etyb/plans/` file |
| `.etyb/plans/` created before Claude plan mode | Migrate key content to Claude plan annotations, keep `.etyb/plans/` as archive |
| User explicitly wants `.etyb/plans/` | Honor user preference, add a note in Claude plan pointing to `.etyb/plans/` file |

---

## 5. Gate Readiness Assessment Methodology

### Assessment Process

Before any gate transition, the `project-planner` produces a gate readiness report. This is the evidence the `orchestrator` uses to pass or fail the gate.

### Step 1: Gather Evidence

For each exit criterion of the current gate (from `orchestrator/references/process-architecture.md` §9-13):

1. **Check the artifact** — does it exist? Is it complete?
2. **Check the sign-off** — has the mandatory expert reviewed and approved?
3. **Check the verification** — has the verification protocol been followed?

### Step 2: Assess Each Criterion

| Assessment | Meaning | Action |
|-----------|---------|--------|
| **Met** | Criterion fully satisfied with evidence | No action needed |
| **Partially met** | Work done but incomplete or unverified | Identify what's remaining |
| **Not met** | No work done or work insufficient | Flag as blocker |

### Step 3: Produce the Report

Use the Gate Readiness Assessment template from the SKILL.md Response Format section.

### Gate-Specific Checklists

#### Design Gate Readiness

```markdown
- [ ] Requirements documented and unambiguous
- [ ] Architecture diagram covers all major components
- [ ] API contracts defined at interface level
- [ ] Data model documented (if data-intensive)
- [ ] Security threat model completed (if auth/data/API change)
- [ ] Non-functional requirements specified
- [ ] Cross-cutting concerns addressed (logging, monitoring, error handling)
- [ ] Scale-appropriate complexity validated
- [ ] Domain architect reviewed (if domain-specific)
- [ ] `security-engineer` reviewed (if mandatory)
- [ ] All Design-phase tasks marked `done`
- [ ] All Decision Log entries from Design phase recorded
```

#### Plan Gate Readiness

```markdown
- [ ] All implementation tasks identified and assigned
- [ ] Task dependencies mapped
- [ ] Effort estimates provided per task
- [ ] Test strategy defined by `qa-engineer`
- [ ] Risk register populated with top risks
- [ ] Decision log captures all choices made so far
- [ ] `security-engineer` approved security approach (if applicable)
- [ ] Infrastructure requirements specified (if applicable)
- [ ] Rollback strategy defined for high-risk changes
- [ ] All Plan-phase tasks marked `done`
- [ ] Milestones set and aligned with gate boundaries
```

#### Implement Gate Readiness

```markdown
- [ ] All implementation tasks completed
- [ ] Code compiles/builds without errors
- [ ] Unit tests written and passing
- [ ] Code follows project conventions (lint, format, types)
- [ ] No new SAST/SCA findings (or justified exceptions)
- [ ] Database migrations tested (if applicable)
- [ ] API implementation matches design contract
- [ ] Error handling covers identified edge cases
- [ ] Logging added for debugging and observability
- [ ] Feature flags configured (if applicable)
```

#### Verify Gate Readiness

```markdown
- [ ] Integration tests passing
- [ ] E2E tests covering critical user journeys
- [ ] Performance tests meeting SLA targets (if applicable)
- [ ] Security review completed by `security-engineer`
- [ ] Code review completed by `code-reviewer`
- [ ] Accessibility requirements met (if frontend)
- [ ] Documentation reviewed by `technical-writer` (if user-facing)
- [ ] Load testing results acceptable (if applicable)
- [ ] Rollback procedure tested
```

#### Ship Gate Readiness

```markdown
- [ ] Staging deployment successful
- [ ] Smoke tests passing in staging
- [ ] Monitoring and alerting configured
- [ ] Runbook created or updated
- [ ] Stakeholders notified of deployment plan
- [ ] Feature flags configured for rollout strategy
- [ ] Production deployment successful
- [ ] Post-deployment smoke tests passing
- [ ] Canary metrics healthy (if canary deployment)
```

---

## 6. Progress Tracking Metrics

### Core Metrics

Track these metrics throughout the plan lifecycle:

| Metric | Formula | What It Tells You |
|--------|---------|-------------------|
| **Task completion rate** | Completed tasks / Total tasks × 100 | Overall progress |
| **Phase completion rate** | Completed tasks in phase / Total tasks in phase × 100 | Phase-level progress |
| **Estimate accuracy** | Actual effort / Estimated effort | Estimation calibration |
| **Blocker count** | Tasks with `blocked` status | Health of the plan execution |
| **Risk exposure** | Count of P1/P2 open risks | Unaddressed danger level |
| **Gate velocity** | Calendar days per gate transition | Process efficiency |
| **Decision density** | Decision Log entries / Calendar weeks | Decision-making pace |

### Progress Dashboard Template

At any point, you should be able to produce this snapshot:

```markdown
## Plan Progress — {Plan Name} — {Date}

### Overall
- **Status:** {Active / Blocked}
- **Current Gate:** {gate} — {in-progress / etc.}
- **Days since plan creation:** {N}
- **Estimated completion:** {date or "TBD"}

### Task Progress
| Phase | Total | Done | In Progress | Blocked | Pending |
|-------|-------|------|-------------|---------|---------|
| Design | {N} | {N} | {N} | {N} | {N} |
| Plan | {N} | {N} | {N} | {N} | {N} |
| Implement | {N} | {N} | {N} | {N} | {N} |
| Verify | {N} | {N} | {N} | {N} | {N} |
| Ship | {N} | {N} | {N} | {N} | {N} |

### Estimates vs Actuals
- **Original total estimate:** {X}
- **Current total estimate:** {Y} ({variance}%)
- **Completed effort:** {Z}
- **Remaining effort:** {W}

### Health Indicators
- **Open P1/P2 risks:** {N}
- **Active blockers:** {N}
- **Decisions pending:** {N}
- **Expert sign-offs pending:** {N}
```

### When to Recalibrate Estimates

| Signal | Action |
|--------|--------|
| 3+ tasks exceed estimate by > 50% | Recalibrate all remaining estimates using actual data |
| Critical path task is blocked | Reassess milestone dates |
| Scope change adds > 20% new tasks | Full re-estimation with new baseline |
| Expert availability changes | Adjust timeline for affected tasks |

---

## 7. Risk Escalation Criteria and Process

### When to Escalate

Escalate to the `orchestrator` when any of these conditions are met:

| Condition | Escalation Priority |
|-----------|-------------------|
| P1 risk with no viable mitigation | Immediate |
| Blocker persisting > 1 sprint cycle | High |
| Scope change that would move the project to a higher tier | High |
| Expert availability blocking a gate transition | High |
| Estimates drifted > 150% of original forecast | Medium |
| 3+ risks materialized in current phase | Medium |
| User requirements changed significantly | Medium |
| External dependency failed or delayed | Depends on impact |

### Escalation Process

1. **Document the issue** — clear, specific description in the plan artifact
2. **Assess impact** — what gates, tasks, and milestones are affected
3. **Propose options** — 2-3 possible actions with tradeoffs
4. **Produce the Risk Escalation report** (see SKILL.md Response Format)
5. **Wait for orchestrator decision** — do not proceed past the affected gate

### Escalation Response Expectations

| Priority | Expected Response Time |
|----------|----------------------|
| Immediate | Same interaction — orchestrator must decide before work continues |
| High | Within 1 sprint — may proceed with workaround if available |
| Medium | Next gate transition — reassess when gate readiness is evaluated |

---

## 8. Plan Templates

### Tier 3 Lightweight Plan — Filled Example

```markdown
# Plan: Add Real-Time Notifications

## Metadata
- **Created:** 2026-04-15
- **Last Updated:** 2026-04-15
- **Tier:** 3
- **Scale:** Growth
- **Status:** Active
- **Owner:** orchestrator
- **Domain:** —

## Context
Users currently have no way to know when they receive a message or comment
without manually refreshing. We need real-time push notifications via WebSocket
to reduce time-to-awareness from minutes to seconds.

## Phase Gates

| Gate | Status | Entry Date | Exit Date | Blocking Issues |
|------|--------|------------|-----------|-----------------|
| Design | passed | 2026-04-15 | 2026-04-15 | |
| Plan | in-progress | 2026-04-15 | | |
| Implement | not-started | | | |
| Verify | not-started | | | |
| Ship | not-started | | | |

## Task Breakdown

### Phase: Design
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| D1 | Define WebSocket API contract | `system-architect` | done | WebSocket event schema | `backend-architect` |
| D2 | Select notification delivery approach | `real-time-architect` | done | Decision: WebSocket with Redis Pub/Sub | `system-architect` |

### Phase: Plan
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| P1 | Break down implementation tasks | `project-planner` | done | Task breakdown (below) | `orchestrator` |
| P2 | Define test strategy for real-time features | `qa-engineer` | in-progress | Test strategy document | `project-planner` |

### Phase: Implement
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| I1 | Implement WebSocket server with Redis Pub/Sub | `backend-architect` | pending | WebSocket server + unit tests | `qa-engineer` |
| I2 | Implement notification event publishing | `backend-architect` | pending | Event publisher service | `qa-engineer` |
| I3 | Implement frontend notification listener | `frontend-architect` | pending | React notification component | `qa-engineer` |
| I4 | Add notification preferences API | `backend-architect` | pending | REST endpoint + database schema | `qa-engineer` |

### Phase: Verify
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| V1 | Integration test WebSocket connection lifecycle | `qa-engineer` | pending | Passing test suite | `backend-architect` |
| V2 | Load test concurrent WebSocket connections | `qa-engineer` | pending | Load test report (target: 10K concurrent) | `sre-engineer` |
| V3 | Code review all notification code | `code-reviewer` | pending | Review approval | `backend-architect` |

### Phase: Ship
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| S1 | Deploy to staging with feature flag | `devops-engineer` | pending | Staging deployment | `sre-engineer` |
| S2 | Production deployment with 10% canary | `devops-engineer` | pending | Canary deployment | `sre-engineer` |

## Decision Log
| # | Date | Decision | Options Considered | Rationale | Decided By |
|---|------|----------|-------------------|-----------|------------|
| 1 | 2026-04-15 | Use WebSocket with Redis Pub/Sub | (A) SSE, (B) WebSocket + Redis, (C) Polling | WebSocket gives bidirectional comms for future features. Redis Pub/Sub scales across server instances. SSE insufficient for our use case. | `real-time-architect` |

## Risk Register
| # | Risk | Probability | Impact | Mitigation | Owner | Status |
|---|------|------------|--------|------------|-------|--------|
| R1 | WebSocket connections overwhelm server under load | Medium | High | Redis Pub/Sub distributes load; add connection limits per user | `sre-engineer` | open |
| R2 | Browser compatibility issues with WebSocket API | Low | Medium | Fallback to SSE for unsupported browsers | `frontend-architect` | open |
| R3 | Notification spam if event publishing is too aggressive | Medium | Low | Implement rate limiting and notification batching | `backend-architect` | open |
```

### Tier 4 Full Plan — Filled Example

A Tier 4 plan follows the same structure but with:
- **More tasks:** 30-60+ total across all phases
- **More detailed estimates:** Per-task with confidence ranges
- **More risks:** 5-10 with detailed mitigations
- **More decisions:** 5-15 covering all major architectural choices
- **Verification detail:** Per-task verification notes, not just per-phase
- **Milestones section:** Added between Phase Gates and Task Breakdown

```markdown
### Milestones
| Milestone | Target Date | Gate Alignment | Criteria |
|-----------|------------|----------------|----------|
| Architecture approved | 2026-04-18 | Design gate pass | All Design exit criteria met |
| Plan finalized | 2026-04-22 | Plan gate pass | All tasks estimated, test strategy defined |
| API layer complete | 2026-05-02 | Implement interim | All backend API endpoints implemented and unit-tested |
| Frontend integration complete | 2026-05-09 | Implement interim | All frontend components consuming APIs |
| Quality verified | 2026-05-14 | Verify gate pass | All tests passing, reviews complete |
| Production launch | 2026-05-16 | Ship gate pass | Deployed, monitored, stable |
```

The full Tier 4 template extends the Tier 3 example with these additional sections — it does not use a fundamentally different format. The same tables, the same status values, the same conventions. The difference is depth, not structure.

---

## 9. Good vs Bad Plans

### Characteristics of Good Plans

| Characteristic | What It Looks Like |
|---------------|-------------------|
| **Specific tasks** | "Implement order creation endpoint with request validation and error handling" |
| **Clear ownership** | Every task has exactly one assigned expert and one verifier |
| **Realistic estimates** | Based on team velocity data or analogous past work, with buffer |
| **Mapped dependencies** | Critical path identified, parallel tracks marked |
| **Living document** | Last Updated date is within the current sprint |
| **Honest risk register** | Risks reflect reality, not optimism. Includes "we don't know" risks |
| **Decision rationale** | Every Decision Log entry explains *why*, not just *what* |
| **Scale-appropriate** | Startup plans are lean. Enterprise plans are thorough. Neither pretends to be the other |

### Characteristics of Bad Plans

| Anti-Pattern | What It Looks Like | Why It's Harmful |
|-------------|-------------------|-----------------|
| **Vague tasks** | "Do backend work" | Can't estimate, can't verify, can't assign |
| **Missing ownership** | Tasks with no Assigned Expert | Nobody is responsible, nobody will do it |
| **Fantasy estimates** | Every task is "1 day" regardless of complexity | Creates false confidence, guarantees missed deadlines |
| **No dependencies** | All tasks shown as independent | Parallel work collides, blockers surprise everyone |
| **Write-once plan** | Last Updated date is the creation date | Plan diverges from reality immediately |
| **Empty risk register** | "No risks identified" | Either the project is trivial (shouldn't have a plan) or risks are being ignored |
| **Decision amnesia** | Empty Decision Log during active implementation | Decisions are being made verbally, not documented, and will be forgotten |
| **Scope creep without trace** | New tasks appear with no Decision Log entry | Why did scope change? Who decided? What was traded off? |
| **Over-engineering** | Tier 3 plan with 60 tasks and 15 risks for a single feature | Process overhead exceeds the value of the change |
| **Under-engineering** | Tier 4 plan with 8 tasks and no risk register for a platform migration | Critical work getting insufficient rigor |

### Common Plan Failure Modes

| Failure Mode | Root Cause | Prevention |
|-------------|-----------|------------|
| Plan abandoned mid-project | Too heavy for the tier, or team never bought in | Match plan depth to tier. Get team agreement on process at kickoff |
| Plan contradicts reality | Not updated as work progresses | Update task status as it changes. Review plan at every gate |
| Estimation consistently wrong | Using gut feel instead of data | Track actuals. Calibrate estimates against historical velocity |
| Gate transitions are rubber stamps | No one actually checks exit criteria | Produce gate readiness reports. Orchestrator enforces |
| Experts assigned but never consulted | Expert assignment is ceremonial | Expert continuity protocol — experts verify at every relevant gate |
| Risk register is fiction | Filled once at plan creation, never updated | Review risks at every gate transition. Update when reality changes |
