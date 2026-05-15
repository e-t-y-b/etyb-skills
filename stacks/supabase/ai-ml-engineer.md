---
title: ai-ml-engineer on Supabase
description: pgvector + HNSW + halfvec, hybrid search, RAG via Edge Functions, agent memory, multi-tenant AI via RLS, eval discipline.
role_overlay:
  role: ai-ml-engineer
  stack: supabase
  last_verified_on: "2026-05-14"
  products_covered: [pgvector, pg-trgm, edge-functions, supabase-realtime, row-level-security, database-functions, postgres]
---

## Role briefing

You're ai-ml-engineer on a Supabase engagement. Your surface here is narrower than on AWS or GCP — there are no managed training jobs, no model registry, no Vertex/Bedrock equivalent. What Supabase gives you is **[pgvector](/stacks/supabase/pgvector/) as a first-class vector store**, **[Edge Functions](/stacks/supabase/edge-functions/) as your orchestration runtime**, and **the rest of Postgres** for the data that turns embeddings into useful retrieval. That combination is enough to build production RAG, semantic search, recommendations, and lightweight agent backends — and a lot of teams overbuild around it.

What's distinctive vs. a generic ai-ml-engineer role: **Supabase is the data plane**. Models, model gateways, fine-tuning runs, GPU jobs live elsewhere. Edge Functions stitch them together; pgvector is where the embeddings come to rest. Multi-tenancy through RLS means you get tenant-scoped retrieval for free if you wire it right.

## What you build on Supabase, what you don't

| Build on Supabase | Build elsewhere (call from Edge Functions) |
|-------------------|---------------------------------------------|
| Embedding storage + vector search (pgvector) | Embedding generation (OpenAI / Voyage / Cohere / Anthropic) |
| Hybrid search (vector + BM25 + trigram) | Foundation model inference (Anthropic / OpenAI / Bedrock / Vertex) |
| RAG orchestration | Fine-tuning (HuggingFace, OpenAI fine-tunes, AWS Bedrock custom) |
| Lightweight feature store (Postgres tables) | Heavyweight feature stores (Tecton, Feast) |
| Agent state + memory (Postgres + Realtime) | Agent frameworks (LangChain / LangGraph / Mastra) — they call Supabase |
| Auth-bound multi-tenant AI (RLS) | Image / audio model serving (Replicate, Modal, fal) |

## Decision frameworks specific to ai-ml-engineer on Supabase

### Vector type

Default to **halfvec**. Cuts storage and memory in half; recall loss typically <1%.

| Type | When |
|------|------|
| `vector(N)` | Full float32 — only when precision genuinely matters at the edges |
| `halfvec(N)` | **Default** — half storage, negligible recall loss |
| `sparsevec(N)` | SPLADE / BGE-M3 sparse / learned sparse |

### Index choice

| Index | When |
|-------|------|
| **HNSW** | Default for <10M vectors. Better recall, faster query. |
| **IVFFlat** | Only when HNSW build is prohibitive (>50M vectors). |

`pgvectorscale` is **NOT** on Supabase managed. Don't recommend it.

### Distance operator

| Operator | Distance | When |
|----------|----------|------|
| `<=>` | Cosine | **Default** for OpenAI/Anthropic/Voyage/Cohere |
| `<->` | L2 | Rare in modern embedding workflows |
| `<#>` | Negative inner product | Only with normalized embeddings + IP semantics |

If unsure, use `<=>`.

### When to add a reranker

Rerankers (Cohere, Voyage, Jina) add 200-500ms latency and meaningfully improve retrieval quality. Add when:
- Retrieval quality > latency (analyst, legal, support search).
- Eval scores show meaningful recall@10 improvement with rerank.

Skip when latency-sensitive (chat completions) and vector retrieval is already good enough.

## Product references

- [pgvector](/stacks/supabase/pgvector/) — HNSW + halfvec; metadata in JSONB with GIN index for filters; the canonical match function is `security invoker` so RLS applies.
- [pg_trgm](/stacks/supabase/pg-trgm/) — fuzzy/trigram keyword search; pairs with pgvector for hybrid.
- [Edge Functions](/stacks/supabase/edge-functions/) — embedding ingestion (service role), RAG orchestration (anon + forwarded JWT), streaming model responses.
- [Row-Level Security](/stacks/supabase/row-level-security/) — tenant scoping for embeddings; the match function must be `security invoker` to inherit RLS.
- [Database Functions](/stacks/supabase/database-functions/) — `match_document_chunks` as a `security invoker` RPC.
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — streaming partial completions to the client via Broadcast.

## RAG skeleton on Supabase

```
1. Ingest: chunk → embed → store in pgvector with metadata + org_id
2. Retrieve: embed query → pgvector top-K (RLS-scoped) → optional rerank
3. Generate: stuff top-K → call model from Edge Function → stream
```

**Ingestion Edge Function** uses service role (it's admin work); trigger via [Queues](/stacks/supabase/supabase-queues/) or Cron, not directly from user input.

**Retrieval Edge Function** uses anon + forwarded JWT so RLS scopes embeddings to the user's org.

**The match function** must be `security invoker`:

```sql
create or replace function public.match_document_chunks(
  query_embedding vector(1536),
  match_count int default 10
)
returns table (id bigint, content text, similarity float)
language sql stable security invoker as $$
  select id, content, 1 - (embedding <=> query_embedding) as similarity
  from public.document_chunks
  order by embedding <=> query_embedding
  limit match_count
$$;
```

`security invoker` is critical — without it, the function bypasses RLS and the caller retrieves chunks from other orgs.

## Hybrid search — vector + BM25 + trigram

Pure vector misses exact-keyword matches (ISBNs, error codes). Combine:
1. Vector similarity (pgvector).
2. Full-text BM25-ish (`tsvector` + `to_tsquery`).
3. Trigram (`pg_trgm`) for fuzzy keyword.

Weight by app-specific tuning on a labeled eval set, or use RRF (Reciprocal Rank Fusion) for parameter-free fusion. See the [pgvector](/stacks/supabase/pgvector/) page for the full query shape.

## Multi-tenant AI = RLS, not app filter

A common mistake: build single-tenant RAG, then "make it multi-tenant" by adding a tenant_id filter in the Edge Function. The filter is forgettable; RLS isn't.

```sql
alter table public.embeddings enable row level security;

create policy "users access their org embeddings" on public.embeddings
  for select using ( org_id in (select public.user_orgs()) );
```

Then `select * from embeddings where embedding <=> $1` from a JWT-authenticated user automatically filters to their org. The match function (`security invoker`) inherits this.

## Agent memory pattern

```sql
create table public.agent_memory (
  id bigserial primary key,
  user_id uuid not null,
  agent_id text not null,
  memory_type text not null,
  content text not null,
  embedding halfvec(1536),
  metadata jsonb default '{}',
  created_at timestamptz default now(),
  importance int default 1
);

create index agent_memory_user_idx on public.agent_memory (user_id, agent_id);
create index agent_memory_hnsw on public.agent_memory using hnsw (embedding halfvec_cosine_ops);
```

Retrieval combines similarity + recency + importance:

```sql
select id, content,
  (0.5 * (1 - (embedding <=> $1)))
  + (0.3 * exp(-extract(epoch from now() - created_at) / 86400.0))
  + (0.2 * importance / 10.0) as score
from public.agent_memory
where user_id = $2 and agent_id = $3
order by score desc
limit 10;
```

Cap `importance` at 10 to keep scale stable.

## Cost shape

| Surface | Driver |
|---------|--------|
| Compute (Postgres + Edge Functions) | Storage + Postgres tier; Edge invocations cheap |
| Embedding API | Per-token, per-call — **big one for ingestion** |
| Model inference | Per-token in + out — **big one for queries** |
| Storage | Vector index size; halfvec halves it |
| Egress | Streaming model responses through Edge Functions |

Cost levers in order of impact:
1. Cache aggressively (embeddings, query results).
2. halfvec, not vector.
3. Right-size model per task.
4. Batch embedding calls.
5. Tune HNSW `ef_search` (lower if rate-limited).

## 2025-2026 platform reset relevant to ai-ml-engineer

- **HNSW + halfvec** is the 2026 default vector setup. IVFFlat is legacy.
- **`sparsevec`** for SPLADE / learned sparse retrieval is stable.
- **Realtime Authorization** matters when streaming partial completions over Broadcast.
- **Edge Functions support background tasks + ephemeral storage** for moderate batch ingestion.
- **Custom Access Token Hook** (via [Supabase Auth](/stacks/supabase/supabase-auth/)) can inject org_id into JWT — useful for cheap multi-tenant RLS on embedding tables.
- **MCP server** + `--read-only` for agent-driven schema exploration.

## Patterns the role applies

### TDD on retrieval quality

Build a small labeled eval set (queries + expected document IDs); run in CI. Score with recall@K and MRR. Every change to chunking, embedding model, index params, hybrid weights goes through the eval. **Without an eval, "the RAG works" is unfalsifiable.**

### Verification

Before claiming "RAG works for org isolation": run impersonation tests (see [security-engineer](/stacks/supabase/security-engineer/)) on the embeddings table AND on the match function. Two impersonated users should see disjoint results.

Before claiming "retrieval is fast": show `EXPLAIN ANALYZE` for the query shape with the HNSW index used (`Index Scan using documents_embedding_hnsw_idx`).

### Debugging

**"Retrieval returns nothing."**
- Most likely: RLS filters to zero rows. Embedding table missing org_id, or user's JWT missing the org_id custom claim.
- Test: run as service_role. If results come back, RLS is the issue.

**"Retrieval is slow."**
- HNSW index not being used. Causes:
  - Additional filters make seq scan win. Try `set local enable_seqscan = off;` to confirm.
  - `ef_search` too low — bump it.
  - Embedding column is `vector` but index on `halfvec` (or vice versa).
  - Index op-class doesn't match query operator (HNSW on `vector_l2_ops` won't help a `<=>` cosine query).

**"Retrieval quality is bad."**
- Query-time embedding model ≠ ingestion-time model (orthogonal vector spaces).
- halfvec precision loss at the edges.
- Chunking too small / too large.
- Try a reranker.

## What about LLM-driven SQL?

Supabase Studio's AI assistant + the MCP server expose this. From engineering's seat:
- **Never let user-controlled input reach an LLM generating SQL against prod.** Prompt-injection-as-SQL-injection.
- For internal/admin use, route through a sandbox / staging branch.
- Audit LLM-generated SQL like any other SQL — `EXPLAIN ANALYZE`, run against test data, PR review.

## Cross-references

- [backend-architect](/stacks/supabase/backend-architect/) — Edge Functions for orchestration
- [database-architect](/stacks/supabase/database-architect/) — pgvector schema from a DBA seat
- [security-engineer](/stacks/supabase/security-engineer/) — RLS on embeddings + `security definer` functions
- [frontend-architect](/stacks/supabase/frontend-architect/) — streaming AI endpoints
- For model selection / fine-tuning → external LLM Stack (Anthropic, OpenAI)
- [Supabase Stack index](/stacks/supabase/) — what changed in 2025-2026
