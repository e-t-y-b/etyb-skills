---
title: Audit Logs
description: Org-level audit log API. Captures key + project + member + settings changes. Full retention enterprise-gated; export to SIEM for compliance.
product:
  name: Audit Logs
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect]
  authoritative_url: https://platform.openai.com/docs/api-reference/audit-logs
  notes: "API exists since 2024; default retention 30 days; longer retention via enterprise contract; SIEM export is the standard compliance pattern."
---

## What it is

The Audit Logs API (`/v1/organization/audit_logs`) returns org-level audit events. Captures **administrative + access changes** — not API request bodies.

### What's captured

- API key created / updated / deleted.
- Project created / updated / deleted.
- Project member added / removed.
- Service account created / deleted.
- Organization role changes.
- Login events.
- Settings changes (rate limits, model allowlists, ZDR toggles).

### What's NOT captured

- API request bodies (prompts + completions). For those, use application-level tracing (Langfuse / Helicone / Braintrust / OpenAI Platform Logs).
- User-level "did this user use the model" — that's app-layer telemetry.

Reference: [Audit Logs API reference](https://platform.openai.com/docs/api-reference/audit-logs).

## When to use

**Use Audit Logs for:**

- Compliance — SOC 2 / ISO 27001 / HIPAA require audit trails for access + admin events.
- Incident response — was a key created outside change-window?
- Forensics — who deleted that project? When?
- SIEM integration — daily export of audit events to your central SOC pipeline.

**Don't use Audit Logs for:**

- Prompt + response forensics — that's [Stored Completions](/stacks/openai/stored-completions/) or application-level tracing.
- Cost or token usage — that's the usage / billing surface.

## 2025-2026 currency anchors

- **Default retention: 30 days.**
- **Enterprise retention: longer via contract.**
- **API access** — pull events programmatically; default in OpenAI Console as well.
- **Format** — JSON event records with timestamp, actor, action, target, metadata.
- **GitHub secret scanning** is integrated for OpenAI keys leaked in public repos — leaked keys are revoked within minutes; auditable via the audit log.

## Patterns

### Pattern: daily SIEM export

```python
# Pseudo-code; run as a daily job
events = client.organization.audit_logs.list(
    effective_at={"gte": yesterday_timestamp},
    limit=1000,
)
for event in events:
    siem_client.ingest(format_as_cef(event))
```

Pipe to Splunk / Datadog / Sumo Logic / Elastic per your SIEM choice. Retention follows your own policy (often 1+ years for compliance).

### Pattern: alerting on suspicious events

Alert on:

- **New API key created outside change-window** — possible insider threat or compromised account.
- **Service account created / deleted** — admin action that should be expected only during planned changes.
- **ZDR toggle changed** — significant compliance posture change.
- **Rate-limit changed to a higher value** — could signal compromise + exfiltration attempt.
- **Member added with admin role** — high-privilege grant.

### Pattern: compliance evidence

For SOC 2 / ISO 27001 audits, store quarterly audit log exports as compliance evidence — proof of access-control monitoring + admin-event audit trail.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Relying on default 30-day retention for compliance | Export to SIEM with longer local retention. |
| Audit logs accessed only when an incident hits | Daily export + alerting. |
| No alerting on key creation outside change-window | Wire alerts. |
| Treating audit logs as prompt/response forensics | They're admin events; use tracing for content. |
| Granting Org Owner to everyone | Owner role is small; auditors get Org Reader. |
| Auditing only on the OpenAI side | Combine OpenAI audit + your app-side audit (who ran what request) for full trail. |

## Gotchas

- **Retention is 30 days by default.** Export aggressively.
- **No request-body content.** This is admin audit, not request audit.
- **Org-level only** — events are org-scoped; project-level filtering is via event metadata.
- **API rate limits** apply to audit log retrieval; for daily exports, paginate.
- **GitHub secret scanning integration** is automatic for public-repo OpenAI keys; private repos need your own secret scanning.
- **Enterprise retention** isn't automatic — needs to be in your contract.
- **Permissions** — Audit Logs API requires org-admin-level access; not exposed to project members.

## Cross-references

### Related products in this Stack

- [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/) — what audit logs cover.
- [OpenAI Platform Console](/stacks/openai/openai-platform-console/) — audit logs visible in console.
- [Stored Completions](/stacks/openai/stored-completions/) — prompt/response forensics (different surface).

### Role overlays

- [security-engineer](/stacks/openai/security-engineer/) — audit policy + SIEM integration + alerting.
- [system-architect](/stacks/openai/system-architect/) — operational topology + retention posture.

### Authoritative sources

- [Audit Logs API reference](https://platform.openai.com/docs/api-reference/audit-logs)
- [Production best practices](https://platform.openai.com/docs/guides/production-best-practices)
