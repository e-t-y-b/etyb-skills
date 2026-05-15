---
title: Grafana Pyroscope
description: Continuous profiling — CPU + memory call-stack samples aggregated. OSS + Grafana Cloud Profiles. OTel Profiles convergence.
product:
  name: Grafana Pyroscope
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, backend-architect, devops-engineer]
  authoritative_url: https://grafana.com/docs/pyroscope/
  notes: "Continuous profiling went GA; OTel Profiles spec convergence in 2025-26; OSS + Grafana Cloud."
---

## What it is

Pyroscope is the OSS continuous profiling system: per-second CPU samples and memory allocations, aggregated across instances, queryable in Grafana. Supports Go, Java, Python, Ruby, Node, .NET, Rust, eBPF-based collection. See [grafana.com/docs/pyroscope](https://grafana.com/docs/pyroscope/).

## When to use

Pick Pyroscope when:
- You're in the Grafana ecosystem.
- CPU-bound regression hunting, GC tuning, memory-leak debugging matters.
- You want OSS over vendor-locked profiling.

Alternatives: [Datadog Continuous Profiling](/stacks/observability/datadog-apm/), [Sentry Profiling](/stacks/observability/sentry-profiling/), Splunk APM Profiling, Parca (OSS).

Profiling is not useful for I/O-bound services — use APM tracing instead.

## 2025-2026 currency anchors

- **GA** continuous profiling.
- **OTel Profiles spec convergence** — Pyroscope ingests OTel profile format alongside its native format (2025-2026).
- **Grafana Cloud Profiles** is the managed offering.
- **eBPF profiling** for kernel + user-space sampling without language SDK.

## Patterns

- **SDK-based profiling per language** for in-process visibility.
- **eBPF profiling** for legacy / unowned services.
- **Correlate profile to trace span** when investigating slow operations.

## Anti-patterns

- **Profiling I/O-bound services** — most time is in syscall wait; profile shows the network library, not the bug. Use APM tracing.
- **Profiling at 100% always-on without budget** — sample cost adds up at high core counts.

## Gotchas

- **Symbolication overhead** for compiled languages (Go, Rust) — debug info must be available.
- **Comparison views** (before/after deploy) are the highest-value workflow; learn them.

## Cross-references

- OTel Profiles spec → [opentelemetry](/stacks/observability/opentelemetry/)
- DD Profiling (alternative) → [datadog-apm](/stacks/observability/datadog-apm/)
- Sentry Profiling → [sentry-profiling](/stacks/observability/sentry-profiling/)
- Authoritative: [grafana.com/docs/pyroscope](https://grafana.com/docs/pyroscope/)
