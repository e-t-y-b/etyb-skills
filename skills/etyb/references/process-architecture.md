# Process Architecture — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Plan Artifact Format](#1-plan-artifact-format)
2. [Plan Artifact Metadata](#2-plan-artifact-metadata)
3. [Phase Gates and Status Tracking](#3-phase-gates-and-status-tracking)
4. [Task Breakdown and Expert Assignments](#4-task-breakdown-and-expert-assignments)
5. [Decision Log](#5-decision-log)
6. [Risk Register](#6-risk-register)
7. [Verification Checklist per Phase](#7-verification-checklist-per-phase)
8. [Claude Plan Mode Integration](#8-claude-plan-mode-integration)
9. [Gate Definitions — Design](#9-gate-definitions--design)
10. [Gate Definitions — Plan](#10-gate-definitions--plan)
11. [Gate Definitions — Implement](#11-gate-definitions--implement)
12. [Gate Definitions — Verify](#12-gate-definitions--verify)
13. [Gate Definitions — Ship](#13-gate-definitions--ship)
14. [Gate Scale Calibration](#14-gate-scale-calibration)
15. [Expert Mandating Rules](#15-expert-mandating-rules)
16. [Expert Continuity Protocol](#16-expert-continuity-protocol)
17. [Coordination Patterns with Gate Checkpoints](#17-coordination-patterns-with-gate-checkpoints)
18. [Plan Lifecycle Management](#18-plan-lifecycle-management)
19. [Cross-Skill Integration Points](#19-cross-skill-integration-points)
20. [Process Anti-Patterns](#20-process-anti-patterns)
21. [Process Protocol Integration](#21-process-protocol-integration)

---

## 1. Plan Artifact Format

Every non-trivial task tracked by ETYB produces a **plan artifact** — a living document that captures intent, decisions, assignments, risks, and verification status across the project lifecycle.

### File Location

```
.etyb/plans/{plan-name}.md
```

**Naming convention:** lowercase, hyphenated, descriptive. Examples:
- `.etyb/plans/user-auth-migration.md`
- `.etyb/plans/payment-gateway-integration.md`
- `.etyb/plans/api-v2-redesign.md`
- `.etyb/plans/database-sharding-rollout.md`

### When to Create a Plan Artifact

| Scenario | Create Plan? | Rationale |
|----------|-------------|-----------|
| Tier 1 — Single specialist, simple task | No | Overhead exceeds value |
| Tier 2 — Incident response | No | Speed-first, post-incident review instead |
| Tier 3 — Focused multi-team (2-3 skills) | Yes | Coordination needs tracking |
| Tier 4 — Full project (4+ skills) | Yes | Complex work requires formal gates |
| Any task touching auth, payments, or PII | Yes | Compliance and security traceability |
| Any task with external deadlines | Yes | Risk management and stakeholder communication |

### Complete Plan Artifact Template

```markdown
# Plan: {Plan Name}

## Metadata
- **Created:** {YYYY-MM-DD}
- **Last Updated:** {YYYY-MM-DD}
- **Tier:** {3 or 4}
- **Scale:** {Startup | Growth | Scale | Enterprise}
- **Status:** {Draft | Active | Blocked | Complete | Abandoned}
- **Owner:** {Primary orchestrating skill}
- **Domain:** {If applicable — e-commerce, fintech, healthcare, etc.}

## Context
{1-3 sentences: what problem this plan solves and why it matters now}

## Phase Gates

| Gate | Status | Entry Date | Exit Date | Blocking Issues |
|------|--------|------------|-----------|-----------------|
| Design | {not-started / in-progress / passed / failed} | | | |
| Plan | {not-started / in-progress / passed / failed} | | | |
| Implement | {not-started / in-progress / passed / failed} | | | |
| Verify | {not-started / in-progress / passed / failed} | | | |
| Ship | {not-started / in-progress / passed / failed} | | | |

## Task Breakdown

### Phase: Design
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| D1 | | | | | |

### Phase: Plan
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| P1 | | | | | |

### Phase: Implement
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| I1 | | | | | |

### Phase: Verify
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| V1 | | | | | |

### Phase: Ship
| # | Task | Assigned Expert | Status | Deliverable | Verified By |
|---|------|----------------|--------|-------------|-------------|
| S1 | | | | | |

## Decision Log
| # | Date | Decision | Options Considered | Rationale | Decided By |
|---|------|----------|-------------------|-----------|------------|
| 1 | | | | | |

## Risk Register
| # | Risk | Probability | Impact | Mitigation | Owner | Status |
|---|------|------------|--------|------------|-------|--------|
| R1 | | | | | | |

## Verification Checklist
{Per-phase checklists — see Section 7}
```

---

## 2. Plan Artifact Metadata

### Status Definitions

| Status | Meaning | Transitions To |
|--------|---------|---------------|
| **Draft** | Plan is being defined, tasks not yet assigned | Active, Abandoned |
| **Active** | Work is in progress across one or more gates | Blocked, Complete, Abandoned |
| **Blocked** | Work is stopped due to unresolved issues | Active (after unblocking) |
| **Complete** | All gates passed, work shipped | — (terminal) |
| **Abandoned** | Work intentionally stopped, no longer relevant | — (terminal) |

### Scale Definitions

These correspond directly to ETYB's scale-aware guidance:

| Scale | Team Size | Process Intensity | Gate Formality |
|-------|-----------|-------------------|---------------|
| **Startup** | 1-5 engineers | Minimal — Design+Plan may collapse | Lightweight checklists |
| **Growth** | 5-20 engineers | Moderate — all gates present but async | Documented decisions |
| **Scale** | 20-100+ engineers | Full — formal handoffs at each gate | Sign-offs and reviews |
| **Enterprise** | 100+ engineers | Formal — approval boards at each gate | Compliance-grade audit trails |

### Tier Impact on Plan Depth

| Plan Section | Tier 3 (Focused) | Tier 4 (Full Project) |
|-------------|-------------------|----------------------|
| Metadata | Required | Required |
| Context | 1-2 sentences | Full problem statement with constraints |
| Phase Gates | All 5, lightweight | All 5, with entry/exit criteria documented |
| Task Breakdown | Key tasks only | Exhaustive per phase |
| Decision Log | Key decisions (2-5) | All architectural decisions (5-15) |
| Risk Register | Top 3 risks | Full risk assessment (5-10) |
| Verification Checklist | Per-phase summary | Per-task verification detail |

---

## 3. Phase Gates and Status Tracking

### Gate Status Values

Each gate progresses through a fixed lifecycle:

```
not-started → in-progress → passed
                           ↘ failed → in-progress → passed
```

| Status | Meaning | Action Required |
|--------|---------|----------------|
| **not-started** | Gate prerequisites not yet met | Wait for prior gate to pass |
| **in-progress** | Gate work actively happening | Monitor and verify |
| **passed** | All exit criteria met, verified | Proceed to next gate |
| **failed** | Exit criteria not met after review | Address failures, re-enter gate |

### Gate Failure Protocol

When a gate fails:

1. **Record the failure** in the Blocking Issues column of the Phase Gates table
2. **Identify what failed** — which exit criterion was not met
3. **Assign remediation** — which expert owns the fix
4. **Re-verify** — the same expert who identified the failure re-checks after fix
5. **Update status** — only moves to `passed` when all exit criteria are met

### Gate Dependencies

```
Design ──────► Plan ──────► Implement ──────► Verify ──────► Ship
  │              │               │                │             │
  │              │               │                │             │
  ▼              ▼               ▼                ▼             ▼
Architecture   Task specs     Working code    Test results   Production
decisions      & estimates    & unit tests    & reviews      deployment
```

**Strict rule:** A gate cannot begin until the previous gate has passed. The only exception is scale-aware gate collapsing (see Section 14).

---

## 4. Task Breakdown and Expert Assignments

### Task Naming Convention

Tasks use a phase prefix + sequential number:

| Prefix | Phase | Example |
|--------|-------|---------|
| D | Design | D1: Define API contract for order service |
| P | Plan | P1: Estimate effort for database migration |
| I | Implement | I1: Implement order creation endpoint |
| V | Verify | V1: Run integration test suite |
| S | Ship | S1: Deploy to staging environment |

### Task Status Values

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in-progress` | Actively being worked on |
| `done` | Completed and verified |
| `blocked` | Cannot proceed, dependency or issue |
| `dropped` | Removed from scope |

### Expert Assignment Rules

Every task MUST have:
1. **Assigned Expert** — the skill responsible for doing the work
2. **Verified By** — the skill responsible for checking the work (cannot be the same as Assigned Expert for critical tasks)

```
Task Assignment Matrix:

                     Assigned To          Verified By
                     ───────────          ───────────
Architecture work  → system-architect   → code-reviewer or domain architect
Frontend code      → frontend-architect → qa-engineer + code-reviewer
Backend code       → backend-architect  → qa-engineer + code-reviewer
Database changes   → database-architect → backend-architect + security-engineer
API design         → system-architect   → frontend-architect + backend-architect
Security concerns  → security-engineer  → code-reviewer (security-reviewer sub-skill)
Infrastructure     → devops-engineer    → sre-engineer
Test strategy      → qa-engineer        → code-reviewer
Documentation      → technical-writer   → assigned expert (domain accuracy)
```

### Multi-Expert Tasks

Some tasks require collaboration. In these cases, designate a **lead** and **supporting** expert(s):

```markdown
| I3 | Implement payment webhook handler | `backend-architect` (lead), `security-engineer` (support) | in-progress | Webhook endpoint with signature verification | `qa-engineer` |
```

---

## 5. Decision Log

### When to Log a Decision

| Log It | Don't Log It |
|--------|-------------|
| Choosing between architectures (monolith vs microservices) | Obvious implementation details |
| Selecting a technology (PostgreSQL vs DynamoDB) | Standard library usage |
| Defining API contract shape | Variable naming |
| Setting non-functional requirements (p99 < 200ms) | Code formatting choices |
| Scope changes (cutting or adding features) | Test organization |
| Security model selection (JWT vs sessions) | Build tool configuration |

### Decision Entry Format

Each decision log entry captures:

```markdown
| # | Date | Decision | Options Considered | Rationale | Decided By |
|---|------|----------|-------------------|-----------|------------|
| 1 | 2026-04-14 | Use PostgreSQL with row-level security for multi-tenancy | (A) Schema-per-tenant PostgreSQL, (B) Shared schema with RLS, (C) DynamoDB with partition key per tenant | Option B gives us tenant isolation without the operational overhead of schema-per-tenant. Our scale (50 tenants, <10K rows/tenant) doesn't justify DynamoDB's complexity. RLS is auditable for SOC 2. | `system-architect` + `database-architect` |
```

### Decision Categories

| Category | Examples | Mandatory Experts |
|----------|---------|-------------------|
| **Architecture** | Service boundaries, communication patterns | `system-architect` |
| **Data** | Database selection, schema design, caching strategy | `database-architect` |
| **Security** | Auth model, encryption, compliance approach | `security-engineer` |
| **Infrastructure** | Cloud provider, deployment topology, IaC approach | `devops-engineer` |
| **Frontend** | Framework selection, rendering strategy, state management | `frontend-architect` |
| **API** | Protocol (REST/GraphQL/gRPC), versioning strategy | `system-architect` + consuming team |

---

## 6. Risk Register

### Risk Assessment Framework

Each risk is assessed on two dimensions:

**Probability:**

| Level | Definition | Likelihood |
|-------|-----------|------------|
| Low | Unlikely to occur | < 20% chance |
| Medium | Could occur under certain conditions | 20-60% chance |
| High | Likely to occur without mitigation | > 60% chance |

**Impact:**

| Level | Definition | Consequence |
|-------|-----------|------------|
| Low | Minor inconvenience, easy workaround | Hours of delay |
| Medium | Significant rework or partial feature loss | Days of delay |
| High | Project failure, data loss, security breach | Weeks of delay or critical incident |

### Risk Priority Matrix

```
              Impact
           Low    Med    High
         ┌──────┬──────┬──────┐
   High  │  P3  │  P2  │  P1  │  ← Address immediately
Prob Med │  P4  │  P3  │  P2  │  ← Plan mitigation
   Low   │  P5  │  P4  │  P3  │  ← Monitor
         └──────┴──────┴──────┘
```

### Risk Status Values

| Status | Meaning |
|--------|---------|
| `open` | Risk identified, mitigation planned but not yet active |
| `mitigating` | Mitigation in progress |
| `mitigated` | Mitigation in place, residual risk acceptable |
| `occurred` | Risk materialized, handling in progress |
| `closed` | Risk no longer applicable |

### Common Risk Templates by Domain

| Domain | Typical Risk | Default Probability | Default Impact | Default Owner |
|--------|-------------|--------------------:|---------------:|---------------|
| Authentication | Token/session hijacking vulnerability | Medium | High | `security-engineer` |
| Database migration | Data loss during schema change | Medium | High | `database-architect` |
| Third-party API | Provider outage or breaking change | Medium | Medium | `backend-architect` |
| Performance | Endpoint exceeds latency SLA under load | Medium | Medium | `sre-engineer` |
| Compliance | Regulation non-compliance discovered late | Low | High | `security-engineer` |
| Deployment | Rollback failure in production | Low | High | `devops-engineer` |
| Frontend | Browser compatibility regression | Medium | Low | `frontend-architect` |
| Mobile | App store rejection | Low | Medium | `mobile-architect` |

---

## 7. Verification Checklist per Phase

Each phase has a verification checklist that must be completed before the gate can pass.

### Design Phase Checklist

```markdown
## Design Verification
- [ ] Requirements are unambiguous and testable
- [ ] Architecture diagram covers all major components
- [ ] API contracts defined (OpenAPI/GraphQL schema/proto files)
- [ ] Data model documented (ERD or equivalent)
- [ ] Security threats identified (STRIDE or equivalent)
- [ ] Non-functional requirements specified (latency, throughput, availability)
- [ ] Cross-cutting concerns addressed (logging, monitoring, error handling)
- [ ] Scale-appropriate complexity (not over-engineering for startup, not under-engineering for enterprise)
- [ ] Domain architect reviewed (if domain-specific project)
- [ ] `security-engineer` reviewed (if touching auth, data, or API boundaries)
```

### Plan Phase Checklist

```markdown
## Plan Verification
- [ ] All implementation tasks identified and assigned
- [ ] Task dependencies mapped (what blocks what)
- [ ] Effort estimates provided per task
- [ ] Test strategy defined by `qa-engineer`
- [ ] Risk register populated with top risks
- [ ] Decision log captures all architectural choices made so far
- [ ] `security-engineer` has approved the security approach (if applicable)
- [ ] Infrastructure requirements specified (if applicable)
- [ ] Rollback strategy defined for high-risk changes
```

### Implement Phase Checklist

```markdown
## Implementation Verification
- [ ] Code compiles/builds without errors
- [ ] Unit tests written and passing
- [ ] Code follows project conventions (lint, format, types)
- [ ] No security vulnerabilities introduced (SAST scan clean)
- [ ] No new dependencies with known vulnerabilities (SCA scan clean)
- [ ] Database migrations are reversible
- [ ] API contracts match the design specification
- [ ] Error handling covers identified edge cases
- [ ] Logging added for debugging and observability
- [ ] Feature flags in place for gradual rollout (if applicable)
```

### Verify Phase Checklist

```markdown
## Verify Phase Checklist
- [ ] Integration tests passing
- [ ] E2E tests covering critical user journeys
- [ ] Performance tests meeting SLA targets (if applicable)
- [ ] Security review completed by `security-engineer`
- [ ] Code review completed by `code-reviewer`
- [ ] Accessibility requirements met (if frontend)
- [ ] Documentation updated by `technical-writer` (if user-facing)
- [ ] Load testing results acceptable (if applicable)
- [ ] Rollback procedure tested
```

### Ship Phase Checklist

```markdown
## Ship Phase Checklist
- [ ] Staging deployment successful
- [ ] Smoke tests passing in staging
- [ ] Monitoring and alerting configured
- [ ] Runbook created or updated (if production-impacting)
- [ ] Stakeholders notified of deployment
- [ ] Feature flags configured for rollout strategy
- [ ] Production deployment successful
- [ ] Post-deployment smoke tests passing
- [ ] Canary metrics healthy (if canary deployment)
```

---

## 8. Claude Plan Mode Integration

### Strategy: Annotate, Don't Duplicate

When Claude's built-in plan mode is active, skills should annotate the Claude plan rather than creating a separate `.etyb/plans/` file. This avoids duplication and leverages Claude's native plan tracking.

### Detection Mechanism

Claude plan mode detection is **best-effort**. Skills use the following heuristic:

```
Detection signals (check in order):
1. Claude explicitly states it is in plan mode
2. The conversation context shows plan mode was entered
3. A plan file exists in .claude/plans/

If ANY signal detected → annotate Claude's plan
If NO signals detected → create .etyb/plans/ artifact
```

### How Skills Annotate Claude Plans

When operating inside Claude plan mode, skills add their process artifacts as **sections** within the Claude plan rather than creating separate files:

**Instead of creating** `.etyb/plans/auth-migration.md`:
```markdown
## Process Architecture Annotations

### Gate Status
| Gate | Status | Notes |
|------|--------|-------|
| Design | passed | Architecture reviewed by system-architect |
| Plan | in-progress | Task breakdown 80% complete |
| ... | | |

### Expert Assignments
- security-engineer: mandatory (auth change)
- qa-engineer: mandatory (code-producing task)
- backend-architect: lead implementer

### Decision Log
| # | Decision | Rationale |
|---|----------|-----------|
| 1 | JWT with refresh tokens over sessions | Stateless scaling, mobile client support |

### Risk Register
| # | Risk | Mitigation |
|---|------|-----------|
| R1 | Token theft via XSS | HttpOnly cookies, CSP headers |
```

### Graceful Fallback

If Claude plan mode detection fails (signal is ambiguous), the default behavior is:
1. Create the `.etyb/plans/` artifact
2. Note in the artifact that it may coexist with a Claude plan
3. On next interaction, check if a Claude plan exists and offer to merge

### Sync Protocol

When both a Claude plan and `.etyb/plans/` artifact exist:

| Situation | Action |
|-----------|--------|
| Claude plan is canonical, `.etyb/plans/` was created by mistake | Merge `.etyb/plans/` content into Claude plan annotations, delete `.etyb/plans/` file |
| `.etyb/plans/` was created before Claude plan mode existed | Migrate key content to Claude plan annotations, keep `.etyb/plans/` as archive |
| User explicitly wants `.etyb/plans/` | Honor user preference, add a note in Claude plan pointing to the `.etyb/plans/` file |

---

## 9. Gate Definitions — Design

### Purpose

The Design gate ensures that the team understands **what** they're building and **why** before committing to **how**. It produces the architectural blueprint that all subsequent work builds on.

### Entry Criteria

| Criterion | Verified By |
|-----------|-------------|
| User's request is understood and restated | `etyb` |
| Request complexity tier is classified (Tier 3 or 4) | `etyb` |
| Relevant domain identified (if applicable) | `etyb` |
| Existing system context gathered (if brownfield) | Relevant architect |

### Exit Criteria

| Criterion | Verified By |
|-----------|-------------|
| Architecture design documented (components, data flow, boundaries) | `system-architect` or domain architect |
| API contracts defined at interface level | `system-architect` |
| Data model defined at entity/relationship level | `database-architect` (if data-intensive) |
| Security threat model completed (if auth/data/API change) | `security-engineer` |
| Non-functional requirements specified | Relevant architect |
| Key architectural decisions logged with rationale | Lead architect |

### Mandatory Experts

| Expert | Condition |
|--------|-----------|
| `system-architect` | Always (Tier 3+) |
| `security-engineer` | If touching auth, PII, payments, API boundaries |
| Domain architect | If domain-specific (e-commerce, fintech, healthcare, etc.) |
| `frontend-architect` | If the project has a user interface |
| `database-architect` | If introducing new data models or migrations |

### Required Artifacts

- Architecture diagram or component description
- API contract stubs (endpoints, request/response shapes)
- Data model sketch (entities, relationships)
- Threat model summary (if security-relevant)
- Decision log entries for all architecture choices

---

## 10. Gate Definitions — Plan

### Purpose

The Plan gate translates the architecture into **concrete, estimable, assignable work**. It ensures the team knows who does what, in what order, and what could go wrong.

### Entry Criteria

| Criterion | Verified By |
|-----------|-------------|
| Design gate passed | `etyb` |
| Architecture artifacts available and reviewed | Lead architect |

### Exit Criteria

| Criterion | Verified By |
|-----------|-------------|
| All implementation tasks identified with clear deliverables | `etyb` |
| Each task assigned to a specific expert | `etyb` |
| Task dependencies mapped (what blocks what) | `etyb` |
| Test strategy defined | `qa-engineer` |
| Risk register populated with top risks and mitigations | `etyb` |
| Rollback strategy defined for high-risk changes | `devops-engineer` or `sre-engineer` |
| Infrastructure requirements identified | `devops-engineer` (if applicable) |

### Mandatory Experts

| Expert | Condition |
|--------|-----------|
| `qa-engineer` | Always — must define test strategy for any code-producing plan |
| `etyb` | Always — owns the task breakdown |
| `devops-engineer` | If infrastructure changes are needed |
| `security-engineer` | If security review was flagged at Design gate |

### Required Artifacts

- Complete task breakdown table with assignments
- Test strategy document or section
- Risk register with top 3-10 risks
- Dependency map (which tasks block which)
- Rollback plan (for high-risk changes)

---

## 11. Gate Definitions — Implement

### Purpose

The Implement gate is where working code is produced. It ensures code meets quality standards, follows the architecture, and is accompanied by unit tests.

### Entry Criteria

| Criterion | Verified By |
|-----------|-------------|
| Plan gate passed | `etyb` |
| Task assignments accepted by assigned experts | Assigned experts |
| Development environment ready | `devops-engineer` (if applicable) |

### Exit Criteria

| Criterion | Verified By |
|-----------|-------------|
| All implementation tasks completed | Assigned experts |
| Code compiles/builds without errors | Assigned experts |
| Unit tests written and passing | Assigned experts + `qa-engineer` |
| Lint and type checks passing | Assigned experts |
| No new SAST/SCA findings (or justified exceptions) | `security-engineer` |
| Database migrations tested (if applicable) | `database-architect` |
| API implementation matches design contract | `system-architect` |
| Feature flags configured for gradual rollout (if applicable) | `devops-engineer` |

### Mandatory Experts

| Expert | Condition |
|--------|-----------|
| Assigned implementation experts | Always |
| `qa-engineer` | Always — verifies unit test coverage and quality |
| `security-engineer` | If auth, data, or API changes |
| `database-architect` | If database schema changes |

### Required Artifacts

- Working code with unit tests
- Clean build (no compile errors, lint clean, types clean)
- SAST scan results (clean or exceptions documented)
- Migration scripts (if database changes)

---

## 12. Gate Definitions — Verify

### Purpose

The Verify gate ensures the implementation actually works correctly, performs adequately, and is safe to ship. This is where integration testing, code review, and security review happen.

### Entry Criteria

| Criterion | Verified By |
|-----------|-------------|
| Implement gate passed | `etyb` |
| All unit tests passing | `qa-engineer` |
| Code is in a reviewable state (no WIP commits) | Assigned experts |

### Exit Criteria

| Criterion | Verified By |
|-----------|-------------|
| Integration tests passing | `qa-engineer` |
| E2E tests covering critical paths | `qa-engineer` |
| Code review completed with no blocking findings | `code-reviewer` |
| Security review completed (if applicable) | `security-engineer` |
| Performance tests meeting SLA targets (if applicable) | `qa-engineer` or `sre-engineer` |
| Accessibility audit passed (if frontend) | `frontend-architect` |
| Documentation reviewed for accuracy | `technical-writer` (if user-facing) |
| All blocking code review comments resolved | Assigned experts |

### Mandatory Experts

| Expert | Condition |
|--------|-----------|
| `code-reviewer` | Always — every code change gets reviewed |
| `qa-engineer` | Always — owns integration and E2E verification |
| `security-engineer` | If auth, data, API, or infrastructure changes |
| `technical-writer` | If user-facing changes or API documentation updates |
| `sre-engineer` | If performance-critical or production-impacting changes |

### Required Artifacts

- Integration test results (all passing)
- E2E test results (critical paths covered)
- Code review approval
- Security review sign-off (if applicable)
- Performance test results (if applicable)

---

## 13. Gate Definitions — Ship

### Purpose

The Ship gate covers deployment to production and post-deployment verification. It ensures the change reaches users safely and can be rolled back if needed.

### Entry Criteria

| Criterion | Verified By |
|-----------|-------------|
| Verify gate passed | `etyb` |
| All review comments resolved | Assigned experts |
| Staging deployment successful (if applicable) | `devops-engineer` |

### Exit Criteria

| Criterion | Verified By |
|-----------|-------------|
| Staging smoke tests passing | `qa-engineer` or `sre-engineer` |
| Production deployment successful | `devops-engineer` |
| Post-deployment smoke tests passing | `sre-engineer` |
| Monitoring and alerting active | `sre-engineer` |
| Canary metrics healthy (if canary deployment) | `sre-engineer` |
| Runbook created or updated | `technical-writer` or `sre-engineer` |
| Rollback tested or rollback path verified | `devops-engineer` + `sre-engineer` |
| Stakeholders notified | `etyb` |

### Mandatory Experts

| Expert | Condition |
|--------|-----------|
| `devops-engineer` | Always — owns deployment |
| `sre-engineer` | Always — owns production verification |
| `code-reviewer` | Tier 3+ — final sign-off before production |
| `security-engineer` | If auth, data, or compliance-relevant changes |

### Required Artifacts

- Deployment log (what was deployed, when, by whom)
- Post-deployment verification results
- Monitoring dashboard links
- Runbook (new or updated)
- Rollback procedure documented and tested

---

## 14. Gate Scale Calibration

### How Gates Adapt by Scale

Not every organization needs the same process rigor. Gates scale up or down based on team size and organizational maturity.

### Startup (1-5 Engineers)

```
Allowed gate collapsing:
  Design + Plan → single "Design & Plan" gate
  Verify + Ship → single "Verify & Ship" gate

Resulting flow:
  Design & Plan ──► Implement ──► Verify & Ship
```

| Gate | Adjustments |
|------|-------------|
| Design & Plan (collapsed) | Informal architecture discussion, task list in plan artifact, minimal risk register |
| Implement | Unit tests still required, but coverage targets relaxed (50%+ vs 80%+) |
| Verify & Ship | Code review by peer (not formal `code-reviewer`), smoke tests instead of full E2E |

### Growth (5-20 Engineers)

```
All 5 gates present, but:
  - Design and Plan can run asynchronously
  - Verify gate reviews can be async (PR-based)
  - Ship gate can be automated for non-critical changes

Flow:
  Design ──► Plan ──► Implement ──► Verify ──► Ship
  (async)   (async)   (parallel    (async     (automated
                       tracks OK)   reviews)   for low-risk)
```

| Gate | Adjustments |
|------|-------------|
| Design | Architecture doc required but can be lightweight (1-2 pages) |
| Plan | Task breakdown required, test strategy defined |
| Implement | Unit tests + integration tests required |
| Verify | Code review required (async PR review acceptable) |
| Ship | Staging deployment required, production deployment can be automated |

### Scale (20-100+ Engineers)

```
All 5 gates, formal:
  - Each gate has explicit sign-off from mandatory experts
  - Gate transitions documented in plan artifact
  - Cross-team coordination via plan artifact

Flow:
  Design ──► Plan ──► Implement ──► Verify ──► Ship
  (formal)  (formal)  (formal,     (formal,   (formal,
                       parallel     reviews +   staging +
                       tracks)      sign-offs)  canary)
```

| Gate | Adjustments |
|------|-------------|
| Design | Full architecture review with multiple architects |
| Plan | Detailed task breakdown with effort estimates |
| Implement | Full test pyramid, SAST/SCA mandatory |
| Verify | Mandatory code review + security review + performance testing |
| Ship | Staging → canary → production progression required |

### Enterprise (100+ Engineers)

```
All 5 gates, with governance:
  - Architecture Review Board at Design gate
  - Security review board at Verify gate
  - Change Advisory Board at Ship gate
  - Compliance audit trail throughout

Flow:
  Design ──► Plan ──► Implement ──► Verify ──► Ship
  (ARB)     (formal)  (formal,     (SRB +     (CAB +
                       parallel     formal     compliance
                       tracks,      reviews)   sign-off)
                       feature
                       branches)
```

| Gate | Adjustments |
|------|-------------|
| Design | Architecture Review Board approval required |
| Plan | Formal capacity planning, resource allocation |
| Implement | Feature branches, CI gating, full test pyramid |
| Verify | Security Review Board, performance benchmarks, load testing |
| Ship | Change Advisory Board, phased rollout mandatory, incident response plan |

---

## 15. Expert Mandating Rules

### Automatic Expert Assignment

Certain types of changes **always** require specific experts, regardless of who ETYB would normally assign.

### Mandatory Expert Matrix

| Change Type | Mandatory Expert | Gate(s) | Rationale |
|-------------|-----------------|---------|-----------|
| Auth changes (login, session, token, RBAC) | `security-engineer` | Design, Verify | Auth flaws are critical vulnerabilities |
| PII/sensitive data handling | `security-engineer` | Design, Verify | Compliance and privacy requirements |
| API boundary changes (new/modified endpoints) | `security-engineer` | Design, Verify | API surface is primary attack vector |
| Payment/financial flows | `security-engineer` + `fintech-architect` | Design, Plan, Verify | PCI compliance, fraud prevention |
| Database schema changes | `database-architect` | Design, Implement | Data integrity, migration safety |
| Any code-producing task | `qa-engineer` | Plan | Test strategy must exist before coding begins |
| Any code change (Tier 3+) | `code-reviewer` | Ship | No unreviewed code reaches production |
| Infrastructure changes | `devops-engineer` + `sre-engineer` | Plan, Ship | Infra reliability and cost control |
| Healthcare data | `healthcare-architect` + `security-engineer` | Design, Verify, Ship | HIPAA compliance |
| User-facing changes | `frontend-architect` | Verify | Accessibility, UX consistency |
| API documentation changes | `technical-writer` | Verify | Documentation accuracy |

### Mandating Rule Precedence

When multiple rules apply, **all** mandatory experts are included. There is no "one overrides another" — mandates are additive.

```
Example: Adding a payment endpoint (new API + financial flow)

Mandatory experts:
  - security-engineer    (API boundary change + financial flow)
  - fintech-architect    (financial flow)
  - qa-engineer          (code-producing task)
  - code-reviewer        (Tier 3+ code change at Ship gate)
  - database-architect   (if payment data stored in new tables)
```

### Exemption Process

Mandatory experts can only be exempted when:
1. The expert explicitly confirms the change doesn't require their review
2. The exemption is logged in the Decision Log with rationale
3. The `etyb` approves the exemption

**No silent skipping.** If a mandatory expert is not available, the gate blocks until they review.

---

## 16. Expert Continuity Protocol

### The Problem

Experts assigned at Design or Plan gates often lose context by the time their work is needed at Verify or Ship. This leads to rubber-stamp reviews, missed issues, and duplicated effort.

### The Solution: Continuous Assignment

When an expert is assigned to a plan, they remain assigned **throughout the plan lifecycle** and verify at every checkpoint where they're relevant.

### Continuity Matrix

| Expert | Design | Plan | Implement | Verify | Ship |
|--------|--------|------|-----------|--------|------|
| `system-architect` | Designs architecture | Reviews task breakdown for completeness | Spot-checks implementation matches design | Reviews architecture adherence | Confirms no architectural drift |
| `security-engineer` | Threat model | Reviews test strategy for security coverage | Reviews security-sensitive code as it's written | Full security review | Confirms security controls active in production |
| `qa-engineer` | Reviews testability of design | Defines test strategy | Reviews unit test quality | Runs integration/E2E tests | Verifies smoke tests in staging/production |
| `code-reviewer` | — | — | Informal review of critical code during implementation | Formal code review | Final sign-off |
| `database-architect` | Data model design | Reviews migration plan | Reviews migration scripts | Verifies migration rollback works | Monitors database health post-deploy |
| `devops-engineer` | — | Reviews infrastructure needs | — | — | Owns deployment execution |
| `sre-engineer` | Reviews SLA/SLO requirements | Reviews monitoring plan | — | Reviews runbook | Owns production verification |

### Checkpoint Protocol

At each gate transition, assigned experts perform a **checkpoint review**:

1. **Re-read** the plan artifact for their relevant sections
2. **Verify** their prior recommendations were followed
3. **Flag** any new concerns based on what's changed
4. **Update** the plan artifact with their checkpoint findings
5. **Sign off** or **block** the gate based on findings

### Context Preservation

To maintain expert context across gate transitions:

- All expert feedback is recorded in the plan artifact (Decision Log or task comments)
- Experts are notified when their assigned tasks change status
- The plan artifact serves as the single source of truth — experts re-read it rather than relying on memory

---

## 17. Coordination Patterns with Gate Checkpoints

These extend the five coordination patterns from ETYB SKILL.md with explicit gate checkpoints.

### Sequential Pipeline (with Gates)

```
Research → [DESIGN GATE] → Architecture → [PLAN GATE] → Development → [IMPLEMENT GATE]
→ Testing → [VERIFY GATE] → Deployment → [SHIP GATE] → Operations

Gate Owners:
  DESIGN GATE:    system-architect + security-engineer (if applicable)
  PLAN GATE:      ETYB + qa-engineer
  IMPLEMENT GATE: assigned experts + qa-engineer
  VERIFY GATE:    code-reviewer + security-engineer (if applicable)
  SHIP GATE:      devops-engineer + sre-engineer
```

**Use for:** Greenfield projects where each phase builds on the previous. Most common pattern.

### Parallel Tracks (with Gates)

```
                      [DESIGN GATE]
                           │
                      [PLAN GATE]
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         Frontend     Backend      Database
         Track        Track        Track
              │            │            │
              └────────────┼────────────┘
                           │
                    [IMPLEMENT GATE]     ← All tracks must pass
                           │
                     [VERIFY GATE]
                           │
                      [SHIP GATE]
```

**Gate checkpoint rule:** The IMPLEMENT gate blocks until ALL parallel tracks are complete. Individual tracks can have internal checkpoints, but the formal gate applies to the combined work.

**Use for:** Feature development after architecture is set. Frontend, backend, and database work in parallel against API contracts.

### Hub-and-Spoke (with Gates)

```
                    Security Hub
                    (security-engineer)
                         │
            ┌────────────┼────────────┐
            │            │            │
      [VERIFY GATE] [VERIFY GATE] [VERIFY GATE]
            │            │            │
         Frontend     Backend     Infrastructure
         Spoke        Spoke       Spoke
```

**Gate checkpoint rule:** Each spoke goes through Design → Plan → Implement independently. The hub (`security-engineer` or `system-architect`) performs VERIFY gate reviews for each spoke, then the combined work passes through the SHIP gate together.

**Use for:** Audits, compliance initiatives, cross-cutting security hardening.

### Domain-Augmented (with Gates)

```
Domain Specialist                    Core Teams
(e.g., fintech-architect)           (backend, frontend, etc.)
         │                                │
    [DESIGN GATE]                         │
    Domain patterns &                     │
    constraints defined                   │
         │                                │
         └────────────► [PLAN GATE] ◄─────┘
                             │
                     Core teams implement
                     with domain constraints
                             │
                       [IMPLEMENT GATE]
                             │
         ┌───────────► [VERIFY GATE]
         │            Domain specialist
         │            verifies domain
         │            rules followed
         │                   │
         │              [SHIP GATE]
         │              Domain specialist
         │              confirms production
         │              compliance
         │                   │
    Domain specialist        │
    stays assigned ──────────┘
    throughout (continuity protocol)
```

**Use for:** Building domain-specific systems (e-commerce, fintech, healthcare) where domain constraints must be verified at every gate.

### Incident Response (with Post-Incident Gates)

```
Active Incident:
  NO GATES — speed is everything
  SRE leads → pull relevant expert → fix → verify fix works

Post-Incident (when stable):
  [POST-INCIDENT REVIEW]
      │
      ├── Root cause analysis
      ├── Action items generated
      │
      └──► Action items become Tier 3/4 plans
           with full gate process
```

**Use for:** Production incidents. The gate process applies to post-incident remediation, not the incident itself.

---

## 18. Plan Lifecycle Management

### Plan Creation

| Step | Action | Owner |
|------|--------|-------|
| 1 | User request received | `etyb` |
| 2 | Request classified as Tier 3 or 4 | `etyb` |
| 3 | Plan artifact created with metadata and context | `etyb` |
| 4 | Relevant skills read and synthesized | `etyb` |
| 5 | Initial task breakdown drafted | `etyb` |
| 6 | Mandatory experts identified and notified | `etyb` |

### Plan Updates

The plan artifact is a living document. Updates happen at:

| Trigger | Who Updates | What Changes |
|---------|-------------|-------------|
| Gate transition | `etyb` | Gate status, entry/exit dates |
| Task completion | Assigned expert | Task status, verification notes |
| Decision made | Decision maker | Decision log entry |
| Risk identified | Any expert | Risk register entry |
| Scope change | `etyb` | Tasks added/removed, decision log entry |
| Blocker encountered | Affected expert | Task status → blocked, blocking issues column |

### Plan Archival

When a plan reaches `Complete` or `Abandoned`:

1. Move the plan to `.etyb/plans/archive/` (or keep in place with terminal status)
2. Ensure the Decision Log captures all key learnings
3. If `Abandoned`, record the reason in the Decision Log
4. Post-completion, the plan serves as a reference for similar future work

---

## 19. Cross-Skill Integration Points

### How This Reference Connects to Other Skills

| Skill | Integration Point |
|-------|------------------|
| `system-architect` | Produces the architecture artifacts required by the Design gate |
| `database-architect` | Produces data model artifacts and migration plans required at Design and Implement gates |
| `security-engineer` | Mandatory expert at Design, Verify gates for auth/data/API changes |
| `qa-engineer` | Mandatory at Plan gate for test strategy, Verify gate for test execution |
| `code-reviewer` | Mandatory at Verify and Ship gates for all code changes |
| `devops-engineer` | Mandatory at Ship gate for deployment; contributes to Plan gate for infrastructure |
| `sre-engineer` | Mandatory at Ship gate for production verification; reviews SLO requirements at Design |
| `technical-writer` | Contributes at Verify gate for documentation accuracy |
| `project-planner` | Can supplement ETYB for detailed sprint planning and estimation |
| `research-analyst` | Produces feasibility analysis and technology evaluation before Design gate |
| Domain architects | Mandatory at Design and Verify gates for domain-specific projects |

### Skill Invocation Sequence by Pattern

```
Sequential Pipeline:
  research-analyst → system-architect → [implementation skills] → qa-engineer
  → code-reviewer → devops-engineer → sre-engineer

Parallel Tracks:
  system-architect → [frontend-architect ∥ backend-architect ∥ database-architect]
  → qa-engineer → code-reviewer → devops-engineer → sre-engineer

Hub-and-Spoke:
  security-engineer → [parallel verification of each spoke's work]
  → combined ship gate

Domain-Augmented:
  domain-architect → system-architect → [implementation skills]
  → domain-architect (verify) → code-reviewer → devops-engineer
```

---

## 20. Process Anti-Patterns

### What NOT to Do

| Anti-Pattern | Description | Correct Approach |
|-------------|-------------|-----------------|
| **Gate Theater** | Going through gate motions without actually verifying exit criteria | Each gate exit criterion must have a concrete artifact or verification step |
| **Expert Ping-Pong** | Assigning different experts at each gate, losing context | Use expert continuity protocol — same expert throughout |
| **Over-Process for Tier 1** | Creating plan artifacts for simple single-specialist tasks | Only create plans for Tier 3+ |
| **Under-Process for Tier 4** | Skipping gates for complex projects because "we're moving fast" | Fast execution comes from clear plans, not skipped gates |
| **Phantom Reviews** | Marking code review as complete without actually reviewing | `code-reviewer` must produce specific, actionable feedback |
| **Risk Register Rot** | Populating risk register at Plan gate, never updating it | Review and update risk register at every gate transition |
| **Decision Amnesia** | Making architectural decisions verbally without logging them | All decisions go in the Decision Log with rationale |
| **Security as Afterthought** | Only involving `security-engineer` at the Verify gate | Security is mandatory at Design gate for auth/data/API changes |
| **Test Strategy Drift** | Defining test strategy at Plan gate, implementing different tests | `qa-engineer` verifies test implementation matches strategy at Verify gate |
| **Silent Gate Failure** | Proceeding past a failed gate without documenting the failure | All gate failures must be recorded and remediated |
| **Plan Artifact Staleness** | Creating a plan and never updating it as work progresses | Plan artifact is updated at every task completion and gate transition |
| **Scope Creep Without Decision** | Adding tasks mid-implementation without updating the plan | All scope changes go through the Decision Log and update the task breakdown |

---

## 21. Process Protocol Integration

### How Process Protocols Fit the Gate System

Process protocols are always-on engineering disciplines with deep reference knowledge. Their principles are embedded in ETYB's Engineering Culture section. Their deep knowledge lives in dedicated skill directories loaded on demand.

| Gate | Protocols Active | What They Enforce |
|------|-----------------|-------------------|
| Pre-Design | brainstorm-protocol | Structured exploration for ambiguous requests |
| Design | (domain experts lead) | Protocols provide background discipline |
| Plan | (qa-engineer + project-planner lead) | TDD strategy informs tdd-protocol execution |
| Implement | tdd-protocol, plan-execution-protocol, subagent-protocol | Red-green-refactor, task-by-task execution, parallel dispatch |
| Verify | review-protocol | Review dispatch and rigorous feedback evaluation |
| Ship | git-workflow-protocol | Branch finishing with test verification |
| All Gates | Verification discipline, debugging discipline | Evidence before claims, root cause first |

### Protocol + Expert Combinations

Protocols activate ALONGSIDE domain experts, not instead of them:
- Implement gate: tdd-protocol + backend-architect (for a backend task)
- Parallel Implement: subagent-protocol + git-workflow-protocol + multiple experts
- Verify gate: review-protocol + code-reviewer + security-engineer (if mandated)

### Hook Enforcement (Deterministic)

Hooks fire outside the LLM reasoning loop — they cannot be bypassed by rationalization:

| Hook | When | What | Blocking? |
|------|------|------|-----------|
| skills/tdd-protocol/hooks/pre-edit-check.sh | Before Edit tool | Warns if no test file exists | Warning |
| skills/tdd-protocol/hooks/post-test-log.sh | After test runs | Logs results for verification | No |
| skills/git-workflow-protocol/hooks/pre-merge-verify.sh | Before git merge | Blocks if tests fail | Blocking |
| skills/review-protocol/hooks/pre-commit-review-check.sh | Before git commit | Warns if no review evidence | Warning |
| skills/plan-execution-protocol/hooks/post-edit-log.sh | After Edit tool | Logs edits for plan traceability | No |
