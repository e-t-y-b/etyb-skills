# Architecture Documentation — Deep Reference

**Always use `WebSearch` to verify current tool versions, ADR template updates, and diagramming tool features before giving architecture documentation advice. The diagramming and docs-as-code ecosystem evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Architecture Decision Records (ADRs)](#1-architecture-decision-records-adrs)
2. [C4 Model and Diagramming](#2-c4-model-and-diagramming)
3. [Technical Design Documents](#3-technical-design-documents)
4. [RFC Process](#4-rfc-process)
5. [Diagramming Tools](#5-diagramming-tools)
6. [Architecture Documentation Frameworks](#6-architecture-documentation-frameworks)
7. [Living Documentation](#7-living-documentation)
8. [Sequence Diagrams](#8-sequence-diagrams)
9. [Architecture Visualization and Portals](#9-architecture-visualization-and-portals)
10. [Decision Matrices and Trade-Off Analysis](#10-decision-matrices-and-trade-off-analysis)
11. [Architecture Governance](#11-architecture-governance)
12. [Cloud Architecture Diagrams](#12-cloud-architecture-diagrams)

---

## 1. Architecture Decision Records (ADRs)

### MADR 4.0 (Current Standard)

MADR (Markdown Architectural Decision Records) v4.0.0 (released Sep 2024) is the most widely adopted ADR format. Files go in `decisions/` with naming pattern `NNNN-title-with-dashes.md`.

**MADR 4.0 Template Sections:**
1. **Title** — short noun phrase (e.g., "ADR-0005: Use PostgreSQL for user data")
2. **Status** — proposed, accepted, deprecated, superseded
3. **Context and Problem Statement** — what we're deciding and why now
4. **Decision Drivers** (optional) — key factors influencing the decision
5. **Considered Options** — every viable option explored
6. **Decision Outcome** — chosen option + justification
7. **Pros and Cons of the Options** — detailed per option
8. **Consequences** — what results from this decision (merged from separate positive/negative in v3.0)
9. **More Information** — links, references, follow-up ADRs

MADR 4.0 ships "bare" and "minimal" template variants, each in annotated and plain formats.

### Other ADR Formats

| Format | Style | Best For |
|--------|-------|----------|
| **Nygard** (original) | Minimal: Title, Status, Context, Decision, Consequences | Quick, lightweight decisions |
| **Y-Statements** | Single sentence: "In the context of [X], facing [Y], we decided [Z], to achieve [A], accepting [B]" | Capturing decisions inline in other documents |
| **Alexandrian** | Rich narrative form | Decisions requiring extensive context |

### ADR Tooling

| Tool | Language | Key Features |
|------|----------|-------------|
| **adr-tools** (npryce) | Bash | Original CLI: `adr init`, `adr new`, `adr link`, `adr generate`; stores in `doc/adr/` |
| **Log4brains** | Node.js | MADR default template; generates static website from ADRs; CI/CD auto-publishing |
| **adr-viewer** | Python | Generates browsable website from ADR files; lighter than Log4brains |
| **dotnet-adr** | .NET | Cross-platform CLI; supports MADR, Alexandrian, Business Case templates |

### ADR Best Practices

- Keep to 1-2 pages, readable in 5-10 minutes
- Write BEFORE or DURING implementation, not after — the decision-making process is the value
- Review every 6-12 months; supersede when decisions change (don't delete — link to successor)
- Link ADRs to PRs/commits (reference ADR number in commit messages: `Implements ADR-0005`)
- Store alongside code in version control (`docs/decisions/` or `docs/adr/`)
- Focus on "why" over "what" — the reasoning matters more than the outcome
- Document the alternatives that were rejected and why — future engineers will ask "why didn't we use X?"
- Include the team members involved in the decision and any constraints that influenced it

---

## 2. C4 Model and Diagramming

### The Four Levels

1. **System Context (Level 1)** — shows the system in scope, its users, and external system dependencies. The "10,000 foot view." Every architecture documentation should start here.
2. **Container (Level 2)** — decomposes the system into applications, services, databases, message queues. Shows technology choices and high-level communication.
3. **Component (Level 3)** — decomposes a container into internal components, classes, or modules. Shows internal structure.
4. **Code (Level 4)** — class/entity-level detail. Rarely documented manually — auto-generate from code if needed.

**Supplementary Diagrams:** System Landscape (broader context), Dynamic (sequence-style interactions), Deployment (infrastructure mapping).

### C4 Tools

| Tool | Approach | Best For |
|------|----------|----------|
| **Structurizr** | DSL (diagrams-as-code) | Reference implementation by Simon Brown; model-based consistency; auto-generates multiple diagram types from single model; AWS/Azure/GCP/K8s themes; Python bindings available (2026) |
| **IcePanel** | Drag-and-drop GUI + model | Enterprise/cross-functional teams; interactive drill-down across C4 levels; overlays for sequences/flows; exports to PNG/PDF/JSON/CSV |
| **C4-PlantUML** | PlantUML extension | Teams already using PlantUML; full UML power |
| **Mermaid C4** | Mermaid syntax | Lightweight, GitHub-native; experimental/beta; less complete than dedicated tools |

### C4 Best Practices

- Always start with Level 1 (System Context) — it's the most useful diagram for stakeholder communication
- Level 2 (Container) is the most commonly used for engineering teams — shows technology choices
- Level 3 (Component) is useful for complex containers but don't over-document — keep it focused
- Skip Level 4 (Code) unless required for compliance — the code itself is the documentation
- Use consistent notation and a legend on every diagram
- Update diagrams when containers/services are added, removed, or significantly changed

---

## 3. Technical Design Documents

### Google-Style Design Document Template

The most widely referenced template, emphasizing trade-offs over exhaustive specs:

1. **Metadata** — author(s), reviewers, date, status (Draft/In Review/Approved/Deprecated)
2. **Overview/Summary** — 1-2 paragraphs: what and why
3. **Background/Context** — why now? What problem? Enough for a newcomer to understand
4. **Goals and Non-Goals** — explicit scope boundaries (non-goals are as important as goals)
5. **Proposed Solution / Design** — architecture overview, API schemas, data models, workflow diagrams
6. **Alternatives Considered** — what was rejected and why (critical for future understanding)
7. **System Design Details** — component interactions, data flow, sequence diagrams
8. **Security / Privacy Considerations** — threat model, data classification, access control
9. **Scalability / Performance** — load estimates, bottlenecks, capacity planning
10. **Monitoring and Observability** — metrics, alerts, dashboards
11. **Rollout Plan** — feature flags, migration strategy, rollback plan
12. **Open Questions** — unresolved items requiring discussion
13. **Timeline / Milestones** — rough estimates, key dates

### Design Document Best Practices

- Use diagrams liberally (system context, sequence, data flow) — a diagram is worth a thousand words
- Include code snippets only for API interfaces and critical algorithms — not implementation details
- Review with both technical and product stakeholders
- Keep living — update as implementation diverges from original design
- 5-10 pages is the sweet spot; longer documents indicate the scope is too broad
- The process of writing is as valuable as the artifact — it forces clear thinking about trade-offs

---

## 4. RFC Process

### How Top Organizations Run RFCs

**HashiCorp RFC Template (best-in-class starting point):**
1. **Overview** — 1-2 paragraphs, goal of the RFC, without diving into "how"
2. **Background** — at least 2 paragraphs, full context. "A random engineer should acquire nearly full context from this section alone." Link to prior RFCs/discussions
3. **Proposal/Goal** — overview of the "how"
4. **Implementation** — rough API changes, package changes, surface area
5. **Abandoned Ideas** — organized separately with explanations for why they were rejected (never delete, always document)

**Other Notable Approaches:**
- **Uber**: Segmented mailing lists by engineering group; "approver" fields for complex proposals; scaled to 2000+ engineers
- **Spotify**: RFCs and ADRs deeply embedded in engineering culture; integrated with Backstage
- **Airbnb**: Specs + design docs for Product and Engineering
- **Google Fuchsia**: Published RFC best practices as open-source reference

### RFC Process Best Practices

- Start with a template to guide authors — reduce the barrier to writing
- Iterate templates over time — add sections the team cares about (reliability, scale, security)
- Set clear approval processes — who must sign off, by role or by domain
- Time-box the review period (typically 1-2 weeks) — prevent RFCs from lingering indefinitely
- Store in version control or a searchable knowledge base (not email)
- Use status fields: Draft, In Review, Accepted, Rejected, Superseded
- Separate the "what" decision from the "how" implementation when possible

---

## 5. Diagramming Tools

### Text/Code-Based (Diagrams-as-Code)

| Tool | Strengths | Best For |
|------|-----------|----------|
| **Mermaid.js** (v11.x) | Native GitHub/GitLab/Notion rendering; 20+ diagram types; AI generation support | README-embedded docs, lightweight diagrams, CI-rendered docs |
| **D2** (Terrastruct) | Clean modern syntax, multiple layout engines, animations/tooltips/themes | Complex system architecture, professional diagrams |
| **PlantUML** | Most feature-rich UML tool, strict compliance, powerful sequence diagrams | Enterprise UML, Confluence/Jira environments |
| **Structurizr DSL** | C4-native, model-based, cloud themes | C4 model diagrams exclusively |
| **Eraser.io** | AI-powered (DiagramGPT), visual + code hybrid, cloud icons | Technical design docs, whiteboard + code hybrid |

### Visual/Collaborative

| Tool | Best For |
|------|----------|
| **draw.io / diagrams.net** | General-purpose, enterprise, Atlassian shops; free, open source |
| **Excalidraw** | Brainstorming, architecture reviews, collaborative design; hand-drawn aesthetic signals "work in progress" |
| **tldraw** | Developers building custom whiteboard experiences; infinite canvas SDK |

### Tool Selection Framework

```
1. Where will diagrams be rendered?
   - GitHub/GitLab READMEs → Mermaid (native rendering)
   - Documentation sites → Mermaid or D2
   - Confluence/Jira → PlantUML or draw.io
   - Dedicated architecture portal → Structurizr or IcePanel

2. Who creates the diagrams?
   - Engineers (text-first) → Mermaid, D2, or PlantUML
   - Mixed technical/non-technical → draw.io or Excalidraw
   - Architecture team → Structurizr or IcePanel

3. Version control important?
   - Yes → Mermaid, D2, PlantUML, Structurizr (text-based = diff-friendly)
   - Less important → draw.io, Excalidraw

4. Complexity level?
   - Simple/moderate → Mermaid
   - Complex with fine control → D2 or PlantUML
   - C4 model diagrams → Structurizr
```

**Note:** draw.io is dropping PlantUML support (online end of 2025, Confluence/Jira 2028). Plan migration for PlantUML diagrams in draw.io.

---

## 6. Architecture Documentation Frameworks

### Framework Comparison

| Framework | Scope | Best For |
|-----------|-------|----------|
| **arc42** | Single system's software architecture | Most software teams; practical, well-templated (12 sections) |
| **TOGAF** | Enterprise-wide IT architecture | Enterprise contexts requiring organizational alignment |
| **ISO/IEC/IEEE 42010:2022** | Architecture description standard | Formal/regulated environments requiring compliance |
| **SEI Views and Beyond** | Academic/rigorous documentation | Teams needing the most rigorous approach |

### arc42 Sections

1. Introduction and Goals
2. Architecture Constraints
3. System Scope and Context
4. Solution Strategy
5. Building Block View
6. Runtime View
7. Deployment View
8. Cross-cutting Concepts
9. Architecture Decisions (ADRs fit here)
10. Quality Requirements
11. Risks and Technical Debt
12. Glossary

Available as templates in Markdown, AsciiDoc, LaTeX on GitHub. arc42 is practical and focused — use it as the default framework unless the organization mandates something else.

### When to Use Which

- **Startup/Growth** → No formal framework; ADRs + design docs + C4 diagrams are sufficient
- **Scale** → arc42 as a template for service documentation; ADRs for decisions
- **Enterprise** → arc42 for system-level + TOGAF for enterprise alignment
- **Regulated** → ISO 42010 for formal compliance

---

## 7. Living Documentation

### Core Principle

Documentation lives alongside code in version control, uses plain text formats, and is built/deployed through CI/CD. Architecture diagrams stay current because they're generated from models or updated in the same PRs as code changes.

### Patterns for Keeping Docs in Sync

| Pattern | Tool | How It Works |
|---------|------|-------------|
| **Model-based diagrams** | Structurizr | Single DSL model generates all diagram types; change the model = change all diagrams |
| **Infrastructure-from-code** | Diagrams (Python) | Python code generates infrastructure diagrams; run in CI |
| **Auto-discovery** | Hava | Auto-generates diagrams from live cloud accounts; always up-to-date |
| **AI-powered** | DocBot, Claude+Excalidraw MCP | Auto-generates/updates READMEs, API references, Mermaid diagrams from codebase analysis |
| **Docs-in-portal** | Backstage TechDocs | Markdown alongside code, built via MkDocs, published to Backstage |

### Living Documentation Checklist

- [ ] Architecture diagrams stored as code (Mermaid, D2, Structurizr DSL)
- [ ] ADRs in `docs/decisions/` tracked in Git
- [ ] API docs auto-generated from OpenAPI specs
- [ ] Docs CI/CD pipeline rebuilds on push
- [ ] Stale documentation alerts (pages not updated in > 6 months)
- [ ] Documentation freshness indicators on every page

---

## 8. Sequence Diagrams

### Tool Comparison

| Tool | Strength | Best For |
|------|----------|----------|
| **Mermaid** | Simplest syntax, GitHub-native | Most use cases in 2025+ |
| **PlantUML** | Most powerful, strict UML compliance | Complex interactions with advanced features |
| **ZenUML** | Purpose-built, code-like syntax, OMG UML 2.5.1 compliant | Dedicated sequence diagrams; Confluence/JetBrains/VS Code |
| **D2** | Clean syntax, part of broader diagramming | When already using D2 |
| **Structurizr** | Dynamic diagrams showing flows through distributed systems | When using C4/Structurizr |

### Sequence Diagram Best Practices

- Document critical flows: authentication, checkout, error handling, data sync
- One scenario per diagram — don't overload
- Show system boundaries clearly (which service handles what)
- Include error/alternative paths as separate diagrams or alt blocks
- Use activation bars to show processing time
- Label messages with specific API calls or event names, not generic descriptions
- Store alongside the code they document; reference from ADRs and design docs

---

## 9. Architecture Visualization and Portals

### Backstage TechDocs

Spotify's internal developer portal framework. TechDocs provides docs-as-code integrated into Backstage:

- Markdown files alongside code, rendered via MkDocs
- Software Catalog shows service dependencies, ownership, and metadata
- Catalog Graph visualizes entity relationships
- CI/CD generates docs and stores in external storage (S3/GCS)
- New Backend System reached 1.0 stable (Sep 2024)

### Other Visualization Tools

| Tool | Purpose |
|------|---------|
| **IcePanel** | Interactive C4 drill-down with flow overlays |
| **Port.io** | Internal developer portal with C4-style visualization |
| **Hava** | Auto-generated cloud infrastructure diagrams |
| **Cloudcraft** | AWS architecture auto-discovery and diagramming |

### Portal Selection

- Already using Backstage → TechDocs for docs + Catalog for service visualization
- Enterprise wanting C4 navigation → IcePanel
- Need auto-generated cloud diagrams → Hava or Cloudcraft
- Building internal developer portal → Backstage (open-source) or Port.io (managed)

---

## 10. Decision Matrices and Trade-Off Analysis

### Decision Matrix Framework

A structured method for evaluating options against weighted criteria:

1. **Identify criteria** (5-8 is the sweet spot): performance, scalability, development time, operational complexity, team familiarity, cost, vendor lock-in risk, security posture
2. **Assign weights** reflecting relative importance to the specific decision
3. **Score each option** against each criterion (1-5 scale)
4. **Calculate weighted totals**
5. **Document the matrix** as part of the ADR or design doc

**Example:**

| Criterion | Weight | Option A (PostgreSQL) | Option B (DynamoDB) | Option C (MongoDB) |
|-----------|--------|----------------------|--------------------|--------------------|
| Query flexibility | 5 | 5 (25) | 2 (10) | 4 (20) |
| Operational complexity | 4 | 3 (12) | 5 (20) | 3 (12) |
| Team familiarity | 3 | 5 (15) | 2 (6) | 3 (9) |
| Scale characteristics | 4 | 3 (12) | 5 (20) | 4 (16) |
| Cost at projected scale | 3 | 4 (12) | 3 (9) | 4 (12) |
| **Total** | | **76** | **65** | **69** |

### Integration with ADRs

The decision matrix becomes the "Considered Options" section of an ADR, providing quantitative evidence for the chosen option. This combination (ADR + matrix) is the best-in-class approach for documenting architectural decisions with evidence.

### Best Practices

- Document the matrix within the ADR, not as a separate document
- Include qualitative notes alongside numerical scores — numbers alone miss nuance
- Have multiple team members score independently, then discuss disagreements
- Re-score when significant new information emerges
- Don't force false precision — if two options score within 10%, the decision is genuinely close

---

## 11. Architecture Governance

### Fitness Functions

Objective, automated integrity checks on architectural characteristics. From "Building Evolutionary Architectures" (Ford, Parsons, Kua — O'Reilly, 2nd Edition).

| Tool | Language | Purpose |
|------|----------|---------|
| **ArchUnit** | Java | Unit tests for architecture rules: package dependencies, class relationships, naming, layer isolation |
| **NetArchTest** | .NET | Fluent API for .NET architecture rules in unit tests |
| **dependency-cruiser** | JavaScript/TypeScript | Validates and visualizes dependency graphs |
| **jMolecules** | Java | Structural fitness functions for DDD patterns |

### Governance Documentation

- Document architectural principles and constraints in ADRs
- Encode constraints as automated fitness functions in CI
- Architecture review checklist for PRs touching boundaries (API contracts, service interactions)
- Regular architecture review meetings (monthly or quarterly) with documented outcomes

### Trends (2025-2026)

- **Declarative architecture**: distilling decisions into machine-enforceable guardrails
- **AI-assisted governance**: AI helps teams make informed local decisions within clear guardrails
- **Architects as coaches**: in scaling teams, architects shift from decision-makers to coaches who challenge assumptions and enable safe autonomy

---

## 12. Cloud Architecture Diagrams

### Tool Categories

**Auto-generated from live infrastructure:**

| Tool | Clouds | Key Feature |
|------|--------|-------------|
| **Hava** | AWS, GCP, Azure, K8s | Connects to cloud accounts, auto-generates diagrams that stay current |
| **Cloudcraft** | AWS (primary) | Auto-creates from AWS account, drag-and-drop editor |
| **Hyperglance** | AWS, Azure, GCP | Auto-discovers and diagrams infrastructure |
| **Brainboard** | AWS, Azure, GCP, OCI | Drag-and-drop + instant Terraform generation; $99/user/month |

**Code-based:**

| Tool | Approach |
|------|----------|
| **Diagrams (Python)** | Python code generates diagrams with AWS/Azure/GCP/K8s icons; requires Graphviz; version-controllable |
| **Structurizr** | DSL with cloud provider themes |
| **D2** | Text-based with cloud icon support |

**Manual/visual:**

| Tool | Notes |
|------|-------|
| **draw.io** | Most comprehensive icon sets; free; Network 2025 shape library |
| **Lucidchart** | Enterprise; AWS/Azure/GCP templates; real-time AWS import |

### Cloud Diagram Best Practices

- Use auto-generated diagrams for accuracy; manual diagrams for simplified stakeholder views
- Layer diagrams at different abstraction levels: infrastructure, network, application
- Include data flow directions, security boundaries, and availability zones
- Follow cloud provider well-architected frameworks (AWS, Azure, GCP)
- Version control diagram source files — use code-based tools when possible
- Include cost annotations for significant infrastructure components
