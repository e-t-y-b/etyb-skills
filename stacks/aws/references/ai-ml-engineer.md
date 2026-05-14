---
role: ai-ml-engineer
stack: aws
last_verified_on: "2026-05-14"
---

# AWS Overlay — ai-ml-engineer

You are ai-ml-engineer on an AWS engagement. You own the **agent design**, the **model selection and routing**, the **RAG pipeline**, the **fine-tuning + custom training**, the **inference serving**, and the **AI safety + guardrails posture**. This overlay covers the AWS-specific decisions for AI/ML in 2026 — and AWS's AI surface moved more in 2025 than in the prior three years combined.

**Currency:** AWS as of **2026-Q2**. AgentCore (Runtime + Browser + Memory) is the post-2024 layer most LLM training data won't know. Strands Agents SDK is open-sourced. Bedrock model gateway evolved twice in 2025.

## What changed in 2025-2026 that older training data misses

This is the most-changed surface in the entire AWS stack. Every claim here is post-cutoff for many LLMs:

- **AgentCore** (Bedrock AgentCore) is the production agent layer. Components:
  - **AgentCore Runtime** — production execution environment for agents with isolated, ephemeral, secure sessions. Replaces "deploy your own agent on Lambda + custom orchestration."
  - **AgentCore Browser** — managed browser tool for agents (fill forms, click, scrape). Replaces hand-rolled Playwright orchestration.
  - **AgentCore Memory** — managed long-term + short-term memory for agents, with hooks for retention/forgetting policies.
  - Additional AgentCore components shipped through 2025 (Tools, Gateway, etc.) — verify current state.
- **Strands Agents SDK** — open-sourced May 2025. AWS's blessed agent framework, agent-loop + tool-use + planning. Pairs with AgentCore Runtime. Apache 2.0 license; community + AWS development.
- **Bedrock model gateway** evolved — Claude (Anthropic), Nova (Amazon), Llama (Meta), Mistral, DeepSeek, Stable Diffusion + image models, plus more depending on region and availability. The exact list changes; verify against [Bedrock model docs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html).
- **Amazon Nova** family (Amazon's own model family, late 2024): Nova Micro (text only, cheap), Nova Lite (multimodal, balanced), Nova Pro (multimodal, capable), Nova Premier (frontier).
- **Bedrock Guardrails** — content moderation, prompt-attack detection, PII redaction, **automated reasoning** (formal verification of LLM output against Cedar policies, Dec 2025), centralized enforcement across Organizations.
- **Bedrock Knowledge Bases** — managed RAG, multiple vector store backends (OpenSearch Serverless, Aurora pgvector, MongoDB Atlas), advanced chunking strategies (semantic chunking, hierarchical), reranking.
- **SageMaker Unified Studio / SageMaker AI Studio** — one-click onboarding with existing AWS data (Athena, Redshift, S3), unified workspace for data + ML + analytics.
- **SageMaker HyperPod** — distributed training infrastructure with checkpointless training (>95% goodput), dynamic scaling, NVL72 UltraServer (72 Blackwell GPUs via NVLink).
- **Trainium2** GA, **Trainium3** preview end 2025 → volume 2026. Up to 50% cost reduction for training + inference vs GPUs. Majority of Bedrock token usage already on Trainium.
- **Bedrock Agents (the older feature)** is still around but **AgentCore is the new path** for production agents. Don't propose old Bedrock Agents for new builds when AgentCore fits.
- **CodeWhisperer → Amazon Q Developer.** Q Business is the enterprise RAG/search tier.

If you're proposing custom Lambda-based agent orchestration (with no good reason), old Bedrock Agents for new builds, or "let's call Anthropic's API directly from Lambda" for a workload that should use Bedrock — your knowledge is stale.

## Agent design — the AgentCore-first pattern

### Decision: is an agent the right answer?

Before reaching for AgentCore + Strands, ask: **is this an agent, or a workflow?**

| Pattern | Use |
|---------|-----|
| **Workflow** — deterministic steps, branching by conditions, occasional LLM call for classification/extraction | **Step Functions + Lambda + Bedrock InvokeModel.** No agent framework. |
| **Agent** — the LLM decides which tool to call, in what order, based on reasoning. Loop continues until task complete. | **AgentCore Runtime + Strands Agents SDK** (or comparable framework). |
| **Conversational interface** — user-facing chat with memory, tools, RAG | **AgentCore Runtime + AgentCore Memory + Knowledge Bases.** |

The wrong call costs operational complexity and inference dollars. Most "agent" requirements are actually workflows with an LLM call inside; promote to true agent only when LLM-decided control flow adds value.

### Strands Agents SDK — the modern shape

```python
# strands_agent_example.py
from strands import Agent, tool
from strands.models.bedrock import BedrockModel

@tool
def get_order_status(order_id: str) -> dict:
    """Get the current status of an order by ID."""
    # business logic, DB call, etc.
    return {'order_id': order_id, 'status': 'shipped', 'tracking': '1Z999...'}

@tool
def refund_order(order_id: str, reason: str) -> dict:
    """Initiate a refund for an order with the given reason."""
    # business logic
    return {'order_id': order_id, 'refund_id': 'r-456', 'amount': 49.99}

model = BedrockModel(
    model_id='anthropic.claude-sonnet-4-7-20251015-v1:0',
    region_name='us-east-2',
    temperature=0.0,
    max_tokens=4096,
)

agent = Agent(
    model=model,
    tools=[get_order_status, refund_order],
    system_prompt=(
        "You are a customer service agent. Help users check order status and process refunds. "
        "Confirm refund requests before processing. Use only the tools provided."
    ),
)

response = agent("My order ABC-123 hasn't arrived. Can I get a refund?")
print(response.message)
```

Key Strands properties:
- **Tool decorator** — functions with type hints become tools the agent can call.
- **Agent loop** built-in — `agent(prompt)` runs reasoning → tool call → result → next reasoning until done.
- **Multiple model providers** — Bedrock, Anthropic API direct, OpenAI, others. Bedrock first for AWS-native workloads.
- **Streaming** — `agent.stream(prompt)` for token-by-token output.
- **Memory** — short-term (in-session) built-in; long-term integrates with AgentCore Memory.

### Deploying to AgentCore Runtime

```python
# After developing locally with Strands, deploy to AgentCore Runtime
# Pseudo-flow (verify exact AgentCore SDK against latest docs):

from agentcore import Runtime, RuntimeConfig

runtime = Runtime(
    name='customer-service-agent',
    config=RuntimeConfig(
        max_session_duration='1h',
        memory_backend='agentcore-memory',
        guardrail_id='gr-xxxxx',
        observability='cloudwatch',
    ),
)

# Package agent + tools, deploy
runtime.deploy(agent_module='customer_service.agent')
```

AgentCore Runtime gives you:
- **Isolated session execution** — each session in its own ephemeral environment, no cross-session data leak.
- **Built-in observability** — sessions surfaced in CloudWatch + X-Ray.
- **Guardrail integration** — every model call evaluated against Bedrock Guardrails.
- **Memory integration** — long-term memory via AgentCore Memory.
- **IAM-based access control** — each session runs with a scoped role.
- **Auto-scaling** — handles concurrent sessions without you sizing infrastructure.

For new agentic workloads in 2026, **AgentCore Runtime is the deployment target**, not "self-host on EC2" or "build orchestration on Step Functions."

### AgentCore Browser

For agents that need to interact with web pages (form fill, click, scrape):

```python
from agentcore.browser import Browser

browser = Browser()
page = browser.navigate('https://example.com/order/lookup')
page.fill('input[name="orderId"]', 'ABC-123')
page.click('button[type="submit"]')
result = page.read('selector .status')
```

vs hand-rolling Playwright + headless Chrome + screenshot capture. AgentCore Browser handles:
- Session isolation.
- CAPTCHA handling (limited; check current state).
- Screenshot + accessibility tree extraction for LLM context.
- Audit logging of actions.

### AgentCore Memory

Long-term memory for agents — preferences, history, derived facts:

```python
from agentcore.memory import Memory

memory = Memory(memory_id='user-123-prefs')
memory.put('preferred_language', 'en')
memory.put('past_orders', [...])

# In a new session
prefs = memory.get('preferred_language')
```

Patterns:
- **User-scoped memory**: persists across sessions for a single user.
- **Session-scoped memory**: only within a single session (short-term context).
- **Org-scoped memory**: shared facts across users (e.g., FAQs, company policy).

Retention policies — forget after N days, on user request (GDPR right-to-be-forgotten), or never. Set explicitly.

## Bedrock — the model gateway

### Model selection

Decision matrix:

| Workload | Default Model | Why |
|----------|---------------|-----|
| General reasoning, agentic, coding | **Claude Sonnet (latest)** | Best reasoning + tool-use + safety for production agents |
| High-frequency, lower-stakes | **Claude Haiku (latest)** | Cheaper, faster, sufficient for many tasks |
| Frontier reasoning, hard problems | **Claude Opus (latest)** | When Sonnet stalls or quality matters more than cost |
| AWS-internal / data-residency-sensitive | **Amazon Nova (Pro / Lite / Micro / Premier)** | Trained + served on AWS; cost-competitive |
| Open-source preference, fine-tunable | **Llama 3.1/3.3 (Meta) or DeepSeek** | Open weights, can be fine-tuned via SageMaker |
| Image generation | **Stable Diffusion XL or Amazon Titan Image** | Bedrock-managed; check region availability |
| Embeddings | **Cohere embed-v3 / Amazon Titan Text Embeddings v2** | Cohere v3 strong on multilingual; Titan strong on cost + AWS-native |
| Speech-to-text | **Bedrock-hosted Whisper or AWS Transcribe** | Whisper for transcription quality; Transcribe for AWS-integrated streaming |
| Text-to-speech | **Amazon Polly** or **AWS-hosted Eleven Labs (if available)** | Polly for traditional TTS; check current external model availability |

Always **verify the exact model ID** against current Bedrock docs — model IDs include version dates, and Anthropic releases new Claude Sonnet versions quarterly.

### Bedrock Runtime — the invoke patterns

```python
import boto3, json

bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-2')

# Invoke with structured tool use (Claude)
response = bedrock_runtime.converse(
    modelId='anthropic.claude-sonnet-4-7-20251015-v1:0',
    messages=[
        {'role': 'user', 'content': [{'text': 'Help me cancel order ABC-123'}]}
    ],
    system=[{'text': 'You are a helpful customer service agent.'}],
    inferenceConfig={
        'maxTokens': 4096,
        'temperature': 0.0,
    },
    toolConfig={
        'tools': [
            {
                'toolSpec': {
                    'name': 'cancel_order',
                    'description': 'Cancel an order by ID',
                    'inputSchema': {
                        'json': {
                            'type': 'object',
                            'properties': {
                                'order_id': {'type': 'string'},
                            },
                            'required': ['order_id'],
                        }
                    }
                }
            }
        ],
        'toolChoice': {'auto': {}},
    },
    guardrailConfig={
        'guardrailIdentifier': 'gr-xxxxx',
        'guardrailVersion': '1',
    },
)
```

The **Converse API** (and **ConverseStream**) is the modern unified interface across all Bedrock models — same shape whether you're calling Claude, Nova, Llama, or Mistral. Tool config + guardrails are first-class.

Don't use the legacy `invoke_model` API for new code; Converse is the path forward.

### Streaming

```python
response_stream = bedrock_runtime.converse_stream(modelId=..., messages=..., ...)

for event in response_stream['stream']:
    if 'contentBlockDelta' in event:
        delta = event['contentBlockDelta']['delta']
        if 'text' in delta:
            print(delta['text'], end='', flush=True)
```

Stream for user-facing latency (TTFB matters); buffer + return for backend pipelines (latency doesn't matter, simpler error handling).

### Cross-region inference

Bedrock cross-region inference (2024) — invoke a model and AWS routes to the region with lowest latency / least throttling. Significantly reduces ProvisionedThroughputExceededException at scale.

Enable via inference profile ID:

```python
modelId='us.anthropic.claude-sonnet-4-7-20251015-v1:0'  # 'us.' prefix = cross-region in US
```

### Provisioned throughput

For latency-critical or high-RPS workloads, Bedrock Provisioned Throughput (committed inference capacity) — pay hourly for guaranteed TPS. Use when:
- Predictable steady volume that exceeds on-demand quota.
- Latency SLO requires no queueing.

On-demand is sufficient for most workloads up to the per-model TPS quota.

## Bedrock Guardrails

```python
guardrails = boto3.client('bedrock', region_name='us-east-2')

guardrail = guardrails.create_guardrail(
    name='order-agent-guardrail',
    description='Guardrails for the customer service order agent',
    contentPolicyConfig={
        'filtersConfig': [
            {'type': 'SEXUAL', 'inputStrength': 'HIGH', 'outputStrength': 'HIGH'},
            {'type': 'VIOLENCE', 'inputStrength': 'HIGH', 'outputStrength': 'HIGH'},
            {'type': 'HATE', 'inputStrength': 'HIGH', 'outputStrength': 'HIGH'},
            {'type': 'INSULTS', 'inputStrength': 'HIGH', 'outputStrength': 'HIGH'},
            {'type': 'MISCONDUCT', 'inputStrength': 'HIGH', 'outputStrength': 'HIGH'},
            {'type': 'PROMPT_ATTACK', 'inputStrength': 'HIGH', 'outputStrength': 'NONE'},
        ]
    },
    sensitiveInformationPolicyConfig={
        'piiEntitiesConfig': [
            {'type': 'EMAIL', 'action': 'ANONYMIZE'},
            {'type': 'CREDIT_DEBIT_CARD_NUMBER', 'action': 'BLOCK'},
            {'type': 'US_SOCIAL_SECURITY_NUMBER', 'action': 'BLOCK'},
        ]
    },
    topicPolicyConfig={
        'topicsConfig': [{
            'name': 'NoLegalAdvice',
            'definition': 'Avoid giving legal advice about consumer rights',
            'examples': ['What are my rights under FTC...'],
            'type': 'DENY',
        }]
    },
    contextualGroundingPolicyConfig={
        'filtersConfig': [
            {'type': 'GROUNDING', 'threshold': 0.7},
            {'type': 'RELEVANCE', 'threshold': 0.7},
        ]
    },
)
```

The six guardrail categories:
1. **Content moderation** — sexual, violence, hate, insults, misconduct.
2. **Prompt-attack detection** — jailbreak attempts, prompt injection.
3. **Topic policy** — natural-language descriptions of disallowed topics.
4. **PII** — entity detection with block/anonymize actions.
5. **Word filters** — exact-string deny lists.
6. **Contextual grounding** — for RAG: hallucination detection (output not grounded in retrieved context) and relevance (retrieved context not relevant to query).

**Automated Reasoning** (Dec 2025) — formal verification of LLM output against Cedar policies. For domains where you can write Cedar (auth, policy enforcement), Automated Reasoning gives mathematically-verified output.

### Centralized guardrails across Organizations

2026 addition: guardrails can be enforced centrally via Organizations — every Bedrock invocation in the org passes through the central guardrail. Use for:
- Org-wide PII redaction.
- Org-wide topic denials.
- Compliance enforcement.

## RAG — retrieval-augmented generation on AWS

### Bedrock Knowledge Bases — the managed RAG path

```python
kb_client = boto3.client('bedrock-agent', region_name='us-east-2')

# Knowledge Base setup — once, via console or IaC
# Then query at runtime:

bedrock_agent_runtime = boto3.client('bedrock-agent-runtime', region_name='us-east-2')

response = bedrock_agent_runtime.retrieve_and_generate(
    input={'text': 'What is our refund policy for damaged items?'},
    retrieveAndGenerateConfiguration={
        'type': 'KNOWLEDGE_BASE',
        'knowledgeBaseConfiguration': {
            'knowledgeBaseId': 'kb-xxxxx',
            'modelArn': 'arn:aws:bedrock:us-east-2::foundation-model/anthropic.claude-sonnet-4-7-20251015-v1:0',
            'retrievalConfiguration': {
                'vectorSearchConfiguration': {
                    'numberOfResults': 5,
                }
            },
            'generationConfiguration': {
                'guardrailConfiguration': {
                    'guardrailId': 'gr-xxxxx',
                    'guardrailVersion': '1',
                }
            }
        }
    }
)
```

Knowledge Bases supports:
- **Vector stores**: OpenSearch Serverless (default), Aurora pgvector, MongoDB Atlas, Pinecone, Redis Enterprise.
- **Data sources**: S3, Confluence, SharePoint, Salesforce, web (via crawl), Slack, Atlassian Jira.
- **Chunking strategies**: fixed-size, semantic, hierarchical, custom (Lambda-defined).
- **Reranking** (2024-2025): rerank retrieved chunks with a reranking model for better relevance.
- **Citations** — every generated response can include source citations.

For most RAG workloads in 2026, Knowledge Bases is the right starting point. Reach for custom RAG only when:
- You need a custom retrieval algorithm Knowledge Bases doesn't expose.
- Data sources aren't in the supported list and connector isn't worth building.
- You're running outside AWS and don't want the vendor lock.

### Custom RAG — when

```python
# Generate embeddings, store in vector DB
embedding_response = bedrock_runtime.invoke_model(
    modelId='amazon.titan-embed-text-v2:0',
    body=json.dumps({'inputText': text, 'dimensions': 1024}),
)
embedding = json.loads(embedding_response['body'].read())['embedding']

# Store in OpenSearch Serverless / Aurora pgvector / Pinecone / Qdrant
# At retrieval time: kNN search → top-k → assemble context → invoke Bedrock model with retrieved context
```

Patterns that matter regardless of vector DB:
- **Chunking strategy** — fixed-size 256-512 tokens with overlap is the baseline; semantic chunking (chunk-on-paragraph-break or topic-shift) often better.
- **Embedding model** — Cohere embed-v3 for multilingual + better quality; Titan v2 for AWS-native + cost.
- **Hybrid search** — combine vector search + BM25 keyword search for higher recall.
- **Reranking** — rerank top-50 with a reranking model, take top-5 for context.
- **Context window management** — for long contexts, summarize older history; don't blindly stuff every retrieved chunk.

### Vector DB choice

| Choice | Use when |
|--------|----------|
| **OpenSearch Serverless (VECTORSEARCH workload type)** | Variable load, AWS-native, hybrid (text + vector) needed |
| **Aurora pgvector / DSQL pgvector** | <10M vectors, embeddings live with relational data, low-medium scale |
| **Bedrock Knowledge Bases** (managed) | Don't want to think about vector DB choice |
| **Pinecone** | High-scale, vendor-managed, best-in-class APIs |
| **Qdrant / Weaviate** | Self-hosted, open-source, customizable |

Default for new RAG on AWS: Knowledge Bases (which uses OpenSearch Serverless or Aurora pgvector under the hood). Reach for custom when you've outgrown the managed shape.

## SageMaker — the ML lifecycle

### SageMaker AI Studio (Unified)

The 2024 unified workspace. One-click onboarding with Athena / Redshift / S3. Covers:
- **Data prep**: Glue + Athena + EMR.
- **Notebooks**: JupyterLab + Code Editor on persistent EKS clusters.
- **Training**: SageMaker Training Jobs, HyperPod for distributed.
- **Deployment**: SageMaker endpoints (real-time, async, serverless).
- **Pipelines**: SageMaker Pipelines for orchestration.

Pick when:
- Building custom models (not just using Bedrock-hosted).
- Need full ML lifecycle (data → train → deploy → monitor).
- Team has data scientists, not just app engineers.

### SageMaker HyperPod

Distributed training infrastructure.
- **NVL72 UltraServer**: 18 instances × 72 Blackwell GPUs via NVLink.
- **Checkpointless training**: auto-recovery in minutes, >95% goodput.
- **Dynamic scaling**: expand / contract running jobs to absorb idle accelerators.
- **JupyterLab + Code Editor** on persistent EKS clusters (Nov 2025).
- **Managed Grafana dashboards** for GPU / network / cluster health (Mar 2026).

Pick HyperPod when:
- Training large models (>10B parameters).
- Distributed training across 100+ GPUs.
- Need infrastructure resilience (checkpointless, dynamic scaling).

For smaller fine-tuning jobs, SageMaker Training Jobs without HyperPod is sufficient.

### Custom silicon — Trainium / Inferentia

| Chip | Status | Use for |
|------|--------|---------|
| **Trainium2** | GA | Training + inference; 30-40% better price-perf vs GPUs |
| **Trainium3** | Preview end 2025, volume 2026 | 4.4x perf vs Trn2 |
| **Inferentia2** | GA (de-emphasized for GenAI) | Cost-optimized inference; used for traditional ML serving |

**Bedrock token usage is majority Trainium-served** (per AWS reports). For your own training, Trn2 is the cost-effective alternative to P4/P5/P6 (NVIDIA H100/H200/B200/B300). The catch: you must compile for Neuron (Trainium SDK) — most models work, custom ops may not.

For inference: P5/P6 (GPU) is the safer choice when you need broad model + framework support; Inf2/Trn2 when cost is the priority and the model compiles cleanly.

### SageMaker endpoints

| Type | Use for |
|------|---------|
| **Real-time** | Sync inference, latency-sensitive |
| **Serverless** | Variable load, scale-to-zero acceptable |
| **Async** | Long-running inference (>1min) |
| **Batch transform** | Offline bulk inference |
| **Multi-model endpoint** | Many models, infrequent traffic each |

Default for new endpoints: **Serverless** for spiky workloads, **Real-time** for steady high-RPS, **Async** when input/output are large or compute is long.

### Model Monitor + Clarify

- **Model Monitor**: data drift + model drift detection on deployed endpoints. Scheduled jobs compare baseline statistics vs production traffic.
- **Clarify**: bias detection + explainability (SHAP). Run pre-deploy for fairness audits; integrate into Model Monitor for continuous bias monitoring.

For any production model, both are non-negotiable.

## Fine-tuning — the where + when

### Fine-tuning on Bedrock

Some Bedrock models support fine-tuning (verify current list — Claude, Llama, Titan, Cohere typically). Provision Custom Model Units to host fine-tuned models.

```python
# Submit fine-tuning job
bedrock = boto3.client('bedrock', region_name='us-east-2')

job = bedrock.create_model_customization_job(
    jobName='order-classifier-finetune',
    customModelName='order-classifier-v1',
    baseModelIdentifier='meta.llama3-3-70b-instruct-v1:0',
    trainingDataConfig={'s3Uri': 's3://my-bucket/training/orders.jsonl'},
    validationDataConfig={'validators': [{'s3Uri': 's3://my-bucket/validation/orders.jsonl'}]},
    outputDataConfig={'s3Uri': 's3://my-bucket/output/'},
    roleArn='arn:aws:iam::123456789012:role/BedrockCustomizationRole',
    hyperParameters={'epochCount': '3', 'batchSize': '4', 'learningRate': '0.00005'},
)
```

Use Bedrock fine-tuning when:
- Open-weight model + your data + Bedrock hosting is the cleanest path.
- You want managed hosting (Custom Model Units) without setting up SageMaker endpoints.

### Fine-tuning on SageMaker

For deeper customization: SageMaker Training Jobs + your own data + HuggingFace / PyTorch + deploy to SageMaker endpoint.

- **LoRA / QLoRA** via HuggingFace PEFT — most cost-effective for adapter-style fine-tuning.
- **Full fine-tuning** on Trainium2 — when adapters aren't enough.
- **Continued pretraining** for domain adaptation (rare in 2026 — RAG usually wins).

### When NOT to fine-tune

- **Better prompts + RAG can usually beat fine-tuning** for knowledge updates. Try first.
- **Fine-tuned models go stale** as base models improve. A fine-tuned Claude 3.5 model in 2025 is worse than out-of-the-box Claude 4.7 in 2026 for most general tasks.
- **The data isn't there.** Fine-tuning needs hundreds-thousands of high-quality examples; few teams have curated this.

## Inference at scale — patterns

### Throttling + back-pressure

Bedrock per-model TPS quotas are low by default (e.g., 10 TPS for some Claude models per region). Hit them, you get ProvisionedThroughputExceededException.

Patterns:
- **Cross-region inference profile** — automatic spreading.
- **Provisioned Throughput** — committed capacity.
- **Application-level token bucket** — pace requests below quota.
- **Quota increase requests** — file early, take weeks for some models.
- **Multi-model fallback** — Claude Sonnet fails → fallback to Nova Pro → fallback to cached / canned response.

### Caching

Same input → same output (deterministic with `temperature=0`)? Cache.

- **DynamoDB or ElastiCache** with input hash as key, output as value, TTL based on freshness needs.
- **Bedrock Prompt Caching** (recent addition; check current state) — cache the prompt prefix server-side for repeated invocations with shared system prompt.

Cache aggressively for high-RPS LLM-as-utility patterns (classification, summarization of static documents). Don't cache for personalized / non-deterministic responses.

### Cost monitoring on LLM workloads

LLM workloads can rack up six-figure monthly Bedrock bills surprisingly fast.

- **Custom CloudWatch metrics** emitted from your Lambda / agent code: tokens-in, tokens-out, model invoked, success/failure.
- **Daily cost reports** filtered by Bedrock + the tags on your principals.
- **Per-tenant cost attribution** if you're running multi-tenant — tag invocations with `Tenant`, attribute via CUR.
- **Hard caps** via Service Quotas — set lower-than-default per-model TPS in dev/staging to prevent runaway bills.

## Patterns

- **AgentCore Runtime + Strands SDK** for new agentic workloads.
- **Bedrock Knowledge Bases** for managed RAG.
- **Converse API** (not legacy invoke_model) for new Bedrock code.
- **Cross-region inference profiles** for resilience to per-region throttling.
- **Guardrails on every customer-facing model call** — non-negotiable.
- **Tool use with structured schemas** — typed tools beat free-form prompts.
- **Citations on RAG responses** for grounding + trust.
- **Reranking** for higher RAG precision.
- **Embedded LLM observability** — token counts, model IDs, latencies in CloudWatch.
- **Per-tenant cost attribution** for SaaS multi-tenant LLM workloads.
- **Trust + Safety review** for any user-generated content path that touches an LLM.

## Anti-patterns

- **Custom Lambda-based agent orchestration** when AgentCore fits.
- **Old Bedrock Agents for new builds** — AgentCore is the new path.
- **Legacy invoke_model API** — use Converse.
- **No guardrails on customer-facing endpoints** — eventual prompt-injection / abuse.
- **Fine-tuning when RAG + better prompts would do** — fine-tuning is the last resort.
- **Calling Anthropic / OpenAI APIs directly from Lambda** when Bedrock has the same model and integrates with AWS IAM + observability + guardrails.
- **No token / cost metrics** — surprise bills.
- **Single-region Bedrock for global apps** — latency + throttling. Use cross-region inference.
- **RAG without citations** — users can't verify; trust eroded.
- **No data drift / model drift monitoring** — silent quality degradation.
- **PII in prompts without redaction** — compliance violation.

## Tooling specifics

- **`boto3` (Python) / `@aws-sdk/client-bedrock-runtime` (JS)** — Bedrock SDK clients.
- **Strands Agents SDK** — open-source, Apache 2.0. Pip: `pip install strands-agents`.
- **AgentCore SDKs** — Python + Node primary. Check current state.
- **SageMaker Python SDK** — `pip install sagemaker`. High-level API over training jobs, endpoints, pipelines.
- **HuggingFace + SageMaker integration** — `transformers` + SageMaker `HuggingFace` estimator for training.
- **LangChain + Bedrock** — LangChain has Bedrock LLM + embeddings + RetrievalQA wrappers. Use if team already on LangChain; otherwise prefer Strands for agentic + raw Bedrock for simple invocations.
- **LangGraph + Bedrock** — graph-based agent orchestration; alternative to Strands.
- **Amazon Q Developer** — IDE assistant. Free + Pro tiers. Editor-embedded, not an installable MCP.
- **Amazon Q Business** — enterprise RAG/search product.

## Cross-references — products this overlay touches

- **AgentCore (Runtime + Browser + Memory)** — high drift risk; covered here.
- **Strands Agents SDK** — high drift risk; covered here.
- **Bedrock + Guardrails + Knowledge Bases** — covered here.
- **SageMaker (AI Studio, HyperPod)** — covered here.
- **Trainium / Inferentia** — covered here.
- **OpenSearch Serverless / Aurora pgvector** — vector storage; design in [`database-architect.md`](database-architect.md), usage here.

## Integration with always-on protocols

### TDD on AI/ML

- **Eval-driven development**: before deploying a prompt change, run against an eval set (50-200 examples) and score with a programmatic eval (regex, structured output check, LLM-as-judge).
- **Regression tests on agent flows**: replay past sessions through the new agent; assert tool-use shape + output quality didn't regress.
- **Guardrails are testable**: test inputs that should be blocked, assert block. Test inputs that should pass, assert pass.

### Verification on AI/ML

Claims must cite:
- "Claude Sonnet 4.7 is available on Bedrock us-east-2" → [Bedrock model docs](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html).
- "AgentCore Runtime supports session isolation" → AgentCore docs.
- "Bedrock Guardrails support automated reasoning" → re:Invent 2025 announcement.

Models, regions, features change quarterly. Verify against docs, not memory.

### Debugging AI/ML

1. **Inspect the actual prompt sent** — including the system prompt + tool descriptions + history. LLM behavior often diverges from intent here.
2. **Inspect the actual model output** — including tool-use blocks. Format issues often hide here.
3. **Vary one parameter at a time** — temperature, model ID, system prompt, tool schemas. If you change three at once, you don't know which fixed/broke it.
4. **Eval on a frozen set** — when fixing an issue, ensure the fix doesn't regress other behaviors. Run the eval set.
5. **LLM-as-judge for subjective quality** — pair-wise comparison or rubric-based grading by a stronger model.

### Branch safety on AI/ML

- **Prompts in version control** — never edit prompts in production console.
- **Agent + tool definitions in code** — reviewable, testable.
- **Model ID pinned, not floating** — `anthropic.claude-sonnet-4-7-20251015-v1:0`, not `latest`.
- **Eval set in repo** — every prompt change PR runs the eval; reviewers see deltas.
