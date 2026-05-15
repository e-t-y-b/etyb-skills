---
title: Chat SDK
description: Vercel's opinionated chatbot template built on AI SDK + AI Elements. Persistence, multi-tenancy, tool use with Sandbox, file uploads, voice optional.
product:
  name: Chat SDK
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, frontend-architect]
  authoritative_url: https://chat-sdk.dev
  notes: "Tightly coupled to AI SDK version cadence. For greenfield chatbot work, scaffold from Chat SDK and customize. For chat inside an existing app, use AI SDK + AI Elements directly."
---

## What it is

`@vercel/chat-sdk` is Vercel's opinionated chatbot template — a full Next.js scaffold that ships:

- **Persistence** — chat history in Postgres.
- **Multi-tenant chat support.**
- **Tool use** with Sandbox for code execution.
- **File uploads** (Blob).
- **Voice** (optional).
- **AI Elements UI.**

See [chat-sdk.dev](https://chat-sdk.dev).

## When to use

- **Greenfield chatbot work** — scaffold from Chat SDK and customize.

When to skip:

- **Chat *inside* an existing app** — use [AI SDK](/stacks/vercel/ai-sdk/) + AI Elements directly; you don't need Chat SDK's persistence + multi-tenancy if your app already has those.
- **Non-chat AI surfaces** (extraction, classification, generative UI) — AI SDK is enough.

## 2025-2026 currency anchors

- **Tightly coupled to AI SDK version cadence** — pin/update both together.
- **Default model via AI Gateway** — change in config.
- **Tool execution via Sandbox** — for code-running tools.
- **Persistence layer is Postgres** — pair with [Vercel Postgres](/stacks/vercel/vercel-postgres/) / Neon.

## Patterns + anti-patterns

**Pattern: Scaffold + audit.**

```bash
npx create-next-app -e https://github.com/vercel/ai-chatbot
```

Then audit:
- **Authorization on every message endpoint** — multi-tenant isolation.
- **Per-tenant data isolation** — chat history scoped to tenant.
- **Tool definitions match your business logic** — replace template tools.
- **Cost monitoring** — token budgets per tenant.

**Pattern: Replace template tools with domain-specific ones.** The scaffold's tools are illustrative; your business needs its own.

**Anti-pattern: Treating the scaffold as production-ready.** Audit auth, validation, cost monitoring before shipping.

**Anti-pattern: Pinning to an old Chat SDK version while updating AI SDK.** They evolve together; track both.

## Gotchas

- **Persistence schema is opinionated.** Customize for your data shape, but don't fight it without reason.
- **Multi-tenant isolation requires explicit auth.** The template provides scaffolding; your auth enforcement is on you.
- **AI SDK version compatibility** — Chat SDK updates may require AI SDK updates.

## Cross-references

- [AI SDK](/stacks/vercel/ai-sdk/) — Chat SDK is built on AI SDK
- [AI Gateway](/stacks/vercel/ai-gateway/) — default routing
- [Vercel Sandbox](/stacks/vercel/vercel-sandbox/) — code execution tools
- [Vercel Postgres](/stacks/vercel/vercel-postgres/) — persistence
- [Vercel Blob](/stacks/vercel/vercel-blob/) — file uploads
- [ai-ml-engineer on Vercel](/stacks/vercel/ai-ml-engineer/)
- Authoritative: [chat-sdk.dev](https://chat-sdk.dev)
- Delegate: `vercel:chat-sdk`
