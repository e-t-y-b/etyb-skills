---
title: Veo
description: Google's video generation model on Vertex AI — Veo 3 for text-to-video and image-to-video; SynthID watermark on output.
product:
  name: Veo
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/vertex-ai/generative-ai/docs/video/overview
  notes: "Veo 3 is current as of 2026-05; text-to-video and image-to-video; SynthID watermark; via Vertex AI Video Generation API."
---

## What it is

Veo is Google's video generation model on [Vertex AI](/stacks/gcp/vertex-ai/). **Veo 3** is current in 2026 Q2 — text-to-video and image-to-video, with SynthID watermark on output.

Authoritative reference: [cloud.google.com/vertex-ai/generative-ai/docs/video/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/video/overview).

## When to use

Pick Veo when:
- Short-form video generation in a creative product
- Marketing creative pipelines
- Storyboard / animatic generation from text

Don't pick Veo when:
- Live-action video needs are the requirement — Veo is generative
- Sensitive content generation without moderation — abuse risk

## 2025-2026 currency anchors

- **Veo 3** is current; supports text-to-video and image-to-video.
- **SynthID watermark** on all outputs.
- **Duration limits** apply per generation; verify against current docs.

## Patterns

Generate video from text via the Vertex AI SDK; outputs land in [Cloud Storage](/stacks/gcp/cloud-storage/). The API is long-running — submit, poll, retrieve.

## Anti-patterns

- **No content moderation** on user-provided prompts — abuse vector.
- **Treating Veo output as ready-to-publish** without review — generative artifacts are common.

## Gotchas

- **Long-running operation** — submit job, poll status, retrieve result. Not synchronous request-response.
- **Quota** is limited; request increases for production volume.
- **Pricing** per second of generated video; budget for iteration cycles.

## Cross-references

- Related: [Vertex AI](/stacks/gcp/vertex-ai/), [Imagen](/stacks/gcp/imagen/), [Cloud Storage](/stacks/gcp/cloud-storage/)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/vertex-ai/generative-ai/docs/video/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/video/overview)
