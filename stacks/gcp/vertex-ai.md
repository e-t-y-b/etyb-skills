---
title: Vertex AI
description: GCP's unified ML platform — Gemini 2.5 family, Model Garden (Claude/Llama/Gemma/Mistral), Vector Search, Pipelines, Feature Store, Endpoints, Tuning.
product:
  name: Vertex AI
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, backend-architect]
  authoritative_url: https://cloud.google.com/vertex-ai/docs
  notes: "Gemini 2.5 family (Pro / Flash / Flash-Lite), Vertex AI Agent Builder generations, Imagen 4, Veo 3 — model lineup churns every quarter."
---

## What it is

Vertex AI is GCP's unified machine learning platform. It covers the full ML lifecycle:

- **Foundation models** — Gemini family (Pro / Flash / Flash-Lite), Imagen, Veo, plus partner models (Claude via Vertex)
- **Model Garden** — open weights models (Llama, Gemma, Mistral) with one-click deploy
- **Endpoints** — managed model serving with autoscaling and traffic splitting
- **Pipelines** — Kubeflow/TFX orchestration
- **Feature Store** — managed feature serving for tabular ML
- **Vector Search** — purpose-built ANN service
- **Tuning** — fine-tuning Gemini and Model Garden models
- **Studio** — UI for prompt iteration and evaluation
- **Agent Builder** — see dedicated [Agent Builder page](/stacks/gcp/agent-builder/)

This page covers Vertex AI as a platform. For Gemini-specific API depth see [Gemini](/stacks/gcp/gemini/); for agent building see [Vertex AI Agent Builder](/stacks/gcp/agent-builder/); for enterprise agent surface see [Agentspace](/stacks/gcp/agentspace/).

Authoritative reference: [cloud.google.com/vertex-ai/docs](https://cloud.google.com/vertex-ai/docs) — verify model availability and pricing against the [release notes](https://cloud.google.com/vertex-ai/docs/release-notes) before quoting specifics.

## When to use

Pick Vertex AI when:
- Building any LLM / GenAI feature on GCP — Gemini API, Claude on Vertex, Llama via Model Garden
- Managed ML model serving with autoscaling
- ML pipelines for training, fine-tuning, batch inference
- Vector search at scale (>10M vectors with low-latency demands)

Don't reach for Vertex AI when:
- BigQuery ML handles the simple case (`ML.GENERATE_TEXT`, `ML.GENERATE_EMBEDDING` in SQL) — see [BigQuery ML](/stacks/gcp/bigquery-ml/)
- Embeddings + pgvector in [AlloyDB AI](/stacks/gcp/alloydb/) cover the vector use case (<10M vectors)
- Inference is sparse and Cloud Run with GPU covers it

## 2025-2026 currency anchors

- **Gemini 2.5 family** — Pro (most capable, 1M+ context), Flash (balanced default), Flash-Lite (lowest cost / highest throughput).
- **Claude on Vertex AI** (Partner Models) — Anthropic Claude Sonnet / Opus / Haiku via the Vertex Partner Models API.
- **Llama / Gemma / Mistral** via Model Garden — one-click deploy with vLLM TPU serving.
- **Imagen 4** — image generation; **Veo 3** — video generation.
- **TPU v7 (Ironwood)** for inference; **TPU v6e (Trillium)** for training; **NVIDIA A3 Ultra (H200)** for largest models.
- **Vertex AI Studio** — UI for prompt iteration, prompt templates, evaluation.
- **Vertex AI Pipelines** — Kubeflow Pipelines / TFX orchestration on Vertex; managed.
- **Vertex AI Feature Store** — online (low-latency) + offline (batch) feature serving.
- **Vertex AI Vector Search** — Tree-AH + ScaNN under the hood; purpose-built for >10M vectors.

If your training data has "Generative AI App Builder", "PaLM API", "MakerSuite", "Bard API", or "Duet AI for Developers" — those names are wrong. See [Gemini Code Assist](/stacks/gcp/gemini-code-assist/), [Vertex AI Agent Builder](/stacks/gcp/agent-builder/), [Agentspace](/stacks/gcp/agentspace/) for current naming.

## Patterns

### Calling Gemini from code

See dedicated [Gemini page](/stacks/gcp/gemini/) for full coverage. Quick version:

```python
from google import genai
from google.genai import types

client = genai.Client(vertexai=True, project="my-project", location="us-central1")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Summarize this support ticket: ...",
    config=types.GenerateContentConfig(temperature=0.2, max_output_tokens=1024),
)
```

### Deploying a Model Garden model to a Vertex AI Endpoint

```bash
gcloud ai models upload \
  --region=us-central1 \
  --display-name=llama-3-70b \
  --container-image-uri=us-docker.pkg.dev/vertex-ai/prediction/vllm-tpu:latest \
  --artifact-uri=gs://my-models/llama-3-70b/

gcloud ai endpoints create --region=us-central1 --display-name=llama-endpoint

gcloud ai endpoints deploy-model ENDPOINT_ID \
  --region=us-central1 \
  --model=MODEL_ID \
  --machine-type=a3-highgpu-8g \
  --accelerator=type=nvidia-h100-80gb,count=8 \
  --min-replica-count=1 \
  --max-replica-count=3
```

### Vector Search

```python
from google.cloud import aiplatform_v1
from google.cloud.aiplatform_v1 import IndexDatapoint, FindNeighborsRequest

client = aiplatform_v1.MatchServiceClient(client_options={"api_endpoint": ENDPOINT})
request = FindNeighborsRequest(
    index_endpoint=INDEX_ENDPOINT,
    deployed_index_id=DEPLOYED_INDEX_ID,
    queries=[FindNeighborsRequest.Query(
        datapoint=IndexDatapoint(feature_vector=query_embedding),
        neighbor_count=10,
    )],
)
response = client.find_neighbors(request)
```

Use when: >10M vectors, p99 <50ms, high QPS. Otherwise AlloyDB AI / BigQuery vector / Firestore vector are simpler.

### Pipelines (KFP)

```python
from kfp import dsl

@dsl.component(base_image="python:3.13", packages_to_install=["scikit-learn"])
def train(...): ...

@dsl.pipeline(name="my-pipeline")
def pipeline(uri: str):
    ingest = ingest_op(uri=uri)
    train_step = train(data=ingest.outputs["dataset"])
    deploy(model=train_step.outputs["model_out"])
```

Submit via Vertex AI SDK; runs as managed orchestration.

### Inference architecture decision

| Pattern | When |
|---------|------|
| **Vertex AI Endpoint** | Managed serving, autoscaling, traffic splitting; default |
| **[Cloud Run](/stacks/gcp/cloud-run/) + GPU** | Single-container inference, scale-to-zero, simple deploys; <50B params |
| **[GKE](/stacks/gcp/gke/) with GPU/TPU pools** | Custom serving stacks (vLLM, TGI, Triton); multi-GPU model parallelism |
| **Vertex AI Batch Prediction** | Offline scoring jobs; reads from BigQuery / Cloud Storage |

## Anti-patterns

- **Stale model names** — "PaLM API", "MakerSuite", "Bard API", "Generative AI App Builder" don't exist anymore.
- **Reflexive Gemini 2.5 Pro** — Flash is the default; promote to Pro when quality is provably the constraint.
- **Vertex AI Endpoint for sparse workload** — Cloud Run GPU with `min-instances=0` is cheaper for low QPS.
- **Custom RAG (LangChain) when [Vertex AI Search](/stacks/gcp/agent-builder/) covers** — extra ops without value.
- **Pinecone / Weaviate when AlloyDB AI fits** — extra store, extra cost.
- **Fine-tuning when prompting suffices** — fine-tunes are tied to base versions; fragile.

## Gotchas

- **Model lineup churns quarterly.** Always verify against [release notes](https://cloud.google.com/vertex-ai/docs/release-notes).
- **Regional availability** of new models is staggered — `us-central1` first, others lag.
- **Quota** for Generative AI APIs is per-region per-model; request increases for high-volume.
- **`google-genai` SDK** is the modern Python path; older `google-cloud-aiplatform` is still maintained but split-purpose.

## Cross-references

- Related: [Gemini](/stacks/gcp/gemini/), [Vertex AI Agent Builder](/stacks/gcp/agent-builder/), [Agentspace](/stacks/gcp/agentspace/), [Gemini Code Assist](/stacks/gcp/gemini-code-assist/), [Imagen](/stacks/gcp/imagen/), [Veo](/stacks/gcp/veo/), [BigQuery ML](/stacks/gcp/bigquery-ml/), [AlloyDB](/stacks/gcp/alloydb/) (AlloyDB AI)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/)
- Authoritative: [cloud.google.com/vertex-ai/docs](https://cloud.google.com/vertex-ai/docs)
