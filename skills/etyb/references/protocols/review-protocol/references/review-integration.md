# Review Integration: How Reviews Connect to the Gate System

This reference covers how code reviews integrate with the etyb-skills gate system -- what blocks the Verify gate, how to file review completion reports, managing review iteration cycles, handling multiple reviewers, and tracking review debt.

## Verify Gate Blocking Criteria

The Verify gate cannot pass until all blocking criteria are resolved. Review protocol is responsible for producing the evidence that the gate evaluates.

### What Blocks the Gate

| Criterion | Blocking? | Resolution |
|-----------|-----------|------------|
| Any must-fix (critical) finding unresolved | YES -- hard block | Fix the finding. Must-fix cannot be deferred. |
| Unresolved security concerns | YES -- hard block | Fix or get security-engineer clearance. |
| Missing test coverage for changed code | YES -- hard block | Add tests per qa-engineer's test strategy. |
| Open questions from reviewer | YES -- soft block | Answer the questions. If the reviewer is a subagent, address in the response. |
| Automated checks failing (lint, type, SAST) | YES -- hard block | Fix the automated check failures before requesting human review. |
| Should-fix (major) findings unresolved | NO -- advisory | Track as follow-up. Must have ticket reference. |
| Minor suggestions unresolved | NO -- does not block | Author decides. No tracking required. |
| Nits unresolved | NO -- does not block | Optional. |

### Hard Block vs Soft Block

**Hard block:** The gate CANNOT pass under any circumstances. There is no override, no exception, no "we'll fix it later." Must-fix findings and security concerns are hard blocks because they represent immediate risk to users or data.

**Soft block:** The gate SHOULD NOT pass, but can with explicit acknowledgment. Open questions from a reviewer are soft blocks because the question may turn out to be a misunderstanding that is quickly clarified.

### Escalation Path

If a hard block cannot be resolved:

1. **Identify the blocking finding** and why it cannot be resolved
2. **Escalate to ETYB** with the specific block and what has been tried
3. **ETYB determines next action:** rework the implementation, adjust the plan, or bring in a specialist
4. **Never bypass a hard block.** If it cannot be resolved, the work is not done.

## Review Completion Report

After all findings are addressed (fixed, deferred, or pushed back), file a review completion report. This is the primary artifact the Verify gate evaluates.

### Completion Report Format

```markdown
## Review Completion: [Plan/Task Name]

**Reviewer:** [code-reviewer / person name]
**Author:** [who wrote the code]
**Date:** [date completed]
**Review round:** [1 / 2 / 3]

### Automated Checks (Stage 1)
| Check | Status | Notes |
|-------|--------|-------|
| Lint & formatting | PASS / FAIL | [details if fail] |
| Type checking | PASS / FAIL | [details if fail] |
| Unit tests | PASS ([count]) | [any notes] |
| Integration tests | PASS ([count]) | [any notes] |
| SAST | PASS / [N] new findings | [details if findings] |
| SCA | PASS / [N] new CVEs | [details if CVEs] |
| Build | PASS / FAIL | [details if fail] |

### Human Review (Stage 2)
| Dimension | Findings | Severity Breakdown |
|-----------|----------|-------------------|
| Code Quality | [N] findings | [X critical, Y major, Z minor] |
| Performance | [N] findings | [X critical, Y major, Z minor] |
| Security | [N] findings | [X critical, Y major, Z minor] |
| Architecture | [N] findings | [X critical, Y major, Z minor] |

### Findings Resolution

**Total findings:** [N]

| # | Finding | Severity | Resolution | Evidence |
|---|---------|----------|------------|----------|
| 1 | [title] | must-fix | Fixed | [commit SHA / test name] |
| 2 | [title] | should-fix | Fixed | [commit SHA / test name] |
| 3 | [title] | should-fix | Deferred | [ticket ref + reason] |
| 4 | [title] | suggestion | Pushed back | [evidence summary] |
| 5 | [title] | nit | Fixed | [commit SHA] |

### Plan Compliance (Tier 3+ only)
- **Test strategy followed:** [Yes / Gaps: list specific gaps]
- **Design decisions honored:** [Yes / Deviations: list specific deviations]
- **Risk mitigations present:** [Yes / Missing: list missing mitigations]

### Summary
- **Fixed:** [count]
- **Deferred:** [count] (tickets: [list])
- **Pushed back:** [count]
- **Verdict:** APPROVED / APPROVED WITH COMMENTS / CHANGES REQUESTED

### Blocking Items
[List any remaining blockers, or "None -- ready for Verify gate"]
```

### When to File the Completion Report

File the completion report when ALL of these are true:
- Every must-fix finding has been fixed (not deferred, not pushed back without evidence)
- Every security concern has been resolved or cleared by security-engineer
- All open questions have been answered
- All automated checks pass
- All fixes have been verified (tests pass, no regressions)

Do NOT file the completion report if any must-fix finding remains open. The report is the signal to the Verify gate that the review cycle is complete.

## Review Iteration Cycle

Reviews are rarely one-and-done. The iteration cycle is: review -> fix -> re-review -> approve.

### When to Do a Full Re-Review

Request a full re-review (all four dimensions) when:

- Fixes changed the architecture or design approach
- More than 30% of the code was rewritten to address findings
- New files or modules were created as part of the fixes
- The fix for one finding introduced concerns in a different dimension
- The reviewer explicitly requested a full re-review

### When to Do an Incremental Re-Review

Request an incremental re-review (only the changed areas) when:

- Fixes were localized (specific lines or functions changed)
- No architectural changes were made
- The total fix diff is under 100 lines
- The fixes are straightforward (adding validation, fixing a query, adding error handling)

### Incremental Re-Review Dispatch

When dispatching an incremental re-review to code-reviewer:

```markdown
## Re-Review Request: [Title] (Round [N])

**Previous findings addressed:** [count]
**Changes made:** [summary of fixes]

### Original Findings and Resolutions
| # | Finding | Resolution | Change |
|---|---------|------------|--------|
| 1 | [title] | Fixed | [what changed] |
| 2 | [title] | Fixed | [what changed] |
| 3 | [title] | Pushed back | [reason -- no change] |

### New Diff (fixes only)
[The diff showing only the changes made to address review findings]

### Verification
- All previous tests still passing: Yes
- New tests added: [count]
- No regressions detected: Yes

### Review Request
Please verify:
1. Finding 1 fix is correct and complete
2. Finding 2 fix is correct and complete
3. No new issues introduced by the fixes
4. Any findings you want to change based on my pushback responses
```

### Maximum Iteration Count

- **Normal reviews:** 3 rounds maximum. If the review has not converged after 3 rounds, escalate to ETYB. Something is fundamentally wrong (unclear requirements, mismatched design intent, or wrong reviewer).
- **Security reviews:** No maximum. Security findings iterate until resolved. Critical security issues do not have a "we've been going back and forth too long" escape valve.
- **Architecture reviews:** 2 rounds maximum for structural concerns. If the architecture is not right after 2 rounds, the issue is at the Design gate, not the review.

### Convergence Signals

A review is converging when:
- Each round has fewer findings than the previous round
- No new critical or major findings appear in later rounds
- The remaining findings are minor or nit
- The reviewer's tone shifts from "changes requested" to "looks good with minor comments"

A review is NOT converging when:
- New critical findings appear in later rounds
- Fixes for one finding introduce new findings
- The author and reviewer disagree on fundamental approach
- The total finding count is not decreasing

If the review is not converging, stop iterating and escalate. The problem is upstream of the review.

## Handling Multiple Reviewers

When multiple reviewers are involved (Scale/Enterprise tier, or high-risk changes), their feedback must be reconciled.

### Reviewer Roles

| Role | Authority | Typical Scope |
|------|-----------|---------------|
| **Primary reviewer** | Final approval authority | All four dimensions |
| **Security reviewer** | Veto on security findings | Security dimension only |
| **Architecture reviewer** | Veto on architecture findings | Architecture dimension |
| **Domain expert** | Advisory | Domain-specific correctness |
| **Style/standards reviewer** | Advisory | Code quality, conventions |

### When Reviewers Disagree

Disagreements between reviewers are resolved based on the type of finding:

#### Architecture Disagreements -> Consensus Required

Architecture decisions affect the whole team. When reviewers disagree on architecture:

1. Document both positions with their reasoning
2. Evaluate against the project's architecture decision log
3. If the existing ADR covers the case, follow it
4. If no ADR covers the case, escalate to system-architect for a decision
5. Record the outcome as a new ADR entry

Do NOT pick the more senior reviewer's opinion by default. Architecture decisions should be evaluated on technical merit, not seniority.

#### Security Disagreements -> Most Conservative Wins

When reviewers disagree on security:

1. Apply the more conservative interpretation
2. If the conservative interpretation has significant cost, escalate to security-engineer
3. Never resolve a security disagreement by choosing the less secure option

#### Style Disagreements -> Single Authority

Style and convention disagreements are resolved by a single authority:

1. If the project has a style guide or linter configuration, it wins
2. If not, the primary reviewer's preference applies
3. Do NOT iterate on style disagreements. Pick one and move on.

#### Correctness Disagreements -> Evidence Wins

When reviewers disagree on correctness:

1. Write a test that demonstrates which interpretation is correct
2. If both interpretations are valid, defer to the design intent documented in the plan
3. If no plan exists, defer to the author's intent (they understand the requirements best)

### Multi-Reviewer Response Format

```markdown
## Review Response: [Title]

### Reviewer A Findings
[Address each finding from Reviewer A]

### Reviewer B Findings
[Address each finding from Reviewer B]

### Cross-Reviewer Conflicts
| Topic | Reviewer A | Reviewer B | Resolution | Reason |
|-------|-----------|-----------|------------|--------|
| [topic] | [position] | [position] | [chosen] | [why] |
```

## Review Debt

Deferred findings are review debt. Like technical debt, it accumulates interest -- deferred findings become harder to fix as the codebase evolves around them.

### What Qualifies as Review Debt

| Category | Is Review Debt? | Tracking Required? |
|----------|----------------|-------------------|
| Must-fix deferred | NEVER -- must-fix cannot be deferred | N/A |
| Should-fix deferred | YES | Mandatory -- ticket with timeline |
| Minor suggestions deferred | YES (low priority) | Recommended -- note in backlog |
| Nits not addressed | NO | Not needed |
| Pushed back findings | NO (disagreement is resolution) | Not needed |

### Tracking Review Debt

Every deferred should-fix finding MUST be tracked:

```markdown
### Deferred Finding: [Title]
**Original review:** [Review title, date]
**Severity:** should-fix
**Description:** [What the finding was]
**Reason for deferral:** [Why it was not fixed now]
**Ticket:** [PROJ-XXX]
**Target resolution:** [Sprint/milestone]
**Risk if unresolved:** [What happens if this is never fixed]
```

### Review Debt Review

Periodically (at sprint boundaries or before major releases), review the review debt backlog:

1. Are any deferred findings now critical due to codebase changes?
2. Are any deferred findings no longer relevant (code was refactored or deleted)?
3. Are any deferred findings blocking other work?
4. Is the total debt growing or shrinking?

If debt is growing, the team is not addressing review feedback effectively. This is a process problem, not a code problem.

### Debt Limits

| Tier | Maximum Deferred Should-Fix | Action When Exceeded |
|------|---------------------------|---------------------|
| Startup | 10 | Review and prioritize at next sprint planning |
| Growth | 20 | Dedicate 10% of sprint capacity to debt reduction |
| Scale | Per-team limit set by engineering manager | Block new features until debt is below limit |
| Enterprise | Per-service limit with SLA | Formal debt review with engineering leadership |

## Cross-References

| Reference | Location | When to Consult |
|-----------|----------|-----------------|
| Code Reviewer | `skills/code-reviewer/SKILL.md` | For review dimensions, severity framework, two-stage protocol |
| Verification Protocol | `skills/verification-protocol/references/verification-methodology.md` | For universal gate criteria and completion report format |
| Process Architecture | `skills/etyb/references/process-architecture.md` | For gate definitions, tier classification |
| QA Test Strategy | `skills/qa-engineer/SKILL.md` | For test coverage requirements at the Verify gate |
| Review Dispatch | `review-protocol/references/review-dispatch.md` | For constructing re-review requests |
| Feedback Evaluation | `review-protocol/references/feedback-evaluation.md` | For evaluating findings from re-reviews |
