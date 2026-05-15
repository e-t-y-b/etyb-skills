---
title: Vision fine-tuning
description: Supervised fine-tuning on GPT-4o for image+text tasks. Pair image/text training pairs to specialize on visual extraction or classification.
product:
  name: Vision fine-tuning
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/fine-tuning
  notes: "GA on GPT-4o for image+text training; SFT/DPO surfaces evolving; verify target-model availability against current fine-tuning docs."
---

## What it is

Supervised fine-tuning on GPT-4o (and select other models) where training data includes images alongside text. The model learns visual patterns specific to your domain — invoice layouts, product photos, document templates, medical imaging conventions (with appropriate compliance posture).

Reference: [Fine-tuning guide](https://platform.openai.com/docs/guides/fine-tuning).

## When to use

**Use vision fine-tuning when:**

- Default vision quality is below your domain bar (e.g., extracting specific invoice fields with variable layouts).
- You have 100+ image+text training pairs.
- Prompting + few-shot + structured output can't get you to the quality bar.
- The task is narrow enough that fine-tuning specialization pays off.

**Don't use vision fine-tuning when:**

- Default [Vision input](/stacks/openai/vision-input/) on GPT-5 / GPT-4.1 / GPT-4o is good enough.
- You have <100 training examples.
- The task evolves rapidly — fine-tuning bakes in training-time knowledge.
- A specialized OCR / document-AI service (Azure Document Intelligence, AWS Textract) would be cheaper + more accurate.

## 2025-2026 currency anchors

- **GA on GPT-4o** for image+text training.
- **DPO + SFT** both supported on chat models; verify vision-specific DPO availability.
- **Training data format** — JSONL with image+text messages; verify the exact schema against current docs.
- **Fine-tuned model serving** has its own per-token rate; verify.
- **Integrates with [Distillation Platform](/stacks/openai/distillation-platform/)** for vision distillation flows.

## Patterns

### Pattern: invoice field extraction

```
1. Collect 500+ invoice images with hand-labeled (or LLM-labeled-then-reviewed) field extractions.
2. Format as JSONL: each line has the image + text prompt + expected extraction.
3. Fire fine-tune job on GPT-4o.
4. Eval on held-out set; compare to base GPT-4o with structured output.
5. Deploy fine-tune if eval improves materially.
```

### Pattern: vision distillation

Combine with [Distillation Platform](/stacks/openai/distillation-platform/) — run GPT-5 with vision in production, store completions with image+output, filter golden, fine-tune a smaller vision model. Reduce cost on high-volume document workflows.

### Pattern: hybrid fine-tune + RAG

Fine-tune the vision model on **layout patterns** + use RAG for **fresh domain context** (e.g., new product names introduced after training). Fine-tuning bakes layout understanding; RAG handles fresh data.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Vision fine-tune without trying [Vision input](/stacks/openai/vision-input/) + [Structured Outputs](/stacks/openai/structured-outputs/) first | Try the cheap path first. Fine-tune only if it can't reach the bar. |
| <100 training examples | Wait until you have more. Quality floor isn't met. |
| Training data with PII not sanitized | Sanitize first; fine-tunes can regurgitate training data. |
| Replacing specialized OCR with vision fine-tune at scale | Specialized OCR is often cheaper + more accurate for narrow tasks. |
| No eval before deploying the fine-tune | Always eval against held-out + production samples. |
| Fine-tuning on tasks that evolve weekly | Fine-tuning lag will hurt. Use RAG. |

## Gotchas

- **Training data cost** — verify per-token training cost on [pricing](https://openai.com/api/pricing/).
- **Fine-tuned model serving cost** is separate from training cost.
- **Image token counting** in training data follows same rules as inference — high-detail images cost more.
- **Privacy** — training images and labels are OpenAI-stored. Sanitize PII; restrict access.
- **Target model availability** — vision fine-tuning may not cover all model variants. Verify current support.
- **DPO with images** — verify support; surface may lag SFT.
- **Reproducibility** — fine-tune jobs have a seed; same data + seed = reproducible model.

## Cross-references

### Related products in this Stack

- [Vision input](/stacks/openai/vision-input/) — the inference-side surface (no fine-tuning required).
- [Structured Outputs](/stacks/openai/structured-outputs/) — pair with vision fine-tunes for schema-bound extraction.
- [Distillation Platform](/stacks/openai/distillation-platform/) — for vision distillation flows.
- [Files API](/stacks/openai/files-api/) — training data upload.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — fine-tuning decision + design.

### Authoritative sources

- [Fine-tuning guide](https://platform.openai.com/docs/guides/fine-tuning)
- [Vision guide](https://platform.openai.com/docs/guides/vision)
