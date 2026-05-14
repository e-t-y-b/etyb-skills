---
role: system-architect
stack: openai
last_verified_on: "2026-05-14"
---

# OpenAI — system-architect Overlay

You are the system-architect on an OpenAI engagement. The ai-ml-engineer picks the model and the agent shape; the backend-architect plumbs the SDK; the security-engineer locks down keys + ZDR + moderation. You own the **topology**: which API surfaces compose how, where the abstraction boundaries sit, whether to multi-provider, how the org / project / key hierarchy maps to your tenants, what the cost + reliability + residency posture looks like at scale.

**Currency stamp:** verified 2026-05-14 against the OpenAI platform surface — Responses API + Chat Completions long-term-supported, Realtime API GA, Batch API + Files API, Assistants API on deprecation glide path, automatic Prompt Caching, Scale Tier, ZDR via DPA, Azure OpenAI as a parallel compose point.

## Role briefing — what you own on OpenAI

You own:

1. **API surface composition** — which workloads land on Responses vs Chat Completions vs Realtime vs Batch vs Embeddings.
2. **Multi-provider strategy** — direct SDK vs LangGraph vs Vercel AI SDK vs gateway (Helicone, LiteLLM, Portkey, Bifrost, OpenRouter).
3. **Caching + routing topology** — where the cache lives (app-level semantic, OpenAI prefix, none) and where the router lives (in-app, gateway, agent).
4. **Org / project / key hierarchy** — how it maps to your environments, tenants, features.
5. **Capacity model** — default API + Scale Tier + Batch; usage-tier ladder; rate-limit budgeting.
6. **Residency + compliance posture** — OpenAI direct vs Azure OpenAI for FedRAMP/HIPAA/IL5; ZDR vs default 30-day retention; EU residency posture.
7. **Reliability target** — multi-region (Azure OpenAI), multi-provider (Anthropic / Gemini fallback), graceful degradation.

You do **not** own:

- Specific model + prompt design (`ai-ml-engineer`).
- SDK plumbing within a service (`backend-architect`).
- Key + RBAC + audit log enforcement (`security-engineer`).
- Vertical compliance semantics (vertical pack).

## API surface composition — pick the right surface per workload

A real system has multiple workloads. Don't pick one surface for everything; pick the right surface per workload.

| Workload | Surface | Why |
|----------|---------|-----|
| User-facing chat | Responses API (or Chat Completions if no tools) | Streaming + conversation state + tools. |
| Single-turn classification, extraction, summary | Chat Completions | Lower overhead than Responses; no agentic-loop machinery needed. |
| Agent with web/file/code/computer-use tools | Responses API | Required for built-in tools. |
| Voice agent | Realtime API + Realtime Agents | Speech-native. |
| Bulk classification / embedding refresh | Batch API | 50% cost savings; 24h SLA. |
| Embeddings (interactive) | Embeddings API direct | Synchronous, fast. |
| Embeddings (bulk) | Batch API | 50% off. |
| Image generation | Images API (gpt-image-1) | Specific endpoint. |
| TTS / STT | TTS + Audio Transcriptions APIs | Specific endpoints. |
| Fine-tuning data prep / evals | Eval Platform + Stored Completions | Console-driven. |
| Moderation | Moderation API (omni-moderation-latest) | Always at input + (optionally) output boundary. |

**The mistake to avoid:** picking Responses API for *everything* because it's the new shiny. A vanilla classification call is cheaper + lower-latency on Chat Completions. Use Responses where its features (built-in tools, conversation state, MCP) earn their keep.

## Multi-provider strategy — when to abstract OpenAI away

Three positions, each defensible in the right context.

### Position 1: OpenAI-only, direct SDK

**When this is right:**
- Single-provider strategic commitment.
- Team is small; framework overhead would cost more than it saves.
- Compliance + procurement is OpenAI-direct (or Azure OpenAI) without negotiation room.
- You want all of OpenAI's surface (built-in tools, Realtime, Computer Use) and would lose features going through a gateway.

**Cost:** No portability. Pricing risk is single-vendor.

### Position 2: OpenAI-compatible abstraction (gateway)

Helicone, LiteLLM, Portkey, OpenRouter, Bifrost. Most LLM gateways are OpenAI-compatible — they expose the Chat Completions wire format and route under the hood.

**When this is right:**
- Multi-provider routing or failover is a real need.
- You want observability + cost-tracking + rate-limit management at a single chokepoint.
- The Chat Completions surface covers your needs (i.e., you don't need built-in tools).

**Cost:** Gateways generally don't proxy Responses API + Realtime + Computer Use cleanly. You lose access to OpenAI's most differentiated features. Latency adds 5-50ms.

**Recommendation:** put Chat Completions traffic through the gateway. Direct OpenAI for Responses + Realtime.

### Position 3: Framework-level abstraction (LangGraph, Vercel AI SDK)

LangGraph (Python + TS), Vercel AI SDK (TS).

**When LangGraph is right:**
- Long-running workflows with checkpoints + resumability.
- Multi-agent state machines with conditional edges.
- You need to swap models per-node based on cost/quality requirements.

**When Vercel AI SDK is right:**
- React / Next.js web app shipping streaming chat.
- Want `useChat`, `useObject`, RSC streaming for AI-generated UI.
- Vercel-platform shop.

**Cost:** Framework overhead. Tied to that framework's release cadence + abstractions.

### Decision: when does abstraction earn its keep?

```
Provider-direct                 Gateway                    Framework
        |--------------------------|--------------------------|
single-provider OK         multi-provider routing      complex orchestration
no observability             observability + cost          state machines
direct features (Realtime,  Chat-Completions-only       cross-provider routing
Computer Use, MCP) needed   sufficient                    per-node
```

Most production OpenAI deployments end up with:

- **Direct OpenAI SDK** for Responses / Realtime / Computer Use / Images / Audio.
- **Helicone or LiteLLM gateway** in front of Chat Completions for cost + multi-provider.
- **LangGraph** only where state machines justify it.

## Caching + routing topology

Caching has three layers; routing has three patterns. Pick deliberately.

### Caching layers

1. **OpenAI prompt caching (automatic, server-side)** — 50% off cached input ≥ 1024 tokens. Architect for cacheability: stable prefix, varying tail. No code change.

2. **Application-level exact-match cache** — hash the full prompt; return cached completion. Use Redis. Best for deterministic queries (classification with fixed prompt, repeated extraction). Cache hit rate 5-30% depending on query distribution.

3. **Application-level semantic cache** — embed the prompt; cosine-similarity against cached prompts; return on match. Use Redis (LangCache), Pinecone, Qdrant. Best for FAQ-heavy workloads. ~73% cost reduction in high-repetition workloads per Redis benchmarks. Hit rate ~15-50% in customer-support patterns.

**Stack them.** OpenAI prefix cache + your exact-match cache + your semantic cache. Each layer is independent; each adds savings.

### Routing patterns

1. **Cascading** — try smallest model first; escalate on quality below threshold. Best for max savings; needs a quality eval per step (LLM-as-judge, structured output validation, etc.).

2. **Intent-based** — classify intent up front (cheap model); route based on intent. Predictable costs per feature.

3. **Provider routing** — pick provider by capacity, cost, latency. Done at the gateway. Best when multi-provider is established.

### Where the router lives

- **In-app router** (your code) — simplest. Easy to evolve. Hard to share across services.
- **Gateway router** (Helicone, Portkey, LiteLLM) — centralized; cross-service. Adds a hop.
- **Agent router** (Agents SDK handoffs, LangGraph nodes) — model decides. Most flexible. Hardest to predict cost.

Production architecture for a mid-size deployment:

```
client
  ↓
your service (FastAPI / Next.js)
  ↓
[in-app exact-match cache check]
  ↓ miss
[in-app semantic cache check]
  ↓ miss
[in-app intent classifier (GPT-5 Nano)]
  ↓ route by intent
[gateway (Helicone) for cost tracking + multi-provider fallback]
  ↓
[OpenAI (Chat Completions or Responses)]
```

## Org / project / key hierarchy — mapping to your topology

OpenAI's hierarchy is:

```
Organization (org_…)
  └── Project (proj_…)
        ├── API keys (sk-proj-…)
        ├── Model allowlist
        ├── Rate limits
        ├── Members (RBAC roles)
        └── Usage / billing
```

### How to map this to your environments

| Topology | Org / Project pattern |
|----------|----------------------|
| Single product, single team | One org, one project per environment (dev / staging / prod). |
| Multi-product platform | One org per product line, OR one org + one project per product. |
| Multi-tenant SaaS | One org, projects shared across tenants; cost attribution at app layer. **Or** one project per large tenant for hard cost isolation. |
| Internal tools + customer-facing app | Separate orgs (or projects) — different threat models. Internal tooling keys must never reach customer-facing services. |

**Rule:** at minimum, **one project per environment** (dev / staging / prod), with the production project having stricter rate limits + tighter member access + tighter model allowlist + ZDR enabled.

### Model allowlists per project

Each project can restrict which models its keys can call. Use this:

- Prod project allowlists only the models you actively use. Drift-protect against accidental migration.
- Dev project allowlists everything you might experiment with.
- The "Computer Use Preview" model is dangerous; allowlist on a separate project gated behind explicit human review.

### Rate limits per project

You can also set custom per-project rate limits (lower than your org's tier ceiling). Useful to:

- Cap dev / staging spend at a small fraction of prod.
- Prevent a runaway experiment from eating prod headroom.

## Capacity model — usage tiers, rate limits, Scale Tier

### Tier ladder

Each org has a usage tier from **Tier 1 → Tier 5**. Tier auto-promotes on cumulative spend + account age.

- **Tier 1** — minimal limits. Some models (GPT-5, o-series, Realtime, Computer Use) are gated and not accessible.
- **Tier 2-3** — production-grade for most apps. Most models unlocked. Rate limits in the low thousands of RPM and millions of TPM.
- **Tier 4-5** — high-volume; required for high-traffic apps.

**Always confirm tier before promising a feature works.** A new project on Tier 1 cannot call GPT-5 Pro even with a valid key.

### Rate limits per model per tier

Two limits:

- **RPM** (requests per minute).
- **TPM** (tokens per minute).

Whichever you hit first triggers a 429. Headers tell you which:

```
x-ratelimit-limit-requests: 5000
x-ratelimit-remaining-requests: 4998
x-ratelimit-reset-requests: 30s
x-ratelimit-limit-tokens: 800000
x-ratelimit-remaining-tokens: 799123
x-ratelimit-reset-tokens: 6s
```

**Capacity planning:** estimate average prompt + completion size; multiply by traffic; check against your tier's TPM. If you'll hit 80% of TPM at peak, you need a higher tier (request via support) or to split across more projects.

### Scale Tier / Priority Processing

**Scale Tier** is an enterprise commit-and-burst pricing. You commit to N tokens/month at discounted rates; bursts above commit are at standard or premium rates depending on contract.

**Priority Processing** is a per-request flag (`service_tier: "priority"`) that gives higher SLA at higher cost.

**When to bring it up:** when your monthly OpenAI spend is in the $50K+ range and you have predictable load. Otherwise, default API + Batch is fine.

### Rate-limit budgeting at the app layer

Even with your tier headroom, **enforce per-tenant + per-feature budgets** in your app to prevent a runaway tenant or runaway feature from eating org-wide capacity. This is your defense against a buggy customer integration or a misconfigured loop.

## Reliability + multi-region + multi-provider

### OpenAI direct — single-region behavior

OpenAI's API is globally available but routed through a small number of regions. **There is no public multi-region failover for OpenAI direct.** If OpenAI's API is degraded, you can't "fail over to us-east-2."

What you can do:

- **Multi-provider failover** — when OpenAI is degraded, fail over to Anthropic / Gemini / DeepSeek via a gateway.
- **Multi-model failover within OpenAI** — when one model is degraded (e.g., GPT-5 is overloaded but GPT-4.1 is fine), fail over within the OpenAI fleet.

### Azure OpenAI for multi-region

Azure OpenAI is the multi-region path. Deployments are region-scoped (East US, West Europe, etc.). For multi-region:

- Provision deployments in N regions.
- Route via Azure Front Door / Application Gateway / your gateway.
- Active-active or active-passive depending on RPO/RTO.

**Watch:** Azure OpenAI has its own quota model (DTU / TPU equivalents), its own pricing, and its own model version cadence (typically lagging OpenAI direct by weeks-to-months). It is a different product surface — but the same models underneath.

### Bedrock / GCP for OpenAI?

Bedrock does not host OpenAI models (it hosts Anthropic, Mistral, Meta, etc.). GCP does not host OpenAI directly. **Azure is OpenAI's hyperscaler partner.** If a user asks "can I run OpenAI on AWS Bedrock?" — no.

### SLA posture

OpenAI direct: stated SLA is on the Enterprise contract; default is best-effort. Azure OpenAI: stated SLA per region per deployment.

**For mission-critical:** Azure OpenAI in 2+ regions + your own circuit breakers + multi-provider fallback to Anthropic / Gemini. Don't promise 99.99% on a single API.

## Residency + compliance posture

### Default API

- **Data retention:** 30 days for abuse monitoring (even with `store: false`).
- **Training:** API data is not used to train OpenAI models by default (for API customers). Verify in the current DPA.
- **Region:** Requests can be served from any OpenAI region. No data residency guarantee.

### ZDR (Zero Data Retention)

Enterprise-tier path:

- Negotiate via DPA / sales contract.
- ZDR endpoints have zero abuse-monitoring retention (data does not persist after the response is returned).
- Required for HIPAA, certain GDPR postures, certain government workloads.
- Not all models / endpoints are ZDR-eligible — verify in your DPA.

### Azure OpenAI for compliance

- **HIPAA**: Azure OpenAI is HIPAA-eligible under a Microsoft BAA.
- **FedRAMP High**: Azure OpenAI in Azure Government regions.
- **EU residency**: Azure OpenAI deployments in EU regions (West Europe, Sweden Central, etc.).
- **SOC 2, ISO 27001**: Inherited from Azure.

For regulated / sovereign workloads, **Azure OpenAI is the path**, not OpenAI direct.

### EU AI Act

Effective August 2026 for high-risk AI obligations. Implications:

- Human oversight for high-risk AI use cases.
- Logging retention (10-year rule for technical docs + metadata).
- Inventory of AI systems.

OpenAI is the provider; you are the deployer. **Deployer obligations apply to you.** Defer to `security-engineer` for compliance posture; this Stack tells you what data classes flow through what endpoints.

## Decision frameworks

### Direct SDK vs gateway vs framework

```
Single-provider, OpenAI-only,
custom features (Realtime, MCP)         → Direct SDK
Multi-provider, simple chat completions  → Gateway (Helicone / LiteLLM / Portkey)
Complex state machines + checkpointing   → LangGraph + direct SDK
React web app with streaming chat        → Vercel AI SDK
Multi-agent supervisor architecture       → Agents SDK (OpenAI-only) or LangGraph (cross-provider)
```

### Responses vs Chat Completions

```
Need built-in tools?                  → Responses
Need remote MCP servers as tools?      → Responses
Want server-side conversation state?   → Responses
Plain generation / classification?     → Chat Completions (lower overhead)
OpenAI-compatible 3rd-party endpoint?  → Chat Completions (Responses isn't widely re-implemented)
Greenfield in 2026?                    → Responses, unless you have a specific Chat Completions reason
```

### OpenAI direct vs Azure OpenAI

```
Need HIPAA / FedRAMP / IL5?           → Azure OpenAI
Need EU residency contractual?         → Azure OpenAI (in EU region)
Want first access to new models?        → OpenAI direct (Azure typically lags)
Want all features (Realtime, MCP)?      → OpenAI direct (Azure feature parity lags)
On Azure ecosystem already?             → Azure OpenAI (auth + monitoring + billing align)
Building for global consumer market?    → OpenAI direct (simpler)
```

### Build vs buy on agent orchestration

```
1-3 tools, single turn → no orchestration. Direct API.
Multi-turn with same agent → server-side conversation (Responses with previous_response_id).
Handoffs between agents (triage → specialist) → Agents SDK (OpenAI) or LangGraph (cross-provider).
Long-running workflows with checkpoints → LangGraph + persistence.
Human-in-the-loop approvals across days → LangGraph + persistent queue.
```

## Anti-patterns

| Anti-pattern | Fix |
|--------------|-----|
| Single key shared across dev + staging + prod | One project per environment; one key per service. |
| User-scoped key in prod | Project-scoped key. |
| Responses API used for vanilla one-shot classification | Chat Completions. |
| Greenfielding on Assistants API | Responses API. |
| Multi-provider gateway in front of Realtime API | Direct OpenAI for Realtime — gateways don't proxy it cleanly. |
| Promising 99.99% on OpenAI direct | Azure OpenAI multi-region + multi-provider fallback. |
| HIPAA workload on OpenAI direct | Azure OpenAI + signed BAA. |
| EU residency required, on OpenAI direct | Azure OpenAI in EU region. |
| Cost surprise — no cache architecture | Stable prefix + variable tail; OpenAI prefix cache (auto) + app-level cache. |
| Tier 1 project asked to call GPT-5 Pro | Confirm tier; promote or move to a tier-eligible project. |
| Per-project rate limits unset (relies on tier ceiling) | Set explicit per-project limits to defend against runaway feature. |
| No multi-provider fallback | At minimum, multi-model fallback within OpenAI (GPT-5 → GPT-4.1). For mission-critical, add Anthropic / Gemini via gateway. |
| Sales pricing quoted from training-data values | Quote from current pricing page. Pricing has reshuffled twice in 2025-2026. |

## Topology patterns

### Pattern: Internal agent + external Custom GPT

Some teams ship both:
- An internal API-built agent (Responses + Agents SDK) for the product UI.
- A Custom GPT in the GPT Store for top-of-funnel.

Both share the same business logic (function tools, RAG corpus). Architecture:

```
Shared tier:
  - RAG corpus + Vector Stores
  - Function-tool implementations (HTTP API)
  - Eval datasets

API agent (in product):
  - Responses API + Agents SDK
  - Custom UI with streaming
  - Project A keys

Custom GPT (in ChatGPT):
  - Configured to call your HTTP API for tools
  - OAuth/API-key authentication
  - Project B keys (separate)
```

Don't share keys across projects.

### Pattern: Agent ↔ Batch hybrid

The user-facing agent runs synchronously (Responses API). The agent can request a long-running background job via a tool:

```
User → Agent (Responses, GPT-5)
       Agent calls tool: queue_background_job(prompt=..., model="gpt-5", spec={...})
       Tool returns: {"job_id": "...", "status": "queued"}
       Agent: "I've queued that. You'll get a notification when it's ready."
Background worker:
  Picks job from queue
  Calls Batch API or direct API as appropriate
  Stores result
  Pings user (email, webhook, push)
```

Synchronous user experience + bulk-batch economics.

### Pattern: Distillation production loop

The fine-tuned smaller model in production; the larger model as a fallback + a labeller for the next training round:

```
User request → Fine-tuned GPT-5 Nano (cheap, fast)
              If quality flag (low confidence / structured output failure):
                Escalate to GPT-5 Standard (rich)
              Log (request, fine-tuned-response, gpt-5-response) for next training round
Periodically:
  Sample logged pairs
  Use as training data for next fine-tune
  Eval-gate the new fine-tune
  Deploy if eval improves
```

The model gets better over time without manual prompt iteration.

## Tooling

- **Helicone / Portkey / LiteLLM** — gateway. Cost + multi-provider.
- **Langfuse** — observability + prompt management + evals.
- **OpenAI Platform Console** — primary control plane for org / project / key / usage / eval / distillation.
- **OpenAI status page** ([status.openai.com](https://status.openai.com/)) — wire to your incident response.
- **Azure portal** when using Azure OpenAI — separate control plane.

## Cross-references

- [`SKILL.md`](../SKILL.md) — team briefing + product table.
- [`references/ai-ml-engineer.md`](ai-ml-engineer.md) — model + agent design (informed by your topology decisions).
- [`references/backend-architect.md`](backend-architect.md) — SDK plumbing within services.
- [`references/security-engineer.md`](security-engineer.md) — security posture this topology must respect.
- Specialist skill: `skills/etyb/references/specialists/system-architect/` — platform-neutral architecture patterns.
- Adjacent stack: `stacks/azure/` — compose point for Azure OpenAI workloads.

## Integration with always-on protocols

| Protocol | OpenAI-specific application |
|----------|----------------------------|
| **Verification** | Topology changes (e.g., introducing a gateway, switching to Azure OpenAI) must be staged with load tests + dual-write before cutover. |
| **Plan Execution** | Stage one topology change at a time. Don't introduce gateway + multi-provider + Azure OpenAI + ZDR in the same PR. |
| **Brainstorm-First** | "What workload mix?" before "which surfaces?" before "which providers?" |
| **Subagent Coordination** | When the topology has multi-agent supervision, the supervisor (Agents SDK / LangGraph node) is itself a documented architecture artifact. |
| **Self-Improvement** | Cost + reliability metrics tracked over time; architecture review every quarter informed by actual usage. |
