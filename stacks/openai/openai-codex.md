---
title: OpenAI Codex (agent product)
description: 2025 cloud + IDE coding agent powered by GPT-5 family / o-series. DISTINCT from the retired 2023 code-davinci model — same brand, totally different artifact.
product:
  name: OpenAI Codex (agent product)
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://codex.openai.com
  notes: "Launched 2025; cloud + IDE coding agent product. DISTINCT from 2023-retired code-davinci-002. Always confirm intent before answering 'Codex' questions."
---

## What it is

**OpenAI Codex (2025)** is OpenAI's coding-agent product — a cloud + IDE surface (`codex.openai.com`) powered by [GPT-5 family](/stacks/openai/gpt-5/) and [o-series reasoning models](/stacks/openai/o-series-reasoning/). It does multi-step coding work — implementation, refactor, test generation — across whole repositories.

**This is NOT the 2023 Codex model.** The 2023 `code-davinci-002` ("Codex" of that era) was retired in March 2023. The 2025 "OpenAI Codex" is a product brand applied to a new agentic surface. **Always confirm intent before answering questions about "Codex" — the brand collision causes constant confusion.**

The terminal-side companion is the [Codex CLI](/stacks/openai/codex-cli/).

## When to use

**Use OpenAI Codex when:**

- The team wants a fully-managed cloud-side coding agent — you don't want to build your own.
- You want a IDE-integrated agent for multi-step coding tasks across a repo.
- You're evaluating coding-agent products alongside Claude Code, Cursor Agent, GitHub Copilot Workspace.

**Use [Codex CLI](/stacks/openai/codex-cli/) when:** you want the terminal-side agent that pairs with the cloud product (open-source, npm-distributed).

**Use your own [Agents SDK](/stacks/openai/agents-sdk/) build when:** you want to define the coding workflow yourself — custom tools, custom prompts, your own orchestration.

**Don't conflate with `code-davinci-002`** — that's the retired 2023 model. If a 2026 codebase references it, flag immediately.

## 2025-2026 currency anchors

- **Launched 2025** as a coding-agent product — distinct from `code-davinci-002` (retired March 2023).
- **Cloud surface** at `codex.openai.com`; **IDE-integrated**.
- **Powered by GPT-5 family + o-series** for reasoning-heavy code tasks.
- **Pairs with [Codex CLI](/stacks/openai/codex-cli/)** for terminal workflows.
- **Peer to Claude Code, Cursor Agent, GitHub Copilot Workspace** in the 2026 coding-agent landscape.

## Patterns

### Pattern: clarify the term "Codex"

If a user mentions "Codex," confirm:

- "Are you asking about the OpenAI Codex agent product (2025, `codex.openai.com`) or the retired 2023 `code-davinci-002` model?"

If the answer is the retired model, redirect: "That was retired March 2023. The 2026 path is either the new OpenAI Codex agent product or [Agents SDK](/stacks/openai/agents-sdk/) with GPT-5 / o-series for custom coding workflows."

### Pattern: Codex vs Claude Code vs Cursor

| Surface | Strength | Best for |
|---|---|---|
| OpenAI Codex (cloud + IDE) | Tight OpenAI integration; multi-step | OpenAI-only teams |
| Claude Code | Anthropic models; CLI-first | Teams on Claude |
| Cursor | IDE-first; multi-provider | IDE-bound teams |
| Codex CLI (terminal) | Open-source; pairs with cloud Codex | Terminal-first workflows |
| GitHub Copilot Workspace | GitHub-native; multi-provider | GitHub-bound teams |

Pick by where the team works (terminal / IDE / cloud-only) and which provider is committed.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Confusing Codex (2025 agent product) with code-davinci-002 (2023 retired model) | Always confirm intent. |
| Recommending code-davinci-002 in 2026 code | Retired. Suggest GPT-5 / o-series with Codex agent product OR Agents SDK. |
| Assuming Codex is OpenAI's only coding-agent product (it has API alternatives too) | Codex is a managed product; you can build similar with [Agents SDK](/stacks/openai/agents-sdk/) + custom tools. |
| Using cloud Codex when team is fully terminal-bound | Codex CLI is the pair. |
| Skipping eval when adopting a coding agent | Eval against your repo + your test suite before adopting. |

## Gotchas

- **Brand collision.** "Codex" means two different things. Confirm before answering.
- **Cloud surface evolves rapidly.** Verify current features at [codex.openai.com](https://codex.openai.com).
- **Underlying models matter.** Coding tasks benefit from o-series reasoning for complex refactors; GPT-5 for general coding. Codex selects under the hood.
- **Privacy + data residency.** Code submitted to Codex is processed by OpenAI; standard data-retention + DPA applies.
- **Repo-scale context** — Codex can ingest whole repos; cost scales with codebase size.

## Cross-references

### Related products in this Stack

- [Codex CLI](/stacks/openai/codex-cli/) — terminal companion.
- [Agents SDK](/stacks/openai/agents-sdk/) — build your own coding agent.
- [GPT-5 family](/stacks/openai/gpt-5/) / [o-series](/stacks/openai/o-series-reasoning/) — underlying models.
- [Predicted Outputs](/stacks/openai/predicted-outputs/) — useful in code-edit pipelines.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — coding-agent design + selection.
- [system-architect](/stacks/openai/system-architect/) — coding-agent in your dev tooling stack.

### Authoritative sources

- [OpenAI Codex product page](https://codex.openai.com)
- [OpenAI Deprecations](https://platform.openai.com/docs/deprecations) — for the 2023 retired model history
