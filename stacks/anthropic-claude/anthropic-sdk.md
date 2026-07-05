---
title: Anthropic SDK
description: First-party SDKs in Python, TypeScript, Go, Java, Ruby. Same surface; one constructor per provider (Anthropic API, Bedrock, Vertex). Don't drop down to raw HTTP without a reason.
product:
  name: Anthropic SDK (multi-lang)
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-07-05"
  applies_to_roles: [backend-architect, ai-ml-engineer]
  authoritative_url: https://docs.anthropic.com/en/api/client-sdks
  notes: "Python + TypeScript + Go + Java + Ruby first-party. Same SDK supports Anthropic API, Bedrock, Vertex via different constructors."
---

## What it is

Anthropic ships first-party SDKs in five languages as of mid-2026. Each SDK wraps the [Messages API](/stacks/anthropic-claude/claude-api/), exposing idiomatic clients with retries, idempotency keys, error mapping, streaming helpers, and provider-aware constructors for [Anthropic API](/stacks/anthropic-claude/claude-api/) / [Bedrock](/stacks/anthropic-claude/bedrock-provider/) / [Vertex AI](/stacks/anthropic-claude/vertex-ai-provider/).

| SDK | Package | Maturity | Use when |
|-----|---------|----------|----------|
| **Python** | `anthropic` (PyPI) | Highest — most-used | Python services, data pipelines, ML workloads |
| **TypeScript** | `@anthropic-ai/sdk` (npm) | Highest — Node-default | Web services, edge runtime, Next.js |
| **Go** | `github.com/anthropics/anthropic-sdk-go` | High | Go services, latency-sensitive backends |
| **Java** | `com.anthropic:anthropic-java` | High | JVM services, Spring Boot integrations |
| **Ruby** | `anthropic` (gem) | Good | Rails apps |

Community SDKs exist for PHP, Rust, Kotlin, C#, etc. — quality varies; verify before depending in production. See [Client SDKs](https://docs.anthropic.com/en/api/client-sdks).

## When to use

Use the SDK for **every** Claude integration. Drop down to raw HTTP only with a specific reason — the SDK adds value at every layer (retries, error mapping, streaming parsing, idempotency, telemetry hooks).

For agentic loops, layer the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) on top of the language SDK — don't hand-roll the loop.

## 2025-2026 currency anchors

- **SDK versions move fast** — verify current versions against the package registries before pinning; review changelogs on upgrade.
- **Bedrock + Vertex provider clients** ship in the same package — `AnthropicBedrock` and `AnthropicVertex` classes alongside `Anthropic`.
- **Async clients exist in Python (`AsyncAnthropic`) and Go (context-aware methods).** TypeScript is always async. Java has both blocking and reactive flavors.
- **Streaming helpers** — `client.messages.stream()` in Python / TypeScript handles SSE event assembly. Don't parse raw SSE unless you must.
- **Idempotency keys auto-generated** on retries — protects against double-charging on transient failures.

## Patterns + anti-patterns

### Pattern — async by default

```python
from anthropic import AsyncAnthropic
client = AsyncAnthropic()

async def chat(user_message: str) -> str:
    response = await client.messages.create(
        model="claude-sonnet-5",
        max_tokens=1024,
        messages=[{"role": "user", "content": user_message}],
    )
    return response.content[0].text
```

In any service handling concurrent requests, use the async client. TypeScript is always async.

### Pattern — provider-aware constructor

```python
# Anthropic API (default)
from anthropic import Anthropic
client = Anthropic()

# AWS Bedrock
from anthropic import AnthropicBedrock
client = AnthropicBedrock(aws_region="us-east-1")
# Model ID format: "anthropic.claude-sonnet-5" (current-gen, dateless);
# pre-4.6 snapshots use "anthropic.claude-haiku-4-5-20251001-v1:0"

# Google Vertex AI
from anthropic import AnthropicVertex
client = AnthropicVertex(project_id="my-gcp-project", region="us-east5")
# Model ID format: "claude-sonnet-5" (bare first-party ID for current-gen);
# dated snapshots use "@", e.g. "claude-haiku-4-5@20251001"
```

The Messages API surface is identical across the three; model ID format and credential handling differ.

### Pattern — streaming via helpers

```python
with client.messages.stream(
    model="claude-sonnet-5",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Write a short poem."}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
    final = stream.get_final_message()
```

```typescript
const stream = await client.messages.stream({
  model: 'claude-sonnet-5',
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

### Pattern — mock at the HTTP layer for tests

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

Don't mock the SDK methods directly — that bypasses SDK upgrade testing. Mock at the HTTP layer (respx for Python, msw for TypeScript). Catches breaking SDK changes early.

### Anti-pattern — raw HTTP without the SDK

Hand-rolling SSE parsing, retry-with-backoff, idempotency keys, error mapping. The SDK does this well — drop down only with a clear reason.

### Anti-pattern — mocking `client.messages.create` directly

Skips SDK behavior in tests. Mock at the HTTP layer instead.

### Anti-pattern — community SDK in production without review

Quality varies. A community SDK that's six months stale on bug fixes will surface as flaky behavior in production. Vet thoroughly or stick to first-party.

### Anti-pattern — sync client in a concurrent service

Sync client + many threads = thread pool exhaustion under load. Use the async client.

## Gotchas

- **Per-request timeout default may be too long** for your latency budget. Set `timeout=N` on the client or per-call.
- **Rate-limit headers** (`anthropic-ratelimit-*`) on response objects — log them; alert when remaining drops.
- **SDK version pinning** — minor versions add features; major versions may have breaking changes. Pin in production; review changelogs on upgrade.
- **Provider client differences** — `AnthropicBedrock` uses AWS IAM credentials; `AnthropicVertex` uses GCP service-account auth. Set up the right credential chain per provider.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — the underlying API
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — layered on top
- [Bedrock Provider](/stacks/anthropic-claude/bedrock-provider/), [Vertex AI Provider](/stacks/anthropic-claude/vertex-ai-provider/) — provider-specific constructors
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — SDK integration depth
- [Client SDKs](https://docs.anthropic.com/en/api/client-sdks)
