---
role: backend-architect
stack: openai
last_verified_on: "2026-05-14"
---

# OpenAI — backend-architect Overlay

You are the backend-architect plumbing OpenAI into a production service. The ai-ml-engineer picks the model + agent shape + tool design. You own SDK wiring, streaming through your services, idempotency + retries + circuit breakers, webhook + Batch API integration, Realtime API on the server, function-tool runtime implementation, and token + cost accounting in app code.

**Currency stamp:** verified 2026-05-14 against the OpenAI Python SDK v1.x, OpenAI Node SDK, Responses API, Realtime API (WebRTC + WebSocket), Batch API, Streaming (SSE), Prompt Caching automatic surface, project-scoped API keys.

## Role briefing — what you own on OpenAI

You own:

1. **SDK initialization + config** — base URLs, organizations, projects, ephemeral tokens, retries.
2. **Service architecture** — where OpenAI calls live (synchronous API, background worker, batch job, queue consumer).
3. **Streaming surface** — SSE through your gateway → client; backpressure; reconnect; error mid-stream.
4. **Idempotency + retries** — request IDs, exponential backoff, circuit breakers, fallback chains.
5. **Function-tool runtime** — the actual Python / TS code that runs when the model calls a tool. Input validation, error handling, idempotency, observability.
6. **Webhook + Batch wiring** — submit + poll + consume + reconcile.
7. **Realtime server pieces** — WebSocket bridge if applicable; ephemeral token mint endpoint; audio frame buffering.
8. **Cost + token telemetry** — token counts on every span; cost computed per request; budgets per feature.

You do **not** own:

- Model selection or prompt design (`ai-ml-engineer`).
- Multi-provider abstraction (`system-architect`).
- Project key + RBAC + ZDR posture (`security-engineer`).

## SDK setup — the production-correct baseline

### Python

```python
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["OPENAI_API_KEY"],   # sk-proj-... (project-scoped)
    organization=os.environ.get("OPENAI_ORG_ID"),  # org_... — only if multi-org
    project=os.environ.get("OPENAI_PROJECT_ID"),   # proj_... — only if not implicit from key
    timeout=60.0,        # per-request timeout (seconds)
    max_retries=2,        # SDK auto-retries on 429 + 5xx
    default_headers={"X-Internal-Trace-Id": trace_id},  # propagate for log correlation
)
```

For async:

```python
from openai import AsyncOpenAI
client = AsyncOpenAI(...)  # same args
```

### Node / TypeScript

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  organization: process.env.OPENAI_ORG_ID,
  project: process.env.OPENAI_PROJECT_ID,
  timeout: 60_000,        // ms
  maxRetries: 2,
  defaultHeaders: { 'X-Internal-Trace-Id': traceId },
});
```

### Key handling rules

- **Never read the key from anything but the secrets store.** No `.env` committed. No hardcoded keys.
- **Project-scoped keys (`sk-proj-…`) only** for production. User keys are a fire risk; a user leaves = key is orphaned.
- **One key per service.** Don't share across services. Easier to rotate, easier to revoke.
- **Frontend never sees the key.** Server-side proxy for any OpenAI call from the browser; for Realtime, mint ephemeral session tokens server-side.

## Streaming — SSE through your service

OpenAI's `stream=true` returns SSE. Your service needs to relay that stream to the client, not buffer-and-return.

### Python (FastAPI) example

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from openai import OpenAI

app = FastAPI()
client = OpenAI()

@app.post("/chat")
async def chat(req: ChatRequest):
    def event_stream():
        stream = client.chat.completions.create(
            model="gpt-5",
            messages=req.messages,
            stream=True,
            stream_options={"include_usage": True},  # final usage chunk at the end
        )
        for chunk in stream:
            # Each chunk is an SDK object; serialize for SSE
            yield f"data: {chunk.model_dump_json()}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")
```

### Critical: `stream_options.include_usage`

By default, streaming responses omit the `usage` object (because tokens are still being counted). Set `stream_options={"include_usage": True}` to get a final chunk with `prompt_tokens`, `completion_tokens`, `cached_tokens`, and `reasoning_tokens` (for o-series). **Without this you cannot bill or observe cost per streamed request.**

### Backpressure + cancellation

- If the client disconnects mid-stream, you should abort the upstream OpenAI request (don't keep generating tokens for a closed socket).
- Detect via `request.is_disconnected()` in FastAPI; cancel the SDK iterator.
- For long streaming responses (multi-minute), implement a heartbeat (empty SSE event every 15s) to keep proxies / load balancers from killing the connection.

### Errors mid-stream

OpenAI streaming can fail mid-stream. The SDK raises an exception; partial data may have been emitted. Handle:

1. Catch the exception.
2. Emit a final SSE event with an error marker (e.g., `event: error\ndata: {"error": "..."}\n\n`).
3. Log `request_id` + error + partial output.
4. Client-side, distinguish error events from data events.

### Streaming structured outputs

When using `response_format: { type: "json_schema", strict: true }` with streaming, the JSON arrives token by token. Your client cannot `JSON.parse()` until the stream completes — partial JSON is invalid. Options:

- **Buffer + parse at end.** Simplest. Lose the streaming UX benefit.
- **Streaming partial parser** (Vercel AI SDK's `useObject`, custom logic). Emit partial objects to the UI as fields complete.
- **Responses API streaming events** include `response.refusal.delta`, `response.function_call.arguments.delta`, etc. — typed event stream lets you handle each part separately.

## Function tools — runtime implementation discipline

The model emits a tool call. Your runtime executes it. Your runtime is the production code path.

### Tool definition (Chat Completions)

```python
tools = [{
    "type": "function",
    "function": {
        "name": "create_ticket",
        "description": "Create a support ticket. Use when user reports an issue requiring follow-up.",
        "parameters": {
            "type": "object",
            "properties": {
                "title": {"type": "string", "description": "Short title, < 80 chars"},
                "priority": {"type": "string", "enum": ["low", "medium", "high"]},
                "description": {"type": "string"},
            },
            "required": ["title", "priority", "description"],
            "additionalProperties": False,
        },
        "strict": True,  # JSON schema enforcement
    },
}]
```

### Tool definition (Responses API)

Slightly different shape; the `function` wrapper is flatter:

```python
tools = [{
    "type": "function",
    "name": "create_ticket",
    "description": "Create a support ticket...",
    "parameters": { ... },  # same JSON schema
    "strict": True,
}]
```

### Executing the tool call

Chat Completions tool call returns the arguments as a JSON-encoded **string** even with `strict: true`. Parse it.

```python
import json

for tool_call in response.choices[0].message.tool_calls:
    name = tool_call.function.name
    args = json.loads(tool_call.function.arguments)  # always a string
    
    if name == "create_ticket":
        result = create_ticket(**args)  # your business logic
        # append tool result to messages for next turn
        messages.append({
            "role": "tool",
            "tool_call_id": tool_call.id,
            "content": json.dumps(result),
        })
```

Responses API gives you a parsed object directly; less ceremony.

### Tool runtime rules

1. **Validate inputs even with `strict: true`.** Schema strictness guarantees the JSON shape — it does **not** validate that `title` is < 80 chars or that `priority` is one of your enums (well, enums do work; but max-length doesn't enforce at decode-time). Add a Pydantic / Zod second-pass validator.
2. **Be idempotent.** The model may retry a tool call (loops, errors, agent re-runs). If `create_ticket` is called twice with the same args, the second call should not create a duplicate. Use idempotency keys derived from the tool args.
3. **Return structured errors, not exceptions.** Don't let an exception propagate up to the LLM via the tool result; the model gets confused. Return `{"success": false, "error": "<human-readable>"}` and let the model decide what to do.
4. **Timeout aggressively.** A tool call should not be a 30-second operation in a real-time agent loop. Tools that need real work should hand off to a background job and return `{"status": "queued", "job_id": "..."}`.
5. **Observe per-tool latency + error rate.** Tools are your service's API endpoints in disguise. Treat them as such.

### Tool naming + descriptions

The model picks tools based on names + descriptions. **Both matter.**

- **Verb-noun names** — `create_ticket`, `search_invoices`, `escalate_to_human`.
- **Descriptions tell the model when to use the tool.** "Use when..." is more useful than "Does..."
- **One tool, one job.** Don't make a `do_anything` tool. Models picks them better when each tool is narrow.
- **3-7 tools** is the sweet spot. >10 and the model starts confusing them; <3 and you're doing too much in code.

## Idempotency, retries, circuit breakers

### Retries

The OpenAI SDK auto-retries on 429 and 5xx with exponential backoff (default `max_retries=2`). For production, **set `max_retries=3-5` and your own timeout**.

For idempotency on writes (Responses API conversations, fine-tune jobs, batches), pass an `Idempotency-Key` header — OpenAI honors the standard idempotency-key pattern; same key in 24 hours returns the same response.

```python
client.with_options(
    timeout=120.0,
    max_retries=4,
    default_headers={"Idempotency-Key": f"create-ticket-{user_id}-{request_id}"},
).chat.completions.create(...)
```

### Backoff config

Default SDK backoff is exponential with jitter, capped at 8s. For latency-sensitive paths, **lower the cap** by overriding the retry config. For Batch + background paths, the defaults are fine.

### Circuit breakers

When OpenAI is degraded (e.g., elevated error rate on a specific model), trip a circuit:

- **Closed**: normal operation.
- **Open**: fail fast (return cached / fallback / "service degraded" to user); don't hit OpenAI for the window.
- **Half-open**: probe periodically; if probes succeed, return to closed.

Libraries: `pybreaker` (Python), `opossum` (Node). Or integrate with your service mesh (Istio circuit-breaker rules).

**Trip on:**
- Sustained > X% error rate over Y seconds.
- Latency > Z ms p95 sustained.
- Hard failures (`500` / `503`) clustered.

**Don't trip on:**
- Single 429 with `Retry-After` — that's expected backoff, not failure.
- Slow responses for o-series with high reasoning effort — expected.

### Fallback chain

When the circuit is open or a request fails after retries:

1. Fallback to a smaller model (Mini → Nano).
2. Fallback to a different provider (Anthropic, Gemini) via a multi-provider gateway.
3. Fallback to a cached or templated response.
4. Surface a clean "service degraded" error to the user.

The fallback chain is platform-neutral pattern (see `skills/etyb/references/specialists/ai-ml-engineer/`); the OpenAI specific is: **trip on `503`, `429` with no `Retry-After`, and connection errors.**

## Webhook + Batch API integration

### Batch API workflow

1. **Build a JSONL file**, one request per line:

```jsonl
{"custom_id": "req-1", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-5-mini", "messages": [...]}}
{"custom_id": "req-2", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-5-mini", "messages": [...]}}
```

2. **Upload** via Files API: `client.files.create(file=open("requests.jsonl", "rb"), purpose="batch")`.

3. **Create** the batch: `client.batches.create(input_file_id=file.id, endpoint="/v1/chat/completions", completion_window="24h")`.

4. **Poll** status — `client.batches.retrieve(batch_id)`. Statuses: `validating`, `in_progress`, `completed`, `failed`, `expired`.

5. **Download** the output file when `completed`: contains one response per line, matched by `custom_id`.

6. **Reconcile** — match output rows to your job DB. Handle failed rows.

### Webhooks (for non-batch async)

OpenAI's webhooks surface is small (mainly fine-tune job completions, batch completions). For your own application-level async, build:

- Internal queue (SQS, Redis, RabbitMQ, Cloud Tasks).
- Background worker consumes the queue; calls OpenAI.
- Worker writes result + status to your DB.
- API endpoint serves status to client; client polls or you push via WebSocket / SSE.

## Realtime API on the server

Two transport modes for Realtime:

### WebRTC (browser-side, server mints token)

1. Client requests session: `POST /api/realtime/session` on your server.
2. Your server calls OpenAI: `POST /v1/realtime/sessions` with the model, voice, etc. Receive `client_secret.value` (ephemeral token, ~60s TTL).
3. Return the ephemeral token to the client.
4. Client establishes WebRTC peer connection to OpenAI directly using the ephemeral token.
5. Audio + events flow browser ↔ OpenAI directly. Your server is **not** in the audio path.

This is the right architecture for browser-based voice. Lowest latency.

### WebSocket (server-side)

1. Your server connects to OpenAI's Realtime WS: `wss://api.openai.com/v1/realtime?model=gpt-realtime`.
2. Authenticate with the real API key (server-side; not the ephemeral token).
3. Stream audio frames (PCM16, G.711, or Opus) to OpenAI; receive audio + text events back.
4. Bridge to your client however you want (WebSocket to mobile app, RTP to a telephony gateway, etc.).

Use WebSocket when:

- Client isn't a modern browser (mobile native, telephony).
- You need to inject server-side audio (recordings, hold music, transitions).
- You want to record / observe the audio centrally.

### Tool calls during Realtime

The Realtime model can call function tools mid-conversation. Tool definitions are sent in the `session.update` event. Tool call events arrive as `response.function_call_arguments.done`; your code runs the tool; you send a `conversation.item.create` event with the result; trigger a `response.create` to continue.

Latency budget for tool calls is tight — the user is mid-conversation. Tools called in Realtime should be **sub-200ms**. Long-running work needs to be queued + acknowledged.

### Audio + transcripts

Realtime emits both audio and text transcripts. Always log the transcript (text) to your trace store; audio is optional and often subject to consent / retention rules.

## Token + cost accounting

Every OpenAI response carries token counts. Capture them. Compute cost.

### What to log per request

```python
{
    "request_id": response_id_or_x_request_id_header,
    "model": "gpt-5",
    "prompt_tokens": usage.prompt_tokens,
    "completion_tokens": usage.completion_tokens,
    "cached_tokens": usage.prompt_tokens_details.cached_tokens,  # cache hits
    "reasoning_tokens": usage.completion_tokens_details.reasoning_tokens,  # o-series
    "total_tokens": usage.total_tokens,
    "cost_usd": compute_cost(model, usage),
    "duration_ms": end - start,
    "first_token_ms": first_token_time - start,  # streaming
    "tool_calls": [...],
    "feature": "ticket_classification",  # your feature label
    "tenant_id": tenant_id,
}
```

### Cost computation

Pricing table per model from [openai.com/api/pricing](https://openai.com/api/pricing). Bake it into a `compute_cost()` helper that you keep current.

```python
PRICING = {
    "gpt-5": {"input": 0.0/_PER_1M, "output": 0.0/_PER_1M, "cached_input": ...},
    # ... keep current
}

def compute_cost(model, usage):
    p = PRICING[model]
    cached = usage.prompt_tokens_details.cached_tokens or 0
    uncached_input = usage.prompt_tokens - cached
    return (
        uncached_input * p["input"]
        + cached * p["cached_input"]
        + usage.completion_tokens * p["output"]
    )
```

**Refresh the table every quarter.** Pricing reshuffles.

### Streaming + cost

Without `stream_options.include_usage=True`, you don't get usage on streamed responses. **Always include it.** Without usage, you can't bill or observe.

### Cost budgets

For multi-tenant apps, enforce per-tenant + per-feature daily / monthly token budgets at the application layer:

- Pre-check estimated tokens (rough = `len(prompt) / 4` chars-per-token) before making a high-cost request.
- Post-check actual usage; deduct from tenant budget.
- Hard cap: reject calls when over budget; surface cleanly to the user.

OpenAI's project-level rate limits also help, but they're org/project-wide. Application-level budgets are per-tenant.

## Decision framework — when each surface fits

| Need | Pick | Why |
|------|------|-----|
| One-shot generation, classification, extraction | Chat Completions | Lowest overhead; long-term-supported. |
| Multi-turn conversation with tool use | Responses API | Server-side conversation state; agentic loop. |
| Web search / file search / code interpreter / computer use as tools | Responses API | Only surface that supports built-in tools. |
| Long-running multi-day workflow with checkpoints | Direct API + your own state store (or LangGraph + persistence) | Responses doesn't checkpoint; you need durable state in your DB. |
| Bulk processing of 1K-1M jobs | Batch API | 50% cost discount; 24h SLA. |
| Voice in / voice out, sub-second latency | Realtime API (WebRTC for browser) | Speech-native; lowest latency. |
| Voice with telephony / mobile native | Realtime API (WebSocket on your server) | Bridge to non-browser transports. |
| Embeddings refresh on millions of docs | Batch API + Embeddings | Cheapest path. |
| Audio transcription (file-based) | Whisper-1 or gpt-4o-transcribe (batch) | Cheapest; non-streaming. |
| Streaming transcription | gpt-4o-transcribe (streaming) | Lower latency than Whisper. |

## Patterns

### Pattern: Two-phase agent (cheap router → expensive synthesizer)

A common cost-saving pattern:

1. **GPT-5 Nano** classifies the user intent + extracts entities into structured output.
2. Based on the intent, route to:
   - Cheap path: respond with a templated answer or call one cheap tool.
   - Expensive path: invoke **GPT-5 Standard** with rich context for the hard case.

Reduces calls to the expensive model by 50-90%.

### Pattern: Tool result truncation

Tool results can be large (a database query returning 1000 rows). Truncate before feeding back to the model:

```python
def tool_result_for_model(rows):
    if len(rows) > 50:
        return {
            "total_count": len(rows),
            "shown_count": 50,
            "rows": rows[:50],
            "truncated": True,
        }
    return {"total_count": len(rows), "rows": rows}
```

The model knows it got truncated data and can ask follow-up questions for more.

### Pattern: Tool-call audit log

Every tool call is a side effect (or could be). Log:

```python
audit_log({
    "request_id": ...,
    "user_id": ...,
    "tool_name": ...,
    "tool_args": ...,         # what model asked for
    "validated_args": ...,    # what passed validation
    "result_summary": ...,
    "duration_ms": ...,
    "trace_id": ...,
})
```

This is your forensic trail when an agent does something unexpected.

### Pattern: Output caching (semantic + exact)

Beyond OpenAI's input-prefix caching, you can cache outputs at the application layer:

- **Exact-match cache** — hash the prompt; return the cached completion. Works for deterministic queries (classification, extraction).
- **Semantic cache** — embed the prompt; if a cached prompt has cosine similarity > 0.9, return the cached completion. Useful for customer support FAQ patterns.

Redis is the typical store. Watch staleness — invalidate aggressively if context can change.

### Pattern: Sandboxing tool execution

When tools run untrusted-ish operations (file I/O, network calls based on model-generated args), sandbox them:

- Run in a separate process / container.
- Limit time + memory + CPU.
- No access to secrets beyond what the tool needs.
- No access to other tenants' data.

Code Interpreter's sandbox handles this for Python code execution. For your custom tools, you build the sandbox.

## Anti-patterns

| Anti-pattern | Fix |
|--------------|-----|
| Buffering streaming responses before returning to client | Stream end-to-end via SSE. |
| Not setting `stream_options.include_usage=True` | Set it. Without it, no token counts on streams. |
| User key (`sk-...`) in environment / config | Project-scoped key (`sk-proj-...`). |
| Browser uses real API key | Server-side proxy or ephemeral session token (Realtime). |
| Synchronous Batch submit-and-wait | Async; queue + poll + webhook. Batch SLA is 24h. |
| Tool runtime raising exceptions to the SDK | Return structured `{"success": false, "error": "..."}` to the model. |
| Tool calls without idempotency | Idempotency keys derived from tool args. |
| Ignoring `Retry-After` on 429 | Honor it; back off the indicated time. |
| Hardcoding model names | Read from config; pin to snapshot ID for stability (`gpt-5-2026-04-01` not `gpt-5`). |
| Tool descriptions like "Does X" instead of "Use when..." | Use-case-led descriptions; the model is reading them as routing instructions. |
| No `request_id` in your logs | Capture `x-request-id` header on every response. |
| Realtime WebSocket on your server bridging to a browser client | Use WebRTC instead — lower latency, audio bypass. |

## Tooling

### Required app dependencies

- **Python**: `openai`, `pydantic`, `tenacity` (for custom retry policies), `httpx` (already a dep of openai).
- **TypeScript**: `openai`, `zod`, `axios-retry` or custom retry, `eventsource-parser` (for SSE parsing client-side).
- **Observability**: Helicone for cost tracking gateway, Langfuse for self-hosted tracing, OpenTelemetry instrumentation (`opentelemetry-instrumentation-openai`).
- **Testing**: `pytest-recording` (Python) / `nock` (Node) for recording + replaying OpenAI HTTP traffic in tests.

### Server framework patterns

- **FastAPI** — best fit for Python services. Native async, SSE via `StreamingResponse`, easy WebSocket for Realtime bridging.
- **Next.js Route Handlers** — best fit for Vercel-deployed apps; Edge runtime + Streaming response.
- **Hono** — Cloudflare Workers + Edge runtimes; minimal overhead.
- **NestJS** — when the broader service is Nest-shaped; OpenAI integration is just one provider.

### CLI / dev tools

- `openai-python` includes a CLI; rarely needed in production but useful for local debugging.
- `pytest-recording` (`vcr-py`) — record real OpenAI responses to fixture files; replay in CI; no live calls during tests.
- `nock` — same pattern for Node.

## Cross-references

- [`SKILL.md`](../SKILL.md) — team briefing.
- [`references/ai-ml-engineer.md`](ai-ml-engineer.md) — model + prompt + agent design (what you're plumbing).
- [`references/system-architect.md`](system-architect.md) — topology and multi-provider tradeoffs.
- [`references/security-engineer.md`](security-engineer.md) — keys, RBAC, ZDR.
- Specialist skill: `skills/etyb/references/specialists/backend-architect/` — platform-neutral API + service patterns.

## Integration with always-on protocols

| Protocol | OpenAI-specific application |
|----------|----------------------------|
| **TDD** | Mock the SDK with recorded responses (`pytest-recording` / `nock`). Tool runtime unit tests are pure functions. |
| **Verification** | Streaming requests verified end-to-end (client receives all chunks + the `[DONE]`). Cost + tokens logged per request. |
| **Debugging** | Capture `x-request-id` on every response. Reproduce with `temperature=0` + `seed` (or pinned model snapshot). |
| **Plan Execution** | One feature at a time. Don't ship streaming + Batch + Realtime in the same PR; each surface has its own failure modes. |
| **Branch Safety** | Integration tests run against `OPENAI_API_KEY` in CI's dedicated test project (low tier, low budget). Production keys never touch CI. |
| **Subagent Coordination** | When the service has multiple agents (Agents SDK handoffs), one handoff per request; each handoff logged with traces. |
