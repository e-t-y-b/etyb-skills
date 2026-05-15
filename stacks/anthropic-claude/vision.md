---
title: Vision
description: Native image input on the Messages API — base64, URL, or Files API reference. Up to ~100 images per request. For document understanding, UI screenshots, charts, diagrams.
product:
  name: Vision
  stack: anthropic-claude
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/vision
  notes: "Native image input on Messages API; size/count limits documented; Files API recommended at scale."
---

## What it is

Claude 4.x natively accepts images in the Messages API. Three input modes:

```python
# Base64-inline (fine for small one-offs, bad at scale)
{"type": "image", "source": {"type": "base64", "media_type": "image/jpeg", "data": "<base64>"}}

# URL (Claude fetches the image)
{"type": "image", "source": {"type": "url", "url": "https://..."}}

# Files API reference (best at scale — upload once, reference many times)
{"type": "image", "source": {"type": "file", "file_id": "file_..."}}
```

Per-request limits (verify current): up to 100 images, with size limits per image. See [Vision Guide](https://docs.anthropic.com/en/docs/build-with-claude/vision).

## When to use

Vision is right for:

- **OCR / document understanding** — extract text and structured data from scanned documents, forms, receipts.
- **UI screenshots** — debugging "what does the user see" questions in agents; powering [Computer Use](/stacks/anthropic-claude/computer-use/).
- **Charts / diagrams** — describe, summarize, reason about visual data; pair with [Citations](/stacks/anthropic-claude/citations/) for grounding.
- **Visual QA / classification** — identify objects, count items, validate visual states.
- **Multi-modal RAG** — retrieve image chunks alongside text; pass both to Claude.

For pure text input, don't use Vision — it's slower and more expensive than text-only.

## 2025-2026 currency anchors

- **Native multi-image in a single request.** Up to ~100 images (verify current limit).
- **Three input modes:** base64, URL, [Files API](/stacks/anthropic-claude/files-api/) reference. Files API is the path at scale.
- **Image tokens count toward context window** at a documented rate per resolution (verify).
- **Cache invalidation** — image bytes in the cached prefix mean exact-byte matching is required for cache hits. Push images after the breakpoint when they change per request.

## Patterns + anti-patterns

### Pattern — Vision + tool use for structured extraction

Send the page image; ask for extraction via a tool with a typed schema. Don't ask for "the text" — ask for the specific fields you need (`invoice_number`, `total_amount`, `line_items[]`).

### Pattern — Files API for repeated reference

Upload an image once; reference by `file_id` across 50 requests. Eliminates 50x the base64 transfer overhead.

### Pattern — pair with Citations for grounded visual responses

For document understanding where users need to know "where did this come from" — Vision + [Citations](/stacks/anthropic-claude/citations/) provides span/region attribution.

### Anti-pattern — resizing to extremes

Claude scales images internally. A 4K screenshot doesn't help more than 1080p for most tasks — you're paying for tokens that don't add value. Match resolution to the task.

### Anti-pattern — mixing high-res images with cache

Image bytes in cached prefixes mean exact match required. A slight image change (different timestamp watermark, different user UI) = cache miss. Push variable images after the cache breakpoint.

### Anti-pattern — base64-inlining a 5MB image into 100 requests

500MB transferred for content that could be uploaded once and referenced by ID. Use the [Files API](/stacks/anthropic-claude/files-api/) at any non-trivial scale.

### Anti-pattern — Vision when text would do

If your source is a PDF with extractable text, send the text — Vision pays for OCR you don't need. Reserve Vision for genuinely visual content (charts, layouts, screenshots).

## Gotchas

- **Image content invalidates [prompt caching](/stacks/anthropic-claude/prompt-caching/)** if any byte differs. Plan cache breakpoints around variable images.
- **Vision token cost** scales with image resolution. Larger images = more tokens. Resize to the smallest resolution that answers the question.
- **URL fetches happen Anthropic-side** — your images must be publicly accessible (or signed URLs that Anthropic can fetch). For private content, use Files API.
- **PDF Input ≠ Vision.** PDFs go through `document` content blocks; images through `image`. The [PDF Input](/stacks/anthropic-claude/pdf-input/) page covers PDF specifics.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — Vision is content blocks of `type: image`
- [PDF Input](/stacks/anthropic-claude/pdf-input/) — PDF-specific input
- [Files API](/stacks/anthropic-claude/files-api/) — upload once, reference many
- [Computer Use](/stacks/anthropic-claude/computer-use/) — Vision underpins screen driving
- [Citations](/stacks/anthropic-claude/citations/) — grounded visual responses
- [Vision Guide](https://docs.anthropic.com/en/docs/build-with-claude/vision)
