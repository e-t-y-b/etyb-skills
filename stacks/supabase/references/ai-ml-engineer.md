---
role: ai-ml-engineer
stack: supabase
last_verified_on: "2026-05-14"
---

# Supabase Overlay — ai-ml-engineer

You are ai-ml-engineer on a Supabase engagement. Your surface here is narrower than on AWS or GCP — there are no managed training jobs, no model registry, no Vertex/Bedrock equivalent. What Supabase gives you is **`pgvector` as a first-class vector store**, **Edge Functions as your orchestration runtime**, and **the rest of Postgres** for the data that turns embeddings into useful retrieval. That combination is enough to build production RAG, semantic search, recommendations, and lightweight agent backends — and a lot of teams overbuild around it.

**Currency:** verified against Supabase docs + `pgvector` 0.7-0.8 (HNSW + `halfvec` + `sparsevec` stable) through **2026-05-14**.

## What you build on Supabase, what you don't

| Build on Supabase | Build elsewhere (call from Edge Functions) |
|-------------------|---------------------------------------------|
| Embedding storage + vector search (pgvector) | Embedding generation (OpenAI / Voyage / Cohere / Anthropic) |
| Hybrid search (vector + BM25 + trigram) | Foundation model inference (Anthropic / OpenAI / Bedrock / Vertex) |
| Retrieval-augmented generation orchestration | Fine-tuning (HuggingFace, OpenAI fine-tunes, AWS Bedrock custom models) |
| Lightweight feature store (Postgres tables) | Heavyweight feature stores (Tecton, Feast) |
| Agent state + memory (Postgres + Realtime) | Agent frameworks (LangChain / LangGraph / Mastra) — they call Supabase |
| Auth-bound multi-tenant AI (RLS gates which user sees which embeddings) | Image / audio model serving (Replicate, Modal, fal) |

The rule: **Supabase is the data plane**. Models, model gateways, fine-tuning runs, and GPU jobs live elsewhere. Edge Functions stitch them together; pgvector is where the embeddings come to rest.

## pgvector — the core skill

Source: [pgvector on GitHub](https://github.com/pgvector/pgvector). Enabled in Supabase via the Extensions UI; no special install.

### The three vector types you can use

```sql
create extension if not exists vector;

create table public.documents (
  id bigserial primary key,
  org_id uuid not null,
  content text not null,
  embedding vector(1536),          -- float32 — 1536 dims, e.g., OpenAI text-embedding-3-small
  embedding_half halfvec(1536),    -- float16 — half storage cost, ~negligible recall loss
  embedding_sparse sparsevec(30000) -- sparse — for BM25-like models (SPLADE, ColBERT-style)
);
```

- **`vector(N)`** — 32-bit floats, N dimensions. Default for OpenAI/Anthropic-style dense embeddings.
- **`halfvec(N)`** — 16-bit floats, half the storage, recall loss is typically <1%. Use as default unless you have a specific reason for full precision.
- **`sparsevec(N)`** — sparse representation with N dimensions and explicit zeros. For SPLADE, BGE-M3 sparse, learned sparse retrieval.

**For 1M+ vectors**, halfvec is almost always the right choice. It cuts storage and memory in half, makes the HNSW index smaller, and the recall impact is invisible in most downstream metrics.

### Distance operators

| Operator | Distance | When |
|----------|----------|------|
| `<->` | L2 (Euclidean) | Rare in modern embedding workflows |
| `<=>` | Cosine | **The default** for OpenAI/Anthropic/Voyage/Cohere embeddings |
| `<#>` | Negative inner product | When the embeddings are normalized to unit length AND you want IP semantics |

If you don't know, use cosine (`<=>`). It's what every major embedding API returns embeddings appropriate for.

### Indexes — HNSW vs IVFFlat

```sql
-- HNSW (default; better recall, larger index, slower build)
create index documents_embedding_hnsw_idx
  on public.documents using hnsw (embedding vector_cosine_ops)
  with (m = 16, ef_construction = 64);

-- IVFFlat (older; smaller index, cheaper build, needs tuning)
create index documents_embedding_ivf_idx
  on public.documents using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);
```

**HNSW** is the default since pgvector 0.5+. Tuning:
- `m` — graph degree. Default 16. Higher = better recall, more memory, longer build.
- `ef_construction` — build-time search width. Default 64. Higher = better recall, longer build.
- At query time, set `ef_search` per session: `set hnsw.ef_search = 100;` — higher = better recall, slower query.

**IVFFlat** is older but still useful for very large corpora (>50M vectors) where HNSW build time becomes prohibitive. Tuning:
- `lists` — number of clusters. Heuristic: `lists ≈ sqrt(rows)`. For 1M rows, ~1000 lists.
- At query time, set `ivfflat.probes = 10;` — number of clusters to search. Higher = better recall, slower query.

**Decision rule**: HNSW under 10M vectors, halfvec embeddings. IVFFlat only when HNSW build time is intolerable. `pgvectorscale` (the Timescale extension) is NOT on Supabase managed — don't recommend it.

### The retrieval pattern

```sql
-- Top-K nearest neighbors with metadata filter (RLS-gated)
select id, content, 1 - (embedding <=> $1) as similarity
from public.documents
where org_id = $2          -- RLS filter or explicit predicate
order by embedding <=> $1   -- cosine distance
limit 10;
```

The `1 - (embedding <=> $1)` converts distance to similarity for display. RLS on `documents` automatically scopes the query to the user's accessible rows.

### Hybrid search — combine vector + BM25 + trigram

Pure vector search misses exact-keyword matches ("ISBN 978-..."). Hybrid search combines:

1. **Vector similarity** (pgvector) — semantic.
2. **Full-text (tsvector + BM25-ish ranking)** — keyword.
3. **Trigram (`pg_trgm`)** — fuzzy keyword.

```sql
create extension if not exists pg_trgm;

alter table public.documents
  add column ts tsvector generated always as (to_tsvector('english', content)) stored;

create index documents_ts_idx on public.documents using gin (ts);
create index documents_content_trgm_idx on public.documents using gin (content gin_trgm_ops);

-- Hybrid query:
with vec as (
  select id, 1 - (embedding <=> $1) as vec_score
  from public.documents
  order by embedding <=> $1
  limit 50
),
fts as (
  select id, ts_rank_cd(ts, plainto_tsquery('english', $2)) as fts_score
  from public.documents
  where ts @@ plainto_tsquery('english', $2)
  order by fts_score desc
  limit 50
)
select d.id, d.content,
  coalesce(vec.vec_score, 0) * 0.6 + coalesce(fts.fts_score, 0) * 0.4 as score
from public.documents d
left join vec on d.id = vec.id
left join fts on d.id = fts.id
where vec.id is not null or fts.id is not null
order by score desc
limit 10;
```

The weights (0.6 / 0.4 here) are app-specific; tune on a labeled dev set. Reciprocal Rank Fusion (RRF) is a parameter-free alternative — average the inverse ranks across retrievers.

## RAG patterns on Supabase

### The skeleton

1. **Ingest**: chunk documents → embed → store in pgvector with metadata.
2. **Retrieve**: embed query → pgvector top-K → optional rerank.
3. **Generate**: stuff top-K into a prompt → call model via Edge Function → stream back.

### Ingestion via Edge Function

```ts
// supabase/functions/ingest-document/index.ts
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // bypasses RLS for ingestion
  );

  const { document_id, content, org_id } = await req.json();
  const chunks = chunkText(content, 1000, 200); // 1000-char chunks, 200 overlap

  // Embed all chunks in one API call
  const embeddings = await embedBatch(chunks, "text-embedding-3-small");

  const rows = chunks.map((text, i) => ({
    document_id,
    org_id,
    chunk_index: i,
    content: text,
    embedding: embeddings[i],
  }));

  const { error } = await supabase.from("document_chunks").insert(rows);
  if (error) return new Response(error.message, { status: 500 });
  return new Response("ok");
});

function chunkText(text: string, size: number, overlap: number): string[] {
  // ... naive char-based chunker; replace with semantic chunker for production.
}

async function embedBatch(texts: string[], model: string): Promise<number[][]> {
  const r = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ input: texts, model }),
  });
  const { data } = await r.json();
  return data.map((d: any) => d.embedding);
}
```

Notes:
- Use service role here because ingestion is an admin operation. Trigger this from a Queue + Cron, not directly from user input.
- Batch embeddings — embedding APIs charge per request and per token; batch up to the API's max (OpenAI: 100, Voyage: 100).
- Store the org_id alongside chunks so RLS on `document_chunks` can gate retrieval.

### Retrieval + generation Edge Function

```ts
// supabase/functions/rag-query/index.ts
Deno.serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });

  const { query } = await req.json();

  // 1. Embed query
  const [queryEmbedding] = await embedBatch([query], "text-embedding-3-small");

  // 2. Vector retrieval (RLS auto-scopes to user's org)
  const { data: chunks, error } = await supabase.rpc("match_document_chunks", {
    query_embedding: queryEmbedding,
    match_count: 10,
  });
  if (error) return new Response(error.message, { status: 400 });

  // 3. Stuff into prompt
  const context = chunks.map((c: any) => c.content).join("\n---\n");
  const prompt = `Answer using only the context below.\n\n${context}\n\nQuestion: ${query}`;

  // 4. Stream from Anthropic / OpenAI
  const stream = await callModelStreaming(prompt);
  return new Response(stream, {
    headers: { "Content-Type": "text/event-stream" },
  });
});
```

And the SQL function (defined once, used per query):

```sql
create or replace function public.match_document_chunks(
  query_embedding vector(1536),
  match_count int default 10
)
returns table (
  id bigint,
  content text,
  similarity float
)
language sql
stable
security invoker -- RLS applies
as $$
  select id, content, 1 - (embedding <=> query_embedding) as similarity
  from public.document_chunks
  order by embedding <=> query_embedding
  limit match_count
$$;
```

`security invoker` is critical here — without it, the function bypasses RLS and the caller can retrieve chunks from other orgs.

### Reranking — when it earns its keep

If retrieval quality matters more than latency (analyst tools, legal search, support search):

```ts
// After pgvector retrieval, rerank top 50 → top 10
const top50 = await retrieve(query, 50);
const top10 = await rerank(query, top50, "cohere-rerank-v3");
```

Rerankers (Cohere, Voyage, Jina) score query-document pairs more accurately than dense similarity. They add 200-500ms of latency. The right pattern: vector retrieve K=50, rerank to K=10, generate.

Reranking on Supabase = call the reranker API from the Edge Function. Don't try to run reranker models in Postgres.

## Vector schema patterns

### One big table vs partitioned

For <10M vectors per tenant, one table with RLS scoping works:

```sql
create table public.embeddings (
  id bigserial primary key,
  org_id uuid not null,
  source_type text not null,        -- 'document', 'message', 'product', ...
  source_id uuid not null,
  embedding halfvec(1536) not null,
  metadata jsonb not null default '{}'
);

create index embeddings_org_id_idx on public.embeddings (org_id);
create index embeddings_hnsw_idx on public.embeddings using hnsw (embedding halfvec_cosine_ops);
```

For >100M vectors, consider partitioning by `source_type` or by org_id range. The HNSW index doesn't natively partition — each partition has its own index, and queries fan out. Plan capacity.

### Metadata in jsonb, indexable

```sql
-- For filters like "embeddings tagged 'reviewed' from after 2025-01-01":
create index embeddings_metadata_idx on public.embeddings using gin (metadata jsonb_path_ops);

-- Query:
select * from public.embeddings
where org_id = $1
  and metadata @> '{"reviewed": true}'
  and metadata->>'created_at' > '2025-01-01'
order by embedding <=> $2
limit 10;
```

GIN on jsonb is necessary for `@>` containment. For range filters on a jsonb field, consider expression indexes or materialize the field into a column.

### Re-embedding strategy

Embedding models update. You'll need to re-embed your corpus eventually. Two approaches:

1. **In-place re-embed**: keep one `embedding` column, run a backfill that overwrites in batches. Downtime risk if a query hits a row mid-rewrite.
2. **Side-by-side**: add `embedding_v2` column, backfill it, swap reads to `v2`, drop `v1`. Safer for production.

Always include the model name + version in metadata so you know what generated each vector:

```sql
metadata = '{"model": "text-embedding-3-small", "version": "v1"}'
```

## Edge Functions for AI — operational rules

1. **Stream model responses.** Don't wait for the full completion; return SSE or Anthropic's streaming format. Users perceive latency on first-token, not on last-token.
2. **Cache embeddings.** Same query → same embedding. Hash the query, check a cache table or KV, skip the embedding call.
3. **Cap retrieval cost.** Top-K = 10 is fine; top-K = 100 to "be safe" is wasted tokens.
4. **Don't pass raw retrieval results to the model.** Truncate, dedupe, format. Bigger prompt ≠ better answer.
5. **Log every call.** Prompt, retrieved chunks (or hashes), model used, tokens, latency, user. This is your training data for prompt iteration AND your auditability surface.
6. **Use the right model for the job.** A reranker isn't a generator. A fast/cheap model for routing isn't your generation model. Don't pay Claude Opus prices for a topic-classification task.
7. **Set per-user rate limits.** AI features are abuse magnets — implement at the Edge Function level (a tracking table + early return) or via a CDN rate limit.

## Cost shape

Where the money goes on a Supabase RAG app:

| Surface | Cost driver |
|---------|-------------|
| Compute (Postgres + Edge Functions) | Mostly storage + Postgres tier; Edge Function invocations are cheap. |
| Embedding API | Per-token, per-call. **The big one for ingestion**. |
| Model inference | Per-token in + out. **The big one for queries**. |
| Storage | Vector index size. halfvec halves it. |
| Egress | Streaming model responses through Edge Functions adds outbound bytes. |

The cost lever in order of impact:
1. **Cache aggressively** (embeddings, query results).
2. **Use halfvec, not vector.**
3. **Right-size the model** per task (router → small, generator → larger only where needed).
4. **Batch embedding calls.**
5. **Tune HNSW `ef_search`** — lower at the cost of recall if you're rate-limited.

## Multi-tenancy + AI = use RLS

A common mistake: build a single-tenant RAG, then "make it multi-tenant" by adding a tenant_id filter in the Edge Function. The filter is forgettable; RLS isn't.

```sql
-- The right shape:
alter table public.embeddings enable row level security;

create policy "users access their org embeddings" on public.embeddings
  for select using (
    org_id in (select public.user_orgs())
  );
```

Then `select * from embeddings where embedding <=> $1` from a JWT-authenticated user automatically filters to their org. The match function (`security invoker`) inherits this.

## Agent + memory patterns

For an agentic loop where the agent has persistent memory:

```sql
create table public.agent_memory (
  id bigserial primary key,
  user_id uuid not null,
  agent_id text not null,
  memory_type text not null,        -- 'fact', 'preference', 'goal', 'episode'
  content text not null,
  embedding halfvec(1536),
  metadata jsonb default '{}',
  created_at timestamptz default now(),
  importance int default 1
);

create index agent_memory_user_idx on public.agent_memory (user_id, agent_id);
create index agent_memory_hnsw on public.agent_memory using hnsw (embedding halfvec_cosine_ops);
```

The retrieval pattern: at each agent step, retrieve the top-K memories most similar to the current input AND most recent / important. Combine vector similarity with recency / importance scores:

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

The weights are tunable. Cap `importance` at 10 to keep the formula scale-stable.

## What about LLM-driven SQL?

Supabase's AI assistant in Studio generates SQL from natural language. The MCP server exposes the same capability to external agents. From an engineer's seat:

- **Never let user-controlled inputs reach an LLM that generates SQL against your prod DB.** That's prompt-injection-as-SQL-injection.
- **For internal/admin use, route through a sandbox or staging branch.** Database Branches are ideal here.
- **Audit LLM-generated SQL like any other SQL** — `EXPLAIN ANALYZE`, run against test data, PR review.

## Cross-references

- **pgvector schema choices, index tuning from a DBA seat** → [database-architect overlay](database-architect.md)
- **Edge Function runtime, streaming, secrets** → [backend-architect overlay](backend-architect.md)
- **RLS on embeddings + security definer functions** → [security-engineer overlay](security-engineer.md)
- **Frontend wiring to streaming AI endpoints** → [frontend-architect overlay](frontend-architect.md)
- **For model selection / fine-tuning** → Anthropic Claude or OpenAI stack pack

## Integration with always-on protocols

### TDD on retrieval quality

Build a small labeled eval set (queries + expected document IDs) and run it in CI. Score with recall@K and MRR. Any change to chunking, embedding model, index params, hybrid weights goes through the eval. Without an eval, "the RAG works" is unfalsifiable.

### Verification

Before claiming "the RAG works for org isolation": run the impersonation test from the [security-engineer overlay](security-engineer.md) on the embeddings table AND on the match function. Two different impersonated users should see disjoint results.

Before claiming "the retrieval is fast": show `EXPLAIN ANALYZE` for the actual query shape with the HNSW index being used (look for `Index Scan using documents_embedding_hnsw_idx`).

### Debugging

Symptom: "retrieval returns nothing."
- Most likely: RLS is filtering to zero rows because the embedding table doesn't have the right org_id, or the user's JWT is missing the org_id custom claim.
- Test: run the same query as service_role; if it returns results, RLS is the issue.

Symptom: "retrieval is slow."
- The HNSW index isn't being used. Causes:
  - The query has additional filters that the planner thinks make seq scan faster. Try `set local enable_seqscan = off;` temporarily to confirm.
  - `ef_search` is too low. Bump it.
  - The embedding column is `vector` but the index was created on `halfvec` (or vice versa). Match types.
  - The op class in the index doesn't match the query operator (HNSW on `vector_l2_ops` won't help a `<=>` cosine query).

Symptom: "retrieval quality is bad."
- Verify the embedding model used at query time matches the one used at ingestion time. Two different models = orthogonal vector spaces.
- Verify halfvec hasn't lost precision in a way that matters for your domain (rare, but possible at the edges).
- Check chunking — chunks too small lose context; too large dilute the embedding.
- Try a reranker on top of the vector retrieval.
