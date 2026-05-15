---
title: GPT-5 family
description: The 2025 default model family — Pro / Standard / Mini / Nano plus thinking variants. Replaces GPT-4 as the recommended default for new builds in 2026.
product:
  name: GPT-5 family
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://platform.openai.com/docs/models
  notes: "Launched 2025; replaces GPT-4 as default; Pro / Standard / Mini / Nano tiers + thinking variants; pricing reshuffled twice in 2025-2026 — verify before quoting budget."
---

## What it is

GPT-5 is OpenAI's 2025-launched flagship model family. It is the recommended default for new builds in 2026, replacing GPT-4 / gpt-4o / gpt-4-turbo. The family is tiered by capability + cost:

| Variant | Context | Output | Posture |
|---|---|---|---|
| **GPT-5 Pro** | 1.05M | 128K | Premium — hardest reasoning, longest context, highest stakes |
| **GPT-5 Standard** | 1.05M | 128K | **Production default** — drop-in upgrade from gpt-4o |
| **GPT-5 Mini** | 256K | 64K | Cost-sensitive production — classification, extraction, simple agents |
| **GPT-5 Nano** | 128K | 32K | High-volume + low-stakes — intent routing, draft generation |
| **GPT-5 thinking variants** | 1.05M | 128K | When you'd reach for [o-series](/stacks/openai/o-series-reasoning/) but want the standard chat tool-use surface |

GPT-5 thinking variants are an alternative to going to o3 / o4 when you need reasoning depth but want to stay on the chat-style tool-use surface without the o-series no-temperature + reasoning-token semantics.

Current model IDs and snapshots are at [platform.openai.com/docs/models](https://platform.openai.com/docs/models). Pricing is at [openai.com/api/pricing](https://openai.com/api/pricing/).

## When to use

**Default rule:** start with **GPT-5 Standard**. Move up to Pro only when Standard is below quality bar; move down to Mini / Nano when Standard is overkill for cost-sensitive workloads.

| Use case | Model |
|---|---|
| General-purpose agentic app, RAG-grounded answering, customer support | **GPT-5 Standard** |
| Hardest reasoning (multi-hop legal/medical analysis, complex code refactors) | **GPT-5 Pro** or [o3 / o4](/stacks/openai/o-series-reasoning/) |
| Classification, intent routing, simple extraction | **GPT-5 Mini** |
| Bulk intent labels, draft generation, very high QPS | **GPT-5 Nano** |
| Long-context document analysis | **GPT-5 Standard** or **Pro** (both at 1.05M context) |
| Multimodal vision input | GPT-5 Standard / Pro (also supports [vision input](/stacks/openai/vision-input/)) |
| Production reasoning workloads needing chain-of-thought | **GPT-5 thinking variant** OR [o-series](/stacks/openai/o-series-reasoning/) |
| Cost-tight workload that needs more than Mini can deliver | [GPT-4.1](/stacks/openai/gpt-4-1/) — the cost-effective workhorse below GPT-5 |

**Don't default to Pro.** Pro is for the hardest reasoning, longest-context, highest-stakes workloads. Standard is the production default. Picking Pro because "we want the best" wastes cost without quality gain on routine tasks.

## 2025-2026 currency anchors

- **GPT-5 family launched 2025**, replacing GPT-4 / gpt-4o as the default recommendation.
- **Pricing reshuffled twice in 2025-2026.** Verify against [openai.com/api/pricing](https://openai.com/api/pricing/) before quoting budget. Numbers in your training data are wrong.
- **Tier-gated.** New projects on Tier 1 cannot call GPT-5 family — even with a valid key, requests fail until the org's [usage tier](/stacks/openai/organization-project-hierarchy/) auto-promotes (spend + age). Always confirm project tier before promising the model works.
- **Thinking variants** were added through 2025-2026 as an alternative to o-series for reasoning workloads.
- **GPT-5 fine-tuning** is rolling out in stages — verify availability against [the fine-tuning guide](https://platform.openai.com/docs/guides/fine-tuning) before promising it for a specific variant.
- **Snapshot pinning matters.** `gpt-5` is an alias that points at the current snapshot. For high-stakes workloads, pin a specific snapshot ID (e.g., `gpt-5-2026-04-01`) to lock in eval results. OpenAI rolls snapshots forward; aliases shift.

## Patterns

### Pattern: model cascade

```
Mini → Standard → Pro (or → o-series)
```

Start with Mini for an eval set. Escalate to Standard when Mini misses below threshold. Escalate to Pro / o4-mini only for cases where Standard is below bar. Eval-driven routing is the OpenAI 2026 cost-optimization stack.

### Pattern: snapshot-pinning for eval stability

For workloads where eval scores must be reproducible (compliance, customer-promised SLAs), pin to a specific snapshot:

```python
# Production
client.chat.completions.create(model="gpt-5-2026-04-01", ...)
# Dev / canary
client.chat.completions.create(model="gpt-5", ...)
```

When the alias rolls forward, your prod evals don't shift under you. Plan a re-eval before adopting the new snapshot.

### Pattern: GPT-5 + structured output for production JSON

Always use [Structured Outputs](/stacks/openai/structured-outputs/) `strict: true` for any JSON output on GPT-5 family. The model is constrained at decode time; no parse failures.

### Pattern: thinking variant vs o-series

If you need reasoning depth but:
- You want the chat-style tool-use surface (not the o-series reasoning-effort + no-temperature regime).
- You want predictable output-token counts (o-series emits hidden reasoning tokens that can 5-10x output cost).

then GPT-5 thinking variant is the right pick. If you want maximum reasoning quality and you can budget for it, [o-series](/stacks/openai/o-series-reasoning/) full.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Defaulting to gpt-4o / gpt-4-turbo for new builds | GPT-5 Standard for new builds; [GPT-4.1](/stacks/openai/gpt-4-1/) if cost-sensitive. |
| Picking GPT-5 Pro because "best model" | Pro is for hardest reasoning + longest context. Standard is the production default. |
| Hardcoding `gpt-5` (alias) for compliance-sensitive workload | Pin to a snapshot (`gpt-5-2026-04-01`). Re-eval before bumping. |
| Promising GPT-5 access without checking tier | Tier 1 projects can't call GPT-5. Confirm the project's [usage tier](/stacks/openai/organization-project-hierarchy/). |
| Quoting cost from training-data pricing | Pricing reshuffled twice in 2025-2026. Verify current [pricing](https://openai.com/api/pricing/) per quote. |
| Routing every workload to Standard | Use Nano / Mini for routing + classification + draft generation. Save Standard for synthesis. |
| Using `temperature` with thinking variant the same as Standard | Thinking variants behave differently — eval before committing. |

## Gotchas

- **Pricing is fluid.** Two reshuffles in 2025-2026. Always quote from the current pricing page, never from baked knowledge.
- **Tier-gating bites at deploy.** A new project at Tier 1 doesn't have GPT-5. Tier auto-promotes on cumulative spend + account age. Promote before launch.
- **`gpt-5` alias rolls forward.** OpenAI promotes new snapshots into the alias. Pin in prod to avoid silent eval drift.
- **GPT-5 + vision** — multimodal input works the same way as gpt-4o (`image_url` parts). See [Vision input](/stacks/openai/vision-input/).
- **Output token budgets are large** (128K on Standard / Pro) but you pay for what you generate. Set `max_tokens` aggressively for cost.
- **Cached input is 50% off** on prompts ≥1024 tokens with a shared prefix. Architect for [Prompt Caching](/stacks/openai/prompt-caching/) — stable prefix, varying tail.
- **GPT-5 Mini and Nano** drop quality faster than the cost saving suggests for hard synthesis tasks. Eval first; don't auto-cascade-down.
- **Refusals come back as normal responses** (not errors). Detect via content match + `finish_reason: "content_filter"` for filter-side refusals.

## Cross-references

### Related products in this Stack

- [GPT-4.1](/stacks/openai/gpt-4-1/) — the cost-effective workhorse below GPT-5.
- [o-series reasoning models](/stacks/openai/o-series-reasoning/) — when reasoning depth matters more than chat-style flexibility.
- [Vision input](/stacks/openai/vision-input/) — multimodal input on GPT-5.
- [Structured Outputs](/stacks/openai/structured-outputs/) — production JSON default on GPT-5.
- [Prompt Caching](/stacks/openai/prompt-caching/) — automatic; architect the prompt for it.
- [Responses API](/stacks/openai/responses-api/) / [Chat Completions](/stacks/openai/chat-completions/) — surfaces for the model.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — model selection + cascade design.
- [system-architect](/stacks/openai/system-architect/) — tier + capacity planning, multi-provider.

### Authoritative sources

- [OpenAI Models Catalog](https://platform.openai.com/docs/models)
- [OpenAI Pricing](https://openai.com/api/pricing/)
- [OpenAI Changelog](https://platform.openai.com/docs/changelog)
