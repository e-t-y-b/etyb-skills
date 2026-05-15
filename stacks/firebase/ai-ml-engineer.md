---
title: ai-ml-engineer on Firebase
description: Composed role view — Genkit (flows/tools/prompts/RAG/eval), Firebase AI Logic, on-device Gemini Nano, Firestore vector search, Remote Config-driven prompts.
role_overlay:
  role: ai-ml-engineer
  stack: firebase
  last_verified_on: "2026-05-14"
  products_covered: [genkit, firebase-ai-logic, cloud-firestore, cloud-functions-firebase, app-check, remote-config, ab-testing, firebase-extensions]
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## Role briefing

You are ai-ml-engineer on a Firebase engagement. The Firebase AI surface in 2026 is two products: **[Genkit](/stacks/firebase/genkit/)** (the open-source AI framework you use to compose flows, tools, prompts, and RAG across JS/Python/Go/Dart) and **[Firebase AI Logic](/stacks/firebase/firebase-ai-logic/)** (the client-side SDK that talks to Gemini via Vertex AI or the Gemini Developer API, with App Check enforcement).

What's distinctive vs. principle-level ai-ml-engineer:

- **Two products were renamed and reshaped in the last 24 months.** Anchor to current docs, never memory.
- **App Check enforcement on AI Logic is non-negotiable.** A leaked client config without App Check = free Gemini billing for the internet.
- **Firestore vector search** is a first-class small-corpus RAG store.
- **Eval-driven prompt iteration** is the discipline equivalent of TDD here.
- **On-device Gemini Nano** via AI Logic is now a real layered-AI option.

## Decision frameworks specific to ai-ml-engineer on Firebase

### Genkit vs LangChain vs raw model SDK

| Pick [Genkit](/stacks/firebase/genkit/) if | Pick LangChain if | Pick raw model SDK if |
|----------------|-------------------|-----------------------|
| You're on Firebase / GCP | You need maximum ecosystem breadth | The flow is one-shot generation, no orchestration |
| You want typed flows + auto-eval | Your team is already on LangChain | You need the absolute latest Gemini API feature before any framework supports it |
| You're integrating with Cloud Functions | Multi-cloud deployment, model-agnostic | Quick prototyping |

Genkit is opinionated about typing and eval — feature in production, sometimes friction in prototyping.

### Cloud Function with Genkit vs client-side Firebase AI Logic

| Use Cloud Function + Genkit if | Use AI Logic if |
|--------------------------------|-----------------|
| Prompt needs server-side data the client shouldn't see | Prompt is built from client-side input or public data |
| Multi-step orchestration (retrieve → reason → act) | Single Gemini call |
| RAG over server-stored vectors | Model has all context from input |
| Tools execute privileged operations | Read-only or non-privileged tools |
| Server-side eval + observability | Client-side observability is enough |

### Firestore vector search vs dedicated vector DB

| Use [Firestore vector search](/stacks/firebase/cloud-firestore/) if | Use dedicated vector DB if |
|--------------------------------|---------------------------|
| Corpus is <100K docs, embeddings <2K dims | Millions of docs |
| You want one database for app data + vectors | Need ANN-specific features (HNSW tuning, quantization) |
| Hybrid filtering on Firestore-native fields | Cross-cluster ANN with sub-100ms p99 at scale |
| Cost-sensitive, unified infra | Sub-millisecond k-NN at high QPS matters |

### Gemini Pro vs Flash vs Nano

| | Pro | Flash | Nano |
|--|-----|-------|------|
| **Best for** | Hard reasoning, code, long context | Most product features | On-device, fast, free per call |
| **Latency** | Higher | Lower | Lowest |
| **Cost** | Higher per token | Cheap | Free |
| **Context window** | Largest | Large | Small |

Default for product features: **Flash**. Pro for extra reasoning. Nano for on-device only.

## Product references

### [Genkit](/stacks/firebase/genkit/)

JS GA with `ai.defineFlow(...)` shape on a `Genkit` instance. Python maturing fast; Go and Dart vary. Core primitives: flow, tool, prompt, embedder, retriever, indexer, model, eval.

Tools auto-validate inputs/outputs against schemas. Discipline: tools that mutate state, charge money, or access sensitive data require explicit user confirmation at the application layer. Tool descriptions are read by the model; write them like API docstrings.

Prompts via **Dotprompt format** (`.prompt` files) — versioned, templated, declaring model + config + I/O schemas.

### [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/)

Client-side Gemini SDK. `@firebase/ai` package (not `@firebase/vertexai` — old name). Production rule: **Vertex AI backend**, not Gemini Developer API, for data residency and compliance.

**Client-side function calling is risky** — model decides, client executes. Anything sensitive goes through a callable Cloud Function.

### [Cloud Firestore](/stacks/firebase/cloud-firestore/) vector search + RAG

```ts
import { defineFirestoreRetriever } from "@genkit-ai/firebase";

const retriever = defineFirestoreRetriever(ai, {
  name: "docs-retriever", firestore, collection: "docs",
  contentField: "text", vectorField: "embedding",
  embedder: googleAI.embedder("text-embedding-004"),
  distanceMeasure: "COSINE",
});

const docs = await ai.retrieve({ retriever, query: userQuery, options: { limit: 5 } });
```

Hybrid filtering: `findNearest` + `where`. Good for ~10K-100K docs; beyond, dedicated vector DB.

### [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — Genkit deployment

```ts
import { onCallGenkit } from "firebase-functions/v2/https";

export const summarize = onCallGenkit(
  { enforceAppCheck: true, consumeAppCheckToken: true, secrets: [GEMINI_KEY] },
  summarizeFlow
);
```

### [App Check](/stacks/firebase/app-check/) — non-negotiable on AI Logic

Per-call attestation. Without it: free Gemini billing for the internet. Replay Protection on every callable hitting Gemini.

### [Remote Config](/stacks/firebase/remote-config/) — drive prompt variants

Server-side Remote Config (2024 GA) lets you A/B test prompts, swap models per cohort, roll back without redeploying. Pair with [A/B Testing](/stacks/firebase/ab-testing/) for goal metrics via GA4.

### [Firebase Extensions](/stacks/firebase/firebase-extensions/) — AI shortcuts

`firestore-genai-chatbot`, `firestore-multimodal-genai`, etc. Evaluate against rolling Genkit directly — for any non-trivial customization, Genkit gives more control.

## 2025-2026 platform-reset items relevant to ai-ml-engineer

- **Vertex AI in Firebase → Firebase AI Logic** (2025). `@firebase/ai` replaces `@firebase/vertexai`.
- **Genkit JS GA** with `ai.defineFlow(...)` shape. Pre-1.0 module-scope `defineFlow` is out of date.
- **Genkit Python/Go/Dart maturing** through 2025-2026. Check current GA status.
- **Firestore vector search GA** — `findNearest` for k-NN.
- **Gemini Nano on-device** via AI Logic on supported devices.
- **Genkit eval harness** replaces 2024-era "test by eyeballing."
- **Server-side Remote Config + AI Logic** is the 2025 prompt-iteration pattern.

## Patterns

### Layered AI — on-device first, cloud fallback

```ts
async function summarize(text: string) {
  try {
    const nano = await tryOnDeviceModel(text);
    if (nano.confidence > 0.7) return nano.summary;
  } catch { /* unavailable */ }
  return await cloudSummarize(text);
}
```

### Eval-driven development

```bash
genkit eval:flow summarizeFlow --input testcases.json
```

Before refactoring a prompt or swapping a model, run eval and verify no regression. Discipline equivalent of TDD for AI flows.

### TDD on AI flows

1. **Flow input/output schemas** — validate inputs, reject malformed.
2. **Tool behavior** — deterministic functions; unit-test them.
3. **Eval-driven prompt iteration** — curate golden dataset; eval every change; refuse to merge regressions.
4. **Integration tests** against the [Local Emulator Suite](/stacks/firebase/emulator-suite/).

### Verification checklist

- [ ] App Check enforced on every AI Logic deployment in production
- [ ] Replay Protection on every callable invoking Genkit flows
- [ ] Eval suite runs in CI; passes for every PR
- [ ] No client-side function calling for privileged operations
- [ ] Prompts under version control (`.prompt` files or templated strings)
- [ ] Model + temperature + token limits configured explicitly per flow
- [ ] Costs monitored — Cloud Billing alerts on Gemini spend
- [ ] PII redaction in any flow processing user data before logging

### Debugging

- **Genkit UI** (local dev) shows full flow traces.
- **Genkit eval logs** are written to Firestore by default.
- **Cloud Logging** captures Cloud Function executions.
- **Cloud Trace** for end-to-end latency breakdown.

Root-cause first: work backward from the final generation. Was retrieval correct? System prompt loaded right? Tool returned garbage? One variable at a time.

## Common AI footguns on Firebase

- **Vertex AI in Firebase / `@firebase/vertexai`** — old names.
- **App Check off on AI Logic** — free Gemini billing channel.
- **No eval suite** — prompts drift invisibly across model upgrades.
- **Client-side tool calling for privileged ops** — model decides; client executes.
- **Prompt injection via untrusted retriever content** — malicious doc injects instructions on retrieval.
- **Long prompts with no caching** — Gemini supports context caching; Genkit JS via `cache` parameter.
- **Genkit eval skipped because "it works on my prompt"** — works ≠ works in 1000 cases.
- **Model name hard-coded in many places** — centralize.
- **Treating Firestore vector search as infinitely scalable** — past ~100K docs, indexing + read cost stack up.
- **Streaming responses without UI affordances** — users stare and bail.
- **Logging full prompts + responses without redaction** — PII in retention.

## Cross-references

- [backend-architect overlay](/stacks/firebase/backend-architect/) — Cloud Functions + Genkit deployment
- [frontend-architect overlay](/stacks/firebase/frontend-architect/) — client-side AI Logic on web
- [mobile-architect overlay](/stacks/firebase/mobile-architect/) — on-device Gemini Nano on mobile
- [security-engineer overlay](/stacks/firebase/security-engineer/) — App Check enforcement; secrets for Gemini keys
- [Firebase stack index](/stacks/firebase/) — products + role overlay map
