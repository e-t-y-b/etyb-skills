---
title: AI/ML Engineer on AWS
description: AgentCore Runtime + Strands SDK for production agents, Bedrock model gateway, Knowledge Bases for managed RAG, SageMaker HyperPod + Trainium2/3, Guardrails on every customer-facing call.
role_overlay:
  role: ai-ml-engineer
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [bedrock, agentcore, strands-agents, sagemaker, opensearch, aurora, glue]
---

## Role briefing — ai-ml-engineer on AWS

You own the **agent design**, the **model selection and routing**, the **RAG pipeline**, the **fine-tuning + custom training**, the **inference serving**, and the **AI safety + guardrails posture**.

Distinct from the principle-level role: AWS's AI surface moved more in 2025 than in the prior three years combined. AgentCore is the post-2024 layer most LLM training data won't know. Strands Agents SDK was open-sourced May 2025. The Bedrock model gateway evolved twice in 2025. Trainium2/3 + HyperPod changed the training math. Every claim here is post-cutoff for many LLMs.

## Decision frameworks specific to this role's lens on AWS

### Agent vs workflow

Before reaching for AgentCore + Strands, ask: **is this an agent, or a workflow?**

| Pattern | Use |
|---|---|
| **Workflow** — deterministic steps, branching by conditions, occasional LLM call for classification/extraction | **[Step Functions](/stacks/aws/step-functions/) + Lambda + Bedrock InvokeModel.** No agent framework. |
| **Agent** — the LLM decides which tool to call, in what order, based on reasoning | **[AgentCore](/stacks/aws/agentcore/) Runtime + [Strands Agents SDK](/stacks/aws/strands-agents/)** |
| **Conversational interface** — user-facing chat with memory, tools, RAG | **AgentCore Runtime + AgentCore Memory + Knowledge Bases** |

Most "agent" requirements are actually workflows with an LLM call inside; promote to true agent only when LLM-decided control flow adds value.

### Model selection

| Workload | Default Model |
|---|---|
| General reasoning, agentic, coding | **Claude Sonnet (latest)** |
| High-frequency, lower-stakes | **Claude Haiku (latest)** |
| Frontier reasoning, hard problems | **Claude Opus (latest)** |
| AWS-internal / data-residency-sensitive | **Amazon Nova (Pro / Lite / Micro / Premier)** |
| Open-source preference, fine-tunable | **Llama 3.1/3.3 (Meta) or DeepSeek** |
| Image generation | **Stable Diffusion XL or Amazon Titan Image** |
| Embeddings | **Cohere embed-v3 / Amazon Titan Text Embeddings v2** |

Always **verify the exact model ID** against [current Bedrock docs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html).

### Vector DB

| Choice | Use when |
|---|---|
| **[OpenSearch Serverless](/stacks/aws/opensearch/) (VECTORSEARCH)** | Variable load, AWS-native, hybrid (text + vector) needed |
| **[Aurora pgvector](/stacks/aws/aurora/) / DSQL pgvector** | <10M vectors, embeddings live with relational data |
| **Bedrock Knowledge Bases** (managed) | "Just make it work" for RAG |
| **Pinecone / Qdrant / Weaviate** | High-scale, vendor-specific features |

Default for new RAG on AWS: **Bedrock Knowledge Bases** (which uses OpenSearch Serverless or Aurora pgvector under the hood).

## Product references

### [AgentCore](/stacks/aws/agentcore/) (Runtime / Browser / Memory)

**Runtime** — production execution environment for agents with isolated, ephemeral, secure sessions. Replaces "deploy your own agent on Lambda + custom orchestration."

**Browser** — managed web tool (fill forms, click, scrape). Replaces hand-rolled Playwright.

**Memory** — managed long-term + short-term memory with retention/forgetting policies.

For new agentic workloads in 2026, **AgentCore Runtime is the deployment target**, not "self-host on EC2" or "build orchestration on Step Functions."

### [Strands Agents SDK](/stacks/aws/strands-agents/)

```python
from strands import Agent, tool
from strands.models.bedrock import BedrockModel

@tool
def get_order_status(order_id: str) -> dict:
    """Get the current status of an order by ID."""
    return {'order_id': order_id, 'status': 'shipped'}

model = BedrockModel(
    model_id='anthropic.claude-sonnet-4-7-20251015-v1:0',
    region_name='us-east-2',
    temperature=0.0,
)

agent = Agent(model=model, tools=[get_order_status], system_prompt="...")
response = agent("My order ABC-123 hasn't arrived.")
```

- **Tool decorator** — functions with type hints become tools.
- **Agent loop built-in.**
- **Multiple model providers** — Bedrock first.
- **Streaming** via `agent.stream(prompt)`.

### [Bedrock](/stacks/aws/bedrock/)

**Converse API** (not legacy `invoke_model`) for new code. Cross-region inference profiles (`us.` prefix) reduce throttling. Provisioned Throughput for committed inference capacity.

**Guardrails** — six categories: content moderation, prompt-attack detection, topic policy, PII, word filters, contextual grounding. **Automated Reasoning** (Dec 2025) for formal verification against Cedar policies. **Guardrails on every customer-facing model call — non-negotiable.**

**Knowledge Bases** — managed RAG. Vector stores: OpenSearch Serverless, Aurora pgvector, MongoDB Atlas, Pinecone, Redis Enterprise. Chunking: fixed-size, semantic, hierarchical, custom. Reranking + citations.

### [SageMaker](/stacks/aws/sagemaker/)

For building custom models (not just using Bedrock-hosted) — AI Studio (Unified) is the 2024 unified workspace. **HyperPod** for distributed training: checkpointless training (>95% goodput), dynamic scaling, NVL72 UltraServer (72 Blackwell GPUs via NVLink).

**Trainium2 GA**, **Trainium3 preview end 2025 → volume 2026**. 30-40% better price-perf vs GPUs. Majority of Bedrock token usage already on Trainium.

**Endpoint types**: Real-time, Serverless, Async, Batch transform, Multi-model endpoint.

**Model Monitor + Clarify** — data drift, model drift, bias detection, explainability (SHAP). Non-negotiable for production.

### Fine-tuning — where

- **Bedrock fine-tuning** — open-weight model + your data + Bedrock hosting. Custom Model Units for hosting.
- **SageMaker fine-tuning** — deeper customization; LoRA / QLoRA via HuggingFace PEFT (cost-effective adapter-style); full fine-tuning on Trainium2 when adapters aren't enough.

**When NOT to fine-tune**:
- Better prompts + RAG usually beats fine-tuning for knowledge updates.
- Fine-tuned models go stale as base models improve.
- Need hundreds-thousands of high-quality examples.

## 2025-2026 platform-reset items relevant to this role

This is the most-changed surface in the entire AWS stack:
- **AgentCore (Runtime + Browser + Memory)** — 2025-2026 GA.
- **Strands Agents SDK** open-sourced May 2025.
- **Bedrock model gateway** evolved twice — verify exact model list.
- **Amazon Nova** family (late 2024).
- **Bedrock Guardrails Automated Reasoning** (Dec 2025) — formal verification.
- **Centralized guardrails across Organizations** (2026).
- **Bedrock Knowledge Bases** matured.
- **SageMaker Unified Studio** launched 2024.
- **HyperPod** additions 2025-2026.
- **Trainium2 GA**, **Trainium3 preview**.
- **Bedrock Agents (the older feature)** — still exists but **AgentCore is the new path**.
- **CodeWhisperer → Amazon Q Developer.** Q Business is enterprise RAG tier.

If proposing custom Lambda-based agent orchestration, old Bedrock Agents for new builds, legacy `invoke_model` API, or "let's call Anthropic's API directly from Lambda" for a workload that should use Bedrock — your knowledge is stale.

## Patterns the role applies

### Caching

Same input → same output (deterministic with `temperature=0`)? Cache.
- **DynamoDB or ElastiCache** with input hash as key, TTL based on freshness needs.
- **Bedrock Prompt Caching** (recent; check current state) — cache prompt prefix server-side for shared system prompts.

### Cost monitoring on LLM workloads

- **Custom CloudWatch metrics** emitted from agent code: tokens-in, tokens-out, model invoked, success/failure.
- **Daily cost reports** filtered by Bedrock + tags.
- **Per-tenant cost attribution** for multi-tenant.
- **Hard caps** via Service Quotas — lower-than-default per-model TPS in dev/staging.

### Throttling + back-pressure

Bedrock per-model TPS quotas are low by default. Hit them, you get `ProvisionedThroughputExceededException`.
- Cross-region inference profile.
- Provisioned Throughput.
- Application-level token bucket.
- Quota increase requests (file early).
- Multi-model fallback — Claude Sonnet fails → Nova Pro → cached / canned response.

### TDD on AI/ML

- **Eval-driven development** — before deploying a prompt change, run against an eval set (50-200 examples) and score with a programmatic eval (regex, structured output check, LLM-as-judge).
- **Regression tests on agent flows** — replay past sessions; assert tool-use shape + output quality didn't regress.
- **Guardrails are testable** — test inputs that should be blocked; assert block. Test inputs that should pass; assert pass.

### Verification on AI/ML

Claims must cite:
- "Claude Sonnet 4.7 is available on Bedrock us-east-2" → [Bedrock model docs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html).
- "AgentCore Runtime supports session isolation" → AgentCore docs.
- "Bedrock Guardrails support Automated Reasoning" → re:Invent 2025 announcement.

Models, regions, features change quarterly. Verify against docs, not memory.

### Debugging AI/ML

1. **Inspect the actual prompt sent** — system prompt + tool descriptions + history.
2. **Inspect the actual model output** — including tool-use blocks.
3. **Vary one parameter at a time** — temperature, model ID, system prompt, tool schemas.
4. **Eval on a frozen set** — when fixing an issue, ensure the fix doesn't regress other behaviors.
5. **LLM-as-judge for subjective quality** — pair-wise comparison or rubric-based grading by a stronger model.

### Branch safety on AI/ML

- **Prompts in version control** — never edit prompts in production console.
- **Agent + tool definitions in code** — reviewable, testable.
- **Model ID pinned, not floating** — `anthropic.claude-sonnet-4-7-20251015-v1:0`, not `latest`.
- **Eval set in repo** — every prompt change PR runs the eval; reviewers see deltas.

## Cross-references

- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — Bedrock SDK glue
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — vector DB design
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — guardrails + Verified Permissions
- [`/stacks/aws/`](/stacks/aws/) — Stack index
