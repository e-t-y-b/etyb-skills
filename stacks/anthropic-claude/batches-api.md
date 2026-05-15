---
title: Batches API
description: 50% discount on async Claude work — up to 100K requests, 256MB, 24-hour window. Use for evals, bulk classification, backfill, synthetic data. Don't use for tool-use loops or interactive paths.
product:
  name: Batches API
  stack: anthropic-claude
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, system-architect]
  authoritative_url: https://docs.anthropic.com/en/api/creating-message-batches
  notes: "Stable async API; 50% discount on both input and output tokens; up to 100K requests per batch."
---

## What it is

The Batches API submits Claude work in bulk for asynchronous processing with a **50% discount on both input AND output tokens**. Constraints (verify current):

- Up to **100K requests per batch**
- Up to **256MB total request size**
- Up to **24-hour completion window** (most batches finish in minutes-to-hours)
- Polling-based status (or webhook on enterprise tiers)
- Same Messages API surface, just submitted in bulk via `client.messages.batches.create()`

See [Batches API reference](https://docs.anthropic.com/en/api/creating-message-batches).

## When to use

Batches are right for:

- **Bulk classification / extraction** — categorizing 10K support tickets, extracting fields from a document set.
- **Eval runs** — running an eval suite of 1,000 prompts before a deploy.
- **Backfill / regeneration** — regenerating summaries for an old corpus, regenerating embeddings descriptions.
- **Synthetic data generation** — training data, content variations, examples for prompt tuning.
- **Pair with [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/) for ultra-cheap bulk** — 50% off a cheap tier = pennies per thousand records.

Don't use Batches for:

- **Real-time user-facing.** Latency is minutes-to-hours.
- **When each result is needed as soon as ready.** Batches return all-at-once.
- **Tool-use loops.** Batches are single-turn; agentic workflows need the synchronous [Messages API](/stacks/anthropic-claude/claude-api/) (typically via the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/)).

## 2025-2026 currency anchors

- **50% discount applies to both input and output tokens.** Stack with [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) for additional savings on cached prefixes.
- **`custom_id` per request.** Set a meaningful per-record ID; results return keyed by `custom_id`. Without it you can't map results to inputs.
- **Webhooks available on enterprise** for completion notification — saves polling overhead. Verify availability for your tier.
- **Bedrock and Vertex have their own batch inference surfaces** with different APIs; this page covers Anthropic API's Batches API specifically.

## Patterns + anti-patterns

### Pattern — submit, poll on a sensible cadence, retrieve

```python
batch = client.messages.batches.create(
    requests=[
        {
            "custom_id": f"ticket_{ticket.id}",
            "params": {
                "model": "claude-haiku-4-5-20251022",
                "max_tokens": 1024,
                "messages": [{"role": "user", "content": classify_prompt(ticket)}],
            },
        }
        for ticket in tickets  # up to 100K
    ]
)

while batch.processing_status != "ended":
    time.sleep(60)  # poll every 60s, not every second
    batch = client.messages.batches.retrieve(batch.id)

for result in client.messages.batches.results(batch.id):
    save_classification(result.custom_id, result.result.message.content[0].text)
```

### Pattern — Batches + Haiku + Caching for bulk classification

100K classification jobs on Haiku-via-Batches with a cached system prompt: 50% off × cheap-tier × 90% off cached input = the kind of cost profile where "let's classify everything" becomes feasible.

### Pattern — eval suite via Batches

Running an eval suite of 1,000 prompts every commit is too expensive on the synchronous API. Submit as a batch; gate the deploy on batch results. Eval cycle stretches from "minutes" to "tens of minutes" but cost drops by half.

### Anti-pattern — polling every second

Wasteful — the operation runs for minutes-to-hours. Poll every 30-60 seconds, or use webhooks if available.

### Anti-pattern — many tiny batches

The discount kicks in at any batch size, but operational overhead of many small batches outweighs savings. Aggregate. One batch of 10K records beats 100 batches of 100 records.

### Anti-pattern — not setting `custom_id`

You get results back keyed by `custom_id`. Without setting it, you can't map results to your input records. Always set a stable, meaningful ID per request.

### Anti-pattern — Batches for interactive UX

A user clicks "summarize" and waits 47 minutes. Use the synchronous API for anything user-facing.

## Gotchas

- **All-at-once result return.** You don't get partial results streaming back as records complete — wait for the batch to finish, then iterate `results()`.
- **Per-request failures don't fail the batch.** Individual records can fail (validation error, model refusal); the batch still completes. Inspect each `result` for errors.
- **24-hour SLA.** Most batches finish much faster, but the SLA is 24h. If your workflow can't tolerate that worst case, Batches isn't the right fit.
- **Same model availability as the synchronous API.** A model that's not on the synchronous API isn't on Batches either.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — Batches submit Messages-shaped requests
- [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) — natural pairing for bulk classification
- [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) — stack savings on cached prefixes
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — when async pays
- [Batches API reference](https://docs.anthropic.com/en/api/creating-message-batches)
