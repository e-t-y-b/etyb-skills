---
title: Stripe Data Pipeline
description: Native sync of Stripe data to Snowflake, Redshift, BigQuery, Databricks. Schema stable; frequency configurable. Use instead of building your own ETL.
product:
  name: Stripe Data Pipeline
  stack: stripe
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, saas-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/data-pipeline
  notes: "Native warehouse sync. Schema mirrors Sigma. Use for long-term retention, joining with operational data, BI dashboards, ledger ETL, SIEM."
---

## What it is

Stripe Data Pipeline syncs Stripe data to your warehouse on a schedule — Snowflake, Redshift, BigQuery, Databricks. Schema mirrors [Stripe Sigma](/stacks/stripe/stripe-sigma/). Use it instead of building your own ETL from the Stripe API.

Canonical reference: [docs.stripe.com/data-pipeline](https://docs.stripe.com/data-pipeline).

## When to use

| Need | Data Pipeline? |
|------|----------------|
| Long-term retention beyond Sigma's Dashboard limits | Yes |
| Joining Stripe data with operational data (orders, users, ledger) | Yes |
| Powering BI dashboards (Looker, Mode, Hex, Tableau) | Yes |
| Feeding double-entry ledger ETL | Yes |
| SIEM integration for security audit retention | Yes |
| Ad-hoc one-off queries | Use [Sigma](/stacks/stripe/stripe-sigma/) — in-Dashboard, no warehouse needed |
| Real-time analytics | No — Data Pipeline is scheduled (hourly/daily) |

For any platform doing serious volume, Data Pipeline + a warehouse is the right setup. Don't build your own ETL by polling the Stripe API.

## 2025-2026 currency anchors

- **Schema stable** — mirrors Sigma's tables. Stripe adds new tables for new products but doesn't break existing.
- **Configurable frequency** — typically hourly, daily, or per-event-class.
- **Connect platforms** see both platform data and connected-account data per scope.

## Patterns

### Ledger ETL pattern

1. **Pull `balance_transactions`** daily — every money movement (charge, refund, transfer, application_fee, dispute, payout)
2. **Map each balance transaction to ledger entries** — e.g., charge = credit "Stripe Balance" + debit "Accounts Receivable Stripe"; payout = credit "Stripe Balance" + debit "Operating Bank Account"
3. **Verify** — sum of Stripe-balance changes from your ledger = Stripe's reported daily balance change
4. **For Connect** — track both platform balance and each connected-account balance

### Audit retention for security

- Mirror `events` table to your warehouse → multi-year audit trail
- Mirror webhook receipts → reconciliation against your handler's processing log
- Combine with your app logs in the warehouse for cross-system forensics

### BI dashboards

- Sync Stripe → warehouse
- Build dashboards in Looker / Mode / Hex / Tableau / Metabase
- Don't build production dashboards against Sigma — different tool

## Anti-patterns

- **Polling the Stripe API for analytics.** Rate-limited, slow, fragile. Data Pipeline is built for bulk sync.
- **Data Pipeline as real-time event source.** It's scheduled. For real-time, use [webhooks](/stacks/stripe/webhooks/) → your event stream.
- **No reconciliation between Stripe's reported balances and your ledger derived from Data Pipeline.** You can drift silently.

## Gotchas

- **Initial backfill takes time** — for high-volume accounts, weeks of history can be a long initial sync.
- **Schema versions** — Stripe occasionally adds columns; pipeline handles forward-compat but check before assuming column existence.
- **Warehouse cost** — Stripe data volumes can be substantial (millions of balance transactions). Budget warehouse storage + compute accordingly.

## Cross-references

- [Stripe Sigma](/stacks/stripe/stripe-sigma/) — in-Dashboard alternative for ad-hoc
- [Stripe Connect](/stacks/stripe/stripe-connect/) — reconciliation across connected accounts
- [Stripe Treasury](/stacks/stripe/stripe-treasury/) — ledger design
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — audit retention
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — ledger ETL
- [saas-architect on Stripe](/stacks/stripe/saas-architect/) — revenue recognition data flow
- Authoritative: [docs.stripe.com/data-pipeline](https://docs.stripe.com/data-pipeline)
