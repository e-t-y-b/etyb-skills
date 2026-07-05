---
title: Claude Opus
description: The flagship general-availability tier — deepest reasoning, hardest code generation, longest agent chains. Opus 4.8 ships a 1M-token context window by default at standard pricing; Claude Fable 5 sits above it for the most demanding work.
product:
  name: Claude Opus
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-07-05"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/about-claude/models
  notes: "Current release Claude Opus 4.8 (claude-opus-4-8, launched 2026-05-28), $5/$25 per MTok, 1M context at standard pricing (no long-context premium). Claude Fable 5 / Mythos 5 ($10/$50) are the tier above Opus."
---

## What it is

Claude Opus is the flagship generally-available tier of the Claude family — the model you reach for when reasoning depth, code-generation quality at the hardest end, or coherence over long agent chains is the binding constraint. The current release is **Claude Opus 4.8** (`claude-opus-4-8`, launched 2026-05-28) at **$5/MTok input, $25/MTok output**, with a **1M-token context window by default at standard pricing** — there is no separate long-context variant and no >200K input premium on Opus 4.6 and later. See the [Anthropic model page](https://docs.anthropic.com/en/docs/about-claude/models) for current IDs.

**Above Opus sits the Mythos-class tier**: **Claude Fable 5** (`claude-fable-5`, GA 2026-06-09, $10/$50 per MTok) is Anthropic's most capable widely released model, built for the most demanding reasoning and long-horizon agentic work. **Claude Mythos 5** (`claude-mythos-5`) shares Fable 5's capabilities, specs, and pricing but ships **without** Fable 5's dual-use safety classifiers; it is available only in limited release to approved customers in Project Glasswing (invitation-only, oriented at defensive cybersecurity work). Fable 5 integrations must handle `stop_reason: "refusal"` (its classifiers can decline cyber/bio-adjacent requests — unbilled if refused before output; opt into the `fallbacks` parameter to retry on another Claude model), and both models require 30-day data retention (not available under zero-data-retention). Announcement: [anthropic.com/news/claude-fable-5-mythos-5](https://www.anthropic.com/news/claude-fable-5-mythos-5).

## When to use

Default flow: try [Sonnet](/stacks/anthropic-claude/claude-sonnet/) first; escalate to Opus only on **eval signal**, not a vibe. Concrete escalation triggers:

- **Sonnet fails the eval at the required quality threshold** (e.g., < 85% on your domain benchmark). Measure delta on Opus; decide if cost is worth it.
- **Multi-agent orchestration where the orchestrator reasons about other agents' outputs.** Opus's depth helps when Sonnet loses the thread on 5+ agent chains.
- **Long-horizon agent work** — 50+ tool calls in a chain. Opus is observably more coherent at high tool-call counts; Opus 4.8 is state-of-the-art on long autonomous runs.
- **Code generation on legacy / unusual languages** (COBOL, Tcl, MUMPS). Sonnet handles modern stacks fine; Opus is more reliable on the long tail.
- **Hardest reasoning** — novel math, multi-step scientific / legal / financial analysis where each step depends on the prior.

Escalate **past Opus to Claude Fable 5** only when Opus 4.8 demonstrably falls short on the most demanding long-horizon or frontier-difficulty work — it costs 2x Opus, single turns can run many minutes, and your integration must handle refusal fallbacks.

When NOT to use Opus:

- **"Just in case."** Roughly 1.7x Sonnet's standard input/output cost; you usually won't notice the quality delta.
- **Pure throughput** (chewing through a million classification tasks) — use [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/) + [Batches API](/stacks/anthropic-claude/batches-api/).
- **Latency-sensitive UX paths.** Opus is slower; never put it synchronously in the user path without a fallback.

## 2025-2026 currency anchors

- **1M context at standard pricing.** Opus 4.6/4.7/4.8 (and Sonnet 5 / 4.6, Fable 5) include the full 1M-token context window with **no long-context premium** — the old ≤200K/> 200K tiered-pricing model no longer applies. Verify at the [pricing page](https://docs.anthropic.com/en/docs/about-claude/pricing) before quoting.
- **Pricing.** Opus 4.8 is $5/$25 per MTok (same as 4.5-4.7). The $15/$75 figures from Opus 4.1 and earlier are two generations stale.
- **API surface (4.7/4.8).** Adaptive thinking only — `budget_tokens` and sampling params (`temperature`/`top_p`/`top_k`) return 400; `output_config.effort` (default `high`) controls depth. Opus 4.8 adds mid-conversation `role: "system"` messages. Fast mode (research preview, premium pricing) is Opus 4.8/4.7 only, and 4.7 fast mode is deprecated (removal 2026-07-24).
- **Model ID rotation.** Opus 4.5 → 4.6 → 4.7 (Apr 2026) → 4.8 (May 2026). Dateless IDs from 4.6 onward are pinned snapshots — `claude-opus-4-8` is stable; upgrades ship as new IDs. Opus 4.1 is deprecated (retires 2026-08-05).
- **Older Opus models retired.** `claude-3-opus-20240229` was retired Jan 2026; `claude-opus-4-20250514` retired June 2026. If a code search surfaces those IDs, it's a bug.
- **No fine-tuning on Opus** (or any Claude model) as of July 2026. If your problem requires fine-tuning, the answer is not Opus.

## Patterns + anti-patterns

### Pattern — Opus on a Sonnet-failed branch

Build your eval first; run Sonnet through it. On the cases Sonnet fails, run Opus. If Opus passes, you've identified the routing condition: cheap path Sonnet, fallback Opus. Don't put Opus on every request "to be safe."

### Pattern — 1M-context with prompt caching

For whole-codebase or large-doc-corpus work, Opus with `cache_control` on the large stable prefix (the codebase / corpus) is sometimes more economical than RAG with retrieval — the cache amortizes the input cost, and long context now bills at standard rates. Measure both before committing.

### Pattern — Fable 5 with a fallback chain

If you do route the hardest work to Claude Fable 5, ship the opt-in `fallbacks` parameter (or SDK fallback middleware) from day one so a classifier refusal degrades to Opus 4.8 instead of failing the request. A refusal before any output is unbilled.

### Anti-pattern — "Opus for everything"

The single most common 2026 Claude mistake. Most production work runs identically on Sonnet at a fraction of the cost. Default Sonnet; escalate by eval.

### Anti-pattern — Opus on latency-sensitive synchronous paths

Opus is slower than Sonnet, which is slower than Haiku. A chat UI with Opus feels sluggish; an autocompletion tool with Opus is wrong. For TTFT-sensitive paths, route to faster tiers.

### Anti-pattern — 1M-context on routine work

A 1M-token context window is a tool for the rare case where retrieval can't decide what to include. Long context now bills at standard per-token rates, but dumping 800K tokens of "potentially relevant code" into every request still burns 100x the input cost of RAG-selected 8K tokens for no quality benefit.

## Gotchas

- **Output tokens dominate long responses** — Opus's $25/MTok output is 5x its input rate. A long Opus response is expensive at any input size; cap `max_tokens`.
- **Tokenizer shift at 4.7.** Opus 4.7/4.8 (and Fable 5, Sonnet 5) use a tokenizer that produces ~30% more tokens for the same text than 4.6-and-earlier. Re-baseline token budgets with `count_tokens` when upgrading from 4.6 or older.
- **Fable 5 is not a drop-in Opus swap.** Always-on adaptive thinking (explicit `disabled` 400s), no assistant prefill, refusal handling required, 30-day retention required. Read the migration guide before routing traffic to it.

## Cross-references

- [Claude Sonnet](/stacks/anthropic-claude/claude-sonnet/) — production default
- [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) — cheap tier
- [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) — required cost lever
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — model-selection flowchart
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — when-Claude decisions
- [Anthropic Pricing](https://docs.anthropic.com/en/docs/about-claude/pricing) — verify current rates
