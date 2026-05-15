---
title: Dynatrace OneAgent
description: Single-binary agent that auto-instruments every process on the node — library injection + eBPF. Highest "deploy and forget" factor.
product:
  name: Dynatrace OneAgent
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://docs.dynatrace.com/docs/setup-and-configuration/dynatrace-oneagent
  notes: "1.300+ as of 2026; K8s deployment improving each quarter; library injection model stable; invasive — compliance review needed."
---

## What it is

Dynatrace OneAgent is a single binary that installs on each node and auto-instruments every process — library injection for app frameworks, eBPF for syscall/network, cgroup-aware container visibility. The most "deploy and forget" agent in the observability space. See [docs.dynatrace.com](https://docs.dynatrace.com/docs/setup-and-configuration/dynatrace-oneagent).

## When to use

Pick OneAgent when:
- You're committed to Dynatrace.
- You want auto-instrumentation without per-language SDK setup.
- The team's bandwidth for instrumentation work is limited.

Don't pick if:
- Compliance regimes (FedRAMP High, certain HIPAA BAAs) require explicit approval of invasive agents.
- You want vendor portability (OneAgent is Dynatrace-specific).

## 2025-2026 currency anchors

- **OneAgent 1.300+** as of 2026-Q2.
- **K8s deployment improving** via Dynatrace Operator (`DynaKube` CRD) — improvements each quarter.
- **`cloudNativeFullStack`** deployment mode is the K8s default.

## Patterns

- **Dynatrace Operator** with `DynaKube` CRD deploys OneAgent + ActiveGate.
- **ActiveGate** as the cluster-level routing/aggregation node.
- **OneAgent for runtime + ActiveGate for cluster-level concerns** (K8s API monitoring).

## Anti-patterns

- **OneAgent + OTel parallel for same data** — pick one for the same signal.
- **OneAgent in PSS `restricted` namespaces** without exception — won't schedule.

## Gotchas

- **OneAgent is invasive** — auto-instruments via library injection. Compliance regimes require explicit approval.
- **DDU billing model** — GiB-hour with 4 GiB floor per host means small containers cost the same as 4 GiB hosts.
- **Kernel module loading** restrictions on some managed K8s — check before promising.

## Cross-references

- [Dynatrace Davis AI](/stacks/observability/dynatrace-davis-ai/) (root-cause AI)
- [Dynatrace Grail + DQL](/stacks/observability/dynatrace-grail-dql/) (data lakehouse)
- Security review → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.dynatrace.com](https://docs.dynatrace.com/)
