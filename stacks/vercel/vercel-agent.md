---
title: Vercel Agent
description: Vercel's first-party agent platform — step management, memory, tool use (Sandbox-integrated), observability, cost controls. Surface is new (2025-2026) and evolving.
product:
  name: Vercel Agent
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://vercel.com/docs/agent
  notes: "Brand new (2025-2026). Active development. Verify current capabilities before architecting — surface is changing fast."
---

## What it is

Vercel Agent is Vercel's first-party agent platform — a managed runtime for agentic AI apps with built-in:

- **Step management.**
- **Memory.**
- **Tool use** (with [Sandbox](/stacks/vercel/vercel-sandbox/) integration).
- **Observability.**
- **Cost controls.**

See [vercel.com/docs/agent](https://vercel.com/docs/agent). **Verify current capabilities** — the surface is new and changing fast.

## When to use

When Vercel Agent is the right fit:

- You're already on Vercel and want a managed agent platform.
- You want Sandbox + AI Gateway + observability wired by default.
- The agent's lifecycle is "user-initiated, run to completion in minutes-hours, return result".

When it's not:

- **Cross-system agentic orchestration** (multiple LLMs across multiple services) — consider Temporal / Mastra / custom orchestration.
- **Very tight customization of the agent loop** — Vercel Agent is opinionated.
- **Heavy investment in LangGraph / Mastra / custom orchestrator** — migration cost outweighs the benefit.

## 2025-2026 currency anchors

- **Active development.** Verify the current `@vercel/agent` API and capabilities before committing to an architecture.
- **Integrates with [AI Gateway](/stacks/vercel/ai-gateway/), [Sandbox](/stacks/vercel/vercel-sandbox/), [Workflow](/stacks/vercel/workflow/), and AI SDK** — those primitives compose under Agent.
- **Observability + cost controls built-in** — per-agent-run dashboards.

## Patterns + anti-patterns

**Pattern: Verify before architecting.** Check [vercel.com/docs/agent](https://vercel.com/docs/agent) for the current API; don't pattern-match from older agent frameworks.

**Pattern: Use Sandbox for code-executing tools.** Don't run untrusted code in your Function — Sandbox is the canonical isolation boundary.

**Pattern: Agents trigger Workflows for durable steps.** Long-running multi-step parts of an agent's plan can offload to Workflow.

**Anti-pattern: Treating Vercel Agent as identical to LangGraph / Mastra.** It has its own opinions; learn them.

**Anti-pattern: Architecting before verifying current capabilities.** The platform is evolving; design after a docs review.

**Anti-pattern: Multi-vendor agent orchestration on Vercel Agent.** For cross-system agentic flows, Temporal or custom orchestration may fit better.

## Gotchas

- **API surface still moving** — pin versions; track release notes.
- **Cost dashboards** are per-run — verify they meet your observability needs.
- **Memory model** has its own semantics — read docs before assuming behavior.

## Cross-references

- [AI SDK](/stacks/vercel/ai-sdk/) — the call surface Agent composes
- [AI Gateway](/stacks/vercel/ai-gateway/) — model routing
- [Vercel Sandbox](/stacks/vercel/vercel-sandbox/) — code-running tools
- [Workflow](/stacks/vercel/workflow/) — alternative for durable AI pipelines
- [Chat SDK](/stacks/vercel/chat-sdk/) — alternative for chatbot use cases
- [ai-ml-engineer on Vercel](/stacks/vercel/ai-ml-engineer/)
- Authoritative: [Vercel Agent docs](https://vercel.com/docs/agent)
