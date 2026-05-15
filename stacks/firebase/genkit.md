---
title: Genkit
description: Firebase's open-source AI orchestration framework — typed flows, tools, prompts, RAG, eval. JS GA; Python/Go/Dart maturing 2025-2026.
product:
  name: Genkit
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://firebase.google.com/docs/genkit
  notes: "JS GA; Python/Go/Dart maturing through 2025-2026; API shape has churned — anchor to current docs not training data."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Genkit is Firebase's open-source AI orchestration framework. It runs anywhere (any Node / Python / Go / Dart server), but the natural deployment is **inside [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/)** — that's where Firebase publishes the strongest integration. Core primitives:

- **Flow** — a named, typed function that orchestrates AI work. Inputs and outputs are validated (Zod in JS, Pydantic in Python).
- **Tool** — a function the model can call. Typed inputs/outputs. Auto-exposed in the model's tool registry.
- **Prompt** — a versioned, templated prompt, definable inline or in `.prompt` files (Dotprompt format).
- **Embedder** — generates embeddings for vectors.
- **Retriever** — queries a vector store.
- **Indexer** — writes documents (with embeddings) to a vector store.
- **Model** — abstraction over LLM providers (Gemini, OpenAI, Anthropic, local, etc.).
- **Eval** — testing harness for flow outputs against golden datasets.

Canonical reference: [Genkit docs](https://firebase.google.com/docs/genkit).

## When to use it

**Use Genkit when:**

- You're on Firebase / GCP and want typed AI orchestration
- You want auto-eval as a first-class concept (golden datasets, scored evaluators)
- You're integrating with Cloud Functions for Firebase
- You want flow tracing in a dev UI

**Use LangChain when:**

- You need maximum ecosystem breadth (every vector DB, every loader)
- Your team is already on LangChain
- Multi-cloud deployment, model-agnostic

**Use raw model SDK when:**

- The flow is one-shot generation, no orchestration
- You need the absolute latest Gemini API feature before any framework supports it
- Quick prototyping

## 2025-2026 currency anchors

- **Genkit JS GA** with `ai.defineFlow(...)` shape on a `Genkit` instance. Pre-1.0 module-scope `defineFlow(...)` patterns are out of date.
- **Genkit Python, Go, Dart** maturing through 2025-2026. Python is the next most mature. Match your runtime to current GA status — check [docs](https://firebase.google.com/docs/genkit).
- **API has churned multiple times.** Any sample older than mid-2024 likely uses out-of-date shapes. Anchor to current docs, never to memory.
- **Genkit eval harness** ships a `genkit evaluate` workflow with golden datasets, replacing 2024-era "test by eyeballing."
- **`onCallGenkit`** in `firebase-functions/v2/https` wraps a flow as a Firebase callable function.

## Patterns

### Genkit JS — current shape (2026)

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

### Tools — typed function calling

```ts
export const getWeather = ai.defineTool(
  {
    name: "getWeather",
    description: "Get current weather for a city",
    inputSchema: z.object({ city: z.string() }),
    outputSchema: z.object({ tempC: z.number(), conditions: z.string() }),
  },
  async ({ city }) => {
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

Genkit auto-handles the tool-call loop: model emits function call → Genkit validates args against input schema → tool runs → output validated → Genkit feeds back to model → continue.

**Discipline:**

1. **Tools that mutate state / charge money / access sensitive data require explicit user confirmation** at the application layer. Don't trust the model alone.
2. **Tool inputs/outputs are typed.** The model's tool call gets validated before your tool runs.
3. **Tools should be idempotent** where possible.
4. **Tool descriptions are read by the model** — write them like API docstrings.

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
```

```ts
const summarize = ai.prompt("summarize");
const { output } = await summarize({ text: "...", tone: "professional" });
```

`.prompt` files version with your code, support handlebars templating, declare model + config + I/O schemas, produce typed outputs. Use for any prompt you'd otherwise inline as a multi-line string.

### RAG with Firestore vector search

```ts
import { defineFirestoreRetriever } from "@genkit-ai/firebase";

const retriever = defineFirestoreRetriever(ai, {
  name: "docs-retriever",
  firestore,
  collection: "docs",
  contentField: "text",
  vectorField: "embedding",
  embedder: googleAI.embedder("text-embedding-004"),
  distanceMeasure: "COSINE",
});

const docs = await ai.retrieve({ retriever, query: userQuestion, options: { limit: 5 } });
const { text } = await ai.generate({
  model: googleAI.model("gemini-2.5-pro"),
  prompt: `Use these docs:\n${docs.map(d => d.content[0].text).join("\n\n")}\n\nQ: ${userQuestion}`,
});
```

Firestore vector search is good for ~10k-100k docs. Beyond, evaluate dedicated vector DBs.

### Eval — testing AI behavior

```bash
genkit eval:flow summarizeFlow --input testcases.json
```

Genkit's eval harness runs your flow against a golden dataset, records inputs/outputs/intermediate generations, supports automated evaluators (groundedness, harmfulness, relevance) and custom evaluators. **Eval-driven development is the discipline equivalent of TDD for AI flows.** Before refactoring a prompt or swapping a model, run eval and verify no regression.

### Genkit deployed on Cloud Functions

```ts
import { onCallGenkit } from "firebase-functions/v2/https";

export const summarize = onCallGenkit(
  { enforceAppCheck: true, consumeAppCheckToken: true, secrets: [GEMINI_KEY] },
  summarizeFlow
);
```

Wraps a Genkit flow as a Firebase callable with App Check enforcement.

## Anti-patterns

- **Module-scope `defineFlow(...)`** — pre-1.0 shape. Use `ai.defineFlow(...)` on a `Genkit` instance.
- **No eval suite** — prompt drifts invisibly across model upgrades.
- **Client-side tool calling for privileged operations** — model decides to "transfer money"; client executes. Server-side via callable Cloud Function.
- **Long prompts with no caching** — Gemini supports context caching for repeated long prompts. Genkit JS supports via the `cache` parameter on `generate`.
- **Vague tool descriptions** — the model reads them; vague = wrong tool calls.
- **Prompt injection via untrusted retriever content** — a malicious doc in your vector store can inject instructions. Sanitize.

## Gotchas

- **Genkit's API has churned.** Code from early 2024 (`defineFlow` at module scope) and 2025 code (`ai.defineFlow`) look different and aren't interchangeable. Always check current docs.
- **Genkit JS plugin ecosystem is the most mature**; Python, Go, Dart vary by version.
- **Eval is async + writes results to Firestore by default** — provision the Firestore collection.
- **Genkit dev UI** runs locally — fine for inspection but not a production observability layer.

## Cross-references

- [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) — client-side Gemini SDK; Genkit is the server-side orchestration
- [Cloud Firestore](/stacks/firebase/cloud-firestore/) — vector search backing for retrievers
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — `onCallGenkit` deploys flows as callables
- [Remote Config](/stacks/firebase/remote-config/) — server-side Remote Config drives prompt variants
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — Genkit + AI Logic full playbook
- Authoritative: [firebase.google.com/docs/genkit](https://firebase.google.com/docs/genkit)
