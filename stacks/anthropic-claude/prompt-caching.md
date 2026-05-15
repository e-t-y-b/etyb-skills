---
title: Prompt Caching
description: Up to 4 cache breakpoints, two TTLs (5-min / 1-hour), 90% off on cache reads. Not an optimization — a primary modeling decision on Claude in 2026.
product:
  name: Prompt Caching
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
  notes: "Pricing 1.25x/2x write; 0.1x read (90% off); two TTLs; up to 4 breakpoints. Architecture decision, not late optimization."
---

## What it is

Prompt caching on Claude lets you mark sections of a request with `cache_control` so the API caches that prefix and reuses it on subsequent matching requests. The economics:

- **Cache write:** 1.25x the normal input price (5-min TTL) or 2x (1-hour TTL).
- **Cache read:** 0.1x the normal input price — **90% off**.
- **Up to 4 cache breakpoints** per request.

Cache reads are 90% off the input price. A system prompt that's reused 100 times an hour saves 90% of its input cost via caching. Designing the prompt as a *cacheable prefix + variable suffix* is a primary modeling decision, not a late optimization. See the [Prompt Caching Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) for current pricing and behavior.

## When to use

Caching pays off when:

- **Substantial stable prefix** (rule of thumb: >1024 tokens) is reused across multiple requests.
- **Hot paths** — system prompt + tool definitions reused per chat session, per agent task, per RAG retrieval cycle.
- **Multi-tenant services** — platform prompt cached across all tenants; tenant context cached per tenant; conversation context cached per session.

Don't cache when:

- **One-off requests** with no expected reuse — the write cost dominates.
- **Tiny prefixes** (<1024 tokens) — overhead exceeds savings.
- **Every request mutates the cached content** — you've defeated caching. Find a different layer for variability.

## 2025-2026 currency anchors

- **Two TTLs:** 5-minute (default, 1.25x write cost) and 1-hour (2x write cost). Both 0.1x read.
- **Up to 4 cache breakpoints** per request.
- **Cache lifetime refreshes on read.** A frequently-read cache stays alive past its nominal TTL.
- **Cache scope.** Per-workspace and per-organization. Not cross-org. Verify cross-workspace behavior with current docs.
- **Bedrock / Vertex parity** — both providers now support prompt caching; historically lagged on details (cache key exact-match semantics, TTL options). Verify against the [Bedrock](/stacks/anthropic-claude/bedrock-provider/) and [Vertex](/stacks/anthropic-claude/vertex-ai-provider/) pages and current docs before assuming parity.
- **Observability fields.** `usage.cache_creation_input_tokens` and `usage.cache_read_input_tokens` on every response. Log both; compute hit rate.

## Patterns + anti-patterns

### Pattern — cache-friendly structure

```
[Stable system prompt]                       ← cached
   + persona
   + capabilities
   + constraints
   + few-shot examples
[Stable tool definitions]                    ← cached (in same breakpoint)
[cache_control: { type: "ephemeral", ttl: "5m" }]  ← breakpoint here
[Variable user input]                        ← not cached
```

Push all variability *after* the cache breakpoint.

### Pattern — multi-tenant layered breakpoints

Up to 4 breakpoints lets you layer caching:

```
[Platform prompt v1]       ← breakpoint 1 (stable across all users)
[Per-tenant config]        ← breakpoint 2 (stable for one tenant)
[Per-conversation context] ← breakpoint 3 (stable for one chat session)
[Current user turn]        ← no breakpoint (changes every request)
```

Reads hit the deepest valid prefix. A new tenant's first request misses everything after breakpoint 1; a returning tenant's request hits everything through breakpoint 2.

### Pattern — TTL selection

- **5-minute** — conversational sessions, chatbots, anything where 2-100 requests come within 5 minutes of the prior. Cheaper to write.
- **1-hour** — long-running batch jobs, agents on multi-task work against the same context, RAG over a fixed corpus during a work session. More expensive to write; pays off if reuse spans >5 minutes.

### Anti-pattern — cache breakpoint after the user message

Self-defeating. The breakpoint applies to *everything up to and including* its position. Putting it after the variable content means every request is a cache miss.

### Anti-pattern — per-user variability in the cached prefix

Even one variable token in the cached prefix invalidates the cache. "You are helping user {user_name} who joined on {join_date}" in the system prompt = never cacheable. Push personalization to the user message, retrieved context, or post-processing.

### Anti-pattern — caching a 100-token system prompt

The write-cost overhead exceeds the savings. Caching is for substantial prefixes only.

### Anti-pattern — caching every request unconditionally

Caching has a write cost. For one-off requests with no expected reuse, it's net-negative. Default-on for hot paths; off for cold.

### Anti-pattern — ignoring `cache_read_input_tokens`

Without observability you don't know if caching works. Log this field; alert when hit rate drops (something broke cacheability — a prompt change, a new variable in the prefix, a model upgrade invalidated all cached entries).

## Gotchas

- **Any whitespace difference invalidates.** Cache keys are based on exact prompt-prefix match. A trailing newline added during a refactor = cold cache everywhere.
- **Model ID upgrades invalidate all caches.** Switching from `claude-sonnet-4-6-20251201` to `claude-sonnet-4-7-20260301` cold-starts caching. Plan upgrades for low-traffic windows if cost matters.
- **Caching doesn't reduce token counts in rate-limit math.** ITPM (Input Tokens Per Minute) limits count cached tokens. Caching saves money, not throughput.
- **Output tokens not cached.** Only the input prefix is cached. The model still generates output fresh each time.
- **Vision content invalidates.** Image content in the cached prefix means the image bytes must match exactly. Push images after the breakpoint if they change per request.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — the underlying API
- [Bedrock Provider](/stacks/anthropic-claude/bedrock-provider/), [Vertex AI Provider](/stacks/anthropic-claude/vertex-ai-provider/) — provider caching parity
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — caching as a modeling decision
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — caching as systems design
- [Prompt Caching Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) — canonical reference
