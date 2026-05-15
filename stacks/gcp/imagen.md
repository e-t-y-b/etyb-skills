---
title: Imagen
description: Google's image generation model on Vertex AI — Imagen 4 for text-to-image, image editing, style transfer; SynthID watermark.
product:
  name: Imagen
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/vertex-ai/generative-ai/docs/image/overview
  notes: "Imagen 4 is current as of 2026-05; SynthID watermark on all outputs; via Vertex AI Image Generation API."
---

## What it is

Imagen is Google's text-to-image generation model, served via [Vertex AI](/stacks/gcp/vertex-ai/). **Imagen 4** is current in 2026 Q2 — text-to-image, image editing, style transfer, in-painting. All outputs carry the **SynthID** watermark for provenance verification.

Authoritative reference: [cloud.google.com/vertex-ai/generative-ai/docs/image/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/image/overview).

## When to use

Pick Imagen when:
- Text-to-image generation in a SaaS product
- Image editing / variation features
- Need SynthID watermark for verifiable provenance

Don't pick Imagen when:
- A photo library / stock service covers it
- The use case is sensitive (image of person, public figure, etc.) without safety review

## 2025-2026 currency anchors

- **Imagen 4** is the current generation as of Q2 2026.
- **SynthID watermark** on all outputs; survives transformations.
- **Edit / inpaint / outpaint** capabilities; mask-driven editing.

## Patterns

```python
from google import genai

client = genai.Client(vertexai=True, project="my-project", location="us-central1")

response = client.models.generate_images(
    model="imagen-4.0-generate-001",
    prompt="A photorealistic widget on a wooden table, soft natural lighting",
    config={"number_of_images": 4, "aspect_ratio": "16:9"},
)
for img in response.generated_images:
    img.save("widget.png")
```

## Anti-patterns

- **No safety filter** on user-generated prompts — moderation should be policy + filter.
- **Treating SynthID as full provenance** — useful but not unbreakable; not a substitute for content moderation.

## Gotchas

- **Quota** is modest by default; request increases for high-volume.
- **Latency** is seconds per image; not real-time.
- **Pricing** per image; budget accordingly.

## Cross-references

- Related: [Vertex AI](/stacks/gcp/vertex-ai/), [Veo](/stacks/gcp/veo/), [Gemini](/stacks/gcp/gemini/) (multimodal input)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/vertex-ai/generative-ai/docs/image/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/image/overview)
