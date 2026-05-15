---
title: Log Drains
description: Route runtime + build logs to Datadog, Axiom, Better Stack, Logtail, Splunk, CloudWatch, S3. Stable; the way to persist Vercel logs.
product:
  name: Log Drains
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, backend-architect]
  authoritative_url: https://vercel.com/docs/log-drains
  notes: "Stable. Route runtime + build logs externally. Marketplace integrations (Datadog, Axiom, etc.) auto-wire. Filter at destination to control cost."
---

## What it is

Log Drains forward Vercel runtime + build logs to external destinations: Datadog, Axiom, Better Stack, Logtail, AWS CloudWatch, S3, Splunk, custom HTTPS endpoints. Configured per-project in the Vercel dashboard. See [vercel.com/docs/log-drains](https://vercel.com/docs/log-drains).

## When to use

- **Any production project** — Vercel's built-in log retention is short; persist to a destination.
- **Compliance retention** — when you need months/years of log history.
- **SIEM integration** — Splunk, Datadog, etc., for unified observability.
- **Custom alerting** — log patterns trigger alerts at the destination, not at Vercel.

## 2025-2026 currency anchors

- **Stable.** Destinations + payload schema largely unchanged.
- **Marketplace integrations auto-wire** Log Drains for Datadog, Axiom, Better Stack.
- **Payload includes runtime + build logs** — you choose at the destination what to keep.

## Common destinations

- **Datadog** (via Marketplace) — auto-wires; unified logs/traces/metrics.
- **Axiom** — popular for Next.js; cheap; SQL-style query.
- **Better Stack / Logtail** — friendly UI.
- **AWS CloudWatch / S3** — for compliance / long retention.
- **Splunk** — enterprise.
- **Custom HTTPS endpoint** — for in-house aggregators.

## Patterns + anti-patterns

**Pattern: Marketplace install for Datadog/Axiom** — auto-wires the Log Drain.

**Pattern: Filter at destination.** Don't ship every `console.log` to Datadog; filter on the destination side to control cost.

**Pattern: Pair with `@vercel/otel`** — Log Drains for logs; OTel for traces; together they cover observability.

**Pattern: Log redaction rules at destination** for PII handling.

**Anti-pattern: No Log Drain.** Vercel's built-in log retention is short; without a drain, you lose history for incident analysis.

**Anti-pattern: Shipping everything unfiltered.** Volume-based pricing at destinations makes uncontrolled shipping expensive.

**Anti-pattern: Treating logs as primary observability.** Tracing (OTel) is for understanding flow; logs are for grep-after-the-fact. Both matter.

## Gotchas

- **Log Drain payload format** is JSON; verify destination compatibility.
- **Build vs runtime logs** are both in the drain — filter accordingly at destination.
- **PII in logs** is your responsibility — redact at source or destination.
- **Drains can be rate-limited** at the destination — verify capacity.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — produces logs
- [Speed Insights](/stacks/vercel/speed-insights/) — separate RUM
- [Marketplace](/stacks/vercel/marketplace/) — Datadog / Axiom integrations
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — observability wiring
- Authoritative: [Log Drains docs](https://vercel.com/docs/log-drains)
