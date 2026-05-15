---
title: Datadog LLM Observability
description: LLM and agent telemetry — prompt inspection, completion analytics, evaluators, cost tracking. Ingests OTel GenAI natively.
product:
  name: Datadog LLM Observability
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, sre-engineer]
  authoritative_url: https://docs.datadoghq.com/llm_observability/
  notes: "GA 2024; evaluator surface + provider list iterating quarterly; ingests OTel GenAI semconv natively (2025)."
---

## What it is

Datadog LLM Observability captures LLM and agent telemetry — prompts, completions, token usage, cost, latency (TTFT, TTC), tool-call traces, evaluator scores — and renders them in a dedicated UI. GA'd 2024; **ingests OTel GenAI semantic conventions natively** as of late 2025. See [docs.datadoghq.com/llm_observability](https://docs.datadoghq.com/llm_observability/).

Provider coverage: OpenAI, Anthropic, AWS Bedrock, Google Vertex AI, Azure OpenAI, Cohere, Mistral, Together, and any custom OTel GenAI-tagged span.

## When to use

Pick DD LLM Obs when:
- You're already on Datadog APM and want LLM correlation.
- You want managed evaluators (hallucination, toxicity, prompt injection) without standing up Langfuse.
- Cost tracking matters and you want $/request as a first-class metric.

Alternatives:
- **Langfuse** — OSS, purpose-built; OTel-compatible. Best for dev-team-led, self-hosted.
- **LangSmith** — LangChain's tracing; OTel-compatible.
- **[New Relic AI Monitoring](/stacks/observability/newrelic-ai-monitoring/)** — similar surface.
- **Helicone** — proxy-based, simple.
- **[Honeycomb](/stacks/observability/honeycomb-events/)** — event model handles high-cardinality LLM spans natively.

## 2025-2026 currency anchors

- **OTel GenAI native ingestion** (late 2025) — instrument with [otel-genai](/stacks/observability/otel-genai/), see in DD LLM Obs without custom tags.
- **Evaluator surface** — managed evaluators for hallucination, toxicity, prompt-injection scoring. Iterates quarterly.
- **Agent traces** — multi-step agent spans (plan, tool, reflect) rendered as agent timelines.
- **Cost analytics** — `gen_ai.cost.usd` or DD-computed cost surfaces as a SLI dimension.

## Patterns

- **Instrument with OTel GenAI**, not DD-proprietary tags — vendor portability preserved.
- **Keep 100% sampling** on LLM traces — volume is low (rate-limited by $/call), value is high.
- **Don't log full prompts** in span attributes — PII, payload size, cost. Hash or truncate.
- **TTFT and TTC as separate SLIs** — see [sre-engineer overlay](/stacks/observability/sre-engineer/) LLM section.
- **Tool-call success rate** as an agent SLI — `agent.tool.success` attribute aggregated as a counter.

## Anti-patterns

- **Vendor-proprietary tags first, OTel later** — repeat of the SDK migration trap.
- **Sampling LLM traces** — defeats debugging value.
- **No cost SLO** — for LLM-heavy products, $/request is the first-class SLI.
- **Treating LLM as HTTP** — `p99 latency < 1s` for a 4096-token completion is impossible.

## Gotchas

- **Evaluators cost extra** — managed evaluators are billed separately; check pricing before enabling for all traffic.
- **Prompt logging defaults are conservative** — most installs disable prompt-body capture for PII reasons; sample or hash.
- **Agent conventions still drafting** — `agent.step.*` attributes work but are not yet in OTel spec proper.

## Cross-references

- OTel GenAI schema → [otel-genai](/stacks/observability/otel-genai/)
- LLM SLO design (TTFT, TTC, cost, quality) → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Instrumentation patterns per language → [backend-architect overlay](/stacks/observability/backend-architect/)
- Alternative: New Relic AI Monitoring → [newrelic-ai-monitoring](/stacks/observability/newrelic-ai-monitoring/)
- Authoritative: [docs.datadoghq.com/llm_observability](https://docs.datadoghq.com/llm_observability/)
