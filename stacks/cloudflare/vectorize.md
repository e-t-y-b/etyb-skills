---
title: Vectorize
description: Cloudflare's managed vector database — V2 supports up to 1536+ dimensions, metadata indexes for filtered search, namespace partitioning, multi-million-vector indexes.
product:
  name: Vectorize
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, database-architect, backend-architect]
  authoritative_url: https://developers.cloudflare.com/vectorize/
  notes: "Vectorize V2: increased dimensions, metadata indexes, larger index sizes; v1 indexes have migration path."
---

## What it is

Vectorize is Cloudflare's managed vector database — approximate nearest-neighbor search over high-dimensional embeddings. V2 (current) supports up to 1536+ dimensions, metadata indexes for fast filtered search, namespace partitioning for multi-tenancy, and millions of vectors per index.

Authoritative reference: [developers.cloudflare.com/vectorize](https://developers.cloudflare.com/vectorize/).

## When to use

- **Semantic search over embeddings** — docs, products, FAQs, user-generated content.
- **RAG retrieval** for LLM-powered features (paired with [Workers AI](/stacks/cloudflare/workers-ai/) embeddings + an LLM through [AI Gateway](/stacks/cloudflare/ai-gateway/)).
- **Multi-tenant retrieval** — use metadata index on `tenant_id` (or namespaces for stricter partition).
- **Up to tens of millions of vectors** on Cloudflare.

Don't use Vectorize when:

- **Hybrid search (BM25 + vector)** — external (Elasticsearch, OpenSearch, Vespa, Pinecone hybrid) or roll-your-own on D1 + Vectorize.
- **Graph-aware retrieval** — external (Neo4j, FalkorDB).
- **Hundreds of millions+ vectors** — external (Pinecone, Weaviate, Qdrant Cloud) or self-host on Containers.
- **Custom rerankers, multi-vector retrieval** — DIY with multiple stores or external.

## 2025-2026 currency anchors

- **Vectorize V2** is current. Up to 1536-dim (and larger for some configurations), metadata indexes, namespaces, millions of vectors per index.
- **Metadata index filter ops** include `$eq`, `$ne`, `$in`, `$gt`, `$lt` as of 2025-26.
- **V1 indexes still exist; migration path documented.** New projects target V2.

## Decision frameworks

### Vectorize V2 index layout

| Pattern | Layout |
|---------|--------|
| Single-tenant, many topics | One index per topic; query by index |
| Multi-tenant, same schema | One index, tenant_id metadata, **metadata index on tenant_id**, filter every query |
| Multi-tenant with namespaces | One index, namespace per tenant — strict partition at index level |
| Different embedding dimensions per use case | Separate indexes (you can't mix dimensions in one) |

Set up metadata indexes at index-create time for every field you'll filter on (tenant_id, source, doc_type, language). Without metadata index, the filter scans more vectors.

## Patterns

### Create index + metadata indexes

```bash
wrangler vectorize create my-index --dimensions=1024 --metric=cosine
wrangler vectorize create-metadata-index my-index --property-name=tenant_id --type=string
wrangler vectorize create-metadata-index my-index --property-name=doc_type --type=string
```

Match `dimensions` to your embedding model — `bge-base` 768, `bge-large` 1024, OpenAI `text-embedding-3-small` 1536, etc.

### Insert with metadata

```ts
await env.VECTORS.upsert([
  { id: "doc1", values: emb1, metadata: { tenant_id: "t1", doc_type: "policy", title: "Refund Policy" } },
  { id: "doc2", values: emb2, metadata: { tenant_id: "t1", doc_type: "faq", title: "How returns work" } }
]);
```

For bulk ingest, use `wrangler vectorize insert my-index --file=./vectors.ndjson` — don't loop `upsert` from a Worker for tens of thousands of vectors.

### Query with metadata filter

```ts
const r = await env.VECTORS.query(queryEmb, {
  topK: 5,
  filter: { tenant_id: { $eq: "t1" }, doc_type: { $in: ["policy", "faq"] } },
  returnMetadata: "all"
});
```

Without the metadata index, the filter still works but scans more vectors — slower and more expensive.

### Vectorize binding in `wrangler.toml`

```toml
[[vectorize]]
binding = "VECTOR_INDEX"
index_name = "my-index"
```

## Anti-patterns

- **Cross-tenant Vectorize queries** — `env.VECTORS.query(queryEmb, { topK: 10 })` with no filter returns matches across all tenants. Always filter by tenant in multi-tenant systems.
- **Storing vectors without metadata** — you can't filter, you can't debug ("which doc did this match represent?"). Always include enough metadata to reconstruct context.
- **Mixing embedding dimensions in one index** — won't work; create separate indexes per model.
- **Forgetting to set up metadata indexes before bulk insert** — adding the index later means a rebuild.

## Gotchas

1. **Embedding model lock-in per index** — switching models means re-embedding and rebuilding the index.
2. **Metadata indexes are configured at create time.** Adding new ones later is supported but may require background work.
3. **Vector counts and dimension limits** are plan-tied — verify against current pricing.
4. **Bulk ingest via CLI is the right path**; per-Worker `upsert` loops hit subrequest limits.

## Cross-references

- [Workers AI](/stacks/cloudflare/workers-ai/) — embedding models (bge, jina) for populating Vectorize
- [AI Gateway](/stacks/cloudflare/ai-gateway/) — cache/log LLM calls that consume retrieval results
- [AI Search](/stacks/cloudflare/ai-search/) — managed RAG that uses Vectorize under the hood
- [R2](/stacks/cloudflare/r2/) — source docs typically live in R2; embeddings live in Vectorize; pair them
- [Workers](/stacks/cloudflare/workers/) — runtime that queries Vectorize
- Role overlay: [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/), [database-architect on Cloudflare](/stacks/cloudflare/database-architect/)
- Authoritative: [developers.cloudflare.com/vectorize](https://developers.cloudflare.com/vectorize/)
