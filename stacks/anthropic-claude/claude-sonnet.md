---
title: Claude Sonnet
description: The production default — best quality/cost ratio at the frontier. Sonnet 5 (June 2026) is what 80% of production traffic should target on Claude in 2026.
product:
  name: Claude Sonnet
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-07-05"
  applies_to_roles: [ai-ml-engineer, system-architect, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/about-claude/models
  notes: "Current production default is Claude Sonnet 5 (claude-sonnet-5, launched 2026-06-30); introductory pricing $2/$10 per MTok through 2026-08-31, then $3/$15."
---

## What it is

Claude Sonnet is the workhorse of the Claude lineup — best quality/cost ratio at the frontier, strong on multi-step reasoning, code generation, tool use, and agent loops. **This is what 80% of production Claude traffic should target.** The current release is **Claude Sonnet 5** (`claude-sonnet-5`, launched 2026-06-30) with a **1M-token context window** and **128K max output tokens**; Sonnet 4.6 remains available as the previous generation.

Sonnet 5 reaches near-Opus quality on coding and agentic work at Sonnet cost. The 2026 Sonnet replaces the "default to Opus" mental model from 2024 outright.

## When to use

**Default for production.** Reach away from Sonnet when:

- **Latency or cost dominates** → [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/). Routing, classification, real-time UX, "is this in scope?" gating.
- **Sonnet eval fails on a hard problem** → [Opus 4.8](/stacks/anthropic-claude/claude-opus/), or Claude Fable 5 for the most demanding long-horizon work. Measure delta first.

In every other production case — chatbots, coding agents, document Q&A, RAG generators, tool-use agents, content generation — start with Sonnet, escalate only on evidence.

## 2025-2026 currency anchors

- **Sonnet 5 (`claude-sonnet-5`) is the current release** as of July 2026 (launched 2026-06-30). Verify at the [release notes](https://docs.anthropic.com/en/release-notes) before pinning.
- **Introductory pricing.** $2/MTok input, $10/MTok output through 2026-08-31; standard $3/$15 from 2026-09-01. Budget against the standard rate.
- **1M context at standard pricing.** Sonnet 5 (and 4.6) ship a 1M-token context window with no long-context premium — a 900K-token request bills at the same per-token rate as a 9K one.
- **API surface changes vs 4.6.** Adaptive thinking (`thinking: {type: "adaptive"}`) is on by default when `thinking` is omitted; manual `budget_tokens` extended thinking is removed (returns 400); non-default `temperature`/`top_p`/`top_k` return 400. Priority Tier is not available on Sonnet 5.
- **New tokenizer.** Sonnet 5 uses the tokenizer introduced with Opus 4.7 — the same text produces ~30% more tokens than on Sonnet 4.6. Re-baseline `max_tokens`, context budgets, and cost dashboards with `count_tokens`; don't reuse Sonnet 4.6 numbers.
- **3.5 Sonnet was a different generation.** Old training data treats `claude-3-5-sonnet-20240620` as current; that model was retired in Oct 2025. Sonnet 5 is the replacement.

## Patterns + anti-patterns

### Pattern — Sonnet-by-default routing

Build your service to call Sonnet by default. Add explicit routing rules only when an eval shows another tier is appropriate. Hardcode model IDs in config (not in code) so production upgrades are one config change with a rollback.

### Pattern — pin the model ID; know that dateless IDs are snapshots

Starting with the 4.6 generation, model IDs are dateless (`claude-sonnet-5`, `claude-sonnet-4-6`) **and each dateless ID is itself a pinned snapshot** — Anthropic does not update weights under an existing ID; updates ship as a new ID. Pinning `claude-sonnet-5` in config is stable. (Only pre-4.6 models had floating convenience aliases that resolved to dated snapshots — e.g. `claude-sonnet-4-5` → `claude-sonnet-4-5-20250929`.) Track upgrade cycles explicitly: moving to the next Sonnet is a deliberate config change, never something the platform does under you.

### Anti-pattern — "Sonnet for everything cheap"

Haiku 4.5 at $1/$5 is roughly 3x cheaper than Sonnet at standard pricing for routing / classification / extraction / gating tasks where Haiku quality is sufficient. Sonnet for these is wasted spend. Re-eval your cheap path on Haiku.

### Anti-pattern — comparing Sonnet to Opus by intuition

"Opus is better than Sonnet" is true on the hardest benchmarks; it's not true on most production tasks. Measure on your workload. Most teams find Sonnet sufficient for >80% of routes.

### Anti-pattern — appending date suffixes to current-generation IDs

`claude-sonnet-5` is the complete model ID. Constructing `claude-sonnet-5-20260630` (or any dated variant) from habit 404s — the dated-ID convention ended with the 4.5 generation.

## Gotchas

- **Tool use behavior evolves with each model.** Tool-use accuracy, refusal patterns, and `tool_choice` behaviors shift between Sonnet 4.6 and Sonnet 5 (Sonnet 5 is more agentic by default). Re-eval your tool surface when you upgrade.
- **Thinking configuration.** `thinking: {type: "enabled", budget_tokens: N}` was deprecated on 4.6 and now 400s on Sonnet 5. Use adaptive thinking plus `output_config.effort` instead. See [Extended Thinking](/stacks/anthropic-claude/extended-thinking/).
- **Tokenizer shift breaks old budgets.** A `max_tokens` or compaction trigger tuned on Sonnet 4.6 may truncate on Sonnet 5 (~30% more tokens for the same text). Re-measure before rollout.
- **Cache invalidation on model change.** Switching model IDs invalidates [prompt caching](/stacks/anthropic-claude/prompt-caching/) — your first request after an upgrade is a cache miss. Schedule upgrades during low-traffic windows if cost matters.

## Cross-references

- [Claude Opus](/stacks/anthropic-claude/claude-opus/) — escalation tier
- [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) — cheap tier
- [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) — for >90% cost savings on stable prefixes
- [Tool Use](/stacks/anthropic-claude/tool-use/) — Sonnet's tool-use surface
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — model-selection flow
