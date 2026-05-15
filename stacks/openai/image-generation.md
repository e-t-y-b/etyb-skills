---
title: Image generation (gpt-image-1)
description: The 2025 native multimodal image model — generation, editing, variations, transparent backgrounds. DALL·E 3 is legacy.
product:
  name: Image generation
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/images
  notes: "gpt-image-1 replaced DALL·E 3 as default in 2025; native multimodal — accepts text + image refs; surface evolving."
---

## What it is

**gpt-image-1** is OpenAI's 2025 native multimodal image model. It is the production default for image generation, editing, variations, and transparent-background outputs. It accepts both text prompts and reference images as inputs — so editing and variations are first-class.

**DALL·E 3** is the legacy alternative — works, but new builds should default to gpt-image-1.

**DALL·E 2** is long-tail legacy. Don't recommend it.

Endpoint: `/v1/images/generations`, `/v1/images/edits`, `/v1/images/variations`. Reference: [Images guide](https://platform.openai.com/docs/guides/images).

## When to use

**Use gpt-image-1 when:**

- You're generating images from a text prompt.
- You're editing images with text instructions ("change the background to blue").
- You're generating variations of an input image.
- You need transparent backgrounds (gpt-image-1 supports this natively).
- You need image generation alongside text generation in the same product.

**Don't use OpenAI image generation when:**

- You need photorealistic faces of real people — use specialized providers; OpenAI restricts identifiable likenesses.
- Cost-per-image dominates and quality is secondary — open-source diffusion (Stable Diffusion via Replicate / Together / Fal) may be cheaper.
- The brand requires a specific style consistently — fine-tune your own model with a specialized provider.
- You need video — that's [Sora](/stacks/openai/) (consumer surface; API surface still early).

## 2025-2026 currency anchors

- **gpt-image-1 launched 2025** as the unified multimodal image model.
- **DALL·E 3 → legacy.** Existing pipelines run; new work uses gpt-image-1.
- **DALL·E 2 → long-tail legacy.** Don't recommend.
- **Editing + variations** unified through gpt-image-1 — no separate models.
- **Transparent backgrounds** are native — request via API parameters.
- **Per-image pricing** varies by size + quality. Verify on [pricing](https://openai.com/api/pricing/).
- **Sora (video) is consumer-surface** as of 2026-Q2; public video-generation API still early.

## Patterns

### Pattern: text-to-image

```python
result = client.images.generate(
    model="gpt-image-1",
    prompt="A photorealistic mountain landscape at sunrise",
    size="1024x1024",
    quality="high",
    n=1,
)
image_b64 = result.data[0].b64_json
```

### Pattern: image edit

```python
result = client.images.edit(
    model="gpt-image-1",
    image=open("original.png", "rb"),
    prompt="Change the sky to a vivid sunset",
)
```

### Pattern: variations

```python
result = client.images.create_variation(
    model="gpt-image-1",
    image=open("source.png", "rb"),
    n=4,
)
```

### Pattern: transparent background

Request transparent-background output for product photography, design assets, or compositing flows. Native to gpt-image-1.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Defaulting to DALL·E 3 for new builds | Use gpt-image-1. |
| Using gpt-image-1 to generate identifiable real people | Restricted; use specialized providers (or stay with prompts that don't reference real identities). |
| Inline base64 images in repeated API calls | Use the [Files API](/stacks/openai/files-api/) or signed URLs. |
| No moderation on user-submitted image prompts | [Moderation API](/stacks/openai/moderation-api/) at input — omni-moderation covers text + image. |
| Persisting generated images without licensing review | Usage rights vary; check OpenAI's terms for your use case. |
| Generating 1000s of variants for "creative" output without an eval | Set up an eval; brand consistency is hard at scale. |
| Trying to use gpt-image-1 for ID-document handling | OpenAI restricts; use compliant document-AI services. |

## Gotchas

- **Per-image cost is significant** compared to chat tokens. Budget carefully.
- **Latency** — image generation is multi-second per image. Plan UX.
- **Content policy** — generated images go through OpenAI's safety pipeline. Some prompts are refused; some outputs are filtered.
- **Identifiable likenesses** — restricted. Don't ask for "Tom Hanks" portraits.
- **Brand consistency** — generation varies per call. For brand-tight visuals, consider open-source diffusion + LoRA fine-tunes.
- **Output formats** — verify supported sizes + quality settings on the current API reference.
- **Async-friendly** — image generation is a good candidate for async workflows (queue + worker + push notification).

## Cross-references

### Related products in this Stack

- [Vision input](/stacks/openai/vision-input/) — image input to chat models (different surface).
- [Moderation API](/stacks/openai/moderation-api/) — omni-moderation covers image prompts.
- [Files API](/stacks/openai/files-api/) — image upload alternative.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — model selection + prompt design.
- [backend-architect](/stacks/openai/backend-architect/) — async + cost accounting.

### Authoritative sources

- [Images guide](https://platform.openai.com/docs/guides/images)
- [OpenAI Pricing](https://openai.com/api/pricing/)
- [OpenAI Usage Policies](https://openai.com/policies/usage-policies/)
