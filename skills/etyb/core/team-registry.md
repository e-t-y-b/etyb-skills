# Team Registry — The 20 Specialists

All 20 specialists live as internal references under `references/specialists/<name>/README.md` (core teams) or `references/verticals/<name>/README.md` (verticals). When the registry below points to a team, read `references/<library>/<name>/README.md` first.

## Core Teams (14) — `references/specialists/`

| # | Team | Reference | SDLC Phase | What They Own |
|---|------|-----------|------------|---------------|
| 1 | Research & Discovery | `references/specialists/research-analyst/` | Phase 0 | Technology evaluation, competitive analysis, feasibility studies, requirements engineering |
| 2 | Project Planning | `references/specialists/project-planner/` | Phase 1 | Sprint planning, project timelines, agile processes, stakeholder communication |
| 3 | System Architecture | `references/specialists/system-architect/` | Phase 2 | End-to-end system design, domain modeling, API design, integration architecture, data architecture |
| 4 | Frontend Engineering | `references/specialists/frontend-architect/` | Phase 2-3 | React, Angular, Vue, Svelte, SEO, web performance, accessibility, UI/UX, design systems |
| 5 | Backend Engineering | `references/specialists/backend-architect/` | Phase 2-3 | Java, TypeScript, Go, Python, Rust, API implementation, microservices, auth patterns |
| 6 | Database Engineering | `references/specialists/database-architect/` | Phase 2-3 | SQL, NoSQL, caching, search, data pipelines, schema migrations |
| 7 | Mobile Engineering | `references/specialists/mobile-architect/` | Phase 2-3 | React Native, Flutter, iOS native, Android native, mobile performance |
| 8 | AI/ML Engineering | `references/specialists/ai-ml-engineer/` | Phase 2-3 | Model development, MLOps, LLM/GenAI, data science, AI product integration |
| 9 | Quality Assurance | `references/specialists/qa-engineer/` | Phase 4 | Unit testing, integration testing, E2E testing, performance testing, API testing, test strategy |
| 10 | DevOps & Infrastructure | `references/specialists/devops-engineer/` | Phase 5 | CI/CD, containers, Kubernetes, AWS/GCP/Azure, IaC, release management |
| 11 | Site Reliability | `references/specialists/sre-engineer/` | Phase 6-7 | Monitoring, logging, tracing, incident response, capacity planning, chaos engineering |
| 12 | Security | `references/specialists/security-engineer/` | Cross-cutting | AppSec, infrastructure security, IAM, compliance, secrets management, threat modeling |
| 13 | Documentation | `references/specialists/technical-writer/` | Cross-cutting | API docs, architecture docs, user docs, runbooks |
| 14 | Code Quality | `references/specialists/code-reviewer/` | Cross-cutting | Code quality, performance review, security review, architecture review |

## Domain-Specific Teams (6) — `references/verticals/`

Bring these in when the user is building in their domain. They provide patterns and constraints that core teams don't have. Pro tier only.

| # | Team | Reference | Domain |
|---|------|-----------|--------|
| 15 | Social Platform | `references/verticals/social-platform-architect/` | Feed systems, fan-out, social graphs, content ranking, real-time delivery |
| 16 | E-Commerce | `references/verticals/e-commerce-architect/` | Product catalogs, cart/checkout, payments, inventory, order management |
| 17 | FinTech | `references/verticals/fintech-architect/` | Ledger systems, payment processing, PCI/PSD2 compliance, fraud detection |
| 18 | SaaS Platform | `references/verticals/saas-architect/` | Multi-tenancy, billing/subscriptions, onboarding, usage metering, tenant isolation |
| 19 | Real-Time Systems | `references/verticals/real-time-architect/` | WebSockets, gaming backends, collaboration tools, live streaming, chat |
| 20 | Healthcare | `references/verticals/healthcare-architect/` | HIPAA compliance, HL7/FHIR, EHR integration, patient data, audit trails |

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

## Process Protocols (9) — `references/protocols/`

Always-on engineering disciplines with deep reference knowledge. Principles are embedded in `core/session.md`. Read these references when you need the detailed HOW.

| # | Protocol | Reference | Deep Knowledge For | Hooks |
|---|----------|-----------|--------------------|-------|
| 21 | tdd-protocol | `references/protocols/tdd-protocol/` | Red-green-refactor patterns, rationalization counters, framework-specific TDD | pre-edit, post-test |
| 22 | subagent-protocol | `references/protocols/subagent-protocol/` | Dispatch templates, parallel coordination, context isolation, two-stage review | — |
| 23 | git-workflow-protocol | `references/protocols/git-workflow-protocol/` | Worktree management, branch finishing, parallel development | pre-merge |
| 24 | plan-execution-protocol | `references/protocols/plan-execution-protocol/` | Task execution cycle, blocker management, gate transitions | post-edit |
| 25 | brainstorm-protocol | `references/protocols/brainstorm-protocol/` | Exploration techniques, convergence patterns, design brief templates | — |
| 26 | review-protocol | `references/protocols/review-protocol/` | Review dispatch, feedback evaluation, review integration | pre-commit |
| 27 | skill-evolution-protocol | `references/protocols/skill-evolution-protocol/` | Skill creation, eval engineering, improvement loops, institutional memory | — |
| 28 | verification-protocol | `references/protocols/verification-protocol/` | Five verification questions, completion report format, done criteria per gate, evidence standards | — |
| 29 | debugging-protocol | `references/protocols/debugging-protocol/` | Root-cause methodology, hypothesis-driven debugging, one-variable rule, 3-failure escalation | — |

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
