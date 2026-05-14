# AI Product Integration — Platform-Neutral Patterns + Stack Pointers

This file used to be a 569-line single-specialist reference. As of v4.0.0 (2026-05-14), **vendor-specific SDK and integration content has migrated to Stacks**; this file retains the platform-neutral integration principles.

## Vendor-specific SDK + integration patterns live in Stacks

| Topic | Stack reference |
|---|---|
| Anthropic SDK (Python/TS), streaming, prompt-caching strategy, AnthropicBedrock + AnthropicVertex provider clients | `stacks/anthropic-claude/references/backend-architect.md` |
| OpenAI SDK, Responses API, Realtime API, Agents SDK with handoffs/guardrails/tracing, Batch API, streaming with `stream_options.include_usage` | `stacks/openai/references/backend-architect.md` and `stacks/openai/references/ai-ml-engineer.md` |
| Vercel AI SDK + AI Elements + AI Gateway routing + Chat SDK + Vercel Agent | `stacks/vercel/references/ai-ml-engineer.md` |
| Cloudflare AI Gateway + Workers AI + AI Search (formerly AutoRAG) + Vectorize | `stacks/cloudflare/references/ai-ml-engineer.md` |
| Firebase AI Logic (formerly Vertex AI in Firebase) + Genkit (JS/Python/Go/Dart) | `stacks/firebase/references/ai-ml-engineer.md` |
| AWS Bedrock SDK + AgentCore + Strands | `stacks/aws/references/ai-ml-engineer.md` |
| GCP Vertex AI SDK + Agent Builder + Gemini integration | `stacks/gcp/references/ai-ml-engineer.md` |
| Azure OpenAI SDK + AI Foundry + Foundry Agents | `stacks/azure/references/ai-ml-engineer.md` |
| LLM observability (Datadog LLM Observability, New Relic AI Monitoring, Langfuse, Helicone, Honeycomb AI) | `stacks/observability/references/sre-engineer.md` and `stacks/observability/references/backend-architect.md` (OTel GenAI semantic conventions) |

## What stays in the platform-neutral surface

The AI/ML Engineer specialist still owns these integration principles, applicable regardless of provider:

- **Request shape patterns** — synchronous request/response, streaming via SSE, WebSocket for bidirectional, webhooks for async batch completion, polling for long-running. Choose per use case, not per vendor
- **Reliability patterns** — circuit breakers, exponential backoff with jitter, retry budgets, deadline propagation, idempotency keys, partial-failure handling. Universal across LLM APIs
- **Fallback chains** — primary model → cheaper model → cached response → static fallback. Vendor-neutral logic; gateways implement it consistently
- **Rate limiting design** — token-bucket vs leaky-bucket, per-user vs per-org quotas, surge pricing, soft + hard limits. Pattern is universal; vendor SDKs expose different rate-limit headers
- **Cost-attribution architecture** — per-tenant, per-feature, per-user accounting. Track tokens at the edge before the LLM call so attribution survives streaming
- **Gateway-level concerns** — when to use Helicone / Bifrost / Portkey / Vercel AI Gateway / Cloudflare AI Gateway / OpenRouter. Tradeoffs: latency overhead, observability gains, multi-provider routing, caching, prompt management
- **A/B testing for LLM features** — feature flags + per-arm metrics, prompt-A vs prompt-B + model-A vs model-B factorial design, evaluator-LLM-as-judge for offline eval
- **Edge inference** — when to run small models at the edge (latency-critical, privacy-sensitive, offline-capable use cases) vs centralized large-model calls. Workers AI, Vercel Edge, Cloudflare AI fit here
- **Webhook + async patterns** — long-running batch jobs (OpenAI Batch API, Anthropic Batch, Vertex AI batch prediction) with webhook delivery vs polling vs Server-Sent Events for in-progress reporting
- **OpenTelemetry GenAI semantic conventions** — vendor-neutral instrumentation for spans (`gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, etc.); see `stacks/observability/` for vendor-side ingestion
- **EU AI Act compliance framing** — risk-tier classification (unacceptable, high, limited, minimal), GPAI provider obligations, transparency requirements, post-market monitoring. Compliance lives in the specialist; vendor-specific operator notes live in each Stack's `security-engineer.md` overlay
- **Sensitive-data scrubbing** — PII / PHI / PAN detection and redaction before the LLM call. Tool selection (Presidio, Datadog SDS, vendor-specific) lives in `stacks/observability/references/security-engineer.md`

## How ETYB uses both layers

For a question like "build me a customer-support chatbot," ETYB consults `core/stack-registry.md` for vendor signals (Claude? OpenAI? Vercel-hosted? Firebase-hosted?). When a specific vendor is in scope, the corresponding Stack overlay loads alongside this specialist; the Stack carries the integration specifics, this file carries the architecture principles. When the user is vendor-shopping, ETYB loads multiple Stacks and uses this file's frameworks to present the tradeoffs.
