---
title: Vercel Postgres
description: "Serverless Postgres on Vercel — Neon-backed since 2024-2025. New code should use `@neondatabase/serverless` or an ORM pointing at Neon, not the legacy `@vercel/postgres` SDK."
product:
  name: Vercel Postgres
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://vercel.com/docs/storage/vercel-postgres
  notes: "Migrated to Neon backend in 2024-2025. Old `@vercel/postgres` SDK guidance partially stale. Prefer `@neondatabase/serverless` or direct Neon clients (Prisma/Drizzle pointing at Neon)."
---

## What it is

Vercel Postgres is the Postgres offering in Vercel Storage, now Neon under the hood. Marketplace provisioning, branching per Preview Deployment, serverless connection layer (HTTP driver works in Edge runtime), and a free tier. See [vercel.com/docs/storage/vercel-postgres](https://vercel.com/docs/storage/vercel-postgres) and the [Neon docs](https://neon.tech/docs).

## When to use

For most relational app data on Vercel — users, orders, posts, transactions, anything fundamentally relational. The Marketplace path with Neon is the 2026 default.

Don't use when:

- **Multi-region active-active writes** — Aurora Global, CockroachDB, Spanner.
- **Hard real-time ingestion** (millions of events/sec) — ClickHouse, TimescaleDB.
- **On-prem / sovereign requirements** — self-hosted Postgres.
- **Auth + realtime + DB as one product** — Supabase often wins on DX.

## 2025-2026 currency anchors

- **Neon-backed since 2024-2025.** Old `@vercel/postgres` SDK still works but new code should use `@neondatabase/serverless` directly or ORMs (Prisma/Drizzle) pointing at Neon.
- **Branching per Preview Deployment** — Neon's Vercel integration creates a DB branch per Preview, rebased from main on creation. Cleans up on PR close. This makes Preview environments *actually* useful for migration testing.
- **HTTP driver works in Edge runtime** — `@neondatabase/serverless` has both HTTP and WebSocket drivers; HTTP works in Edge.
- **Connection pooling** is handled at Neon's connection layer; no PgBouncer setup needed.

## Patterns + anti-patterns

**Pattern: Direct Neon client.**

```ts
import { neon } from '@neondatabase/serverless';
const sql = neon(process.env.DATABASE_URL!);

export async function getUser(id: string) {
  const rows = await sql`SELECT * FROM users WHERE id = ${id}`;
  return rows[0];
}
```

**Pattern: Drizzle pointing at Neon.**

```ts
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql);
```

**Pattern: Module-scope client.** Fluid Compute shares module-level state across concurrent invocations; reuse one client.

**Pattern: Neon branching for Preview.** Configure Neon Vercel integration → "Create branch on Preview" → every PR gets its own DB.

**Anti-pattern: `@vercel/postgres` for new code.** It wraps Neon but adds an abstraction layer you don't need now that Neon is the backend.

**Anti-pattern: PgBouncer in front of Neon.** Neon handles pooling; double-pooling is a maintenance burden.

**Anti-pattern: Function in `syd1`, DB in `iad1`.** Every query crosses the Pacific. Pin function region to DB region, or use Neon read replicas.

## ORM choices

- **Drizzle** — recommended; serverless-friendly; explicit migrations; small bundle.
- **Prisma** — works; serverless adapter exists; heavier client bundle.
- **Kysely** — typed query builder; great if you want ORM-free with types.
- **Raw `neon` template tags** — fine for small surface area.

## Gotchas

- **Connection string differs** between pooler (port 5432-pooler) and direct (port 5432) — use the pooler for serverless functions; direct for migrations.
- **HTTP vs WebSocket driver** — HTTP works in Edge runtime; WebSocket for streaming queries from Node.
- **Autosuspend** — Neon scales to zero on idle; the first query after suspend wakes the compute (cold start measured in low seconds).
- **Branch lifecycle** — Preview branches need cleanup on PR close; verify the Neon Vercel integration is doing this.

## Cross-references

- [Marketplace](/stacks/vercel/marketplace/) — how Neon gets wired
- [Vercel KV](/stacks/vercel/vercel-kv/) — for non-relational hot data
- [backend-architect on Vercel](/stacks/vercel/backend-architect/) — storage decision matrix
- [system-architect on Vercel](/stacks/vercel/system-architect/) — when Neon vs Supabase vs RDS
- Authoritative: [Vercel Postgres docs](https://vercel.com/docs/storage/vercel-postgres), [Neon docs](https://neon.tech/docs)
- Delegate: `vercel:vercel-storage`
