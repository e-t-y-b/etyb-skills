# Two-Stage Review: Quality Assurance for Subagent Output

This reference covers the two-stage quality gate for subagent output -- Stage 1 (spec conformance) verifies the agent did what was asked, and Stage 2 (quality review) verifies the work is good. Together they catch both functional deviations and quality issues before integration.

## Why Two Stages

A single review pass conflates two different questions:
1. Did the agent do what was asked? (spec conformance)
2. Is what the agent did any good? (quality)

These questions require different evaluation methods. Spec conformance is mechanical -- check each criterion in the task spec against the output. Quality review requires expertise -- code structure, performance implications, security considerations, maintainability. Separating them ensures neither is skipped.

| | Stage 1: Spec Conformance | Stage 2: Quality Review |
|---|---|---|
| **Question** | Did the agent do what was asked? | Is the work good? |
| **Who** | Dispatcher (you, following this protocol) | code-reviewer (dispatched via review-protocol) |
| **Method** | Checklist against task spec | Expert review with focused context |
| **Speed** | Fast (minutes) | Slower (depends on change size) |
| **Catches** | Scope creep, under-delivery, wrong files, missed criteria | Bugs, security issues, performance problems, bad patterns |
| **Always runs** | Yes -- mandatory for every subagent dispatch | Conditional -- see "When to Skip Stage 2" |

## Stage 1: Spec Conformance

Stage 1 is performed by the dispatcher (this protocol) immediately upon receiving agent output. It is a mechanical check -- no judgment calls, no quality assessment, just verification against the spec.

### Stage 1 Checklist

For each subagent's output, check the following:

#### 1. Success Criteria Verification

Go through each "Done when" criterion from the task spec:

```markdown
## Stage 1: Spec Conformance -- {Agent Name}

### Success Criteria Check
| # | Criterion | Met? | Evidence |
|---|-----------|------|----------|
| 1 | {criterion from spec} | YES/NO | {file/test that proves it} |
| 2 | {criterion from spec} | YES/NO | {file/test that proves it} |
| 3 | {criterion from spec} | YES/NO | {file/test that proves it} |
| 4 | All tests pass | YES/NO | {test output} |
```

Every criterion must have evidence. "The agent says it's done" is not evidence. Evidence is: a file exists, a test passes, output matches expected format.

#### 2. Scope Boundary Check

Verify the agent stayed within its designated scope:

```markdown
### Scope Check
| Check | Result |
|-------|--------|
| Files modified are within scope? | YES/NO -- {list any out-of-scope files} |
| No unrelated changes? | YES/NO -- {list any unrelated modifications} |
| Dependencies unchanged (or changes documented)? | YES/NO |
| Configuration files unchanged (unless specified)? | YES/NO |
```

#### 3. Deviation Detection

Check for three types of deviation:

**Scope creep** -- agent did more than asked:
- Added features not in the spec
- Modified files outside the scope boundary
- Introduced new dependencies without justification
- Added abstraction layers that weren't requested

**Under-delivery** -- agent did less than asked:
- Skipped success criteria (even with an explanation)
- Implemented partial solutions ("TODO" comments, placeholder code)
- Wrote tests that don't actually test the specified behavior
- Left error handling incomplete

**Lateral deviation** -- agent did something different than asked:
- Chose a different approach than specified
- Used a different library or pattern than the context packet indicated
- Changed the API contract or interface when it should have been kept stable
- Reinterpreted the task based on the agent's own judgment

#### 4. Handling Deviations

| Deviation Type | Action |
|---------------|--------|
| **Scope creep (agent explanation is valid)** | Evaluate: is the additional work correct and useful? If yes, accept and update the spec. If no, re-dispatch with stricter scope. |
| **Scope creep (no explanation)** | Re-dispatch with explicit constraints: "ONLY do X. Do NOT do Y. The previous output included {deviation} which was not requested." |
| **Under-delivery (agent flagged it)** | If the agent explains why criteria couldn't be met, evaluate: is the blocker real? If yes, resolve and re-dispatch. If no, re-dispatch with clarification. |
| **Under-delivery (agent didn't flag it)** | Re-dispatch with specific gaps identified: "The following criteria were not met: {list}. Complete these specific items." |
| **Lateral deviation (better approach)** | If the alternative approach is genuinely better, accept it. Update the spec to reflect the new approach. Document why the original approach was replaced. |
| **Lateral deviation (wrong approach)** | Re-dispatch with the original approach reinforced: "Use {specified approach}, not {agent's approach}. The reason is {justification}." |

### Stage 1 Outcome

Stage 1 produces one of three outcomes:

| Outcome | Meaning | Next Step |
|---------|---------|-----------|
| **PASS** | All criteria met, no deviations | Proceed to Stage 2 (or skip if eligible) |
| **MINOR_DEVIATIONS** | Criteria mostly met, deviations are acceptable | Accept deviations, proceed to Stage 2 |
| **FAIL** | Criteria not met, or unacceptable deviations | Re-dispatch with specific corrections (see Iteration Loop) |

## Stage 2: Quality Review

Stage 2 dispatches the `code-reviewer` skill (via `review-protocol`) to perform an expert quality review of the agent's output. This is not a re-check of spec conformance -- it's an evaluation of whether the work is good.

### Stage 2 Setup

Construct a review request with focused context:

```markdown
## Review Request for Subagent Output

### Design Intent
{What the agent was asked to do and why -- from the original task spec}

### Changes to Review
{List of files modified, with diff or full content}

### Original Task Specification
{The complete context packet given to the agent}

### Test Results
{Output of running the agent's tests}

### Specific Review Concerns
{Any concerns flagged by the agent (DONE_WITH_CONCERNS) or by Stage 1}

### Review Dimensions
Please review for:
1. **Correctness** -- Does the code do what the spec says? Are there logic errors?
2. **Performance** -- Are there N+1 queries, unnecessary allocations, or algorithmic issues?
3. **Security** -- Are there injection risks, auth bypasses, or data exposure?
4. **Maintainability** -- Is the code readable, well-structured, and following project patterns?
5. **Error handling** -- Are failure modes handled? Are errors informative?
```

### Stage 2 Review Dimensions

| Dimension | What to Look For | Severity if Found |
|-----------|-----------------|-------------------|
| **Correctness** | Logic errors, incorrect algorithms, wrong return types, missed edge cases | Critical -- must fix |
| **Performance** | N+1 queries, O(n^2) where O(n) is possible, memory leaks, unnecessary I/O | Important -- should fix |
| **Security** | SQL injection, XSS, auth bypass, sensitive data in logs, hardcoded secrets | Critical -- must fix |
| **Maintainability** | Unclear naming, deep nesting, god functions, missing abstractions | Advisory -- nice to fix |
| **Error handling** | Swallowed exceptions, generic error messages, missing validation | Important -- should fix |
| **Test quality** | Tests that don't test behavior, tests coupled to implementation, missing edge cases | Important -- should fix |

### Stage 2 Outcome

Stage 2 produces a review report with findings categorized by severity:

```markdown
## Stage 2 Review Report -- {Agent Name}

### Verdict: APPROVE / APPROVE_WITH_CONCERNS / REQUEST_CHANGES

### Critical Findings (must-fix)
- {finding}: {location}, {description}, {recommended fix}

### Important Findings (should-fix)
- {finding}: {location}, {description}, {recommended fix}

### Advisory Findings (nice-to-fix)
- {finding}: {location}, {description}, {recommended fix}

### Overall Assessment
{Summary of code quality, patterns observed, and confidence level}
```

| Verdict | Meaning | Next Step |
|---------|---------|-----------|
| **APPROVE** | No critical or important findings | Integrate the agent's output |
| **APPROVE_WITH_CONCERNS** | No critical findings, some important findings | Integrate, but address important findings in follow-up |
| **REQUEST_CHANGES** | Critical findings present | Re-dispatch agent with review findings (see Iteration Loop) |

## Iteration Loop

When either stage fails, the agent is re-dispatched with corrections. The iteration loop has a maximum depth to prevent infinite cycles.

### Stage 1 Failure: Re-Dispatch with Corrections

```markdown
## Re-Dispatch: {Agent Name} (Iteration {N}/2)

### Previous Output Summary
{Brief summary of what the agent produced}

### Stage 1 Findings
{Specific criteria that were not met}
{Specific deviations detected}

### Corrections Required
1. {Specific correction 1}
2. {Specific correction 2}
3. {Specific correction 3}

### Updated Constraints
{Any additional constraints based on the previous attempt}

### Original Task Spec
{Include the full original task spec -- the agent needs the complete context}
```

### Stage 2 Failure: Re-Dispatch with Review Findings

```markdown
## Re-Dispatch: {Agent Name} (Iteration {N}/2)

### Previous Output Summary
{Brief summary of what the agent produced}

### Stage 2 Review Findings
{Critical findings from code-reviewer}

### Corrections Required
1. {Address finding 1}: {specific fix expected}
2. {Address finding 2}: {specific fix expected}
3. {Address finding 3}: {specific fix expected}

### Additional Constraints
- All previous success criteria still apply
- These review findings are additional constraints on the implementation
- Prioritize critical findings over important findings

### Original Task Spec
{Include the full original task spec}
```

### Maximum Iteration Depth

- **Maximum 2 re-dispatches per agent** (total 3 attempts including the original)
- After 2 re-dispatches, escalate to ETYB

**Why 2?**
- Iteration 1 (original): agent's first attempt
- Iteration 2 (first re-dispatch): addresses specific, identified issues
- Iteration 3 (second re-dispatch): addresses any remaining gaps

If 3 attempts are not enough, the problem is one of:
- The task spec is ambiguous (fix the spec, not the agent)
- The task is too complex for a single agent (decompose further)
- The model is wrong for the task (upgrade to a more capable model)
- The task has hidden dependencies (resolve dependencies first)

### Escalation Protocol

When escalating to ETYB after max iterations:

```markdown
## Escalation: {Agent Name} -- Max Iterations Reached

### Original Task
{Task spec}

### Iteration History
| Attempt | Stage Failed | Reason | Correction Applied |
|---------|-------------|--------|--------------------|
| 1 | {1 or 2} | {reason} | {correction} |
| 2 | {1 or 2} | {reason} | {correction} |
| 3 | {1 or 2} | {reason} | N/A -- escalating |

### Root Cause Analysis
{Why the agent keeps failing -- ambiguous spec? too complex? wrong model?}

### Recommendation
{Decompose further | Change model | Resolve dependency | Handle manually}
```

## When to Skip Stage 2

Stage 2 (quality review) adds overhead. For some tasks, Stage 1 (spec conformance) provides sufficient confidence. Skip Stage 2 when all of the following are true:

### Eligible for Stage 2 Skip

| Condition | Rationale |
|-----------|-----------|
| **Mechanical changes** (renames, formatting, import updates) | No quality judgment needed -- either it compiles or it doesn't |
| **Haiku-level tasks** (1-2 files, no ambiguity) | Too simple for quality review to find issues |
| **Test-only changes** (adding tests, not modifying production code) | Tests are self-verifying -- if they pass and test the right things, they're correct |
| **Configuration changes** (env vars, build config, CI pipeline) | Correctness is binary -- configuration works or it doesn't |
| **Documentation changes** (comments, READMEs, docstrings) | Low risk, no production impact |

### NOT Eligible for Stage 2 Skip

| Condition | Why Review is Mandatory |
|-----------|----------------------|
| **Security-sensitive code** (auth, payments, PII handling) | Security issues are subtle and expensive |
| **Cross-cutting changes** (shared libraries, utility functions) | Impacts many consumers, mistakes are amplified |
| **Performance-critical code** (hot paths, data processing) | Performance issues are invisible without expert review |
| **Architecture-level changes** (new patterns, structural changes) | Bad patterns propagate across the codebase |
| **Any Opus-level task** | If it needed Opus, it needs quality review |
| **Agent reported DONE_WITH_CONCERNS** | The agent itself identified risks |

### Stage 2 Skip Documentation

When skipping Stage 2, document the reason:

```markdown
## Stage 2: SKIPPED
**Reason**: {mechanical change | haiku-level task | test-only | config change}
**Confidence**: Stage 1 PASS provides sufficient confidence for this change type
**Risk**: {Low -- incorrect output is immediately detectable via compilation/tests}
```

## Two-Stage Review Summary

```
Agent completes work
    |
    v
Stage 1: Spec Conformance (always runs)
    |
    |-- FAIL --> Re-dispatch with corrections (max 2 iterations)
    |
    |-- PASS --> Is Stage 2 required?
                    |
                    |-- Skip eligible --> Document skip, integrate
                    |
                    |-- Required --> Stage 2: Quality Review
                                      |
                                      |-- APPROVE --> Integrate
                                      |-- APPROVE_WITH_CONCERNS --> Integrate + follow-up
                                      |-- REQUEST_CHANGES --> Re-dispatch with findings
                                                               (max 2 iterations total)
```
