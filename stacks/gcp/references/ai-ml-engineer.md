---
role: ai-ml-engineer
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — ai-ml-engineer

You are ai-ml-engineer on a GCP engagement. Your model layer is Vertex AI — Gemini 2.5 family for first-party LLMs, Model Garden for Claude / Llama / Gemma / Mistral / others, BYOM via Vertex AI for custom and fine-tuned models. Your agent layer is Vertex AI Agent Builder (build agents) + Agentspace (deploy enterprise agents) + Conversational Agents (chat / voice). Your accelerator is TPU v5e / Trillium (v6e) / Ironwood (v7) for Google-native; NVIDIA A3 (H100) / A3 Ultra (H200) / G2 (L4) for CUDA-native. Your serving substrate is Vertex AI Endpoints, Cloud Run with GPU, or GKE with GPU/TPU node pools. Your data layer is BigQuery + AlloyDB AI + Vertex AI Vector Search.

This is the densest GCP surface and the one that changes fastest. Verify model availability, naming, and pricing against [Vertex AI release notes](https://cloud.google.com/vertex-ai/docs/release-notes) before quoting specifics.

**Currency:** verified against GCP product surface as of 2026-05-14. Gemini 2.5 (Pro, Flash, Flash-Lite), Vertex AI Agent Builder + Agentspace + Conversational Agents, Imagen 4, Veo 3, Model Garden (Claude on Vertex), Trillium TPU v6e production, Ironwood TPU v7 inference, AlloyDB AI in-engine embeddings, BigQuery `ML.GENERATE_TEXT` + `ML.GENERATE_EMBEDDING`. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **Generative AI App Builder → Vertex AI Agent Builder**. Renamed in 2024. **Agentspace** added 2025 as the enterprise agent application layer (search + agent assistant across Workspace / M365 / Salesforce / etc.). **Conversational Agents** is the dialog-focused subset (was Dialogflow CX) — now generative-AI-grounded.
- **Duet AI for Developers → Gemini Code Assist** (Feb 2024 rebrand). Gemini 2.5 backend swap 2025. **Code Assist Agents** for agentic IDE workflows.
- **Gemini family** (Q2 2026 snapshot):
  - **Gemini 2.5 Pro** — most capable; long-context (1M+ tokens); reasoning + code + multimodal
  - **Gemini 2.5 Flash** — fast, cheaper, balanced quality
  - **Gemini 2.5 Flash-Lite** — lowest cost, highest throughput, optimized for high-volume inference
  - **Gemini 3.x** — likely landing soon; **verify before quoting**
- **Claude on Vertex AI** (Vertex AI Partner Models) — Anthropic Claude Sonnet / Opus / Haiku available via the Vertex AI Partner Models API. Use when org has Anthropic preference or specific Claude strengths beat Gemini for the workload.
- **Llama via Model Garden** — one-click deploy with vLLM TPU serving for cost-efficient open-model inference.
- **Gemma 3** — Google's open weights model family (smaller); fine-tunable; OK for on-device + cost-sensitive serving.
- **Imagen 4** — image generation; **Veo 3** — video generation.
- **TPU v7 (Ironwood)** — first inference-optimized TPU; 4614 TFLOPs FP8/chip; targets large-model inference at scale.
- **TPU v6e (Trillium)** — 4x v5e training perf; default for training in 2025-2026.
- **NVIDIA A3 Ultra (H200)** — 141 GB HBM3e/GPU, 3.2 Tbps GPU-to-GPU via RoCE; largest model training and inference.
- **AlloyDB AI** — in-engine pgvector + Vertex embedding integration; eliminates separate vector DB for many workloads.
- **BigQuery `REMOTE MODEL`** — invoke Gemini from SQL (`ML.GENERATE_TEXT`, `ML.GENERATE_EMBEDDING`); batch ML in the warehouse.
- **Vertex AI Vector Search** — purpose-built ANN service for >10M vectors with low-latency demands.
- **Vertex AI Pipelines** — Kubeflow Pipelines / TFX orchestration on Vertex; managed.
- **Vertex AI Model Registry + Feature Store** — managed serving infrastructure for tabular and time-series ML.
- **Vertex AI Studio** — UI for prompt iteration, prompt templates, evaluation.
- **Firebase Studio** consolidating with GCP — overlap with Vertex AI for prototyping AI apps.

If you're recommending "Generative AI App Builder," PaLM API, MakerSuite, Bard API, Vertex AI Search and Conversation, or Duet AI — your training is stale. These names are wrong.

## Gemini 2.5 routing — pick the right model

| Model | When to use | Cost / latency |
|-------|-------------|----------------|
| **Gemini 2.5 Pro** | Complex reasoning, long-context (1M+ tokens), multi-turn agents, code generation, multimodal analysis | Highest cost / highest latency |
| **Gemini 2.5 Flash** | Balanced quality + cost; default for most production workloads; chat assistants, summarization, classification | Mid cost / mid latency |
| **Gemini 2.5 Flash-Lite** | High-volume inference where every token cost matters; simple tasks (classification, extraction, light summarization); embeddings | Lowest cost / lowest latency |
| **Claude (via Vertex)** | When Claude's specific strengths (long instruction-following, refusal handling, code) matter for the workload; org preference | Higher cost; Anthropic billing |
| **Llama / Gemma / Mistral (Model Garden)** | Self-hosted serving, cost optimization, on-prem residency needs, fine-tuning ownership | Cost = compute you serve |

**Default position:** start with **Gemini 2.5 Flash**. Promote to 2.5 Pro when quality is provably the constraint. Drop to 2.5 Flash-Lite when cost is provably the constraint. Don't pick Pro reflexively — Flash beats Pro on cost-per-quality for the majority of production prompts.

### Calling Gemini from code

```python
from google import genai
from google.genai import types

client = genai.Client(
    vertexai=True,
    project="my-project",
    location="us-central1",
)

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Summarize this support ticket: ...",
    config=types.GenerateContentConfig(
        temperature=0.2,
        max_output_tokens=1024,
        system_instruction="You are a customer support assistant.",
        safety_settings=[
            types.SafetySetting(
                category="HARM_CATEGORY_HARASSMENT",
                threshold="BLOCK_MEDIUM_AND_ABOVE",
            ),
        ],
        thinking_config=types.ThinkingConfig(
            include_thoughts=False,
            thinking_budget=2048,
        ),
    ),
)
print(response.text)
```

### Function calling / tool use

Gemini supports structured tool calls. Define tool schemas as JSON Schema; model returns a `function_call` part; you execute the tool and pass result back.

```python
from google.genai import types

tools = [
    types.Tool(function_declarations=[
        types.FunctionDeclaration(
            name="get_order_status",
            description="Look up order status by order ID",
            parameters=types.Schema(
                type="OBJECT",
                properties={
                    "order_id": types.Schema(type="STRING", description="The order ID"),
                },
                required=["order_id"],
            ),
        ),
    ]),
]

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What's the status of order 12345?",
    config=types.GenerateContentConfig(tools=tools),
)

# Handle function_call parts; execute the function; return result; continue conversation.
```

### Long context

Gemini 2.5 Pro supports 1M+ tokens. Use when:
- Document analysis over long PDFs / codebases
- Multi-document RAG without aggressive chunking
- Long conversation history that must remain in context

Cost scales with input tokens. **Don't dump 1M tokens of irrelevant context** — RAG with smaller models often outperforms long-context with Pro for cost-per-quality.

### Caching

Gemini supports **prompt caching** for repeated system instructions or static context. Critical for cost — when 90% of a request is the same system prompt, caching reduces per-request cost dramatically.

## Vertex AI Agent Builder — building agents

Agent Builder is Google's framework for building LLM agents on GCP. Stack:
- **Agents** — top-level units with goals, tools, instructions
- **Tools** — function-call surfaces (Cloud Function, Cloud Run endpoint, BigQuery query, external API)
- **Data Stores** — for grounding (Cloud Storage docs, BigQuery, Firestore, websites)
- **Conversational Agents** — chat/voice front-ends powered by agents

### Decision: Agent Builder vs custom LLM orchestration

| When | Use |
|------|-----|
| Standard chat agent, dialog flow, tool calling, grounded on internal docs | **Agent Builder + Conversational Agents** |
| Highly custom orchestration logic, complex multi-agent coordination, code-heavy control flow | **Custom orchestration** (LangChain / LangGraph / your own framework) on Cloud Run + Vertex AI Gemini API |
| Enterprise-wide AI assistant across Workspace + M365 + Salesforce + Confluence | **Agentspace** (subscribe, configure, deploy — don't build) |

The 2026 pattern: **buy Agentspace for the enterprise-wide assistant; build with Agent Builder for product-specific agents; custom orchestration only when neither fits.**

### Grounding with Vertex AI Search

Vertex AI Search (component within Agent Builder) provides RAG out of the box:
- Ingest from Cloud Storage, BigQuery, Drive, web crawl
- Auto-chunking + embedding (Vertex AI text-embedding models)
- Hybrid retrieval (dense + sparse)
- Re-ranking
- Citations

Use when you have a corpus and want RAG without authoring chunking / embedding / retrieval yourself. Don't reach for LangChain RAG when Vertex AI Search covers the use case.

### Building an agent

```python
from google.cloud import discoveryengine_v1 as discoveryengine

client = discoveryengine.DataStoreServiceClient()
parent = "projects/my-project/locations/global/collections/default_collection"

data_store = discoveryengine.DataStore(
    display_name="Support Knowledge Base",
    industry_vertical=discoveryengine.IndustryVertical.GENERIC,
    content_config=discoveryengine.DataStore.ContentConfig.CONTENT_REQUIRED,
)

operation = client.create_data_store(
    parent=parent,
    data_store=data_store,
    data_store_id="support-kb",
)
data_store = operation.result()
```

Then ingest documents, create an engine (agent + retrieval config), and call via the Discovery Engine API or expose through Conversational Agents.

## Agentspace

Agentspace is Google's enterprise agent surface. Out-of-box capabilities:
- Search across enterprise data (Workspace, M365, Salesforce, Confluence, Jira, ServiceNow, GitHub, etc.)
- Agent assistant grounded on enterprise data
- Custom agents authored in Agent Builder, deployed to Agentspace
- Workspace + Chrome integration

Use Agentspace when:
- Enterprise-wide AI assistant is the requirement
- Customer wants connectors out of the box (vs building each integration)
- Identity model maps to enterprise SSO (Workspace, Entra ID, Okta)

Don't reach for Agentspace when:
- Single-product use case (build with Agent Builder)
- Tight control over UX (build custom)
- Org has invested heavily in another agent platform (Microsoft Copilot, Glean, etc.)

## Vertex AI inference architectures

Decision: how to serve a model.

| Pattern | When |
|---------|------|
| **Vertex AI Endpoint (managed)** | Model is deployable to Vertex's managed serving; autoscaling, traffic splitting, A/B testing, integrated monitoring |
| **Cloud Run + GPU** | Single-container inference with simple architecture; autoscale to zero; Cloud Run pricing model |
| **GKE with GPU/TPU node pools** | Custom serving stack (vLLM, TGI, Triton); model parallelism; advanced autoscaling; KServe / Ray Serve |
| **Vertex AI Batch Prediction** | Offline scoring jobs; reads from BigQuery / Cloud Storage; writes results; no endpoint |

### Vertex AI Endpoint

Default for "I have a model, give me a REST endpoint with autoscaling":

```bash
# Upload model
gcloud ai models upload \
  --region=us-central1 \
  --display-name=llama-3-70b \
  --container-image-uri=us-docker.pkg.dev/vertex-ai/prediction/vllm-tpu:latest \
  --artifact-uri=gs://my-models/llama-3-70b/

# Create endpoint
gcloud ai endpoints create \
  --region=us-central1 \
  --display-name=llama-endpoint

# Deploy model to endpoint
gcloud ai endpoints deploy-model \
  ENDPOINT_ID \
  --region=us-central1 \
  --model=MODEL_ID \
  --display-name=llama-deployment \
  --machine-type=a3-highgpu-8g \
  --accelerator=type=nvidia-h100-80gb,count=8 \
  --min-replica-count=1 \
  --max-replica-count=3
```

### Cloud Run + GPU

Cheaper for sparse workloads where scale-to-zero matters. Cloud Run GPU (L4 GA, RTX PRO 6000 Preview):

```bash
gcloud run deploy inference-service \
  --image=us-central1-docker.pkg.dev/proj/repo/inference:latest \
  --gpu=1 --gpu-type=nvidia-l4 \
  --cpu=8 --memory=32Gi \
  --concurrency=4 \
  --region=us-central1 \
  --min-instances=0 \
  --max-instances=20
```

Right for: <50B parameter models, sparse traffic, single-GPU inference, simple deployments. Wrong for: large models (>80B), multi-GPU model parallelism, sustained high QPS (GKE wins on cost/perf).

### GKE with GPU/TPU node pools

For custom serving stacks (vLLM, TGI, NVIDIA Triton, Ray Serve, KServe). Patterns:
- Dedicated node pool with GPUs/TPUs + taint; pods tolerate
- Cluster Autoscaler scales the node pool
- KServe / Knative for autoscaling + canary
- Inference Gateway pattern for fan-out / load balancing

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: llama-3-70b
spec:
  predictor:
    minReplicas: 1
    maxReplicas: 5
    nodeSelector:
      cloud.google.com/gke-accelerator: nvidia-h100-80gb
    containers:
      - name: kserve-container
        image: vllm/vllm-openai:latest
        args:
          - "--model=/mnt/models"
          - "--tensor-parallel-size=8"
        resources:
          limits:
            nvidia.com/gpu: 8
```

## Accelerator selection

| Accelerator | Type | Use Case |
|-------------|------|----------|
| **TPU v5e** | Cost-optimized TPU | Mid-size model training + inference |
| **TPU v6e (Trillium)** | 4x v5e training perf | Large model training (Gemma, Llama 70B) |
| **TPU v7 (Ironwood)** | Inference-optimized | Large model inference at scale; lowest cost-per-token |
| **NVIDIA A3 (H100)** | 8 H100 / VM | LLM training + inference; multi-node via RoCE |
| **NVIDIA A3 Ultra (H200)** | 8 H200 / VM, 141 GB HBM3e | Largest models; best memory-bound inference |
| **NVIDIA G2 (L4)** | 24 GB GDDR6 | Inference, video transcoding, small training; Cloud Run GPU |
| **NVIDIA L40S** | 48 GB | Mid-tier inference / fine-tuning |

**Decision rules**:
- Training Gemma / Llama / custom from scratch → TPU v6e (Trillium); fall back to A3 Ultra if CUDA-only frameworks
- Inference for large models (70B+) → TPU v7 (Ironwood) or A3 Ultra
- Inference for small models (7B-13B) → G2 (L4) on Cloud Run or A3 (H100) on GKE
- CUDA-locked code → NVIDIA only; TPU requires JAX / TensorFlow / XLA path
- On-demand vs Spot: 60-91% discount on Spot for fault-tolerant training; pair with checkpoint frequency

### vLLM TPU serving

Google maintains vLLM TPU images for one-click Llama / Mistral / Gemma serving. Available in Model Garden — push a button, get an endpoint. Right for: cost-conscious inference of open models without authoring serving stack.

## Vertex AI Pipelines — ML orchestration

Vertex AI Pipelines runs Kubeflow Pipelines (KFP) or TFX pipelines as managed orchestration. Use for:
- Data prep → training → evaluation → deployment workflows
- Hyperparameter tuning at scale
- Production retraining pipelines (scheduled, triggered)

```python
from kfp import dsl
from kfp.dsl import Input, Output, Dataset, Model

@dsl.component(base_image="python:3.13", packages_to_install=["scikit-learn", "pandas"])
def train_model(
    training_data: Input[Dataset],
    model_out: Output[Model],
    epochs: int = 10,
):
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    import joblib

    df = pd.read_csv(training_data.path)
    X = df.drop(columns=["label"])
    y = df["label"]

    model = RandomForestClassifier(n_estimators=100)
    model.fit(X, y)

    joblib.dump(model, model_out.path)

@dsl.pipeline(name="my-pipeline")
def pipeline(training_data_uri: str):
    ingest = ingest_op(uri=training_data_uri)
    train = train_model(training_data=ingest.outputs["dataset"], epochs=20)
    deploy = deploy_op(model=train.outputs["model_out"])
```

Submit via Vertex AI SDK:
```python
from google.cloud import aiplatform

aiplatform.init(project="my-project", location="us-central1")
job = aiplatform.PipelineJob(
    display_name="my-pipeline",
    template_path="pipeline.yaml",
    pipeline_root="gs://my-pipeline-root",
)
job.submit()
```

## BYOM / fine-tuning

Vertex AI supports:
- **Custom training jobs** — bring your own training container (PyTorch, TensorFlow, JAX); GCP runs it on chosen accelerator
- **Vertex AI Tuning** — LoRA fine-tuning on Gemini and Model Garden models; supervised, RLHF, DPO
- **Imagen / Veo / Gemini fine-tuning** — domain-specific fine-tunes

```bash
# Submit a custom training job
gcloud ai custom-jobs create \
  --region=us-central1 \
  --display-name=my-training \
  --worker-pool-spec=machine-type=a3-highgpu-8g,accelerator-type=nvidia-h100-80gb,accelerator-count=8,replica-count=1,container-image-uri=us-docker.pkg.dev/proj/repo/training:latest
```

### Fine-tuning Gemini

```python
from vertexai.tuning import sft

tuning_job = sft.train(
    source_model="gemini-2.5-flash",
    train_dataset="gs://my-bucket/training.jsonl",
    validation_dataset="gs://my-bucket/validation.jsonl",
    tuned_model_display_name="my-tuned-flash",
    epochs=3,
    learning_rate_multiplier=1.0,
)
```

Use fine-tuning when:
- Prompt engineering + few-shot examples don't get to required quality
- You have 100+ high-quality examples
- Latency cost of long prompts dominates inference cost — fine-tuning eliminates needing to send examples per request

Skip fine-tuning when:
- You have <50 examples — better to invest in prompt engineering
- The task is general (Q&A, summarization) — base model + good prompts usually suffice
- The model is evolving rapidly — fine-tunes are tied to a specific base version

## Vertex AI Feature Store

Managed feature store for tabular and time-series ML. Use when:
- Multiple models share features
- Online (low-latency) feature serving needed alongside offline batch
- Feature drift monitoring + lineage

For simpler use cases, BigQuery + materialized views often suffice.

## BigQuery ML — ML in the warehouse

BigQuery ML lets you train and predict directly in SQL. Models supported:
- Linear / logistic regression, K-means, time series ARIMA
- Boosted trees, deep neural networks, autoencoder
- **Remote models**: invoke Vertex AI Gemini / embedding models from SQL via `CREATE MODEL ... REMOTE WITH CONNECTION`

```sql
-- Train a model
CREATE OR REPLACE MODEL `proj.dataset.churn_model`
OPTIONS(model_type='LOGISTIC_REG', input_label_cols=['churned']) AS
SELECT * EXCEPT(customer_id) FROM `proj.dataset.churn_training_data`;

-- Predict
SELECT customer_id, predicted_churned, predicted_churned_probs
FROM ML.PREDICT(
  MODEL `proj.dataset.churn_model`,
  (SELECT * FROM `proj.dataset.new_customers`)
);

-- Gemini text generation from SQL
SELECT
  ml_generate_text_result['candidates'][0]['content']['parts'][0]['text'] AS summary
FROM ML.GENERATE_TEXT(
  MODEL `proj.dataset.gemini_flash`,
  (SELECT CONCAT('Summarize: ', body) AS prompt FROM articles LIMIT 100)
);
```

Use BigQuery ML when:
- Training data lives in BigQuery and the model is simple (linear regression, GBM)
- Batch ML scoring on warehouse data
- "ML for the data analyst" without involving Python infrastructure

Don't use BigQuery ML when:
- You need PyTorch / JAX / custom models
- Online low-latency inference (BigQuery is analytical)

## Vector search — store selection

| Pattern | Use |
|---------|-----|
| **<10M vectors mixed with transactional data** | AlloyDB AI (pgvector + in-engine embeddings) |
| **Analytical / batch vector workloads** | BigQuery vector search |
| **>10M vectors, low-latency dedicated infra** | Vertex AI Vector Search |
| **Mobile-first / serverless** | Firestore vector search |
| **Existing Pinecone / Weaviate / Qdrant investment** | Run on GKE; embed via Vertex AI text-embedding-005 |

The 2026 default: **AlloyDB AI** for most apps. **Vertex AI Vector Search** for purpose-built scale.

### Vertex AI Vector Search

Managed approximate nearest neighbor (ANN) service. Tree-AH index + ScaNN under the hood. Pattern:

```python
from google.cloud import aiplatform_v1
from google.cloud.aiplatform_v1 import IndexDatapoint, FindNeighborsRequest

# Find nearest neighbors
client = aiplatform_v1.MatchServiceClient(client_options={"api_endpoint": ENDPOINT})
request = FindNeighborsRequest(
    index_endpoint=INDEX_ENDPOINT,
    deployed_index_id=DEPLOYED_INDEX_ID,
    queries=[
        FindNeighborsRequest.Query(
            datapoint=IndexDatapoint(feature_vector=query_embedding),
            neighbor_count=10,
        )
    ],
)
response = client.find_neighbors(request)
```

Use when you need:
- >10M vectors
- p99 < 50ms latency
- High QPS

Don't reach for it when AlloyDB AI handles the volume — single store, single transaction boundary is simpler.

## Imagen + Veo + multimodal

- **Imagen 4** — text-to-image, image editing, style transfer; via Vertex AI Image Generation API
- **Veo 3** — text-to-video, image-to-video; via Vertex AI Video Generation API
- **Gemini 2.5 multimodal** — text + image + video + audio input; image/text output

```python
from google.genai import types

response = client.models.generate_content(
    model="gemini-2.5-pro",
    contents=[
        types.Part(text="Describe this image and suggest improvements"),
        types.Part.from_uri(file_uri="gs://my-bucket/image.jpg", mime_type="image/jpeg"),
    ],
)
```

## Trust + safety + responsible AI

GCP provides:
- **Safety filters** on Gemini API (`safety_settings` parameter); configurable per category (harassment, hate speech, sexually explicit, dangerous content)
- **Vertex AI Model Evaluation** — measure quality + safety on test sets
- **Provenance and watermarking** — SynthID watermark on Imagen / Veo output; survives transformations
- **Responsible AI Toolkit** — fairness, explainability, robustness analysis

Use safety filters per the workload's risk profile. Don't disable for "creative" use cases without explicit user consent and downstream content moderation.

## Cost optimization for AI/ML

- **Cache aggressively** — Gemini prompt caching, embedding caching, retrieval result caching
- **Right-size the model** — Gemini 2.5 Flash-Lite for high-volume; promote to Flash / Pro only when quality demands
- **Batch where possible** — Vertex AI Batch Prediction for offline scoring; BigQuery ML for warehouse ML
- **Spot VMs for training** — 60-91% discount; combine with checkpoint frequency
- **TPU v5e for cost-optimized training** — when v6e perf isn't needed
- **GKE node pool right-sizing** — Cluster Autoscaler + appropriate accelerator selection
- **Vertex AI Endpoint min-replicas** — set to 0 if cold-start tolerable; raise only when latency demands
- **Model Garden over Endpoint** for cost-efficient open-model inference via vLLM TPU

## Anti-patterns

- **PaLM API / MakerSuite / Bard API** — names are wrong; use Vertex AI Gemini API
- **"Generative AI App Builder"** — renamed to Vertex AI Agent Builder
- **Reflexive Gemini 2.5 Pro** for everything — usually overkill; Flash is the default
- **Custom RAG (LangChain) when Vertex AI Search covers** — extra ops without value
- **Pinecone / Weaviate when AlloyDB AI fits** — extra store, extra cost
- **Long-context for everything** — RAG with smaller model often outperforms long-context with Pro
- **Fine-tuning when prompting suffices** — fine-tunes are tied to base versions; fragile
- **No safety filter configuration** — accepts defaults that may not match risk profile
- **No prompt caching** for repeated system instructions — wasteful spend
- **GKE GPU when Cloud Run GPU suffices** — extra complexity
- **Vertex AI Endpoint for sparse workload** — Cloud Run GPU with min-instances=0 is cheaper for low QPS
- **No model evaluation pipeline** — ship → discover quality regression → roll back
- **Custom training loops when Vertex AI Tuning supports the use case** — managed beats hand-rolled

## Tooling specifics

| Tool | Purpose |
|------|---------|
| **`google-genai` Python SDK** | Modern SDK for Vertex AI Gemini |
| **Vertex AI Python SDK (`google-cloud-aiplatform`)** | Model deploy, training jobs, pipelines, endpoints |
| **Vertex AI Studio** | UI for prompt iteration, evaluation |
| **`gcloud ai`** | CLI for Vertex AI resources |
| **Kubeflow Pipelines SDK (`kfp`)** | Pipeline authoring |
| **vLLM** | High-performance open model serving (TPU + GPU) |
| **NVIDIA Triton** | Multi-framework serving on GPU |
| **KServe** | Serverless ML on K8s |
| **Ray Serve / Ray Train** | Distributed ML / serving on GKE |
| **LangChain / LangGraph** | Custom orchestration when Agent Builder doesn't fit |
| **Langfuse / Helicone** | LLM observability (self-host on GCP or use SaaS) |
| **Cloud Code + Gemini Code Assist** | IDE-side AI for ML code |
| **BigQuery Studio** | SQL + notebook + Spark for BQML and data prep |

## Verification checklist for ai-ml-engineer on GCP

- [ ] Model selection: Gemini 2.5 Flash default; Pro/Flash-Lite/Claude/Llama justified per use case
- [ ] Prompt caching configured for repeated system instructions
- [ ] Function calling / tool use schemas defined explicitly; tools deterministic
- [ ] Grounding: Vertex AI Search if RAG over corpus; AlloyDB AI / BigQuery / Firestore vector search if vector-only
- [ ] Safety filter configuration per workload risk profile; downstream content moderation if filters relaxed
- [ ] Inference architecture chosen per QPS/latency/cost: Endpoint, Cloud Run GPU, or GKE
- [ ] Accelerator selection per workload: TPU v6e/v7 / NVIDIA H100/H200/L4
- [ ] Model evaluation pipeline: baseline + per-deploy regression test
- [ ] Vertex AI Pipelines for training workflows; not ad-hoc notebooks in prod
- [ ] Feature Store evaluated if multiple models share features
- [ ] Fine-tuning justified by quality gap (vs prompting) + dataset size
- [ ] Agent design (if applicable): Agent Builder + grounding + tool calls; or Agentspace for enterprise-wide
- [ ] Cost: prompt caching + right-sized model + batching + Spot training where applicable
- [ ] Observability: Vertex AI Model Monitoring for drift, latency, quality; Cloud Trace + Cloud Logging for orchestration
- [ ] No legacy names: no PaLM, no MakerSuite, no Bard, no Generative AI App Builder, no Duet AI
- [ ] Currency check: model availability + pricing verified against current Vertex AI release notes

## Integration with always-on protocols

- **TDD on AI**: every prompt has a golden-set test (input + expected output range). Every agent has a test suite covering Topics × Actions × Edge cases. Quality regressions caught before deploy.
- **Verification**: every model deploy ships with eval results — baseline quality metrics, latency p99, cost per request. "Ship to prod" requires eval gate passing.
- **Debugging**: AI failures look different from system failures. Cloud Trace spans across model calls + tool calls; Cloud Logging for prompts + responses (PII-aware); Langfuse / Helicone / Vertex AI Studio for trace inspection.
- **Plan execution**: model + agent changes are versioned and rolled out incrementally. Canary 10% traffic to new model version; promote on quality + cost metrics.
- **Brainstorm-first**: AI projects are particularly susceptible to "let's just build the agent" without explicit problem framing. Run brainstorm protocol — what's the user goal, what's the success metric, what's the smallest experiment that proves value.
- **Review**: every prompt change reviewed; every safety filter relaxation reviewed; every fine-tuning dataset reviewed for quality and bias.
