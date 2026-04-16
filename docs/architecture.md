# ETYB Skills -- Architecture

## Overview

ETYB Skills is a virtual engineering company implemented as a system of 30 coordinated AI agent skills. It covers the full software development lifecycle -- from research and discovery through operations and monitoring -- with mandatory quality gates, process protocols, and ETYB enforcing engineering discipline at every stage.

## System Architecture

```
+-----------------------------------------------------------------------------+
|                          PROCESS LAYER                                       |
|  +----------+  +----------+  +-----------+  +----------+  +----------+      |
|  |  DESIGN  |->|   PLAN   |->| IMPLEMENT |->|  VERIFY  |->|   SHIP   |     |
|  |   Gate   |  |   Gate   |  |   Gate    |  |   Gate   |  |   Gate   |     |
|  +----------+  +----------+  +-----------+  +----------+  +----------+      |
+-----------------------------------------------------------------------------+
|                     PROCESS PROTOCOLS (always-on)                            |
|  tdd . verification . review . plan-execution . brainstorm . branch-safety  |
|  subagent-coordination . self-improvement . debugging                       |
+-----------------------------------------------------------------------------+
|                            +---------------------+                          |
|                            |         ETYB         |                          |
|                            |  (Process-Enforcing  |                          |
|                            |   CTO / Router)      |                          |
|                            +----------+----------+                          |
|                                       |                                     |
|        +----------+----------+--------+-------+----------+----------+       |
|        v          v          v                v          v          v       |
|   +---------++---------++---------+   +---------++---------++---------+    |
|   |Research &||Design & ||  Dev    |   |  Test & || DevOps &||  SRE &  |   |
|   |Discovery||Architect||  Teams  |   |   QA    ||  Infra  ||  Ops    |   |
|   +---------++---------++---------+   +---------++---------++---------+    |
|        |          |          |               |          |          |        |
|        |          |     +----+----+          |          |          |        |
|        |          |     v    v    v          |          |          |        |
|        |          |  Front  Back  DB &       |          |          |        |
|        |          |  end    end   Data       |          |          |        |
|        |          |               Mobile     |          |          |        |
|        |          |               AI/ML      |          |          |        |
|        |          |                          |          |          |        |
|   +----+----------+------- ------------------+----------+----------+---+    |
|   |                    CROSS-CUTTING TEAMS                             |    |
|   |         Security  .  Documentation  .  Code Review                 |    |
|   +---------+----------------------------------------------------------+    |
|                                                                             |
|   Quality Gates: qa-engineer (TDD), security-engineer (auto-consult),      |
|                  code-reviewer (mandatory review)                           |
+-----------------------------------------------------------------------------+
```

## Core Concepts

**ETYB** -- The process-enforcing CTO. Classifies request complexity into tiers (Tier 0-4), mandates the right domain experts, enforces phase gates, and tracks plan state. It does not perform work directly; it routes, coordinates, and enforces.

**Domain Experts** -- Team leads with broad domain knowledge. Each domain expert delegates to specialist sub-skills for deep, targeted work. They participate in the plan lifecycle and coordinate handoffs with other teams.

**Sub-Skills** -- Specialists with deep expertise in a single area. They perform the actual work -- writing code, designing schemas, configuring pipelines, auditing security. Each sub-skill contains production-proven patterns, decision matrices, and tool-specific guidance.

**Quality Gates** -- Three mandatory checkpoints that cannot be bypassed:
- **QA Engineer** enforces TDD -- no code ships without test coverage.
- **Security Engineer** auto-consults on authentication, PII, payments, infrastructure, database, and healthcare work.
- **Code Reviewer** blocks the Ship gate until review is complete.

**Process Layer** -- A 5-gate lifecycle (Design, Plan, Implement, Verify, Ship) that wraps every non-trivial project. Living plan artifacts default to `.etyb/plans/`, with Claude-specific plan-mode overrides handled by its adapter.

## SDLC Phase Coverage

| Phase | Responsible Team |
|-------|-----------------|
| Research and Discovery | Research Analyst |
| Requirements and Planning | Project Planner |
| Design and Architecture | System Architect, Frontend Architect, Backend Architect |
| Development | Frontend, Backend, Database, Mobile, AI/ML |
| Testing and QA | QA Engineer |
| Build, Deploy, and Release | DevOps Engineer |
| Operations and Monitoring | SRE Engineer |
| Maintenance and Optimization | SRE + Security + relevant dev team |
| Cross-cutting: Security | Security Engineer |
| Cross-cutting: Documentation | Technical Writer |
| Cross-cutting: Code Quality | Code Reviewer |

## Skill Reference

### ETYB

**`etyb`** -- `skills/etyb/`

The top-level agent. It parses user intent, routes to the correct team (or multiple teams for cross-cutting tasks), coordinates handoffs, tracks project context across sessions, and enforces the process layer. It classifies every request by tier and mandates the appropriate experts and gates.

---

### Research and Discovery

**`research-analyst`** -- `skills/research-analyst/`

Phase: Research and Discovery

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `tech-researcher` | Technology Evaluator | Evaluates frameworks, libraries, and cloud services. Produces comparison matrices with pros, cons, and benchmarks. |
| `competitive-analyst` | Competitive Intelligence | Analyzes competitor products, architectures, and tech stacks. Reverse-engineers public technical content. |
| `feasibility-analyst` | Feasibility and Risk | Assesses technical feasibility, estimates complexity, identifies risks and unknowns. |
| `requirements-analyst` | Requirements Engineer | Translates business requirements into technical requirements. Produces BRDs and TRDs. Identifies edge cases and ambiguities. |

---

### Design and Architecture

**`system-architect`** -- `skills/system-architect/`

Phase: Design and Architecture

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `solution-architect` | End-to-End Design | Produces full system designs: components, data flow, API contracts, deployment topology. |
| `domain-modeler` | Domain-Driven Design | Bounded contexts, aggregates, domain events, ubiquitous language for complex business domains. |
| `api-designer` | API-First Design | Designs REST, GraphQL, and gRPC APIs. Produces OpenAPI specs, schema definitions, and versioning strategies. |
| `integration-architect` | System Integration | API gateways, event buses, webhooks, third-party integrations, ETL pipelines. |
| `data-architect` | Data Modeling | ERDs, data flow diagrams, storage strategy, data lifecycle, and migration planning. |

---

### Frontend Engineering

**`frontend-architect`** -- `skills/frontend-architect/`

Phase: Architecture and Development

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `react-stack` | React / Next.js Expert | React ecosystem, Next.js, state management, server components. |
| `angular-stack` | Angular Expert | Angular architecture, RxJS, NgRx, Angular ecosystem. |
| `vue-specialist` | Vue / Nuxt Expert | Vue 3 composition API, Nuxt 3, Pinia, Vue ecosystem. |
| `svelte-specialist` | Svelte / SvelteKit Expert | SvelteKit, runes, compile-time reactivity, Svelte ecosystem. |
| `seo-specialist` | SEO Engineering | Technical SEO, structured data, crawl optimization, Core Web Vitals. |
| `architecture-patterns` | Frontend Architecture | Micro-frontends, module federation, rendering strategies, state management patterns. |
| `ui-ux-engineer` | Design Systems | Component libraries, design tokens, Storybook, Figma-to-code, accessibility patterns. |
| `web-performance` | Performance Engineer | Core Web Vitals, bundle analysis, runtime performance, memory profiling, Lighthouse optimization. |
| `accessibility-specialist` | Accessibility Expert | WCAG 2.2 compliance, screen reader testing, ARIA patterns, keyboard navigation, focus management. |

---

### Backend Engineering

**`backend-architect`** -- `skills/backend-architect/`

Phase: Architecture and Development

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `java-stack` | Java / Spring Expert | Spring Boot, Spring Cloud, JVM performance, enterprise Java patterns. |
| `typescript-stack` | TypeScript / Node.js Expert | Node.js runtime, NestJS, Express, TypeScript patterns, serverless. |
| `go-stack` | Go Expert | Go concurrency, standard library, microservice patterns, performance. |
| `python-stack` | Python Expert | Django, FastAPI, Flask, async Python, scientific computing integration. |
| `rust-specialist` | Rust Expert | Systems programming, Actix/Axum, memory safety, performance-critical services. |
| `architecture-patterns` | Backend Architecture | Distributed systems patterns, CQRS, event sourcing, hexagonal architecture. |
| `api-developer` | API Implementation | REST, GraphQL, and gRPC implementation, middleware, validation, error handling, rate limiting. |
| `microservices-specialist` | Distributed Systems | Service decomposition, service mesh, inter-service communication, saga patterns, circuit breakers. |
| `auth-specialist` | Authentication and Authorization | OAuth2, OIDC, SAML, JWT, RBAC/ABAC, session management, SSO, MFA implementation. |

---

### Database Engineering

**`database-architect`** -- `skills/database-architect/`

Phase: Architecture and Development

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `sql-specialist` | Relational DB Expert | PostgreSQL, MySQL, SQL Server. Schema design, indexing, query optimization, partitioning, replication. |
| `nosql-specialist` | NoSQL Expert | MongoDB, DynamoDB, Cassandra/ScyllaDB. Document modeling, partition key design, consistency tradeoffs. |
| `cache-specialist` | Caching Expert | Redis, Memcached, CDN caching. Cache invalidation strategies, cache-aside/write-through/write-behind patterns. |
| `search-specialist` | Search Engine Expert | Elasticsearch, OpenSearch, Meilisearch, Typesense. Index design, relevance tuning, faceted search. |
| `data-pipeline` | Data Engineering | ETL/ELT pipelines, Kafka/Flink/Spark, CDC, data lake design, batch vs streaming. |
| `migration-specialist` | Schema Migrations | Zero-downtime migrations, data backfill strategies, blue-green database deployments, version control for schemas. |

---

### Mobile Engineering

**`mobile-architect`** -- `skills/mobile-architect/`

Phase: Architecture and Development

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `react-native-specialist` | React Native / Expo | Cross-platform with React Native, Expo Router, native modules, Hermes engine, EAS Build. |
| `flutter-specialist` | Flutter / Dart | Flutter architecture, Riverpod/Bloc, platform channels, Dart patterns. |
| `ios-specialist` | iOS Native | Swift, SwiftUI, UIKit, Combine, Core Data, App Store guidelines. |
| `android-specialist` | Android Native | Kotlin, Jetpack Compose, Room, Coroutines, Play Store guidelines. |
| `mobile-performance` | Mobile Performance | App size optimization, startup time, battery usage, memory profiling, offline-first patterns. |

---

### AI and Machine Learning

**`ai-ml-engineer`** -- `skills/ai-ml-engineer/`

Phase: Architecture and Development (specialized)

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `ml-engineer` | Model Development | Feature engineering, model training, evaluation metrics, experiment tracking (MLflow/W&B). |
| `mlops-specialist` | ML Operations | Model serving, A/B testing models, monitoring drift, CI/CD for ML. |
| `llm-specialist` | LLM and GenAI | Prompt engineering, RAG pipelines, fine-tuning, evaluation frameworks, vector databases, embedding strategies. |
| `data-scientist` | Data Science | Statistical analysis, experimentation design, A/B test analysis, feature importance, data exploration. |
| `ai-integration` | AI Product Integration | Embedding AI into products, API design for AI features, latency optimization, fallback strategies, cost management. |

---

### Testing and Quality Assurance

**`qa-engineer`** -- `skills/qa-engineer/`

Phase: Testing and QA | Quality Gate: TDD Enforcement

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `unit-test-specialist` | Unit Testing | TDD/BDD patterns, mocking strategies, test isolation, coverage analysis. Jest, Vitest, JUnit, pytest, Go testing. |
| `integration-test-specialist` | Integration Testing | API testing, contract testing (Pact), database integration tests, testcontainers. |
| `e2e-test-specialist` | End-to-End Testing | Playwright, Cypress, Selenium. Page object patterns, visual regression, flaky test management. |
| `performance-test-specialist` | Load and Performance | k6, JMeter, Locust, Artillery. Load testing, stress testing, soak testing, benchmarking. |
| `api-test-specialist` | API Testing | REST and GraphQL test automation, schema validation, Postman/Newman, REST Assured. |
| `test-strategy-architect` | Test Strategy | Test pyramid design, shift-left testing, CI integration, test data management, environment strategy. |

---

### DevOps and Infrastructure

**`devops-engineer`** -- `skills/devops-engineer/`

Phase: Build, Deploy, and Release

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `ci-cd-engineer` | CI/CD Pipelines | GitHub Actions, GitLab CI, Jenkins, CircleCI, ArgoCD. Pipeline design, caching, parallelization, deployment gates. |
| `container-specialist` | Containerization | Docker multi-stage builds, image optimization, container security scanning, OCI standards. |
| `kubernetes-specialist` | Orchestration | Kubernetes architecture, Helm charts, operators, service mesh, autoscaling, resource management. |
| `cloud-aws-specialist` | AWS Expert | EC2, ECS/EKS, Lambda, RDS, S3, CloudFront, VPC, IAM, Well-Architected Framework. |
| `cloud-gcp-specialist` | GCP Expert | GKE, Cloud Run, Cloud SQL, BigQuery, Pub/Sub, Cloud Functions, GCP networking. |
| `cloud-azure-specialist` | Azure Expert | AKS, Azure Functions, Cosmos DB, Azure DevOps, Azure networking. |
| `iac-specialist` | Infrastructure as Code | Terraform, Pulumi, CloudFormation, CDK. Module design, state management, drift detection. |
| `release-engineer` | Release Management | Blue-green deployments, canary releases, feature flags, rollback strategies, GitOps. |

---

### Security

**`security-engineer`** -- `skills/security-engineer/`

Phase: Cross-cutting (all phases) | Quality Gate: Auto-consultation

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `appsec-specialist` | Application Security | OWASP Top 10, SAST/DAST tooling, dependency scanning, secure coding patterns. |
| `infra-security-specialist` | Infrastructure Security | Network security, WAF configuration, DDoS protection, security groups, zero-trust architecture. |
| `iam-specialist` | Identity and Access | OAuth2/OIDC/SAML implementation, RBAC/ABAC design, session management, SSO, MFA. |
| `compliance-specialist` | Compliance and Governance | SOC2, GDPR, HIPAA, PCI-DSS. Audit readiness, data classification, retention policies, privacy by design. |
| `secret-management` | Secrets and Keys | HashiCorp Vault, AWS Secrets Manager, key rotation, certificate management, environment variable hygiene. |
| `security-reviewer` | Security Review | Threat modeling (STRIDE), security architecture review, penetration test planning, vulnerability assessment. |

---

### Site Reliability Engineering

**`sre-engineer`** -- `skills/sre-engineer/`

Phase: Operations, Monitoring, and Maintenance

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `monitoring-specialist` | Monitoring and Alerting | Prometheus, Grafana, Datadog, CloudWatch, PagerDuty. Dashboard design, alert tuning, SLO/SLI/SLA definition. |
| `logging-specialist` | Logging and Analysis | ELK/EFK stack, structured logging, log aggregation, correlation IDs, log-based alerting. |
| `tracing-specialist` | Distributed Tracing | OpenTelemetry, Jaeger, Zipkin, Tempo. Trace propagation, span design, performance bottleneck identification. |
| `incident-response` | Incident Management | Runbook creation, on-call processes, incident classification, postmortem writing, escalation procedures. |
| `capacity-planner` | Capacity and Cost | Auto-scaling policies, resource right-sizing, cost optimization, reserved instance strategy, FinOps. |
| `chaos-engineer` | Resilience Testing | Chaos Monkey, Litmus, fault injection, game days, resilience validation, failure mode analysis. |

---

### Technical Writing

**`technical-writer`** -- `skills/technical-writer/`

Phase: Cross-cutting (all phases)

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `api-doc-specialist` | API Documentation | OpenAPI/Swagger specs, API reference generation, developer portal design, code examples. |
| `architecture-doc` | Architecture Docs | ADRs, C4 diagrams, technical design docs, RFC templates. |
| `user-doc-specialist` | User Documentation | User guides, tutorials, onboarding flows, knowledge base articles. |
| `runbook-writer` | Operational Docs | Runbooks, troubleshooting guides, incident response playbooks, operational procedures. |

---

### Project Planning

**`project-planner`** -- `skills/project-planner/`

Phase: Requirements and Planning

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `sprint-planner` | Sprint Planning | Story breakdown, estimation, sprint capacity planning, velocity tracking. |
| `technical-pm` | Technical PM | Project timeline, dependency mapping, risk register, milestone tracking, stakeholder communication. |
| `agile-coach` | Process Expert | Scrum/Kanban setup, retrospective facilitation, process improvement, team health metrics. |

---

### Code Review

**`code-reviewer`** -- `skills/code-reviewer/`

Phase: Cross-cutting (during development) | Quality Gate: Mandatory Review

| Sub-skill | Role | Description |
|-----------|------|-------------|
| `code-quality` | Quality Analysis | Code smells, SOLID principles, DRY/KISS, complexity analysis, refactoring recommendations. |
| `performance-reviewer` | Performance Review | Algorithmic complexity, memory leaks, N+1 queries, unnecessary re-renders, profiling guidance. |
| `security-reviewer` | Security Review | Injection vulnerabilities, auth flaws, sensitive data exposure, dependency risks. |
| `architecture-reviewer` | Architecture Review | Pattern adherence, separation of concerns, coupling analysis, technical debt identification. |

---

### Domain-Specific Architects

Specialized teams activated when building specific types of products. They complement the core teams above.

| Skill | Folder | Coverage |
|-------|--------|----------|
| `social-platform-architect` | `skills/social-platform-architect/` | Feed systems, fan-out, social graphs, real-time delivery, content ranking |
| `e-commerce-architect` | `skills/e-commerce-architect/` | Product catalogs, cart/checkout, payments, inventory, order management |
| `fintech-architect` | `skills/fintech-architect/` | Ledger systems, payment processing, compliance (PCI/PSD2), fraud detection |
| `saas-architect` | `skills/saas-architect/` | Multi-tenancy, billing/subscriptions, onboarding, usage metering, tenant isolation |
| `real-time-architect` | `skills/real-time-architect/` | WebSocket systems, gaming backends, collaboration tools, live streaming, chat |
| `healthcare-architect` | `skills/healthcare-architect/` | HIPAA compliance, HL7/FHIR, EHR integration, patient data, audit trails |

---

## Process Protocols

Nine always-on engineering disciplines govern how work gets done. Their principles are embedded in ETYB; deep reference knowledge is loaded on demand.

| Protocol | Folder | Scope | Description |
|----------|--------|-------|-------------|
| TDD Protocol | `skills/tdd-protocol/` | All code-producing work | Red-green-refactor cycle, rationalization counters, TDD patterns. Claude has deterministic hooks; Codex adds prompt/Bash guardrails; Antigravity stays model-trusted. |
| Subagent Protocol | `skills/subagent-protocol/` | Parallel and delegated work | Dispatch patterns, parallel coordination, two-stage review, context isolation. Platform mechanics come from adapters or project runtime, not the protocol itself. |
| Git Workflow Protocol | `skills/git-workflow-protocol/` | Branch management | Worktree management, branch finishing, parallel development. Claude blocks merges with a hook; Codex adds Bash merge guards; Antigravity is model-trusted. |
| Plan Execution Protocol | `skills/plan-execution-protocol/` | Any active plan | Task execution cycle, blocker management, gate transitions. Portable default is `.etyb/plans/`; Claude may override through native plan mode. |
| Brainstorm Protocol | `skills/brainstorm-protocol/` | Ambiguous or exploratory requests | Exploration techniques, convergence patterns, design brief templates. |
| Review Protocol | `skills/review-protocol/` | Code review lifecycle | Review dispatch, feedback evaluation, review integration. Hooks: `pre-commit-review-check` verifies review before commit. |
| Skill Evolution Protocol | `skills/skill-evolution-protocol/` | Skill creation and improvement | Skill creation, eval engineering, improvement loop, institutional memory. |
| Verification Protocol | `skills/verification-protocol/` | Every completion claim | Five verification questions, completion report format, done criteria per gate, evidence standards. |
| Debugging Protocol | `skills/debugging-protocol/` | Active troubleshooting | Root-cause methodology, hypothesis-driven debugging, one-variable rule, 3-failure escalation. |

## Process Architecture

### Five-Gate Lifecycle

Every non-trivial project passes through five gates, each with defined entry and exit criteria:

1. **Design Gate** -- Problem understood, constraints identified, approach selected. Mandatory experts consulted for sensitive domains.
2. **Plan Gate** -- Tasks decomposed, dependencies mapped, test strategy defined. Living plan artifact created in `.etyb/plans/` unless a platform adapter explicitly overrides it.
3. **Implement Gate** -- Code written test-first, plan tracked task-by-task, blockers surfaced immediately.
4. **Verify Gate** -- All tests green, verification protocol completed, experts re-consulted. Evidence collected for every claim.
5. **Ship Gate** -- Code reviewed, security signed off, documentation updated. No merge without green tests.

### Tier Classification

ETYB classifies every request by complexity:

- **Tier 0** -- Direct answer, no code involved.
- **Tier 1** -- Single-file change, one domain expert.
- **Tier 2** -- Multi-file change, requires a plan.
- **Tier 3** -- Cross-team coordination, multiple experts, full gate lifecycle.
- **Tier 4** -- System-level change, architectural decisions, all gates enforced with mandatory expert consultation.

### Verification Protocol

A universal framework applied at every gate:

1. What was done?
2. How was it verified?
3. What tests cover it?
4. What edge cases were considered?
5. What could go wrong?

Each domain expert applies role-specific checklists on top of this framework -- database experts check query plans, frontend experts check Lighthouse scores, healthcare experts check HIPAA compliance.

### Coordination Model

| Role | Behavior |
|------|----------|
| ETYB | Classifies tiers, mandates experts, enforces gates, blocks progression without exit criteria |
| QA Engineer | Blocks Ship without test coverage, enforces TDD at Plan gate |
| Security Engineer | Auto-consulted on auth, PII, payments, infrastructure; blocks Ship without security sign-off |
| Code Reviewer | Mandatory review before Ship gate passes |
| Project Planner | Creates and maintains plan artifacts, assesses gate readiness |
| Technical Writer | Decision logs, ADRs as plan artifacts, documentation assigned per gate |
| All other skills | Read active plan, respect gate boundaries, follow verification protocol, use debugging protocol |

## Platform Runtime Surface

| Platform | Runtime Contract |
|----------|------------------|
| Claude Code | Flagship. Deterministic hooks, native `.claude/plans/` integration, isolated subagent runtime support. |
| OpenAI Codex | Project-scoped `.codex/` config, lifecycle hooks (`UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`), custom agents in `.codex/agents/`, portable plans at `.etyb/plans/`. |
| Google Antigravity | Markdown-first and model-trusted. Portable plans at `.etyb/plans/`. ADK remains a documented future path, not a shipped runtime in this repo. |

## Design Principles

1. **Conversational first** -- Skills ask questions before giving answers. No prescriptive dumps.
2. **Tradeoff-oriented** -- Present options with pros and cons. Let the user decide.
3. **Production-proven** -- Reference real-world implementations, not textbook theory.
4. **Current** -- Ecosystems change fast. Advice is verified against the latest state of the art.
5. **Cross-referencing** -- Skills know their boundaries and defer to other skills when appropriate.
6. **Scale-aware** -- Different advice for a 3-person startup vs a 200-person enterprise.
7. **Process-aware** -- Every skill participates in the plan lifecycle, follows the verification protocol, and respects gate boundaries.

## Inventory Summary

- **1** ETYB (process-enforcing CTO and router)
- **14** core domain expert teams with approximately 80 specialist sub-skills
- **6** domain-specific architects for vertical product categories
- **9** process protocols
- **3** mandatory quality gates (TDD, security, code review)
- **5-gate lifecycle** covering Design through Ship
- **9** always-on engineering disciplines embedded in ETYB
- **3 platform modes**: Claude flagship, Codex partial runtime-enforced, Antigravity markdown-first
