---
title: system-architect on OpenAI
description: API surface composition, multi-provider tradeoffs, org/project topology, residency + compliance posture, capacity model. The role that decides how OpenAI fits the system.
role_overlay:
  role: system-architect
  stack: openai
  last_verified_on: "2026-05-14"
  products_covered:
    - responses-api
    - chat-completions
    - assistants-api-legacy
    - realtime-api
    - batch-api
    - agents-sdk
    - built-in-tools
    - prompt-caching
    - organization-project-hierarchy
    - openai-platform-console
    - audit-logs
    - gpt-5
    - gpt-4-1
    - o-series-reasoning
    - embeddings
---

## Role briefing — what you own on OpenAI

You are the **system-architect**. You own:

1. **API surface composition** — which workloads land on [Responses](/stacks/openai/responses-api/) vs [Chat Completions](/stacks/openai/chat-completions/) vs [Realtime](/stacks/openai/realtime-api/) vs [Batch](/stacks/openai/batch-api/) vs [Embeddings](/stacks/openai/embeddings/).
2. **Multi-provider strategy** — direct SDK vs LangGraph vs Vercel AI SDK vs gateway (Helicone, LiteLLM, Portkey, Bifrost, OpenRouter).
3. **Caching + routing topology** — where the cache lives (app-level semantic, OpenAI prefix, none); where the router lives (in-app, gateway, agent).
4. **Org / project / key hierarchy** — see [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/). Mapping to environments, tenants, features.
5. **Capacity model** — default API + Scale Tier + [Batch](/stacks/openai/batch-api/); [usage-tier](/stacks/openai/organization-project-hierarchy/) ladder; rate-limit budgeting.
6. **Residency + compliance posture** — OpenAI direct vs Azure OpenAI for FedRAMP/HIPAA/IL5; ZDR vs default 30-day retention; EU residency posture.
7. **Reliability target** — multi-region (Azure OpenAI), multi-provider (Anthropic / Gemini fallback), graceful degradation.

You do **not** own:

- Specific model + prompt design — [ai-ml-engineer](/stacks/openai/ai-ml-engineer/).
- SDK plumbing within a service — [backend-architect](/stacks/openai/backend-architect/).
- Key + RBAC + audit log enforcement — [security-engineer](/stacks/openai/security-engineer/).

## Currency stamp

Verified 2026-05-14 — [Responses API](/stacks/openai/responses-api/) + [Chat Completions](/stacks/openai/chat-completions/) long-term-supported, [Realtime API](/stacks/openai/realtime-api/) GA, [Batch API](/stacks/openai/batch-api/) + [Files API](/stacks/openai/files-api/), [Assistants API (legacy)](/stacks/openai/assistants-api-legacy/) on deprecation glide path, [Prompt Caching](/stacks/openai/prompt-caching/) automatic, Scale Tier, ZDR via DPA, Azure OpenAI as parallel compose point.

## API surface composition — pick the right surface per workload

Real systems have multiple workloads. Don't pick one surface for everything.

| Workload | Surface | Why |
|---|---|---|
| User-facing chat | [Responses API](/stacks/openai/responses-api/) (or [Chat Completions](/stacks/openai/chat-completions/) if no tools) | Streaming + conversation state + tools. |
| Single-turn classification, extraction | [Chat Completions](/stacks/openai/chat-completions/) | Lower overhead. |
| Agent with web/file/code/computer-use tools | [Responses API](/stacks/openai/responses-api/) | Required for built-in tools. |
| Voice agent | [Realtime API](/stacks/openai/realtime-api/) + [Realtime Agents](/stacks/openai/realtime-agents/) | Speech-native. |
| Bulk classification / embedding refresh | [Batch API](/stacks/openai/batch-api/) | 50% cost; 24h SLA. |
| Embeddings (interactive) | [Embeddings](/stacks/openai/embeddings/) direct | Sync, fast. |
| Embeddings (bulk) | [Batch API](/stacks/openai/batch-api/) | 50% off. |
| Image generation | [Image generation](/stacks/openai/image-generation/) | Specific endpoint. |
| TTS / STT | [TTS](/stacks/openai/tts/) + [Whisper](/stacks/openai/whisper/) | Specific endpoints. |
| Fine-tuning data prep / evals | [Eval Platform](/stacks/openai/eval-platform/) + [Stored Completions](/stacks/openai/stored-completions/) | Console-driven. |
| Moderation | [Moderation API](/stacks/openai/moderation-api/) | Always at input + (optionally) output boundary. |

**Avoid:** picking [Responses API](/stacks/openai/responses-api/) for *everything* because it's new. Vanilla classification is cheaper + lower-latency on [Chat Completions](/stacks/openai/chat-completions/).

## Multi-provider strategy — when to abstract OpenAI

### Position 1: OpenAI-only, direct SDK

**When right:**
- Single-provider strategic commitment.
- Small team; framework overhead would cost more than it saves.
- Compliance + procurement is OpenAI-direct (or Azure OpenAI).
- You want all of OpenAI's surface ([built-in tools](/stacks/openai/built-in-tools/), [Realtime](/stacks/openai/realtime-api/), [Computer Use](/stacks/openai/computer-use/)) and would lose features going through a gateway.

### Position 2: OpenAI-compatible gateway

Helicone, LiteLLM, Portkey, OpenRouter, Bifrost. Most expose Chat Completions wire format.

**When right:**
- Multi-provider routing / failover is a real need.
- Observability + cost-tracking + rate-limit management at a single chokepoint.
- [Chat Completions](/stacks/openai/chat-completions/) covers needs (no built-in tools required).

**Cost:** gateways don't proxy [Responses API](/stacks/openai/responses-api/) + [Realtime](/stacks/openai/realtime-api/) + [Computer Use](/stacks/openai/computer-use/) cleanly. Lose access to differentiated features. Adds 5-50ms latency.

**Recommendation:** put Chat Completions traffic through the gateway. Direct OpenAI for Responses + Realtime.

### Position 3: Framework-level abstraction (LangGraph, Vercel AI SDK)

**LangGraph when:**
- Long-running workflows with checkpoints.
- Multi-agent state machines with conditional edges.
- You need to swap models per-node based on cost/quality.

**Vercel AI SDK when:**
- React / Next.js web app shipping streaming chat.
- `useChat`, `useObject`, RSC streaming for AI-generated UI.
- Vercel-platform shop.

**Cost:** framework overhead; tied to framework cadence.

### Most production deployments

- Direct OpenAI SDK for [Responses](/stacks/openai/responses-api/) / [Realtime](/stacks/openai/realtime-api/) / [Computer Use](/stacks/openai/computer-use/) / Images / Audio.
- Helicone or LiteLLM gateway in front of [Chat Completions](/stacks/openai/chat-completions/) for cost + multi-provider.
- LangGraph only where state machines justify it.

## Caching + routing topology

### Caching layers

1. **OpenAI [prompt caching](/stacks/openai/prompt-caching/) (automatic, server-side)** — 50% off cached input ≥1024 tokens. Architect for cacheability: stable prefix, varying tail.
2. **Application-level exact-match cache** — hash the prompt → Redis. Best for deterministic queries. Hit rate 5-30%.
3. **Application-level semantic cache** — embed the prompt → vector store; cosine similarity > 0.9. Hit rate 15-50% in FAQ-heavy workloads.

**Stack them.** OpenAI prefix cache + your exact-match + your semantic cache. Each layer is independent.

### Routing patterns

1. **Cascading** — try smallest model first; escalate on quality below threshold.
2. **Intent-based** — classify intent up front (cheap model); route based on intent.
3. **Provider routing** — by capacity / cost / latency. At the gateway.

### Where the router lives

| Location | Pros | Cons |
|---|---|---|
| In-app | Simplest, easy to evolve | Hard to share across services |
| Gateway | Centralized, cross-service | Adds a hop |
| Agent ([Agents SDK](/stacks/openai/agents-sdk/) handoffs / LangGraph nodes) | Most flexible | Hardest cost prediction |

### Production architecture for a mid-size deployment

```
client → your service (FastAPI / Next.js)
       → [in-app exact-match cache check]    miss ↓
       → [in-app semantic cache check]        miss ↓
       → [in-app intent classifier (GPT-5 Nano)]
       → route by intent
       → [gateway (Helicone) for cost tracking + multi-provider fallback]
       → [OpenAI (Chat Completions or Responses)]
```

## Org / project / key hierarchy — mapping to your topology

See [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/) for full details.

| Your topology | Org / Project pattern |
|---|---|
| Single product, single team | One org, one project per environment. |
| Multi-product platform | One org per product line, OR one org + one project per product. |
| Multi-tenant SaaS | One org, projects shared; cost attribution at app layer. OR one project per large tenant for hard cost isolation. |
| Internal tools + customer-facing app | Separate orgs (or projects) — different threat models. |

**Minimum:** one project per environment (dev / staging / prod); production project has stricter rate limits + tighter member access + tighter model allowlist + ZDR enabled.

### Model allowlists per project

- Prod project allowlists only models actively used — drift-protects against accidental migration.
- Dev project allowlists everything experimental.
- `computer_use_preview` (see [Computer Use](/stacks/openai/computer-use/)) — allowlist on a separate project gated behind explicit human review.

### Rate limits per project

Set per-project rate limits lower than tier ceiling to:
- Cap dev / staging spend at fraction of prod.
- Prevent runaway feature eating prod headroom.

## Capacity model — usage tiers, rate limits, Scale Tier

### Tier ladder

- Tier 1 — minimal. GPT-5 / o-series / Realtime / Computer Use are gated.
- Tier 2-3 — production-grade for most apps; most models unlocked.
- Tier 4-5 — high-volume.

**Always confirm tier before promising a feature works.**

### Rate limits per model per tier

- RPM (requests per minute).
- TPM (tokens per minute).

Whichever hits first triggers 429. Headers tell you which (`x-ratelimit-*`).

**Capacity planning:** estimate avg prompt + completion size; multiply by traffic; check against tier TPM. If you'll hit 80% of TPM at peak, request higher tier or split across more projects.

### Scale Tier / Priority Processing

Scale Tier = enterprise commit-and-burst pricing. Priority Processing = per-request flag (`service_tier: "priority"`) for higher SLA at higher cost.

**Bring up when:** monthly spend in $50K+ range with predictable load. Otherwise, default API + Batch is fine.

### Rate-limit budgeting at the app layer

Even with tier headroom, enforce per-tenant + per-feature budgets to prevent runaway. Defense against buggy integration or misconfigured loops.

## Reliability + multi-region + multi-provider

### OpenAI direct — single-region behavior

**No public multi-region failover.** If OpenAI's API is degraded, you can't "fail over to us-east-2."

What you can do:
- **Multi-provider failover** — fail over to Anthropic / Gemini via gateway.
- **Multi-model within OpenAI** — fail over from GPT-5 to GPT-4.1 when one model is degraded.

### Azure OpenAI for multi-region

Region-scoped deployments. For multi-region:
- Provision deployments in N regions.
- Route via Azure Front Door / your gateway.
- Active-active or active-passive depending on RPO/RTO.

**Watch:** Azure OpenAI has its own quota model, pricing, model version cadence (lags OpenAI direct by weeks-to-months). Different product surface — same models underneath.

### Bedrock / GCP for OpenAI

Bedrock does **not** host OpenAI models. GCP does not host OpenAI directly. **Azure is OpenAI's hyperscaler partner.**

### SLA posture

- OpenAI direct — stated SLA on Enterprise contract; default is best-effort.
- Azure OpenAI — stated SLA per region per deployment.

**Mission-critical:** Azure OpenAI in 2+ regions + your circuit breakers + multi-provider fallback. Don't promise 99.99% on a single API.

## Residency + compliance posture

### Default API

- **Retention:** 30 days for abuse monitoring (even with `store: false`).
- **Training:** API data not used to train OpenAI models for API customers (verify in current DPA).
- **Region:** any OpenAI region; no data residency guarantee.

### ZDR (Zero Data Retention)

- Negotiate via DPA / sales contract.
- ZDR endpoints don't persist prompts/completions after response.
- Not all models / endpoints are ZDR-eligible.
- Required for HIPAA, certain GDPR postures, government workloads.

### Azure OpenAI for compliance

- **HIPAA:** eligible under Microsoft BAA.
- **FedRAMP High:** Azure OpenAI in Azure Government.
- **EU residency:** deployments in EU regions.
- **SOC 2, ISO 27001:** inherited from Azure.

For regulated workloads, **Azure OpenAI is the path**, not OpenAI direct.

### EU AI Act

Effective August 2026 for high-risk AI obligations. Deployer obligations apply to you. Defer to [security-engineer](/stacks/openai/security-engineer/) for compliance posture.

## Decision frameworks

### Direct SDK vs gateway vs framework

```
Single-provider, OpenAI-only, custom features (Realtime, MCP) → Direct SDK
Multi-provider, simple chat completions                       → Gateway
Complex state machines + checkpointing                         → LangGraph + direct SDK
React web app with streaming chat                              → Vercel AI SDK
Multi-agent supervisor                                          → Agents SDK (OpenAI-only) or LangGraph (cross-provider)
```

### [Responses](/stacks/openai/responses-api/) vs [Chat Completions](/stacks/openai/chat-completions/)

```
Built-in tools needed                  → Responses
Remote MCP servers as tools             → Responses
Server-side conversation state          → Responses
Plain generation / classification       → Chat Completions
OpenAI-compatible 3rd-party endpoint   → Chat Completions
Greenfield in 2026                      → Responses
```

### OpenAI direct vs Azure OpenAI

```
HIPAA / FedRAMP / IL5                  → Azure OpenAI
EU residency contractual                → Azure OpenAI (EU region)
First access to new models              → OpenAI direct (Azure lags)
All features (Realtime, MCP)             → OpenAI direct
On Azure ecosystem already               → Azure OpenAI
Global consumer market                   → OpenAI direct
```

### Build vs buy on agent orchestration

```
1-3 tools, single turn → no orchestration
Multi-turn same agent → Responses + previous_response_id
Handoffs (triage → specialist) → Agents SDK or LangGraph
Long-running workflows with checkpoints → LangGraph + persistence
Human-in-the-loop approvals across days → LangGraph + persistent queue
```

## Product references

- [Responses API](/stacks/openai/responses-api/) — new unified surface.
- [Chat Completions API](/stacks/openai/chat-completions/) — long-term-supported foundation.
- [Assistants API (legacy)](/stacks/openai/assistants-api-legacy/) — sunset H1 2026.
- [Realtime API](/stacks/openai/realtime-api/) — speech-to-speech.
- [Batch API](/stacks/openai/batch-api/) — 50% off, 24h SLA.
- [Agents SDK](/stacks/openai/agents-sdk/) — OpenAI-only orchestration.
- [Built-in tools](/stacks/openai/built-in-tools/) — Responses-only.
- [Prompt Caching](/stacks/openai/prompt-caching/) — automatic, architect for it.
- [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/) — your topology mapping.
- [OpenAI Platform Console](/stacks/openai/openai-platform-console/) — operations surface.
- [Audit Logs](/stacks/openai/audit-logs/) — compliance trail.
- [GPT-5 family](/stacks/openai/gpt-5/) / [GPT-4.1](/stacks/openai/gpt-4-1/) / [o-series](/stacks/openai/o-series-reasoning/) — model defaults in topology decisions.
- [Embeddings](/stacks/openai/embeddings/) — vector DB decision (managed vs custom).

## 2025-2026 platform-reset items relevant to this role

- **[Responses API](/stacks/openai/responses-api/)** is the new unified surface. Greenfield default.
- **[Assistants API (legacy)](/stacks/openai/assistants-api-legacy/)** is deprecating — sunset H1 2026.
- **Project-scoped keys (`sk-proj-…`)** are the production default.
- **Tier-gating** — Tier 1 can't access GPT-5 / o-series / Realtime / Computer Use.
- **Pricing reshuffled twice in 2025-2026** — verify before quoting budget.
- **Azure OpenAI** is the FedRAMP / HIPAA / multi-region path.
- **Scale Tier / Priority Processing** for enterprise commit-and-burst.
- **No public multi-region failover on OpenAI direct.**
- **[Computer Use](/stacks/openai/computer-use/)** typically requires separate project + governance.

## Patterns the role applies

### Topology change discipline

- **Stage one topology change at a time.** Don't introduce gateway + multi-provider + Azure OpenAI + ZDR in the same PR.
- **Load test + dual-write** before cutover.
- **Verify cost + reliability metrics over time.**

### Verification

- Topology changes must be validated against actual usage; eval + cost dashboards before/after.
- Cutovers staged with shadow traffic.

### Brainstorm-first

- "What workload mix?" before "which surfaces?" before "which providers?"
- Don't pick the model first; pick the surface for the workload.

### Self-improvement

- Cost + reliability metrics tracked over time.
- Architecture review every quarter informed by actual usage.

## Cross-references

### Other roles on this Stack

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — model + agent design informed by your topology decisions.
- [backend-architect](/stacks/openai/backend-architect/) — SDK plumbing within services.
- [security-engineer](/stacks/openai/security-engineer/) — security posture your topology must respect.

### Stack index

- [OpenAI Stack](/stacks/openai/) — product table + currency.

### Adjacent Stacks

- `stack-azure` — Azure OpenAI compose point.
- `stack-anthropic-claude` — Claude side of multi-provider builds.
- `stack-vercel` — Vercel AI SDK + AI Gateway.

### Authoritative sources

- [Production best practices](https://platform.openai.com/docs/guides/production-best-practices)
- [OpenAI Platform Console](https://platform.openai.com)
- [OpenAI Status](https://status.openai.com/)
