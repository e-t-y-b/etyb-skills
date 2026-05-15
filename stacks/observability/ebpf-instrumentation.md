---
title: eBPF Auto-Instrumentation
description: Kernel-level instrumentation without code changes — Grafana Beyla, NR Pixie, Datadog USM, Cilium Tetragon.
product:
  name: eBPF Auto-Instrumentation
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://ebpf.io/
  notes: "Beyla/Pixie/USM/Tetragon evolving; capabilities + PSS interactions stable; kernel version constraints unchanged."
---

## What it is

eBPF (extended Berkeley Packet Filter) lets agents instrument the Linux kernel itself — syscalls, network packets, function entries — without modifying application code. In observability, eBPF agents produce service-level **RED metrics** + **L7 traces** for HTTP, gRPC, MySQL, Redis, Postgres, DNS by sniffing kernel events.

Major vendors:
- **[Grafana Beyla](/stacks/observability/grafana-beyla/)** — open source, OTel-native output.
- **[New Relic Pixie](/stacks/observability/newrelic-pixie/)** — acquired by NR; PxL DSL for custom scripts.
- **Datadog Universal Service Monitoring (USM)** — bundled with Datadog Agent + system-probe (see [Datadog APM](/stacks/observability/datadog-apm/)).
- **Cilium Tetragon** — security-focused (process exec, network events, file access).
- **Falco** — security events at syscall level.

## When to use

eBPF auto-instrumentation pays back when:
- **Legacy services** you can't easily redeploy with an OTel SDK.
- **Third-party binaries** (databases, proxies, caches, vendor appliances).
- **Adoption acceleration** — get RED metrics from 100 services in a day, then add OTel SDKs over weeks.

When it doesn't:
- **Business attributes** — eBPF sees HTTP method/path/status, not your `customer_id` or `cart_total`. Add OTel for product analytics.
- **Internal logic** — eBPF can't see "the retry logic kicked in" or "the cache hit path took the early return." That's an in-process span.
- **TLS-encrypted traffic** — eBPF sees metadata (5-tuple, sizes) but not plaintext. Some tools (Pixie) do user-space TLS keylog hooks for Go/Node/Python — verify with security.

Pair eBPF for infra/legacy + OTel SDK for new services. Don't pick one and skip the other.

## 2025-2026 currency anchors

- **CIS Benchmarks for eBPF collectors** landed late 2025 — operational hardening checklist.
- **OneAgent** (Dynatrace) and **Datadog system-probe** both use eBPF for portions of their instrumentation.
- **Cilium Tetragon** became the leading security-focused eBPF in 2025 — runtime detection paired with eBPF datapath.

## Patterns

### Privileges and PSS

All eBPF agents need elevated capabilities:

| Tool | Capabilities | Notes |
|---|---|---|
| Beyla | `CAP_SYS_ADMIN` or `CAP_BPF + CAP_PERFMON` | hostPID for process visibility |
| Pixie | `CAP_BPF, CAP_PERFMON, hostPID` | Includes TLS keylog hooks |
| Datadog USM | `CAP_SYS_ADMIN` (via system-probe DaemonSet) | Bundled with DD Agent |
| Cilium Tetragon | `CAP_BPF + CAP_PERFMON` | Security-event focus |
| Falco | `CAP_SYS_ADMIN` | Kernel module or eBPF mode |

**Pod Security Standards `restricted` profile blocks all of these.** Use `baseline` or `privileged` in a dedicated namespace with admission webhook exceptions. Default-deny in PSS for PCI/HIPAA workloads; opt-in per namespace.

### Kernel version constraints

- Beyla: 5.8+
- Pixie: 5.4+
- Tetragon: 5.4+
- Datadog system-probe: kernel headers required on host OS in some versions
- AKS, GKE, EKS may lock kernel module loading — check before promising eBPF features.

### Deployment shape

DaemonSet, one pod per node, mounts `/sys/kernel/debug` (for some) and uses `hostPID` to see all processes. Typically uses 200-500MB memory per node.

## Anti-patterns

- **eBPF as the only instrumentation** — you lose business attributes, retry logic visibility, internal span events. Pair with OTel SDK.
- **Running eBPF agent without security review** — node-level visibility on every workload. Compromise = breach.
- **Default-allowing eBPF in PSS `restricted` namespaces** — broken contract with the platform team.
- **Not pinning the eBPF agent image** — kernel-level agents are critical-tier supply chain. Use Cosign verification, SBOM scans.

## Gotchas

- **TLS visibility varies by tool and runtime.** Pixie can decrypt Go, Node, Python TLS via user-space keylog hooks; Beyla and Datadog USM see only 5-tuple. Verify your security team accepts the visibility model before deploying.
- **eBPF agent compromise impact is severe** — treat agent images as critical-tier supply chain (SBOM verification, signed images, Cosign).
- **Auto-instrument coverage is L7-protocol-specific** — HTTP/1, HTTP/2, gRPC, MySQL, Redis, Postgres, MongoDB, DNS commonly supported. Custom protocols won't decode.
- **Some compliance regimes (FedRAMP High, certain HIPAA BAAs) require explicit approval** of OneAgent or DD system-probe behavior.

## Cross-references

- Datadog USM details → [datadog-apm](/stacks/observability/datadog-apm/)
- NR Pixie deep dive → [newrelic-pixie](/stacks/observability/newrelic-pixie/)
- Grafana Beyla details → [grafana-beyla](/stacks/observability/grafana-beyla/)
- Security review framework → [security-engineer overlay](/stacks/observability/security-engineer/)
- Operational deployment → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [ebpf.io](https://ebpf.io/), [Cilium docs](https://docs.cilium.io/)
