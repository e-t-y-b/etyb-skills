---
title: Security Engineer on Observability
description: Security's lens — PII/PHI/PCI scrubbing, audit-log retention, BAA per vendor, SIEM vs APM composition, Collector hardening.
role_overlay:
  role: security-engineer
  stack: observability
  last_verified_on: "2026-05-14"
  products_covered:
    - otel-collector
    - datadog-sds
    - datadog-logs
    - datadog-apm
    - datadog-asm
    - datadog-cspm
    - splunk-cloud
    - sentry-errors
    - sentry-debug-ids
    - newrelic-apm
    - grafana-loki
    - honeycomb-events
    - dynatrace-oneagent
    - ebpf-instrumentation
---

## Role briefing

You're the security engineer on an observability engagement. Your concerns:
- Telemetry leaking secrets and PII.
- Audit-log retention for compliance.
- SIEM patterns versus APM patterns.
- Observability platforms themselves as a **privileged attack surface**.
- Security-product surfaces inside observability vendors ([DD CSPM/CWPP/ASM](/stacks/observability/datadog-cspm/), [Splunk Enterprise Security](/stacks/observability/splunk-cloud/), [Sentry Issue Owners](/stacks/observability/sentry-errors/)).

**Distinctive vs. the SOC analyst:** you're not the analyst. You're the engineer who makes sure the telemetry pipeline doesn't introduce a compliance failure or an exfiltration path.

## 2025-2026 platform-reset items for security

- **[Datadog Sensitive Data Scanner](/stacks/observability/datadog-sds/) became default.** SDS v2 (2024) extended from logs to APM spans, RUM, DBM. 70+ standard patterns including OAuth tokens, AWS keys, Stripe keys, SSNs, PANs, JWTs.
- **[OTel Collector `transform` + `redaction` processors](/stacks/observability/otel-collector/)** are the OSS path for PII scrubbing.
- **[Splunk Cisco acquisition](/stacks/observability/splunk-cloud/)** finalized March 2024. Splunk ES + SOAR remain Splunk products; convergence with Cisco SecureX over 2026-2027.
- **[Datadog ASM](/stacks/observability/datadog-asm/)** matured — agent-side WAF + IAST.
- **[DD CSPM/CWPP](/stacks/observability/datadog-cspm/)** unified surface.
- **[OneAgent BAA-signed config](/stacks/observability/dynatrace-oneagent/)** for HIPAA.
- **[Sentry data scrubbing](/stacks/observability/sentry-errors/)** matured — server-side rules + `beforeSend` hooks.
- **CIS Benchmarks for OTel Collector** landed late 2025.
- **Confidential computing for telemetry** — AWS Nitro Enclaves, GCP Confidential VMs (FedRAMP High / DoD IL5 territory).
- **Audit logs as a separate signal type** — DD Audit Trail, NR Audit Logs API, Splunk admin event indexes.

If you're recommending "scrub logs at app layer only," "let Datadog index everything," or "use a single SIEM for security AND APM" — your training is stale.

## Threat model — observability is privileged

The observability platform sees:
- Every HTTP request (URLs, headers, sometimes bodies).
- Every SQL query (often with parameters).
- Every error and stack trace.
- Every log line.
- Every span attribute.
- Every metric label.
- Every K8s pod/deployment topology.

**This is the most privileged read-access in your environment after the database.** A compromised vendor account, leaked API key, or misconfigured pipeline is a data-breach event.

Key threats and mitigations:

| Threat | Mitigation |
|---|---|
| **API key leak** (DD, NR, Honeycomb, Sentry DSN in client code) | Vault-managed secrets, rotation, GitGuardian/TruffleHog scans, env-var-only SDK init |
| **PII in logs/traces** | [SDS](/stacks/observability/datadog-sds/), Collector `redaction`, SDK `beforeSend`, app-layer redaction |
| **PAN in logs** (PCI) | SDS PAN + Luhn, explicit deny in app, PCI-scoped destinations only |
| **PHI in logs** (HIPAA) | BAA vendor, encryption at rest + transit, audit retention, identifier scrubbing |
| **SSRF via Collector** | NetworkPolicy egress isolation, no outbound to private CIDRs, internal-only ports |
| **Vendor compromise** | CMK (customer-managed key) where supported, minimize retention, archive to own S3 |
| **Insider abuse** | RBAC, audit log on queries, JIT access for sensitive datasets |
| **Telemetry as exfil channel** | Egress policies (Collector → approved vendor endpoints only) |
| **Alert spoofing** | Webhook signature verification on PD/Opsgenie |
| **Source map exposure** | `sentry-cli sourcemaps upload --no-upload-source-maps` for server builds |

## PII / PHI / PCI scrubbing

Three layers; defense in depth.

### Layer 1 — App-layer redaction (recommended primary)

Don't generate sensitive data in logs. Pre-redact at app boundary. Pros: deterministic, no vendor lock-in, testable. Cons: developer discipline required.

### Layer 2 — Collector-tier redaction

[OTel Collector](/stacks/observability/otel-collector/) `transform` or `redaction` processor. Centralized, no app changes, transformed once for all backends. Cons: relies on Collector being in path; pattern-matching is best-effort.

### Layer 3 — Vendor-side scrubbing

[Datadog SDS](/stacks/observability/datadog-sds/), [Sentry data scrubbers](/stacks/observability/sentry-errors/), Splunk SED. Backstop. Catches misses from upstream.

For PCI/PHI: **all three layers**. App-layer is the only safe path for PAN — regex backstop is supplementary. Encrypt logs in transit (TLS) and at rest (vendor + CMK). Limit log destinations to scope-specific accounts.

## Compliance — retention, encryption, residency, BAA

### Audit log retention

| Vendor | Default | Max | Archive path |
|---|---|---|---|
| **[Datadog](/stacks/observability/datadog-logs/)** | 15d indexed | 15mo (Premier) | Log Archives → S3/GCS/Azure (effectively unlimited) |
| **[New Relic](/stacks/observability/newrelic-apm/)** | 30d (varies, 8-395d) | 13mo | NR Streaming Export → S3 |
| **[Loki](/stacks/observability/grafana-loki/)** | Configurable | Infinite (object storage) | Native retention |
| **[Splunk Cloud](/stacks/observability/splunk-cloud/)** | 90d hot/warm | 7+ yrs (cold/frozen) | SmartStore → S3 |
| **[Honeycomb](/stacks/observability/honeycomb-events/)** | 60d | 60d max | S3 export |
| **[Sentry](/stacks/observability/sentry-errors/)** | 90d (Errors) | 90d (Enterprise: longer) | None native |
| **[Dynatrace](/stacks/observability/dynatrace-grail-dql/)** | 35d | 10yrs (Grail) | Native Grail long-term |

**Honeycomb's 60d max is a compliance gap** for 1yr+ retention requirements. Keep audit logs in Splunk/DD/CloudWatch in those cases.

### Audit logs of the observability platform itself

- [Datadog Audit Trail](/stacks/observability/datadog-logs/) — every API call and UI action.
- [NR Audit Logs API](/stacks/observability/newrelic-apm/) — NerdGraph.
- [Splunk](/stacks/observability/splunk-cloud/) — admin events in `_audit` index.
- Grafana Enterprise/Cloud — Audit Log.
- [Honeycomb](/stacks/observability/honeycomb-events/) — Audit Log (Enterprise).
- [Sentry](/stacks/observability/sentry-errors/) — Audit Log per org.
- [Dynatrace](/stacks/observability/dynatrace-grail-dql/) — built-in.

**Ship the platform's audit log to your SIEM.** Don't trust the platform to audit itself in isolation.

### Encryption + residency + BAA

- **TLS 1.2+** to every vendor; Collector OTLP exporters with `tls.min_version: "1.2"`.
- **CMK (customer-managed key)** at rest where supported (DD Enterprise, NR Enterprise, Splunk Cloud, Honeycomb Enterprise, Sentry Business+, Dynatrace HYOK).
- **EU residency** — DD EU1/EU3, NR EU, Honeycomb EU, Sentry EU, Grafana EU, Splunk Cloud EU, Dynatrace EU. Vendor-side multi-region preferred over multi-account.
- **BAA-signing vendors** (2026): DD Enterprise, NR (specific tier), Splunk Cloud HIPAA, Honeycomb Enterprise, Sentry Business/Enterprise, Dynatrace, Grafana Cloud Pro+, AWS/GCP/Azure native, Loki/Prometheus/OTel self-hosted (no BAA needed).

Read the BAA carefully — which services covered, subprocessor list, breach notification SLA, termination provisions.

## SIEM vs APM patterns

| Concern | SIEM ([Splunk ES](/stacks/observability/splunk-cloud/), Sentinel, Elastic, Chronicle) | APM/Observability (DD, NR, Grafana, Honeycomb) |
|---|---|---|
| **Use** | Security incident detection | Performance, SLO, debugging |
| **Data** | Multi-source events (FW, auth, EDR, app, network) | Structured telemetry from app + infra |
| **Retention** | Years (compliance) | Months (performance) |
| **Query latency** | Minutes (search-time schema) | Sub-second (pre-aggregated) |
| **Compliance** | Heavily certified | SOC 2 + HIPAA + GDPR; FedRAMP varies |

**You almost always need both.** Don't make Datadog your SIEM; don't make Splunk Enterprise your APM.

Standard 2026 composition:
- **[Splunk ES](/stacks/observability/splunk-cloud/) or Sentinel or Elastic SIEM or Chronicle** for SOC use cases.
- **[DD](/stacks/observability/datadog-apm/) / [NR](/stacks/observability/newrelic-apm/) / [Grafana](/stacks/observability/grafana-cloud/) / [Honeycomb](/stacks/observability/honeycomb-events/)** for SRE/dev.
- **Audit log of each** flows to the SIEM.

### Bridging SIEM and APM

Some signals matter to both — auth failures, errors with `category=security`, LLM prompt/response logs (prompt injection vs hallucination rate). Use Collector multi-exporter routing:

```yaml
processors:
  routing:
    from_attribute: security_event
    table:
      - value: "true"
        exporters: [otlphttp/splunk_es, otlp/datadog]
      - value: "false"
        exporters: [otlp/datadog]
```

## Datadog ASM, CSPM/CWPP — when to adopt

[ASM](/stacks/observability/datadog-asm/) — agent-side WAF + IAST, in-Datadog correlation. Use if already on DD APM and no dedicated WAF. Skip if edge WAF (Cloudflare, AWS WAF) is the strategy.

[CSPM/CWPP](/stacks/observability/datadog-cspm/) — cloud posture + workload protection. Use if DD is observability platform and security needs aren't deep. Mature SOC teams pick Wiz / Lacework / Prisma Cloud.

## Splunk Enterprise Security

The SIEM. Sits on top of [Splunk Enterprise / Cloud](/stacks/observability/splunk-cloud/). Threat intelligence, Notable events, correlation rules (`tstats`), risk-based alerting, MITRE ATT&CK, Adaptive Response Actions.

When ES is in architecture:
- All security-relevant logs flow to Splunk (HEC, Forwarders, Cribl).
- Observability signals stay in APM platform — don't put traces/metrics in ES.
- CIM normalization for cross-source correlation.

2026 alternatives if not on Splunk: **Microsoft Sentinel** (Azure-native), **Elastic SIEM**, **Chronicle / Google SecOps**, **Panther / Hunters** (cloud-first startups).

## OTel Collector hardening

Collector is a privileged pod. Harden:

- **`runAsNonRoot: true`**, `runAsUser: 65534`.
- **`readOnlyRootFilesystem: true`**.
- **`privileged: false`**.
- **`capabilities.drop: [ALL]`**.
- **NetworkPolicy egress** — Collector → approved vendor endpoints only; no outbound to private CIDRs.
- **No public exposure of OTLP receivers** — internal-only.
- **ServiceAccount minimum scope** — read-only on `pods`/`nodes`/`namespaces`.
- **TLS on every exporter** — never disable cert verification.
- **API keys in K8s Secrets** (External Secrets Operator + Vault), not ConfigMaps.

See [otel-collector](/stacks/observability/otel-collector/) and [devops-engineer overlay](/stacks/observability/devops-engineer/) for the hardened PodSpec + NetworkPolicy YAML.

## eBPF observability — security considerations

[eBPF agents](/stacks/observability/ebpf-instrumentation/) (Beyla, Pixie, DD USM, Tetragon) run with elevated capabilities (`CAP_BPF`, `CAP_PERFMON`, sometimes `CAP_SYS_ADMIN`). PSS `restricted` blocks them — use `baseline` or `privileged` in dedicated namespace with admission exceptions.

For PCI/HIPAA: explicit security review and approval; default-deny in PSS, opt-in per namespace.

Vendor compromise impact is severe — eBPF agent images are **critical-tier supply chain** (SBOM, signed images, Cosign verification).

## Sentry security configuration

- **`beforeSend`** to drop credential headers (Authorization, Cookie, X-Api-Key).
- **Server-side data scrubbing rules** (Sentry UI) apply regardless of client config.
- **Issue Owners** — route errors to teams via path/URL rules. Without this, Sentry becomes unowned-issue dumpster.

[Source Maps Debug IDs](/stacks/observability/sentry-debug-ids/) mandatory for modern builds — legacy `sentry-cli releases files upload-sourcemaps` produces broken stack traces.

## API key rotation and management

- **Store in Vault / AWS Secrets Manager / GCP SM / Azure Key Vault**, never ConfigMaps or repo.
- **External Secrets Operator (ESO)** projects secrets into K8s Secrets.
- **Rotate quarterly**; on-demand on suspected compromise.
- **Scope narrowly** — ingest-only, read-only, admin tiers.
- **Audit key usage** — alert on unused keys.
- **No personal API keys in production** — service accounts only.

## RBAC on observability platforms

- **[Datadog](/stacks/observability/datadog-apm/)**: DD Teams (2024+); custom roles; per-resource permissions.
- **[New Relic](/stacks/observability/newrelic-apm/)**: Account/Group/Role with per-product permissions.
- **[Grafana](/stacks/observability/grafana-cloud/)**: Org → Team → Folder → Dashboard; Datasource permissions.
- **[Splunk](/stacks/observability/splunk-cloud/)**: Role-based; CIM-aware roles (SOC sees security indexes only).
- **[Honeycomb](/stacks/observability/honeycomb-events/)**: Team-based; per-Environment.
- **[Sentry](/stacks/observability/sentry-errors/)**: Org → Team → Project.
- **[Dynatrace](/stacks/observability/dynatrace-oneagent/)**: Management Zones + IAM.

**SSO + SCIM provisioning is table-stakes.** Auto-provision/deprovision from Okta/Entra ID.

## Statuspage and disclosure

If you operate a statuspage:
- Automate updates from SLO alert state (not manual during incidents).
- Detail published externally must pass legal review for regulated industries.
- Postmortem timing — many SLAs require RC disclosure within 5 business days. Publish public summary; keep internal private if exploitable.

## Anti-patterns

- **No PII scrubbing in any layer**.
- **Single observability tenant for prod + staging + dev** — cross-env contamination.
- **API keys in repo or ConfigMap** — trivially exfiltrated.
- **No audit log of the observability platform itself** — insider queries invisible.
- **TLS verification disabled on Collector exporters** — telemetry MITM-able.
- **Trusting "HIPAA-compliant" claims without reading the BAA**.
- **Same data to DD Logs + Splunk ES + Loki "just in case"** — triple cost, triple liability.
- **No PII redaction in test environments** — test fixtures often have real-looking data.

## Integration with always-on protocols

- **TDD on scrubbing rules** — test asserts PAN never reaches vendor mock; assert JWT in HTTP header doesn't appear in span attributes.
- **Verification** — after enabling SDS, inject synthetic PII at app boundary; query vendor for that ingest; assert redacted. Repeat per pattern.
- **Plan execution** — compliance has explicit deadlines (audit, certification). Ship with cutover date + verification artifact, not "ship and hope."
- **Branch safety** — scrubbing rule changes via PR with test pass; API key rotation announced + scheduled + rollback tested; vendor RBAC via Terraform.
- **Debugging** — PII in vendor → which layer failed? App / Collector / vendor. Audit-log gap → ingest pipeline check. API key compromise → rotate immediately, audit usage, identify leak source.

## Cross-references

- **Vendor selection (compliance dimension)** → [sre-engineer overlay](/stacks/observability/sre-engineer/), Stack index compliance composition
- **Collector hardening + NetworkPolicy + ESO** → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- **App-layer redaction + structured logging** → [backend-architect overlay](/stacks/observability/backend-architect/)
- **OTel semconv + PII discipline** → [otel-semantic-conventions](/stacks/observability/otel-semantic-conventions/)
- **Vertical compliance (HIPAA, PCI, SOX)** → vertical specialists (`healthcare-architect`, `fintech-architect`)
- **Stack index** → [/stacks/observability/](/stacks/observability/)
