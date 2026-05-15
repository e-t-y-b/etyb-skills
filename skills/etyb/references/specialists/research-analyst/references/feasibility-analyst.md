# Feasibility Analysis & Risk Assessment — Deep Reference

**Always use `WebSearch` to verify current tool capabilities, framework maturity, cloud service limits, and industry benchmarks before assessing feasibility. What was impossible last year may be straightforward today, and what seemed easy may have hidden gotchas.**

## Table of Contents
1. [Technical Feasibility Assessment Framework](#1-technical-feasibility-assessment-framework)
2. [Risk Identification & Assessment](#2-risk-identification--assessment)
3. [Complexity Estimation](#3-complexity-estimation)
4. [Spike & Prototype Design](#4-spike--prototype-design)
5. [Build vs. Buy Decision Framework](#5-build-vs-buy-decision-framework)
6. [Constraint Analysis](#6-constraint-analysis)
7. [Scalability & Performance Feasibility](#7-scalability--performance-feasibility)
8. [Integration Feasibility](#8-integration-feasibility)
9. [Team Capability Gap Analysis](#9-team-capability-gap-analysis)
10. [Go/No-Go Decision Framework](#10-gono-go-decision-framework)
11. [Technical Debt Impact Assessment](#11-technical-debt-impact-assessment)
12. [Feasibility Report Template](#12-feasibility-report-template)

---

## 1. Technical Feasibility Assessment Framework

### The Five Dimensions of Technical Feasibility

Every technical feasibility assessment should evaluate across five dimensions:

| Dimension | Key Questions | How to Assess |
|-----------|--------------|---------------|
| **Functional Feasibility** | Can we build this to meet the functional requirements? | Requirements analysis, similar system references, PoC |
| **Technical Feasibility** | Do the required technologies exist and work at our scale? | Technology evaluation, benchmarks, PoC |
| **Resource Feasibility** | Do we have the people, skills, time, and budget? | Team assessment, effort estimation, budget analysis |
| **Operational Feasibility** | Can we deploy, operate, and maintain this? | Ops complexity assessment, team ops skills |
| **Schedule Feasibility** | Can we deliver this within the required timeline? | Estimation, dependency analysis, critical path |

### Feasibility Scoring

For each dimension, score on a 5-point scale:

| Score | Meaning | Implication |
|-------|---------|-------------|
| 5 — Highly Feasible | Straightforward, proven approach, team has experience | Proceed with confidence |
| 4 — Feasible | Achievable with manageable challenges | Proceed with standard risk management |
| 3 — Conditionally Feasible | Achievable but requires specific conditions to be met | Proceed only if conditions can be guaranteed |
| 2 — Marginally Feasible | Significant challenges, uncertain outcome | Consider alternatives or scope reduction |
| 1 — Not Feasible | Fundamental blockers, unproven technology, impossible constraints | Do not proceed without major scope changes |

**Overall Feasibility** = Minimum score across all dimensions (a chain is only as strong as its weakest link)

### Feasibility Assessment Process

```
1. Define what "feasible" means (success criteria, constraints, timeline)
2. Identify the highest-risk unknowns
3. Assess each dimension (functional, technical, resource, operational, schedule)
4. For any dimension scoring ≤ 3, conduct deeper analysis (spike, PoC, expert consultation)
5. Document findings with evidence
6. Present go/no-go recommendation with conditions
```

---

## 2. Risk Identification & Assessment

### Risk Categories for Software Projects

| Category | Example Risks | Likelihood Assessment |
|----------|-------------|----------------------|
| **Technical Risks** | Unproven technology, performance unknowns, integration complexity, data migration | PoC results, benchmark data, similar project experience |
| **Resource Risks** | Key person dependency, skill gaps, hiring delays, budget constraints | Team assessment, market analysis, budget projections |
| **Schedule Risks** | Dependency delays, scope creep, underestimation, regulatory approval timelines | Historical data, dependency mapping, buffer analysis |
| **External Risks** | Third-party API changes, vendor stability, regulatory changes, market shifts | Vendor assessment, regulatory monitoring, contract terms |
| **Organizational Risks** | Stakeholder alignment, priority changes, organizational restructuring | Stakeholder mapping, executive sponsorship assessment |
| **Security Risks** | Data breach potential, compliance gaps, attack surface expansion | Threat modeling, compliance gap analysis |

### Risk Matrix

Plot risks on a likelihood × impact matrix:

```
Impact →    Negligible   Minor      Moderate    Major      Critical
            (1)          (2)        (3)         (4)        (5)
Likelihood
─────────────────────────────────────────────────────────────────
Almost      Low          Medium     High        Critical   Critical
Certain (5)

Likely (4)  Low          Medium     High        High       Critical

Possible (3) Low         Medium     Medium      High       High

Unlikely (2) Low         Low        Medium      Medium     High

Rare (1)    Low          Low        Low         Medium     Medium
```

### Risk Response Strategies

| Strategy | When to Use | Example |
|----------|------------|---------|
| **Avoid** | Risk is too high and can be eliminated by changing approach | Choose a different technology that doesn't have the risk |
| **Mitigate** | Risk can be reduced to acceptable levels | Build a PoC to validate the risky technology before committing |
| **Transfer** | Risk can be shifted to a third party | Use a managed service instead of self-hosting; buy insurance |
| **Accept** | Risk is low enough or unavoidable, and the team is prepared | Document the risk, monitor it, have a contingency plan |
| **Escalate** | Risk is beyond the team's control or authority | Escalate to leadership for decision on regulatory risk |

### Failure Mode and Effects Analysis (FMEA)

FMEA systematically analyzes potential failure modes:

| Component | Failure Mode | Effect | Severity (1-10) | Likelihood (1-10) | Detection (1-10) | RPN | Mitigation |
|-----------|-------------|--------|-----------------|-------------------|-------------------|-----|------------|
| Database | Connection pool exhaustion | Service unavailable | 9 | 4 | 3 | 108 | Connection pooler (PgBouncer), monitoring |
| Auth Service | Token validation failure | Users locked out | 8 | 2 | 2 | 32 | Fallback auth, token caching |
| Payment API | Third-party timeout | Failed transactions | 9 | 3 | 4 | 108 | Retry with idempotency, queue + async |
| Search Index | Index corruption | No search results | 6 | 2 | 5 | 60 | Automated rebuild, dual-write strategy |

**Risk Priority Number (RPN)** = Severity × Likelihood × Detection difficulty

- RPN > 100: Requires immediate mitigation
- RPN 50-100: Should be mitigated before production
- RPN < 50: Monitor, mitigate if convenient

### Pre-Mortem Analysis

A pre-mortem inverts the question: "Imagine this project has failed. Why did it fail?"

**Process:**
1. Gather the team and announce: "It's 6 months from now. This project has failed spectacularly. What happened?"
2. Each person independently writes down 3-5 failure scenarios
3. Collect and cluster the scenarios
4. For each cluster, discuss:
   - How realistic is this failure mode?
   - What would we see as early warning signs?
   - What can we do now to prevent it?
5. Add the highest-risk items to the project risk register

This technique surfaces risks that people are reluctant to raise in a positive-framing context.

---

## 3. Complexity Estimation

### Estimation Approaches Comparison

| Approach | Precision | Speed | Best For | Limitations |
|----------|----------|-------|----------|-------------|
| **T-Shirt Sizing** (XS, S, M, L, XL) | Low | Very Fast | Initial roadmap planning, backlog grooming | Not precise enough for sprint planning |
| **Story Points** (Fibonacci: 1, 2, 3, 5, 8, 13) | Medium | Fast | Sprint planning, relative sizing | Teams calibrate differently, stakeholders want days |
| **Ideal Days** | Medium | Medium | Teams that struggle with abstract points | Can be confused with calendar days |
| **Time-Based Estimates** (hours/days) | Medium-High | Slow | Fixed-bid projects, client commitments | Humans are bad at absolute time estimation |
| **Three-Point Estimation** (Optimistic, Most Likely, Pessimistic) | High | Slow | High-stakes estimates, uncertainty quantification | Time-consuming, requires experienced estimators |
| **PERT** | High | Slow | Critical path analysis, project planning | (O + 4M + P) / 6 — assumes beta distribution |
| **Monte Carlo Simulation** | Very High | Very Slow | Portfolio planning, schedule risk analysis | Requires historical data, tooling (Focusplan, Nave) |
| **COCOMO II/III** | High | Slow | Large project effort estimation, contract estimation | Effort = a × (KSLOC)^b × effort multipliers. COCOMO III (emerging) adds Agile Process multiplier (0.91-1.11) and DevOps/CI-CD support |

### Story Points Calibration Guide

When teams are new to story points, calibrate with concrete examples:

| Points | Complexity Signal | Example Tasks |
|--------|------------------|---------------|
| **1** | Trivial, well-understood, no unknowns | Fix a typo, update a config value, add a log statement |
| **2** | Simple, straightforward, minimal risk | Add a new field to an API response, write a unit test |
| **3** | Moderate, some thinking required | Add a new API endpoint with validation, implement a form |
| **5** | Complex, multiple components involved | Build a feature with frontend + backend + database changes |
| **8** | Very complex, significant unknowns | Integrate with a new third-party API, implement auth flow |
| **13** | Highly complex, should probably be broken down | Major refactoring across multiple services |
| **21+** | Too complex to estimate — break it down | Anything this large has too many unknowns |

### COCOMO II Model (For Large Projects)

The Constructive Cost Model is useful for large-scale effort estimation:

**Basic COCOMO II:**
```
Effort (person-months) = a × (KSLOC)^b × ΠEM

Where:
- KSLOC = thousands of source lines of code (estimated)
- a, b = calibration constants (typically a=2.94, b=1.0-1.2)
- EM = effort multipliers (product complexity, team experience, tool support, etc.)
```

**Effort Multipliers that significantly impact estimates:**

| Factor | Low (0.75-0.90) | Nominal (1.0) | High (1.15-1.40) | Very High (1.30-1.75) |
|--------|-----------------|---------------|-------------------|-----------------------|
| Product complexity | Simple CRUD | Standard business logic | Real-time, distributed | Safety-critical, AI/ML |
| Team experience | Very experienced | Average | New technology | New domain + new tech |
| Tool maturity | Mature ecosystem | Standard tooling | Limited tools | No existing tooling |
| Requirements volatility | Stable | Some changes | Frequent changes | Constantly changing |
| Schedule pressure | Relaxed | Normal | Compressed | Highly compressed |

### Estimation Anti-Patterns

| Anti-Pattern | Why It's Harmful | Better Approach |
|-------------|-----------------|-----------------|
| **Anchoring** | First estimate heard biases all subsequent estimates | Estimate independently, then reveal and discuss |
| **Planning Fallacy** | People consistently underestimate time required | Use historical data, add risk buffer (20-30%) |
| **Padding** | Each person adds buffer, compounds to absurd totals | Estimate honestly, add explicit risk buffer once |
| **Precision Theatre** | "This will take 47.5 hours" implies false certainty | Use ranges: "3-5 days, depending on API integration complexity" |
| **Scope Optimism** | Assuming the simplest interpretation of requirements | Explicitly list assumptions and edge cases before estimating |
| **Ignoring Integration** | Estimating components in isolation | Include integration, testing, deployment, and documentation time |

---

## 4. Spike & Prototype Design

### Spike vs. Prototype vs. PoC

| Type | Duration | Goal | Output | Throwaway? |
|------|----------|------|--------|------------|
| **Spike** | 1-2 days | Answer a specific technical question | Knowledge (documented findings) | Yes — the code is always throwaway |
| **Prototype** | 3-5 days | Validate a user experience or workflow | Interactive demo | Usually yes — but UI patterns may survive |
| **Proof of Concept (PoC)** | 1-2 weeks | Prove a technical approach works end-to-end | Working system (limited scope) | Sometimes evolves into production code |

### Designing an Effective Spike

**Spike Template:**

```markdown
## Spike: [Specific Question to Answer]

### Background
[Why are we investigating this? What decision does it inform?]

### Question
[The specific, answerable question this spike addresses]
Example: "Can we achieve <100ms p99 latency for full-text search
across 10M documents using Meilisearch on a single server?"

### Approach
[How you plan to investigate — not a detailed plan, just the approach]
1. Set up Meilisearch with 10M synthetic documents
2. Run benchmark with realistic query patterns
3. Measure p99 latency under various concurrency levels

### Time Box
[Maximum time before stopping, regardless of progress]
- Hard limit: 2 days
- Checkpoint at end of day 1 (go/no-go on continuing)

### Success Criteria
[What constitutes a clear answer — avoid "it depends" outcomes]
- PASS: p99 < 100ms at 100 concurrent queries
- FAIL: p99 > 200ms at 100 concurrent queries
- INCONCLUSIVE: Between 100-200ms (need different approach or hardware)

### Out of Scope
[Explicitly what you're NOT investigating]
- Production deployment patterns
- Data ingestion pipeline
- Multi-server clustering

### Results
[Filled in after the spike]
- Outcome: PASS / FAIL / INCONCLUSIVE
- Key findings: [bullet points]
- Recommendation: [proceed / don't proceed / investigate further]
- Evidence: [links to benchmarks, code, screenshots]
```

### When to Spike

| Signal | Spike? | Duration |
|--------|--------|----------|
| "I'm not sure if Technology X can handle Requirement Y" | Yes | 1 day |
| "This integration seems complex, I don't know how their API works" | Yes | 1-2 days |
| "We've never done this type of thing before" | Yes | 2 days |
| "The team disagrees on the right approach" | Maybe — compare approaches | 1 day per approach |
| "The requirements are unclear" | No — talk to stakeholders first | — |
| "This is a well-understood problem with standard solutions" | No — just build it | — |

---

## 5. Build vs. Buy Decision Framework

### The Build vs. Buy Matrix

| Factor | Favors Build | Favors Buy |
|--------|-------------|------------|
| **Core differentiator?** | Yes — this IS our product | No — commodity functionality |
| **Team expertise** | Strong in this domain | No expertise, would need to hire/learn |
| **Customization needs** | Highly custom, unique workflow | Standard use case, minor configuration |
| **Timeline** | Flexible timeline, can invest | Urgent, need it working yesterday |
| **Budget** | Development budget available | Operational budget (OpEx) preferred |
| **Scale requirements** | Unique scale characteristics | Standard scale, vendor handles it |
| **Data sensitivity** | Highly sensitive, must own the data | Standard data, vendor compliance is sufficient |
| **Long-term maintenance** | Team can maintain it | Don't want to maintain it |
| **Vendor landscape** | No good vendors exist | Multiple mature vendors available |
| **Regulatory** | Requirements prevent vendor use | Vendor has relevant certifications |

### TCO Comparison Template

```
Feature: [e.g., User Authentication]

BUILD Option:
┌────────────────────────────┬──────────┬──────────┬──────────┐
│ Cost Component              │ Year 1   │ Year 2   │ Year 3   │
├────────────────────────────┼──────────┼──────────┼──────────┤
│ Development (initial)       │ $XXX     │ —        │ —        │
│ Development (ongoing 20%)   │ —        │ $XXX     │ $XXX     │
│ Infrastructure              │ $XXX     │ $XXX     │ $XXX     │
│ Security audits             │ $XXX     │ $XXX     │ $XXX     │
│ On-call / incident response │ $XXX     │ $XXX     │ $XXX     │
│ ────────────────────────────┼──────────┼──────────┼──────────│
│ Total                       │ $XXX     │ $XXX     │ $XXX     │
│ Cumulative                  │ $XXX     │ $XXX     │ $XXX     │
└────────────────────────────┴──────────┴──────────┴──────────┘

BUY Option (e.g., Auth0/Clerk/WorkOS):
┌────────────────────────────┬──────────┬──────────┬──────────┐
│ Cost Component              │ Year 1   │ Year 2   │ Year 3   │
├────────────────────────────┼──────────┼──────────┼──────────┤
│ Subscription                │ $XXX     │ $XXX     │ $XXX     │
│ Integration development     │ $XXX     │ —        │ —        │
│ Customization               │ $XXX     │ $XXX     │ $XXX     │
│ Vendor management           │ $XXX     │ $XXX     │ $XXX     │
│ ────────────────────────────┼──────────┼──────────┼──────────│
│ Total                       │ $XXX     │ $XXX     │ $XXX     │
│ Cumulative                  │ $XXX     │ $XXX     │ $XXX     │
└────────────────────────────┴──────────┴──────────┴──────────┘
```

### Common Build vs. Buy Decisions (2025-2026)

| Capability | Usually Build | Usually Buy | Depends |
|-----------|--------------|-------------|---------|
| Core business logic | Yes | — | — |
| Authentication | — | Auth0, Clerk, WorkOS, Supabase Auth | Build if extreme customization needed |
| Payments | — | Stripe, Adyen | Build ledger/invoicing on top |
| Email sending | — | SendGrid, Resend, Postmark | — |
| Search | — | Algolia, Typesense Cloud, Elastic Cloud | Build if core differentiator |
| Monitoring/Observability | — | Datadog, Grafana Cloud, New Relic | — |
| Feature flags | — | LaunchDarkly, Unleash, Statsig | OpenFeature + simple DB if basic needs |
| CMS | — | Contentful, Sanity, Strapi | — |
| Real-time/WebSocket | Depends | Ably, Pusher, Liveblocks | Build if core to product |
| AI/ML inference | — | OpenAI API, Anthropic API, Bedrock | Fine-tune/self-host if data sensitivity or cost |
| File storage | — | S3, GCS, Cloudflare R2 | — |
| Queues/messaging | Depends | SQS, Cloud Tasks | Kafka/Redis if complex routing |

### The "Build Then Buy" and "Buy Then Build" Patterns

**Buy Then Build**: Start with a vendor, then build your own when:
- You understand the requirements from using the vendor
- The vendor becomes a cost bottleneck at scale
- You need customization the vendor can't provide
- Example: Use Auth0 at launch, build custom auth at 100K users if vendor costs are prohibitive

**Build Then Buy**: Start building, then switch to vendor when:
- Your custom solution becomes a maintenance burden
- The vendor landscape matures to meet your needs
- Your team should focus on core product, not infrastructure
- Example: Build simple email templates initially, switch to a marketing automation platform as needs grow

---

## 6. Constraint Analysis

### Constraint Categories

| Category | Constraints | Assessment Method |
|----------|------------|-------------------|
| **Technical** | Language/framework mandates, infrastructure limits, legacy system compatibility, browser support requirements | Technology audit, compatibility testing |
| **Resource** | Team size, skill mix, budget, hardware | Team assessment, budget review |
| **Timeline** | Hard deadlines (regulatory, contractual, market), soft deadlines (desired launch) | Dependency mapping, critical path analysis |
| **Regulatory** | GDPR, HIPAA, PCI-DSS, SOX, CCPA, accessibility (ADA/WCAG), data residency | Compliance checklist, legal review |
| **Organizational** | Approved technology list, architecture standards, deployment procedures, change management | Enterprise architecture review |
| **External** | Third-party API limits, vendor SLAs, partner dependencies | Vendor documentation, contract review |

### Constraint vs. Preference

Not all "requirements" are actual constraints. Distinguish between:

| Type | Definition | Example | Flexibility |
|------|-----------|---------|-------------|
| **Hard Constraint** | Violating this is not possible or not acceptable | HIPAA compliance for health data, contractual deadline | Zero — must be met |
| **Soft Constraint** | Violating this has a cost but is negotiable | "We'd prefer to use React" — but Vue would also work | Can be traded off with stakeholder agreement |
| **Preference** | Desired but not required | "It would be nice to have dark mode" | Can be deferred or dropped |
| **Assumption** | Believed to be true but not verified | "Our users all have modern browsers" | Must be validated |

### Constraint Interaction Analysis

Constraints often interact in non-obvious ways:

```
Example: E-commerce Platform

Constraint 1: Must launch in 3 months (timeline)
Constraint 2: Must support 10K concurrent users (scalability)
Constraint 3: Team of 4 engineers (resource)
Constraint 4: PCI-DSS compliance for payments (regulatory)

Interactions:
- Timeline + Team Size → Can't build everything custom, need to buy/integrate
- PCI-DSS + Timeline → Use Stripe (pre-certified) instead of building payment processing
- Scalability + Team Size → Use managed services (serverless, managed DB) to reduce ops burden
- All Together → Scope must be ruthlessly prioritized to core MVP
```

---

## 7. Scalability & Performance Feasibility

### Scalability Assessment Framework

| Dimension | Questions | How to Assess |
|-----------|----------|---------------|
| **User Scale** | How many concurrent users? Growth rate? Geographic distribution? | Current analytics, market sizing, growth projections |
| **Data Scale** | How much data? Growth rate? Access patterns (read/write ratio)? | Current data volume, growth model, access pattern analysis |
| **Transaction Scale** | Transactions per second? Peak vs. average? Burst patterns? | Current traffic, seasonal patterns, event-driven spikes |
| **Computational Scale** | CPU/memory-intensive operations? Batch processing? Real-time requirements? | Workload profiling, benchmark results |
| **Integration Scale** | Number of integrations? API call volume? Webhook fanout? | Integration inventory, API call projections |

### Back-of-Envelope Capacity Estimation

Before building anything, do rough math:

```
Example: Social Media Feed Service

Users: 10M registered, 1M DAU, 100K concurrent at peak
Posts: Average user posts 2x/day → 2M posts/day → 23 posts/sec average, ~100/sec peak
Feed reads: Average user checks feed 10x/day → 10M reads/day → 115 reads/sec, ~500/sec peak
Feed size: 50 posts per feed page

Storage:
- 2M posts/day × 365 days × 1KB avg = ~730 GB/year (text only)
- With media metadata/links: ~3-5 TB/year
- With images (stored in object storage): ~50-100 TB/year

Compute:
- Feed generation: 500 reads/sec × 50 posts = 25K DB reads/sec at peak
- Can PostgreSQL handle this? Yes, with read replicas and caching
- Can a single Redis cache handle this? Yes, easily (100K+ ops/sec)

Conclusion: PostgreSQL + Redis can handle Year 1 easily.
Re-evaluate when approaching 10M DAU or 1000 writes/sec.
```

### Performance Feasibility Benchmarks

Know these rough numbers for capacity planning:

| System | Throughput (per node) | Latency (typical) |
|--------|----------------------|-------------------|
| **PostgreSQL** (tuned) | 10K-50K queries/sec | 1-10ms (indexed queries) |
| **MySQL** (tuned) | 10K-50K queries/sec | 1-10ms (indexed queries) |
| **Redis** | 100K-200K ops/sec | < 1ms |
| **Kafka** | 100K-2M messages/sec per broker | 2-10ms (producer ack) |
| **Elasticsearch** | 5K-20K searches/sec per node | 10-100ms |
| **Node.js** (HTTP API) | 10K-50K requests/sec | 1-50ms |
| **Go** (HTTP API) | 50K-200K requests/sec | < 1ms-10ms |
| **Nginx** (reverse proxy) | 50K-100K requests/sec | < 1ms overhead |
| **CDN** (Cloudflare/CloudFront) | Millions of requests/sec | 10-50ms (edge) |

**Caveat**: These are rough guidelines. Actual performance depends heavily on hardware, configuration, query complexity, and workload characteristics. Always benchmark with realistic data.

### Scaling Strategy Decision Tree

```
Is the bottleneck...

CPU-bound?
├── Yes → Horizontal scaling (more instances) or vertical scaling (bigger instance)
│         Consider: Can the workload be parallelized? Is it a hot path?
└── No ↓

Memory-bound?
├── Yes → Vertical scaling (more RAM), or distributed caching (Redis Cluster)
│         Consider: Is it a cache? A large dataset? Memory leak?
└── No ↓

I/O-bound (disk)?
├── Yes → Faster storage (SSD/NVMe), caching layer, read replicas
│         Consider: Is it database? File system? Log writing?
└── No ↓

I/O-bound (network)?
├── Yes → CDN, edge computing, connection pooling, protocol optimization
│         Consider: Is it external API? Database connections? Client-server?
└── No ↓

Concurrency-limited?
├── Yes → Connection pooling, async processing, queue-based architecture
│         Consider: Database connection limits? Thread pool exhaustion?
└── No → Profile deeper — the bottleneck may not be where you think it is
```

---

## 8. Integration Feasibility

### Integration Complexity Assessment

| Factor | Low Complexity | Medium Complexity | High Complexity |
|--------|---------------|-------------------|-----------------|
| **API quality** | RESTful, well-documented, stable | REST but poorly documented, some quirks | SOAP/XML, undocumented, or no API |
| **Auth model** | API key or OAuth 2.0 | Custom auth, client certificates | Proprietary auth, VPN required |
| **Data format** | JSON, standard schemas | XML, custom schemas, multiple formats | Binary, proprietary format, inconsistent |
| **Error handling** | Clear error codes, retry guidance | Inconsistent errors, limited guidance | Opaque errors, no retry guidance |
| **Rate limiting** | Generous, well-documented | Restrictive but documented | Undocumented, unpredictable |
| **Testing** | Sandbox/test environment available | Test environment with limitations | No test environment |
| **Versioning** | Semver, long deprecation | Version changes with short notice | Breaking changes without versioning |
| **Support** | Responsive, SLA-backed | Community support only | No support channel |

### Integration Feasibility Scorecard

Rate each integration point:

```markdown
## Integration Assessment: [System Name]

| Criterion | Score (1-5) | Notes |
|-----------|-------------|-------|
| API documentation quality | | |
| Authentication complexity | | |
| Data format compatibility | | |
| Error handling maturity | | |
| Rate limit adequacy | | |
| Testing environment | | |
| Vendor support quality | | |
| Version stability | | |
| **Average Score** | | |

Overall Assessment: [Straightforward / Manageable / Complex / High Risk]
Estimated Integration Effort: [days/weeks]
Key Risks: [list]
```

### Integration Patterns

| Pattern | When to Use | Complexity |
|---------|------------|------------|
| **Direct API call** | Simple, synchronous integration | Low |
| **Webhook + Queue** | Event-driven, async notifications | Medium |
| **ETL/ELT pipeline** | Batch data synchronization | Medium-High |
| **CDC (Change Data Capture)** | Real-time data replication | High |
| **API Gateway** | Multiple integrations, rate limiting, transformation | Medium |
| **Event Bus (Kafka/SNS)** | Fan-out to multiple consumers, decoupling | High |
| **File Transfer (SFTP/S3)** | Legacy systems, batch processing | Low-Medium |

---

## 9. Team Capability Gap Analysis

### Skills Assessment Framework

| Skill Area | Required Level | Current Team Level | Gap | Mitigation |
|-----------|---------------|-------------------|-----|------------|
| React/TypeScript | Expert | Expert | None | — |
| PostgreSQL | Advanced | Intermediate | Medium | Training + DBA consultation |
| Kubernetes | Intermediate | Beginner | Large | Managed K8s + contractor |
| GraphQL | Intermediate | None | Large | Training or use REST instead |
| ML/AI Integration | Basic | None | Medium | Use hosted API (Anthropic, OpenAI) |

### Gap Mitigation Strategies

| Strategy | Timeline | Cost | Risk |
|----------|----------|------|------|
| **Training** | 2-8 weeks | Low-Medium | Medium (skill may not transfer well) |
| **Hiring** | 2-6 months | High | High (hiring is slow and uncertain) |
| **Contractor/Consultant** | 1-2 weeks | Medium-High | Low-Medium (knowledge transfer risk) |
| **Technology Substitution** | Immediate | Low | Low (use what team knows) |
| **Managed Service** | 1-2 weeks | Medium (ongoing) | Low (vendor handles complexity) |
| **Pair Programming** | Ongoing | Low (time cost) | Low (knowledge sharing) |
| **AI-Assisted Development** | Immediate | Low | Medium (quality verification needed) |

### Team Readiness Assessment

| Question | Green | Yellow | Red |
|----------|-------|--------|-----|
| Has the team built something similar before? | Yes, multiple times | Once, in a different context | Never |
| Does the team have the required technology skills? | All key skills covered | Most skills, gaps in 1-2 areas | Major skill gaps |
| Is the team appropriately sized for the project scope? | Yes, with buffer | Tight but manageable | Understaffed |
| Is domain expertise available? | On the team | Available as consultant | Not available |
| Is the team stable (no expected departures)? | Stable | Some risk | Key person leaving |

---

## 10. Go/No-Go Decision Framework

### Go/No-Go Criteria Matrix

| Criterion | Go (Green) | Conditional Go (Yellow) | No-Go (Red) |
|-----------|-----------|------------------------|-------------|
| **Technical Feasibility** | All dimensions score ≥ 4 | Some dimensions score 3, mitigations identified | Any dimension scores ≤ 2 |
| **Team Capability** | Skills available or easily acquired | Gaps exist but mitigatable within timeline | Critical skill gaps with no mitigation |
| **Timeline** | Achievable with 20% buffer | Tight but achievable with scope prioritization | Not achievable without scope reduction |
| **Budget** | Within budget with contingency | At budget, no contingency | Over budget |
| **Risk Profile** | No critical risks, all risks mitigated | 1-2 high risks with mitigation plans | Multiple critical risks, or unmitigable risks |
| **Dependencies** | All dependencies available or alternatives exist | Some dependencies uncertain, fallbacks planned | Critical dependencies unavailable |
| **Stakeholder Alignment** | All stakeholders aligned | Most aligned, minor disagreements | Key stakeholders not aligned |

### Decision Outcomes

| Outcome | When | Action |
|---------|------|--------|
| **Go** | All criteria Green, or Green with minor Yellow | Proceed to implementation with full funding |
| **Conditional Go** | Mostly Green/Yellow, conditions identifiable | Proceed with conditions documented and checkpoints set |
| **Recycle** | Promising but needs rework | Send back to previous phase with specific feedback for improvement |
| **Hold** | External conditions need to change | Pause, set review date, track conditions that would change the decision |
| **No-Go (Rescope)** | Some Red, but addressable with scope change | Reduce scope, change approach, re-evaluate |
| **No-Go (Kill)** | Multiple Red, fundamental blockers | Stop the project, communicate decision, reallocate resources |

### Automatic No-Go Red Flags

These conditions should trigger automatic No-Go unless explicitly overridden by executive sponsorship:

- No identified technical approach after a time-boxed spike
- Required skills unavailable and unhireable within timeline
- Regulatory blocker with no clear resolution path
- TCO exceeds 2x initial budget estimate
- Core dependency has no viable alternative
- Key stakeholder alignment cannot be achieved

### Stage Gate Reviews

For large projects, use staged go/no-go decisions:

| Gate | When | Key Questions |
|------|------|---------------|
| **Gate 0: Concept** | Before any work | Is the problem worth solving? Is there a market/need? |
| **Gate 1: Feasibility** | After spike/research | Is it technically feasible? Can we staff it? |
| **Gate 2: Design** | After architecture design | Is the design sound? Are risks manageable? |
| **Gate 3: Build** | After MVP/PoC | Does it work? Does it meet requirements? |
| **Gate 4: Launch** | Before production release | Is it ready for production? Are ops prepared? |

---

## 11. Technical Debt Impact Assessment

### Measuring Technical Debt: SQALE Model

The SQALE (Software Quality Assessment based on Lifecycle Expectations) model provides quantifiable debt measurement:

- **SQALE Index** = Total remediation time across all issues (in person-days)
- **SQALE Ratio** = SQALE Index / Estimated effort to rebuild from scratch
- Rating: A (<5%), B (5-10%), C (10-20%), D (20-50%), E (>50%)
- **Technical Debt Ratio (TDR)** = Cost of fixing / Cost of building — target: < 5%
- **Interest Rate** = Percentage of sprint capacity consumed by debt-related work

Tools: SonarQube (SQALE built-in), Code Climate, CAST (architecture-level analysis for enterprise)

### Technical Debt Categories

| Category | Description | Impact on New Features |
|----------|-------------|----------------------|
| **Code Debt** | Complex code, lack of abstraction, duplication | Slower development, more bugs in changes |
| **Architecture Debt** | Monolith that should be decomposed, wrong patterns | Hard to scale, deploy, or modify independently |
| **Test Debt** | Missing tests, flaky tests, poor coverage | Lower confidence, slower changes, more bugs |
| **Infrastructure Debt** | Manual deployments, no IaC, outdated servers | Slow deployments, environment inconsistency |
| **Documentation Debt** | Missing or outdated docs, tribal knowledge | Slow onboarding, knowledge silos |
| **Dependency Debt** | Outdated dependencies, vulnerable packages | Security risks, compatibility issues |

### Debt Impact Assessment

For each feature or project, assess how existing technical debt affects feasibility:

| Debt Area | Impact on This Project | Severity | Remediation Cost | Recommendation |
|-----------|----------------------|----------|------------------|----------------|
| No unit tests in payment module | Can't safely modify payment logic | High | 2 weeks to add tests | Add tests before building on this module |
| Monolithic deployment | New feature deployment blocks all other deployments | Medium | 3 months to decompose | Accept for now, plan decomposition separately |
| Outdated React version (v17) | Can't use new React features needed for this feature | High | 1 week to upgrade | Upgrade React first |

### Technical Debt Quadrant (Martin Fowler)

| | Deliberate | Inadvertent |
|---|-----------|-------------|
| **Reckless** | "We don't have time for tests" | "What's a design pattern?" |
| **Prudent** | "We'll ship now and refactor later" | "Now we know how we should have built it" |

- **Reckless + Deliberate**: Consciously cutting corners — document the debt, plan to repay
- **Reckless + Inadvertent**: Skills gap — invest in training and code review
- **Prudent + Deliberate**: Strategic shortcut — acceptable if tracked and scheduled for repayment
- **Prudent + Inadvertent**: Learning — inevitable, refactor as understanding improves

---

## 12. Feasibility Report Template

```markdown
# Technical Feasibility Assessment: [Project/Feature Name]

## Executive Summary
[One paragraph: Is this feasible? Under what conditions? Key risks?]

## Project Overview
- **Business Objective**: [What business problem does this solve?]
- **Proposed Solution**: [High-level technical approach]
- **Timeline**: [Desired delivery date]
- **Team**: [Available team members and skills]
- **Budget**: [Available budget]

## Feasibility Assessment

### Functional Feasibility: [Score 1-5]
[Can we build the required functionality?]
- [Finding 1 with evidence]
- [Finding 2 with evidence]

### Technical Feasibility: [Score 1-5]
[Do the technologies work? At our scale?]
- [Finding 1 — e.g., "PoC demonstrated 50ms p99 latency at 10K RPM"]
- [Finding 2 — e.g., "Third-party API supports required data format"]

### Resource Feasibility: [Score 1-5]
[Do we have the people, skills, and budget?]
- [Finding 1 — e.g., "Team has React expertise but needs GraphQL training"]
- [Finding 2 — e.g., "Budget covers infrastructure but not additional hiring"]

### Operational Feasibility: [Score 1-5]
[Can we deploy and maintain this?]
- [Finding 1]

### Schedule Feasibility: [Score 1-5]
[Can we deliver on time?]
- [Finding 1]
- [Critical path analysis]

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|----|------|-----------|--------|------------|-------|
| R1 | [Description] | High/Med/Low | High/Med/Low | [Strategy] | [Person] |
| R2 | [Description] | High/Med/Low | High/Med/Low | [Strategy] | [Person] |

## Recommendation

### Overall Feasibility: [Score] — [Go / Conditional Go / No-Go]

### Conditions (if Conditional Go)
1. [Condition 1 — what must be true]
2. [Condition 2 — what must be true]

### Next Steps
1. [Immediate action]
2. [Short-term action]
3. [Checkpoint/gate review date]

## Appendix
- [Link to PoC results]
- [Link to benchmark data]
- [Link to detailed cost analysis]
```
