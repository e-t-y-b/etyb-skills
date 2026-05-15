---
title: AI Gateway
description: Cloudflare's universal model proxy — cache, fallback chains, guardrails, BYOK, rate limiting, evals, and unified analytics across OpenAI, Anthropic, Workers AI, and more.
product:
  name: AI Gateway
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://developers.cloudflare.com/ai-gateway/
  notes: "Provider catalog + features (cache, fallback, guardrails, BYOK) ship continuously; pricing model evolves."
---

## What it is

AI Gateway is Cloudflare's provider-agnostic proxy for LLM and AI calls. Sits between your Worker and the model — whether the model is [Workers AI](/stacks/cloudflare/workers-ai/), OpenAI, Anthropic, Mistral, or another provider. Provides cache (exact + semantic), fallback chains, rate limiting, guardrails (prompt-injection detection), BYOK (managed keys), evals, and unified analytics.

Authoritative reference: [developers.cloudflare.com/ai-gateway](https://developers.cloudflare.com/ai-gateway/).

## When to use

**Every model call should go through AI Gateway** — including Workers AI calls. The free tier covers most teams; paid tiers add log retention and advanced features.

You get for free:

- **Cache** — exact-prompt and semantic cache; significant cost savings on cacheable workloads.
- **Fallback** — primary provider → secondary → tertiary on error/latency/cost.
- **Rate limiting** per-gateway.
- **Guardrails** — prompt-injection classifier (uses Workers AI under the hood).
- **Evals + logging** — every call captured.
- **BYOK / Managed keys** — store provider keys in AI Gateway, rotate without redeploying.
- **Universal endpoint** — one URL, configurable provider per call.
- **Real-time analytics** in dashboard.

Don't bypass AI Gateway for:

- "Just one quick call to OpenAI" — you lose all of the above.
- Workers AI internal calls — Gateway works for them too.
- Low-volume models — the free tier is generous.

## 2025-2026 currency anchors

- **Provider catalog and feature set ship continuously.** Verify against [AI Gateway docs](https://developers.cloudflare.com/ai-gateway/) for current provider list, cache modes, and BYOK scope.
- **Semantic cache** (matches similar prompts via embedding) is a huge cost saver — turn it on for FAQ-style queries.
- **Fallback chains** are configurable per route; universal endpoint accepts an ordered provider list.
- **Guardrails are powered by Workers AI classifiers** under the hood.

## Patterns

### Worker → AI Gateway → OpenAI

```ts
const response = await fetch(
  `https://gateway.ai.cloudflare.com/v1/${ACCOUNT}/${GATEWAY}/openai/chat/completions`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }]
    })
  }
);
```

### Even Workers AI calls go through Gateway

```ts
const response = await env.AI.run("@cf/meta/llama-4-scout-17b-16e-instruct", {
  messages,
  stream: true
}, {
  gateway: { id: env.AI_GATEWAY_ID, cacheTtl: 3600, skipCache: false }
});
```

The Workers AI binding accepts a `gateway` config — pass your gateway ID for cache + analytics through Gateway.

### Universal endpoint with fallback

```ts
const url = `https://gateway.ai.cloudflare.com/v1/${env.ACCOUNT_ID}/${env.GATEWAY_ID}/universal`;
const r = await fetch(url, {
  method: "POST",
  body: JSON.stringify([
    { provider: "workers-ai", endpoint: "@cf/meta/llama-4-scout-17b-16e-instruct", query: { messages } },
    { provider: "openai", endpoint: "v1/chat/completions", headers: { Authorization: "Bearer ..." }, query: { model: "gpt-4o-mini", messages } }
  ])
});
```

AI Gateway tries providers in order until one succeeds.

### Aggressive cache TTL for FAQ-style queries

```ts
const r = await fetch(gatewayUrl, {
  method: "POST",
  headers: {
    "cf-aig-cache-ttl": "86400",  // cache 24h
    "Authorization": `Bearer ${env.PROVIDER_KEY}`,
    "content-type": "application/json"
  },
  body: JSON.stringify({ model, messages })
});
```

For FAQs / docs Q&A / classifier tasks, the same prompt returns the same answer. Gateway cache wins outright. Test **semantic cache** if exact-string matching isn't enough.

### Evals — tag and replay

```ts
const r = await fetch(gatewayUrl, {
  method: "POST",
  headers: {
    "cf-aig-eval": "my-eval-set-id",
    // ...
  },
  body: JSON.stringify({ /* ... */ })
});
```

Query AI Gateway logs API for the tagged set later. Compare model variants by changing `env.LLM_MODEL` and re-running.

## Anti-patterns

- **Calling OpenAI / Anthropic directly from Workers** — lose cache, fallback, eval, analytics, BYOK. Always route through Gateway.
- **Hardcoded provider keys in Worker code** — use BYOK in Gateway; Worker holds a gateway-scoped key only.
- **No cache TTL on cacheable prompts** — default cache TTL is 0 (no cache). Set it explicitly.
- **No fallback chain for production** — single point of failure when the primary provider degrades.

## Gotchas

1. **Cache key includes the prompt and provider params** — slight variations defeat cache. Normalize.
2. **Semantic cache requires embedding compute** — has its own cost; profile before turning on for low-traffic models.
3. **Guardrails add latency** — measure before/after; tune sensitivity.
4. **BYOK keys live in Cloudflare** — rotate per your secret-management cadence.

## Cross-references

- [Workers AI](/stacks/cloudflare/workers-ai/) — even these calls should route through AI Gateway
- [Vectorize](/stacks/cloudflare/vectorize/) — retrieval results feed LLM calls through Gateway
- [AI Search](/stacks/cloudflare/ai-search/) — managed RAG; LLM call lives behind Gateway
- [Workers](/stacks/cloudflare/workers/) — runtime that calls Gateway
- Role overlay: [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/), [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/)
- Authoritative: [developers.cloudflare.com/ai-gateway](https://developers.cloudflare.com/ai-gateway/)
