---
title: Data 360
description: Salesforce's lakehouse-style customer data platform (formerly Data Cloud). Zero Copy federation, vector/hybrid search, Calculated Insights, Tableau Semantics.
product:
  name: Data 360
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, database-architect, ai-ml-engineer, healthcare-architect, fintech-architect]
  authoritative_url: https://developer.salesforce.com/docs/data/data-cloud-int/guide/
  notes: "Renamed from Data Cloud at Dreamforce '25; Zero Copy adapters expanded TDX 2026; Tableau Semantics + Intelligent Context shipped Dreamforce '25."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25, TDX 2026.</div>

## What it is

**Data 360** is Salesforce's lakehouse-style customer data platform (CDP). It was named **Data Cloud** until Dreamforce '25; older references and training data use the old name. It is a **separate runtime** from the core CRM database — different storage (lakehouse: Iceberg on object storage), different query engine (vectorized SQL + SOQL + vector + hybrid), different sharing model (entity-level + row-level filters, not OWD).

Treat Data 360 as a sibling system that happens to share a tenancy boundary with the CRM. Canonical reference: [Data 360 Docs](https://developer.salesforce.com/docs/data/data-cloud-int/guide/).

## When to use it

Decision frame — where data lives:

```
Is the data customer-360 (unifying multiple sources)?       → Data 360
Is the source-of-truth in Snowflake/Databricks/BigQuery?    → Zero Copy (federate), don't copy
Is it transactional CRM with UI / sharing / Flow?           → sObjects
Is it >1B rows, write-heavy, audit/archive?                 → Big Objects
Is it read-mostly reference data owned outside Salesforce?  → External Objects (Salesforce Connect)
```

**Use Data 360 for:**
- Long-tail behavioral / clickstream / IoT / web events
- Unified customer profile across systems (Identity Resolution + Unified Profile)
- Calculated insights, segments
- Real-time federated reads from external warehouse (Zero Copy)
- AI grounding substrate — vector and hybrid search are first-class

**Don't use Data 360 for:**
- OLTP transactional CRM workflows — those stay on sObjects
- Compliance archives where original-of-record matters — use Big Objects
- Lookup data — Custom Metadata Types are cached, deployable, and free

## 2025-2026 currency anchors

- **Data Cloud → Data 360** (renamed Dreamforce '25). Capability is unchanged; the name is everywhere new. Calling it Data Cloud in 2026 dates you.
- **Tableau Semantics** (Dreamforce '25) — unified semantic layer over Data 360 + Tableau. Define dimensions/measures/governance once at the semantic layer; every consumer (Tableau, [Agentforce](/stacks/salesforce/agentforce/) grounding, Calculated Insights, Flow) reads the same definitions. Replaces the older "model in Tableau, re-model in CRM Analytics, re-model in Data Cloud" sprawl.
- **Intelligent Context** (Dreamforce '25) — Data 360 surfaces are first-class grounding inputs for Agentforce. Vector search and hybrid (BM25 + vector) are native. You no longer wire Data Cloud → Pinecone → agent.
- **Zero Copy expansion 2026** — bidirectional with Databricks Delta sharing (GA Spring '26); Live Query Federation pushes JDBC into Snowflake/BigQuery/Redshift in-memory; BYOM inference reads features in place.
- **BYOM via Einstein Studio** is mainstream — connect SageMaker, Vertex AI, Databricks Model Serving, Azure OpenAI; inference reads Data 360 features without ETL.
- **Headless 360** (TDX 2026) — Data 360 + Agentforce composable as APIs/MCP/CLI.

## Object kinds in Data 360

| Kind | Suffix | Purpose |
|------|--------|---------|
| **Data Stream** | — | Ingest pipeline (S3, Kafka, MuleSoft, CRM, web SDK, mobile SDK). Lands raw into a DLO. |
| **Data Lake Object (DLO)** | `__dll` | Raw ingested data, schema-on-read |
| **Data Model Object (DMO)** | `__dlm` | Canonical mapped objects (Individual, Account, Order, Engagement). Query these. |
| **Calculated Insight** | `__cio` | SQL-defined derived metrics, materialized & refreshed on schedule |
| **Unified DMO** | `unified*__dlm` | Output of Identity Resolution — one row per unified individual/account |
| **Segment** | — | Filter expression over DMOs/Unified objects, activated to targets (CRM, Marketing Cloud, Ads) |

## Patterns

### Vector + hybrid search (Intelligent Context)

```sql
-- Hybrid search (BM25 + vector) over a DMO with embedded text + vector index
SELECT
  knowledge_id__c,
  title__c,
  body__c,
  HYBRID_SCORE() AS relevance
FROM Knowledge_Article__dlm
WHERE HYBRID_SEARCH(body_vector__c, body__c, :userQuery)
ORDER BY relevance DESC
LIMIT 10
```

The DMO carries both a tokenized text column (BM25) and a vector embedding column (cosine similarity), produced at ingest by an embedding model registered in Einstein Studio. Agentforce grounding consumes the same surface — define the index once, every consumer benefits.

### Calculated Insights

SQL-defined derived metrics over Data 360 objects (LTV, churn risk score, NPS rolling 30d). Materialized, refreshed on schedule. Become first-class data model objects — queryable, segmentable, activatable to CRM as flow inputs or to Marketing Cloud as audience members.

```sql
SELECT
  unified_individual_id__c                       AS individual_id,
  SUM(order_total__c)                            AS spend_30d__c,
  COUNT(DISTINCT order_id__c)                    AS order_count_30d__c
FROM ssot__Order__dlm
WHERE order_date__c >= DATEADD(day, -30, CURRENT_DATE)
GROUP BY unified_individual_id__c
```

### Identity Resolution

The only sanctioned way to do cross-system customer unification — fuzzy match on email/phone/name with deterministic + probabilistic rules, party/individual graph output. Identity Resolution is **destructive once run** — bad rules produce ghost unified profiles you'll be cleaning for months. Test the ruleset on a representative slice before going live.

### Zero Copy — federation patterns

Zero Copy means **the data does not move**. Data 360 queries reach into the external warehouse, materialize results into in-memory query buffers, and return. No nightly ETL, no duplication, no stale snapshot.

| Flavor | Direction | Best for | Cost |
|--------|-----------|----------|------|
| **Live Query Federation** | Pull from Snowflake / BigQuery / Redshift via JDBC push-down | Read-only joins to warehouse facts, ad-hoc analytics, segmentation against fresh data | Per-query latency depends on source warehouse; concurrency capped by source |
| **File-level Zero Copy (Databricks Delta sharing)** | Bidirectional — Data 360 reads & writes Delta tables in the lakehouse | Two-way reference data, shared feature stores | Cross-cloud egress; Delta schema evolution must be coordinated |
| **Iceberg-based Data Cloud sharing** | Bidirectional, lakehouse-native | When the customer is all-in on Iceberg | Newer; check region availability |

**Tradeoffs at design time:**

1. **Latency.** A federated query pays warehouse round-trip on every execution. High-volume rebuilds may be cheaper materialized.
2. **Concurrency.** Snowflake/BigQuery have their own concurrency limits and per-query cost. Naive Live Query Federation will throttle or blow billing.
3. **Schema coupling.** Federation makes the warehouse a hot dependency. Treat the federated surface as a published contract — version it.
4. **Sharing & masking.** Zero Copy reads bypass the source warehouse's row-level security unless explicitly configured.
5. **Tableau Semantics** sits across all of this — define dimensions/measures/governance once, every consumer reads the same definitions.

**Default heuristic:** federate when the warehouse owns the truth and refresh requirements are minutes-to-hours; materialize into Data 360 when query volume is high or sub-second latency matters.

## Anti-patterns

- **Saying "Data Cloud."** Renamed Dreamforce '25.
- **Re-implementing Identity Resolution in Apex** against the unified profile. The platform's ruleset owns match-merge — don't roll your own.
- **Pre-embedding everything.** Embed what's actually used for retrieval. Embedding costs money and storage.
- **Wiring Data Cloud → Pinecone → agent.** Intelligent Context made this unnecessary. Use native vector + hybrid search.
- **Federation against an under-provisioned source warehouse.** Live Query Federation is only as fast as the source.
- **Parallel modeling across Tableau / CRM Analytics / Data 360.** Tableau Semantics is the single semantic layer. Don't fragment.
- **Treating Data 360 like OLTP CRM.** Different runtime, different query model, different sharing. Don't reach for Data 360 when an sObject would do.

## Gotchas

- **Custom indexes** must be requested via Support; selectivity math owns the request
- **Big Object composite indexes are immutable** once data exists — get the order right the first time
- **Sharing recalculation under-tested at scale.** A sharing rule change on a large object can lock the org for hours
- **Identity Resolution is destructive** — test on a representative slice
- **Zero Copy egress costs** are real — cross-cloud federation surfaces them
- **Tableau Semantics changes ripple** to every consumer including agent grounding; coordinate updates

## Cross-references

- Database design depth: [database-architect on Salesforce](/stacks/salesforce/database-architect/)
- AI grounding patterns: [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/), [Agentforce](/stacks/salesforce/agentforce/)
- Apex query patterns: [Apex](/stacks/salesforce/apex/)
- Architecture decision (Data 360 vs Reports vs Tableau): [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Authoritative: [Data 360 Docs](https://developer.salesforce.com/docs/data/data-cloud-int/guide/)
