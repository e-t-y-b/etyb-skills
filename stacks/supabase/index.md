---
title: Supabase
description: Supabase platform knowledge overlay — Postgres, RLS, Auth, Storage, Realtime, Edge Functions, Supavisor, pgvector, Branching, Queues, Cron, MCP. Current to 2026-Q2.
stack:
  vendor: supabase
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - backend-architect
    - database-architect
    - frontend-architect
    - security-engineer
    - ai-ml-engineer
    - saas-architect
  authoritative_sources:
    - { name: "Supabase Docs",              url: "https://supabase.com/docs",                                                          type: official_docs }
    - { name: "Supabase Changelog",         url: "https://supabase.com/changelog",                                                     type: changelog }
    - { name: "Supabase CLI Reference",     url: "https://supabase.com/docs/reference/cli",                                            type: cli_reference }
    - { name: "supabase-js Reference",      url: "https://supabase.com/docs/reference/javascript",                                     type: api_reference }
    - { name: "@supabase/ssr Guide",        url: "https://supabase.com/docs/guides/auth/server-side",                                  type: api_reference }
    - { name: "Edge Functions Docs",        url: "https://supabase.com/docs/guides/functions",                                         type: official_docs }
    - { name: "RLS Performance Guide",      url: "https://supabase.com/docs/guides/database/postgres/row-level-security#performance",  type: official_docs }
    - { name: "Supabase Status",            url: "https://status.supabase.com",                                                        type: community }
    - { name: "Supavisor Source",           url: "https://github.com/supabase/supavisor",                                              type: official_docs }
    - { name: "Supabase MCP Server",        url: "https://github.com/supabase-community/supabase-mcp",                                 type: official_docs }
  delegate_to_skills:
    - { skill: "supabase:supabase",                          covers: [supabase-auth, supabase-storage, supabase-realtime, edge-functions, postgres, row-level-security, supabase-js, supabase-ssr, supabase-cli, migrations, supabase-vector] }
    - { skill: "supabase:supabase-postgres-best-practices",  covers: [postgres, row-level-security, database-functions, pg-trgm, pgvector] }
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="note" title="How to read this Stack">
Per-product pages under `/stacks/supabase/<product>/` carry the canonical knowledge. Role views under `/stacks/supabase/<role>/` compose those products through one role's lens. If you have the `supabase:supabase` skill installed, defer to it on matching products — this site is the curated fallback.
</Aside>

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Supabase Cloud (Postgres 17 default, supabase-js v2 stable / v3 stabilizing, Edge Functions Deno runtime, Supavisor as default pooler).</div>

If today's date is more than 6 months past the `last_verified_on` above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff will get these wrong. Read carefully:

- **`@supabase/auth-helpers-*` is dead.** Use [`@supabase/ssr`](/stacks/supabase/supabase-ssr/) for every Next.js / SvelteKit / Remix / Astro app. The old helper packages will steer you into broken middleware and cookie bugs.
- **Supavisor replaced PgBouncer** as the default pooler in 2024. Transaction mode (port `6543`) is required for serverless; prepared statements are off — ORMs need explicit config. See [Supavisor](/stacks/supabase/supavisor/).
- **PostgreSQL 17** is the default for new projects (since 2025). PG16 → PG17 path is in-place but requires extension compatibility checks. See [Postgres](/stacks/supabase/postgres/).
- **Wrap `auth.uid()` in a subquery** in RLS policies: `(select auth.uid()) = user_id`. ~100x speed-up on large tables. See [Row-Level Security](/stacks/supabase/row-level-security/).
- **Realtime got Authorization** (2024). Broadcast + Presence now respect RLS-style policies on `realtime.messages`. The "everyone on the channel sees everything" pattern is wrong for any production app. See [Supabase Realtime](/stacks/supabase/supabase-realtime/).
- **Database Branching** is GA. Every preview deploy on Vercel/Netlify can have its own database branch with seeded data. See [Branching](/stacks/supabase/branching/).
- **Declarative schemas** (`supabase/schemas/*.sql`) coexist with diff-based migrations. Pick one per project. See [Migrations](/stacks/supabase/migrations/).
- **Supabase Queues** (2025) and **Supabase Cron** (late 2024) are first-class managed surfaces wrapping `pgmq` and `pg_cron`. See [Supabase Queues](/stacks/supabase/supabase-queues/) and [Supabase Cron](/stacks/supabase/supabase-cron/).
- **Foreign Data Wrappers** (Wrappers framework) — Stripe, BigQuery, Clickhouse, Redis, Firebase, Auth0 are first-class FDWs. Excellent for read-side joins. See [Foreign Data Wrappers](/stacks/supabase/foreign-data-wrappers/).
- **Edge Functions now support background tasks** (`EdgeRuntime.waitUntil`), **ephemeral storage**, and stable `npm:` specifiers. JSR (`jsr:@supabase/supabase-js@2`) is the preferred specifier. See [Edge Functions](/stacks/supabase/edge-functions/).
- **Supabase MCP server** is real — agents can drive a project. Default `--read-only` matters; never connect with write scope to prod without human-in-the-loop guards. See [Supabase MCP](/stacks/supabase/supabase-mcp/).
- **pgvector + HNSW + halfvec is the default.** IVFFlat only at very large scale. `halfvec` cuts storage in half with negligible recall loss. See [pgvector](/stacks/supabase/pgvector/).
- **Custom Access Token Hook** lets you inject `org_id`, role, plan into the JWT at sign-in. Powers cheap multi-tenant RLS. See [Supabase Auth](/stacks/supabase/supabase-auth/).
- **JWKS / RS256** for JWT verification rolled out 2024-2025. New projects use it by default; verify externally via JWKS, never hard-code the JWT secret.

If you find yourself recommending `@supabase/auth-helpers-nextjs`, raw PgBouncer for new builds, `pg_cron` from the SQL editor, `IVFFlat` as a default vector index, or "just put `SET ROLE` in a function" for tenant isolation — you're using stale knowledge.

## Products covered

| Product | Drift risk | Why |
|---|---|---|
| [Postgres](/stacks/supabase/postgres/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Default major bumped to PG17 in 2025; extension defaults shift between releases |
| [Row-Level Security](/stacks/supabase/row-level-security/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable primitive; performance idioms (wrap `auth.uid()`, index policy columns) still evolving in docs |
| [Supabase Auth](/stacks/supabase/supabase-auth/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Auth Hooks, anonymous sign-ins, SSO/SCIM, third-party auth, MFA factors all expanded 2024-2026 |
| [Supabase Storage](/stacks/supabase/supabase-storage/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | TUS resumable uploads, image transforms, S3-compatible API GA; storage RLS on `storage.objects` |
| [Supabase Realtime](/stacks/supabase/supabase-realtime/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Realtime Authorization (2024) reshaped Broadcast/Presence; Postgres Changes vs Broadcast tradeoffs shifted |
| [Edge Functions](/stacks/supabase/edge-functions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Deno runtime updates, background tasks, ephemeral storage, `npm:` stabilized 2024-2025 |
| [Database Webhooks](/stacks/supabase/database-webhooks/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Async via `pg_net`; ordering + back-pressure semantics critical to understand |
| [Database Functions](/stacks/supabase/database-functions/) | <span class="etyb-drift-badge" data-risk="low">low</span> | plpgsql / SQL; stable; `SECURITY DEFINER` + `search_path` discipline is the only moving piece |
| [pg_graphql](/stacks/supabase/pg-graphql/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Auto-generated GraphQL; works but rarely the right primary API |
| [pg_cron](/stacks/supabase/pg-cron/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; scheduled SQL; now wrapped by Supabase Cron UI |
| [pg_net](/stacks/supabase/pg-net/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Async HTTP from Postgres; powers Database Webhooks; queue backlog matters |
| [pgvector](/stacks/supabase/pgvector/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | HNSW since 0.5; halfvec / sparsevec added; index choice matters at scale |
| [pg_trgm](/stacks/supabase/pg-trgm/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Trigram fuzzy match + ILIKE acceleration; stable |
| [Supabase Vault](/stacks/supabase/supabase-vector/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | pgsodium-backed encrypted secrets in Postgres; rotation semantics still maturing |
| [Supavisor](/stacks/supabase/supavisor/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replaced PgBouncer as default pooler in 2024; transaction vs session mode determines what works |
| [Supabase CLI](/stacks/supabase/supabase-cli/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Active surface; `db push` vs declarative schemas is the current axis of change |
| [supabase-js](/stacks/supabase/supabase-js/) | <span class="etyb-drift-badge" data-risk="high">high</span> | v2 stable; v3 stabilizing in 2026; auth client splits + improved type inference |
| [@supabase/ssr](/stacks/supabase/supabase-ssr/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replaces deprecated `@supabase/auth-helpers-*`; cookie handling is the #1 SSR auth bug |
| [Migrations](/stacks/supabase/migrations/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Declarative (`schemas/`) vs diff-based (`migrations/`); mixing is the top cause of broken `db push` |
| [Branching](/stacks/supabase/branching/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA in 2024; Vercel/Netlify preview integration; branch → main promotion semantics maturing |
| [Studio](/stacks/supabase/studio/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Local + hosted UIs; AI assistant + SQL editor heavily updated 2025-2026 |
| [Supabase Queues](/stacks/supabase/supabase-queues/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Launched 2025; managed pgmq with DLQ + visibility timeout semantics |
| [Supabase Cron](/stacks/supabase/supabase-cron/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Launched late 2024; pg_cron wrapped in UI + auth-bound auditability |
| [Supabase MCP](/stacks/supabase/supabase-mcp/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Lets agents drive a project; permissions, read-only flag, scope-per-token still tightening |
| [Foreign Data Wrappers](/stacks/supabase/foreign-data-wrappers/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Wrappers framework: Stripe/BigQuery/Clickhouse/Redis/Auth0/Firebase; read-side joins, not write throughput |

## Role overlays

Composed views under `/stacks/supabase/<role>/`. Each stitches together the products that role's work touches.

- [`backend-architect`](/stacks/supabase/backend-architect/) — Edge Functions, server-side supabase-js, Database Functions, Realtime publishers, Queues, Cron, pooler decisions
- [`database-architect`](/stacks/supabase/database-architect/) — schema, RLS performance, migrations, branching, extensions, indexes, FDWs, query observability
- [`frontend-architect`](/stacks/supabase/frontend-architect/) — `@supabase/ssr` cookie wiring, supabase-js query patterns, Realtime client wiring, generated types
- [`security-engineer`](/stacks/supabase/security-engineer/) — RLS as the security primitive, Auth hardening, Vault, network controls, audit, Storage RLS, JWT verification
- [`ai-ml-engineer`](/stacks/supabase/ai-ml-engineer/) — pgvector + HNSW + halfvec, hybrid search, RAG via Edge Functions, agent memory, eval discipline
- [`saas-architect`](/stacks/supabase/saas-architect/) — tenancy models on RLS, JWT shape via Custom Access Token Hook, Stripe FDW + webhooks, SSO/SCIM, tenant lifecycle

## Authoritative sources

For verified-current behavior, see the official Supabase surfaces:

- **[Supabase Docs](https://supabase.com/docs)** — canonical reference
- **[Changelog](https://supabase.com/changelog)** — release history; check for drift between `last_verified_on` and today
- **[supabase-js Reference](https://supabase.com/docs/reference/javascript)** — client SDK
- **[`@supabase/ssr` Guide](https://supabase.com/docs/guides/auth/server-side)** — cookie-based SSR auth
- **[Edge Functions Docs](https://supabase.com/docs/guides/functions)** — Deno runtime + deployment
- **[CLI Reference](https://supabase.com/docs/reference/cli)** — `supabase` CLI commands
- **[RLS Performance Guide](https://supabase.com/docs/guides/database/postgres/row-level-security#performance)** — the `(select auth.uid())` rule
- **[Supavisor Source](https://github.com/supabase/supavisor)** — pooler reference
- **[Supabase Status](https://status.supabase.com)** — incident history
- **[Supabase MCP Server](https://github.com/supabase-community/supabase-mcp)** — agent access surface

## Delegate skills

If the user's environment has the `supabase:supabase` skill or `supabase:supabase-postgres-best-practices` skill installed, **prefer those over this site** for matching products. The first-party Supabase MCP/skill surface knows current product state better than any curated layer; this site is the opinionated fallback when first-party tooling isn't available.

ETYB does this detection automatically by inspecting the available-skills list. Third-party agents should do the same — see [how to read these docs](/conventions/agent-protocol/).
