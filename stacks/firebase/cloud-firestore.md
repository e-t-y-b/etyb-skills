---
title: Cloud Firestore
description: Firebase's flagship document database — strongly-consistent docs, real-time listeners, multi-database, vector search. Default Firebase persistence layer.
product:
  name: Cloud Firestore
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, mobile-architect, database-architect, ai-ml-engineer]
  authoritative_url: https://firebase.google.com/docs/firestore
  notes: "Multi-database per project GA 2024; vector search GA; Datastore-mode option exists but new projects use Native mode."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Cloud Firestore is Firebase's document database — collections of documents, where each document is a typed JSON-shaped record up to 1 MiB with up to 20K field paths. It supports real-time listeners that push changes to subscribed clients, offline persistence for mobile/web SDKs, transactions, batched writes, composite indexes, and (since 2024-2025) k-NN vector search via `findNearest`.

Two modes exist at the persistence-engine level:

- **Native mode** — the default for new projects. Document model, rich query semantics, real-time listeners on client SDKs.
- **Datastore mode** — same wire protocol as Native mode but with the consistency/index/scaling characteristics of legacy Google Cloud Datastore. Use **only** if you have an existing Datastore app. Never start a new project in Datastore mode.

Canonical reference: [Firestore docs](https://firebase.google.com/docs/firestore).

## When to use it

**Use Firestore when:**

- Your data is naturally document-shaped (one record per entity, no rigid joins)
- You need real-time listeners (`onSnapshot`) on the client
- You need offline persistence on mobile/web
- Queries are mostly by-key or by-single-field with composite indexes
- You can denormalize for read shapes

**Don't use Firestore when:**

- You need referential integrity, FK constraints, joins across heterogeneous types → use [Firebase Data Connect](/stacks/firebase/firebase-data-connect/)
- You need aggregations (SUM, COUNT, GROUP BY) as a primary query shape → Data Connect or BigQuery
- You need sub-100ms presence/typing/cursor fan-out → [Realtime Database](/stacks/firebase/realtime-database/)
- You need server-side full-text search → Algolia / Typesense / Meilisearch mirror

## 2025-2026 currency anchors

- **Multi-database per project GA** (2024) — you can now provision multiple Firestore databases per project (named, distinct rules, distinct locations). Replaces "one project per database scope" workarounds.
- **Vector search GA** (2024-2025) — `FieldValue.vector([...])` for storage, `findNearest({...})` for k-NN query. Pair with Genkit embedders or Vertex AI embeddings.
- **Datastore mode** is a separate persistence mode — don't confuse "Firestore" with "Firestore in Datastore mode" in an architecture doc.
- **Query plan output** (`.explain()`) — observe indexes used and read counts during query development.
- **Server-side TTL policies** for automatic doc expiration are now standard.

## Patterns

### Data modeling rules

- **Denormalize for reads.** Compute the read-shaped document at write time. Embed user names into orders, embed post counts into user docs. Don't join at read time.
- **Bound query result sets.** Use `.limit()` aggressively. A `where` that can return unbounded results is a cost time bomb.
- **Use subcollections for unbounded children.** Comments under a post, line items under an order — parent stays small, children scale independently.
- **Counter sharding for hot writes.** A single counter doc caps at ~1 write/sec sustained. For viral counters, shard across N docs and aggregate at read time.
- **Composite indexes for compound queries.** Defined in `firestore.indexes.json`, deployed via `firebase deploy --only firestore:indexes`. The console will offer to create them when a query fails — commit the result to source control.

### Transactions and batched writes

```ts
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

// Batched write — atomic, 500 ops max
const batch = db.batch();
batch.set(db.collection("orders").doc(orderId), order);
batch.update(db.collection("inventory").doc(sku), { count: FieldValue.increment(-1) });
await batch.commit();

// Transaction — read + conditional write, auto-retries on contention
await db.runTransaction(async (tx) => {
  const snap = await tx.get(db.collection("inventory").doc(sku));
  const count = snap.data()?.count ?? 0;
  if (count <= 0) throw new Error("Out of stock");
  tx.update(snap.ref, { count: count - 1 });
});
```

Transactions auto-retry on contention. **Don't put long external calls inside a transaction body** — retries replay the whole thing. Keep transactions fast and idempotent in their reads.

### Multi-database

```ts
const primary = getFirestore();                       // default DB
const analytics = getFirestore("analytics-db");       // named DB
```

Use cases:
- **Tenant isolation** — one DB per large tenant when per-collection rules don't suffice
- **Workload separation** — high-write analytics on its own DB so it can't starve the main app DB
- **Compliance fencing** — a separate DB in a specific region for residency requirements

Cost is per-DB — provisioning many small DBs to "be tidy" is wasteful. Use multi-DB when there's a real isolation reason.

### Vector search

```ts
await db.collection("articles").doc(id).set({
  title, body,
  embedding: FieldValue.vector([0.12, 0.45, /* ... */]),
});

const results = await db.collection("articles")
  .findNearest({
    vectorField: "embedding",
    queryVector: FieldValue.vector(queryEmbedding),
    limit: 10,
    distanceMeasure: "COSINE",
  })
  .get();
```

Excellent for "small RAG corpus living next to my app data" — works well up to ~100K docs. Hybrid filtering (`findNearest` + `where`) works natively. See [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/#retrieval-augmented-generation-rag-with-firestore-vector-search) for the full RAG pattern.

For production-scale vector search with millions of docs, evaluate dedicated vector DBs (Pinecone, Weaviate, pgvector via Data Connect).

### Real-time listeners (client SDK)

```ts
const q = query(collection(db, "messages"), where("roomId", "==", roomId), orderBy("createdAt", "desc"), limit(50));
const unsubscribe = onSnapshot(q, (snapshot) => {
  setMessages(snapshot.docs.map(d => ({ id: d.id, ...d.data() })));
});
return () => unsubscribe();   // CRITICAL: detach on unmount
```

### Offline persistence

```ts
const db = initializeFirestore(app, {
  localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
});
```

IndexedDB-backed; survives page reloads; multi-tab leader elects one tab to sync. Non-negotiable for PWAs and offline-first apps.

### Pagination — cursor-based

`startAfter(documentSnapshot)` is the canonical pattern. Don't paginate via offset — Firestore doesn't support efficient offsets.

## Anti-patterns

- **Treating Firestore as a relational DB** — N+1 queries on referenced docs, array-of-IDs lookups, "join in client code." Denormalize for reads or use [Data Connect](/stacks/firebase/firebase-data-connect/).
- **`where()` queries without `.limit()`** — cost time bomb as the collection grows.
- **`onSnapshot` on a query firing hundreds of doc updates per second** — cost + render thrash.
- **Listeners not detached on component unmount** — leaked listeners cost reads continuously and keep the connection open.
- **Long external calls inside transactions** — they replay on retry.
- **Trusting client-supplied `request.resource.data.userId`** in Security Rules — client lies. Use `request.auth.uid`.
- **Starting a new project in Datastore mode** — you lose multi-database, vector search, and real-time listeners on the client SDKs. Always Native mode for new projects.

## Gotchas

- **Reads cost per document, not per query.** A `where` returning 50,000 docs costs 50,000 reads. Composite indexes don't help cost — they help latency and avoiding "this query requires an index" errors.
- **1 MiB max document size.** Embed images/files in Cloud Storage, reference by path.
- **20K field paths per document.** Pathologically wide docs hit this.
- **1 write/second per document sustained** — shard hot counters.
- **Strong consistency within a document; eventual across collections for indexed queries.**
- **Multi-database cost** is per-DB — don't shard for "tidiness."
- **Cross-region listeners** add latency — pin your Firestore region next to your function region.

## Cross-references

- [Firebase Data Connect](/stacks/firebase/firebase-data-connect/) — relational alternative when joins/aggregations matter
- [Realtime Database](/stacks/firebase/realtime-database/) — sub-100ms presence sibling
- [Security Rules](/stacks/firebase/security-rules/) — rules language for Firestore
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — `onDocumentCreated`/`onDocumentWritten` triggers
- [backend-architect overlay](/stacks/firebase/backend-architect/) — Firestore data modeling at scale
- [frontend-architect overlay](/stacks/firebase/frontend-architect/) — client-side real-time + offline
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — vector search + RAG
- Authoritative: [firebase.google.com/docs/firestore](https://firebase.google.com/docs/firestore)
