# Search Specialist -- Deep Reference

**Always use `WebSearch` to verify current search engine versions, features, and performance characteristics before giving advice. The search ecosystem evolves rapidly -- this reference reflects the state as of early 2026.**

## Table of Contents
1. [Search Engine Selection](#1-search-engine-selection)
2. [Elasticsearch (8.x / 9.x)](#2-elasticsearch-8x--9x)
3. [OpenSearch (2.x)](#3-opensearch-2x)
4. [Meilisearch (1.x)](#4-meilisearch-1x)
5. [Typesense (v27+)](#5-typesense-v27)
6. [Apache Solr](#6-apache-solr)
7. [Index Design](#7-index-design)
8. [Relevance Tuning](#8-relevance-tuning)
9. [Faceted Search](#9-faceted-search)
10. [Autocomplete and Suggestions](#10-autocomplete-and-suggestions)
11. [Hybrid Search](#11-hybrid-search)
12. [Scaling Search](#12-scaling-search)
13. [Search Observability](#13-search-observability)
14. [Search Infrastructure Patterns](#14-search-infrastructure-patterns)

---

## 1. Search Engine Selection

### Decision Matrix

| Criteria | Elasticsearch | OpenSearch | Meilisearch | Typesense | Apache Solr |
|----------|--------------|------------|-------------|-----------|-------------|
| **Best for** | Enterprise search, analytics, observability | AWS-native, fully open-source enterprise search | Developer-friendly instant search, small-to-mid datasets | Instant search with typo tolerance, developer UX | Legacy enterprise search, Hadoop/ECM integration |
| **Scaling** | Distributed, petabyte-scale | Distributed, petabyte-scale | Single-node (sharding via federated search in v1.13+) | Raft-based clustering, HA | Distributed (SolrCloud) |
| **Vector search** | kNN with HNSW, BBQ quantization | FAISS + nmslib, up to 16K dims | HNSW with binary quantization | Built-in S-BERT/E-5, OpenAI embeddings | Limited (dense vector via Lucene) |
| **Hybrid search** | Native RRF + linear combination | Neural search plugin + RRF (2.19+) | Semantic + full-text built-in | Semantic + keyword with re-ranking | Not native |
| **License** | AGPL v3 / SSPL / ELv2 (triple-licensed, Aug 2024) | Apache 2.0 (Linux Foundation, Sep 2024) | MIT | GPL v3 | Apache 2.0 |
| **Managed services** | Elastic Cloud, AWS (marketplace) | Amazon OpenSearch Service, Aiven | Meilisearch Cloud | Typesense Cloud | Solr on self-managed, SearchStax |
| **Query language** | Query DSL + ES\|QL (pipe-based) | Query DSL (Elasticsearch-compatible) | Simple REST parameters | Simple REST parameters | Lucene syntax + JSON API |
| **Latency** | 10-100ms typical | 10-100ms typical | <50ms (optimized for instant) | <50ms (C++ in-memory) | 10-100ms typical |
| **Learning curve** | Steep (most powerful) | Steep (similar to Elasticsearch) | Low (designed for simplicity) | Low (simple API) | Steep (XML config, complex tuning) |

### When to Choose Each

**Elasticsearch** -- choose when:
- You need the full analytics + search + observability platform
- Complex relevance tuning (function_score, LTR, semantic reranking) is required
- Data volume exceeds 1TB or you need multi-cluster federation
- Team has Elasticsearch expertise or is willing to invest in learning
- You need ES|QL for data exploration alongside search
- Hybrid search with production-grade RRF and vector quantization is critical

**OpenSearch** -- choose when:
- You're on AWS and want native integration (Amazon OpenSearch Service)
- Apache 2.0 licensing is a hard requirement (AGPL/SSPL unacceptable)
- You need a community-governed, fully open-source alternative
- Your workload is text-heavy search + aggregations (OpenSearch can be 1.6x faster on text workloads per Trail of Bits 2025 benchmark)
- You want FAISS-based vector search with up to 16K dimensions (vs Elasticsearch's 4,096 limit)

**Meilisearch** -- choose when:
- Developer experience and setup speed are priorities
- Dataset fits in single-node memory (up to ~10M documents typical)
- You need instant search with typo tolerance out of the box
- AI-powered search (hybrid semantic + keyword) with minimal configuration
- Federated search across multiple indexes or instances (v1.13+)
- Frontend-facing search for e-commerce, documentation, SaaS products

**Typesense** -- choose when:
- Sub-50ms search is non-negotiable (C++ engine, data in RAM)
- Typo tolerance by default is essential (enabled automatically)
- You want a drop-in Algolia replacement (InstantSearch.js adapter available)
- Geo search with polygon filtering is needed
- Built-in RAG / conversational search is desired
- Smaller datasets that fit in memory

**Apache Solr** -- choose when:
- Existing Solr infrastructure with years of tuning investment
- Deep Hadoop/HDFS integration is required
- Enterprise content management (ECM) platform integration (e.g., Alfresco)
- Your team has deep Solr expertise and no reason to migrate
- Note: Solr's DB-Engines score (32.40) is ~4x lower than Elasticsearch (128.08) as of 2025; declining mindshare makes new adoption harder

**PostgreSQL full-text search** -- choose when:
- Search is secondary functionality (<100K documents, simple queries)
- You want to avoid operational complexity of a separate search engine
- GIN indexes on tsvector columns are sufficient
- Basic ranking with ts_rank is acceptable
- Budget or team size doesn't support a dedicated search cluster

---

## 2. Elasticsearch (8.x / 9.x)

### Version Timeline

| Version | Release | Key Features |
|---------|---------|-------------|
| **8.12** | Feb 2024 | kNN as DSL query (not just search option), dense_vector improvements |
| **8.13** | Apr 2024 | Learning to Rank native integration (tech preview), ES\|QL GA |
| **8.14** | Jun 2024 | NEON SIMD for int8_hnsw, kNN query builder with modelId/modelText |
| **8.15** | Aug 2024 | `semantic_text` field + `semantic` query (tech preview), int4 scalar quantization, bit vectors with Hamming distance, `sparse_vector` query |
| **8.16** | Oct 2024 | BBQ (Better Binary Quantization) tech preview, logsdb index mode preview |
| **8.17** | Dec 2024 | logsdb GA (up to 65% storage reduction), Elastic Rerank model |
| **8.18** | Apr 2025 | BBQ GA (20% higher recall, 8-30x faster with SIMD), ColPali/ColBERT support via MaxSim |
| **9.0** | Apr 2025 | Same features as 8.18 + breaking changes (SecurityManager removed, AWS SDK v2, TLS_RSA ciphers removed) |
| **9.1** | 2025 | JOIN command in ES\|QL |
| **9.2** | 2025 | Dense vector search + hybrid search in ES\|QL (FORK + FUSE commands) |

### Licensing (Critical Change -- August 2024)

Elasticsearch and Kibana are now **triple-licensed**:
- **AGPL v3** -- OSI-approved open-source license (added August 29, 2024)
- **SSPL** -- Server Side Public License (since 2021)
- **Elastic License v2** -- Elastic's proprietary license (since 2021)

Users can choose any of the three licenses. The AGPL addition means Elasticsearch is officially "open source" again by OSI standards. This does not affect existing users on SSPL or ELv2, and binary distributions remain unchanged.

**Impact**: Organizations that avoided Elasticsearch due to the 2021 license change can now adopt it under AGPL. However, AGPL requires source code disclosure for network-accessible services, which may be incompatible with some SaaS business models.

### ES|QL (Elasticsearch Query Language)

ES|QL is a pipe-based query language that went GA in 8.13. It resembles SPL (Splunk) or KQL more than the JSON Query DSL.

**Structure**: Source command | processing command | processing command | ...

```
FROM logs-*
| WHERE @timestamp > NOW() - 1 HOUR AND status_code >= 500
| STATS error_count = COUNT(*), avg_duration = AVG(duration) BY service.name
| SORT error_count DESC
| LIMIT 20
```

**Key commands**:
- `FROM` -- source command, specifies index pattern
- `WHERE` -- filter rows
- `EVAL` -- compute new columns
- `STATS ... BY` -- aggregate and group
- `SORT`, `LIMIT` -- ordering and pagination
- `ENRICH` -- join with enrichment policies (threat intel, geo data)
- `DISSECT`, `GROK` -- parse unstructured text inline
- `JOIN` -- cross-index joins (9.1+)
- `FORK` -- create parallel execution branches (9.2+, for hybrid search)
- `FUSE` -- combine and score results from FORK branches (9.2+, RRF in ES|QL)
- `KNN` -- dense vector search function (9.2+)

**When to use ES|QL vs Query DSL**:
- ES|QL: data exploration, log analysis, ad-hoc investigation, security analytics
- Query DSL: application search, complex relevance tuning, programmatic query construction, backward compatibility

### semantic_text Field Type (GA in 8.18+)

The recommended approach for most semantic search use cases:

```json
{
  "mappings": {
    "properties": {
      "content": {
        "type": "semantic_text",
        "inference_id": "my-elser-endpoint"
      }
    }
  }
}
```

**What it automates**:
- Chunking long documents into segments
- Generating embeddings via configured inference endpoint
- Storing both text and vectors
- Handling query-time inference automatically

**What you no longer need to manually configure**:
- Ingest pipelines for embedding generation
- Dense vector field mappings with dimensions
- Chunk management logic
- Query-time model inference calls

**Query with `semantic` query**:
```json
{
  "query": {
    "semantic": {
      "field": "content",
      "query": "how to optimize database performance"
    }
  }
}
```

### Vector Search (kNN)

**Supported vector types**:
- `dense_vector` with HNSW index (default) -- best recall/speed tradeoff
- `int8_hnsw` -- 8-bit scalar quantization, ~75% memory reduction
- `int4_hnsw` -- 4-bit scalar quantization (8.15+), ~87% memory reduction
- `int4_flat` -- brute-force with 4-bit quantization for small datasets
- `bbq_hnsw` -- Better Binary Quantization (8.18+ GA), 32x memory reduction with 20% higher recall than naive binary, 8-30x faster throughput with SIMD
- Bit vectors with Hamming distance (8.15+) -- extreme compression for binary embeddings

**Production configuration**:
```json
{
  "mappings": {
    "properties": {
      "embedding": {
        "type": "dense_vector",
        "dims": 768,
        "index": true,
        "similarity": "cosine",
        "index_options": {
          "type": "int8_hnsw",
          "m": 16,
          "ef_construction": 100
        }
      }
    }
  }
}
```

**kNN query with pre-filtering**:
```json
{
  "knn": {
    "field": "embedding",
    "query_vector": [0.1, 0.2, ...],
    "k": 10,
    "num_candidates": 100,
    "filter": {
      "term": { "category": "electronics" }
    }
  }
}
```

Sub-50ms kNN queries are achievable even with term/range filters applied, thanks to integrated filtering in the HNSW graph traversal.

### Machine Learning Integration

- **ELSER** (Elastic Learned Sparse Encoder): Elastic's trained sparse embedding model for out-of-the-box semantic search without external model dependencies
- **Elastic Rerank** (8.17+): Semantic re-ranker model for second-stage relevance reranking
- **Third-party model support**: Deploy custom PyTorch/ONNX models via Eland, or use inference endpoints for OpenAI, Cohere, Google, Hugging Face
- **LTR native** (8.13+ tech preview): XGBoost/LambdaMART models trained externally, deployed natively via Eland

---

## 3. OpenSearch (2.x)

### Key Developments (2024-2025)

**Governance**: AWS transferred OpenSearch governance to the **Linux Foundation** in September 2024, establishing the OpenSearch Foundation. Over 1,400 unique contributors, 350+ active, 100+ GitHub repositories.

**Version highlights**:

| Version | Key Features |
|---------|-------------|
| **2.17** | Bitmap filtering for numeric fields, neural sparse search improvements |
| **2.18** | ByFieldRerankProcessor for second-level reranking, text chunking processor improvements |
| **2.19** | Reciprocal Rank Fusion (RRF) in Neural Search plugin, ML inference search request extension, improved hybrid search |

### Divergence from Elasticsearch

After forking from Elasticsearch 7.10.2 in 2021, OpenSearch has diverged significantly:

**Where OpenSearch differs**:
- **Vector engines**: Uses FAISS and nmslib (not Lucene's HNSW exclusively), supports up to **16,000 dimensions** (vs Elasticsearch's 4,096)
- **SIMD acceleration**: Hardware-accelerated vector operations via FAISS
- **Vector quantization**: Supports product quantization (PQ) and scalar quantization via FAISS
- **Security**: Security plugin is open-source and built-in (vs Elasticsearch's proprietary security in older versions, now AGPL)
- **Alerting and anomaly detection**: Built-in plugins, no separate license tier
- **Query compatibility**: Maintains Elasticsearch 7.x Query DSL compatibility but does not track Elasticsearch 8.x additions (no ES|QL, no semantic_text, no retrievers API)
- **Neural search plugin**: Dedicated plugin for embedding generation, semantic search, and neural sparse search
- **Conversational search**: Built-in RAG pipeline with LLM integration for question-answering over indexed data

**Performance (2025 benchmarks)**:
- Trail of Bits (March 2025): OpenSearch 2.17.1 is **1.6x faster on Big5 text workload** and 11% faster on vector search than Elasticsearch 8.15.4
- Elastic Labs benchmark: Elasticsearch delivers **up to 8x higher throughput** for filtered vector search vs OpenSearch
- Reality: Performance varies by workload -- benchmark your specific use case

### Neural Search Architecture

```
Document → Neural Search Plugin → ML Model (local or remote) → Embedding → k-NN Index
                                                                    ↑
Query → Neural Search Plugin → ML Model → Query Embedding → k-NN Search
```

```json
{
  "query": {
    "neural": {
      "passage_embedding": {
        "query_text": "best hiking trails",
        "model_id": "my-deployed-model",
        "k": 10
      }
    }
  }
}
```

### When OpenSearch over Elasticsearch

1. **AWS-native deployment**: Amazon OpenSearch Service is deeply integrated with IAM, VPC, CloudWatch
2. **Apache 2.0 license is mandatory**: Legal/compliance team rejects AGPL and SSPL
3. **Need >4,096 vector dimensions**: Some embedding models produce high-dimensional vectors
4. **Built-in security without paid tier**: All security features are free and open
5. **Existing OpenSearch investment**: Migration cost outweighs Elasticsearch feature advantages

---

## 4. Meilisearch (1.x)

### Version Highlights

| Version | Key Features |
|---------|-------------|
| **1.10** | Federated search (multi-index merged results), locale settings |
| **1.11** | Binary quantization for vectors, facetsByIndex and mergeFacets for federated search |
| **1.12** | 2x faster document insertion, 4x faster incremental updates, 1.5x faster embedding generation |
| **1.13** | AI-powered search stabilized (GA), remote federated search (cross-instance sharding), dumpless upgrades |
| **1.15** | Typo tolerance settings, comparison operators for string filters, improved Chinese support |
| **1.16** | Multi-modal embeddings, data transfer API between instances |

### Core Strengths

- **Instant search**: Targets <50ms response time out of the box
- **Typo tolerance**: Built-in, configurable, no analyzer setup required
- **Faceted search**: First-class support with distribution counts
- **AI-powered search (GA in 1.13)**: Hybrid semantic + keyword search with auto-embedding via OpenAI, Hugging Face, or local models
- **Federated search**: Merge results from multiple indexes or multiple Meilisearch instances into a single ranked response
- **Developer experience**: REST API that works in minutes, excellent documentation, official SDKs for JS, Python, PHP, Ruby, Go, Rust, Java, Swift, Dart
- **LLM integration**: Works with LangChain and MCP (Model Context Protocol) out of the box

### Architecture

- **Written in Rust** for performance and memory safety
- **Single-node by default** (no distributed clustering like Elasticsearch)
- **Horizontal scaling**: Remote federated search (v1.13+) enables sharding by routing queries across multiple instances and merging results
- **Storage**: Uses LMDB (Lightning Memory-Mapped Database) for persistence
- **Index size**: Practical limit ~10M documents per instance (memory-dependent)

### When Meilisearch Over Elasticsearch

1. **Rapid prototyping**: Search working in minutes, not hours
2. **Frontend-facing search**: E-commerce product search, documentation sites, SaaS search bars
3. **Small-to-medium datasets**: Under 10M documents per index
4. **No Ops team**: Minimal configuration, single binary deployment
5. **Typo tolerance matters**: Built-in vs custom analyzer chains in Elasticsearch
6. **AI search with zero ML infrastructure**: Auto-embedding with cloud providers

### When NOT to Use Meilisearch

- Dataset exceeds single-node memory capacity significantly
- Complex aggregations / analytics are needed (no aggregation pipeline)
- Log analytics or observability workloads
- Multi-tenant isolation at the index level with fine-grained security
- Need for Learning to Rank or advanced relevance models

---

## 5. Typesense (v27+)

### Latest Versions

| Version | Key Features |
|---------|-------------|
| **v27** | OpenAI error handling improvements for conversational search |
| **v28** | Bug fixes and performance regression fixes |
| **v29** | Union/merge of results across collections, dictionary-based stemming, random sort (`_rand(seed)`), hybrid re-ranking (augment keyword/semantic scores) |
| **v30** | Latest stable, continued improvements |

### Core Strengths

- **Written in C++**: In-memory data structures for sub-50ms latency
- **Typo tolerance by default**: Enabled automatically, no configuration needed
- **Geo search**: Radius search, bounding box, polygon filtering, sorting by distance
- **Semantic/hybrid search**: Built-in embedding generation with S-BERT, E-5, OpenAI, PaLM
- **Conversational search (RAG)**: Built-in -- send questions, receive full-sentence answers grounded in indexed data
- **InstantSearch.js adapter**: Drop-in Algolia replacement for frontend components
- **Raft-based clustering**: High availability via multi-node Raft consensus

### Typesense vs Meilisearch

| Criteria | Typesense | Meilisearch |
|----------|-----------|-------------|
| **Language** | C++ | Rust |
| **Latency** | <50ms (in-memory) | <50ms (LMDB-backed) |
| **Typo tolerance** | Default on | Default on |
| **Geo search** | Polygon, radius, bounding box | Basic geo filtering |
| **Clustering** | Raft-based HA | Single-node (federated search for scaling) |
| **Vector search** | Built-in models + external APIs | Built-in models + external APIs |
| **Conversational search** | Built-in RAG | Via LangChain/MCP integration |
| **Frontend components** | InstantSearch.js adapter (Algolia-compatible) | InstantSearch.js adapter + custom components |
| **License** | GPL v3 | MIT |
| **Scalability ceiling** | Higher (Raft clustering) | Lower (single-node, but federated search adds horizontal) |

**Choose Typesense** when: Algolia replacement, geo-heavy search, built-in RAG, Raft HA needed
**Choose Meilisearch** when: MIT license preferred, stronger developer ecosystem, federated multi-index search, AI-powered search with less config

---

## 6. Apache Solr

### Current Status (2025)

- **DB-Engines rank**: #3 among search engines (score 32.40 vs Elasticsearch's 128.08)
- **Market position**: ~4x less popular than Elasticsearch, declining mindshare for new projects
- **Still maintained**: Active Apache project with regular releases
- **Runs on Lucene**: Same underlying library as Elasticsearch

### When Solr Still Makes Sense

1. **Legacy investment**: Years of custom configuration, analyzers, and tuning
2. **ECM integration**: Alfresco, Drupal, and other platforms with deep Solr integration
3. **Hadoop ecosystem**: HDFS-backed indexes, Spark-Solr integration
4. **Complex faceting**: Solr's faceting has historically been more flexible (though Elasticsearch has caught up)
5. **Apache 2.0 licensing**: No ambiguity, pure Apache license

### When to Migrate Away from Solr

- New project with no existing Solr infrastructure
- Need for vector/semantic search (Elasticsearch and OpenSearch are far ahead)
- Need for hybrid search, LTR, or ML-powered relevance
- Team expertise is dwindling (harder to hire Solr engineers)
- Want ES|QL-style data exploration
- Cloud-native deployment is a priority (fewer managed Solr options)

### Migration Path: Solr to Elasticsearch

1. Map Solr schema.xml to Elasticsearch mappings
2. Convert Solr query syntax to Query DSL
3. Migrate analyzers/tokenizers (most have Elasticsearch equivalents)
4. Reindex data using bulk API
5. Test relevance parity with production query logs
6. Run shadow mode (dual-query both engines, compare results) before cutover

---

## 7. Index Design

### Mapping Strategies

**Explicit mapping** (recommended for production):
```json
{
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "english",
        "fields": {
          "raw": { "type": "keyword" },
          "autocomplete": {
            "type": "text",
            "analyzer": "autocomplete_analyzer",
            "search_analyzer": "standard"
          }
        }
      },
      "price": { "type": "scaled_float", "scaling_factor": 100 },
      "category": { "type": "keyword" },
      "description": {
        "type": "text",
        "analyzer": "english"
      },
      "created_at": { "type": "date" },
      "location": { "type": "geo_point" },
      "embedding": {
        "type": "dense_vector",
        "dims": 768,
        "index": true,
        "similarity": "cosine"
      }
    }
  }
}
```

**Key mapping rules**:
- Use `"dynamic": "strict"` in production to prevent mapping explosions
- Use `"dynamic": "runtime"` for exploratory indexes to avoid mapping conflicts
- Multi-fields for different analysis: `title` (full-text) + `title.raw` (keyword for sorting/aggregation) + `title.autocomplete` (edge n-gram)
- Use `keyword` for exact-match fields (IDs, categories, statuses)
- Use `scaled_float` for currency (avoid floating-point precision issues)
- Use `date` with explicit format for timestamp fields
- Set `"index": false` on fields you never search (saves disk, speeds indexing)

**Dynamic templates** for semi-structured data:
```json
{
  "dynamic_templates": [
    {
      "strings_as_keywords": {
        "match_mapping_type": "string",
        "mapping": {
          "type": "keyword",
          "ignore_above": 256
        }
      }
    },
    {
      "unindexed_longs": {
        "match_mapping_type": "long",
        "mapping": {
          "type": "long",
          "index": false
        }
      }
    }
  ]
}
```

### Analyzers and Tokenizers

**Analyzer pipeline**: Character Filters -> Tokenizer -> Token Filters

**Common analyzer configurations**:

```json
{
  "settings": {
    "analysis": {
      "analyzer": {
        "autocomplete_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "autocomplete_filter"]
        },
        "search_synonym_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "synonym_filter"]
        },
        "html_analyzer": {
          "type": "custom",
          "char_filter": ["html_strip"],
          "tokenizer": "standard",
          "filter": ["lowercase", "stop", "snowball"]
        }
      },
      "filter": {
        "autocomplete_filter": {
          "type": "edge_ngram",
          "min_gram": 2,
          "max_gram": 15
        },
        "synonym_filter": {
          "type": "synonym_graph",
          "synonyms_path": "analysis/synonyms.txt"
        }
      }
    }
  }
}
```

**Built-in language analyzers**: `english`, `french`, `german`, `spanish`, `chinese` (with ICU plugin), `japanese` (with kuromoji plugin), `korean` (with nori plugin)

**Tokenizer selection**:
| Tokenizer | Use Case | Example |
|-----------|----------|---------|
| `standard` | General-purpose, Unicode-aware | "It's a test" -> ["It's", "a", "test"] |
| `whitespace` | Preserve punctuation | "user@email.com" -> ["user@email.com"] |
| `keyword` | Entire field as single token | Exact match fields |
| `pattern` | Custom delimiter | Split on hyphens, underscores |
| `icu_tokenizer` | CJK and mixed-script text | Chinese/Japanese/Korean content |
| `edge_ngram` | Prefix matching (autocomplete) | "search" -> ["se", "sea", "sear", ...] |

### Field Types Reference

| Type | Use Case | Notes |
|------|----------|-------|
| `text` | Full-text search | Analyzed, cannot sort/aggregate directly |
| `keyword` | Exact match, sort, aggregate | Not analyzed, max 32KB default |
| `long` / `integer` | Numeric filtering, range queries | Use `scaled_float` for decimals with known precision |
| `date` | Timestamps, date math | Specify format explicitly |
| `boolean` | Flags | Stored as 0/1 |
| `geo_point` | Lat/lon coordinates | For distance queries, geo bounding box |
| `geo_shape` | Polygons, complex geometries | More expensive than geo_point |
| `nested` | Arrays of objects that must be queried independently | Expensive -- avoid if flattened fields work |
| `join` | Parent-child relationships | Rarely needed, use denormalization instead |
| `dense_vector` | Vector embeddings for kNN | Set dims, similarity, index_options |
| `sparse_vector` | Sparse embeddings (ELSER) | Variable-length, learned sparse representations |
| `semantic_text` | Auto-managed semantic search (8.15+) | Handles chunking, embedding, and inference automatically |
| `search_as_you_type` | Autocomplete without custom analyzers | Internally generates edge n-gram and shingle subfields |

---

## 8. Relevance Tuning

### BM25 Fundamentals

BM25 (Best Matching 25) is Elasticsearch's default scoring algorithm since 5.x (replacing TF-IDF):

```
score(q, d) = SUM[ IDF(qi) * (tf(qi, d) * (k1 + 1)) / (tf(qi, d) + k1 * (1 - b + b * |d| / avgdl)) ]
```

**Parameters**:
- **k1** (default: 1.2): Controls term frequency saturation. Higher = more weight to term frequency. Range: 0.0-3.0.
- **b** (default: 0.75): Controls document length normalization. 0 = no length normalization, 1 = full normalization.

**Defaults work for most corpora.** Only tune when:
- Short documents (product names): Lower `b` (0.3-0.5) to reduce length penalty
- Long documents (articles): Default `b` is usually fine
- Highly repetitive terms: Lower `k1` to cap frequency impact

**Per-index BM25 tuning**:
```json
{
  "settings": {
    "similarity": {
      "custom_bm25": {
        "type": "BM25",
        "k1": 1.0,
        "b": 0.5
      }
    }
  },
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "similarity": "custom_bm25"
      }
    }
  }
}
```

**Important**: BM25 scores are computed per-shard. With multiple shards, scores may vary slightly because IDF is calculated per-shard. For small indexes, use `"number_of_shards": 1` or `search_type=dfs_query_then_fetch` for consistent scoring.

### function_score

Use `function_score` to apply business logic boosts without distorting BM25 relevance:

```json
{
  "query": {
    "function_score": {
      "query": { "match": { "title": "running shoes" } },
      "functions": [
        {
          "field_value_factor": {
            "field": "popularity",
            "modifier": "log1p",
            "factor": 2
          }
        },
        {
          "gauss": {
            "created_at": {
              "origin": "now",
              "scale": "30d",
              "decay": 0.5
            }
          }
        },
        {
          "filter": { "term": { "promoted": true } },
          "weight": 5
        }
      ],
      "score_mode": "multiply",
      "boost_mode": "multiply"
    }
  }
}
```

**Best practices**:
- Use `"boost_mode": "multiply"` to preserve BM25 ordering while amplifying by business signals
- `field_value_factor` with `"modifier": "log1p"` for smooth popularity boosting (prevents extreme outliers from dominating)
- `gauss` / `exp` / `linear` decay functions for recency or proximity boosting
- `weight` filters for categorical boosts (promoted items, premium listings)
- `"score_mode": "multiply"` combines multiple function scores multiplicatively -- maintains proportional relationships

### Query vs Filter Context

```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title": "laptop" } }
      ],
      "filter": [
        { "term": { "brand": "apple" } },
        { "range": { "price": { "gte": 500, "lte": 2000 } } },
        { "term": { "in_stock": true } }
      ]
    }
  }
}
```

**Rule**: `must` affects relevance scoring; `filter` is boolean yes/no (cached, faster). Put all non-scoring constraints in `filter`.

### Boosting Across Fields

```json
{
  "query": {
    "multi_match": {
      "query": "database optimization",
      "fields": ["title^3", "summary^2", "body"],
      "type": "best_fields",
      "tie_breaker": 0.3
    }
  }
}
```

**multi_match types**:
- `best_fields` (default): Score from best-matching field, tie_breaker adds partial credit from others
- `most_fields`: Sum scores from all fields (good for same content analyzed differently)
- `cross_fields`: Treats multiple fields as one combined field (good for "first_name" + "last_name")
- `phrase`: Runs `match_phrase` on each field
- `phrase_prefix`: Runs `match_phrase_prefix` (autocomplete)

### Learning to Rank (LTR)

**Native LTR (Elasticsearch 8.13+ tech preview)**:

Two-stage architecture:
1. **First stage**: Standard query (BM25, vector, or hybrid) retrieves candidate documents quickly
2. **Second stage**: LTR model re-ranks top-N results using multiple features

**Feature types**:
- **Query-dependent**: BM25 score, match count, phrase match score
- **Query-independent**: Popularity, recency, quality score, click-through rate
- **Interaction**: Query-document similarity, field-specific match quality

**Model training** (outside Elasticsearch):
```python
# Train with XGBoost (LambdaMART)
import xgboost as xgb
from eland.ml import MLModel

model = xgb.XGBRanker(objective='rank:ndcg', n_estimators=100)
model.fit(X_train, y_train, group=group_sizes)

# Deploy to Elasticsearch via Eland
MLModel.import_model(es_client, model_id='my-ltr-model', model=model, ...)
```

**Judgment list creation**: Requires labeled query-document pairs with relevance grades (0-4 scale typical). Sources: click logs, human annotation, or A/B test results.

### Elastic Rerank (8.17+)

Elastic's semantic re-ranker model for second-stage reranking:
```json
{
  "retriever": {
    "text_similarity_reranker": {
      "retriever": {
        "standard": {
          "query": { "match": { "content": "database optimization" } }
        }
      },
      "field": "content",
      "inference_id": "elastic-rerank",
      "inference_text": "database optimization",
      "rank_window_size": 100
    }
  }
}
```

---

## 9. Faceted Search

### Aggregation Design

**Standard faceted search pattern**:
```json
{
  "size": 10,
  "query": {
    "bool": {
      "must": [{ "match": { "title": "laptop" } }],
      "filter": [{ "term": { "brand": "apple" } }]
    }
  },
  "post_filter": {
    "term": { "color": "silver" }
  },
  "aggs": {
    "brands": {
      "terms": { "field": "brand", "size": 20 }
    },
    "colors": {
      "terms": { "field": "color", "size": 20 }
    },
    "price_ranges": {
      "range": {
        "field": "price",
        "ranges": [
          { "to": 500 },
          { "from": 500, "to": 1000 },
          { "from": 1000, "to": 2000 },
          { "from": 2000 }
        ]
      }
    },
    "avg_rating": {
      "avg": { "field": "rating" }
    }
  }
}
```

**post_filter vs filter**:
- `post_filter` applies filters AFTER aggregations are calculated
- Use `post_filter` for "interactive" facets where selecting a facet value should not reduce counts of other values in the same facet
- Use `filter` in the query body for constraints that should reduce all facet counts

### Nested Aggregations

For nested object fields (e.g., product variants with independent attributes):

```json
{
  "aggs": {
    "variants": {
      "nested": { "path": "variants" },
      "aggs": {
        "sizes": {
          "terms": { "field": "variants.size" }
        },
        "price_stats": {
          "stats": { "field": "variants.price" }
        }
      }
    }
  }
}
```

### Performance Optimization

1. **Limit bucket count**: Use `"size"` parameter in `terms` aggregations (default is 10). Requesting 1000+ buckets is expensive.
2. **Use `doc_count` over sum**: The built-in `doc_count` is more efficient than a `value_count` or `sum` aggregation.
3. **Composite aggregation for pagination**: When you have high-cardinality fields and need to page through all values:
   ```json
   {
     "aggs": {
       "all_brands": {
         "composite": {
           "size": 100,
           "sources": [
             { "brand": { "terms": { "field": "brand" } } }
           ],
           "after": { "brand": "previous_last_brand" }
         }
       }
     }
   }
   ```
4. **Separate aggregation requests**: Sending aggregations in separate requests from search results uses ~20% more CPU but returns search results ~71ms faster (Vinted engineering benchmark).
5. **Shard request cache**: Aggregation results on unchanging data are automatically cached. Size this cache appropriately for facet-heavy workloads.
6. **Avoid nested aggregations when possible**: Nested aggregations are expensive. Flatten data at index time if the nested structure isn't essential for query correctness.
7. **Use `execution_hint: "map"`**: For low-cardinality terms aggregations, `map` execution can be faster than the default `global_ordinals`.

---

## 10. Autocomplete and Suggestions

### Three Approaches Compared

| Approach | Speed | Flexibility | Index Size Impact | Configuration |
|----------|-------|-------------|-------------------|---------------|
| **Completion suggester** | Fastest (FST in-memory) | Prefix-only | Low (separate data structure) | Dedicated `completion` field type |
| **Edge n-gram** | Fast (standard query) | Prefix + infix, fuzzy | High (many tokens per term) | Custom analyzer |
| **search_as_you_type** | Fast (built-in) | Prefix + infix + shingles | Medium | Zero-config field type |

### Completion Suggester

Best for: Dropdown suggestions from a curated list (popular queries, product names).

```json
{
  "mappings": {
    "properties": {
      "suggest": {
        "type": "completion",
        "contexts": [
          { "name": "category", "type": "category" }
        ]
      }
    }
  }
}
```

```json
{
  "suggest": {
    "product-suggest": {
      "prefix": "lap",
      "completion": {
        "field": "suggest",
        "size": 5,
        "fuzzy": { "fuzziness": "AUTO" },
        "contexts": {
          "category": [{ "context": "electronics" }]
        }
      }
    }
  }
}
```

Uses in-memory **Finite State Transducer (FST)** -- fastest option but limited to prefix matching. Supports weighted suggestions and category filtering.

### Edge N-gram

Best for: Search-as-you-type in the main search box with full query capabilities.

```json
{
  "settings": {
    "analysis": {
      "filter": {
        "edge_ngram_filter": {
          "type": "edge_ngram",
          "min_gram": 2,
          "max_gram": 15
        }
      },
      "analyzer": {
        "autocomplete_index": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "edge_ngram_filter"]
        },
        "autocomplete_search": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "autocomplete_index",
        "search_analyzer": "autocomplete_search"
      }
    }
  }
}
```

**Critical**: Use different analyzers for indexing and searching. The index analyzer creates edge n-grams; the search analyzer uses standard tokenization to match against those n-grams. Using the same analyzer for both causes poor precision.

### search_as_you_type Field

Best for: Quick setup with good results and minimal configuration.

```json
{
  "mappings": {
    "properties": {
      "name": {
        "type": "search_as_you_type",
        "max_shingle_size": 3
      }
    }
  }
}
```

Internally creates subfields: `name`, `name._2gram`, `name._3gram`, `name._index_prefix`. Query with:

```json
{
  "query": {
    "multi_match": {
      "query": "data optim",
      "type": "bool_prefix",
      "fields": [
        "name",
        "name._2gram",
        "name._3gram"
      ]
    }
  }
}
```

### Production Autocomplete Architecture

Combine approaches for the best UX:

```
User types "dat"
  ├─ Completion Suggester → "Database", "Data Science", "Data Pipeline" (instant, curated)
  ├─ Edge n-gram query → Product results matching "dat*" (from index)
  └─ Popular queries → "database optimization", "data migration" (from analytics log)
```

1. Show curated suggestions (completion suggester) at the top
2. Show matching results (edge n-gram / search_as_you_type) below
3. Show popular related queries from search analytics
4. Debounce input: 150-300ms delay before firing search request
5. Cache frequent prefix queries (Redis or application-level)

---

## 11. Hybrid Search

### Combining Full-Text and Vector Search

Hybrid search merges lexical (BM25) and semantic (vector) search to get the best of both:
- **Lexical search**: Exact matches, proper nouns, product codes, rare terms
- **Semantic search**: Conceptual similarity, synonyms, paraphrases, meaning

### Reciprocal Rank Fusion (RRF)

RRF is the recommended fusion method -- it normalizes rankings without requiring score calibration:

```
RRF_score(d) = SUM[ 1 / (k + rank_i(d)) ] for each ranking i
```

Where `k` is a constant (default: 60) that dampens the impact of high rankings.

**Elasticsearch RRF retriever**:
```json
{
  "retriever": {
    "rrf": {
      "retrievers": [
        {
          "standard": {
            "query": {
              "match": { "content": "database performance tuning" }
            }
          }
        },
        {
          "knn": {
            "field": "embedding",
            "query_vector_builder": {
              "text_embedding": {
                "model_id": "my-embedding-model",
                "model_text": "database performance tuning"
              }
            },
            "k": 10,
            "num_candidates": 100
          }
        }
      ],
      "rank_constant": 60,
      "rank_window_size": 100
    }
  }
}
```

### Linear Combination

Alternative to RRF when you want explicit control over the weight of each signal:

```json
{
  "retriever": {
    "linear": {
      "retrievers": [
        {
          "retriever": {
            "standard": {
              "query": { "match": { "content": "database tuning" } }
            }
          },
          "weight": 0.7
        },
        {
          "retriever": {
            "knn": {
              "field": "embedding",
              "query_vector": [0.1, 0.2, ...],
              "k": 10,
              "num_candidates": 100
            }
          },
          "weight": 0.3
        }
      ]
    }
  }
}
```

### Hybrid Search in ES|QL (9.2+)

```
FROM products
| FORK
  (WHERE MATCH(description, "database optimization") | SORT _score DESC | LIMIT 100)
  (WHERE KNN(embedding, ?, 100) | SORT _score DESC | LIMIT 100)
| FUSE rrf(rank_constant=60)
| LIMIT 10
```

### Multi-Stage Retrieval Pipeline

Production-grade hybrid search often uses 3+ stages:

```
Stage 1: Candidate retrieval (broad, fast)
  ├─ BM25 full-text → top 1000
  └─ kNN vector search → top 1000
         ↓
Stage 2: Fusion (RRF or linear combination)
  → merged top 200
         ↓
Stage 3: Re-ranking (precise, slow)
  → Elastic Rerank or cross-encoder model → top 20
         ↓
Stage 4: Business logic (function_score)
  → popularity boost, recency, personalization → final top 10
```

### OpenSearch Hybrid Search

```json
{
  "query": {
    "hybrid": {
      "queries": [
        { "match": { "content": "database tuning" } },
        {
          "neural": {
            "embedding": {
              "query_text": "database tuning",
              "model_id": "my-model",
              "k": 10
            }
          }
        }
      ]
    }
  }
}
```

OpenSearch 2.19+ supports RRF via the Neural Search plugin for combining results.

---

## 12. Scaling Search

### Shard Sizing

**Target: 10-50 GB per shard** (Elastic's official recommendation)

| Metric | Guideline |
|--------|-----------|
| **Shard size** | 10-50 GB optimal, never exceed 100 GB |
| **Shards per node** | Max 20 shards per GB of heap (e.g., 640 shards for 32 GB heap) |
| **Documents per shard** | No hard limit, but 200M+ docs per shard degrades merge performance |
| **Shard count** | Start with 1 shard for indexes under 50 GB, add as needed |

**Shard sizing formula**:
```
number_of_shards = ceil(expected_data_size_gb / target_shard_size_gb)
```

Example: 200 GB expected data / 40 GB target = 5 primary shards

**Over-sharding symptoms**: High cluster state size, slow master node operations, wasted memory for shard-level data structures.

### Replica Strategy

- **Minimum 1 replica** per primary for fault tolerance
- **Add replicas for read throughput**: Each replica can serve search queries independently
- **Replicas can be changed anytime** (unlike shard count, which requires reindexing)
- **Search-heavy workloads**: 2-3 replicas common
- **Write-heavy workloads**: 0 replicas during bulk ingestion, add replicas after

```json
{
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 1,
    "auto_expand_replicas": "0-2"
  }
}
```

### Index Lifecycle Management (ILM)

Automate index lifecycle for time-series and log data:

```json
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "7d"
          },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "90d",
        "actions": {
          "searchable_snapshot": {
            "snapshot_repository": "my-s3-repo"
          }
        }
      },
      "delete": {
        "min_age": "365d",
        "actions": { "delete": {} }
      }
    }
  }
}
```

**Phases**: Hot (active write + search) -> Warm (read-only, less resources) -> Cold (searchable snapshots, cheapest) -> Frozen (partially mounted, on-demand) -> Delete

### Cross-Cluster Search (CCS)

Search across multiple Elasticsearch clusters without data duplication:

```json
// On the local cluster, configure remote cluster
PUT _cluster/settings
{
  "persistent": {
    "cluster": {
      "remote": {
        "cluster_us_west": {
          "seeds": ["us-west-node1:9300", "us-west-node2:9300"]
        },
        "cluster_eu": {
          "seeds": ["eu-node1:9300"]
        }
      }
    }
  }
}

// Query across clusters
GET /local-index,cluster_us_west:remote-index,cluster_eu:remote-index/_search
{
  "query": { "match": { "title": "search optimization" } }
}
```

**Use cases**: Multi-region search, data sovereignty (keep EU data in EU cluster), organizational boundaries.

### Data Streams (for Time-Series)

```json
PUT _index_template/logs-template
{
  "index_patterns": ["logs-*"],
  "data_stream": {},
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message": { "type": "text" }
      }
    }
  }
}
```

### LogsDB Index Mode (8.17+ GA)

For log/observability data, logsdb mode reduces storage by up to 65%:

```json
{
  "settings": {
    "index": {
      "mode": "logsdb"
    }
  }
}
```

Enables automatic index sorting, ZSTD compression, delta encoding, and run-length encoding for log data patterns.

---

## 13. Search Observability

### Key Metrics to Track

| Metric | What It Tells You | Target |
|--------|-------------------|--------|
| **Search latency (p50/p95/p99)** | User experience quality | p50 < 50ms, p95 < 200ms, p99 < 500ms |
| **Zero-result rate** | Content gaps or query understanding failures | < 5% |
| **Click-through rate (CTR)** | Result relevance | > 30% for position 1 |
| **Mean Reciprocal Rank (MRR)** | How high the first relevant result appears | > 0.5 |
| **Query volume** | Capacity planning | Track trends |
| **Indexing lag** | Data freshness | < 1 minute for near-real-time |
| **Shard health** | Cluster stability | No unassigned shards |
| **Cache hit rate** | Query cache effectiveness | > 60% for repetitive queries |
| **Query distribution** | Popular vs long-tail queries | Pareto: 20% of queries generate 80% of volume |

### Search Analytics Pipeline

```
User Search Event → Kafka Topic → Search Analytics Service → ClickHouse/Elasticsearch
     ↓
  { query, results[], clicked_result, position, timestamp, user_id, session_id }
```

**Essential events to capture**:
1. **Search executed**: query text, filters applied, result count, latency
2. **Result impression**: which results were shown and in what position
3. **Result click**: which result was clicked, at what position
4. **Conversion**: did the click lead to desired outcome (purchase, sign-up)
5. **Refinement**: did user modify query, add filters, paginate
6. **Abandonment**: user searched but took no action

### Zero-Result Query Analysis

Zero-result queries are the highest-priority search quality signal:

**Common causes and fixes**:
| Cause | Fix |
|-------|-----|
| Typos | Typo tolerance (built into Meilisearch/Typesense; fuzziness in Elasticsearch) |
| Synonyms | Synonym filters ("laptop" = "notebook") |
| Missing content | Content gap analysis -- add missing content or redirect to related results |
| Overly specific filters | Show "nearest match" results when exact filters return zero |
| Language mismatch | Multi-language analyzers, language detection |
| Boolean AND too strict | Fall back to OR with boosted AND matches |

**Monitoring query**:
```json
// Track zero-result queries
POST /search-analytics/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "@timestamp": { "gte": "now-24h" } } },
        { "term": { "result_count": 0 } }
      ]
    }
  },
  "aggs": {
    "zero_result_queries": {
      "terms": { "field": "query.keyword", "size": 50 }
    }
  }
}
```

### Latency Monitoring

**Elasticsearch slow log configuration**:
```json
PUT /my-index/_settings
{
  "index.search.slowlog.threshold.query.warn": "5s",
  "index.search.slowlog.threshold.query.info": "2s",
  "index.search.slowlog.threshold.query.debug": "500ms",
  "index.search.slowlog.threshold.fetch.warn": "1s",
  "index.search.slowlog.threshold.fetch.info": "500ms"
}
```

**Cluster health monitoring endpoints**:
- `_cluster/health` -- overall cluster status (green/yellow/red)
- `_cat/nodes?v` -- node-level CPU, memory, disk, heap
- `_cat/shards?v` -- shard allocation and sizes
- `_nodes/stats` -- detailed node statistics
- `_cat/thread_pool?v` -- search/write thread pool saturation
- `_cat/pending_tasks` -- cluster state update queue

---

## 14. Search Infrastructure Patterns

### Index Aliases for Zero-Downtime Operations

Aliases decouple application code from physical index names:

```json
// Create alias pointing to versioned index
POST /_aliases
{
  "actions": [
    { "add": { "index": "products-v2", "alias": "products" } }
  ]
}

// Atomic swap during reindexing
POST /_aliases
{
  "actions": [
    { "remove": { "index": "products-v1", "alias": "products" } },
    { "add": { "index": "products-v2", "alias": "products" } }
  ]
}
```

**Alias patterns**:
- **Read alias**: `products` -> `products-v2` (application reads from this)
- **Write alias**: `products-write` -> `products-v2` (application writes to this)
- **Filtered alias**: `active-products` -> `products-v2` with filter `{"term": {"active": true}}`

### Reindexing Strategies

**Zero-downtime reindex with alias swap**:

```
1. Create new index (products-v2) with updated mappings/settings
2. POST /_reindex { "source": { "index": "products-v1" }, "dest": { "index": "products-v2" } }
3. During reindex, new writes go to both v1 and v2 (dual-write or CDC)
4. When reindex completes, atomically swap alias from v1 to v2
5. Delete products-v1 after verification
```

**Reindex performance tuning**:
- Set `"number_of_replicas": 0` on target index during reindex (add replicas after)
- Set `"refresh_interval": "-1"` on target (refresh after reindex completes)
- Use `"slices": "auto"` for parallelized reindexing (optimal: slices = number of shards)
- Increase `"scroll_size"` for larger batches (default: 1000, can increase to 5000-10000)

### Snapshot and Restore

**Repository setup (S3 example)**:
```json
PUT /_snapshot/my-s3-repo
{
  "type": "s3",
  "settings": {
    "bucket": "my-es-snapshots",
    "base_path": "production",
    "max_restore_bytes_per_sec": "200mb"
  }
}
```

**Snapshots are incremental**: Only data changed since the last successful snapshot is stored. Frequent snapshots (hourly for critical data) are efficient.

**Snapshot lifecycle management (SLM)**:
```json
PUT /_slm/policy/nightly-snapshots
{
  "schedule": "0 30 2 * * ?",
  "name": "<nightly-{now/d}>",
  "repository": "my-s3-repo",
  "config": {
    "indices": ["products", "orders"],
    "include_global_state": false
  },
  "retention": {
    "expire_after": "30d",
    "min_count": 5,
    "max_count": 50
  }
}
```

### Read-Heavy Optimization

1. **Increase replicas**: Each replica serves queries independently. 2-3 replicas for search-heavy workloads.
2. **Force merge read-only indexes**: `POST /my-index/_forcemerge?max_num_segments=1` -- reduces segments, improves query performance. Only on indexes that are no longer written to.
3. **Use index sorting**: Pre-sort data at index time to enable early termination of top-N queries:
   ```json
   {
     "settings": {
       "index": {
         "sort.field": ["created_at"],
         "sort.order": ["desc"]
       }
     }
   }
   ```
4. **Request cache**: Automatically caches aggregation results for unchanged data. Size with `indices.requests.cache.size` (default: 1% heap).
5. **Query cache**: Caches filter clause results. Auto-managed per segment.
6. **Fielddata for aggregations**: Use `doc_values` (default on, column-oriented) instead of `fielddata` (row-oriented, heap-hungry).
7. **_source filtering**: Return only needed fields to reduce network overhead:
   ```json
   { "_source": ["title", "price", "category"], "query": { ... } }
   ```
8. **Routing**: Direct queries to specific shards when the partition key is known:
   ```json
   GET /products/_search?routing=electronics
   ```

### CDC Pipeline: Source of Truth to Search Index

```
PostgreSQL (source of truth)
  ↓ (Debezium CDC connector)
Kafka (change events topic)
  ↓ (Kafka Connect Elasticsearch/OpenSearch sink)
Elasticsearch (search index)
```

**Best practices**:
- PostgreSQL is always the source of truth; Elasticsearch is a derived read-optimized projection
- Use Debezium for CDC to capture all changes (inserts, updates, deletes)
- Kafka provides buffering and replay capability if the search index falls behind
- Monitor consumer lag to detect indexing delays
- Include a `last_updated` timestamp for consistency verification
- Handle deletes: Use Debezium's tombstone events to delete from Elasticsearch

### Multi-Tenant Search Architecture

| Strategy | Isolation | Complexity | Best For |
|----------|-----------|------------|----------|
| **Index per tenant** | Strong | High (many indexes) | Large tenants, regulatory requirements |
| **Filtered alias per tenant** | Medium | Medium | Most SaaS applications |
| **Routing per tenant** | Medium | Low | Balanced approach |
| **Single shared index** | Low | Low | Small tenants, cost-sensitive |

**Recommended for most SaaS**: Routing-based tenancy with `tenant_id` as the routing key. Ensures queries hit only the relevant shard(s) while maintaining a single logical index:

```json
// Index with routing
PUT /products/_doc/123?routing=tenant-abc
{ "tenant_id": "tenant-abc", "title": "Widget", ... }

// Search with routing + filter
GET /products/_search?routing=tenant-abc
{
  "query": {
    "bool": {
      "must": [{ "match": { "title": "widget" } }],
      "filter": [{ "term": { "tenant_id": "tenant-abc" } }]
    }
  }
}
```

Always include the `tenant_id` filter even with routing -- routing is a performance optimization, not a security boundary.

---

## Cross-References

- **SQL Specialist** (`references/sql-specialist.md`): PostgreSQL full-text search (tsvector/tsquery), GIN indexes for search, when to stay with PostgreSQL vs move to dedicated search
- **Cache Specialist** (`references/cache-specialist.md`): Caching search results, autocomplete caching, Redis for popular query caching
- **Data Pipeline** (`references/data-pipeline.md`): CDC from source databases to search indexes, Debezium connectors, Kafka sink connectors for Elasticsearch/OpenSearch
- **NoSQL Specialist** (`references/nosql-specialist.md`): Vector databases (pgvector, Qdrant, Pinecone) for pure vector search vs Elasticsearch hybrid search
- **Migration Specialist** (`references/migration-specialist.md`): Migrating between search engines, reindexing strategies during schema changes
