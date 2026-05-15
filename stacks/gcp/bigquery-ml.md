---
title: BigQuery ML
description: "Train and predict in SQL inside BigQuery — linear/logistic/GBM/DNN models plus `REMOTE MODEL` to invoke Vertex AI Gemini and embedding models from SQL."
product:
  name: BigQuery ML
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, database-architect]
  authoritative_url: https://cloud.google.com/bigquery/docs/bqml-introduction
  notes: "Direct Vertex AI Gemini integration via `CREATE MODEL ... REMOTE WITH CONNECTION`; `ML.GENERATE_TEXT` and `ML.GENERATE_EMBEDDING` for LLM-in-SQL."
---

## What it is

BigQuery ML lets you train and predict ML models directly in SQL inside BigQuery. Native model types (linear/logistic regression, K-means, ARIMA, boosted trees, deep neural networks, autoencoders) train on warehouse data without moving it. **Remote models** call Vertex AI Gemini / embedding models from SQL — generate text, generate embeddings, classify, all via `ML.GENERATE_TEXT(...)` and `ML.GENERATE_EMBEDDING(...)`.

Authoritative reference: [cloud.google.com/bigquery/docs/bqml-introduction](https://cloud.google.com/bigquery/docs/bqml-introduction).

## When to use

Pick BigQuery ML when:
- Training data lives in BigQuery and the model is simple (linear regression, GBM)
- Batch ML scoring on warehouse data — classification, summarization, embeddings
- "ML for the data analyst" without involving Python infrastructure
- Batch generation of embeddings for vector search

Don't use BigQuery ML when:
- You need PyTorch / JAX / custom models — use [Vertex AI](/stacks/gcp/vertex-ai/) custom training
- Online low-latency inference — BigQuery is analytical, per-query overhead is seconds
- Complex feature engineering pipelines — [Vertex AI Pipelines](/stacks/gcp/vertex-ai/) + Feature Store

## 2025-2026 currency anchors

- **Remote models** via `CREATE MODEL ... REMOTE WITH CONNECTION` — invoke Gemini 2.5 Flash / Pro / Flash-Lite / Vertex embedding models from SQL.
- **`ML.GENERATE_TEXT`** for text generation; **`ML.GENERATE_EMBEDDING`** for embeddings; **`ML.UNDERSTAND_TEXT`** for built-in NLP.
- **Object tables** + BQML for image / audio analysis on Cloud Storage data.

## Patterns

### Native classifier

```sql
CREATE OR REPLACE MODEL `proj.dataset.churn_model`
OPTIONS(model_type='LOGISTIC_REG', input_label_cols=['churned']) AS
SELECT * EXCEPT(customer_id) FROM `proj.dataset.churn_training_data`;

SELECT customer_id, predicted_churned, predicted_churned_probs
FROM ML.PREDICT(
  MODEL `proj.dataset.churn_model`,
  (SELECT * FROM `proj.dataset.new_customers`)
);
```

### Gemini-from-SQL

```sql
-- Create remote model pointing to Gemini 2.5 Flash
CREATE OR REPLACE MODEL `proj.dataset.gemini_flash`
REMOTE WITH CONNECTION `proj.us.gemini-connection`
OPTIONS (endpoint = 'gemini-2.5-flash');

-- Generate text from SQL
SELECT *,
  ml_generate_text_result['candidates'][0]['content']['parts'][0]['text'] AS summary
FROM ML.GENERATE_TEXT(
  MODEL `proj.dataset.gemini_flash`,
  (SELECT CONCAT('Summarize: ', body) AS prompt FROM `proj.dataset.articles` LIMIT 100),
  STRUCT(0.2 AS temperature, 1024 AS max_output_tokens)
);

-- Generate embeddings
SELECT *,
  ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `proj.dataset.text_embedding_model`,
  (SELECT title AS content FROM `proj.dataset.articles`)
);
```

This pattern collapses a lot of ML-in-pipeline architecture into a single SQL query. Use for batch embedding generation, classification, summarization on warehouse data.

## Anti-patterns

- **BQML for online inference** — analytical store, not request-path latency.
- **`ML.GENERATE_TEXT` without rate limiting** on a billion-row table — you'll exhaust Vertex AI quota and your budget.
- **Untracked model versions** — version-control the SQL and the connection config.

## Gotchas

- **Quotas**: `ML.GENERATE_TEXT` on Gemini consumes Vertex AI Generative AI quota; not unlimited.
- **Connection setup**: Remote models require a BigQuery → Vertex AI connection with appropriate IAM bindings.
- **Cost**: Native BQML training uses slots; Gemini calls use Vertex AI pricing per token.

## Cross-references

- Related: [BigQuery](/stacks/gcp/bigquery/), [Vertex AI](/stacks/gcp/vertex-ai/), [Gemini](/stacks/gcp/gemini/)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [database-architect on GCP](/stacks/gcp/database-architect/)
- Authoritative: [cloud.google.com/bigquery/docs/bqml-introduction](https://cloud.google.com/bigquery/docs/bqml-introduction)
