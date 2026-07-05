---
title: Claude Haiku
description: The cheap-tier Claude — Haiku 4.5 (Oct 2025) reset the price/quality envelope and changed routing math. For classification, routing, extraction, and real-time paths, Haiku is now the right default.
product:
  name: Claude Haiku
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-07-05"
  applies_to_roles: [ai-ml-engineer, system-architect, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/about-claude/models
  notes: "Haiku 4.5 (claude-haiku-4-5 / claude-haiku-4-5-20251001, Oct 2025) is still the current cheap tier in July 2026 — $1/$5 per MTok, 200K context, 64K max output; latency profile sub-second TTFT on most prompts."
---

## What it is

Claude Haiku 4.5 (Oct 2025; still the current Haiku as of July 2026) is the cheap tier of the Claude family — **$1/MTok input, $5/MTok output** with sub-second TTFT on most prompts, 200K context, and 64K max output. Model ID: `claude-haiku-4-5` (alias for the dated snapshot `claude-haiku-4-5-20251001`). Before 4.5, Haiku was "use only for the cheapest tasks." After 4.5, Haiku hits roughly Sonnet-3.5 quality on many benchmarks, which fundamentally changes the routing math for cost-sensitive production systems.

## When to use

Haiku is the right call for:

- **Latency-critical paths** (<500ms TTFT target) — chat autocompletion, real-time UX, voice latency budgets.
- **Routing / classification / extraction** — "which department should this ticket go to?", "is this query about orders or refunds?", "extract the product name from this email."
- **High-volume gating** — content moderation pre-filter, in-scope checks, simple validation.
- **Batch classification at scale** — pair with the [Batches API](/stacks/anthropic-claude/batches-api/) for another 50% off.
- **First-pass on multi-tier routing** — Haiku decides if the task is "easy" (Haiku handles) or "hard" (escalate to Sonnet).

Reach past Haiku to [Sonnet](/stacks/anthropic-claude/claude-sonnet/) when:

- Multi-step reasoning is on the path.
- Code generation beyond trivial completion.
- Tool-use agent loops with more than 2-3 steps.
- Quality regressions show up in your eval suite.

## 2025-2026 currency anchors

- **Haiku 4.5** (Oct 2025) reset the price/quality envelope. Older training data underestimates Haiku — re-benchmark for your workload before assuming Haiku is "too dumb." It remains the current Haiku through the Claude 5 generation (no Haiku 5 as of July 2026).
- **Pricing.** $1 input / $5 output per MTok, verified July 2026; check the [pricing page](https://docs.anthropic.com/en/docs/about-claude/pricing) before quoting.
- **Tool use works on Haiku 4.5** — older Haiku versions had patchier tool-use; 4.5 is reliable enough for production routing agents.
- **Extended Thinking on Haiku 4.5** uses the legacy manual mode (`thinking: {type: "enabled", budget_tokens: N}`); Haiku 4.5 does not support adaptive thinking or `effort: "max"`. Keep budgets low.
- **No `1M-context` Haiku variant** — Haiku stays at 200K context (64K max output), while Opus 4.6+/Sonnet 5 ship 1M.
- **Retired predecessors.** `claude-3-5-haiku-20241022` retired Feb 2026; `claude-3-haiku-20240307` retired Apr 2026. Haiku 4.5 is the drop-in replacement.

## Patterns + anti-patterns

### Pattern — Haiku as the router, Sonnet/Opus as the worker

A multi-tier agent that uses Haiku for triage / routing / classification and escalates to Sonnet (or Opus) for the actual work. Total cost is dominated by Haiku for the routing decisions; only a fraction of requests reach the expensive tiers.

### Pattern — Haiku + Batches for bulk classification

Categorizing 100K support tickets? Haiku via Batches API. 50% Batches discount × cheap Haiku tier = pennies per thousand records.

### Pattern — Haiku for the gating step

"Is this request in-scope?" / "Does this contain PII?" / "Is this complaint or feedback?" — Haiku reliably handles these binary / small-cardinality decisions at minimal cost.

### Anti-pattern — assuming Haiku is too weak

Pre-4.5 reasoning ("we tried Haiku, it wasn't good enough") doesn't transfer. Re-test on 4.5 before defaulting to Sonnet for "cheap" routes.

### Anti-pattern — Haiku on hard reasoning

Multi-step math, deep code generation, long-horizon agent loops — Haiku will fail more often than Sonnet. Escalate when eval signal supports it.

### Anti-pattern — Haiku without an eval

Switching from Sonnet to Haiku without measuring is how you ship silent quality regressions. Eval first; measure delta; switch if acceptable.

## Gotchas

- **Quality vs Sonnet varies by task.** Haiku is excellent at classification / extraction; weaker at long-form generation. Test on your specific task type.
- **Cache hit rate matters more.** With low per-token cost, the absolute savings from cache reads are smaller — but cache hit rate still matters for throughput limits (token budgets, ITPM).
- **Output verbosity.** Haiku sometimes returns shorter responses than Sonnet would for the same prompt. Verify your output expectations on Haiku before switching.

## Cross-references

- [Claude Sonnet](/stacks/anthropic-claude/claude-sonnet/) — escalation tier
- [Claude Opus](/stacks/anthropic-claude/claude-opus/) — for the hardest tasks
- [Batches API](/stacks/anthropic-claude/batches-api/) — pair with Haiku for bulk savings
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — routing strategy
