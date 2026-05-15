---
title: Foreign Data Wrappers (Wrappers)
description: Pull Stripe/BigQuery/Clickhouse/Redis/Firebase/Auth0 data into Postgres as foreign tables. Read-side joins, not write throughput.
product:
  name: Foreign Data Wrappers
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, saas-architect]
  authoritative_url: https://supabase.com/docs/guides/database/extensions/wrappers
  notes: "First-party Wrappers: Stripe, BigQuery, Clickhouse, Firebase, Redis, Auth0, S3, AirTable. Excellent for read-side joins, useless for write throughput."
---

## What it is

The `wrappers` extension framework exposes external services as Postgres foreign tables. You can query Stripe customers, BigQuery datasets, Clickhouse tables, Firebase Firestore collections, Redis keys, and more as if they were local tables — and join them with your data.

Source: [Wrappers docs](https://supabase.com/docs/guides/database/extensions/wrappers).

## When to use

| Use Wrappers for | Don't use Wrappers for |
|------------------|-----------------------|
| Joining your `orgs` table with Stripe subscription state in a dashboard | High-throughput writes — they're a read-side primitive |
| Ad-hoc reporting across Postgres + SaaS sources | Replacing replication when you need bulk reads at scale |
| Quick enrichment ("show this row with Stripe metadata") | Anything that needs transactional guarantees with source writes |
| Pulling auth data from Auth0/Firebase for migration analysis | Operational paths that can't tolerate source-side latency or rate limits |

## 2025-2026 currency anchors

First-party Wrappers (as of 2026):
- **Stripe** — customers, subscriptions, charges, invoices, products, prices.
- **BigQuery** — datasets and tables.
- **Clickhouse** — tables.
- **Firebase** — Firestore collections.
- **Redis** — keys.
- **Auth0** — users.
- **S3** — bucket listings + object metadata.
- **AirTable** — bases/tables.

Additional Wrappers may exist by today's date — check the [docs](https://supabase.com/docs/guides/database/extensions/wrappers).

## Patterns and anti-patterns

### Patterns

**Stripe FDW setup:**

```sql
create extension if not exists wrappers;

create foreign data wrapper stripe_wrapper
  handler stripe_fdw_handler
  validator stripe_fdw_validator;

create server stripe_server
  foreign data wrapper stripe_wrapper
  options (
    api_key_id (select id from vault.secrets where name = 'stripe_secret_key'),
    api_url 'https://api.stripe.com/v1/'
  );

create foreign table stripe.customers (
  id text,
  email text,
  name text,
  created timestamp,
  attrs jsonb
) server stripe_server options ( object 'customers' );

create foreign table stripe.subscriptions (
  id text,
  customer text,
  status text,
  current_period_end timestamp,
  attrs jsonb
) server stripe_server options ( object 'subscriptions' );
```

**Read-side join** — your data + Stripe data:

```sql
select s.email, count(o.*) as orders
from stripe.customers s
left join public.orders o on o.stripe_customer_id = s.id
group by s.email;
```

**Use [Vault](/stacks/supabase/supabase-vector/) for FDW credentials.** Never inline `api_key` in `create server`.

**Pair FDW reads with webhook-driven writes.** The dashboard uses FDW for live state; an Edge Function consuming Stripe webhooks updates a local `subscriptions` table for fast operational reads + RLS gating.

### Anti-patterns

- **FDW for operational paths.** Latency is dominated by the source API; rate limits hit you under load.
- **FDW as a substitute for replication when you need scale.** If you read the foreign table thousands of times per minute, you're hitting the source API thousands of times per minute. Replicate into Postgres.
- **Trusting FDW writes (`INSERT INTO stripe.customers ...`)** for transactional behavior. Treat as best-effort.
- **No source-side rate-limit handling.** A burst of FDW queries can exhaust your API quota — design the query shape accordingly.

## Gotchas

- **Latency is the source's latency.** A Stripe API call from a foreign table is the same latency as a direct API call — multiplied by row count if not optimized.
- **Filter pushdown depends on the wrapper.** Not every filter clause gets pushed down to the source; some run as post-fetch filters. Check the wrapper's docs.
- **Source-side rate limits apply.** Stripe's API is rate-limited; a `select * from stripe.subscriptions` could trigger backoff.
- **Credentials in Vault** are referenced by ID in the `create server` statement; rotation = update the Vault secret + restart connections.
- **Foreign tables don't get indexes** in the usual sense; you can index local data and join, but the foreign side is what the source provides.
- **Connection state** to the source may pool inefficiently under heavy concurrent load.

## Cross-references

- [Supabase Vault](/stacks/supabase/supabase-vector/) — secure FDW credential storage
- [database-architect role view](/stacks/supabase/database-architect/) — FDW vs replication decision
- [saas-architect role view](/stacks/supabase/saas-architect/) — Stripe FDW + webhook composition
- [Edge Functions](/stacks/supabase/edge-functions/) — webhook handlers paired with FDW reads
- Supabase docs: [Wrappers](https://supabase.com/docs/guides/database/extensions/wrappers), [Stripe Wrapper](https://supabase.com/docs/guides/database/extensions/wrappers/stripe)
