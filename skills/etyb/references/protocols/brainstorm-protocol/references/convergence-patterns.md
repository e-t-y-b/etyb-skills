# Convergence Patterns

Deep reference for narrowing from exploration to decision. Read this during steps 5-8 of the brainstorming dialogue: evaluating tradeoffs, converging on a direction, defining scope, and identifying risks.

---

## 1. Tradeoff Matrix

When you have multiple approaches from divergent thinking, you need a structured way to compare them. Gut feel works for trivial decisions, but anything that shapes the project's direction needs explicit tradeoff analysis.

### The Five Axes

Score each approach on these five dimensions. Use a 1-5 scale, where 1 is worst and 5 is best.

| Axis | What It Measures | 1 (Worst) | 5 (Best) |
|------|-----------------|-----------|----------|
| **Feasibility** | Can we actually build this with our team, stack, and constraints? | Requires skills/tech we don't have, major unknowns | Team has done this before, well-understood problem |
| **Impact** | How much of the problem does this solve for the target user? | Addresses a small slice of the pain | Solves the core problem completely |
| **Effort** | How much work is this to build, deploy, and maintain? | 6+ months of development, complex operations | Days to weeks, minimal ongoing maintenance |
| **Risk** | What could go wrong and how bad would it be? | Multiple high-probability, high-impact risks | Well-understood risks with clear mitigations |
| **Time-to-Market** | How quickly can users start getting value? | Months before any user sees anything | Users get value in days to weeks |

### Building the Matrix

```
## Tradeoff Analysis: {Project Name}

| Axis            | Weight | Approach A: {name} | Approach B: {name} | Approach C: {name} |
|-----------------|--------|--------------------|--------------------|---------------------|
| Feasibility     | {%}    | {1-5} — {why}      | {1-5} — {why}      | {1-5} — {why}       |
| Impact          | {%}    | {1-5} — {why}      | {1-5} — {why}      | {1-5} — {why}       |
| Effort          | {%}    | {1-5} — {why}      | {1-5} — {why}      | {1-5} — {why}       |
| Risk            | {%}    | {1-5} — {why}      | {1-5} — {why}      | {1-5} — {why}       |
| Time-to-Market  | {%}    | {1-5} — {why}      | {1-5} — {why}      | {1-5} — {why}       |
| **Weighted Total** | 100% | **{score}**       | **{score}**        | **{score}**         |
```

### Choosing Weights

Weights depend on context. Here are common weight profiles:

| Context | Feasibility | Impact | Effort | Risk | Time-to-Market |
|---------|------------|--------|--------|------|----------------|
| **Startup MVP** | 15% | 25% | 20% | 10% | 30% |
| **Growth feature** | 20% | 30% | 20% | 15% | 15% |
| **Enterprise platform** | 25% | 25% | 15% | 25% | 10% |
| **Regulated industry** | 20% | 20% | 10% | 35% | 15% |
| **Competitive pressure** | 15% | 20% | 15% | 10% | 40% |

Adjust weights based on the constraints identified in step 2. If the user said "we need to ship before the conference in March," time-to-market weight goes up. If they said "this handles patient health data," risk weight goes up.

### When Scores Are Close

If two approaches score within 10% of each other, the matrix alone won't decide. Apply secondary criteria:

1. **Reversibility**: Prefer the more reversible option. Can you switch to the other approach later without starting over?
2. **Learning speed**: Prefer the approach that teaches you faster. Which one validates assumptions earlier?
3. **Team energy**: Prefer the approach the team is more excited to build. Motivation matters for execution quality.
4. **Optionality**: Prefer the approach that keeps more doors open. Does one approach naturally extend to cover future needs?

### Tradeoff Matrix Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| All approaches score 3-4 on everything | Approaches aren't different enough | Generate more divergent options |
| One approach is 5 on everything | Bias — you've already decided | Score with a devil's advocate present |
| Weights are all 20% | No prioritization of what matters | Force-rank the axes, then assign weights |
| Ignoring the "why" column | Scores without rationale are meaningless | Every score needs a one-sentence justification |
| Scoring before understanding constraints | Feasibility and effort depend on context | Complete constraint identification first |

---

## 2. Scope Definition

Scope is where brainstorms live or die. A brainstorm that produces "here's everything we could build" is useless. A brainstorm that produces "here's what v1 includes, here's what it explicitly doesn't, and here's what comes later" is actionable.

### MVP vs MLP

| Concept | Definition | When to Use |
|---------|-----------|-------------|
| **MVP (Minimum Viable Product)** | The smallest thing that tests whether the core assumption is true | When you're validating a hypothesis. "Do users want this at all?" |
| **MLP (Minimum Loveable Product)** | The smallest thing that users would actually enjoy using and recommend | When you know users want it but need to win adoption. "Will users choose this over alternatives?" |

The difference matters. An MVP can be ugly and rough — it's a learning tool. An MLP needs to be good enough that users form a positive first impression. Most products should aim for MLP unless you're in pure hypothesis-testing mode.

### The Scope Definition Exercise

For each candidate feature or capability, classify it:

| Category | Criteria | Examples |
|----------|----------|---------|
| **Must Have (v1)** | The product is useless without this. Users can't accomplish the core job. | Login, core data entry, primary view/report |
| **Should Have (v1)** | Significantly improves the experience but core job is possible without it. | Search, filtering, data export, notifications |
| **Could Have (v1 if time allows)** | Nice polish that improves adoption but not core functionality. | Dark mode, keyboard shortcuts, customizable layouts |
| **Won't Have (v1, explicitly deferred)** | Valuable but not for the first version. Creates expectations for the future. | Advanced analytics, integrations, admin portal, mobile app |

### The "Not Now" List

The most underrated artifact in product development. Explicitly listing what you're NOT building in v1 does three things:

1. **Prevents scope creep**: When someone says "shouldn't we also add X?", you can point to the list: "We discussed X and decided it's a v2 item because {reason}."
2. **Sets expectations**: Stakeholders know what's coming later, so they don't feel ignored.
3. **Enables focus**: The team knows they can ignore certain features entirely during v1, reducing cognitive load.

### Writing Effective Scope Statements

**In (v1)**: Be specific about what's included and at what level of fidelity.

| Too Vague | Better |
|-----------|--------|
| "User management" | "Users can register with email/password, log in, reset password. No social login, no role-based access, no user admin panel." |
| "Dashboard" | "A single dashboard page showing total orders, revenue, and top 10 products for the last 7/30/90 days. No custom date ranges, no drill-down, no export." |
| "Notifications" | "Email notifications for order confirmation and shipping updates. No in-app notifications, no SMS, no push notifications." |

**Out (v1)**: Be specific about why it's deferred.

| Too Vague | Better |
|-----------|--------|
| "Mobile app" | "Mobile app deferred to v2. Web app will be responsive for mobile browsers. Native app requires separate development effort and user base doesn't justify it yet." |
| "Analytics" | "Advanced analytics deferred to v2. v1 has basic counts and totals only. Full analytics requires data warehouse setup and we need usage data from v1 to know what metrics matter." |

### Scope Negotiation Techniques

When stakeholders push for more scope:

1. **"What would you cut?"** — Adding scope means removing scope or extending timeline. Force the tradeoff.
2. **"What's the cost of waiting?"** — If the deferred feature can wait 4 weeks for v2, the cost of waiting is usually low.
3. **"Can we ship a simpler version?"** — Instead of "full search," can we ship "basic text search" in v1 and add filters in v2?
4. **"Let's validate first"** — "If we ship v1 without X and nobody asks for X, we saved ourselves the work. If everyone asks for X, we'll build it next."

---

## 3. Unknown Identification

What you don't know is often more important than what you do know. Unknowns left unidentified become surprises during implementation — the most expensive time to discover them.

### Types of Unknowns

| Type | Definition | Example | Strategy |
|------|-----------|---------|----------|
| **Known unknowns** | We know we don't know this. We can plan to find out. | "Can our database handle 10K concurrent connections?" | Technical spike, benchmark, research |
| **Unknown unknowns** | We don't even know to ask this question yet. | "Users will want to share recipes publicly but we never considered privacy controls." | Prototyping, user testing, domain expert review |
| **Assumptions masquerading as knowledge** | We think we know something but haven't verified it. | "Users prefer mobile over desktop" (never tested) | Assumption audit, data validation |

### Strategies for Each Unknown Type

**For known unknowns — plan specific investigations:**

| Strategy | When to Use | Time Investment | Output |
|----------|------------|-----------------|--------|
| **Technical spike** | Technical feasibility question | 1-3 days | "Yes/no with conditions" |
| **User research** | User behavior or preference question | 1-2 weeks | User insights, validated personas |
| **Competitive analysis** | Market or competitive question | 2-5 days | Landscape map, gap analysis |
| **Prototype** | "Will this approach work?" question | 3-5 days | Working proof-of-concept |
| **Expert consultation** | Domain-specific question | 1-2 hours | Expert judgment, constraints identified |
| **Data analysis** | "What's actually happening?" question | 1-3 days | Metrics, trends, patterns |

**For unknown unknowns — create conditions for discovery:**

- **Prototype with real users early** — unknowns surface when real people interact with real software
- **Talk to domain experts** — people who've been in the industry for years know the gotchas
- **Study failures** — look at similar products that failed and understand why
- **Assumption audit** — list every assumption behind the design brief and mark which ones are verified vs assumed
- **Pre-mortem** — "Imagine it's 6 months from now and this project failed. What went wrong?" (This is the inversion technique applied to unknowns)

**For assumptions masquerading as knowledge:**

- Challenge every "we know" statement: "How do we know that? Is it data, experience, or intuition?"
- Look for conflicting evidence: "Is there any reason this might not be true?"
- Downgrade to "assumption" and add verification strategy if not backed by data

### The Unknown Register

Track unknowns just like you track risks:

```
| # | Unknown | Type | Impact if Wrong | Strategy | Owner | Deadline | Status |
|---|---------|------|-----------------|----------|-------|----------|--------|
| 1 | Can Postgres handle our write volume? | Known unknown | Architecture change needed | Technical spike | Backend team | Week 2 | Open |
| 2 | Do users actually want collaborative editing? | Assumption | Building wrong feature | User interviews | Product | Week 1 | Open |
| 3 | Compliance requirements for storing health data | Known unknown | Scope increase, timeline impact | Legal review | Compliance | Week 1 | Open |
```

---

## 4. Risk Mapping

Risks are things that could go wrong. Unlike unknowns (which are gaps in knowledge), risks are identifiable threats with assessable probability and impact.

### Risk Categories

| Category | What Could Go Wrong | Examples |
|----------|-------------------|---------|
| **Technical risk** | The technology can't do what we need, or it's harder than expected | Performance doesn't meet requirements, integration is more complex than estimated, third-party API is unreliable |
| **Market risk** | Users don't want this, or the market shifts | No adoption, competitor launches first, market too small |
| **Team risk** | The team can't execute the plan | Key person leaves, skills gap, team too small, poor communication |
| **Timeline risk** | We can't ship on time | Underestimation, scope creep, dependencies delayed, unexpected complexity |
| **Operational risk** | We can ship it but can't run it | High maintenance cost, on-call burden, scaling surprises, vendor outages |
| **Compliance risk** | We violate regulations or policies | Data breach, audit failure, regulatory fine, missed certification |

### Risk Assessment Matrix

For each identified risk, assess likelihood and impact:

```
| Risk | Likelihood | Impact | Score | Mitigation |
|------|-----------|--------|-------|------------|
| {description} | {Low/Med/High} | {Low/Med/High} | {L*I} | {strategy} |
```

Scoring:
- **Low likelihood + Low impact** = Accept (don't worry about it)
- **Low likelihood + High impact** = Monitor (have a contingency plan)
- **High likelihood + Low impact** = Mitigate (reduce likelihood or impact)
- **High likelihood + High impact** = Avoid or Transfer (change the approach or insure against it)

### Mitigation Strategies

| Strategy | What It Means | Example |
|----------|--------------|---------|
| **Avoid** | Change the plan so the risk doesn't apply | "Use managed database instead of self-hosted to avoid operational risk" |
| **Mitigate** | Reduce likelihood or impact | "Do a technical spike in week 1 to validate the approach before committing" |
| **Transfer** | Shift the risk to someone else | "Use Stripe for payments to transfer PCI compliance burden" |
| **Accept** | Acknowledge the risk and move forward | "We accept the risk that the competitor might launch first; our differentiation is X" |
| **Monitor** | Watch for early warning signs | "Track API response times weekly; if p95 exceeds 500ms, escalate" |

### Pre-Mortem Technique

The single most effective risk identification technique. Run it at the end of the brainstorm, after the approach is chosen.

**How to run it:**

1. "Imagine it's 6 months from now. This project has failed. What went wrong?"
2. Write down every failure scenario — technical, team, market, operational
3. For each scenario: "How likely is this? How would we detect it early? What would we do to prevent it?"
4. The top 3-5 most likely/impactful scenarios become your risk register

**Why it works:** People are better at explaining past events than predicting future ones. By framing risk identification as "what went wrong" instead of "what could go wrong," you bypass optimism bias and get more honest assessments.

---

## 5. Decision Criteria

When the tradeoff matrix doesn't give a clear winner, you need secondary criteria to break the tie. These are the meta-principles for making good decisions under uncertainty.

### Reversibility

Prefer reversible decisions. Irreversible decisions need more analysis; reversible decisions need more speed.

| Decision Type | Examples | Approach |
|--------------|---------|----------|
| **One-way door** | Primary database, cloud provider, core language, major vendor commitment | Invest significant research time. Get multiple perspectives. Document reasoning thoroughly. |
| **Sliding door** | Framework choice, API design, service boundaries | Moderate research. Consider migration cost if you need to change later. |
| **Two-way door** | UI library, CSS framework, logging tool, internal tooling choice | Decide quickly. If it doesn't work, switch. The cost of analysis exceeds the cost of switching. |

Questions to assess reversibility:
- "If this turns out to be wrong in 6 months, what does it cost to change?"
- "How much code would need to be rewritten?"
- "How much data migration would be required?"
- "Would users be affected during the transition?"

### Time-to-Learn

Prefer approaches that teach you faster. In the early stages of a project, learning speed matters more than efficiency.

| Approach | Learning Speed | When to Prefer |
|----------|---------------|----------------|
| Build a prototype | Fast — learn from real user interaction | When you're unsure about user needs or technical feasibility |
| Do competitive analysis | Medium — learn from others' experiences | When the market is established and patterns exist |
| Build the full thing | Slow — learn after significant investment | When the problem is well-understood and the approach is proven |

"What's the fastest way to learn whether this approach works?" is a more useful question than "What's the best approach?"

### Team Alignment

Prefer approaches the team can execute confidently. A theoretically superior approach that the team can't build (or hates building) is practically inferior.

Signals of good alignment:
- The team has experience with the required technologies
- The approach plays to the team's strengths
- The team is enthusiastic (or at least not resistant)
- No single-person dependencies (no "only Alice can do this")

Signals of poor alignment:
- "We'd need to hire someone for that" — hiring is slow and uncertain
- "Nobody here has done this before" — learning curve is a hidden cost
- "That sounds like a lot of work we don't enjoy" — morale affects quality
- "Only one person could build that" — bus factor risk

### Optionality

Prefer approaches that keep future options open. In uncertain environments, optionality has value.

- Does approach A allow us to pivot to approach B later? (Good: preserves optionality)
- Does approach A lock us into a specific vendor or technology? (Bad: reduces optionality)
- Does approach A generate data or learnings useful for future decisions? (Good: increases optionality)

---

## 6. Killing Darlings

One of the hardest parts of convergence is letting go of ideas the team (or the user) loves but that don't meet the criteria. This is emotionally difficult but essential for shipping.

### The Parking Lot Technique

Don't kill ideas — park them. Create an explicit "parking lot" list of ideas that:

- Didn't make the cut for v1 but have merit
- Are interesting but not aligned with current constraints
- Need more research before we can evaluate them properly
- Are great ideas for a different project or a future version

The parking lot respects the idea (and the person who proposed it) while keeping the current scope focused. It also becomes the starting point for v2 planning.

### How to Let Go

When the user is attached to a feature that doesn't fit:

1. **Validate the idea**: "This is a genuinely good idea. The question isn't whether it's good — it's whether it's right for v1."
2. **Make the tradeoff explicit**: "If we include X in v1, we'd need to cut Y or extend the timeline by Z weeks. Is that a trade you want to make?"
3. **Show the path to inclusion**: "Let's put X in the v2 list with a clear trigger. If we ship v1 and users ask for X, we'll prioritize it immediately."
4. **Reframe as learning**: "Shipping without X first actually teaches us something — if nobody misses it, we saved ourselves the work."

### Decision Fatigue Management

Long brainstorming sessions degrade decision quality. Watch for:

- **Late-session additions**: New features proposed in the last 15 minutes of a long session are usually lower quality
- **"Yes to everything"** mode: When the team stops pushing back on scope additions, they're tired, not agreeing
- **Revisiting decided items**: Going back to choices already made is a sign of fatigue, not genuine reconsideration

When you detect fatigue: "We've covered a lot of ground. Let me summarize where we are and what's still open. I think we can wrap up the remaining decisions in a fresh session."

---

## 7. Consensus vs Decision-Maker

Not every decision needs consensus, and not every decision should be made by one person. Matching the decision-making style to the decision type saves time and produces better outcomes.

### When to Seek Consensus

| Seek Consensus When... | Because... |
|------------------------|-----------|
| The decision affects how the whole team works | Buy-in matters for adoption |
| The decision is hard to reverse | Everyone should understand and accept the tradeoffs |
| Multiple people have relevant expertise | More perspectives produce better decisions |
| The team needs to own the outcome | Imposed decisions get sabotaged (consciously or not) |

Examples: Core technology choices, team processes, architectural patterns, definition of done

### When One Person Decides

| One Person Decides When... | Because... |
|---------------------------|-----------|
| The decision is easily reversible | Speed matters more than consensus |
| One person has clearly superior expertise | Their judgment is the most informed |
| The team is deadlocked | Someone needs to break the tie |
| The decision is about implementation details | Consensus on implementation creates design-by-committee |

Examples: Which library to use, API naming conventions, code style, internal tool selection

### The "Disagree and Commit" Pattern

When the team can't reach consensus but a decision is needed:

1. **Ensure everyone has been heard** — the dissenting voice has explained their concern fully
2. **Acknowledge the disagreement** — "We have two valid perspectives and no clear winner"
3. **Make the call** — the designated decision-maker chooses
4. **Commit fully** — everyone executes the chosen approach with full effort, not half-heartedly
5. **Set a review point** — "Let's revisit this in 4 weeks with real data"

This is not "the boss always wins." It's "we've explored thoroughly, we can't agree, someone has to decide, and we all commit to making the decision work."

### Decision Documentation

For every significant decision during convergence, capture:

```
## Decision: {What was decided}

**Date:** {date}
**Decider:** {who made the final call}
**Context:** {why this decision was needed}
**Options considered:** {list with brief pros/cons}
**Chosen option:** {which one and why}
**Dissenting views:** {what concerns were raised}
**Review date:** {when to revisit, if applicable}
```

This becomes part of the design brief and feeds into ETYB's decision log.
