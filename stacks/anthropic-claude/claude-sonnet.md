---
title: Claude Sonnet
description: The production default — best quality/cost ratio at the frontier. Sonnet 4.7 (or current 4.x) is what 80% of production traffic should target on Claude in 2026.
product:
  name: Claude Sonnet
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/about-claude/models
  notes: "Current production default; 4.6/4.7 cadence with quarterly minor bumps."
---

## What it is

Claude Sonnet 4.x is the workhorse of the Claude lineup — best quality/cost ratio at the frontier, 200K standard context (1M variant available in some configurations), strong on multi-step reasoning, code generation, tool use, and agent loops. **This is what 80% of production Claude traffic should target.** As of May 2026 the current release is Sonnet 4.7; the 4.6 / 4.7 cadence has been roughly quarterly.

Sonnet outperforms older Opus models on most benchmarks while costing a fraction. The 2026 Sonnet replaces the "default to Opus" mental model from 2024 outright.

## When to use

**Default for production.** Reach away from Sonnet when:

- **Latency or cost dominates** → [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/). Routing, classification, real-time UX, "is this in scope?" gating.
- **Sonnet eval fails on a hard problem** → [Opus 4.x](/stacks/anthropic-claude/claude-opus/). Measure delta first.
- **Context requirements exceed 200K** → Opus 1M-context variant (with audit — RAG often wins).

In every other production case — chatbots, coding agents, document Q&A, RAG generators, tool-use agents, content generation — start with Sonnet, escalate only on evidence.

## 2025-2026 currency anchors

- **Sonnet 4.7 (or current 4.x) is the default ID** as of May 2026. Verify the current dated alias at the [release notes](https://docs.anthropic.com/en/release-notes) before pinning.
- **Quarterly minor cadence.** Sonnet 4.5 (mid-2025), 4.6 (late-2025), 4.7 (early-2026). Plan for ~quarterly upgrades to track Anthropic's release rhythm.
- **3.5 Sonnet was a different generation.** Old training data treats `claude-3-5-sonnet-20240620` as current; that's 2024 vintage. 4.x is a different lineage.
- **Pricing.** $3/MTok input, $15/MTok output as of May 2026 — verify before quoting.
- **1M-context Sonnet** is available in some configurations (verify per current release); standard Sonnet ships at 200K.

## Patterns + anti-patterns

### Pattern — Sonnet-by-default routing

Build your service to call Sonnet by default. Add explicit routing rules only when an eval shows another tier is appropriate. Hardcode dated model IDs in config (not in code) so production upgrades are one config change with a rollback.

### Pattern — pin dated IDs in production

Use `claude-sonnet-4-7-20260301` (or current dated ID), not the floating alias `claude-sonnet-4-7`. Track upgrade cycles explicitly. Aliases can shift under you between minor releases; dated IDs are stable.

### Anti-pattern — "Sonnet for everything cheap"

Haiku 4.5 at ~$1/$5 is roughly 3x cheaper than Sonnet for routing / classification / extraction / gating tasks where Haiku quality is sufficient. Sonnet for these is wasted spend. Re-eval your cheap path on Haiku.

### Anti-pattern — comparing Sonnet to Opus by intuition

"Opus is better than Sonnet" is true on the hardest benchmarks; it's not true on most production tasks. Measure on your workload. Most teams find Sonnet sufficient for >80% of routes.

### Anti-pattern — floating alias in production

`claude-sonnet-4-7` floats to the latest 4.7-series patch. A patch that subtly regresses your prompt can ship without your knowledge. Use the dated ID; upgrade deliberately.

## Gotchas

- **Tool use behavior evolves with each model.** Tool-use accuracy, refusal patterns, and `tool_choice` behaviors shift between 4.6 and 4.7. Re-eval your tool surface when you upgrade.
- **Extended Thinking budget.** Sonnet supports extended thinking; budget tuning that worked on 4.6 may need re-tuning on 4.7. See [Extended Thinking](/stacks/anthropic-claude/extended-thinking/).
- **Cache invalidation on minor bumps.** Switching dated model IDs typically invalidates [prompt caching](/stacks/anthropic-claude/prompt-caching/) — your first request after an upgrade is a cache miss. Schedule upgrades during low-traffic windows if cost matters.

## Cross-references

- [Claude Opus](/stacks/anthropic-claude/claude-opus/) — escalation tier
- [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) — cheap tier
- [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) — for >90% cost savings on stable prefixes
- [Tool Use](/stacks/anthropic-claude/tool-use/) — Sonnet's tool-use surface
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — model-selection flow
