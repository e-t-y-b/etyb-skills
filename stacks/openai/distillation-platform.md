---
title: Distillation Platform
description: Console product launched 2025. Chains Stored Completions → Eval Platform → fine-tuning. The OpenAI-native loop for "big model in dev, fine-tuned smaller model in prod."
product:
  name: Distillation Platform
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/distillation
  notes: "Console product 2025; chains three coupled products (Stored Completions → Evals → Fine-tuning); surface is new and shifting."
---

## What it is

The Distillation Platform is OpenAI's managed distillation pipeline. It chains three existing platform products into one console-driven loop:

1. **[Stored Completions](/stacks/openai/stored-completions/)** — production traffic stored server-side.
2. **[Eval Platform](/stacks/openai/eval-platform/)** — filter + score stored completions; mark a golden subset.
3. **Fine-tuning** — train a smaller model on the golden subset.

The killer pattern: run GPT-5 Standard or Pro in production for a high-value task, store completions, mark golden examples, fine-tune GPT-5 Nano / Mini / 4o-mini → deploy fine-tuned smaller model at a fraction of the cost with near-equivalent quality.

Reference: [Distillation guide](https://platform.openai.com/docs/guides/distillation).

## When to use

**Use the Distillation Platform when:**

- You have a high-volume task where GPT-5 Standard / Pro is the right quality but cost is dominating.
- Production traffic provides 1000+ examples of the task being done well.
- You want to ship a fine-tuned smaller model that approximates the larger model's quality at smaller cost.
- You're committed to OpenAI (the distillation flow is OpenAI-internal).

**Don't use distillation when:**

- You have <100 high-quality examples — fine-tuning quality floor is not met.
- The task requires fresh data — fine-tuning bakes in training-time knowledge; RAG is the answer for fresh data.
- You haven't proven prompting + few-shot can't get you there at lower cost.
- The task evolves rapidly — fine-tuning lags; you'll be re-distilling frequently.

## 2025-2026 currency anchors

- **Console product launched 2025**, with API access.
- **Three-product loop** — Stored Completions + Eval Platform + Fine-tuning, surfaced as one experience.
- **Fine-tuning target models** — GPT-4o-mini, GPT-4o, GPT-4.1; GPT-5 fine-tuning is rolling out in stages (verify).
- **DPO + SFT + Vision fine-tuning** all supported in the underlying fine-tuning surface.
- **Distillation Platform automates much of the manual work** that distillation previously required.

## Patterns

### Pattern: the 2026 distillation loop

```
1. Production: GPT-5 Standard / Pro with store: true + metadata tagged.
2. Tag a subset as "golden":
     - Manual review (small batches).
     - LLM-as-judge filter (Eval Platform grader → score >= threshold).
3. Push the golden set as a fine-tune training dataset.
4. Fire a fine-tune job on a smaller model (GPT-5 Nano / 4o-mini).
5. Re-run evals on the fine-tuned smaller model. Compare against the baseline.
6. Deploy the fine-tuned smaller model when it's within X% of baseline quality at Y% of cost.
```

This is the canonical pattern. Distillation Platform automates steps 2-5; you wire 1 + 6.

### Pattern: production deployment with fallback

The fine-tuned smaller model in production; the larger model as a fallback:

```
User request → Fine-tuned smaller model
              If confidence low / structured output fails:
                Escalate to GPT-5 Standard
              Log both responses for the next training round
```

### Pattern: distillation cadence

- **Initial distillation** — 1000+ examples, run once.
- **Refresh cadence** — quarterly or when production drift is detected.
- **Eval-gated deploy** — never deploy a distillation without eval improvement vs the existing fine-tune.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Distilling without enough examples (<100) | Wait until you have 1000+ tagged golden examples. |
| Distilling on tasks where fresh data matters | Use RAG instead. |
| Skipping eval before deploying the fine-tune | Always eval. Fine-tuning can regress. |
| Distilling without metadata tags on Stored Completions | You can't filter the golden subset without metadata. |
| Distilling on PII without sanitization | Strip PII before fine-tune. |
| Treating distillation as a one-time job | Refresh quarterly or on production drift. |
| Distilling without a fallback to the larger model | Build the fallback. |

## Gotchas

- **Surface is new.** Verify console + API shape against current docs.
- **Fine-tune target models** matter. GPT-4o-mini is the common target; GPT-5 fine-tuning rollout is staged.
- **Eval lift is real but not always large.** Sometimes prompting + few-shot is within 5% of fine-tune at zero training cost.
- **Fine-tuning cost** is per-token-trained; verify on [pricing](https://openai.com/api/pricing/).
- **Hosted fine-tuned models** have their own per-token serving rates.
- **Privacy** — training data is OpenAI-stored. PII review before submitting.

## Cross-references

### Related products in this Stack

- [Stored Completions](/stacks/openai/stored-completions/) — source data for distillation.
- [Eval Platform](/stacks/openai/eval-platform/) — score + filter the golden subset.
- [GPT-5 family](/stacks/openai/gpt-5/) — distillation source (Standard / Pro).
- [Vision fine-tuning](/stacks/openai/vision-fine-tuning/) — for multimodal distillation.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — distillation pipeline design.

### Authoritative sources

- [Distillation guide](https://platform.openai.com/docs/guides/distillation)
- [Fine-tuning guide](https://platform.openai.com/docs/guides/fine-tuning)
- [Eval Platform guide](https://platform.openai.com/docs/guides/evals)
