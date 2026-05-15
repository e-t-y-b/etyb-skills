---
title: New Relic AI Monitoring
description: NR's LLM observability surface — prompt/completion traces, token usage, latency, evaluators. Native OTel GenAI + Pixie integration.
product:
  name: New Relic AI Monitoring
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, sre-engineer]
  authoritative_url: https://docs.newrelic.com/docs/ai-monitoring/
  notes: "GA 2024; OTel GenAI ingestion expanding; Pixie eBPF for LLM API calls."
---

## What it is

New Relic AI Monitoring captures LLM telemetry — prompts, completions, token usage, TTFT/TTC, cost — and renders in a dedicated NR surface. Ingests OTel GenAI semantic conventions and integrates with [Pixie](/stacks/observability/newrelic-pixie/) for eBPF-captured LLM API calls. See [docs.newrelic.com/docs/ai-monitoring](https://docs.newrelic.com/docs/ai-monitoring/).

## When to use

Pick NR AI Monitoring when:
- You're on [NR APM](/stacks/observability/newrelic-apm/) and want LLM correlation.
- Pixie eBPF on K8s gives you LLM API instrumentation without code changes.

Alternatives: [Datadog LLM Observability](/stacks/observability/datadog-llm-observability/), Langfuse (OSS), LangSmith, [Honeycomb](/stacks/observability/honeycomb-events/).

## 2025-2026 currency anchors

- **GA 2024**.
- **OTel GenAI ingestion** for `gen_ai.*` attributes.
- **Pixie integration** captures LLM API HTTP calls without SDK changes (best for legacy proxies / vendor SDKs).
- **Evaluators** for hallucination / toxicity scoring landing 2025-2026.

## Patterns

- **Instrument with [OTel GenAI](/stacks/observability/otel-genai/)**, not vendor-proprietary tags.
- **Keep 100% sampling** — LLM volume is low, value is high.
- **Track $/request as a SLI** — cost SLO is first-class for LLM-heavy products.

## Anti-patterns

- **Treating LLM as HTTP** — separate TTFT/TTC SLIs; cost SLO.
- **Vendor-proprietary tags first** — migration trap repeats.
- **Sampling LLM traces** — defeats debugging.

## Gotchas

- **Pixie eBPF visibility** — TLS-encrypted LLM API calls require Pixie's user-space keylog (Go/Node/Python).
- **NRQL queries on AI events** count against CU budget.

## Cross-references

- OTel GenAI schema → [otel-genai](/stacks/observability/otel-genai/)
- NR APM → [newrelic-apm](/stacks/observability/newrelic-apm/)
- Pixie → [newrelic-pixie](/stacks/observability/newrelic-pixie/)
- LLM SLO design → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.newrelic.com/docs/ai-monitoring](https://docs.newrelic.com/docs/ai-monitoring/)
