# Design Brief Template

The design brief is the primary output of the brainstorm protocol. It's the structured artifact that feeds into ETYB's Design gate and gives architects, planners, and specialist skills a clear target. This reference covers the template, examples, anti-patterns, and tier mapping.

---

## 1. The Template

Every design brief follows this structure. Depth varies by project scale, but the sections are consistent.

### Full Template with Explanations

```markdown
## Design Brief: {Project Name}

**Date:** {YYYY-MM-DD}
**Author:** brainstorm-protocol
**Status:** Draft | Ready for Design Gate | Approved

---

### Problem Statement

{1-2 sentences describing the pain we're solving. Must be about the problem, not the solution.
Good: "Solo restaurant owners waste 15-20% of perishable inventory because they rely on
guesswork for ordering."
Bad: "We need a React app to manage restaurant inventory."}

### Target User

{Specific description of who this is for. Not a demographic — a person with a context.

Include:
- Who they are (role, situation)
- What they do today (current workflow/workaround)
- What frustrates them about the current approach
- What would make them switch to something new}

### Constraints

{Hard constraints that shape what we can and cannot build. These are non-negotiable.

Format as a table for scannability:}

| Constraint | Type | Impact on Solution |
|-----------|------|-------------------|
| {constraint} | {Time/Budget/Team/Technical/Regulatory/User} | {how it shapes the approach} |

### Chosen Approach

{What we're building and WHY this approach over alternatives.

This section should:
1. State the approach in 2-3 sentences
2. Explain why this approach was chosen (reference the tradeoff analysis)
3. Acknowledge what this approach gives up vs alternatives
4. Note the reversibility — can we change course later?}

#### Alternatives Considered

{Brief summary of other approaches explored and why they were not chosen.

| Approach | Why Not Chosen |
|----------|----------------|
| {approach} | {reason — feasibility, effort, risk, time-to-market} |}

### Scope

#### In (v1)

{What the first version includes. Be specific about what each item means and its level of fidelity.

| Feature | Description | Fidelity |
|---------|------------|----------|
| {feature} | {what it does, specifically} | {Full / Basic / Minimal} |}

#### Out (v1)

{What the first version explicitly excludes. Each item needs a reason.

| Feature | Why Deferred | When to Reconsider |
|---------|-------------|-------------------|
| {feature} | {reason} | {trigger — "after v1 launch", "if users request it", "v2 planning"} |}

#### Later (v2+)

{Ideas for future versions. Less formal than the Out list — these are possibilities, not commitments.

- {idea 1}
- {idea 2}
- {idea 3}}

### Unknowns and Risks

{What we don't know and what could go wrong.

| # | Item | Type | Impact if Unaddressed | Strategy | Priority |
|---|------|------|----------------------|----------|----------|
| 1 | {description} | Unknown / Risk | {what happens} | {Research / Spike / Mitigate / Accept / Transfer} | {High / Med / Low} |}

### Success Criteria

{How we'll know this worked. Measurable where possible.

| Criterion | Target | How to Measure | Timeframe |
|-----------|--------|---------------|-----------|
| {criterion} | {specific target} | {measurement method} | {when to assess} |}

### Next Steps

{What the Design gate needs to address. These are handoff items for the system-architect,
project-planner, and other skills.

1. {action} — {who should handle this}
2. {action} — {who should handle this}
3. {action} — {who should handle this}}

### Appendix: Exploration Notes

{Optional. Key insights from the brainstorming conversation that don't fit in the sections
above but provide useful context for downstream teams.}
```

### Section-by-Section Guidance

**Problem Statement**: This is the anchor for the entire project. If the problem statement is wrong, everything downstream is wrong. Test it by asking: "If someone read only this sentence, would they understand what pain we're addressing?" Avoid embedding solutions in the problem statement.

**Target User**: The quality test is specificity. "Small business owners" is a demographic. "Solo restaurant owners who manage their own inventory and don't have an IT person" is a target user. The more specific you are, the better the downstream decisions.

**Constraints**: Hard constraints only. Preferences go in the approach section. A constraint is something that, if violated, makes the project fail or unacceptable. "Must be HIPAA compliant" is a constraint. "Should use React" is a preference (unless the entire team only knows React, in which case it becomes a team constraint).

**Chosen Approach**: This is not a technical architecture. It's a strategic direction. "Build a simple web app focused on inventory tracking with automatic reorder suggestions" is an approach. "Use React + Node.js + PostgreSQL on AWS" is architecture (which comes later, at the Design gate).

**Scope**: The most important section for preventing scope creep. The Out list is as valuable as the In list. Every item in the Out list should feel like something someone will ask "why isn't this in v1?" — and the answer is right there.

**Unknowns and Risks**: Honesty is more valuable than completeness here. It's better to have 5 well-identified unknowns than to claim there are none. The strategy column forces you to think about what to do about each unknown, not just list them.

**Success Criteria**: Resist the temptation to make everything measurable. Some success criteria are qualitative ("users report the onboarding was easy in post-launch interviews"). But where possible, use numbers: "50% of invited users complete onboarding within the first week."

**Next Steps**: Bridge from brainstorm to design. Each next step should name the responsible skill or role. "System architect should design the data model" is actionable. "Figure out the architecture" is not.

---

## 2. Good Brief Examples

### Example 1: Restaurant Inventory Tool (Startup Scale)

```markdown
## Design Brief: FreshTrack — Restaurant Inventory Manager

**Date:** 2025-03-15
**Author:** brainstorm-protocol
**Status:** Ready for Design Gate

---

### Problem Statement

Solo restaurant owners waste 15-20% of perishable inventory because they rely on memory and
guesswork for ordering, with no visibility into consumption patterns or cost trends.

### Target User

Independent restaurant owners who:
- Run a single location with 10-30 menu items
- Do their own purchasing (no dedicated procurement staff)
- Currently track inventory on paper, in their head, or in a basic spreadsheet
- Are frustrated by throwing away food they over-ordered and running out of items mid-service
- Are comfortable with a smartphone but not technical tools

### Constraints

| Constraint | Type | Impact on Solution |
|-----------|------|-------------------|
| Solo founder, 8 weeks to MVP | Time + Team | Must be extremely simple to build; no complex features in v1 |
| $0 budget for infrastructure initially | Budget | Must use free tiers; minimal operational cost |
| Users are not tech-savvy | User | Must be dead simple; mobile-first; minimal training required |
| Must work in a kitchen environment | User | Large touch targets; works with wet/dirty hands; quick interactions |

### Chosen Approach

Build a mobile-first web app where restaurant owners log inventory daily (2-3 minutes) and
get weekly insights on waste patterns and suggested order quantities. The app learns from
their patterns over time using simple moving averages — no ML in v1.

Chosen over: (a) spreadsheet template (too hard to get insights), (b) full ERP system
(way too complex for solo operators), (c) hardware-based solution with barcode scanning
(too expensive and complex for v1).

This approach is reversible — the data model supports adding barcode scanning or supplier
integrations later without restructuring.

#### Alternatives Considered

| Approach | Why Not Chosen |
|----------|----------------|
| Enhanced spreadsheet template | No automatic insights; users already abandon spreadsheets |
| Full restaurant ERP | 6+ month build; too complex for target user |
| Barcode scanning hardware | High upfront cost; requires hardware; overkill for 10-30 items |

### Scope

#### In (v1)

| Feature | Description | Fidelity |
|---------|------------|----------|
| Daily inventory count | Quick-entry form for counting current stock of each item | Full |
| Item management | Add/edit/remove inventory items with unit and category | Full |
| Waste tracking | Flag items thrown away with reason (expired, spoiled, over-prepped) | Basic |
| Weekly report | Simple dashboard showing waste trends and top wasted items | Basic |
| Suggested order quantities | Based on 4-week moving average consumption | Minimal |

#### Out (v1)

| Feature | Why Deferred | When to Reconsider |
|---------|-------------|-------------------|
| Supplier integration | Requires supplier API partnerships; too complex for v1 | After 50+ active users validate demand |
| Barcode scanning | Requires camera integration; most users have <30 items | If users report data entry is too slow |
| Multi-location support | Target user is single-location | If multi-location owners express interest |
| Cost tracking / P&L | Requires price data entry; adds complexity | v2, after basic tracking is adopted |
| Team accounts | Target user is solo operator | If restaurants with staff show interest |

#### Later (v2+)

- Cost-per-dish calculation
- Supplier price comparison
- Menu engineering (which dishes are profitable vs popular)
- Integration with POS systems

### Unknowns and Risks

| # | Item | Type | Impact if Unaddressed | Strategy | Priority |
|---|------|------|----------------------|----------|----------|
| 1 | Will owners actually log inventory daily? | Unknown | Product is useless without data | User interviews with 5 owners before building | High |
| 2 | Is a 4-week moving average accurate enough for order suggestions? | Unknown | Bad suggestions erode trust | Start with display-only (no automated ordering); validate accuracy first | Med |
| 3 | Mobile web vs native app for kitchen use | Unknown | Bad UX in kitchen environment | Build as PWA; test in actual kitchen setting | Med |
| 4 | Competitor launches similar tool | Risk | Reduced market opportunity | Ship fast; focus on simplicity as differentiator | Low |

### Success Criteria

| Criterion | Target | How to Measure | Timeframe |
|-----------|--------|---------------|-----------|
| Daily logging adoption | 60% of users log at least 5 days/week | App analytics | 4 weeks post-launch |
| Reported waste reduction | 10% reduction in self-reported food waste | User survey | 8 weeks post-launch |
| Retention | 40% of users active after 30 days | App analytics | 30 days post-launch |
| NPS | >30 | In-app survey | 6 weeks post-launch |

### Next Steps

1. Validate daily logging assumption with 5 user interviews — research-analyst
2. Design data model for inventory items, counts, and waste events — system-architect
3. Design mobile-first UI for kitchen environment (large touch targets, quick entry) — frontend-architect
4. Estimate effort and plan sprint breakdown — project-planner
```

### Example 2: Internal Developer Portal (Growth Scale)

```markdown
## Design Brief: DevHub — Internal Developer Portal

**Date:** 2025-03-15
**Author:** brainstorm-protocol
**Status:** Ready for Design Gate

---

### Problem Statement

Developers at a 40-person engineering org waste 3-5 hours per week searching for internal
documentation, API specs, and service ownership information scattered across Confluence,
Notion, GitHub READMEs, and Slack threads.

### Target User

Backend and frontend developers (junior to senior) at the company who:
- Work across 15+ microservices owned by 6 teams
- Spend significant time asking "who owns this?" and "where are the docs for X?"
- Currently search across 4 different tools to find information
- Would adopt a single source of truth if it were kept current and searchable

### Constraints

| Constraint | Type | Impact on Solution |
|-----------|------|-------------------|
| 2 engineers, 20% time (internal project) | Team | Must be minimal build; leverage existing data sources |
| Must integrate with GitHub, Confluence, Slack | Technical | API integrations required; can't replace existing tools |
| Must not require teams to change their workflow | User | Aggregate from existing sources, don't create a new place to write docs |
| SSO required (Okta) | Technical | Authentication via existing Okta setup |

### Chosen Approach

Build a lightweight internal portal that aggregates and indexes information from existing
sources (GitHub repos, Confluence spaces, Slack channels) with a unified search interface
and a service catalog showing ownership. Teams don't change how they write docs — DevHub
pulls from where docs already live.

Chosen over: (a) Backstage (powerful but heavy; would consume entire 2-person allocation),
(b) enhanced Confluence (doesn't solve the "scattered across tools" problem),
(c) custom knowledge base (requires teams to migrate content, which won't happen).

#### Alternatives Considered

| Approach | Why Not Chosen |
|----------|----------------|
| Spotify Backstage | Excellent tool but requires significant setup and maintenance; overkill for 40 engineers |
| Better Confluence organization | Doesn't solve the multi-tool fragmentation problem |
| Custom knowledge base | Requires content migration; teams won't do it; creates yet another tool |

### Scope

#### In (v1)

| Feature | Description | Fidelity |
|---------|------------|----------|
| Service catalog | List of all services with owner, tech stack, repo link, status page | Full |
| Unified search | Search across GitHub READMEs, Confluence pages, indexed Slack threads | Basic |
| API directory | Auto-generated from OpenAPI specs in repos | Basic |
| Team directory | Who owns what service, on-call rotation links | Full |

#### Out (v1)

| Feature | Why Deferred | When to Reconsider |
|---------|-------------|-------------------|
| Scaffolding / templates | Requires opinionated choices about project structure | v2, after service catalog is adopted |
| CI/CD visibility | Already in GitHub Actions dashboard; low incremental value | If teams report it's missing |
| Dependency graph | Requires service mesh or manual input; hard to keep current | v2, after service catalog has accurate data |
| Documentation quality scoring | Needs baseline data on what "good" looks like | After 3 months of usage data |

### Unknowns and Risks

| # | Item | Type | Impact if Unaddressed | Strategy | Priority |
|---|------|------|----------------------|----------|----------|
| 1 | Can we get useful search results from Slack without noise? | Unknown | Search quality degrades; users lose trust | Spike: test Slack API search with filters for 2 days | High |
| 2 | Will teams keep service catalog data current? | Risk | Stale data makes the tool useless | Auto-populate from GitHub; minimize manual fields | High |
| 3 | Search relevance across different content types | Unknown | Users can't find what they need | Start with basic text search; add ranking in v2 | Med |

### Success Criteria

| Criterion | Target | How to Measure | Timeframe |
|-----------|--------|---------------|-----------|
| Weekly active users | 70% of engineering org | Analytics | 6 weeks post-launch |
| Reduced "where is X?" Slack messages | 50% reduction | Slack channel monitoring | 8 weeks post-launch |
| Service catalog completeness | 90% of services registered with owner | Manual audit | 4 weeks post-launch |
| Developer satisfaction | Positive in quarterly eng survey | Survey | Next quarterly survey |

### Next Steps

1. Technical spike on Slack API search quality — backend-architect
2. Design service catalog data model and auto-population from GitHub — system-architect
3. Security review for SSO integration and data access patterns — security-engineer
4. Estimate effort and plan v1 sprint breakdown — project-planner
```

---

## 3. Bad Brief Anti-Patterns

### Anti-Pattern 1: Too Vague

```markdown
### Problem Statement
We need a better way to manage our data.

### Target User
Our team and our customers.

### Chosen Approach
Build an app.
```

**Why it's bad**: No specificity. An architect reading this can't design anything. A planner can't estimate anything. Every downstream decision becomes a guess.

**Fix**: Ask "who specifically?", "what data?", "what's broken about the current approach?", "what does 'better' mean in measurable terms?"

### Anti-Pattern 2: Too Solution-Focused

```markdown
### Problem Statement
We need a React + Next.js app with a PostgreSQL database, deployed on Vercel,
using Stripe for payments and SendGrid for emails.

### Chosen Approach
Use React + Next.js + PostgreSQL + Vercel + Stripe + SendGrid.
```

**Why it's bad**: This is a tech stack shopping list, not a design brief. There's no problem, no user, no scope definition, no success criteria. The technology might be right or might be completely wrong — we can't tell because we don't know what problem it's solving.

**Fix**: Strip out all technology references. Start with the problem and user. Let the system-architect choose the technology based on the problem, constraints, and team context.

### Anti-Pattern 3: No Constraints

```markdown
### Constraints
None — we're flexible!
```

**Why it's bad**: Every project has constraints. "No constraints" means "I haven't thought about constraints." This leads to solutions that are technically beautiful but practically impossible given the team, timeline, or budget that actually exist.

**Fix**: Walk through the constraint taxonomy systematically. Time? Budget? Team? Technical? Regulatory? User? There's always something.

### Anti-Pattern 4: No Scope Boundaries

```markdown
### Scope
#### In (v1)
- User management
- Dashboard
- Reports
- Notifications
- Integrations
- Admin panel
- Mobile app
- Analytics
- AI recommendations
```

**Why it's bad**: This is a feature wish list, not a scope definition. There's no "Out" list, no fidelity levels, no prioritization. If everything is in scope, nothing is in scope. This leads to a project that takes 3x longer than expected and ships nothing.

**Fix**: Force-rank features. Apply the Must/Should/Could/Won't framework. Create an explicit Out list. For every feature in the In list, specify what "done" means at what fidelity level.

### Anti-Pattern 5: No Success Criteria

```markdown
### Success Criteria
- Users like it
- It works well
- Good performance
```

**Why it's bad**: These are not criteria — they're wishes. "Users like it" can't be measured, debated, or verified. When the project ships, there's no way to assess whether it succeeded.

**Fix**: Make each criterion specific and measurable. "60% of invited users complete onboarding in the first week." "API response time under 200ms at p95." "NPS score above 30 at 6-week mark."

### Anti-Pattern 6: Skipping Alternatives

```markdown
### Chosen Approach
Build a custom solution.

### Alternatives Considered
None — this is the obvious approach.
```

**Why it's bad**: If only one approach was considered, the choice wasn't made — it was assumed. Without exploring alternatives, you can't articulate WHY this approach is right, which means you can't defend the choice when challenged.

**Fix**: Always explore at least 3 approaches (see the divergent thinking techniques in exploration-techniques.md). Even if the choice seems obvious, documenting why alternatives were rejected strengthens the brief.

---

## 4. How the Brief Maps to ETYB Tier Classification

The design brief provides signals that help ETYB classify the project tier. Understanding these signals helps you produce briefs that give ETYB clear classification input.

### Tier Signal Matrix

| Brief Signal | Tier 1 (Quick) | Tier 2 (Standard) | Tier 3 (Focused) | Tier 4 (Full Project) |
|-------------|----------------|-------------------|-------------------|-----------------------|
| **Scope: In list size** | 1-2 items | 3-5 items | 5-10 items | 10+ items |
| **Scope: Out list size** | None needed | 1-3 items | 3-7 items | 7+ items |
| **Constraints count** | 0-1 | 1-3 | 3-5 | 5+ |
| **Unknowns count** | 0 | 0-2 | 2-5 | 5+ |
| **Risks: High priority** | 0 | 0-1 | 1-3 | 3+ |
| **Success criteria** | 1 | 1-3 | 3-5 | 5+ |
| **Stakeholder types** | 1 (user) | 1-2 | 2-3 | 3+ |
| **Regulatory constraints** | None | None or 1 | 1-2 | 2+ |
| **Integration requirements** | None | 0-1 | 1-3 | 3+ |
| **Estimated team size** | 1 person | 1-2 people | 2-5 people | 5+ people |

### How Scope Drives Tier

The single strongest signal for tier classification is scope complexity:

- **Tier 1-2**: The brief is so simple it barely needs a brief. A clear problem, one approach, minimal scope. ETYB might not even invoke brainstorm-protocol for these.
- **Tier 3**: The brief has meaningful scope definition with clear in/out boundaries, several unknowns, and a tradeoff analysis. This is the sweet spot for brainstorm-protocol.
- **Tier 4**: The brief is a substantial document with multiple stakeholders, regulatory constraints, significant unknowns, and a complex scope. Multiple brainstorming sessions may be needed. The brief might have an appendix.

### What ETYB Looks For

When ETYB reviews your design brief at the Design gate, they check:

1. **Is the problem clear?** — Can downstream skills understand what we're building and why?
2. **Is the scope bounded?** — Are there explicit in/out boundaries, or is this open-ended?
3. **Are constraints identified?** — Does the brief acknowledge real-world limitations?
4. **Are risks surfaced?** — Are there known unknowns with strategies, or is the brief naively optimistic?
5. **Are success criteria defined?** — Will we know when this is done and whether it worked?
6. **Is the approach justified?** — Was more than one approach considered? Is there a rationale?

A brief that answers all six questions well is ready for the Design gate. A brief that misses any of them needs more exploration.

### Feedback Loop

If ETYB returns the brief with questions or concerns:

1. Read their feedback carefully — what specific gaps are they seeing?
2. Return to the relevant step (1-8) and gather more information
3. Update the brief — don't start over; patch the gaps
4. Resubmit for the Design gate

This is normal and expected. The first pass of a brief for a Tier 3-4 project rarely passes the Design gate on the first try. The iteration makes the brief better.
