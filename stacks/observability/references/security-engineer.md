---
role: security-engineer
stack: observability
last_verified_on: "2026-05-14"
---

# Observability Overlay — security-engineer

You are security-engineer on an observability engagement. Your concerns: telemetry leaking secrets and PII, audit-log retention for compliance, SIEM patterns versus APM patterns, observability platforms themselves as a privileged attack surface, and the security-product surfaces inside observability vendors (Datadog CSPM/CWPP/ASM, Splunk Enterprise Security, Sentry Issue Owners). You're not the SOC analyst — you're the engineer who makes sure the telemetry pipeline doesn't introduce a compliance failure or an exfiltration path.

**Currency:** 2026-Q2 — Datadog Sensitive Data Scanner v2, Splunk Enterprise 9.x + Splunk Cloud, OneAgent 1.300+, OTel Collector 0.110+ with `transform` processor PII patterns, Sentry SDK 8.x with `beforeSend` filters, OpenSSF SLSA L3 baseline.

## What changed in 2025-2026 that older training data misses

- **Datadog Sensitive Data Scanner (SDS) became default.** SDS v2 (2024) extended from logs to APM spans, RUM, and Database Monitoring. Default rule library covers 70+ PII patterns including OAuth tokens, AWS keys, Stripe keys, SSNs (US/UK/CA/AU/etc.), credit-card PANs (with Luhn validation), JWT tokens. Enable SDS at agent install — opt-in, doesn't default-scan.
- **OTel Collector `transform` processor** is the OSS path. Combined with `redaction` processor, it's a credible PII-scrub layer when you don't have SDS or aren't on Datadog.
- **Splunk Cisco acquisition** finalized March 2024. Splunk Enterprise Security (ES, the SIEM) and Splunk SOAR (security automation) remain Splunk products but expect convergence with Cisco SecureX over 2026-2027.
- **Datadog ASM (App Security Management)** matured — agent-side WAF, attacker traces, business-logic abuse detection. Pairs with the regular APM trace pipeline.
- **Datadog CSPM (Cloud Security Posture Management)** and **CWPP (Cloud Workload Protection Platform)** unified surfaces in the Datadog Security product line. Wiz, Lacework, Aqua Security, Sysdig compete in this space outside Datadog.
- **OneAgent has BAA-signed config** for HIPAA workloads — explicit policy required to keep PHI out of OneAgent's automatic instrumentation.
- **Sentry data scrubbing** matured — Server-side Data Scrubbing rules at the project level, plus `beforeSend` / `beforeSendTransaction` hooks in SDKs. Use both layers.
- **OTel attribute processor `redaction`** (added 2023, mature 2025) — drop or hash specific attributes at the Collector before they reach a vendor.
- **CIS Benchmarks for OTel Collector** landed late 2025 — operational hardening checklist for production Collectors.
- **Confidential computing for telemetry storage** — AWS Nitro Enclaves and GCP Confidential VMs are being used for high-sensitivity telemetry pipelines (financial, healthcare). Out of scope for most installs but on the radar for FedRAMP High / DoD IL5.
- **Audit logs as a separate signal type** — observability vendors increasingly treat audit logs (admin actions on the platform itself) as their own pipeline. Datadog Audit Trail, NR Audit Logs API, Splunk admin event indexes.

If you're recommending "scrub logs at the app layer only," "let Datadog index everything," or "use a single SIEM for security AND APM" — your training is stale.

## Threat model — observability is privileged

The observability platform sees:
- Every HTTP request your app handles (URLs, headers, sometimes bodies).
- Every SQL query (often with parameters).
- Every error and stack trace (sometimes with surrounding context).
- Every log line (everything the app logs).
- Every span attribute (whatever your code or auto-instrumentation puts there).
- Every metric label (which can be unbounded if undisciplined).
- Every K8s pod/deployment topology.

This is **the most privileged read-access in your environment after the database**. A compromised observability vendor account, a leaked API key, or a misconfigured ingestion pipeline is a data-breach event.

Threats to address:

| Threat | Mitigation |
|--------|------------|
| **API key leak** (Datadog / NR / Honeycomb / Sentry DSN exposed in client code or repo) | Vault-managed secrets, rotation policy, GitGuardian / TruffleHog scans, SDK init from env vars only |
| **PII in logs/traces** | Sensitive Data Scanner, Collector `redaction` processor, SDK `beforeSend` filters, app-layer log redaction |
| **PAN in logs** (PCI scope) | SDS PAN rule + Luhn validation, explicit deny-list in app code, PCI-scoped log destinations only |
| **PHI in logs** (HIPAA scope) | BAA-signed vendor, encryption at rest + in transit, audit-log retention, scrubbing of patient identifiers |
| **SSRF via the Collector** | Network-policy isolation of Collector pods, no outbound to private CIDRs, Collector receivers on internal-only ports |
| **Vendor compromise** | Encrypt at rest with customer-managed keys (CMK) where supported (DD, NR, Splunk all support); minimize retention; archive to your own S3 with separate encryption |
| **Insider abuse** (engineer queries telemetry to read user data) | RBAC on observability vendor, audit log on all queries, just-in-time access for sensitive datasets |
| **Telemetry as exfiltration channel** | Egress policies (Collector can only reach approved vendor endpoints), block external `otlphttp` exporters in untrusted code |
| **Alert spoofing** (attacker triggers paging to mask another attack) | Webhook signature verification on PagerDuty/Opsgenie integrations |
| **Source map exposure** (uploads include unminified server code) | `sentry-cli sourcemaps upload` with `--no-upload-source-maps` for server-only builds; verify only client maps uploaded |

## PII / PHI / PCI scrubbing

Three layers; defense in depth.

### Layer 1 — App-layer redaction (recommended)

Best path: don't generate the sensitive data in the first place. Pre-redact at the app boundary.

```python
# Python — sanitize before log
def redact_pan(message: str) -> str:
    return re.sub(r'\b\d{13,19}\b', lambda m: '[REDACTED-PAN]' if luhn_valid(m.group()) else m.group(), message)

log.info(redact_pan(f"Charge attempt for cart {cart_id}: response={charge_response}"))
```

Pros: deterministic, no vendor lock-in, testable.
Cons: developer discipline required; one missing redaction leaks.

### Layer 2 — Collector-tier redaction

OTel Collector `transform` processor with attribute-level redaction.

```yaml
processors:
  transform/pii_scrub:
    log_statements:
      - context: log
        statements:
          # Redact credit-card numbers (Luhn-eligible patterns)
          - replace_pattern(body, "\\b\\d{13,19}\\b", "[REDACTED-PAN]")
          # Redact email addresses
          - replace_pattern(body, "\\b[\\w.-]+@[\\w.-]+\\.\\w+\\b", "[REDACTED-EMAIL]")
          # Redact SSN
          - replace_pattern(body, "\\b\\d{3}-\\d{2}-\\d{4}\\b", "[REDACTED-SSN]")
          # Redact JWT tokens
          - replace_pattern(body, "eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+", "[REDACTED-JWT]")
          # Redact AWS access keys
          - replace_pattern(body, "AKIA[0-9A-Z]{16}", "[REDACTED-AWS-KEY]")
    trace_statements:
      - context: span
        statements:
          # Strip sensitive attribute values
          - delete_key(attributes, "http.request.header.authorization")
          - delete_key(attributes, "http.request.header.cookie")
          - replace_match(attributes["db.statement"], "*'*'*", "[REDACTED-SQL-PARAM]")
```

Or use the `redaction` processor (simpler API for attribute-level rules):

```yaml
processors:
  redaction:
    allow_all_keys: false
    allowed_keys:
      - http.request.method
      - http.response.status_code
      - http.route
      - service.name
      - db.system
    blocked_values:
      - "\\b\\d{13,19}\\b"           # PAN
      - "\\b[\\w.-]+@[\\w.-]+\\.\\w+\\b"  # email
    ignored_keys: [k8s.pod.name]
    summary: debug
```

Pros: centralized, doesn't require app changes, transformed once for all backends.
Cons: relies on Collector being in the path (direct-to-vendor pipelines bypass it); pattern matching is best-effort.

### Layer 3 — Vendor-side scrubbing

Datadog Sensitive Data Scanner, Sentry data scrubbers, Splunk SED — backstop layer.

**Datadog Sensitive Data Scanner (SDS):**

```yaml
# Datadog SDS rule (configured via Datadog API / Terraform)
resource "datadog_sensitive_data_scanner_rule" "redact_pan" {
  name              = "Redact Credit Card Numbers"
  description       = "PCI compliance — redact PAN at ingest"
  standard_pattern_id = data.datadog_sensitive_data_scanner_standard_pattern.credit_card.id
  text_replacement {
    type              = "hash"
    replacement_string = "[REDACTED-PAN]"
  }
  tags = ["sensitivity:pci", "scope:logs,apm,rum"]
  excluded_namespaces = []
  is_enabled        = true
}
```

SDS standard patterns (built-in, 70+ in 2026): credit cards (PAN + Luhn), SSN (multi-country), passport, driver's license, IBAN, MAC address, IPv4/v6, email, phone, OAuth bearer, AWS / GCP / Azure / Stripe / Twilio / Mailgun / Sendgrid / Slack / GitHub / PagerDuty API keys, JWT, private keys.

**Sentry data scrubbers:**

```yaml
# Sentry server-side scrubbing rules (project settings → Security & Privacy)
# Default rules:
# - Anything looking like a credit card (regex + Luhn) → [Filtered]
# - Anything matching @<domain> → [Filtered]
# - PII data field names (password, secret, token, api_key) → [Filtered]
# Custom regex rules per project
```

```typescript
// Sentry SDK `beforeSend` hook — client-side scrub before transmission
Sentry.init({
  beforeSend(event) {
    // Redact request body in HTTP errors
    if (event.request?.data) {
      event.request.data = '[REDACTED]';
    }
    // Redact custom user fields
    if (event.user?.email) {
      event.user.email = '[REDACTED]';
    }
    return event;
  },
});
```

**Splunk SED (Sensitive Data Encryption):**

Splunk Enterprise Security has Data Anonymization rules in the props.conf SEDCMD field — regex replace at index time. Used heavily in PCI/HIPAA Splunk environments.

```
# props.conf — anonymize PAN at index time
[my_application_logs]
SEDCMD-redact_pan = s/\b\d{13,19}\b/[REDACTED-PAN]/g
SEDCMD-redact_ssn = s/\b\d{3}-\d{2}-\d{4}\b/[REDACTED-SSN]/g
```

Pros: backstop catches misses from upstream layers.
Cons: vendor-specific, can't recover the original if redacted incorrectly.

### Strategy

For high-sensitivity data (PCI, PHI):
- All three layers.
- Critical: **app-layer redaction never relies on regex alone for PAN** — use structured payment-handler code paths that never serialize PAN to logs/traces. Regex is the backstop, not the primary control.
- Encrypt logs in transit (TLS) and at rest (vendor-side encryption + your CMK where supported).
- Limit log destinations to PCI-scoped vendor accounts (don't merge PCI logs with general engineering logs).

For general PII (email, phone):
- Layer 1 (app discipline) + Layer 3 (SDS / Sentry scrubbers).
- Layer 2 if you're not on Datadog or want to scrub before vendor sees data.

## Compliance — retention, encryption, residency, BAA

### Audit log retention

Most regulations require multi-year retention of audit logs (HIPAA 6 years, SOX 7, PCI 1 year on-line + 1 year archive, GDPR varies).

| Vendor | Default log retention | Max log retention | Archive path |
|--------|----------------------|--------------------|---------------|
| **Datadog** | 15 days indexed | 15 months (Premier) | Datadog Log Archives → S3/GCS/Azure Blob (effectively unlimited) |
| **New Relic** | 30 days (varies by data type, 8-395 days) | 13 months | Stream to S3 via NR Streaming Export |
| **Grafana Loki** | Configurable | Infinite (object storage) | Local; archive via Loki's own retention config |
| **Splunk Cloud** | 90 days hot/warm default | 7+ years (cold/frozen) | Splunk SmartStore → S3 |
| **Honeycomb** | 60 days | 60 days max | Stream via S3 export |
| **Sentry** | 90 days (Errors); varies for Performance | 90 days max (Enterprise: longer) | None native; query via API |
| **Dynatrace** | 35 days default | 10 years (Grail) | Native Grail long-term storage |

Honeycomb's 60-day max is a **compliance gap** for industries requiring 1+ year audit-log retention. If Honeycomb is your trace backend, either (a) it's not the audit-log destination — keep audit logs in Splunk/Datadog/CloudWatch, or (b) stream Honeycomb data to S3 via the export feature.

### Audit logs of the observability platform itself

Who queried what data, when, from where. Required for SOC 2, SOX, HIPAA on observability platforms that hold sensitive data.

- **Datadog Audit Trail** — captures every Datadog API call and UI action. Retain via Log Archives.
- **New Relic Audit Logs API** — query via NerdGraph.
- **Splunk** — admin events in the `_audit` index by default.
- **Grafana Enterprise / Grafana Cloud** — Audit Log feature.
- **Honeycomb** — Audit Log (Enterprise tier).
- **Sentry** — Audit Log (per organization).
- **Dynatrace** — built-in audit log; retained per global policy.

Ship the platform's audit log to your SIEM (Splunk ES, Sentinel, Elastic SIEM, etc.). Don't trust the platform to audit itself in isolation.

### Encryption

Encryption in transit: TLS 1.2+ to every vendor; OTel Collector should use `tls` config for OTLP exporters.

```yaml
exporters:
  otlphttp/datadog:
    endpoint: https://http-intake.logs.datadoghq.com
    headers: { "DD-API-KEY": "${env:DD_API_KEY}" }
    tls:
      insecure: false
      min_version: "1.2"
```

Encryption at rest:
- Datadog: encrypted at rest with Datadog-managed keys; **customer-managed key (CMK) via AWS KMS** for Enterprise tier.
- New Relic: encrypted; CMK via AWS KMS for Enterprise.
- Splunk Cloud: encrypted; CMK for Splunk Cloud.
- Honeycomb: encrypted; CMK on Enterprise tier.
- Sentry: encrypted; CMK on Business/Enterprise.
- Dynatrace: encrypted; HYOK (hold-your-own-key) option.

For HIPAA, PCI, FedRAMP — use CMK and rotate keys per policy.

### Data residency

EU customers, EU operations → EU-region telemetry pipelines.

- **Datadog**: US1, US3, US5, EU1, AP1, US1-FED regions; choose at install; one site per Datadog org.
- **New Relic**: US, EU regions; choose at signup.
- **Honeycomb**: US and EU; tied to account.
- **Sentry**: US and EU regions; Sentry SaaS or self-hosted (Helm).
- **Grafana Cloud**: US, EU, AU regions.
- **Splunk Cloud**: multi-region (AWS regions, Splunk Cloud Gov).
- **Dynatrace**: SaaS in 14+ regions worldwide.

For multi-region deployments, prefer **vendor-side multi-region** over running separate vendor accounts per region — but use separate accounts if the data sensitivity differs (e.g., EU PII in EU account, US analytics in US account).

### BAA (Business Associate Agreement) for HIPAA

Vendors that sign BAAs as of 2026:
- **Datadog** — yes, Enterprise tier.
- **New Relic** — yes, with specific tier.
- **Splunk** — yes (Splunk Cloud HIPAA).
- **Honeycomb** — yes, Enterprise.
- **Sentry** — yes, Business/Enterprise.
- **Dynatrace** — yes.
- **Grafana Cloud** — yes, Pro+.
- **AWS / GCP / Azure native** — yes (BAA covers eligible services including CloudWatch, AMP, Cloud Monitoring, Azure Monitor).
- **Loki / Prometheus / OTel self-hosted** — no BAA needed; you control the environment.

If working with PHI, **read the BAA carefully**:
- Which services are covered (e.g., Datadog Logs may be covered but Datadog Audit Trail may not).
- Subprocessor list (vendors using AWS may transitively require AWS BAA).
- Notification SLA on breach.
- Termination provisions and data return.

## SIEM patterns vs APM patterns

| Concern | SIEM (Splunk ES, Sentinel, Elastic SIEM, Chronicle) | APM / Observability (Datadog, NR, Grafana, Honeycomb) |
|---------|------------------------------------------------------|---------------------------------------------------------|
| **Primary use** | Security incident detection and investigation | Performance analysis, SLO management, debugging |
| **Data shape** | Events from many sources (firewall, auth, EDR, app logs, network) | Structured telemetry from app + infra |
| **Retention** | Years (compliance) | Months (performance) |
| **Query latency** | Minutes (search-time schema-on-read) | Sub-second (pre-aggregated metrics, indexed traces) |
| **Cost model** | Per-GB-indexed + per-license-tier | Per-host + per-metric + per-GB-indexed |
| **Compliance posture** | Heavily certified (FedRAMP, FedRAMP High, SOC 2) | Mostly SOC 2 + HIPAA + GDPR; FedRAMP varies |

You almost always need both. **Don't try to make Datadog your SIEM** (Datadog Security exists but it's not a Splunk ES replacement). **Don't try to make Splunk your APM** (Splunk Observability Cloud is real APM, but Splunk Enterprise indexing rates make APM via SPL slow and expensive).

The standard 2026 composition:
- **Splunk ES or Microsoft Sentinel or Elastic SIEM** for SOC use cases: firewall logs, auth events, EDR alerts, audit trails, app security events.
- **Datadog / NR / Grafana / Honeycomb** for SRE/dev use cases: APM traces, RED metrics, SLOs, RUM.
- **Audit log of each** flows to the SIEM (so SOC can detect tampering in the observability platform).

### Bridging SIEM and APM

Some signals matter to both:
- Authentication failures: SIEM cares (brute force, credential stuffing); SRE cares (user friction, latency). Emit once, route to both via OTel Collector multi-exporter.
- Errors: SIEM cares about security errors (auth failure, authorization denied, input validation rejected, suspected XSS/SQLi); SRE cares about all errors. Use a `category=security` attribute, route via Collector to SIEM additionally.
- LLM prompt/response logs: SIEM cares about prompt injection attempts and data exfiltration; SRE cares about hallucination rate and latency. Same trace, two consumers.

```yaml
# Collector — route security-relevant logs to both SIEM and observability backend
processors:
  routing:
    from_attribute: security_event
    table:
      - value: "true"
        exporters: [otlphttp/splunk_es, otlp/datadog]
      - value: "false"
        exporters: [otlp/datadog]
```

## Datadog ASM (App Security Management)

Application-layer security signal inside the Datadog APM pipeline.

What it does:
- Agent-side WAF rules (OWASP Top 10 patterns, injection attempts, command injection).
- Attacker traces — every blocked or detected attack is traceable via APM.
- Business logic abuse detection (account takeover, credential stuffing, scraping).
- Vulnerability detection on dependencies (Software Composition Analysis).
- Exposed secrets in code.
- IAST (Interactive Application Security Testing) on traced requests.

Activation: enable in Agent config + AppSec features in Datadog UI; needs `dd-trace-*` SDK (or library injection) for full coverage. OTel-only does not get ASM today.

Use Datadog ASM if:
- You're already on Datadog APM.
- You want WAF + AppSec + APM correlated.
- You don't have a dedicated WAF (Cloudflare, AWS WAF, Imperva).

Don't use Datadog ASM if:
- Your WAF strategy is at the edge (Cloudflare, AWS WAF) and you're satisfied.
- You're OTel-only and not adopting `dd-trace-*`.

## Datadog CSPM / CWPP

Cloud Security Posture Management (CSPM) — continuously checks cloud accounts (AWS, GCP, Azure) against benchmarks (CIS, AWS Foundational, custom).

Cloud Workload Protection Platform (CWPP) — runtime security on workloads (containers, hosts). File integrity, process behavior, network anomalies.

Both surfaces inside Datadog Security. Competitors: Wiz, Lacework, Aqua Security, Sysdig Secure, Prisma Cloud.

Use Datadog CSPM/CWPP if Datadog is already your observability platform and your security tooling needs aren't deep (mature SOC teams pick Wiz or Prisma Cloud).

## Splunk Enterprise Security (ES)

The SIEM. Sits on top of Splunk Enterprise / Splunk Cloud. Provides:
- Threat intelligence ingestion.
- Notable events workflow (the SOC analyst's queue).
- Correlation rules (`tstats`-based searches on a schedule).
- Risk-based alerting (entity risk scores from many signals).
- MITRE ATT&CK navigator.
- Adaptive Response Actions (orchestration).

When Splunk ES is in the architecture:
- All security-relevant logs flow to Splunk (via HEC, Forwarders, or Cribl Stream as the front door).
- Observability signals (APM traces, metrics) stay in the APM platform — don't try to put them in Splunk ES.
- Apply data normalization via CIM (Common Information Model) so correlation rules work across sources.

If you're not already on Splunk ES, the 2026 alternatives are **Microsoft Sentinel** (best Microsoft-shop fit; Azure-native), **Elastic SIEM** (best Elastic-shop fit), **Chronicle / Google SecOps** (best GCP-shop fit), or **Panther / Hunters** (cloud-first SIEM startups). All except Chronicle are still maturing in head-to-head with Splunk ES.

## Sensitive Data Scanner — operational patterns

Datadog SDS specifically (since it's the most mature):

```hcl
# Terraform — SDS rule group for PCI logs
resource "datadog_sensitive_data_scanner_group" "pci_compliance" {
  name        = "PCI Compliance"
  description = "Redact PCI-DSS sensitive data from logs, APM, RUM"
  filter {
    query = "service:checkout-* OR service:payment-*"
  }
  product_list = ["logs", "apm", "rum"]
  is_enabled   = true
}

resource "datadog_sensitive_data_scanner_rule" "pan_with_luhn" {
  name                = "PAN (Luhn-validated)"
  description         = "Credit card numbers passing Luhn check"
  group_id            = datadog_sensitive_data_scanner_group.pci_compliance.id
  standard_pattern_id = data.datadog_sensitive_data_scanner_standard_pattern.credit_card.id
  text_replacement {
    type              = "replacement_string"
    replacement_string = "[REDACTED-PAN]"
  }
  excluded_namespaces = ["test-fixtures"]
  is_enabled         = true
}

resource "datadog_sensitive_data_scanner_rule" "aws_keys" {
  name                = "AWS Access Keys"
  group_id            = datadog_sensitive_data_scanner_group.pci_compliance.id
  standard_pattern_id = data.datadog_sensitive_data_scanner_standard_pattern.aws_access_key.id
  text_replacement {
    type              = "replacement_string"
    replacement_string = "[REDACTED-AWS-KEY]"
  }
  is_enabled = true
}
```

Operational gotchas:
- SDS scans **after ingest** — the unscrubbed data is in Datadog briefly. Datadog claims sub-second scrubbing latency, but for hard PCI compliance, app-layer redaction is the only safe path.
- SDS doesn't scrub the original; it **replaces in the indexed view**. If you query the raw via Logs Explorer, you see the redacted form.
- SDS rules can hash (hex) instead of replace — useful for joining redacted records without revealing the value. `text_replacement { type = "hash" }`.

## OTel Collector hardening

The Collector is a privileged pod. Harden it:

- **Run as non-root** (`runAsUser: 65534`, `runAsNonRoot: true`).
- **Read-only root filesystem** (`readOnlyRootFilesystem: true`).
- **No privileged mode** (`privileged: false`).
- **Drop all Linux capabilities** except those needed (CAP_NET_BIND_SERVICE if binding to <1024; usually unnecessary).
- **Limit egress** via NetworkPolicy — Collector can only reach approved vendor endpoints (Datadog API, NR API, etc.). No outbound to private CIDRs.
- **Don't expose Collector endpoints publicly** — OTLP receiver listens on `0.0.0.0` inside the cluster only; ingress only via authenticated gateway if accepting external traces.
- **Use service accounts with minimum scope** — Collector reading K8s API should have read-only `pods`, `nodes`, `namespaces` and nothing else.
- **TLS on every exporter** — never disable cert verification.
- **API keys in K8s Secrets**, not ConfigMaps. Use External Secrets Operator + Vault / AWS Secrets Manager / GCP Secret Manager.

```yaml
# Collector PodSpec — hardened
spec:
  serviceAccountName: otel-collector
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    fsGroup: 65534
    seccompProfile: { type: RuntimeDefault }
  containers:
    - name: otel-collector
      image: otel/opentelemetry-collector-contrib:0.110.0
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities: { drop: [ALL] }
      env:
        - name: DD_API_KEY
          valueFrom:
            secretKeyRef:
              name: datadog-api-key
              key: api-key
      volumeMounts:
        - name: config
          mountPath: /conf
          readOnly: true
        - name: tmp
          mountPath: /tmp
  volumes:
    - name: config
      configMap: { name: otel-collector-config }
    - name: tmp
      emptyDir: {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: otel-collector-egress
spec:
  podSelector: { matchLabels: { app: otel-collector } }
  egress:
    - to:
        - namespaceSelector: { matchLabels: { name: kube-system } }
      ports: [{ port: 53, protocol: UDP }]
    - to:
        - ipBlock: { cidr: 0.0.0.0/0, except: [10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16] }
      ports: [{ port: 443, protocol: TCP }]   # vendor endpoints over HTTPS
  policyTypes: [Egress]
```

## eBPF observability — security considerations

eBPF agents (Beyla, Pixie, Datadog USM, Tetragon) run with elevated capabilities. Security review:

- **Capabilities required**: `CAP_BPF`, `CAP_PERFMON`, sometimes `CAP_SYS_ADMIN`. These let the agent read all process memory and network traffic on the node.
- **Pod Security Standards** `restricted` profile **blocks these**. Use `baseline` or `privileged` profile in dedicated namespace with admission controller exception.
- **TLS-encrypted traffic** — eBPF can see metadata (5-tuple, sizes) but not plaintext. Some tools (Pixie) do user-space TLS keylog hooks for Go/Node/Python runtimes — verify your security team accepts this.
- **Vendor compromise impact** — a compromised eBPF agent has node-level visibility on every workload. Treat eBPF agent images as critical-tier supply chain (SBOM verification, signed images, Cosign verification).
- **CIS Benchmarks for eBPF collectors** landed late 2025 — operational hardening checklist.

For PCI/HIPAA workloads: eBPF agents should be reviewed and approved explicitly; default-deny in PSS, opt-in per namespace.

## Sentry — security-specific configuration

```typescript
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  // Server-side data scrubbing rules apply server-side regardless of client config;
  // beforeSend is the client-side last-line-of-defense
  beforeSend(event, hint) {
    // Drop events containing credential headers
    if (event.request?.headers) {
      delete event.request.headers['Authorization'];
      delete event.request.headers['Cookie'];
      delete event.request.headers['Set-Cookie'];
      delete event.request.headers['X-Api-Key'];
    }
    // Drop events from synthetic monitoring
    if (event.user?.id === 'synthetic-monitor') return null;
    return event;
  },
  // Issue Owners — auto-assign Sentry issues to teams based on stack trace
  // (configured in Sentry UI; route to Slack/email/PD per team)
});
```

Sentry Issue Owners (per-file ownership rules in Sentry UI):

```
# Sentry CODEOWNERS-like file
path:src/checkout/*           #checkout-team
path:src/auth/*               #auth-team
url:https://api.example.com/v1/payments*  #payments-team
```

Routes Sentry issues to the right team on creation. Without this, Sentry becomes an unowned issue dumpster.

## API key rotation and management

Every observability vendor uses API keys. Treat them as production credentials:

- **Store in Vault / AWS Secrets Manager / GCP Secret Manager / Azure Key Vault.** Never in K8s ConfigMaps or repo.
- **Use External Secrets Operator (ESO)** to project secrets into K8s Secrets dynamically.
- **Rotate quarterly** at minimum; on-demand on suspected compromise.
- **Scope keys narrowly** — each vendor lets you scope API keys to "ingest only," "read only," "admin." Use the narrowest scope per use case.
- **Audit key usage** — vendors expose key-last-used; alert on unused keys (rotate or revoke).
- **No personal API keys in production** — service accounts only. Personal keys leave when the engineer leaves.

```yaml
# External Secrets Operator — project Datadog key into K8s Secret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: datadog-api-key
spec:
  secretStoreRef:
    name: vault-secret-store
    kind: ClusterSecretStore
  target:
    name: datadog-api-key
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: secret/data/datadog/api-key
        property: value
```

## RBAC on observability platforms

Observability platforms hold privileged data. Apply least privilege:

- **Datadog**: Use Datadog Teams (since 2024); role-based access (Read/Standard/Admin); per-resource permissions (Dashboard, Monitor, SLO, Log Index). Avoid the catch-all Admin role; create custom roles.
- **New Relic**: Account / Group / Role-based access with per-product permissions.
- **Grafana**: Org → Team → Folder → Dashboard access; Datasource permissions (limit which datasources a team can query).
- **Splunk**: Role-based access; CIM-aware roles (only see security indexes if SOC role).
- **Honeycomb**: Team-based access; per-Environment permissions.
- **Sentry**: Organization → Team → Project hierarchy; per-Project access.
- **Dynatrace**: Management Zones (logical scope) + IAM policies.

SSO + SCIM provisioning is table-stakes. Every vendor supports SAML, most support SCIM (auto-provision/deprovision from Okta, Entra ID, OneLogin). Use it. Don't manage observability users by hand.

## Statuspage and disclosure

If you operate a statuspage (Statuspage.io, Better Stack, Instatus, Cachet):
- Updates should be automated from SLO alert state — manual updates are error-prone during incidents.
- Detail published externally must pass legal review for regulated industries (avoid revealing customer names, internal architecture details).
- Postmortem timing — many SLA contracts require root-cause disclosure within 5 business days. Publish a public-facing summary; keep internal postmortem private if it contains exploitable details.

## Anti-patterns

- **No PII scrubbing in any layer.** Logs / spans / metrics carry PII to vendor. Compliance failure.
- **Single observability tenant for prod + staging + dev.** Cross-environment contamination; staging logs containing test PII end up indexed for years.
- **API keys in repo or ConfigMap.** Trivially exfiltrated; key rotation impossible without a redeploy.
- **No audit log of the observability platform itself.** SOC can't tell if an insider queried sensitive data.
- **Disabling TLS verification on Collector exporters.** Telemetry MITM-able.
- **Trusting the vendor's compliance posture without reading the BAA / DPA / agreements.** Some "HIPAA-compliant" claims are partial (covers Logs, not Audit Trail, etc.).
- **Sending the same data to Datadog Logs AND Splunk ES AND Loki "in case we need it."** Triple cost, triple liability surface.
- **No PII redaction in test environments.** Test fixtures often include real-looking data; SDS / scrubbers must apply to all environments equally.

## Integration with always-on protocols

### TDD on scrubbing rules

- Write a test that asserts a log line containing a PAN never reaches the vendor mock.
- Write a test that asserts a JWT in an HTTP header doesn't appear in span attributes.
- Run scrubbers against a known-PII fixture set in CI; assert zero matches in the post-scrub output.

### Verification

After enabling SDS / scrubbing:
- Inject a synthetic PII record at the app boundary.
- Query the vendor for that record's recent ingest.
- Assert the value is redacted.
- Repeat per pattern (PAN, SSN, email, JWT, AWS key).

### Plan execution

Compliance work has explicit deadlines (audit dates, certification windows). Plan each scrubbing rollout with the cutover date and verification artifact. Don't ship scrubbing rules and hope.

### Branch safety

- Scrubbing rule changes are PRs with the scrubbing test pass evidence.
- API key rotation is announced + scheduled + rollback path tested.
- Vendor RBAC changes are PR'd via Terraform (Datadog, NR, Grafana, Honeycomb, Sentry all have Terraform providers for users/teams/roles).

### Debugging

- PII in a vendor → which layer failed? App-layer (developer used `log.info(user.email)`)? Collector-layer (scrubbing rule pattern didn't match)? Vendor-layer (SDS rule disabled for this scope)?
- Audit-log gap → did the audit log integration silently break? Check the ingest pipeline.
- API key compromise alert → rotate immediately, audit recent usage, identify the leak source (GitGuardian / TruffleHog scan repos and the public web).

## Cross-references

- **Vendor selection (compliance dimension)** → see `sre-engineer.md` and SKILL.md compliance composition.
- **Collector hardening** → see `devops-engineer.md` and this overlay's hardening section.
- **App-layer redaction patterns** → see `backend-architect.md` log conventions.
- **OTel semantic conventions and PII attribute discipline** → https://opentelemetry.io/docs/specs/semconv/.
- **Vertical compliance specifics (HIPAA, PCI, SOX)** → vertical specialists (healthcare-architect, fintech-architect).
