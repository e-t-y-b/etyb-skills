---
title: Workers Logs
description: "Queryable persistent logs for Workers — `console.log` lands in a searchable store, filterable by request, status, version, and custom fields."
product:
  name: Workers Logs
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, backend-architect, sre-engineer]
  authoritative_url: https://developers.cloudflare.com/workers/observability/logs/
  notes: "Replaced legacy 'Logpush every Worker invocation for debugging' pattern in 2024-25; sampling and retention controls still evolving."
---

## What it is

Workers Logs is Cloudflare's queryable, persistent log store for [Workers](/stacks/cloudflare/workers/). Enable it in `wrangler.toml` and every `console.log()` / `console.error()` lands in a store you can query from the Cloudflare dashboard — filter by time, request URL, status code, Worker name, version, and custom fields. Replaces the older pattern of fanning every Worker invocation out to a third-party SIEM for casual debugging.

Authoritative reference: [developers.cloudflare.com/workers/observability/logs](https://developers.cloudflare.com/workers/observability/logs/).

## When to use

- **Every Worker should have it on** unless there's a specific reason not to.
- **Casual debugging** — "why did this request 500" — query by time + status, find the offending invocation, read the structured log.
- **Per-version comparisons** — Workers Logs distinguishes by version ID; useful during a [Versions](/stacks/cloudflare/wrangler/) rollout to check error rate on the new vs old version.
- **Sampling at high QPS** to control cost while keeping signal on errors.

For long retention and SIEM fan-out, complement with [Logpush](/stacks/cloudflare/logpush/) on the `workers_trace_events` dataset.

## 2025-2026 currency anchors

- **`observability.logs.enabled = true`** in `wrangler.toml` is the canonical activation; `head_sampling_rate` and `invocation_logs` are the main knobs.
- **Invocation-level sampling** — a sampled invocation logs everything, an unsampled one logs nothing; pick wisely if you want errors always-captured.
- **Replaced the legacy "tail Worker to a third-party logger for every request" pattern** for routine debugging. `wrangler tail` is still useful for live streams; Workers Logs is the queryable backing store.

## Patterns

### Enable with sampling

```toml
[observability]
[observability.logs]
enabled = true
head_sampling_rate = 1.0   # 1.0 = 100%; 0.1 = 10%; etc.
invocation_logs = true
```

For a Worker doing 1000 req/sec, full sampling produces a lot of data — set `head_sampling_rate = 0.1` and log errors with `console.error()` (errors always sampled in many configs; verify current behavior).

### Structured logs

```ts
console.log(JSON.stringify({
  event: "order_created",
  order_id: order.id,
  tenant_id: tenantId,
  total_cents: order.total_cents
}));
```

Workers Logs supports filtering on structured fields if you log JSON consistently. Adopt a logging convention (a `log()` helper that always emits JSON) early.

### Errors always, successes sampled

```ts
try {
  // ...
  if (Math.random() < 0.1) console.log({ event: "ok", request_id });
} catch (e) {
  console.error({ event: "fail", error: String(e), stack: (e as Error).stack, request_id });
  throw e;
}
```

Cheaper than full sampling but you don't miss errors.

### Filter in the dashboard

The Workers Logs UI in the Cloudflare dashboard supports filters like `status >= 500`, `worker_version = abc123`, `url contains "/api/orders"`, and custom-field filters when you log JSON.

## Anti-patterns

- **Logging full request bodies / response bodies / secrets.** Workers Logs has retention; sensitive data leaks become long-lived.
- **`console.log` with raw strings.** Hard to filter, hard to query, hard to alert. Log JSON.
- **Skipping Workers Logs and going straight to Logpush.** Logpush has setup cost, a destination cost, and slower turnaround for "what just happened." Workers Logs is the first reach.
- **Sampling at 100% on a 10k-req/sec Worker.** Cost adds up; sample.

## Gotchas

1. **Retention is plan- and dataset-dependent.** Workers Logs is queryable in-dashboard for a window (days to weeks); for SOC 2-style retention, fan via [Logpush](/stacks/cloudflare/logpush/) to long-term storage.
2. **No transactional alerting** built in — Workers Logs is for querying, not real-time alerting. For alerts, push relevant signals to [Analytics Engine](/stacks/cloudflare/analytics-engine/) or external monitoring.
3. **Versions tag matters.** If you don't use [Versions](/stacks/cloudflare/wrangler/) for rollouts, you'll see all logs under one version — diagnosis becomes "which commit was deployed when this fired."
4. **PII discipline.** Workers Logs is internal-only by default, but if you ever Logpush it externally, redact before logging.

## Cross-references

- [Wrangler](/stacks/cloudflare/wrangler/) — `wrangler tail` complements Workers Logs for live streaming
- [Logpush](/stacks/cloudflare/logpush/) — long-retention fan-out of the same dataset
- [Analytics Engine](/stacks/cloudflare/analytics-engine/) — metrics counterpart
- [Workers](/stacks/cloudflare/workers/) — runtime emitting the logs
- Role overlay: [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/workers/observability/logs](https://developers.cloudflare.com/workers/observability/logs/), [Tail Workers](https://developers.cloudflare.com/workers/observability/logs/tail-workers/)
