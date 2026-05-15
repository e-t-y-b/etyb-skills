---
title: Supabase Studio
description: The hosted + local dashboard UI. SQL editor, Reports, Advisor, AI assistant, plus an inspection surface for every other product.
product:
  name: Supabase Studio
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, frontend-architect, security-engineer, ai-ml-engineer, saas-architect]
  authoritative_url: https://supabase.com/docs/guides/getting-started/architecture
  notes: "Studio is your inspection plane (Reports, Advisor, SQL editor). Local Studio comes with `supabase start`; hosted Studio is the dashboard."
---

## What it is

Supabase Studio is the dashboard UI for a Supabase project — hosted at `supabase.com/dashboard/project/<ref>` and also bundled locally with `supabase start` at `http://localhost:54323`. It's the inspection plane: table editor, SQL editor, Auth users, Storage buckets, Edge Function logs, Reports, Advisor, AI assistant.

## When to use

Use Studio for:
- **Schema inspection** — table editor, column types, indexes.
- **SQL editor + EXPLAIN ANALYZE** — query authoring + plan inspection.
- **Reports** — query performance, top slow queries.
- **Database Advisor** — surfaces missing indexes, unused indexes, RLS-disabled tables, security drift.
- **Auth admin** — user list, MFA factors, providers config.
- **Storage admin** — buckets, objects, policies.
- **Logs Explorer** — Edge Functions, Auth, PostgREST, Realtime logs.
- **Webhooks + Cron + Queues** UI configuration.

Don't use Studio as:
- **Your migration tool.** Always export via `supabase db diff`.
- **A production data editor.** Inline edits via table editor land instantly; no review trail.
- **A daily dev environment.** The CLI + `supabase start` is the workflow; Studio is the inspector.

## 2025-2026 currency anchors

- **AI assistant in SQL editor** — natural-language → SQL, with schema-aware context. Heavily updated 2025-2026.
- **"Explain" button** in SQL editor — runs `EXPLAIN (ANALYZE, BUFFERS)` and renders a flame graph.
- **Reports → Query Performance** — curated cut of `pg_stat_statements`.
- **Database Advisor** — security + performance lints; run monthly minimum.
- **Local Studio** mirrors hosted with most features; some org-level features (members, billing) are hosted-only.

## Patterns and anti-patterns

### Patterns

**Day-1 discovery on a new project**:
- Database → Advisor → review all warnings.
- Database → Reports → identify top slow queries.
- Auth → Providers → verify which providers are enabled, SMTP configured.
- Edge Functions → logs → confirm functions are healthy.
- Storage → review buckets, policies.

**SQL Editor + Explain** for any RLS or query change touching tables >10k rows.

**Logs Explorer filters** with structured JSON `console.log` from Edge Functions:

```ts
console.log(JSON.stringify({ level: "info", function: "process-order", duration_ms: 42 }));
```

Then filter by `function: "process-order"` in Studio.

**Save SQL editor snippets** for repeatable diagnostics (top queries, lock waits, advisor checks).

### Anti-patterns

- **Editing migrations or running ad-hoc DDL via Studio in production.** Use the CLI + PR workflow.
- **Treating Studio as the source of truth for schema.** Source of truth is `supabase/migrations/` or `supabase/schemas/`.
- **Sharing dashboard access widely.** Studio access = service-role equivalent. Use the org access controls.
- **Ignoring Advisor warnings.** RLS-disabled tables, missing `search_path`, missing indexes — each one is a real bug.

## Gotchas

- **Local Studio uses local Postgres**; switching between local and linked-project context is by toggle. Get this wrong and you're inspecting the wrong DB.
- **Service-role queries via Studio bypass RLS.** Useful for admin work; don't confuse with "RLS is working" for end users.
- **The AI assistant generates SQL but doesn't run it.** Review before executing — especially on production projects.
- **Realtime tab can show events from `realtime.*` schema for debugging** — useful when channels misbehave.
- **Quota / cost dashboards live under Settings → Usage**, not under each product.

## Cross-references

- [Supabase CLI](/stacks/supabase/supabase-cli/) — the workflow surface paired with Studio's inspection
- [Postgres](/stacks/supabase/postgres/) — `pg_stat_statements` powers Reports
- [Row-Level Security](/stacks/supabase/row-level-security/) — Advisor flags RLS-disabled tables
- Supabase docs: [Architecture overview](https://supabase.com/docs/guides/getting-started/architecture)
