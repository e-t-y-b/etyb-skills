---
title: Moderation API
description: omni-moderation-latest. Multimodal (text + image). Free + fast. Mandatory at the input boundary for user-generated content pipelines.
product:
  name: Moderation API
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, ai-ml-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/moderation
  notes: "omni-moderation-latest is multimodal (text + image); replaces text-moderation-latest as default; categories + thresholds evolve."
---

## What it is

Endpoint `/v1/moderations` classifies content against OpenAI's policy categories. Two model classes:

- **omni-moderation-latest** — multimodal (text + image). Production default 2026.
- **text-moderation-latest** — legacy text-only.

Returns per-category `flagged: true/false` plus `category_scores: float[0,1]`.

**Free and fast.** No excuse not to use it.

Reference: [Moderation guide](https://platform.openai.com/docs/guides/moderation).

## When to use

**Use omni-moderation at:**

1. **Input boundary** — moderate every user-provided prompt before it reaches the LLM. If the user is trying to elicit unsafe content, refuse early.
2. **Retrieved RAG context** — moderate retrieved chunks if they include UGC. Indirect prompt-injection comes from documents.
3. **Output boundary (optional)** — moderate model output before serving to the user; second-pass safety check.

**Don't moderate after a refusal** — the refusal itself is the safe response. Moderating it as if it were unsafe content is wrong.

**Use a domain-specific second pass when:** Moderation API doesn't cover your domain (medical advice, legal advice, brand safety, profanity rules). Build a custom filter on top.

## 2025-2026 currency anchors

- **omni-moderation-latest** is multimodal — text + image inputs.
- **Free** — no per-call cost on Moderation.
- **Mandatory for UGC pipelines.** Skipping moderation on user-submitted prompts is a policy + safety risk.
- **Categories** (current):
  - harassment, harassment/threatening
  - hate, hate/threatening
  - illicit, illicit/violent
  - self-harm, self-harm/intent, self-harm/instructions
  - sexual, sexual/minors
  - violence, violence/graphic
- **Category thresholds tune per use case.** Don't accept defaults blindly; tune for false positive rate.

## Patterns

### Pattern: input boundary moderation

```python
mod = client.moderations.create(model="omni-moderation-latest", input=user_text)
if mod.results[0].flagged:
    if mod.results[0].categories.get("hate") or mod.results[0].categories.get("sexual/minors"):
        # Hard block
        block_and_alert(user_id, mod.results[0])
        return refusal_response()
    else:
        # Soft route
        return restricted_model_response()
# Otherwise proceed to LLM
```

### Pattern: retrieved-content moderation

For RAG over UGC sources (forum posts, customer-submitted docs), moderate retrieved chunks before injecting into the model's context. Indirect prompt injection often hides in retrieved content.

### Pattern: tiered response

- **Block + alert** — input flagged for hate / sexual/minors / self-harm-instructions.
- **Soft route** — ambiguous categories; invoke a less-permissive model or restrict tool access.
- **Allow** — clean input; proceed.

### Pattern: image moderation

```python
mod = client.moderations.create(
    model="omni-moderation-latest",
    input=[
        {"type": "text", "text": user_caption},
        {"type": "image_url", "image_url": {"url": image_url}},
    ],
)
```

User-submitted images get the same treatment as text.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| No moderation on user-submitted prompts | Mandatory. Add at the input boundary. |
| Using text-moderation-latest in 2026 | Switch to omni-moderation-latest (multimodal). |
| Hard-blocking on every flagged category | Tune per category; not all flags warrant a block. |
| Moderating model output as if a refusal were unsafe content | Refusals are the safe response. Don't double-flag. |
| Relying on Moderation API for domain-specific rules (medical, legal, brand) | Build a second-pass filter for your domain. |
| No alerting on repeated flagged input from one user | Log + alert; suspicious actors should be flagged for review. |
| Storing flagged content unredacted | Treat as sensitive; redact in logs. |

## Gotchas

- **False positives are common.** Tune category thresholds.
- **Doesn't catch every domain-specific issue.** Medical/legal advice, regulated content, brand safety need custom filters.
- **`omni-moderation` ≠ general LLM safety guardrails.** It classifies content; it doesn't decide downstream action. That's your business logic.
- **Cost is free** — there's no excuse not to call it.
- **Latency is low** — typically <500ms.
- **Rate limits** apply per tier.
- **Image moderation** requires the image to be accessible (URL or base64).

## Cross-references

### Related products in this Stack

- [Chat Completions API](/stacks/openai/chat-completions/) / [Responses API](/stacks/openai/responses-api/) — moderate inputs before sending.
- [Built-in tools](/stacks/openai/built-in-tools/) — moderate retrieved content from `web_search` / `file_search`.
- [Image generation](/stacks/openai/image-generation/) — moderate prompts before generating.
- [Computer Use](/stacks/openai/computer-use/) — moderate observed page content before feeding back.
- [Realtime API](/stacks/openai/realtime-api/) — moderate transcripts per turn.

### Role overlays

- [security-engineer](/stacks/openai/security-engineer/) — moderation placement strategy.
- [backend-architect](/stacks/openai/backend-architect/) — moderation in the request pipeline.
- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — moderation as a guardrail in agent design.

### Authoritative sources

- [Moderation guide](https://platform.openai.com/docs/guides/moderation)
- [OpenAI Usage Policies](https://openai.com/policies/usage-policies/)
