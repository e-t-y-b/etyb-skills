# Exploration Techniques

Deep reference for the divergent/exploratory phase of brainstorming. Read this during steps 1-4 of the brainstorming dialogue: understanding the problem, identifying constraints, mapping mental models, and generating solution approaches.

---

## 1. Problem Space Mapping

The single most important skill in brainstorming is understanding the problem before proposing solutions. Most failed projects don't fail because of bad technology — they fail because they solve the wrong problem, or solve the right problem for the wrong user.

### The Four Questions

Every problem space exploration starts with these four questions. Get answers to all four before moving to solutions.

**1. Who is the user?**

Not "users" — a specific person with specific needs. The more concrete, the better.

| Too Vague | Better | Best |
|-----------|--------|------|
| "Users" | "Small business owners" | "Solo restaurant owners who manage their own inventory and don't have a dedicated IT person" |
| "Everyone" | "Developers" | "Junior backend developers at companies with 5-20 engineers who deploy to AWS" |
| "Customers" | "E-commerce shoppers" | "Repeat customers who buy 3+ times per month and use mobile exclusively" |

Techniques for identifying the user:
- **"Who would cry if this didn't exist?"** — identifies the core user with the most pain
- **"Who uses the workaround today?"** — identifies people already trying to solve this problem
- **"Who would pay for this?"** — separates nice-to-have users from must-have users
- **"Who can't use the current solution?"** — identifies underserved segments

If the user says "it's for everyone," push back gently: "If we had to pick one type of person to make really happy with v1, who would that be?"

**2. What pain are we solving?**

Pain is the foundation. No pain, no product. Understanding the pain determines the solution shape.

| Pain Level | Characteristics | Solution Implication |
|-----------|----------------|---------------------|
| **Vitamin** | Nice to have, mild convenience | Hard to get adoption; needs to be free or nearly free |
| **Painkiller** | Solves a real, recurring pain | Willing to pay; moderate urgency to adopt |
| **Lifesaver** | Critical problem, no good alternative | Willing to pay premium; high urgency |

Questions to assess pain:
- "How often does this problem occur?" (daily vs monthly changes everything)
- "What happens when the problem occurs?" (minor inconvenience vs lost revenue)
- "How much time/money does the current workaround cost?"
- "Have you tried to solve this before? What happened?"

**3. What exists today?**

Understanding the current state reveals constraints, expectations, and migration challenges.

- "How do people handle this today?" (manual process, spreadsheet, competitor tool, nothing)
- "What do they like about the current approach?" (don't break what works)
- "What do they hate about it?" (this is your opportunity)
- "Are there tools they've tried and abandoned? Why?"

**4. What alternatives do they currently use?**

Direct and indirect competitors, plus the "do nothing" option.

- **Direct competitors**: Tools that solve the same problem for the same user
- **Indirect competitors**: Tools that partially solve the problem as a side effect (e.g., Excel "competes" with almost everything)
- **Manual workarounds**: Spreadsheets, email chains, sticky notes, phone calls
- **Do nothing**: The user tolerates the pain — this is your biggest competitor

### Problem Statement Formula

After gathering answers, synthesize into a problem statement:

```
{Target user} needs a way to {job to be done} because {pain/reason},
but today they {current workaround}, which {limitation of workaround}.
```

Examples:

> Solo restaurant owners need a way to track ingredient inventory and costs because food waste directly cuts into their thin margins, but today they use spreadsheets and guesswork, which means they regularly over-order perishables and can't spot cost trends.

> Junior developers at small startups need a way to set up CI/CD pipelines because their team doesn't have a dedicated DevOps person, but today they copy-paste configs from blog posts, which leads to fragile pipelines that break unpredictably and nobody knows how to fix.

### When the User Skips the Problem

Sometimes users arrive with a solution, not a problem. "I want to build a React app with real-time chat." This is solution-first thinking, and it's the most common pattern you'll encounter.

Don't reject it — use it as a starting point to work backward:

1. "That sounds interesting — who would be using the chat feature?"
2. "What's happening today that makes you want to add chat?"
3. "What would success look like for this feature?"
4. "Are there existing chat solutions you've considered? What's missing from them?"

The goal is to understand WHY they want chat so you can verify that chat is actually the right solution.

---

## 2. Constraint Identification

Constraints shape solutions. A project with $0 budget and 2 weeks looks nothing like the same project with $100K and 6 months. Surface all constraints early — they prevent wasted exploration.

### The Constraint Taxonomy

#### Time Constraints
- **Hard deadline**: Event, regulatory date, contract obligation, market window
- **Soft deadline**: Business preference, stakeholder expectation, competitive pressure
- **No deadline**: Ongoing product development, internal tooling, exploratory work

Questions:
- "Is there a hard deadline? What happens if we miss it?"
- "Is this tied to an event, launch, or external date?"
- "What's the cost of shipping 2 weeks late? 2 months late?"

#### Budget Constraints
- **No budget**: Side project, internal tool, open source
- **Fixed budget**: Contract work, grant-funded, approved project budget
- **Flexible budget**: Startup with runway, enterprise with discretionary funding

Questions:
- "Is there a budget for third-party services (hosting, APIs, SaaS tools)?"
- "Are we paying for development time or is this internal team capacity?"
- "What's the ongoing operational cost ceiling?"

#### Team Constraints
- **Size**: Solo developer vs 3-person team vs 20-person org
- **Skills**: What the team knows well vs what requires learning
- **Availability**: Full-time on this vs splitting with other projects
- **Location**: Co-located vs distributed (timezone implications)

Questions:
- "How many people are working on this?"
- "What's the team's primary tech stack and expertise?"
- "Is the team dedicated to this project or splitting time?"
- "Any hiring planned? Timeline for new team members being productive?"

#### Technical Constraints
- **Existing stack**: Must integrate with current systems, languages, frameworks
- **Infrastructure**: On-prem vs cloud, specific cloud provider requirements
- **Data**: Existing databases, data migration needs, data formats
- **Integrations**: Third-party APIs, legacy systems, partner systems
- **Performance**: Latency requirements, throughput needs, data volume

Questions:
- "What's the existing tech stack?"
- "Are there systems this needs to integrate with?"
- "Is there existing data that needs to be migrated or accessed?"
- "Are there performance requirements (response time, concurrent users)?"

#### Regulatory Constraints
- **Healthcare**: HIPAA (PHI handling, BAAs, audit logging)
- **Finance**: PCI-DSS (card data), SOX (financial reporting), banking regulations
- **Privacy**: GDPR (EU data), CCPA (California), data residency requirements
- **Accessibility**: WCAG 2.1 AA/AAA, Section 508
- **Industry-specific**: FedRAMP (government), FERPA (education), COPPA (children)

Questions:
- "Is this handling any sensitive data (health, financial, personal)?"
- "Are there compliance requirements we need to meet?"
- "Does data need to stay in specific geographic regions?"
- "Do we need accessibility compliance?"

#### User Constraints
- **Accessibility**: Screen reader support, keyboard navigation, color contrast
- **Language**: Multi-language support, RTL languages, localization
- **Connectivity**: Offline support, low-bandwidth environments
- **Device**: Mobile-first, desktop-only, cross-platform, specific OS versions
- **Technical literacy**: Developer users vs non-technical users

Questions:
- "What devices will people use this on?"
- "Do we need to support offline use?"
- "What's the technical comfort level of the target users?"
- "Any language or accessibility requirements?"

### Constraint Priority Matrix

Not all constraints are equal. Classify each as:

| Priority | Meaning | Example |
|----------|---------|---------|
| **Hard** | Non-negotiable, violating this is a project failure | HIPAA compliance for health data |
| **Firm** | Strongly preferred, would need executive override to change | Ship before the conference in March |
| **Soft** | Preferred but flexible, can be traded for other value | Support mobile browsers (could be v2) |
| **Wish** | Nice to have, no real consequence if not met | Dark mode support |

---

## 3. Mental Model Mapping

Understanding what the user already believes about the solution is critical. Their mental model shapes what they'll accept, what they'll resist, and where they might have blind spots.

### What to Listen For

**Assumptions about the solution:**
- "It should be a mobile app" — Why mobile? Is web not an option?
- "We need microservices" — What's driving that? Is the team ready for that complexity?
- "We'll use AI for this" — Is AI actually the right approach, or is it hype-driven?

**Assumptions about the user:**
- "Everyone will want this" — Who specifically? What evidence?
- "It's obvious how to use it" — Have they tested with real users?
- "Our users are technical" — How technical? Developer-technical or "uses Excel" technical?

**Assumptions about the market:**
- "Nobody else does this" — Have they searched thoroughly? Maybe the problem isn't worth solving.
- "It's a billion-dollar market" — For whom? What slice are they realistically capturing?

### Cognitive Biases to Watch For

| Bias | What It Looks Like | How to Address |
|------|--------------------|----------------|
| **Anchoring** | Fixated on the first idea or the first technology that came to mind | "That's one approach — let me suggest two alternatives so we can compare" |
| **Sunk Cost** | "We've already built X, so we need to keep using it" | "What would we choose if we were starting from scratch? Is the switching cost worth the improvement?" |
| **Survivorship Bias** | "Company X did it this way and they succeeded" | "They succeeded, but how many companies tried the same approach and failed? What was different about their context?" |
| **Confirmation Bias** | Only considering evidence that supports their preferred approach | "Let's steelman the alternative — what's the strongest case for approach B?" |
| **Dunning-Kruger** | Underestimating complexity because they haven't built something like this before | "Teams that have built similar systems report that X was much harder than expected. Let's plan for that" |
| **Availability Bias** | Overweighting recent experiences or dramatic examples | "That's a valid data point, but is it representative? What does the broader pattern look like?" |
| **Bandwagon Effect** | "Everyone is using X" | "X is popular, but is it popular for our use case? Let's check if our constraints match the typical X user" |
| **IKEA Effect** | Over-valuing their own prior work or ideas | "You've done great work on this already. Let's make sure we're building on the strongest parts" |

### Gentle Redirection Techniques

When the user's mental model has gaps or errors, don't confront directly. Use these patterns:

1. **"Yes, and..."** — Accept their input and expand: "Yes, a mobile app could work. And we might also consider a PWA, which gives us mobile presence without the app store overhead."
2. **"I've seen teams..."** — Share indirect experience: "I've seen teams in similar situations discover that their users actually preferred a simple web form over a mobile app because they were at their desks when they needed it."
3. **"What if..."** — Hypothetical exploration: "What if we validated that assumption first? A quick prototype could tell us whether mobile is essential or just preferred."
4. **"Help me understand..."** — Genuine curiosity: "Help me understand why microservices feels like the right fit. I want to make sure we're choosing it for the right reasons."

---

## 4. Divergent Thinking Techniques

The goal of divergent thinking is to generate meaningfully different approaches to the problem — not variations on the same theme. "React vs Vue vs Svelte" is not divergent thinking. "Build a custom app vs use an off-the-shelf tool vs redesign the process so software isn't needed" is divergent thinking.

### Technique 1: The Company Lens

"How would [company] solve this?" Apply different company philosophies to the same problem.

| Company Philosophy | Approach Style | Best For |
|-------------------|----------------|----------|
| **Amazon** | Start with the press release. Work backward from the customer experience. Build the minimum to validate. | Products where user experience clarity matters most |
| **Stripe** | Developer experience first. API-first design. Documentation as a feature. | Developer tools, platforms, APIs |
| **Basecamp** | Ruthlessly simple. Say no to features. Ship small, opinionated software. | Products where simplicity is the differentiator |
| **Google** | Data-driven. Prototype fast. Let metrics decide. Kill things that don't work. | Products where you can measure success clearly |
| **Apple** | Design-driven. Integrated experience. Control the full stack. | Products where polish and integration matter most |

Use this technique when the team is stuck in one mode of thinking. "We've been assuming we need to build a platform. What if we took the Basecamp approach and built something deliberately simple?"

### Technique 2: The Simplicity Spectrum

Generate approaches at different complexity levels:

1. **Zero-code**: "Could we solve this with a spreadsheet, Airtable, or Notion database?"
2. **Low-code**: "Could we solve this with Zapier, Retool, or a WordPress plugin?"
3. **Simple custom**: "What's the simplest custom software that solves the core problem?"
4. **Full custom**: "What's the complete solution with all the features?"
5. **Platform**: "What if we built this as a platform others could extend?"

Most teams jump to level 3 or 4 without considering 1 or 2. For early-stage or internal tools, levels 1-2 are often the right answer. The "simplest thing that could work" is a powerful filter.

### Technique 3: The Resource Spectrum

Explore how the solution changes under different resource assumptions:

- **"What if we had 2 weeks?"** — Forces ruthless prioritization. What's the absolute core?
- **"What if we had 6 months?"** — Allows for proper architecture. What would we do differently?
- **"What if we had unlimited budget?"** — Reveals the ideal experience. What's the dream?
- **"What if we had $0 budget?"** — Forces creative use of existing tools and open source.
- **"What if the team was 10x larger?"** — Reveals parallelizable work and platform thinking.
- **"What if it was just one person?"** — Reveals the critical path and essential features.

### Technique 4: Inversion

"How would we make this fail?" Then avoid those things.

Instead of asking "how do we build a great recipe app," ask:
- "How would we build a recipe app that nobody uses?"
- "What would make someone delete this app after one day?"
- "What would make the development team quit?"

Common failure modes that inversion reveals:
- Onboarding that requires too many steps
- Solving a problem the user doesn't actually have
- Building for the general case when the specific case is what matters
- Ignoring the migration problem (how do users get their existing data in?)
- Over-building before validating demand

### Technique 5: Analogies from Other Domains

The best solutions often come from translating patterns across domains.

| If Your Problem Is... | Look At How... |
|----------------------|----------------|
| User onboarding | Video games introduce mechanics gradually |
| Data entry | Conversational UIs reduce form fatigue |
| Complex configuration | IDE settings use sensible defaults with progressive disclosure |
| Content organization | Libraries use multiple classification systems (Dewey, subject, format) |
| Collaboration | Git solved concurrent editing with branching, not locking |
| Notifications | Emergency services use triage to prioritize alerts |

Prompt the user: "This problem reminds me of how [domain] handles [similar challenge]. What if we borrowed that pattern?"

### Technique 6: The "What If Software Isn't the Answer?" Check

Before committing to building software, ask whether the problem could be solved with:

- **Process change**: "What if we changed the workflow instead of automating the current one?"
- **Training**: "What if the problem is that people don't know how to use existing tools?"
- **Communication**: "What if a weekly email summary solves 80% of the need?"
- **Existing tools**: "What if we configure Slack/Notion/Jira differently?"
- **Hiring**: "What if we hire someone to handle this instead of building a tool?"

This isn't about avoiding building software — it's about ensuring software is the right lever for this problem.

---

## 5. Stakeholder Identification

"Who else cares about this?" is a question that prevents scope surprises, adoption failures, and political landmines.

### The Stakeholder Map

| Stakeholder Type | Why They Matter | What to Ask Them |
|-----------------|-----------------|------------------|
| **End users** | They use the thing. If they don't adopt it, nothing else matters. | What's painful? What do you wish existed? What would make you switch from your current tool? |
| **Operations** | They run and maintain it. If it's operationally expensive, it dies. | How will this be deployed? Who's on call? What monitoring exists? |
| **Compliance** | They say no. If they aren't consulted early, they say no later — at higher cost. | What regulations apply? What audit requirements exist? What data classification? |
| **Business/Product** | They fund it and define success. Misaligned expectations lead to "successful" projects nobody's happy with. | What does success look like? How will we measure it? What's the budget and timeline expectation? |
| **Adjacent teams** | They're affected by it. Ignored adjacent teams become blockers or competitors. | Does this overlap with anything you're building? Do you need to integrate with this? |
| **Leadership** | They approve it. If the project doesn't align with strategic priorities, it gets deprioritized. | How does this align with company goals? What's the priority relative to other initiatives? |

### The RACI Shortcut

For brainstorming purposes, you don't need a full RACI matrix. Just identify:

- **Decider**: Who has final say on what we build? (Usually product owner or founder)
- **Builders**: Who will build it? (Development team)
- **Blockers**: Who could say no or slow us down? (Compliance, security, leadership)
- **Beneficiaries**: Who benefits from the result? (End users, operations)

---

## 6. Question Techniques

The quality of a brainstorm depends on the quality of the questions asked.

### The Question Funnel

Start broad and open-ended. Narrow as understanding develops.

**Phase 1: Open exploration** (Steps 1-2)
- "Tell me about..."
- "Walk me through..."
- "What does a typical day look like when..."
- "What's the story behind this idea?"

**Phase 2: Focused probing** (Steps 3-4)
- "You mentioned X — can you tell me more about that?"
- "What happens when Y goes wrong?"
- "How would you prioritize A vs B?"
- "What's the most important thing about this?"

**Phase 3: Confirming and narrowing** (Steps 5-7)
- "So if I understand correctly, the key problem is..."
- "It sounds like the main constraint is..."
- "Between these three approaches, which feels most aligned with..."
- "Would it be accurate to say that v1 should include X but not Y?"

**Phase 4: Validating** (Steps 8-9)
- "If we shipped this tomorrow, what would you check first?"
- "What's the one thing that could make this fail?"
- "How would you know this was successful in 3 months?"
- "Is there anything we haven't talked about that feels important?"

### Questions to Avoid

| Avoid | Why | Instead |
|-------|-----|---------|
| "Should we use React or Vue?" | Premature technology choice | "What kind of user experience are we aiming for?" |
| "Is this a good idea?" | Too vague, invites platitudes | "Who specifically benefits from this, and how much?" |
| "Can we build this?" | Yes/no question, doesn't reveal constraints | "What would need to be true for us to build this in 8 weeks?" |
| "Don't you think X is better?" | Leading question, biases the answer | "What are the pros and cons of X vs Y in our context?" |
| "What's the best framework?" | No context, no constraints, no useful answer | "Given our team of 4 React developers and 6-week timeline, what approach would you recommend?" |

---

## 7. Red Flags in User Requests

Patterns that signal the brainstorm needs to go deeper before moving to planning.

### Solution-First Thinking

**Red flag**: "I need a React app with Firebase backend, Stripe for payments, and Tailwind for styling."

**What's happening**: The user has jumped past the problem entirely. They're describing implementation, not intent.

**Response**: "You've clearly been thinking about this — those are solid technology choices. Before we commit to the approach, can I ask a few questions about what problem this solves? I want to make sure we're building the right thing with those tools."

### Technology Fixation

**Red flag**: "We need to use GraphQL" / "It has to be serverless" / "We should use AI for this."

**What's happening**: A specific technology has captured their imagination (or their boss mentioned it).

**Response**: "GraphQL is great for certain problems. What's driving the GraphQL preference — is it the query flexibility, the type system, or something else? Understanding the 'why' helps me make sure GraphQL is the right fit vs alternatives."

### Scope Creep Signals

**Red flag**: "And it should also..." / "Oh, and we need..." / "Eventually it will need to..."

**What's happening**: Features are accumulating without prioritization. Every feature is treated as equally important.

**Response**: "There are a lot of great ideas here. Let's separate them into what's essential for v1 vs what can come later. If we could only ship three features, which three would make this useful?"

### Unclear Success Criteria

**Red flag**: "We'll know it when we see it" / "It should just work well" / "Make it user-friendly."

**What's happening**: No measurable definition of success. This leads to endless iterations and "it's not quite right" feedback.

**Response**: "I want to make sure we can objectively tell when this is done. What would a user be able to do that they can't do today? How would we measure whether the solution is working?"

### Copying Without Context

**Red flag**: "Build it like Slack" / "Make it work like Notion" / "We want our own Figma."

**What's happening**: Anchoring on a successful product without understanding that Slack has 2000+ engineers and 8 years of development.

**Response**: "Slack does a lot of things well. Which specific aspect of Slack are you most interested in replicating? Understanding the core need helps us build something achievable with our constraints."

### The Missing "Who"

**Red flag**: "Users will love this" / "People need this" / "Everyone wants this."

**What's happening**: No specific user identified. Building for "everyone" means building for no one.

**Response**: "Let's get specific about who benefits most. If you had to describe one person who would use this every day, who are they? What's their job title, their biggest frustration, and what they do today to work around it?"

### The Premature Scale Problem

**Red flag**: "It needs to handle millions of users from day one" / "We need to be enterprise-ready."

**What's happening**: Over-engineering for scale that doesn't exist yet. This kills velocity and increases complexity.

**Response**: "Planning for scale is smart, but building for it on day one can slow us down significantly. What if we designed for scale but built for our actual first 100 users? That way we validate the idea without over-investing in infrastructure."
