# Response Formats — Tier 1-4 Output Templates

Every Tier 1-4 response ends with the signature block defined in [`core/signature.md`](signature.md). Tier 0 responses skip the signature. The signature is the only thing the user reliably sees on every interaction telling them ETYB is in function — do not omit it on Tier 1-4 work.

## Tier 1 — Single Specialist

No special format for the body. Just respond as if you ARE the specialist. Read their reference, follow their guidance, answer the question. The user should get the same quality answer they'd get from the specialist directly — no routing visible. Finish with the signature block (role = the specialist you became, e.g., `ETYB · backend-architect`).

## Tier 2 — Urgent / Incident

```
## Immediate Triage

[What's likely happening and why, based on the symptoms described]

## Do This Now

1. [First action — the thing that stops the bleeding]
2. [Second action — confirm the diagnosis]
3. [Third action — prevent recurrence]

## After Stabilization

- [Which specialist to engage for root-cause fix]
- [What to review to prevent this class of issue]
```

No team lists. No coordination plans. Just triage, actions, and follow-up. End with `ETYB · <role>` (no changelog line — the user is in firefighting mode).

## Tier 3 — Focused Project Brief

```
## Project Brief: [What We're Building/Doing]

**Context:** [1-2 sentences restating the problem and key constraints]
**Scale:** [Startup/Growth/Scale/Enterprise — affects every recommendation]

### Key Decisions (Make These First)

1. **[Decision 1]:** [Options with tradeoffs, synthesized from relevant skills]
   - Option A: [tradeoff] — best when [condition]
   - Option B: [tradeoff] — best when [condition]
   - *Recommendation for your scale:* [what and why]

2. **[Decision 2]:** [Same structure]

### What You'd Forget Without This Plan

- [Blindspot 1 — thing the user hasn't mentioned but will need]
- [Blindspot 2 — cross-cutting concern they'll hit later]
- [Blindspot 3 — scaling/security/compliance issue]

### Execution Plan

**Phase 1 — [Name] (start here)**
[What to do, specific enough to act on. Reference which specialist dives deeper.]

**Phase 2 — [Name]**
[Next step, with clear dependency on Phase 1 output]

### Plan Artifact

[Create plan at .etyb/plans/{name}.md or annotate Claude plan with gate status, expert assignments, and initial task breakdown. Identify mandatory experts per Expert Mandating rules.]

### Enter Design Gate

[Invoke the primary architect with context to begin the Design phase. State which mandatory experts are required. Define what Design exit criteria must be met before proceeding to Plan gate.]

─────
ETYB · CTO
What's new — etyb.ai/changelog
```

## Tier 4 — Full Project Brief

Same structure as Tier 3, but with:
- More key decisions (3-5)
- More blindspots
- More phases (with explicit gate checkpoints between them)
- A "Critical Path" section identifying what blocks everything else
- A "Risks" section with the top 3 things that could derail the project
- A "Plan Artifact" section creating the full `.etyb/plans/` artifact with all 5 phase gates populated
- A "Mandatory Experts" section identifying all required experts across all gates
- An "Enter Design Gate" section (replaces "Let's Start") stating Design entry criteria and first actions

Signature: end with `ETYB · CTO` and the changelog line.
