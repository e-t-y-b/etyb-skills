---
title: Azure AI Search
description: Renamed from Azure Cognitive Search (2023). Vector + hybrid search, semantic ranker, integrated vectorization (auto-embed via Azure OpenAI). Default for doc-search RAG.
product:
  name: Azure AI Search
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, database-architect]
  authoritative_url: https://learn.microsoft.com/azure/search/
  notes: "Renamed from Cognitive Search 2023; integrated vectorization GA; semantic ranker stable."
---

## What it is

Azure AI Search is Microsoft's managed search service — built-in chunking, vector indexes (HNSW), semantic ranker, integrated vectorization (auto-embed via Azure OpenAI), hybrid retrieval (vector + keyword + facet). Renamed from Azure Cognitive Search in 2023. Canonical reference: [AI Search docs](https://learn.microsoft.com/azure/search/).

## When to use

Pick AI Search when:

- **Doc-search-heavy RAG** — the default for "documents in, search results out, RAG over them."
- **Hybrid retrieval** — vector + keyword + semantic ranker outperforms pure vector for queries with named entities / exact phrases.
- **Integrated vectorization** — skip writing chunking + embedding pipeline code.

Pick [Cosmos DB DiskANN](/stacks/azure/cosmos-db/) when vectors live alongside operational data with multi-region writes. Pick [PostgreSQL Flex + pgvector](/stacks/azure/postgresql-flexible-server/) when already on Postgres.

## 2025-2026 currency anchors

- **Renamed from Azure Cognitive Search** (2023).
- **Integrated vectorization GA** — AI Search pulls from data source → chunks → calls Azure OpenAI for embeddings → indexes. No pipeline code.
- **Semantic ranker** — re-ranks initial retrieval results using a multilingual deep learning model.
- **Vector + hybrid search** — combine vector distance with keyword and semantic ranking in one query.
- **Index design**: vector field (HNSW, cosine, 1536-dim for text-embedding-3-large), searchable text fields for keyword, filter fields for facet, semantic configuration for ranker.
- **Scale**: indexes to billions of vectors.

## Patterns + anti-patterns

### Pattern: Hybrid retrieval (vector + keyword + semantic ranker)

Almost always beats pure vector. Especially for queries with named entities or exact phrases.

```json
{
  "search": "user query text",
  "vectorQueries": [
    { "kind": "text", "text": "user query text", "fields": "embedding", "k": 50 }
  ],
  "queryType": "semantic",
  "semanticConfiguration": "default",
  "top": 10
}
```

Sends: keyword search + text auto-embedded into vector query + semantic ranking + return top 10. One call.

### Pattern: Integrated vectorization for hands-off RAG

Configure vectorizer in index spec:

```json
{
  "vectorSearch": {
    "vectorizers": [{
      "name": "myAzureOpenAI",
      "kind": "azureOpenAI",
      "azureOpenAIParameters": {
        "resourceUri": "https://...openai.azure.com",
        "deploymentId": "text-embedding-3-large",
        "modelName": "text-embedding-3-large"
      }
    }]
  }
}
```

Data source → AI Search auto-chunks → auto-embeds → indexes.

### Pattern: Filter then vector for tenancy / scope

`WHERE category eq 'public'` reduces vector search space dramatically — much cheaper.

### Anti-pattern: Vector-only retrieval

Hybrid almost always wins. Don't skip the keyword + semantic ranker.

### Anti-pattern: Standalone Pinecone / Qdrant / Weaviate when AI Search fits

Pay for what the platform offers.

### Anti-pattern: Building chunking + embedding pipeline by hand when integrated vectorization fits

You're re-implementing what Microsoft maintains.

## Gotchas

- **Index storage cost** — vectors consume more than text; size with embedding dimensions in mind (1536 vs 3072 makes a material difference at billions of docs).
- **Semantic ranker** is region-restricted to specific regions; verify availability.
- **Integrated vectorization** uses Azure OpenAI capacity (TPM) — plan PTU/Standard accordingly.
- **Custom analyzers** for non-English content; test before committing.

## Cross-references

- [Cosmos DB](/stacks/azure/cosmos-db/) — DiskANN alternative
- [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) — pgvector alternative
- [Azure OpenAI](/stacks/azure/azure-openai/) — embedding source for integrated vectorization
- [Foundry Agents](/stacks/azure/foundry-agents/) — AI Search as tool source
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — RAG retrieval design
- [Database Architect on Azure](/stacks/azure/database-architect/) — vector store selection
- [Azure AI Search](https://learn.microsoft.com/azure/search/)
- [Integrated vectorization](https://learn.microsoft.com/azure/search/vector-search-integrated-vectorization)
