---
title: Extended Thinking
description: "Claude produces internal reasoning before its final response. On current models (Opus 4.6+, Sonnet 5, Fable 5) use adaptive thinking + `output_config.effort`; manual `budget_tokens` is removed on 4.7+/Sonnet 5. `signature` field must round-trip across tool-use turns on models that return it."
product:
  name: Extended Thinking
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-07-05"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
  notes: "Adaptive thinking (thinking: {type: adaptive}) is the current mode on Opus 4.6+, Sonnet 5, Fable 5; budget_tokens returns 400 on Opus 4.7/4.8, Sonnet 5, Fable 5. Depth is controlled by output_config.effort. Manual budget_tokens survives only on pre-4.6-era models and Haiku 4.5."
---

## What it is

Extended thinking lets Claude produce internal reasoning as `thinking` content blocks before its final `text` response. The configuration surface changed across 2025-2026 — know which regime your model is in:

- **Current models (Opus 4.6/4.7/4.8, Sonnet 5, Fable 5): adaptive thinking.** `thinking: {"type": "adaptive"}` — Claude decides when and how much to think; depth is steered with `output_config: {"effort": "low" | "medium" | "high" | "xhigh" | "max"}` (support varies by model; default `high`). Interleaved thinking between tool calls is automatic. On Sonnet 5 adaptive is on by default when `thinking` is omitted; on Fable 5 thinking is **always on** (explicit `disabled` returns 400).
- **Manual extended thinking (`thinking: {"type": "enabled", "budget_tokens": N}`) is legacy.** Deprecated on Opus 4.6 / Sonnet 4.6; **removed — returns 400 — on Opus 4.7/4.8, Sonnet 5, and Fable 5.** It remains the mechanism only on older models (e.g. Sonnet 4.5, Haiku 4.5), where `budget_tokens` must be < `max_tokens` (min 1024).

```python
# Current models (Opus 4.6+, Sonnet 5)
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=16000,
    thinking={"type": "adaptive"},
    output_config={"effort": "high"},
    messages=[...],
)
```

See the [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking) and adaptive-thinking docs.

## When to use

Enable (or leave on) thinking for:

- **Hard reasoning problems** — math, multi-step logic, complex code generation.
- **Agent planning** — let the model think through a plan before executing tool calls.
- **Tasks where you'd prompt "think step by step"** — thinking is the supported way to do CoT, with the reasoning separated from the user-facing response.
- **Long agent chains with [Tool Use](/stacks/anthropic-claude/tool-use/)** — interleaved thinking between calls; quality on 50+ step chains observably improves.

Dial it down for:

- **Trivial tasks** — classification, extraction, formatting. Use `effort: "low"` (or `thinking: {"type": "disabled"}` where supported — not on Fable 5).
- **Latency-critical paths** — thinking adds latency. Lower effort before disabling; adaptive thinking already skips thinking on easy inputs.
- **Every-turn agent loops** — costs compound; steer with effort and prompt guidance rather than paying `max`-effort thinking on every turn.

## 2025-2026 currency anchors

- **Adaptive thinking replaced token budgets.** `budget_tokens` 400s on Opus 4.7/4.8, Sonnet 5, and Fable 5. If a user asks for a "thinking budget" on a current model, the answer is `output_config.effort`, not a token count. (`output_config.task_budget` — beta — is the separate whole-loop advisory budget.)
- **`thinking.display` defaults to `"omitted"` on Opus 4.7/4.8, Sonnet 5, and Fable 5** — thinking blocks stream with an empty `thinking` field. Set `display: "summarized"` to get readable summaries. Billing is identical either way; on Fable 5 / Mythos 5 the raw chain of thought is never returned.
- **`signature` / block round-trip discipline still applies.** Pass thinking blocks back verbatim (including empty-text blocks on Fable 5) when continuing a conversation on the same model. Stripping or modifying them = API rejection. The [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) preserves them automatically when you pass `response.content` back; manual REST builders forget.
- **Thinking tokens bill at output rate.** High effort on every classification query is unconscionable; cost compounds quickly.
- **Bedrock / Vertex parity** on adaptive thinking and effort — supported on both; verify per-feature in current docs.

## Patterns + anti-patterns

### Pattern — effort proportional to task difficulty

- **Trivial tasks:** `effort: "low"` (or thinking disabled where supported).
- **Standard production work:** `"medium"`-`"high"`.
- **Hard coding / agentic work:** `"high"`-`"xhigh"` (xhigh: Opus 4.7+, Sonnet 5, Fable 5).
- **Correctness-over-cost frontier work:** `"max"`.

Tune via evals — set the lowest effort that meets the quality bar; don't pay for unused thinking.

### Pattern — interleaved thinking on long agent chains

For agents with 10+ tool calls in sequence, thinking between tool results measurably improves coherence. Adaptive thinking interleaves automatically — no beta header. Pair with the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/), which handles block round-tripping correctly.

### Pattern — log thinking, display text

Thinking is the model's scratchpad. Log `thinking` blocks (set `display: "summarized"` if you need readable content) for debugging / replay / audit; display only `text` blocks to end users.

### Anti-pattern — showing thinking to end users

Thinking output isn't polished. It's the model working through a problem, complete with false starts and corrections. Render only the `text` content.

### Anti-pattern — sending `budget_tokens` to a current model

`thinking: {"type": "enabled", "budget_tokens": N}` on Opus 4.7/4.8, Sonnet 5, or Fable 5 is a hard 400, not a deprecation warning. Migrate to adaptive + effort before upgrading the model ID.

### Anti-pattern — modifying thinking blocks between turns

Thinking blocks are content-bound. Stripping or modifying them (including the `signature` field where present) = the API rejects the request. Pass them verbatim when round-tripping on the same model.

### Anti-pattern — thinking at high effort on every turn of a multi-turn chat

Each thinking turn adds latency and cost. Steer effort per route — high for hard turns, low for chit-chat — rather than one global setting.

## Gotchas

- **Round-trip is non-obvious.** The SDK handles it; manual REST builders need to copy `thinking` blocks verbatim when sending follow-up turns.
- **Thinking + tool use** requires explicit support in your loop — both content block types come back; both need to be passed forward correctly.
- **Streaming thinking** — `thinking_delta` events stream alongside `text_delta`; with `display: "omitted"` (the default on 4.7+/Sonnet 5/Fable 5) the stream looks like a long pause before output. Set `display: "summarized"` if users watch the stream.
- **Token usage** — thinking tokens count in `output_tokens`; `max_tokens` caps the total (thinking + response), and rate limits apply.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — `thinking` is a request parameter and response content block
- [Tool Use](/stacks/anthropic-claude/tool-use/) — interleaved thinking between tool calls
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — handles block round-trip
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — when to enable thinking
- [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)
