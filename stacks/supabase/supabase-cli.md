---
title: Supabase CLI
description: The unified local-dev, migrations, deploys, types, secrets surface. The CLI is where the workflow lives.
product:
  name: Supabase CLI
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, frontend-architect, devops-engineer]
  authoritative_url: https://supabase.com/docs/reference/cli
  notes: "Active surface; commands gain/lose flags often. db push vs declarative schemas is the current axis of change."
---

## What it is

The `supabase` CLI is the unified developer surface for working with Supabase locally and against linked projects. It starts a local stack (Postgres, Auth, Storage, Realtime, Edge Functions, Studio) for offline development, manages [migrations](/stacks/supabase/migrations/), deploys Edge Functions, generates TypeScript types, manages secrets, and links to remote projects.

Source: [CLI reference](https://supabase.com/docs/reference/cli).

## When to use

Use the CLI for:
- **Local development** — `supabase start` brings up the whole stack via Docker.
- **Schema migrations** — `supabase db diff`, `db push`, `db reset`, `db pull`.
- **Type generation** — `supabase gen types typescript --linked`.
- **Edge Functions** — `supabase functions deploy/serve`.
- **Secrets** — `supabase secrets set/unset/list`.
- **Branching** — `supabase branches create/list/delete`.

You can't avoid the CLI on any non-trivial Supabase project. Studio is for inspection; the CLI is where the workflow lives.

## 2025-2026 currency anchors

- **`supabase init`** scaffolds the local config and folder structure.
- **`supabase start` / `stop` / `status`** controls the local Docker stack.
- **`supabase db push`** applies pending migrations to the linked project — directly to main is the anti-pattern; go via a [preview branch](/stacks/supabase/branching/).
- **`supabase db diff -f <name>`** generates a migration file from the difference between local schema and migrations.
- **`supabase db reset`** wipes local and re-applies migrations + seed; the foundational CI step.
- **`supabase db pull`** introspects the remote schema into local — catch-up tool.
- **`supabase gen types typescript --linked > types/database.ts`** — the type-generation command; wire into `predev`.
- **`supabase functions deploy <name>`** ships an Edge Function.
- **`supabase secrets set MY_KEY=value`** sets Edge Function env secrets.
- **`supabase db lint`** runs the schema linter (catches RLS-disabled tables, missing search_path, etc.).
- **`supabase link --project-ref <ref>`** links the local project to a remote.

## Patterns and anti-patterns

### Patterns

**Local-first workflow:**

```bash
supabase init
supabase start                  # docker-compose stack
supabase db reset               # apply migrations + seed
# ... edit schema ...
supabase db diff -f add_orders  # generate migration
supabase gen types typescript --local > types/database.ts
supabase db push --linked       # apply to remote (preferably via branch)
```

**CI pipeline:**

```bash
supabase start
supabase db reset               # asserts migrations apply clean
deno test --allow-net supabase/functions/_tests/  # Edge Function tests
psql "$DB_URL" -f tests/rls/*.sql  # RLS impersonation tests
```

**Auto-regenerate types** via a `predev` npm script:

```json
{ "scripts": { "predev": "supabase gen types typescript --linked > types/database.ts" } }
```

**Link once, work many times** — `supabase link --project-ref <ref>` stores the link in `supabase/config.toml` (project-scoped) or in user state.

### Anti-patterns

- **`supabase db push` directly to production.** Always go through a [preview branch](/stacks/supabase/branching/).
- **Hand-editing `supabase/migrations/*.sql` after they've been applied.** Migrations are append-only.
- **`supabase functions deploy` without local `supabase functions serve` testing first.** Cold-start latency, env vars, and `Authorization` header forwarding are easy to miss otherwise.
- **`supabase db reset` skipped in CI.** Catches broken migrations before they reach humans.
- **Multiple developers running `supabase db diff` against the same local DB without sync.** The diff is relative to local state; coordinate via PR merges, not parallel diffs.

## Gotchas

- **Local stack requires Docker.** Resource-hungry on dev machines; configure Docker memory generously.
- **`supabase db reset` is destructive locally** — fine; just don't run against `--linked` thinking it's local.
- **The `--linked` flag** targets the linked remote project; default commands target local. Get this wrong and you'll either fail or worse.
- **Migration timestamps must be monotonic.** Two developers generating migrations in parallel get colliding timestamps; rebase fixes by renaming.
- **Type generation requires schema introspection access.** `--local` reads local; `--linked` reads remote — they must match for predictable types.
- **Edge Functions deployed via CLI inherit the linked project's region by default.** Use `--region` to pin.
- **CLI version drift between contributors** causes "works on my machine" issues. Pin the CLI version in `package.json` `devDependencies` (or use a tool-version file).

## Cross-references

- [Migrations](/stacks/supabase/migrations/) — diff-based vs declarative workflows
- [Branching](/stacks/supabase/branching/) — preview branches via CLI + dashboard
- [Edge Functions](/stacks/supabase/edge-functions/) — deploy/serve commands
- [Studio](/stacks/supabase/studio/) — the inspection surface paired with the CLI
- [Postgres](/stacks/supabase/postgres/) — local Postgres comes from `supabase start`
- Supabase docs: [CLI reference](https://supabase.com/docs/reference/cli)
