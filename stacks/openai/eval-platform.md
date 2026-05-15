---
title: Eval Platform
description: "Console product launched 2025. Datasets, graders, runs — replaces the legacy `openai-evals` repo for most use cases. Integrate into CI to gate regressions."
product:
  name: Eval Platform
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, qa-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/evals
  notes: "Console + API; replaces legacy openai-evals repo for most use cases; surface UI + API both moving — verify against current docs."
---

## What it is

The Eval Platform is OpenAI's console-hosted eval product. Build evals as:

- **Datasets** — input / expected-output pairs, optionally with metadata.
- **Graders** — scoring functions: string equality, semantic similarity, model-graded (LLM-as-judge), regex, custom Python.
- **Runs** — combine a dataset + a model + a grader. Get aggregate scores + per-example breakdowns.

It replaces the legacy [`openai-evals`](https://github.com/openai/evals) repo for most use cases. The repo is still around for advanced/custom evals, but the console + API is the recommended surface.

Reference: [Eval Platform guide](https://platform.openai.com/docs/guides/evals).

## When to use

**Use the Eval Platform when:**

- You want CI-blocking eval gates on prompt changes / model changes.
- You're running LLM-as-judge graders against your domain.
- You want a managed dataset → grader → run pipeline without building your own.
- You're sourcing eval datasets from [Stored Completions](/stacks/openai/stored-completions/).
- You're integrating with the [Distillation Platform](/stacks/openai/distillation-platform/) loop.

**Use external alternatives when:**

- You need cross-provider eval (Promptfoo, DeepEval, Braintrust, LangSmith).
- You want deeply custom Python eval logic that doesn't fit OpenAI's grader model.
- You want self-hosted eval infrastructure for compliance.

## 2025-2026 currency anchors

- **Console product launched 2025**, with API access.
- **Replaces the legacy `openai-evals` repo** for most use cases.
- **Stored Completions** ([Stored Completions](/stacks/openai/stored-completions/)) are a primary dataset source.
- **LLM-as-judge graders** are first-class — use GPT-5 Standard or Pro as judge, with a rubric.
- **Integrates with Distillation** — eval output filters Stored Completions into golden datasets for fine-tuning.
- **[Batch API](/stacks/openai/batch-api/) integration** for eval runs at 50% off.

## Patterns

### Pattern: regression eval per feature

Whenever you ship a prompt change, the eval runs in CI. Score below baseline = build fails.

```
1. Define dataset: 50-500 (input, expected) pairs covering core flows + edge cases.
2. Define grader: schema validity / semantic match / LLM-as-judge with rubric.
3. Wire CI: on PR, run eval; compare to baseline; block if regression > threshold.
```

### Pattern: stored-completions → eval dataset

Use production traffic as the eval dataset source:

```
1. Production runs with store: true + metadata tagged.
2. Eval Platform pulls Stored Completions filtered by metadata.
3. Reviewer marks subset as golden (manual or LLM-as-judge with rubric).
4. Golden set becomes the regression eval dataset.
```

This is more honest than hand-curated datasets — eval reflects actual usage.

### Pattern: LLM-as-judge with rubric

Don't grade with a single score; grade on rubric (clarity, completeness, citation, schema validity, tool selection). Multi-criteria > single score.

```python
grader_prompt = """
Rate the response on:
- clarity (1-5)
- completeness (1-5)
- citation accuracy (1-5)
- schema validity (pass/fail)
Return JSON: {"clarity": ..., "completeness": ..., ...}
"""
```

### Pattern: graders per claim category

- **Structured output validity** — does the JSON parse? Match the schema?
- **Tool selection accuracy** — did the agent pick the right tool?
- **Tool argument correctness** — did it call with the right args?
- **Final answer quality** — LLM-as-judge on rubric.
- **Cost + latency** — within budget per turn?

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Eval-by-vibes ("looks good to me on the demo prompt") | Build eval datasets + graders + CI gates. |
| Hand-curated eval dataset disconnected from production traffic | Source from [Stored Completions](/stacks/openai/stored-completions/). |
| Single-score grader | Multi-criteria rubric grader. |
| LLM-as-judge using the same model under eval | Use a stronger judge model (GPT-5 Pro or Standard) than the model under eval. |
| No CI gate on eval regression | Wire it. Block merges on score drop. |
| Evaluating only on happy path | Include edge cases + adversarial inputs. |
| Skipping eval after model snapshot rollover | Re-eval whenever the upstream snapshot moves. |

## Gotchas

- **LLM-as-judge has bias.** Validate the judge against human-graded samples before trusting at scale.
- **Eval run cost** — graders consume model calls. Use [Batch API](/stacks/openai/batch-api/) for cost (50% off).
- **Score drift** — same dataset can score differently across model snapshots. Pin model snapshots in production eval; allow drift in dev.
- **Eval coverage** — small datasets miss edge cases. Aim for hundreds of examples covering production distribution.
- **Dataset privacy** — datasets may contain PII; treat as sensitive.
- **UI + API both move.** Verify against current docs.

## Cross-references

### Related products in this Stack

- [Stored Completions](/stacks/openai/stored-completions/) — eval dataset source.
- [Distillation Platform](/stacks/openai/distillation-platform/) — uses eval output to filter golden subset.
- [Batch API](/stacks/openai/batch-api/) — eval runs at 50% off.
- [Agents Platform](/stacks/openai/agents-platform/) — trace inspection of agent runs.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — eval design + integration into CI.

### Authoritative sources

- [Eval Platform guide](https://platform.openai.com/docs/guides/evals)
- [Legacy openai-evals repo](https://github.com/openai/evals)
- [Stored Completions / Distillation guide](https://platform.openai.com/docs/guides/distillation)
