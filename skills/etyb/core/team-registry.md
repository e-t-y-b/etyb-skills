# Team Registry — The 20 Specialists

## Core Teams (14)

| # | Team | Skill | SDLC Phase | What They Own |
|---|------|-------|------------|---------------|
| 1 | Research & Discovery | `research-analyst` | Phase 0 | Technology evaluation, competitive analysis, feasibility studies, requirements engineering |
| 2 | Project Planning | `project-planner` | Phase 1 | Sprint planning, project timelines, agile processes, stakeholder communication |
| 3 | System Architecture | `system-architect` | Phase 2 | End-to-end system design, domain modeling, API design, integration architecture, data architecture |
| 4 | Frontend Engineering | `frontend-architect` | Phase 2-3 | React, Angular, Vue, Svelte, SEO, web performance, accessibility, UI/UX, design systems |
| 5 | Backend Engineering | `backend-architect` | Phase 2-3 | Java, TypeScript, Go, Python, Rust, API implementation, microservices, auth patterns |
| 6 | Database Engineering | `database-architect` | Phase 2-3 | SQL, NoSQL, caching, search, data pipelines, schema migrations |
| 7 | Mobile Engineering | `mobile-architect` | Phase 2-3 | React Native, Flutter, iOS native, Android native, mobile performance |
| 8 | AI/ML Engineering | `ai-ml-engineer` | Phase 2-3 | Model development, MLOps, LLM/GenAI, data science, AI product integration |
| 9 | Quality Assurance | `qa-engineer` | Phase 4 | Unit testing, integration testing, E2E testing, performance testing, API testing, test strategy |
| 10 | DevOps & Infrastructure | `devops-engineer` | Phase 5 | CI/CD, containers, Kubernetes, AWS/GCP/Azure, IaC, release management |
| 11 | Site Reliability | `sre-engineer` | Phase 6-7 | Monitoring, logging, tracing, incident response, capacity planning, chaos engineering |
| 12 | Security | `security-engineer` | Cross-cutting | AppSec, infrastructure security, IAM, compliance, secrets management, threat modeling |
| 13 | Documentation | `technical-writer` | Cross-cutting | API docs, architecture docs, user docs, runbooks |
| 14 | Code Quality | `code-reviewer` | Cross-cutting | Code quality, performance review, security review, architecture review |

## Domain-Specific Teams (6)

Bring these in when the user is building in their domain. They provide patterns and constraints that core teams don't have.

| # | Team | Skill | Domain |
|---|------|-------|--------|
| 15 | Social Platform | `social-platform-architect` | Feed systems, fan-out, social graphs, content ranking, real-time delivery |
| 16 | E-Commerce | `e-commerce-architect` | Product catalogs, cart/checkout, payments, inventory, order management |
| 17 | FinTech | `fintech-architect` | Ledger systems, payment processing, PCI/PSD2 compliance, fraud detection |
| 18 | SaaS Platform | `saas-architect` | Multi-tenancy, billing/subscriptions, onboarding, usage metering, tenant isolation |
| 19 | Real-Time Systems | `real-time-architect` | WebSockets, gaming backends, collaboration tools, live streaming, chat |
| 20 | Healthcare | `healthcare-architect` | HIPAA compliance, HL7/FHIR, EHR integration, patient data, audit trails |

## Domain Detection

| Signal in User's Request | Domain Team to Read |
|--------------------------|---------------------|
| Social feeds, followers, likes, content ranking, fan-out | `social-platform-architect` |
| Product catalog, shopping cart, checkout, payments, inventory | `e-commerce-architect` |
| Ledgers, transactions, payment processing, fraud, PCI | `fintech-architect` |
| Multi-tenant, subscriptions, billing, usage metering | `saas-architect` |
| WebSockets, real-time updates, collaboration, chat, gaming | `real-time-architect` |
| Patient data, HIPAA, HL7/FHIR, EHR, clinical workflows | `healthcare-architect` |
| ML models, training, inference, drift, embeddings, LLMs | `ai-ml-engineer` |

## Process Protocols (7)

Always-on engineering disciplines with deep reference knowledge. Principles are embedded in `core/always-on-protocols.md`. Read these skills when you need the detailed HOW.

| # | Protocol | Deep Knowledge For | Hooks |
|---|----------|--------------------|-------|
| 21 | `tdd-protocol` | Red-green-refactor patterns, rationalization counters, framework-specific TDD | pre-edit, post-test |
| 22 | `subagent-protocol` | Dispatch templates, parallel coordination, context isolation, two-stage review | — |
| 23 | `git-workflow-protocol` | Worktree management, branch finishing, parallel development | pre-merge |
| 24 | `plan-execution-protocol` | Task execution cycle, blocker management, gate transitions | post-edit |
| 25 | `brainstorm-protocol` | Exploration techniques, convergence patterns, design brief templates | — |
| 26 | `review-protocol` | Review dispatch, feedback evaluation, review integration | pre-commit |
| 27 | `skill-evolution-protocol` | Skill creation, eval engineering, improvement loops, institutional memory | — |

## Domain Overlap Resolution

When a request triggers multiple domain signals, use these rules to determine the **primary** vs **supporting** domain:

**Rule 1: The business domain leads, infrastructure domains support.**
`real-time-architect` is often a supporting concern rather than the primary domain. "Set up multi-tenant billing with real-time usage metering" → `saas-architect` leads (tenancy + billing are the business problem), `real-time-architect` supports (metering pipeline is the transport layer).

**Rule 2: Integration vs. system-building determines depth.**
"Add payment processing to my e-commerce site" → `e-commerce-architect` leads (payment integration into commerce flow). "Build a payment ledger system" → `fintech-architect` leads (financial system from scratch). The verb and scope matter: "add/integrate" = consumer-side skill leads; "build/design" = system-side skill leads.

**Rule 3: "Design the API" routing depends on the word after "API".**
- "Design the API contract/specification" → `system-architect` (API-first design, OpenAPI specs)
- "Implement the API endpoints" → `backend-architect` (framework, middleware, validation)
- "Design the API for mobile/frontend consumption" → `system-architect` leads, but read `mobile-architect` or `frontend-architect` for consumer constraints

**Rule 4: Production ML issues are AI/ML-first, not SRE-first.**
"Model drift in production" or "inference latency degradation" → `ai-ml-engineer` leads (MLOps domain expertise), `sre-engineer` supports (monitoring infrastructure). Generic production issues ("server is down", "memory leak") → `sre-engineer` leads.
