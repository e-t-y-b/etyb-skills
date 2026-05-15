---
title: Prompt Caching
description: Automatic server-side caching ≥1024 tokens at 50% off on cached input. No manual breakpoints (distinct from Anthropic). Architect for cacheability by keeping the prefix stable.
product:
  name: Prompt Caching
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://platform.openai.com/docs/guides/prompt-caching
  notes: "Automatic since 2024; discount + threshold stable; caching applies to all surfaces (Chat Completions, Responses, Realtime audio with lower hit rate)."
---

## What it is

OpenAI caches the **prefix** of every prompt ≥ 1,024 tokens for a short window (~5-10 minutes idle, longer for active conversations). Subsequent prompts that share the same prefix get the cached tokens at **50% off** input pricing.

**This is distinct from Anthropic.** No `cache_control` breakpoints. No explicit cache writes. Fully automatic.

Reference: [Prompt Caching guide](https://platform.openai.com/docs/guides/prompt-caching).

## When to use

**Always.** Prompt Caching is automatic — you don't opt in, you architect for it. The question is whether your prompt is structured to benefit.

You benefit when:

- Prompts ≥ 1,024 tokens.
- Multiple requests share a long prefix (system prompt + tool definitions + few-shot + retrieved context).
- The varying tail (the user message) is the only change between requests.

You don't benefit when:

- Prompts are short (<1,024 tokens).
- Every request has a unique prefix (e.g., per-request timestamp in system prompt).
- Tool definitions / few-shot get reordered per request.

## 2025-2026 currency anchors

- **Automatic.** No breakpoints. No manual cache writes. (Different from Anthropic's explicit `cache_control` model.)
- **Threshold: 1,024 tokens.** Below that, no caching.
- **Discount: 50% off cached input tokens.**
- **TTL: ~5-10 minutes idle**, extended on active conversations.
- **Cache key = prompt prefix + org.** Cache is scoped to your org; users + tenants under the same org share the cache (which can be a privacy concern — see below).
- **Realtime API has cached audio input** since 2025, but hit rates are much lower than text (audio frames vary frame-by-frame).
- **`usage.prompt_tokens_details.cached_tokens`** tells you how many tokens hit the cache on each response. Capture it for observability + cost auditing.

## Patterns

### Pattern: architect for cacheability

Put the **stable** parts of the prompt at the top:

1. System prompt.
2. Tool definitions (Responses tool list / Chat Completions tools array).
3. Few-shot examples.
4. Retrieved RAG context (cacheable if you re-use the same retrieved chunks; not if every query retrieves different chunks).
5. **User message at the bottom.**

Then **vary only the tail** (the user message). Each request hits a long stable prefix → cache hit → 50% off input.

### Pattern: stable system prompt at the very top

```
[STABLE]
- System: "You are a customer support agent..."
- Tools: [10 tool definitions, stable order]
- Few-shot: [5 examples, stable order]
- Retrieved chunks: [stable per session if RAG re-uses]
[VARIES]
- User: "the actual question this turn"
```

### Pattern: multi-turn conversation

Each new user message extends the prefix. Every prior turn's text gets cached. With a 50K-token conversation and a 200-token new user message, you pay full price on ~200 tokens and 50% on ~50K. Costs collapse.

### Pattern: observability

Log `usage.prompt_tokens_details.cached_tokens` per request. Track cache-hit ratio = `cached_tokens / prompt_tokens`. Aim for 50-80% on conversational workloads; >80% on workloads with very stable system + tools.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Timestamp / request UUID in system prompt | Move it elsewhere or eliminate. Every request misses cache. |
| Reordering tools / few-shot per request | Stable order. |
| Per-user data in system prompt | Splits cache N-ways across users. Move user data to the user message or use a different placement strategy. |
| Frequent prompt revisions during dev | Cache resets each time. Expected during dev; quantify the impact on production. |
| Putting the user message at the top | Cache busts every request. User message at the bottom. |
| Not measuring `cached_tokens` | You can't optimize what you don't measure. Log it. |
| Assuming Anthropic-style cache_control behavior | OpenAI has no breakpoints. Don't add them; they're ignored. |
| Long retrieved context that varies per query (RAG with fresh chunks) | Lower cache hit; ok if quality demands. But: consider hybrid (stable persona + retrieved tail) prompt design. |

## Gotchas

- **Cross-tenant cache visibility risk.** Cache is keyed at the org level. Tenant A's prefix and Tenant B's prefix, if identical, share the cache. If your prompts contain tenant-specific data, that data won't leak (the cache stores the model's KV state, not raw prompt text returned to other users), but **don't rely on cache opacity for tenant isolation** — see [security-engineer overlay](/stacks/openai/security-engineer/).
- **Cache hit is not guaranteed even with a stable prefix.** Eviction happens; cache TTL is short.
- **Cache benefits only `input`** — output tokens are billed at full rate.
- **Realtime audio caching** has much lower hit rates than text; don't budget heavily on it.
- **First request after a deploy** is a cache miss for everyone. Plan rollouts.
- **Doesn't apply to fine-tuned models** the same way — check current behavior on your specific fine-tuned model.

## Cross-references

### Related products in this Stack

- [Chat Completions API](/stacks/openai/chat-completions/) — caching applies.
- [Responses API](/stacks/openai/responses-api/) — caching applies.
- [Realtime API](/stacks/openai/realtime-api/) — audio caching with lower hit rate.
- [GPT-5 family](/stacks/openai/gpt-5/) / [GPT-4.1](/stacks/openai/gpt-4-1/) / [o-series](/stacks/openai/o-series-reasoning/) — caching applies across model families.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — prompt structure for cacheability.
- [backend-architect](/stacks/openai/backend-architect/) — cache observability in logs.
- [system-architect](/stacks/openai/system-architect/) — caching in the cost-optimization stack.

### Authoritative sources

- [Prompt Caching guide](https://platform.openai.com/docs/guides/prompt-caching)
- [OpenAI Pricing](https://openai.com/api/pricing/)
