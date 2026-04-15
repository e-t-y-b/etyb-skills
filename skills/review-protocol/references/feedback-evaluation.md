# Feedback Evaluation: How to Receive and Respond to Review Feedback

This reference covers the complete workflow for receiving review feedback -- evaluating each finding on its merits, pushing back when wrong, fixing what is valid, and documenting the outcome. This is the most important reference in the review-protocol skill because it is where intellectual honesty either happens or does not.

## The Evaluation Framework

For EACH finding in a review, follow this five-step process. Do not skip steps. Do not batch findings. Each finding gets individual treatment.

### Step 1: Read Completely Without Reacting

Read the entire finding before forming an opinion. Do not:
- Stop reading at the first sentence and start fixing
- Dismiss the finding because the first line sounds wrong
- Start agreeing because the reviewer sounds confident

The reviewer may have nuanced reasoning that only becomes clear in the full explanation. A finding that sounds wrong in the first sentence may be correct when you understand the full argument.

### Step 2: Restate What the Reviewer Is Suggesting

Before evaluating, restate the finding in your own words. This serves two purposes:
1. It confirms you understood the finding correctly
2. It exposes misunderstandings early

**Template:**
```
The reviewer is suggesting that [specific change] because [their reasoning].
This would affect [specific code/behavior].
```

**Example:**
```
The reviewer is suggesting that the rate limiter should use a sliding window
instead of a fixed window because fixed windows allow burst traffic at window
boundaries. This would affect the token bucket implementation in
src/rate-limiter.ts lines 23-45.
```

If you cannot restate the finding clearly, you do not understand it yet. Re-read or ask for clarification.

### Step 3: Verify Against Codebase Reality

The reviewer may be working from assumptions that do not match the actual codebase. Before accepting or rejecting a finding, verify:

- **Does the code the reviewer references actually exist?** Subagent reviewers may hallucinate file names or line numbers.
- **Is the reviewer's understanding of the code correct?** They may have misread the control flow or missed a guard clause.
- **Does the issue actually manifest?** A theoretical concern may be prevented by other code the reviewer did not see.
- **Are the reviewer's assumptions about the runtime environment correct?** They may assume a different deployment model, database, or framework version.

**Verification actions:**
```bash
# Verify the code exists and matches what the reviewer describes
cat -n src/rate-limiter.ts | head -60

# Check if a guard clause exists that the reviewer missed
grep -n "if.*null\|if.*undefined\|if.*empty" src/rate-limiter.ts

# Verify the dependency version the reviewer assumes
grep "rate-limiter" package.json

# Run the specific test the reviewer claims would fail
npm test -- --grep "rate limiter"

# Check if the issue manifests in practice
npm run test:integration -- --grep "boundary"
```

### Step 4: Evaluate Technical Soundness in Context

Even if the reviewer's observation is factually correct, the suggestion may not be the right action in context. Evaluate:

- **Does the suggestion improve the code in a way that matters?** A technically correct observation that has no practical impact is a nit, not a must-fix.
- **Does the suggestion fit the project's constraints?** Perfect is the enemy of shipped. A suggestion that requires 3 days of work for marginal improvement may not be worth it.
- **Does the suggestion account for the design intent?** The reviewer may suggest something that contradicts a deliberate tradeoff documented in the plan.
- **Is the suggestion consistent with the project's patterns?** A suggestion that introduces a pattern used nowhere else in the codebase may create more confusion than it solves.
- **Does the suggestion work with the actual tech stack?** A reviewer may suggest an approach that works in one framework but not the one being used.

### Step 5: Respond with ONE of Three Options

Every finding gets exactly one response. No ambiguity.

#### Option A: Agree + Fix

The finding is correct. The code should change.

**When to use:**
- The finding identifies a real bug, vulnerability, or correctness issue
- The suggestion improves the code and the improvement justifies the effort
- The finding aligns with project patterns and constraints

**How to respond:**
```markdown
### Finding: [Title]
**Assessment:** Agree + Fix
**Action:** [Specific change made]
**Evidence:** [How you verified the fix is correct]
```

**Example:**
```markdown
### Finding: N+1 query in user listing
**Assessment:** Agree + Fix
**Action:** Added select_related('profile') and prefetch_related('roles')
to the user queryset. Replaced per-row queries with annotated counts.
**Evidence:** Query count dropped from 1+N to 3 constant queries.
Verified with django-debug-toolbar. Integration test added:
test_user_list_query_count.
```

Do NOT say "Great catch!" or "You're absolutely right!" Acknowledge through action, not gratitude.

#### Option B: Agree + Defer

The finding is correct, but fixing it now is not the right action.

**When to use:**
- The finding is valid but not blocking (minor or nit severity)
- The fix is outside the scope of the current change
- The fix requires coordination with other work (e.g., a planned refactor)
- The fix has dependencies that are not yet in place

**How to respond:**
```markdown
### Finding: [Title]
**Assessment:** Agree + Defer
**Action:** Deferred to [ticket/issue reference]
**Reason:** [Why deferral is appropriate]
**Tracking:** [How this will be tracked to prevent it from being forgotten]
```

**Example:**
```markdown
### Finding: Rate limiter should support weighted requests
**Assessment:** Agree + Defer
**Action:** Deferred to PROJ-456
**Reason:** Weighted rate limiting requires API endpoint classification
that is planned for Sprint 12. Current uniform rate limiting is correct
for the current use case (all endpoints have similar cost).
**Tracking:** Added to Sprint 12 backlog with link to this review finding.
```

**Rules for deferral:**
- Must-fix (critical) findings CANNOT be deferred. Period.
- Should-fix (major) findings can be deferred only with a documented ticket and timeline.
- Minor and nit findings can be deferred freely.
- Every deferred finding must be tracked -- review debt is real debt.

#### Option C: Disagree + Explain

The finding is wrong, inapplicable, or the suggestion would make the code worse.

**When to use:**
- The reviewer misunderstood the code or its context
- The suggestion breaks existing functionality
- The suggestion violates a deliberate design decision
- The suggestion adds complexity for theoretical benefit
- The reviewer's assumption about the runtime environment is wrong

**How to respond:**
```markdown
### Finding: [Title]
**Assessment:** Disagree + Explain
**Reason:** [Why the finding does not apply or the suggestion is wrong]
**Evidence:** [Concrete proof: test results, documentation, benchmarks, code references]
```

**Example:**
```markdown
### Finding: Use sliding window instead of fixed window rate limiting
**Assessment:** Disagree + Explain
**Reason:** The boundary burst concern does not apply here. Our rate
limiter uses a token bucket algorithm (not fixed window), which inherently
handles burst smoothing. The token refill rate provides the sliding
behavior the reviewer is looking for.
**Evidence:** See src/rate-limiter.ts line 28: `refillRate: tokensPerSecond`
implements continuous refill. Load test results in tests/load/results.json
show p99 rate limiting activates within 50ms of threshold regardless of
timing relative to any window boundary.
```

**Rules for disagreement:**
- Never disagree based on opinion alone. Provide evidence.
- Never disagree to avoid work. If the suggestion is correct but inconvenient, that is Agree + Defer, not Disagree.
- Never disagree because "it works." Working code can still be wrong.
- Always explain WHY you disagree, not just THAT you disagree.

## Red Flags: Performative Agreement

These phrases and behaviors indicate that feedback is being accepted without evaluation. If you catch yourself doing any of these, stop and restart the evaluation framework.

### Dangerous Phrases

| Phrase | Why It Is Dangerous |
|--------|-------------------|
| "Great catch!" | You have not evaluated the finding yet. You are performing gratitude. |
| "You're absolutely right!" | You have not verified against the codebase yet. |
| "Excellent point!" | Flattery is not evaluation. |
| "I'll fix that right away!" | You are skipping the verify step. The suggestion may be wrong. |
| "Thanks for the thorough review!" | This is filler. Address the findings individually. |
| "I agree with all your points." | You have not evaluated each finding individually. |
| "I'll fix everything you mentioned." | Batch agreement is not evaluation. Some findings may be wrong. |
| "Good eye!" | You are complimenting the reviewer instead of evaluating the code. |

### Dangerous Behaviors

| Behavior | Why It Is Dangerous |
|----------|-------------------|
| Implementing a suggestion without running existing tests | The suggestion may break something. |
| Accepting all findings in a batch | Some findings may contradict each other. |
| Not verifying the reviewer's code references | Subagent reviewers may hallucinate line numbers. |
| Changing code you do not understand | You now own code you cannot maintain. |
| Agreeing faster when the reviewer sounds confident | Confidence is not correctness. |
| Agreeing to avoid conflict | The codebase does not benefit from diplomatic lies. |
| Making a change without understanding why | You have learned nothing and will repeat the mistake. |

### Self-Check Questions

Before responding to any finding, ask yourself:

1. Did I read the entire finding before forming an opinion?
2. Can I restate what the reviewer is suggesting in my own words?
3. Did I verify the finding against the actual codebase?
4. Am I agreeing because the suggestion is correct, or because the reviewer sounds confident?
5. If I am disagreeing, do I have evidence (not just opinions)?
6. If I am deferring, do I have a tracking mechanism?

If the answer to any of these is "no," you are not done evaluating.

## When to Push Back

Push back is not confrontation. It is intellectual honesty. The reviewer wants the code to be correct -- if their suggestion would make it worse, telling them is a service, not an insult.

### Mandatory Push Back Scenarios

You MUST push back (Disagree + Explain) when:

#### 1. The Suggestion Breaks Existing Tests

```markdown
**Assessment:** Disagree + Explain
**Reason:** Implementing this suggestion causes 3 existing tests to fail:
- test_rate_limiter_token_refill: Expects continuous refill, suggestion changes to discrete
- test_rate_limiter_concurrent: Race condition introduced by suggested locking change
- test_rate_limiter_overflow: Boundary handling differs in suggested algorithm
**Evidence:** Test run output attached. The current implementation passes all
47 unit tests and 12 integration tests.
```

#### 2. The Suggestion Violates YAGNI

```markdown
**Assessment:** Disagree + Explain
**Reason:** The suggestion to add a plugin system for rate limiting algorithms
adds 200+ lines of abstraction for a single concrete implementation. We have
no current or planned need for multiple rate limiting algorithms. If this need
arises, we can extract the interface then.
**Evidence:** Product roadmap through Q3 shows no rate limiting algorithm changes.
The current token bucket algorithm meets all documented requirements.
```

#### 3. The Suggestion Adds Complexity for Theoretical Benefits

```markdown
**Assessment:** Disagree + Explain
**Reason:** The suggestion to replace the in-memory cache with a distributed
cache assumes multi-instance deployment. We currently run a single instance
and have no plans to scale horizontally before Q4. Adding Redis as a dependency
increases operational complexity and introduces a new failure mode with no
current benefit.
**Evidence:** Architecture decision ADR-023 specifies single-instance deployment
through Q3. The migration to distributed caching is planned for the horizontal
scaling initiative.
```

#### 4. The Suggestion Is Based on Outdated Information

```markdown
**Assessment:** Disagree + Explain
**Reason:** The suggestion to use `request.user.is_authenticated()` (method call)
applies to Django < 1.10. Since Django 1.10, `is_authenticated` is a property,
not a method. Our project uses Django 4.2.
**Evidence:** Django docs: https://docs.djangoproject.com/en/4.2/ref/contrib/auth/
We use Django 4.2 (see requirements.txt line 3).
```

#### 5. The Suggestion Contradicts the Design Intent

```markdown
**Assessment:** Disagree + Explain
**Reason:** The suggestion to use application-level rate limiting contradicts
the design decision to use infrastructure-level rate limiting (API gateway).
This decision was made at the Design gate because: (a) it provides rate
limiting before requests reach the application, (b) it allows rate limit
changes without deployment, (c) it provides consistent rate limiting across
all services.
**Evidence:** See plan artifact decision log entry DL-007: "Rate limiting
implemented at API gateway layer, not application layer."
```

### Appropriate Push Back Scenarios

You SHOULD push back (but can defer if the finding is low-severity) when:

- The suggestion is stylistically different but not objectively better
- The suggestion optimizes code that is not on a hot path
- The suggestion introduces a dependency for marginal benefit
- The suggestion changes an API contract that consumers depend on
- The suggestion assumes a different usage pattern than documented

### When NOT to Push Back

Do NOT push back when:

- The finding is correct and you just do not want to do the work
- The finding is correct but you find the reviewer's tone annoying
- The finding duplicates something you already planned to fix (just say "already planned")
- The finding is minor and fixing it takes less time than arguing

## Handling Different Reviewer Types

The evaluation framework applies to all reviewers, but the verification intensity varies.

### Human Partner (High Trust)

**Trust level:** High -- they understand the codebase and context.

**Verification intensity:** Standard. Verify the technical suggestion is correct, but trust their understanding of the codebase.

**Push back style:** Direct and collaborative. "I see your point about X, but I think Y because Z. What do you think?"

**Common pattern:** Human reviewers are more likely to catch design-level issues that require context. Take architecture and design feedback seriously.

**Watch for:** Even trusted reviewers can be wrong. Do not skip verification because you respect the reviewer.

### Subagent Reviewer (Verify More Carefully)

**Trust level:** Medium -- they are technically competent but have limited context and may hallucinate.

**Verification intensity:** High. Verify every factual claim:
- Do the files and line numbers the reviewer references actually exist?
- Does the code behave the way the reviewer claims?
- Are the framework APIs the reviewer suggests real and current?
- Does the alternative approach the reviewer suggests actually work?

**Push back style:** Factual. "The file src/foo.ts does not have a function bar() at line 42. The relevant function is baz() at line 38."

**Common patterns subagents get wrong:**
- Line numbers (frequently off or hallucinated)
- Framework API details (may suggest deprecated or non-existent APIs)
- Project structure assumptions (may reference files that do not exist)
- Performance claims without benchmarks (may claim something is "slow" without evidence)
- Suggesting changes that break other code they did not see

**Watch for:** Subagents are confident even when wrong. Do not treat confidence as evidence. Verify with the actual codebase.

### External Reviewer (Highest Scrutiny)

**Trust level:** Low -- they may not understand the project's context, conventions, or constraints.

**Verification intensity:** Highest. Verify everything, including whether the reviewer's frame of reference matches your project.

**Push back style:** Explanatory. Provide context the external reviewer may lack. "In our project, we use pattern X because of constraint Y. The suggestion to use pattern Z would not work because of Y."

**Common patterns with external reviewers:**
- Applying conventions from their own projects that do not fit yours
- Suggesting "best practices" that are inappropriate for your scale or context
- Not understanding deliberate tradeoffs documented in your decision log
- Expecting patterns from a different framework or language version
- Over-engineering for a scale you do not have and may never reach

**Watch for:** External reviewers may have valuable outside perspective. Do not dismiss all their feedback just because some of it is context-inappropriate.

## Multi-Finding Responses

When a review contains multiple findings, address each one individually. Never batch.

### Structure for Multi-Finding Responses

```markdown
## Review Response: [Review Title]

**Review received:** [date/time]
**Total findings:** [N]
**Response summary:** [X fixed, Y deferred, Z pushed back]

---

### Finding 1: [Title from reviewer]
**Severity:** [must-fix / should-fix / suggestion / nit]
**Assessment:** [Agree + Fix / Agree + Defer / Disagree + Explain]
**Action:** [Specific action taken or reason for non-action]
**Evidence:** [Test result, benchmark, code reference, or documentation]

---

### Finding 2: [Title from reviewer]
**Severity:** [must-fix / should-fix / suggestion / nit]
**Assessment:** [Agree + Fix / Agree + Defer / Disagree + Explain]
**Action:** [Specific action taken or reason for non-action]
**Evidence:** [Test result, benchmark, code reference, or documentation]

---

[... repeat for each finding ...]

---

### Summary
| Category | Count | Details |
|----------|-------|---------|
| Fixed | X | [Brief list] |
| Deferred | Y | [Ticket references] |
| Pushed back | Z | [Brief reasons] |

### Re-Review Needed?
[Yes -- significant changes made / No -- only minor fixes / Partial -- only finding N needs re-verification]
```

### Ordering Multi-Finding Responses

Address findings in this order:
1. **Must-fix (critical)** -- these block merge, address first
2. **Should-fix (major)** -- these should be fixed before merge
3. **Suggestions (minor)** -- address after critical and major items
4. **Nits** -- address last or batch with "Acknowledged, will clean up"

### When Findings Conflict

If two findings in the same review contradict each other, note the conflict:

```markdown
### Findings 3 and 5: Conflict Detected
**Finding 3** suggests extracting the validation logic into a separate module.
**Finding 5** suggests inlining the validation to reduce indirection.
These are contradictory. I am proceeding with Finding 3 (extraction) because
it aligns with the project's separation of concerns pattern and the plan's
architecture decision DL-012.
```

## Response Template

Use this template for every feedback response:

```markdown
## Review Response: [Title matching the review request]

**Review from:** [reviewer name/type]
**Date:** [date]
**Total findings:** [N]

### Finding 1: [Reviewer's finding title]
**Severity:** [must-fix / should-fix / suggestion / nit]
**Assessment:** Agree + Fix / Agree + Defer / Disagree + Explain
**Action:** [What was done or why it was not done]
**Evidence:** [Test result, benchmark, documentation, or code reference]

[Repeat for each finding]

### Summary
- **Fixed:** [count] -- [brief list]
- **Deferred:** [count] -- [ticket references]
- **Pushed back:** [count] -- [brief reasons]
- **Re-review needed:** [Yes/No/Partial]

### Verification
- All existing tests still passing: [Yes/No]
- New tests added for fixes: [Yes/No, count]
- Coverage impact: [unchanged / +X% / -X%]
```
