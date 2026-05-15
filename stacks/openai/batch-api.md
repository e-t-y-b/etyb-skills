---
title: Batch API
description: 50% discount with a 24-hour SLA. Wraps Chat Completions, Embeddings, and Responses. The default home for evals, classification jobs, embedding refreshes, and bulk content generation.
product:
  name: Batch API
  stack: openai
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://platform.openai.com/docs/guides/batch
  notes: "Stable since 2024; 50% off + 24h SLA; Responses-batch went GA late 2025 — minor adjustments since."
---

## What it is

Submit a JSONL file with one request per line; OpenAI processes them at 50% discount with a 24-hour completion SLA (often completes in minutes; the SLA is the worst case). Receive a JSONL with one response per line.

Wraps:

- [Chat Completions](/stacks/openai/chat-completions/)
- [Embeddings](/stacks/openai/embeddings/)
- [Responses API](/stacks/openai/responses-api/) (GA late 2025)

Reference: [Batch API guide](https://platform.openai.com/docs/guides/batch).

## When to use

**Use Batch API for:**

- Embedding refresh runs.
- Eval Platform dataset scoring (LLM-as-judge).
- Bulk content generation (taxonomy classification, intent labeling).
- Migration jobs (re-summarizing every doc in a corpus).
- Anything not user-facing.

**Don't use Batch API for:**

- Anything user-facing.
- Anything where latency matters.
- Anything that triggers more downstream work synchronously.
- Workloads where a 24h SLA is a real risk.

## 2025-2026 currency anchors

- **50% off** — applies to both prompt + completion tokens for Chat Completions; both surfaces for Embeddings + Responses.
- **24-hour SLA** — most jobs complete in minutes; SLA is the worst case.
- **Responses-batch went GA late 2025** — you can now batch Responses API calls (including with built-in tools, where the tools support it).
- **JSONL in, JSONL out** — one request per line with a `custom_id`; matched by `custom_id` in the output.
- **Statuses:** `validating`, `in_progress`, `completed`, `failed`, `expired`.
- **Batch + Embedding** is the canonical pattern for embeddings refresh on large corpora.

## Patterns

### Pattern: batch workflow

```python
# 1. Build JSONL
with open("requests.jsonl", "w") as f:
    for item in items:
        f.write(json.dumps({
            "custom_id": item.id,
            "method": "POST",
            "url": "/v1/chat/completions",
            "body": {"model": "gpt-5-mini", "messages": [...]},
        }) + "\n")

# 2. Upload
file = client.files.create(file=open("requests.jsonl", "rb"), purpose="batch")

# 3. Submit batch
batch = client.batches.create(
    input_file_id=file.id,
    endpoint="/v1/chat/completions",
    completion_window="24h",
)

# 4. Poll status
while True:
    batch = client.batches.retrieve(batch.id)
    if batch.status in ("completed", "failed", "expired"):
        break
    time.sleep(60)

# 5. Download output
output = client.files.content(batch.output_file_id)

# 6. Reconcile by custom_id
for line in output.iter_lines():
    response = json.loads(line)
    reconcile(response["custom_id"], response["response"])
```

### Pattern: cost-optimization stack

A 2026 cost-optimization stack on OpenAI:

1. [Prompt caching](/stacks/openai/prompt-caching/) — 50% off cached input.
2. Right-size model — Nano/Mini for cheap paths, Standard/Pro for hard cases.
3. **Batch API — 50% off non-interactive.**
4. [Distillation](/stacks/openai/distillation-platform/) — fine-tune smaller model on bigger-model outputs.
5. [Predicted Outputs](/stacks/openai/predicted-outputs/) for code-edit flows.

### Pattern: eval dataset scoring via Batch

The [Eval Platform](/stacks/openai/eval-platform/) can submit LLM-as-judge scoring via Batch — eval runs are inherently non-interactive and benefit from the 50% discount.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| User-facing workload on Batch | Use sync API. 24h SLA breaks UX. |
| Synchronous wait on batch completion in a request handler | Async + queue + webhook / poll from a background worker. |
| Embedding refresh on sync API | Use Batch + [Embeddings](/stacks/openai/embeddings/). 50% savings. |
| Bulk classification on sync API | Batch. |
| Not using `custom_id` | You'll lose track of which response maps to which input. |
| Treating 24h SLA as worst-case latency for capacity planning | Most jobs complete fast, but plan for worst case. |
| Same JSONL ID twice | Idempotency lost; results ambiguous. |
| Single huge JSONL (>millions of rows) without chunking | Chunk into multiple batches for parallelism + size limits. |

## Gotchas

- **24h SLA is a worst case.** Most batches complete much faster, but capacity planning should assume worst case.
- **Built-in tools in batched Responses** — verify per-tool support; not every built-in tool runs cleanly in batch.
- **Per-batch size limits** — large batches may need chunking. Check current limits in the [guide](https://platform.openai.com/docs/guides/batch).
- **`custom_id` is your reconciliation key.** Use a stable identifier you can match back to your source data.
- **Failed rows** — partial batch failures are returned in the output; check `error` field per row.
- **Token counting** still applies — batch is the same model + same tokens, just discounted + delayed.
- **No streaming.** Batch is bulk — no SSE.

## Cross-references

### Related products in this Stack

- [Chat Completions API](/stacks/openai/chat-completions/) — wrapped by Batch.
- [Responses API](/stacks/openai/responses-api/) — wrapped by Batch (GA late 2025).
- [Embeddings](/stacks/openai/embeddings/) — wrapped by Batch.
- [Files API](/stacks/openai/files-api/) — upload + download JSONL.
- [Eval Platform](/stacks/openai/eval-platform/) — uses Batch for scoring.
- [Prompt Caching](/stacks/openai/prompt-caching/) — also applies to batched requests.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — when Batch is the right pattern.
- [backend-architect](/stacks/openai/backend-architect/) — async/queue/poll plumbing.
- [system-architect](/stacks/openai/system-architect/) — Batch in the topology.

### Authoritative sources

- [Batch API guide](https://platform.openai.com/docs/guides/batch)
- [Files API reference](https://platform.openai.com/docs/api-reference/files)
