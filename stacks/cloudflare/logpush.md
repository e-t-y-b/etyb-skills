---
title: Logpush
description: Stream Cloudflare logs (HTTP requests, firewall events, Worker traces, Access logins, audit logs) to S3, R2, GCS, Datadog, Splunk, and other SIEMs.
product:
  name: Logpush
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, security-engineer, sre-engineer]
  authoritative_url: https://developers.cloudflare.com/logs/logpush/
  notes: "Per-dataset configs stable; destination catalog expands; per-Worker dataset deprecated in favor of Workers Logs for casual debugging."
---

## What it is

Logpush is the streaming-export path for Cloudflare logs. You configure a job per dataset (`http_requests`, `firewall_events`, `workers_trace_events`, `access_logins`, `audit_logs`, and many others) targeting an S3 / R2 / GCS bucket or a SIEM (Datadog, Splunk, Sumo, New Relic, Elastic). Cloudflare batches and pushes; you query in your destination.

Authoritative reference: [developers.cloudflare.com/logs/logpush](https://developers.cloudflare.com/logs/logpush/).

## When to use

- **Compliance retention** — SOC 2, ISO 27001, PCI, HIPAA all expect long-retention audit trails.
- **SIEM correlation** — joining Cloudflare events with origin / app logs in Datadog / Splunk.
- **Cold storage of high-volume data** in [R2](/stacks/cloudflare/r2/) for ad-hoc querying via [R2 SQL](/stacks/cloudflare/r2/) or Athena.
- **Streaming firewall + access events** to a SOC team's tooling.

Don't reach for Logpush when:

- You just want to look at a recent Worker error — use [Workers Logs](/stacks/cloudflare/workers-logs/) (queryable in-dashboard) or `wrangler tail` instead.
- Volume is low enough that the destination's free tier doesn't justify the setup.

## 2025-2026 currency anchors

- **[Workers Logs](/stacks/cloudflare/workers-logs/) replaced the old "push every Worker invocation to a logging vendor for casual debugging" pattern** — Logpush is now the right answer for fan-out + long retention, not for routine debugging.
- **R2 destination** is the cheapest for high-volume Cloudflare data (zero egress) — Cloudflare → R2 → Athena/R2 SQL is a common cost-optimal pattern.
- **Datadog Cloud Network Insights** integrates with Logpush datasets — useful when network-tier observability is the goal.

## Common datasets

| Dataset | What's in it | When you want it |
|---------|--------------|------------------|
| `http_requests` | Zone-level HTTP request logs (status, latency, country, ASN) | Traffic analytics, abuse forensics |
| `firewall_events` | WAF, Rate Limiting, Bot Management, custom rule hits | Security review, FP triage |
| `workers_trace_events` | Every Worker invocation (subrequests, console logs, errors) | Long-retention Worker tracing |
| `audit_logs` | Account-level admin actions | SOC 2, compliance |
| `access_logins` | Cloudflare Access auth events | ZTNA audit trail |
| `dns_logs` | DNS query logs | Threat hunting |
| `nel_reports`, `csp_reports` | Browser-emitted security reports | Browser-side telemetry |

## Patterns

### Standing four streams for security baseline

```bash
wrangler logpush create --dataset=firewall_events     --destination="..."
wrangler logpush create --dataset=access_logins       --destination="..."
wrangler logpush create --dataset=workers_trace_events --destination="..."
wrangler logpush create --dataset=audit_logs          --destination="..."
```

For a compliance-bound estate, these four are the minimum: edge security events, identity events, runtime events, account-level events.

### R2 destination for cheap retention

```
[Cloudflare datasets] -> [Logpush] -> [R2 bucket] -> [R2 SQL queries] / [Athena] / [Snowflake]
```

R2's zero-egress + bulk read pricing is the cheapest long-retention path.

### SIEM fan-out with filtering

```ts
// Logpush "filter" expression on the job
http.response.status >= 400 and http.response.status < 600
```

Only push 4xx / 5xx to your SIEM if cost matters; everything else to R2 cold storage.

## Anti-patterns

- **Pushing every dataset to your most expensive SIEM.** Volume × destination cost adds up fast — push cheap to R2, fan only what needs alerting to the SIEM.
- **No retention policy.** Compliance demands often dictate retention windows; configure destination lifecycle rules accordingly.
- **Forgetting the filter expression.** High-volume zones can produce gigabytes per hour on `http_requests`; filter aggressively if you don't need it all.
- **Logpush for Worker dev-loop debugging.** Use [Workers Logs](/stacks/cloudflare/workers-logs/) for that; Logpush is the long-retention path.

## Gotchas

1. **Per-job batching** — Logpush batches data on a configurable cadence (5-60 min typical); not real-time. For real-time signal, complement with Cloudflare Notifications.
2. **Destination credentials** are sensitive — manage as IaC inputs, not in the dashboard, when possible.
3. **Pricing** varies by dataset and plan — `audit_logs` is usually included; `workers_trace_events` and `http_requests` at high volume can add real cost.
4. **Field schemas evolve.** Cloudflare adds fields to datasets over time; downstream parsers should be schema-tolerant (avoid strict-mode unmarshalling).

## Cross-references

- [Workers Logs](/stacks/cloudflare/workers-logs/) — dashboard-side queryable logs; complementary
- [Analytics Engine](/stacks/cloudflare/analytics-engine/) — custom metrics from Workers
- [R2](/stacks/cloudflare/r2/) — cheap log destination
- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — `firewall_events` source
- [Access (ZTNA)](/stacks/cloudflare/access/) — `access_logins` source
- Role overlay: [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/), [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/)
- Authoritative: [developers.cloudflare.com/logs/logpush](https://developers.cloudflare.com/logs/logpush/), [Logpush datasets](https://developers.cloudflare.com/logs/reference/log-fields/)
