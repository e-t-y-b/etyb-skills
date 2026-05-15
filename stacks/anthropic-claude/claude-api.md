---
title: Claude API (Messages)
description: The Messages API is the entry point for all Claude work — chat completions, tool use, streaming, vision/PDF input, prompt caching, extended thinking. Same surface on Anthropic API, Bedrock, and Vertex.
product:
  name: Claude API (Messages)
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, system-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/api/
  notes: "Model names rotate every 2-3 months; pricing changes; new beta flags every release."
---

## What it is

The Messages API is the canonical interface to every Claude capability. One endpoint (`POST /v1/messages`) carries chat completions, tool use, streaming via SSE, vision/PDF input, prompt caching breakpoints, extended thinking blocks, Citations, and the Memory tool. Everything else in this Stack — the SDKs, the Agent SDK, Claude Code's underlying calls — composes over the Messages API.

The surface is consistent across all three provider clouds (Anthropic API, [Amazon Bedrock](/stacks/anthropic-claude/bedrock-provider/), [Google Vertex AI](/stacks/anthropic-claude/vertex-ai-provider/)) — only the model ID format and credential handling differ. Authoritative reference: [docs.anthropic.com/en/api](https://docs.anthropic.com/en/api/).

## When to use

The Messages API is the default for any direct Claude integration. Reach past it only when:

- **You're building an agent loop** → use the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) instead; it wraps Messages API with tool-loop, retries, sub-agents.
- **You're running async batch workloads** → use the [Batches API](/stacks/anthropic-claude/batches-api/) (still Messages-shaped under the hood, but submitted in bulk for a 50% discount).
- **You're inside Claude Code / Claude Agent SDK** → the SDK calls Messages API for you; don't drop down.

Don't hand-roll HTTP to `/v1/messages` unless you have a specific reason — the [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) handles retries, idempotency keys, error mapping, streaming, and SSE event parsing better than you will.

## 2025-2026 currency anchors

- **Model IDs rotate every 2-3 months.** Pinning `claude-3-opus-20240229` in 2026 is wrong — that model is retired. Use the current Sonnet 4.x dated ID with a written upgrade plan; never use floating aliases in production without monitoring.
- **`anthropic-beta` headers expire.** Today's beta header is tomorrow's GA. Track which beta flags your code depends on; revisit on every release-notes cycle.
- **Parallel tool use is default on 4.x.** Multiple `tool_use` blocks can come back in one turn — your loop must handle all of them, not just the first.
- **`thinking` content blocks are first-class** (2025) and their `signature` field must round-trip across tool-use turns. Stripping it breaks the request.
- **`document` content blocks** (with the [Citations API](/stacks/anthropic-claude/citations/)) are the supported path for grounded RAG — don't interpolate retrieved text into user messages.
- **Pricing is conditional.** Cache writes cost more than uncached; cache reads are 90% off; Batches are 50% off; >200K input on 1M-context Opus is premium. There's no single $/MTok number.

## Patterns + anti-patterns

### Pattern — typed message structure

The Messages API enforces structure. A "user message" isn't a string — it's a typed content array of `text`, `image`, `document`, `tool_result` blocks. Build messages as structured data; let the SDK serialize.

### Pattern — `system` parameter for the stable prefix

The `system` parameter is treated specially: it's the most stable prefix candidate for [prompt caching](/stacks/anthropic-claude/prompt-caching/), and it's where agent persona / constraints belong. Don't put instructions in a user message that should be in `system`.

### Pattern — `stop_reason` drives your loop

`end_turn` = final answer. `tool_use` = execute the tools, send back `tool_result`. `max_tokens` = you hit the cap; decide if you retry with more budget. `stop_sequence` = your stop sequence fired. `refusal` = the model refused (rare on Claude; verify policy fit). Loop conditions live on this field.

### Anti-pattern — raw HTTP without the SDK

Hand-rolling SSE event parsing, retry-with-backoff, idempotency key generation, error mapping. The SDK exists and does this well — drop down only with a clear reason.

### Anti-pattern — single `$/MTok` cost estimate

A spreadsheet that multiplies "$3/MTok input" by your traffic forecast ignores cache hit rate, output:input ratio, batch eligibility, and 1M-context premium tiers. Real cost requires real measurement on real prompts. See [system-architect's cost framework](/stacks/anthropic-claude/system-architect/#cost-architecture).

### Anti-pattern — no `max_tokens` cap

Output tokens are 5x input tokens in price. An unbounded response on Opus on a 100K-context request burns dollars per call. Always cap `max_tokens` to the actual budget you'll tolerate.

## Gotchas

- **Idempotency.** Network retries can replay a request. The SDK sends an `Idempotency-Key` so you don't double-charge for the same generation. Hand-rolled HTTP misses this.
- **Rate-limit headers** (`anthropic-ratelimit-requests-*`, `anthropic-ratelimit-tokens-*`) on every response. Log them; alert when remaining drops below threshold. Token-based limits (ITPM / OTPM) trigger 429s before request-rate limits do in many workloads.
- **Cross-region availability.** Anthropic API has fewer customer-facing regions than Bedrock / Vertex. For latency, region proximity is the dominant factor — see the [Bedrock provider](/stacks/anthropic-claude/bedrock-provider/) and [Vertex AI provider](/stacks/anthropic-claude/vertex-ai-provider/) pages.
- **Request timeout.** Anthropic API has its own request timeout (~10 minutes, verify current). For long-thinking or long-tool-use work, use the [Batches API](/stacks/anthropic-claude/batches-api/) rather than holding a connection open.

## Cross-references

- [Claude Opus](/stacks/anthropic-claude/claude-opus/), [Claude Sonnet](/stacks/anthropic-claude/claude-sonnet/), [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) — model selection
- [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) — language clients
- [Prompt Caching](/stacks/anthropic-claude/prompt-caching/), [Tool Use](/stacks/anthropic-claude/tool-use/), [Extended Thinking](/stacks/anthropic-claude/extended-thinking/) — features layered on Messages API
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — production wiring
- [Claude API Reference](https://docs.anthropic.com/en/api/) — canonical docs
- [Release Notes](https://docs.anthropic.com/en/release-notes) — for currency
