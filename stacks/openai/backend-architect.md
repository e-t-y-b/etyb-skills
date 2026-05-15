---
title: backend-architect on OpenAI
description: SDK plumbing, streaming, idempotency, Realtime server pieces, function-tool runtime, cost + token accounting. The engineer who turns model design into production services.
role_overlay:
  role: backend-architect
  stack: openai
  last_verified_on: "2026-05-14"
  products_covered:
    - chat-completions
    - responses-api
    - assistants-api-legacy
    - realtime-api
    - batch-api
    - files-api
    - function-calling
    - structured-outputs
    - prompt-caching
    - stored-completions
    - vision-input
    - embeddings
    - gpt-5
    - gpt-4-1
    - o-series-reasoning
    - openai-platform-console
    - organization-project-hierarchy
---

## Role briefing — what you own on OpenAI

You are the **backend-architect** plumbing OpenAI into production services. You own:

1. **SDK initialization + config** — base URLs, organizations, [projects](/stacks/openai/organization-project-hierarchy/), ephemeral tokens, retries.
2. **Service architecture** — where OpenAI calls live (sync API, background worker, [Batch](/stacks/openai/batch-api/) job, queue consumer).
3. **Streaming** — SSE through your gateway → client; backpressure; reconnect; error mid-stream.
4. **Idempotency + retries + circuit breakers** — request IDs, exponential backoff, fallback chains.
5. **[Function-tool](/stacks/openai/function-calling/) runtime** — input validation, error handling, idempotency, observability.
6. **Webhook + [Batch](/stacks/openai/batch-api/) wiring** — submit + poll + consume + reconcile.
7. **[Realtime API](/stacks/openai/realtime-api/) server pieces** — WebSocket bridge or ephemeral-token mint endpoint for WebRTC.
8. **Cost + token telemetry** — token counts on every span; cost computed per request; budgets per feature.

You do **not** own:

- Model + prompt + agent design — that's [ai-ml-engineer](/stacks/openai/ai-ml-engineer/).
- Multi-provider abstraction + topology — that's [system-architect](/stacks/openai/system-architect/).
- Project key + RBAC + ZDR posture — that's [security-engineer](/stacks/openai/security-engineer/).

## Currency stamp

Verified 2026-05-14 against OpenAI Python SDK v1.x, OpenAI Node SDK, [Responses API](/stacks/openai/responses-api/), [Realtime API](/stacks/openai/realtime-api/) (WebRTC + WebSocket), [Batch API](/stacks/openai/batch-api/), Streaming (SSE), [Prompt Caching](/stacks/openai/prompt-caching/) automatic, project-scoped API keys.

## SDK setup — the production-correct baseline

### Python

```python
from openai import OpenAI
client = OpenAI(
    api_key=os.environ["OPENAI_API_KEY"],          # sk-proj-... (project-scoped)
    organization=os.environ.get("OPENAI_ORG_ID"),
    project=os.environ.get("OPENAI_PROJECT_ID"),
    timeout=60.0,
    max_retries=2,
    default_headers={"X-Internal-Trace-Id": trace_id},
)
```

For async: `from openai import AsyncOpenAI`.

### TypeScript

```typescript
import OpenAI from 'openai';
const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  organization: process.env.OPENAI_ORG_ID,
  project: process.env.OPENAI_PROJECT_ID,
  timeout: 60_000,
  maxRetries: 2,
  defaultHeaders: { 'X-Internal-Trace-Id': traceId },
});
```

### Key handling rules

- Never read keys from anything but a secrets store. No committed `.env`. No hardcoded keys.
- Project-scoped keys (`sk-proj-…`) only for production — see [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/).
- **One key per service.** Easier to rotate; smaller blast radius if leaked.
- Frontend never sees the key. Server-side proxy for browser calls; ephemeral tokens for [Realtime](/stacks/openai/realtime-api/) WebRTC.

## Streaming — SSE through your service

OpenAI's `stream=true` returns SSE. Your service must relay the stream — not buffer-and-return.

### Python (FastAPI)

```python
@app.post("/chat")
async def chat(req: ChatRequest):
    def event_stream():
        stream = client.chat.completions.create(
            model="gpt-5",
            messages=req.messages,
            stream=True,
            stream_options={"include_usage": True},  # MUST include for cost data
        )
        for chunk in stream:
            yield f"data: {chunk.model_dump_json()}\n\n"
        yield "data: [DONE]\n\n"
    return StreamingResponse(event_stream(), media_type="text/event-stream")
```

### Critical: `stream_options.include_usage=True`

Without it, streamed responses **omit the `usage` object** — no `prompt_tokens`, no `completion_tokens`, no `cached_tokens`, no `reasoning_tokens`. **You cannot bill or observe cost without it.** Set it always.

### Backpressure + cancellation

- Client disconnects mid-stream → abort the upstream request. Detect via `request.is_disconnected()` (FastAPI); cancel the SDK iterator.
- Multi-minute streams → emit heartbeats (empty SSE event every 15s) so proxies don't kill the connection.

### Errors mid-stream

Catch the exception. Emit a final SSE event with an error marker. Log `request_id` + error + partial output. Client distinguishes error events from data events.

### Streaming Structured Outputs

JSON arrives token by token. Cannot `JSON.parse()` until stream completes. Options:

- Buffer + parse at end (simplest; lose streaming UX).
- Streaming partial parser (`useObject` in Vercel AI SDK; custom logic).
- [Responses API](/stacks/openai/responses-api/) typed events for per-event handling.

## Function-tool runtime discipline

### Critical: Chat Completions tool args are strings

Even with [Structured Outputs](/stacks/openai/structured-outputs/) `strict: true`, [Chat Completions](/stacks/openai/chat-completions/) returns `tool_call.function.arguments` as a JSON-encoded string. Parse it:

```python
for tool_call in response.choices[0].message.tool_calls:
    args = json.loads(tool_call.function.arguments)
    result = run_tool(tool_call.function.name, args)
    messages.append({
        "role": "tool",
        "tool_call_id": tool_call.id,
        "content": json.dumps(result),
    })
```

[Responses API](/stacks/openai/responses-api/) returns parsed objects directly.

### Tool runtime rules

1. **Validate inputs even with `strict: true`.** Schema strictness guarantees JSON shape — not business rules.
2. **Be idempotent.** Idempotency keys derived from tool args. Models retry tool calls.
3. **Return structured errors, not exceptions.** `{"success": false, "error": "..."}` lets the model recover.
4. **Timeout aggressively.** Tools in a real-time agent loop should be sub-30s. Long-running work hands off to background.
5. **Observe per-tool latency + error rate.**

## Idempotency, retries, circuit breakers

### Retries

SDK auto-retries 429 + 5xx (default `max_retries=2`). Production:

```python
client.with_options(
    timeout=120.0,
    max_retries=4,
    default_headers={"Idempotency-Key": f"create-ticket-{user_id}-{request_id}"},
).chat.completions.create(...)
```

### Circuit breakers

Trip on sustained > X% error rate, latency > Z ms p95, or hard failures clustered. Don't trip on single 429 with `Retry-After` or slow o-series. Libraries: `pybreaker` (Python), `opossum` (Node).

### Fallback chain

1. Smaller model ([GPT-5 Mini](/stacks/openai/gpt-5/) → Nano).
2. Different provider (Anthropic, Gemini) via gateway.
3. Cached or templated response.
4. Clean "service degraded" error.

## Realtime API on the server

See [Realtime API](/stacks/openai/realtime-api/) for full details. Server pieces:

### WebRTC pattern (browser, server mints token)

```
1. Client requests session: POST /api/realtime/session on your server.
2. Server: POST /v1/realtime/sessions → ephemeral client_secret.value (~60s TTL).
3. Server returns ephemeral token to client.
4. Client establishes WebRTC peer connection to OpenAI directly using ephemeral token.
5. Audio + events flow browser ↔ OpenAI direct. Server NOT in the audio path.
```

Lowest latency for browser voice. Real key never leaves the server.

### WebSocket pattern (server-side)

`wss://api.openai.com/v1/realtime?model=gpt-realtime`. Authenticate with real key. Stream audio frames (PCM16 / G.711 / Opus); bridge to client however needed.

Use when: client isn't a modern browser, need server-side audio injection, central audio recording.

### Tool calls during Realtime

Tools in `session.update`. Tool call events: `response.function_call_arguments.done`. Run tool. Send `conversation.item.create` with result. Trigger `response.create`. **Sub-200ms tool latency or hand off async** — the user is mid-conversation.

## Webhook + Batch API integration

See [Batch API](/stacks/openai/batch-api/).

### Batch workflow

1. Build JSONL with one request per line + `custom_id`.
2. Upload via [Files API](/stacks/openai/files-api/).
3. Create: `client.batches.create(input_file_id=..., endpoint="/v1/chat/completions", completion_window="24h")`.
4. Poll: `client.batches.retrieve(batch_id)`. Statuses: validating / in_progress / completed / failed / expired.
5. Download output; reconcile by `custom_id`.

### Webhooks

OpenAI's webhook surface is small (fine-tune + batch completions). For application-level async: internal queue (SQS / Redis / RabbitMQ / Cloud Tasks) + background worker + WebSocket / SSE push.

## Token + cost accounting

Capture per request:

```python
{
    "request_id": x_request_id_header,
    "model": "gpt-5",
    "prompt_tokens": usage.prompt_tokens,
    "completion_tokens": usage.completion_tokens,
    "cached_tokens": usage.prompt_tokens_details.cached_tokens,
    "reasoning_tokens": usage.completion_tokens_details.reasoning_tokens,
    "cost_usd": compute_cost(model, usage),
    "duration_ms": end - start,
    "tool_calls": [...],
    "feature": "ticket_classification",
    "tenant_id": tenant_id,
}
```

**Refresh the pricing table every quarter** — pricing has reshuffled twice in 2025-2026.

Per-tenant + per-feature daily/monthly budgets enforced at the app layer. OpenAI's project rate limits help but are project-wide; app budgets are per-tenant.

## Decision frameworks specific to backend-architect

### Decision: where do OpenAI calls live

```
User-blocking, real-time         → Synchronous handler with streaming
User-blocking, seconds-tolerant  → Sync handler with async response (poll or push)
Non-blocking, scheduled           → Background worker + queue
Bulk, predictable                 → Batch API (50% off, 24h SLA)
```

### Decision: streaming format to the client

```
Web client → SSE
WebSocket client → WS frames (your protocol)
Mobile → SSE or WS, platform-dependent
Non-streaming environment → Buffer + return when done
```

## Product references

- [Chat Completions API](/stacks/openai/chat-completions/) — `JSON.parse()` tool args; `stream_options.include_usage=True`.
- [Responses API](/stacks/openai/responses-api/) — parsed tool calls; typed event stream.
- [Assistants API (legacy)](/stacks/openai/assistants-api-legacy/) — migration path.
- [Realtime API](/stacks/openai/realtime-api/) — WebSocket bridging + ephemeral-token mint endpoint.
- [Batch API](/stacks/openai/batch-api/) — 50% off, 24h SLA.
- [Files API](/stacks/openai/files-api/) — JSONL upload/download.
- [Function calling / tool use](/stacks/openai/function-calling/) — runtime discipline.
- [Structured Outputs](/stacks/openai/structured-outputs/) — strict mode; parsing differs by surface.
- [Prompt Caching](/stacks/openai/prompt-caching/) — capture `cached_tokens`.
- [Stored Completions](/stacks/openai/stored-completions/) — `store: true` semantics + ZDR interaction.
- [Vision input](/stacks/openai/vision-input/) — image tokens count against prompt budget.
- [Embeddings](/stacks/openai/embeddings/) — batch path for refresh.
- [GPT-5 family](/stacks/openai/gpt-5/) / [GPT-4.1](/stacks/openai/gpt-4-1/) / [o-series](/stacks/openai/o-series-reasoning/) — snapshot pinning.
- [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/) — project keys, tier-gating.
- [OpenAI Platform Console](/stacks/openai/openai-platform-console/) — Platform Logs.

## 2025-2026 platform-reset items relevant to this role

- **Project-scoped keys (`sk-proj-…`)** are the production default.
- **`stream_options.include_usage=True`** is mandatory on streaming for cost data.
- **`x-request-id`** captured on every response; non-negotiable for OpenAI support tickets.
- **[Responses API](/stacks/openai/responses-api/)** returns parsed tool calls; [Chat Completions](/stacks/openai/chat-completions/) returns JSON-encoded strings.
- **Snapshot pinning** (e.g., `gpt-5-2026-04-01`) for high-stakes workloads.
- **[Realtime API](/stacks/openai/realtime-api/) ephemeral tokens** for WebRTC.
- **[Batch API](/stacks/openai/batch-api/)** wraps Chat Completions + Embeddings + Responses at 50% off.
- **Tier-gating** — Tier 1 can't access GPT-5 / o-series / Realtime / Computer Use.

## Patterns the role applies

### TDD on OpenAI features

- Mock the SDK with recorded responses (`pytest-recording` Python / `nock` Node). Replay in CI; no live calls during tests.
- Tool runtime unit tests are pure functions.
- Integration tests against a low-tier test project in CI.

### Verification

- Streaming requests verified end-to-end (client receives all chunks + `[DONE]`).
- Cost + tokens logged per request.
- `request_id` captured on every response.

### Debugging on OpenAI

1. `x-request-id` from response headers.
2. Reproduce with `temperature=0` + `seed`, or pin snapshot model.
3. Inspect raw response JSON; don't trust SDK shorthand.
4. OpenAI Platform Logs in [Console](/stacks/openai/openai-platform-console/).
5. Tier + rate-limit confirmation.
6. Open OpenAI support with `request_id`.

### Branch safety

Integration tests run against `OPENAI_API_KEY` in CI's dedicated test project (low tier, low budget). **Production keys never touch CI.**

## Cross-references

### Other roles on this Stack

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — model + prompt + agent design you're plumbing.
- [system-architect](/stacks/openai/system-architect/) — topology + multi-provider.
- [security-engineer](/stacks/openai/security-engineer/) — keys, RBAC, ZDR.

### Stack index

- [OpenAI Stack](/stacks/openai/) — product table + currency.

### Authoritative sources

- [OpenAI Python SDK](https://github.com/openai/openai-python)
- [OpenAI Node SDK](https://github.com/openai/openai-node)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Production best practices](https://platform.openai.com/docs/guides/production-best-practices)
