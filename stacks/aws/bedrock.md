---
title: Bedrock
description: AWS managed gateway for foundation models — Converse API replaces legacy invoke_model, cross-region inference reduces throttling, Guardrails with Automated Reasoning (Dec 2025).
product:
  name: Bedrock
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect, fintech-architect]
  authoritative_url: https://docs.aws.amazon.com/bedrock/latest/userguide/
  notes: "Model gateway evolved twice in 2025; AgentCore Runtime/Browser/Memory are 2025-2026 GA; surfaces, IAM shape, and pricing still shifting."
---

## What it is

Amazon Bedrock is the managed gateway for foundation models on AWS — Claude (Anthropic), Nova (Amazon), Llama (Meta), Mistral, DeepSeek, Stable Diffusion + image models, plus more depending on region. The unified Converse API + ConverseStream replace the legacy `invoke_model` API. Pairs with [Bedrock Guardrails](#bedrock-guardrails), [Bedrock Knowledge Bases](#bedrock-knowledge-bases-the-managed-rag-path), and [AgentCore](/stacks/aws/agentcore/) for production agent workloads.

Canonical surface: [docs.aws.amazon.com/bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/).

## When to use

| Workload | Default Model |
|---|---|
| General reasoning, agentic, coding | **Claude Sonnet (latest)** |
| High-frequency, lower-stakes | **Claude Haiku (latest)** |
| Frontier reasoning, hard problems | **Claude Opus (latest)** |
| AWS-internal / data-residency-sensitive | **Amazon Nova (Pro / Lite / Micro / Premier)** |
| Open-source preference, fine-tunable | **Llama 3.1/3.3 (Meta) or DeepSeek** |
| Image generation | **Stable Diffusion XL or Amazon Titan Image** |
| Embeddings | **Cohere embed-v3 / Amazon Titan Text Embeddings v2** |
| Speech-to-text | **Bedrock-hosted Whisper or AWS Transcribe** |

Always **verify the exact model ID** against [current Bedrock docs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html) — model IDs include version dates, and Anthropic releases new Claude Sonnet versions quarterly.

## 2025-2026 currency anchors

- **Converse API** (and `converse_stream`) is the modern unified interface across all Bedrock models — tool config + guardrails first-class. **Don't use legacy `invoke_model` for new code.**
- **Cross-region inference profiles** route to the region with lowest latency / least throttling. Significantly reduces `ProvisionedThroughputExceededException` at scale.
- **Amazon Nova** family (late 2024): Nova Micro (text, cheap), Nova Lite (multimodal, balanced), Nova Pro (multimodal, capable), Nova Premier (frontier).
- **Bedrock Guardrails** — six categories: content moderation, prompt-attack detection, PII redaction, topic policy, word filters, contextual grounding. **Automated Reasoning** (Dec 2025) provides formal verification of LLM output against Cedar policies.
- **Centralized guardrails across Organizations** (2026) — every Bedrock invocation in the org passes through the central guardrail.
- **Bedrock Knowledge Bases** matured — managed RAG with OpenSearch Serverless / Aurora pgvector / MongoDB Atlas / Pinecone / Redis Enterprise; semantic + hierarchical chunking; reranking; citations.
- **Prompt Caching** (recent addition; check current state) — cache the prompt prefix server-side for repeated invocations sharing system prompt.
- **Majority of Bedrock token usage is Trainium-served** per AWS reports — see [SageMaker](/stacks/aws/sagemaker/) for Trainium2/3 details.
- **Bedrock Agents (the older feature)** is still around but **[AgentCore](/stacks/aws/agentcore/) is the new path** for production agents.

## Patterns

### Converse API

```python
import boto3

bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-2')

response = bedrock_runtime.converse(
    modelId='anthropic.claude-sonnet-4-7-20251015-v1:0',
    messages=[{'role': 'user', 'content': [{'text': 'Help me cancel order ABC-123'}]}],
    system=[{'text': 'You are a helpful customer service agent.'}],
    inferenceConfig={'maxTokens': 4096, 'temperature': 0.0},
    toolConfig={
        'tools': [{
            'toolSpec': {
                'name': 'cancel_order',
                'description': 'Cancel an order by ID',
                'inputSchema': {'json': {'type': 'object', 'properties': {'order_id': {'type': 'string'}}, 'required': ['order_id']}}
            }
        }],
        'toolChoice': {'auto': {}},
    },
    guardrailConfig={'guardrailIdentifier': 'gr-xxxxx', 'guardrailVersion': '1'},
)
```

Same shape whether you're calling Claude, Nova, Llama, or Mistral.

### Streaming

```python
response_stream = bedrock_runtime.converse_stream(modelId=..., messages=..., ...)
for event in response_stream['stream']:
    if 'contentBlockDelta' in event:
        delta = event['contentBlockDelta']['delta']
        if 'text' in delta:
            print(delta['text'], end='', flush=True)
```

Stream for user-facing latency; buffer + return for backend pipelines.

### Cross-region inference profile

```python
modelId='us.anthropic.claude-sonnet-4-7-20251015-v1:0'  # 'us.' prefix = cross-region in US
```

Reduces throttling at the cost of slightly higher latency variance.

### Provisioned Throughput

For latency-critical or high-RPS workloads, committed inference capacity — pay hourly for guaranteed TPS. Use when predictable steady volume exceeds on-demand quota or latency SLO requires no queueing.

### Bedrock Guardrails

Six categories: content moderation, prompt-attack detection, topic policy, PII, word filters, contextual grounding (RAG hallucination + relevance). **Automated Reasoning** (Dec 2025) provides formal verification against Cedar policies.

**Guardrails on every customer-facing model call — non-negotiable.**

### Bedrock Knowledge Bases — the managed RAG path

Vector stores: OpenSearch Serverless, Aurora pgvector, MongoDB Atlas, Pinecone, Redis Enterprise. Data sources: S3, Confluence, SharePoint, Salesforce, web, Slack, Jira. Chunking: fixed-size, semantic, hierarchical, custom (Lambda). Reranking + citations.

For most RAG workloads in 2026, Knowledge Bases is the right starting point.

### Throttling + back-pressure

Bedrock per-model TPS quotas are low by default. Strategies:
- **Cross-region inference profile** — automatic spreading.
- **Provisioned Throughput** — committed capacity.
- **Application-level token bucket** — pace requests below quota.
- **Quota increase requests** — file early.
- **Multi-model fallback** — Claude Sonnet fails → Nova Pro → cached / canned response.

## Anti-patterns

- **Legacy `invoke_model` API** for new code. Use Converse.
- **No guardrails on customer-facing endpoints.** Eventual prompt-injection / abuse.
- **Calling Anthropic / OpenAI APIs directly from Lambda** when Bedrock has the same model and integrates with AWS IAM + observability + guardrails.
- **Single-region Bedrock for global apps.** Use cross-region inference profile.
- **Fine-tuning when RAG + better prompts would do.** Fine-tuning is the last resort.
- **No token / cost metrics emitted from your agent code.** Surprise bills.
- **PII in prompts without redaction.** Compliance violation.

## Gotchas

- **Per-model TPS quotas vary** — verify the current quota for the model in your region before designing high-RPS workloads.
- **Model availability per region** — not every model in every region; verify before promising features.
- **Streaming requires holding the connection open** — long contexts can hit API Gateway 29s timeout. Use response streaming Lambda + Lambda URLs.
- **Embedding model dimensions matter** for downstream vector store — switching models means re-embedding.
- **Bedrock pricing is per-token** — calculate carefully for long-context use cases.

## Cross-references

- [`/stacks/aws/agentcore/`](/stacks/aws/agentcore/) — production agent layer; AgentCore Runtime/Browser/Memory
- [`/stacks/aws/strands-agents/`](/stacks/aws/strands-agents/) — AWS-blessed agent authoring SDK
- [`/stacks/aws/sagemaker/`](/stacks/aws/sagemaker/) — custom training / fine-tuning beyond Bedrock fine-tuning
- [`/stacks/aws/opensearch/`](/stacks/aws/opensearch/) — vector store for Knowledge Bases
- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — pgvector alternative
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — role view; agent vs workflow decision
- [Bedrock model docs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html) — canonical model list with versions
