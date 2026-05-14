---
role: backend-architect
stack: anthropic-claude
last_verified_on: "2026-05-14"
---

# Anthropic Claude Overlay — backend-architect

You are backend-architect on a Claude engagement. Your job is to wire Claude into a service that survives production: SDK choice, streaming, tool execution, retries, rate-limit handling, the Batches API for async, the Files API for documents, prompt-caching as a *systems* concern, provider routing across Anthropic API / Bedrock / Vertex, and authoring or consuming MCP servers. The ai-ml-engineer overlay owns the prompt and model selection; you own everything between that prompt and a live service.

**Currency:** Anthropic SDK Python v0.79+, TypeScript v0.40+, Go/Java/Ruby first-party SDKs current; Claude 4.x family; MCP spec revision 2025-06-18; Bedrock and Vertex parity verified May 2026.

## SDK selection — Python, TypeScript, Go, Java, Ruby

Anthropic ships first-party SDKs in five languages as of mid-2026. Community SDKs exist for others (PHP, Rust, Kotlin, C#, etc.) — quality varies; verify before depending on a community SDK in production.

| SDK | Package | Maturity | Use when |
|-----|---------|----------|----------|
| **Python** | `anthropic` (PyPI) | Highest — most-used | Python services, data pipelines, ML workloads |
| **TypeScript** | `@anthropic-ai/sdk` (npm) | Highest — Next.js / Node-default | Web services, edge runtime, Next.js servers |
| **Go** | `github.com/anthropics/anthropic-sdk-go` | High | Go services, latency-sensitive backends |
| **Java** | `com.anthropic:anthropic-java` | High | JVM services, Spring Boot integrations |
| **Ruby** | `anthropic` (gem) | Good | Rails apps |

**The two SDKs you'll use 90% of the time are Python and TypeScript.** Everything below is shown in Python; TypeScript is structurally identical (different language idioms).

### Common SDK setup

```python
from anthropic import Anthropic

client = Anthropic()  # reads ANTHROPIC_API_KEY from env

response = client.messages.create(
    model="claude-sonnet-4-7-20260301",
    max_tokens=1024,
    system="You are a customer support agent for ACME Corp.",
    messages=[{"role": "user", "content": "I need help with my order #12345."}],
)
print(response.content[0].text)
```

That's it for non-streaming, non-tool-use. The SDK handles retries, JSON parsing, error mapping. **Don't drop down to raw HTTP unless you have a specific reason** — the SDK adds value at every layer.

### Async / sync

Python SDK exposes both `Anthropic` (sync) and `AsyncAnthropic` (async). Use async in any service handling concurrent requests:

```python
from anthropic import AsyncAnthropic
client = AsyncAnthropic()

async def chat(user_message: str) -> str:
    response = await client.messages.create(
        model="claude-sonnet-4-7-20260301",
        max_tokens=1024,
        messages=[{"role": "user", "content": user_message}],
    )
    return response.content[0].text
```

TypeScript SDK is always async. Go SDK uses context-aware methods (`messages.New(ctx, ...)`); Java SDK has both blocking and reactive flavors.

### Vertex / Bedrock SDKs

The same SDK supports all three providers via different client constructors:

```python
# Anthropic API (default)
from anthropic import Anthropic
client = Anthropic()

# AWS Bedrock
from anthropic import AnthropicBedrock
client = AnthropicBedrock(aws_region="us-east-1")
# Model ID format: "anthropic.claude-sonnet-4-7-20260301-v1:0"

# Google Vertex AI
from anthropic import AnthropicVertex
client = AnthropicVertex(project_id="my-gcp-project", region="us-east5")
# Model ID format: "claude-sonnet-4-7@20260301"
```

The Messages API surface is identical across the three; model ID format and credential handling differ. See the system-architect overlay for choosing among them.

## Streaming — SSE

Streaming is the default UX for anything user-facing. The Anthropic API streams Server-Sent Events; the SDK exposes idiomatic streaming.

### Python streaming

```python
with client.messages.stream(
    model="claude-sonnet-4-7-20260301",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Write a short poem."}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
    # Access the full message at the end
    final = stream.get_final_message()
```

### TypeScript streaming

```typescript
const stream = await client.messages.stream({
  model: 'claude-sonnet-4-7-20260301',
  max_tokens: 1024,
  messages: [{ role: 'user', content: 'Write a short poem.' }],
});

for await (const event of stream) {
  if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
    process.stdout.write(event.delta.text);
  }
}

const final = await stream.finalMessage();
```

### Streaming with tool use

When Claude calls tools mid-stream, you get `tool_use` content blocks streamed in. Pattern:

1. Stream the response; collect any `tool_use` blocks as they complete.
2. When the stream ends (`message_stop` event), execute the tools.
3. Send the assistant message (with `tool_use` blocks) + `tool_result` blocks as a new user message.
4. Stream the next response. Repeat until no more `tool_use`.

The Claude Agent SDK handles this loop. If you're rolling your own, use the SDK's streaming helpers to assemble blocks; don't parse raw SSE events unless necessary.

### Streaming to the client

For an HTTP service that streams Claude to a browser:

- **HTTP/1.1 + SSE:** Works through most proxies. Set `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `X-Accel-Buffering: no` (Nginx).
- **HTTP/2:** Streaming works natively; SSE still good.
- **WebSocket:** Overkill for unidirectional streaming, but fine if you already have a WS infra.
- **gRPC streaming:** For internal service-to-service streaming, not browser.

Don't terminate the stream prematurely on a `tool_use` mid-stream — that's mid-conversation, not end-of-conversation. Wait for `message_stop` from Claude before deciding whether to continue (next tool round) or close to the client.

### Anti-patterns

- **Wrapping streaming in a non-streaming abstraction.** "We'll just await the whole response and return it." You've broken UX; first-token latency is now full-response latency.
- **Streaming to a buffer, returning the buffer.** Same thing — you got the worst of both worlds (server holds resources for the full duration *and* no perceived speedup).
- **Not handling connection drops.** Browser tabs close; networks flake. Detect client disconnect and abort the in-flight API call to stop billing for tokens the user never sees.

## Tool execution loop — the right way

The Messages API tool surface:

1. You declare `tools` in the request.
2. Claude returns assistant message with `tool_use` content blocks (one or more, parallel).
3. You execute each tool, build `tool_result` content blocks.
4. You send a user message with those `tool_result` blocks.
5. Claude returns the next assistant message (more tools, or final text).
6. Loop until `stop_reason: end_turn` (or your iteration cap).

### Minimal correct loop (Python)

```python
def run_agent(client, system, tools, tool_executor, user_message, max_iters=10):
    messages = [{"role": "user", "content": user_message}]

    for _ in range(max_iters):
        response = client.messages.create(
            model="claude-sonnet-4-7-20260301",
            max_tokens=4096,
            system=system,
            tools=tools,
            messages=messages,
        )

        messages.append({"role": "assistant", "content": response.content})

        if response.stop_reason == "end_turn":
            return response  # final answer

        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    result = tool_executor(block.name, block.input)
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result,  # string or list of content blocks
                    })
            messages.append({"role": "user", "content": tool_results})
            continue

        # stop_reason could be max_tokens, stop_sequence, refusal — handle as needed
        return response

    raise RuntimeError("Hit iteration cap")
```

### Production hardening

- **Always cap iterations.** Even with the SDK, set an explicit cap. Unbounded agent loops are how you go broke.
- **Wrap `tool_executor` with timeouts.** A tool that hangs for 30 seconds blocks the agent. Per-tool timeouts (e.g., `asyncio.wait_for`) with sensible defaults.
- **Wrap with error handling.** A tool that raises should return a `tool_result` with `is_error: true` and an error message — *not* propagate up and abort the agent. Let Claude react to the error and try again.
- **Log every tool call.** Tool name, input, output, latency, error. This is your debugging surface.
- **Idempotency keys for side-effecting tools.** If Claude retries a tool (it sometimes does), don't send the email twice. Idempotency on tool name + input hash.
- **Parallel tool execution.** When multiple `tool_use` blocks come back in one response, execute them in parallel (`asyncio.gather` / `Promise.all`). The Agent SDK does this automatically.

### When to use the Claude Agent SDK instead

If you find yourself writing the loop above with retries, timeouts, error handling, parallel execution, sub-agent spawning — **stop. Use the Claude Agent SDK.** It is the loop above with all those features battle-tested.

```python
from claude_agent_sdk import Agent

agent = Agent(
    model="claude-sonnet-4-7-20260301",
    system="...",
    tools=[...],
    max_iters=10,
)
result = await agent.run(user_message="...")
```

Reach for the raw Messages API tool loop when you have constraints the Agent SDK doesn't fit (specific framework integration, custom permission gating, etc.). Most teams should default to the SDK.

## Retries, timeouts, rate limits

### What the SDK handles automatically

- **Transient network errors** — automatic retry with exponential backoff (configurable).
- **429 rate-limit responses** — retries respecting `Retry-After` header.
- **Idempotency for retries** — the SDK sends an `Idempotency-Key` so retries don't double-charge for tokens.

### What you handle

- **Per-request timeout.** Set `timeout=30.0` (or whatever) on the client or per-call. Default may be too long for your latency budget.
- **Token-budget rate limits.** Anthropic rate limits are token-based (Input Tokens Per Minute, Output Tokens Per Minute) in addition to request-based. The SDK doesn't pre-throttle for you; you can hit ITPM and start getting 429s. Configure your application-level token throttling or use a gateway (Helicone, Bifrost, Portkey) that does it for you.
- **Long-running requests.** Anthropic API has its own request timeout (verify current; was ~10 minutes). For batched / long-thinking work, use the Batches API instead of holding a connection open.

### Rate-limit headers

Every response includes:

```
anthropic-ratelimit-requests-limit:  N
anthropic-ratelimit-requests-remaining: N
anthropic-ratelimit-requests-reset:  <ISO 8601>
anthropic-ratelimit-tokens-limit:    N
anthropic-ratelimit-tokens-remaining: N
anthropic-ratelimit-tokens-reset:    <ISO 8601>
```

Log these; alert when remaining drops below a threshold. The SDK exposes them on response objects.

### Anti-patterns

- **No timeout configured.** Default timeouts are long; a hung connection ties up resources.
- **Retrying on 400-class errors.** 400 = your fault; retrying won't help.
- **Ignoring `429 Retry-After`.** Hammering after 429 just gets you longer waits.
- **Single-key, single-workspace, no quotas.** One bug or one bad actor and you've spent your monthly budget in an hour. See the security-engineer overlay on Admin API + spend limits.

## Prompt caching — the systems view

The ai-ml-engineer overlay covers prompt caching as a modeling decision. From the backend side:

- **Caching is per-workspace and per-organization.** Cache entries are not shared across orgs. Cross-workspace caching depends on workspace config (verify; historically scoped at workspace level).
- **Cache key includes the entire prompt prefix up to the breakpoint.** Any difference — even whitespace — invalidates. Be precise.
- **Cache lifetime starts at write, refreshes on read.** A frequently-read cache stays alive past its nominal TTL. A cache read after the TTL has fully expired triggers a re-write at the write price.
- **Observability:** `response.usage.cache_creation_input_tokens` (writes) and `response.usage.cache_read_input_tokens` (reads). Log both; compute hit rate.

### Caching pattern for a multi-tenant service

```python
# Stable platform prompt (cacheable across all tenants)
system = [
    {"type": "text", "text": PLATFORM_PROMPT, "cache_control": {"type": "ephemeral"}}
]

# Per-tenant context (cacheable per tenant)
tenant_context = [
    {"type": "text", "text": tenant_profile, "cache_control": {"type": "ephemeral"}}
]

# Tools (cacheable across all tenants if stable)
tools = [...]  # with cache_control on the last tool to anchor a breakpoint

# Variable user message — last, not cached
messages = [{"role": "user", "content": user_message}]
```

Each `cache_control` mark anchors a breakpoint. You get up to 4. Multi-tenant + multi-conversation = 3 useful breakpoints (platform / tenant / session) + room for a 4th if needed.

### Anti-patterns

- **Caching every request unconditionally.** Caching has a write cost. For one-off requests with no expected reuse, it's net-negative. Default-on for hot paths; off for cold.
- **Cache breakpoint after volatile content.** Self-defeating.
- **Caching a 100-token system prompt.** Overhead exceeds savings. Cache substantial prefixes only.

## The Batches API — when async pays

The Batches API offers a 50% discount on input AND output tokens for non-interactive workloads. Constraints:

- Up to 100K requests per batch
- Up to 256MB total request size
- Up to 24 hours to complete (most batches finish in minutes-to-hours)
- Polling-based completion (or webhook on enterprise)
- Same Messages API surface, just submitted in bulk

### Use Batches for

- **Bulk classification / extraction.** Categorizing 10K support tickets.
- **Eval runs.** Running an eval suite of 1,000 prompts.
- **Backfill / regeneration.** Regenerating summaries for an old corpus.
- **Synthetic data generation.** Generating training data, content variations, examples.
- **Anything where latency >5 seconds is acceptable.**

### Don't use Batches for

- **Real-time user-facing.** Latency is minutes-to-hours.
- **When you need each result as soon as it's ready.** Batches return all-at-once.
- **Tool-use loops.** Batches are single-turn; agentic workflows don't fit.

### Pattern

```python
batch = client.messages.batches.create(
    requests=[
        {
            "custom_id": "ticket_1",
            "params": {
                "model": "claude-sonnet-4-7-20260301",
                "max_tokens": 1024,
                "messages": [{"role": "user", "content": "..."}],
            },
        },
        # ... up to 100K requests
    ]
)

# Poll for completion
while batch.processing_status != "ended":
    time.sleep(60)
    batch = client.messages.batches.retrieve(batch.id)

# Retrieve results
for result in client.messages.batches.results(batch.id):
    print(result.custom_id, result.result.message.content[0].text)
```

### Anti-patterns

- **Polling every second.** Wasteful. Poll every 30-60 seconds; or use webhooks if available.
- **Mixing tiny batches.** The discount kicks in at any batch size, but operational overhead of many small batches outweighs the savings. Aggregate.
- **Not tracking custom_id.** You'll get results back keyed by `custom_id`; if you don't set a meaningful one, you can't map results back to your input records.

## Files API — when to use it

The Files API (GA 2025) lets you upload PDFs, images, and other supported documents and reference them by ID across many requests. Replaces base64-inlining at any non-trivial scale.

### When to use Files API

- **Documents referenced by many requests.** A user uploads a 100-page PDF; you'll ask 50 questions about it. Upload once, reference by `file_id` 50 times.
- **Images larger than 1MB.** Base64 overhead is brutal; Files API is cleaner.
- **Workspaces sharing documents.** A document uploaded to a workspace is referenceable by any key in that workspace.

### When base64-inlining is fine

- **One-off requests.** A user sends a single screenshot for analysis; inline and move on.
- **Documents that change per request.** Each request has unique content; Files API just adds round-trips.

### Pattern

```python
# Upload
with open("document.pdf", "rb") as f:
    uploaded = client.beta.files.upload(file=("document.pdf", f, "application/pdf"))

# Reference in many requests
for question in questions:
    response = client.messages.create(
        model="claude-sonnet-4-7-20260301",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": [
                {"type": "document", "source": {"type": "file", "file_id": uploaded.id}},
                {"type": "text", "text": question},
            ]
        }]
    )
```

### Operational concerns

- **Storage lifetime.** Files persist until you delete them. Implement deletion on user-data-deletion paths (GDPR / general hygiene).
- **Workspace isolation.** Files are workspace-scoped; cross-workspace requires re-upload.
- **Quotas.** Per-workspace storage quota (verify current); cleanup or upgrade as needed.
- **Audit.** Log file uploads and references for compliance trail.

### Anti-patterns

- **Uploading every request's content as a new file.** You've added a round-trip without reuse benefit. Inline instead.
- **Forgetting to delete.** Storage grows; eventually quota hits. Lifecycle policy.
- **Uploading PII without considering data residency.** Anthropic's storage is in their cloud; data residency commitments may apply. See the Trust Center.

## MCP — authoring an MCP server (Python or TypeScript)

The Model Context Protocol is the 2025-2026 standard for agent tools. If you're building agent-callable tools at any scale, build them as MCP servers.

### MCP at a glance

- **Tools, resources, prompts** — three primitives an MCP server exposes.
- **Transport: stdio (process-local) or HTTP/SSE (remote).** Stdio is for tools the agent runs locally; HTTP/SSE is for tools hosted as services.
- **JSON-RPC 2.0** over the chosen transport.
- **Spec at 2025-06-18 revision** (verify current at `modelcontextprotocol.io`).
- **First-party SDKs:** TypeScript, Python; community SDKs in Go, Rust, Java, C#, Kotlin.

### Minimal MCP server (Python)

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("order-management")

@mcp.tool()
def get_order(order_id: str) -> dict:
    """Look up an order by ID. Returns order details including status and items."""
    return db.get_order(order_id)  # your business logic

@mcp.tool()
def cancel_order(order_id: str, reason: str) -> str:
    """Cancel an order. Requires a reason. Returns 'cancelled' on success."""
    db.cancel_order(order_id, reason)
    return "cancelled"

if __name__ == "__main__":
    mcp.run()  # stdio transport by default
```

That's a working MCP server. A Claude Code / Claude Agent SDK client can install it (`claude mcp add order-management ./server.py`) and call its tools.

### Minimal MCP server (TypeScript)

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "order-management", version: "1.0.0" });

server.tool(
  "get_order",
  "Look up an order by ID. Returns order details including status and items.",
  { order_id: z.string() },
  async ({ order_id }) => {
    const order = await db.getOrder(order_id);
    return { content: [{ type: "text", text: JSON.stringify(order) }] };
  }
);

await server.connect(new StdioServerTransport());
```

### Resources

A "resource" is a read-only piece of data the model can request: `mcp.resource()` registers a URI pattern and a handler. Use for surfacing data without requiring an explicit tool call — e.g., the agent can read `orders://recent` to see recent orders.

### Prompts

A "prompt" is a parameterized prompt template the server provides. Use for letting users / agents invoke pre-built prompts: e.g., "use the order-summary prompt with order_id=42."

### Stdio vs HTTP/SSE

| Transport | Best for | Notes |
|-----------|----------|-------|
| **stdio** | Local tools, dev/personal use, sandboxed integrations | Process-per-server; client spawns the process |
| **HTTP/SSE** | Hosted services, multi-user tools, network-accessible | Server runs as a network service; multiple clients connect |

Most public MCP servers (Slack, GitHub, Google Drive, etc.) run as hosted HTTP/SSE services. Most local-development MCP servers run as stdio.

### Authoring discipline

- **Name tools verb-first.** `get_order`, `create_invoice`, `send_email`. Claude routes by verb.
- **Describe every tool and parameter.** Same rules as Claude tool definitions (see ai-ml-engineer overlay).
- **Validate inputs server-side.** Don't trust the model. Zod (TypeScript) / Pydantic (Python) at the entry point.
- **Return structured data.** `text` content with stringified JSON, or `image` content for images, or `embedded resource` content for richer types.
- **Handle errors visibly.** Return error info in the result, not as a transport-level error — let the model see the error and adapt.
- **Version your server.** Semver. Breaking schema changes need a major bump.

### Consuming MCP servers (clients)

Claude Code is an MCP client. So is Cursor, Zed, and increasingly every other agent harness. Adding an MCP server:

```bash
# Claude Code
claude mcp add my-server -- npx -y @vendor/my-mcp-server

# Settings.json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@vendor/my-mcp-server"],
      "env": { "API_KEY": "..." }
    }
  }
}
```

Once installed, the server's tools are visible to the agent. The agent decides when to call them.

### Anti-patterns

- **Building tools as Claude-native definitions when MCP is the better path.** If your tools are useful beyond a single agent setup, build them as MCP. Reusable, multi-client.
- **MCP server that does too much.** One MCP server per domain. A "do-everything" server is a maintenance nightmare.
- **Untyped tools.** No schema = unreliable tool calls.
- **MCP server that calls Claude.** Anti-pattern unless you have a specific reason; usually the client (Claude) is calling the server's tools, not the reverse.
- **Hardcoded credentials in the MCP server.** Use env vars / per-call config; never bake credentials into source.

## Provider routing — Anthropic API vs Bedrock vs Vertex

System-architect owns the strategic choice; backend-architect implements it. The three providers in code:

### Anthropic API

- Default for most teams.
- Latest models / features ship here first.
- Beta flags / new tool versions sometimes Anthropic-API-only at launch.
- Pricing on Anthropic's bill.

### AWS Bedrock

- For AWS-resident customers / VPC integration / AWS-billing requirements.
- May lag Anthropic API on bleeding-edge features (verify per-feature).
- Model IDs differ: `anthropic.claude-sonnet-4-7-20260301-v1:0` (and similar).
- Costs on AWS bill; uses AWS credentials (IAM); regional availability per AWS region.

### Google Vertex AI

- For GCP-resident customers / VPC integration / GCP-billing requirements.
- May lag Anthropic API on bleeding-edge features (verify per-feature).
- Model IDs differ: `claude-sonnet-4-7@20260301` (project-scoped).
- Costs on GCP bill; uses GCP credentials (service accounts); regional availability per GCP region.

### Multi-provider abstraction

For services that may need to switch providers, abstract behind a thin wrapper:

```python
def make_client(provider: str):
    if provider == "anthropic":
        from anthropic import Anthropic
        return Anthropic(), "claude-sonnet-4-7-20260301"
    elif provider == "bedrock":
        from anthropic import AnthropicBedrock
        return AnthropicBedrock(), "anthropic.claude-sonnet-4-7-20260301-v1:0"
    elif provider == "vertex":
        from anthropic import AnthropicVertex
        return AnthropicVertex(), "claude-sonnet-4-7@20260301"
```

The Messages API surface is the same across all three; you mostly need different model IDs and credential setup.

**Don't abstract too aggressively.** A "swap any LLM provider" abstraction usually leaks (different streaming semantics, different tool schemas, different rate-limit shapes). Build for the providers you'll actually use, not hypothetical future ones.

### Failover routing

For mission-critical: primary on Anthropic API; failover to Bedrock or Vertex on outage. Patterns:

- **Health-check before each request:** too expensive.
- **Circuit breaker:** primary fails N times in M seconds → flip to secondary for the next P seconds → probe primary; restore if healthy.
- **Gateway-level routing:** Helicone / Portkey / Bifrost can do this for you with config, not code.

## Admin API + budgets

The Admin API (verify availability for your org tier) exposes:

- **Workspace creation / management** — isolate tenants/projects.
- **API key creation / rotation** — programmatic provisioning.
- **Spend limits** — per-key, per-workspace, organization-wide caps.
- **Usage retrieval** — token usage by key / workspace / model.

### Wire this into provisioning

- **One workspace per tenant** (or per environment) — isolates billing, rate limits, governance.
- **Programmatic key rotation** — keys should rotate on schedule (90 days) and on revocation events. Automate.
- **Budget caps before going to production** — every workspace has a spend cap configured. The cap stops a runaway bug at workspace dollar-amount, not at "we noticed the bill."
- **Usage alerts** — webhook on usage anomalies (sudden 10x spike, daily spend >threshold).

See the security-engineer overlay for the governance discipline; backend-architect owns the wiring.

### Anti-patterns

- **One key, no rotation.** Lost key = full re-deploy + secret rotation.
- **No spend limit.** A bug + 24 hours = thousands of dollars before someone notices.
- **Manual key provisioning.** Doesn't scale; doesn't audit. Use the API.

## Observability

What to log per request:

- Request ID (from `response._request_id` if the SDK exposes it)
- Model used
- Input tokens, output tokens, cache create/read tokens
- Cost (compute from tokens × rate)
- Latency (TTFT + total)
- `stop_reason`
- Tool calls (names, durations, errors)
- User ID / tenant ID
- Workspace ID

What to alert on:

- Error rate >X% over Y minutes
- P95 latency above SLO
- Cache hit rate dropping (something broke cacheability)
- Cost per request creeping up (prompt grew, or routing changed)
- Tool error rate (tools failing more often)

### Observability stack

- **OpenTelemetry** — standard. Auto-instrumentation for Anthropic SDK via OpenLLMetry or vendor-specific instrumentations.
- **Langfuse / Helicone / Braintrust / Portkey** — purpose-built LLM observability with cost tracking, prompt versioning.
- **Datadog / Honeycomb / Grafana** — general-purpose if you're already there; add LLM-specific attributes via OTel.

## TDD on backend Claude code

What "TDD" means for a Claude-wrapping service:

1. **Unit tests** for non-LLM logic (tool implementations, schema validation, retry behavior). Standard pytest / vitest.
2. **Integration tests** for the actual API surface — mock the Anthropic API at the HTTP layer (`respx` for Python httpx; `msw` for TypeScript). Test that your service constructs requests correctly, parses responses correctly, handles errors.
3. **Eval tests** for prompt + model behavior — see ai-ml-engineer overlay.
4. **Contract tests** for MCP servers — call the server with known inputs, assert outputs.

### Mocking patterns

Don't mock the Anthropic SDK at the SDK level (mocking `client.messages.create` directly). Mock at the HTTP layer — your test should exercise the actual SDK with a fake HTTP response. This catches SDK upgrade breakage.

```python
import respx
from httpx import Response

@respx.mock
def test_chat():
    respx.post("https://api.anthropic.com/v1/messages").mock(
        return_value=Response(200, json={
            "id": "msg_test",
            "type": "message",
            "content": [{"type": "text", "text": "Hi"}],
            "stop_reason": "end_turn",
            "usage": {"input_tokens": 5, "output_tokens": 1},
        })
    )
    result = my_service.chat("hello")
    assert result == "Hi"
```

## Cross-references

- [`ai-ml-engineer.md`](ai-ml-engineer.md) — prompt design, tool schema design, model selection, eval design.
- [`system-architect.md`](system-architect.md) — provider routing strategy, when-to-build-vs-buy.
- [`security-engineer.md`](security-engineer.md) — API key management, prompt injection defenses, AUP.
- `https://docs.anthropic.com/en/api/` — full API reference.
- `https://docs.anthropic.com/en/api/client-sdks` — SDK list.
- `https://modelcontextprotocol.io/` — MCP spec.
- `https://github.com/modelcontextprotocol/typescript-sdk` — MCP TS SDK.
- `https://github.com/modelcontextprotocol/python-sdk` — MCP Python SDK.
- `https://github.com/anthropics/anthropic-cookbook` — pattern examples.
