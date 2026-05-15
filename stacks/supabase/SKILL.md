---
name: stack-supabase
description: >
  Supabase platform knowledge overlay for the ETYB team. Loads when work involves the Supabase
  ecosystem — Postgres (Supabase-hosted), Row-Level Security (RLS), Supabase Auth, Storage,
  Realtime, Edge Functions, Database Webhooks, Database Functions, Supavisor pooler, pgvector,
  pg_cron, pg_net, pg_graphql, pg_jsonschema, pgaudit, pgsodium, pgmq, Supabase Vault, Supabase
  Queues, Supabase Cron, Branching, Studio, supabase-js, @supabase/ssr, Supabase CLI, Supabase
  MCP server, Foreign Data Wrappers. This is NOT a new team member; it is a context overlay
  that teaches each existing ETYB role what it needs to know to ship production-grade Supabase
  work as of 2026-Q2.
  Triggers: supabase, supabase auth, supabase storage, supabase realtime, supabase edge
  functions, supabase functions, edge function, deno deploy, supabase-js, @supabase/ssr,
  @supabase/supabase-js, supabase ssr, ssr cookies, server components supabase, supabase cli,
  supabase login, supabase start, supabase db push, supabase db pull, supabase db reset,
  supabase db diff, supabase gen types, supabase migration, supabase functions deploy,
  supabase functions serve, supabase link, supabase init, supabase secrets, supabase branching,
  database branch, preview branch, supabase preview, supabase studio, supabase dashboard,
  postgres, postgresql, pg, rls, row level security, row-level security, policy, auth.uid,
  auth.jwt, auth.role, pgvector, hnsw, ivfflat, embedding, vector index, vector similarity,
  pg_graphql, pg_cron, pg_net, pg_jsonschema, pg_trgm, pgaudit, pgsodium, pgmq, pg_tle,
  pg_stat_statements, pgvectorscale, postgres extension, supavisor, pgbouncer, transaction
  pooler, session pooler, connection pooler, prepared statement, SET LOCAL, pgbouncer mode,
  serverless postgres, vault, supabase vault, supabase secrets vault, supabase queue, queues,
  pgmq, supabase cron, cron job, scheduled job, foreign data wrapper, fdw, wrappers, stripe
  fdw, clickhouse fdw, bigquery fdw, redis fdw, magic link, otp, passwordless, social login,
  third-party auth, oauth provider, supabase sso, supabase mfa, totp, webauthn, passkey
  supabase, anonymous sign in, captcha hook, auth hook, send email hook, custom access token,
  custom claims jwt, supabase storage, storage bucket, signed url, resumable upload, tus,
  storage policy, image transformation, presence, broadcast, postgres changes, realtime
  channel, realtime listen, supabase realtime authorization, supabase rls realtime, broadcast
  authorization, presence sync, presence join, supabase mcp, supabase mcp server, supabase
  agent, claude code supabase, foreign key, security definer, search_path, declarative schema,
  declarative migrations, supabase types, type generation, codegen supabase, plv8, plpgsql,
  trigger function, generated column, generated always as, identity column, materialized view,
  pgcrypto, uuid_generate_v4, uuid v7, btree_gin, btree_gist, fuzzymatchsearch.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - backend-architect
    - database-architect
    - frontend-architect
    - security-engineer
    - ai-ml-engineer
    - saas-architect
authoritative_sources:
  primary:
    - { name: "Supabase Docs",                  url: "https://supabase.com/docs",                              type: official_docs }
    - { name: "Supabase CLI Reference",         url: "https://supabase.com/docs/reference/cli",                type: cli_reference }
    - { name: "supabase-js Reference",          url: "https://supabase.com/docs/reference/javascript",         type: api_reference }
    - { name: "Supabase Changelog",             url: "https://supabase.com/changelog",                         type: changelog }
    - { name: "Supabase Blog",                  url: "https://supabase.com/blog",                              type: official_docs }
    - { name: "Supabase GitHub Org",            url: "https://github.com/supabase",                            type: source_code }
    - { name: "Supabase Status",                url: "https://status.supabase.com",                            type: status_page }
    - { name: "Supavisor (pooler) source",      url: "https://github.com/supabase/supavisor",                  type: source_code }
    - { name: "@supabase/ssr",                  url: "https://supabase.com/docs/guides/auth/server-side",      type: api_reference }
    - { name: "Supabase Edge Functions",        url: "https://supabase.com/docs/guides/functions",             type: official_docs }
    - { name: "Supabase RLS Performance",       url: "https://supabase.com/docs/guides/database/postgres/row-level-security#performance", type: official_docs }
    - { name: "Supabase MCP Server",            url: "https://github.com/supabase-community/supabase-mcp",     type: source_code }
delegate_to_skills:
  - { skill: "supabase:supabase",                          covers: [Database, Auth, Edge Functions, Realtime, Storage, Vectors, Cron, Queues, supabase-js, "@supabase/ssr", CLI, migrations, security audits, RLS] }
  - { skill: "supabase:supabase-postgres-best-practices",  covers: [Postgres query optimization, schema design, RLS performance, indexing] }
products_covered:
  - { name: "Postgres (Supabase-hosted)",   drift_risk: medium, notes: "Stable core; Supabase regularly bumps default major (PG16 → PG17 path through 2025-2026); extension defaults shift" }
  - { name: "Row-Level Security (RLS)",     drift_risk: medium, notes: "Stable primitive but performance idioms (wrap auth.uid in SELECT, index policy columns) keep evolving in docs" }
  - { name: "Supabase Auth",                drift_risk: high,   notes: "Auth Hooks, anonymous sign-ins, SSO/SCIM, third-party auth (Clerk/Firebase/Cognito), MFA factors expanded 2024-2026" }
  - { name: "Supabase Storage",             drift_risk: medium, notes: "Resumable uploads (TUS), image transformations, S3-compatible API GA; storage RLS lives in storage.objects" }
  - { name: "Supabase Realtime",            drift_risk: high,   notes: "Realtime Authorization for Broadcast + Presence (2024) replaces older listen-everything model; Postgres Changes vs Broadcast tradeoffs shifted" }
  - { name: "Edge Functions (Deno)",        drift_risk: high,   notes: "Deno runtime updates, regional invocation, background tasks + ephemeral storage, npm: imports stabilized 2024-2025" }
  - { name: "Supavisor",                    drift_risk: high,   notes: "Replaced PgBouncer as default pooler in 2024; transaction mode required for serverless, session mode for prepared statements + migrations" }
  - { name: "Database Branching",           drift_risk: high,   notes: "GA in 2024; Vercel/Netlify preview integration; semantics for production-branch promotion still maturing" }
  - { name: "Declarative migrations",       drift_risk: high,   notes: "Declarative schema (supabase/schemas/*.sql) added 2024; coexists with diff-based migrations; choose one and stick" }
  - { name: "pgvector",                     drift_risk: medium, notes: "HNSW since 0.5.0 (mainstream by 2024); halfvec / sparsevec types added; index choice matters at scale" }
  - { name: "pg_cron",                      drift_risk: low,    notes: "Stable; scheduled SQL; Supabase Cron is a UI wrapper" }
  - { name: "pg_net",                       drift_risk: medium, notes: "Async HTTP from Postgres; used by Database Webhooks; watch queue backlog" }
  - { name: "pg_graphql",                   drift_risk: medium, notes: "Auto-generated GraphQL from schema; works but rarely the right primary API choice" }
  - { name: "pg_jsonschema",                drift_risk: low,    notes: "JSON Schema validation in CHECK constraints" }
  - { name: "pgmq",                         drift_risk: medium, notes: "Lightweight queues; Supabase Queues is the managed surface" }
  - { name: "Supabase Queues",              drift_risk: high,   notes: "Launched 2025; managed pgmq with UI + visibility timeout + DLQ semantics" }
  - { name: "Supabase Cron",                drift_risk: medium, notes: "Launched late 2024; pg_cron wrapped in UI + auth-bound auditability" }
  - { name: "Supabase Vault",               drift_risk: medium, notes: "pgsodium-backed encrypted secrets in Postgres; rotation semantics + key management still maturing" }
  - { name: "Foreign Data Wrappers (Wrappers)", drift_risk: medium, notes: "Stripe/Clickhouse/BigQuery/Redis/Auth0/Firebase wrappers; useful for read-side joins, not write-throughput" }
  - { name: "Supabase CLI",                 drift_risk: high,   notes: "Active surface; commands gain/lose flags often; `supabase db push` workflow vs declarative schemas is the current axis of change" }
  - { name: "supabase-js",                  drift_risk: high,   notes: "v2 stable; v3 stabilizing 2026; auth client splits + improved type inference; query builder shape stable" }
  - { name: "@supabase/ssr",                drift_risk: high,   notes: "Replaces deprecated @supabase/auth-helpers-nextjs / sveltekit / remix; cookie handling is the #1 source of broken auth flows" }
  - { name: "Supabase Studio",              drift_risk: medium, notes: "Local-only and hosted UIs; AI assistant + SQL editor heavily updated 2025-2026" }
  - { name: "Supabase MCP Server",          drift_risk: high,   notes: "Lets agents drive a Supabase project; permissions, read-only flag, and scope-per-token still tightening" }
---

# Supabase Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Supabase knowledge lives.

## Where the full briefing lives

Per-product and per-role pages are maintained at **[docs.etyb.ai/stacks/supabase](https://docs.etyb.ai/stacks/supabase/)** with `last_verified_on` stamps and authoritative-source URLs. ETYB fetches from those URLs at runtime — see `skills/etyb/core/knowledge-currency.md` for the fetch contract.

- **Stack index:** <https://docs.etyb.ai/stacks/supabase/>
- **Per-product pages:** `https://docs.etyb.ai/stacks/supabase/<product>/`
- **Per-role views:** `https://docs.etyb.ai/stacks/supabase/<role>/` — composed views for each role in `applies_to_roles` above

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first; docs.etyb.ai is the curated fallback.

## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **`@supabase/auth-helpers-*` is dead.** Use **`@supabase/ssr`** for every Next.js / SvelteKit / Remix / Astro app. Cookie-based session handling lives here. The old helpers libraries are deprecated and *will* steer you into broken middleware/cookie bugs. Use `createBrowserClient` + `createServerClient` from `@supabase/ssr`.
- **Supavisor replaced PgBouncer** as the default connection pooler in 2024. Two modes: **Transaction mode** (port `6543` — required for serverless / Edge Functions / Lambda; prepared statements disabled by default) and **Session mode** (required for migrations, `LISTEN/NOTIFY`, advisory locks, prepared statements). Get this wrong and the first prepared-statement-dependent query throws in production.
- **RLS policies pay a per-row cost if you call `auth.uid()` directly.** Wrap in a subselect to let the planner cache: `(select auth.uid()) = user_id`. This is documented but routinely missed.
- **Realtime got Authorization.** Broadcast + Presence channels now respect RLS-style policies on `realtime.messages` and `realtime.broadcasts`. The old pattern of "anyone on the channel sees everything" is wrong for any production app touching customer data.
- **Database Branches are GA.** Every preview deploy on Vercel/Netlify can have its own database branch with seeded data. Branches inherit from `main` migrations + can carry their own; PR merges promote branch → main with a managed migration.
- **Declarative schemas** (`supabase/schemas/*.sql`) live alongside the older diff-based migrations (`supabase/migrations/*.sql`). Choose **one** workflow per project. Mixing them is the most common cause of broken `supabase db push`.
- **Supabase Queues** (2025) and **Supabase Cron** (late 2024) are now first-class managed surfaces. Stop using `pg_cron` directly through SQL Editor for new work.
- **Foreign Data Wrappers** got the **Wrappers** framework — Stripe, BigQuery, Clickhouse, Redis, Firebase, Auth0 are first-class FDWs. Excellent for read-side joins; don't use them as a write-throughput path.
- **Edge Functions now support background tasks** (waitUntil-style) and **ephemeral storage** for the duration of an invocation. `npm:` specifiers are stable. Deno KV is not exposed; use Postgres or the storage bucket instead.
- **Supabase MCP server** is real — agent surfaces (Claude Code, Codex, Antigravity) can drive a Supabase project. The default `--read-only` flag matters; never connect an agent with write scope to a production project without explicit human-in-the-loop guards.
- **pgvector + HNSW is the default vector index.** `ivfflat` is still useful for very large corpora that need cheaper builds. `halfvec` (16-bit floats) cuts storage cost in half with negligible recall loss.
- **PostgreSQL 17** is the default for new projects (as of 2025). PG16 → PG17 upgrade path is in-place but requires extension compatibility checks (especially `pg_graphql`, `pg_cron`, `wrappers`).

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Fetch the current page from docs.etyb.ai before continuing.

## Standing instructions for every role on a Supabase engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, fetch the relevant docs.etyb.ai page and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Default to RLS-on-everything.** Every table in the `public` schema must have RLS enabled. Service role is a break-glass key, not an architecture. If the answer involves the service role, ask first whether RLS could be modeled to give the user-role what it needs.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Supabase | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Supabase alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
