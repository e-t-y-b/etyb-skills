---
title: Files API
description: "Upload PDFs, images, and supported documents once; reference by `file_id` across many requests. Replaces base64-inlining at any non-trivial scale. Still in beta."
product:
  name: Files API
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-07-06"
  applies_to_roles: [backend-architect, ai-ml-engineer]
  authoritative_url: https://platform.claude.com/docs/en/build-with-claude/files
  notes: "Still in beta (requires anthropic-beta: files-api-2025-04-14 header) as of mid-2026, not GA. 500MB max per file, 500GB total per organization. Available on Claude API, Claude Platform on AWS, Microsoft Foundry — not on Bedrock or Google Cloud."
---

## What it is

The Files API (**beta** — requires the `anthropic-beta: files-api-2025-04-14` header) lets you upload PDFs, images, and other supported documents to Anthropic-managed storage and reference them by `file_id` across many requests. Replaces base64-inlining at any non-trivial scale.

```python
with open("document.pdf", "rb") as f:
    uploaded = client.beta.files.upload(file=("document.pdf", f, "application/pdf"))

response = client.beta.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    betas=["files-api-2025-04-14"],
    messages=[{
        "role": "user",
        "content": [
            {"type": "document", "source": {"type": "file", "file_id": uploaded.id}},
            {"type": "text", "text": "What does this contract say about termination?"},
        ]
    }]
)
```

See [Files API reference](https://platform.claude.com/docs/en/build-with-claude/files).

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

- **Still beta as of mid-2026**, not GA — requires the `anthropic-beta: files-api-2025-04-14` header on every upload/list/retrieve/delete/download call and on any Messages request that references a `file_id`. Rate limit during beta: ~100 file-related requests/minute.
- **Storage limits: 500MB max per file, 500GB total per organization** (not per-workspace — the quota pools across every workspace in the org).
- **Workspace-scoped files.** A file is scoped to the workspace of the API key that created it; any API key in that same workspace can use it. Cross-workspace requires re-upload. Multi-tenant SaaS = one workspace per tenant = files scoped to tenants naturally.
- **Files persist until deleted.** No automatic eviction. Implement deletion on user-data-deletion paths (GDPR / general hygiene).
- **Supported types:** PDF and plain text as `document` blocks; JPEG/PNG/GIF/WebP as `image` blocks; other formats (.csv, .txt, .md, .docx, .xlsx) via the code-execution tool's `container_upload`, or convert to plain text and inline instead.
- **Platform availability:** Claude API, Claude Platform on AWS, and Microsoft Foundry (Hosted-on-Anthropic deployments only). Not currently available on Amazon Bedrock or Google Cloud.
- **Not ZDR-eligible.** Files API is explicitly excluded from Zero Data Retention, unlike PDF/Vision input.

## Patterns + anti-patterns

### Pattern — upload once, reference many

Upload the document on the first request that references it. Cache the `file_id` mapping (e.g., document hash → file_id) in your application database. Subsequent requests reference by ID; no re-upload.

### Pattern — pair with Citations

The [Citations API](/stacks/anthropic-claude/citations/) works with Files-uploaded documents — character-level span attribution for grounded responses. RAG over uploaded PDFs with proper citation is the canonical pattern.

### Pattern — lifecycle policy

Decide and document:

- **TTL for uploaded files** — 30 days? 1 year? Until user deletes their account?
- **Deletion triggers** — user-initiated data deletion, GDPR right-to-be-forgotten, account closure, project archive.
- **Quota monitoring** — alert at 80% of the 500GB per-organization quota (it pools across all workspaces, not per-workspace).

Automate deletion via API; don't rely on manual ops cleanup.

### Anti-pattern — uploading every request's content as a new file

You've added a round-trip without reuse benefit. If the document is one-off, inline it. Files API for multi-use only.

### Anti-pattern — forgetting to delete

Storage grows; eventually quota hits. Quotas surface as upload-time errors, often during an incident response. Have lifecycle in place from day one.

### Anti-pattern — uploading PII without considering data residency

Anthropic's storage is in their cloud, and Files API isn't ZDR-eligible. Data residency commitments may apply (verify [Trust Center](https://trust.anthropic.com/) for your jurisdiction). For strict residency requirements, base64-inline documents per request instead of uploading — Files API isn't available at all on [Bedrock](/stacks/anthropic-claude/bedrock-provider/) or [Vertex/Google Cloud](/stacks/anthropic-claude/vertex-ai-provider/) as of mid-2026, so it isn't an option for keeping storage in your own cloud region.

### Anti-pattern — not audit-logging uploads

Compliance regimes (HIPAA, GDPR, SOC 2) typically require records of when PHI/PII was sent to a third-party processor. Log every upload — workspace, user, content classification, retention plan — separately from any logging of the file contents themselves.

## Gotchas

- **`file_id` format** is opaque; treat as a black-box identifier. Don't parse or pattern-match.
- **Workspace isolation** is the unit. A `file_id` from one workspace doesn't work in another.
- **Upload errors aren't generation errors.** A failed upload returns an HTTP error; a generation error against a valid `file_id` returns a Messages-API error. Different retry strategies.
- **Beta header required everywhere.** Forgetting `anthropic-beta: files-api-2025-04-14` (or the SDK's `betas=["files-api-2025-04-14"]` equivalent) on the Messages call that references a `file_id`, not just on the upload, is a common integration bug.
- **Files API isn't available on Bedrock or Google Cloud at all** (as of mid-2026) — only Claude API, Claude Platform on AWS, and Microsoft Foundry (Hosted-on-Anthropic only). Don't assume portability; fall back to base64-inlining for those providers.
- **Uploaded files can't be downloaded.** Only files *created by* skills or the code-execution tool are downloadable — a file you uploaded yourself has no download endpoint.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — Files referenced via `document` content blocks
- [Citations](/stacks/anthropic-claude/citations/) — grounded responses on uploaded documents
- [Vision](/stacks/anthropic-claude/vision/) — image input alternative to inline base64
- [PDF Input](/stacks/anthropic-claude/pdf-input/) — PDF-specific patterns
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — operational concerns
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — PII handling, data residency
