# Debugging Protocol — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices before giving recommendations.**

## Table of Contents
1. [Root Cause First Methodology](#1-root-cause-first-methodology)
2. [The Debugging Loop](#2-the-debugging-loop)
3. [Hypothesis-Driven Debugging](#3-hypothesis-driven-debugging)
4. [The One-Variable Rule](#4-the-one-variable-rule)
5. [Three-Failure Escalation Rule](#5-three-failure-escalation-rule)
6. [Debugging State Tracking](#6-debugging-state-tracking)
7. [Expert Escalation Paths](#7-expert-escalation-paths)
8. [Common Debugging Patterns by Domain](#8-common-debugging-patterns-by-domain)
9. [Debugging Anti-Patterns](#9-debugging-anti-patterns)
10. [Root Cause Verification](#10-root-cause-verification)
11. [Post-Debug Actions](#11-post-debug-actions)
12. [Debugging Decision Trees](#12-debugging-decision-trees)

---

## 1. Root Cause First Methodology

### The Principle

**Never fix symptoms. Fix causes.** A symptom fix masks the real problem and guarantees it will resurface — usually at a worse time.

```
Symptom:   "The API returns 500 errors intermittently"
Bad fix:   Add a retry wrapper around the API call
Root cause: Database connection pool exhaustion under load
Real fix:   Tune connection pool size + add connection timeout + add pool exhaustion alert
```

### The Root Cause Hierarchy

Most bugs have multiple layers of cause. The root cause is the deepest actionable layer:

```
Layer 1 (Symptom):     API returns 500 error
Layer 2 (Mechanism):   Unhandled exception in order service
Layer 3 (Direct cause): Database query times out
Layer 4 (Root cause):   Missing index on orders.user_id column
Layer 5 (Process gap):  No query plan review during code review
```

**Fix at Layer 4** (add the index) to solve the immediate problem.
**Fix at Layer 5** (add query plan review to `code-reviewer` checklist) to prevent the class of problem.

### When to Stop Digging

| Layer | Action | Fix Duration |
|-------|--------|-------------|
| Symptom | Temporary mitigation only (circuit breaker, feature flag) | Minutes |
| Direct cause | Fix the immediate trigger | Hours |
| Root cause | Fix the underlying system flaw | Hours to days |
| Process gap | Update process to prevent recurrence | Follow-up task |

**Rule:** Always fix at least to the root cause level. Process gaps become follow-up tasks in the plan artifact.

---

## 2. The Debugging Loop

### The Four Steps

Every debugging session follows the same loop, regardless of the problem domain:

```
    ┌──────────────┐
    │  1. REPRODUCE │◄──────────────────────────────────┐
    │   the problem │                                    │
    └──────┬───────┘                                    │
           │                                            │
           ▼                                            │
    ┌──────────────┐                                    │
    │ 2. HYPOTHESIZE│                                   │
    │   the cause   │                                   │
    └──────┬───────┘                                    │
           │                                            │
           ▼                                            │
    ┌──────────────┐        ┌──────────────┐            │
    │  3. TEST ONE  │───────▶│ Hypothesis   │───No──────┘
    │   variable    │        │ confirmed?   │
    └──────────────┘        └──────┬───────┘
                                   │ Yes
                                   ▼
                            ┌──────────────┐
                            │  4. VERIFY   │
                            │   the fix    │
                            └──────────────┘
```

### Step 1: Reproduce

**Before anything else, reproduce the problem reliably.**

| Reproduction Quality | Definition | Debugging Difficulty |
|---------------------|-----------|---------------------|
| **Deterministic** | Same steps always trigger the bug | Easy — test, fix, verify |
| **Probabilistic** | Bug occurs ~X% of the time | Medium — need multiple attempts per test |
| **Environment-dependent** | Only in production/staging, not locally | Hard — need environment parity or remote debugging |
| **Timing-dependent** | Only under load, concurrency, or specific timing | Hard — need load generation or concurrency tools |
| **Data-dependent** | Only with specific data patterns | Medium — need to identify and isolate the triggering data |

**If you cannot reproduce the bug:**
1. Gather more information (logs, traces, error reports)
2. Narrow the reproduction conditions (specific user, specific data, specific time)
3. Add targeted logging to capture the state when the bug occurs
4. Do NOT guess at fixes — you can't verify a fix for a bug you can't reproduce

### Step 2: Hypothesize

Form a specific, testable hypothesis about the cause:

| Bad Hypothesis | Good Hypothesis |
|---------------|----------------|
| "Something is wrong with the database" | "The query on orders.user_id is doing a full table scan because the index is missing" |
| "It's a timing issue" | "The WebSocket reconnection fires before the auth token refresh completes, sending an expired token" |
| "The cache is broken" | "Cache entries for user sessions are not invalidated when the user's role changes, causing stale authorization" |

**Hypothesis quality checklist:**
- [ ] Is it specific enough to test with a single action?
- [ ] Does it explain ALL observed symptoms (not just some)?
- [ ] Is it falsifiable (what would disprove it)?
- [ ] Is it consistent with what you know about the system?

### Step 3: Test ONE Variable

Change exactly ONE thing to test the hypothesis. If you change multiple things:
- You won't know which change fixed it
- You might introduce new bugs while fixing the original
- You can't verify the root cause

### Step 4: Verify the Fix

See Section 10 for detailed fix verification methodology.

---

## 3. Hypothesis-Driven Debugging

### Forming Good Hypotheses

```
Information Gathering:
  │
  ├── Error messages and stack traces
  ├── Log entries around the time of failure
  ├── Recent code changes (git log --since="2 days ago")
  ├── Recent deployments or configuration changes
  ├── System metrics (CPU, memory, disk, network)
  ├── User reports (when, where, what they were doing)
  │
  ▼
Hypothesis Formation:
  │
  ├── "The most recent change to X could cause this because..."
  ├── "The error message points to X, which depends on Y..."
  ├── "This only happens under condition Z, which affects..."
  │
  ▼
Hypothesis Ranking:
  │
  ├── Most likely (based on evidence)
  ├── Second most likely
  ├── Least likely but highest impact if true
  │
  ▼
Test the most likely hypothesis first
```

### Hypothesis Prioritization Matrix

| Factor | Test First | Test Later |
|--------|-----------|------------|
| **Likelihood** | High probability based on evidence | Low probability, speculative |
| **Test cost** | Quick to verify (< 5 minutes) | Slow to verify (requires setup) |
| **Impact if true** | Explains all symptoms | Only explains some symptoms |
| **Reversibility** | Test is non-destructive | Test might cause side effects |

### The "What Changed?" Shortcut

Most bugs are caused by recent changes. Before forming complex hypotheses, check:

```
Quick "what changed?" checklist:
  1. git log --since="3 days ago" --oneline    → Recent code changes
  2. Deployment history                          → Recent deployments
  3. Configuration changes                       → Environment/config diffs
  4. Infrastructure changes                      → Cloud provider updates, scaling events
  5. Dependency updates                          → New library versions
  6. Data changes                                → New data patterns, migrations
  7. Traffic changes                             → Load spikes, new usage patterns
```

If the bug started at a specific time, correlate with these change sources. The temporal correlation is often the fastest path to root cause.

---

## 4. The One-Variable Rule

### The Rule

**Change exactly ONE variable per debugging attempt.**

### Why It Matters

```
Scenario: API returns 500 errors

Bad approach (multiple changes):
  Change 1: Increase database connection pool from 10 to 50
  Change 2: Add timeout to external API call
  Change 3: Fix null check in error handler
  Result: Bug is fixed. But which change fixed it?
  
  Problems:
  - You don't know the root cause
  - You may have introduced unnecessary changes
  - The pool increase might mask a connection leak
  - The null check fix might hide a deeper issue

Good approach (one variable):
  Attempt 1: Fix null check in error handler
  Result: Still fails, but error message changes — now shows "connection timeout"
  Learning: The null check was masking the real error
  
  Attempt 2: Add query plan analysis for the slow query
  Result: Full table scan detected on orders.user_id
  Learning: Missing index identified
  
  Attempt 3: Add index on orders.user_id
  Result: Bug fixed. p95 latency drops from 8s to 50ms.
  Root cause: Missing index confirmed
```

### One-Variable Exceptions

The one-variable rule has ONE exception: **incident response during active production outages.**

During incidents, speed matters more than root cause purity. Multiple changes are acceptable when:
1. Production is degraded and users are impacted
2. Changes are reversible (feature flags, rollbacks)
3. Each change is logged for post-incident analysis
4. Root cause investigation happens AFTER stabilization

---

## 5. Three-Failure Escalation Rule

### The Rule

**After 3 failed fix attempts on the same hypothesis, escalate.** Do not continue iterating on the same approach.

### The Escalation Decision

```
Attempt 1: Test hypothesis → Failed
  Action: Refine hypothesis based on new information

Attempt 2: Test refined hypothesis → Failed
  Action: Reconsider fundamental assumptions

Attempt 3: Test alternative hypothesis → Failed
  Action: ESCALATE — you are likely missing something fundamental
```

### Escalation Options

After 3 failures, choose one of:

| Option | When to Use | Action |
|--------|------------|--------|
| **Different specialist** | You suspect the root cause is outside your domain | Hand off to the relevant expert with your debugging state |
| **Pair debugging** | You might have a blind spot in your approach | Work with a peer who brings fresh eyes |
| **Reconsider hypothesis** | All your hypotheses have been wrong | Step back, re-gather evidence, form fundamentally different hypotheses |
| **Ask the user** | You need information you can't get from the system | Ask for reproduction steps, user context, business context |
| **Expand observation** | You don't have enough information to form good hypotheses | Add more logging, tracing, or monitoring before attempting fixes |

### Escalation State Handoff

When escalating to another expert, provide:

```markdown
## Debugging Escalation: {Issue Description}

### Current State
- **Symptom:** {What's happening}
- **When it started:** {Timestamp or trigger}
- **Reproduction steps:** {How to trigger it}

### What's Been Tried
| # | Hypothesis | Test | Result | Learning |
|---|-----------|------|--------|----------|
| 1 | {hypothesis} | {what was changed} | {outcome} | {what was learned} |
| 2 | {hypothesis} | {what was changed} | {outcome} | {what was learned} |
| 3 | {hypothesis} | {what was changed} | {outcome} | {what was learned} |

### Current Best Hypothesis
{What you think the cause is now, given all evidence}

### What You Haven't Tried
{Approaches you considered but didn't attempt, and why}

### Key Information
- Relevant logs: {location}
- Relevant code: {file:line}
- Relevant config: {location}
- Relevant metrics: {dashboard link}
```

---

## 6. Debugging State Tracking

### Why Track State

Debugging sessions can span hours or days. Without state tracking:
- You forget what you've already tried
- You repeat failed experiments
- You lose the thread of evidence when context-switching
- Handoffs to other experts lose accumulated knowledge

### Debugging State in Plan Artifacts

When a debugging session is part of a tracked plan, add a Debugging section:

```markdown
## Debugging: {Issue Title}

### Symptom
{Clear, specific description of what's wrong}

### Timeline
| Timestamp | Event |
|-----------|-------|
| {time} | Issue first reported |
| {time} | Reproduction confirmed |
| {time} | Hypothesis 1 tested — failed |
| {time} | Hypothesis 2 tested — failed |
| {time} | Escalated to {expert} |
| {time} | Root cause identified |
| {time} | Fix applied and verified |

### Evidence Gathered
| Source | Finding |
|--------|---------|
| Logs | {relevant log entries} |
| Metrics | {relevant metric observations} |
| Code review | {relevant code findings} |
| Git history | {relevant recent changes} |

### Hypotheses
| # | Hypothesis | Status | Evidence For | Evidence Against |
|---|-----------|--------|-------------|-----------------|
| 1 | {hypothesis} | {tested/rejected/confirmed} | {supporting evidence} | {contradicting evidence} |
| 2 | {hypothesis} | {tested/rejected/confirmed} | {supporting evidence} | {contradicting evidence} |

### Root Cause
{Final determination of what caused the issue}

### Fix Applied
{What was changed to fix it}

### Verification
{How the fix was verified — links to the completion report}
```

### State Tracking Discipline

| Debugging Phase | Track This |
|----------------|-----------|
| **Before first hypothesis** | Symptom description, reproduction steps, environment details |
| **Each hypothesis test** | Hypothesis, what was changed, result, learning |
| **After each attempt** | Updated evidence list, refined hypothesis |
| **After escalation** | Who was brought in, what new information they provided |
| **After fix** | Root cause, fix description, verification evidence |

---

## 7. Expert Escalation Paths

### Skill-to-Skill Escalation Matrix

When an expert encounters an issue outside their domain, they escalate to the appropriate specialist. This matrix defines the default escalation paths.

```
Debugging Expert         Escalate To              When
──────────────────       ────────────────          ──────────────────────────
frontend-architect   →   backend-architect         API not returning expected data
                     →   database-architect         Query performance issue visible in UI
                     →   devops-engineer            Build/deployment failures
                     →   sre-engineer               CDN or hosting issues

backend-architect    →   database-architect         Slow queries, connection issues, data integrity
                     →   sre-engineer               Infrastructure failures, resource exhaustion
                     →   security-engineer           Auth bypass, token issues, CORS problems
                     →   devops-engineer            Container/deployment issues
                     →   system-architect            Service communication failures

database-architect   →   sre-engineer               Replication lag, cluster health
                     →   devops-engineer            Backup/restore failures, infrastructure
                     →   backend-architect           Application-level connection management

security-engineer    →   backend-architect           Implementation details of auth flow
                     →   devops-engineer            Infrastructure security configuration
                     →   sre-engineer               WAF/DDoS/network-level security events

devops-engineer      →   sre-engineer               Production infrastructure instability
                     →   security-engineer           Container/pipeline security issues
                     →   backend-architect           Application configuration issues

sre-engineer         →   backend-architect           Application-level performance issues
                     →   database-architect           Database-level performance issues
                     →   devops-engineer            Deployment/rollback issues
                     →   security-engineer           Security incident during operations

mobile-architect     →   backend-architect           API compatibility issues
                     →   security-engineer           Mobile auth, certificate pinning issues
                     →   devops-engineer            App store / build pipeline issues

ai-ml-engineer       →   backend-architect           Inference serving performance
                     →   database-architect           Vector database / data pipeline issues
                     →   sre-engineer               Model serving infrastructure issues
                     →   devops-engineer            ML pipeline / training infrastructure
```

### Domain Architect Escalation

Domain architects escalate to core teams for implementation-level issues:

| Domain Architect | Escalates To | For |
|-----------------|-------------|-----|
| `e-commerce-architect` | `backend-architect` | Payment gateway integration issues |
| `e-commerce-architect` | `database-architect` | Inventory consistency, order data issues |
| `fintech-architect` | `security-engineer` | Compliance, encryption, audit trail issues |
| `fintech-architect` | `database-architect` | Ledger consistency, transaction isolation |
| `healthcare-architect` | `security-engineer` | HIPAA compliance, PHI handling issues |
| `healthcare-architect` | `backend-architect` | HL7/FHIR integration issues |
| `saas-architect` | `database-architect` | Tenant isolation, cross-tenant data leaks |
| `saas-architect` | `backend-architect` | Multi-tenant middleware issues |
| `real-time-architect` | `sre-engineer` | WebSocket scaling, connection management |
| `real-time-architect` | `backend-architect` | Message ordering, delivery guarantees |
| `social-platform-architect` | `database-architect` | Feed query performance, fan-out issues |
| `social-platform-architect` | `sre-engineer` | Content delivery, caching infrastructure |

---

## 8. Common Debugging Patterns by Domain

### Frontend Debugging Patterns

| Symptom | Common Causes | Debugging Approach |
|---------|--------------|-------------------|
| Blank page / white screen | JS error in render, failed module import | Check console errors, verify build output |
| Infinite re-renders | State update inside useEffect without deps, circular state | React DevTools profiler, add render counts |
| Stale data | Missing cache invalidation, stale closure | Check data fetching hooks, verify cache keys |
| Layout broken on mobile | Missing viewport meta, CSS overflow, fixed positioning | Device emulation, responsive breakpoint testing |
| Slow initial load | Large bundle, render-blocking resources, no code splitting | Lighthouse audit, bundle analyzer, network waterfall |

### Backend Debugging Patterns

| Symptom | Common Causes | Debugging Approach |
|---------|--------------|-------------------|
| 500 errors intermittent | Connection pool exhaustion, timeout, race condition | Check connection metrics, add request tracing |
| Memory leak | Unclosed connections, growing cache, event listener leak | Heap profiling over time, GC analysis |
| Slow endpoint | N+1 queries, missing index, large payload | Query logging, EXPLAIN ANALYZE, payload size check |
| Auth failures | Token expiry, clock skew, key rotation | Check token claims, verify system clocks, check key versions |
| Data inconsistency | Race condition, missing transaction, eventual consistency lag | Add transaction tracing, check isolation levels |

### Database Debugging Patterns

| Symptom | Common Causes | Debugging Approach |
|---------|--------------|-------------------|
| Slow queries | Missing index, stale statistics, lock contention | EXPLAIN ANALYZE, pg_stat_statements, lock monitoring |
| Connection exhausted | Pool too small, connection leak, long-running queries | Pool metrics, active connection list, query duration |
| Replication lag | Write-heavy workload, network issues, large transactions | Replication metrics, WAL monitoring, transaction sizes |
| Data corruption | Missing constraint, concurrent update, migration bug | Constraint validation queries, WAL analysis, migration audit |
| Deadlocks | Circular lock dependencies, inconsistent lock ordering | Deadlock logs, lock graph analysis, transaction ordering |

### Infrastructure Debugging Patterns

| Symptom | Common Causes | Debugging Approach |
|---------|--------------|-------------------|
| Pod crash loops | OOM kill, failed health check, missing config | `kubectl logs`, `kubectl describe pod`, resource limits |
| Deployment stuck | Readiness probe failing, insufficient resources | Pod events, resource quotas, probe endpoint check |
| Network timeout | Security group rules, DNS resolution, service discovery | `traceroute`, DNS lookup, security group audit |
| Certificate errors | Expired cert, wrong domain, missing intermediate | `openssl s_client`, cert chain verification |
| Disk full | Log accumulation, temp files, large artifacts | `du -sh`, log rotation config, cleanup policies |

---

## 9. Debugging Anti-Patterns

### What NOT to Do

| Anti-Pattern | Description | Correct Approach |
|-------------|-------------|-----------------|
| **Shotgun debugging** | Changing multiple things at once hoping something works | Change ONE variable, test, observe |
| **Blame-driven debugging** | "It must be the library's fault" / "It worked yesterday" | Evidence-driven investigation regardless of assumptions |
| **Fix-and-pray** | Applying a fix without understanding why it works | Understand the root cause before claiming the fix is correct |
| **Log-and-hope** | Adding logging everywhere without a hypothesis | Add targeted logging to test a specific hypothesis |
| **Restart-first** | Restarting the service before investigating | Capture state (logs, metrics, heap dump) BEFORE restarting |
| **Configuration whack-a-mole** | Randomly tweaking configuration values | Understand what each configuration controls before changing it |
| **Tunnel vision** | Only looking at the component you suspect | Widen the investigation if initial suspects don't pan out |
| **Stack Overflow copy-paste** | Copying fixes without understanding them | Understand WHY a fix works before applying it |
| **Silent revert** | Reverting a change without understanding why it broke things | Investigate the regression, add a test, then fix or revert with explanation |
| **Infinite loop debugging** | Spending hours on the same approach without progress | Apply the 3-failure escalation rule |

---

## 10. Root Cause Verification

### How to Verify You Found the Real Root Cause

A fix is only verified when ALL of these are true:

```
Root Cause Verification Checklist:
  [x] The fix explains ALL observed symptoms (not just some)
  [x] The fix can be explained mechanistically (you understand WHY it works)
  [x] Removing the fix re-introduces the bug (reversibility test)
  [x] A regression test captures the bug and passes with the fix
  [x] No other symptoms have appeared as a side effect of the fix
  [x] The fix addresses the root cause, not just a symptom
```

### The Reversibility Test

The strongest verification of a root cause fix:

```
Step 1: Confirm the bug exists (reproduction)
Step 2: Apply the fix
Step 3: Confirm the bug is gone
Step 4: Remove the fix
Step 5: Confirm the bug returns     ← This step is critical
Step 6: Re-apply the fix
Step 7: Confirm the bug is gone again
```

If removing the fix does NOT re-introduce the bug, either:
- Your fix isn't fixing what you think it's fixing
- Something else changed that fixed it
- The bug was intermittent and you got lucky

### Fix Quality Levels

| Level | Description | Acceptable? |
|-------|------------|-------------|
| **Band-aid** | Addresses symptom, root cause unknown | Only during active incidents |
| **Targeted fix** | Addresses direct cause, root cause understood | Acceptable for most bugs |
| **Root cause fix** | Addresses underlying system flaw | Ideal for all bugs |
| **Systemic fix** | Fixes root cause + adds prevention for the class of bugs | Gold standard |

---

## 11. Post-Debug Actions

### After Every Bug Fix

Every resolved debugging session should result in:

| Action | Owner | When |
|--------|-------|------|
| **Regression test** | Implementer | Immediately — part of the fix |
| **Completion report** | Implementer | Immediately — using the verification protocol |
| **Plan artifact update** | `etyb` | Same day — if part of a tracked plan |
| **Process improvement** | `etyb` | Follow-up — if a process gap was identified |
| **Monitoring improvement** | `sre-engineer` | Follow-up — if the bug could have been caught by monitoring |

### When to Write a Post-Mortem

Not every bug needs a post-mortem. Use this criteria:

| Factor | Post-Mortem? |
|--------|-------------|
| User-facing production outage > 5 minutes | Yes |
| Data loss or corruption | Yes |
| Security vulnerability exploited | Yes |
| Same bug recurred after being "fixed" | Yes |
| Bug took > 3 escalations to resolve | Yes |
| Bug exposed a systemic process gap | Yes |
| Minor bug, quickly fixed, no user impact | No |

### Knowledge Capture

After resolving a non-trivial bug, capture the knowledge for the team:

```markdown
## Bug Knowledge: {Title}

### TL;DR
{One sentence: what happened and why}

### Symptoms
{What the user/system experienced}

### Root Cause
{What actually went wrong at the deepest level}

### How It Was Found
{The debugging path — which hypotheses were tested, what worked}

### How It Was Fixed
{The specific change and why it addresses the root cause}

### How to Prevent Recurrence
{Process, tooling, or architectural changes to prevent this class of bug}
```

---

## 12. Debugging Decision Trees

### "Where Is the Problem?" Decision Tree

```
User reports a problem
        │
        ▼
Can you reproduce it?
  │              │
  Yes            No
  │              │
  ▼              ▼
  │         Gather more info:
  │         - Error logs
  │         - User steps
  │         - Environment details
  │         - Frequency and pattern
  │              │
  │              ▼
  │         Can you reproduce NOW?
  │           │           │
  │           Yes         No → Add targeted logging,
  │           │                 wait for recurrence
  │           │
  ▼           ▼
Is the error message helpful?
  │              │
  Yes            No
  │              │
  ▼              ▼
Follow the       Add debugging output:
stack trace      - Request/response logging
to the source    - State inspection
  │              - Metric collection
  │              │
  ▼              ▼
Form hypothesis about root cause
        │
        ▼
Test ONE variable
        │
        ▼
Did it fix the problem?
  │              │
  Yes            No
  │              │
  ▼              ▼
Verify fix       Attempt count?
(Section 10)       │         │
                 < 3        ≥ 3
                   │         │
                   ▼         ▼
              New hypothesis  ESCALATE
              (back to top)   (Section 5)
```

### "Who Should Debug This?" Decision Tree

```
Bug identified
      │
      ▼
Where does the symptom appear?
      │
      ├── Browser/UI → frontend-architect
      │                    └── If API data issue → escalate to backend-architect
      │
      ├── API response → backend-architect
      │                    ├── If query issue → escalate to database-architect
      │                    ├── If auth issue → escalate to security-engineer
      │                    └── If infra issue → escalate to sre-engineer
      │
      ├── Database → database-architect
      │                 └── If application-generated bad data → escalate to backend-architect
      │
      ├── Infrastructure → sre-engineer
      │                       ├── If deployment issue → escalate to devops-engineer
      │                       └── If security event → escalate to security-engineer
      │
      ├── Build/Deploy → devops-engineer
      │                     └── If code compilation error → escalate to relevant dev team
      │
      ├── Security event → security-engineer
      │                       └── If needs code fix → escalate to relevant dev team
      │
      └── Unknown origin → sre-engineer (triage first)
                              └── Route to appropriate expert after initial diagnosis
```

### "Is This Really Fixed?" Decision Tree

```
Fix applied
      │
      ▼
Does the bug still reproduce?
  │              │
  Yes            No
  │              │
  ▼              ▼
Fix is wrong.    Remove the fix temporarily.
Go back to       Does the bug come back?
hypothesis.        │              │
                   Yes            No
                   │              │
                   ▼              ▼
            Fix is correct.   Fix is coincidental.
            Continue to       Something else changed.
            verify.           Investigate further.
                   │
                   ▼
            Regression test written?
              │              │
              Yes            No
              │              │
              ▼              ▼
        Does test fail      Write a test that
        without the fix?    fails without the fix.
          │         │         │
          Yes       No        ▼
          │         │       Test captures
          ▼         ▼       the bug?
     Fix verified.  Test is    │        │
     Write         not         Yes      No
     completion    testing      │        │
     report.       the right    ▼        ▼
                   thing.   Continue.  Improve test
                   Improve            until it does.
                   the test.
```
