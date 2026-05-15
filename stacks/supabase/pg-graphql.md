---
title: pg_graphql
description: Auto-generated GraphQL endpoint from your Postgres schema. It works, but rarely the right primary API choice.
product:
  name: pg_graphql
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect]
  authoritative_url: https://supabase.com/docs/guides/graphql
  notes: "Enabled by default; reflects schema changes; rarely the right choice for app-internal APIs."
---

## What it is

`pg_graphql` is a Postgres extension that auto-generates a GraphQL endpoint from your schema. Enabled by default on Supabase; queryable at `https://<project>.supabase.co/graphql/v1`.

Source: [Supabase GraphQL guide](https://supabase.com/docs/guides/graphql).

## When to use

| Use pg_graphql for | Use [PostgREST](/stacks/supabase/supabase-js/) or [Edge Functions](/stacks/supabase/edge-functions/) for |
|--------------------|---------------------------------------------------------------------------------------------------------|
| Public-facing GraphQL endpoint (you're a content platform with a spec) | Internal app APIs (most cases) |
| LLM/agent use cases where the introspective schema is useful | Complex authorization rules that don't map to RLS |
| Quick queries from a GraphQL-native client | Performance-sensitive paths (PostgREST is leaner) |

**Default: don't use it.** For internal apps, PostgREST + RLS + supabase-js is the right answer; the generated GraphQL schema follows DB shape rather than client shape, and authorization is more naturally per-table than per-graph.

## 2025-2026 currency anchors

- **Reflects schema changes automatically** — DDL changes propagate to the GraphQL surface.
- **PG17 compatibility check needed on major upgrade.** Re-create extension if the upgrade pre-check flags it.
- **RLS applies** — pg_graphql runs as the caller, so policies on underlying tables gate the rows.
- **No persisted queries / no rate-limited query depth controls out of the box.** Public exposure requires a CDN-layer guard.

## Patterns and anti-patterns

### Patterns

- **Use for an LLM agent's introspection surface** — the schema description is good prompt fuel.
- **Use for content-platform public APIs** — when you genuinely want GraphQL semantics on a stable schema.
- **Disable in projects that don't use it** — one less surface to harden.

### Anti-patterns

- **Building an internal SPA against pg_graphql** when supabase-js + PostgREST works fine. You'll fight the schema shape and the RLS interaction.
- **Exposing pg_graphql publicly without rate limits.** Query depth and node-count attacks are trivial.
- **Using pg_graphql for write-heavy mutations.** PostgREST RPC or Edge Functions are better for transactional writes.

## Gotchas

- **Authorization is per-table RLS, not per-field/per-type.** Complex GraphQL authorization rules that don't map to row predicates are awkward.
- **N+1 query risk on nested selections.** pg_graphql tries to flatten, but deep selections on large datasets can be slow.
- **Generated schema follows your DB column names.** Renaming a column renames the GraphQL field — coordinate with clients.
- **Extension may need re-create on Postgres major upgrade.**

## Cross-references

- [supabase-js](/stacks/supabase/supabase-js/) — the typical alternative for internal apps
- [Edge Functions](/stacks/supabase/edge-functions/) — for custom GraphQL servers if pg_graphql doesn't fit
- [backend-architect role view](/stacks/supabase/backend-architect/) — API choice decision
- Supabase docs: [GraphQL](https://supabase.com/docs/guides/graphql)
