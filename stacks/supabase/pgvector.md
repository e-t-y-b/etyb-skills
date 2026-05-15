---
title: pgvector
description: Vector storage and similarity search inside Postgres. HNSW + halfvec is the default for 2026 RAG workloads.
product:
  name: pgvector
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, database-architect, backend-architect]
  authoritative_url: https://supabase.com/docs/guides/ai/vector-columns
  notes: "HNSW since 0.5 (mainstream by 2024); halfvec / sparsevec types added; index choice matters at scale. pgvectorscale NOT on Supabase managed."
---

## What it is

`pgvector` is a Postgres extension that adds vector data types (`vector`, `halfvec`, `sparsevec`), distance operators (`<->`, `<=>`, `<#>`), and index types (HNSW, IVFFlat). On Supabase, it's the vector store for RAG, semantic search, recommendations, and agent memory.

Source: [pgvector on GitHub](https://github.com/pgvector/pgvector), [Supabase vector guide](https://supabase.com/docs/guides/ai/vector-columns).

## When to use

Use pgvector when:
- You're already on Postgres and want to keep vectors next to your relational data + RLS.
- Corpus is up to ~10M vectors per tenant; HNSW + halfvec keeps it fast.
- You want hybrid search (vector + BM25 + trigram) without standing up a separate index.

Pick a dedicated vector DB (Pinecone, Weaviate, Qdrant, Turbopuffer) when:
- Corpus is hundreds of millions of vectors.
- You need specialized features (cross-encoder rerank built-in, multi-modal).
- The relational join isn't valuable to you.

For most B2B SaaS, **pgvector is the right answer**.

## 2025-2026 currency anchors

- **HNSW since pgvector 0.5** — the default index type. Better recall, slower build, faster query than IVFFlat.
- **`halfvec` (16-bit floats)** — half the storage and memory, recall loss typically <1%. **Use as default** unless you have a specific reason for full precision.
- **`sparsevec`** — for SPLADE / BGE-M3 sparse / learned sparse retrieval.
- **`pgvectorscale` is NOT on Supabase managed.** Don't recommend it.
- **`ef_search` per session** — `set hnsw.ef_search = 100;` tunes recall vs latency at query time.
- **Cosine (`<=>`) is the default operator** for OpenAI/Anthropic/Voyage/Cohere embeddings. L2 (`<->`) is rare in modern workflows.

## Patterns and anti-patterns

### Patterns

**Schema with halfvec + HNSW:**

```sql
create extension if not exists vector;

create table public.embeddings (
  id bigserial primary key,
  org_id uuid not null,
  source_type text not null,
  source_id uuid not null,
  embedding halfvec(1536) not null,
  metadata jsonb default '{}'
);

create index embeddings_org_id_idx on public.embeddings (org_id);
create index embeddings_hnsw_idx
  on public.embeddings
  using hnsw (embedding halfvec_cosine_ops)
  with (m = 16, ef_construction = 64);
```

**Top-K retrieval with RLS gating** — the canonical RAG fetch:

```sql
select id, content, 1 - (embedding <=> $1) as similarity
from public.documents
where org_id = $2  -- explicit predicate; RLS would also apply
order by embedding <=> $1
limit 10;
```

**Match function** exposed via RPC — `security invoker` so RLS applies:

```sql
create or replace function public.match_document_chunks(
  query_embedding vector(1536),
  match_count int default 10
)
returns table (id bigint, content text, similarity float)
language sql
stable
security invoker
as $$
  select id, content, 1 - (embedding <=> query_embedding) as similarity
  from public.document_chunks
  order by embedding <=> query_embedding
  limit match_count
$$;
```

**Tune `ef_search` at query time:**

```sql
set local hnsw.ef_search = 100;  -- higher recall, slower
-- run vector query
```

**Store the embedding model + version in metadata:**

```sql
metadata = '{"model": "text-embedding-3-small", "version": "v1"}'::jsonb
```

Two different models = orthogonal vector spaces; you must know which generated each vector.

### Anti-patterns

- **`vector` instead of `halfvec` by default.** Doubles storage and memory for marginal accuracy.
- **`IVFFlat` as the default index.** Old advice. HNSW is the right default; reach for IVFFlat only at corpora >50M vectors where HNSW build time is intolerable.
- **HNSW on `vector_l2_ops` when querying with `<=>` (cosine).** Index op-class must match the query operator.
- **Forgetting RLS on the embedding table.** Multi-tenant retrieval leaks across orgs. The match function MUST be `security invoker`.
- **Mixing embedding models in one column.** Each row's vector is in a different space; similarity is meaningless.
- **Re-embedding the corpus in-place during traffic.** Use side-by-side `embedding_v2` column, swap after backfill.

## Gotchas

- **HNSW indexes are slow to build** — for very large corpora, plan a backfill window. `ef_construction` higher = even slower.
- **`ef_search` defaults to 40** — for serious recall, bump to 100+ at the cost of latency.
- **Index choice and op-class must match query operator.** A common silent perf bug.
- **Sparse vectors (`sparsevec`) need different index types** and are not yet supported by all retrieval frameworks.
- **`pgvectorscale` (Timescale extension)** is NOT available on Supabase managed — don't recommend StreamingDiskANN.
- **Adding a vector column to a large existing table** holds a lock long enough to matter — schedule the migration.
- **Embedding cost dominates ingestion.** Cache aggressively; batch API calls.

## Cross-references

- [pg_trgm](/stacks/supabase/pg-trgm/) — pairs with pgvector for hybrid (vector + fuzzy keyword) search
- [Edge Functions](/stacks/supabase/edge-functions/) — embedding generation + RAG orchestration
- [Row-Level Security](/stacks/supabase/row-level-security/) — tenant isolation on embeddings
- [Database Functions](/stacks/supabase/database-functions/) — `security invoker` match functions
- [ai-ml-engineer role view](/stacks/supabase/ai-ml-engineer/) — full RAG playbook
- pgvector source: [github.com/pgvector/pgvector](https://github.com/pgvector/pgvector)
- Supabase docs: [Vector columns](https://supabase.com/docs/guides/ai/vector-columns), [AI guide](https://supabase.com/docs/guides/ai)
