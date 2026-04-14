# LLM & Generative AI — Deep Reference

**Always use `WebSearch` to verify version numbers, model capabilities, and best practices. The LLM landscape changes weekly. Last verified: April 2026.**

## Table of Contents
1. [LLM Landscape](#1-llm-landscape)
2. [Prompt Engineering](#2-prompt-engineering)
3. [RAG (Retrieval-Augmented Generation)](#3-rag-retrieval-augmented-generation)
4. [Vector Databases](#4-vector-databases)
5. [Fine-Tuning](#5-fine-tuning)
6. [LLM Evaluation](#6-llm-evaluation)
7. [Agents & Tool Use](#7-agents--tool-use)
8. [LLM Security & Safety](#8-llm-security--safety)
9. [Cost Optimization](#9-cost-optimization)
10. [Decision Frameworks](#10-decision-frameworks)

---

## 1. LLM Landscape

### Frontier Models (April 2026)

| Model | Provider | Context | Output | Input/Output $/MTok | SWE-bench | Key Strength |
|-------|----------|---------|--------|-------------------|-----------|-------------|
| **Claude Opus 4.6** | Anthropic | 1M | 128K | $5/$25 | 80.8% | Deep reasoning, 1M context, agent teams |
| **Claude Sonnet 4.6** | Anthropic | 1M | 64K | $3/$15 | 79.6% | Best quality/cost ratio at frontier |
| **GPT-5.4** | OpenAI | 1.05M | 128K | ~$5/$15 | ~78% | Thinking variants, OSWorld 75% |
| **Gemini 2.5 Pro** | Google | 1M | 64K | $1/$10 | 80.6% | Multimodal (9.5hr audio), cheapest frontier |
| **DeepSeek V4** | DeepSeek | 128K | 32K | $0.30/$0.50 | 81% | 10-50x cheaper than frontier |

### Open-Weight Models

| Model | Params | Architecture | License | Best For |
|-------|--------|-------------|---------|----------|
| **Llama 4 Maverick** | 17B active / 400B+ total | MoE, 128 experts | Llama license | Self-hosted general-purpose, fits single H100 |
| **Llama 4 Scout** | 17B active | MoE, 16 experts | Llama license | Smaller footprint, INT4 on single H100 |
| **Mistral Large 3** | 41B active / 675B total | MoE | Apache 2.0 | True open-source, strong performance |
| **Qwen 3.5** | 397B | Dense | Apache 2.0 | 201 languages, best multilingual |
| **Qwen3.5-Omni** | Variable | Multimodal | Apache 2.0 | Text+image+audio+video native |
| **DeepSeek R1** | MoE | MLA + MoE | Open weights | Reasoning rivaling o1, open weights |

### Small Models (On-Device / Edge)

| Model | Params | Best For |
|-------|--------|----------|
| Qwen3.5-0.8B/2B | 0.8-2B | On-device, mobile |
| Ministral 3B | 3B | Edge, IoT |
| Llama 4 Scout (INT4) | 17B active | Single GPU, cost-sensitive |
| Mistral Small 4 | ~14B | Unified reasoning + multimodal + code |

### Open-Source vs Proprietary Decision

The performance gap has collapsed from 12 quality points (early 2025) to ~5 points (2026):

| Factor | Use Proprietary API | Use Open/Self-Hosted |
|--------|-------------------|---------------------|
| **Volume** | Low volume (no infra overhead) | High volume (economics win at scale) |
| **Quality** | Need absolute best (5-7% edge) | Good enough for the task |
| **Privacy** | Data can leave org | Data must stay on-prem |
| **Fine-tuning** | API fine-tuning sufficient | Need full weight access |
| **Control** | Acceptable vendor dependency | Need full control |
| **Cost** | < ~$5K/month on API | > ~$10K/month (self-host breaks even) |

**Reality check on self-hosting costs:** Realistic self-hosted deployment costs $125K-$190K/year when factoring in staff, infrastructure, and operations — not just GPU rental.

---

## 2. Prompt Engineering

### Core Techniques

| Technique | What It Does | When to Use |
|-----------|-------------|-------------|
| **Zero-shot** | Direct instruction, no examples | Simple tasks, capable models |
| **Few-shot** | 2-5 input/output examples | Format standardization, edge case handling |
| **Chain-of-Thought (CoT)** | Step-by-step reasoning | Math, logic, analysis, troubleshooting |
| **Self-Consistency** | Multiple CoT paths, majority vote | Ambiguous problems, higher reliability |
| **Tree-of-Thought** | Explore/backtrack reasoning branches | Complex multi-step reasoning |
| **Hybrid** | Blend role + few-shot + CoT + format | Complex production tasks |

**Chain-of-Thought** is standard in 2026 production systems. For Claude, use extended thinking mode for automatic CoT.

### Structured Outputs

**Anthropic (Claude):**
- Tool use with `strict: true` in tool definitions for guaranteed JSON schema compliance
- Returns parsed objects directly in `tool_use` content blocks
- Supports `type: "json"` in tool definitions

**OpenAI:**
- `response_format: { type: "json_schema", json_schema: {...} }` with `strict: true`
- Returns parsed JSON objects
- Function calling returns JSON string (requires `JSON.parse()`)

**MCP (Model Context Protocol):**
- Introduced by Anthropic (Nov 2024), now adopted by OpenAI, Google
- 97M installs by March 2026, 10,000+ public MCP servers
- Donated to Linux Foundation under the Agentic AI Foundation (AAIF)
- OpenAI deprecated Assistants API in favor of MCP (mid-2026 sunset)
- Standard protocol for tools, resources, and prompts across providers

### Prompt Optimization

**DSPy (Stanford NLP):**
Programming (not prompting) language models. Key optimizers:
- **MIPROv2**: Optimizes instructions + few-shot demonstrations
- **COPRO**: Generates and refines new instructions per step
- Compiles high-level task descriptions into optimized prompt pipelines
- **When to use**: When you need systematic prompt optimization, not manual iteration

**Promptfoo:**
- Open-source prompt testing and evaluation
- YAML-based config, A/B testing, LLM-as-judge evaluations
- Red teaming capabilities with OWASP/NIST presets
- 30,000+ developers

### Production Prompt Best Practices

1. **Be specific**: Crisp numeric constraints ("3 bullets", "under 50 words") and formatting hints ("in JSON")
2. **Add `strict: true`** to tool definitions for guaranteed schema compliance
3. **Validate inputs** with Pydantic before executing tool functions
4. **Handle errors everywhere**: Malformed arguments, missing functions, timeouts, infinite loops
5. **Control costs**: Tool definitions consume tokens; agent loops multiply API calls
6. **Test systematically**: Verify tool selection, argument accuracy, edge cases
7. **Version your prompts**: Track prompt changes alongside code changes

---

## 3. RAG (Retrieval-Augmented Generation)

### Architecture Patterns

| Pattern | Description | Complexity | Best For |
|---------|-------------|-----------|----------|
| **Naive RAG** | Embed → Store → Retrieve top-K → Generate | Low | Prototypes, simple Q&A |
| **Advanced RAG** | + Query rewriting, hybrid search, reranking, iterative retrieval | Medium | Production standard |
| **Agentic RAG** | Agent decides when/what to retrieve, can re-query and self-evaluate | High | Complex research, multi-step |
| **GraphRAG** | Vector search + knowledge graphs + ontologies | High | Up to 99% search precision |
| **Streaming RAG** | Continuous pipelines driven by document change events | Medium | Real-time data freshness |

**Production recommendation**: Start with Advanced RAG. Move to Agentic RAG only when users need multi-step research capabilities.

**Streaming RAG (2026):** Replaces batch re-indexing with continuous pipelines. Keeps embeddings fresh within seconds. Costs proportional to change rate, not corpus size.

### Chunking Strategies

| Strategy | Accuracy (Benchmark) | Best For | Typical Size |
|----------|---------------------|----------|-------------|
| **RecursiveCharacterTextSplitter** | 69% (highest) | Production default | 400-512 tokens |
| **Fixed-size** | ~65% | Simple starting point | 400-512 tokens with 10-20% overlap |
| **Semantic** | 54% | Dense prose, variable content | Variable (avg 43 tokens) |
| **Hierarchical** | Good | Complex docs, multi-level retrieval | Multi-level |
| **Page-level** | Good | PDFs, structured documents | Per page |

**Start with**: `RecursiveCharacterTextSplitter` at 400-512 tokens with 10-20% overlap. Only switch to semantic or hierarchical if metrics demand it.

### Retrieval Pipeline

The production RAG retrieval pipeline in 2026:

```
1. Query Processing
   - Query rewriting (LLM reformulates for better retrieval)
   - Query decomposition (break complex queries into sub-queries)

2. Hybrid Search
   - BM25 (keyword) + Vector (semantic) search
   - Reciprocal Rank Fusion (RRF) to combine results
   - Retrieve top-100 candidates

3. Reranking (HIGHEST ROI ADDITION)
   - Cohere Rerank 3.5 or BGE-Reranker
   - Re-scores top-100 → keep top 5-10
   - 10-30% precision improvement, 50-100ms added latency

4. Context Assembly
   - Arrange chunks with metadata (source, page, date)
   - Optionally expand with surrounding context

5. Generation
   - Pass retrieved context + query to LLM
   - Include source attribution instructions
```

**Reranking is the single highest-ROI addition** to basic RAG. If you only add one thing to naive RAG, add a reranker.

**HyDE (Hypothetical Document Embeddings):** Generate a hypothetical answer, embed it, retrieve similar docs. Underperforms vanilla dense retrieval in benchmarks. Use selectively for complex/exploratory queries only.

### RAG Evaluation

| Framework | Key Feature | Metrics |
|-----------|-------------|---------|
| **RAGAS 1.2** | Reference-free evaluation, dynamic recalibration | Faithfulness, Contextual Relevancy, Answer Relevancy, Recall, Precision |
| **DeepEval 2.3** | pytest-compatible TDD approach | 15+ metrics including G-Eval, Hallucination, Faithfulness |
| **MLflow GenAI** | Unified evaluation via `mlflow.genai.evaluate` | 50+ metrics from DeepEval, RAGAS, Arize Phoenix |

**Production impact:** Organizations using RAG report 60-80% reduction in hallucinations and 3x improvement in answer accuracy for domain-specific questions.

---

## 4. Vector Databases

### Comparison Matrix

| Database | Scale | Deployment | Key Strength | Best For |
|----------|-------|------------|-------------|----------|
| **Pinecone** | Billions | Fully managed | Zero-ops, API-first | Teams wanting no infrastructure management |
| **Weaviate** | Billions | Open-source + cloud | Built-in vectorization modules, hybrid search | Teams wanting built-in ML integration |
| **Qdrant** | Billions | Open-source (Rust) | Fastest, powerful metadata filtering | Performance-critical, complex filtering |
| **Milvus/Zilliz** | Billions | Open-source + managed | Distributed architecture, community | Cost at scale, largest dataset sizes |
| **Chroma** | Millions | Open-source, in-process | Simplicity, fast iteration | Prototyping, small-medium datasets |
| **pgvector** | 10-100M | Postgres extension | Zero new infrastructure | Postgres-native teams, smaller scale |

**Selection guide:**
- **Just starting / prototype**: Chroma (in-process, simplest setup)
- **Already using Postgres**: pgvector (up to ~10-100M vectors)
- **Production, managed**: Pinecone (zero-ops) or Zilliz (managed Milvus)
- **Production, self-hosted**: Qdrant (Rust, fastest) or Milvus (distributed)
- **Need built-in ML**: Weaviate (vectorization modules)

### Embedding Models (April 2026)

| Model | MTEB Score | $/MTok | Dims | Context | Type |
|-------|-----------|--------|------|---------|------|
| **Cohere embed-v4.0** | 65.2 | Varies | Variable | 512 tok | Proprietary, multimodal |
| **OpenAI text-embedding-3-large** | 64.6 | $0.13 | 3,072 | 8,192 tok | Proprietary |
| **OpenAI text-embedding-3-small** | ~62 | $0.02 | 1,536 | 8,192 tok | Proprietary, budget |
| **BGE-M3** (BAAI) | 63.0 | Free | 1,024 | 8,192 tok | Open-source, hybrid dense+sparse+multi-vector |
| **Nomic Embed Text V2** | ~62 | Free | 768 | 8,192 tok | Open-source, MoE |

**BGE-M3** stands out: supports dense, sparse, and multi-vector retrieval in a single model — hybrid search without separate models.

### Indexing Strategies

| Method | Speed | Memory | Recall | Best For |
|--------|-------|--------|--------|----------|
| **HNSW** | 10-50x faster | High | >95% | Real-time apps, <100M vectors |
| **IVF** | Good | Lower | Good | Memory-constrained, moderate scale |
| **Product Quantization (PQ)** | Good | 32-64x reduction | Lower | Billion-scale on commodity hardware |
| **IVF-PQ + HNSW** | Fastest | Smallest | 0.77 recall | Billion-scale production |

**Default**: HNSW for <100M vectors. IVF-PQ for billion-scale or severe memory constraints.

---

## 5. Fine-Tuning

### Methods Comparison

| Method | Precision | VRAM | Quality vs Full | Use Case |
|--------|----------|------|----------------|----------|
| **Full fine-tuning** | 16/32-bit | Very high | Best | Massive compute available, max quality |
| **LoRA** | 16-bit | Medium | Slightly less | Standard PEFT, good GPU available |
| **QLoRA** | 4-bit | Lowest | Near-LoRA | Single-GPU training, memory-constrained |
| **DoRA** | 16-bit | Like LoRA | +3.7% vs LoRA | When marginal quality matters |
| **ReFT (LoReFT)** | Variable | 10-50x less than LoRA | Good | Maximum parameter efficiency |

**2026 breakthrough**: Single-GPU fine-tuning era is peaking. QLoRA + Unsloth + FP8 → fine-tune 70B on a single 24GB GPU.

### Fine-Tuning Tools

| Tool | Best For | Key Feature |
|------|----------|-------------|
| **Unsloth** | Single-GPU efficiency | 2-5x faster, 80% less memory. Web UI (Unsloth Studio) |
| **Axolotl** | Multi-GPU / beginners | YAML config, FSDP2 integration, easy setup |
| **HuggingFace TRL** | RLHF/DPO workflows | Integrates with transformers ecosystem |
| **NVIDIA NeMo AutoModel** | Enterprise, multi-node | Day-0 HF model support, native PyTorch |
| **LLaMA-Factory** | Quick experimentation | 100+ models, web UI |
| **TorchTune** | PyTorch-native | Part of PyTorch ecosystem |

### When to Fine-Tune vs Prompt Engineering vs RAG

```
Decision tree:
1. Does the answer need data newer than training cutoff?
   → YES: RAG is mandatory (fine-tuning won't help)

2. Must the model consistently apply specific style/jargon/behavior?
   → YES: Evaluate fine-tuning (style is hard to prompt)

3. Knowledge base under 200K tokens?
   → YES: Full-context prompting (often cheaper than RAG pipeline)

4. None of the above?
   → Prompt engineering first (cheapest, fastest to iterate)
```

**Key insight**: "RAG changes what the model can see right now. Fine-tuning changes how the model tends to behave every time."

**2026 best pattern**: Hybrid — RAG for facts, fine-tuning for style/policy/decision behavior.

**Reality check**: The majority who think they need fine-tuning don't. Fine-tuning is worth the investment only when the model must learn domain-specific behavior that prompting cannot achieve.

### Training Data Preparation

- **Minimum viable dataset**: 50-100 high-quality examples for LoRA/QLoRA
- **Sweet spot**: 500-5,000 examples for most domain adaptation tasks
- **Quality > quantity**: 500 perfect examples beat 5,000 mediocre ones
- **Format**: Instruction-response pairs, conversation format, or completion format depending on use case
- **Decontamination**: Remove any benchmark test set examples from training data
- **Validation split**: Hold out 10-20% for evaluation

---

## 6. LLM Evaluation

### Evaluation Frameworks

| Framework | Type | Best For |
|-----------|------|----------|
| **lm-eval-harness** (EleutherAI) | Academic benchmarks | Backend for HF Open LLM Leaderboard, 60+ benchmarks |
| **HELM** (Stanford) | Holistic eval | Multi-dimensional assessment |
| **Braintrust** | Production platform | Scoring + tracing + datasets + CI enforcement |
| **Promptfoo** | Testing / red-teaming | YAML config, 30K+ devs, OWASP/NIST presets |
| **DeepEval** | RAG + LLM eval | pytest-compatible TDD, 15+ metrics |
| **Langfuse** | Observability + eval | Open-source, OpenTelemetry-based, 19K+ GitHub stars |

**Summary**: Promptfoo for red teaming, RAGAS for RAG evaluation, Langfuse for open-source observability, Braintrust for all-in-one convenience.

### LLM-as-Judge Best Practices

1. **Write your own rubrics** — use yes/no questions, break down complex criteria
2. **Use CoT reasoning** — add "Evaluation" field before final score
3. **Small integer scales** — 1-4 or 1-5, not large float scales
4. **Build validation set** — minimum 30-50 human-labeled examples, production-ready 100-200
5. **Multi-agent debate** — achieves higher human alignment (Spearman rho up to 0.47)
6. **Integrate into CI** — changes degrading eval metrics require justification
7. **LLM-as-judge is not infallible** — valid for detecting degradations when smoothed over time

### Key Benchmarks (April 2026)

| Benchmark | What It Measures | Current Leaders |
|-----------|-----------------|----------------|
| **SWE-bench Verified** | Real-world code fixing | DeepSeek V4 (81%), Claude Opus 4.6 (80.8%) |
| **MMLU / MMLU-Pro** | Broad knowledge | Kimi K2.5 (92%) |
| **HumanEval** | Code generation | Kimi K2.5 (99%) |
| **Chatbot Arena** | Human preference (Elo) | GLM-5 (1451 Elo) |
| **AIME 2025** | Math competition | Ministral 14B reasoning (85%) |
| **GPQA Diamond** | PhD-level science | Frontier models ~60-75% |

### Production Evaluation & Observability

| Tool | Type | Key Differentiator |
|------|------|-------------------|
| **Langfuse** | Open-source observability | Self-hosted, MIT, OpenTelemetry-based, 19K+ stars |
| **LangSmith** | LangChain-native | Visual graphs, annotation queues, native LangChain |
| **Helicone** | Lightweight gateway | One-line setup (URL swap), 100+ provider routing |
| **Braintrust** | All-in-one platform | Scoring + tracing + datasets + CI |

**Common production pattern**: Helicone as gateway for cost tracking/routing + Langfuse for deeper tracing/evaluation.

---

## 7. Agents & Tool Use

### Agent Frameworks (April 2026)

| Framework | Orchestration | Maturity | Key Differentiator |
|-----------|--------------|----------|-------------------|
| **LangGraph** | Directed graph + conditional edges | Production (47M+ PyPI downloads) | Checkpointing with time travel, 87% task success |
| **CrewAI** | Role-based crews | Production | Fastest-growing multi-agent, 82% task success |
| **AutoGen/AG2** | Conversational GroupChat | Production (v0.4 rewrite) | Event-driven, async-first, pluggable orchestration |
| **Claude Agent SDK** | Tool-use chains + sub-agents | Growing | Sub-agents, Anthropic-backed |
| **OpenAI Agents SDK** | Native tool chains | Newest | Lowest barrier, tightest OpenAI integration |
| **Google ADK** | Hierarchical agent tree | Growing | Root agent delegates to sub-agents |

### Agent Patterns

| Pattern | How It Works | Task Completion | Best For |
|---------|-------------|----------------|----------|
| **ReAct** | Think → Act → Observe → Repeat | Good | General-purpose, simple agents |
| **Plan-and-Execute** | Full plan → execute → replan on failure | 92%, 3.6x speedup | Complex multi-step tasks |
| **Agents-as-Tools** | Specialist agents wrapped as callable functions | High | Modular, composable architectures |
| **Reflection** | Agent evaluates own output, iterates | Improved | Quality-critical reasoning |
| **Multi-Agent Debate** | Multiple agents debate candidate outputs | Highest alignment | Evaluation, complex decisions |

### MCP (Model Context Protocol)

MCP is the emerging standard for agent-tool interaction:
- Standardizes tools, resources, and prompts across providers
- 97M installs, 10,000+ public servers
- OpenAI deprecated Assistants API in favor of MCP
- Donated to Linux Foundation under AAIF (co-founded by Anthropic, Block, OpenAI)
- **Build on MCP now** — it's the convergence point for the industry

### Tool Use Best Practices

1. **Keep tool schemas minimal** — each tool definition consumes tokens
2. **Use `strict: true`** for guaranteed schema compliance
3. **Validate tool arguments** with Pydantic/Zod before execution
4. **Handle all errors**: malformed arguments, missing functions, timeouts, infinite loops
5. **Implement circuit breakers** for external tool calls
6. **Log every tool call** for debugging and audit trails
7. **Test tool selection**: verify the model picks the right tool for each scenario

---

## 8. LLM Security & Safety

### Threat Landscape

**OWASP Top 10 for LLMs (v2.0):**
- LLM01: **Prompt Injection** — #1 most exploited, especially indirect injection via retrieved content
- LLM02: Sensitive Information Disclosure
- LLM03: Supply Chain Vulnerabilities
- LLM04: Data and Model Poisoning
- LLM05: Improper Output Handling

**OWASP Top 10 for Agentic Applications (2026):**
New framework covering: goal misalignment, tool misuse, delegated trust, inter-agent communication, persistent memory, emergent autonomous behavior.

### Guardrails Frameworks

| Framework | Type | Key Feature |
|-----------|------|-------------|
| **NVIDIA NeMo Guardrails** (v0.20) | Open-source | Colang DSL for conversational flows, input/output rails |
| **Guardrails AI** | Open-source | Validator Hub, re-prompting, provider-agnostic |
| **Promptfoo** | Red-teaming | OWASP/NIST presets, 40+ vulnerability types |
| **DeepTeam** (Confident AI) | Red-teaming | 40+ vulnerability types, 10+ attack methods |

**NeMo Guardrails (v0.20):**
- Input rails: jailbreak detection, prompt injection filtering, content moderation, intent classification
- Output rails: self-checking, fact-checking, hallucination detection
- **Colang**: Domain-specific language for defining conversational safety constraints
- Integrations with NVIDIA safety models and third-party APIs

### Defense-in-Depth Strategy

```
1. Input Validation     → NeMo Guardrails / Guardrails AI
2. Content Filtering    → Moderation APIs, content classifiers
3. Output Validation    → Schema validation, fact-checking, hallucination detection
4. Rate Limiting        → Per-user, per-endpoint quotas
5. Monitoring & Alerts  → Anomaly detection on inputs/outputs
6. Regular Red Teaming  → Continuous, not periodic (minimum: per deployment change)
```

### Red Teaming Best Practices

- Use **Promptfoo** or **DeepTeam** for automated vulnerability scanning
- Test prompt injection (direct + indirect), jailbreaking, data exfiltration
- Agent-specific testing: reconnaissance, attack planning, tool misuse
- **Testing cadence**: Targeted per deployment change, comprehensive quarterly
- Document findings and mitigations in a security report

---

## 9. Cost Optimization

### Token Optimization

| Strategy | Cost Reduction | How |
|----------|---------------|-----|
| **Prompt compression** (LLMLingua) | Up to 20x | Compress prompts while preserving quality — especially effective for RAG |
| **Strategic optimization** | 60-80% | Minimize tool definitions, compress context, use efficient formats |
| **Shorter system prompts** | 10-30% | Remove redundant instructions, use references instead of inline content |

### Caching

**Provider-Level Prefix Caching:**

| Provider | Mechanism | Savings | Notes |
|----------|-----------|---------|-------|
| **Anthropic** | 5-min cache (1.25x write), 1-hour (2x write), reads at 0.1x | 90% cost, 85% latency | Workspace-level isolation |
| **OpenAI** | Automatic for prompts ≥ 1,024 tokens | 50% cost | No code changes needed |

**Application-Level Semantic Caching:**
- Redis LangCache: ~73% cost reduction in high-repetition workloads
- Stores query vector embeddings + LLM responses
- Cache hits return in milliseconds vs seconds
- **When to use**: Customer support, FAQ-heavy, repetitive queries

### Model Routing

Route queries by complexity to optimize cost:
- **Simple queries** (classification, extraction) → Small/cheap models (Haiku, GPT-4o-mini, Ministral 3B)
- **Medium queries** (summarization, analysis) → Mid-tier models (Sonnet, GPT-4o)
- **Complex queries** (deep reasoning, long context) → Frontier models (Opus, GPT-5.4 Thinking)
- Combined routing + caching + batching: **47-80% cost reduction** without UX degradation

### Batching

**Continuous Batching** (standard in 2026 production):
- Each sequence finishes independently and is immediately replaced
- vLLM achieves up to 23x throughput improvement with PagedAttention
- Frameworks: vLLM, SGLang, TensorRT-LLM, LMDeploy, HuggingFace TGI

**API Batch Processing:**
- Anthropic Message Batches API: discounted pricing for non-real-time workloads
- OpenAI Batch API: similar discounted processing
- **When to use**: Bulk processing, evaluation runs, data enrichment — anything not user-facing

### Enterprise LLM Gateways

Use a gateway for unified multi-provider access:
- **Helicone**: Lightweight, one-line setup, routing + failover across 100+ providers
- **LiteLLM**: Open-source, OpenAI-compatible proxy for 100+ LLM providers
- **Portkey**: Enterprise gateway with caching, routing, guardrails

---

## 10. Decision Frameworks

### Model Selection

| Decision | Default | Switch When |
|----------|---------|-------------|
| Frontier API | Claude Sonnet 4.6 | Max quality needed (Opus), cheapest frontier (Gemini 2.5 Pro) |
| Budget API | DeepSeek V4 | Need full open-source (Mistral Large 3) |
| Self-hosted LLM | Llama 4 Maverick | Multilingual (Qwen3.5), reasoning (DeepSeek R1) |
| Small/edge | Qwen3.5-2B | iOS (Apple models), specific hw (Ministral) |
| Embeddings (proprietary) | OpenAI text-embedding-3-large | Budget (3-small), multimodal (Cohere v4) |
| Embeddings (open) | BGE-M3 | Hybrid dense+sparse in single model |

### RAG vs Fine-Tuning vs Prompting

| Approach | Best For | Cost | Time to Deploy |
|----------|----------|------|---------------|
| **Prompt engineering** | Most tasks, quick iteration | Lowest | Hours |
| **RAG** | External/dynamic knowledge | Medium | Days-weeks |
| **Fine-tuning** | Consistent style/behavior | Highest | Weeks |
| **RAG + fine-tuning** | Knowledge + behavior | Highest | Weeks-months |

### Vector Database Selection

| Scenario | Recommended |
|----------|-------------|
| Prototype / small scale | Chroma |
| Already using Postgres | pgvector |
| Managed, zero-ops | Pinecone |
| Self-hosted, max performance | Qdrant |
| Distributed, billion-scale | Milvus / Zilliz |
| Built-in ML integration | Weaviate |

### Agent Framework Selection

| Scenario | Recommended |
|----------|-------------|
| General-purpose, production | LangGraph |
| Multi-agent with roles | CrewAI |
| Claude-native | Claude Agent SDK |
| OpenAI-native | OpenAI Agents SDK |
| Google/Gemini-native | Google ADK |
| Conversational multi-agent | AutoGen/AG2 |
