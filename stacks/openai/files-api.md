---
title: Files API
description: Foundational object store for inputs, outputs, fine-tuning data, vector store contents, and batch payloads. Stable surface.
product:
  name: Files API
  stack: openai
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer]
  authoritative_url: https://platform.openai.com/docs/api-reference/files
  notes: "Foundational; stable for years; shared between Assistants (legacy), Responses Vector Stores, Batch API, fine-tuning, and Vision inputs."
---

## What it is

A simple object store at `/v1/files` for content that other OpenAI APIs consume or produce:

- **Batch payloads** — JSONL input + output for [Batch API](/stacks/openai/batch-api/).
- **Fine-tuning training data** — JSONL training files.
- **Vector store contents** — files indexed for `file_search` ([Built-in tools](/stacks/openai/built-in-tools/)).
- **Image / audio inputs** — alternative to inline base64 for Vision input + Audio.
- **Code interpreter inputs/outputs** — files attached to a `code_interpreter` session.

Files are uploaded with a `purpose` field (`batch`, `fine-tune`, `assistants`, `vision`, `user_data`) that determines what the file can be used for.

Reference: [Files API reference](https://platform.openai.com/docs/api-reference/files).

## When to use

**Use the Files API when:**

- You're submitting a [Batch API](/stacks/openai/batch-api/) job.
- You're providing fine-tuning training data.
- You're adding files to a Vector Store for `file_search`.
- You're attaching documents to a [Code Interpreter](/stacks/openai/built-in-tools/) session.
- You want to send large image / audio inputs without inlining base64.

**Don't use the Files API for:**

- General-purpose blob storage. Use S3 / GCS / R2.
- Long-term retention. OpenAI retention policies apply.

## 2025-2026 currency anchors

- **Stable surface.** No major shape changes through 2025-2026.
- **Vector Stores** are built on top of Files — same file objects, layered into a vector store via the Vector Stores API.
- **Files carry over** between [Assistants API (legacy)](/stacks/openai/assistants-api-legacy/) and [Responses API](/stacks/openai/responses-api/) — `file_search` on Responses uses the same vector stores as Assistants did.
- **`purpose` field is enforced.** A file uploaded with `purpose: "batch"` cannot be used as a fine-tuning dataset.

## Patterns

### Pattern: batch input upload

```python
file = client.files.create(
    file=open("requests.jsonl", "rb"),
    purpose="batch",
)
batch = client.batches.create(input_file_id=file.id, endpoint="/v1/chat/completions", completion_window="24h")
```

### Pattern: vector store ingestion

```python
file = client.files.create(file=open("kb_doc.pdf", "rb"), purpose="assistants")
vector_store = client.vector_stores.create(name="kb")
client.vector_stores.files.create(vector_store_id=vector_store.id, file_id=file.id)
```

The vector store handles chunking + embedding automatically.

### Pattern: cleanup policy

Files persist until deleted. For ephemeral workloads (batch jobs you've already reconciled, fine-tune datasets you've completed), delete after use:

```python
client.files.delete(file_id)
```

Otherwise you accumulate orphaned files in the project.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Re-uploading the same file repeatedly | Reuse file IDs across requests. |
| Not setting a deletion policy | Build cleanup. Orphaned files accumulate. |
| Wrong `purpose` field | Match purpose to use case. |
| Storing customer files in OpenAI as primary storage | Use your own object store; Files API is for OpenAI-consumed data. |
| Large file inline-base64 in prompt | Upload via Files API; reference by file ID. |
| Not handling upload errors | Network failures happen; retry. |

## Gotchas

- **`purpose` is enforced.** You can't repurpose a file uploaded for batch as a fine-tune dataset.
- **Retention.** Files persist until deleted — your responsibility.
- **Size limits.** Vary by purpose; check current limits in the API reference.
- **PII** — files may contain PII; treat as sensitive data subject to your retention + access policies.
- **Files share the project's storage quota** — large fine-tune datasets can consume meaningful storage.
- **Batch input/output files** are not auto-deleted post-batch; clean up explicitly.

## Cross-references

### Related products in this Stack

- [Batch API](/stacks/openai/batch-api/) — uses Files for JSONL input/output.
- [Built-in tools](/stacks/openai/built-in-tools/) — `file_search` backed by Vector Stores → Files.
- [Vision input](/stacks/openai/vision-input/) — images via Files API or inline.
- [Vision fine-tuning](/stacks/openai/vision-fine-tuning/) — training data via Files.

### Role overlays

- [backend-architect](/stacks/openai/backend-architect/) — file lifecycle + cleanup.
- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — training data preparation.

### Authoritative sources

- [Files API reference](https://platform.openai.com/docs/api-reference/files)
- [Vector Stores API reference](https://platform.openai.com/docs/api-reference/vector-stores)
