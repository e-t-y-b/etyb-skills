---
title: Sentry Profiling
description: Sampling profiler inside the Sentry SDK — CPU + memory flame graphs attached to spans. Profiling v2 reshaped pricing 2025.
product:
  name: Sentry Profiling
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer]
  authoritative_url: https://docs.sentry.io/product/profiling/
  notes: "Profiling v2 (2025) reshape; languages added quarterly; attached to spans for correlation."
---

## What it is

Sentry Profiling runs a sampling profiler alongside the Sentry SDK, captures CPU + memory call stacks, attaches profiles to performance spans for one-click correlation. See [docs.sentry.io/product/profiling](https://docs.sentry.io/product/profiling/).

## When to use

Pick Sentry Profiling when:
- You're on [Sentry Performance](/stacks/observability/sentry-performance/) and want profile↔trace correlation in one UI.
- CPU-bound regression hunting matters.

Alternatives: [Datadog Profiling](/stacks/observability/datadog-apm/), [Grafana Pyroscope](/stacks/observability/grafana-pyroscope/), Splunk APM Profiling.

## 2025-2026 currency anchors

- **Profiling v2 (2025)** — pricing model reshape.
- **Languages added quarterly** — Python, Node, Browser JS, iOS/Android, Go, Ruby, .NET coverage.

## Patterns

- **`profilesSampleRate: undefined`** — let dynamic sampling decide.
- **Profile sampling rate `0.1`** for steady traffic, raise for active investigation.

## Anti-patterns

- **100% profiling sample rate** without budget — overhead + bill.
- **Profiling I/O-bound services** — most time is syscall wait; profile misleads.

## Gotchas

- **Profiling overhead is real** — measure before/after on hot paths.
- **Symbolication requires debug info** for compiled languages.

## Cross-references

- [Sentry Performance](/stacks/observability/sentry-performance/)
- Alternative: [Pyroscope](/stacks/observability/grafana-pyroscope/), [Datadog APM Profiling](/stacks/observability/datadog-apm/)
- Authoritative: [docs.sentry.io/product/profiling](https://docs.sentry.io/product/profiling/)
