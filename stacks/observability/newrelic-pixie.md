---
title: New Relic Pixie
description: eBPF auto-instrumentation for K8s under New Relic — HTTP, MySQL, Redis, Postgres, gRPC, DNS without code changes. PxL scripting.
product:
  name: New Relic Pixie
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://docs.px.dev/
  notes: "Under New Relic since acquisition; auto-instrument coverage expanding; PxL DSL out of scope for most ETYB engagements."
---

## What it is

Pixie is an eBPF-based observability platform for K8s, acquired by New Relic and now bundled with NR's K8s integration. Auto-instruments HTTP, MySQL, Redis, Postgres, gRPC, DNS, and Kafka without code changes. Includes **PxL** — a Python-like DSL for custom telemetry scripts. See [docs.px.dev](https://docs.px.dev/) and [docs.newrelic.com/docs/kubernetes-pixie](https://docs.newrelic.com/docs/kubernetes-pixie/auto-telemetry-pixie/).

## When to use

Pick Pixie when:
- You're on New Relic and have K8s workloads you can't easily instrument with OTel SDKs.
- TLS visibility into Go/Node/Python services matters (Pixie has user-space keylog hooks).
- Adoption acceleration — get RED metrics from 100 services in a day.

Pair with [OTel SDK](/stacks/observability/opentelemetry/) for business attributes (Pixie sees protocol-level, not your `customer_id`).

## 2025-2026 currency anchors

- **Coverage expanded** to include LLM API calls (paired with [NR AI Monitoring](/stacks/observability/newrelic-ai-monitoring/)).
- **PxL DSL** stable but niche — most teams use Pixie's default scripts, not custom PxL.

## Patterns

- **Deploy via Helm sub-chart** as part of `nri-bundle`.
- **Use as a starter signal** — get coverage fast, then add OTel SDKs over weeks.
- **TLS visibility** — Pixie's keylog hooks see plaintext for Go/Node/Python; verify with security.

## Anti-patterns

- **Pixie as the only instrumentation** — loses business attributes, internal retry-logic visibility.
- **Custom PxL scripts** unless you have a real reason — maintenance burden.
- **Pixie + DD USM + Beyla** on the same node — three eBPF agents competing for kernel resources.

## Gotchas

- **Capabilities required**: `CAP_BPF`, `CAP_PERFMON`, `hostPID`. PSS-incompatible by default.
- **Kernel version**: 5.4+ required.
- **TLS keylog hooks** are runtime-specific — verify your security team accepts the visibility model.

## Cross-references

- General eBPF instrumentation → [ebpf-instrumentation](/stacks/observability/ebpf-instrumentation/)
- NR APM → [newrelic-apm](/stacks/observability/newrelic-apm/)
- Security review → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.px.dev](https://docs.px.dev/)
