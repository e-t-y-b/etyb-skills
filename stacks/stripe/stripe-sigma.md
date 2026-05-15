---
title: Stripe Sigma
description: SQL queries over your Stripe data inside the Dashboard. Stable surface. Saves building your own reporting on Stripe data.
product:
  name: Stripe Sigma
  stack: stripe
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, saas-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/sigma
  notes: "Stable surface; in-Dashboard SQL over Stripe data. Tables include charges, payouts, transfers, application_fees, disputes, subscriptions, invoices, customers, connected_accounts."
---

## What it is

Stripe Sigma is in-Dashboard SQL over your Stripe data. Tables include `charges`, `payouts`, `transfers`, `application_fees`, `disputes`, `subscriptions`, `invoices`, `customers`, `balance_transactions`, `connected_accounts` (Connect platforms), and more.

Use it for ad-hoc reporting, fraud/security forensics, reconciliation queries, finance/ops exploration — anything that needs a quick SQL view of Stripe state without building your own ETL.

Canonical reference: [docs.stripe.com/sigma](https://docs.stripe.com/sigma).

## When to use

| Need | Sigma? |
|------|--------|
| Ad-hoc reporting on Stripe data | Yes |
| Reconciliation queries (Connect platforms especially) | Yes |
| Joining Stripe data with your operational data | No — use [Data Pipeline](/stacks/stripe/stripe-data-pipeline/) |
| Long-term retention beyond Dashboard limits | No — use Data Pipeline + your warehouse |
| Powering BI dashboards (Looker, Mode, Hex) | Use Data Pipeline; Sigma is in-Dashboard only |
| Real-time analytics | No — Sigma is batch-ish |

## 2025-2026 currency anchors

- **Schema stable** — table list grows as new products ship, but existing tables are reliable.
- **Scheduled queries** — Sigma supports scheduled execution + delivery (CSV, JSON).
- **Per-account scope** — for Connect platforms, queries see your platform's data; querying connected-account data requires the right permissions.

## Patterns

### Daily Connect reconciliation

```sql
SELECT
  date_trunc('day', c.created) AS day,
  c.destination AS connected_account,
  SUM(c.amount) AS gross_charges,
  SUM(c.application_fee_amount) AS platform_fees,
  SUM(c.amount - c.application_fee_amount) AS transferred_to_account
FROM charges c
WHERE c.status = 'succeeded'
  AND c.created >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY 1, 2;
```

### Subscription analytics

```sql
SELECT
  date_trunc('month', s.created) AS month,
  s.plan_id,
  COUNT(*) AS new_subscriptions
FROM subscriptions s
WHERE s.status = 'active'
GROUP BY 1, 2;
```

### Fraud forensics

```sql
SELECT
  c.id,
  c.amount,
  c.outcome_risk_level,
  c.outcome_seller_message,
  c.customer
FROM charges c
WHERE c.outcome_risk_level = 'highest'
  AND c.created >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY c.amount DESC;
```

## Anti-patterns

- **Sigma as your warehouse.** It's in-Dashboard; retention is limited. For deep historical analysis, use [Data Pipeline](/stacks/stripe/stripe-data-pipeline/).
- **Real-time decisions on Sigma data.** It's not real-time; latency exists.
- **Building production dashboards on Sigma.** It's not a BI tool. Sync to your warehouse, build dashboards there.

## Gotchas

- **Schema docs** — Sigma's table list and column reference is in Stripe's docs; reference before writing queries.
- **Connect data permissions** — for Connect platforms, querying connected-account-level data requires being signed in as that account or having the right Sigma permissions.
- **Per-query cost / time limits** — long-running queries may time out.

## Cross-references

- [Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) — warehouse sync for deeper analytics
- [Stripe Connect](/stacks/stripe/stripe-connect/) — reconciliation queries
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — forensic queries
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — reconciliation pattern
- Authoritative: [docs.stripe.com/sigma](https://docs.stripe.com/sigma)
