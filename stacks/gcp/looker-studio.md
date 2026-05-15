---
title: Looker Studio
description: Free dashboarding tool from Google — connect to BigQuery, Sheets, third-party sources; Looker Studio Pro adds team workspaces and governance.
product:
  name: Looker Studio
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/looker-studio/docs
  notes: "Free tier sufficient for most teams; Looker Studio Pro for managed workspaces and team governance; positioned between free dashboarding and full Looker."
---

## What it is

Looker Studio (formerly Data Studio) is Google's free dashboarding tool. Connect to [BigQuery](/stacks/gcp/bigquery/), Google Sheets, third-party data sources; drag-and-drop chart authoring; share via link or embed in pages.

**Looker Studio Pro** is the managed tier — team workspaces, calculated fields management, embedding in apps with auth, premium support.

Authoritative reference: [cloud.google.com/looker-studio/docs](https://cloud.google.com/looker-studio/docs).

## When to use

Pick Looker Studio (free) when:
- Internal dashboards on BigQuery / Sheets / third-party SaaS data
- Quick ad-hoc visualizations
- No need for LookML semantic layer

Pick Looker Studio Pro when:
- Team workspaces with governance
- Embedded dashboards in customer-facing app
- Need premium support

Pick [Looker](/stacks/gcp/looker/) (full) when:
- Enterprise BI with governed metric layer (LookML)
- Heavy embedded analytics in SaaS

## 2025-2026 currency anchors

- **Looker Studio Pro** GA — managed tier with team workspaces.
- **Gemini-powered chart generation** — natural language to chart.
- **BigQuery BI Engine** integration — sub-second dashboard refresh on supported queries.

## Patterns

### BigQuery dashboard

Connect a BigQuery dataset as a Looker Studio source; build charts on top. Pair with **BI Engine** reservation in BigQuery Enterprise edition for sub-second refresh.

### Embedded in SaaS

Looker Studio Pro embed:
- Sign URL with row-level filter parameters
- Iframe into your app
- For tighter integration use the full [Looker](/stacks/gcp/looker/) Embedded SDK

## Anti-patterns

- **Production dashboards on free tier without governance** — version control via "make a copy" is fragile.
- **Looker Studio for enterprise metric layer needs** — use full Looker.
- **No data freshness indicators** — users get stale data, blame the platform.

## Gotchas

- **Free tier rate limits** apply on data source queries.
- **Calculated fields** are per-report; not reusable across reports without Pro.

## Cross-references

- Related: [BigQuery](/stacks/gcp/bigquery/), [Looker](/stacks/gcp/looker/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/)
- Authoritative: [cloud.google.com/looker-studio/docs](https://cloud.google.com/looker-studio/docs)
