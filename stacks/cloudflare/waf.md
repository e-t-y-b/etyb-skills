---
title: WAF + Managed Rulesets
description: Cloudflare's Web Application Firewall — managed rulesets (Cloudflare + OWASP), custom rule engine, and per-zone configuration applied before the request reaches your origin.
product:
  name: WAF
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/waf/
  notes: "OWASP and Cloudflare-managed rules; custom rule engine syntax stable; specific managed-ruleset IDs and paranoia tuning evolve."
---

## What it is

The WAF runs at Cloudflare's edge, before your origin (or [Worker](/stacks/cloudflare/workers/)) sees the request. It composes three classes of rules:

- **Cloudflare Managed Ruleset** — Cloudflare-curated rules for known exploit patterns, CVEs, abuse.
- **Cloudflare OWASP Core Ruleset** — generic OWASP CRS rules with tunable paranoia levels.
- **Custom rules** — your zone-specific expressions, written in the WAF's rule-engine language.

Authoritative reference: [developers.cloudflare.com/waf](https://developers.cloudflare.com/waf/).

## When to use

- **Every public HTTP zone** should have at least the Cloudflare Managed Ruleset enabled — it catches a wide class of opportunistic attacks for free.
- **Login flows** benefit from the Exposed Credentials Check ruleset.
- **APIs with high abuse signal** should add custom rules for known-bad patterns (geo-blocks, header anomalies, path-specific limits).
- **Compliance-bound apps** (PCI, SOC 2) typically require a WAF — Cloudflare's managed rulesets satisfy that.

## 2025-2026 currency anchors

- **Paranoia levels** on the OWASP ruleset are the primary knob for false-positive tuning — start at a low paranoia level in log mode, raise after observing real traffic.
- **Custom rule expressions** stable; the rule-engine language (`http.request.uri.path`, `ip.geoip.country`, `cf.bot_management.score`, etc.) is mature.
- **Rate Limiting + WAF integration** — see [Rate Limiting](/stacks/cloudflare/rate-limiting/); both compose at the edge.

## Patterns

### Log mode → tune → block mode

The non-negotiable launch sequence:

1. Enable managed rulesets in **log mode**. Observe `firewall_events` via [Logpush](/stacks/cloudflare/logpush/) or the dashboard.
2. Identify false positives. Tune (paranoia level, per-rule exclusions, custom skip rules).
3. Promote to **block mode** rule-by-rule (or ruleset-by-ruleset) once FP rate is acceptable.

Shipping a freshly-enabled WAF straight to block mode is how legitimate users get 403'd on launch day.

### Custom rule example

```
(http.request.uri.path contains "/admin/") and (ip.geoip.country ne "US")
  -> action: block
```

### Terraform-managed WAF

```hcl
resource "cloudflare_ruleset" "owasp" {
  account_id  = var.account_id
  name        = "OWASP managed ruleset"
  kind        = "zone"
  phase       = "http_request_firewall_managed"
  rules {
    action      = "execute"
    description = "OWASP managed ruleset"
    expression  = "true"
    action_parameters {
      id = "4814384a9e5d4991b9815dcfc25d2f1f"   # current OWASP ruleset ID — verify
    }
  }
}

resource "cloudflare_ruleset" "custom" {
  account_id = var.account_id
  name       = "Custom rules"
  kind       = "zone"
  phase      = "http_request_firewall_custom"
  rules {
    action      = "block"
    description = "Block admin paths from outside US"
    expression  = "(http.request.uri.path contains \"/admin/\") and (ip.geoip.country ne \"US\")"
  }
}
```

### Composition with other security layers

```
[Internet] -> DDoS -> WAF (managed + OWASP + custom) -> Rate Limiting -> Bot Management -> Turnstile -> Access -> Worker
```

Each layer gives independent value; the WAF is the broadest-coverage layer that catches known patterns before any other check spends compute.

## Anti-patterns

- **Block mode on day one without tuning.** False positives will block real users; the resulting tickets are expensive and embarrassing.
- **Custom rules without a logging plan.** A rule no one looks at is noise; pair every custom rule with a SIEM destination via [Logpush](/stacks/cloudflare/logpush/) and a review cadence.
- **Trying to do everything in custom rules.** The managed rulesets cover most of what you'd hand-write; lean on them and reserve custom rules for app-specific patterns.
- **No FP triage cadence.** Real users get blocked eventually; without a weekly review, the first you hear about it is a CEO email.

## Gotchas

1. **Rule ordering matters.** Custom rules at the `http_request_firewall_custom` phase run before the managed phase by default; skip-rules in custom can short-circuit the managed ruleset.
2. **Managed ruleset IDs are versioned.** Verify the ID in your Terraform / API config against current docs; Cloudflare occasionally rolls new ruleset versions.
3. **WAF doesn't see Worker → Worker traffic** if you use service bindings or [Workers RPC](/stacks/cloudflare/workers-rpc/) — those skip the public path. That's a feature, but it means your authz must live somewhere the WAF can't.
4. **Bot Management score in custom rules** (`cf.bot_management.score`) is enterprise-tier; lean on Bot Fight Mode for non-enterprise zones.

## Cross-references

- [Rate Limiting](/stacks/cloudflare/rate-limiting/) — different layer, also at the edge
- [DDoS Protection](/stacks/cloudflare/ddos/) — always-on, runs before the WAF
- [Turnstile](/stacks/cloudflare/turnstile/) — form-level abuse defense
- [Logpush](/stacks/cloudflare/logpush/) — `firewall_events` dataset for SIEM
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/waf](https://developers.cloudflare.com/waf/), [WAF managed rules](https://developers.cloudflare.com/waf/managed-rules/)
