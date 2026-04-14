# ETYB Skills — Master Plan

## Bird's-Eye View

```
                            ┌─────────────────────┐
                            │     ORCHESTRATOR     │
                            │  (Intent Router /    │
                            │   Project Manager)   │
                            └─────────┬───────────┘
                                      │
        ┌──────────┬──────────┬───────┴───────┬──────────┬──────────┐
        ▼          ▼          ▼               ▼          ▼          ▼
   ┌─────────┐┌─────────┐┌─────────┐   ┌─────────┐┌─────────┐┌─────────┐
   │Research &││Design & ││  Dev    │   │  Test & ││ DevOps &││  SRE &  │
   │Discovery││Architect││  Teams  │   │   QA    ││  Infra  ││  Ops    │
   └─────────┘└─────────┘└─────────┘   └─────────┘└─────────┘└─────────┘
        │          │          │               │          │          │
        │          │     ┌────┼────┐          │          │          │
        │          │     ▼    ▼    ▼          │          │          │
        │          │  Front  Back  DB &       │          │          │
        │          │  end    end   Data       │          │          │
        │          │               Mobile     │          │          │
        │          │               AI/ML      │          │          │
        │          │                          │          │          │
   ┌────┴──────────┴──────────────────────────┴──────────┴──────────┴────┐
   │                    CROSS-CUTTING TEAMS                              │
   │         Security  ·  Documentation  ·  Code Review                  │
   └─────────────────────────────────────────────────────────────────────┘
```

## The Concept

Think of this as a virtual engineering company:

- **Orchestrator** = CTO / VP Engineering — understands the intent of any request, knows which team(s) to pull in, coordinates across teams
- **Master Skills** = Team Leads — broad domain knowledge, delegates to specialists
- **Sub-Skills** = Specialists — deep expertise in one area, does the actual work

## SDLC Phase Coverage

| Phase | Team Responsible | Status |
|-------|-----------------|--------|
| 0. Research & Discovery | Research Analyst | NEW |
| 1. Requirements & Planning | Project Planner | NEW |
| 2. Design & Architecture | System Architect, Frontend Architect, Backend Architect | PARTIAL |
| 3. Development | Frontend, Backend, Database, Mobile, AI/ML | PARTIAL |
| 4. Testing & QA | QA Engineer | NEW |
| 5. Build, Deploy & Release | DevOps Engineer | NEW |
| 6. Operations & Monitoring | SRE Engineer | NEW |
| 7. Maintenance & Optimization | SRE + Security + relevant dev team | NEW |
| Cross-cutting: Security | Security Engineer | NEW |
| Cross-cutting: Documentation | Technical Writer | NEW |
| Cross-cutting: Code Quality | Code Reviewer | NEW |

---

## Master Skill #0: Orchestrator

**Folder:** `orchestrator/`

The top-level agent. It does NOT do work itself — it understands user intent and routes to the correct team(s). It can bring in multiple teams for cross-cutting tasks.

**Responsibilities:**
- Parse user intent (Are they asking for research? Architecture? A bug fix? A deployment?)
- Route to the correct master skill (or multiple skills for complex requests)
- Coordinate handoffs between teams (e.g., architect designs → developer implements → QA tests)
- Track project context across sessions

**Sub-skills:** None — this is the coordinator, not a specialist.

---

## Master Skill #1: Research Analyst

**Folder:** `research-analyst/`
**SDLC Phase:** 0 — Research & Discovery
**Analogy:** The team you bring in before writing a single line of code.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `tech-researcher` | Technology Evaluator | Evaluates frameworks, libraries, cloud services. Produces comparison matrices with pros/cons/benchmarks. Answers "should we use X or Y?" |
| `competitive-analyst` | Competitive Intelligence | Analyzes competitor products, architectures, and tech stacks. Reverse-engineers public technical blog posts and conference talks. |
| `feasibility-analyst` | Feasibility & Risk | Assesses whether a proposed approach is technically feasible, estimates complexity, identifies risks and unknowns. |
| `requirements-analyst` | Requirements Engineer | Translates business requirements into technical requirements. Produces BRDs → TRDs. Identifies edge cases and ambiguities. |

---

## Master Skill #2: System Architect

**Folder:** `system-architect/`
**SDLC Phase:** 2 — Design & Architecture
**Analogy:** The chief architect who designs the big picture before any team starts building.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `solution-architect` | End-to-End Design | Takes requirements and produces a full system design: components, data flow, API contracts, deployment topology. |
| `domain-modeler` | Domain-Driven Design | Bounded contexts, aggregates, domain events, ubiquitous language. For complex business domains. |
| `api-designer` | API-First Design | Designs REST/GraphQL/gRPC APIs. Produces OpenAPI specs, schema definitions, versioning strategies. |
| `integration-architect` | System Integration | Designs how systems talk to each other: API gateways, event buses, webhooks, third-party integrations, ETL pipelines. |
| `data-architect` | Data Modeling | ERDs, data flow diagrams, storage strategy (SQL vs NoSQL vs hybrid), data lifecycle, migration planning. |

---

## Master Skill #3: Frontend Architect ✅ EXISTS

**Folder:** `frontend-architect/` (already created)
**SDLC Phase:** 2-3 — Architecture + Development
**Status:** Exists with React, Angular, SEO, and architecture-patterns references.

### Current Sub-skills (references):
- `react-stack` ✅
- `angular-stack` ✅
- `seo-specialist` ✅
- `architecture-patterns` ✅

### Sub-skills to ADD:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `vue-specialist` | Vue/Nuxt Expert | Vue 3 composition API, Nuxt 3, Pinia, Vue ecosystem. |
| `svelte-specialist` | Svelte/SvelteKit Expert | SvelteKit, runes, compile-time reactivity, Svelte ecosystem. |
| `ui-ux-engineer` | Design Systems | Component libraries, design tokens, Storybook, Figma-to-code, accessibility patterns. |
| `web-performance` | Performance Engineer | Core Web Vitals deep-dive, bundle analysis, runtime performance, memory profiling, Lighthouse optimization. |
| `accessibility-specialist` | Accessibility Expert | WCAG 2.2 compliance, screen reader testing, ARIA patterns, keyboard navigation, focus management. |

---

## Master Skill #4: Backend Architect ✅ EXISTS

**Folder:** `backend-architect/` (already created)
**SDLC Phase:** 2-3 — Architecture + Development
**Status:** Exists with Java, TypeScript, Go, Python, and architecture-patterns references.

### Current Sub-skills (references):
- `java-stack` ✅
- `typescript-stack` ✅
- `go-stack` ✅
- `python-stack` ✅
- `architecture-patterns` ✅

### Sub-skills to ADD:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `rust-specialist` | Rust Expert | Systems programming, Actix/Axum, memory safety, performance-critical services. |
| `api-developer` | API Implementation | REST/GraphQL/gRPC implementation patterns, middleware, validation, error handling, rate limiting. |
| `microservices-specialist` | Distributed Systems | Service decomposition, service mesh (Istio/Linkerd), inter-service communication, saga patterns, circuit breakers. |
| `auth-specialist` | Authentication/Authorization | OAuth2, OIDC, SAML, JWT, RBAC/ABAC, session management, SSO, MFA implementation. |

---

## Master Skill #5: Database Architect

**Folder:** `database-architect/`
**SDLC Phase:** 2-3 — Architecture + Development
**Analogy:** The DBA team — they own data modeling, performance, migrations, and storage decisions.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `sql-specialist` | Relational DB Expert | PostgreSQL, MySQL, SQL Server. Schema design, indexing, query optimization, partitioning, replication. |
| `nosql-specialist` | NoSQL Expert | MongoDB, DynamoDB, Cassandra/ScyllaDB. Document modeling, partition key design, consistency tradeoffs. |
| `cache-specialist` | Caching Expert | Redis, Memcached, CDN caching. Cache invalidation strategies, cache-aside/write-through/write-behind patterns. |
| `search-specialist` | Search Engine Expert | Elasticsearch, OpenSearch, Meilisearch, Typesense. Index design, relevance tuning, faceted search. |
| `data-pipeline` | Data Engineering | ETL/ELT pipelines, Kafka/Flink/Spark, CDC (change data capture), data lake design, batch vs streaming. |
| `migration-specialist` | Schema Migrations | Zero-downtime migrations, data backfill strategies, blue-green database deployments, version control for schemas. |

---

## Master Skill #6: Mobile Architect

**Folder:** `mobile-architect/`
**SDLC Phase:** 2-3 — Architecture + Development
**Analogy:** The mobile engineering team.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `react-native-specialist` | React Native / Expo | Cross-platform with RN, Expo Router, native modules, Hermes engine, EAS Build. |
| `flutter-specialist` | Flutter / Dart | Flutter architecture, Riverpod/Bloc, platform channels, Dart patterns. |
| `ios-specialist` | iOS Native | Swift, SwiftUI, UIKit, Combine, Core Data, App Store guidelines. |
| `android-specialist` | Android Native | Kotlin, Jetpack Compose, Room, Coroutines, Play Store guidelines. |
| `mobile-performance` | Mobile Performance | App size optimization, startup time, battery usage, memory profiling, offline-first patterns. |

---

## Master Skill #7: QA Engineer

**Folder:** `qa-engineer/`
**SDLC Phase:** 4 — Testing & Quality Assurance
**Analogy:** The QA/testing team that ensures nothing ships broken.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `unit-test-specialist` | Unit Testing | TDD/BDD patterns, mocking strategies, test isolation, coverage analysis. Framework-specific: Jest, Vitest, JUnit, pytest, Go testing. |
| `integration-test-specialist` | Integration Testing | API testing, contract testing (Pact), database integration tests, testcontainers. |
| `e2e-test-specialist` | End-to-End Testing | Playwright, Cypress, Selenium. Page object patterns, visual regression, flaky test management. |
| `performance-test-specialist` | Load & Performance | k6, JMeter, Locust, Artillery. Load testing, stress testing, soak testing, benchmarking, profiling. |
| `api-test-specialist` | API Testing | REST/GraphQL test automation, schema validation, Postman/Newman, REST Assured. |
| `test-strategy-architect` | Test Strategy | Test pyramid design, shift-left testing, CI integration, test data management, environment strategy. |

---

## Master Skill #8: DevOps Engineer

**Folder:** `devops-engineer/`
**SDLC Phase:** 5 — Build, Deploy & Release
**Analogy:** The DevOps/platform engineering team.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `ci-cd-engineer` | CI/CD Pipelines | GitHub Actions, GitLab CI, Jenkins, CircleCI, ArgoCD. Pipeline design, caching, parallelization, deployment gates. |
| `container-specialist` | Containerization | Docker multi-stage builds, image optimization, container security scanning, OCI standards. |
| `kubernetes-specialist` | Orchestration | K8s architecture, Helm charts, operators, service mesh (Istio/Linkerd), autoscaling, resource management. |
| `cloud-aws-specialist` | AWS Expert | EC2, ECS/EKS, Lambda, RDS, S3, CloudFront, VPC, IAM, Well-Architected Framework. |
| `cloud-gcp-specialist` | GCP Expert | GKE, Cloud Run, Cloud SQL, BigQuery, Pub/Sub, Cloud Functions, GCP networking. |
| `cloud-azure-specialist` | Azure Expert | AKS, Azure Functions, Cosmos DB, Azure DevOps, Azure networking. |
| `iac-specialist` | Infrastructure as Code | Terraform, Pulumi, CloudFormation, CDK. Module design, state management, drift detection. |
| `release-engineer` | Release Management | Blue-green deployments, canary releases, feature flags (LaunchDarkly/Unleash), rollback strategies, GitOps. |

---

## Master Skill #9: Security Engineer

**Folder:** `security-engineer/`
**SDLC Phase:** Cross-cutting (all phases)
**Analogy:** The security team — involved from design through production.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `appsec-specialist` | Application Security | OWASP Top 10, SAST/DAST tooling, dependency scanning (Snyk/Dependabot), secure coding patterns. |
| `infra-security-specialist` | Infrastructure Security | Network security, WAF configuration, DDoS protection, security groups, zero-trust architecture. |
| `iam-specialist` | Identity & Access | OAuth2/OIDC/SAML implementation, RBAC/ABAC design, session management, SSO, MFA. |
| `compliance-specialist` | Compliance & Governance | SOC2, GDPR, HIPAA, PCI-DSS. Audit readiness, data classification, retention policies, privacy by design. |
| `secret-management` | Secrets & Keys | HashiCorp Vault, AWS Secrets Manager, key rotation, certificate management, environment variable hygiene. |
| `security-reviewer` | Security Review | Threat modeling (STRIDE), security architecture review, penetration test planning, vulnerability assessment. |

---

## Master Skill #10: SRE Engineer

**Folder:** `sre-engineer/`
**SDLC Phase:** 6-7 — Operations, Monitoring & Maintenance
**Analogy:** The SRE/operations team that keeps production running.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `monitoring-specialist` | Monitoring & Alerting | Prometheus, Grafana, Datadog, CloudWatch, PagerDuty. Dashboard design, alert tuning, SLO/SLI/SLA definition. |
| `logging-specialist` | Logging & Analysis | ELK/EFK stack, structured logging, log aggregation, correlation IDs, log-based alerting. |
| `tracing-specialist` | Distributed Tracing | OpenTelemetry, Jaeger, Zipkin, Tempo. Trace propagation, span design, performance bottleneck identification. |
| `incident-response` | Incident Management | Runbook creation, on-call processes, incident classification, postmortem writing, escalation procedures. |
| `capacity-planner` | Capacity & Cost | Auto-scaling policies, resource right-sizing, cost optimization, reserved instance strategy, FinOps. |
| `chaos-engineer` | Resilience Testing | Chaos Monkey, Litmus, fault injection, game days, resilience validation, failure mode analysis. |

---

## Master Skill #11: AI/ML Engineer

**Folder:** `ai-ml-engineer/`
**SDLC Phase:** 2-3 — Architecture + Development (specialized)
**Analogy:** The AI/ML team for intelligent features.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `ml-engineer` | Model Development | Feature engineering, model training, evaluation metrics, experiment tracking (MLflow/W&B). |
| `mlops-specialist` | ML Operations | Model serving (TorchServe, TFServing, Triton), A/B testing models, monitoring drift, CI/CD for ML. |
| `llm-specialist` | LLM & GenAI | Prompt engineering, RAG pipelines, fine-tuning, evaluation frameworks, vector databases, embedding strategies. |
| `data-scientist` | Data Science | Statistical analysis, experimentation design, A/B test analysis, feature importance, data exploration. |
| `ai-integration` | AI Product Integration | Embedding AI into products, API design for AI features, latency optimization, fallback strategies, cost management. |

---

## Master Skill #12: Technical Writer

**Folder:** `technical-writer/`
**SDLC Phase:** Cross-cutting (all phases)
**Analogy:** The documentation team.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `api-doc-specialist` | API Documentation | OpenAPI/Swagger specs, API reference generation, developer portal design, code examples. |
| `architecture-doc` | Architecture Docs | ADRs (Architecture Decision Records), C4 diagrams, technical design docs, RFC templates. |
| `user-doc-specialist` | User Documentation | User guides, tutorials, onboarding flows, knowledge base articles. |
| `runbook-writer` | Operational Docs | Runbooks, troubleshooting guides, incident response playbooks, operational procedures. |

---

## Master Skill #13: Project Planner

**Folder:** `project-planner/`
**SDLC Phase:** 1 — Requirements & Planning
**Analogy:** The PM/TPM team.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `sprint-planner` | Sprint Planning | Story breakdown, estimation (t-shirt/story points), sprint capacity planning, velocity tracking. |
| `technical-pm` | Technical PM | Project timeline, dependency mapping, risk register, milestone tracking, stakeholder communication. |
| `agile-coach` | Process Expert | Scrum/Kanban setup, retrospective facilitation, process improvement, team health metrics. |

---

## Master Skill #14: Code Reviewer

**Folder:** `code-reviewer/`
**SDLC Phase:** Cross-cutting (during development)
**Analogy:** The senior engineer who reviews every PR.

### Sub-skills:

| Sub-skill | Role | What It Does |
|-----------|------|-------------|
| `code-quality` | Quality Analysis | Code smells, SOLID principles, DRY/KISS, complexity analysis, refactoring recommendations. |
| `performance-reviewer` | Performance Review | Algorithmic complexity, memory leaks, N+1 queries, unnecessary re-renders, profiling guidance. |
| `security-reviewer` | Security Review | Injection vulnerabilities, auth flaws, sensitive data exposure, dependency risks. |
| `architecture-reviewer` | Architecture Review | Pattern adherence, separation of concerns, coupling analysis, technical debt identification. |

---

## Domain-Specific Architects (Specialized Teams)

These are brought in when building specific types of products. They complement the core teams above.

| Skill | Folder | Status | What It Covers |
|-------|--------|--------|----------------|
| `social-platform-architect` | `social-platform-architect/` | ✅ EXISTS | Feed systems, fan-out, social graphs, real-time delivery, content ranking |
| `e-commerce-architect` | `e-commerce-architect/` | NEW | Product catalogs, cart/checkout, payments, inventory, order management |
| `fintech-architect` | `fintech-architect/` | NEW | Ledger systems, payment processing, compliance (PCI/PSD2), fraud detection |
| `saas-architect` | `saas-architect/` | NEW | Multi-tenancy, billing/subscriptions, onboarding, usage metering, tenant isolation |
| `real-time-architect` | `real-time-architect/` | NEW | WebSocket systems, gaming backends, collaboration tools, live streaming, chat |
| `healthcare-architect` | `healthcare-architect/` | NEW | HIPAA compliance, HL7/FHIR, EHR integration, patient data, audit trails |

---

## Summary: Complete Skill Inventory

### Core Teams (14 master skills + 1 orchestrator)

| # | Master Skill | Sub-skills | Status | Priority |
|---|-------------|------------|--------|----------|
| 0 | `orchestrator` | — | NEW | P0 — Build last (needs all teams to exist first) |
| 1 | `research-analyst` | 4 sub-skills | DONE | P1 |
| 2 | `system-architect` | 5 sub-skills | DONE | P0 |
| 3 | `frontend-architect` | 5 new + 4 existing = 9 | DONE | P1 (groomed + 5 new sub-skills added) |
| 4 | `backend-architect` | 4 new + 5 existing = 9 | PARTIAL | P1 (groom existing + add new) |
| 5 | `database-architect` | 6 sub-skills | DONE | P0 |
| 6 | `mobile-architect` | 5 sub-skills | NEW | P1 |
| 7 | `qa-engineer` | 6 sub-skills | NEW | P0 |
| 8 | `devops-engineer` | 8 sub-skills | DONE | P0 |
| 9 | `security-engineer` | 6 sub-skills | DONE | P0 |
| 10 | `sre-engineer` | 6 sub-skills | NEW | P0 |
| 11 | `ai-ml-engineer` | 5 sub-skills | NEW | P1 |
| 12 | `technical-writer` | 4 sub-skills | NEW | P2 |
| 13 | `project-planner` | 3 sub-skills | NEW | P2 |
| 14 | `code-reviewer` | 4 sub-skills | NEW | P1 |

### Domain-Specific Teams (6 master skills)

| # | Master Skill | Status | Priority |
|---|-------------|--------|----------|
| 15 | `social-platform-architect` | ✅ EXISTS | Done (groom later) |
| 16 | `e-commerce-architect` | NEW | P2 |
| 17 | `fintech-architect` | NEW | P2 |
| 18 | `saas-architect` | NEW | P2 |
| 19 | `real-time-architect` | NEW | P2 |
| 20 | `healthcare-architect` | NEW | P3 |

### Totals

- **21 master skills** (including orchestrator)
- **~80 sub-skills** across all teams
- **3 already exist** (frontend-architect, backend-architect, social-platform-architect)
- **18 master skills to create**
- **~70 sub-skills to create**

---

## Execution Task List

Each task below = one dedicated session. Order follows priority and dependency.

### Wave 1 — Foundation (P0 Core Teams)

These are the essential teams that every engineering org needs. Without these, you can't build, deploy, or operate anything.

| Session | Task | Deliverable |
|---------|------|-------------|
| 1 | Create `system-architect` master skill + all 5 sub-skills | SKILL.md + 5 reference files |
| 2 | Create `database-architect` master skill + all 6 sub-skills | SKILL.md + 6 reference files |
| 3 | Create `devops-engineer` master skill + all 8 sub-skills | SKILL.md + 8 reference files |
| 4 | Create `security-engineer` master skill + all 6 sub-skills | SKILL.md + 6 reference files |
| 5 | Create `qa-engineer` master skill + all 6 sub-skills | SKILL.md + 6 reference files |
| 6 | Create `sre-engineer` master skill + all 6 sub-skills | SKILL.md + 6 reference files |

### Wave 2 — Extended Core (P1 Teams)

These extend coverage across the full SDLC and add specialized development capabilities.

| Session | Task | Deliverable |
|---------|------|-------------|
| 7 | Create `research-analyst` master skill + all 4 sub-skills | SKILL.md + 4 reference files |
| 8 | Groom `frontend-architect` + add 5 new sub-skills | Updated SKILL.md + 5 new reference files |
| 9 | Groom `backend-architect` + add 4 new sub-skills | Updated SKILL.md + 4 new reference files |
| 10 | Create `mobile-architect` master skill + all 5 sub-skills | SKILL.md + 5 reference files |
| 11 | Create `ai-ml-engineer` master skill + all 5 sub-skills | SKILL.md + 5 reference files |
| 12 | Create `code-reviewer` master skill + all 4 sub-skills | SKILL.md + 4 reference files |

### Wave 3 — Support & Domain (P2 Teams)

Support functions and domain-specific expertise.

| Session | Task | Deliverable |
|---------|------|-------------|
| 13 | Create `technical-writer` master skill + all 4 sub-skills | SKILL.md + 4 reference files |
| 14 | Create `project-planner` master skill + all 3 sub-skills | SKILL.md + 3 reference files |
| 15 | Create `e-commerce-architect` domain skill | SKILL.md + reference files |
| 16 | Create `fintech-architect` domain skill | SKILL.md + reference files |
| 17 | Create `saas-architect` domain skill | SKILL.md + reference files |
| 18 | Create `real-time-architect` domain skill | SKILL.md + reference files |

### Wave 4 — Orchestrator & Integration (P0 but built last)

| Session | Task | Deliverable |
|---------|------|-------------|
| 19 | Create `healthcare-architect` domain skill | SKILL.md + reference files |
| 20 | Groom `social-platform-architect` (align with new structure) | Updated SKILL.md + references |
| 21 | Create `orchestrator` master skill (routing logic across all teams) | SKILL.md + routing rules + team registry |
| 22 | Integration testing — verify cross-references and routing across all skills | Updated cross-references in all skills |

---

## How Each Session Should Work

For each session creating a new skill:

1. **Research Phase**: Use web search to gather the latest best practices, tools, frameworks, and patterns for that domain (2026-current).
2. **SKILL.md Creation**: Write the master skill file — this is the "team lead" with broad domain knowledge, decision frameworks, and guidance on when to consult which sub-skill.
3. **Sub-skill References**: Create each sub-skill reference file with deep, actionable knowledge — not generic overviews, but production-proven patterns, specific tool recommendations, and decision matrices.
4. **Cross-references**: Add references to related skills (e.g., `security-engineer` should reference `devops-engineer` for infra security, `backend-architect` for app security).
5. **Evals (where applicable)**: Create evaluation scenarios to test the skill's quality.

## Design Principles for All Skills

1. **Conversational first** — Skills ask questions before giving answers. No prescriptive dumps.
2. **Tradeoff-oriented** — Always present 2-3 options with pros/cons. Let the user decide.
3. **Production-proven** — Reference real-world implementations, not textbook theory.
4. **Current** — Always use WebSearch to verify advice. Ecosystems change fast.
5. **Cross-referencing** — Skills should know their boundaries and defer to other skills when appropriate.
6. **Scale-aware** — Different advice for a 3-person startup vs a 200-person enterprise.
