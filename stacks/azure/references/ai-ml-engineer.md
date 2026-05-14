---
role: ai-ml-engineer
stack: azure
last_verified_on: "2026-05-14"
---

# Azure — ai-ml-engineer overlay

You're building AI / ML on Azure. Generative AI (Azure OpenAI / Foundry / Foundry Agents), classical ML (Azure ML), RAG (AI Search + Cosmos DiskANM + pgvector), agent orchestration (Semantic Kernel / AutoGen), responsible AI (Content Safety + evaluation). This overlay teaches you what Azure 2026 provides and how to wire it correctly.

You don't write the surrounding application code (backend-architect) or the security wrapper (security-engineer) — you design the model selection, prompt strategy, retrieval strategy, evaluation strategy, and the agent topology.

## What this role does on Azure

- Selects models from **AI Foundry catalog** (Azure OpenAI, Anthropic Claude, Mistral, Llama, Phi, partner/community).
- Designs **Azure OpenAI deployment** (PTU vs Standard vs Batch vs Global vs Data Zone).
- Designs **RAG pipelines** using **Azure AI Search** + **Cosmos DiskANN** + **pgvector**.
- Builds **agents** using **Foundry Agents** + **Semantic Kernel** + **AutoGen**.
- Implements **Content Safety** (filtering, jailbreak detection, groundedness).
- Implements **evaluation framework** (quality, safety, groundedness metrics).
- Operates **Azure ML** for classical training / fine-tuning / batch inference.
- Designs **Entra Agent ID** posture for agents in production.
- Implements **prompt flow** in AI Foundry for RAG / agent orchestration.
- Designs **PTU vs Standard** capacity strategy for production.

## Decision frameworks

### Model selection — AI Foundry catalog

AI Foundry (formerly Azure AI Studio) catalog has **1,900+ models** as of 2026-Q2:

**Models sold by Azure** (covered by Azure SLA + Microsoft commercial terms):

- GPT-4o, GPT-4o-mini, GPT-4.5, GPT-5.2 (latest), o1, o3, o4-mini (reasoning)
- DALL-E 3 (image generation)
- Whisper (ASR)
- text-embedding-3-small, text-embedding-3-large
- Anthropic Claude Opus, Sonnet, Haiku (Azure-only hyperscaler with both OpenAI + Anthropic frontier)
- Mistral Large, Mistral Small, Codestral
- Meta Llama 3 / 3.1 / 4 (8B, 70B, 405B variants)
- Microsoft Phi (3 / 4 small models — efficient, fine-tunable)

**Partner / community models** (not covered by Azure SLA — Microsoft hosts, partner provides):

- DeepSeek V3 / V3.2
- Kimi K2
- Stable Diffusion variants
- Many specialized models (medical, legal, coding)

**Deployment options per model**:

- **Managed compute (real-time endpoint)** — dedicated GPU / CPU, you pay for the SKU + uptime.
- **Serverless API (MaaS / pay-as-you-go)** — Microsoft hosts; per-token billing.
- **Self-hosted on AKS / VMs** — bring-your-own-infra (open-source / weights-available models only).

**Pick guide** (broad strokes for 2026-Q2):

| Use case | Pick |
|----------|------|
| Frontier reasoning / agents | GPT-5.2 or o3 (Azure OpenAI) or Claude Opus 4.7 |
| Cost-effective high-quality | Claude Sonnet 4.5 / 4.6 |
| Cheap fast classification / extraction | GPT-4o-mini or Phi-4 |
| Embeddings | text-embedding-3-large (1536/3072 dim) or text-embedding-3-small (1536) |
| Image generation | DALL-E 3 |
| Speech-to-text | Whisper |
| Coding tasks | Claude (any current) or GPT-5.2 |
| Fine-tunable open-weight | Phi-4 or Mistral Small |
| Confidential / on-prem | Phi-4 / Mistral via self-host on AKS |

**Anti-pattern: defaulting to GPT-4 for everything**. GPT-4o-mini and Phi-4 are 10-100× cheaper for classification / extraction / simple summarization. Use the smallest model that meets quality bar.

**Anti-pattern: choosing a model without an eval**. Without measurement, you're guessing. Run Foundry evaluation first; pick by data.

Cite: [Azure OpenAI models](https://learn.microsoft.com/azure/ai-services/openai/concepts/models), [AI Foundry model catalog](https://learn.microsoft.com/azure/ai-foundry/concepts/model-catalog-overview).

### Azure OpenAI deployment types

| Type | Use case | Capacity | Cost model |
|------|----------|----------|------------|
| **Standard** | Dev / prototyping / variable load | Shared, rate-limited (TPM-based) | Per-token |
| **Provisioned Throughput Units (PTU)** | Production with predictable load | Reserved capacity (regional, per-deployment) | Hourly per PTU |
| **Batch API** | Async high-throughput | Process up to 24h, 50% cost discount | Per-token (discounted) |
| **Global** | Highest availability via routing | Cross-region | Per-token (slightly higher) |
| **Data Zone** | Regulatory data residency | Restricted geographic routing | Per-token |

**Decision: PTU vs Standard for production.**

PTU advantages:
- Predictable latency (no rate-limiting)
- Capacity guaranteed (no 429 errors at peak)
- Lower TCO if utilization is high (typically >50% of provisioned capacity)

PTU disadvantages:
- Region-bound; capacity may be unavailable in some regions
- 1-month or 1-year commitment for best rates
- Fixed cost regardless of usage

**Pattern: PTU baseline + Standard burst**. PTU at 70-80% expected steady-state; spillover to Standard when PTU saturated. Code routes by checking quota headers.

**Anti-pattern: PTU at 100% expected peak**. You're paying for unused capacity off-peak. Right-size to 70-80%; let Standard handle bursts.

**Anti-pattern: starting at PTU without baseline data**. Run on Standard for 2-4 weeks to establish actual TPM patterns; then size PTU. The Foundry "capacity calculator" helps but real usage data is better.

**PTU quota** is region-bound + contended. Don't assume "we'll provision more when we need it" — there's a queue. Plan with the AI program lead.

Cite: [Azure OpenAI deployment types](https://learn.microsoft.com/azure/ai-services/openai/concepts/deployment-types), [PTU concepts](https://learn.microsoft.com/azure/ai-services/openai/concepts/provisioned-throughput).

### Foundry Agents — when to use

Foundry Agents (GA 2025) is Microsoft's managed agent runtime in AI Foundry:

- Declarative agent definition (system prompt, tools, output schema)
- Managed thread state (no DB plumbing for conversation state)
- Tool calling with auto-loop until response
- Structured output (JSON schema-enforced)
- Built-in evaluation hooks
- Content Safety integrated
- Entra Agent ID compatible

**vs Azure OpenAI Assistants API**: Foundry Agents is the higher-level surface. Assistants API is lower-level; you have more control but more plumbing.

**vs Semantic Kernel / AutoGen**: SK + AutoGen are open-source SDKs for orchestrating LLM calls — you run them in your own compute. Foundry Agents is managed.

**Decision matrix**:

| Need | Pick |
|------|------|
| Single-agent with tools and threaded state, managed | **Foundry Agents** |
| Multi-agent orchestration with custom topology | **AutoGen** (with Foundry Agents as the underlying agent runtime) |
| Microsoft-pattern agent SDK across .NET / Python / Java | **Semantic Kernel** |
| Lowest-level control over OpenAI API | **Azure OpenAI SDK directly** |
| Low-code agent builder for business users | **Copilot Studio** |

**Pattern: Foundry Agents as the unit of agent**; **AutoGen for multi-agent topologies**. AutoGen 0.4+ has Microsoft-supported multi-agent patterns.

**Pattern: Copilot Studio for citizen-developer scenarios**. Power Platform integration; business users design agents declaratively.

Cite: [Foundry Agents](https://learn.microsoft.com/azure/ai-foundry/concepts/agents), [AutoGen](https://microsoft.github.io/autogen/), [Semantic Kernel](https://learn.microsoft.com/semantic-kernel/), [Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/).

### RAG architecture — vector store selection

| Store | When |
|-------|------|
| **Azure AI Search** | Default for doc-search-heavy RAG; built-in chunking, vector + hybrid search, semantic ranker, integrated vectorization |
| **Cosmos DB DiskANN** | When vectors live alongside operational data; global multi-region; billions of vectors |
| **PostgreSQL Flex + pgvector** | When already on Postgres; tens of millions of vectors with HNSW |
| **Cosmos DB MongoDB vCore $vectorSearch** | MongoDB-native workloads |
| **Self-hosted Qdrant / Milvus / Weaviate on AKS** | When you have a specific need not met by managed options (rare) |

**Decision: AI Search vs Cosmos DiskANN for RAG.**

- **AI Search** wins when: "documents in, search results out" is the dominant pattern; you want semantic ranker; you want integrated vectorization (auto-embed via Azure OpenAI without writing a pipeline); you want hybrid (vector + keyword + facet) retrieval.
- **Cosmos DiskANN** wins when: vectors are part of the operational data model; you want multi-region writes; you have billions of vectors.

**Anti-pattern: standalone Pinecone / Qdrant on Azure when AI Search or Cosmos fits**. Pay for what the platform offers.

### Azure AI Search — hybrid retrieval design

**Index design**:

- **Vector field** (HNSW index, cosine similarity, 1536-dim for text-embedding-3-large).
- **Searchable text fields** (chunk content, title) for keyword.
- **Filter fields** (category, date, source) for facet + filter.
- **Semantic configuration** — semantic ranker tuned to specific fields.

**Integrated vectorization** (GA): AI Search pulls from data source → chunks → calls Azure OpenAI for embeddings → indexes. No pipeline code. Configure in Search service:

```json
{
  "name": "my-index",
  "fields": [...],
  "vectorSearch": {
    "vectorizers": [
      {
        "name": "myAzureOpenAI",
        "kind": "azureOpenAI",
        "azureOpenAIParameters": {
          "resourceUri": "https://...openai.azure.com",
          "deploymentId": "text-embedding-3-large",
          "modelName": "text-embedding-3-large"
        }
      }
    ]
  }
}
```

**Hybrid query**:

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

This sends: keyword search + text auto-embedded into vector query + semantic ranking + return top 10. One call.

**Anti-pattern: vector-only retrieval**. Hybrid (vector + keyword) almost always outperforms pure vector for real-world queries with named entities / exact phrases.

Cite: [Azure AI Search](https://learn.microsoft.com/azure/search/), [Integrated vectorization](https://learn.microsoft.com/azure/search/vector-search-integrated-vectorization).

### Cosmos DB DiskANN — RAG store

When operational data + vectors:

```sql
SELECT TOP 10 c.id, c.title, c.content, VectorDistance(c.embedding, @queryVector) AS score
FROM c
WHERE c.tenantId = @tenantId
ORDER BY VectorDistance(c.embedding, @queryVector)
```

**Critical: always filter by partition before vector distance**. Searching across all partitions is expensive; filtered search within a partition is cheap.

**Container vector embedding policy** declares the path + dimensions + distance function. Indexing policy declares the index type (`diskANN` for large; `quantizedFlat` for medium; `flat` for small).

See database-architect overlay for partition / RU sizing.

### Content Safety

Azure AI Content Safety (built into Azure OpenAI + Foundry; also standalone):

- **Text moderation** — hate / sexual / violence / self-harm categories with severity
- **Image moderation** — same categories
- **Prompt Shields** — jailbreak detection (user prompt injection)
- **Indirect Prompt Shields** — indirect injection from retrieved content
- **Groundedness detection** — does the response stay grounded in provided context?
- **Protected material detection** — copyrighted text / code

**Default**: enabled on Azure OpenAI deployments with default filters (medium severity blocked across categories).

**Customization**: per-deployment content filter configuration; severity thresholds; allow/deny lists.

**Pattern**: enable Prompt Shields on every user-facing endpoint. Indirect Prompt Shields on every RAG pipeline (retrieved content is untrusted).

**Anti-pattern: turning off content filters in production** "because they're blocking legitimate traffic." Adjust thresholds, exclude specific categories — don't blanket-disable.

Cite: [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/).

### Evaluation framework

Foundry has built-in evaluation:

- **Quality metrics**: groundedness, relevance, coherence, fluency, similarity to ground truth.
- **Safety metrics**: hateful, sexual, violent, self-harm, protected material, indirect prompt injection.
- **Custom metrics**: your own evaluators (LLM-as-judge with custom rubric).

Pattern:

1. **Eval dataset**: 50-500 representative queries with expected outputs (or rubric for open-ended).
2. **Eval run**: execute the agent / chain against the dataset; compute metrics.
3. **Baseline**: capture metrics at v1.
4. **Compare**: every prompt change / model change / retrieval change → run eval; compare to baseline.
5. **Ship**: only ship if metrics improve or hold.

**Anti-pattern: shipping prompt / model changes without eval**. You're guessing.

**Anti-pattern: testing only happy path**. Include adversarial queries (jailbreak attempts, edge cases, multi-turn confusion) in the eval dataset.

Cite: [Foundry evaluation](https://learn.microsoft.com/azure/ai-foundry/concepts/evaluation-approach-gen-ai).

### Azure ML — when to use

Azure Machine Learning is the platform for classical ML + custom training + fine-tuning + batch inference:

| Use | Service |
|-----|---------|
| Train custom model | Azure ML compute (managed clusters / instances) |
| Fine-tune frontier model | Azure OpenAI fine-tuning (managed) or Foundry fine-tuning |
| Fine-tune open-weight model (LoRA / QLoRA) | Azure ML with HuggingFace / PyTorch |
| Batch inference | Azure ML managed batch endpoint or Container Apps Jobs |
| Real-time inference (custom) | Azure ML managed online endpoint or Container Apps |
| ML experiment tracking | Azure ML MLflow integration |
| Model registry | Azure ML model registry |
| Responsible AI dashboard | Azure ML Responsible AI components |

**Pattern**: prototype in Azure ML notebooks → MLflow tracking → model registry → managed online endpoint (blue-green deploy with autoscaling) → A/B test.

Cite: [Azure ML](https://learn.microsoft.com/azure/machine-learning/).

### GPU VM selection for training / inference

| Series | GPU | Memory/GPU | Use |
|--------|-----|------------|-----|
| NC T4 v3 | NVIDIA T4 | 16 GB | Inference, light training |
| NC A100 v4 | NVIDIA A100 | 80 GB | Training, large models |
| **NCads H100 v5** | NVIDIA H100 NVL | 94 GB | Training, batch inference |
| ND H100 v4 | NVIDIA H100 | 80 GB | Large-scale distributed training |
| **ND H200 v5** | NVIDIA H200 | 141 GB (HBM3e) | Largest models, highest throughput |
| **NCv6 (preview Nov 2025)** | NVIDIA RTX PRO 6000 Blackwell | TBD | Visual computing + cost-effective inference |
| GB200 Grace Blackwell | Per cluster | per cluster | Frontier training |

For Azure-hosted training: **ND H200 v5** is current frontier-grade. For inference: **NCads H100 v5** or upcoming **NCv6 (Blackwell)** when GA.

**Maia 100** — Microsoft's custom AI accelerator. Currently for internal Microsoft services (Copilot, Defender AI, Azure OpenAI). Not generally available for customer deployments yet. Maia 200 (Braga) delayed to 2026.

Cite: [GPU VM sizes](https://learn.microsoft.com/azure/virtual-machines/sizes-gpu).

### Entra Agent ID — production identity for agents

Every production agent gets an Entra Agent ID:

- Conditional Access policies apply (e.g., "this agent only operates during business hours from these IPs")
- PIM-eligible for sensitive operations
- Audit log attributes actions to agent identity
- Tool permissions scoped per agent

**Pattern**: agent acts on behalf of user → OBO token exchange → both identities logged. Agent acts as service → agent identity only.

**Anti-pattern**: agent running with developer's user creds in production. Misattribution.

See security-engineer overlay for the full Entra Agent ID design.

### Prompt strategy patterns

- **Few-shot examples** for structured output / consistent style.
- **Chain-of-thought** for reasoning tasks (or use a reasoning model — o1 / o3 — and skip the prompt scaffolding).
- **Output schemas** (JSON schema) for structured extraction — enforced server-side via `response_format`.
- **Tool use** for actions the model needs to take (search, calculator, DB query).
- **Self-critique** for higher quality at higher cost (model evaluates its own output, revises).
- **Plan-and-execute** for multi-step tasks (separate "planner" call → step executor calls).

**Anti-pattern**: 4000-token system prompt with everything. Long prompts increase cost + latency + reduce quality on edge cases. Iterate to the shortest prompt that achieves the metric.

**Anti-pattern**: hard-coding examples in code. Externalize prompts to AI Foundry / Prompt flow / config file; version them.

### Prompt flow — orchestration

Available in AI Foundry + Azure ML:

- Visual DAG-based orchestration of LLM calls + tools + Python code
- Built-in flow types: chat, embedding, custom
- Version control + evaluation integration
- Deploy as managed endpoint

**Decision**: Prompt flow vs Semantic Kernel vs Foundry Agents.

- **Prompt flow** — best for "explorable" RAG / agent pipelines with non-developer collaborators.
- **Semantic Kernel** — best for production code with .NET / Python / Java teams.
- **Foundry Agents** — best for managed runtime + thread state + tool calling out-of-the-box.

All three can compose: Prompt flow can call Semantic Kernel; Foundry Agents can be tools inside Prompt flow.

## 2025-2026 platform reset items relevant to this role

- **Azure AI Studio → Microsoft Foundry / AI Foundry** rename (2024-25).
- **Azure Cognitive Search → Azure AI Search** rename (2023).
- **Foundry Agents GA 2025** — managed agent runtime.
- **AI Foundry model catalog** — 1,900+ models incl. Anthropic Claude + OpenAI frontier.
- **Cosmos DB DiskANN GA 2024-25** — billion-scale vector index, native.
- **Integrated vectorization in AI Search** — auto-embed via Azure OpenAI.
- **Entra Agent ID** (Ignite 2025) — first-class agent identity.
- **AutoGen 0.4+** — Microsoft-supported multi-agent SDK.
- **Semantic Kernel** stable across .NET / Python / Java.
- **Copilot Studio** for low-code agent builder (renamed from Power Virtual Agents).
- **Purview AI Hub** — visibility into AI prompts + risky AI usage.
- **Defender for AI Services** — Azure OpenAI / Foundry threat detection.
- **Content Safety Prompt Shields + Indirect Prompt Shields** — GA.
- **Azure OpenAI Batch API** — 50% discount for async.
- **Phi-4** — Microsoft's small model family; efficient + fine-tunable.

## Patterns and anti-patterns

### Pattern: PTU baseline + Standard burst

Production capacity strategy. PTU at 70-80% expected steady; Standard handles bursts. Code routes by checking rate limit headers.

### Pattern: Foundry evaluation in CI for every prompt change

Eval dataset (50-500 cases) in repo. CI runs evaluation on PR; blocks merge if metrics regress beyond threshold.

### Pattern: AI Search integrated vectorization for RAG

Skip writing chunking / embedding pipeline code. Configure AI Search index with vectorizer; data source pulls + embeds + indexes automatically.

### Pattern: hybrid retrieval (vector + keyword + semantic ranker)

Almost always beats pure vector. Especially for queries with named entities or exact phrases.

### Pattern: small model for the cheap step, large model for the expensive step

"GPT-4o-mini classifies the intent → routes to a specialist (GPT-5.2 for hard cases; cached canned response for trivial)." Cost-quality optimization.

### Pattern: Content Safety on every endpoint, every direction

Filter user input (Prompt Shields), filter LLM output, filter retrieved content (Indirect Prompt Shields). Defense in depth.

### Pattern: Entra Agent ID for every production agent

First-class identity. Conditional Access. PIM. Audit trail.

### Pattern: model + prompt versioning in AI Foundry

Treat prompts like code: versioned, reviewed, eval'd. AI Foundry prompt flow supports this natively.

### Anti-pattern: prompt iteration without eval

You're guessing. Measure.

### Anti-pattern: GPT-4 for everything

10× cost vs Phi-4 / GPT-4o-mini for simple tasks. Match model to task complexity.

### Anti-pattern: turning off Content Safety in production

If filters block legitimate traffic, tune thresholds. Don't disable.

### Anti-pattern: 4000-token system prompt

Shorter is usually better. Iterate down.

### Anti-pattern: building custom RAG from scratch when AI Search / Cosmos DiskANN fits

You're rebuilding what Microsoft maintains.

### Anti-pattern: ignoring PTU regional capacity

PTU is region-bound + contended. Plan with the AI program lead; have Standard fallback for bursts.

### Anti-pattern: agent running with developer creds in production

Use Entra Agent ID. Audit trail.

### Anti-pattern: BYO Pinecone / Weaviate when not needed

Pay for what the platform offers.

### Anti-pattern: prompt logging without redaction

User prompts contain PII / confidential info. Redact before logging. Purview classification + DLP on prompt logs.

## Tooling specifics

- **AI Foundry portal** (ai.azure.com) — model catalog, deployments, evaluations, prompt flow, agents.
- **Azure OpenAI Studio** (legacy URL, redirects to Foundry).
- **`azd ai agent` commands** (March 2026+) — local dev for agents.
- **Semantic Kernel SDK** — .NET / Python / Java.
- **AutoGen** — Python (primarily); orchestration framework.
- **`@azure/openai` / `Azure.AI.OpenAI` / `openai` (Python with Azure config)** — direct SDK access.
- **`@azure/search-documents` / `Azure.Search.Documents`** — AI Search SDK.
- **Foundry SDK** (`azure-ai-projects`) — programmatic Foundry access.
- **Prompt flow CLI** (`pf`) — local prompt flow development.
- **`@azure/ai-content-safety` / `Azure.AI.ContentSafety`** — Content Safety SDK.
- **Azure ML SDK v2** (`azure-ai-ml`) — Azure ML SDK.
- **MLflow** — experiment tracking + model registry.

## Integration with always-on protocols

### TDD on AI/ML

- **Eval-driven development**: eval dataset is the test suite. Every change runs against it.
- **Unit tests for tool functions**: tools are deterministic code; test them like any function.
- **Integration tests against deployed dev endpoint**: end-to-end with real LLM (rate-limited; use cheaper model in tests).
- **Snapshot tests for prompts**: stable prompts produce stable outputs on stable inputs; test with deterministic temperature=0.

### Verification

- Eval metrics meet or exceed baseline.
- Content Safety not triggering false positives at unacceptable rate.
- Latency P95 within budget.
- Cost per request within budget.
- Groundedness metric (for RAG) above threshold.

### Review

Push back on:

- Default GPT-4 / GPT-5 without eval-justified reason.
- No eval on prompt / model / retrieval change.
- Content Safety disabled.
- Long prompts without iteration.
- Custom RAG when AI Search / Cosmos DiskANN fits.
- PTU at 100% expected peak.
- Agent without Entra Agent ID.
- Prompt logs without PII redaction.

### Debugging AI/ML

- **Foundry traces** — call-level tracing of agent/chain execution.
- **App Insights distributed tracing** — across LLM call + tool call + DB query.
- **Eval results** — which cases failed? Why?
- **Content Safety logs** — which filter triggered? Severity?
- **Prompt Shields logs** — was a jailbreak attempt detected?

Root cause workflow:

1. Reproduce in eval framework with the failing input.
2. Hypothesize: is it the prompt, retrieval, model, or post-processing?
3. Test one variable.
4. Verify against eval metrics.
5. Iterate.

## Cross-references to products_covered

| Product | Role usage |
|---------|------------|
| `Azure OpenAI Service` | Frontier OpenAI models on Azure |
| `AI Foundry` | Model catalog, agents, evaluation, prompt flow |
| `Azure AI Search` | Hybrid retrieval for RAG |
| `Azure Machine Learning` | Custom training / fine-tuning / batch |
| `Copilot Studio` | Low-code agent builder |
| `Semantic Kernel` | Orchestration SDK |
| `Cosmos DB for NoSQL` (DiskANN) | Vector store alongside operational data |
| `PostgreSQL Flexible Server` (pgvector) | Vector store alongside Postgres |
| `Azure AI Content Safety` | Filtering + Prompt Shields + groundedness |
| `Microsoft Purview` (AI Hub) | AI-aware DLP + classification |
| `Defender for AI Services` | AI threat detection |
| `Entra Agent ID` | Agent identity |

## When to refresh this overlay

- New model GA (especially GPT-6, Claude 5, frontier releases)
- AI Foundry feature GA
- Foundry Agents evolution
- Content Safety category additions
- Entra Agent ID feature expansion
- PTU quota / pricing changes
- New GPU SKU GA
- Major SDK version bumps (Semantic Kernel, AutoGen)

Target refresh cadence: every 3 months given the velocity of AI model + tooling change.
