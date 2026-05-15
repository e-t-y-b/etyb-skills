---
title: Firestore
description: Serverless document database with real-time listeners, multi-database support, MongoDB compatibility (Preview), vector search. Native vs Datastore mode is irreversible.
product:
  name: Firestore
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, saas-architect, mobile-architect]
  authoritative_url: https://cloud.google.com/firestore/docs
  notes: "MongoDB compatibility (Preview), Firestore for Datastore mode unification, Firestore in Native vs Datastore mode confusion still common."
---

## What it is

Firestore is GCP's serverless document database — strong consistency, real-time listeners, mobile/web SDKs, multi-region 99.999% SLA. Two modes exist (irreversible at database creation):

- **Native mode** — modern path; real-time listeners, mobile SDKs, MongoDB compatibility (Preview), vector search
- **Datastore mode** — legacy Cloud Datastore API; for backwards compatibility only

**New builds = Native mode.** The "Firestore (Datastore mode)" naming confuses people regularly; clarify before provisioning.

Authoritative reference: [cloud.google.com/firestore/docs](https://cloud.google.com/firestore/docs).

## When to use

Pick Firestore (Native) when:
- Document data model with hierarchical/sub-collection shape
- Real-time listeners required (mobile chat, collaborative editing, live dashboards)
- Mobile-first / web-first app where Firebase SDKs are the integration point
- Serverless scaling — no instance to size or manage
- Multi-region 99.999% SLA matters

Don't pick Firestore when:
- Relational workload with joins / transactions across many entities — use [Cloud SQL](/stacks/gcp/cloud-sql/) / [AlloyDB](/stacks/gcp/alloydb/) / [Spanner](/stacks/gcp/spanner/)
- High-volume time series at petabyte scale — use [Bigtable](/stacks/gcp/bigtable/)
- Analytical aggregations — use [BigQuery](/stacks/gcp/bigquery/)

## 2025-2026 currency anchors

- **Multi-database** (GA) — multiple Firestore databases per project. Useful for tenant isolation in SaaS or environment separation.
- **MongoDB compatibility** (Preview) — use MongoDB drivers/tools against Firestore. Useful for migrations away from Mongo.
- **Vector search** — `FindNearest()` queries on a vector field; integrates with Vertex AI for embedding generation.
- **Firestore in Native vs Datastore mode** — choice is at database creation and irreversible per database; with multi-database you can have one Native and one Datastore in the same project.
- **Aggregation queries** (`count()`, `sum()`, `avg()`) GA — reduce client-side aggregation.

## Patterns

### Multi-tenant SaaS with multi-database

```bash
gcloud firestore databases create --database=tenant-abc --location=us-central1 --type=firestore-native
gcloud firestore databases create --database=tenant-xyz --location=us-central1 --type=firestore-native
```

Per-tenant isolation at the database boundary; per-database pricing floor applies, so viable for moderate tenant count. See [saas-architect on GCP](/stacks/gcp/saas-architect/) for tenant isolation models.

### Real-time listener (web SDK)

```js
import { onSnapshot, query, collection, where } from "firebase/firestore";

const q = query(
  collection(db, "messages"),
  where("channelId", "==", channelId)
);

const unsubscribe = onSnapshot(q, (snapshot) => {
  snapshot.docChanges().forEach((change) => {
    if (change.type === "added") {
      renderNewMessage(change.doc.data());
    }
  });
});
```

The real-time listener pattern is Firestore's signature strength; replicates Realtime DB-style live sync with structured documents.

### Vector search

```js
import { FieldValue } from "firebase-admin/firestore";

await db.collection("articles").doc(id).set({
  title: "...",
  body: "...",
  embedding: FieldValue.vector(embeddingArray),
});

const results = await db.collection("articles")
  .findNearest("embedding", queryEmbedding, { limit: 10, distanceMeasure: "COSINE" })
  .get();
```

Right for mobile-first / serverless vector search. For >10M vectors with low-latency demands, use [Vertex AI Vector Search](/stacks/gcp/vertex-ai/).

## Anti-patterns

- **Firestore in Datastore mode for new builds** — legacy compatibility surface; use Native.
- **Relational data model in Firestore** — joins are client-side; if you find yourself fetching N+1 documents to render a screen, you have the wrong store.
- **No security rules** — Firestore Security Rules are how access control works for mobile/web SDK direct access; missing rules = open database.
- **Hot-doc writes** — a single document with >1 write/second causes contention; shard via subcollections or counter patterns.
- **No indexes on composite queries** — Firestore requires explicit composite indexes; failed queries tell you which to create.

## Gotchas

- **Pricing** is per document read/write/delete + storage. Aggregation queries reduce read counts substantially.
- **Maximum document size** is 1 MiB; for larger payloads use [Cloud Storage](/stacks/gcp/cloud-storage/) with the doc holding a reference.
- **Security Rules** apply to direct SDK access; server-side access via Admin SDK bypasses rules — useful but a foot-gun.
- **Export/import** is the standard backup pattern; managed export to Cloud Storage.
- **Realtime Database vs Firestore** — different products. Realtime DB is the older simpler key-value; Firestore is the modern path.

## Cross-references

- Related: [Cloud SQL](/stacks/gcp/cloud-sql/), [AlloyDB](/stacks/gcp/alloydb/), [Spanner](/stacks/gcp/spanner/), [Bigtable](/stacks/gcp/bigtable/), [Vertex AI](/stacks/gcp/vertex-ai/) (embeddings)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [backend-architect on GCP](/stacks/gcp/backend-architect/), [saas-architect on GCP](/stacks/gcp/saas-architect/)
- Authoritative: [cloud.google.com/firestore/docs](https://cloud.google.com/firestore/docs)
