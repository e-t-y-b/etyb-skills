---
title: Workers AI
description: Cloudflare's managed model inference — Llama 4 family, DeepSeek-R1, Mistral, Whisper, Stable Diffusion XL, BGE embeddings; per-neuron pricing; running on Cloudflare GPUs.
product:
  name: Workers AI
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://developers.cloudflare.com/workers-ai/
  notes: "Model catalog churns weekly — Llama 4 family, DeepSeek, Mistral, Whisper, Stable Diffusion; pricing per-neuron model still current 2026."
---

## What it is

Workers AI is Cloudflare's managed model inference — LLMs, embeddings, speech-to-text, image generation, classifiers. Exposed via the `AI` binding (`env.AI.run(model, params)`). Models run on Cloudflare's GPUs at the edge. Per-neuron pricing; many models have free-tier inclusions.

Authoritative reference: [developers.cloudflare.com/workers-ai](https://developers.cloudflare.com/workers-ai/).

## When to use

- **Lightweight LLM inference** with predictable cost and cache-friendly prompts.
- **Embeddings** — `bge-base`, `bge-large`, `bge-m3` multilingual.
- **Image generation** — Stable Diffusion XL, Flux variants.
- **Speech-to-text** — Whisper-large-v3-turbo.
- **Classification / moderation** — classifier models, llama-guard.

Don't use Workers AI when:

- **Frontier model quality (Claude Sonnet/Opus, GPT-4 class)** — go to Anthropic/OpenAI via [AI Gateway](/stacks/cloudflare/ai-gateway/).
- **Fine-tuned models on private data** — Workers AI doesn't host custom fine-tunes (verify current state); use external hosting (HF Inference, vLLM, Replicate, Modal) via AI Gateway.
- **Text-to-speech (quality bar)** — Workers AI TTS quality lags as of 2026-Q2; use ElevenLabs/OpenAI via AI Gateway.

**All Workers AI calls should still route through [AI Gateway](/stacks/cloudflare/ai-gateway/)** for cache, fallback, eval, analytics.

## 2025-2026 currency anchors

- **Catalog churns weekly.** Models you used 3 months ago may be deprecated. Cadence: new models land weekly; old models stay for a while then deprecate with notice.
- **Llama 4 family** (Scout, Maverick) — replaces most Llama 3 use cases.
- **DeepSeek-R1, DeepSeek-V3** — strong reasoning + code.
- **Mistral Small 3.1** — strong open-weight default.
- **Stable Diffusion XL + Flux variants** — image gen.
- **Whisper-large-v3-turbo** — speech-to-text.
- **bge-m3 multilingual** — better cross-language retrieval.
- **Per-neuron pricing model** — pay per million neurons consumed. Big models cost more per call; small/quantized models are dramatically cheaper.

## Model catalog snapshot (2026-Q2)

Treat as a snapshot — verify against [Workers AI models](https://developers.cloudflare.com/workers-ai/models/) before committing:

- `@cf/meta/llama-4-scout-17b-16e-instruct` — Llama 4 Scout; good default for general chat.
- `@cf/meta/llama-3.3-70b-instruct-fp8-fast` — better quality for hard tasks; slower.
- `@cf/deepseek-ai/deepseek-r1-distill-qwen-32b` — reasoning-focused; good for code/math.
- `@cf/mistralai/mistral-small-3.1-24b-instruct` — strong general model.
- `@cf/microsoft/phi-3-medium-4k-instruct` — small, fast, decent for simple tasks.
- `@cf/openai/whisper-large-v3-turbo` — speech-to-text.
- `@cf/baai/bge-base-en-v1.5` — 768-dim English embeddings; good default.
- `@cf/baai/bge-large-en-v1.5` — 1024-dim for higher recall.
- `@cf/baai/bge-m3` — multilingual.
- `@cf/stabilityai/stable-diffusion-xl-base-1.0` — image gen.

## Patterns

### LLM inference with streaming

```ts
const r = await env.AI.run("@cf/meta/llama-4-scout-17b-16e-instruct", {
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "..." }
  ],
  stream: true
}, {
  gateway: { id: env.AI_GATEWAY_ID }
});
return new Response(r, { headers: { "content-type": "text/event-stream" } });
```

Workers AI supports streaming via `stream: true`. The response is a `ReadableStream` of SSE-formatted lines.

### Model selection via env var

```toml
[vars]
LLM_MODEL = "@cf/meta/llama-4-scout-17b-16e-instruct"
EMBED_MODEL = "@cf/baai/bge-base-en-v1.5"
SUMMARIZER_MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
```

```ts
const r = await env.AI.run(env.LLM_MODEL, { messages });
```

Model rolls (catalog updates, deprecations, quality improvements) become a config change, not a code change.

### Embeddings → Vectorize

```ts
const emb = await env.AI.run(env.EMBED_MODEL, { text: ["query text"] });
const hits = await env.VECTORS.query(emb.data[0], { topK: 5 });
```

Pair embeddings with [Vectorize](/stacks/cloudflare/vectorize/) for retrieval.

### Two-step routing — cheap classifier picks model

```ts
const classification = await env.AI.run("@cf/google/gemma-3-12b", {
  messages: [{ role: "user", content: `Is this a simple factual question? Answer 'simple' or 'complex'. Q: ${query}` }]
});

const model = classification.response.includes("simple")
  ? "@cf/microsoft/phi-3-medium-4k-instruct"   // cheap
  : "@cf/meta/llama-3.3-70b-instruct-fp8-fast"; // capable

return await env.AI.run(model, { messages: [{ role: "user", content: query }] });
```

Saves 10-100x on cost for the simple half of your traffic.

### Batch embedding

```ts
// Bad: per-doc
for (const doc of docs) {
  await env.AI.run(EMBED_MODEL, { text: [doc.text] });
}

// Good: batch
const r = await env.AI.run(EMBED_MODEL, { text: docs.map(d => d.text) });
```

One subrequest, cheaper per-token.

## Anti-patterns

- **Hardcoded model IDs** — catalog churns. Env-var indirected so deprecations become deploys, not code edits.
- **Skipping AI Gateway** — no cache, no fallback, no eval, no analytics.
- **Defaulting to the biggest model** — test with the smallest that passes eval; up-shift on regression.
- **Synchronous AI in a request handler with no AbortController timeout** — LLM hangs stall the handler.
- **Buffering streaming responses** to return in one shot — wastes CPU time, ruins UX.

## Gotchas

1. **CPU vs wall-clock** — LLM calls are wall-clock-bound, not CPU; you can wait for the model without burning your CPU budget. But hung calls still tie up the handler — use `AbortController`.
2. **Cost** — neuron pricing varies by model size. A 70B-class model is dramatically more expensive than a 4B model per token.
3. **Streaming returns SSE lines** — your client must parse SSE, not JSON.
4. **Model deprecations land with notice but happen.** Have a fallback model configured via env var.

## Cross-references

- [AI Gateway](/stacks/cloudflare/ai-gateway/) — every Workers AI call should route through Gateway
- [Vectorize](/stacks/cloudflare/vectorize/) — embeddings produced here, stored there
- [AI Search](/stacks/cloudflare/ai-search/) — uses Workers AI under the hood for managed RAG
- [Workers](/stacks/cloudflare/workers/) — runtime
- [Realtime](/stacks/cloudflare/realtime/) — Whisper + LLM + TTS for voice agents
- Role overlay: [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/workers-ai](https://developers.cloudflare.com/workers-ai/), [model catalog](https://developers.cloudflare.com/workers-ai/models/)
