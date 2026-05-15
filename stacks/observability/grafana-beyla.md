---
title: Grafana Beyla
description: eBPF auto-instrumentation by Grafana — HTTP server/client RED metrics + traces, no app code changes. OTel-native output.
product:
  name: Grafana Beyla
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://grafana.com/docs/beyla/
  notes: "Auto-instrumentation evolving rapidly; CAP_BPF + CAP_PERFMON; kernel 5.8+."
---

## What it is

Grafana Beyla is the Grafana stack's eBPF auto-instrumentation agent — produces HTTP server/client RED metrics, distributed traces, and database protocol metrics without app code changes. Ships as OTel-native output. See [grafana.com/docs/beyla](https://grafana.com/docs/beyla/).

## When to use

Pick Beyla when:
- You're in the Grafana ecosystem and have K8s workloads.
- Legacy services need instrumentation without redeploy.
- Adoption acceleration on a new platform.

Alternatives: [NR Pixie](/stacks/observability/newrelic-pixie/) (deeper protocol coverage), Datadog USM ([datadog-apm](/stacks/observability/datadog-apm/)), Cilium Tetragon (security-focused).

## 2025-2026 currency anchors

- **Rapidly evolving** — features land monthly through 2026.
- **OTel-native output** — ships traces and metrics via OTLP to any backend.
- **Protocol coverage**: HTTP/1, HTTP/2, gRPC, SQL, Redis growing.

## Patterns

- **DaemonSet on every node** with `CAP_BPF + CAP_PERFMON`.
- **Use as a starter signal** + add OTel SDKs for business attributes.
- **Output to OTel Collector** for routing.

## Anti-patterns

- **Beyla as the only instrumentation** — loses business attributes.
- **Beyla + Pixie + DD USM** on the same node — three eBPF agents competing.
- **No security review of capabilities** — node-level visibility.

## Gotchas

- **Kernel 5.8+** required.
- **PSS `restricted` profile blocks Beyla** — use `baseline` with admission exceptions.
- **TLS visibility limited** — sees 5-tuple, not plaintext (unlike Pixie's keylog hooks).

## Cross-references

- General eBPF instrumentation → [ebpf-instrumentation](/stacks/observability/ebpf-instrumentation/)
- Grafana Alloy as the collector tier → [grafana-alloy](/stacks/observability/grafana-alloy/)
- Security review → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [grafana.com/docs/beyla](https://grafana.com/docs/beyla/)
