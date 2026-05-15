---
title: Supabase MCP Server
description: "Model Context Protocol server that lets agents drive a Supabase project. Default `--read-only`. Permissions and scoping still tightening."
product:
  name: Supabase MCP Server
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer, database-architect, ai-ml-engineer]
  authoritative_url: https://github.com/supabase-community/supabase-mcp
  notes: "Active surface; permissions, read-only flag, and scope-per-token are still tightening. Never connect with write scope to production without human-in-the-loop guards."
---

## What it is

The Supabase MCP server is a Model Context Protocol implementation that lets agents (Claude Code, Codex, Antigravity) drive a Supabase project: list tables, run SQL, deploy migrations, deploy Edge Functions, manage Auth users. It's the canonical "agent talks to Supabase" surface.

Source: [github.com/supabase-community/supabase-mcp](https://github.com/supabase-community/supabase-mcp).

## When to use

Use the MCP for:
- **Agent-assisted exploration** of a project's schema and data.
- **Agent-driven migration drafts** against a branch (NOT main).
- **LLM-as-developer workflows** where the agent needs project state.

Don't connect the MCP to:
- **Production projects with write scope.** Use a [branch](/stacks/supabase/branching/) or staging project.
- **Untrusted agents.** Treat MCP-mediated SQL like any other untrusted input.

## 2025-2026 currency anchors

- **`--read-only` flag** — restricts to SELECT-equivalent operations. Use unless you have explicit reason to allow writes.
- **Personal Access Token (PAT) scoped per project** — preferred over full-account PATs.
- **Active surface** — capabilities, flags, and scoping are tightening across 2025-2026 releases. Check the changelog before relying on specific commands.
- **Compatible with Claude Code, Codex, Google Antigravity** and any MCP-compliant agent runtime.

## Patterns and anti-patterns

### Patterns

**Read-only mode for exploration:**

```bash
npx -y @supabase-community/supabase-mcp \
  --access-token <pat> \
  --project-ref <ref> \
  --read-only
```

**Branch-scoped write mode** — agent drafts migrations against a branch:

1. Create a branch via [CLI](/stacks/supabase/supabase-cli/) or dashboard.
2. Point MCP at the branch.
3. Agent generates migrations; human reviews before merging branch → main.

**Audit MCP-generated SQL** like any other SQL — `EXPLAIN ANALYZE`, run against test data, PR review.

**Use PATs scoped to one project**, not full-account tokens. If the agent is compromised, blast radius is one project.

### Anti-patterns

- **Connecting with write scope to production** without human-in-the-loop guards. Catastrophic.
- **Sharing the same PAT across multiple agents.** Per-agent tokens or short-lived tokens.
- **Trusting agent-generated SQL** for security-sensitive work (RLS policies, `SECURITY DEFINER` functions) without review.
- **Letting user-controlled input reach an LLM that generates SQL against prod.** Prompt-injection-as-SQL-injection.

## Gotchas

- **MCP surface evolves** — capabilities, command names, flags shift across releases. Pin a version when integrating into automation.
- **Read-only is enforced server-side** but the agent's view of "read-only" depends on the client honoring the response. Defense-in-depth means PAT scope too.
- **Migration deployment via MCP** still goes through the normal `db push` path; the MCP just initiates it.
- **Network egress from Supabase to MCP client** — the MCP server runs locally typically; if you host it remotely, lock down access.
- **Agent context limits matter** — large schemas may exceed the agent's context window; the MCP exposes pagination/filtering for table lists.

## Cross-references

- [Branching](/stacks/supabase/branching/) — the sandbox for agent write operations
- [Supabase CLI](/stacks/supabase/supabase-cli/) — the alternative human-driven workflow
- [security-engineer role view](/stacks/supabase/security-engineer/) — MCP hardening checklist
- Source: [github.com/supabase-community/supabase-mcp](https://github.com/supabase-community/supabase-mcp)
