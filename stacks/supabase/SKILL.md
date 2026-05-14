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

# Supabase Stack Pack — Team Briefing

You're working on Supabase. This is a **knowledge overlay**, not a new specialist. backend-architect writes the Edge Functions and the server-side data access; database-architect designs the Postgres schema + RLS; frontend-architect wires `@supabase/ssr` + `supabase-js`; security-engineer owns RLS as the security primitive plus auth hardening; ai-ml-engineer owns pgvector + Edge Functions for AI; saas-architect designs multi-tenancy on top of RLS. This pack tells each of them what 2026 Supabase actually looks like.

**Currency stamp:** verified against Supabase docs, changelog, and `supabase-js` reference as of **2026-05-14**. If today's date is more than ~6 months past `last_verified_on` above, the pack is stale — warn the user, check `https://supabase.com/changelog`, and verify Edge Functions runtime + CLI command shapes before recommending specifics.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff will get these wrong. Read carefully:

- **`@supabase/auth-helpers-*` is dead.** Use **`@supabase/ssr`** for every Next.js / SvelteKit / Remix / Astro app. Cookie-based session handling lives here. The old helpers libraries (`@supabase/auth-helpers-nextjs`, `@supabase/auth-helpers-sveltekit`, etc.) are deprecated and *will* steer you into broken middleware/cookie bugs. Use `createBrowserClient` + `createServerClient` from `@supabase/ssr`.
- **Supavisor replaced PgBouncer** as the default connection pooler in 2024. Two modes matter and they are not interchangeable:
  - **Transaction mode** (port `6543` on the pooled URL) — required for serverless / Edge Functions / Lambda / any short-lived connection. **Prepared statements are disabled** in this mode by default; many ORMs (Prisma, Drizzle in some configs) need explicit "no prepared statements" config or they'll silently throw at runtime.
  - **Session mode** (port `5432` via pooler hostname OR the direct connection) — required for migrations, `LISTEN/NOTIFY`, advisory locks, prepared statements, `SET` (non-LOCAL). Use session mode in the `supabase/migrations` CLI flow.
- **RLS policies pay a per-row cost if you call `auth.uid()` directly.** Wrap in a subselect to let the planner cache: `(select auth.uid()) = user_id`. This is documented but routinely missed. We cover it in `security-engineer.md` and `database-architect.md`.
- **Realtime got Authorization.** Broadcast + Presence channels now respect RLS-style policies on `realtime.messages` and `realtime.broadcasts`. The old pattern of "anyone on the channel sees everything" is wrong for any production app touching customer data. Postgres Changes still works but you should default-to-Broadcast for app-level events and Postgres-Changes for true DB CDC.
- **Database Branches** are GA. Every preview deploy on Vercel/Netlify can have its own database branch with seeded data. The new shape changes the migration story: branches inherit from `main` migrations + can carry their own; PR merges promote branch → main with a managed migration.
- **Declarative schemas** (`supabase/schemas/*.sql`) live alongside the older diff-based migrations (`supabase/migrations/*.sql`). Choose **one** workflow per project. Mixing them is the most common cause of broken `supabase db push`.
- **Supabase Queues** (2025) and **Supabase Cron** (late 2024) are now first-class managed surfaces. Stop using `pg_cron` directly through SQL Editor for new work — use the UI/CLI surface; it gives you auth-bound auditability + run history.
- **Foreign Data Wrappers** got the **Wrappers** framework — Stripe, BigQuery, Clickhouse, Redis, Firebase, Auth0 are first-class FDWs. Excellent for *read-side* joins (e.g., enrich Postgres rows with Stripe data without a sync pipeline). Don't use them as a write-throughput path.
- **Edge Functions now support background tasks** (waitUntil-style) and **ephemeral storage** for the duration of an invocation. `npm:` specifiers are stable. Deno KV is not exposed; use Postgres or the storage bucket instead.
- **Supabase MCP server** is real — agent surfaces (Claude Code, Codex, Antigravity) can drive a Supabase project: list tables, run SQL, deploy migrations, deploy functions. The default `--read-only` flag matters; never connect an agent with write scope to a production project without explicit human-in-the-loop guards.
- **pgvector + HNSW is the default vector index.** `ivfflat` is still useful for very large corpora that need cheaper builds, but HNSW is the right default. `halfvec` (16-bit floats) cuts storage cost in half with negligible recall loss for most embeddings.
- **`auth-js` evolved**: anonymous sign-ins, `signInAnonymously()`, MFA enrollment APIs, custom access token claims via the **Custom Access Token Hook**, plus third-party auth (use Clerk/Auth0/Firebase as the IdP and Supabase still issues RLS-aware tokens).
- **`pg_net` powers Database Webhooks**; the queue is async and back-pressures under load. Don't treat webhooks as transactional — they're best-effort and ordered only within a single row.
- **PostgreSQL 17** is the default for new projects (as of 2025). PG16 → PG17 upgrade path is in-place but requires extension compatibility checks (especially `pg_graphql`, `pg_cron`, `wrappers`).

If you find yourself recommending `@supabase/auth-helpers-nextjs`, raw PgBouncer for new builds, `pg_cron` from the SQL editor, or "just put `SET ROLE` in a function" for tenant isolation — you're using stale knowledge. Read the references.

## How this pack plugs in

ETYB's router detects Supabase signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The Supabase overlay shapes how each protocol is applied here — for example, TDD on RLS = write a `pgTAP`-style policy assertion against a test schema with seeded users; TDD on Edge Functions = `deno test` against a local Supabase instance started by `supabase start`.

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | Edge Functions (Deno) idioms, **server-side `supabase-js` patterns**, service-role vs user-role calls, Database Functions (plpgsql / plv8) vs Edge Functions decision, Database Webhooks + `pg_net`, Queues, Cron, async patterns, connection pooling and ORM compatibility |
| `database-architect` | [`references/database-architect.md`](references/database-architect.md) | Schema design on Supabase, RLS as a data layer concern (performance, indexing, helper functions, multi-tenancy modeling), migrations strategy (declarative vs diff), branching, extensions ecosystem, query performance, `pg_stat_statements`, FDWs, pgvector index choices |
| `frontend-architect` | [`references/frontend-architect.md`](references/frontend-architect.md) | `@supabase/ssr` cookie patterns for Next.js / SvelteKit / Remix / Astro, server components vs route handlers vs middleware, `supabase-js` v2/v3 query builder, real-time client wiring, optimistic UI, generated TypeScript types, Realtime Authorization on the client |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | **RLS is the security primitive** — policy design, performance, the `(select auth.uid())` rule, security-definer functions, search_path safety, role separation (anon / authenticated / service_role), Auth hardening (MFA, captcha, rate limiting, password policy, leaked-password protection), JWT / Access Token Hook, Vault, network restrictions, IP allow-list, audit (pgaudit), Storage RLS |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | pgvector + HNSW/IVFFlat tradeoffs, halfvec / sparsevec, hybrid search (pgvector + pg_trgm + tsvector), embeddings pipelines via Edge Functions, RAG patterns native to Postgres, AI integrations through Edge Functions, vector schema patterns, cost/recall tuning |
| `saas-architect` | [`references/saas-architect.md`](references/saas-architect.md) | Multi-tenancy on Supabase — shared schema + RLS vs schema-per-tenant vs project-per-tenant, billing integration via Stripe FDW, tenant onboarding via Auth + JWT custom claims, signup gates, per-tenant Edge Functions, branching for tenant data migrations, scaling shape |

## Platform surface map — the products at a glance

Use this as the mental model for "what part of Supabase am I touching?" Each row maps a product to the role that owns it on this stack and the depth of coverage.

| Product | Owner role | Depth | Notes |
|---------|-----------|-------|-------|
| **Postgres** | database-architect | Deep | The substrate. Everything else is a layer on top. |
| **RLS** | security-engineer + database-architect | Deep | The authorization plane. Performance is a database-architect concern; policy correctness is security. |
| **Supabase Auth (GoTrue)** | security-engineer | Deep | MFA, JWT shape, hooks, SSO, anonymous, third-party auth. |
| **Storage** | backend-architect (writes) + security-engineer (RLS) | Medium | Buckets are config; objects are RLS-gated rows. |
| **Realtime** | frontend-architect (client) + backend-architect (broadcast publishers) | Medium | Three primitives: postgres-changes, broadcast, presence. |
| **Edge Functions** | backend-architect | Deep | Deno runtime; orchestration layer; webhook handlers; AI calls. |
| **Database Functions** | backend-architect + database-architect | Medium | When the work is set-based SQL or a trigger. |
| **Database Webhooks** | backend-architect | Medium | Async, best-effort. Layer on top of `pg_net`. |
| **Queues** | backend-architect | Medium | Managed pgmq. Worker = Edge Function on Cron. |
| **Cron** | backend-architect + database-architect | Light | Wrapped pg_cron. UI-bound auditability. |
| **Vault** | security-engineer | Medium | pgsodium-backed. Secrets that live inside Postgres. |
| **Foreign Data Wrappers** | database-architect | Light | Read-side joins to SaaS sources. Not for write throughput. |
| **pgvector** | ai-ml-engineer | Deep | Vector storage. HNSW + halfvec is the default. |
| **pg_graphql** | backend-architect | Light | Auto-generated GraphQL. Niche choice. |
| **Connection Pooler (Supavisor)** | backend-architect + database-architect | Deep | Transaction mode vs session mode determines what works. |
| **Branching** | devops (informal — split TBD) + database-architect | Medium | Database per preview deploy. |
| **Studio** | All roles | Light | UI; useful for SQL Editor + Reports + Advisor. |
| **CLI (`supabase`)** | All roles | Medium | The unified surface for local dev, migrations, deploys. |
| **MCP Server** | All roles | Light | Lets agents drive a project. Default read-only. |
| **supabase-js** | frontend-architect + backend-architect | Deep | Client + server SDK. |
| **@supabase/ssr** | frontend-architect | Deep | The auth cookie adapter. Critical for SSR. |

## Top 10 Supabase gotchas the team must know

Opinionated, named, with consequences. Internalize these.

1. **Transaction pooler + prepared statements = silent runtime errors.** On port `6543` (Supavisor transaction mode), prepared statements are turned off by default. Prisma needs `?pgbouncer=true&connection_limit=1` in the URL. Drizzle needs `prepare: false` in the postgres-js config. Get this wrong and the first prepared-statement-dependent query throws in production. Cause: Supavisor multiplexes one client connection across many backend connections per-transaction; a prepared statement plan from connection A is not valid for connection B.

2. **RLS without indexed policy columns is O(n) per query.** A policy like `using (org_id = (select org_id from memberships where user_id = (select auth.uid())))` looks fine — but if `memberships.user_id` isn't indexed and `<your table>.org_id` isn't indexed, every query scans the table. RLS policies must drive *index choice* the same way joins do.

3. **`auth.uid()` called directly in RLS policies is re-executed per row.** Always wrap: `(select auth.uid())`. This is THE single highest-ROI optimization for Supabase RLS performance. The planner caches the result of the scalar subquery and re-uses it.

4. **`SECURITY DEFINER` functions without `SET search_path` are a privilege escalation path.** Every `SECURITY DEFINER` function must `SET search_path = ''` and reference every object with a schema-qualified name (`public.users`, not `users`). Without it, an attacker can create a `public.users` view in their own schema and the function runs against that.

5. **Storage policies live in `storage.objects` (and `storage.buckets`)**, not in your tenant tables. Forgetting this leaves uploaded files world-readable while the rest of the app is locked down. Use the same RLS patterns on `storage.objects` and audit them with the same rigor.

6. **Realtime Postgres Changes is not free.** Every replicated row goes through the Realtime worker; busy tables (audit logs, telemetry) will saturate Realtime quickly. Default to **Broadcast** for app events (publish from a trigger or Edge Function), reserve **Postgres Changes** for true CDC where you genuinely need every row.

7. **Edge Functions cold starts are real and Deno-flavored.** Module loading dominates cold start; large `npm:` deps blow up first invocation latency. Keep functions small, prefer ESM-native libs, pin versions, use the bundler's tree-shaking, and consider warm-keep strategies (cron-pinged endpoint) for latency-critical paths.

8. **Service-role keys must never reach the browser.** This is obvious, and yet — every Supabase incident postmortem has one. The `service_role` JWT bypasses RLS. It belongs in Edge Functions, server-side Next.js route handlers, and your CI/CD secrets — never in `NEXT_PUBLIC_*`, never in a client bundle, never in a mobile app.

9. **Declarative schemas + diff migrations are not friends.** Pick one. If you adopt declarative (`supabase/schemas/*.sql`), all schema changes go through `supabase db diff -f <name>` or via stop-the-world re-diff. If you adopt diff migrations, never hand-edit `supabase/migrations/*.sql` — generate them with `db diff`. Mixing modes is the #1 cause of broken `supabase db push`.

10. **Database Branches are not "production preview" by default.** Each branch is its own logical database; data does not flow back to production. Seed scripts (`supabase/seed.sql`) determine the dev experience. Treat preview branches as throwaway test environments — never test data-migration scripts against `main` from a branch.

## Migrating from older Supabase patterns

If you're reading code that was written before mid-2024, you'll likely encounter these patterns. Each is a flag for "needs an update before we extend it":

| Old pattern | What it is | Replacement |
|-------------|------------|-------------|
| `@supabase/auth-helpers-nextjs` (or sveltekit / remix / shared) | The pre-`@supabase/ssr` auth library | `@supabase/ssr` with the cookie adapter pattern (see [frontend-architect overlay](references/frontend-architect.md)) |
| `createMiddlewareClient`, `createServerComponentClient`, `createRouteHandlerClient` | Helpers from `auth-helpers-nextjs` | `createServerClient` from `@supabase/ssr` with explicit cookie wiring |
| `auth.uid()` directly in policies | Pre-2023 RLS pattern | `(select auth.uid())` — wrap in scalar subquery |
| `WITH SECURITY_ENFORCED` (the SOQL-style hint) | Doesn't exist in Postgres — confusion from Salesforce migrants | Use RLS with `(select auth.role()) = 'authenticated'` |
| Raw PgBouncer URL (port `6432`) | Pre-Supavisor pooler URL | Supavisor URLs (`6543` transaction, pooler hostname for session) |
| `pg_cron` configured via SQL Editor | Worked, but no UI audit trail | Supabase Cron — same underlying tech, dashboard-bound |
| `pg_net` direct usage from a trigger | Sync HTTP from trigger; serializes the transaction | Database Webhooks (async via `pg_net`) or Queues + worker |
| `db push` of un-tested migrations to prod | Pre-Branching workflow | Branches → preview → merge → migration applies to main |
| Realtime "subscribe to a table, see all rows" | Pre-Realtime Authorization | Realtime Authorization policies on `realtime.messages` |
| `vector(...)` everywhere with no halfvec | Pre-pgvector 0.7 pattern | `halfvec(...)` for most embedding workflows |
| `IVFFlat` as the default index | Pre-pgvector 0.5 pattern | HNSW as default; IVFFlat only at huge scale |
| Service role used in a browser-side data path | Always wrong; sometimes seen in older "MVP" code | Anon key + RLS, or move the call server-side |
| `auth.users` directly extended with custom columns | Forbidden — `auth.users` is managed | `public.profiles` table FK-linked to `auth.users` |

When you find one of these in code, the migration is part of the work, not a separate ticket. Don't extend a broken pattern.

## Operational checklist — when a Supabase engagement starts

Use this as the day-one runbook on any new Supabase project ETYB takes on:

### Day 1 — discovery

- [ ] Confirm the Supabase tier (Free / Pro / Team / Enterprise). Some features require Pro+ (PITR, IP allow-list, branching, read replicas, SSO).
- [ ] Identify all environments (production, staging, dev). Each is typically a separate project.
- [ ] List all integrated services (Vercel, Stripe, Resend/Postmark, Slack, GitHub, etc.).
- [ ] Verify Auth provider config (which providers are enabled; SMTP configured for production).
- [ ] Run `supabase db lint` against the linked project to see lint findings.
- [ ] Check Database Advisor (Studio → Database → Advisor). Note any RLS-disabled tables, missing indexes, security definer view issues.
- [ ] Verify `pg_stat_statements` is on (it should be — but verify).
- [ ] Inventory enabled extensions.

### Day 2-3 — assessment

- [ ] Sample 5 tables; verify each has RLS enabled and at least one tested policy.
- [ ] Sample 5 `SECURITY DEFINER` functions; verify each has `SET search_path = ''`.
- [ ] Sample 5 RLS policies; verify each wraps `auth.uid()` in `(select ...)`.
- [ ] Verify the cookie adapter is in place if SSR is used (`@supabase/ssr` and not `@supabase/auth-helpers-*`).
- [ ] Verify Edge Functions are using `jsr:` imports and have pinned versions for npm deps.
- [ ] Verify migration story: declarative or diff-based, but consistent.
- [ ] Verify CI runs `supabase db reset` (or equivalent) on every PR — catches broken migrations early.

### Production-readiness

Before any project sees real customer load:

- [ ] PITR is enabled on Pro+ projects.
- [ ] Custom SMTP is configured for production Auth emails.
- [ ] MFA is offered (and enforced for admins).
- [ ] Service role key is rotated post-MVP and stored in secrets management.
- [ ] CAPTCHA is enabled on sign-up / sign-in.
- [ ] Rate limits on Edge Functions exist (either app-level or via your CDN).
- [ ] Logs Explorer is being shipped to a SIEM if compliance demands it.
- [ ] Backups have been test-restored at least once.
- [ ] Realtime Authorization is configured if Broadcast/Presence are used.

This is not exhaustive but it's the floor.

## Compliance composition

Supabase is HIPAA-available (BAA on Enterprise/Team — confirm tier with the vendor) and SOC 2 Type II. The Stack covers *platform* knobs (Vault, audit, network restrictions, Storage encryption, pgaudit). For domain compliance:

| Domain | Defer to |
|--------|----------|
| HIPAA semantics, PHI minimization, audit discipline | `healthcare-architect` (not in this pack's `applies_to_roles`) |
| PCI scope, ledger discipline | `fintech-architect` (not in this pack's `applies_to_roles`) |
| GDPR data residency (Supabase EU regions exist) | `security-engineer` + the relevant vertical |
| SOC 2 controls mapping | `security-engineer` |

If the user's work intersects a vertical that this pack doesn't cover, ETYB's router will pull the vertical reference *separately* and compose both. The Supabase pack speaks platform; the vertical speaks domain.

## Stack composition

If the user is on Supabase **plus** another stack:

| Combo | How it composes |
|-------|-----------------|
| Supabase + **Vercel** | Vercel pack covers Next.js + edge runtime + preview deploys; Supabase pack covers `@supabase/ssr` cookie patterns, Branching integration, Edge Functions vs Vercel Functions decision |
| Supabase + **Cloudflare** | Cloudflare pack covers Workers/D1/Durable Objects; Supabase pack covers what stays in Postgres + how to call Supabase from Workers (Hyperdrive in front of Supabase is a recurring pattern) |
| Supabase + **Stripe** | Stripe pack covers billing semantics; Supabase pack covers Stripe FDW for read-side joins + webhook handling in Edge Functions |
| Supabase + **Anthropic Claude / OpenAI** | LLM pack covers model APIs; Supabase pack covers pgvector indexing, Edge Functions as orchestration, MCP server |
| Supabase + **Expo** | Expo pack covers RN client patterns; Supabase pack covers `supabase-js` on RN, deep-link auth, Realtime over web socket on mobile |

Neither pack pretends to know the other's depth.

## Standing instructions for every role on a Supabase engagement

1. **Anchor to currency.** Before claiming a CLI flag, `supabase-js` method signature, or RLS syntax, check whether the role overlay covers it. If yes, follow the overlay. If no, say so and verify against the changelog or docs URL — both linked in `authoritative_sources.primary`.
2. **Default to RLS-on-everything.** Every table in `public` schema must have RLS enabled. The only exceptions are reference data that's intentionally world-readable. If RLS is disabled on a table, the linter `supabase db lint` will flag it; ship CI with the lint enabled.
3. **Service role is a break-glass key, not an architecture.** If the answer involves the service role, ask first whether RLS could be modeled to give the user-role what it needs. Only escalate to service role when the operation is genuinely admin-scoped.
4. **Use the SQL planner.** Every RLS or query change touching a table > 10k rows should be exercised under `EXPLAIN (ANALYZE, BUFFERS)`. The Supabase Studio SQL editor has a one-click button for this; in CI, `pg_stat_statements` is your historical view.
5. **Cookie handling is fragile.** Whenever an SSR auth flow breaks, the root cause is 80% of the time the `@supabase/ssr` cookie adapter not being wired to read AND write across the middleware → server → client boundary. The `frontend-architect.md` overlay has the canonical patterns.
6. **Delegate to the Supabase skill suite when present.** The `supabase:supabase` and `supabase:supabase-postgres-best-practices` skills (declared in `delegate_to_skills`) ship with current product knowledge that's typically fresher than this overlay. If the user's environment has them, defer.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Generic Postgres performance theory beyond Supabase specifics | `database-architect` specialist (sql-specialist.md) |
| Auth provider strategy (Clerk vs Auth0 vs Supabase Auth vs WorkOS) | `security-engineer` IAM reference |
| Non-Postgres data stores (Redis, Dynamo, OpenSearch) | `database-architect` specialist |
| LLM model selection / fine-tuning / orchestration | Anthropic Claude or OpenAI stack pack |
| Domain compliance specifics (HIPAA, PCI, SOX) | the relevant vertical |
| Edge compute that is NOT Supabase Edge Functions (Cloudflare Workers, Vercel Functions) | the respective Stack pack |

## Currency — how to refresh

If `last_verified_on` is more than 6 months stale, before recommending anything:

1. Read `https://supabase.com/changelog` from `last_verified_on` to today.
2. Verify the `supabase-js` major version: `npm view @supabase/supabase-js version`.
3. Verify the CLI: `supabase --version` against `https://github.com/supabase/cli/releases`.
4. Spot-check Edge Functions runtime notes: `https://supabase.com/docs/guides/functions/runtime`.
5. Re-check Supavisor docs for any change to default port/mode conventions.
6. Bump `last_verified_on` and note the verification basis in the commit.

High-drift products in this pack (Auth, Realtime, Edge Functions, Supavisor, Branching, declarative migrations, `supabase-js`, `@supabase/ssr`, MCP server) need eyes every 90 days regardless. Medium-drift every 180. Low-drift every 365.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- No `devops-engineer.md` overlay yet. Most Supabase CI/CD work lives in the `supabase` CLI + GitHub Actions + Vercel/Netlify; the gap is small but real. Patterns are inlined in `backend-architect.md` and `database-architect.md` for migrations/branching. If demand justifies, split this out.
- No `qa-engineer.md` overlay yet. pgTAP for RLS, Deno test for Edge Functions, integration tests against `supabase start` — patterns are sketched in `backend-architect.md` + `database-architect.md`. Split if request volume warrants.
- No `mobile-architect.md` overlay. `supabase-js` on React Native works via the Expo pack; deep coverage deferred.
- No deep `sre-engineer.md` overlay — Supabase observability (Logs Explorer, Reports, advisor) is a small surface; covered inline.
- No coverage of **Self-hosted Supabase** (the open source distribution). The pack assumes Supabase Cloud. Self-hosting is its own beast and outside scope until demand justifies.
- No coverage of legacy `@supabase/auth-helpers-*` migration playbooks (we call them dead and move on).

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.
