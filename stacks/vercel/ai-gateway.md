---
title: AI Gateway
description: Vercel-hosted multi-provider routing for LLMs — one API for 100+ models, with caching, retries, fallback, observability, and BYOK.
product:
  name: AI Gateway
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://vercel.com/docs/ai-gateway
  notes: "Model catalog + pricing changes monthly. Always check `/v1/models` at runtime for the live catalog. The catalog includes Anthropic, OpenAI, Google, Mistral, xAI, Groq, Fireworks, Bedrock, Cohere, Together, more."
---

## What it is

AI Gateway is Vercel-hosted multi-provider routing for LLM calls. One SDK, one API, ~100 models across providers (Anthropic Claude, OpenAI GPT, Google Gemini, xAI Grok, Mistral, Groq, Fireworks, Bedrock, Cohere, Together, etc.). Built-in: caching, retries, fallback, observability, BYOK, rate limiting. See [vercel.com/docs/ai-gateway](https://vercel.com/docs/ai-gateway).

## When to use

- **You want one SDK for many models** without per-provider integration code.
- **You want observability** without rolling your own.
- **You want fallback** (Claude down → switch to GPT) without retry plumbing.
- **You're on Vercel and want one bill** (Marketplace billing) — for startups, this wins.
- **You want prompt caching across providers** — Gateway exposes provider-side caching where supported.

When to bypass:

- **You're at high volume** and BYOK + direct billing is cheaper than Vercel's margin.
- **You need provider-specific features** the Gateway doesn't surface yet (rare; Gateway tracks providers fast).
- **You need ultra-low-latency direct provider edge endpoints** (rare).

## 2025-2026 currency anchors

- **Model catalog moves monthly** — never claim a specific model version from memory; check at runtime or [vercel.com/docs/ai-gateway](https://vercel.com/docs/ai-gateway).
- **`@ai-sdk/gateway`** is the SDK package; `gateway('anthropic/claude-sonnet-4.7')` etc.
- **BYOK** in dashboard → AI Gateway → BYOK → add provider keys. Requests bill against your provider account, not the Marketplace. Useful at scale.
- **Provider prompt caching exposed** through `providerOptions` — Anthropic, OpenAI prompt caching available.

## Model selection rubric (2026)

| Use case | Default choice | Rationale |
|----------|----------------|-----------|
| Production chat assistant (general) | Anthropic Claude Sonnet (current generation) via AI Gateway | Best instruction following + tool use; strong reasoning |
| High-volume classification / extraction | Claude Haiku or Gemini Flash via AI Gateway | Cheap; fast; good for structured output |
| Complex reasoning, multi-step planning | Claude Opus, GPT-5 reasoning, Gemini Pro reasoning | Extended thinking / chain-of-thought |
| Code generation + agent code-running | Claude Sonnet (code-trained) + Vercel Sandbox | Best code quality; Sandbox executes safely |
| Long-context (>100k tokens) summary/QA | Claude (200k+ context) or Gemini (1M+ context) | Both excel; Gemini wins on cost for ultra-long |
| Realtime voice | OpenAI Realtime API or Deepgram + ElevenLabs | OpenAI Realtime most integrated; the 3-step is more flexible |
| Embeddings | OpenAI text-embedding-3-small (cheap default), text-embedding-3-large (higher quality), Cohere embed-v3 (multilingual) | Match dimension to vector store config |

**Always verify model names + pricing at runtime** — the Gateway catalog (`/v1/models`) is the source of truth.

## Patterns + anti-patterns

**Pattern: Default routing via `gateway()`.**

```ts
import { gateway } from '@ai-sdk/gateway';
import { streamText } from 'ai';

const result = streamText({
  model: gateway('anthropic/claude-sonnet-4.7'),
  prompt,
});
```

**Pattern: Fallback configuration.**

```ts
const { text } = await generateText({
  model: gateway('anthropic/claude-sonnet-4.7', {
    fallbacks: ['openai/gpt-5-mini', 'google/gemini-2.5-flash'],
    retries: 2,
  }),
  prompt: '...',
});
```

(Exact API surface evolves; check current `@ai-sdk/gateway` docs.)

**Pattern: BYOK at scale.** In Vercel dashboard → AI Gateway → BYOK → add provider keys. Requests then bill against your provider account, skipping Vercel's margin.

**Anti-pattern: Building your own router on top of `streamText`.** You're duplicating Gateway. Use it.

**Anti-pattern: Hardcoding model IDs from 2024 training data.** Catalog updates monthly; check at runtime.

**Anti-pattern: Ignoring cost monitoring.** LLM bills balloon overnight from loops, bad prompts, or model misroute. Cost dashboards and alerts are mandatory.

## Gotchas

- **Gateway prices are pass-through plus a margin.** For huge volume, BYOK direct to the provider is cheaper.
- **The provider catalog updates faster than docs cache** — query `/v1/models` for the live catalog.
- **Per-key, per-project, per-model rate limits** are configurable in the dashboard.
- **Observability dashboard** shows per-request logs, latency, tokens, cost, errors — use it.

## Cross-references

- [AI SDK](/stacks/vercel/ai-sdk/) — pairs with `@ai-sdk/gateway`
- [Chat SDK](/stacks/vercel/chat-sdk/) — uses AI Gateway by default
- [Vercel Agent](/stacks/vercel/vercel-agent/) — composes with AI Gateway
- [ai-ml-engineer on Vercel](/stacks/vercel/ai-ml-engineer/) — full provider strategy
- Authoritative: [AI Gateway docs](https://vercel.com/docs/ai-gateway)
- Delegate: `vercel:ai-gateway`
