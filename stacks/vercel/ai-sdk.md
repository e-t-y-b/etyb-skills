---
title: AI SDK
description: "TypeScript-first AI SDK — `streamText`, `generateText`, `streamObject`, `generateObject`, `tool()`, `useChat()`. v5+ (2025) is a major rewrite; old `streamUI` patterns are deprecated."
product:
  name: AI SDK
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, frontend-architect, backend-architect]
  authoritative_url: https://sdk.vercel.ai/docs
  notes: "v5+ (2025) shipped major rewrites — UI Message Stream protocol, generateObject schemas, tool use, AI Elements. Old streamUI / v3 patterns are stale."
---

## What it is

The Vercel AI SDK is a TypeScript-first SDK for working with LLMs. Provider-agnostic but pairs naturally with Next.js. The 2026 surface:

- **`streamText`, `generateText`** — text generation, streamed or not.
- **`streamObject`, `generateObject`** — typed structured outputs with Zod schemas.
- **`tool()`** — typed tool definitions for agentic loops.
- **`useChat()`** (`@ai-sdk/react`) — client hook for streaming chat; pairs with AI Elements.
- **AI Elements** — shadcn-layered UI components for AI (`<Message>`, `<Composer>`, `<Reasoning>`, `<Tool>`, `<Source>`, `<Artifact>`).

See [sdk.vercel.ai/docs](https://sdk.vercel.ai/docs).

## When to use

- **Any LLM interaction in a Next.js or Vercel project** — the AI SDK is the canonical client.
- **Multi-provider apps** — pair with [AI Gateway](/stacks/vercel/ai-gateway/) for one SDK across providers.
- **Streaming chat UIs** — `useChat` + AI Elements is the default.
- **Typed structured outputs** — `generateObject` + Zod replaces manual JSON parsing.

## 2025-2026 currency anchors

- **v5+ shipped (2025)** as a major rewrite. Streaming UI primitives (`streamUI`, `experimental_StreamingReactResponse`) from v3 are deprecated.
- **UI Message Stream protocol** is the new streaming format; `result.toUIMessageStreamResponse()` is the canonical conversion.
- **AI Elements** — new shadcn-layered library for AI UI components.
- **`stopWhen: stepCountIs(N)`** bounds the agentic loop in tool-use flows.
- **`useChat()` v2** is the current chat hook in `@ai-sdk/react`.
- **Provider prompt caching** is exposed via `providerOptions` — significant cost reduction on long-context repeats.

## Patterns + anti-patterns

**Pattern: Streaming chat via Route Handler.**

```ts
// app/api/chat/route.ts
import { streamText, convertToModelMessages } from 'ai';
import { gateway } from '@ai-sdk/gateway';

export async function POST(req: Request) {
  const { messages } = await req.json();
  const result = streamText({
    model: gateway('anthropic/claude-sonnet-4.7'),
    messages: convertToModelMessages(messages),
    system: 'You are a helpful assistant. Be concise.',
  });
  return result.toUIMessageStreamResponse();
}
```

```tsx
// app/chat/chat-ui.tsx
'use client';
import { useChat } from '@ai-sdk/react';
import { Message } from '@ai-elements/message';
import { Composer } from '@ai-elements/composer';

export function ChatUI() {
  const { messages, sendMessage, status } = useChat({ api: '/api/chat' });
  return (
    <div className="flex flex-col h-screen">
      <div className="flex-1 overflow-y-auto">
        {messages.map(m => <Message key={m.id} role={m.role} parts={m.parts} />)}
      </div>
      <Composer onSubmit={text => sendMessage({ text })} disabled={status !== 'ready'} />
    </div>
  );
}
```

**Pattern: Typed structured outputs with `generateObject` + Zod.**

```ts
import { generateObject } from 'ai';
import { z } from 'zod';

const ContactSchema = z.object({
  name: z.string(),
  email: z.string().email(),
  intent: z.enum(['sales', 'support', 'partnership', 'other']),
});

const { object } = await generateObject({
  model: gateway('anthropic/claude-haiku-4'),
  schema: ContactSchema,
  prompt: `Extract from this email:\n\n${email}`,
});
```

`generateObject` retries on schema validation failure. Don't manually JSON.parse provider output in 2026.

**Pattern: Tool definitions with authorization inside `execute`.**

```ts
function makeTools(authUser: User) {
  return {
    cancelOrder: tool({
      description: 'Cancel an order.',
      inputSchema: z.object({ orderId: z.string() }),
      execute: async ({ orderId }) => {
        const order = await db.query.orders.findFirst({ where: eq(orders.id, orderId) });
        if (!order || order.userId !== authUser.id) throw new Error('Forbidden');
        await db.update(orders).set({ status: 'cancelled' }).where(eq(orders.id, orderId));
      },
    }),
  };
}
```

**Pattern: Provider prompt caching.**

```ts
const result = streamText({
  model: gateway('anthropic/claude-sonnet-4.7'),
  system: VERY_LONG_SYSTEM_PROMPT,  // 4000+ tokens
  providerOptions: {
    anthropic: { cacheControl: { type: 'ephemeral' } },
  },
  messages,
});
```

**Anti-pattern: Trusting LLM-provided `userId` in tool args.** Inject auth context from the server; don't let the LLM pass identity.

**Anti-pattern: Memorizing model names.** Model versions change quarterly. Always check the current AI Gateway catalog or AI SDK docs.

**Anti-pattern: Streaming AI from a Server Action.** Server Actions return promises, not streams. Use Route Handlers for AI streaming.

**Anti-pattern: Manual JSON.parse of provider output.** Use `generateObject` / `streamObject` with Zod.

**Anti-pattern: Using deprecated `streamUI` from v3.** It's gone in v5; use UI Message Stream + AI Elements.

## Gotchas

- **`tool()` `execute` must return a serializable object.** The LLM sees the return; format accordingly.
- **`stopWhen` defaults to single-turn.** For multi-step agents, specify `stepCountIs(N)`.
- **Tool inputs validated via Zod** — `inputSchema` is your guard against malformed args.
- **Reasoning tokens (Claude extended thinking, OpenAI o-series)** surface as a separate `reasoning-delta` part — don't render verbatim; AI Elements `<Reasoning>` collapses by default.
- **Don't cache LLM responses at the route level** — `'use cache'` on a chat page = same response for every user. Cache at the prompt level (AI Gateway prompt cache, provider prompt caching).

## Cross-references

- [AI Gateway](/stacks/vercel/ai-gateway/) — pair with `@ai-sdk/gateway`
- [Chat SDK](/stacks/vercel/chat-sdk/) — opinionated chatbot template built on AI SDK
- [Vercel Agent](/stacks/vercel/vercel-agent/) — first-party agent platform
- [Vercel Sandbox](/stacks/vercel/vercel-sandbox/) — for code-executing tools
- [ai-ml-engineer on Vercel](/stacks/vercel/ai-ml-engineer/) — full AI patterns
- Authoritative: [AI SDK docs](https://sdk.vercel.ai/docs)
- Delegate: `vercel:ai-sdk`
