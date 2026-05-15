---
title: AI/ML Engineer on Azure
description: Model selection from AI Foundry's 1,900+ catalog (OpenAI + Anthropic frontier). Foundry Agents + Semantic Kernel + AutoGen. RAG with AI Search / Cosmos DiskANN / pgvector. Eval-driven.
role_overlay:
  role: ai-ml-engineer
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - azure-openai
    - ai-foundry
    - foundry-agents
    - ai-search
    - cosmos-db
    - postgresql-flexible-server
    - microsoft-purview
    - defender-for-cloud
    - entra-id
    - virtual-machines
---

## Role briefing

You're building AI/ML on Azure. Generative AI ([Azure OpenAI](/stacks/azure/azure-openai/) / [Foundry](/stacks/azure/ai-foundry/) / [Foundry Agents](/stacks/azure/foundry-agents/)), classical ML (Azure ML), RAG ([AI Search](/stacks/azure/ai-search/) + [Cosmos DiskANN](/stacks/azure/cosmos-db/) + [pgvector](/stacks/azure/postgresql-flexible-server/)), agent orchestration (Semantic Kernel / AutoGen), responsible AI (Content Safety + evaluation).

You don't write surrounding app code ([backend-architect](/stacks/azure/backend-architect/)) or the security wrapper ([security-engineer](/stacks/azure/security-engineer/)) — you design model selection, prompt strategy, retrieval, evaluation, agent topology.

## Decision frameworks specific to this role's lens on Azure

### Model selection — AI Foundry catalog

[AI Foundry](/stacks/azure/ai-foundry/) catalog has **1,900+ models** as of 2026-Q2.

**Models sold by Azure** (Azure SLA + MS commercial terms):

- GPT-4o, GPT-4o-mini, GPT-4.5, **GPT-5.2 (latest)**, o1, o3, o4-mini
- DALL-E 3, Whisper, text-embedding-3-small/-large
- **Anthropic Claude Opus, Sonnet, Haiku** — Azure is the **only hyperscaler with both OpenAI + Anthropic frontier**
- Mistral Large, Mistral Small, Codestral
- Meta Llama 3 / 3.1 / 4
- Microsoft **Phi 3 / 4** — small, efficient, fine-tunable

**Partner / community** (Microsoft hosts; not Azure SLA): DeepSeek V3 / V3.2, Kimi K2, Stable Diffusion variants.

Pick guide (2026-Q2):

| Use case | Pick |
|----------|------|
| Frontier reasoning / agents | GPT-5.2 or o3 or Claude Opus 4.7 |
| Cost-effective high-quality | Claude Sonnet 4.5 / 4.6 |
| Cheap fast classification / extraction | GPT-4o-mini or Phi-4 |
| Embeddings | text-embedding-3-large or -small |
| Image gen | DALL-E 3 |
| Speech-to-text | Whisper |
| Coding | Claude or GPT-5.2 |
| Fine-tunable open-weight | Phi-4 or Mistral Small |
| Confidential / on-prem | Phi-4 / Mistral via self-host on [AKS](/stacks/azure/aks/) |

**Anti-pattern: defaulting to GPT-4/5 for everything.** GPT-4o-mini / Phi-4 are 10-100× cheaper for classification / extraction / simple summarization.

**Anti-pattern: choosing without eval.** Run Foundry evaluation first; pick by data.

### Azure OpenAI deployment types

See [Azure OpenAI](/stacks/azure/azure-openai/) for the full picture.

| Type | Use case |
|------|----------|
| Standard | Dev / proto / variable load |
| Provisioned Throughput Units (PTU) | Production predictable load |
| Batch API | Async high-throughput (**50% discount**) |
| Global | Highest availability via cross-region |
| Data Zone | Regulatory data residency |

**Pattern: PTU baseline + Standard burst.** PTU at 70-80% expected steady; Standard spillover handles bursts.

**Anti-pattern: PTU at 100% expected peak.** **Anti-pattern: starting at PTU without baseline data** (run on Standard 2-4 weeks first). **Anti-pattern: assuming PTU capacity is on-demand** — region-bound + contended.

### Foundry Agents — when to use

See [Foundry Agents](/stacks/azure/foundry-agents/). Decision matrix:

| Need | Pick |
|------|------|
| Single-agent with tools + thread state, managed | **Foundry Agents** |
| Multi-agent custom topology | **AutoGen** (with Foundry Agents as underlying runtime) |
| Microsoft-pattern SDK across .NET / Python / Java | **Semantic Kernel** |
| Lowest-level control over OpenAI API | **Azure OpenAI SDK directly** |
| Low-code agent for business users | **Copilot Studio** |

Pattern: Foundry Agents as the unit of agent; AutoGen for multi-agent topologies.

### RAG architecture — vector store selection

| Store | When |
|-------|------|
| [Azure AI Search](/stacks/azure/ai-search/) | Default for doc-search RAG; integrated vectorization, semantic ranker |
| [Cosmos DB DiskANN](/stacks/azure/cosmos-db/) | Vectors alongside operational data; global multi-region; billions |
| [PostgreSQL Flex + pgvector](/stacks/azure/postgresql-flexible-server/) | Already on Postgres; tens of millions with HNSW |
| [Cosmos MongoDB vCore $vectorSearch](/stacks/azure/cosmos-db/) | MongoDB-native workloads |
| Self-hosted Qdrant / Milvus / Weaviate on AKS | Specific need not met by managed (rare) |

**Anti-pattern: standalone Pinecone / Qdrant on Azure when one of the above fits.**

### Azure AI Search — hybrid retrieval design

**Index design**: vector field (HNSW, cosine, 1536-dim for text-embedding-3-large), searchable text fields, filter fields, semantic configuration.

**Integrated vectorization** (GA) — AI Search pulls from data source → chunks → calls Azure OpenAI for embeddings → indexes. No pipeline code. See [Azure AI Search](/stacks/azure/ai-search/).

**Hybrid query** (vector + keyword + semantic ranker) almost always beats pure vector.

### Cosmos DB DiskANN

When operational data + vectors:

```sql
SELECT TOP 10 c.id, c.title, c.content, VectorDistance(c.embedding, @queryVector) AS score
FROM c
WHERE c.tenantId = @tenantId
ORDER BY VectorDistance(c.embedding, @queryVector)
```

**Critical: always filter by partition before vector distance.** See [Cosmos DB](/stacks/azure/cosmos-db/) + [Database Architect on Azure](/stacks/azure/database-architect/) for sizing.

### Content Safety

Built into Azure OpenAI + Foundry; also standalone.

- **Text + image moderation** — hate / sexual / violence / self-harm with severity
- **Prompt Shields** — jailbreak detection
- **Indirect Prompt Shields** — indirect injection from retrieved content
- **Groundedness detection** — does response stay in provided context?
- **Protected material detection** — copyrighted text / code

**Default**: enabled on Azure OpenAI deployments with medium severity blocked.

**Pattern**: Prompt Shields on every user-facing endpoint. Indirect Prompt Shields on every RAG (retrieved content is untrusted).

**Anti-pattern: turning off Content Safety in production** "because it's blocking legitimate traffic." Tune thresholds; exclude categories; don't blanket-disable.

### Evaluation framework

Foundry built-in evaluation:

- **Quality**: groundedness, relevance, coherence, fluency, similarity to ground truth.
- **Safety**: hateful, sexual, violent, self-harm, protected material, indirect prompt injection.
- **Custom**: LLM-as-judge with custom rubric.

Pattern:

1. **Eval dataset**: 50-500 representative queries with expected outputs (or rubric).
2. **Eval run**: execute agent/chain; compute metrics.
3. **Baseline**: capture at v1.
4. **Compare**: every change → run eval; compare.
5. **Ship**: only if metrics improve or hold.

**Anti-pattern: shipping prompt / model changes without eval.** **Anti-pattern: testing only happy path** — include adversarial queries (jailbreak attempts, edge cases, multi-turn confusion).

### Azure ML — when to use

| Use | Service |
|-----|---------|
| Train custom model | Azure ML compute |
| Fine-tune frontier model | Azure OpenAI fine-tuning or Foundry fine-tuning |
| Fine-tune open-weight (LoRA / QLoRA) | Azure ML with HuggingFace / PyTorch |
| Batch inference | Azure ML batch endpoint or Container Apps Jobs |
| Real-time inference (custom) | Azure ML online endpoint or [Container Apps](/stacks/azure/container-apps/) |
| Experiment tracking | Azure ML MLflow integration |
| Model registry | Azure ML model registry |
| Responsible AI dashboard | Azure ML Responsible AI components |

### GPU VM selection

| Series | GPU | Memory/GPU | Use |
|--------|-----|------------|-----|
| NC T4 v3 | T4 | 16 GB | Inference, light training |
| NC A100 v4 | A100 | 80 GB | Training, large models |
| **NCads H100 v5** | H100 NVL | 94 GB | Training, batch inference |
| ND H100 v4 | H100 | 80 GB | Large-scale distributed |
| **ND H200 v5** | H200 | 141 GB HBM3e | Largest models, highest throughput |
| **NCv6 (preview Nov 2025)** | RTX PRO 6000 Blackwell | TBD | Cost-effective inference + visual |
| GB200 Grace Blackwell | per cluster | per cluster | Frontier training |

**Maia 100** — Microsoft's custom AI accelerator. Currently internal-only. Maia 200 (Braga) delayed to 2026.

See [Virtual Machines](/stacks/azure/virtual-machines/).

### Entra Agent ID

Every production agent gets an Entra Agent ID. Conditional Access scopes when/where it operates; PIM gates sensitive ops; audit attributes actions to the agent. See [Security Engineer on Azure](/stacks/azure/security-engineer/).

**Anti-pattern: agent running with developer's user credentials in production.**

### Prompt strategy patterns

- **Few-shot examples** for structured / consistent style.
- **Chain-of-thought** for reasoning (or use a reasoning model — o1/o3 — and skip the scaffolding).
- **Output schemas** (JSON schema) for structured extraction — enforced via `response_format`.
- **Tool use** for actions the model takes.
- **Self-critique** for higher quality at higher cost.
- **Plan-and-execute** for multi-step (separate planner → step executor).

**Anti-pattern: 4000-token system prompt.** Iterate to the shortest that achieves the metric. **Anti-pattern: hard-coding examples in code** — externalize to Foundry / Prompt flow / config; version.

### Prompt flow — orchestration

Available in AI Foundry + Azure ML. Visual DAG of LLM calls + tools + Python code. Built-in flow types: chat, embedding, custom. Version control + evaluation integration. Deploy as managed endpoint.

| Decision | Pick |
|----------|------|
| Explorable RAG / agent pipelines with non-developer collaborators | **Prompt flow** |
| Production code with .NET / Python / Java teams | **Semantic Kernel** |
| Managed runtime + thread state + tool calling | **Foundry Agents** |

All three can compose.

## 2025-2026 platform-reset items relevant to this role

- **Azure AI Studio → Microsoft Foundry / AI Foundry** rename (2024-25).
- **Azure Cognitive Search → Azure AI Search** rename (2023).
- **Foundry Agents GA 2025** — managed agent runtime.
- **AI Foundry model catalog** — 1,900+ including Anthropic Claude + OpenAI frontier.
- **Cosmos DB DiskANN GA 2024-25** — billion-scale native.
- **Integrated vectorization in AI Search** — auto-embed via Azure OpenAI.
- **Entra Agent ID** (Ignite 2025).
- **AutoGen 0.4+** — Microsoft-supported multi-agent.
- **Semantic Kernel** stable across .NET / Python / Java.
- **Copilot Studio** — renamed from Power Virtual Agents.
- **Purview AI Hub** — visibility into AI prompts + risky usage.
- **Defender for AI Services** — threat detection.
- **Content Safety Prompt Shields + Indirect Prompt Shields** GA.
- **Azure OpenAI Batch API** — 50% discount.
- **Phi-4** — Microsoft small model family.

## Patterns the role applies

### Pattern: PTU baseline + Standard burst

Production capacity strategy.

### Pattern: Foundry evaluation in CI for every prompt change

Eval dataset in repo. CI runs eval on PR; blocks merge if regression.

### Pattern: AI Search integrated vectorization for RAG

Skip chunking + embedding pipeline code.

### Pattern: Hybrid retrieval

Vector + keyword + semantic ranker. Almost always beats pure vector.

### Pattern: Small for cheap step, large for expensive step

"GPT-4o-mini classifies intent → routes to specialist (GPT-5.2 for hard; cached canned for trivial)."

### Pattern: Content Safety on every endpoint, every direction

Filter input (Prompt Shields), filter output, filter retrieved content (Indirect Prompt Shields).

### Pattern: Entra Agent ID for every production agent

First-class identity. Conditional Access. PIM. Audit.

### Pattern: Model + prompt versioning in AI Foundry

Treat prompts like code: versioned, reviewed, eval'd.

### Anti-pattern: prompt iteration without eval

### Anti-pattern: GPT-4/5 for everything

### Anti-pattern: turning off Content Safety in production

### Anti-pattern: 4000-token system prompt

### Anti-pattern: building custom RAG when AI Search / Cosmos DiskANN fits

### Anti-pattern: ignoring PTU regional capacity

### Anti-pattern: agent running with developer creds in production

### Anti-pattern: BYO Pinecone / Weaviate when not needed

### Anti-pattern: prompt logging without redaction

Purview classification + DLP on prompt logs.

## Integration with always-on protocols

### TDD on AI/ML

- **Eval-driven**: eval dataset is the test suite.
- **Unit tests for tool functions** — deterministic code; test like any function.
- **Integration tests against deployed dev endpoint** — rate-limited; use cheaper model.
- **Snapshot tests** for stable prompts with deterministic temperature=0.

### Verification

- Eval metrics meet/exceed baseline.
- Content Safety not triggering false positives at unacceptable rate.
- Latency P95 within budget.
- Cost per request within budget.
- Groundedness (for RAG) above threshold.

### Review

Push back on the anti-patterns above.

### Debugging AI/ML

- **Foundry traces** — call-level tracing.
- **App Insights distributed tracing** — across LLM + tool + DB.
- **Eval results** — which cases failed? Why?
- **Content Safety logs** — which filter? Severity?
- **Prompt Shields logs** — jailbreak detected?

Workflow: reproduce in eval framework → hypothesize (prompt? retrieval? model? post-processing?) → test one variable → verify → iterate.

## Cross-references

- [System Architect on Azure](/stacks/azure/system-architect/) — agent vs orchestrated compute decision
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — SDK + integration
- [Database Architect on Azure](/stacks/azure/database-architect/) — vector store selection
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Entra Agent ID + Content Safety
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/) — Confidential AI for PHI
- [Azure Stack index](/stacks/azure/)
- [AI Foundry model catalog](https://learn.microsoft.com/azure/ai-foundry/concepts/model-catalog-overview)
- [Foundry evaluation](https://learn.microsoft.com/azure/ai-foundry/concepts/evaluation-approach-gen-ai)
- [Azure OpenAI deployment types](https://learn.microsoft.com/azure/ai-services/openai/concepts/deployment-types)
