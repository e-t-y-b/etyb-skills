---
title: Codex CLI
description: "Open-source terminal coding agent. `npm i -g @openai/codex` or `brew install codex`. Pairs with the cloud Codex product — peer to Claude Code."
product:
  name: Codex CLI
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer]
  authoritative_url: https://github.com/openai/codex
  notes: "Open-source; npm-distributed; pairs with the cloud Codex agent product; peer to Claude Code in the terminal-agent landscape."
---

## What it is

The Codex CLI is OpenAI's open-source terminal coding agent — pairs with the cloud [OpenAI Codex (agent product)](/stacks/openai/openai-codex/). Distributed via:

- `npm install -g @openai/codex`
- `brew install codex`

GitHub repo: [github.com/openai/codex](https://github.com/openai/codex).

It is a **peer to Claude Code**, not a successor to anything from 2023. Like Claude Code, it runs in the terminal, takes natural-language instructions, makes filesystem edits, runs commands, iterates.

## When to use

**Use Codex CLI when:**

- You're a terminal-first developer who wants a coding agent in the shell.
- The team is on OpenAI (you're using GPT-5 / o-series under the hood anyway).
- You want an open-source CLI you can audit and extend.
- You want the local-files-aware companion to the cloud Codex product.

**Use Claude Code when:** the team is on Claude. Both CLIs serve similar workflows; pick by provider commitment.

**Use both** when you want to compare outputs side-by-side for a specific task.

## 2025-2026 currency anchors

- **Open-source.** Repo at [github.com/openai/codex](https://github.com/openai/codex).
- **Multi-distribution** — npm + brew + (verify) other channels.
- **Pairs with cloud Codex** but can be used independently as a standalone coding agent.
- **Peer to Claude Code** — same product category, different provider.
- **Built on Responses API + Agents SDK conventions** under the hood (verify against the repo).
- **Evolves with the cloud Codex product** — release cadence tracks OpenAI's coding-agent roadmap.

## Patterns

### Pattern: terminal coding workflow

```
$ codex "Add a /healthz endpoint that returns service version"
# agent makes edits, runs tests, asks for confirmation on uncertain changes
```

### Pattern: pair with cloud Codex

Use Codex CLI for terminal-side tasks; switch to cloud Codex IDE for visual diff + larger-context refactors. Both share the same backing models.

### Pattern: alongside Claude Code

Some teams run both — Claude Code for one task, Codex CLI for another, A/B comparing outputs. Each CLI has its own credentials, its own session, its own model preferences.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Confusing Codex CLI with `code-davinci-002` | Different artifact entirely. CLI is the 2025 terminal agent. |
| Skipping local CI / tests before committing the agent's edits | Always run tests + linter + review the diff. Agents make mistakes. |
| Putting production API keys in the CLI config without rotation discipline | Treat like any prod-grade key. Project-scoped keys + rotation. |
| Letting the agent commit + push without human review | Human approval before commit/push. |
| Running the agent without a clean working tree | Stash or commit first. Agent edits should be reviewable diffs. |

## Gotchas

- **Open-source pace.** Releases are frequent. Update regularly.
- **Permissions.** The agent can run shell commands. Restrict where appropriate (e.g., sandboxed dev container).
- **Cost.** Agent loops can consume tokens fast. Set budget caps.
- **Token + cost telemetry** — see what the agent consumed per session; log + observe.
- **Filesystem scope.** Be explicit about which directories the agent can read/write.
- **Pair with version control.** Always work on a feature branch. Don't let the agent commit to main directly.

## Cross-references

### Related products in this Stack

- [OpenAI Codex (agent product)](/stacks/openai/openai-codex/) — cloud + IDE companion.
- [Agents SDK](/stacks/openai/agents-sdk/) — the SDK conventions Codex CLI sits on.
- [GPT-5 family](/stacks/openai/gpt-5/) / [o-series](/stacks/openai/o-series-reasoning/) — underlying models.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — CLI + IDE agent comparison.

### Authoritative sources

- [Codex CLI GitHub](https://github.com/openai/codex)
- [OpenAI Codex product page](https://codex.openai.com)
