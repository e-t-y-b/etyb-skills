---
title: Migrations
description: "Declarative schemas vs diff-based migrations. Pick one per project; mixing is the #1 cause of broken `db push`."
product:
  name: Migrations
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, devops-engineer]
  authoritative_url: https://supabase.com/docs/guides/deployment/database-migrations
  notes: "Declarative schemas (`supabase/schemas/*.sql`) added 2024 alongside diff-based; mixing them is the top cause of broken `db push`."
---

## What it is

Supabase ships two migration workflows:

- **Diff-based** (default since 2020) — sequence of `supabase/migrations/<timestamp>_<name>.sql` files; you author by editing a local DB and running `supabase db diff -f <name>`.
- **Declarative** (added 2024) — `supabase/schemas/*.sql` files are the source of truth; `supabase db diff` generates migrations to bring the live DB to match.

Both produce the same `migrations/` history; the difference is what you edit.

Source: [Migrations docs](https://supabase.com/docs/guides/deployment/database-migrations), [Declarative schemas](https://supabase.com/docs/guides/local-development/declarative-database-schemas).

## When to use

Pick **one workflow per project**:

| Use diff-based when | Use declarative when |
|---------------------|----------------------|
| Existing project with 50+ migrations of history | Greenfield project, schema is mostly new |
| Team lives in Studio / psql for ad-hoc changes | Team prefers schema-as-code reviewable in PRs |
| You want explicit history of "what changed when" | You want to rebase the schema cleanly |

**Don't mix.** Once you start declarative, all schema changes go through `schemas/`. Once you start diff-based, all changes go through `db diff`. Mixing modes is the #1 cause of broken `supabase db push`.

## 2025-2026 currency anchors

- **Declarative schemas** (`supabase/schemas/*.sql`) added 2024 — one logical file per concern (`users.sql`, `orders.sql`).
- **`supabase db diff -f <name>`** is the generator for both workflows; difference is what it diffs against.
- **`supabase db reset`** wipes local and re-applies migrations + seed.
- **`supabase db pull`** introspects remote into a migration — catch-up tool for diff-based.
- **Branching integration** — preview branches replay migrations at merge time. See [Branching](/stacks/supabase/branching/).
- **`supabase db lint`** runs schema checks and is the right CI step.

## Patterns and anti-patterns

### Patterns

**Diff-based loop:**

```bash
supabase start
supabase db reset
# ... edit schema via Studio / psql ...
supabase db diff -f add_orders_table
# inspect migrations/<timestamp>_add_orders_table.sql, commit
supabase db push --linked  # apply to a remote (preview branch ideally)
```

**Declarative loop:**

```bash
# Edit supabase/schemas/orders.sql
supabase db diff -f add_orders_table   # generates a migration bridging live → schema
# inspect, commit, then:
supabase db push --linked
```

**Always go via a preview branch** — don't `db push` directly to production. [Branches](/stacks/supabase/branching/) replay migrations at merge time, giving you a tested promotion.

**CI step on every PR:**

```bash
supabase start
supabase db reset                       # asserts migrations apply clean
supabase db lint                        # asserts schema invariants
psql "$DB_URL" -f tests/rls/*.sql       # asserts RLS policies behave
```

**Type generation after migration:**

```bash
supabase gen types typescript --linked > types/database.ts
```

Wire into a post-migration step in deploy + into `predev` for local.

**Two-phase destructive changes** — never combine in one PR:
- Phase 1: ship code that stops using the column.
- Phase 2: drop the column in a follow-up migration.

### Anti-patterns

- **Mixing declarative and diff-based.** Pick one.
- **Editing `supabase/migrations/*.sql` after they've been applied.** Migrations are append-only.
- **`supabase db push` directly to production** without preview-branch validation.
- **Skipping `supabase db reset` in CI.** Catches broken migrations before they reach humans.
- **Hand-writing migrations that drop columns** without a deprecation period.
- **Two developers running `db diff` in parallel** without coordinating timestamps. The diffs collide on merge.

## Gotchas

- **Migration timestamps must be monotonic.** Parallel work gets renumbered on rebase.
- **The local DB drifts from migrations when you edit via Studio without diffing.** Run `db diff` before commits, or use declarative to avoid the drift question.
- **`db pull` introspects everything**, including extensions you didn't intend to capture. Review the generated migration carefully.
- **Reordering migrations is forbidden.** They apply in timestamp order; renaming for clarity is fine, reordering for logic is not.
- **Declarative diff isn't complete.** Some changes (renaming a column with data preservation, complex type conversions) need a hand-written migration as a bridge.
- **PG major upgrade may invalidate extensions.** Re-create `pg_graphql`, `pg_cron`, `wrappers` post-upgrade if pre-check flagged them.

## Cross-references

- [Postgres](/stacks/supabase/postgres/) — what migrations migrate
- [Branching](/stacks/supabase/branching/) — preview branches as the safe `db push` target
- [Supabase CLI](/stacks/supabase/supabase-cli/) — the surface for all migration commands
- [database-architect role view](/stacks/supabase/database-architect/) — declarative vs diff decision in depth
- Supabase docs: [Database migrations](https://supabase.com/docs/guides/deployment/database-migrations), [Declarative schemas](https://supabase.com/docs/guides/local-development/declarative-database-schemas)
