---
name: stack-openai
description: >
  OpenAI platform knowledge overlay for the ETYB team. Loads when work involves the OpenAI ecosystem — OpenAI API, GPT-5 family (Pro / Standard / Mini / Nano), GPT-4.1, o-series reasoning models (o3, o4), Responses API, Chat Completions, Assistants API (deprecated path), Realtime API + Realtime Agents, Agents SDK (formerly Swarm), OpenAI Codex (agent product), Codex CLI, Computer Use Preview / Computer Use API, Structured Outputs, Function Calling / Tool Use, Built-in Tools (web search, file search, code interpreter, computer use), Image generation (gpt-image-1, DALL·E 3 legacy), Whisper, TTS, Embeddings (text-embedding-3-large/small), Moderation API, Batch API, Files API, Vision input, Predicted Outputs, Stored Completions, Logprobs, Streaming, Prompt Caching (automatic), Distillation Platform, Eval Platform, OpenAI Platform Console, Organizations + Projects + API keys, RBAC, Audit Logs, Usage tiers, GPT Store, Custom GPTs. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade OpenAI work as of 2026-Q2.
  Triggers: openai, open ai, gpt, gpt-5, gpt5, gpt-5 pro, gpt-5-pro, gpt-5 standard, gpt-5 mini, gpt-5-mini, gpt-5 nano, gpt-5-nano, gpt-4.1, gpt-4o, gpt-4o-mini, o1, o3, o3-mini, o4, o4-mini, reasoning model, reasoning models, chain of thought, openai api, openai sdk, openai-python, openai-node, responses api, /v1/responses, chat completions, /v1/chat/completions, assistants api, assistants v2, assistants deprecation, realtime api, realtime agents, voice agent, agents sdk, openai agents sdk, swarm, openai codex, codex cli, computer use, computer use preview, operator, browser agent, structured outputs, json schema, strict mode, function calling, tool use, built-in tools, web search tool, file search tool, code interpreter, code interpreter sandbox, vector store, openai vector store, batch api, files api, vision, image input, predicted outputs, stored completions, logprobs, streaming, sse, prompt caching, automatic caching, cached input, distillation, eval platform, openai evals, platform.openai.com, openai dashboard, openai org, openai project, project-scoped api key, sk-proj, openai rbac, audit logs, usage tier, tier 1, tier 5, rate limits, tpm, rpm, gpt store, custom gpts, gpts, gpt builder, dall-e, dall-e 3, gpt-image-1, image generation, whisper, whisper-1, tts-1, tts-1-hd, text-to-speech, speech-to-text, embeddings, text-embedding-3-large, text-embedding-3-small, matryoshka, dimensions parameter, moderation api, omni-moderation, openai-compatible, openai compatible api, function tool, tool result, web_search tool, file_search tool, computer_use_preview, retrieval, openai retrieval, openai fine-tuning, vision fine-tuning, dpo fine-tuning, supervised fine-tuning, custom models, dedicated capacity, scale tier, priority processing, openai status, status.openai.com, soc2 openai, openai zdr, zero data retention, openai dpa, openai enterprise, chatgpt enterprise, chatgpt team, openai for business.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.2"
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

# OpenAI Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current OpenAI knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/openai/index.md`](index.md)
- **Per-product pages:** `stacks/openai/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/openai/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/openai/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **GPT-5 launched (2025) and replaced GPT-4 as the default recommendation.** Tiers are **GPT-5 Pro**, **GPT-5 Standard**, **GPT-5 Mini**, **GPT-5 Nano** — plus **thinking variants** for the Pro/Standard tier. If a user types "use GPT-4 / gpt-4-turbo / gpt-4o" for a new feature, that is a legacy default; offer GPT-5 Standard or GPT-4.1 with a one-line rationale.
- **The Responses API is the new unified surface** (`/v1/responses`). It replaces Assistants and is the *only* surface that supports built-in tools (`web_search`, `file_search`, `code_interpreter`, `computer_use_preview`) + remote MCP servers. Chat Completions is still supported long-term, but Responses is the right default for new agentic builds.
- **Assistants API is being deprecated.** OpenAI announced the migration glide path in 2025; the sunset is scheduled in the first-half-2026 window. **Do not greenfield on Assistants.** Migrate threads → conversations, tools → built-in tools or function tools.
- **OpenAI Codex (2025) is an AGENT PRODUCT, not the retired code model.** The 2023 `code-davinci-002` "Codex" was retired in March 2023. The 2025 "OpenAI Codex" is a cloud + IDE coding agent (`codex.openai.com` + `codex` CLI) powered by GPT-5 family / o-series.
- **Computer Use Preview** (consumer surface: **Operator**) lets the model drive a browser or desktop via screenshots + click/type tool calls. The API exposes it as the `computer_use_preview` tool on Responses + the `computer-use-preview` model. The safety surface is large — sandboxing, allowlists, human-in-loop confirmation are required.
- **Prompt Caching is automatic on the OpenAI platform.** No manual `cache_control` breakpoints (this is distinct from Anthropic). Prompts ≥ **1,024 tokens** that share a prefix with a recent prompt get cached; cached input is billed at **50% off**.
- **The Agents SDK (Python + TypeScript) is the rebranded + hardened Swarm.** It is the OpenAI-native answer to multi-agent orchestration: handoffs, guardrails, tracing, deterministic tool routing. `openai-agents-python` is the import path.
- **Realtime API is GA and now ships Realtime Agents.** Speech-to-speech with `gpt-realtime` / `gpt-4o-realtime`, WebRTC for low-latency in-browser, WebSocket for server-side.
- **Structured Outputs with `strict: true`** is the production default for any JSON. It enforces the JSON schema at decode time — no parsing failures, no malformed JSON.
- **Stored Completions + Eval Platform + Distillation Platform** are three coupled console products. Turn on `store: true` on a completion → query it in the Eval platform → distill into a fine-tuned smaller model.
- **Project-scoped API keys** (`sk-proj-…`) replace user-scoped keys as the production pattern. Every production deployment should use a project key with a model allowlist, a per-project rate limit, and the project's own service account / audit log scope.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on an OpenAI engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Pick the API surface before the model.** Responses API for agentic / tool-using / built-in-tools workloads. Chat Completions for vanilla generation. Realtime for speech. Batch for non-interactive. Picking model first and then surface leads to API-surface re-architecture mid-build.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch OpenAI | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running OpenAI alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
