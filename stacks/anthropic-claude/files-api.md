---
title: Files API
description: "Upload PDFs, images, and supported documents once; reference by `file_id` across many requests. Replaces base64-inlining at any non-trivial scale."
product:
  name: Files API
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-07-05"
  applies_to_roles: [backend-architect, ai-ml-engineer]
  authoritative_url: https://docs.anthropic.com/en/api/files
  notes: "GA 2025; storage is workspace-scoped; lifecycle policies and PII residency considerations apply."
---

## What it is

The Files API (GA 2025) lets you upload PDFs, images, and other supported documents to Anthropic-managed storage and reference them by `file_id` across many requests. Replaces base64-inlining at any non-trivial scale.

```python
with open("document.pdf", "rb") as f:
    uploaded = client.beta.files.upload(file=("document.pdf", f, "application/pdf"))

response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {"type": "document", "source": {"type": "file", "file_id": uploaded.id}},
            {"type": "text", "text": "What does this contract say about termination?"},
        ]
    }]
)
```

See [Files API reference](https://docs.anthropic.com/en/api/files).

## When to use

Files API is right when:

- **A document is referenced by many requests.** User uploads a 100-page PDF; you'll ask 50 questions about it. Upload once, reference 50 times.
- **Images larger than ~1MB.** Base64 overhead is brutal; Files API is cleaner.
- **Workspaces sharing documents.** A document uploaded to a workspace is referenceable by any API key in that workspace.
- **Long-running agents need persistent document references.** Agent can attach a `file_id` to its memory or state, retrieve it across sessions.

Stay on base64 inlining when:

- **One-off requests.** A user sends a single screenshot for analysis; inline and move on.
- **Documents change per request.** Each request has unique content; Files API just adds an upload round-trip.

## 2025-2026 currency anchors

- **GA in 2025.** Surface stable; verify quota and lifetime details against current docs.
- **Per-workspace storage quota** (verify current limit on Anthropic docs).
- **Workspace-scoped files.** Cross-workspace requires re-upload. Multi-tenant SaaS = one workspace per tenant = files scoped to tenants naturally.
- **Files persist until deleted.** No automatic eviction. Implement deletion on user-data-deletion paths (GDPR / general hygiene).
- **Supported types:** PDFs, images (PNG/JPEG/GIF/WebP), some other document formats — verify current support matrix.

## Patterns + anti-patterns

### Pattern — upload once, reference many

Upload the document on the first request that references it. Cache the `file_id` mapping (e.g., document hash → file_id) in your application database. Subsequent requests reference by ID; no re-upload.

### Pattern — pair with Citations

The [Citations API](/stacks/anthropic-claude/citations/) works with Files-uploaded documents — character-level span attribution for grounded responses. RAG over uploaded PDFs with proper citation is the canonical pattern.

### Pattern — lifecycle policy

Decide and document:

- **TTL for uploaded files** — 30 days? 1 year? Until user deletes their account?
- **Deletion triggers** — user-initiated data deletion, GDPR right-to-be-forgotten, account closure, project archive.
- **Quota monitoring** — alert at 80% of workspace quota.

Automate deletion via API; don't rely on manual ops cleanup.

### Anti-pattern — uploading every request's content as a new file

You've added a round-trip without reuse benefit. If the document is one-off, inline it. Files API for multi-use only.

### Anti-pattern — forgetting to delete

Storage grows; eventually quota hits. Quotas surface as upload-time errors, often during an incident response. Have lifecycle in place from day one.

### Anti-pattern — uploading PII without considering data residency

Anthropic's storage is in their cloud. Data residency commitments may apply (verify [Trust Center](https://trust.anthropic.com/) for your jurisdiction). For strict residency requirements, you may need to keep documents in your own storage and inline them per request (or use [Bedrock](/stacks/anthropic-claude/bedrock-provider/) / [Vertex](/stacks/anthropic-claude/vertex-ai-provider/) where storage stays in your cloud region).

### Anti-pattern — not audit-logging uploads

Compliance regimes (HIPAA, GDPR, SOC 2) typically require records of when PHI/PII was sent to a third-party processor. Log every upload — workspace, user, content classification, retention plan — separately from any logging of the file contents themselves.

## Gotchas

- **`file_id` format** is opaque; treat as a black-box identifier. Don't parse or pattern-match.
- **Workspace isolation** is the unit. A `file_id` from one workspace doesn't work in another.
- **Upload errors aren't generation errors.** A failed upload returns an HTTP error; a generation error against a valid `file_id` returns a Messages-API error. Different retry strategies.
- **Files API on Bedrock / Vertex** has different shapes (cloud-provider-native storage). Verify per-provider before assuming portability.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — Files referenced via `document` content blocks
- [Citations](/stacks/anthropic-claude/citations/) — grounded responses on uploaded documents
- [Vision](/stacks/anthropic-claude/vision/) — image input alternative to inline base64
- [PDF Input](/stacks/anthropic-claude/pdf-input/) — PDF-specific patterns
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — operational concerns
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — PII handling, data residency
