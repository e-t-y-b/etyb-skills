---
title: database-architect on Supabase
description: Schema, RLS performance, indexes, migrations, branching, extensions, FDWs, query observability, pooler decisions from a DB seat.
role_overlay:
  role: database-architect
  stack: supabase
  last_verified_on: "2026-05-14"
  products_covered: [postgres, row-level-security, migrations, branching, supavisor, pgvector, pg-trgm, pg-cron, pg-net, database-functions, foreign-data-wrappers, supabase-vector, database-webhooks]
---

## Role briefing

You're database-architect on a Supabase engagement. Supabase is **Postgres**, with managed extensions, RLS, a pooler, and a small constellation of products bolted on. Your job: the schema, the policies, the indexes, the migration story, the extensions you turn on, the pooler mode you choose, and how the data layer composes with Auth, Realtime, Storage, and Edge Functions. Everything else is implementation detail.

What's distinctive vs. a generic database-architect role: **RLS is part of the schema**. Every schema decision is also a policy decision. The auth schema (`auth.users`) is managed and not directly editable. The pooler (Supavisor) sits between every connection and the database; you choose its mode and that choice changes which features work. Branching changes the migration story.

## Decision frameworks specific to database-architect on Supabase

### Tenancy model

| Pattern | When | Tradeoff |
|---------|------|----------|
| **Single `public` schema, tenant_id column, RLS** | The default for SaaS. Fits 95% of B2B apps up to tens of millions of rows per tenant. | One DB, one set of indexes; RLS does the isolation. |
| **Schema per tenant** | Tenants need genuinely separate data perimeters (regulated industries, customer-owned backups). | `SET search_path` interaction with transaction pooler is painful; migrations apply N times. |
| **Project per tenant** | Compliance-driven (HIPAA isolation, sovereignty), or you're an ISV embedding Supabase per customer. | Operationally heavy; each project has its own Auth, backup, URL. |

Default is **single schema + RLS**. Escalate only on concrete reason. See [saas-architect](/stacks/supabase/saas-architect/) for the multi-tenancy deep-dive.

### Declarative migrations vs diff-based

Pick one per project; **don't mix**. See [Migrations](/stacks/supabase/migrations/) for the full story.

- **Diff-based** — edit local DB, run `db diff -f <name>`, file lands in `supabase/migrations/`. Strength: explicit history. Weakness: drift if humans hand-edit migration files.
- **Declarative** — edit `supabase/schemas/*.sql`, run `db diff` to bridge live → schema. Strength: schema-in-PR-diff review. Weakness: some changes (renaming with data preservation) still need hand-written bridges.

### Pooler mode

| URL | Mode | Port | When |
|-----|------|------|------|
| Direct | — | `5432` | Studio, `psql`, replication subscribers |
| Session pooler | Session | `5432` (pooler hostname) | Migrations, `LISTEN/NOTIFY`, prepared statements, long-lived servers |
| Transaction pooler | Transaction | `6543` | **Default app traffic** — Edge Functions, serverless |

Transaction mode disables prepared statements, `SET` (non-LOCAL), `LISTEN/NOTIFY`, session-level advisory locks, and cursors outliving a transaction. ORMs need explicit config. See [Supavisor](/stacks/supabase/supavisor/).

### When to add a read replica

Pro+ supports read replicas. Add one when:
- Read traffic >> write traffic AND reads saturate primary CPU/IO.
- Heavy analytics queries compete with operational traffic.
- Multi-region deployment with regional read latency requirements.

Replicas are eventually consistent (<100ms typical lag). Most apps under 10k req/s don't need them.

### Vector index choice

| Index | When |
|-------|------|
| **HNSW** | Default for <10M vectors. Better recall, slower build, faster query. |
| **IVFFlat** | Only when HNSW build time is prohibitive (>50M vectors). Smaller index, cheaper build, recall depends on tuning. |
| Use **halfvec** by default. | Half storage and memory; negligible recall loss for typical embeddings. |

See [pgvector](/stacks/supabase/pgvector/) for full tuning.

## Product references

- [Postgres](/stacks/supabase/postgres/) — the substrate; managed schemas (`auth`, `storage`, `realtime`, etc.) are off-limits for direct edit. PG17 default since 2025.
- [Row-Level Security](/stacks/supabase/row-level-security/) — the authorization plane. Performance is your concern; policy correctness is shared with security-engineer. The `(select auth.uid())` wrap rule + indexed policy columns is the single highest-leverage performance ruleset.
- [Migrations](/stacks/supabase/migrations/) — declarative vs diff-based; mix is the #1 cause of broken `db push`.
- [Branching](/stacks/supabase/branching/) — every PR a database; migrations replay at merge time. Not a replacement for backups.
- [Supavisor](/stacks/supabase/supavisor/) — transaction vs session mode; ORM compatibility matrix.
- [pgvector](/stacks/supabase/pgvector/) — HNSW + halfvec for most workloads; IVFFlat only at very large scale.
- [pg_trgm](/stacks/supabase/pg-trgm/) — fuzzy text + ILIKE acceleration; pairs with pgvector for hybrid search.
- [pg_cron](/stacks/supabase/pg-cron/) / [Supabase Cron](/stacks/supabase/supabase-cron/) — scheduled SQL; prefer the UI wrapper for auditability.
- [pg_net](/stacks/supabase/pg-net/) — async HTTP from Postgres; never sync from triggers.
- [Database Functions](/stacks/supabase/database-functions/) — RPC, triggers, RLS helpers; `SECURITY DEFINER` + `SET search_path = ''` is non-negotiable.
- [Foreign Data Wrappers](/stacks/supabase/foreign-data-wrappers/) — read-side joins to SaaS sources; not for write throughput.
- [Supabase Vault](/stacks/supabase/supabase-vector/) — encrypted secrets inside Postgres for things called via `pg_net`.
- [Database Webhooks](/stacks/supabase/database-webhooks/) — async via `pg_net`; design for at-least-once.

## Extension strategy

**Default-enabled on new projects:** `uuid-ossp`, `pgcrypto`, `pg_stat_statements`, `pgjwt`, `pg_graphql`, `pgsodium`, `supabase_vault`.

**Worth enabling on most projects:** `pgvector`, `pg_trgm`, `btree_gin`, `btree_gist`, `pg_jsonschema`, `pg_cron`, `pg_net`, `pgaudit` (regulated workloads).

**Enable only when needed:** `pgmq` (via Supabase Queues), `wrappers`, `pg_tle`, `plv8`, `tsm_system_rows`.

**Don't enable:** `citus` (not the right shape on managed Supabase), `timescaledb` (not on current managed surface).

Each enabled extension is something to maintain at PG-version upgrade time. Be deliberate.

## 2025-2026 platform reset relevant to database-architect

- **PG17 is default for new projects** (2025). PG16 → PG17 in-place upgrade requires extension compatibility pre-check; some extensions (`pg_graphql`, `pg_cron`, `wrappers`) may need re-create post-upgrade.
- **The `(select auth.uid())` performance rule** is documented and benchmarked. ~100x on 1M-row tables.
- **`SECURITY INVOKER` views** (PG15+) — opt-in via `WITH (security_invoker = true)`. Audit every view; legacy default is `SECURITY DEFINER` semantics that bypass RLS.
- **Database Branching is GA** and integrated with Vercel/Netlify. Branch migrations replay at merge.
- **Declarative schemas (2024)** coexist with diff-based migrations. Pick one per project.
- **Supabase Cron + Queues** are the managed surfaces on `pg_cron` and `pgmq` respectively.
- **No `pgvectorscale`** on managed Supabase — don't recommend.

## Patterns the role applies

### TDD on schema and RLS

Every RLS policy ships with an impersonation test in `tests/rls/*.sql`:

```sql
begin;
  insert into auth.users (id, email) values
    ('11111111-1111-1111-1111-111111111111', 'alice@test.com'),
    ('22222222-2222-2222-2222-222222222222', 'bob@test.com');

  insert into public.orders (id, user_id, total) values
    ('a1', '11111111-1111-1111-1111-111111111111', 100),
    ('b1', '22222222-2222-2222-2222-222222222222', 200);

  set local role authenticated;
  set local request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';

  do $$
  begin
    assert (select count(*) from public.orders) = 1, 'Alice should see 1 order';
    assert (select count(*) from public.orders where user_id = '22222222-2222-2222-2222-222222222222') = 0, 'Alice should not see Bob''s order';
  end $$;
rollback;
```

Run in CI with `psql -f tests/rls/*.sql` against `supabase start`.

### Verification

Before claiming a policy is correct: show `EXPLAIN ANALYZE` plan AND impersonation-test pass. Before claiming an index speeds a query: show before/after `EXPLAIN ANALYZE` row counts and buffer hits. Don't trust "the dashboard says it's faster" — show the planner output.

### Debugging

**"RLS isn't working" — six distinct causes** (ranked):
1. RLS enabled but no policies (default-deny → empty result).
2. `auth.uid()` direct and user isn't authenticated (`null = null` is false).
3. Policy joins through a table that has its own RLS filtering out the inner select.
4. Query goes through `service_role` and bypasses RLS.
5. Query hits a view that's `SECURITY DEFINER` (legacy default).
6. Policy logic bug (wrong join condition).

`set local role authenticated; set local request.jwt.claims = '{"sub": ...}';` then run the query — that's the truth of what the user sees.

**"Connection saturation"** — symptoms: `remaining connection slots are reserved` errors, sudden latency cliffs with light DB CPU.
- Confirm app uses transaction pooler (`:6543`) not direct.
- Set `statement_timeout` on roles.
- Move long jobs to Queues + workers.

**"Slow RLS query"** — hypothesis-ranked:
1. `auth.uid()` not wrapped in `(select ...)`.
2. Policy column not indexed.
3. Helper function not `stable`.
4. Helper function does its own seq scan.

## Cross-references

- [backend-architect](/stacks/supabase/backend-architect/) — Edge Functions, server-side patterns
- [frontend-architect](/stacks/supabase/frontend-architect/) — client-side queries + generated types
- [security-engineer](/stacks/supabase/security-engineer/) — RLS from the security seat
- [ai-ml-engineer](/stacks/supabase/ai-ml-engineer/) — pgvector + hybrid search
- [saas-architect](/stacks/supabase/saas-architect/) — multi-tenancy modeling on RLS
- [Supabase Stack index](/stacks/supabase/) — what changed in 2025-2026
