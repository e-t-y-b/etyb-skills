# Technology Research & Evaluation — Deep Reference

**Always use `WebSearch` to verify current tool versions, framework benchmarks, community metrics, and ecosystem status before giving recommendations. Technology landscapes shift rapidly — what was bleeding-edge six months ago may be mainstream today or abandoned.**

## Table of Contents
1. [Technology Evaluation Frameworks](#1-technology-evaluation-frameworks)
2. [Weighted Scoring Matrix Design](#2-weighted-scoring-matrix-design)
3. [Proof of Concept (PoC) Design](#3-proof-of-concept-poc-design)
4. [Total Cost of Ownership (TCO) Analysis](#4-total-cost-of-ownership-tco-analysis)
5. [Technology Radar](#5-technology-radar)
6. [Open-Source Project Health Assessment](#6-open-source-project-health-assessment)
7. [Vendor Evaluation & Lock-In Assessment](#7-vendor-evaluation--lock-in-assessment)
8. [Migration Cost Estimation](#8-migration-cost-estimation)
9. [Decision Documentation (ADRs & RFCs)](#9-decision-documentation-adrs--rfcs)
10. [Common Technology Comparison Domains](#10-common-technology-comparison-domains)
11. [AI-Assisted Technology Evaluation](#11-ai-assisted-technology-evaluation)
12. [Technology Evaluation Anti-Patterns](#12-technology-evaluation-anti-patterns)

---

## 1. Technology Evaluation Frameworks

### Architecture Tradeoff Analysis Method (ATAM)

ATAM is a structured method for evaluating software architecture decisions against quality attribute requirements. Originally developed at the Software Engineering Institute (SEI), it remains the gold standard for high-stakes architecture decisions.

**When to Use**: Major technology or architecture decisions that are hard to reverse — primary database, cloud provider, core framework, communication protocol.

**ATAM Process (Adapted for Technology Evaluation)**:

| Phase | Activity | Output |
|-------|----------|--------|
| 1. Present | Present the business drivers and quality attribute requirements | Priority-ranked quality attributes |
| 2. Investigate | Analyze each technology candidate against quality attributes | Sensitivity points, tradeoff points |
| 3. Test | Develop scenarios to test each candidate | Scenario-based evaluation results |
| 4. Report | Summarize findings, risks, tradeoffs | Decision recommendation with evidence |

**Quality Attributes to Evaluate** (ISO 25010 aligned):

| Attribute | Example Questions | Measurement |
|-----------|-------------------|-------------|
| Performance | What's the p99 latency? Throughput under load? | Benchmarks, load tests |
| Scalability | Horizontal vs vertical scaling? Auto-scaling support? | Architecture patterns, cloud support |
| Reliability | What's the SLA? Failure modes? Recovery time? | Uptime data, chaos testing results |
| Security | Authentication models? Vulnerability history? Compliance? | CVE database, security audit results |
| Maintainability | Code quality? Documentation? Breaking change frequency? | Release notes, migration guides |
| Portability | Vendor lock-in? Standard compliance? Multi-cloud? | API surface area, abstraction layers |
| Usability (DX) | Learning curve? Developer tooling? Debugging experience? | Community surveys, onboarding time |

### Cost Benefit Analysis Method (CBAM)

CBAM extends ATAM by adding economic analysis. For each architectural decision, it quantifies the expected utility (benefit) against the cost.

**CBAM Steps:**
1. Prioritize quality attribute scenarios from ATAM
2. Estimate the benefit of each candidate for each scenario (0-100 scale)
3. Estimate the cost (development time, licensing, infrastructure, training)
4. Calculate ROI = Benefit / Cost for each candidate
5. Rank candidates by ROI

### Lightweight Evaluation Approaches

For less critical decisions (choosing a UI component library, logging framework, testing tool), use lighter methods:

**Quick Comparison Table** (5-10 minutes):

| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| Meets core requirements | Yes/No | Yes/No | Yes/No |
| Team familiarity | High/Med/Low | High/Med/Low | High/Med/Low |
| Community/support | Active/Moderate/Declining | ... | ... |
| License compatible | Yes/No | Yes/No | Yes/No |
| **Decision** | | **Winner** | |

**The "Good Enough" Heuristic**: For reversible decisions (libraries, tools), if one option clearly meets all requirements and the team knows it, choose it. Don't over-research reversible choices.

### Decision Reversibility Framework

| Decision Type | Examples | Research Investment | Method |
|--------------|----------|-------------------|--------|
| **One-Way Door** (hard to reverse) | Primary database, cloud provider, programming language, core framework | High — weeks of evaluation, PoC builds, stakeholder review | ATAM/CBAM, weighted scoring, PoC |
| **Two-Way Door** (easy to reverse) | UI library, testing framework, CI tool, monitoring tool | Low — hours of comparison, team discussion | Quick comparison, try it for a sprint |
| **Sliding Door** (gets harder to reverse over time) | ORM, state management, API protocol | Medium — days of evaluation, small PoC | Weighted scoring, time-boxed spike |

---

## 2. Weighted Scoring Matrix Design

### Building an Effective Scoring Matrix

A weighted scoring matrix makes technology decisions transparent and defensible. The process matters as much as the result — it forces teams to explicitly state what they value.

**Step 1: Define Criteria**

Start with broad categories, then decompose into specific, measurable criteria:

| Category | Specific Criteria | How to Measure |
|----------|-------------------|----------------|
| **Technical Fit** | Performance benchmarks, scalability model, API design, type safety | Benchmarks, architecture review |
| **Developer Experience** | Learning curve, documentation quality, IDE support, debugging tools | Team survey, onboarding time |
| **Ecosystem** | Package ecosystem, integrations, hosting options, CI/CD support | Package registry counts, integration list |
| **Community & Support** | Community size, activity, commercial support, training resources | GitHub metrics, Stack Overflow activity |
| **Operational** | Deployment complexity, monitoring, observability, upgrade path | Ops complexity score, upgrade history |
| **Cost** | Licensing, infrastructure, training, hiring | TCO analysis |
| **Risk** | Maturity, vendor stability, lock-in, security track record | Risk matrix |

**Step 2: Assign Weights**

Weights should reflect business priorities, not technical preferences. Use the 100-point allocation method: distribute 100 points across criteria, forcing prioritization.

```
Example Weight Distribution (B2B SaaS Product):
  Performance Benchmarks:     15 points
  Scalability Model:          15 points
  Developer Experience:       15 points
  Ecosystem Maturity:         10 points
  Community & Support:        10 points
  Operational Complexity:     10 points
  Cost (TCO):                 10 points
  Security Track Record:       5 points
  Team Familiarity:           10 points
  ────────────────────────────────
  Total:                     100 points
```

**Step 3: Score Each Candidate**

Use a consistent 1-5 scale with clear definitions:

| Score | Meaning | Guidance |
|-------|---------|----------|
| 5 | Excellent | Best-in-class, exceeds all requirements |
| 4 | Good | Meets all requirements, minor gaps |
| 3 | Adequate | Meets core requirements, notable gaps |
| 2 | Weak | Partially meets requirements, significant gaps |
| 1 | Poor | Does not meet requirements, dealbreaker issues |

**Step 4: Calculate Weighted Scores**

```
Weighted Score = Σ (Weight_i × Score_i) / Total Weight
```

**Example: Frontend Framework Comparison**

| Criteria | Weight | React | Vue | Svelte |
|----------|--------|-------|-----|--------|
| Performance | 15 | 4 (60) | 4 (60) | 5 (75) |
| DX / Learning Curve | 15 | 4 (60) | 5 (75) | 4 (60) |
| Ecosystem | 10 | 5 (50) | 4 (40) | 3 (30) |
| Community | 10 | 5 (50) | 4 (40) | 3 (30) |
| Team Familiarity | 10 | 5 (50) | 2 (20) | 1 (10) |
| Hiring Pool | 10 | 5 (50) | 3 (30) | 2 (20) |
| Scalability | 15 | 5 (75) | 4 (60) | 4 (60) |
| Operational | 10 | 4 (40) | 4 (40) | 3 (30) |
| Cost | 5 | 5 (25) | 5 (25) | 5 (25) |
| **Total** | **100** | **460** | **390** | **340** |

**Key Principle**: The matrix doesn't make the decision — it structures the conversation. If the result feels wrong, examine the weights, not the scores.

### Common Pitfalls in Scoring Matrices

| Pitfall | How to Avoid |
|---------|-------------|
| Weights that are all equal | Force prioritization — if everything is equally important, nothing is |
| Scores based on vibes | Require evidence for each score (benchmark, doc link, team survey) |
| Too many criteria | 7-12 criteria max — more dilutes the signal |
| Missing the dealbreaker check | Before scoring, verify no candidate has a hard dealbreaker (license, missing critical feature) |
| Ignoring the team's emotional response | If the team groans at the winner, explore why — there may be valid concerns the matrix missed |

---

## 3. Proof of Concept (PoC) Design

### When to Build a PoC

Build a PoC when:
- The decision is a one-way or sliding door
- The team has no prior experience with a candidate technology
- Benchmarks and documentation alone can't answer the key questions
- Stakeholders need a tangible demonstration to be convinced

Skip the PoC when:
- The team already has production experience with the technology
- The decision is easily reversible
- Time constraints make a PoC impractical (decide with available evidence instead)
- One candidate clearly dominates on all criteria

### PoC Design Principles

**1. Define Success Criteria Before Building**

Write down exactly what the PoC needs to prove before writing a single line of code:

```markdown
## PoC: Evaluate [Technology X] for [Use Case]

### Hypothesis
[Technology X] can handle [specific scenario] with [specific performance/quality requirement].

### Success Criteria
1. [ ] Can process 10K events/second with < 100ms p99 latency
2. [ ] Integrates with our existing PostgreSQL database
3. [ ] Team can onboard and be productive within 2 days
4. [ ] Deployment to our K8s cluster is straightforward
5. [ ] Monitoring/observability hooks are available

### Out of Scope
- Production-grade error handling
- Full feature implementation
- UI polish
- Security hardening
```

**2. Time-Box Ruthlessly**

| PoC Type | Time Box | Scope |
|----------|----------|-------|
| **Spike** | 1-2 days | Answer a single technical question ("Can X do Y?") |
| **Lightweight PoC** | 3-5 days | Build a representative slice of the core use case |
| **Full PoC** | 1-2 weeks | Build a realistic prototype covering core + integration points |
| **Bake-off** | 2-4 weeks | Build the same thing with 2-3 candidates, compare head-to-head |

**3. Build the Hardest Part First**

Don't start with the happy path. Build the scenario you're most worried about:
- If worried about performance → build and benchmark the hot path first
- If worried about integration → connect to the real system first
- If worried about DX → give it to a junior dev and observe their experience

**4. Use Production-Like Conditions**

- Realistic data volumes (not toy data)
- Actual network conditions (latency, connection limits)
- Real authentication/authorization patterns
- Deployment to the actual target environment (not just localhost)

### PoC Evaluation Template

```markdown
## PoC Results: [Technology]

### Summary
[One paragraph: did it meet success criteria?]

### Success Criteria Results
| Criteria | Result | Evidence |
|----------|--------|----------|
| 10K events/sec @ <100ms p99 | PASS/FAIL | [benchmark results link] |
| PostgreSQL integration | PASS/FAIL | [notes] |
| Team onboarding time | PASS/FAIL | [actual time observed] |

### Surprises (Positive)
- [Things that went better than expected]

### Surprises (Negative)
- [Things that went worse than expected]

### Estimated Production Effort
- [How long to go from PoC to production-ready]
- [What shortcuts were taken that need to be addressed]

### Recommendation
[Proceed / Proceed with caveats / Do not proceed — with reasoning]
```

---

## 4. Total Cost of Ownership (TCO) Analysis

### TCO Framework for Technology Decisions

TCO goes far beyond licensing costs. The hidden costs of a technology choice often dwarf the sticker price.

### Cost Categories

| Category | Components | Often Forgotten |
|----------|-----------|-----------------|
| **Acquisition** | License fees, subscription costs, one-time purchase | Negotiation time, procurement process |
| **Implementation** | Development time, integration effort, data migration | Learning curve ramp-up, initial bugs |
| **Infrastructure** | Compute, storage, network, CDN, database hosting | Egress fees, cross-region replication, backup storage |
| **Operations** | Monitoring, maintenance, upgrades, patches | On-call burden, incident response time |
| **Training** | Courses, documentation, pairing, mentoring | Productivity dip during transition, hiring for new skills |
| **Opportunity Cost** | Time spent on this choice vs. alternatives | Features delayed, technical debt from learning on the job |
| **Migration (future)** | Cost to move away if the choice doesn't work out | Data migration, API contract changes, retraining |
| **Scaling** | Cost growth as usage increases | Non-linear pricing tiers, egress at scale, connection limits |

### Cloud Service TCO Comparison Template

```
Service: [e.g., Managed PostgreSQL]
Candidates: AWS RDS vs. GCP Cloud SQL vs. Azure Database vs. Self-Hosted

Monthly Cost Estimation (at expected scale):
┌──────────────────────┬────────┬────────┬────────┬──────────────┐
│ Cost Component        │ AWS RDS│ GCP SQL│ Azure  │ Self-Hosted  │
├──────────────────────┼────────┼────────┼────────┼──────────────┤
│ Compute              │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
│ Storage              │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
│ Backup/snapshots     │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
│ Network/egress       │ $XXX   │ $XXX   │ $XXX   │ N/A          │
│ HA/replication       │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
│ Ops engineer time    │ Low    │ Low    │ Low    │ High ($XXX)  │
│ ────────────────────┼────────┼────────┼────────┼──────────────│
│ Monthly Total        │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
│ Annual Total         │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
│ 3-Year Total         │ $XXX   │ $XXX   │ $XXX   │ $XXX         │
└──────────────────────┴────────┴────────┴────────┴──────────────┘
```

### TCO Time Horizons

| Horizon | When to Use | What to Include |
|---------|-------------|-----------------|
| **1 Year** | MVP, experiments, uncertain future | Direct costs only, minimal ops |
| **3 Year** | Growth-stage products, established systems | Full TCO including scaling projections |
| **5 Year** | Enterprise, infrastructure decisions | Include technology lifecycle, migration risk |

### SaaS vs. Self-Hosted Decision Framework

| Factor | Favor SaaS/Managed | Favor Self-Hosted |
|--------|--------------------|--------------------|
| Team size | Small team (< 10 engineers) | Large platform team available |
| Ops expertise | Limited | Deep infrastructure expertise |
| Customization | Standard use case | Highly custom requirements |
| Compliance | Standard compliance (SOC2, GDPR) | Strict data residency, air-gapped |
| Scale | Predictable, moderate scale | Very high scale (managed services get expensive) |
| Budget | Operating budget (OpEx preferred) | Capital budget available, want to amortize |

---

## 5. Technology Radar

### ThoughtWorks Technology Radar Model

The ThoughtWorks Technology Radar is the gold standard for technology evaluation at an organizational level. It categorizes technologies into four rings:

| Ring | Meaning | Action |
|------|---------|--------|
| **Adopt** | Production-ready, proven. Use with confidence. | Default choice for new projects |
| **Trial** | Worth pursuing. Use on non-critical projects to build experience. | Time-boxed pilot projects |
| **Assess** | Interesting. Explore to understand potential impact. | Research, attend talks, read case studies |
| **Hold** | Proceed with caution. Don't start new work with this. | Existing use is OK, but don't expand |

**Quadrants** (what type of technology):
1. **Techniques** — Processes, patterns, approaches (e.g., trunk-based development, event sourcing)
2. **Platforms** — Infrastructure, cloud services (e.g., AWS, Vercel, Cloudflare Workers)
3. **Tools** — Software tools (e.g., Cursor, k6, Terraform)
4. **Languages & Frameworks** — Programming languages and frameworks (e.g., Rust, SvelteKit, htmx)

### Building Your Own Technology Radar

**Process:**
1. **Gather nominations** — Engineers submit technologies they've used, explored, or want to evaluate
2. **Working group discussion** — Senior engineers + architects discuss each nomination (quarterly)
3. **Assign ring and quadrant** — Based on production experience, community health, strategic fit
4. **Publish and communicate** — Share with the organization with clear rationale for each placement
5. **Review quarterly** — Technologies move between rings as experience accumulates

**Tools for Maintaining a Radar:**
- **Thoughtworks Build Your Own Radar** — Free tool at radar.thoughtworks.com (upload a CSV/Google Sheet)
- **Backstage Tech Radar Plugin** — Integrates with Spotify Backstage developer portal
- **AOE Technology Radar** — Open-source radar visualization tool (GitHub: AOEpeople/aoe_technology_radar)
- **Custom internal wiki** — Simple but effective — a table in Confluence/Notion with ring assignments

### When to Update the Radar

| Event | Action |
|-------|--------|
| New project starts | Check if chosen technologies align with radar |
| Technology graduates from PoC to production | Move from Trial → Adopt |
| Major incident caused by a technology | Consider moving to Hold |
| Critical vulnerability in a dependency | Consider moving to Hold |
| Team adopts something new successfully | Add to radar at Trial/Adopt |
| Quarterly review | Reassess all entries for ring accuracy |

---

## 6. Open-Source Project Health Assessment

### Community Health Metrics

When evaluating an open-source project, look beyond vanity metrics (stars, downloads) to signals that predict long-term viability.

### Health Assessment Framework

| Dimension | Metrics to Check | Red Flags |
|-----------|-----------------|-----------|
| **Activity** | Commit frequency, recent release date, PR merge rate | No commits in 3+ months, no releases in 6+ months |
| **Maintainer Health** | Number of active maintainers, bus factor, maintainer diversity | Single maintainer, all from one company, maintainer burnout signals |
| **Community** | Open issues trend, time to first response, contributor growth | Issues piling up unanswered, declining contributor count |
| **Quality** | Test coverage, CI status, security policy, changelog quality | No tests, broken CI, no SECURITY.md, no semver |
| **Adoption** | Production users (case studies), corporate backing, ecosystem integration | No visible production users, no corporate sponsors |
| **Funding** | Funding model, sustainability plan | No funding model, sole reliance on volunteer maintainers |
| **Governance** | License clarity, contribution guidelines, code of conduct, decision-making process | Unclear license, no CONTRIBUTING.md, opaque decision-making |

### Where to Find Health Data

| Data Point | Source |
|-----------|--------|
| Commit frequency, PR merge rate | GitHub/GitLab repository insights |
| npm/PyPI downloads | npm (npmjs.com), PyPI (pypistats.org), downloads by version |
| Dependency usage | GitHub dependency graph, Socket.dev, deps.dev |
| Security vulnerabilities | Snyk Advisor, Socket.dev, GitHub Advisory Database, OSV.dev |
| Community health | CHAOSS metrics (chaoss.community), GitHub Community Standards |
| Funding | Open Collective, GitHub Sponsors, Tidelift, company backing |
| Bus factor | Git contributor analysis, maintainer count on GitHub insights |
| Package score | Snyk Advisor (snyk.io/advisor), Scorecard (securityscorecards.dev), Socket.dev |

### The OpenSSF Scorecard

The Open Source Security Foundation (OpenSSF) Scorecard provides automated security health checks:

| Check | What It Evaluates |
|-------|-------------------|
| Code-Review | Are changes reviewed before merging? |
| Branch-Protection | Are branch protection rules enabled? |
| CI-Tests | Are CI tests running on PRs? |
| Dependency-Update-Tool | Is Dependabot/Renovate configured? |
| Fuzzing | Is fuzzing configured (OSS-Fuzz, ClusterFuzz)? |
| License | Is the license declared and OSI-approved? |
| Maintained | Is the project actively maintained? |
| Pinned-Dependencies | Are dependencies pinned to specific versions? |
| Signed-Releases | Are releases signed? |
| Token-Permissions | Are GitHub token permissions minimally scoped? |
| Vulnerabilities | Are there known unfixed vulnerabilities? |
| SAST | Is static analysis configured? |

Run the scorecard: `scorecard --repo=github.com/owner/repo`

### Funding Model Assessment

| Model | Sustainability | Examples |
|-------|---------------|----------|
| **Corporate-backed (single)** | Medium risk — depends on one company's priorities | Next.js (Vercel), Angular (Google), PyTorch (Meta) |
| **Corporate-backed (multiple)** | Lower risk — diversified backing | Kubernetes (CNCF), Linux (Linux Foundation) |
| **Foundation-governed** | Low risk — institutional backing | Apache projects, CNCF projects, Eclipse Foundation |
| **VC-funded open-core** | Medium risk — commercial pressure may change licensing | HashiCorp (BSL change), Elastic (SSPL), Redis (RSAL) |
| **Community-funded** | Higher risk — depends on donations | curl (sponsor-backed), many smaller projects |
| **Unfunded volunteer** | Highest risk — burnout, abandonment | Thousands of critical dependencies |

### License Compatibility Quick Reference

| License | Commercial Use | Modification | Distribution | Patent Grant | Copyleft |
|---------|---------------|-------------|-------------|-------------|----------|
| MIT | Yes | Yes | Yes | No | No |
| Apache 2.0 | Yes | Yes | Yes | Yes | No |
| BSD 2/3 Clause | Yes | Yes | Yes | No | No |
| ISC | Yes | Yes | Yes | No | No |
| MPL 2.0 | Yes | Yes | Yes | Yes | File-level |
| LGPL 2.1/3.0 | Yes | Yes | Yes | No | Library-level |
| GPL 2.0/3.0 | Yes | Yes | Yes (source required) | v3 only | Strong |
| AGPL 3.0 | Yes | Yes | Yes (network use = distribution) | Yes | Strongest |
| SSPL | Check terms | Yes | Restricted (SaaS) | No | Very strong |
| BSL 1.1 | Check terms | Yes | Restricted (time-limited) | Varies | Time-delayed |
| Elastic License 2.0 | Yes (not competing) | Yes | Restricted (no managed service) | No | Non-compete |

**Key License Risks:**
- **AGPL**: If your service uses AGPL code, you may need to open-source your entire service
- **SSPL/BSL/ELv2**: "Source available" but not truly open source — check if your use case is allowed
- **License changes**: Watch for projects changing licenses (Redis RSAL, HashiCorp BSL, Elastic ELv2)

---

## 7. Vendor Evaluation & Lock-In Assessment

### Vendor Lock-In Assessment Framework

| Dimension | Low Lock-In | Medium Lock-In | High Lock-In |
|-----------|-------------|----------------|-------------|
| **API Standards** | Open standards (SQL, HTTP, OpenAPI) | Proprietary with export APIs | Proprietary, no export |
| **Data Portability** | Standard formats, easy export | Export possible but lossy | Data trapped in proprietary format |
| **Migration Path** | Drop-in alternatives exist | Alternatives exist but migration is complex | No viable alternatives |
| **Multi-Cloud** | Works across providers | Provider-specific but portable with effort | Deeply integrated with one provider |
| **Contract Terms** | Month-to-month, no minimum | Annual with cancellation | Multi-year with penalties |

### Cloud Provider Lock-In Spectrum

| Service Type | Lock-In Level | Examples | Mitigation |
|-------------|--------------|---------|------------|
| Compute (VMs) | Low | EC2, GCE, Azure VMs | Standard containers, infrastructure as code |
| Containers (K8s) | Low-Medium | EKS, GKE, AKS | Standard K8s API, Helm charts |
| Serverless | Medium-High | Lambda, Cloud Functions, Azure Functions | Frameworks like Serverless/SST abstract some lock-in |
| Managed DB (SQL) | Medium | RDS, Cloud SQL, Azure SQL | Standard SQL, pgdump/restore |
| Proprietary DB | High | DynamoDB, Cosmos DB, Spanner | No drop-in alternative; design for abstraction layers |
| AI/ML Services | High | Bedrock, Vertex AI, Azure AI | Use model-agnostic APIs (OpenAI-compatible), abstract provider |
| Identity | Medium-High | Cognito, Firebase Auth, Azure AD B2C | Use standard protocols (OIDC/SAML), auth abstraction layer |
| Messaging | Medium | SQS/SNS, Pub/Sub, Service Bus | Standard protocols (AMQP, MQTT) or Kafka (portable) |

### Vendor Evaluation Scorecard

| Criteria | Weight | Questions to Ask |
|----------|--------|-----------------|
| **Product Fit** | 25% | Does it solve the core problem? Performance benchmarks? |
| **Financial Stability** | 15% | Revenue growth, funding, profitability, customer count? |
| **Support Quality** | 15% | Response time SLAs, dedicated support, documentation quality? |
| **Pricing Model** | 15% | Transparent pricing? Scales predictably? Hidden costs (egress, API calls)? |
| **Lock-In Risk** | 10% | Data portability? Standards compliance? Migration path? |
| **Security & Compliance** | 10% | SOC2 Type II? GDPR? HIPAA? Penetration testing? |
| **Roadmap Alignment** | 10% | Does the vendor's direction align with your needs? |

---

## 8. Migration Cost Estimation

### Migration Cost Framework

When estimating the cost of migrating from Technology A to Technology B:

| Cost Category | Components | Estimation Method |
|--------------|-----------|-------------------|
| **Analysis & Planning** | Current state assessment, target architecture, migration plan | 10-15% of total migration effort |
| **Code Changes** | Rewriting, refactoring, API changes, dependency updates | Count affected files/modules, estimate per-module effort |
| **Data Migration** | Schema changes, data transformation, validation | Measure data volume, identify transformation complexity |
| **Integration Updates** | Third-party integrations, internal service contracts | Count integration points, assess change per integration |
| **Testing** | Regression testing, performance testing, UAT | Proportional to code changes (typically 30-50% of dev effort) |
| **Training** | Team training, documentation, knowledge transfer | Hours × team size × hourly rate |
| **Rollout** | Blue-green deployment, canary rollout, monitoring | 5-10% of total migration effort |
| **Risk Buffer** | Unknown unknowns, scope creep, delays | 20-30% buffer on total estimate |

### Migration Complexity Scoring

| Factor | Low (1) | Medium (2) | High (3) |
|--------|---------|------------|----------|
| **Codebase size** | < 10K LOC | 10K-100K LOC | > 100K LOC |
| **Team familiarity with target** | Expert | Some experience | No experience |
| **Data volume** | < 1GB | 1GB-1TB | > 1TB |
| **Integration points** | 0-2 | 3-10 | > 10 |
| **Downtime tolerance** | Hours acceptable | Minutes acceptable | Zero downtime required |
| **Compliance requirements** | None | Standard (SOC2, GDPR) | Strict (HIPAA, PCI-DSS, FedRAMP) |

**Complexity Score:**
- 6-9: Straightforward migration (weeks)
- 10-14: Moderate migration (months)
- 15-18: Complex migration (quarters to years)

### Migration Strategies

| Strategy | When to Use | Risk Level |
|----------|------------|------------|
| **Big Bang** | Small systems, tight timelines, low risk | High (all-or-nothing) |
| **Strangler Fig** | Large systems, gradual migration, service-by-service | Low (incremental, reversible) |
| **Parallel Run** | Critical systems requiring validation | Medium (expensive to maintain both) |
| **Blue-Green** | Database or infrastructure migrations | Medium (requires infrastructure duplication) |
| **Feature-Flag Gated** | Gradual rollout with ability to roll back per-feature | Low (granular control) |

---

## 9. Decision Documentation (ADRs & RFCs)

### Architecture Decision Records (ADRs)

ADRs document significant architecture and technology decisions. They answer "why did we choose X?" months or years later.

**ADR Template (Michael Nygard Format):**

```markdown
# ADR-NNN: [Short Title of Decision]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Date
YYYY-MM-DD

## Context
[What is the issue that we're seeing that is motivating this decision or change?
What forces are at play? Technical, business, organizational, regulatory?]

## Decision
[What is the change that we're proposing and/or doing?
State the decision clearly and directly: "We will use X for Y."]

## Alternatives Considered

### Alternative 1: [Name]
- **Pros**: [list]
- **Cons**: [list]
- **Why rejected**: [specific reason]

### Alternative 2: [Name]
- **Pros**: [list]
- **Cons**: [list]
- **Why rejected**: [specific reason]

## Consequences

### Positive
- [What becomes easier or possible?]

### Negative
- [What becomes harder? What are the risks?]

### Neutral
- [What changes but is neither good nor bad?]

## References
- [Links to evaluation documents, PoC results, benchmarks]
```

**Where to Store ADRs:**
- In the repository: `docs/adr/` or `docs/decisions/` (close to the code)
- Tools: adr-tools CLI (GitHub: npryce/adr-tools), Log4brains (web viewer), Backstage ADR plugin

### Request for Comments (RFCs)

RFCs are used for more complex proposals that need broader input before a decision is made.

**When to Use ADR vs. RFC:**

| Use | ADR | RFC |
|-----|-----|-----|
| Single team decision | Yes | No |
| Cross-team impact | Maybe | Yes |
| Needs broad feedback | No | Yes |
| Document a completed decision | Yes | No |
| Propose a change for discussion | No | Yes |
| Quick, focused decision | Yes | No |
| Complex, multi-faceted proposal | No | Yes |

**RFC Template:**

```markdown
# RFC: [Title]

## Author(s)
[Names]

## Status
[Draft | Under Review | Accepted | Rejected | Withdrawn]

## Summary
[One paragraph: what are you proposing and why?]

## Motivation
[Why is this important? What problem does it solve?
What impact does it have? Who is affected?]

## Detailed Design
[The technical details of the proposal.
Include diagrams, API designs, data models as needed.]

## Alternatives Considered
[What other approaches were considered and why were they rejected?]

## Drawbacks
[What are the downsides of this approach?
Be honest — this builds credibility.]

## Unresolved Questions
[What questions remain? What needs to be figured out
during implementation?]

## Implementation Plan
[High-level phases and timeline.]

## References
[Links to prior art, benchmarks, related decisions.]
```

---

## 10. Common Technology Comparison Domains

### Quick-Reference Comparison Templates

These are the technology comparisons most frequently requested. Use `WebSearch` to get current data — the landscape changes constantly.

**Frontend Frameworks (2025-2026)**

| Dimension | React | Vue 3 | Svelte 5 | Angular 19+ | Solid | Qwik |
|-----------|-------|-------|----------|-------------|-------|------|
| Rendering Model | Virtual DOM | Virtual DOM (vapor mode coming) | Compiled (no VDOM) | Incremental DOM (signals) | Fine-grained reactivity | Resumable |
| State Management | useState/Redux/Zustand/Jotai | Pinia/refs/reactive | Runes ($state, $derived) | Signals (v16+) | Signals (built-in) | Signals + Resumability |
| SSR/SSG | Next.js, Remix, Astro | Nuxt 3, Astro | SvelteKit, Astro | Angular Universal/Analog | SolidStart | Built-in |
| Bundle Size | Medium | Small-Medium | Very small | Large (improving) | Very small | Small (lazy) |
| Learning Curve | Medium | Low-Medium | Low | High | Medium | Medium-High |
| Ecosystem Size | Largest | Large | Growing | Large | Small-Medium | Small |
| Job Market | Largest | Moderate | Growing | Large (enterprise) | Niche | Niche |

**Backend Runtimes (2025-2026)**

| Dimension | Node.js | Deno 2 | Bun | Go | Rust | Python |
|-----------|---------|--------|-----|----|----|--------|
| Performance | Good | Good | Excellent | Excellent | Best | Moderate |
| Startup Time | Fast | Fast | Very Fast | Very Fast | Very Fast | Slow |
| Type Safety | TS (opt-in) | TS (native) | TS (native) | Static | Static | Optional (mypy) |
| Package Ecosystem | npm (largest) | npm + JSR | npm compatible | Go modules | crates.io | PyPI |
| Concurrency Model | Event loop | Event loop | Event loop | Goroutines | async/await + threads | asyncio/GIL |
| Use Case Sweet Spot | Full-stack JS, APIs | Secure by default, modern JS | Performance-sensitive JS | Microservices, infra tools | Systems, performance-critical | AI/ML, data, scripting |

**Databases (2025-2026)**

| Dimension | PostgreSQL | MySQL | MongoDB 8 | DynamoDB | Redis/Valkey | CockroachDB |
|-----------|-----------|-------|-----------|----------|-------------|-------------|
| Model | Relational | Relational | Document | Key-Value/Document | Key-Value/Cache | Distributed SQL |
| Scaling | Vertical + read replicas | Vertical + read replicas | Horizontal (sharding) | Horizontal (managed) | Vertical + cluster | Horizontal (auto) |
| ACID | Full | Full | Multi-doc transactions | Per-item + transactions | Per-command | Full (serializable) |
| Best For | General purpose, complex queries | Web apps, read-heavy | Flexible schema, rapid iteration | Massive scale, serverless | Caching, sessions, pub/sub | Global distribution |
| Managed Options | RDS, Cloud SQL, Azure, Neon, Supabase | RDS, Cloud SQL, Azure, PlanetScale | Atlas | AWS native | ElastiCache, MemoryDB, Upstash | Cockroach Cloud |

---

## 11. AI-Assisted Technology Evaluation

### Using AI for Technology Research (2025-2026)

AI tools can accelerate technology evaluation, but require verification:

| Task | AI Can Help With | Still Needs Human Verification |
|------|-----------------|-------------------------------|
| Initial landscape scan | "What are the top 5 React state management libraries in 2026?" | Current adoption data, recent releases |
| Feature comparison | Generate comparison tables from documentation | Accuracy of feature claims, edge cases |
| Code examples | Generate PoC code for candidate technologies | Production readiness, performance characteristics |
| Migration estimation | Identify API surface differences between versions | Actual effort in your specific codebase |
| Documentation analysis | Summarize changelogs, migration guides | Breaking changes relevant to your use case |

**Best Practice**: Use AI to generate a first draft of any technology comparison, then verify every claim with `WebSearch` and primary sources. AI models may have outdated or incorrect information about specific versions and features.

---

## 12. Technology Evaluation Anti-Patterns

### Anti-Pattern Catalog

| Anti-Pattern | Description | Better Approach |
|-------------|-------------|-----------------|
| **Benchmark Theatre** | Running benchmarks that don't reflect your actual workload | Benchmark with realistic data volumes, access patterns, and concurrency |
| **Demo-Driven Development** | Choosing technology because the demo was impressive | Evaluate with your actual requirements, not the vendor's cherry-picked scenarios |
| **Conference-Driven Development** | Adopting technologies seen at conferences | Conference talks show success stories, not failures. Verify with production users in your segment |
| **Stack Overflow-Driven Development** | Choosing the technology with the most Stack Overflow answers | High SO activity can mean the tool is confusing, not popular |
| **Ignoring the Boring Option** | Dismissing proven technologies in favor of exciting new ones | PostgreSQL, Linux, and HTTP have won because they're reliable, not because they're exciting |
| **Vendor Pitch as Evaluation** | Treating a vendor demo/sales pitch as a technology evaluation | Conduct independent evaluation with your data, your team, your requirements |
| **Survivorship Bias** | Only reading success stories for a technology | Actively search for "why we left X" and "X post-mortem" posts |
| **False Equivalence** | Comparing a mature tool's rough edges to a new tool's promises | Compare what's proven in production, not what's promised in a README |
| **Ignoring Operational Cost** | Choosing the best developer experience without considering ops burden | Include deployment, monitoring, debugging, and upgrade complexity in evaluation |
| **The Rewrite Fallacy** | "If we just rewrote everything in X, all our problems would go away" | Most problems are in the business logic, not the framework. A rewrite carries the same problems plus new ones |
