# etyb-skills

**A virtual engineering company for your AI coding agent.**

29 skills organized as a coordinated engineering team — not just a list of experts, but an operating system for engineering work with process discipline, quality gates, and domain depth.

```
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb-full@etyb-skills
```

---

## What this gives you

An AI coding agent that works like a 100-person engineering org:

- **Refuses to ship untested code** — TDD enforcement with deterministic hooks, not just instructions
- **Stops you from building the wrong thing** — structured brainstorming before architecture
- **Pushes back on bad review feedback** — evaluates findings on merit, no performative agreement
- **Coordinates parallel work** — subagent dispatch with two-stage review and worktree isolation
- **Covers the full SDLC** — from research through production operations
- **Knows your domain** — fintech ledgers, HIPAA compliance, e-commerce patterns, real-time systems, and more

## Why it works

Most skill packages give you a list of independent instructions. etyb-skills is different:

- **29 skills** — process discipline AND deep domain expertise in one package
- **20 domain experts with 100+ deep references** — fintech ledgers, HIPAA compliance, e-commerce patterns, real-time systems, and more
- **Deterministic enforcement** — shell hooks fire outside the LLM, so TDD gates and merge checks can't be talked around
- **Orchestrator-centric architecture** — a CTO routes every request through the right experts with always-on protocols
- **Full SDLC coverage** — Research, Architecture, Code, Test, Deploy, Operate (not just plan-to-merge)

## Architecture

```
USER REQUEST
     ↓
ORCHESTRATOR (CTO — routes, enforces gates, tracks plans)
     │
     │  ALWAYS-ON PROTOCOL LAYER
     │  ├── TDD — no code without failing test
     │  ├── Verification — evidence before claims
     │  ├── Review — no performative agreement
     │  ├── Plan execution — one task at a time
     │  ├── Brainstorm-first — explore before solving
     │  ├── Branch safety — never merge without green tests
     │  ├── Subagent coordination — parallel dispatch + review
     │  └── Self-improvement — failing eval before skill changes
     │
     ↓
DOMAIN EXPERTS (14 core teams + 6 vertical specialists)
     │
     ↓
DEEP REFERENCES (100+ files, loaded on demand)
```

## The 29 Skills

### Orchestrator
The CTO. Routes requests, enforces 5-phase gates (Design → Plan → Implement → Verify → Ship), mandates experts, tracks living plans.

### Core Team (14 skills)

| Skill | SDLC Phase | What It Does |
|-------|-----------|-------------|
| `research-analyst` | Discovery | Tech evaluation, competitive analysis, feasibility, requirements |
| `project-planner` | Planning | Sprint planning, timelines, agile coaching |
| `system-architect` | Design | System design, domain modeling, API design, data architecture |
| `frontend-architect` | Design + Dev | React, Angular, Vue, Svelte, SEO, performance, accessibility |
| `backend-architect` | Design + Dev | Java, TypeScript, Go, Python, Rust, microservices, auth |
| `database-architect` | Design + Dev | SQL, NoSQL, caching, search, data pipelines, migrations |
| `mobile-architect` | Design + Dev | React Native, Flutter, iOS, Android, mobile performance |
| `ai-ml-engineer` | Design + Dev | ML, MLOps, LLMs, data science, AI product integration |
| `qa-engineer` | Testing | Unit, integration, E2E, performance, API testing, test strategy |
| `devops-engineer` | Deploy | CI/CD, containers, Kubernetes, AWS/GCP/Azure, IaC, releases |
| `sre-engineer` | Operations | Monitoring, logging, tracing, incident response, chaos engineering |
| `security-engineer` | Cross-cutting | AppSec, infra security, IAM, compliance, threat modeling |
| `technical-writer` | Cross-cutting | API docs, architecture docs, runbooks, user guides |
| `code-reviewer` | Cross-cutting | Code quality, performance, security, architecture review |

### Domain Specialists (6 skills)

| Skill | Domain |
|-------|--------|
| `social-platform-architect` | Feeds, social graphs, content ranking, fan-out, real-time delivery |
| `e-commerce-architect` | Catalogs, cart/checkout, payments, inventory, order management |
| `fintech-architect` | Ledgers, payment processing, AML/KYC, PCI/PSD2, fraud detection |
| `saas-architect` | Multi-tenancy, billing, subscriptions, onboarding, usage metering |
| `real-time-architect` | WebSockets, CRDTs, collaboration, gaming backends, live streaming |
| `healthcare-architect` | HIPAA, HL7/FHIR, EHR integration, patient data, audit trails |

### Process Protocols (7 skills)

| Skill | Always On | Hooks |
|-------|----------|-------|
| `tdd-protocol` | Every code change | `pre-edit-check`, `post-test-log` |
| `review-protocol` | Every review cycle | `pre-commit-review-check` |
| `subagent-protocol` | Parallel work | — |
| `git-workflow-protocol` | Branch management | `pre-merge-verify` |
| `plan-execution-protocol` | Active plans | `post-edit-log` |
| `brainstorm-protocol` | Ambiguous requests | — |
| `skill-evolution-protocol` | Skill improvements | — |

## Install

### Everything
```bash
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb-full@etyb-skills
```

### Just process discipline
```bash
/plugin install etyb-process-protocols@etyb-skills
```

### Just core engineering team
```bash
/plugin install etyb-core-team@etyb-skills
```

### Just domain verticals
```bash
/plugin install etyb-verticals@etyb-skills
```

## How skills load (token efficiency)

Skills use progressive disclosure — a markdown-based RAG pattern:

```
Layer 0: Hooks fire deterministically (0 tokens — shell scripts, outside LLM)
Layer 1: Orchestrator always loaded (~3,500 tokens — the culture)
Layer 2: Relevant skill SKILL.md loads on demand (~2,500 tokens — the router)
Layer 3: Single reference loads on demand (~4,000 tokens — deep knowledge)

Per-activation: ~6,000-10,000 tokens (not the whole system)
Tier 0-1 requests: 0 extra tokens (orchestrator handles directly)
```

## Evidence: with vs without skills

We tested 3 scenarios comparing vanilla Claude vs Claude with etyb-skills:

| Scenario | Without Skills | With Skills |
|----------|---------------|-------------|
| "Skip tests, demo tomorrow" | Wrote production code immediately | Refused. Named the rationalization. Laid out 4 TDD cycles. |
| "Build restaurant app with React+Firebase" (6 features) | Built entire architecture, 6-week plan, all code | Stopped. Identified 3 red flags. Asked 10 questions. Challenged build-vs-buy. |
| "Handle these 5 review findings" | Agreed with all 5 | Pushed back on 2 with evidence. Caught a mis-severity. Demanded a test before accepting a code change. |

**Average token overhead: +53%. What you get: an engineer who says "no" when it matters.**

## License

MIT
