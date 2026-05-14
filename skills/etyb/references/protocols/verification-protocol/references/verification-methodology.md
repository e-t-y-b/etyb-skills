# Verification Protocol — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Completion Checklist Structure](#1-completion-checklist-structure)
2. [The Five Verification Questions](#2-the-five-verification-questions)
3. [Verification-by-Role Expectations](#3-verification-by-role-expectations)
4. [Done Criteria per Gate](#4-done-criteria-per-gate)
5. [Mandatory Code Review Gate](#5-mandatory-code-review-gate)
6. [Automated Checks Layer](#6-automated-checks-layer)
7. [Human Review Layer](#7-human-review-layer)
8. [Verification Escalation](#8-verification-escalation)
9. [Verification Evidence Standards](#9-verification-evidence-standards)
10. [Cross-Skill Verification Matrix](#10-cross-skill-verification-matrix)
11. [Verification Anti-Patterns](#11-verification-anti-patterns)
12. [Verification Templates](#12-verification-templates)

---

## 1. Completion Checklist Structure

Every task completion — at any gate, by any expert — must include a structured completion report. This is not bureaucracy; it's the mechanism that prevents "it works on my machine" from reaching production.

### Universal Completion Report Format

```markdown
## Task Completion: {Task ID} — {Task Description}

### (a) What Was Done
{Concrete description of the work performed. Not "implemented the feature" —
specific: "Added /api/v2/orders endpoint with POST handler, request validation,
and database persistence layer."}

### (b) How It Was Verified
{What steps were taken to confirm correctness. Not "tested it" —
specific: "Ran the endpoint locally with valid and invalid payloads.
Confirmed 201 response with valid data, 400 response with missing fields,
409 response with duplicate order ID."}

### (c) What Tests Prove It Works
{List of tests written or executed, with pass/fail status.}
- [x] unit: OrderService.createOrder — happy path
- [x] unit: OrderService.createOrder — missing required fields
- [x] unit: OrderService.createOrder — duplicate order ID
- [x] integration: POST /api/v2/orders — full request lifecycle
- [x] integration: POST /api/v2/orders — database persistence verified

### (d) What Edge Cases Were Considered
{Edge cases explicitly thought about, whether or not they were mitigated.}
- Concurrent order creation with same idempotency key → handled via DB unique constraint
- Request body exceeding 1MB → handled via middleware size limit
- Database connection failure mid-transaction → handled via transaction rollback
- Unicode characters in order notes → verified passing through correctly

### (e) What Could Go Wrong
{Honest assessment of remaining risks or known limitations.}
- High concurrency (>1000 orders/sec) not load-tested yet — deferred to Verify gate
- No rate limiting on this endpoint — tracked as risk R3 in plan artifact
- Webhook delivery to external systems is fire-and-forget — retry mechanism planned for Phase 2
```

### Completion Report Depth by Scale

| Scale | Report Depth | Details |
|-------|-------------|---------|
| **Startup** | Lightweight | Sections (a), (b), (c) required. Sections (d), (e) optional but recommended |
| **Growth** | Standard | All 5 sections required. Can be brief (2-3 bullet points each) |
| **Scale** | Detailed | All 5 sections required. Specific test names, edge case analysis |
| **Enterprise** | Formal | All 5 sections required. Links to test results, security scan outputs, compliance evidence |

### When Completion Reports Are Required

| Situation | Report Required? | Rationale |
|-----------|-----------------|-----------|
| Implementation task completed | Yes | Proves the work meets spec |
| Bug fix applied | Yes | Proves the root cause is addressed and regression test exists |
| Configuration change | Yes (abbreviated) | Proves the change is correct and reversible |
| Documentation update | No | Self-evident from the diff |
| Dependency update | Yes (abbreviated) | Proves no breaking changes, security scan clean |

---

## 2. The Five Verification Questions

Every verification — whether self-verification by the implementer or review by another expert — must answer these five questions:

### Question Framework

```
                    ┌─────────────────────────────────┐
                    │     THE FIVE QUESTIONS           │
                    │                                  │
                    │  1. What was done?               │  ← Clarity
                    │  2. How was it verified?         │  ← Process
                    │  3. What tests prove it?         │  ← Evidence
                    │  4. What edge cases considered?  │  ← Thoroughness
                    │  5. What could go wrong?         │  ← Honesty
                    │                                  │
                    └─────────────────────────────────┘
```

### Why Each Question Matters

| Question | What It Catches | Without It |
|----------|----------------|------------|
| What was done? | Scope drift, incomplete implementation | "I think I finished it" — no one knows what "it" is |
| How was it verified? | Untested code, "it compiled" as verification | Code that compiles but doesn't work correctly |
| What tests prove it? | Missing test coverage, phantom tests | Bugs caught in production instead of CI |
| What edge cases considered? | Unconsidered failure modes | The "it works for the happy path" problem |
| What could go wrong? | Unmitigated risks shipped knowingly | Surprised by predictable failures |

### Question Depth by Task Criticality

| Criticality | Questions (a)-(c) | Questions (d)-(e) |
|-------------|-------------------|-------------------|
| Low (config, docs, tooling) | Brief (1-2 sentences each) | Optional |
| Medium (feature, enhancement) | Standard (2-4 bullet points each) | Required (2-3 items each) |
| High (auth, payments, data) | Detailed (specific artifacts referenced) | Thorough (failure mode analysis) |
| Critical (migration, security) | Exhaustive (linked evidence) | Formal risk assessment |

---

## 3. Verification-by-Role Expectations

Different skills verify their work differently because different types of work have different failure modes. This section defines what "verified" means for each skill.

### `frontend-architect` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| Component renders correctly | Visual inspection + snapshot tests | Storybook, Chromatic |
| Responsive layout works | Test at mobile/tablet/desktop breakpoints | Browser DevTools, Playwright viewport |
| Accessibility compliance | Automated audit + keyboard navigation test | axe-core, Lighthouse, screen reader |
| Performance acceptable | Core Web Vitals measurement | Lighthouse, Web Vitals library |
| Cross-browser compatibility | Test in target browsers | BrowserStack, Playwright multi-browser |
| State management correct | Unit tests for state transitions | Jest/Vitest with state assertions |
| API integration works | Integration test with mock API | MSW (Mock Service Worker) |
| No visual regressions | Visual diff against baseline | Chromatic, Percy, Playwright screenshots |

**Minimum verification for any frontend change:**
1. Component renders without errors
2. Lighthouse accessibility score >= 90
3. No console errors or warnings
4. Keyboard navigation works for interactive elements

### `backend-architect` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| API endpoint returns correct responses | Request/response validation | Supertest, REST Client, httpie |
| Input validation rejects bad data | Negative test cases | Unit tests with invalid payloads |
| Error handling returns proper status codes | Error scenario tests | Unit/integration tests |
| Database queries are efficient | Query plan analysis | EXPLAIN ANALYZE, query profiling |
| Authentication/authorization enforced | Auth bypass attempt tests | Integration tests with different roles |
| Rate limiting works | Burst request test | Load test tool (k6, Artillery) |
| Pagination works correctly | Boundary tests (page 0, last page, empty) | Integration tests |
| Concurrent access handled | Race condition tests | Parallel request tests |

**Minimum verification for any backend change:**
1. API tests pass (happy path + error cases)
2. No N+1 queries (checked via query logging)
3. Input validation covers all user-supplied fields
4. Error responses use consistent format

### `database-architect` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| Migration runs forward successfully | Execute migration on test database | Migration framework test mode |
| Migration rolls back cleanly | Execute rollback on test database | Migration framework rollback |
| No data loss during migration | Row count + checksum before/after | SQL verification queries |
| Query performance acceptable | EXPLAIN ANALYZE on critical queries | Database query profiler |
| Indexes are effective | Index usage statistics after test load | pg_stat_user_indexes, EXPLAIN |
| Constraints enforce data integrity | Insert invalid data, verify rejection | Integration tests |
| Connection pooling handles load | Concurrent connection test | pgbench, connection pool monitoring |
| Backup/restore works | Test backup + restore cycle | pg_dump/pg_restore or equivalent |

**Minimum verification for any database change:**
1. Migration forward and rollback both succeed
2. No data loss (verified with row counts)
3. Query performance within SLA (EXPLAIN ANALYZE)
4. Constraints tested with invalid data

### `security-engineer` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| No new OWASP Top 10 vulnerabilities | SAST + manual review | Semgrep, CodeQL, SonarQube |
| Dependencies are free of known CVEs | SCA scan | Snyk, Dependabot, npm audit |
| Authentication cannot be bypassed | Auth bypass test cases | Manual testing + automated suite |
| Authorization enforces boundaries | BOLA/BFLA test cases | Integration tests with different roles |
| Secrets not exposed in code/logs | Secret scanning | git-secrets, TruffleHog, Semgrep Secrets |
| Input sanitization prevents injection | Injection payload tests | DAST tools, manual testing |
| CORS/CSP/headers properly configured | Header inspection | SecurityHeaders.com, curl inspection |
| Encryption at rest and in transit | Configuration verification | SSL Labs, infrastructure audit |

**Minimum verification for any security-relevant change:**
1. SAST scan clean (no new findings)
2. SCA scan clean (no new CVEs)
3. Auth bypass tests pass
4. No secrets in code or logs

### `devops-engineer` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| CI pipeline passes all stages | Full pipeline run | GitHub Actions, GitLab CI |
| Container builds successfully | Docker build test | Docker, Podman |
| Container image is secure | Image vulnerability scan | Trivy, Snyk Container |
| Infrastructure changes are correct | Plan/preview before apply | Terraform plan, Pulumi preview |
| Deployment succeeds in staging | Staging deployment test | Deployment pipeline |
| Rollback works | Rollback test in staging | Deployment pipeline rollback |
| Monitoring captures new metrics | Dashboard verification | Grafana, Datadog, CloudWatch |
| Alerting fires on threshold breach | Alert test | Alert testing tools, synthetic failures |

**Minimum verification for any infrastructure change:**
1. `terraform plan` / `pulumi preview` reviewed
2. Staging deployment successful
3. Rollback tested in staging
4. Monitoring captures relevant metrics

### `sre-engineer` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| SLOs are being measured | SLO dashboard check | Grafana, Datadog, Nobl9 |
| Alerting is configured correctly | Alert test fire | PagerDuty, OpsGenie |
| Runbook is accurate and current | Runbook walkthrough | Manual review |
| Performance under load acceptable | Load test | k6, Locust, Artillery |
| Error budget is healthy | Error budget burn rate check | SLO tracking dashboard |
| Graceful degradation works | Partial failure injection | Chaos engineering tools |
| Health checks are comprehensive | Health endpoint verification | Synthetic monitoring |
| Logging captures debugging info | Log search for key events | ELK, Loki, CloudWatch Logs |

**Minimum verification for any production-impacting change:**
1. SLOs measured and dashboarded
2. Alerts configured for failure modes
3. Runbook exists (new or updated)
4. Health checks cover the change

### `qa-engineer` Verification

| What to Verify | How to Verify | Tools |
|----------------|---------------|-------|
| Test coverage meets targets | Coverage report | Istanbul/nyc, JaCoCo, coverage.py |
| Test quality is sufficient | Mutation testing sample | Stryker, PIT, mutmut |
| Tests are not flaky | Run suite 3x, check for intermittent failures | CI retry analysis |
| Test data is isolated | Tests don't share state | Test setup/teardown verification |
| E2E tests cover critical paths | Journey mapping against test list | Test case traceability |
| Performance tests pass SLA | Load test results review | k6, JMeter results |
| Test environment matches production | Config comparison | Environment diff tool |

**Minimum verification for test strategy compliance:**
1. Unit test coverage meets target for changed code
2. Integration tests cover service boundaries
3. No flaky tests introduced
4. Test data is self-contained

---

## 4. Done Criteria per Gate

### What "Done" Means at Each Gate

The word "done" is ambiguous without gate context. A task that's "done" at the Implement gate is not "done" at the Verify gate — it's only partway there.

### Design Gate — "Done" Means

```
Done = Architecture documented + decisions logged + security reviewed (if applicable)

Specifically:
  [x] Architecture components identified and diagrammed
  [x] API contracts defined at interface level (not implementation)
  [x] Data model defined at entity/relationship level
  [x] Key decisions recorded in Decision Log with rationale
  [x] Security threat model completed (if auth/data/API change)
  [x] Non-functional requirements specified with measurable targets
  [x] Mandatory experts have reviewed and signed off

NOT done if:
  [ ] Architecture is "in my head" but not documented
  [ ] API contracts are vague ("we'll figure it out during implementation")
  [ ] Security implications not assessed for auth/data changes
  [ ] Key decisions made but rationale not recorded
```

### Plan Gate — "Done" Means

```
Done = Tasks defined + assigned + estimated + test strategy exists + risks identified

Specifically:
  [x] All implementation tasks identified with clear deliverables
  [x] Each task assigned to a specific expert
  [x] Task dependencies mapped
  [x] Test strategy defined by qa-engineer
  [x] Risk register populated with top risks
  [x] Rollback strategy defined for high-risk changes

NOT done if:
  [ ] Tasks are vague ("implement backend")
  [ ] No test strategy — qa-engineer has not been consulted
  [ ] Risks not assessed ("we'll deal with issues as they come up")
  [ ] No rollback plan for database or infrastructure changes
```

### Implement Gate — "Done" Means

```
Done = Code written + unit tests passing + build clean + SAST clean

Specifically:
  [x] All implementation tasks marked complete
  [x] Code compiles/builds without errors
  [x] Unit tests written AND passing
  [x] Lint, format, and type checks passing
  [x] SAST scan shows no new findings (or justified exceptions)
  [x] SCA scan shows no new vulnerable dependencies
  [x] Database migrations tested (forward and rollback)
  [x] API endpoints match design contracts

NOT done if:
  [ ] "Code works but tests aren't written yet"
  [ ] Build has warnings treated as non-blocking
  [ ] SAST findings ignored without justification
  [ ] Database migration only tested forward, not rollback
```

### Verify Gate — "Done" Means

```
Done = Integration + E2E tests passing + code reviewed + security reviewed

Specifically:
  [x] Integration tests passing
  [x] E2E tests covering critical user journeys
  [x] Code review completed by code-reviewer with no blocking findings
  [x] All blocking code review comments resolved
  [x] Security review completed (if applicable)
  [x] Performance tests meeting SLA targets (if applicable)
  [x] Accessibility audit passed (if frontend)
  [x] Documentation reviewed for accuracy (if user-facing)

NOT done if:
  [ ] Integration tests have failures "that are probably fine"
  [ ] Code review comments deferred to "follow-up PR"
  [ ] Security review waived because "we're in a hurry"
  [ ] Performance hasn't been tested for performance-critical changes
```

### Ship Gate — "Done" Means

```
Done = Deployed to production + verified in production + monitoring active

Specifically:
  [x] Staging deployment successful + smoke tests passing
  [x] Production deployment successful
  [x] Post-deployment smoke tests passing in production
  [x] Monitoring and alerting configured and active
  [x] Canary metrics healthy (if canary deployment)
  [x] Runbook created or updated
  [x] Rollback procedure verified
  [x] Stakeholders notified

NOT done if:
  [ ] Deployed but "we'll check it tomorrow"
  [ ] No monitoring — "we'll add it in the next sprint"
  [ ] No runbook — "the team knows what to do"
  [ ] Rollback procedure not tested
```

---

## 5. Mandatory Code Review Gate

### The Rule

**Every code change goes through `code-reviewer` before Ship.** No exceptions for Tier 3+ plans.

### Two-Stage Review Process

```
Stage 1: Automated Checks          Stage 2: Human Review
─────────────────────────           ─────────────────────
• Lint / format                     • Architecture adherence
• Type checking                     • Business logic correctness
• Unit tests pass                   • Error handling completeness
• Integration tests pass            • Security patterns
• SAST scan clean                   • Performance implications
• SCA scan clean                    • Code readability
• Coverage threshold met            • Testing quality
• Build succeeds                    • Cross-cutting concerns
                                    • Domain-specific patterns
        │                                    │
        ▼                                    ▼
   MUST PASS before                 MUST APPROVE before
   human review begins              gate passes
```

### Stage 1: Automated Checks (Required Before Human Review)

| Check | Tool | Blocking? |
|-------|------|-----------|
| Linting | ESLint, Clippy, golangci-lint | Yes |
| Formatting | Prettier, gofmt, rustfmt | Yes |
| Type checking | TypeScript, mypy, Go compiler | Yes |
| Unit tests | Jest, Vitest, pytest, Go test | Yes |
| Integration tests | Test framework + testcontainers | Yes |
| SAST | Semgrep, CodeQL, SonarQube | Yes (new critical/high findings) |
| SCA | Snyk, Dependabot, npm audit | Yes (new critical/high CVEs) |
| Coverage | Istanbul, JaCoCo, coverage.py | Advisory (warning if below threshold) |
| Build | Framework build command | Yes |

**Rule:** Human review does NOT begin until all automated checks pass. Reviewers should not spend time on code that doesn't compile, doesn't pass tests, or has known security issues.

### Stage 2: Human Review (by `code-reviewer`)

The `code-reviewer` evaluates using four lenses:

| Lens | What to Check | Sub-skill |
|------|---------------|-----------|
| **Quality** | Code smells, SOLID principles, readability, maintainability | `code-quality` |
| **Performance** | Algorithmic complexity, N+1 queries, memory leaks, unnecessary operations | `performance-reviewer` |
| **Security** | Injection, auth flaws, data exposure, OWASP patterns | `security-reviewer` |
| **Architecture** | Pattern adherence, coupling, separation of concerns, technical debt | `architecture-reviewer` |

### Review Feedback Categories

| Category | Meaning | Action Required |
|----------|---------|----------------|
| **Blocking** | Must be fixed before merge | Author must address, reviewer re-reviews |
| **Suggestion** | Recommended improvement, not blocking | Author decides, documents rationale if declined |
| **Nitpick** | Style/preference, definitely not blocking | Author may ignore |
| **Question** | Reviewer needs clarification to complete review | Author must respond |
| **Praise** | Something done particularly well | No action, encourages good patterns |

### Review Turnaround SLA

| Scale | First Review | Re-review After Changes |
|-------|-------------|------------------------|
| Startup | Same day | Same day |
| Growth | Within 4 hours | Within 2 hours |
| Scale | Within 8 hours | Within 4 hours |
| Enterprise | Within 1 business day | Within 4 hours |

---

## 6. Automated Checks Layer

### CI Pipeline Verification Gates

```
PR Opened / Updated
        │
        ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   Fast Gate   │────▶│  Medium Gate   │────▶│   Full Gate   │
│   (< 3 min)   │     │  (< 10 min)   │     │  (< 20 min)   │
│               │     │               │     │               │
│ • lint        │     │ • unit tests  │     │ • E2E tests   │
│ • typecheck   │     │ • integration │     │ • perf tests  │
│ • build       │     │ • SAST        │     │ • visual reg  │
│ • dep audit   │     │ • SCA         │     │ • a11y audit  │
└───────────────┘     └───────────────┘     └───────────────┘
    ▲ ALL BLOCK PR        ▲ ALL BLOCK PR       ▲ BLOCK deploy
```

### Automated Check Ownership

| Check Category | Configured By | Maintained By |
|---------------|---------------|---------------|
| Lint/format rules | `code-reviewer` | Assigned dev team |
| Test suites | `qa-engineer` | Assigned dev team |
| SAST rules | `security-engineer` | `security-engineer` |
| SCA policies | `security-engineer` | `devops-engineer` |
| CI pipeline | `devops-engineer` | `devops-engineer` |
| Coverage thresholds | `qa-engineer` | `qa-engineer` |

---

## 7. Human Review Layer

### Reviewer Selection

| Change Type | Primary Reviewer | Secondary Reviewer (if applicable) |
|-------------|-----------------|-----------------------------------|
| Frontend code | `frontend-architect` peer | `code-reviewer` (architecture lens) |
| Backend code | `backend-architect` peer | `code-reviewer` (quality + security lens) |
| Database changes | `database-architect` | `backend-architect` (migration impact) |
| Infrastructure | `devops-engineer` peer | `sre-engineer` (operational impact) |
| Security-sensitive | `security-engineer` | `code-reviewer` (security-reviewer sub-skill) |
| Cross-cutting | `code-reviewer` | Domain-specific expert |

### Review Checklist by Change Type

**API Changes:**
- [ ] Backwards compatible (or versioned)
- [ ] Input validation on all user-supplied fields
- [ ] Proper HTTP status codes
- [ ] Rate limiting considered
- [ ] Authentication/authorization enforced
- [ ] Error responses use consistent format
- [ ] API documentation updated

**Database Changes:**
- [ ] Migration is reversible
- [ ] No data loss during migration
- [ ] Indexes support expected query patterns
- [ ] Constraints enforce data integrity
- [ ] Large table changes are online-safe (no locks)
- [ ] Backward compatible with current application code

**Security Changes:**
- [ ] No hardcoded secrets
- [ ] Input sanitized before use
- [ ] Output encoded for context (HTML, SQL, etc.)
- [ ] Auth checks on every protected endpoint
- [ ] Least privilege principle applied
- [ ] Audit logging for sensitive operations

---

## 8. Verification Escalation

### When Self-Verification Is Insufficient

| Signal | Escalation Action |
|--------|-------------------|
| "I think this is right but I'm not sure about the edge cases" | Request `qa-engineer` review of edge case analysis |
| "The performance looks OK locally but I haven't load tested" | Request `sre-engineer` or `qa-engineer` performance test |
| "I followed the security patterns but this is auth-critical" | Request `security-engineer` security review |
| "The migration works on my test data but production has 10M rows" | Request `database-architect` migration review |
| "The architecture matches the design but I made some tradeoffs" | Request `system-architect` architecture review |

### Escalation Path

```
Self-verification by implementer
        │
        ▼  (if uncertain)
Peer verification by same-skill expert
        │
        ▼  (if still uncertain or critical)
Cross-skill verification by relevant specialist
        │
        ▼  (if high-risk or compliance-relevant)
Multi-expert verification panel
```

---

## 9. Verification Evidence Standards

### What Counts as Evidence

| Evidence Type | Strength | Example |
|---------------|----------|---------|
| **Test results** | Strong | "All 47 unit tests pass, 12 integration tests pass" |
| **Screenshot/recording** | Medium | "Browser shows correct layout at mobile breakpoint" |
| **Log output** | Medium | "Server logs show correct request handling for error case" |
| **Query plan** | Strong | "EXPLAIN ANALYZE shows index scan, 2ms execution" |
| **Security scan report** | Strong | "Semgrep: 0 findings, Snyk: 0 vulnerabilities" |
| **Performance metrics** | Strong | "k6: p95 = 180ms at 500 RPS, 0% error rate" |
| **Manual testing notes** | Weak | "I clicked through it and it works" |

### Evidence Requirements by Gate

| Gate | Minimum Evidence |
|------|-----------------|
| Design | Architecture diagram, API contract definitions, decision log entries |
| Plan | Task list with assignments, test strategy document, risk register |
| Implement | Passing tests (unit + integration), clean build, SAST/SCA results |
| Verify | Passing E2E tests, code review approval, security review (if applicable) |
| Ship | Deployment log, post-deployment test results, monitoring dashboard |

---

## 10. Cross-Skill Verification Matrix

### Who Verifies Whom

This matrix defines which skills are responsible for verifying work produced by other skills.

```
                                  Verified By
                    ┌─────┬──────┬──────┬──────┬──────┬──────┐
                    │ sys  │ sec  │ qa   │ code │ devops│ sre  │
                    │ arch │ eng  │ eng  │ rev  │ eng  │ eng  │
     ┌──────────────┼──────┼──────┼──────┼──────┼──────┼──────┤
     │ frontend     │  -   │  △   │  ●   │  ●   │  -   │  -   │
     │ backend      │  △   │  △   │  ●   │  ●   │  -   │  -   │
P    │ database     │  -   │  △   │  ●   │  -   │  -   │  -   │
r    │ system-arch  │  -   │  △   │  -   │  ●   │  -   │  -   │
o    │ devops       │  -   │  △   │  -   │  -   │  -   │  ●   │
d    │ security     │  -   │  -   │  -   │  ●   │  -   │  -   │
u    │ sre          │  -   │  -   │  -   │  -   │  -   │  -   │
c    │ mobile       │  -   │  △   │  ●   │  ●   │  -   │  -   │
e    │ ai-ml        │  -   │  △   │  ●   │  ●   │  -   │  -   │
d    │ tech-writer  │  -   │  -   │  -   │  -   │  -   │  -   │
     └──────────────┴──────┴──────┴──────┴──────┴──────┴──────┘

● = Always verifies    △ = Verifies if security-relevant    - = Not applicable
```

---

## 11. Verification Anti-Patterns

### What NOT to Do

| Anti-Pattern | Description | Correct Approach |
|-------------|-------------|-----------------|
| **"It compiles" verification** | Treating successful compilation as sufficient verification | Compilation is the minimum bar, not the verification |
| **Happy-path-only testing** | Only verifying the success scenario | Test error paths, edge cases, boundary conditions |
| **Rubber stamp review** | Approving code without reading it | Every review must produce at least one piece of specific feedback |
| **Self-review only** | Author reviews their own code and calls it reviewed | Independent reviewer required for all Tier 3+ changes |
| **Verification debt** | "We'll add tests later" | Tests are part of "done" — code without tests is incomplete |
| **Evidence-free claims** | "I tested it" without showing results | Every verification claim must have evidence (test results, screenshots, logs) |
| **Stale verification** | Using old test results after code changes | Re-verify after every code change, no matter how small |
| **Scope-limited verification** | Only testing the changed code, ignoring integration points | Verify that changes don't break upstream/downstream dependencies |
| **Production-blind** | Verifying in dev/staging but not monitoring production | Post-deployment verification is part of the Ship gate |
| **Single-dimension review** | Reviewing only for correctness, ignoring security/performance | Use all four `code-reviewer` lenses (quality, performance, security, architecture) |

---

## 12. Verification Templates

### Bug Fix Completion Template

```markdown
## Bug Fix: {Bug Description}

### Root Cause
{What caused the bug — specific: "The `calculateTotal()` function
did not account for negative quantities in cart items, allowing
negative order totals."}

### Fix Applied
{What was changed to fix it — specific: "Added validation in
`CartService.addItem()` to reject quantities < 1. Added guard in
`calculateTotal()` to treat negative quantities as 0."}

### Regression Test
{Test written to prevent this bug from recurring:}
- [x] test: CartService rejects negative quantities
- [x] test: calculateTotal treats negative quantities as zero
- [x] test: existing positive quantity flow still works

### Verified Fix
- [x] Bug no longer reproducible with original reproduction steps
- [x] Regression test fails on old code, passes on fix
- [x] No other test regressions

### Edge Cases Considered
- Zero quantity → validated, returns error
- Extremely large quantity → validated against inventory limits
- Decimal quantity → validated, only integers allowed
```

### Feature Completion Template

```markdown
## Feature: {Feature Name}

### What Was Built
{Concrete description of the feature and its components.}

### Acceptance Criteria Verification
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | {Criterion from spec} | Pass/Fail | {Test name or screenshot} |
| 2 | {Criterion from spec} | Pass/Fail | {Test name or screenshot} |

### Test Coverage
- Unit tests: {N} tests, {coverage}%
- Integration tests: {N} tests covering {boundaries}
- E2E tests: {N} tests covering {user journeys}

### Performance Impact
- Endpoint latency: {p50/p95/p99}
- Database query count: {N queries per request}
- Bundle size impact: {+/- KB} (frontend only)

### Security Considerations
- [x] Input validation on all user-supplied fields
- [x] Authorization checked on all endpoints
- [x] No sensitive data in logs
- [x] SAST scan clean

### What Could Go Wrong
{Honest list of remaining risks.}
```

### Migration Completion Template

```markdown
## Migration: {Migration Description}

### Changes Applied
{Schema changes, data transformations, index modifications.}

### Forward Migration Verified
- [x] Migration runs without errors on test database
- [x] Schema matches expected state after migration
- [x] Data integrity verified (row counts, checksums)
- [x] Application runs correctly against new schema

### Rollback Verified
- [x] Rollback runs without errors
- [x] Schema matches pre-migration state
- [x] No data loss during forward + rollback cycle
- [x] Application runs correctly against rolled-back schema

### Performance Verified
- [x] Migration completes within acceptable time ({N} seconds on {M} rows)
- [x] No table locks that exceed {N} seconds
- [x] Query performance on critical paths unchanged or improved

### Production Readiness
- [x] Backup taken before migration
- [x] Monitoring configured for post-migration anomalies
- [x] Rollback procedure documented in runbook
```
