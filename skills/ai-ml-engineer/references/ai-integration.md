# AI Product Integration — Deep Reference

**Always use `WebSearch` to verify version numbers, tooling, and best practices. AI integration patterns evolve rapidly. Last verified: April 2026.**

## Table of Contents
1. [API Design for AI Features](#1-api-design-for-ai-features)
2. [Latency Optimization](#2-latency-optimization)
3. [Fallback & Reliability](#3-fallback--reliability)
4. [Cost Management](#4-cost-management)
5. [AI UX Patterns](#5-ai-ux-patterns)
6. [Embedding AI into Products](#6-embedding-ai-into-products)
7. [Observability for AI](#7-observability-for-ai)
8. [Compliance & Privacy](#8-compliance--privacy)
9. [SDK & Client Libraries](#9-sdk--client-libraries)
10. [Decision Frameworks](#10-decision-frameworks)

---

## 1. API Design for AI Features

### Streaming Responses (SSE)

Server-Sent Events (SSE) is the de facto standard for LLM streaming in 2026, used natively by OpenAI, Anthropic, Google, and most LLM APIs.

**Why SSE wins over WebSockets for LLM streaming:**
- Unidirectional (server → client) — matches the LLM response pattern
- No handshake complexity
- Works through most proxies and load balancers
- Auto-reconnects on connection loss
- Standard HTTP — no special infrastructure

**User experience impact:** A 500-token response takes ~5 seconds to generate. Without streaming: 5 seconds of blank screen. With streaming: first token appears in ~200ms, text flows naturally. Same total time, dramatically better perceived performance.

**Production architecture:**
```
Request → Auth middleware → Rate limiter (token quota check) 
→ Queue (if GPU busy) → Inference engine (vLLM/SGLang) 
→ SSE stream back to client
```

### Async/Webhook Patterns

For non-interactive tasks (image generation, video, batch processing):

**Webhook pattern:**
1. Client sends POST /generate with a `callback_url`
2. Server returns `202 Accepted` with `job_id`
3. Background worker processes the task
4. Worker POSTs results to the `callback_url` on completion
5. Include retry-with-backoff for callback failures

**Queue-based pattern:**
1. Submit request to persistent queue (RabbitMQ, Redis, SQS)
2. Poll status endpoint or receive webhook notification
3. Retrieve results when ready

**When to use which:**
- **SSE streaming**: Interactive chat, real-time generation, user is watching
- **Async/webhook**: Image/video generation, batch processing, long-running tasks (>30s)
- **Queue-based**: High-volume batch processing, multiple consumers

### Rate Limiting for AI

Traditional request-based rate limiting breaks with LLM traffic — two requests can differ by orders of magnitude in resource consumption.

**Token-based rate limiting (now essential):**
- Allow N tokens/hour instead of N requests/minute
- Track three categories: prompt tokens (input), completion tokens (output), total tokens
- Combine short-term limits (tokens/minute) with long-term quotas (tokens/month)

**API Gateway support:**
| Gateway | Token Rate Limiting |
|---------|-------------------|
| Azure API Management | Token limit policies per consumer |
| Envoy AI Gateway | Token-based via Global Rate Limit API |
| Apache APISIX | `ai-rate-limiting` plugin |
| Kong AI Gateway | Token quota management |

**Response headers for AI APIs:**
```
X-RateLimit-Tokens-Remaining: 45000
X-RateLimit-Tokens-Reset: 1718284800
X-RateLimit-Requests-Remaining: 95
Retry-After: 30
```

---

## 2. Latency Optimization

### Model Selection for Latency Budgets

| Latency Budget | Model Tier | Examples |
|---------------|-----------|----------|
| <500ms TTFT | Small/fast models | Claude Haiku ($0.25/$1.25), GPT-4o-mini |
| 500ms-2s TTFT | Mid-tier | Claude Sonnet 4.6 ($3/$15), GPT-4o ($2.50/$10) |
| 2-5s TTFT | Frontier | Claude Opus 4.6 ($5/$25), GPT-5.4 Thinking |
| >5s acceptable | Batch/async | Any model via batch API (50% discount) |

**Cache economics:** With cache hits, Sonnet 4.6 drops to $0.30/MTok input (90% off) — cheaper than most mid-tier models. Architect for cacheability.

### Inference Optimization Stack

The full optimization stack on H100 delivers 5-8x better cost-efficiency than naive deployment:

| Technique | Speedup | What It Does |
|-----------|---------|-------------|
| **Speculative decoding** | 2-3x | Predict + verify multiple tokens simultaneously. Built into vLLM, SGLang, TensorRT-LLM |
| **FP8 quantization** | 1.5-2x | Reduce precision with minimal quality loss (H100/H200) |
| **Flash Attention 3** | 2-4x (memory) | Fused attention kernels, reduces memory footprint |
| **Continuous batching** | 5-23x throughput | Dynamic request scheduling, no padding waste |
| **KV caching** | Variable | Avoid recomputing attention for past tokens |

**EAGLE-3 (advanced speculative decoding):** Lightweight autoregressive prediction head attached to target model's internal layers — eliminates separate draft model entirely.

**Quantization caution:** Combining quantized draft + target models for speculative decoding generally worsens performance (speedup falls below 1x). Use quantization OR speculative decoding, not both on the same model pair.

### Serving Engine Selection

| Engine | Best For | Key Innovation |
|--------|----------|---------------|
| **vLLM** (v0.19) | Default production serving | PagedAttention, broadest model support |
| **SGLang** | Shared-context workloads (RAG, chat) | RadixAttention, 29% throughput over vLLM |
| **TensorRT-LLM** | Max throughput on NVIDIA | CUDA graph optimization, requires 28-min compilation |

### Edge Inference

| Runtime | Platform | Best For |
|---------|----------|----------|
| **ONNX Runtime** | Cross-platform | Train in PyTorch → deploy anywhere via ONNX |
| **TensorFlow Lite** | Android, embedded | GPU/NNAPI delegates, widest mobile deployment |
| **Core ML** | Apple platforms | Neural Engine, Apple Silicon optimization |

**ONNX Runtime** is the best cross-platform choice: train in PyTorch, convert to ONNX, deploy on any device.

---

## 3. Fallback & Reliability

### Multi-Model Fallback Chains

Reliability must be a system property, not an API property. A well-designed system orchestrating multiple providers can achieve 99%+ effective uptime even when the primary API has a 45% peak failure rate.

**Fallback chain pattern:**
```
1. Try primary model (Claude Sonnet 4.6)
   ↓ timeout/error/rate-limit
2. Try secondary model (GPT-4o)
   ↓ timeout/error/rate-limit
3. Try tertiary model (Gemini 2.5 Pro)
   ↓ all models unavailable
4. Graceful degradation (cached response, simpler logic, human escalation)
```

### Circuit Breakers for AI

Classic three states: **Closed** (normal) → **Open** (failures detected, stop trying) → **Half-Open** (testing recovery).

**Agentic AI extension (2026):** Classic circuit breakers assume binary failure. AI services need:
- **DEGRADED state** for partial capability (model works but quality dropped)
- **Graduated re-enablement** with multiple probe samples
- Detection for five failure categories including **semantic failures** (hallucinations with 200 status codes)

### Layered Resilience Pattern

```
Layer 1: Exponential backoff for transient errors (429, 503)
Layer 2: Circuit breakers for persistent failures
Layer 3: Fallback models for provider unavailability
Layer 4: Graceful degradation (cached responses, simpler logic)
Layer 5: Human escalation for unrecoverable errors
```

### Timeout Handling

- Set per-request timeouts based on expected model latency
- Streaming endpoints get longer timeouts than non-streaming
- Implement request-level deadlines that propagate through the call chain
- Separate timeout policies for prompt processing vs token generation
- For agents: set total workflow timeouts, not just per-step timeouts

### Error Handling Patterns

| Error Type | Response | Recovery |
|-----------|----------|----------|
| Rate limit (429) | Exponential backoff | Retry with jitter, respect Retry-After header |
| Server error (500/503) | Immediate retry once | Fall back to secondary model |
| Timeout | Cancel and retry | Fall back to faster/smaller model |
| Invalid response | Log and retry | Retry with stricter prompt, fall back |
| Content filter | Return safe response | Don't retry, adjust prompt or use different model |
| Hallucination detected | Flag for review | Use RAG for grounding, add fact-checking step |

---

## 4. Cost Management

### Token-Based Cost Tracking

LLM APIs return token counts in every response. Track:
- **Input tokens** (prompt + context)
- **Output tokens** (completion)
- **Cached tokens** (reduced-cost input tokens)
- **Total cost** per request, per user, per feature

**Tools for cost tracking:**
| Tool | Type | Key Feature |
|------|------|-------------|
| **Helicone** | Gateway | One-line setup, automatic cost tracking across providers |
| **Langfuse** | Open-source | Self-hosted, detailed per-trace cost breakdown |
| **Bifrost** | Enterprise gateway | 11μs overhead, four-tier spend hierarchies, budget enforcement |
| **Portkey** | Gateway | Observability + guardrails + cost tracking |

### Model Routing

A task routed to a frontier reasoning model costs **190x more** than the same task on a fast smaller model. Intelligent routing delivers **85% cost reduction** while maintaining 95% of GPT-4 performance.

**Routing strategies:**

| Strategy | How It Works | Best For |
|----------|-------------|----------|
| **Cascading** | Try smallest model first, escalate until quality threshold met | Maximum cost savings |
| **Intent-based** | Classify query intent, route to appropriate model | Predictable costs per feature |
| **Semantic** | Classify by query embedding similarity | Complex routing rules |
| **Cost-aware** | Optimize within budget constraints | Budget enforcement |
| **Load-balanced** | Distribute across providers/keys | Rate limit management |

**Tools:** RouteLLM (open-source, LMSYS/UC Berkeley), Portkey, LiteLLM, Bifrost.

### Caching Strategies

**Semantic caching:**
- Convert queries to vector embeddings (768-1,536 dims)
- Measure cosine similarity against cached queries
- Return cached response when similarity > threshold (0.85-0.95)
- ~31% of LLM queries exhibit semantic similarity
- Redis LangCache achieves ~73% cost reduction in high-repetition workloads

**Exact-match caching:**
- Hash the full prompt (system + user message)
- Fast O(1) lookup
- Works for deterministic queries (classification, extraction)

**Provider-level prefix caching:**
- Anthropic: 5-min cache at 1.25x write, reads at 0.1x (90% savings)
- OpenAI: Automatic for prompts ≥ 1,024 tokens (50% savings)
- Design prompts with shared prefixes to maximize cache hits

### Batch vs Real-Time

| Mode | Pricing | Latency | Use Case |
|------|---------|---------|----------|
| Real-time | Full price | Seconds | User-facing, interactive |
| Batch | ~50% discount | Minutes-hours | Content generation, evaluation, bulk classification |

Batch pricing: GPT-4.1 $1/$4 (vs $2/$8 real-time), Sonnet 4.6 $1.50/$7.50 (vs $3/$15 real-time).

---

## 5. AI UX Patterns

### Streaming UI

Streaming is the baseline expectation — a response that waits until completion before rendering feels broken.

**Challenges and solutions:**
| Challenge | Solution |
|-----------|----------|
| Incomplete markdown | Buffer until complete before rendering |
| Partial code blocks | Defer rendering until closing fence, or show "streaming" indicator |
| Loading states | Skeleton screens (3-5 lines of grey shimmer at decreasing widths) not spinners |
| Cursor/typing indicator | Show blinking cursor at end of streaming text |

### Feedback Collection

**Tiered approach (increasing friction):**
1. **Low-friction**: Thumbs up/down on every response — always visible, zero extra clicks
2. **Categorized**: On thumbs-down, expand categories: "Inaccurate", "Not relevant", "Incomplete", "Harmful"
3. **Deep feedback**: Optional text field for detailed corrections

**Using feedback:** Log all feedback with the full prompt + response + model version. Use negative feedback to identify failure patterns. Feed corrections back into evaluation datasets.

### Confidence & Uncertainty

LLMs are notoriously poorly calibrated. Production approaches:

| Method | How It Works | Cost |
|--------|-------------|------|
| **Self-reported confidence** | Ask the model to output a confidence score | Low (one extra prompt field) |
| **Temperature scaling** | Adjust overconfident predictions with a single parameter | Post-hoc, no inference cost |
| **Isotonic regression** | Fit monotonic function for non-linear recalibration | Requires calibration dataset |
| **Multiple samples** | Generate N responses, measure agreement | Nx inference cost |

**Communicating uncertainty to users:**
- Use verbal indicators ("I'm fairly confident" vs "I'm not sure about this")
- Show source citations when available (RAG)
- Highlight when the model is extrapolating beyond its training data
- Never show raw probability numbers to non-technical users

### Human-in-the-Loop Patterns

| Pattern | When to Use |
|---------|-------------|
| **Pre-action approval** | Irreversible actions (sending emails, database writes, purchases) |
| **Post-action review** | High-volume reversible actions (content moderation, classification) |
| **Confidence-based routing** | Low confidence → human, high confidence → auto |
| **Timeout + fallback** | When humans don't respond within SLA |

**State management:** Approval reviews can take minutes to days. Use checkpointing (LangGraph persists to PostgreSQL/Redis/SQLite) so the workflow resumes from the exact state when approval is granted.

### Generative UI

Agents influence the interface at runtime — the UI changes as context changes. CopilotKit is a leading framework for generative UI in 2026. The agent decides what UI to show and what inputs to collect, moving beyond static chat interfaces.

---

## 6. Embedding AI into Products

### AI-Powered Search

**Architecture:**
```
1. Index: Documents → Chunking → Embeddings → Vector DB
2. Query: User query → Embedding → Vector search + BM25 (hybrid)
3. Rerank: Top-100 candidates → Reranker → Top-5-10
4. Generate: Context + query → LLM → Answer with citations
```

**Vector database selection:** See `llm-specialist.md` for detailed comparison. Quick guide:
- Already on Postgres → pgvector
- Managed, zero-ops → Pinecone
- Self-hosted, max performance → Qdrant
- Billion-scale → Milvus/Zilliz

### Recommendation System Integration

2026 pattern: LLMs enhance recommendation layers by understanding intent from queries, reviews, chat, and support tickets.

**Embedding-based approach:**
- Encode user interactions as vector embeddings
- Similar items cluster in embedding space
- Cosine similarity enables real-time recommendation
- Combine with two-tower models for candidate generation + ranking

See `data-scientist.md` for detailed recommender system architecture.

### Content Generation Pipelines

Multi-model workflows are standard in 2026:
- Text generation → LLM (Claude, GPT)
- Image generation → Diffusion models (DALL-E, Midjourney, Stable Diffusion)
- Video generation → Sora, Runway, Kling
- Audio/speech → ElevenLabs, Cartesia Sonic

Teams automating image/video workflows produce 10-15 variations in the time one used to take.

### Voice/Speech Integration

| Task | Tool | Performance |
|------|------|------------|
| **Speech-to-Text** | Whisper Large v3 Turbo | 5-6% WER, human-level on clear audio |
| **Speech-to-Text (real-time)** | AssemblyAI Universal-3 Pro | ~150ms P50 latency, 99.95% uptime SLA |
| **Text-to-Speech** | Cartesia Sonic 3 | Sub-200ms latency, streaming support |
| **Text-to-Speech (natural)** | ElevenLabs Turbo v3 | Most natural-sounding, 300-400ms latency |

---

## 7. Observability for AI

### LLM Observability Platforms

| Platform | Type | Best For |
|----------|------|----------|
| **Langfuse** | Open-source (MIT) | Self-hosted, privacy-conscious, tracing + prompt management |
| **LangSmith** | Commercial | LangChain/LangGraph ecosystem, auto-instrumentation |
| **Helicone** | Gateway-based | Vanilla API calls, cost tracking, one-line setup |
| **Braintrust** | Commercial | Evaluation automation, CI/CD blocking on quality degradation |
| **Arize Phoenix** | Open-source | LlamaIndex users, tracing + evaluation |

**Common production pattern:** Helicone as gateway (cost tracking, routing, failover) + Langfuse for deeper tracing and evaluation.

### OpenTelemetry for AI

OpenTelemetry is the CNCF standard for LLM observability:
- Auto-instrumentation for OpenAI, Anthropic, LangChain, LlamaIndex
- LLM calls wrapped in spans with standardized `gen_ai` attributes (model, tokens, finish reason)
- Store prompts as **span events** (not attributes) — events can be filtered at Collector level
- Overhead: <1ms per call (LLM latency of 100ms-30s dominates entirely)
- **OpenLLMetry** (by Traceloop): open-source observability for GenAI based on OpenTelemetry

### A/B Testing AI Features

| Requirement | Why It Matters |
|-------------|---------------|
| **Sticky sessions** | Users must stay on same variant (switching fractures conversational context) |
| **Prompt versioning** | Version prompts but load dynamically; avoid hardcoding |
| **Statistical rigor** | Account for stochastic nature of LLM outputs in power analysis |
| **Dual metrics** | Track performance (latency, cost, tokens) AND quality (eval scores, satisfaction) |

**Tool support:** Langfuse (A/B testing via prompt management), Braintrust (CI/CD blocks on quality degradation), Dynatrace (model versioning + A/B testing).

### User Feedback Loops

```
1. Collect: Thumbs up/down, corrections, ratings on every AI interaction
2. Store: Log feedback with full context (prompt, response, model, timestamp)
3. Analyze: Identify failure patterns, cluster negative feedback
4. Evaluate: Build evaluation datasets from real user feedback
5. Improve: Use feedback to update prompts, fine-tune, or adjust RAG retrieval
6. Measure: Track quality improvement over time via eval metrics
```

---

## 8. Compliance & Privacy

### PII Handling

**Microsoft Presidio** — most widely deployed open-source PII solution:
- NER + regex + checksum validation
- 2026 recommendation: use Presidio with **GLiNER** as NER backend for better accuracy
- Recent additions: MedicalNERRecognizer, GPU acceleration (4-10x speedup), batch processing, ONNX Runtime support
- Pattern: Presidio for batch processing, AI functions for edge cases, or AI for custom entity recognition + Presidio for redaction

### EU AI Act (2026)

**Critical timelines:**
- First binding requirements already active
- **August 2026**: High-risk AI system obligations take effect

**Key obligations for deployers:**
- Human oversight for high-risk AI systems
- Data governance compliance
- Logging retention (10-year rule for technical documentation/metadata)
- GDPR compliance in addition to AI Act (complementary, not alternative)
- Systematic inventory of all AI systems in production (>50% of orgs lack this)

**PII in training data:** Must be deleted when training purpose ends. Technical documentation and system logs (containing no personal data) follow the 10-year retention rule.

### Model Cards & Documentation

Required during audits, documenting:
- Architecture and intended use
- Performance metrics and limitations
- Risks and known failure modes
- Training data characteristics
- Fairness and bias evaluation results

### Bias Detection & Fairness Monitoring

**Continuous monitoring** (not just pre-deployment):
- Models passing fairness audits can develop **bias drift** in production
- Monitor **disparate impact ratios** (compare outcomes for protected groups vs baseline)
- Ratio below 0.8 signals problematic bias requiring investigation
- **Fiddler AI** leads production bias monitoring

See `ml-engineer.md` for Fairlearn, AI Fairness 360, and fairness metric details.

---

## 9. SDK & Client Libraries

### Anthropic SDK

**Python SDK** (v0.79+):
- Sync/async clients
- Built-in streaming: `client.messages.stream()` for SSE-based token streaming
- Tool use with `@beta_tool` decorator and `tool_runner`
- Retries with exponential backoff
- Bedrock and Vertex AI compatibility

**Claude Agent SDK** (`claude-agent-sdk-python`):
- Tool-use chains with sub-agents
- Safety built into architecture through constitutional AI principles
- Production toolkit for building autonomous agents

### OpenAI SDK

**Responses API (2026):** Replaces deprecated Assistants API (sunset August 26, 2026):
- Agentic loop: model calls multiple tools in one request
- Built-in tools: web_search, image_generation, file_search, code_interpreter
- Remote MCP server support
- Structured outputs via `text.format` with `strict: true`

**Agents SDK (March 2025):**
- Explicit handoffs between agents
- Guardrails for validation
- Built-in tracing (enabled by default)

### Vercel AI SDK (v6.0)

Released December 2025:
- Unified API for 25+ AI providers (change two lines to switch)
- 67.5 kB gzipped, edge runtime support
- `useChat` hook for streaming chat interfaces
- `useObject` hook for streaming partial JSON with typed reactive objects
- AI RSC (React Server Components) for streaming AI-generated UI
- ToolLoopAgent for agentic tool calling
- Human-in-the-loop tool approval
- DevTools for debugging

### LangChain vs Direct SDK (2026 Reality)

| Approach | When to Use | Tradeoff |
|----------|-------------|---------|
| **Direct SDK** (Anthropic/OpenAI) | Simple completions, latency-sensitive, minimal abstraction | Lowest overhead, most control |
| **Vercel AI SDK** | Web apps with streaming chat, React/Next.js | Best DX for web, multi-provider |
| **LangChain/LangGraph** | Complex agents, state machines, multi-step workflows | Powerful but high complexity |
| **Portkey/LiteLLM** | Multi-provider routing without framework lock-in | Gateway approach, thin abstraction |

**2026 reality:** The gap LangChain filled in 2022 is substantially closed. Many teams report framework overhead has crossed the value threshold. Use LangGraph specifically for complex state-machine agents; use direct SDKs for everything else.

### AI Gateway Solutions

| Gateway | Overhead | Best For |
|---------|----------|----------|
| **Helicone** | Low | Vanilla API calls, cost tracking, one-line setup |
| **Bifrost** | 11μs | Enterprise governance, budget enforcement |
| **Portkey** | Low | Observability + guardrails + prompt management |
| **LiteLLM** | Moderate | Self-hosted, OpenAI-compatible proxy, 100+ LLMs |
| **OpenRouter** | N/A (hosted) | Zero-setup multi-model access |

### Building Abstractions That Don't Leak

1. **Wrap provider SDKs** behind your own interface — swap providers without changing app code
2. **Standardize on OpenAI-compatible APIs** — most gateways support this
3. **Don't abstract away streaming** — expose SSE at every layer
4. **Keep prompt templates in version-controlled config**, not code
5. **Use gateway-level concerns** (retries, fallbacks, caching, rate limiting) not application code
6. **Log raw provider responses** alongside abstracted representations for debugging

---

## 10. Decision Frameworks

### API Pattern Selection

| Scenario | Pattern |
|----------|---------|
| Interactive chat/generation | SSE streaming |
| Long-running generation (>30s) | Async with webhook/polling |
| Batch processing | Queue-based with batch API pricing |
| Real-time search | Sync with timeout + fallback |

### Reliability Strategy

| Traffic Volume | Strategy |
|---------------|---------|
| Low (<100 req/min) | Single provider + basic retries |
| Medium (100-1K req/min) | Primary + fallback provider, circuit breakers |
| High (>1K req/min) | Multi-provider routing, semantic caching, load balancing |
| Mission-critical | All of the above + human escalation + monitoring |

### Cost Optimization Priority

1. **Cache** first (90% savings on cache hits with Anthropic prefix caching)
2. **Route** to cheapest capable model (85% savings with intelligent routing)
3. **Batch** non-interactive work (50% savings)
4. **Optimize** prompts (reduce token count)
5. **Negotiate** volume pricing with providers

### SDK/Framework Selection

| Stack | Recommendation |
|-------|---------------|
| React/Next.js web app | Vercel AI SDK |
| Python backend, simple | Direct Anthropic/OpenAI SDK |
| Complex agent workflows | LangGraph |
| Multi-provider needs | Portkey or LiteLLM gateway |
| Enterprise governance | Bifrost gateway |
