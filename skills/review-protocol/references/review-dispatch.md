# Review Dispatch: How to Request a Code Review

This reference covers the complete workflow for requesting a code review -- constructing focused context, dispatching code-reviewer through an independent review runtime, and avoiding common dispatch mistakes.

## Context Construction

The quality of a code review is determined by the quality of the request. A reviewer with perfect skills and terrible context will produce a terrible review. Your job is to give the reviewer exactly what they need and nothing they do not.

### What the Reviewer Needs

Every review request must include these five elements:

#### 1. The Diff or Commit Range

The reviewer needs to see exactly what changed. Provide one of:

- **Git diff**: `git diff main..feature-branch` for the full changeset
- **Specific SHAs**: `git diff abc123..def456` for a targeted range
- **File list with changes**: When the diff is too large, summarize what changed in each file

For isolated review dispatch, include the actual diff content in the prompt. Do not tell the reviewer to "look at the latest changes" -- they have no persistent state.

```bash
# Generate a focused diff for the review request
git diff main..HEAD --stat          # Overview of changed files
git diff main..HEAD -- src/         # Only source code changes
git diff main..HEAD -- '*.ts'       # Only TypeScript files
```

**Size guidance:**
- Under 400 lines of diff: include the full diff
- 400-1000 lines: include the diff but highlight the critical sections
- Over 1000 lines: break into multiple review requests by module or concern

#### 2. Design Intent

What were you trying to achieve and why? This is the most undervalued part of a review request. Without it, the reviewer is reverse-engineering your intent from the code.

Good design intent:
```
We're adding rate limiting to the /api/search endpoint because load testing
showed it's our most expensive query (p99 = 2.3s) and a single user can
currently DoS the service. We chose a token bucket algorithm with Redis
backing because we need distributed rate limiting across 4 API pods.
```

Bad design intent:
```
Added rate limiting.
```

The design intent should answer:
- What problem does this solve?
- Why this approach over alternatives considered?
- What tradeoffs were made deliberately?
- What constraints drove the design?

#### 3. Test Results

What testing has been done? This tells the reviewer what level of confidence already exists.

```markdown
### Test Results
- Unit tests: 47 passing, 0 failing
- Integration tests: 12 passing, 0 failing
- Coverage on changed files: 87%
- New tests added: 8 unit tests for rate limiter logic, 3 integration tests for Redis interaction
- Manual testing: Verified rate limiting triggers correctly with k6 load test (50 rps threshold)
```

Include:
- Pass/fail counts for each test type
- Coverage percentage on changed code specifically (not project-wide)
- What new tests were added and what they cover
- Any manual testing performed

#### 4. Specific Concerns

Where do you want the reviewer to focus? This is the difference between a rubber-stamp review and a valuable one.

Good specific concerns:
```
1. The error handling in src/rate-limiter.ts lines 45-67 -- I'm not sure the
   Redis connection failure fallback is correct. Should we fail open or closed?
2. The token bucket implementation assumes all requests cost 1 token. Is this
   sufficient or should we weight by endpoint?
3. Thread safety -- I'm using Redis MULTI but unsure if there's a race condition
   between the GET and DECR operations.
```

Bad specific concerns:
```
Let me know if anything looks wrong.
```

#### 5. What NOT to Include

Actively exclude information that distracts the reviewer:

- **Full project history**: The reviewer does not need to know the project was started in 2019
- **Unrelated files**: Do not include changes from other feature branches
- **Generated files**: Exclude lock files, build artifacts, auto-generated code unless reviewing the generator
- **Boilerplate changes**: If you renamed a variable across 50 files, mention it once, do not include all 50 diffs
- **Personal context**: "I spent 3 days on this" is not useful review context

### Context Construction Checklist

Before dispatching a review, verify:

- [ ] Diff is scoped to only the relevant changes
- [ ] Design intent explains the why, not just the what
- [ ] Test results are current (run tests immediately before requesting review)
- [ ] At least one specific concern is articulated
- [ ] Excluded noise (unrelated files, generated code, boilerplate)
- [ ] Review focus is set (security, performance, correctness, architecture)

## Independent Reviewer Setup: Dispatching code-reviewer

When operating in the etyb-skills workflow, code-reviewer should run with isolated context. This means the reviewer has ONLY what you give it -- no access to prior conversation, no implicit project knowledge.

### Dispatch Prompt Template

```markdown
You are performing a code review. Review the following changes across the
relevant dimensions (code quality, performance, security, architecture).

## Review Focus
[Primary]: [Security / Performance / Correctness / Architecture]
[Secondary]: [Optional second dimension]

## Design Intent
[What was implemented and why. What problem this solves. What tradeoffs
were made deliberately.]

## Changes
[The actual diff or code changes]

## Test Results
[Pass/fail counts, coverage, new tests added]

## Specific Concerns
1. [Area of uncertainty #1]
2. [Area of uncertainty #2]

## Review Instructions
- Categorize each finding by severity: must-fix, should-fix, suggestion, nit
- For each finding, state: what the issue is, why it matters, how to fix it
- Acknowledge what is done well (at least one positive observation)
- If any finding is critical severity, state clearly that this blocks merge
- Do not comment on formatting or style -- those are handled by automation
```

### Independent Review Dispatch Considerations

**Context window management:**
- The reviewer runtime has a fresh context window. Include all necessary information.
- Do not reference "the file we discussed earlier" -- include the code.
- If the project has conventions (naming, patterns, architecture rules), state them explicitly.

**Reviewer state:**
- The reviewer does not retain state between reviews. Each dispatch is independent.
- For re-reviews after fixes, include the original findings AND the changes made.
- Do not say "fix the issues from last review" -- restate what was found.

**Output format:**
- Request structured output so you can parse findings individually.
- Each finding should have: severity, category, description, suggestion.
- Request a summary verdict: APPROVED / APPROVED WITH COMMENTS / CHANGES REQUESTED.

### When to Include Additional Context

Sometimes the reviewer needs more than the diff:

| Situation | Additional Context |
|-----------|-------------------|
| New team member's code | Project conventions document, architecture overview |
| Complex algorithm | Link or description of the algorithm being implemented |
| Migration or refactor | Before/after architecture, migration plan |
| Security-sensitive code | Threat model, security requirements |
| Performance-critical code | Performance requirements, benchmarks, SLA targets |
| API changes | API contract, consumer list, versioning strategy |

## Severity Guidance: What to Ask the Reviewer to Focus On

Different changes need different review lenses. Set the primary focus explicitly.

### Security-Focused Review

Request when changes touch:
- Authentication or authorization logic
- User input handling (forms, API parameters, file uploads)
- Data encryption, hashing, or token generation
- Third-party integrations with secrets
- PII or financial data handling
- CORS, CSP, or other security headers

Dispatch guidance:
```markdown
## Review Focus
[Primary]: Security
[Secondary]: Code Quality

Focus the security review on:
- Injection vulnerabilities (SQL, XSS, SSRF, command injection)
- Authentication/authorization correctness
- Sensitive data exposure (logging, error messages, API responses)
- Input validation completeness
- Secrets management (no hardcoded secrets, proper env var usage)
```

### Performance-Focused Review

Request when changes touch:
- Database queries (new queries, query modifications, schema changes)
- Hot code paths (request handlers, event loops, rendering paths)
- Data structures or algorithms processing large datasets
- Caching logic
- Network calls or I/O operations
- Frontend rendering (component trees, re-render triggers)

Dispatch guidance:
```markdown
## Review Focus
[Primary]: Performance
[Secondary]: Code Quality

Focus the performance review on:
- Algorithmic complexity (Big-O analysis on data-dependent paths)
- N+1 queries or unnecessary database round-trips
- Memory allocation patterns (leaks, excessive allocations)
- Caching correctness (invalidation, stale data risks)
- I/O efficiency (connection pooling, batching, streaming)
```

### Correctness-Focused Review

Request when changes touch:
- Business logic or domain rules
- State machines or workflow engines
- Financial calculations or billing logic
- Edge cases in data processing
- Error handling and recovery paths
- Concurrency or distributed system logic

Dispatch guidance:
```markdown
## Review Focus
[Primary]: Correctness
[Secondary]: Architecture

Focus the correctness review on:
- Business rule implementation matches requirements
- Edge cases: null/empty inputs, boundary values, concurrent access
- Error handling: all failure modes covered, appropriate recovery
- State management: transitions are valid, no impossible states
- Data integrity: invariants maintained, no partial updates
```

### Architecture-Focused Review

Request when changes touch:
- Module boundaries or package structure
- API contracts (new endpoints, changed schemas)
- Dependency graph (new dependencies, changed import patterns)
- Design patterns (introducing or modifying patterns)
- Cross-cutting concerns (logging, monitoring, error handling strategy)

Dispatch guidance:
```markdown
## Review Focus
[Primary]: Architecture
[Secondary]: Code Quality

Focus the architecture review on:
- Separation of concerns (are responsibilities correctly distributed?)
- Coupling analysis (does this increase coupling between modules?)
- Pattern consistency (does this follow established project patterns?)
- API contract stability (are there breaking changes?)
- Dependency direction (do dependencies point inward?)
```

## When to Request Reviews

### Mandatory Review Points

| Trigger | Why | Tier |
|---------|-----|------|
| After completing a subagent task | Subagent output must be verified before integration | Any |
| Before merge to main/production branch | Last gate before code reaches users | Tier 2+ |
| At the Verify gate | Formal quality checkpoint in the plan lifecycle | Tier 3+ |
| At the Ship gate | Final sign-off before deployment | Tier 3+ |
| Any change to auth, payments, or PII handling | High-risk changes require review regardless of scope | Any tier |

### Recommended Review Points

| Trigger | Why |
|---------|-----|
| After major feature implementation | Catch design issues before they compound |
| Before large refactoring | Validate the approach before committing to it |
| When uncertain about a design decision | A second perspective prevents expensive mistakes |
| After fixing a production incident | Verify the fix is correct and complete |
| When introducing a new pattern | Ensure the pattern is appropriate and well-implemented |

### Self-Review Acceptable

| Situation | Conditions |
|-----------|------------|
| Tier 0 trivial changes | Config tweaks, typo fixes, comment updates |
| Tier 1 single-file changes | Simple, low-risk changes with test coverage |
| Documentation-only changes | No code changes, no risk to system behavior |

Even for self-review, run through the evaluation framework mentally. Do not skip the discipline just because there is no external reviewer.

## Review Request Template

Use this template for all review requests:

```markdown
## Review Request: [Descriptive Title]

**Reviewer:** [code-reviewer / specific person]
**Requested by:** [author]
**Tier:** [0-4]
**Urgency:** [Normal / Expedited (with reason)]

### Scope
**Commit range:** [SHA..SHA or branch comparison]
**Files changed:** [count]
**Lines changed:** +[additions] / -[deletions]

### Design Intent
[2-4 sentences: what problem this solves, why this approach, deliberate tradeoffs]

### Review Focus
**Primary:** [Security / Performance / Correctness / Architecture]
**Secondary:** [Optional]

### Changes Summary
| File/Module | Change | Why |
|-------------|--------|-----|
| [path] | [what changed] | [why it changed] |

### Test Results
- Unit tests: [pass/fail count]
- Integration tests: [pass/fail count]
- Coverage on changed code: [percentage]
- New tests: [count and what they cover]
- Manual testing: [what was verified manually]

### Specific Concerns
1. [Concern #1 with specific file/line references]
2. [Concern #2]

### Context NOT Needed
- [Excluded items: generated files, unrelated changes, etc.]

### Constraints
- [Any time constraints, deployment windows, dependencies]
```

## Common Mistakes in Requesting Reviews

### Mistake 1: Too Much Context (The Info Dump)

**Symptom:** Review request includes the entire project architecture, history, every file touched in the last month, and a 2000-line diff.

**Problem:** The reviewer cannot find the signal in the noise. Important issues get missed because attention is spread across irrelevant information.

**Fix:** Scope the diff to only the relevant changes. Include only the context necessary to understand the change. If the reviewer needs more, they will ask.

### Mistake 2: No Context (The Bare Diff)

**Symptom:** Review request is just a diff with no explanation of what changed or why.

**Problem:** The reviewer spends most of their time reverse-engineering intent rather than evaluating the implementation. They may miss issues because they do not understand the goal.

**Fix:** Always include design intent, test results, and at least one specific concern. Two paragraphs of context can save an hour of review time.

### Mistake 3: No Specific Concerns (The Rubber Stamp Request)

**Symptom:** "Can you review this?" with no indication of what you are worried about.

**Problem:** The reviewer does a surface-level scan because they have no anchor points. The review becomes a formality rather than a quality gate.

**Fix:** Identify at least one area where you are uncertain, one tradeoff you want validated, or one edge case you want checked. This focuses the reviewer on high-value areas.

### Mistake 4: Wrong Review Focus

**Symptom:** Requesting a general review for a security-critical change, or requesting a security review for a CSS change.

**Problem:** Review effort is misallocated. Critical dimensions get insufficient attention while irrelevant dimensions waste reviewer time.

**Fix:** Match the review focus to the change type. Use the review focus guidance in this document. For auth/payment/PII changes, ALWAYS set security as primary focus.

### Mistake 5: Requesting Review Too Late

**Symptom:** The entire feature is built before any review is requested. 2000+ lines of changes in a single review request.

**Problem:** Large reviews get superficial attention. The reviewer cannot hold the entire changeset in their head. Fundamental design issues discovered at this point require expensive rework.

**Fix:** Request reviews incrementally. After each logical unit of work (a module, a feature slice, an API endpoint), request a focused review before building the next piece.

### Mistake 6: Not Including Test Results

**Symptom:** Review request has no mention of testing. Reviewer does not know if tests exist, pass, or cover the changes.

**Problem:** The reviewer cannot assess the confidence level of the change. They may waste time pointing out issues that are already caught by tests, or miss issues they assume are tested.

**Fix:** Always run tests immediately before requesting review and include the results. Stale test results are worse than no test results -- they create false confidence.
