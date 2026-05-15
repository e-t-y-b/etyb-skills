---
title: MCP (Model Context Protocol)
description: The 2025-2026 standard for agent tools — spec at 2025-06-18 revision, SDKs in 5+ languages, adopted by every major agent platform. Donated to the Linux Foundation under the Agentic AI Foundation (2026).
product:
  name: MCP servers + clients
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, security-engineer, ai-ml-engineer]
  authoritative_url: https://modelcontextprotocol.io/
  notes: "Spec at 2025-06-18 revision; SDKs in TS, Python, Go, Java, Kotlin, Rust, C#. Industry standard since 2025."
---

## What it is

The Model Context Protocol (MCP) is the open standard for agent-tool communication. **If you're building agent tooling in 2026, build it as an MCP server first.** Originally Anthropic-launched (Nov 2024); adopted by OpenAI, Google, Microsoft, JetBrains, Cursor, Zed, and every major agent platform. Donated to the Linux Foundation under the Agentic AI Foundation in 2026.

MCP at a glance:

- **Three primitives:** **tools** (callable functions), **resources** (read-only data the model can request), **prompts** (parameterized prompt templates).
- **Two transports:** **stdio** (process-local) or **HTTP/SSE** (remote service).
- **JSON-RPC 2.0** over the chosen transport.
- **Spec at 2025-06-18 revision** as of May 2026 — verify at [modelcontextprotocol.io](https://modelcontextprotocol.io/).
- **First-party SDKs:** [TypeScript](https://github.com/modelcontextprotocol/typescript-sdk), [Python](https://github.com/modelcontextprotocol/python-sdk); community SDKs in Go, Rust, Java, C#, Kotlin.

## When to use

Build as MCP when:

- **Tools will be reused beyond a single agent setup.** Multi-client (Claude Code, Cursor, Zed, custom agents) = MCP.
- **Building a vendor-integration toolset** (Slack, GitHub, Google Drive, internal systems) — publish as MCP so any compatible client can install.
- **Building tools for your team's internal agents** — MCP gives a clean interface and standard discovery.
- **Building tools you want third-party agents to use** — MCP is the open contract.

Use Claude-native tool definitions (passed in the `tools` array on the [Messages API](/stacks/anthropic-claude/claude-api/)) when:

- **Tools are tightly coupled to a specific agent or workflow.**
- **Tools are dynamic, generated per-request.**
- **Tools wouldn't make sense outside the current context.**

## 2025-2026 currency anchors

- **Industry standard since 2025.** OpenAI / Google / Microsoft / JetBrains / Cursor / Zed adoption normalized MCP across the agent ecosystem.
- **Donated to Linux Foundation (2026)** under the Agentic AI Foundation. Spec governance is now multi-vendor; this is a meaningful neutrality milestone.
- **Tens of thousands of public MCP servers** exist. Quality varies wildly — see [security-engineer overlay on MCP supply chain](/stacks/anthropic-claude/security-engineer/#mcp-server-supply-chain).
- **Stdio vs HTTP/SSE.** Local tools / dev integrations / sandboxed use cases run stdio. Hosted services run HTTP/SSE.
- **Claude Code, Claude Agent SDK, ChatGPT, Cursor, Zed, JetBrains** all install and consume MCP servers — your server is portable across all of them.

## Patterns + anti-patterns

### Pattern — minimal MCP server (Python)

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("order-management")

@mcp.tool()
def get_order(order_id: str) -> dict:
    """Look up an order by ID. Returns order details including status and items."""
    return db.get_order(order_id)

@mcp.tool()
def cancel_order(order_id: str, reason: str) -> str:
    """Cancel an order. Requires a reason. Returns 'cancelled' on success."""
    db.cancel_order(order_id, reason)
    return "cancelled"

if __name__ == "__main__":
    mcp.run()  # stdio transport by default
```

### Pattern — minimal MCP server (TypeScript)

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

### Pattern — verb-first tool naming + full descriptions

Same rules as [Claude tool use](/stacks/anthropic-claude/tool-use/) — lead with verb, describe when/when-not to use, type and describe every parameter, use enums for finite sets, mark `required` accurately. The model still reads MCP tool descriptions to decide what to call.

### Pattern — server-side validation

Don't trust the model's tool inputs. Pydantic (Python) or Zod (TypeScript) at the entry point. The MCP server is the authoritative boundary — apply permission checks, scope enforcement, idempotency.

### Pattern — versioned MCP servers

Semver. Breaking changes (renamed tool, changed schema) need a major version bump. Pin versions in client config; never `latest`.

### Anti-pattern — building tools as Claude-native definitions when MCP is the better path

If your tools will be reused beyond a single setup, build them as MCP. Multi-client portability is real value.

### Anti-pattern — MCP server that does too much

One domain per server. A "do-everything" MCP server is a maintenance nightmare and a security risk (broader credential surface).

### Anti-pattern — untyped tools

No schema = unreliable tool calls. The model needs schema to know what to send; the server needs schema to validate inputs.

### Anti-pattern — MCP server that calls Claude

Anti-pattern unless you have a specific reason. Usually the client (Claude) calls the server's tools, not the reverse.

### Anti-pattern — hardcoded credentials in MCP server source

Use env vars / per-call config; never bake credentials into source. The server is software that gets distributed — credentials in source means they're in everyone's checkout.

### Anti-pattern — installing arbitrary MCP servers in production

The ecosystem is open; quality varies. Curate an allowlist for production. See [security-engineer overlay](/stacks/anthropic-claude/security-engineer/#mcp-server-supply-chain).

## Gotchas

- **MCP servers run with the trust of whoever launched them.** Filesystem access, network access, credentials — all with the launching user's privileges. Treat installation like installing software.
- **Stdio vs HTTP/SSE matters for deployment.** Stdio servers are per-client-process; HTTP/SSE servers are multi-client services. Pick the right one for the use case.
- **Spec evolution.** The protocol still revises. Pin SDK versions. Track changelog at [modelcontextprotocol.io](https://modelcontextprotocol.io/).
- **Resources vs tools** — a resource is read-only data the model can request by URI; a tool is a callable function. Different primitives, different uses. Don't conflate.
- **The MCP spec does NOT enforce sandboxing.** That's the client's job (and most clients delegate to the user). Untrusted servers need explicit sandboxing.

## Cross-references

- [Tool Use](/stacks/anthropic-claude/tool-use/) — Claude-native alternative
- [Claude Code](/stacks/anthropic-claude/claude-code/) — MCP client via `.claude/settings.json`
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — MCP integration in agent loops
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — authoring MCP servers in Python/TS
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — MCP supply-chain threats
- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
