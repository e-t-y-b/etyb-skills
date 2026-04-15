# Sprint Planning — Deep Reference

**Always use `WebSearch` to verify tool features, framework updates, and estimation technique recommendations. Sprint planning tools and practices evolve rapidly. Last verified: April 2026.**

## Table of Contents
1. [Story Breakdown and Splitting](#1-story-breakdown-and-splitting)
2. [Estimation Methods](#2-estimation-methods)
3. [Sprint Capacity Planning](#3-sprint-capacity-planning)
4. [Sprint Goal Setting](#4-sprint-goal-setting)
5. [Backlog Refinement](#5-backlog-refinement)
6. [Definition of Done](#6-definition-of-done)
7. [Sprint Metrics](#7-sprint-metrics)
8. [Planning Tools](#8-planning-tools)
9. [AI-Assisted Planning](#9-ai-assisted-planning)
10. [Remote and Hybrid Sprint Planning](#10-remote-and-hybrid-sprint-planning)
11. [Sprint Anti-Patterns](#11-sprint-anti-patterns)
12. [Sprint Length Selection](#12-sprint-length-selection)
13. [Running the Sprint Planning Ceremony](#13-running-the-sprint-planning-ceremony)

---

## 1. Story Breakdown and Splitting

### The INVEST Criteria

Every user story should be:
- **I**ndependent — can be developed without depending on other stories in the sprint
- **N**egotiable — details can be discussed, not a rigid contract
- **V**aluable — delivers value to a user or stakeholder
- **E**stimable — team can reasonably estimate the effort
- **S**mall — completable within a sprint (ideally 1-3 days)
- **T**estable — has clear acceptance criteria that can be verified

### Story Splitting Techniques

When a story is too large, use these patterns to break it down:

| Technique | When to Use | Example |
|-----------|-------------|---------|
| **Workflow steps** | Story covers a multi-step process | "User checks out" → separate stories for cart review, payment, confirmation |
| **Happy path / edge cases** | Complex validation or error handling | "User logs in" → happy path first, then forgot password, MFA, account locked |
| **Data variations** | Different data types or sources | "Import data" → CSV import, then Excel, then API sync |
| **CRUD operations** | Full entity lifecycle | "Manage users" → create, read, update, delete as separate stories |
| **UI / API split** | Frontend and backend can be built independently | "Search products" → API endpoint story + UI story |
| **Spike + implementation** | High uncertainty / technical risk | "Integrate payment provider" → spike (research + POC) then implementation |
| **Simple / complex** | Different complexity levels within same feature | "Dashboard" → static data display first, then real-time updates |
| **Platform variations** | Multi-platform support | "Push notifications" → iOS first, then Android, then web |

### Vertical Slicing

Always slice vertically (thin end-to-end slices) rather than horizontally (layers):

**Bad (horizontal):**
- Story 1: Build the database schema
- Story 2: Build the API endpoints
- Story 3: Build the frontend forms

**Good (vertical):**
- Story 1: User can create an account (DB + API + minimal UI)
- Story 2: User can view their profile (DB + API + UI)
- Story 3: User can edit their profile (DB + API + UI with validation)

Vertical slices deliver working functionality each sprint. Horizontal slices deliver nothing usable until all layers are complete.

### User Story Mapping

Jeff Patton's story mapping technique organizes stories in a 2D map:

```
Backbone (user activities, left to right):
  Browse Products → Add to Cart → Checkout → Track Order

Walking skeleton (minimum path through each activity):
  View product list → Add item → Enter payment → See status

Subsequent releases (depth under each activity):
  Search/filter    → Update qty  → Save address → Email updates
  Product reviews  → Wishlist    → Promo codes  → Return flow
```

The walking skeleton becomes your MVP. Each row below adds depth. Sprint planning pulls stories from the map top-down.

### Acceptance Criteria Patterns

**Given-When-Then (Gherkin):**
```
Given I am a logged-in user with items in my cart
When I click "Checkout" and enter valid payment details
Then my order is created and I see a confirmation with order number
```

**Checklist style:**
```
- [ ] User can enter credit card details
- [ ] Card validation shows inline errors
- [ ] Successful payment redirects to confirmation
- [ ] Failed payment shows retry option with error message
- [ ] Order confirmation email is sent within 30 seconds
```

Both formats work — use whichever the team prefers. The key is specificity: vague acceptance criteria lead to scope creep and "done" disputes.

---

## 2. Estimation Methods

### Story Points

Story points estimate **relative complexity**, not time. The most common scales:

| Scale | Values | Best For |
|-------|--------|----------|
| **Fibonacci** | 1, 2, 3, 5, 8, 13, 21 | Most teams — the non-linear gaps reflect increasing uncertainty |
| **Modified Fibonacci** | 1, 2, 3, 5, 8, 13, 20, 40, 100 | Large backlogs with wide variance |
| **Powers of 2** | 1, 2, 4, 8, 16, 32 | Teams that prefer doubling as the unit of "bigger" |

**Planning Poker:**
1. Product Owner reads the story and answers clarifying questions
2. Each team member privately selects a card
3. All cards revealed simultaneously
4. If estimates differ by more than 2 positions, the highest and lowest explain their reasoning
5. Re-vote after discussion (usually converges in 2 rounds)
6. If still diverging after 2 rounds, take the higher estimate or spike

**Reference story technique:** Pick a well-understood completed story as your "3" (or whatever baseline). Estimate everything relative to it. Re-calibrate every few sprints as the team's understanding of "a 3" evolves.

### T-Shirt Sizing

Less precise than story points but faster. Good for roadmap-level estimation:

| Size | Relative Effort | Rough Duration (1 dev) |
|------|----------------|----------------------|
| **XS** | Trivial | < half a day |
| **S** | Small, well-understood | 1 day |
| **M** | Moderate complexity | 2-3 days |
| **L** | Significant effort | 1 week |
| **XL** | Too big — must be split | > 1 week (split it) |

T-shirt sizes are great for initial backlog triage and roadmap planning. Convert to story points when the team needs more precision for sprint planning.

### No-Estimates / #NoEstimates

The no-estimates movement focuses on **making stories small enough that they don't need estimating**:

**Core premise:** If every story is roughly the same size (1-3 days), you can forecast by counting stories, not estimating effort.

**How it works:**
1. Break everything into stories that take 1-3 days
2. Track throughput (stories completed per week)
3. Forecast: "We complete ~8 stories per sprint. We have 24 stories. That's ~3 sprints."
4. Use Monte Carlo simulation for probabilistic forecasting

**When it works well:**
- Mature teams with disciplined story splitting
- Continuous delivery environments
- Teams tired of estimation theater

**When it doesn't work:**
- Stories vary wildly in size (infrastructure work vs UI tweaks)
- External stakeholders demand date commitments based on scope
- Team is new and hasn't calibrated what "small" means yet

### Monte Carlo Forecasting

Uses historical throughput data to generate probabilistic forecasts:

1. Collect throughput data (stories completed per sprint) for the last 10-20 sprints
2. Run 10,000 simulations, randomly sampling from historical throughput
3. Generate a probability distribution: "There's an 85% chance we'll complete this by Sprint 7"

**Tools:** Actionable Agile (analytics platform), Monte Carlo spreadsheet templates, Jira plugins (ActionableAgile, Cycle Time Analytics), Linear (built-in project insights)

**Key advantage:** Communicates uncertainty honestly. Instead of "We'll be done in 6 sprints," you say "We have an 85% confidence of finishing by Sprint 7 and a 50% chance of finishing by Sprint 5."

### Cycle Time-Based Estimation

Instead of estimating forward, use historical data:

1. Tag stories by type/complexity (bug fix, feature, refactor, infrastructure)
2. Track cycle time (from "in progress" to "done") by category
3. Use percentiles for forecasting:
   - p50: "A typical feature takes 3 days"
   - p85: "85% of features complete within 5 days"
   - p95: "Almost all features complete within 8 days"

This approach eliminates estimation meetings entirely — the data speaks for itself.

### Estimation Method Selection Guide

| Situation | Recommended Method |
|-----------|-------------------|
| New team, little historical data | Story points with Planning Poker |
| Mature team, consistent sizing | No-estimates with throughput counting |
| Roadmap-level planning | T-shirt sizing |
| Date commitment with uncertainty range | Monte Carlo forecasting |
| Team fatigued by estimation ceremonies | Cycle time-based estimation |
| Mixed technical and non-technical stakeholders | T-shirt sizing (roadmap) + story points (sprint) |

---

## 3. Sprint Capacity Planning

### Calculating Team Capacity

**Hours-based approach:**

```
Available hours per person per sprint:
  Sprint days × hours per day × focus factor − planned absences

Focus factor (percentage of time on sprint work):
  - New team: 50-60%
  - Established team: 60-70%
  - Mature team: 70-80%

Focus factor accounts for:
  - Meetings (standups, refinement, reviews, retros)
  - Unplanned work (production support, bug fixes)
  - Code reviews
  - Context switching
  - Administrative tasks
```

**Example (2-week sprint, 5-person team):**
```
10 days × 8 hours × 0.65 focus factor = 52 productive hours per person
5 people × 52 hours = 260 team hours available
Minus: 1 person on PTO for 3 days = 260 - 24 = 236 team hours
```

**Velocity-based approach (preferred for mature teams):**

```
Use rolling average of last 3-5 sprints' completed story points:
  Sprint 1: 34 points
  Sprint 2: 28 points
  Sprint 3: 31 points
  Sprint 4: 36 points
  Sprint 5: 30 points
  
  Average: 31.8 points
  Range: 28-36 points

Plan for: 28-32 points (err conservative)
Adjust for: known PTO, holidays, production support rotation
```

### Accounting for Unplanned Work

Reserve capacity for unplanned work. Common approaches:

| Approach | How It Works | When to Use |
|----------|-------------|-------------|
| **80/20 rule** | Plan 80% feature work, reserve 20% for bugs/tech debt/unplanned work | Widely adopted best practice — Scrum.org explicitly recommends developers demand 20% slack |
| **Buffer percentage** | Reserve 15-25% of capacity for unplanned work | Teams with predictable interrupt rate |
| **Bug budget** | Allocate specific story points to bug fixes | Teams with known bug backlog |
| **Interrupt rotation** | One person handles all interrupts per sprint | Teams with high support load |
| **Split board** | Separate kanban for unplanned work | Dual-track teams (feature + support) |

Track the ratio of planned vs unplanned work over time. If unplanned work consistently exceeds 30%, address the root cause (technical debt, operational gaps, unclear requirements).

### Sprint Commitment Strategies

| Strategy | Description | Best For |
|----------|-------------|----------|
| **Committed + stretch** | Team commits to core stories, adds stretch goals | Teams learning their velocity |
| **Confidence levels** | Mark stories as "high confidence" or "if time permits" | Teams with variable capacity |
| **Sprint goal-focused** | Commit to the goal, flex the stories | Teams that want outcome-driven sprints |
| **Throughput-based** | Plan to the conservative end of velocity range | Mature teams with good data |

---

## 4. Sprint Goal Setting

### What Makes a Good Sprint Goal

- **Outcome-oriented**, not output-oriented: "Users can complete checkout" not "Finish 12 stories"
- **Achievable** within the sprint with the available team
- **Focused** on a single theme or outcome (ideally)
- **Measurable** — you can objectively say whether it was met at the sprint review
- **Connected** to the product roadmap or quarterly OKRs

### Sprint Goal Examples

**Bad:** "Complete sprint backlog items" (just restates the plan)
**Bad:** "Work on user management" (too vague to measure)
**Good:** "New users can sign up, verify email, and log in for the first time"
**Good:** "Reduce checkout abandonment by implementing address autocomplete and saved payment methods"
**Good:** "Complete the API integration with Stripe so the payments team can begin their frontend work next sprint"

### When Sprint Goals Don't Work

Some sprints genuinely don't have a single theme — maintenance sprints, tech debt sprints, or mixed-priority sprints. In these cases:
- Use 2-3 mini-goals instead of forcing a single goal
- Or skip the sprint goal and focus on throughput/completion
- Don't force a goal that doesn't reflect reality

---

## 5. Backlog Refinement

### When and How Often

| Team Size | Refinement Cadence | Duration |
|-----------|-------------------|----------|
| 3-5 engineers | Once per sprint, mid-sprint | 30-60 min |
| 5-10 engineers | Once per sprint, mid-sprint | 60-90 min |
| 10+ engineers | Twice per sprint or continuous | 45-60 min per session |

**Timing:** Mid-sprint is ideal — far enough from the previous planning to have fresh perspective, early enough to prepare for the next sprint.

### What Happens in Refinement

1. **Review upcoming stories** — ensure stories for next 1-2 sprints are well-defined
2. **Clarify acceptance criteria** — fill in gaps, resolve ambiguities
3. **Split large stories** — anything bigger than 8 points (or 1 week) gets broken down
4. **Identify dependencies** — flag cross-team or external dependencies early
5. **Estimate** — if using story points, estimate refined stories (or at least t-shirt size them)
6. **Reprioritize** — move stories up or down based on new information

### Who Should Attend

**Always:** Product Owner, 2-3 senior engineers (or the full team if small)
**Sometimes:** Designer (for UI stories), DevOps (for infrastructure stories), QA (for complex testing needs)
**Never:** External stakeholders, managers who don't write code (unless specifically invited for context)

### The "Ready" Checklist

A story is "ready" for sprint planning when:
- [ ] It has a clear title and description
- [ ] Acceptance criteria are defined and specific
- [ ] Dependencies are identified and planned for
- [ ] The team has estimated it (or agreed it's small enough to not need estimation)
- [ ] UX designs are available (if needed)
- [ ] Technical approach is understood (if complex, a spike has been completed)
- [ ] It can be completed within one sprint

---

## 6. Definition of Done

### Team-Level Definition of Done

A standard DoD for engineering teams:

```
A story is "Done" when:
- [ ] Code is written and follows team coding standards
- [ ] Unit tests are written and passing
- [ ] Integration tests are written and passing (where applicable)
- [ ] Code has been peer reviewed and approved
- [ ] CI pipeline passes (build, lint, tests)
- [ ] Feature is deployed to staging/preview environment
- [ ] Acceptance criteria are verified (manually or via automated tests)
- [ ] Documentation is updated (if user-facing or API changes)
- [ ] No known critical bugs remain
- [ ] Product Owner has accepted the story
```

### Tailoring DoD by Context

| Context | Additional DoD Items |
|---------|---------------------|
| **Security-sensitive** | Security review completed, no new vulnerabilities introduced |
| **Performance-critical** | Performance benchmarks pass, no regression |
| **Regulated (healthcare, finance)** | Compliance review, audit trail, change documentation |
| **API changes** | API documentation updated, backward compatibility verified |
| **Mobile** | Tested on target devices, app store guidelines met |

### DoD Evolution

Start with a minimal DoD and expand as the team matures. Revisit every 3-6 months. If stories frequently come back as "not actually done," add the missing criteria to the DoD.

---

## 7. Sprint Metrics

### Essential Metrics

| Metric | What It Measures | Target |
|--------|-----------------|--------|
| **Sprint velocity** | Story points completed per sprint | Stable trend (not max) |
| **Sprint goal success rate** | % of sprints where the goal is met | 70-80% |
| **Cycle time** | Time from "in progress" to "done" | Stable or decreasing |
| **Throughput** | Stories completed per sprint | Stable or increasing |
| **WIP** | Items actively in progress | ≤ team size |
| **Carry-over rate** | % of committed stories not completed | < 15-20% |
| **Escaped defects** | Bugs found after sprint release | Decreasing trend |

### Burndown vs Burnup Charts

**Burndown** shows remaining work over time. Simple but hides scope changes.

**Burnup** shows completed work and total scope as separate lines. Better because:
- Scope additions are visible (the top line moves up)
- Progress is always positive (the bottom line moves up)
- The gap between lines shows remaining work
- Stakeholders can see both progress and scope changes

**Recommendation:** Use burnup charts. They tell a more honest story, especially when scope changes mid-sprint.

### Cumulative Flow Diagrams (CFDs)

CFDs show the count of items in each workflow state over time. They reveal:
- **Bottlenecks** — widening bands indicate work piling up in that state
- **WIP problems** — thick "In Progress" band means too much concurrent work
- **Flow efficiency** — ratio of active work time to total cycle time
- **Throughput stability** — consistent band width indicates stable flow

### When to Worry

| Metric Trend | What It Might Mean | Action |
|-------------|-------------------|--------|
| Velocity dropping | Team overcommitting, losing focus, or dealing with tech debt | Reduce sprint commitment, investigate root cause |
| Cycle time increasing | Stories too large, blockers, or context switching | Enforce WIP limits, split stories smaller |
| Carry-over increasing | Poor estimation, scope creep, or hidden dependencies | Improve refinement, reduce sprint scope |
| Escaped defects increasing | Insufficient testing, rushed Definition of Done | Strengthen DoD, add automated test requirements |

---

## 8. Planning Tools

### Tool Comparison (2026)

| Tool | Best For | Estimation | Sprint Board | Analytics | Price Model |
|------|----------|-----------|-------------|-----------|-------------|
| **Jira** | Enterprise, SAFe, complex workflows | Story points, time tracking | Yes (customizable) | Advanced (velocity, burndown, CFD) | Per user, tiered |
| **Linear** | Fast-moving startups, engineering-centric teams | Estimate field, cycles | Yes (clean, fast) | Good (cycle analytics, project insights) | Per user |
| **Shortcut** | Mid-size teams wanting balance of power and simplicity | Story points, epics | Yes | Good (velocity, cycle time) | Per user |
| **GitHub Projects** | Open source, GitHub-native workflows | Custom fields | Yes (table + board views) | Basic (must build custom) | Free (included with GitHub) |
| **ClickUp** | Teams wanting an all-in-one workspace | Story points, time, custom | Yes (many view types) | Good (dashboards) | Freemium, per user |
| **Notion** | Small teams, documentation-heavy workflows | Custom properties | Basic (database views) | Minimal (must build custom) | Per user |
| **Asana** | Cross-functional teams with PM focus | Custom fields | Yes (board + timeline) | Good (portfolios, workload) | Per user, tiered |

### Tool Selection Guide

```
Team size < 5 and already on GitHub → GitHub Projects
Team size < 15 and engineering-focused → Linear
Team size < 15 and cross-functional → Shortcut or Asana
Team size 15-50 with complex workflows → Jira or ClickUp
Team size 50+ or SAFe → Jira
Team already in Notion for everything → Notion (but consider outgrowing it)
```

---

## 9. AI-Assisted Planning

### Current AI Capabilities in Sprint Planning (2026)

| Capability | Tools | Maturity |
|-----------|-------|----------|
| **Auto-estimation** | Jira AI, LinearB, Jellyfish | Medium — useful as initial estimates, needs human review |
| **Story splitting suggestions** | GitHub Copilot for Issues, Jira AI | Early — generates reasonable splits but misses domain context |
| **Backlog prioritization** | LinearB, Jellyfish, Allstacks | Medium — uses delivery data to suggest priority order |
| **Sprint scope prediction** | ActionableAgile, Jira forecasting | Good — Monte Carlo based, reliable with sufficient data |
| **Risk identification** | AI-powered dependency scanning | Early — can flag known patterns but misses novel risks |
| **Status report generation** | Linear, Jira, AI assistants | Good — summarizes sprint progress from ticket data |

### How to Use AI in Planning

**Do:**
- Use AI estimates as a starting point for team discussion, not as the answer
- Let AI draft story descriptions and acceptance criteria for refinement
- Use AI-powered analytics for throughput forecasting
- Automate status report generation from ticket data

**Don't:**
- Skip team discussion because "the AI estimated it"
- Let AI set sprint goals without human judgment
- Trust AI dependency detection for critical-path decisions
- Replace retrospectives with AI-generated insights

---

## 10. Remote and Hybrid Sprint Planning

### Async Sprint Planning

For distributed teams across time zones:

1. **Pre-planning (async, 2-3 days before):**
   - Product Owner shares candidate stories in a shared document
   - Team members review and add questions asynchronously
   - Preliminary estimates via async voting tools (PlanITpoker, Pointing Poker, Linear's built-in estimation)

2. **Synchronous session (1-2 hours in overlapping time zone):**
   - Resolve open questions from async review
   - Final estimation for contested stories
   - Sprint goal agreement
   - Commitment as a team

3. **Post-planning (async, same day):**
   - Scrum Master publishes sprint plan to the team channel
   - Team members self-assign tasks or discuss pairing

### Remote Planning Tools

| Tool | Purpose |
|------|---------|
| **Miro / FigJam** | Visual collaboration, story mapping, affinity clustering |
| **PlanITpoker / Pointing Poker** | Remote Planning Poker sessions |
| **Loom / Bubbles** | Async video for story walkthroughs |
| **Slack / Teams threads** | Async Q&A on stories before planning |
| **Notion / Confluence** | Shared sprint planning documents |

---

## 11. Sprint Anti-Patterns

### Common Anti-Patterns and Fixes

| Anti-Pattern | Symptom | Fix |
|-------------|---------|-----|
| **Overcommitment** | Team commits to more than velocity supports, carries over every sprint | Use conservative velocity (low end of range), add buffer |
| **Fake sprints** | Sprints have no goal, just a pile of unrelated tickets | Set a sprint goal first, then select stories that support it |
| **Estimation theater** | Hours spent debating 3 vs 5 points, no value added | Switch to t-shirt sizing or no-estimates with throughput tracking |
| **Story point inflation** | Points awarded for complexity of conversations, not work | Re-calibrate reference stories, focus on relative sizing |
| **Sprint stuffing** | Manager adds stories mid-sprint "because it's urgent" | Enforce sprint boundary, use interrupt budget, say "next sprint" |
| **Dependency blindness** | Dependencies surface as mid-sprint blockers (36% of sprint rollover is caused by dependency delays) | Map dependencies in refinement, flag cross-team needs at planning |
| **No refinement** | Stories arrive at planning undefined, planning takes 4 hours | Require refinement 1 week before planning, enforce "ready" checklist |
| **Velocity as KPI** | Management uses velocity to compare teams or evaluate performance | Educate: velocity is a planning tool, not a performance metric |
| **Zombie stories** | Stories that have been "in progress" for multiple sprints | WIP limits, split stories, enforce "if it's not done in 2 days, flag it" |
| **Planning without the team** | PM/lead plans the sprint and assigns work to engineers | Involve the whole team — they do the work, they plan the work |

---

## 12. Sprint Length Selection

### Sprint Length Comparison

| Length | Pros | Cons | Best For |
|--------|------|------|----------|
| **1 week** | Fastest feedback, minimal planning overhead, easy to pivot | Very small stories only, high ceremony-to-work ratio, stressful pace | ~14% of teams. Mature teams, rapid experimentation, hotfix cadence |
| **2 weeks** | Most popular, good balance of planning and execution, enough time for meaningful work | Can feel rushed for complex stories, mid-sprint scope changes are disruptive | ~59% of teams (dominant). The default starting point |
| **3 weeks** | More time for complex work, fewer planning sessions per quarter | Less frequent feedback, harder to estimate, more scope creep risk | ~7% of teams. Complex integration work, research-heavy sprints |
| **4 weeks** | Maximum execution time, fewest ceremonies | Too long for fast feedback, sprint goals become vague, estimation is harder | ~6% of teams. Regulated environments, hardware-adjacent teams |

### Choosing Sprint Length

**Start with 2 weeks.** It's the most common for a reason — it balances planning overhead with execution time and feedback frequency. Only change if you have a specific reason:

- Switch to **1 week** if: you ship continuously, stories are consistently small, you want maximum agility
- Switch to **3 weeks** if: 2-week sprints feel rushed, complex work needs more runway, team requests it
- Switch to **4 weeks** if: external constraints require it (release trains, compliance cycles)

**Never change sprint length without trying at least 3-4 sprints at the current length.** Teams need time to calibrate.

---

## 13. Running the Sprint Planning Ceremony

### Preparation Checklist

Before the meeting:
- [ ] Backlog is refined — top stories have acceptance criteria and estimates
- [ ] Team capacity is calculated (accounting for PTO, holidays, support rotation)
- [ ] Previous sprint velocity is available
- [ ] Product Owner has a ranked list of priorities
- [ ] Dependencies from other teams are identified

### Meeting Agenda (2-Week Sprint)

**Total time: 1-2 hours** (shorter for experienced teams)

| Phase | Time | Activity |
|-------|------|----------|
| **1. Review** | 10 min | Quick review of last sprint velocity, carry-overs, and lessons |
| **2. Sprint Goal** | 15 min | Product Owner proposes a goal, team discusses and agrees |
| **3. Story Selection** | 30-45 min | Team pulls stories from the backlog that support the goal and fit capacity |
| **4. Task Breakdown** | 15-30 min | For each story, identify tasks and potential blockers |
| **5. Commitment** | 5 min | Team confirms the sprint plan and sprint goal |

### Facilitation Tips

- **Timebox aggressively** — if a story generates more than 5 minutes of discussion, it's not refined enough. Park it.
- **Protect the sprint goal** — resist the urge to add "one more thing" after the goal is set
- **Include the whole team** — not just senior engineers. Everyone who does the work should be in the room.
- **End with clarity** — every team member should be able to state the sprint goal and know what they're working on first
- **Document immediately** — sprint goal, committed stories, and known risks go into the planning tool within 30 minutes of the meeting ending
