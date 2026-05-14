---
name: stack-openai
description: >
  OpenAI platform knowledge overlay for the ETYB team. Loads when work involves the OpenAI ecosystem — OpenAI API, GPT-5 family (Pro / Standard / Mini / Nano), GPT-4.1, o-series reasoning models (o3, o4), Responses API, Chat Completions, Assistants API (deprecated path), Realtime API + Realtime Agents, Agents SDK (formerly Swarm), OpenAI Codex (agent product), Codex CLI, Computer Use Preview / Computer Use API, Structured Outputs, Function Calling / Tool Use, Built-in Tools (web search, file search, code interpreter, computer use), Image generation (gpt-image-1, DALL·E 3 legacy), Whisper, TTS, Embeddings (text-embedding-3-large/small), Moderation API, Batch API, Files API, Vision input, Predicted Outputs, Stored Completions, Logprobs, Streaming, Prompt Caching (automatic), Distillation Platform, Eval Platform, OpenAI Platform Console, Organizations + Projects + API keys, RBAC, Audit Logs, Usage tiers, GPT Store, Custom GPTs. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade OpenAI work as of 2026-Q2.
  Triggers: openai, open ai, gpt, gpt-5, gpt5, gpt-5 pro, gpt-5-pro, gpt-5 standard, gpt-5 mini, gpt-5-mini, gpt-5 nano, gpt-5-nano, gpt-4.1, gpt-4o, gpt-4o-mini, o1, o3, o3-mini, o4, o4-mini, reasoning model, reasoning models, chain of thought, openai api, openai sdk, openai-python, openai-node, responses api, /v1/responses, chat completions, /v1/chat/completions, assistants api, assistants v2, assistants deprecation, realtime api, realtime agents, voice agent, agents sdk, openai agents sdk, swarm, openai codex, codex cli, computer use, computer use preview, operator, browser agent, structured outputs, json schema, strict mode, function calling, tool use, built-in tools, web search tool, file search tool, code interpreter, code interpreter sandbox, vector store, openai vector store, batch api, files api, vision, image input, predicted outputs, stored completions, logprobs, streaming, sse, prompt caching, automatic caching, cached input, distillation, eval platform, openai evals, platform.openai.com, openai dashboard, openai org, openai project, project-scoped api key, sk-proj, openai rbac, audit logs, usage tier, tier 1, tier 5, rate limits, tpm, rpm, gpt store, custom gpts, gpts, gpt builder, dall-e, dall-e 3, gpt-image-1, image generation, whisper, whisper-1, tts-1, tts-1-hd, text-to-speech, speech-to-text, embeddings, text-embedding-3-large, text-embedding-3-small, matryoshka, dimensions parameter, moderation api, omni-moderation, openai-compatible, openai compatible api, function tool, tool result, web_search tool, file_search tool, computer_use_preview, retrieval, openai retrieval, openai fine-tuning, vision fine-tuning, dpo fine-tuning, supervised fine-tuning, custom models, dedicated capacity, scale tier, priority processing, openai status, status.openai.com, soc2 openai, openai zdr, zero data retention, openai dpa, openai enterprise, chatgpt enterprise, chatgpt team, openai for business.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - ai-ml-engineer
    - backend-architect
    - system-architect
    - security-engineer
authoritative_sources:
  primary:
    - { name: "OpenAI Platform Docs",         url: "https://platform.openai.com/docs",                          type: official_docs }
    - { name: "OpenAI API Reference",         url: "https://platform.openai.com/docs/api-reference",            type: api_reference }
    - { name: "OpenAI Changelog",              url: "https://platform.openai.com/docs/changelog",                type: changelog }
    - { name: "OpenAI Models Catalog",         url: "https://platform.openai.com/docs/models",                   type: official_docs }
    - { name: "OpenAI Pricing",                url: "https://openai.com/api/pricing/",                           type: official_docs }
    - { name: "OpenAI Safety Best Practices",  url: "https://platform.openai.com/docs/guides/safety-best-practices", type: security_advisories }
    - { name: "OpenAI Policies",                url: "https://openai.com/policies/",                              type: official_docs }
    - { name: "OpenAI Status",                 url: "https://status.openai.com/",                                 type: status_page }
    - { name: "OpenAI GitHub",                 url: "https://github.com/openai",                                  type: source_code }
    - { name: "OpenAI Cookbook",               url: "https://cookbook.openai.com/",                              type: reference_implementations }
    - { name: "Agents SDK Repo",                url: "https://github.com/openai/openai-agents-python",             type: source_code }
    - { name: "Codex CLI Repo",                url: "https://github.com/openai/codex",                            type: source_code }
delegate_to_skills:
  # OpenAI ecosystem is API-first as of last_verified_on. No first-party OpenAI MCP server
  # is generally available in current users' environments — revisit if OpenAI ships an
  # official MCP server (Responses API can already _consume_ remote MCP, but doesn't
  # _provide_ one for tools like Claude Code yet).
  []
products_covered:
  - { name: "GPT-5 family",                  drift_risk: high,   notes: "Launched 2025; replaces GPT-4 as the default recommendation; Pro / Standard / Mini / Nano tiers + thinking variants; pricing reshuffled twice in 2025-2026" }
  - { name: "GPT-4.1",                       drift_risk: medium, notes: "April 2025; positioned as cost-effective workhorse below GPT-5; long-context optimization; 1M-token variant landed mid-2025" }
  - { name: "o-series reasoning models",     drift_risk: high,   notes: "o3 (full + mini), o4 (mini + standard); chain-of-thought built in; use cases differ from chat models; pricing structure rebalanced in 2026" }
  - { name: "Responses API",                 drift_risk: high,   notes: "New unified surface launched 2025; supersedes Assistants API; built-in tools + remote MCP support; rapidly evolving" }
  - { name: "Chat Completions API",          drift_risk: medium, notes: "Stable foundational endpoint; OpenAI explicitly committed to long-term support; remains the lowest-overhead surface" }
  - { name: "Assistants API",                drift_risk: high,   notes: "Deprecation path announced — first-half-2026 sunset window; migrate to Responses API; flag immediately if a user is greenfielding on Assistants" }
  - { name: "Realtime API",                  drift_risk: high,   notes: "GA 2025; voice + multimodal; gpt-realtime + gpt-4o-realtime models; WebRTC + WebSocket transports; pricing + audio-token model evolving" }
  - { name: "Realtime Agents",               drift_risk: high,   notes: "Voice agent orchestration on top of Realtime API; experimental → production maturity through 2025-2026" }
  - { name: "Agents SDK",                    drift_risk: high,   notes: "Formerly Swarm (experimental); rebranded + hardened 2025; Python + TypeScript; handoffs, guardrails, tracing; surface is still moving" }
  - { name: "OpenAI Codex (agent product)",  drift_risk: high,   notes: "Launched 2025 as cloud + IDE coding agent; DISTINCT from the 2023-retired Codex model; flag immediately if user means the old code-davinci model" }
  - { name: "Codex CLI",                     drift_risk: high,   notes: "Open-source terminal coding agent; npm-distributed (`@openai/codex`); pairs with the Codex web product" }
  - { name: "Computer Use Preview / API",    drift_risk: high,   notes: "Browser + desktop control; consumer surface is `Operator`, API surface is `computer-use-preview` + Responses API tool; safety surface is large" }
  - { name: "Structured Outputs",            drift_risk: medium, notes: "JSON-schema enforcement with `strict: true`; available on Responses + Chat Completions + tool definitions; the production default for any JSON" }
  - { name: "Function Calling / Tool Use",   drift_risk: medium, notes: "Mature; pair with Structured Outputs; tool definitions consume tokens — keep them tight" }
  - { name: "Built-in tools (web/file/code/computer)", drift_risk: high, notes: "Responses-API-only; web_search, file_search, code_interpreter, computer_use_preview; pricing per tool call; quotas vary by tier" }
  - { name: "Prompt Caching",                drift_risk: medium, notes: "Automatic server-side caching ≥ 1024 tokens; 50% cost discount on cached input; NO manual breakpoints (distinct from Anthropic); cache key = prompt prefix + org" }
  - { name: "Predicted Outputs",             drift_risk: medium, notes: "Pre-supply expected output to accelerate generation; relevant for code-edit + diff workflows" }
  - { name: "Stored Completions",            drift_risk: medium, notes: "Persist completions server-side for eval + distillation pipelines; required for the Eval + Distillation platforms" }
  - { name: "Batch API",                     drift_risk: low,    notes: "50% discount, 24-hour SLA; covers Chat Completions + Embeddings + Responses; stable" }
  - { name: "Files API",                     drift_risk: low,    notes: "Foundational object store for assistants/responses inputs + outputs + fine-tuning data; stable" }
  - { name: "Vision input",                  drift_risk: low,    notes: "Multimodal input as `image_url` parts; supported on GPT-4o, GPT-4.1, GPT-5; per-image token costs apply" }
  - { name: "Image generation (gpt-image-1)", drift_risk: high,  notes: "Native multimodal image model launched 2025; DALL·E 3 is legacy; the editing + variations surface unified through gpt-image-1" }
  - { name: "Whisper (audio STT)",           drift_risk: low,    notes: "Stable; whisper-1 endpoint; competing with newer gpt-4o-transcribe surface for streaming use cases" }
  - { name: "TTS API",                       drift_risk: medium, notes: "tts-1 / tts-1-hd + gpt-4o-audio-preview voices; quality + voice catalog expanded 2025-2026" }
  - { name: "Embeddings (text-embedding-3)", drift_risk: low,    notes: "Stable; -large and -small variants; Matryoshka representation via `dimensions` parameter — truncate without retraining" }
  - { name: "Moderation API",                drift_risk: medium, notes: "omni-moderation (multimodal) replaces text-only moderation; mandatory for user-generated content pipelines" }
  - { name: "Distillation Platform",          drift_risk: high,   notes: "Console product launched 2025; chain Stored Completions → Evals → Fine-tuning; surface is new and shifting" }
  - { name: "Eval Platform",                 drift_risk: high,   notes: "Console product launched 2025; replaces the legacy `openai-evals` repo for most use cases; UI + API both moving" }
  - { name: "Fine-tuning (SFT + DPO + Vision)", drift_risk: medium, notes: "Supervised + DPO + Vision fine-tuning all GA; pricing per model varies; o-series fine-tuning landed 2025-2026" }
  - { name: "Custom Models / Dedicated Capacity", drift_risk: medium, notes: "Enterprise contract path; relevant only at scale; mention as escalation, not default" }
  - { name: "OpenAI Platform Console",        drift_risk: medium, notes: "Org → Project → API key hierarchy; project-scoped keys (`sk-proj-…`) are the production default; user keys are legacy" }
  - { name: "Project-scoped API keys",        drift_risk: low,    notes: "`sk-proj-…` keys with per-project quotas + model allowlists + RBAC; mandatory pattern for any production deployment" }
  - { name: "RBAC + Audit Logs",              drift_risk: medium, notes: "Org-level roles + project-level roles; audit log API exists but is enterprise-tier-gated for full retention" }
  - { name: "Usage tiers + rate limits",      drift_risk: high,   notes: "Tier 1 → Tier 5 ladder; auto-promotion on spend + usage; rate limits scale per tier; tier matrix changes per pricing reshuffles" }
  - { name: "Scale Tier / Priority Processing", drift_risk: high, notes: "Enterprise-only commit-and-burst pricing surface; new in 2025-2026; positioning still moving" }
  - { name: "Zero Data Retention (ZDR)",      drift_risk: medium, notes: "Enterprise + API ZDR endpoints available; opt-in via DPA; default API behavior is 30-day abuse-monitoring retention" }
  - { name: "GPT Store + Custom GPTs",       drift_risk: medium, notes: "Consumer-side surface (ChatGPT); API integrators rarely touch it directly; included for completeness when teams ship GPTs alongside API products" }
---

# OpenAI Stack Pack — Team Briefing

You're working on the OpenAI platform. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — ai-ml-engineer designs the agent and picks the model, backend-architect plumbs the SDK into services, system-architect chooses Responses vs Chat Completions vs Realtime, security-engineer locks down keys + Trust + ZDR + Moderation. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against the OpenAI platform surface as of **2026-05-14** — GPT-5 family (Pro / Standard / Mini / Nano + thinking variants), GPT-4.1, o3 / o4 reasoning models, Responses API as the unified surface, Assistants API on the deprecation glide path, Realtime API GA + Realtime Agents, Agents SDK (rebranded from Swarm), OpenAI Codex agent product + Codex CLI, Computer Use Preview, automatic Prompt Caching, Predicted Outputs, Stored Completions, Eval Platform, Distillation Platform, gpt-image-1, omni-moderation. If today's date is more than **6 months past** `last_verified_on`, this pack is stale — warn the user and consult the [OpenAI changelog](https://platform.openai.com/docs/changelog) before recommending model IDs, pricing, or API shapes.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2023-or-earlier cutoff will get most of these wrong. Even a mid-2024 cutoff will miss the most recent reshuffles.

- **GPT-5 launched (2025) and replaced GPT-4 as the default recommendation.** Tiers are **GPT-5 Pro**, **GPT-5 Standard**, **GPT-5 Mini**, **GPT-5 Nano** — plus **thinking variants** for the Pro/Standard tier. If a user types "use GPT-4 / gpt-4-turbo / gpt-4o" for a new feature, that is a legacy default; offer GPT-5 Standard or GPT-4.1 with a one-line rationale.
- **The Responses API is the new unified surface** (`/v1/responses`). It replaces Assistants and is the *only* surface that supports built-in tools (`web_search`, `file_search`, `code_interpreter`, `computer_use_preview`) + remote MCP servers. Chat Completions is still supported long-term, but Responses is the right default for new agentic builds.
- **Assistants API is being deprecated.** OpenAI announced the migration glide path in 2025; the sunset is scheduled in the first-half-2026 window. **Do not greenfield on Assistants.** Migrate threads → conversations, tools → built-in tools or function tools, vector stores stay (Files + Vector Store APIs are now shared with Responses).
- **OpenAI Codex (2025) is an AGENT PRODUCT, not the retired code model.** The 2023 `code-davinci-002` "Codex" was retired in March 2023. The 2025 "OpenAI Codex" is a cloud + IDE coding agent (`codex.openai.com` + `codex` CLI) powered by GPT-5 family / o-series. If a user says "Codex," confirm which they mean before assuming.
- **The Codex CLI** (`npm i -g @openai/codex` / `brew install codex`) is open-source and pairs with the cloud Codex product. It is a peer to Claude Code, not a successor to anything from 2023.
- **Computer Use Preview** (consumer surface: **Operator**) lets the model drive a browser or desktop via screenshots + click/type tool calls. The API exposes it as the `computer_use_preview` tool on Responses + the `computer-use-preview` model. **The safety surface is large** — sandboxing, allowlists, human-in-loop confirmation are required, not optional.
- **Prompt Caching is automatic on the OpenAI platform.** No manual `cache_control` breakpoints (this is distinct from Anthropic). Prompts ≥ **1,024 tokens** that share a prefix with a recent prompt get cached; cached input is billed at **50% off**. Architect for cacheability by keeping the system prompt + few-shot examples + tool definitions stable at the prefix, and varying the user message at the tail.
- **The Agents SDK (Python + TypeScript) is the rebranded + hardened Swarm.** It is the OpenAI-native answer to multi-agent orchestration: handoffs, guardrails, tracing, deterministic tool routing. `openai-agents-python` is the import path. It is the right default if you are OpenAI-only; if you need to swap providers, stay on direct SDK + LangGraph.
- **Realtime API is GA and now ships Realtime Agents.** Speech-to-speech with `gpt-realtime` / `gpt-4o-realtime`, WebRTC for low-latency in-browser, WebSocket for server-side. Realtime Agents wrap the Realtime API with handoff + tool-call + transcript primitives.
- **Structured Outputs with `strict: true`** is the production default for any JSON. It enforces the JSON schema at decode time — no parsing failures, no malformed JSON. Use it on tool definitions (`"strict": true`) and on response format (`response_format: { type: "json_schema", strict: true }`).
- **Predicted Outputs** ship pre-supplied expected output along with the request to accelerate generation. The model treats the prediction as a strong hint and skips ahead on matching tokens. Use for code-edit / diff / refactor pipelines where most of the output is unchanged.
- **Stored Completions + Eval Platform + Distillation Platform** are three coupled console products. Turn on `store: true` on a completion → query it in the Eval platform → distill into a fine-tuned smaller model. This is now the OpenAI-native loop for "GPT-5 in dev → fine-tuned 4o-mini in prod."
- **Embeddings have a `dimensions` parameter** (Matryoshka representation). `text-embedding-3-large` defaults to 3072 dimensions, but you can truncate to 1024 / 512 / 256 without retraining. Smaller dims = lower storage + faster ANN + slightly lower recall.
- **Moderation API is now `omni-moderation`** — multimodal (text + image). Old `text-moderation-latest` still works but `omni-moderation-latest` is the default for new pipelines.
- **Batch API is 50% off with a 24-hour SLA.** Available for Chat Completions, Embeddings, and Responses (Responses-batch went GA late 2025). The default home for evals, classification jobs, content generation, embedding refreshes.
- **Project-scoped API keys** (`sk-proj-…`) replace user-scoped keys as the production pattern. Every production deployment should use a project key with a model allowlist, a per-project rate limit, and the project's own service account / audit log scope. **User keys (`sk-…` legacy) leaking is a much bigger blast radius** — flag if you see them in code.
- **Usage tiers ladder from Tier 1 → Tier 5.** Auto-promotion on cumulative spend + age. Each tier raises rate limits + unlocks specific models. **GPT-5 / o-series / Realtime / Computer Use are tier-gated** — a project on Tier 1 cannot access them even with a valid key.
- **Scale Tier / Priority Processing** is OpenAI's commit-and-burst enterprise contract — pay for guaranteed throughput, burst above commit at a premium. Mention it only at enterprise scale.
- **GPT-image-1 is the new native multimodal image model.** DALL·E 3 is legacy. gpt-image-1 supports generation + editing + variations + transparent background in one surface.

If you find yourself recommending GPT-4 by default, the Assistants API for a greenfield project, `code-davinci-002`, DALL·E 3 for new work, the legacy Moderation API, or user-scoped API keys — you're working from stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects OpenAI signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The OpenAI overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform:

- **TDD on agents** = unit tests on the function tool implementations + Eval Platform datasets gating CI for the full agent loop.
- **Verification** = log the full `(request, response, tool_calls, usage)` tuple in a tracing platform (Langfuse / Helicone / Braintrust / OpenAI Platform Logs) and assert on cost + latency + structured-output validity per call.
- **Debugging** = always grab `request_id` from response headers (`x-request-id`); OpenAI support will not engage without it. Reproduce with `temperature=0` + identical prompt before assuming a bug is non-deterministic.

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **The model + agent decision** — GPT-5 vs GPT-4.1 vs o3/o4 vs realtime; Responses vs Chat Completions vs Assistants; Agents SDK orchestration; built-in tools; Structured Outputs + tool design; embeddings + vector stores; fine-tuning + distillation; eval + observability |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | SDK plumbing (Python + TypeScript); streaming (SSE) wiring through services; idempotency keys + retries + circuit breakers; webhook + Batch API integration; Realtime API on the server (WebSocket); function-tool implementation discipline; cost + token accounting in app code |
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | API-surface selection (Responses vs Chat Completions vs Realtime vs Batch); multi-provider abstraction tradeoffs (direct SDK vs LangGraph vs Vercel AI SDK vs gateway); caching + routing topology; org-project-key topology; Scale Tier vs default capacity; ZDR + residency posture |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | Project-scoped keys + key rotation + scope-down posture; RBAC + audit logs; ZDR + DPA + retention; Moderation API placement; prompt-injection defense for Responses + Built-in Tools + Computer Use; PII handling; OWASP LLM Top 10 mapped to OpenAI primitives; abuse + content policy posture |

## Top platform gotchas the team must know

These are the failure patterns we see repeatedly. Memorize them.

1. **Don't conflate "Codex" 2023 and "Codex" 2025.** The 2023 model `code-davinci-002` was retired in March 2023. The 2025 OpenAI Codex is a coding agent product. Same brand, totally different artifact. Confirm intent before answering.

2. **Don't greenfield on Assistants API.** It is on the deprecation glide path. Responses API is the answer. If you see `client.beta.threads.create(...)` in 2026 code, the team is building tech debt.

3. **Responses API is required for built-in tools.** `web_search`, `file_search`, `code_interpreter`, `computer_use_preview` only exist on Responses. Chat Completions can't call them. If a user wants "an agent that can browse the web" in 2026, that's Responses (or Agents SDK on top), not Chat Completions.

4. **Prompt Caching is automatic but order-sensitive.** Cache key is the *prefix* of the prompt up to the first divergence. Put the stable parts at the top (system message → tool definitions → few-shot examples → retrieved context) and put the user message at the bottom. Reorder and you blow the cache for every old request.

5. **Structured Outputs `strict: true` does NOT auto-parse JSON for you on Chat Completions function tools.** The tool-call `arguments` field is still a JSON-encoded string — you must `JSON.parse()` it. The `strict: true` guarantee is *schema compliance*, not *Python/JS object return*. The Responses API returns the object pre-parsed; Chat Completions does not.

6. **`temperature` does not exist on o-series.** o3, o4 are reasoning models with built-in chain-of-thought. Pass `reasoning.effort` (`low` / `medium` / `high`) instead. Passing `temperature` is silently ignored (or errors, depending on SDK version).

7. **Reasoning tokens are billed as output tokens but invisible by default.** o-series models emit reasoning tokens before the visible answer. They count against your output token budget AND your output cost. Plan for 2-10x output token usage when switching from GPT-5 to o3/o4.

8. **Tier-gating bites at deploy time.** A new project starts at Tier 1, which doesn't have access to GPT-5 family / Realtime / Computer Use. Auto-promotion needs spend + age. **Always confirm the project tier before promising a feature works.**

9. **Project-scoped keys (`sk-proj-…`) are the only safe production pattern.** User keys (`sk-…` legacy) tie to a human; if that human leaves, the key is a security incident, not a deletion. Project keys are scoped by org admin, can be model-allowlisted, can be rotated independently. **Flag user keys in production code.**

10. **Realtime API audio tokens are NOT chat tokens.** Audio input + output have separate per-minute pricing, separate caching rules, and separate context limits. Reading "Realtime is the same price as Chat Completions" is wrong. Always check the dedicated Realtime pricing page.

11. **Computer Use requires explicit human-in-the-loop on irreversible actions.** OpenAI documents this as a safety requirement, not a recommendation. Form submits, purchases, destructive deletes — all require confirmation in your application loop. Failing to enforce this is the path to PR-disaster headlines.

12. **Default Data Retention is 30 days for abuse monitoring.** Even with `store: false`. Enterprise customers can negotiate ZDR (zero data retention) via the DPA. If a user says "we can't have data go to OpenAI at all," that is a contract conversation (`sales@openai.com`), not a code conversation — escalate to procurement.

## Compliance composition

When OpenAI work composes with a vertical Stack (fintech, healthcare, e-commerce, SaaS), the vertical owns compliance discipline and this pack owns the OpenAI mechanism:

- **Healthcare** — OpenAI is **not HIPAA-covered by default**. ChatGPT Enterprise / API on the BAA path is required for PHI. Defer all HIPAA semantics to `healthcare-architect`; this pack tells you which API surfaces are eligible (Enterprise API + ZDR + signed BAA), not what HIPAA actually requires.
- **Fintech** — OpenAI is not the system of record for transactions or balances. Use OpenAI for understanding (intent classification, document extraction, agent assistance), not for moving money. Defer ledger / PCI / PSD2 / AML to `fintech-architect`.
- **EU AI Act / GDPR** — EU residency for OpenAI requires explicit configuration. Defer GDPR semantics to `security-engineer` general practice; this pack tells you what data classes flow through what endpoints and what ZDR + DPA buys you.
- **Education / public sector** — FERPA, FedRAMP, IL5 surfaces exist as enterprise contract paths (Microsoft Azure OpenAI Service is the typical FedRAMP path, not OpenAI direct). Flag explicitly when scope demands them.

## Currency — when this pack is stale

This pack is stale if **any** of these is true:

- `last_verified_on` is more than 6 months old (today's date is past 2026-11-14).
- A new major GPT model (GPT-6, o5, equivalent) has shipped and isn't named in this pack.
- The Assistants API has fully sunset and we still describe it as "deprecating."
- The Responses API has shipped a new top-level concept not named in this pack.
- A new built-in tool has shipped (e.g., a generally-available `image_generation` tool, a new `database_query` tool) and isn't named in `products_covered`.

**To refresh:** read [the OpenAI changelog](https://platform.openai.com/docs/changelog) end-to-end since `last_verified_on`, the [models catalog](https://platform.openai.com/docs/models), and the latest two OpenAI keynote / DevDay summaries. Bump `metadata.last_verified_on` and add a `last_verified_release` line if a named DevDay anchored the refresh.

## Stack composition with other ETYB Stacks

If the user is on OpenAI **plus** another stack, both overlays load:

- **`stack-anthropic-claude`** — When a team runs Claude AND OpenAI (multi-provider routing, A/B between Sonnet and GPT-5 Standard, agent built on Claude with OpenAI moderation, etc.). Both packs apply; let each handle its side. Don't pretend either is the other.
- **`stack-aws`** (Bedrock) / **`stack-azure`** (Azure OpenAI Service) — OpenAI models are also accessible through hyperscaler-hosted surfaces. **Azure OpenAI is a different product** from OpenAI direct — different model versioning cadence, different rate limits, different compliance (FedRAMP, HIPAA out of the box), different SDK calls (`AzureOpenAI` class). When the user is on Azure OpenAI, this pack still applies for prompting + model behavior, but routing + auth + region semantics defer to `stack-azure`.
- **`stack-vercel`** — Vercel AI SDK + AI Gateway sit on top of OpenAI (and others). Vercel pack owns the SDK wiring + Edge runtime; this pack owns the OpenAI-specific behavior the SDK is calling into.
- **`stack-supabase`** / **`stack-cloudflare`** — When OpenAI calls run through Supabase Edge Functions or Cloudflare Workers (common for cost + auth offload). Both packs apply.

## Standing instructions for every role on an OpenAI engagement

1. **Pick the API surface before the model.** Responses API for agentic / tool-using / built-in-tools workloads. Chat Completions for vanilla generation + classification + extraction. Realtime for speech. Batch for non-interactive. Picking model first ("we'll use GPT-5") and then surface ("how do I add a web-search tool?") leads to API surface re-architecture mid-build.

2. **Default to GPT-5 Standard, not GPT-5 Pro.** Pro is for the hardest reasoning, longest-context, and highest-stakes workloads. Standard is the production default. Mini and Nano exist for cost-sensitive tiers — route deliberately, don't default low.

3. **Use Structured Outputs by default for any JSON.** `strict: true`. Defining a Pydantic / Zod schema and feeding it into `response_format` or the tool definition is cheaper, more reliable, and faster to debug than parsing free-form JSON.

4. **Wire observability before the second feature ships.** Even with OpenAI Platform Logs, you want app-level tracing. `request_id` on every response. Token + cost per request stamped on every trace. Cost-by-feature dashboards before scale.

5. **Read the pricing page before quoting a budget.** OpenAI reshuffles pricing twice a year on average. The numbers in your training data are wrong. Verify against [openai.com/api/pricing](https://openai.com/api/pricing) every quote.

6. **Never put OpenAI keys in the browser.** Even Realtime browser sessions use **ephemeral tokens** (created server-side, short TTL, scoped to that session). Frontend code does not see the long-lived key. Direct browser → OpenAI with a real key is an immediate findings-letter security issue.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Vertical compliance (HIPAA, PCI, PSD2, FERPA) | `healthcare-architect` / `fintech-architect` / vertical pack |
| Hyperscaler-hosted OpenAI (Azure OpenAI, Bedrock GPT family) | `stack-azure` / `stack-aws` (plus this pack for the OpenAI behavior surface) |
| Non-OpenAI providers in a multi-provider system | `stack-anthropic-claude` (or other provider stack) for *that* provider's behavior surface |
| Pure web frontend / SSE-rendering issues | `frontend-architect` (no OpenAI overlay needed) |
| Pure infrastructure questions (Kubernetes, IaC) outside of OpenAI deployment | `devops-engineer` / hyperscaler stack |

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- **GPT Store / Custom GPTs deep coverage.** These are consumer-side (ChatGPT) artifacts. API integrators rarely touch them; we keep coverage thin and flag if the team is shipping Custom GPTs as a deployment vehicle.
- **Azure OpenAI Service deep coverage.** That's the `stack-azure` pack's territory; we describe it as a compose point, not the primary surface.
- **Sora / video generation.** Coverage will land when the API surface stabilizes. As of 2026-Q2, Sora is the consumer surface and the public API for video generation is still early.
- **OpenAI o-series for tools beyond text** (multimodal o-series reasoning). Pricing + capability is moving; coverage is flagged at the high level and deferred for a 4.x release.
- **OpenAI MCP server.** No first-party MCP server from OpenAI yet. The Responses API *consumes* remote MCP servers as a tool surface, but does not *publish* an MCP server you can plug into Claude Code / Cursor / Codex CLI. Revisit `delegate_to_skills` when that ships.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.
