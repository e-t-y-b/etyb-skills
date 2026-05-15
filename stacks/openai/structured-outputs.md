---
title: Structured Outputs
description: "JSON-schema enforcement at decode time with `strict: true`. The production default for any JSON output. Eliminates \"model returned bad JSON\" failures."
product:
  name: Structured Outputs
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/structured-outputs
  notes: "Production default since 2024 with strict mode; schema constraints evolved through 2025; pair with Pydantic / Zod for clean dev ergonomics."
---

## What it is

Structured Outputs constrains the model at decode time to produce only tokens that match a JSON schema. No more parse failures, no more malformed JSON. Two places to apply it:

1. **`response_format: { type: "json_schema", strict: true }`** — the main response is constrained.
2. **Tool definitions with `strict: true`** — tool arguments are constrained.

Reference: [Structured Outputs guide](https://platform.openai.com/docs/guides/structured-outputs).

## When to use

**Use Structured Outputs `strict: true` when:**

- You need JSON output. Always. It is the production default.
- Tool arguments must conform to a schema (which is always, for serious tools).
- You want to eliminate "the model returned bad JSON" support tickets.

**Don't use `strict: true` when:**

- Output is **truly free-form** (creative writing, summaries). Strict adds zero value.
- Output is **very deeply nested** (>5 levels) and hits the recursion limit. Refactor or accept non-strict.
- You're **streaming with partial JSON parsing** where you want token-by-token assembly client-side. Use `useObject` (Vercel AI SDK) or a custom incremental parser.

## 2025-2026 currency anchors

- **`strict: true` is the production default** for any JSON. Without it, you're relying on the model to produce valid JSON by happy accident.
- **Schema constraints** (still apply):
  - **All fields must be `required`.** No optional fields. Model optional fields as `["null", "string"]` and have the model emit `null`.
  - **No `oneOf` / `anyOf` at the top level.** Use a `kind` discriminator field for unions.
  - **`additionalProperties: false`** required.
  - **No recursion deeper than 5 levels.** No self-`$ref`.
- **Generate schemas from Pydantic / Zod / Valibot.** Don't hand-write. `pydantic.json_schema()` + `from openai.lib._pydantic import to_strict_json_schema` (Python); `z.toJSONSchema()` and OpenAI's `zodResponseFormat` helper (TS).
- **Tool call args are still JSON-encoded strings on [Chat Completions](/stacks/openai/chat-completions/)** even with `strict: true`. Only [Responses API](/stacks/openai/responses-api/) returns parsed objects.
- **`refusal` field** on the response (Responses API) explicitly surfaces refused outputs separately from regular content.

## Patterns

### Pattern: response_format (Chat Completions)

```python
class Invoice(BaseModel):
    invoice_id: str
    total: float
    line_items: list[LineItem]

response = client.chat.completions.create(
    model="gpt-5-mini",
    messages=[...],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "Invoice",
            "strict": True,
            "schema": Invoice.model_json_schema(),
        },
    },
)
invoice = Invoice.model_validate_json(response.choices[0].message.content)
```

### Pattern: response_format (Responses API)

Responses returns the parsed object directly via `text.format`:

```python
response = client.responses.create(
    model="gpt-5",
    instructions="Extract invoice fields...",
    input=[...],
    text={
        "format": {
            "type": "json_schema",
            "name": "Invoice",
            "strict": True,
            "schema": Invoice.model_json_schema(),
        },
    },
)
# Parsed object available directly
```

### Pattern: tool with strict params

```python
{
    "type": "function",
    "function": {
        "name": "create_ticket",
        "parameters": Ticket.model_json_schema(),
        "strict": True,
    },
}
```

The arguments the model emits will conform to the Pydantic Ticket schema.

### Pattern: discriminated union via `kind` field

Strict mode doesn't allow top-level `oneOf`. Model unions as:

```python
class CreateAction(BaseModel):
    kind: Literal["create"]
    title: str

class DeleteAction(BaseModel):
    kind: Literal["delete"]
    id: str

class Action(BaseModel):
    kind: Literal["create", "delete"]
    title: str | None = None
    id: str | None = None
```

The `kind` field tells the consumer how to interpret the rest.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Free-form JSON parsing with try/except retry loops | `strict: true` + Pydantic / Zod schema. |
| Hand-writing JSON schema | Generate from Pydantic / Zod. |
| Optional fields (not in `required`) | All fields required; use nullable types. |
| `oneOf` at top level | Discriminator field (`kind: ...`). |
| Skipping strict on tool params | Add `strict: true`. Tool args should be schema-compliant. |
| Assuming Chat Completions returns parsed tool args | They're JSON-encoded strings; `JSON.parse()` always. |
| Deep recursion (>5 levels) | Refactor schema; flatten. |
| Streaming + try-parse partial JSON manually | Use a partial parser (`useObject`) or buffer until done. |

## Gotchas

- **All fields required, even logically-optional ones.** Use nullable types: `Optional[str]` → `["null", "string"]`.
- **`oneOf` not at top level.** Discriminator pattern.
- **`additionalProperties: false`** is required. Don't allow extra keys.
- **Recursion limit is ~5 levels.** Self-`$ref` is disallowed.
- **Tool args still strings on Chat Completions.** Parse them.
- **First-time schema validation** can add latency on Responses (~hundreds of ms). Cached after that.
- **Refusals come back via `refusal` field** on Responses; explicit handling required.
- **Streaming JSON** arrives token by token; cannot `JSON.parse()` until stream completes.

## Cross-references

### Related products in this Stack

- [Function calling / tool use](/stacks/openai/function-calling/) — tool params use strict mode.
- [Responses API](/stacks/openai/responses-api/) — parsed output via `text.format`.
- [Chat Completions API](/stacks/openai/chat-completions/) — JSON-encoded strings even with strict.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — schema design.
- [backend-architect](/stacks/openai/backend-architect/) — parsing + validation pipelines.

### Authoritative sources

- [Structured Outputs guide](https://platform.openai.com/docs/guides/structured-outputs)
- [Function calling guide](https://platform.openai.com/docs/guides/function-calling)
