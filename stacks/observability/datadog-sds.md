---
title: Datadog Sensitive Data Scanner
description: Vendor-side PII/PCI/PHI scrubbing at ingest — 70+ standard patterns covering OAuth tokens, AWS keys, PANs, JWTs, SSN, email, phone.
product:
  name: Datadog Sensitive Data Scanner (SDS)
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer]
  authoritative_url: https://docs.datadoghq.com/sensitive_data_scanner/
  notes: "SDS v2 (2024) extended from logs to APM spans, RUM, DBM; default library: 70+ patterns with Luhn validation for PAN."
---

## What it is

Datadog Sensitive Data Scanner inspects logs, APM span attributes, RUM events, and DBM query parameters at ingest, matches against rule patterns (regex + validators), and replaces or hashes matches before indexing. See [docs.datadoghq.com/sensitive_data_scanner](https://docs.datadoghq.com/sensitive_data_scanner/).

**Standard patterns (70+ as of 2026):** PANs (with Luhn validation), SSN multi-country, passport, driver's license, IBAN, IPv4/v6, MAC address, email, phone, OAuth bearer tokens, JWT, AWS/GCP/Azure/Stripe/Twilio/Mailgun/Sendgrid/Slack/GitHub/PagerDuty API keys, private keys.

## When to use

**Always enable SDS** when on Datadog. Cost is minimal vs the compliance risk. Pair with:
1. **App-layer redaction** (primary control) — see [backend-architect overlay](/stacks/observability/backend-architect/).
2. **Collector-tier redaction** ([otel-collector](/stacks/observability/otel-collector/) `redaction` processor) — middle layer.
3. **SDS** — backstop.

For PCI/HIPAA, **never rely on SDS alone** — the unscrubbed data is in Datadog briefly (sub-second scrubbing latency, but still). App-layer redaction is the only fully-safe path for PAN.

## 2025-2026 currency anchors

- **SDS v2 (2024)** extended scope from logs to APM spans, RUM events, DBM query params.
- **Standard pattern library** expanded to 70+; Luhn validation for PAN reduces false positives.
- **Terraform support** via `datadog_sensitive_data_scanner_rule` / `_group` resources.
- **Hash replacement** option — preserve join-ability without revealing value.

## Patterns

### Rule group per compliance scope

```hcl
resource "datadog_sensitive_data_scanner_group" "pci_compliance" {
  name         = "PCI Compliance"
  filter       = { query = "service:checkout-* OR service:payment-*" }
  product_list = ["logs", "apm", "rum"]
  is_enabled   = true
}

resource "datadog_sensitive_data_scanner_rule" "pan_with_luhn" {
  name                = "PAN (Luhn-validated)"
  group_id            = datadog_sensitive_data_scanner_group.pci_compliance.id
  standard_pattern_id = data.datadog_sensitive_data_scanner_standard_pattern.credit_card.id
  text_replacement {
    type               = "replacement_string"
    replacement_string = "[REDACTED-PAN]"
  }
  excluded_namespaces = ["test-fixtures"]
  is_enabled = true
}
```

### Hash vs replace

- `replacement_string: "[REDACTED-PAN]"` — opaque; can't join records.
- `type: "hash"` — preserves join-ability (same input → same hash) without revealing value. Use for analytics.

## Anti-patterns

- **SDS as the only PII layer** — relies on Datadog being in the path; misses direct-to-archive flows; pattern matching is best-effort.
- **No PII scrubbing in test environments** — test fixtures often contain real-looking PII; SDS must apply to all envs.
- **Not auditing the SDS rule set quarterly** — new code paths, new providers (Anthropic API key wasn't a standard pattern in 2022), missing patterns.

## Gotchas

- **Sub-second scrubbing latency** still means the unscrubbed data exists in Datadog briefly. For hard PCI, layer 1 (app) is mandatory.
- **Rule order matters** — patterns evaluated in order; place specific patterns before generic.
- **Regex performance** — overly-broad rules slow ingest. Test patterns against representative log volumes.
- **Some products not yet covered** — DD Audit Trail, Workflow inputs, etc. Check coverage per surface.

## Cross-references

- App-layer + Collector-tier redaction patterns → [security-engineer overlay](/stacks/observability/security-engineer/)
- Compliance composition (HIPAA, PCI, SOX) → [security-engineer overlay](/stacks/observability/security-engineer/)
- DD Logs surface → [datadog-logs](/stacks/observability/datadog-logs/)
- Authoritative: [docs.datadoghq.com/sensitive_data_scanner](https://docs.datadoghq.com/sensitive_data_scanner/)
