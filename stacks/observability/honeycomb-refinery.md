---
title: Honeycomb Refinery
description: Tail-based sampling proxy for the Honeycomb event pipeline. Keep 100% of errors + slow traces, ~1% baseline. Memory-tuned.
product:
  name: Honeycomb Refinery
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://docs.honeycomb.io/manage-data-volume/refinery/
  notes: "Refinery 2.x; tail-sampling memory + rules evolving; standard pattern at >10K events/sec."
---

## What it is

Refinery is Honeycomb's tail-based sampling proxy — sits between your apps/Collector and Honeycomb, holds traces in memory until completion, applies sampling rules with full trace context. **Standard pattern for >10K events/sec** since 2025. See [docs.honeycomb.io/manage-data-volume/refinery](https://docs.honeycomb.io/manage-data-volume/refinery/).

## When to use

Run Refinery when:
- You're on Honeycomb at >10K events/sec.
- Random head sampling is throwing away interesting traces.
- Paying Honeycomb's per-event rate hurts.

Alternative: tail-sampling in [OTel Collector](/stacks/observability/otel-collector/). Refinery is more memory-efficient for Honeycomb specifically.

## 2025-2026 currency anchors

- **Refinery 2.x** — performance improvements, better memory management.
- **Sampling rules evolving** — per-service, per-error-class rates configurable.

## Patterns

- **Keep 100% errors + 100% slow + ~1% baseline.**
- **Memory configuration** — `MaxMemoryPercentage: 75` works for moderate scale; tune for very high volume.
- **Sampling rules** per-service-per-status-class.

## Anti-patterns

- **Random head sampling at 1%** with Honeycomb's per-event pricing — keeps the wrong traces.
- **Refinery with too little memory** — drops traces under load.
- **Sampling 100% at high volume** without Refinery — bill explosion.

## Gotchas

- **Refinery is stateful** — holds incomplete traces in memory. Restart loses in-flight traces.
- **Memory sizing scales with span volume × decision_wait window** — model and test before scale.
- **Decision logic ordering** — first matching rule wins.

## Cross-references

- Honeycomb base → [honeycomb-events](/stacks/observability/honeycomb-events/)
- OTel tail-sampling alternative → [otel-collector](/stacks/observability/otel-collector/)
- Sampling strategy → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.honeycomb.io/manage-data-volume/refinery](https://docs.honeycomb.io/manage-data-volume/refinery/)
