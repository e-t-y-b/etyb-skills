---
title: Citations
description: Document-grounded responses with character-level source spans. The supported path for RAG with provenance — don't parse "[1]" out of prose in 2026.
product:
  name: Citations
  stack: anthropic-claude
  drift_risk: low
  last_verified_on: "2026-07-05"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/citations
  notes: "Stable surface; requires document content blocks (not interpolated text); pair with Files API for uploaded documents."
---

## What it is

The Citations API returns responses with source-grounded character spans pointing back to documents you provided. The API includes `citation` content blocks alongside `text` blocks; each citation references the source document and the character span it grounds.

You pass documents as `document` content blocks with `cite_documents: true` (or via [Files API](/stacks/anthropic-claude/files-api/) references with the citation flag); the response carries citation data with character-level precision. See [Citations Guide](https://docs.anthropic.com/en/docs/build-with-claude/citations).

## When to use

Citations are the right path for:

- **Document Q&A** — "Answer this question based on these PDFs; cite where each claim comes from."
- **RAG with provenance** — your retrieval pipeline pulls chunks; you pass them with citations enabled; the response has spans you render as footnotes.
- **Compliance-friendly generation** — generated text with sources for audit, legal review, regulated workflows.
- **Hallucination defense** — citations don't guarantee correctness, but force the model to ground claims in provided sources rather than inventing them.

Don't use Citations when:

- **No source documents are passed.** Citations need something to cite.
- **Pure generation tasks** — creative writing, code generation, summarization without specific source attribution requirements.

## 2025-2026 currency anchors

- **Stable since 2025.** Surface and behavior consistent across recent Claude 4.x releases.
- **Works with [Files API](/stacks/anthropic-claude/files-api/)** — uploaded PDFs/documents can be cited by character range.
- **Works with both [Vision](/stacks/anthropic-claude/vision/) and [PDF Input](/stacks/anthropic-claude/pdf-input/)** — page-level grounding for PDFs.
- **`document` content block type is the trust boundary.** Documents are treated as data, not instructions — also a defense against indirect prompt injection (see [security-engineer overlay](/stacks/anthropic-claude/security-engineer/)).

## Patterns + anti-patterns

### Pattern — RAG generation step

```python
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {
                "type": "document",
                "source": {"type": "text", "media_type": "text/plain", "data": chunk_1},
                "title": "Section 1.1",
                "context": "From the employee handbook, March 2026",
                "citations": {"enabled": True},
            },
            {
                "type": "document",
                "source": {"type": "text", "media_type": "text/plain", "data": chunk_2},
                "title": "Section 4.3",
                "citations": {"enabled": True},
            },
            {"type": "text", "text": "What's the policy on remote work?"},
        ]
    }]
)
```

Verify exact field shapes against current docs — the surface stabilized but field names have shifted across early releases.

### Pattern — render citations as footnotes

Map citation spans to numbered footnotes; expose document name + character range to the user; let them click through to the original. The structured citation data makes this trivial — no regex parsing of "[1]" tokens.

### Pattern — citations as the trust boundary

Documents passed as `document` content blocks are treated as data by the model, not as instructions. This is structurally safer than interpolating retrieved text into the user message — it's both a citation enabler and a partial defense against indirect prompt injection.

### Anti-pattern — asking Claude in prose to "cite your sources"

You'll get hallucinated citation numbers half the time. Claude can invent footnote references that point to nothing. Use the Citations API — structured spans, no parsing.

### Anti-pattern — treating citations as proof of correctness

Claude can cite a real document for a wrong claim if the document's text is misinterpreted. Citations help auditability and reduce hallucination; they don't guarantee accuracy. For high-stakes outputs, layer human review on top.

### Anti-pattern — passing retrieved chunks as `text` content

If you stuff retrieved text into a `text` block ("Context:\n{chunks}\n\nQuestion: {q}"), the Citations API has nothing to cite — those chunks aren't documents to the model. Pass them as `document` blocks.

## Gotchas

- **Citations are character-level on text documents, page-level on PDFs** (verify current behavior — has evolved).
- **Empty citations field** = the response wasn't grounded in any provided document. Useful signal that the model couldn't find the answer in your sources.
- **Citation spans may overlap.** A single claim can be grounded in multiple documents; your UI must handle multi-source citations gracefully.
- **Vision-based PDF citations** anchor to image regions on visually-complex pages; verify current support for your specific layout.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — `document` content blocks
- [Files API](/stacks/anthropic-claude/files-api/) — uploaded documents work with Citations
- [PDF Input](/stacks/anthropic-claude/pdf-input/) — PDF-specific citation behavior
- [Vision](/stacks/anthropic-claude/vision/) — image-input citations
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — RAG patterns with Claude
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — `document` blocks as trust boundary
- [Citations Guide](https://docs.anthropic.com/en/docs/build-with-claude/citations)
