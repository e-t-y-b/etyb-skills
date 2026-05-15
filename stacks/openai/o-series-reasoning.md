---
title: o-series reasoning models
description: "o3 and o4 reasoning models with chain-of-thought built in. Different semantics from chat models — reasoning tokens, no temperature, `reasoning.effort` knob."
product:
  name: o-series reasoning models
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://platform.openai.com/docs/guides/reasoning
  notes: "o3 (full + mini), o4 (mini + standard) — chain-of-thought built in; semantics differ from chat models; pricing rebalanced 2026. Tier-gated."
---

## What it is

The o-series is OpenAI's reasoning-model line. Unlike chat models (GPT-5, GPT-4.1), o-series models emit **reasoning tokens** before the visible answer — a hidden chain-of-thought that you pay for but don't see. The trade is significantly higher quality on multi-step inference at higher token cost.

Current generation: **o3** (full + mini) and **o4** (mini + standard). Pricing was rebalanced in 2026; verify against the [pricing page](https://openai.com/api/pricing/) before quoting.

Distinct semantics:

- **No `temperature` parameter.** o-series is silently ignored (or errors, depending on SDK version) if you pass `temperature`.
- **`reasoning.effort`** is the knob — `low` / `medium` / `high`. Higher effort = more reasoning tokens = better quality + higher cost + higher latency.
- **`reasoning_tokens`** is billed as output but invisible by default. The [Responses API](/stacks/openai/responses-api/) can expose a reasoning summary.

Reference: [Reasoning guide](https://platform.openai.com/docs/guides/reasoning).

## When to use

**Use o-series when:**

- The task requires multi-step inference that [GPT-5 Standard](/stacks/openai/gpt-5/) gets wrong.
- Math, code refactoring with deep semantic understanding, legal / medical analysis, scientific problem-solving.
- Agent planning steps where the model must reason about tool sequences.
- Quality is more valuable than latency or token cost.

**Don't use o-series when:**

- The task is already trivial — you're paying for reasoning the model doesn't need.
- Latency matters (o-series is slower than chat models, especially at `reasoning.effort: high`).
- The interface assumes chat semantics (`temperature`, sampling controls).
- You can budget-cap reasoning tokens — o-series can blow output token budgets unpredictably.

**Default rule:** start with **GPT-5 Standard**. If quality misses, try **GPT-5 thinking variant** before going to o-series — thinking variants stay on the chat surface without o-series quirks. Only go to o3 / o4 when the thinking variant is itself below bar.

| Variant | Use when |
|---|---|
| **o3** | Hardest reasoning — math proofs, complex code refactors, multi-hop analysis. |
| **o3-mini** | Production reasoning with cost discipline. |
| **o4** | Frontier reasoning; pricing reshuffled 2026 — verify. |
| **o4-mini** | Production reasoning default in 2026; often cheaper than o3-mini. |

## 2025-2026 currency anchors

- **o3 launched 2025**, replacing o1. Mini + full variants.
- **o4 launched 2025-2026** with mini + standard variants.
- **Pricing rebalanced 2026.** Verify before quoting.
- **o-series fine-tuning** rolled out 2025-2026 for o-mini variants — capability and cost vary by variant. See [the fine-tuning guide](https://platform.openai.com/docs/guides/fine-tuning).
- **Tier-gated.** o-series typically requires Tier 2+ even for the mini variants. Confirm project tier.
- **`reasoning.effort: high`** can produce 5-10x output tokens vs chat models. Budget accordingly.
- **`reasoning.summary` field** on [Responses API](/stacks/openai/responses-api/) returns a human-readable summary of the model's reasoning — surface this to users for transparency where appropriate.

## Patterns

### Pattern: reasoning-token budgeting

Set `max_completion_tokens` aggressively. o-series will spend reasoning tokens up to roughly the same budget; capping output also caps reasoning. Watch `completion_tokens_details.reasoning_tokens` in usage; if reasoning is consuming most of your budget, drop to `reasoning.effort: medium` or `low`.

### Pattern: cascade — chat model → o-series escalation

```
1. GPT-5 Standard with structured output.
2. Validate the output (schema, citation check, LLM-as-judge).
3. If validation fails or confidence is low: escalate to o4-mini with the same input.
4. Validate again. If still failing: escalate to o3 or surface to human.
```

Cost-optimal pattern — most traffic stays on the cheaper chat model; only hard cases consume o-series cost.

### Pattern: reasoning effort tuning per workload

Don't hardcode `reasoning.effort: high`. Eval at each effort level:

- `low` — for routine reasoning with quality bar acceptable; cheapest.
- `medium` — production default for most reasoning workloads.
- `high` — only for genuinely hard cases; verify cost-per-correct-answer is favorable.

### Pattern: parsed structured output via Responses

Pair o-series with [Responses API](/stacks/openai/responses-api/) + [Structured Outputs](/stacks/openai/structured-outputs/) `strict: true` — the model reasons internally, then produces a schema-compliant final answer. Best of both worlds.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Passing `temperature` to o-series | Use `reasoning.effort` instead. `temperature` is ignored / errors. |
| Defaulting to o-series for routine workloads | Use chat model + structured output. Escalate only when needed. |
| Hardcoding `reasoning.effort: high` | Eval per workload; many tasks are fine at medium or low. |
| Not measuring `reasoning_tokens` in usage | Capture it. Reasoning tokens are billed as output and can dominate cost. |
| Promising sub-second latency on o-series | High-effort reasoning takes seconds to tens of seconds. Plan UX. |
| Streaming o-series and expecting first-token in milliseconds | Reasoning tokens emit before visible answer; first visible token is delayed. |
| Using o-series for tasks where input dominates (long-context analysis) | A long-context chat model (GPT-5 Pro, GPT-4.1 1M) may be both cheaper and faster. |

## Gotchas

- **No `temperature`.** Don't pass it. Use `reasoning.effort`.
- **Reasoning tokens are billed as output tokens.** They count against your `max_completion_tokens` budget AND your output cost.
- **Latency.** o3 at `reasoning.effort: high` can take 30+ seconds. Don't put it in a synchronous user-facing path without explicit UX.
- **Tier-gating.** Confirm tier before promising o3 / o4 access.
- **Pricing.** Reshuffled 2026; verify against [pricing](https://openai.com/api/pricing/).
- **Reasoning summary is opt-in** on Responses (`reasoning.summary: "concise"` / `"detailed"`). It's a separate output stream from the visible answer.
- **No streaming reasoning tokens.** You see them in the final usage object, not as they're emitted. (The reasoning summary, when enabled, can stream.)
- **Tools work** but tool-iteration cost scales with reasoning effort. Each tool-call cycle re-incurs reasoning.

## Cross-references

### Related products in this Stack

- [GPT-5 family](/stacks/openai/gpt-5/) — thinking variants are the chat-surface alternative.
- [Responses API](/stacks/openai/responses-api/) — exposes reasoning summary cleanly.
- [Structured Outputs](/stacks/openai/structured-outputs/) — pair with o-series for typed output.
- [Function calling / tool use](/stacks/openai/function-calling/) — tools work; cost multiplies per iteration.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — when to escalate to o-series.
- [system-architect](/stacks/openai/system-architect/) — cost + latency planning.
- [backend-architect](/stacks/openai/backend-architect/) — async/queueing patterns for high-latency reasoning.

### Authoritative sources

- [Reasoning guide](https://platform.openai.com/docs/guides/reasoning)
- [OpenAI Models Catalog](https://platform.openai.com/docs/models)
- [OpenAI Pricing](https://openai.com/api/pricing/)
