# ETYB Skills — Master Plan

## Bird's-Eye View

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PROCESS LAYER (v2)                                 │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐    │
│  │  DESIGN  │→ │   PLAN   │→ │ IMPLEMENT │→ │  VERIFY  │→ │   SHIP   │    │
│  │   Gate   │  │   Gate   │  │   Gate    │  │   Gate   │  │   Gate   │    │
│  └──────────┘  └──────────┘  └───────────┘  └──────────┘  └──────────┘    │
├─────────────────────────────────────────────────────────────────────────────┤
│                     PROCESS PROTOCOLS (always-on HOW)                       │
│  tdd · verification · review · plan-execution · brainstorm · branch-safety │
│  subagent-coordination · self-improvement · debugging                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                            ┌─────────────────────┐                         │
│                            │     ORCHESTRATOR     │                         │
│                            │  (Process-Enforcing  │                         │
│                            │   CTO / Router)      │                         │
│                            └─────────┬───────────┘                         │
│                                      │                                     │
│        ┌──────────┬──────────┬───────┴───────┬──────────┬──────────┐       │
│        ▼          ▼          ▼               ▼          ▼          ▼       │
│   ┌─────────┐┌─────────┐┌─────────┐   ┌─────────┐┌─────────┐┌─────────┐  │
│   │Research &││Design & ││  Dev    │   │  Test & ││ DevOps &││  SRE &  │  │
│   │Discovery││Architect││  Teams  │   │   QA    ││  Infra  ││  Ops    │  │
│   └─────────┘└─────────┘└─────────┘   └─────────┘└─────────┘└─────────┘  │
│        │          │          │               │          │          │       │
│        │          │     ┌────┼────┐          │          │          │       │
│        │          │     ▼    ▼    ▼          │          │          │       │
│        │          │  Front  Back  DB &       │          │          │       │
│        │          │  end    end   Data       │          │          │       │
│        │          │               Mobile     │          │          │       │
│        │          │               AI/ML      │          │          │       │
│        │          │                          │          │          │       │
│   ┌────┴──────────┴──────────────────────────┴──────────┴──────────┴────┐  │
│   │                    CROSS-CUTTING TEAMS                              │  │
│   │         Security  ·  Documentation  ·  Code Review                  │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│   Quality Gates: qa-engineer (TDD), security-engineer (auto-consult),     │
│                  code-reviewer (mandatory review)                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## The Concept

Think of this as a **virtual engineering company with process discipline** — not just a roster of experts, but an operating team with gates, verification, and living plans:

- **Orchestrator** = Process-enforcing CTO — classifies request complexity (Tier 0–4), mandates the right experts, enforces phase gates, and tracks plan state
- **Master Skills** = Team Leads — broad domain knowledge, delegates to specialists, participates in plan lifecycle
- **Sub-Skills** = Specialists — deep expertise in one area, does the actual work
- **Quality Gates** = Mandatory checkpoints — qa-engineer enforces TDD, security-engineer auto-consults on sensitive changes, code-reviewer blocks Ship without review
- **Process Layer** = The 5-gate lifecycle (Design → Plan → Implement → Verify → Ship) that wraps every Tier 2+ project, with living plan artifacts, verification protocols, and debugging escalation

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
| `saas-architect` | `saas-architect/` | DONE | Multi-tenancy, billing/subscriptions, onboarding, usage metering, tenant isolation |
| `real-time-architect` | `real-time-architect/` | DONE | WebSocket systems, gaming backends, collaboration tools, live streaming, chat |
| `healthcare-architect` | `healthcare-architect/` | DONE | HIPAA compliance, HL7/FHIR, EHR integration, patient data, audit trails |

---

## Summary: Complete Skill Inventory

### Core Teams (14 master skills + 1 orchestrator)

| # | Master Skill | Sub-skills | Status | Priority | Process |
|---|-------------|------------|--------|----------|---------|
| 0 | `orchestrator` | — | DONE | P0 — Build last | v2 — process-enforcing CTO |
| 1 | `research-analyst` | 4 sub-skills | DONE | P1 | v2 |
| 2 | `system-architect` | 5 sub-skills | DONE | P0 | v2 |
| 3 | `frontend-architect` | 5 new + 4 existing = 9 | DONE | P1 | v2 |
| 4 | `backend-architect` | 4 new + 5 existing = 9 | DONE | P1 | v2 |
| 5 | `database-architect` | 6 sub-skills | DONE | P0 | v2 |
| 6 | `mobile-architect` | 5 sub-skills | DONE | P1 | v2 |
| 7 | `qa-engineer` | 6 sub-skills | DONE | P0 | v2 — quality gate (TDD) |
| 8 | `devops-engineer` | 8 sub-skills | DONE | P0 | v2 |
| 9 | `security-engineer` | 6 sub-skills | DONE | P0 | v2 — quality gate (auto-consult) |
| 10 | `sre-engineer` | 6 sub-skills | DONE | P0 | v2 |
| 11 | `ai-ml-engineer` | 5 sub-skills | DONE | P1 | v2 |
| 12 | `technical-writer` | 4 sub-skills | DONE | P2 | v2 — plan-integrated docs |
| 13 | `project-planner` | 3 sub-skills | DONE | P2 | v2 — plan lifecycle owner |
| 14 | `code-reviewer` | 4 sub-skills | DONE | P1 | v2 — quality gate (mandatory review) |

### Domain-Specific Teams (6 master skills)

| # | Master Skill | Status | Priority | Process |
|---|-------------|--------|----------|---------|
| 15 | `social-platform-architect` | DONE | Done (groomed) | v2 |
| 16 | `e-commerce-architect` | DONE | P2 | v2 |
| 17 | `fintech-architect` | DONE | P2 | v2 |
| 18 | `saas-architect` | DONE | P2 | v2 |
| 19 | `real-time-architect` | DONE | P2 | v2 |
| 20 | `healthcare-architect` | DONE | P3 | v2 |

### Process Protocols (7 skills)

| # | Protocol | Status | Priority | Process |
|---|----------|--------|----------|---------|
| 21 | `tdd-protocol` | DONE | P0 | v2 — always-on TDD enforcement |
| 22 | `subagent-protocol` | DONE | P1 | v2 — parallel coordination |
| 23 | `git-workflow-protocol` | DONE | P1 | v2 — branch safety |
| 24 | `plan-execution-protocol` | DONE | P0 | v2 — task-by-task execution |
| 25 | `brainstorm-protocol` | DONE | P1 | v2 — exploration before solution |
| 26 | `review-protocol` | DONE | P0 | v2 — review lifecycle |
| 27 | `skill-evolution-protocol` | DONE | P2 | v2 — self-improvement |

### Totals

- **29 skills** (1 orchestrator + 14 core teams + 6 domain specialists + 7 process protocols + 1 orchestrator) — ALL DONE, all at process v2
- **~80 sub-skills** across all teams — ALL DONE
- **7 process protocols** with hooks and deep reference knowledge — ALL DONE
- **29 sessions completed** (Waves 1-4: 22 sessions, Wave 5: 6 sessions, Wave 6: 1 session)
- Cross-references verified across all 29 skills
- Orchestrator routing tested with 15 prompts (10 PASS, 5 WARN, 0 FAIL)
- Process discipline: 5 new reference files, 21 SKILL.md upgrades, 10 process evals
- Engineering culture: 9 always-on disciplines embedded in orchestrator, 5 hooks registered

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
| 5 | ~~Create `qa-engineer` master skill + all 6 sub-skills~~ | DONE |
| 6 | ~~Create `sre-engineer` master skill + all 6 sub-skills~~ | DONE |

### Wave 2 — Extended Core (P1 Teams)

These extend coverage across the full SDLC and add specialized development capabilities.

| Session | Task | Deliverable |
|---------|------|-------------|
| 7 | ~~Create `research-analyst` master skill + all 4 sub-skills~~ | DONE |
| 8 | ~~Groom `frontend-architect` + add 5 new sub-skills~~ | DONE |
| 9 | ~~Groom `backend-architect` + add 4 new sub-skills~~ | DONE |
| 10 | ~~Create `mobile-architect` master skill + all 5 sub-skills~~ | DONE |
| 11 | ~~Create `ai-ml-engineer` master skill + all 5 sub-skills~~ | DONE |
| 12 | ~~Create `code-reviewer` master skill + all 4 sub-skills~~ | DONE |

### Wave 3 — Support & Domain (P2 Teams)

Support functions and domain-specific expertise.

| Session | Task | Deliverable |
|---------|------|-------------|
| 13 | ~~Create `technical-writer` master skill + all 4 sub-skills~~ | DONE |
| 14 | ~~Create `project-planner` master skill + all 3 sub-skills~~ | DONE |
| 15 | ~~Create `e-commerce-architect` domain skill~~ | DONE |
| 16 | ~~Create `fintech-architect` domain skill~~ | DONE |
| 17 | ~~Create `saas-architect` domain skill~~ | DONE |
| 18 | ~~Create `real-time-architect` domain skill~~ | DONE |

### Wave 4 — Orchestrator & Integration (P0 but built last)

| Session | Task | Deliverable |
|---------|------|-------------|
| 19 | ~~Create `healthcare-architect` domain skill~~ | DONE |
| 20 | ~~Groom `social-platform-architect` (align with new structure)~~ | DONE |
| 21 | ~~Create `orchestrator` master skill (routing logic across all teams)~~ | DONE |
| 22 | ~~Integration testing — verify cross-references and routing across all skills~~ | DONE |

### Wave 5 — Process Discipline (Plan #2)

Transforms etyb-skills from a roster of experts into an operating team with gates, verification, and living plans. 6 sessions adding process architecture across all 21 skills.

#### Overview

**What was added:**
- **Process Architecture** — 5-gate lifecycle (Design → Plan → Implement → Verify → Ship) with tier-based complexity classification (Tier 0–4)
- **Verification Protocol** — Universal 5-question framework ("What was done? How verified? What tests? Edge cases? What could go wrong?") with role-specific checklists
- **Debugging Protocol** — Root-cause-first methodology, one-variable rule, 3-failure escalation to domain experts
- **Plan Lifecycle** — Living plan artifacts in `.etyb/plans/`, Claude plan mode integration, gate readiness assessments
- **Quality Gates** — Three mandatory checkpoints: qa-engineer (TDD enforcement), security-engineer (auto-consultation), code-reviewer (mandatory review before Ship)
- **Expert Mandating** — Orchestrator automatically mandates specialists for auth, PII, payments, infrastructure, database, and healthcare work
- **Expert Continuity** — Experts consulted at Design gate are re-consulted at Verify gate

#### New Files Created

| File | Purpose |
|------|---------|
| `orchestrator/references/process-architecture.md` | Master process reference — plan format, gates, expert mandating, coordination patterns |
| `orchestrator/references/verification-protocol.md` | Verification framework — 5 questions, role-specific checklists, done criteria per gate |
| `orchestrator/references/debugging-protocol.md` | Debugging methodology — root cause first, hypothesis-driven, escalation paths |
| `project-planner/references/plan-lifecycle.md` | Plan creation workflow, update patterns, gate readiness assessment, templates |
| `orchestrator/evals/process-evals.json` | 10 end-to-end eval scenarios testing process-enforced workflow |

#### All 21 SKILL.md Modifications

Every SKILL.md received three new sections (placed before the final "What You Are NOT"):

1. **Process Awareness** — Read active plan, understand current phase, respect gate boundaries
2. **Verification Protocol** — Domain-specific checklist (e.g., database checks query plans; frontend checks Lighthouse scores; healthcare checks HIPAA)
3. **Debugging Protocol** — Systematic debugging with skill-specific escalation paths

Additionally, three skills were enhanced as **mandatory quality gates**:
- `qa-engineer` — TDD enforcement, plan-time test strategy, Verify gate participation
- `security-engineer` — Auto-consultation triggers (8 conditions), security checkpoints per gate
- `code-reviewer` — Mandatory review gate, tier-based review requirements, plan compliance verification

And two skills were enhanced as **process owners**:
- `orchestrator` — Plan lifecycle management, phase gating enforcement, expert mandating, state tracking, debugging protocol activation
- `project-planner` — Plan artifact population, living plan updates, gate readiness assessment, decision logging

#### Coordination Model

| Role | Process Behavior |
|------|-----------------|
| `orchestrator` | **Process-enforcing** — classifies tiers, mandates experts, enforces gates, blocks progression without exit criteria |
| `qa-engineer` | **Quality gate** — blocks Ship without test coverage, enforces TDD at Plan gate |
| `security-engineer` | **Quality gate** — auto-consulted on auth/PII/payments/infra, blocks Ship without security sign-off |
| `code-reviewer` | **Quality gate** — mandatory review before Ship gate passes |
| `project-planner` | **Process owner** — creates and maintains plan artifacts, assesses gate readiness |
| `technical-writer` | **Process-integrated** — decision logs, ADRs as plan artifacts, docs assigned per gate |
| All other skills | **Process-aware** — read plan, respect gates, follow verification protocol, use debugging protocol |

#### Session Log

| Session | Task | Deliverable |
|---------|------|-------------|
| 23 | ~~Create process architecture foundation — 3 orchestrator reference files~~ | `process-architecture.md`, `verification-protocol.md`, `debugging-protocol.md` |
| 24 | ~~Enhance orchestrator to process-enforcing CTO~~ | Plan lifecycle, phase gating, expert mandating, state tracking |
| 25 | ~~Enhance project-planner and technical-writer for plan-centric workflow~~ | `plan-lifecycle.md`, living plans, gate readiness, decision logging |
| 26 | ~~Enhance qa-engineer, code-reviewer, security-engineer as quality gates~~ | TDD enforcement, mandatory review, auto-consultation |
| 27 | ~~Add process sections to all 15 remaining skills~~ | Process awareness, verification, debugging for all skills |
| 28 | ~~Validate system, update master docs, add process evals~~ | This document update, `process-evals.json`, cross-reference verification |

---

## Wave 6: Process Protocols (7 new skills)

**Purpose:** Always-on engineering disciplines that govern HOW work gets done. These are behavioral enforcers with deep reference knowledge, not domain experts. Principles are embedded in the orchestrator; deep knowledge is loaded on demand.

### Process Protocol #21: TDD Protocol
**Folder:** `tdd-protocol/`
**Always on for:** All code-producing work
**Sub-skills:** red-green-refactor, rationalization-counters, tdd-patterns
**Hooks:** pre-edit-check (warns if no test file), post-test-log (logs results)

### Process Protocol #22: Subagent Protocol
**Folder:** `subagent-protocol/`
**Always on for:** Parallel work, delegated tasks
**Sub-skills:** dispatch-patterns, parallel-coordination, two-stage-review, context-isolation

### Process Protocol #23: Git Workflow Protocol
**Folder:** `git-workflow-protocol/`
**Always on for:** Branch management, parallel development
**Sub-skills:** worktree-management, branch-finishing, parallel-development
**Hooks:** pre-merge-verify (blocks merge if tests fail)

### Process Protocol #24: Plan Execution Protocol
**Folder:** `plan-execution-protocol/`
**Always on for:** Any active plan
**Sub-skills:** task-execution-cycle, blocker-management, gate-transitions
**Hooks:** post-edit-log (traces edits to plan tasks)

### Process Protocol #25: Brainstorm Protocol
**Folder:** `brainstorm-protocol/`
**Always on for:** Ambiguous or exploratory requests
**Sub-skills:** exploration-techniques, convergence-patterns, design-brief-template

### Process Protocol #26: Review Protocol
**Folder:** `review-protocol/`
**Always on for:** Code review lifecycle
**Sub-skills:** review-dispatch, feedback-evaluation, review-integration
**Hooks:** pre-commit-review-check (verifies review before commit)

### Process Protocol #27: Skill Evolution Protocol
**Folder:** `skill-evolution-protocol/`
**Always on for:** Skill creation, evaluation, improvement
**Sub-skills:** skill-creation, eval-engineering, improvement-loop, institutional-memory

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
7. **Process-aware** — Every skill participates in the plan lifecycle, follows the verification protocol, and respects gate boundaries.
