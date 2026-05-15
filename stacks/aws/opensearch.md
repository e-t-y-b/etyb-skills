---
title: OpenSearch
description: AWS managed search and vector store — Serverless workload types (SEARCH / TIME_SERIES / VECTORSEARCH); zero-ETL from DynamoDB; default backend for many Bedrock Knowledge Bases.
product:
  name: OpenSearch
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer, backend-architect]
  authoritative_url: https://docs.aws.amazon.com/opensearch-service/
  notes: "Serverless workload types (SEARCH / TIME_SERIES / VECTORSEARCH); vector search matured 2025; default backend for many Bedrock Knowledge Bases."
---

## What it is

Amazon OpenSearch Service is the managed search engine — Elasticsearch-compatible (fork after 2021 licensing change), with first-class vector search, log analytics, time-series patterns. **OpenSearch Serverless** auto-scales capacity (OCUs).

Canonical surface: [docs.aws.amazon.com/opensearch-service](https://docs.aws.amazon.com/opensearch-service/).

## When to use

| Need | Use OpenSearch? |
|---|---|
| Full-text search | Yes |
| Vector search at scale (>10M vectors) | Yes — Serverless VECTORSEARCH |
| Log analytics (centralized logs) | Yes — Serverless TIME_SERIES |
| Smaller vector workloads (<10M, integrated with relational) | Use [Aurora pgvector](/stacks/aws/aurora/) |
| RAG without managing vector layer | Use [Bedrock Knowledge Bases](/stacks/aws/bedrock/) (uses OpenSearch Serverless or pgvector underneath) |
| Self-hosted / open-source | Qdrant / Weaviate / Pinecone alternatives |

## 2025-2026 currency anchors

- **OpenSearch Serverless workload types**: `SEARCH` (full-text), `TIME_SERIES` (logs/metrics), `VECTORSEARCH` (vector + hybrid).
- **Capacity paid as OCUs** (OpenSearch Compute Units).
- **Zero-ETL from [DynamoDB](/stacks/aws/dynamodb/)** for search/vector workloads.
- **Default backend for [Bedrock Knowledge Bases](/stacks/aws/bedrock/)**.
- **Vector search matured 2025** — kNN + hybrid (BM25 + vector) + reranking.

## Patterns

### Serverless vs Managed

| | Serverless | Managed |
|---|---|---|
| **Capacity** | Auto-scale OCUs | Provisioned cluster |
| **Use** | Variable load, new workloads | Steady load, full plugin ecosystem |
| **Workload types** | SEARCH / TIME_SERIES / VECTORSEARCH | Generic |

Default for new workloads: **Serverless**. Promote to Managed when steady load or specific plugins demand it.

### Vector search

```python
client.indices.create(
    index='documents',
    body={
        'mappings': {
            'properties': {
                'embedding': {
                    'type': 'knn_vector',
                    'dimension': 1024,
                    'method': {
                        'name': 'hnsw',
                        'space_type': 'cosinesimil',
                        'engine': 'faiss',
                    }
                },
                'text': {'type': 'text'},
            }
        }
    }
)

response = client.search(
    index='documents',
    body={
        'size': 5,
        'query': {'knn': {'embedding': {'vector': query_embedding, 'k': 5}}}
    }
)
```

### Hybrid search (BM25 + vector)

```json
{
  "query": {
    "hybrid": {
      "queries": [
        {"match": {"text": "refund policy damaged items"}},
        {"knn": {"embedding": {"vector": [...], "k": 50}}}
      ]
    }
  }
}
```

Hybrid combines BM25 keyword + vector kNN with configurable score weighting.

### Zero-ETL from DynamoDB

Enable on a DynamoDB table with Streams + PITR; OpenSearch indexes items continuously. Replaces custom replication Lambda.

### Index management

- **ISM (Index State Management)** — automated lifecycle (rollover → warm → cold → delete).
- **Snapshots** to S3 for backup.
- **Index aliases** for blue-green index swaps without downtime.

## Anti-patterns

- **OpenSearch managed for variable workloads.** Use Serverless.
- **Vector workloads with no reranking.** Top-50 kNN → rerank to top-5 dramatically improves precision.
- **Custom DynamoDB → OpenSearch Lambda.** Use zero-ETL.
- **Hand-managed cluster sizing.** Serverless handles it.
- **Index per-day for low-volume.** Wasted overhead.

## Gotchas

- **OCU pricing** can be high for low-volume — sometimes a small managed cluster is cheaper.
- **VECTORSEARCH workload type required** for kNN; not SEARCH.
- **Refresh interval** affects search latency vs indexing throughput.
- **Cross-region replication** requires snapshot + restore or third-party tooling.

## Cross-references

- [`/stacks/aws/bedrock/`](/stacks/aws/bedrock/) — Knowledge Bases use OpenSearch Serverless
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — zero-ETL source
- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — pgvector alternative
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; search + vector tier
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — role view; RAG patterns
- [OpenSearch Serverless docs](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/serverless.html)
