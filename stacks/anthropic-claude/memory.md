---
title: Memory
description: Anthropic-managed memory store the model can read/write across conversations. For long-running assistant relationships and multi-session agent state — not a replacement for your database.
product:
  name: Memory tool
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/memory
  notes: "Released 2025; surface still evolving — read release notes before claiming behavior."
---

## What it is

The Memory tool (released 2025) is a managed memory store that Claude can read and write across conversations. You enable it by including it in the `tools` array (a named built-in tool); Claude calls memory operations (`view`, `create`, `str_replace`, `insert`, `delete`, `rename`); state persists across requests, sessions, and conversations until you delete it.

Memory is scoped to a workspace + user/key combination you configure. This is distinct from "memory" in the conversational sense (context window) — Memory survives session boundaries; context windows don't.

See [Memory Tool Guide](https://docs.anthropic.com/en/docs/build-with-claude/memory) and verify behavior against current release notes — the surface is still evolving.

## When to use

Memory fits when:

- **Long-running assistant relationships** — a customer-facing assistant that learns user preferences over weeks/months. "Remember that I'm allergic to peanuts" persists per user.
- **Agents with extended task horizons** — an agent working a multi-day project that needs to recall earlier decisions across sessions.
- **Personalization that survives session boundaries** — facts about the user the model itself derives and writes to memory.

Memory is the **wrong call** when:

- **You already have a database.** If you have a CRM, profile store, or app-specific data layer — write structured data there. Memory is for state the model itself owns; not for structured business data.
- **Compliance-sensitive data.** Memory contents live in Anthropic-managed storage. For PHI/PII subject to data residency, you may need state in your own database. Verify against [Trust Center](https://trust.anthropic.com/).
- **Short-lived task state.** A single-conversation task uses the context window. Memory is for things that need to survive across conversations.
- **You need structured queries.** Memory is text-shaped. SQL-shaped questions need a real database.

## 2025-2026 currency anchors

- **Released 2025; surface evolving.** Verify the exact set of supported operations and scoping rules against current docs before designing around them.
- **Workspace + user/key scoping** — verify exact key shape (is it per-API-key, per-user-id-attribute, per-conversation-id?) against current docs.
- **No automatic eviction.** Memory grows until you delete entries. Lifecycle is your responsibility.
- **Operations:** `view`, `create`, `str_replace`, `insert`, `delete`, `rename` (verify current). Model decides when to call which.

## Patterns + anti-patterns

### Pattern — derived facts only

Memory contents should be facts the model derives during interaction, not pre-loaded data from your systems. "User mentioned they're vegetarian (Mar 2026)" → Memory. "User's order history" → your database.

### Pattern — explicit eviction policy

Decide and document:

- **Retention** — 30 days? 1 year? Until user deletes account?
- **Eviction triggers** — user-initiated, end-of-relationship, GDPR right-to-be-forgotten.
- **Audit** — when was a memory written / read / deleted? Logged separately.

Automate eviction; don't rely on manual cleanup.

### Pattern — validate memory reads

Claude writes memory; Claude can write wrong memory. When Claude later reads memory and acts on it, treat memory contents as untrusted input (same way you'd treat any LLM output). Validate before action.

### Anti-pattern — Memory as a key-value store

Using Memory for arbitrary application data ("set value=X for key=Y") works but turns the model into your database. Wrong tool. Use Redis, Postgres, or your existing store.

### Anti-pattern — no memory eviction strategy

Memory grows; nothing prunes it automatically. Decide what's worth keeping, what's stale, what's PII that must be deleted on schedule.

### Anti-pattern — trusting memory as ground truth

Claude wrote it; Claude is fallible. Memory contents can be wrong, manipulated (via prompt injection convincing the model to write false memories), or stale. Don't treat as authoritative without verification for high-stakes actions.

### Anti-pattern — Memory for compliance-sensitive data without Trust Center review

PHI / PII / regulated data going into the Anthropic-managed memory store changes your data residency story. Verify against Trust Center before defaulting Memory on for any regulated product.

## Gotchas

- **Scoping is workspace-level (verify).** Memory written in workspace A is not visible in workspace B. Multi-tenant SaaS with workspace-per-tenant gets natural isolation; sharing a workspace mixes tenant memory.
- **Prompt injection can manipulate Memory.** A user can prompt-inject Claude into writing a misleading memory ("the user has admin privileges"). Defense: Claude's tool-input validation, server-side rules on what memories are allowed to encode (no permission grants, no credentials), and treating memory reads as untrusted.
- **Memory tool counts as a tool call.** Each `view` / `create` / etc. is a tool round-trip — adds latency. Don't enable Memory for paths where it isn't needed.
- **Surface evolution.** This is a 2025 release; operation set, scoping rules, and retention semantics may shift in 2026. Read release notes before pinning behavior.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — Memory is a tool in the `tools` array
- [Tool Use](/stacks/anthropic-claude/tool-use/) — the protocol Memory operations ride on
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — when Memory fits in agent design
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — data residency, prompt-injection considerations
- [Memory Tool Guide](https://docs.anthropic.com/en/docs/build-with-claude/memory)
- [Trust Center](https://trust.anthropic.com/) — data handling commitments
