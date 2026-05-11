<p align="center">
  <a href="https://etyb.ai">
    <img src="https://etyb.ai/og-image.png" alt="etyb.ai — Your AI team. Built to deliver." width="100%" />
  </a>
</p>

<p align="center">
  <a href="https://etyb.ai"><strong>etyb.ai</strong></a> &nbsp;·&nbsp;
  <a href="https://github.com/e-t-y-b/etyb-skills/releases/tag/v3.0.0">v3.0.0</a> &nbsp;·&nbsp;
  <a href="STACKS.md">Stacks</a> &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a> &nbsp;·&nbsp;
  <a href="docs/installation.md">Install Guide</a> &nbsp;·&nbsp;
  <a href="docs/architecture.md">Architecture</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-hook--enforced-00cc66?style=flat-square" alt="Claude Code" />
  <img src="https://img.shields.io/badge/OpenAI_Codex-hooks_+_agents-00cc66?style=flat-square" alt="OpenAI Codex" />
  <img src="https://img.shields.io/badge/Google_Antigravity-model--trusted-888?style=flat-square" alt="Google Antigravity" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/skills-30-black?style=flat-square" alt="30 skills" />
  <img src="https://img.shields.io/badge/stack--packs-Salesforce-00cc66?style=flat-square" alt="Stack Packs: Salesforce" />
</p>

---

# etyb-skills

**Install a virtual engineering company.** Your AI agent gets a CTO, 20 specialists, 9 always-on engineering disciplines, and platform-specific [Stack Packs](STACKS.md) — out of the box.

30 coordinated skills that turn any [agentskills.io](https://agentskills.io)-compliant agent into a team that ships features methodically: brainstorming before architecture, tests before code, reviews before commits, evidence before "done." As of v3.0.0, **Stack Packs** add platform expertise on top of the team — the first pack ships full [Salesforce](stacks/salesforce/SKILL.md) coverage current to Spring '26, with AWS, GCP, Stripe, Shopify, SAP, and ServiceNow on the roadmap.

## Quick Start

```bash
# Claude Code — native plugin
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb-full@etyb-skills

# OpenAI Codex, Google Antigravity, or manual install
git clone https://github.com/e-t-y-b/etyb-skills.git
./etyb-skills/scripts/install.sh

# Codex projects — add runtime hooks + custom agents
./etyb-skills/scripts/install-codex-runtime.sh --target /path/to/your-project
```

---

## Platform Support

| Platform | Enforcement | What You Get |
|----------|-------------|--------------|
| **Claude Code** | Hook-enforced (flagship) | Deterministic gates via `PreToolUse`/`PostToolUse` hooks — edit-before-test, pre-merge, pre-commit review checks |
| **OpenAI Codex** | Partial runtime-enforced | 4 lifecycle hooks (prompt guardrails, Bash guards, stop checks) + 4 custom agents + per-skill `openai.yaml` metadata. [Documented model-trusted gaps](skills/etyb/adapters/codex/ADAPTER.md) |
| **Google Antigravity** | Model-trusted | Markdown-first protocols; ADK integration deferred. All gates and disciplines apply via instruction |

---

## Who This Is For

- **Teams shipping real software** — your AI agent works like a disciplined team member, not a solo cowboy
- **Engineers tired of AI "yes-and" behavior** — agents that skip tests, rubber-stamp reviews, or chase symptoms
- **Regulated or high-stakes codebases** (fintech, healthcare, e-commerce) — traceable decisions, gated releases, evidence-backed claims
- **Solo developers** — every specialist works standalone; the CTO is optional

## What You Get

An AI coding agent that works like a 100-person engineering org:

- **Refuses to ship untested code** — TDD enforcement with deterministic hooks, not just instructions
- **Stops you from building the wrong thing** — structured brainstorming before architecture
- **Pushes back on bad review feedback** — evaluates findings on merit, no performative agreement
- **Coordinates parallel work** — subagent dispatch with two-stage review and worktree isolation
- **Covers the full SDLC** — from research through production operations
- **Knows your domain** — fintech ledgers, HIPAA compliance, e-commerce patterns, real-time systems
- **Speaks your platform** — Stack Packs load on top of the team when work involves a specific stack. [Salesforce](stacks/salesforce/SKILL.md) is live; AWS, GCP, Stripe, Shopify, SAP, ServiceNow on the way

---

## Architecture

```
USER REQUEST
     |
ETYB (CTO — routes, enforces gates, tracks plans)
     |
     |  ALWAYS-ON PROTOCOL LAYER
     |  |-- TDD — no code without failing test
     |  |-- Verification — evidence before claims
     |  |-- Review — no performative agreement
     |  |-- Plan execution — one task at a time
     |  |-- Brainstorm-first — explore before solving
     |  |-- Branch safety — never merge without green tests
     |  |-- Subagent coordination — parallel dispatch + review
     |  |-- Self-improvement — failing eval before skill changes
     |  +-- Debugging — root-cause-first after repeated failures
     |
     |  STACK PACK OVERLAYS (new in v3.0.0 — load when platform signals match)
     |  +-- Salesforce — Apex, LWC, Data 360, Agentforce, MCP-native dev
     |  +-- (roadmap: AWS, GCP, Azure, Vercel, Supabase, Snowflake, Stripe, Shopify, SAP, ServiceNow)
     |
DOMAIN EXPERTS (14 core teams + 6 vertical specialists)
     |
DEEP REFERENCES (100+ files, loaded on demand)
```

Three orthogonal axes: **specialists** (the roles), **protocols** (the disciplines), **Stack Packs** (the platforms). Specialists and protocols are always there; Stack Packs load when the work involves their platform. Adding a new stack adds a folder, not a roster slot.

---

## The 30 Skills

### ETYB (1)

Your virtual CTO. Routes requests, enforces 5-phase gates (Design > Plan > Implement > Verify > Ship), mandates experts, tracks living plans. Works standalone, or as the conductor that pulls the other 29 skills into a coordinated team.

### Core Team (14)

| Skill | Phase | What It Does |
|-------|-------|--------------|
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

### Domain Specialists (6)

| Skill | Domain |
|-------|--------|
| `social-platform-architect` | Feeds, social graphs, content ranking, fan-out, real-time delivery |
| `e-commerce-architect` | Catalogs, cart/checkout, payments, inventory, order management |
| `fintech-architect` | Ledgers, payment processing, AML/KYC, PCI/PSD2, fraud detection |
| `saas-architect` | Multi-tenancy, billing, subscriptions, onboarding, usage metering |
| `real-time-architect` | WebSockets, CRDTs, collaboration, gaming backends, live streaming |
| `healthcare-architect` | HIPAA, HL7/FHIR, EHR integration, patient data, audit trails |

### Process Protocols (9)

| Skill | Always On | Runtime Support |
|-------|----------|-----------------|
| `tdd-protocol` | Every code change | Claude hooks, Codex prompt/Bash guardrails, Antigravity model-trusted |
| `review-protocol` | Every review cycle | Claude pre-commit hook, Codex reviewer agent + commit reminder, Antigravity model-trusted |
| `subagent-protocol` | Parallel work | Claude isolated subagents, Codex custom agents, Antigravity markdown-first |
| `git-workflow-protocol` | Branch management | Claude pre-merge hook, Codex merge guard via Bash hooks, Antigravity model-trusted |
| `plan-execution-protocol` | Active plans | Claude native plan mode + post-edit hook, Codex `.etyb/plans/`, Antigravity `.etyb/plans/` |
| `brainstorm-protocol` | Ambiguous requests | Platform-neutral |
| `skill-evolution-protocol` | Skill improvements | Platform-neutral |
| `verification-protocol` | Every completion claim | Claude deterministic, Codex stop hook assist, Antigravity model-trusted |
| `debugging-protocol` | Active troubleshooting | Platform-neutral |

### Stack Packs (new in v3.0.0)

Platform-specific knowledge overlays that load across the existing 20 specialists when work involves a specific tech stack. The team doesn't grow — it learns the platform.

| Stack | Version | Coverage | Status |
|-------|---------|----------|--------|
| [Salesforce](stacks/salesforce/SKILL.md) | 3.0.0 (Spring '26) | 11 role overlays — Apex, LWC, Flow, Data 360, Agentforce, MCP-native development, ECA migration, MFA mandate, Health Cloud, FSC | Live |
| AWS, GCP, Azure, Vercel, Supabase, Snowflake, Databricks, Stripe, Shopify, SAP, ServiceNow | — | — | Roadmap |

See [STACKS.md](STACKS.md) for the full registry and authoring conventions.

---

## Install

### Claude Code (plugin)

```bash
# Everything
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb-full@etyb-skills

# Or install subsets
/plugin install etyb-process-protocols@etyb-skills   # 9 protocols + ETYB
/plugin install etyb-core-team@etyb-skills            # 14 core teams + ETYB
/plugin install etyb-verticals@etyb-skills            # 6 domain specialists
```

### Codex, Antigravity, or Manual

```bash
git clone https://github.com/e-t-y-b/etyb-skills.git
cd etyb-skills

# Everything (default)
./scripts/install.sh

# Bundles — same groups as the Claude plugin marketplace
./scripts/install.sh --bundle process-protocols   # ETYB + 9 always-on protocols
./scripts/install.sh --bundle core-team           # ETYB + 14 core engineering teams
./scripts/install.sh --bundle verticals           # 6 domain specialists

# À la carte
./scripts/install.sh --skills tdd-protocol,code-reviewer

# Discovery + preview
./scripts/install.sh --list-bundles
./scripts/install.sh --dry-run                    # change nothing, show plan
```

Bundles are defined once in [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json); plain-text manifests in [bundles/](bundles/) are regenerated by [scripts/generate-bundles.py](scripts/generate-bundles.py) and CI verifies they stay in sync.

### Codex Runtime (hooks + agents)

```bash
./scripts/install-codex-runtime.sh --target /path/to/your-project
```

Installs `.codex/config.toml`, lifecycle hooks, and 4 custom agents (explorer, planner, reviewer, docs researcher). Backs up existing `.codex/` on conflict. See [docs/installation.md](docs/installation.md) for the full guide.

---

## Updating

```bash
./scripts/update.sh --check   # is there a newer version?
./scripts/update.sh           # interactive update (shows before/after)
./scripts/update.sh --force   # skip confirmation prompts
```

Preserves `.etyb/plans/`, `.claude/plans/`, and `.claude/settings.local.json`. Uses `git merge --ff-only` — no destructive operations. See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## How Skills Load (Token Efficiency)

Skills use progressive disclosure — a markdown-based RAG pattern:

```
Layer 0  Runtime guardrails (0 tokens — scripts outside the LLM)
Layer 1  ETYB always loaded (~3,500 tokens — the culture)
Layer 2  Relevant skill loads on demand (~2,500 tokens — the router)
Layer 3  Single reference loads on demand (~4,000 tokens — deep knowledge)

Per-activation: ~6,000-10,000 tokens (not the whole system)
Tier 0-1 requests: 0 extra tokens (ETYB handles directly)
```

---

## Evidence: With vs Without Skills

| Scenario | Without Skills | With Skills |
|----------|---------------|-------------|
| "Skip tests, demo tomorrow" | Wrote production code immediately | Refused. Named the rationalization. Laid out 4 TDD cycles. |
| "Build restaurant app with React+Firebase" (6 features) | Built entire architecture, 6-week plan, all code | Stopped. Identified 3 red flags. Asked 10 questions. Challenged build-vs-buy. |
| "Handle these 5 review findings" | Agreed with all 5 | Pushed back on 2 with evidence. Caught a mis-severity. Demanded a test before accepting a code change. |

**Average token overhead: +53%. What you get: an engineer who says "no" when it matters.**

---

## Links

- Website: [etyb.ai](https://etyb.ai)
- Repo: [github.com/e-t-y-b/etyb-skills](https://github.com/e-t-y-b/etyb-skills)
- Latest release: [v3.0.0](https://github.com/e-t-y-b/etyb-skills/releases/tag/v3.0.0)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Install guide: [docs/installation.md](docs/installation.md)
- Architecture: [docs/architecture.md](docs/architecture.md)
- Issues & contributions: [github.com/e-t-y-b/etyb-skills/issues](https://github.com/e-t-y-b/etyb-skills/issues)

## License

MIT — see [LICENSE](LICENSE).
