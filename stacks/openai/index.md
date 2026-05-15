---
title: OpenAI
description: OpenAI platform knowledge overlay — Responses API, GPT-5 / GPT-4.1 / o-series, Agents SDK, Realtime, Computer Use, built-in tools, eval + distillation, project keys. Current to 2026-Q2.
stack:
  vendor: openai
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - ai-ml-engineer
    - backend-architect
    - system-architect
    - security-engineer
  authoritative_sources:
    - { name: "OpenAI Platform Docs",         url: "https://platform.openai.com/docs",                              type: official_docs }
    - { name: "OpenAI API Reference",         url: "https://platform.openai.com/docs/api-reference",                type: api_reference }
    - { name: "OpenAI Changelog",             url: "https://platform.openai.com/docs/changelog",                    type: changelog }
    - { name: "OpenAI Models Catalog",        url: "https://platform.openai.com/docs/models",                       type: official_docs }
    - { name: "OpenAI Pricing",               url: "https://openai.com/api/pricing/",                               type: official_docs }
    - { name: "OpenAI Safety Best Practices", url: "https://platform.openai.com/docs/guides/safety-best-practices", type: security_advisories }
    - { name: "OpenAI Status",                url: "https://status.openai.com/",                                    type: community }
    - { name: "OpenAI Cookbook",              url: "https://cookbook.openai.com/",                                  type: official_docs }
    - { name: "Agents SDK (Python)",          url: "https://github.com/openai/openai-agents-python",                type: api_reference }
    - { name: "Codex CLI",                    url: "https://github.com/openai/codex",                               type: cli_reference }
  delegate_to_skills: []
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="note" title="No first-party MCP server yet">
OpenAI does not (as of `last_verified_on`) publish a first-party MCP server you can plug into Claude Code / Cursor / Codex CLI. The Responses API *consumes* remote MCP servers as a tool surface, but does not *provide* one. `delegate_to_skills` is empty until that ships — ETYB answers from this site for OpenAI knowledge.
</Aside>

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against the OpenAI platform — GPT-5 family (Pro / Standard / Mini / Nano + thinking variants), GPT-4.1, o3 / o4 reasoning models, Responses API, Agents SDK, Realtime API + Realtime Agents, Computer Use Preview, automatic Prompt Caching, Eval + Distillation Platforms, gpt-image-1, omni-moderation.</div>

If today's date is more than 6 months past the last_verified_on above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2023-or-earlier cutoff will get most of these wrong. Even a mid-2024 cutoff will miss the most recent reshuffles.

- **GPT-5 launched (2025) and replaced GPT-4 as the default recommendation.** Tiers are **GPT-5 Pro**, **GPT-5 Standard**, **GPT-5 Mini**, **GPT-5 Nano** plus **thinking variants**. If a user types "use GPT-4 / gpt-4-turbo / gpt-4o" for a new feature, that's a legacy default — offer GPT-5 Standard or GPT-4.1.
- **Responses API is the new unified surface** (`/v1/responses`). It replaces Assistants and is the *only* surface that supports built-in tools (`web_search`, `file_search`, `code_interpreter`, `computer_use_preview`) and remote MCP servers.
- **Assistants API is being deprecated** — sunset is scheduled in the first-half-2026 window. **Do not greenfield on Assistants.** Migrate threads → conversations, tools → built-in tools, vector stores carry over.
- **OpenAI Codex (2025) is an AGENT PRODUCT, not the retired code model.** The 2023 `code-davinci-002` "Codex" was retired in March 2023. The 2025 "OpenAI Codex" is a cloud + IDE coding agent. Always confirm intent before answering "Codex" questions.
- **Codex CLI** (`npm i -g @openai/codex` / `brew install codex`) is open-source and pairs with the cloud Codex product — a peer to Claude Code.
- **Computer Use Preview** (consumer surface: **Operator**) lets the model drive a browser or desktop. Massive safety surface — sandboxing, allowlists, human-in-loop are required, not optional.
- **Prompt Caching is automatic** — no manual breakpoints (distinct from Anthropic). Prompts ≥ 1,024 tokens that share a prefix get cached input at **50% off**.
- **Agents SDK** is the rebranded + hardened Swarm. Python + TypeScript. Handoffs, guardrails, tracing.
- **Realtime API is GA and now ships Realtime Agents** — speech-to-speech with `gpt-realtime` / `gpt-4o-realtime`, WebRTC + WebSocket transports.
- **Structured Outputs `strict: true`** is the production default for any JSON. JSON-schema enforcement at decode time.
- **Predicted Outputs** ship pre-supplied expected output to accelerate generation. Use for code-edit / diff / refactor pipelines.
- **Stored Completions + Eval Platform + Distillation Platform** are three coupled console products that turn production traffic into fine-tuning data.
- **Embeddings have a `dimensions` parameter** (Matryoshka representation) — truncate without retraining.
- **Moderation API is now `omni-moderation`** — multimodal (text + image).
- **Batch API is 50% off with a 24-hour SLA**, covers Chat Completions + Embeddings + Responses.
- **Project-scoped API keys** (`sk-proj-…`) are the production default — user keys are legacy and a security risk.
- **Usage tiers** (1 → 5) gate access to GPT-5 / o-series / Realtime / Computer Use even with a valid key.
- **gpt-image-1 is the new native multimodal image model** — DALL·E 3 is legacy.

If you find yourself recommending GPT-4 by default, the Assistants API for greenfield, `code-davinci-002`, DALL·E 3 for new work, the legacy Moderation API, or user-scoped API keys — you're working from stale knowledge.

## Products covered

Per-product pages under `/stacks/openai/<product>/`.

### Models

| Product | Drift risk | Why |
|---|---|---|
| [GPT-5 family](/stacks/openai/gpt-5/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Launched 2025; replaces GPT-4 as default; pricing reshuffled twice in 2025-2026 |
| [GPT-4.1](/stacks/openai/gpt-4-1/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | April 2025; cost-effective workhorse below GPT-5; 1M-context variant mid-2025 |
| [o-series reasoning models](/stacks/openai/o-series-reasoning/) | <span class="etyb-drift-badge" data-risk="high">high</span> | o3, o4 (mini + standard); chain-of-thought built in; pricing rebalanced 2026 |
| [Vision input](/stacks/openai/vision-input/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Multimodal input as `image_url` parts; per-image token costs apply |

### API surfaces

| Product | Drift risk | Why |
|---|---|---|
| [Responses API](/stacks/openai/responses-api/) | <span class="etyb-drift-badge" data-risk="high">high</span> | New unified surface launched 2025; supersedes Assistants; built-in tools + remote MCP |
| [Chat Completions API](/stacks/openai/chat-completions/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable foundational endpoint; long-term-supported |
| [Assistants API (legacy)](/stacks/openai/assistants-api-legacy/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Deprecation glide path — sunset H1 2026; do not greenfield |
| [Realtime API](/stacks/openai/realtime-api/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2025; voice + multimodal; pricing + audio-token model evolving |
| [Batch API](/stacks/openai/batch-api/) | <span class="etyb-drift-badge" data-risk="low">low</span> | 50% discount, 24-hour SLA; stable |
| [Files API](/stacks/openai/files-api/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Foundational object store for inputs/outputs/fine-tuning data |

### Media + embeddings + moderation

| Product | Drift risk | Why |
|---|---|---|
| [Image generation (gpt-image-1)](/stacks/openai/image-generation/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Native multimodal image model 2025; DALL·E 3 is legacy |
| [Whisper](/stacks/openai/whisper/) | <span class="etyb-drift-badge" data-risk="low">low</span> | whisper-1; competing with gpt-4o-transcribe for streaming |
| [TTS](/stacks/openai/tts/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | tts-1 / tts-1-hd + gpt-4o-audio-preview voices |
| [Embeddings](/stacks/openai/embeddings/) | <span class="etyb-drift-badge" data-risk="low">low</span> | text-embedding-3-large / -small; Matryoshka via `dimensions` |
| [Moderation API](/stacks/openai/moderation-api/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | omni-moderation (multimodal); replaces text-only |

### Capabilities

| Product | Drift risk | Why |
|---|---|---|
| [Function calling / tool use](/stacks/openai/function-calling/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Mature; pair with Structured Outputs |
| [Structured Outputs](/stacks/openai/structured-outputs/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | `strict: true` is the production default for JSON |
| [Built-in tools](/stacks/openai/built-in-tools/) | <span class="etyb-drift-badge" data-risk="high">high</span> | web_search, file_search, code_interpreter, computer_use_preview — Responses-only |
| [Computer Use](/stacks/openai/computer-use/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Browser + desktop control; huge safety surface |
| [Prompt Caching](/stacks/openai/prompt-caching/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Automatic server-side ≥1024 tokens; 50% discount on cached input |
| [Predicted Outputs](/stacks/openai/predicted-outputs/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Pre-supply expected output for code-edit / diff workflows |
| [Stored Completions](/stacks/openai/stored-completions/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Persist completions for eval + distillation pipelines |
| [Vision fine-tuning](/stacks/openai/vision-fine-tuning/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | GA on GPT-4o; image+text training pairs |

### Agents + Codex

| Product | Drift risk | Why |
|---|---|---|
| [Agents SDK](/stacks/openai/agents-sdk/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Rebranded Swarm; Python + TypeScript; handoffs, guardrails, tracing |
| [Realtime Agents](/stacks/openai/realtime-agents/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Voice agent orchestration on Realtime; experimental → production through 2025-2026 |
| [OpenAI Codex (agent product)](/stacks/openai/openai-codex/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Cloud + IDE coding agent 2025; DISTINCT from retired 2023 code-davinci |
| [Codex CLI](/stacks/openai/codex-cli/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Open-source terminal coding agent; pairs with cloud Codex |

### Platform consoles

| Product | Drift risk | Why |
|---|---|---|
| [Agents Platform](/stacks/openai/agents-platform/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Console-side agent surface tied to Agents SDK + Built-in Tools |
| [Eval Platform](/stacks/openai/eval-platform/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replaces legacy openai-evals repo for most use cases; UI + API moving |
| [Distillation Platform](/stacks/openai/distillation-platform/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Console product 2025; chains Stored Completions → Evals → Fine-tuning |
| [OpenAI Platform Console](/stacks/openai/openai-platform-console/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Org / Project / API key hierarchy; primary control plane |
| [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | RBAC + rate limits + model allowlists per project |
| [Audit Logs](/stacks/openai/audit-logs/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Org-level audit log API; full retention enterprise-gated |

## Role overlays

Composed views under `/stacks/openai/<role>/`. Each one stitches together the products that role's work touches on OpenAI.

- [`/stacks/openai/ai-ml-engineer/`](/stacks/openai/ai-ml-engineer/) — model + agent + tool design; evals + distillation
- [`/stacks/openai/backend-architect/`](/stacks/openai/backend-architect/) — SDK plumbing; streaming; idempotency; Realtime server pieces
- [`/stacks/openai/system-architect/`](/stacks/openai/system-architect/) — surface composition; multi-provider; org/project topology
- [`/stacks/openai/security-engineer/`](/stacks/openai/security-engineer/) — keys; RBAC; ZDR; moderation; prompt-injection; Computer Use safety

## Authoritative sources

For verified-current behavior, see the official OpenAI surfaces:

- **[OpenAI Platform Docs](https://platform.openai.com/docs)** — canonical reference
- **[OpenAI API Reference](https://platform.openai.com/docs/api-reference)** — endpoint-by-endpoint
- **[OpenAI Changelog](https://platform.openai.com/docs/changelog)** — what shipped when
- **[OpenAI Models Catalog](https://platform.openai.com/docs/models)** — current model IDs + context windows
- **[OpenAI Pricing](https://openai.com/api/pricing/)** — verify before every budget quote; pricing reshuffles twice a year
- **[OpenAI Safety Best Practices](https://platform.openai.com/docs/guides/safety-best-practices)** — content + abuse policy
- **[OpenAI Status](https://status.openai.com/)** — wire to your incident response
- **[OpenAI Cookbook](https://cookbook.openai.com/)** — official examples + recipes
- **[Agents SDK (Python)](https://github.com/openai/openai-agents-python)** — agent orchestration library
- **[Codex CLI](https://github.com/openai/codex)** — open-source terminal agent

## Delegate skills

No first-party OpenAI-hosted MCP server is generally available in user environments as of the last verification date. The Responses API can *consume* remote MCP servers as a tool surface; OpenAI does not yet *publish* an MCP server with a known skill identifier. Once one ships, it will be added to `delegate_to_skills` and ETYB will defer to it for matching products.

## Compose with other Stacks

- **`stack-anthropic-claude`** — when a team runs both. Both packs apply; let each handle its side.
- **`stack-azure`** — Azure OpenAI Service is a parallel surface. Different versioning cadence, different rate limits, FedRAMP / HIPAA out of the box, different SDK calls (`AzureOpenAI`). This Stack still applies for prompting + model behavior; routing + auth + region semantics defer to `stack-azure`.
- **`stack-aws`** — Bedrock does *not* host OpenAI models. AWS is not a compose point for OpenAI direct.
- **`stack-vercel`** — Vercel AI SDK + AI Gateway sit on top of OpenAI (and others). Vercel pack owns the SDK wiring + Edge runtime; this pack owns OpenAI behavior.
- **`stack-supabase`** / **`stack-cloudflare`** — when OpenAI calls run through Edge Functions or Workers (common for cost + auth offload). Both packs apply.
