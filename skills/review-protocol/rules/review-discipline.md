# Review Discipline: Hard Constraints

These rules are non-negotiable. They apply to every review interaction regardless of tier, urgency, or reviewer identity.

## Performative Agreement Ban

- NEVER use "Great catch!", "Excellent point!", "You're absolutely right!", or any variation
- NEVER say "Thanks for the thorough review!" as a substitute for engaging with findings
- NEVER say "I'll fix everything you mentioned" -- each finding gets individual evaluation
- Acknowledge correct findings through ACTION (fixing the code), not gratitude theater

## Individual Evaluation Requirement

- EVERY finding gets its own assessment: Agree + Fix, Agree + Defer, or Disagree + Explain
- NEVER batch findings with "I agree with all your points"
- NEVER implement suggestions without first verifying they do not break existing tests
- NEVER change code you do not understand just because a reviewer suggested it

## Evidence-Based Disagreement

- Push back with EVIDENCE (test results, documentation, benchmarks, code references), not opinions
- NEVER disagree to avoid work -- if the finding is correct but inconvenient, that is Agree + Defer
- NEVER agree to avoid conflict -- the codebase does not benefit from diplomatic lies
- When evidence is ambiguous, write a test to settle the disagreement

## Mandatory Review Gates

- Review is MANDATORY at the Verify gate for Tier 2+ work
- Review is MANDATORY for any change touching auth, payments, or PII regardless of tier
- Must-fix (critical) findings CANNOT be deferred -- they block until resolved
- Security concerns CANNOT be deferred without security-engineer clearance

## Deferred Finding Tracking

- Every deferred should-fix finding MUST have a ticket reference
- Every deferred finding MUST have a documented reason for deferral
- Deferred findings MUST be reviewed at sprint boundaries
- Review debt limits must be respected (see review-integration.md)

## Review Request Quality

- Every review request MUST include design intent (not just a diff)
- Every review request MUST include current test results
- Every review request MUST include at least one specific concern
- Do NOT dump the entire project for review -- scope the diff to relevant changes
