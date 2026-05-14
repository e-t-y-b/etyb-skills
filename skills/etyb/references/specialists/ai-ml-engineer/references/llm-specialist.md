# LLM & Generative AI — Platform-Neutral Reference + Stack Pointers

This file used to be a 544-line single-specialist reference. As of v4.0.0 (2026-05-14), **vendor-specific LLM content has migrated to dedicated Stacks**; this file now carries the platform-neutral principles that apply across providers.

## Vendor-specific guidance lives in Stacks

| Vendor | Stack |
|---|---|
| Anthropic Claude — Messages API, Claude 4.x family, prompt caching, tool use, Agent SDK, MCP authoring, Claude Code | [`stacks/anthropic-claude/SKILL.md`](../../../../../../stacks/anthropic-claude/SKILL.md) and `stacks/anthropic-claude/references/ai-ml-engineer.md` |
| OpenAI — GPT-5 family, Responses API (replaces Assistants), o-series reasoning, Realtime API, Agents SDK, Structured Outputs, Computer Use | [`stacks/openai/SKILL.md`](../../../../../../stacks/openai/SKILL.md) and `stacks/openai/references/ai-ml-engineer.md` |
| AWS Bedrock — model catalog, AgentCore (Runtime/Browser/Memory), Strands Agents SDK, Bedrock Knowledge Bases, Trainium | [`stacks/aws/references/ai-ml-engineer.md`](../../../../../../stacks/aws/references/ai-ml-engineer.md) |
| GCP Vertex AI — Gemini 2.5 family, Vertex AI Agent Builder, Agentspace, TPU v7, Gemini Code Assist | [`stacks/gcp/references/ai-ml-engineer.md`](../../../../../../stacks/gcp/references/ai-ml-engineer.md) |
| Azure AI Foundry — Azure OpenAI deployment types, Foundry Agents, Entra Agent ID | [`stacks/azure/references/ai-ml-engineer.md`](../../../../../../stacks/azure/references/ai-ml-engineer.md) |
| Cloudflare Workers AI + AI Gateway + AI Search + Vectorize | [`stacks/cloudflare/references/ai-ml-engineer.md`](../../../../../../stacks/cloudflare/references/ai-ml-engineer.md) |
| Vercel AI Gateway + AI SDK + Chat SDK | [`stacks/vercel/references/ai-ml-engineer.md`](../../../../../../stacks/vercel/references/ai-ml-engineer.md) |
| Supabase pgvector + Edge Functions for AI | [`stacks/supabase/references/ai-ml-engineer.md`](../../../../../../stacks/supabase/references/ai-ml-engineer.md) |
| Firebase AI Logic + Genkit (JS/Python/Go/Dart) | [`stacks/firebase/references/ai-ml-engineer.md`](../../../../../../stacks/firebase/references/ai-ml-engineer.md) |

For ANY provider-specific question (model IDs, API surface, pricing, feature availability, SDK patterns), consult the relevant Stack. The Stack carries the `last_verified_on` timestamp and authoritative-source URLs needed to apply the drift-check protocol (`skills/etyb/core/knowledge-currency.md`).

## What stays in the platform-neutral surface

The AI/ML Engineer specialist still owns these principles, applicable across any LLM provider:

- **Model-selection framework** — when to use a small fast model vs a large reasoning model vs a multimodal model, independent of vendor
- **RAG architecture patterns** — retrieval, chunking strategies, hybrid search, re-ranking, evaluation. Choose your vector DB per stack; the pattern is universal
- **Agent design patterns** — single-agent vs multi-agent, planner/executor splits, handoffs, guardrails, tool design. Vendor SDKs (Claude Agent SDK, OpenAI Agents SDK, AWS Strands, Vertex Agent Builder) implement these differently but the patterns are vendor-neutral
- **Vector database selection matrix** — Pinecone, Weaviate, Qdrant, Chroma, pgvector, Vectorize, Vertex Vector Search, Azure AI Search, MongoDB Atlas Vector. Tradeoff dimensions: managed vs self-hosted, hybrid search support, metadata filtering performance, multi-region replication, cost-at-scale
- **Embeddings strategy** — dense vs sparse, dimensionality choice (Matryoshka representation), domain fine-tuning, multilingual, multimodal embeddings
- **Fine-tuning methods** — LoRA, QLoRA, DoRA, PEFT, full fine-tuning. When fine-tuning is worth it vs prompt engineering vs retrieval
- **Evaluation discipline** — golden datasets, LLM-as-judge, regression suites, A/B testing in prod, eval frameworks (LangSmith, Langfuse, Braintrust, OpenAI Evals, Anthropic console)
- **Prompt engineering principles** — system prompts, few-shot, chain-of-thought (built into reasoning models now), structured outputs, role prompting, self-consistency, prompt injection defenses
- **MCP (Model Context Protocol)** — the vendor-neutral standard for tool/resource exposition; covered in detail in `stacks/anthropic-claude/` since Anthropic authored it, but applies across all clients
- **OWASP LLM Top 10** — prompt injection (LLM01), insecure output handling (LLM02), training data poisoning (LLM03), model DoS (LLM04), supply chain (LLM05), sensitive info disclosure (LLM06), insecure plugin design (LLM07), excessive agency (LLM08), overreliance (LLM09), model theft (LLM10)
- **Cost optimization patterns vendor-agnostic** — caching, model routing (small first, large fallback), streaming for perceived latency, batch APIs where available, distillation patterns, prompt compression
- **Multi-provider gateways** — Helicone, Portkey, Bifrost, OpenRouter, Vercel AI Gateway. When a vendor-neutral gateway is worth it vs direct SDK calls

## How ETYB uses both layers

When a user asks an AI/ML question, ETYB's router consults `core/stack-registry.md` for vendor signals. If a specific vendor is named or implied, the corresponding Stack overlay loads alongside this specialist. If the question is vendor-agnostic ("what's the right RAG architecture for our docs?"), this specialist alone answers from the principles above. When the question crosses both (e.g., "should I use Claude or GPT-5 for this agent?"), ETYB loads multiple Stacks and presents the comparison through the principle frameworks here.
