---
title: Stored Completions
description: "Persist completions server-side with `store: true`. Required for the Eval Platform + Distillation Platform pipelines that turn production traffic into training data."
product:
  name: Stored Completions
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, security-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/distillation
  notes: "Foundation for Eval + Distillation Platform; retention separate from default abuse-monitoring; ZDR considerations apply."
---

## What it is

Pass `store: true` on a [Chat Completions](/stacks/openai/chat-completions/) or [Responses API](/stacks/openai/responses-api/) request and the completion is persisted server-side. Stored completions are the input to the [Eval Platform](/stacks/openai/eval-platform/) and the [Distillation Platform](/stacks/openai/distillation-platform/).

This is **distinct from default abuse-monitoring retention** (30-day rolling, applied to all requests). Stored completions are kept until you delete them and are accessible via the OpenAI console + API for eval + fine-tuning.

Reference: [Distillation guide](https://platform.openai.com/docs/guides/distillation).

## When to use

**Use `store: true` when:**

- You want the completion available for [Eval Platform](/stacks/openai/eval-platform/) scoring.
- You're building a [Distillation Platform](/stacks/openai/distillation-platform/) pipeline — production traffic → golden subset → fine-tune.
- You want OpenAI Console access to the request / response for forensics.

**Don't set `store: true` when:**

- The request contains PII / PHI and you haven't established appropriate data-handling controls.
- You're on a ZDR (Zero Data Retention) contract — `store: true` **opts back in** to retention even on ZDR endpoints.
- You don't have a use for the stored data downstream (it adds retention liability without benefit).

## 2025-2026 currency anchors

- **Foundation for the [Eval Platform](/stacks/openai/eval-platform/)** — datasets can be sourced directly from stored completions.
- **Foundation for the [Distillation Platform](/stacks/openai/distillation-platform/)** — golden-subset fine-tuning data comes from stored completions.
- **ZDR + `store: true` interplay** — even with ZDR negotiated, `store: true` overrides for that specific request. Be deliberate.
- **Metadata tagging.** Tag stored completions with `metadata: {feature: ..., tenant: ..., env: ...}` for downstream filtering in eval/distillation.
- **Console access** — stored completions are visible in OpenAI Platform Logs in the console; useful for incident response and audit.

## Patterns

### Pattern: tag stored completions with metadata

```python
response = client.chat.completions.create(
    model="gpt-5",
    messages=[...],
    store=True,
    metadata={
        "feature": "ticket_classification",
        "tenant": tenant_id,
        "env": "prod",
        "version": prompt_version,
    },
)
```

Metadata lets you filter in Eval + Distillation pipelines later. Tag aggressively.

### Pattern: distillation loop

```
1. Production: GPT-5 Standard on hard task, store: true, metadata tagged.
2. Eval Platform: filter stored completions; LLM-as-judge to mark golden.
3. Export golden subset as fine-tune dataset.
4. Distillation Platform: fine-tune GPT-5 Nano on the golden set.
5. Eval the fine-tuned model on the same dataset.
6. Deploy when within X% of baseline at Y% of cost.
```

Stored completions are the linchpin of this loop.

### Pattern: selective storage

Don't store every completion. Sample-based storage at a known ratio (10-30%) is sufficient for eval and distillation; full storage is unnecessary cost + liability.

```python
import random
should_store = random.random() < 0.2  # 20% sample rate
response = client.chat.completions.create(..., store=should_store, ...)
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| `store: true` on every request without a downstream use | Either define the use (eval / distillation) or set `store: false`. |
| `store: true` with PII in the prompt and no controls | Redact PII before send; or `store: false`; or audit-scoped storage path only. |
| `store: true` on a ZDR endpoint contractually for sensitive data | `store: false`. ZDR + `store: true` defeats the ZDR posture. |
| Storing without metadata tags | Tag. Untagged stored completions are hard to filter / use. |
| Storing 100% in high-volume systems with no distillation plan | Sample. |
| Treating stored completions as ephemeral | They persist until deleted. Build deletion + retention policy. |

## Gotchas

- **ZDR override.** `store: true` opts back in. Be explicit about which requests are eligible.
- **No automatic deletion.** Stored completions persist until deleted via API or console. Build a deletion + retention policy.
- **Cost.** Storage itself is included; what costs is the downstream Eval + Distillation usage.
- **PII liability.** Every stored completion is a record. Treat as data-controller obligation.
- **Multi-tenant care.** Tag with tenant ID; access controls in your console limit who can view.
- **`store: true` does not appear in usage.** Token billing is unchanged; the difference is retention behavior.

## Cross-references

### Related products in this Stack

- [Eval Platform](/stacks/openai/eval-platform/) — consumes stored completions as datasets.
- [Distillation Platform](/stacks/openai/distillation-platform/) — chains Stored Completions → Evals → Fine-tuning.
- [Chat Completions API](/stacks/openai/chat-completions/) / [Responses API](/stacks/openai/responses-api/) — where `store: true` is set.
- [Audit Logs](/stacks/openai/audit-logs/) — for compliance posture around stored data.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — distillation loop design.
- [security-engineer](/stacks/openai/security-engineer/) — retention policy, ZDR interaction.

### Authoritative sources

- [Distillation guide](https://platform.openai.com/docs/guides/distillation)
- [Eval Platform docs](https://platform.openai.com/docs/guides/evals)
