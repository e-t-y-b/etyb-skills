---
title: Claude Opus
description: The flagship Claude tier — deepest reasoning, hardest code generation, longest agent chains. Two products in one because the 1M-context variant has tiered pricing above 200K input tokens.
product:
  name: Claude Opus
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/about-claude/models
  notes: "1M-context variant priced separately (>200K input premium); model IDs versioned by date; rotation cadence quarterly."
---

## What it is

Claude Opus 4.x is the top tier of the Claude family — the model you reach for when reasoning depth, code-generation quality at the hardest end, or coherence over long agent chains is the binding constraint. The May 2026 release surface includes a **standard variant** with a 200K context window and a **1M-context variant** with tiered pricing: standard rate at ≤200K input, premium rate above 200K. See the [Anthropic model card](https://docs.anthropic.com/en/docs/about-claude/models) for current IDs.

The 1M-context variant is effectively two products in one: at ≤200K input it costs the same as standard Opus; above 200K, you pay a premium tier that's substantially more expensive. Don't reflexively dump everything into context — most tasks don't need it, and RAG + caching usually wins on cost.

## When to use

Default flow: try [Sonnet](/stacks/anthropic-claude/claude-sonnet/) first; escalate to Opus only on **eval signal**, not a vibe. Concrete escalation triggers:

- **Sonnet fails the eval at the required quality threshold** (e.g., < 85% on your domain benchmark). Measure delta on Opus; decide if cost is worth it.
- **Multi-agent orchestration where the orchestrator reasons about other agents' outputs.** Opus's depth helps when Sonnet loses the thread on 5+ agent chains.
- **Long-horizon agent work** — 50+ tool calls in a chain. Opus is observably more coherent at high tool-call counts.
- **Code generation on legacy / unusual languages** (COBOL, Tcl, MUMPS). Sonnet handles modern stacks fine; Opus is more reliable on the long tail.
- **Hardest reasoning** — novel math, multi-step scientific / legal / financial analysis where each step depends on the prior.
- **>200K input context** (entire codebases, hundreds of documents) — Opus 1M-context, but audit whether you really need it (RAG + caching usually wins).

When NOT to use Opus:

- **"Just in case."** 5x the cost of Sonnet; you usually won't notice the quality delta.
- **Pure throughput** (chewing through a million classification tasks) — use [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/) + [Batches API](/stacks/anthropic-claude/batches-api/).
- **Latency-sensitive UX paths.** Opus is slower; never put it synchronously in the user path without a fallback.

## 2025-2026 currency anchors

- **1M-context variant tiered pricing.** ≤200K input at standard rate; >200K at premium. Verify the current premium rate at the [pricing page](https://docs.anthropic.com/en/docs/about-claude/pricing) before quoting.
- **Model ID rotation.** Opus 4.0 → 4.5 → current. Pin a dated ID in production with a written upgrade plan; never use floating aliases without monitoring.
- **Older Opus models retired.** `claude-3-opus-20240229` was retired in 2025. If a code search surfaces that ID, it's a bug.
- **No fine-tuning on Opus** (or any Claude model) as of May 2026. If your problem requires fine-tuning, the answer is not Opus.

## Patterns + anti-patterns

### Pattern — Opus on a Sonnet-failed branch

Build your eval first; run Sonnet through it. On the cases Sonnet fails, run Opus. If Opus passes, you've identified the routing condition: cheap path Sonnet, fallback Opus. Don't put Opus on every request "to be safe."

### Pattern — 1M-context with prompt caching

For whole-codebase or large-doc-corpus work, Opus 1M-context with `cache_control` on the large stable prefix (the codebase / corpus) is sometimes more economical than RAG with retrieval — the cache amortizes the input cost. Measure both before committing.

### Anti-pattern — "Opus for everything"

The single most common 2026 Claude mistake. Costs 5x. Most production work runs identically on Sonnet. Default Sonnet; escalate by eval.

### Anti-pattern — Opus on latency-sensitive synchronous paths

Opus is slower than Sonnet, which is slower than Haiku. A chat UI with Opus feels sluggish; an autocompletion tool with Opus is wrong. For TTFT-sensitive paths, route to faster tiers.

### Anti-pattern — 1M-context on routine work

A 1M-token context window is a tool for the rare case where retrieval can't decide what to include. Dumping 800K tokens of "potentially relevant code" into every request burns premium-tier dollars for no quality benefit over RAG-selected 8K tokens.

## Gotchas

- **Pricing transition at 200K** is exact — not "around 200K." Hit 200,001 input tokens and the entire request bills at the premium rate (verify exact boundary semantics in current docs).
- **Caching across the 200K boundary** — verify with current docs whether cache breakpoints anchor below 200K give you standard pricing on cache reads when the total request exceeds 200K. Behavior has shifted; don't assume.
- **Output tokens are still output tokens** — Opus's $75/MTok output is independent of input-tier pricing. A long Opus response is expensive at any input size.

## Cross-references

- [Claude Sonnet](/stacks/anthropic-claude/claude-sonnet/) — production default
- [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) — cheap tier
- [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) — required cost lever
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — model-selection flowchart
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — when-Claude decisions
- [Anthropic Pricing](https://docs.anthropic.com/en/docs/about-claude/pricing) — verify current rates
