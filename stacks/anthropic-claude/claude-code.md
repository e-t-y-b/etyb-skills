---
title: Claude Code
description: Anthropic's general-purpose agent harness — CLI + IDE extensions with hooks, slash commands, Skills, sub-agents, plan mode, settings.json. CLI updates weekly; the substrate ETYB runs on.
product:
  name: Claude Code
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, ai-ml-engineer, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/claude-code/overview
  notes: "CLI updates weekly; hooks, settings.json, slash commands, plan mode evolve rapidly. The harness ETYB itself runs on."
---

## What it is

Claude Code is Anthropic's general-purpose agent harness — a CLI plus IDE extensions (VS Code, JetBrains, etc.) with first-class support for:

- **Hooks** — deterministic scripts that fire outside the LLM (pre-edit, pre-commit, pre-merge). The reliability layer.
- **Slash commands** — `/clear`, `/compact`, custom-defined `/foo` commands authored via skills.
- **[Skills](/stacks/anthropic-claude/skills/)** — `SKILL.md` files with frontmatter, auto-loaded by description-trigger match.
- **[Sub-agents](/stacks/anthropic-claude/sub-agents/)** — `.claude/agents/<name>.md` files with their own context, tools, model.
- **Plan mode** — propose-then-execute flow for complex tasks.
- **`settings.json`** — per-project + per-user config: permissions, env, hooks, MCP servers.
- **[MCP](/stacks/anthropic-claude/mcp/) clients** — Claude Code is a first-class MCP consumer.

See [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/overview). **This is the harness ETYB itself runs on** — every adapter in `skills/etyb/adapters/claude/` targets Claude Code's conventions.

## When to use

Claude Code is right for:

- **Developer-loop agent work** — coding, refactoring, debugging, code review, doc generation.
- **CI/CD automation** — invoking Claude Code in Actions / GitLab CI for PR review, eval runs, security scans.
- **Codifying team conventions** — ship Skills + sub-agents in the repo so everyone's Claude Code has the same context.
- **Personal productivity** — slash commands, custom Skills, hooks for ergonomic workflows.

Don't use Claude Code when:

- **Building a production service** that wraps Claude as a backend. Use the [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) + [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) directly.
- **End-user-facing agents.** Claude Code is a developer harness; the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) is the substrate for service-facing agents.

## 2025-2026 currency anchors

- **Weekly CLI updates.** New features (hooks, plan mode improvements, new slash commands, new tools) land on a weekly cadence. Pin a CLI version in CI; update with explicit review.
- **Skills as first-class capability** (2025) — `.claude/skills/<name>/SKILL.md` auto-loads on description match.
- **Sub-agents formalized** in `.claude/agents/<name>.md` with their own description, tools, system prompt, model.
- **Hooks fire deterministically** outside the LLM via `.claude/settings.json`. Use them for guarantees, not vibes.
- **Plan mode** — explicit propose-then-execute flow for multi-step work, with user approval between phases.
- **MCP integration via `.claude/settings.json`** — declare MCP servers, their commands, env vars; Claude Code spawns and connects them.

## Patterns + anti-patterns

### Pattern — ship Skills in the repo

`.claude/skills/<name>/SKILL.md` versioned with the codebase. Every team member's Claude Code has the same team conventions, debugging tips, codebase quirks. Reviewed in PRs like any other code.

### Pattern — hooks as the deterministic safety layer

```json
// .claude/settings.json
{
  "hooks": {
    "pre-edit-check": ".claude/hooks/check-test-exists.sh",
    "pre-merge-verify": ".claude/hooks/run-tests.sh",
    "pre-commit-review-check": ".claude/hooks/check-review-evidence.sh"
  }
}
```

Hooks execute outside the LLM. They cannot be bypassed by clever prompting — that's the value. Use them for invariants you must guarantee (no merge without green tests, no commit without review evidence).

### Pattern — sub-agents for specialized review

`.claude/agents/security-reviewer.md` with its own description (when to invoke), tools (read-only scanning), system prompt (security focus), and model (Sonnet, not Opus). Primary agent invokes via the Task tool when triggered. See [Sub-agents](/stacks/anthropic-claude/sub-agents/).

### Pattern — plan mode for high-stakes changes

Multi-file refactors, schema migrations, API changes — propose plan first, get user approval, execute one step at a time, verify between steps. Plan mode formalizes this.

### Pattern — custom slash commands via Skills

A Skill with a slash-command name (e.g., `/review-pr`) becomes a user-invokable command. Useful for codifying common workflows.

### Anti-pattern — Claude Code as a production backend

Claude Code is a developer harness; it's not designed for embedded service use. Use the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) for that.

### Anti-pattern — Skills out-of-band

Each developer installs Skills locally; conventions diverge; debugging across the team is harder. Ship them in the repo.

### Anti-pattern — bypassing hooks "for speed"

Hooks exist because the team agreed on the invariant. Skipping them silently is a process violation — and after a few skips the invariant erodes.

### Anti-pattern — `.claude/settings.json` outside source control

Lost or untracked settings = inconsistent behavior across the team. Commit it.

## Gotchas

- **Weekly cadence means breaking changes occur.** Pin CLI versions in CI; track release notes; upgrade deliberately.
- **Per-project + per-user settings layering** — `~/.claude/settings.json` overlays `.claude/settings.json`. Conflicting permissions can confuse; use the `--debug` flag to inspect resolution.
- **Hook failures fail the operation.** A failing `pre-edit-check` blocks the edit. Good when correct; frustrating when the hook itself is buggy. Test hooks before shipping.
- **Skill trigger specificity matters** — over-broad description = Skill loads when it shouldn't and pollutes context. Under-specific = Skill doesn't load when needed. See [Skills](/stacks/anthropic-claude/skills/).

## Cross-references

- [Skills](/stacks/anthropic-claude/skills/) — `.claude/skills/` Skill authoring
- [Sub-agents](/stacks/anthropic-claude/sub-agents/) — `.claude/agents/` sub-agent files
- [MCP](/stacks/anthropic-claude/mcp/) — Claude Code as MCP client
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — service-facing agent alternative
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — Claude Code in the SDLC
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)
