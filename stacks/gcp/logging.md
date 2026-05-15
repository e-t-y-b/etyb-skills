---
title: Cloud Logging
description: GCP's centralized log management — Log Analytics (BigQuery SQL on logs), structured logging, log-based metrics, org-level aggregated sinks. Telemetry API auto-enabled March 2026.
product:
  name: Cloud Logging
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, security-engineer, devops-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/logging/docs
  notes: "Log Analytics GA; Telemetry API auto-enabled for new projects from March 2026; OTLP ingestion GA; trace sinks deprecated Feb 2026."
---

## What it is

Cloud Logging is GCP's centralized log management — ingests logs from every GCP service automatically, plus your apps via structured logging or OpenTelemetry. **Log Analytics** queries logs with SQL (BigQuery-based, no separate export). **Log-based metrics** convert log entries into Cloud Monitoring metrics for alerting.

Authoritative reference: [cloud.google.com/logging/docs](https://cloud.google.com/logging/docs).

## When to use

Cloud Logging is universal — every GCP service writes logs here by default. The decisions:

- **Structured vs unstructured logs** — always structured (JSON) for queryability
- **Log Analytics** vs **export-to-BigQuery** — Log Analytics queries in-place; legacy export is wasteful
- **Log-based metrics** vs **OTLP metrics** — log-based metrics for pattern-based alerting (specific log strings); OTLP for general metrics
- **Org-level aggregated sink** for audit logs — mandatory in regulated orgs

## 2025-2026 currency anchors

- **Log Analytics GA** — BigQuery SQL on logs without separate export.
- **Telemetry API auto-enabled** for new projects after March 2026; consolidates logging + monitoring + trace ingestion.
- **OTLP ingestion** for logs is GA; pair with Ops Agent / Managed OTel for GKE.
- **Trace sinks deprecated Feb 2026** — for traces, migrate to Observability Analytics via Telemetry API.
- **Legacy Monitoring Agent / Logging Agent are deprecated** — Ops Agent v2.37+ is the unified collector.

## Patterns

### Structured logging in code

```python
import logging
from google.cloud.logging.handlers import StructuredLogHandler

logger = logging.getLogger()
logger.addHandler(StructuredLogHandler())

logger.info(
    "Order processed",
    extra={
        "json_fields": {
            "order_id": "12345",
            "customer_id": "67890",
            "amount_cents": 9999,
            "trace": "projects/proj/traces/abc123",  # auto-correlates with Cloud Trace
        }
    },
)
```

The `trace` field auto-correlates log entries with Cloud Trace spans; clicking a trace shows linked logs.

### Log Analytics — SQL on logs

```sql
SELECT
  jsonPayload.error_type,
  COUNT(*) AS count
FROM `proj.global._Default._Default`
WHERE severity = 'ERROR'
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
  AND resource.type = 'cloud_run_revision'
GROUP BY jsonPayload.error_type
ORDER BY count DESC
LIMIT 20;
```

No export needed. Query logs in-place.

### Log-based metrics

```bash
gcloud logging metrics create payment_failures \
  --description="Count of payment failures" \
  --log-filter='resource.type="cloud_run_revision"
    AND severity="ERROR"
    AND jsonPayload.event="payment_failed"'
```

Then alert on the metric value in [Cloud Monitoring](/stacks/gcp/monitoring/).

### Org-level aggregated sink

```bash
gcloud logging sinks create org-audit-sink \
  bigquery.googleapis.com/projects/security-logs/datasets/audit_logs \
  --organization=123456789 \
  --include-children \
  --log-filter='logName:"cloudaudit.googleapis.com"'
```

**Store audit logs in a dedicated security project**, not in the projects being audited — tampering risk.

### Audit log categories

| Type | Default | What |
|------|---------|------|
| Admin Activity | Always on, free | IAM changes, resource lifecycle |
| System Event | Always on, free | GCP-initiated events |
| Data Access | Off by default (except BigQuery); not free | Read/write on data |
| Policy Denied | Always on | IAM denials |

For regulated workloads, **enable Data Access** on Cloud Storage, Cloud SQL/AlloyDB/Spanner, Secret Manager, Cloud KMS.

## Anti-patterns

- **Unstructured logs** — `print()` / `console.log` produce blob logs; structured JSON enables Log Analytics.
- **Log export to BigQuery dataset** for log queries — Log Analytics queries in-place; export is extra cost + pipeline.
- **No org-level aggregated sink** — when you need audit logs, they're gone.
- **Storing audit logs in the project being audited** — tampering risk.
- **No exclusion filters** on noisy logs — paying ingestion cost for log-spam.

## Gotchas

- **Log retention** is 30 days default for `_Default` sink; 400 days for `_Required` (audit logs). Custom retention via routing.
- **Pricing** is per GiB ingested; exclusion filters reduce cost.
- **Severity normalization**: app logs need to set severity explicitly or all show as `DEFAULT`.

## Cross-references

- Related: [Cloud Monitoring](/stacks/gcp/monitoring/), [BigQuery](/stacks/gcp/bigquery/), [Cloud Storage](/stacks/gcp/cloud-storage/) (archive)
- Roles: [sre-engineer on GCP](/stacks/gcp/sre-engineer/), [security-engineer on GCP](/stacks/gcp/security-engineer/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/logging/docs](https://cloud.google.com/logging/docs)
