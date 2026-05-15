---
title: AI Search
description: Cloudflare's managed RAG pipeline over R2 docs — chunks, embeds via Workers AI, stores in Vectorize, exposes a search endpoint. Renamed from AutoRAG in 2025.
product:
  name: AI Search
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://developers.cloudflare.com/ai-search/
  notes: "Renamed from AutoRAG in 2025; managed RAG pipeline on R2 + Vectorize + Workers AI."
---

## What it is

AI Search (formerly AutoRAG) is Cloudflare's managed RAG-as-a-product. You point it at an [R2](/stacks/cloudflare/r2/) bucket; it chunks documents, embeds them with [Workers AI](/stacks/cloudflare/workers-ai/), stores embeddings in [Vectorize](/stacks/cloudflare/vectorize/), and exposes a search endpoint. Less control than DIY RAG; far less code.

Authoritative reference: [developers.cloudflare.com/ai-search](https://developers.cloudflare.com/ai-search/).

## When to use

- **Docs in R2, want managed RAG, OK with managed indexing cadence.** A weekend RAG over your customer support docs, internal wiki, public FAQs.
- **You don't need custom chunking or rerankers.**
- **You want to add RAG without standing up a retrieval pipeline.**

Don't use AI Search when:

- **You want full control over chunking, embedding, reranking, prompts** — DIY with Worker + R2 + Vectorize + Workers AI.
- **You need custom rerankers or multi-vector retrieval** — DIY.
- **Hybrid search (BM25 + vector)** — external or DIY.

## 2025-2026 currency anchors

- **Renamed from AutoRAG to AI Search in 2025.** Same product, same architecture, new branding. Code/docs/console all use "AI Search" now.
- **If you say "AutoRAG" to a Cloudflare account team in 2026 they'll know what you mean**, but flag the rename in any current architecture doc.

## Patterns

### AI Search binding

```toml
[[ai_search]]
binding = "AI_SEARCH"
name = "my-ai-search"
```

```ts
const r = await env.AI_SEARCH.aiSearch({
  query: "what is the refund policy",
  max_num_results: 5,
  // optional rewrite_query, ranking_options, etc.
});
return Response.json({ answer: r.response, sources: r.data });
```

### Configure the source bucket

Create an AI Search instance in the dashboard pointing at an R2 bucket. The bucket gets indexed (chunked, embedded with Workers AI, stored in Vectorize) on a cadence Cloudflare manages.

### When to graduate to DIY RAG

When you outgrow AI Search:

- Custom chunking strategy (overlap, semantic boundaries, hierarchical).
- Custom reranker (cross-encoder, LLM-as-judge).
- Tenant-aware filtering beyond what AI Search exposes.
- Multi-step retrieval (hypothetical-document expansion, query rewriting with multiple variants).

See the DIY RAG pattern in the [ai-ml-engineer overlay](/stacks/cloudflare/ai-ml-engineer/).

## Anti-patterns

- **Saying "AutoRAG"** in net-new doc/code — use "AI Search."
- **Mixing AI Search and DIY in one Worker** without clear ownership — pick one path per retrieval surface.
- **No tenant isolation** — if AI Search is queryable across tenants, you have a data leakage problem. Use separate instances per tenant or constrain at the calling layer.

## Gotchas

1. **Indexing cadence is managed** — newly-added docs aren't searchable instantly.
2. **Cost is composite** — underlying R2 + Vectorize + Workers AI costs all apply.
3. **Source files in R2 must be in supported formats** — verify against current docs.
4. **Rename surface area** — old `AutoRAG`-named bindings/config may still work but the canonical name is AI Search.

## Cross-references

- [R2](/stacks/cloudflare/r2/) — source bucket for documents
- [Vectorize](/stacks/cloudflare/vectorize/) — embedding storage under the hood
- [Workers AI](/stacks/cloudflare/workers-ai/) — embedding model under the hood
- [AI Gateway](/stacks/cloudflare/ai-gateway/) — LLM calls that consume retrieval results
- Role overlay: [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/)
- Authoritative: [developers.cloudflare.com/ai-search](https://developers.cloudflare.com/ai-search/)
