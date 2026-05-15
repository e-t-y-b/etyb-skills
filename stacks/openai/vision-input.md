---
title: Vision input
description: "Multimodal image input as `image_url` content parts. Supported on GPT-4o, GPT-4.1, GPT-5. Per-image token costs apply."
product:
  name: Vision input
  stack: openai
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/vision
  notes: "Stable mechanism; image tokenization model unchanged through 2025-2026. Distinguish from Vision fine-tuning."
---

## What it is

Pass images alongside text by including `image_url` parts in your message content. Supported across the modern OpenAI model lineup — GPT-4o, GPT-4o-mini, [GPT-4.1](/stacks/openai/gpt-4-1/), [GPT-5 family](/stacks/openai/gpt-5/).

Images can be passed as either:

- **Inline base64** — convenient for small images, blows token budget for large.
- **URL** — public or signed URL the model fetches.
- **[Files API](/stacks/openai/files-api/) reference** — upload first, reference by file ID.

Reference: [Vision guide](https://platform.openai.com/docs/guides/vision).

## When to use

**Use Vision input when:**

- The task requires visual understanding — document OCR + extraction, screenshot analysis, chart interpretation, image classification, accessibility descriptions.
- The model needs to reference visual context in addition to text.

**Don't use Vision input for:**

- Image generation (use [Image generation](/stacks/openai/image-generation/) — gpt-image-1).
- Pure OCR where a specialized model is cheaper and more accurate (Azure Document Intelligence, AWS Textract).
- Real-time video streams (the surface is single-image input per turn, not video).

## 2025-2026 currency anchors

- **All current chat models support vision** — GPT-4o, GPT-4.1, GPT-5 family. The `image_url` content part is the common shape.
- **`detail` parameter** — `low` / `high` / `auto`. Low detail = lower token cost + faster; high detail = better quality.
- **Per-image token costs apply.** Image tokens count against your `prompt_tokens` budget.
- **Token-counting formula** varies by `detail` setting; small/low images can be ~85 tokens, large/high can be 1000+ tokens.
- **Distinct from [Vision fine-tuning](/stacks/openai/vision-fine-tuning/)** — vision input is using a model with images at inference time; vision fine-tuning is training on image+text pairs.
- **Computer Use](/stacks/openai/computer-use/) uses vision input under the hood** — each screenshot is a vision input.

## Patterns

### Pattern: image + question

```python
response = client.chat.completions.create(
    model="gpt-5",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "What is in this image?"},
            {"type": "image_url", "image_url": {"url": image_url, "detail": "high"}},
        ],
    }],
)
```

### Pattern: image via Files API

```python
file = client.files.create(file=open("doc.png", "rb"), purpose="vision")
response = client.chat.completions.create(
    model="gpt-5",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Extract invoice fields"},
            {"type": "image_file", "image_file": {"file_id": file.id}},
        ],
    }],
)
```

### Pattern: structured output from vision

Pair vision input with [Structured Outputs](/stacks/openai/structured-outputs/) `strict: true` for extraction pipelines:

```python
response = client.chat.completions.create(
    model="gpt-5",
    messages=[image_message],
    response_format={"type": "json_schema", "json_schema": {"name": "Invoice", "strict": True, "schema": Invoice.model_json_schema()}},
)
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Sending huge images base64-inline | Upload via [Files API](/stacks/openai/files-api/) or URL. |
| `detail: "high"` for thumbnail images | `detail: "low"` — saves tokens. |
| Vision for pure OCR at scale | Specialized OCR service is cheaper and more accurate. |
| Streaming video through vision (frame by frame, every frame) | Sample frames; OpenAI vision is per-image, not video. |
| Not measuring image tokens in `usage` | Capture; image tokens count toward prompt budget. |
| Image URL behind auth | Model can't fetch; use signed URLs or Files API. |

## Gotchas

- **Per-image token cost** — measurable. Always check `prompt_tokens` after first request to calibrate.
- **`detail` setting** changes both cost and quality. Low can mishandle small text in images.
- **URL fetching** — model fetches the URL synchronously; behind auth = fails. Use signed URLs with short TTL, or Files API.
- **Computer Use](/stacks/openai/computer-use/) blows vision tokens fast** — every screenshot is a vision input.
- **Max images per request** — check the current API reference for limits per model.
- **Image moderation** — uploaded images go through OpenAI's safety pipeline; certain images may be rejected.
- **PII in images** — treat as PII (screenshots can contain everything visible).

## Cross-references

### Related products in this Stack

- [GPT-5 family](/stacks/openai/gpt-5/) / [GPT-4.1](/stacks/openai/gpt-4-1/) — models supporting vision.
- [Image generation](/stacks/openai/image-generation/) — generating images (gpt-image-1).
- [Vision fine-tuning](/stacks/openai/vision-fine-tuning/) — training on image+text pairs.
- [Files API](/stacks/openai/files-api/) — image upload alternative to inline base64.
- [Computer Use](/stacks/openai/computer-use/) — screenshots-as-vision-input under the hood.
- [Structured Outputs](/stacks/openai/structured-outputs/) — extract structured data from images.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — vision use-case selection.
- [backend-architect](/stacks/openai/backend-architect/) — image upload + tokens accounting.

### Authoritative sources

- [Vision guide](https://platform.openai.com/docs/guides/vision)
- [OpenAI Models Catalog](https://platform.openai.com/docs/models)
