---
title: Firebase AI Logic
description: Client-side Gemini SDK with App Check enforcement. Rebranded from Vertex AI in Firebase 2025. Direct client-to-Gemini latency, on-device Gemini Nano option.
product:
  name: Firebase AI Logic
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, frontend-architect, mobile-architect, security-engineer]
  authoritative_url: https://firebase.google.com/docs/ai-logic
  notes: "Rebranded from Vertex AI in Firebase 2025; client-side Gemini access with App Check; on-device Gemini Nano option."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase AI Logic lets your client (iOS, Android, Flutter, Web) call Gemini directly, with **App Check** enforcing that the call comes from your authentic app. The SDK abstracts:

- Auth (App Check token attached automatically)
- Backend selection (Vertex AI or Gemini Developer API)
- Streaming responses
- Function calling
- Multimodal inputs (text, images, audio, video)
- On-device Gemini Nano (where available)

Rebranded from **Vertex AI in Firebase** in 2025. SDK packages renamed (`@firebase/ai` replaces `@firebase/vertexai`; iOS `FirebaseAI` replaces `FirebaseVertexAI`).

Canonical reference: [Firebase AI Logic docs](https://firebase.google.com/docs/ai-logic).

## Why AI Logic exists

Without it, your options for client Gemini calls are:

1. **Direct Gemini API call from client** — requires a Gemini API key in the client, which is immediate leakage. **Don't.**
2. **Cloud Function proxy** — every Gemini call hops through your backend, adding latency, adding cost (function invocation + bandwidth).

AI Logic gives you **direct client-to-Gemini latency** with **server-side authorization via App Check + Firebase Auth**, billed to your project.

## When to use it

**Use AI Logic when:**

- The prompt is built from client-side input or public data (no server-side secrets in the prompt)
- The flow is a single Gemini call (no multi-step orchestration)
- Read-only or non-privileged tools (or no tools)
- Client-side observability is sufficient

**Use a Cloud Function + [Genkit](/stacks/firebase/genkit/) when:**

- The prompt needs server-side data the client shouldn't see
- The flow has multi-step orchestration (retrieve → reason → act)
- You need RAG over server-stored vectors
- Tools execute privileged operations
- You need server-side eval + observability

## 2025-2026 currency anchors

- **Rebrand 2025** — Vertex AI in Firebase → Firebase AI Logic. `@firebase/ai` replaces `@firebase/vertexai`. iOS class `FirebaseAI` replaces `FirebaseVertexAI`.
- **App Check enforcement** is non-negotiable. A leaked client config without App Check = free Gemini billing for the internet.
- **On-device Gemini Nano** via AI Logic on supported devices — Android with AICore service; Apple Intelligence-capable devices for some flows.
- **Two backends**: Vertex AI (production default) or Gemini Developer API (prototyping).

## Patterns

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
```

### Setup (iOS Swift)

```swift
import FirebaseAI
import FirebaseAppCheck

// App Check setup before FirebaseApp.configure() — see security overlay
let ai = FirebaseAI.firebaseAI(backend: .vertexAI())
let model = ai.generativeModel(modelName: "gemini-2.5-flash")
let response = try await model.generateContent("Summarize this in 3 bullets: ...")
```

### Backend choice — Vertex AI vs Gemini Developer API

| | Vertex AI backend | Gemini Developer API backend |
|--|-------------------|------------------------------|
| **Billing** | Vertex AI pricing, on GCP project | Gemini API pricing |
| **Data residency** | Per-region in GCP | Limited |
| **Compliance** | GCP BAA-eligible | Limited |
| **Feature parity** | Closest to bleeding-edge Vertex features | Sometimes faster for Gemini Developer features |
| **Free tier** | No (Vertex AI is paid) | Yes (with quotas) |

**Production rule:** use Vertex AI backend. Production apps need data residency, compliance, GCP billing footprint. Gemini Developer API for prototyping only.

### Streaming responses

```ts
const result = await model.generateContentStream("Tell me a story.");
for await (const chunk of result.stream) {
  process.stdout.write(chunk.text());
}
```

Stream for any user-facing response longer than ~50 tokens — first-token latency is the perceived latency.

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
```

**Client-side function calling is risky** — the model decides which function to call, the client executes. Anything sensitive (DB writes, payments) should be server-side via a callable Cloud Function the client invokes in response to the function call. **The client should never directly execute "transfer money" because the model said so.**

### Multimodal — images, audio, video

```ts
const result = await model.generateContent([
  { inlineData: { data: base64Image, mimeType: "image/png" } },
  "Describe what's in this image."
]);
```

Image inputs inline base64 or Cloud Storage references. Video consumes way more tokens than text — budget appropriately.

### On-device Gemini Nano

Where the platform supports it (newer Android with AICore; Apple Intelligence-capable iOS for some flows), AI Logic routes to **Gemini Nano on-device**:

| Trade | On-device | Cloud |
|-------|-----------|-------|
| **Latency** | Sub-100ms typical | 200-1000ms first token |
| **Cost** | Free per call | Per-token |
| **Privacy** | Data never leaves device | Hits Vertex AI / Gemini API |
| **Capability** | Smaller model; shorter context; less capable on complex reasoning | Full Pro/Flash; longer context; SOTA |
| **Availability** | Limited devices | Universal |

Use on-device for: classification, summarization, autocomplete, content safety pre-filter, voice-input correction. Use cloud for: complex reasoning, multi-step planning, RAG over large corpora.

### Layered AI — on-device first, cloud fallback

```ts
async function summarize(text: string) {
  try {
    const nano = await tryOnDeviceModel(text);
    if (nano.confidence > 0.7) return nano.summary;
  } catch { /* on-device unavailable */ }
  return await cloudSummarize(text);
}
```

Saves cost and latency for the common case; falls back for complex inputs.

## Anti-patterns

- **`@firebase/vertexai` / `FirebaseVertexAI` imports** — old name. Migrate to `@firebase/ai` / `FirebaseAI`.
- **App Check off on AI Logic** — free Gemini billing channel for the internet.
- **Client-side tool calling for privileged ops** — model decides; client executes "transfer money." Don't.
- **Direct Gemini API key in client** — immediate leakage. Use AI Logic.
- **Long prompts with no caching** — Gemini supports context caching for repeated long prompts.
- **Hard-coding model name in many places** — when Gemini 3 ships, you grep for `gemini-2.5-` in 50 files. Centralize.

## Gotchas

- **App Check token must be initialized before first AI Logic call** — first calls go unprotected otherwise.
- **Debug App Check provider shipping to production** — backdoor; gate behind `#if DEBUG` / equivalent.
- **Streaming without UI affordance** — users staring at a blinking cursor for 3 seconds bail. Show partial tokens.
- **Cost** — Gemini calls aren't free. Monitor Cloud Billing; alert on spend.
- **Per-token billing** — long contexts add up fast. Trim.
- **On-device availability varies by device + OS version** — graceful fallback to cloud.

## Cross-references

- [App Check](/stacks/firebase/app-check/) — Replay Protection on AI Logic
- [Genkit](/stacks/firebase/genkit/) — server-side orchestration alternative
- [Remote Config](/stacks/firebase/remote-config/) — drive prompt variants / model selection
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — full AI playbook on Firebase
- [security-engineer overlay](/stacks/firebase/security-engineer/) — App Check + Replay Protection setup
- Authoritative: [firebase.google.com/docs/ai-logic](https://firebase.google.com/docs/ai-logic)
