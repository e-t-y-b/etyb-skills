---
title: Predicted Outputs
description: "Pre-supply expected output as a `prediction` field to accelerate generation. Discount on matching tokens. Relevant for code-edit, refactor, and document-update workflows."
product:
  name: Predicted Outputs
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/predicted-outputs
  notes: "Stable surface since 2024-2025; pairs especially well with GPT-4.1 for code-edit pipelines."
---

## What it is

Predicted Outputs ships a pre-supplied expected output along with the request, as a `prediction` field. The model uses it as a strong hint and skips ahead on matching tokens. Output tokens that match the prediction are billed at a discount; tokens that diverge are billed at full price.

Reference: [Predicted Outputs guide](https://platform.openai.com/docs/guides/predicted-outputs).

## When to use

**Use Predicted Outputs when:**

- Most of the output is **known up front** and the model is making targeted changes.
- Code edit pipelines — "here's the original file, please apply this change" with the original file as the prediction.
- Refactor flows where the model makes small targeted changes to a large file.
- Document update tasks — edit a contract, regenerate a section.
- Diff / patch generation where the model produces a modified version of input.

**Don't use Predicted Outputs when:**

- Generation is free-form (creative writing, novel summaries).
- The output is mostly different from any known prediction.
- The prediction is short — the overhead doesn't pay off.

## 2025-2026 currency anchors

- **Stable surface** since launch — no recent shape changes.
- **Pairs especially well with [GPT-4.1](/stacks/openai/gpt-4-1/)** for code-edit pipelines — GPT-4.1 is code-optimized.
- **Token billing** — matching tokens at discount; diverging tokens at full output rate.
- **Works on [Chat Completions](/stacks/openai/chat-completions/) and [Responses API](/stacks/openai/responses-api/).**

## Patterns

### Pattern: code-edit pipeline

```python
original_file = read_file(path)
response = client.chat.completions.create(
    model="gpt-4.1",
    messages=[
        {"role": "system", "content": "Apply the user's edit to the file. Return the full file."},
        {"role": "user", "content": f"File:\n{original_file}\n\nEdit: {edit_instruction}"},
    ],
    prediction={"type": "content", "content": original_file},
)
new_file = response.choices[0].message.content
```

Model returns the modified file; matching tokens billed at discount.

### Pattern: section regeneration

```python
response = client.chat.completions.create(
    model="gpt-5-mini",
    messages=[...],
    prediction={"type": "content", "content": current_doc_content},
)
```

For doc-update flows where 90% of the doc is unchanged.

### Pattern: with Structured Outputs

Combine with [Structured Outputs](/stacks/openai/structured-outputs/) `strict: true` for JSON-formatted edits — the prediction hints at the expected JSON shape; strict mode constrains it.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Predicted Outputs on free-form generation | Don't. The overhead doesn't pay off. |
| Prediction that diverges 50%+ from final output | Likely no savings; check eval. |
| Prediction much longer than necessary | Trim. Shorter predictions transfer less data. |
| Not measuring matched-token rate | Log `usage` to track savings. |
| Combining with `temperature: high` | Defeats the prediction signal. Lower temperature is usually better for edit flows. |

## Gotchas

- **Discount applies only to matching output tokens.** Diverging tokens are billed at full output rate.
- **Doesn't accelerate generation beyond what the model can produce token-for-token** — it skips ahead on matches but doesn't change underlying inference cost when divergence happens.
- **Input tokens** for the prediction count against your prompt-token budget.
- **Best with [GPT-4.1](/stacks/openai/gpt-4-1/) for code** — eval-test on your workload before committing.

## Cross-references

### Related products in this Stack

- [GPT-4.1](/stacks/openai/gpt-4-1/) — pairs well with code-edit flows.
- [Chat Completions API](/stacks/openai/chat-completions/) / [Responses API](/stacks/openai/responses-api/) — supports Predicted Outputs.
- [Structured Outputs](/stacks/openai/structured-outputs/) — compose for structured edits.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — when Predicted Outputs is the right pattern.
- [backend-architect](/stacks/openai/backend-architect/) — request shape + cost telemetry.

### Authoritative sources

- [Predicted Outputs guide](https://platform.openai.com/docs/guides/predicted-outputs)
