---
title: Embeddings
description: "text-embedding-3-large / -small. Matryoshka representation — truncate to fewer dimensions via the `dimensions` parameter without retraining."
product:
  name: Embeddings
  stack: openai
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/embeddings
  notes: "text-embedding-3 generation stable since 2024; Matryoshka via `dimensions` is the key feature; -ada-002 is legacy."
---

## What it is

Embeddings convert text into a fixed-length vector (a list of floats). Two production models:

- **text-embedding-3-large** — 3072 default dimensions. Highest quality.
- **text-embedding-3-small** — 1536 default dimensions. Budget default.

Both support the **`dimensions`** parameter (Matryoshka representation) — you can truncate to 1024 / 512 / 256 / 128 dims **without retraining** and retain most quality.

**text-embedding-ada-002** is legacy. Don't pick it for new work.

Reference: [Embeddings guide](https://platform.openai.com/docs/guides/embeddings).

## When to use

**Use embeddings when:**

- Building semantic search / retrieval (RAG).
- Clustering similar documents.
- Recommendations based on content similarity.
- Semantic deduplication.
- Classification via nearest-neighbor in embedding space.

**Use text-embedding-3-small for:**

- Most RAG workloads. Quality is excellent for the cost.

**Use text-embedding-3-large for:**

- The 5-10% of cases where -small misses on retrieval quality and your eval shows -large wins.

**Don't pick -ada-002** for new work — it's legacy.

## 2025-2026 currency anchors

- **text-embedding-3-large** — 3072 default dims. Supports `dimensions` parameter.
- **text-embedding-3-small** — 1536 default dims. Supports `dimensions` parameter.
- **Matryoshka representation** is the key 2024-onwards feature. Smaller dims = lower storage + faster ANN + slightly lower recall.
- **`text-embedding-ada-002` is legacy.** Existing pipelines run; new pipelines don't pick it.
- **Embeddings via [Batch API](/stacks/openai/batch-api/)** is 50% off for refresh runs.

## Patterns

### Pattern: pick dimensions

`text-embedding-3-large` defaults to 3072 dims. **Almost never use the default in production.** Storage is 3x more than necessary; ANN index size is 3x; query latency is higher.

| Dimensions | Use case |
|---|---|
| **256** | High-volume + low-recall-tolerance (recommendations, semantic dedup, fuzzy clustering). |
| **512** | Balanced default for most RAG; slight quality loss vs full but huge storage gain. |
| **1024** | High-quality RAG; the sweet spot for serious search. |
| **1536** | Full quality of -small / strong -large; rare to need more. |
| **3072** | -large full quality; budget for storage. |

```python
emb = client.embeddings.create(
    model="text-embedding-3-large",
    input=text,
    dimensions=1024,
).data[0].embedding
```

### Pattern: hybrid search

Embeddings alone underperform vs hybrid (BM25 + dense). For production RAG, run both and combine with Reciprocal Rank Fusion (RRF). Then add a reranker (Cohere Rerank, BGE-reranker) on the top-50 to top-100 candidates.

This is platform-neutral RAG hygiene; OpenAI doesn't ship a reranker — you bring one.

### Pattern: batch refresh

For initial corpus embedding + periodic refresh, use [Batch API](/stacks/openai/batch-api/) — 50% off, 24h SLA, perfect for non-interactive bulk.

### Pattern: vector store choice

You have two main options on OpenAI for RAG:

1. **[OpenAI Vector Stores](/stacks/openai/built-in-tools/)** (via `file_search` built-in tool) — managed; created via Files + Vector Stores APIs. Best for v0.
2. **Bring your own vector DB** — pgvector, Pinecone, Qdrant, Weaviate, Milvus. Best when you need hybrid search, custom chunking, custom rerankers, advanced metadata filtering.

Ship v0 on `file_search`. Migrate when eval scores plateau or retrieval-side requirements outgrow the managed surface.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Defaulting to text-embedding-3-large at 3072 dims | Truncate via `dimensions` to 1024 unless eval demands more. |
| Picking text-embedding-ada-002 for new work | Use text-embedding-3-small or -large. |
| Embeddings-only search (no BM25) | Hybrid (BM25 + dense + reranker). |
| Embedding refresh on sync API | Use [Batch API](/stacks/openai/batch-api/) — 50% off. |
| Not measuring dim-truncation impact on your eval | Eval-test 256/512/1024/1536/3072 on your workload before committing. |
| Treating embeddings as semantically equivalent across models | Don't mix embedding models in the same index. Pick one + commit. |

## Gotchas

- **Re-embedding when you change models.** If you switch from -small to -large, every vector in your index needs re-embedding.
- **Matryoshka truncation** preserves most quality but not all — eval-test at your chosen dim.
- **Cosine similarity** is the standard distance metric. L2 also works on normalized vectors.
- **Cost per token** — verify against [pricing](https://openai.com/api/pricing/).
- **Rate limits** — embedding endpoints have their own RPM / TPM limits per tier.
- **Input length limits** — chunk long documents before embedding.
- **Batch is the cheap path** for bulk; use it.
- **Embeddings + PII** — vectors don't reveal source text, but the index does (chunks are stored alongside vectors). Standard PII practices apply.

## Cross-references

### Related products in this Stack

- [Built-in tools](/stacks/openai/built-in-tools/) — `file_search` is OpenAI-hosted RAG built on embeddings.
- [Batch API](/stacks/openai/batch-api/) — bulk embedding refresh at 50% off.
- [Files API](/stacks/openai/files-api/) — vector store backing.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — RAG architecture + retrieval design.
- [backend-architect](/stacks/openai/backend-architect/) — embedding pipeline + vector store integration.

### Authoritative sources

- [Embeddings guide](https://platform.openai.com/docs/guides/embeddings)
- [OpenAI Pricing](https://openai.com/api/pricing/)
