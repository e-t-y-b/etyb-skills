---
title: Workbench / Console
description: The Anthropic web UI at console.anthropic.com — prompt experimentation, key management, usage dashboards, workspace administration. Surface stable; the place to debug prompts interactively.
product:
  name: Workbench / Console
  stack: anthropic-claude
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, backend-architect, security-engineer]
  authoritative_url: https://console.anthropic.com/
  notes: "Web UI; surface stable; the place to debug prompts interactively and review per-key usage."
---

## What it is

The Anthropic Console at [console.anthropic.com](https://console.anthropic.com/) is the web UI for Anthropic API administration and prompt experimentation. The **Workbench** is the interactive prompt-testing surface within the Console — author a prompt, run it against any current model, inspect the response, tweak, iterate.

Surfaces:

- **Workbench** — interactive prompt + tool experimentation; the fastest way to debug prompt behavior.
- **API Keys** — create, rotate, revoke keys per workspace.
- **Workspaces** — isolation boundaries for tenants / environments / products.
- **Usage** — per-key, per-workspace, per-model token usage and cost.
- **Limits** — spend caps, rate limits, alerts.
- **Logs** — request inspection (where available per plan tier).

## When to use

The Console is right for:

- **Prompt debugging.** Drop the exact request payload from production into the Workbench; iterate until it produces the right output; ship the corrected prompt.
- **Quick eval comparisons.** Run a prompt against Sonnet vs Opus; eyeball the quality delta before deciding to escalate.
- **Manual key rotation** (one-off) or workspace creation (one-off). For programmatic provisioning, use the [Admin API](/stacks/anthropic-claude/admin-api/) instead.
- **Usage analytics.** Per-key cost dashboards, monthly review.

Don't use the Console for:

- **Production provisioning.** Use the Admin API — automated, audited, repeatable.
- **Eval suites.** Use [promptfoo](https://github.com/promptfoo/promptfoo), DeepEval, or [Braintrust](https://braintrust.dev/) — the Workbench is for one-off interactive iteration, not regression testing.
- **Anything you need to do at scale or programmatically.**

## 2025-2026 currency anchors

- **Surface stable** through 2025-2026; periodic UI refreshes don't change the fundamental capabilities.
- **Workbench supports current Claude models** including [Opus](/stacks/anthropic-claude/claude-opus/) (with 1M context), [Sonnet](/stacks/anthropic-claude/claude-sonnet/), [Haiku](/stacks/anthropic-claude/claude-haiku/).
- **Workbench supports tool use** with interactive tool definition and call inspection.
- **Workbench supports [Extended Thinking](/stacks/anthropic-claude/extended-thinking/)** — see thinking blocks alongside text.
- **Per-key spend caps** configurable in the UI; for production, automate via [Admin API](/stacks/anthropic-claude/admin-api/).

## Patterns + anti-patterns

### Pattern — production-bug reproduction on the Workbench

A user reports the agent gave wrong output. Pull the exact request payload from your logs (sanitize PII first); paste into the Workbench; reproduce the bug; iterate the prompt; ship the fix. The Workbench shows you the model's actual response without your service's parsing/post-processing in the way.

### Pattern — Workbench as eval scratchpad

Quick "is this prompt better?" checks before the formal eval suite. Three prompts in the Workbench, eyeball the diffs, commit the winner to your eval framework for the rigorous comparison.

### Pattern — Console for usage anomaly review

Daily / weekly check on the Usage page: which keys spent what, are there outliers, did cache hit rates drop. Set up Admin-API-driven alerting for the same metrics; use the Console for human investigation when alerts fire.

### Anti-pattern — production provisioning via Console clicks

Manual key creation through the UI doesn't scale, doesn't audit cleanly, and creates drift. Automate via Admin API.

### Anti-pattern — Workbench as the eval suite

A few interactive prompts in the Workbench is not a regression test. Quality regressions slip through. Use [promptfoo](https://github.com/promptfoo/promptfoo) or equivalent for actual eval coverage.

### Anti-pattern — pasting PII into the Workbench

PII in the Workbench gets sent through the API like any other request. Sanitize before pasting. If you need to debug PII-containing prompts, mask realistically (replace real names/numbers with synthetic ones that preserve the structure of the problem).

## Gotchas

- **Workbench prompts use your default key / workspace** — be careful which workspace context you're in if you have multiple. PII in a non-prod workspace is still PII.
- **Workbench is single-turn-friendly.** Multi-turn conversation debugging is more cumbersome; for that, use the SDK locally with a logger.
- **Console UI is not the source of truth for your prompts.** Your prompts live in source control. Workbench iterations should land back in your repo with a commit.

## Cross-references

- [Admin API](/stacks/anthropic-claude/admin-api/) — programmatic alternative for everything but interactive prompt testing
- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — what the Workbench actually calls
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — Console in the SDLC
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — PII handling in the Workbench
- [Anthropic Console](https://console.anthropic.com/)
