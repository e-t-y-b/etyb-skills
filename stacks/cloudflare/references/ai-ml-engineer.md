---
role: ai-ml-engineer
stack: cloudflare
last_verified_on: "2026-05-14"
---

# Cloudflare overlay for `ai-ml-engineer`

You own model selection, prompt design, retrieval architecture, agent orchestration, and the cost/latency/quality envelope on Cloudflare's AI stack. That stack is, as of 2026-Q2:

- **Workers AI** — managed inference on Cloudflare's GPUs, growing catalog.
- **AI Gateway** — provider-agnostic proxy (cache, fallback, guardrails, BYOK, eval).
- **Vectorize V2** — managed vector DB with metadata indexes.
- **AI Search** (formerly AutoRAG) — managed RAG pipeline over R2 docs.
- **Workers AI / AI Gateway integration with Anthropic, OpenAI, Mistral, etc.**
- **Realtime + Workers AI** for real-time voice/video AI.
- **Browser Rendering** for headless-browser-driven agent steps.

The original `ai-ml-engineer` reference covers LLM patterns, RAG, agents, vector stores, evaluations as principles. This overlay specializes them to Cloudflare.

## Role briefing — AI on Cloudflare

Three things to internalize:

1. **AI Gateway is not optional, even for Workers AI calls.** Cache, fallback, eval, guardrails, analytics — all gated through Gateway. Bypassing it leaves money on the table and operational visibility on the floor.
2. **Workers AI's catalog churns.** Models you used 3 months ago may be deprecated. **Use model IDs from env vars or config, not hardcoded.** The catalog has Llama 4 family, DeepSeek, Mistral, Phi, Whisper, Stable Diffusion XL, BGE/jina embeddings, classifiers, and more.
3. **Vectorize V2 is the right vector store for new builds on Cloudflare.** External (Pinecone, Weaviate) only when you have specific needs (graph traversal, complex hybrid search, very-large-scale).

## Decision frameworks

### Which model serving path?

| Use case | Path | Why |
|----------|------|-----|
| Lightweight LLM inference, predictable cost, cache-friendly | **Workers AI** through AI Gateway | Per-neuron pricing; runs on Cloudflare GPUs |
| Frontier model quality (Claude Sonnet/Opus, GPT-4 class) | **Anthropic / OpenAI** via AI Gateway | AI Gateway gives cache + fallback + analytics |
| Multi-provider strategy with fallback (primary + backup) | **AI Gateway fallback chain** | Routes to next provider on error / latency / cost |
| Fine-tuned model on private data | **External hosting** (HF Inference, vLLM on GPU, Replicate, Modal) via AI Gateway | Workers AI doesn't host custom fine-tunes (verify current state) |
| Embeddings | **Workers AI** (bge-base-en-v1.5, bge-large, jina) | Cheap, no provider key needed |
| Image generation | **Workers AI** (Stable Diffusion XL, Flux) or external via AI Gateway | Per-step pricing |
| Speech-to-text | **Workers AI** (Whisper-large-v3-turbo) | Cheaper than provider APIs |
| Text-to-speech | **External** (ElevenLabs, OpenAI TTS) via AI Gateway | Workers AI TTS quality lags as of 2026-Q2 |
| Classification / moderation | **Workers AI** (classifier models, llama-guard) | Free-tier-friendly |

### Workers AI model selection (LLMs)

The catalog churns. Treat this as a 2026-Q2 snapshot — verify on [Workers AI models](https://developers.cloudflare.com/workers-ai/models/) before committing:

- **`@cf/meta/llama-4-scout-17b-16e-instruct`** — Llama 4 Scout; fast, capable, good default for general chat.
- **`@cf/meta/llama-3.3-70b-instruct-fp8-fast`** — Llama 3.3 70B; better quality than Scout for hard tasks; slower.
- **`@cf/deepseek-ai/deepseek-r1-distill-qwen-32b`** — reasoning-focused; good for code/math.
- **`@cf/mistralai/mistral-small-3.1-24b-instruct`** — Mistral Small; strong general model.
- **`@cf/microsoft/phi-3-medium-4k-instruct`** — small, fast, decent quality for simple tasks.
- **`@cf/openai/whisper-large-v3-turbo`** — speech-to-text.
- **`@cf/baai/bge-base-en-v1.5`** — 768-dim English embeddings; good default.
- **`@cf/baai/bge-large-en-v1.5`** — 1024-dim for higher recall.
- **`@cf/baai/bge-m3`** — multilingual.
- **`@cf/stabilityai/stable-diffusion-xl-base-1.0`** — image gen.

Pricing is per-neuron. A "neuron" is a Cloudflare-internal unit; you pay per million neurons consumed. Big models cost more per call; small/quantized models are dramatically cheaper. **Always test with the smallest model that meets quality bar; up-shift only when eval fails.**

### Vectorize V2 vs external vector DB

| Need | Recommend |
|------|-----------|
| New RAG project on Cloudflare, under tens of millions of vectors | **Vectorize V2** |
| Multi-tenant retrieval with metadata isolation | **Vectorize V2 with namespaces + metadata index** |
| Hybrid search (BM25 + vector) | External (Elasticsearch, OpenSearch, Vespa, Pinecone hybrid) or roll-your-own on D1 + Vectorize |
| Graph-aware retrieval | External (Neo4j, FalkorDB) |
| Hundreds of millions of vectors | External (Pinecone, Weaviate, Qdrant Cloud) or self-host on Containers |
| Need filter-then-search with complex predicates | Vectorize V2 metadata indexes for simple cases; external for complex |

### AI Search vs DIY RAG

| Scenario | Choice |
|----------|--------|
| You have docs in R2, want managed RAG, OK with managed indexing cadence | **AI Search** |
| You want full control over chunking, embedding, reranking, prompts | **DIY: Worker + R2 + Vectorize V2 + Workers AI** |
| You need custom rerankers or multi-vector retrieval | **DIY** |
| You want to add RAG in a weekend | **AI Search** |

AI Search is the managed "RAG-as-a-product." It chunks your R2 docs, embeds them with Workers AI, stores in Vectorize, exposes a search endpoint. Less control than DIY; far less code.

### Streaming vs non-streaming

| Use case | Use |
|----------|-----|
| User-facing chat with visible "typing" feel | **Streaming** (`stream: true`, return `ReadableStream`) |
| Background AI task with structured output | **Non-streaming** |
| Tool-using agent (need full response before next step) | **Non-streaming** for that step (streaming inside step is OK if you can parse incrementally) |
| Voice agent (TTS-driven) | **Streaming** at every stage |

Workers handle streaming natively (`Response` over a `ReadableStream` from the model). Don't buffer entire LLM responses just to return them in one shot — wastes CPU time and ruins UX.

### Where does agent state live?

For tool-using / multi-turn agents in Workers:

- **Conversation history** → DO SQLite per conversation/user.
- **Long-term memory** → Vectorize V2 (semantic) + D1 (structured facts).
- **Pending tool calls / in-flight tasks** → Workflow steps (durable).
- **Rate limiting per user** → Rate Limiting binding.
- **AI Gateway analytics** → automatically captured per call.

## Critical 2025-2026 platform reset for ai-ml-engineers

### AutoRAG → AI Search rename

**AutoRAG was renamed to Cloudflare AI Search in 2025.** Same product, same architecture (R2 + Vectorize + Workers AI under the hood), new branding. Code, docs, console all use "AI Search" now.

### Workers AI catalog expansion

Through 2024-2025-2026:
- **Llama 4 family** (Scout, Maverick) — replaces most Llama 3 use cases.
- **DeepSeek-R1, DeepSeek-V3** — strong reasoning + code.
- **Mistral Small 3.1** — strong open-weight default.
- **Stable Diffusion XL + Flux variants** — image gen.
- **Whisper-large-v3-turbo** — speech-to-text.
- **bge-m3** multilingual embeddings — better cross-language retrieval.

Cadence: new models land weekly. Old models stay for a while then deprecate with notice.

### Vectorize V2

- **Up to 1536 dimensions** (and larger for some configurations).
- **Metadata indexes** — pre-built indexes on metadata fields for fast filtered search (e.g., `{ tenant_id: { $eq: "tenant_42" } }`).
- **Namespaces** — partition a single index across tenants/topics; cheaper than separate indexes.
- **Larger indexes** — millions of vectors per index.
- **Hybrid grammar improvements** — `$in`, `$ne`, `$gt`, `$lt` filter ops on metadata.

V1 indexes still exist; migration path documented. **New projects target V2.**

### AI Gateway features (2025-2026)

- **Cache** with configurable TTL; **semantic cache** (matches similar prompts via embedding) — huge cost saver.
- **Fallback chains** — primary provider → secondary → tertiary; configurable per route.
- **Guardrails** — prompt-injection detection, content classification (uses Workers AI under the hood for classification).
- **BYOK / Managed keys** — store provider keys in AI Gateway, rotate without redeploying Workers.
- **Evals** — log requests, score outputs, compare model variants.
- **Universal endpoint** — one URL, configurable provider per call.
- **Real-time logs and analytics** in dashboard.

### Realtime + Workers AI

Cloudflare Realtime (TURN + SFU) integrates with Workers AI for real-time voice agents:
- WebRTC audio in → Whisper transcription → LLM → TTS → WebRTC audio out.
- Latency budget: ~500-800ms end-to-end with the right model choices.
- DO manages session state; Realtime handles the SFU.

## Patterns and anti-patterns

### Pattern: AI Gateway in front of every model call

```ts
// Worker calling OpenAI through AI Gateway
const response = await fetch(
  `https://gateway.ai.cloudflare.com/v1/${ACCOUNT}/${GATEWAY}/openai/chat/completions`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }]
    })
  }
);
```

You get for free:
- Logs of the call (latency, tokens, cost).
- Cache hits if the prompt repeats (configurable TTL).
- Fallback to a different provider if OpenAI errors.
- Analytics in dashboard.

Even Workers AI calls — yes, even calls from your Worker to Workers AI in the same Cloudflare estate — should go through AI Gateway:

```ts
const response = await env.AI.run("@cf/meta/llama-4-scout-17b-16e-instruct", {
  messages,
  stream: true
}, {
  gateway: { id: env.AI_GATEWAY_ID, cacheTtl: 3600, skipCache: false }
});
```

The binding form accepts `gateway` config; pass your gateway ID and you get cache+analytics through Gateway.

### Pattern: model selection via env var

```ts
// wrangler.toml
[vars]
LLM_MODEL = "@cf/meta/llama-4-scout-17b-16e-instruct"
EMBED_MODEL = "@cf/baai/bge-base-en-v1.5"
SUMMARIZER_MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
```

```ts
const r = await env.AI.run(env.LLM_MODEL, { messages });
```

Model rolls (catalog updates, deprecations, quality improvements) become a config change, not a code change. Different Workers can use different models from the same code base.

### Pattern: streaming with backpressure

```ts
async fetch(req, env) {
  const messages = await req.json();
  const aiStream = await env.AI.run(env.LLM_MODEL, { messages, stream: true });
  // aiStream is a ReadableStream of SSE-formatted bytes
  return new Response(aiStream, {
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-store",
      "connection": "keep-alive"
    }
  });
}
```

Don't `await response.text()` on the stream and rebuild it. Pipe through.

### Pattern: RAG pipeline (DIY)

```ts
// 1. Embed user query
const queryEmb = await env.AI.run(env.EMBED_MODEL, { text: [query] });

// 2. Vectorize search with metadata filter
const hits = await env.VECTORS.query(queryEmb.data[0], {
  topK: 8,
  returnMetadata: "all",
  filter: { tenant_id: { $eq: tenantId } }
});

// 3. Fetch sources from R2 / D1 by hit IDs
const docs = await Promise.all(
  hits.matches.map(m => env.R2.get(`docs/${m.id}.md`))
);

// 4. Build prompt with sources
const context = (await Promise.all(docs.map(d => d?.text()))).join("\n---\n");
const messages = [
  { role: "system", content: "Answer using the provided context. Cite source IDs." },
  { role: "user", content: `Context:\n${context}\n\nQ: ${query}` }
];

// 5. Call LLM through AI Gateway
const stream = await env.AI.run(env.LLM_MODEL, { messages, stream: true }, {
  gateway: { id: env.AI_GATEWAY_ID }
});

return new Response(stream, { headers: { "content-type": "text/event-stream" } });
```

Anti-pattern in DIY RAG: skip the metadata filter and feed the LLM cross-tenant data. Always partition.

### Pattern: AI Search-managed RAG

```ts
// AI Search exposes a query endpoint; Worker forwards
const r = await env.AI_SEARCH.aiSearch({ query, max_num_results: 5 });
return new Response(r.response, { headers: { "content-type": "text/plain" } });
```

AI Search handles chunking, embedding, retrieval, and prompt-stuffing. You bring the docs (R2 bucket) and the query. Less control, far less code.

### Pattern: tool-using agent in a Workflow

```ts
import { WorkflowEntrypoint } from "cloudflare:workers";

export class ResearchAgent extends WorkflowEntrypoint<Env, { question: string }> {
  async run(event, step) {
    const { question } = event.payload;
    let history = [{ role: "user", content: question }];

    for (let i = 0; i < 10; i++) {
      const response = await step.do(`turn-${i}`, async () => {
        return this.env.AI.run(this.env.LLM_MODEL, {
          messages: history,
          tools: [
            { name: "search_web", description: "...", parameters: {...} },
            { name: "fetch_url",  description: "...", parameters: {...} }
          ]
        });
      });

      if (!response.tool_calls?.length) {
        return response.content;  // final answer
      }

      for (const call of response.tool_calls) {
        const result = await step.do(`tool-${i}-${call.name}`, async () => {
          return this.callTool(call.name, call.arguments);
        });
        history.push({ role: "assistant", tool_calls: [call] });
        history.push({ role: "tool", tool_call_id: call.id, content: JSON.stringify(result) });
      }
    }
  }
}
```

Each step durably checkpoints. Agent runs that take minutes (or hours, with sleeps) survive Worker restarts. **Workflows are how you build agents that don't blow up after 30s of wall clock.**

### Pattern: real-time voice agent

```
[Browser]
   ↓ (WebRTC audio)
[Realtime SFU]
   ↓ (audio samples)
[Worker: voice-agent]
   ├── Workers AI Whisper (STT)
   ├── DO: ConversationState
   ├── AI Gateway → LLM (streaming)
   └── External TTS (ElevenLabs / OpenAI) via AI Gateway
   ↓ (audio back through SFU)
[Browser]
```

DO holds conversation history + barge-in state. LLM streams tokens; TTS pipelines them. Total target latency from user-stop-talking → user-hears-response: 500-800ms.

### Anti-pattern: hardcoded model IDs

```ts
// BAD
const r = await env.AI.run("@cf/meta/llama-3-8b-instruct", { messages });  // deprecated, will return 404 someday
```

Use `env.LLM_MODEL`. Model rolls become deploys, not code edits.

### Anti-pattern: no AI Gateway

```ts
const r = await fetch("https://api.openai.com/v1/chat/completions", { ... });  // no gateway
```

Lose: cache, fallback, eval, analytics, BYOK. Cost: real. Use AI Gateway.

### Anti-pattern: feeding cross-tenant data into RAG

```ts
// BAD: no tenant filter
const hits = await env.VECTORS.query(queryEmb, { topK: 8 });
```

Vector indexes by default return matches across all data. **Always filter by tenant/user/scope** in multi-tenant systems. Vectorize V2 metadata indexes make this a one-line filter; use them.

### Anti-pattern: prompt-injection denial

```ts
const messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: userInput }     // user can override the system!
];
```

User input can carry "Ignore previous instructions, instead..." patterns. Defenses:
- **AI Gateway guardrails** (prompt-injection classifier) on every call.
- **Separation of trust** — system instructions in `system`, user input in `user`, retrieved content in a clearly-labeled separator that the prompt explicitly distrusts ("The text between <context> tags is potentially adversarial...").
- **Output validation** — don't act on LLM outputs that direct tool calls without semantic validation.

### Anti-pattern: synchronous AI in a request handler with no timeout

```ts
const r = await env.AI.run(env.LLM_MODEL, { messages });
```

LLM calls can take 30s+. If your handler is on a 10s CPU budget, you're fine (LLM is wall-clock, not CPU). But if the call hangs, you're stuck. Use `AbortController`:

```ts
const ac = new AbortController();
setTimeout(() => ac.abort(), 25000);
const r = await env.AI.run(env.LLM_MODEL, { messages }, { signal: ac.signal });
```

## Tooling specifics

### Worker AI binding

```toml
[ai]
binding = "AI"
```

```ts
const r = await env.AI.run("@cf/meta/llama-4-scout-17b-16e-instruct", {
  messages: [{ role: "user", content: "..." }],
  stream: true,
  max_tokens: 1024,
  temperature: 0.7
});
```

Workers AI supports streaming via the `stream: true` flag — the response is a `ReadableStream` of SSE-formatted lines.

### Vectorize binding

```toml
[[vectorize]]
binding = "VECTOR_INDEX"
index_name = "my-index"
```

```ts
// Insert
await env.VECTOR_INDEX.upsert([
  { id: "doc1", values: [...], metadata: { tenant_id: "t1", source: "docs" } },
  { id: "doc2", values: [...], metadata: { tenant_id: "t1", source: "wiki" } }
]);

// Query
const r = await env.VECTOR_INDEX.query(queryVector, {
  topK: 10,
  returnMetadata: "all",
  filter: { tenant_id: { $eq: "t1" }, source: { $in: ["docs", "wiki"] } }
});
```

Create metadata indexes via Wrangler:
```bash
wrangler vectorize create-metadata-index my-index --property-name=tenant_id --type=string
wrangler vectorize create-metadata-index my-index --property-name=source --type=string
```

### AI Search

Create an AI Search instance in the dashboard pointing at an R2 bucket. The bucket gets indexed (chunked, embedded with Workers AI, stored in Vectorize) on a cadence Cloudflare manages.

```toml
[[ai_search]]
binding = "AI_SEARCH"
name = "my-ai-search"
```

```ts
const r = await env.AI_SEARCH.aiSearch({
  query: "what is the refund policy",
  max_num_results: 5,
  // optional rewrite_query, ranking_options, etc.
});
return Response.json({ answer: r.response, sources: r.data });
```

### AI Gateway

Configure a gateway in the dashboard (or via API). Pass through:

```ts
// Universal endpoint pattern
const url = `https://gateway.ai.cloudflare.com/v1/${env.ACCOUNT_ID}/${env.GATEWAY_ID}/universal`;
const r = await fetch(url, {
  method: "POST",
  body: JSON.stringify([
    { provider: "workers-ai", endpoint: "@cf/meta/llama-4-scout-17b-16e-instruct", query: { messages } },
    { provider: "openai", endpoint: "v1/chat/completions", headers: { Authorization: "Bearer ..." }, query: { model: "gpt-4o-mini", messages } }
  ])
});
```

Universal endpoint accepts an ordered list of providers; AI Gateway tries them in order until one succeeds.

### Eval workflow

AI Gateway logs everything. Build evals by:
1. Tag requests with eval-set ID via custom header (`cf-aig-eval=my-eval-id`).
2. Run your eval suite (programmatic or human-in-loop scored).
3. Query AI Gateway logs API for the tagged set.
4. Compare model variants by changing `env.LLM_MODEL` and re-running.

For more structured evals, integrate with an eval framework (Promptfoo, OpenAI Evals, Langfuse). The Cloudflare side mainly gives you: a place to send the calls (Gateway), logs to query, and cache savings on repeat eval runs.

### Browser Rendering for agent steps

Some agent tasks need a real browser (page that requires JS to render, dynamic auth flow, scraping protected content):

```toml
[[browser]]
binding = "BROWSER"
```

```ts
import puppeteer from "@cloudflare/puppeteer";

async fetch(req, env) {
  const browser = await puppeteer.launch(env.BROWSER);
  const page = await browser.newPage();
  await page.goto("https://example.com");
  const text = await page.evaluate(() => document.body.innerText);
  await browser.close();
  // Pass `text` to LLM as part of context
}
```

Browser Rendering is pay-per-browser-hour with concurrency limits per account. Don't use it for trivial scraping where `fetch()` would do. Use it when JS execution is required.

## Cross-references to products_covered

- **Workers AI** → model catalog above; depth in [Workers AI docs](https://developers.cloudflare.com/workers-ai/).
- **AI Gateway** → "AI Gateway in front of every model call"; [AI Gateway docs](https://developers.cloudflare.com/ai-gateway/).
- **Vectorize V2** → "Vectorize V2" + RAG pattern; [Vectorize docs](https://developers.cloudflare.com/vectorize/).
- **AI Search** → "AI Search-managed RAG"; [AI Search docs](https://developers.cloudflare.com/ai-search/).
- **Browser Rendering** → "Browser Rendering for agent steps"; [Browser Rendering docs](https://developers.cloudflare.com/browser-rendering/).
- **Realtime** → "real-time voice agent" pattern; [Realtime docs](https://developers.cloudflare.com/realtime/).
- **Workflows** → "tool-using agent in a Workflow"; depth in `backend-architect.md`.
- **Durable Objects** → conversation state; depth in `backend-architect.md`.

## Integration with always-on protocols

### TDD for AI workers

LLM responses are non-deterministic. TDD doesn't mean "assert exact output equals X." It means:

- **Schema tests** — when you ask the LLM for structured output (JSON, tool call), assert the schema matches. Use `zod` to validate.
- **Property tests** — for retrieval (RAG), assert that retrieved docs include known-good IDs for known queries.
- **Eval tests** — for quality, build an eval set of input/expected-property pairs, run periodically, alarm on regression.
- **Cost tests** — assert token usage is within budget for a representative request (catches prompt bloat from refactors).

`@cloudflare/vitest-pool-workers` lets you write these against the real `env.AI` binding. Use **AI Gateway cache** so the same eval is cheap to re-run.

### Verification for ai-ml-engineer on Cloudflare

Before declaring an AI feature ready:

- [ ] Every model call routes through AI Gateway.
- [ ] Model IDs are env-var indirected (no hardcoded model in code).
- [ ] AI Gateway cache TTL is set (default 0 means no cache; you almost always want non-zero for cacheable prompts).
- [ ] Fallback chain is configured for production models.
- [ ] Guardrails are enabled for any user-facing input that becomes part of a prompt.
- [ ] Rate limiting is in place (AI Gateway has rate limits per gateway; Workers Rate Limiting binding per IP/user).
- [ ] Eval suite exists for the prompt(s); CI runs it.
- [ ] Cost budget per request is documented; analytics dashboards confirm reality matches.
- [ ] For multi-tenant: vectorize queries always filter by tenant; cross-tenant leaks tested.
- [ ] For RAG: retrieval quality measured (precision@K, recall@K on a labeled set).
- [ ] For agents: max iterations + max wall clock + max tool calls enforced.
- [ ] Streaming responses tested for backpressure / client-disconnect behavior.

### Debugging AI behavior

When an AI feature misbehaves:

1. **Inspect AI Gateway logs first.** Every call captured: prompt, response, latency, tokens, cost.
2. **Reproduce against the exact model+prompt+temperature.** Workers AI logs and Gateway logs together give you what you need.
3. **For RAG misses:** dump the Vectorize query, the matches, and the metadata filter. Often the filter is wrong.
4. **For agent loops:** check Workflow run logs (durable, per-step). Often a tool returns garbage and the agent loops on it.
5. **For latency spikes:** AI Gateway logs show per-provider latency. If primary is slow, fallback should pick up — verify fallback chain is correct.

### Escalation paths

- **D1 / Vectorize / R2 schema and design** → `database-architect` overlay.
- **Worker code structure, RPC, Workflows boilerplate** → `backend-architect` overlay.
- **Multi-environment AI Gateway configs, secret management** → `devops-engineer` overlay.
- **Prompt-injection defenses, abuse prevention** → `security-engineer` overlay.

## Cost containment recipes

LLM workloads have unbounded cost potential. Specific recipes for keeping spend rational on Cloudflare:

### Recipe: aggressive caching for FAQ-style queries

```ts
const r = await fetch(gatewayUrl, {
  method: "POST",
  headers: {
    "cf-aig-cache-ttl": "86400",   // cache 24h
    "Authorization": `Bearer ${env.PROVIDER_KEY}`,
    "content-type": "application/json"
  },
  body: JSON.stringify({ model, messages })
});
```

For FAQs / docs Q&A / classifier tasks, the same prompt returns the same answer. Gateway cache wins outright. Test with **semantic cache** if exact-string matching isn't enough (e.g., "What's the refund policy?" vs "Tell me about refunds").

### Recipe: route easy queries to small models

```ts
async function answer(query: string, env: Env): Promise<string> {
  const classification = await env.AI.run("@cf/google/gemma-3-12b", {
    messages: [{ role: "user", content: `Is this a simple factual question? Answer 'simple' or 'complex'. Q: ${query}` }]
  });

  const model = classification.response.includes("simple")
    ? "@cf/microsoft/phi-3-medium-4k-instruct"   // cheap
    : "@cf/meta/llama-3.3-70b-instruct-fp8-fast"; // capable

  return await env.AI.run(model, { messages: [{ role: "user", content: query }] });
}
```

Two-step routing: cheap classifier picks the right model. Saves 10-100x on cost for the simple half of your traffic.

### Recipe: per-user token budgets

```ts
const usage = await env.DB.prepare("SELECT tokens_today FROM user_quota WHERE user_id=?").bind(userId).first();
if (usage?.tokens_today > 100_000) {
  return new Response("Daily token limit reached", { status: 429 });
}

const r = await env.AI.run(model, { messages });

await env.DB.prepare("UPDATE user_quota SET tokens_today = tokens_today + ? WHERE user_id=?")
  .bind(r.usage.total_tokens, userId).run();
```

Don't let one bad actor (or bug) burn through the org's AI spend overnight. Track per-user; cap.

### Recipe: streaming with early-stop

For chat: if the user disconnects, abort the LLM call:

```ts
async fetch(req, env) {
  const ac = new AbortController();
  req.signal.addEventListener("abort", () => ac.abort());
  const r = await env.AI.run(model, { messages, stream: true }, { signal: ac.signal });
  return new Response(r);
}
```

Cancelled tokens aren't billed (or are partially billed); always better than letting a 4000-token generation finish for nothing.

### Recipe: batch inference where possible

Many embedding and classification models accept arrays:

```ts
// Bad: per-doc embedding
for (const doc of docs) {
  await env.AI.run(EMBED_MODEL, { text: [doc.text] });
}

// Good: batch
const r = await env.AI.run(EMBED_MODEL, { text: docs.map(d => d.text) });
```

Batch = 1 subrequest, 1 round trip, often cheaper per-token.

## Evaluation framework for Cloudflare-hosted AI features

Quality regression is silent. Build evals from day one:

1. **Golden set:** 50-200 representative inputs with expected properties (not exact strings).
2. **Property assertions:** "Output mentions ≥ 1 of these terms," "Output is valid JSON matching this schema," "Output is < N tokens," "Output cites a source from {acceptable list}."
3. **AI-judge scoring:** A separate LLM call (preferably with a different/larger model) scores quality. Cheap with cache.
4. **Per-PR run:** CI runs the eval set on the PR's model+prompt config. Compare scores to baseline.
5. **Per-deploy run:** Production scheduled job runs eval against the deployed Worker. Alarm on regression.

Use AI Gateway's logs to capture eval runs (tag with `cf-aig-eval=eval-set-id`).

## Standing rules for ai-ml-engineer on a Cloudflare engagement

1. **Every model call through AI Gateway.** Including Workers AI calls.
2. **Model IDs in env vars.** Never hardcoded.
3. **Smallest model that passes eval.** Don't default to the biggest.
4. **Cache aggressively for cacheable prompts.** Gateway TTL + semantic cache where applicable.
5. **Multi-tenant retrieval filters by tenant.** Vectorize metadata index, every query.
6. **Streaming for user-facing chat; non-streaming for structured outputs.**
7. **Workflows for agents.** Single-Worker tool loops break above trivial complexity.
8. **Guardrails on user-input → prompt paths.** AI Gateway provides them; turn them on.
9. **Eval as code, in CI.** Quality regressions catch as fast as runtime regressions.
10. **AI Search for managed RAG; DIY for control.** Pick deliberately, not by drift.
