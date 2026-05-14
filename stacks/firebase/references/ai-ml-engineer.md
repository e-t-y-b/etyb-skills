---
role: ai-ml-engineer
stack: firebase
last_verified_on: "2026-05-14"
---

# Firebase Overlay — ai-ml-engineer

You are ai-ml-engineer on a Firebase engagement. The Firebase AI surface in 2026 is two products: **Genkit** (the open-source AI framework you use to compose flows, tools, prompts, and RAG across JS/Python/Go/Dart) and **Firebase AI Logic** (the client-side SDK that talks to Gemini via Vertex AI or the Gemini Developer API, with App Check enforcement). Both have been renamed and reshaped in the last 24 months — anchor to current docs.

**Currency:** 2026 Q2. Genkit JS GA (1.x); Genkit Python, Go, Dart maturing through 2025-2026 (check current docs for status); Firebase AI Logic GA (rebrand of Vertex AI in Firebase from 2025); Gemini Nano on-device available via AI Logic where the platform supports it.

## What changed in 2025-2026 that older training data misses

- **Vertex AI in Firebase → Firebase AI Logic** (renamed 2025). SDK packages renamed (`@firebase/ai` replaces `@firebase/vertexai`). The product still calls Gemini via Vertex AI by default; the Gemini Developer API is the alternative backend.
- **Genkit JS GA** with `ai.defineFlow(...)` shape on a `Genkit` instance — the module-scope `defineFlow` patterns from early 2024 are out of date. Anchor any code samples to the current shape.
- **Genkit Python, Go, Dart** maturing — Python is the next most mature; Go and Dart vary by version. Match your runtime to Genkit support level.
- **Firestore vector search GA** (2024-2025) — Firebase has a first-class vector store for RAG, no need to reach for a separate vector DB at small to moderate scale.
- **Gemini Nano on-device** through AI Logic on supported devices — runs locally, no network, no per-call cost, no Gemini API key. Useful for "small prompt, low latency, privacy-sensitive."
- **App Check enforcement on AI Logic** — non-negotiable. A leaked client config without App Check = a free Gemini billing channel for the internet.
- **Genkit's eval harness** — Genkit ships a `genkit evaluate` workflow with golden datasets, replacing 2024-era "test by eyeballing the output."
- **Remote Config Server-Side + Firebase AI Logic** — server-side Remote Config can drive prompt variants, model selection, and feature flags without a client redeploy. The 2025 pattern for prompt iteration.

If you find yourself recommending Vertex AI in Firebase, `@firebase/vertexai`, module-scope `defineFlow`, or client-side Gemini calls without App Check — read on.

## Firebase AI Logic — the client-side Gemini surface

Firebase AI Logic lets your client (iOS, Android, Flutter, Web) call Gemini directly, with **App Check** enforcing that the call comes from your authentic app. The SDK abstracts:

- Auth (App Check token attached automatically)
- Backend selection (Vertex AI or Gemini Developer API)
- Streaming responses
- Function calling
- Multimodal inputs (text, images, audio, video)
- On-device Gemini Nano (where available)

### Why AI Logic exists

Without it, your options are:
1. **Direct Gemini API call from client** — requires a Gemini API key in the client, which is **immediate leakage**. Don't.
2. **Cloud Function proxy** — every Gemini call hops through your backend, adding latency, adding cost (function invocation + bandwidth), and shifting the cost surface to your project.

AI Logic gives you **direct client-to-Gemini latency** with **server-side authorization via App Check + Firebase Auth**, billed to your project. It's the right default for any client-driven Gemini call where the prompt doesn't depend on sensitive server-side data.

### Setup (Web Modular SDK)

```ts
import { initializeApp } from "firebase/app";
import { getAI, getGenerativeModel, VertexAIBackend } from "firebase/ai";
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from "firebase/app-check";

const app = initializeApp(firebaseConfig);

initializeAppCheck(app, {
  provider: new ReCaptchaEnterpriseProvider("RECAPTCHA_SITE_KEY"),
  isTokenAutoRefreshEnabled: true,
});

const ai = getAI(app, { backend: new VertexAIBackend() });
const model = getGenerativeModel(ai, { model: "gemini-2.5-flash" });

const result = await model.generateContent("Summarize this in 3 bullets: ...");
console.log(result.response.text());
```

### Setup (iOS Swift)

```swift
import FirebaseAI
import FirebaseAppCheck

// AppCheck setup before FirebaseApp.configure() — see security overlay
let ai = FirebaseAI.firebaseAI(backend: .vertexAI())
let model = ai.generativeModel(modelName: "gemini-2.5-flash")
let response = try await model.generateContent("Summarize this in 3 bullets: ...")
```

### Backend choice — Vertex AI vs Gemini Developer API

| | Vertex AI backend | Gemini Developer API backend |
|--|-------------------|------------------------------|
| **Billing** | Vertex AI pricing, on the GCP project | Gemini API pricing |
| **Data residency** | Per-region in GCP | Limited control |
| **Compliance** | GCP BAA-eligible | Limited |
| **Feature parity** | Closest to bleeding-edge for Vertex-side features | Sometimes ships faster for Gemini Developer features |
| **Free tier** | No (Vertex AI is paid) | Yes (with quotas) |

**Production rule:** use Vertex AI backend. Production apps need data residency, compliance posture, and the GCP billing footprint. Use Gemini Developer API only for prototyping or genuinely public-facing free-tier features.

### Streaming responses

```ts
const result = await model.generateContentStream("Tell me a story.");
for await (const chunk of result.stream) {
  process.stdout.write(chunk.text());
}
```

Stream for any user-facing response longer than ~50 tokens — the first-token latency is the perceived latency.

### Function calling

```ts
const model = getGenerativeModel(ai, {
  model: "gemini-2.5-pro",
  tools: [{
    functionDeclarations: [{
      name: "get_weather",
      description: "Returns weather for a city",
      parameters: {
        type: "OBJECT",
        properties: { city: { type: "STRING" } },
        required: ["city"],
      }
    }]
  }],
});

const result = await model.generateContent("What's the weather in Tokyo?");
const call = result.response.functionCalls()?.[0];
if (call?.name === "get_weather") {
  const weather = await getWeather(call.args.city);   // your function
  const followup = await model.generateContent([
    { role: "function", parts: [{ functionResponse: { name: "get_weather", response: weather } }] }
  ]);
}
```

**Client-side function calling** is risky — the model decides what functions to call, the client executes them. Anything sensitive (database writes, payments, etc.) should be **server-side** via a callable Cloud Function the client calls in response to the function call. The client should never directly execute "transfer money" because the model said so.

### Multimodal — images, audio, video

```ts
const result = await model.generateContent([
  { inlineData: { data: base64Image, mimeType: "image/png" } },
  "Describe what's in this image."
]);
```

Image inputs are inline base64 or Cloud Storage references. Video inputs (Gemini supports video) consume way more tokens than text — budget appropriately and use lower-resolution video where possible.

### On-device Gemini Nano via AI Logic

Where the platform supports it (newer Android devices with the AICore service; Apple Intelligence-capable devices for some flows), Firebase AI Logic can route to **Gemini Nano on-device**:

```ts
import { getAI, GoogleAIBackend, getGenerativeModel } from "firebase/ai";
// ... or platform-specific on-device provider config
```

Trade-offs:

| Trade | On-device | Cloud |
|-------|-----------|-------|
| **Latency** | Sub-100ms typical | 200-1000ms for first token |
| **Cost** | Free per call | Per-token billing |
| **Privacy** | Data never leaves device | Data hits Vertex AI / Gemini API |
| **Capability** | Smaller model (Nano); shorter context; less capable on complex reasoning | Full Pro/Flash; longer context; SOTA capability |
| **Availability** | Limited devices | Universal |

Use on-device for: classification, summarization, autocomplete suggestions, content safety pre-filter, voice-input correction. Use cloud for: complex reasoning, multi-step planning, RAG over a large corpus.

## Genkit — the AI flow framework

Genkit is Firebase's open-source AI orchestration framework. It runs anywhere (any Node / Python / Go / Dart server), but the natural deployment is **inside Cloud Functions for Firebase** — that's where Firebase publishes the strongest integration.

### Core primitives

- **Flow** — a named, typed function that orchestrates AI work. Inputs and outputs are validated (Zod in JS, Pydantic in Python, struct schemas in Go/Dart).
- **Tool** — a function the model can call. Typed inputs/outputs. Auto-exposed in the model's tool registry.
- **Prompt** — a versioned, templated prompt, definable inline or in `.prompt` files (Dotprompt format).
- **Embedder** — generates embeddings for vectors.
- **Retriever** — queries a vector store.
- **Indexer** — writes documents (with embeddings) to a vector store.
- **Model** — abstraction over LLM providers (Gemini, OpenAI, Anthropic, local, etc.).
- **Eval** — testing harness for flow outputs against golden datasets.

### Genkit JS — current API shape (2026)

```ts
import { genkit, z } from "genkit";
import { googleAI } from "@genkit-ai/googleai";

const ai = genkit({
  plugins: [googleAI()],
});

export const summarizeFlow = ai.defineFlow(
  {
    name: "summarizeFlow",
    inputSchema: z.object({ text: z.string() }),
    outputSchema: z.object({ summary: z.string() }),
  },
  async ({ text }) => {
    const { text: summary } = await ai.generate({
      model: googleAI.model("gemini-2.5-flash"),
      prompt: `Summarize in 3 sentences:\n\n${text}`,
    });
    return { summary };
  }
);
```

**Note**: `ai.defineFlow(...)` on a `Genkit` instance is the current shape. Pre-1.0 Genkit code used module-scope `defineFlow(...)`. If you see the latter, it's pre-GA code; modernize.

### Genkit Python — current shape

```python
from genkit.ai import Genkit
from genkit.plugins.google_genai import google_genai

ai = Genkit(plugins=[google_genai()])

@ai.flow()
async def summarize_flow(text: str) -> str:
    response = await ai.generate(
        model="googleai/gemini-2.5-flash",
        prompt=f"Summarize in 3 sentences:\n\n{text}",
    )
    return response.text
```

### Genkit Go and Dart

Go and Dart are catching up. As of 2026 Q2, Go is suitable for production server work; Dart is most useful for Flutter app integration (Genkit running in a Dart-based backend). Check the [Genkit docs](https://firebase.google.com/docs/genkit) for current GA status per language.

### Tools — typed function calling done right

```ts
export const getWeather = ai.defineTool(
  {
    name: "getWeather",
    description: "Get current weather for a city",
    inputSchema: z.object({ city: z.string() }),
    outputSchema: z.object({ tempC: z.number(), conditions: z.string() }),
  },
  async ({ city }) => {
    // ... real API call ...
    return { tempC: 21, conditions: "sunny" };
  }
);

export const weatherChatFlow = ai.defineFlow(
  { name: "weatherChat", inputSchema: z.object({ message: z.string() }), outputSchema: z.string() },
  async ({ message }) => {
    const result = await ai.generate({
      model: googleAI.model("gemini-2.5-pro"),
      prompt: message,
      tools: [getWeather],
    });
    return result.text;
  }
);
```

Genkit auto-handles the tool-call loop: model emits function call → Genkit invokes the tool with validated args → tool returns validated output → Genkit feeds it back to the model → model continues. Versus the manual loop you'd write with the raw Gemini API.

**Discipline**:

1. **Tools that mutate state, charge money, or access sensitive data should require explicit user confirmation** at the application layer. Don't trust the model alone.
2. **Tool inputs/outputs are typed** — Zod schemas (JS) or Pydantic (Python). The model's tool call gets validated against the input schema before your tool runs.
3. **Tools should be idempotent** where possible — retrying a tool call on a model retry shouldn't double-charge or duplicate.
4. **Tool descriptions are read by the model.** Write them like API docstrings — what it does, when to call it, what shape comes back. Vague descriptions = wrong tool calls.

### Prompts — Dotprompt format

```yaml
# prompts/summarize.prompt
---
model: googleai/gemini-2.5-flash
config:
  temperature: 0.3
input:
  schema:
    text: string
    tone?: string
output:
  schema:
    summary: string
    keyPoints(array): string
---
Summarize the following in {{tone}} tone:

{{text}}

Return JSON with `summary` (string) and `keyPoints` (array).
```

```ts
const summarize = ai.prompt("summarize");
const { output } = await summarize({ text: "...", tone: "professional" });
console.log(output.summary, output.keyPoints);
```

`.prompt` files version with your code, support handlebars templating, declare model + config + input/output schemas, and produce typed outputs. Use them for any prompt you'd otherwise inline as a multi-line string in code — `.prompt` files are versionable, reviewable, and testable.

### Retrieval-augmented generation (RAG) with Firestore vector search

Firestore vector search is the natural pairing with Genkit for small-to-moderate-scale RAG:

```ts
import { genkit, z } from "genkit";
import { googleAI } from "@genkit-ai/googleai";
import { defineFirestoreRetriever } from "@genkit-ai/firebase";
import { getFirestore } from "firebase-admin/firestore";

const ai = genkit({ plugins: [googleAI()] });
const firestore = getFirestore();

// Indexer (write side)
await firestore.collection("docs").doc(id).set({
  text: doc.text,
  embedding: FieldValue.vector(
    (await ai.embed({ embedder: googleAI.embedder("text-embedding-004"), content: doc.text }))[0].embedding
  ),
});

// Retriever (read side)
const retriever = defineFirestoreRetriever(ai, {
  name: "docs-retriever",
  firestore,
  collection: "docs",
  contentField: "text",
  vectorField: "embedding",
  embedder: googleAI.embedder("text-embedding-004"),
  distanceMeasure: "COSINE",
});

const docs = await ai.retrieve({ retriever, query: "user question", options: { limit: 5 } });
const { text } = await ai.generate({
  model: googleAI.model("gemini-2.5-pro"),
  prompt: `Use these docs to answer:\n\n${docs.map(d => d.content[0].text).join("\n\n")}\n\nQuestion: user question`,
});
```

Firestore vector search is good for ~10k-100k docs. Beyond that, evaluate dedicated vector DBs (Pinecone, Weaviate, pgvector via Data Connect). Hybrid filtering (e.g., "vector-similar AND tenant_id = X AND not deleted") works natively in Firestore — combine `findNearest` with `where`.

### Eval — testing AI behavior

```ts
// genkit.config.ts
export default defineConfig({
  // ...
});

// test/evals.ts
import { ai } from "../src/ai";
import { summarizeFlow } from "../src/flows";

const testCases = [
  { input: { text: "..." }, expected: { summary: /three sentences/ } },
  // ...
];
```

```bash
genkit start --flow summarizeFlow
genkit eval:flow summarizeFlow --input testcases.json
```

Genkit's eval harness:
- Runs your flow against a golden dataset
- Records inputs, outputs, intermediate generations
- Supports automated evaluators (groundedness, harmfulness, relevance) and custom evaluators
- Outputs scored results to Firebase / Genkit UI

Eval-driven development is the discipline equivalent of TDD for AI flows. Before refactoring a prompt or swapping a model, run the eval suite and verify scores don't regress.

### Genkit deployed on Cloud Functions for Firebase

```ts
import { onCallGenkit } from "firebase-functions/v2/https";
import { summarizeFlow } from "./flows";

export const summarize = onCallGenkit(
  { enforceAppCheck: true, consumeAppCheckToken: true, secrets: [GEMINI_KEY] },
  summarizeFlow
);
```

`onCallGenkit` wraps a Genkit flow as a Firebase callable function. Client calls via the Firebase callable SDK; Genkit handles flow orchestration; App Check enforcement applies.

Alternative: deploy Genkit as a Cloud Run service (for HTTP, not Firebase-callable semantics) or Cloud Functions HTTP function. Use `onCallGenkit` when the client is a Firebase client; raw Cloud Run when you want generic HTTP access.

## Patterns and anti-patterns

### Pattern: layered AI — on-device first, cloud fallback

```ts
// Try on-device Gemini Nano first; fall back to cloud Gemini
async function summarize(text: string) {
  try {
    const nano = await tryOnDeviceModel(text);
    if (nano.confidence > 0.7) return nano.summary;
  } catch { /* on-device unavailable */ }
  return await cloudSummarize(text);
}
```

Saves cost and latency for the common case. Falls back for complex inputs or when on-device isn't available.

### Pattern: server-side Remote Config drives prompts

```ts
import { getRemoteConfig } from "firebase-admin/remote-config";
const template = await getRemoteConfig().getServerTemplate();
const config = template.evaluate();
const promptVariant = config.getString("summarize_prompt_v");  // "v1" or "v2"

const prompt = ai.prompt(`summarize_${promptVariant}`);
const { output } = await prompt({ text });
```

Server-side Remote Config (2024) lets you A/B test prompts, swap models per cohort, and roll back without redeploying. Pair with A/B Testing in console for goal-metric tracking.

### Anti-pattern: client-side Gemini call without App Check

Already covered. A leaked client config + no App Check = free Gemini billing for the internet. Every AI Logic deployment must enforce App Check in production. Non-negotiable.

### Anti-pattern: trusting tool-call output without validation

The model decides to call a tool. The tool returns a structured response. The model uses that response. If the tool's data is from an untrusted source (e.g., a user-supplied URL), the model now has user-controlled content in its prompt — **prompt injection**. Defend by:

- Validating tool outputs server-side before passing back to the model
- Treating tool outputs as untrusted user input where they come from external sources
- Using a content safety check (Genkit has integrations) before passing to the model
- For sensitive subsequent operations, requiring user confirmation, not just model assertion

### Anti-pattern: long prompts with no caching

Gemini supports **context caching** (prefix caching) for repeated long prompts. If you have a 50K-token system prompt that's identical across many requests, cache it — pay once for the cache; subsequent requests pay only the additional tokens. Genkit JS supports this via the `cache` parameter on `generate`. Without caching, you pay full input tokens on every request.

### Anti-pattern: ignoring eval until the prompt is "obviously broken"

Models drift. Prompts that worked on `gemini-1.5-pro` may behave differently on `gemini-2.5-pro`. Without eval, you discover regressions in production. With eval, you catch them in CI on model upgrade.

### Anti-pattern: vector search where keyword search would work

Vector search is a tool, not a default. For "find docs with exact term X", keyword search (Algolia, Typesense, Postgres full-text) is faster, cheaper, and more accurate. Use vector search for semantic similarity — "find docs about *the concept of* X." Hybrid retrieval (keyword + vector reranked) is best for production RAG.

## Decision frameworks

### Genkit vs LangChain vs raw model SDK

| Pick Genkit if | Pick LangChain if | Pick raw model SDK if |
|----------------|-------------------|-----------------------|
| You're on Firebase / GCP | You need maximum ecosystem breadth (every vector DB, every loader) | The flow is one-shot generation, no orchestration |
| You want typed flows + auto-eval | Your team is already on LangChain | You need the absolute latest Gemini API feature before any framework supports it |
| You're integrating with Cloud Functions | Multi-cloud deployment, model-agnostic | Quick prototyping |

Genkit is opinionated about typing and eval — that's a feature in production, sometimes friction in prototyping.

### Cloud Function with Genkit vs client-side Firebase AI Logic

| Use Cloud Function + Genkit if | Use AI Logic if |
|--------------------------------|-----------------|
| The prompt needs server-side data the client shouldn't see | The prompt is built from client-side input or public data |
| The flow has multi-step orchestration (retrieve → reason → act) | The flow is a single Gemini call |
| You need RAG over server-stored vectors | The model has all the context it needs from the input |
| Tools execute privileged operations | Read-only or non-privileged tools |
| You need server-side eval + observability | Client-side observability is enough |

### Firestore vector search vs dedicated vector DB

| Use Firestore vector search if | Use dedicated vector DB if |
|--------------------------------|---------------------------|
| Corpus is <100K docs, embeddings <2K dims | Corpus is millions of docs |
| You want one database for app data + vectors | You need ANN-specific features (HNSW tuning, quantization) |
| Hybrid filtering on Firestore-native fields is natural | You need cross-cluster ANN with sub-100ms p99 at scale |
| Cost-sensitive (Firestore reads aren't free, but the infra is unified) | Sub-millisecond k-NN at high QPS matters |

### Gemini Pro vs Flash vs Nano

| | Pro | Flash | Nano |
|--|-----|-------|------|
| **Best for** | Hard reasoning, code, long context | Most product features | On-device, fast, free per call |
| **Latency** | Higher | Lower | Lowest |
| **Cost** | Higher per token | Cheap | Free |
| **Context window** | Largest | Large | Small |

Default for most product features: **Flash**. Pro when you need the extra reasoning. Nano for on-device only.

## Integration with always-on protocols

### TDD on AI flows

Don't TDD prompt text. Do TDD:

1. **Flow input/output schemas.** Test that the flow validates inputs correctly, rejects malformed inputs.
2. **Tool behavior.** Tools are deterministic functions — unit-test them like any other function.
3. **Eval-driven prompt iteration.** Curate a golden dataset; eval every change against it; refuse to merge changes that regress eval scores.
4. **Integration tests against the Local Emulator Suite** for the Firebase data layer (Firestore vector reads/writes, Cloud Function invocation).

### Verification

- [ ] App Check enforced on every AI Logic deployment in production
- [ ] Replay Protection on every callable that invokes Genkit flows
- [ ] Eval suite runs in CI; passes for every PR
- [ ] No client-side function calling for privileged operations
- [ ] Prompts under version control (`.prompt` files or templated strings in code)
- [ ] Model + temperature + token limits configured explicitly per flow
- [ ] Costs monitored — Cloud Billing alerts on Gemini spend
- [ ] PII redaction in any flow that processes user data before logging

### Debugging

- **Genkit UI** (local dev) shows full flow traces — every model call, tool invocation, embed, retrieve. Use it for "why did the model decide X?"
- **Genkit eval logs** are written to Firestore (by default) — query them to compare runs.
- **Cloud Logging** captures Cloud Function executions; Genkit logs structured events at `info` and `error` levels.
- **Cloud Trace** integrates with Genkit (where wired up) for end-to-end latency breakdown across the flow.

Root-cause first: when a flow produces wrong output, work backward from the final generation. Was the retrieval correct? Was the system prompt loaded right? Did a tool return garbage? One variable at a time — change the prompt OR change the model OR change the retriever, not all three.

## Common AI footguns on Firebase

- **Vertex AI in Firebase / `@firebase/vertexai`** — old names. Use Firebase AI Logic / `@firebase/ai`.
- **App Check off on AI Logic** — free Gemini billing channel.
- **No eval suite** — prompt drifts invisibly across model upgrades.
- **Client-side tool calling for privileged ops** — model decides to "transfer money"; client executes. Don't.
- **Prompt injection via untrusted retriever content** — a malicious doc in your vector store can inject instructions when retrieved. Defend with content sanitization and instruction-following discipline.
- **Long prompts with no caching** — paying full input tokens per request when 80% is static.
- **Genkit eval skipped because "it works on my prompt"** — works ≠ works in 1000 cases.
- **Model name hard-coded in a hundred places** — when Gemini 3 ships, you grep for `gemini-2.5-` in fifty files. Centralize model selection (env var, Remote Config, or a single config module).
- **Treating Firestore vector search as infinitely scalable** — past ~100K docs, indexing latency and read cost stack up. Plan a graduation path.
- **Streaming responses without UI affordances** — users staring at a blinking cursor for 3 seconds bail. Show progress, partial tokens.
- **Logging full prompts + responses without redaction** — PII in retention. Redact before logging or use sampled logging.

## Cross-references

- App Check setup + Replay Protection on AI Logic: [`security-engineer.md`](security-engineer.md#app-check)
- Calling Genkit flows from callable Cloud Functions: [`backend-architect.md`](backend-architect.md#firebase-admin-sdk--what-you-actually-do-with-it)
- Client-side AI Logic SDK on web: [`frontend-architect.md`](frontend-architect.md)
- On-device Gemini Nano integration on mobile: [`mobile-architect.md`](mobile-architect.md)

## Delegate skills

If the user environment has the Firebase skill suite, defer to:

- [`firebase:developing-genkit-js`](#) — Genkit JS/TS deep dive
- [`firebase:developing-genkit-python`](#) — Genkit Python
- [`firebase:developing-genkit-go`](#) — Genkit Go
- [`firebase:developing-genkit-dart`](#) — Genkit Dart / Flutter
- [`firebase:firebase-ai-logic-basics`](#) — AI Logic SDK, Gemini integration, App Check
- [`firebase:firebase-firestore`](#) — Firestore vector search syntax

These delegate skills cover language- and product-specific API depth that this overlay summarizes.
