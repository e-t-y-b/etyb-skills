---
title: Assistants API (legacy)
description: Deprecated 2025; sunset scheduled H1 2026. Do not greenfield. Migrate threads → conversations and Assistants tools → Responses API built-in or function tools.
product:
  name: Assistants API
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://platform.openai.com/docs/assistants/migration
  notes: "Deprecation path announced 2025; sunset H1 2026 window. Surface is closed to new development per OpenAI guidance. Migration urgency rises as sunset date approaches."
---

## What it is

The Assistants API (`/v1/assistants`, `/v1/threads`, `/v1/runs`) was OpenAI's first stab at an agentic surface — beta-tagged from launch in 2023. It introduced Assistant objects (a stored system prompt + tool config + model selection), Threads (conversation containers), Messages (turns inside a thread), Runs (an execution of an Assistant against a Thread), and Run Steps (the model's internal tool-call / reasoning sequence).

In 2025 OpenAI announced its deprecation in favor of the [Responses API](/stacks/openai/responses-api/), and published the [migration guide](https://platform.openai.com/docs/assistants/migration). Sunset is scheduled in the first-half-2026 window. The surface remains functional but **closed to new development per OpenAI guidance**.

## When to use

**Don't.** This is a legacy surface. The only two valid reasons to touch it in 2026:

1. **Migration** — you have an existing Assistants deployment and you're moving it to Responses before sunset.
2. **Forensic / read-only** — auditing a thread or run from a system that hasn't migrated yet.

**Do not greenfield on Assistants.** If a 2026 codebase contains `client.beta.threads.create(...)` or `client.beta.assistants.create(...)` and is being actively built on, the team is shipping tech debt that will need a rewrite before sunset.

**Migrate to:**

- [Responses API](/stacks/openai/responses-api/) — the official destination. Server-side conversation state replaces Threads. Built-in tools replace Assistants' built-in tools. Function tools port over with a small schema change.
- [Agents SDK](/stacks/openai/agents-sdk/) — if you want the orchestration story OpenAI is investing in, the Agents SDK sits on top of Responses.

## 2025-2026 currency anchors

- **Sunset announced 2025**; deprecation glide path published. Read the [migration guide](https://platform.openai.com/docs/assistants/migration) end-to-end.
- **Sunset window: first half of 2026.** Don't wait until enforcement to migrate.
- **Vector Stores carry over.** The [Files API](/stacks/openai/files-api/) + Vector Store APIs that powered Assistants' File Search are now shared with Responses' `file_search` tool. Existing vector stores work on either surface.
- **No new features land on Assistants.** Built-in tools (Computer Use, the latest web search, code interpreter improvements) only ship to Responses.

## Migration mapping

| Assistants concept | Responses equivalent |
|---|---|
| Thread + messages | `previous_response_id` chain on [Responses](/stacks/openai/responses-api/) |
| Assistant object | System prompt (`instructions`) + tool config sent per-request; or wrap in your own server-side "agent" object / Agents SDK Agent |
| Code Interpreter tool | `code_interpreter` [built-in tool](/stacks/openai/built-in-tools/) on Responses |
| File Search tool | `file_search` [built-in tool](/stacks/openai/built-in-tools/) on Responses (Vector Stores carry over) |
| Function tools | Same [function tools](/stacks/openai/function-calling/) — re-declare with Responses tool schema (flatter; no nested `function` wrapper) |
| Run + Run Step | Built into one `client.responses.create(...)` call — the agentic loop is server-side |
| `assistant_id` | Stored prompt/config in your own DB or as a [stored prompt](https://platform.openai.com/docs/guides/prompt-engineering) |

## Patterns (migration)

### Pattern: thread → previous_response_id

Replace:
```python
thread = client.beta.threads.create()
client.beta.threads.messages.create(thread.id, role="user", content="...")
run = client.beta.threads.runs.create_and_poll(thread.id, assistant_id=assistant.id)
```
with:
```python
response = client.responses.create(
    model="gpt-5",
    instructions=system_prompt,
    input=[{"role": "user", "content": user_message}],
    tools=tools,
    previous_response_id=previous_response_id,
)
```

The poll is gone. The thread is gone. State chains via `previous_response_id`.

### Pattern: tool schema flattening

Assistants' tool schema:
```json
{"type": "function", "function": {"name": "x", "description": "...", "parameters": {...}}}
```
Responses' tool schema:
```json
{"type": "function", "name": "x", "description": "...", "parameters": {...}, "strict": true}
```

The nested `function` wrapper is gone. Add `strict: true` (use [Structured Outputs](/stacks/openai/structured-outputs/) defaults).

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Greenfielding on Assistants in 2026 | Stop; go to [Responses](/stacks/openai/responses-api/). |
| Adding new features to an existing Assistants app | Migrate first; then add features on the new surface. |
| Treating Assistants as production-stable for new contracts | It is on a sunset path. Contractual commitments need to align with Responses. |
| Polling Run Steps for observability | Use Responses' typed event stream + your own tracing layer. |
| Re-implementing Assistant objects in your DB to "stay on Assistants longer" | You're paying tech-debt interest with no upside. Migrate. |

## Gotchas

- **Sunset is firm.** OpenAI's deprecation patterns historically retire surfaces hard (see `code-davinci-002` in 2023). Plan migration well before announced sunset.
- **No new tools.** If a built-in tool you need (`computer_use_preview`, remote MCP) only exists on Responses, that's already a forcing function to migrate.
- **Cost.** Assistants is not cheaper. Migration delivers feature parity at equal or lower per-request cost.
- **Tooling lag.** Some third-party Assistants helper libraries (chat UIs, debuggers) haven't moved to Responses yet. Evaluate whether they're still maintained before depending on them through migration.
- **Vector stores are safe.** The file-storage layer doesn't move; the API surface that calls it does.

## Cross-references

### Related products in this Stack

- [Responses API](/stacks/openai/responses-api/) — the migration destination.
- [Built-in tools](/stacks/openai/built-in-tools/) — file_search / code_interpreter / web_search / computer_use_preview on Responses.
- [Function calling / tool use](/stacks/openai/function-calling/) — custom-tool schema migration.
- [Files API](/stacks/openai/files-api/) + Vector Stores — carry over to Responses unchanged.
- [Agents SDK](/stacks/openai/agents-sdk/) — orchestration layer on top of Responses.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — migration design.
- [backend-architect](/stacks/openai/backend-architect/) — code-level migration.
- [system-architect](/stacks/openai/system-architect/) — schedule + risk of migration in your release plan.

### Authoritative sources

- [Migration guide: Assistants → Responses](https://platform.openai.com/docs/assistants/migration)
- [Assistants API reference (legacy)](https://platform.openai.com/docs/api-reference/assistants)
- [OpenAI deprecation page](https://platform.openai.com/docs/deprecations)
