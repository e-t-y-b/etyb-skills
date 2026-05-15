---
title: Database Branching
description: Every PR can have its own database with seeded data. GA in 2024. Vercel/Netlify preview integration.
product:
  name: Database Branching
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, devops-engineer]
  authoritative_url: https://supabase.com/docs/guides/platform/branching
  notes: "GA in 2024; semantics for branch → main promotion still maturing; not a substitute for backups."
---

## What it is

Database Branching gives every PR a logical preview database. Each branch starts at `main`'s schema, applies branch-specific migrations, and integrates with Vercel/Netlify so preview deploys hit the preview database. On merge, migrations replay against `main`.

Source: [Branching docs](https://supabase.com/docs/guides/platform/branching).

## When to use

Use Branching for:
- **PR-scoped schema changes** with end-to-end preview environments.
- **Tenant-data migration testing** with realistic seed data.
- **AI-agent exploration** — point [MCP](/stacks/supabase/supabase-mcp/) at a branch instead of production.
- **Vercel/Netlify integration** — preview URL + preview database = full-stack PR review.

Don't use Branching for:
- **"Production preview" with real customer data.** Branches start from seed, not from prod data.
- **Disaster recovery.** Use [backups](/stacks/supabase/postgres/) + PITR.
- **Long-lived environments.** Branches are throwaway; staging belongs in a separate project.

## 2025-2026 currency anchors

- **GA in 2024.** Stable enough for production workflows.
- **Each branch is a separate logical database** — auth, storage, edge functions, all branch-scoped.
- **Migrations from branches replay against `main` at merge time.** They must be idempotent-safe.
- **Data does NOT flow back to main** — branches are dev environments. Promotion = migrations only.
- **Seed file (`supabase/seed.sql`)** determines branch contents on creation.
- **Vercel/Netlify integration** auto-creates branches per PR with matching preview URLs.

## Patterns and anti-patterns

### Patterns

**PR lifecycle:**
1. Open PR → preview branch auto-created.
2. CI runs migrations against branch + applies seed.
3. Vercel/Netlify preview deploy hits the branch.
4. Reviewer tests end-to-end against the preview.
5. Merge → migrations replay against `main`.

**Seed strategy** — `supabase/seed.sql` should produce a meaningful but small dataset:
- A few orgs, users, products.
- Representative edge cases (suspended org, empty org, multi-member org).
- Enough variety for UI snapshots.

**Treat migrations as commits.** Small, focused, well-named. Idempotent in the sense that they handle the case where main raced ahead.

**Use branches for tenant-data migration rehearsal:**

```sql
-- Phase 1 migration on branch: add column, backfill from seed
alter table public.orders add column total_with_tax numeric;
update public.orders set total_with_tax = total * 1.08;
-- Test against the branch's preview deploy.
-- Phase 2 (later PR): drop the original column, rename.
```

### Anti-patterns

- **Testing production migration on branch as if it had prod data.** Branches start from seed. Use a separate staging project with restored backup for that.
- **Long-lived feature branches with massive migration history.** Rebase regularly.
- **Connecting an AI agent with write scope to a production project** when a branch would do. Branches are the right sandbox.
- **Relying on data flowing back from branch to main.** It doesn't.
- **Branches as your staging environment.** Staging is a separate Supabase project with its own URL and budget.

## Gotchas

- **Branch creation has latency** — typically seconds to minutes; not instant. PR flows that block on branch ready may need a poll.
- **Migration replay at merge time** can fail if main races ahead. Resolve by re-running `db diff` on the rebased branch.
- **Branches consume project quota.** Pro+ tier has limits; check tier capacity.
- **Auth and Storage state are branch-scoped** — a user signed up on a branch doesn't exist on main.
- **Costs scale with branch count.** Inactive branches don't auto-cleanup; prune.
- **CLI / API surface for branch ops** (`supabase branches list/create/delete`) is active and gains commands; check the changelog.
- **Branches do NOT replace backups.** Disaster recovery is a separate concern.

## Cross-references

- [Migrations](/stacks/supabase/migrations/) — the unit that promotes from branch to main
- [Supabase CLI](/stacks/supabase/supabase-cli/) — branch management commands
- [Postgres](/stacks/supabase/postgres/) — backups + PITR for real DR
- [database-architect role view](/stacks/supabase/database-architect/) — branching strategy
- [saas-architect role view](/stacks/supabase/saas-architect/) — tenant migration rehearsal
- Supabase docs: [Branching](https://supabase.com/docs/guides/platform/branching)
