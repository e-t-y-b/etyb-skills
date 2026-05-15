---
title: OTel GenAI Semantic Conventions
description: Cross-vendor schema for LLM and agent telemetry — gen_ai.system, gen_ai.usage.input_tokens, gen_ai.response.finish_reasons.
product:
  name: OTel GenAI
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, sre-engineer]
  authoritative_url: https://opentelemetry.io/docs/specs/semconv/gen-ai/
  notes: "Conventions landed 1.30-1.32 (2025-26); agent conventions still drafting; ingested natively by DD LLM Obs, NR AI Monitoring, Honeycomb, Langfuse."
---

## What it is

The OTel GenAI semantic conventions (semconv 1.30-1.32) define the attribute schema for LLM and agent telemetry — what to call `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, `gen_ai.response.finish_reasons`, and friends. See [opentelemetry.io/docs/specs/semconv/gen-ai](https://opentelemetry.io/docs/specs/semconv/gen-ai/).

This is the cross-vendor pivot for LLM observability — emit OTel GenAI attributes in your SDK, let the vendor mapping happen at the Collector. [Datadog LLM Observability](/stacks/observability/datadog-llm-observability/), [New Relic AI Monitoring](/stacks/observability/newrelic-ai-monitoring/), [Honeycomb](/stacks/observability/honeycomb-events/), and Langfuse all ingest these natively as of late 2025.

## When to use

For any production LLM endpoint or agent in 2026. Don't roll vendor-proprietary tags (Datadog `ml_app`, Langfuse `trace_id`, Sentry AI spans) — emit OTel GenAI and let vendor adapters translate. Migration cost between vendors becomes trivial.

## 2025-2026 currency anchors

- **semconv 1.30** (mid-2025) introduced base GenAI conventions.
- **semconv 1.32** (early 2026) added more comprehensive agent attributes (in draft as of 2026-Q2; pin 1.32 for stability).
- **Datadog LLM Observability ingests OTel GenAI natively** as of late 2025.
- **New Relic AI Monitoring**, **Honeycomb AI insights**, **Langfuse**, **Sentry AI Spans** all consume OTel GenAI.

## Patterns

### LLM call instrumentation

```python
with tracer.start_as_current_span("gen_ai.chat") as span:
    span.set_attribute("gen_ai.system", "anthropic")
    span.set_attribute("gen_ai.request.model", "claude-3-5-sonnet-20241022")
    span.set_attribute("gen_ai.request.temperature", 0.7)
    span.set_attribute("gen_ai.request.max_tokens", 4096)
    span.set_attribute("gen_ai.prompt.length", len(prompt))  # length, not content

    # ... call LLM, record TTFT, completion

    span.set_attribute("gen_ai.response.id", response.id)
    span.set_attribute("gen_ai.response.finish_reasons", [response.stop_reason])
    span.set_attribute("gen_ai.usage.input_tokens", response.usage.input_tokens)
    span.set_attribute("gen_ai.usage.output_tokens", response.usage.output_tokens)
    span.set_attribute("gen_ai.cost.usd", compute_cost(model, response.usage))
```

### Agent traces

Multi-step agents need agent spans (plan, tool selection, reflection) on top of LLM spans:

```python
with tracer.start_as_current_span("agent.execute"):
    for step in range(MAX_STEPS):
        with tracer.start_as_current_span("agent.step") as step_span:
            step_span.set_attribute("agent.step.number", step)
            with tracer.start_as_current_span("agent.plan"):
                next_action = await plan_next_action()
            if next_action.type == "tool_call":
                with tracer.start_as_current_span("agent.tool_call") as t:
                    t.set_attribute("agent.tool.name", next_action.tool_name)
                    t.set_attribute("agent.tool.success", result.success)
```

### Key attributes by category

- **Identity**: `gen_ai.system` (openai, anthropic, bedrock), `gen_ai.request.model`.
- **Request shape**: `gen_ai.request.temperature`, `gen_ai.request.top_p`, `gen_ai.request.max_tokens`.
- **Response**: `gen_ai.response.id`, `gen_ai.response.finish_reasons`.
- **Usage / cost**: `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, `gen_ai.cost.usd` (custom but conventional).
- **Latency**: `gen_ai.response.time_to_first_token_ms` for streaming (TTFT is its own SLI — see [sre-engineer overlay](/stacks/observability/sre-engineer/)).

## Anti-patterns

- **Putting the full prompt in a span attribute** — PII risk, payload size in spans (vendors may truncate or charge per byte), cost surprise. Hash, truncate, or send to a dedicated prompt-storage path.
- **Vendor-only tags** (`ml_app`, Langfuse `metadata`) instead of OTel GenAI — locks you in.
- **Treating LLM endpoint like HTTP endpoint** — `p99 latency < 1s` for a 4096-token completion is impossible. Latency SLI is TTFT and TTC, separately.
- **Sampling LLM traces** — keep 100%. Volume is low (LLM calls are expensive in dollars, so rate-limited by cost); value is high (debugging hallucinations, tool-call failures).

## Gotchas

- **Streaming responses** require manual TTFT recording — the first chunk callback sets `gen_ai.response.time_to_first_token_ms`.
- **`gen_ai.cost.usd` is conventional but not yet officially in spec** — most vendors accept and surface it. Compute from token counts × model pricing table.
- **Agent conventions still drafting (2026-Q2)** — `agent.step.number`, `agent.tool.name`, `agent.tool.success` are widely adopted in practice but pin them as custom `agent.*` attributes if strict spec compliance matters.

## Cross-references

- LLM observability SLIs (TTFT, TTC, cost SLO, quality SLO) → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Datadog LLM Observability product → [datadog-llm-observability](/stacks/observability/datadog-llm-observability/)
- New Relic AI Monitoring → [newrelic-ai-monitoring](/stacks/observability/newrelic-ai-monitoring/)
- LLM instrumentation patterns per language → [backend-architect overlay](/stacks/observability/backend-architect/)
- Authoritative: [opentelemetry.io/docs/specs/semconv/gen-ai](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
