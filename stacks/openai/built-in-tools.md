---
title: Built-in tools
description: web_search, file_search, code_interpreter, computer_use_preview — Responses-API-only tools billed per call with their own quotas. The agentic primitives that don't require building from scratch.
product:
  name: Built-in tools
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect, security-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/tools
  notes: "Responses-API-only; per-call pricing; tier-gated quotas; capabilities expanding 2025-2026. Computer Use carries the largest safety surface."
---

## What it is

Four tools that OpenAI implements server-side and exposes through the [Responses API](/stacks/openai/responses-api/):

| Tool | What it does |
|---|---|
| `web_search` | Model issues web search queries during a response; results inject into context; model cites sources. |
| `file_search` | Model retrieves chunks from an OpenAI Vector Store (created via [Files API](/stacks/openai/files-api/) + Vector Stores). |
| `code_interpreter` | Model writes + executes Python in an OpenAI-managed sandbox. Files in, files out. |
| `computer_use_preview` | Model drives a virtual browser/desktop via screenshots + click/type tool calls. See [Computer Use](/stacks/openai/computer-use/) for the full safety surface. |

Declared inline in the Responses API `tools` array; each has its own pricing model, quota, and gotchas. **Chat Completions cannot reach these — they only exist on Responses.**

Reference: [Tools guide](https://platform.openai.com/docs/guides/tools).

## When to use

| Need | Tool | Why |
|---|---|---|
| Agent that answers about current events | `web_search` | RAG over the live web; cites sources. |
| Bring-your-own-data RAG without a vector DB | `file_search` | Managed; OpenAI handles embedding + chunking + retrieval. |
| Data analysis, file conversion, chart generation | `code_interpreter` | Python sandbox. |
| Browser automation where the target has no API | `computer_use_preview` | Drives sites via screenshots. **Huge safety surface — see [Computer Use](/stacks/openai/computer-use/).** |
| Web search but want full control of provider | Function tool calling your own search API (Tavily, Serper, Google) | More control, more cost. |
| Production-scale RAG with hybrid + rerankers | Function tool calling your own vector DB (pgvector, Pinecone, Qdrant) | More control over chunking, ranking, metadata. |
| Code execution in your environment, not OpenAI's | Function tool calling your own sandboxed runtime | Don't tie code execution to OpenAI's sandbox. |

**Don't use built-in tools when:** the workload doesn't actually need their managed nature. Function tools are more flexible, more debuggable, and provider-portable.

## 2025-2026 currency anchors

- **`web_search` ships citations** as `annotations` on the assistant message. Extract them; don't regex the answer.
- **`file_search` Vector Stores** are shared with [Assistants API](/stacks/openai/assistants-api-legacy/) — existing vector stores carry forward.
- **`code_interpreter` sandbox** is ephemeral by default. Files don't persist across sessions unless you store externally and re-upload.
- **`computer_use_preview`** is tier-gated, behaviorally fragile (web pages change), and a huge safety surface — see [Computer Use](/stacks/openai/computer-use/).
- **Per-call pricing.** Each built-in tool call is billed independently from chat tokens. Verify against [pricing](https://openai.com/api/pricing/).
- **Tier-gated quotas.** Tier 1 projects may have limited or no built-in tool access. Confirm before promising.

## Patterns

### Pattern: web_search with citation extraction

```python
response = client.responses.create(
    model="gpt-5",
    instructions="Answer with citations from web search results.",
    input=[{"role": "user", "content": query}],
    tools=[{"type": "web_search"}],
)

# Citations are annotations on the assistant message
for item in response.output:
    if item.type == "message":
        for content in item.content:
            for annotation in getattr(content, "annotations", []):
                print(annotation.url, annotation.title)
```

Extract citations from annotations; surface them to the user.

### Pattern: file_search v0 → custom retrieval at scale

Ship v0 on `file_search` — fastest path to RAG. When eval scores plateau or you need hybrid (BM25 + dense) search, custom rerankers, or advanced metadata filtering, migrate to a dedicated vector DB.

```python
# v0
tools = [{"type": "file_search", "vector_store_ids": [vs.id]}]
# v1 (custom)
tools = [{"type": "function", "name": "search_knowledge_base", "parameters": {...}}]
```

### Pattern: code_interpreter for ephemeral compute

Use `code_interpreter` for the LLM's compute scratchpad — analyzing a CSV the user uploaded, generating a chart, doing math. **Don't** use it as your production ETL. The sandbox is ephemeral; files don't persist.

### Pattern: gating computer_use_preview behind a separate project

Computer Use is dangerous enough that a separate [project](/stacks/openai/organization-project-hierarchy/) with explicit human review gating is the right architecture. Allowlist only `computer_use_preview` on that project; main app uses a different project without it.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Trying to use built-in tools on Chat Completions | Built-in tools are Responses-only. Migrate the workload. |
| `file_search` for billion-vector RAG at scale | Custom vector DB (pgvector / Pinecone / Qdrant / Milvus). |
| `code_interpreter` for production data warehouse jobs | Your own data warehouse + function tool. |
| `computer_use_preview` without human-in-loop | Mandatory confirmation for irreversible actions — see [Computer Use](/stacks/openai/computer-use/). |
| `web_search` without citation extraction | Extract citations from annotations; surface them. |
| Mixing `computer_use_preview` and other tools in the same general-purpose project | Isolate Computer Use behind its own project + RBAC. |
| Assuming built-in tools are free | Each call is billed; verify on pricing page. |
| Not tier-confirming before promising web/computer use | Tier 1 may not have access. Confirm. |

## Gotchas

- **Responses-only.** Chat Completions can't call them.
- **Tier-gated.** Confirm project tier.
- **Per-call billing.** Build cost models that account for tool-call counts.
- **`web_search` quality varies.** Sometimes the model produces low-quality queries. Add domain hints in the system prompt; pre-process user queries before passing.
- **`file_search` chunking is opaque** — you lose control. For high-quality RAG, custom retrieval wins.
- **`code_interpreter` sandbox is ephemeral.** Don't depend on files persisting.
- **`computer_use_preview` is fragile** — webpage layouts change, the model misclicks, sites detect automation. Plan for failure modes. See [Computer Use](/stacks/openai/computer-use/) for the threat surface.
- **Citation URLs from `web_search`** come as annotations, not in the answer body. Parse them.
- **Computer Use prompt injection.** Every webpage is an injection vector. Tight sanitization required.

## Cross-references

### Related products in this Stack

- [Responses API](/stacks/openai/responses-api/) — the only surface that supports built-in tools.
- [Computer Use](/stacks/openai/computer-use/) — deep coverage of `computer_use_preview` and its safety surface.
- [Files API](/stacks/openai/files-api/) — backs `file_search` Vector Stores.
- [Function calling / tool use](/stacks/openai/function-calling/) — custom alternative to built-in tools.
- [Agents SDK](/stacks/openai/agents-sdk/) — declares built-in tools inline.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — tool selection per workload.
- [backend-architect](/stacks/openai/backend-architect/) — tool runtime + citation extraction.
- [security-engineer](/stacks/openai/security-engineer/) — Computer Use threat model, web_search trust.

### Authoritative sources

- [Tools guide](https://platform.openai.com/docs/guides/tools)
- [web_search guide](https://platform.openai.com/docs/guides/tools-web-search)
- [file_search guide](https://platform.openai.com/docs/guides/tools-file-search)
- [code_interpreter guide](https://platform.openai.com/docs/guides/tools-code-interpreter)
- [computer_use guide](https://platform.openai.com/docs/guides/tools-computer-use)
