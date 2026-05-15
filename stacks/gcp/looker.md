---
title: Looker
description: GCP's enterprise BI platform — LookML semantic modeling, embedded analytics, governed metric layer over BigQuery and other warehouses.
product:
  name: Looker
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, system-architect, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/looker/docs
  notes: "Enterprise BI; LookML semantic layer; embedded analytics for SaaS; integrated with Gemini for analytical assistants."
---

## What it is

Looker is GCP's enterprise BI platform. The signature feature is **LookML** — a declarative semantic modeling language for describing metrics, dimensions, and joins independent of the underlying SQL. Once modeled, Looker generates SQL against [BigQuery](/stacks/gcp/bigquery/) (or other warehouses) and serves dashboards, scheduled reports, and embedded analytics.

Authoritative reference: [cloud.google.com/looker/docs](https://cloud.google.com/looker/docs).

## When to use

Pick Looker when:
- Enterprise BI with governed metrics — single source of truth for "what does revenue mean"
- Embedded analytics in your SaaS product (Looker Embedded)
- Need a metric layer / semantic layer over warehouse data
- Self-service exploration with guardrails (Explore UI on LookML models)

Don't pick Looker when:
- Simple dashboards on BigQuery without governance needs — [Looker Studio](/stacks/gcp/looker-studio/) is free and sufficient
- Existing BI investment (Tableau, Power BI, Mode) is significant
- Team doesn't want to learn LookML

## 2025-2026 currency anchors

- **Gemini in Looker** — analytical AI assistant inside Looker; ask questions in natural language, get LookML-generated answers.
- **Looker Studio Pro** — managed Looker Studio with team workspaces; positioned between free Looker Studio and full Looker.
- **Embedded SDK** — embed Looker dashboards in customer-facing SaaS apps with row-level filtering.

## Patterns

### LookML model

```lookml
view: orders {
  sql_table_name: dataset.orders ;;

  dimension: order_id { primary_key: yes; sql: ${TABLE}.order_id ;; }
  dimension: customer_id { sql: ${TABLE}.customer_id ;; }
  dimension_group: ordered { type: time; timeframes: [date, week, month]; sql: ${TABLE}.ordered_at ;; }

  measure: count { type: count }
  measure: total_revenue {
    type: sum
    sql: ${TABLE}.amount_cents / 100.0 ;;
    value_format_name: "usd"
  }
}
```

Analysts then explore via the Looker UI — no SQL writing for common slices.

### Embedded analytics in SaaS

For multi-tenant SaaS embedding Looker dashboards:
- Use Looker's signed embed URLs with row-level filters (`models` and `permissions` in the URL signature)
- Tenant data isolated via LookML access filters keyed to the tenant
- Iframe Looker into your app or use the Embed SDK for tighter integration

See [saas-architect on GCP](/stacks/gcp/saas-architect/) for multi-tenant BI patterns.

## Anti-patterns

- **Multiple definitions of "revenue"** across LookML views — defeats the semantic-layer value prop.
- **No access controls / row-level filters** in embedded analytics — cross-tenant data leak.
- **LookML for trivial dashboards** — overhead; use Looker Studio instead.

## Gotchas

- **Persistent Derived Tables (PDTs)** materialize expensive SQL in the warehouse — manage their refresh and cost.
- **API rate limits** for embedded analytics traffic — verify against your SaaS scale.
- **Looker pricing** is per-user; embedded analytics has different SKUs.

## Cross-references

- Related: [BigQuery](/stacks/gcp/bigquery/), [Looker Studio](/stacks/gcp/looker-studio/), [Gemini](/stacks/gcp/gemini/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [saas-architect on GCP](/stacks/gcp/saas-architect/)
- Authoritative: [cloud.google.com/looker/docs](https://cloud.google.com/looker/docs)
