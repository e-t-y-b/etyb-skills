<p align="center">
  <a href="https://etyb.ai">
    <img src="https://etyb.ai/og-image.png" alt="etyb.ai — Your AI team. Built to deliver." width="100%" />
  </a>
</p>

<p align="center">
  <a href="https://etyb.ai"><strong>etyb.ai</strong></a> &nbsp;·&nbsp;
  <a href="https://etyb.ai/changelog">v4.0.0 — Changelog</a> &nbsp;·&nbsp;
  <a href="STACKS.md">Stacks</a> &nbsp;·&nbsp;
  <a href="docs/installation.md">Install Guide</a> &nbsp;·&nbsp;
  <a href="docs/architecture.md">Architecture</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-hook--enforced-00cc66?style=flat-square" alt="Claude Code" />
  <img src="https://img.shields.io/badge/OpenAI_Codex-hooks_+_agents-00cc66?style=flat-square" alt="OpenAI Codex" />
  <img src="https://img.shields.io/badge/Google_Antigravity-model--trusted-888?style=flat-square" alt="Google Antigravity" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/skill-1_command-black?style=flat-square" alt="One skill, /etyb" />
  <img src="https://img.shields.io/badge/content-in_repo-00cc66?style=flat-square" alt="Vendor knowledge in-repo" />
</p>

---

# etyb-skills

**Install a virtual engineering company.** One slash command — `/etyb` — gives your AI agent a CTO, 20 specialists, 9 always-on engineering disciplines, and platform-specific [Stack Packs](STACKS.md).

v4 collapses what used to be 30 separate skills into **one coordinated skill** with currency-stamped vendor knowledge living inside the repo at `stacks/<vendor>/`. The user only ever invokes `/etyb`. ETYB silently routes the work to the right internal specialist, applies the right protocols, reads the relevant Stack page directly when the work involves a vendor, and signs every response. New: the [public changelog](https://etyb.ai/changelog) is linked under every response — one channel, no slash-command pollution.

## Quick Start

```bash
# Claude Code — native plugin
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb@etyb-skills

# OpenAI Codex, Google Antigravity, or manual install
git clone https://github.com/e-t-y-b/etyb-skills.git
./etyb-skills/scripts/install.sh

# Codex projects — add runtime hooks + custom agents
./etyb-skills/scripts/install-codex-runtime.sh --target /path/to/your-project
```

Once installed, every request goes through `/etyb`. Specialist expertise is loaded internally as you need it.

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
- **Solo developers** — `/etyb` is one slash command and works the same regardless of project size

## What You Get

An AI coding agent that works like a 100-person engineering org — through a single trigger:

- **Refuses to ship untested code** — TDD enforcement with deterministic hooks
- **Stops you from building the wrong thing** — structured brainstorming before architecture
- **Pushes back on bad review feedback** — evaluates findings on merit, no performative agreement
- **Coordinates parallel work** — subagent dispatch with two-stage review and worktree isolation
- **Covers the full SDLC** — from research through production operations
- **Knows your domain** — fintech ledgers, HIPAA compliance, e-commerce patterns, real-time systems
- **Speaks your platform** — Stack Packs load across all roles when work involves a specific stack. [Salesforce](stacks/salesforce/SKILL.md) is live; AWS, GCP, Stripe, Shopify, SAP, ServiceNow on the way
- **Identifies itself** — every Tier 1-4 response ends with `ETYB · <role-engaged>` and a `What's new — etyb.ai/changelog` line. One brand, transparent expertise.

---

## Architecture

```
USER REQUEST
     │
   /etyb (the only trigger surface — single skill, single brand)
     │
ETYB CTO core ── reads internal references on demand:
     │
     ├── references/specialists/  (14 core engineering team READMEs)
     ├── references/protocols/    (9 always-on engineering disciplines)
     ├── references/verticals/    (6 business-domain architects)
     │
     │  ALWAYS-ON PROTOCOL LAYER (loaded into every response)
     │  ├── TDD — no code without failing test
     │  ├── Verification — evidence before claims
     │  ├── Review — no performative agreement
     │  ├── Plan execution — one task at a time
     │  ├── Brainstorm-first — explore before solving
     │  ├── Branch safety — never merge without green tests
     │  ├── Subagent coordination — parallel dispatch + review
     │  ├── Self-improvement — failing eval before skill changes
     │  └── Debugging — root-cause-first after repeated failures
     │
     │  STACK PACK OVERLAYS (load when platform signals match)
     │  └── Salesforce — Apex, LWC, Data 360, Agentforce, MCP-native dev
     │      (roadmap: AWS, GCP, Azure, Vercel, Supabase, Snowflake, ...)
     │
RESPONSE — signed: ETYB · <role-engaged> + changelog link
```

Three orthogonal axes: **specialists** (the roles), **protocols** (the disciplines), **Stack Packs** (the platforms). All live as internal references under `skills/etyb/references/`. Adding a new stack adds a folder, not a roster slot — and never a new slash command.

---

## What's Inside ETYB

### Specialists (14, under `references/specialists/`)

| Reference | Phase | What It Owns |
|-----------|-------|--------------|
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

### Verticals (6, under `references/verticals/`)

| Reference | Domain |
|-----------|--------|
| `social-platform-architect` | Feeds, social graphs, content ranking, fan-out, real-time delivery |
| `e-commerce-architect` | Catalogs, cart/checkout, payments, inventory, order management |
| `fintech-architect` | Ledgers, payment processing, AML/KYC, PCI/PSD2, fraud detection |
| `saas-architect` | Multi-tenancy, billing, subscriptions, onboarding, usage metering |
| `real-time-architect` | WebSockets, CRDTs, collaboration, gaming backends, live streaming |
| `healthcare-architect` | HIPAA, HL7/FHIR, EHR integration, patient data, audit trails |

### Protocols (9, under `references/protocols/`)

| Reference | Always On | Runtime Support |
|-----------|-----------|-----------------|
| `tdd-protocol` | Every code change | Claude hooks, Codex prompt/Bash guardrails, Antigravity model-trusted |
| `review-protocol` | Every review cycle | Claude pre-commit hook, Codex reviewer agent + commit reminder, Antigravity model-trusted |
| `subagent-protocol` | Parallel work | Claude isolated subagents, Codex custom agents, Antigravity markdown-first |
| `git-workflow-protocol` | Branch management | Claude pre-merge hook, Codex merge guard via Bash hooks, Antigravity model-trusted |
| `plan-execution-protocol` | Active plans | Claude native plan mode + post-edit hook, Codex `.etyb/plans/`, Antigravity `.etyb/plans/` |
| `brainstorm-protocol` | Ambiguous requests | Platform-neutral |
| `skill-evolution-protocol` | Skill improvements | Platform-neutral |
| `verification-protocol` | Every completion claim | Claude deterministic, Codex stop hook assist, Antigravity model-trusted |
| `debugging-protocol` | Active troubleshooting | Platform-neutral |

### Stack Packs

Platform-specific knowledge overlays with **knowledge-currency timestamps**, authoritative-source URLs, per-product drift-risk ratings, and **vendor-skill delegation** — when a vendor MCP/skill is installed in your environment, ETYB defers to it rather than answering from baked knowledge. The team doesn't grow — it learns the platform.

| Stack | Last Verified | Coverage |
|-------|---------------|----------|
| [Salesforce](stacks/salesforce/) | 2026-05-12 (Spring '26) | Apex, LWC, Flow, Data 360, Agentforce, MCP-native dev, ECA migration, MFA mandate |
| [AWS](stacks/aws/) | 2026-05-14 | Lambda + SnapStart, EKS Auto Mode, Aurora DSQL, Bedrock + AgentCore + Strands Agents SDK, Karpenter v1 |
| [GCP](stacks/gcp/) | 2026-05-14 | Cloud Run gen2, GKE Autopilot, AlloyDB AI, Vertex AI + Gemini, Agent Builder + Agentspace, TPU v7 |
| [Azure](stacks/azure/) | 2026-05-14 | AKS Auto/LTS, Container Apps, Cosmos DiskANN, Entra ID, AI Foundry + Foundry Agents, Microsoft Fabric |
| [Anthropic Claude](stacks/anthropic-claude/) | 2026-05-14 | Claude 4.x API, prompt caching, tool use, Claude Agent SDK, MCP authoring, Claude Code patterns |
| [OpenAI](stacks/openai/) | 2026-05-14 | GPT-5 family, Responses API, Realtime API, Agents SDK, Structured Outputs, Computer Use |
| [Cloudflare](stacks/cloudflare/) | 2026-05-14 | Workers + RPC, Durable Objects (SQLite), D1, R2, Hyperdrive, Vectorize, AI Gateway, AI Search, Workflows |
| [Vercel](stacks/vercel/) | 2026-05-14 | Next.js + PPR + Cache Components, Fluid Compute, AI SDK, AI Gateway, Vercel Sandbox, Workflow |
| [Supabase](stacks/supabase/) | 2026-05-14 | Postgres + RLS, Supabase Auth, Edge Functions, Realtime, Storage, pgvector, Supavisor, branching |
| [Firebase](stacks/firebase/) | 2026-05-14 | Firebase Auth, Firestore + multi-database, App Hosting, Cloud Functions gen 2, Firebase AI Logic, Genkit, Data Connect |
| [Expo](stacks/expo/) | 2026-05-14 | Expo SDK + Router, EAS Build/Update/Submit/Workflows/Hosting, New Architecture, CNG, dev clients |
| [Stripe](stacks/stripe/) | 2026-05-14 | Payment Intents, Checkout, Billing, Connect, Treasury, Issuing, Meter API, Express Checkout, Tax, Radar |
| [Observability](stacks/observability/) | 2026-05-14 | multi-vendor: Datadog, New Relic, Grafana stack, Prometheus, Splunk, Honeycomb, Sentry, Dynatrace, OpenTelemetry |

**13 Stacks live in this repo under [`stacks/`](stacks/)** with a unified knowledge-currency framework. ETYB reads per-product and per-role pages directly when the install is on disk. Third-party agents without the install can fetch the same content as raw markdown from `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/<vendor>/<page>.md`. See [STACKS.md](STACKS.md) for the full registry, drift-risk model, and authoring conventions.

**Roadmap:** Snowflake, Databricks, dbt, Shopify, SAP, ServiceNow, Twilio, Auth0/Okta/Clerk/WorkOS as separate Stacks.

---

## Install

### Claude Code (plugin)

```bash
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb@etyb-skills
```

Installs the full `/etyb` skill — 14 specialists + 9 protocols + 6 verticals.

### Codex, Antigravity, or Manual (CLI installer)

```bash
git clone https://github.com/e-t-y-b/etyb-skills.git
cd etyb-skills

./scripts/install.sh                 # default — copies skills/etyb/ to your skills dir
./scripts/install.sh --dry-run       # change nothing, show plan
./scripts/install.sh --target DIR    # install into DIR (overrides auto-detect)
```

The installer auto-detects target directories (`.claude/skills/`, `.agents/skills/`, `.agent/skills/`, `skills/`) and offers to back up legacy v3 sibling skills if it finds them.

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

Every ETYB response ends with `What's new — etyb.ai/changelog` so you always have a one-click path to release notes. The updater preserves `.etyb/plans/`, `.claude/plans/`, and `.claude/settings.local.json`. Uses `git merge --ff-only` — no destructive operations.

---

## How Skills Load (Token Efficiency)

Skills use progressive disclosure — a markdown-based RAG pattern:

```
Layer 0  Runtime guardrails (0 tokens — scripts outside the LLM)
Layer 1  ETYB SKILL.md always loaded (~3,500 tokens — the culture)
Layer 2  Relevant reference loads on demand (~2,500 tokens — the specialist)
Layer 3  Deep reference loads on demand (~4,000 tokens — single helper file)

Per-activation: ~6,000-10,000 tokens (not the whole library)
Tier 0-1 requests: ~3,500 tokens (ETYB handles directly)
```

The v4 collapse cuts metadata cost — instead of 30 always-loaded descriptions competing at trigger time, there's one. Internal references are loaded only when ETYB consults them.

---

## Evidence: With vs Without

| Scenario | Without ETYB | With ETYB |
|----------|-------------|-----------|
| "Skip tests, demo tomorrow" | Wrote production code immediately | Refused. Named the rationalization. Laid out 4 TDD cycles. |
| "Build restaurant app with React+Firebase" (6 features) | Built entire architecture, 6-week plan, all code | Stopped. Identified 3 red flags. Asked 10 questions. Challenged build-vs-buy. |
| "Handle these 5 review findings" | Agreed with all 5 | Pushed back on 2 with evidence. Caught a mis-severity. Demanded a test before accepting a code change. |

**Average token overhead: +53%. What you get: an engineer who says "no" when it matters.**

---

## Links

- Website: [etyb.ai](https://etyb.ai)
- Changelog: [etyb.ai/changelog](https://etyb.ai/changelog)
- Repo: [github.com/e-t-y-b/etyb-skills](https://github.com/e-t-y-b/etyb-skills)
- Install guide: [docs/installation.md](docs/installation.md)
- Architecture: [docs/architecture.md](docs/architecture.md)
- Issues & contributions: [github.com/e-t-y-b/etyb-skills/issues](https://github.com/e-t-y-b/etyb-skills/issues)

## License

MIT — see [LICENSE](LICENSE).
