---
title: Gemini
description: Google's flagship LLM family on Vertex AI — 2.5 Pro / Flash / Flash-Lite; 1M+ token context, thinking budget, function calling, prompt caching.
product:
  name: Gemini
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/overview
  notes: "Gemini 2.5 family (Pro, Flash, Flash-Lite); 1M+ context on Pro; thinking config; prompt caching; safety settings configurable per category."
---

## What it is

Gemini is Google's flagship LLM family, served via [Vertex AI](/stacks/gcp/vertex-ai/). Three tiers in Q2 2026:

- **Gemini 2.5 Pro** — most capable; long-context (1M+ tokens); reasoning + code + multimodal
- **Gemini 2.5 Flash** — fast, cheaper, balanced quality; **the default for most production workloads**
- **Gemini 2.5 Flash-Lite** — lowest cost, highest throughput, optimized for high-volume inference

**Gemini 3.x is likely landing soon** — verify against [Vertex AI release notes](https://cloud.google.com/vertex-ai/docs/release-notes) before quoting specifics.

Authoritative reference: [cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/overview).

## When to use

Pick Gemini Flash as the default for:
- Chat assistants, summarization, classification, extraction
- API-fronted text generation in a SaaS product
- Tool-calling / function-calling agents (see [Agent Builder](/stacks/gcp/agent-builder/))

Pick Gemini Pro when:
- Complex reasoning, multi-turn agents requiring deep planning
- Long-context (>200K tokens) — Pro supports 1M+
- Multimodal analysis (image + text + video)
- Code generation with high quality demands

Pick Gemini Flash-Lite when:
- High-volume inference where every token cost matters
- Simple tasks (single-shot classification, extraction, light summarization)
- Embeddings generation (though for embeddings, use the dedicated `text-embedding-005` model)

For Claude / Llama / Gemma alternatives, see [Vertex AI](/stacks/gcp/vertex-ai/) Model Garden.

## 2025-2026 currency anchors

- **Gemini 2.5 family** is the current generation in Q2 2026.
- **Thinking budget** (`thinking_config.thinking_budget`) — Pro and Flash support extended reasoning; budget controls how many "thinking tokens" the model can use.
- **Prompt caching** — explicit cached content for repeated system prompts; major cost reduction when 90% of a request is the same context.
- **Safety settings** configurable per category (harassment, hate speech, sexually explicit, dangerous content).
- **Function calling** with JSON Schema tool definitions; model returns structured `function_call` parts.
- **Multimodal input**: text + image + video + audio.

## Patterns

### Basic call

```python
from google import genai
from google.genai import types

client = genai.Client(
    vertexai=True,
    project="my-project",
    location="us-central1",
)

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Summarize this support ticket: ...",
    config=types.GenerateContentConfig(
        temperature=0.2,
        max_output_tokens=1024,
        system_instruction="You are a customer support assistant.",
        safety_settings=[
            types.SafetySetting(
                category="HARM_CATEGORY_HARASSMENT",
                threshold="BLOCK_MEDIUM_AND_ABOVE",
            ),
        ],
        thinking_config=types.ThinkingConfig(
            include_thoughts=False,
            thinking_budget=2048,
        ),
    ),
)
print(response.text)
```

### Function calling / tool use

```python
tools = [
    types.Tool(function_declarations=[
        types.FunctionDeclaration(
            name="get_order_status",
            description="Look up order status by order ID",
            parameters=types.Schema(
                type="OBJECT",
                properties={"order_id": types.Schema(type="STRING")},
                required=["order_id"],
            ),
        ),
    ]),
]

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What's the status of order 12345?",
    config=types.GenerateContentConfig(tools=tools),
)
# Handle function_call parts; execute the function; return result; continue conversation.
```

### Long context

Pro supports 1M+ tokens. Use for:
- Document analysis over long PDFs / codebases
- Multi-document RAG without aggressive chunking
- Long conversation history kept in context

**Don't dump 1M tokens of irrelevant context** — RAG with smaller models often outperforms long-context with Pro for cost-per-quality.

### Prompt caching

For repeated system prompts, create a cached content object and reference it on subsequent generate calls. Cached portions are charged at a discount and don't count toward per-request token billing the same way as fresh tokens.

### Multimodal

```python
response = client.models.generate_content(
    model="gemini-2.5-pro",
    contents=[
        types.Part(text="Describe this image and suggest improvements"),
        types.Part.from_uri(file_uri="gs://my-bucket/image.jpg", mime_type="image/jpeg"),
    ],
)
```

## Anti-patterns

- **Reflexive Gemini 2.5 Pro** — Flash beats Pro on cost-per-quality for the majority of production prompts.
- **No prompt caching** for repeated system instructions — wasteful spend.
- **Long-context for everything** — RAG with smaller model often outperforms long-context.
- **No safety filter configuration** — accepts defaults that may not match your risk profile.
- **No model evaluation pipeline** — ship → discover quality regression → roll back.
- **Stale names**: "PaLM API", "MakerSuite", "Bard API" — these names are wrong.

## Gotchas

- **Token limits per model** vary; check current limits on the model docs.
- **Streaming responses** via `generate_content_stream` for interactive UIs.
- **Quota** is per-region per-model; default quota is modest, request increases for high-volume.
- **Pricing** distinguishes input / output / cached tokens; budget accordingly.
- **`google-genai` SDK** is the modern path; older `vertexai.preview.generative_models` is deprecated.

## Cross-references

- Related: [Vertex AI](/stacks/gcp/vertex-ai/), [Vertex AI Agent Builder](/stacks/gcp/agent-builder/), [Agentspace](/stacks/gcp/agentspace/), [BigQuery ML](/stacks/gcp/bigquery-ml/) (Gemini from SQL), [AlloyDB](/stacks/gcp/alloydb/) (embeddings)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [backend-architect on GCP](/stacks/gcp/backend-architect/)
- Authoritative: [cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/overview)
