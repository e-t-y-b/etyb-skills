---
title: Agents Platform
description: Console-side surface for agents built with the Agents SDK + Built-in Tools — observability, tracing, and management for production agent deployments.
product:
  name: Agents Platform
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, security-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/agents
  notes: "Console surface that wraps Agents SDK telemetry + Built-in Tool quotas; evolving alongside SDK releases — verify against current Agents documentation."
---

## What it is

The Agents Platform is the **console-side** companion to the [Agents SDK](/stacks/openai/agents-sdk/) — the operational surface for agents in production. It provides:

- **Trace inspection** — view per-agent + per-handoff traces with tool calls, model calls, guardrail invocations.
- **Built-in tool quotas** — see per-project [built-in tool](/stacks/openai/built-in-tools/) usage + limits.
- **Eval integration** — wire agent traces into the [Eval Platform](/stacks/openai/eval-platform/).
- **Cost + latency telemetry** — per-agent dashboards.

Reference: [Agents guide](https://platform.openai.com/docs/guides/agents).

## When to use

**Use the Agents Platform when:**

- You've deployed agents via the [Agents SDK](/stacks/openai/agents-sdk/) and want production visibility.
- You're debugging a misbehaving agent — trace inspection is the forensic surface.
- You're tracking [built-in tool](/stacks/openai/built-in-tools/) quotas and costs.
- You're wiring evals into your agent CI ([Eval Platform](/stacks/openai/eval-platform/)).

**Don't conflate with the Agents SDK itself.** The SDK is the library you build agents with; the Agents Platform is the console-side operational view of agents in production.

**Pair with external observability.** OpenAI's console-side surface is for debugging individual traces; for long-term observability (cost trends, regression alerting, multi-provider views), use Langfuse / Helicone / Braintrust.

## 2025-2026 currency anchors

- **Console surface evolves alongside the [Agents SDK](/stacks/openai/agents-sdk/).** Verify current features in the OpenAI console.
- **Tracing on by default** for Agents SDK; appears in the console without extra config.
- **OpenTelemetry pipe** — agents can be wired to OTel collectors for centralized observability.
- **Quota visibility** — built-in tools (web_search / file_search / code_interpreter / computer_use_preview) have per-tier quotas surfaced here.
- **Eval integration** — running agents → Stored Completions → Eval Platform datasets is a coupled loop.

## Patterns

### Pattern: agent debugging via traces

When an agent misbehaves, the Agents Platform trace shows:
- Each model call with token counts.
- Each tool call with arguments + return.
- Handoffs between agents.
- Guardrail invocations + tripwires.
- Total cost + duration.

This is the forensic surface for "why did the agent do that?"

### Pattern: production observability stack

```
Agents Platform (console) — per-trace debugging, built-in tool quotas
        +
Langfuse / Helicone (external) — long-term observability, cost trends, multi-provider
        +
Eval Platform — regression eval gates in CI
```

Each layer plays a role; the Agents Platform is the OpenAI-native debug view, not a substitute for external observability.

### Pattern: wire built-in tool quotas to alerting

Built-in tool quotas (especially `computer_use_preview`) are tier-gated and can hit limits. Wire alerts on quota usage approaching the cap.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Treating Agents Platform as a full observability layer | Pair with Langfuse / Helicone for long-term + cost views. |
| Disabling tracing in production | Keep tracing on. It's your forensic trail. |
| No eval gates wired to agent deployments | Build eval datasets, run on PR; block on regression. |
| Skipping quota monitoring on built-in tools | Alert before quota exhaustion. |
| Console-side debugging without correlation to your app logs | Correlate via `request_id` / `trace_id` to your tracing layer. |

## Gotchas

- **Surface evolves.** Console UI changes alongside Agents SDK releases. Verify in console.
- **Tracing has token + latency overhead** — small but real.
- **Quota limits per project** — built-in tools have separate quotas per project per tier.
- **Trace retention** has defaults — verify if you need long-term retention.
- **Multi-tenant visibility** — your console can see all your projects' traces; consider operational access controls.

## Cross-references

### Related products in this Stack

- [Agents SDK](/stacks/openai/agents-sdk/) — the library agents are built with.
- [Eval Platform](/stacks/openai/eval-platform/) — wire traces into eval datasets.
- [Built-in tools](/stacks/openai/built-in-tools/) — quota tracked here.
- [Stored Completions](/stacks/openai/stored-completions/) — eval input.
- [OpenAI Platform Console](/stacks/openai/openai-platform-console/) — broader console surface.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — using traces for agent design iteration.
- [system-architect](/stacks/openai/system-architect/) — observability topology.
- [security-engineer](/stacks/openai/security-engineer/) — audit trail + access control.

### Authoritative sources

- [Agents guide](https://platform.openai.com/docs/guides/agents)
- [Agents SDK Python](https://github.com/openai/openai-agents-python)
