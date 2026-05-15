# Application Security — Deep Reference

**Always use `WebSearch` to verify current tool versions, vulnerability databases, OWASP updates, and framework-specific security advice before giving recommendations.**

## Table of Contents
1. [OWASP Top 10 (2025)](#1-owasp-top-10-2025)
2. [SAST Tools](#2-sast-tools)
3. [DAST Tools](#3-dast-tools)
4. [SCA and Dependency Scanning](#4-sca-and-dependency-scanning)
5. [SBOM Standards and Compliance](#5-sbom-standards-and-compliance)
6. [API Security](#6-api-security)
7. [Secure Coding Patterns](#7-secure-coding-patterns)
8. [Supply Chain Security](#8-supply-chain-security)
9. [Shift-Left Security in CI/CD](#9-shift-left-security-in-cicd)
10. [AI-Powered Application Security](#10-ai-powered-application-security)
11. [Container and Cloud-Native AppSec](#11-container-and-cloud-native-appsec)
12. [AppSec Tool Selection Framework](#12-appsec-tool-selection-framework)

---

## 1. OWASP Top 10 (2025)

### Current Status

The OWASP Top 10 2025 was officially released, drawing from 500,000+ applications across 40+ organizations (double the 2021 data) and analyzing 589 CWEs. Key shifts: root causes over symptoms, supply chain elevated, SSRF consolidated into access control.

| Rank | 2025 Category | Change from 2021 |
|------|--------------|------------------|
| A01 | Broken Access Control | Remains #1 (100% prevalence). Now absorbs SSRF (was A10:2021) |
| A02 | Security Misconfiguration | Moved UP from A05:2021 — cloud/container misconfig increasingly common |
| A03 | **Software Supply Chain Failures** | **NEW** — expanded from A06:2021 Vulnerable Components. Covers full lifecycle: packages, build systems, deployment pipelines |
| A04 | Cryptographic Failures | Was A02:2021, moved down |
| A05 | Injection | Was A03:2021, moved down. All injection types (SQL, NoSQL, OS, LDAP, template, header) |
| A06 | Insecure Design | Was A04:2021 — emphasis on threat modeling during design phase |
| A07 | Authentication Failures | Was A07:2021 (renamed). Updated for passkeys/WebAuthn, OIDC |
| A08 | Software or Data Integrity Failures | Was A08:2021 — SBOM, artifact signing, CI/CD security |
| A09 | Security Logging and Alerting Failures | Was A09:2021 (renamed from "Monitoring" to "Alerting"). SIEM integration, detection engineering |
| A10 | **Mishandling of Exceptional Conditions** | **NEW** — covers error handling, fail-open logic, resilience failures |

### OWASP API Security Top 10 (2023)

The API-specific list (released 2023, still current) focuses on API-unique risks:

| Rank | Category | Description |
|------|----------|-------------|
| API1 | Broken Object Level Authorization (BOLA) | Manipulating IDs to access other users' resources |
| API2 | Broken Authentication | Weak auth mechanisms, credential stuffing |
| API3 | Broken Object Property Level Authorization | Mass assignment, excessive data exposure |
| API4 | Unrestricted Resource Consumption | Missing rate limiting, pagination abuse |
| API5 | Broken Function Level Authorization | Privilege escalation via API endpoints |
| API6 | Unrestricted Access to Sensitive Business Flows | Bot abuse of legitimate business processes |
| API7 | Server Side Request Forgery | SSRF through API parameters |
| API8 | Security Misconfiguration | Permissive CORS, verbose errors, missing headers |
| API9 | Improper Inventory Management | Shadow APIs, deprecated endpoints still active |
| API10 | Unsafe Consumption of APIs | Trusting third-party API responses without validation |

### OWASP Top 10 for LLM Applications (v2.0, 2025)

| Rank | Category | Description |
|------|----------|-------------|
| LLM01 | Prompt Injection | Direct and indirect manipulation of LLM behavior |
| LLM02 | Sensitive Information Disclosure | Model leaking training data or system prompts |
| LLM03 | Supply Chain Vulnerabilities | Poisoned models, malicious plugins, compromised training data |
| LLM04 | Data and Model Poisoning | Tampering with training/fine-tuning data |
| LLM05 | Improper Output Handling | Using LLM output without sanitization in downstream systems |
| LLM06 | Excessive Agency | Over-permissioned tool use, autonomous actions without guardrails |
| LLM07 | System Prompt Leakage | Extraction of system instructions through adversarial prompts |
| LLM08 | Vector and Embedding Weaknesses | Poisoned embeddings, adversarial retrieval in RAG systems |
| LLM09 | Misinformation | Hallucinated security advice, fabricated vulnerability references |
| LLM10 | Unbounded Consumption | Resource exhaustion through prompt complexity, token abuse |

---

## 2. SAST Tools

### Tool Comparison Matrix (2025-2026)

| Feature | Semgrep | SonarQube/Cloud | CodeQL | Checkmarx One | Fortify |
|---------|---------|----------------|--------|---------------|---------|
| **Architecture** | Local-first CLI + Cloud | Server + Cloud SaaS | GitHub-hosted analysis | SaaS platform | On-prem + Cloud |
| **Languages** | 30+ (pattern-based) | 30+ | 15+ (deep semantic) | 30+ | 30+ |
| **Custom rules** | YAML (very easy) | Java/XML (moderate) | QL language (steep) | CxQL | Custom rules (moderate) |
| **CI/CD integration** | Native (all major CI) | Built-in | GitHub Actions native | All major CI | All major CI |
| **IDE support** | VS Code, IntelliJ, Cursor | All major IDEs | VS Code (native) | VS Code, IntelliJ | VS Code, IntelliJ, Eclipse |
| **AI features** | AI-powered autofix, Assistant | AI CodeFix (SonarQube 2025+) | Copilot Autofix | Checkmarx AI Security | Fortify Audit AI |
| **Secrets detection** | Built-in (Semgrep Secrets) | Basic | No (separate tool) | Via integration | Basic |
| **SCA included** | Semgrep Supply Chain | SonarQube dependency-check | Dependabot (separate) | Checkmarx SCA | Debricked (acquired) |
| **Pricing** | Free Community + paid Teams | Free Community + paid | Free for public repos | Enterprise only | Enterprise only |
| **Scan speed** | Very fast (multicore, 3x since 2025) | Moderate | Slow (deep analysis) | Moderate | Slow |
| **False positive rate** | Low-moderate | Moderate | Low (deep analysis) | Moderate | Moderate-high |

### Semgrep (2025-2026)

Key developments:
- **Multicore scanning**: Up to 3x faster scans (Fall 2025)
- **Native Windows support**: GA for CLI and IDE extensions (Fall 2025)
- **Managed Scanning**: GA October 2025 — bulk repository addition without CI changes
- **Cursor Plugin Marketplace**: Official presence with MCP server, Hooks, and Skills for SAST, supply chain, and secrets scanning
- **MCP Server**: Integration with AI coding assistants
- **Semgrep Secrets**: Critical severity for secret findings (Nov 2025+)
- **Priority Findings**: New Priority tab with customizable categories (Dec 2025)
- **Memory policy flag**: `--x-mem-policy` for OCaml GC tuning (Feb 2026)
- **Taint tracking improvements**: Reduced false positives through better assignment tracking

**Semgrep rule example** (detecting SQL injection in Python):
```yaml
rules:
  - id: sql-injection-format-string
    patterns:
      - pattern: |
          cursor.execute(f"...{$VAR}...")
      - pattern-not: |
          cursor.execute(f"...{CONST}...")
    message: >
      Potential SQL injection via f-string. Use parameterized queries instead.
    severity: ERROR
    languages: [python]
    metadata:
      owasp: A03:2021 Injection
      cwe: CWE-89
      confidence: HIGH
    fix: |
      cursor.execute("... %s ...", ($VAR,))
```

### CodeQL

GitHub's deep semantic analysis engine:
- **Copilot Autofix**: Automatically generates security fix PRs for CodeQL findings
- **Free for public repositories**, included in GitHub Advanced Security for private repos
- **Default query suites**: Curated by GitHub Security Lab, cover OWASP Top 10
- **Custom queries**: Written in QL (datalog-like), powerful but steep learning curve
- **Multi-repository variant analysis**: Find the same vulnerability pattern across all org repos

**CodeQL query example** (detecting SSRF):
```ql
import python
import sst.dataflow.new.TaintTracking
import sst.dataflow.new.DataFlow

class SsrfConfig extends TaintTracking::Configuration {
  SsrfConfig() { this = "SsrfConfig" }
  override predicate isSource(DataFlow::Node source) {
    source instanceof RemoteFlowSource
  }
  override predicate isSink(DataFlow::Node sink) {
    exists(Call call |
      call.getCallee().getName() = ["urlopen", "get", "post", "request"] and
      sink.asExpr() = call.getArg(0)
    )
  }
}
```

### SonarQube (2025-2026)

- **AI CodeFix**: AI-powered fix suggestions integrated into IDE and PR workflows
- **SonarQube Cloud**: Fully managed SaaS option
- **Clean as You Code**: Default methodology — only scan new/changed code
- **Security Hotspots**: Review-focused findings for context-dependent vulnerabilities
- **Quality Gates**: Block PRs that don't meet quality/security thresholds

---

## 3. DAST Tools

### Tool Comparison

| Feature | ZAP (Zaproxy) | Burp Suite Pro | Nuclei | Caido |
|---------|--------------|----------------|--------|-------|
| **Type** | Open-source DAST proxy | Commercial DAST proxy | Template-based scanner | Modern proxy + scanner |
| **Maintained by** | ZAP (formerly OWASP ZAP) | PortSwigger | ProjectDiscovery | Caido Labs |
| **Architecture** | Java-based proxy | Java-based proxy | Go binary + YAML templates | Rust-based, plugin system |
| **Automation** | ZAP Automation Framework | Burp CI/CD extension | CLI-native, CI-friendly | API-driven, CI-ready |
| **API scanning** | OpenAPI import + scan | OpenAPI, GraphQL | Template-based | OpenAPI import |
| **Custom checks** | Zest scripts, add-ons | BApp extensions (Java/Python) | YAML templates (very easy) | JavaScript plugins |
| **CI/CD integration** | Docker image, GitHub Action | Enterprise CI integration | Docker, GitHub Action | Docker, API |
| **Pricing** | Free (open source) | $449/user/yr (Pro), Enterprise pricing | Free (open source) | Free core + paid features |
| **Best for** | Automated CI/CD scanning | Manual + automated pentesting | Large-scale vulnerability scanning | Modern alternative to Burp |

### ZAP (Zaproxy)

Formerly OWASP ZAP, now an independent project (still open source):
- **Automation Framework**: YAML-based configuration for CI/CD scanning
- **GraphQL scanning**: Built-in support for GraphQL introspection and query testing
- **API scan**: Import OpenAPI/Swagger spec and auto-generate security tests
- **Dockerized scanning**: Official Docker images for headless CI/CD integration

**ZAP Automation Framework example:**
```yaml
env:
  contexts:
    - name: "API Context"
      urls:
        - "https://api.example.com"
      includePaths:
        - "https://api.example.com/api/v1/.*"
      authentication:
        method: "json"
        parameters:
          loginPageUrl: "https://api.example.com/auth/login"
          loginRequestUrl: "https://api.example.com/auth/login"
          loginRequestBody: '{"email":"{%username%}","password":"{%password%}"}'

jobs:
  - type: openapi
    parameters:
      apiUrl: "https://api.example.com/openapi.json"
      context: "API Context"
  - type: activeScan
    parameters:
      context: "API Context"
      policy: "API-Scan-Policy"
  - type: report
    parameters:
      template: "sarif-json"
      reportDir: "/zap/reports"
      reportFile: "zap-report.sarif"
```

### Nuclei

ProjectDiscovery's template-based scanner:
- **10,000+ community templates** covering CVEs, misconfigurations, exposures, default credentials
- **YAML templates**: Easy to write, share, and maintain
- **Headless browser**: Chrome-based crawling for SPAs
- **Workflow support**: Chain templates together for complex detection
- **PDCP (ProjectDiscovery Cloud Platform)**: Managed scanning at scale

**Nuclei template example** (detecting exposed .env file):
```yaml
id: exposed-env-file
info:
  name: Exposed Environment File
  severity: high
  tags: exposure,config
  classification:
    cwe-id: CWE-538
    owasp: A05:2021

http:
  - method: GET
    path:
      - "{{BaseURL}}/.env"
    matchers-condition: and
    matchers:
      - type: word
        words:
          - "DB_PASSWORD"
          - "API_KEY"
          - "SECRET"
        condition: or
      - type: status
        status:
          - 200
      - type: word
        part: header
        words:
          - "text/plain"
          - "application/octet-stream"
        condition: or
```

---

## 4. SCA and Dependency Scanning

### Tool Comparison

| Feature | Snyk | Dependabot | Renovate | Trivy | Grype |
|---------|------|------------|----------|-------|-------|
| **Type** | Commercial SCA platform | GitHub-native | Open-source bot | Open-source scanner | Open-source scanner |
| **Languages** | All major | All GitHub-supported | All major + more | All major | All major |
| **Vulnerability DB** | Snyk Vulnerability DB (curated) | GitHub Advisory DB | Multiple sources | Multiple (NVD, GitHub, etc.) | Grype DB (anchore) |
| **Auto-fix PRs** | Yes (with upgrade paths) | Yes (version bumps) | Yes (highly configurable) | No (scanner only) | No (scanner only) |
| **License scanning** | Yes | No | No | Yes | No |
| **Container scanning** | Yes | No | No | Yes (primary use case) | Yes |
| **IaC scanning** | Snyk IaC | No | No | Yes (misconfig) | No |
| **SBOM generation** | Yes | No | No | Yes (SPDX, CycloneDX) | Yes (CycloneDX) |
| **Reachability analysis** | Yes (filters unreachable vulns) | No | No | No | No |
| **Pricing** | Free tier + paid | Free (GitHub included) | Free (open source) | Free (open source) | Free (open source) |
| **CI/CD integration** | All major CI | GitHub Actions only | All major CI | All major CI | All major CI |

### Snyk (2025-2026)

Key features:
- **DeepCode AI Fix**: AI-powered fix suggestions for vulnerabilities
- **Reachability analysis**: Filters out vulnerabilities in code paths that are never called — reduces noise by 70-90%
- **Snyk Container**: Scans container images with base image recommendations
- **Snyk IaC**: Terraform, CloudFormation, Kubernetes YAML scanning
- **Snyk Code (SAST)**: Integrated SAST with real-time IDE feedback
- **Priority Score**: 0-1000 score combining CVSS, exploit maturity, reachability, and social trends

### Trivy (2025-2026)

**CRITICAL**: In March 2026, trivy-action GitHub Action was supply-chain compromised — malicious v0.69.4 exfiltrated credentials for ~3 hours. Docker Hub images v0.69.5/v0.69.6 were also compromised. **Safe versions: v0.69.3, trivy-action v0.35.0, setup-trivy v0.2.6.** Always pin actions by SHA.

Aqua Security's open-source scanner — now the Swiss Army knife of security scanning:
- **Container images**: Full vulnerability scanning with OS and language package detection
- **Filesystem scanning**: Scan local projects for vulnerable dependencies
- **IaC misconfigurations**: Terraform, CloudFormation, Docker, Kubernetes
- **Kubernetes scanning**: CIS benchmarks, RBAC analysis, NetworkPolicy audit
- **SBOM generation**: Output in SPDX and CycloneDX formats
- **Secret detection**: Built-in secret scanning capability
- **VEX support**: Vulnerability Exploitability eXchange for filtering false positives
- **WASM plugins**: Extend scanning capabilities with custom WebAssembly plugins

**Trivy CI/CD example (GitHub Actions):**
```yaml
- name: Trivy vulnerability scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail the build on findings

- name: Upload Trivy SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

### Renovate vs Dependabot

| Feature | Renovate | Dependabot |
|---------|----------|------------|
| **Scheduling** | Highly configurable (cron, timezone, automerge windows) | Limited (daily, weekly, monthly) |
| **Grouping** | Group related updates into single PRs | Limited grouping |
| **Automerge** | Built-in with configurable rules | Via GitHub auto-merge |
| **Monorepo support** | Excellent (multi-manager, path rules) | Basic |
| **Custom managers** | Regex managers for any file format | Fixed managers only |
| **Platforms** | GitHub, GitLab, Bitbucket, Azure DevOps, Gitea | GitHub only |
| **Private registries** | Full support with encrypted credentials | Basic support |
| **Replacement PRs** | Suggest replacing deprecated packages | No |

---

## 5. SBOM Standards and Compliance

### SPDX vs CycloneDX

| Feature | SPDX (v3.0, Apr 2024) | CycloneDX (v1.7, Oct 2025) |
|---------|---------------------|-------------------|
| **Maintained by** | Linux Foundation / ISO | OWASP |
| **ISO standard** | Yes (ISO/IEC 5962:2021) | No (but widely adopted) |
| **Primary focus** | License compliance + security + AI/Dataset profiles | Security-oriented BOM |
| **Format** | JSON, XML, RDF, YAML, tag-value | JSON, XML, Protobuf |
| **VEX support** | Via separate SPDX VEX document | Built-in VEX (v1.4+) |
| **SBOM types** | Software packages, files, AI models, datasets (profiles in v3.0) | Software, hardware, services, ML models, cryptographic assets (CBOM) |
| **Vulnerability linking** | Via external references | Native vulnerability element |
| **Adoption** | Required by NTIA, US federal government | Preferred by OWASP ecosystem, common in DevSecOps |

### Regulatory Requirements (2025-2026)

| Regulation | SBOM Requirement | Timeline |
|-----------|-----------------|----------|
| **US Executive Order 14028** | SBOMs required for federal software procurement | Active since 2021, enforcement tightening |
| **EU Cyber Resilience Act (CRA)** | SBOMs mandatory for products with digital elements in EU. Machine-readable (JSON/XML), CycloneDX 1.4+ or SPDX 2.3+ per TR-03183 | Compliance deadline: December 2027 |
| **FDA Cybersecurity Guidelines** | SBOMs required for medical device software | Active |
| **NTIA Minimum Elements** | Defines minimum SBOM fields: supplier, component name, version, dependency relationship, author, timestamp | Active baseline |

### SBOM Generation Pipeline

```yaml
# GitHub Actions: Generate SBOM, scan, attest
- name: Generate SBOM (Trivy)
  run: |
    trivy fs . \
      --format cyclonedx \
      --output sbom.cdx.json

- name: Scan SBOM for vulnerabilities
  run: |
    grype sbom:sbom.cdx.json \
      --fail-on high \
      --output sarif > vuln-results.sarif

- name: Attest SBOM provenance
  uses: actions/attest-build-provenance@v2
  with:
    subject-name: ghcr.io/org/app
    subject-digest: ${{ steps.build.outputs.digest }}
```

---

## 6. API Security

### API Security Architecture

```
Client → CDN/WAF → API Gateway → Auth Middleware → Rate Limiter → Business Logic → Data Store
           |            |              |                |              |
       DDoS         Routing,       JWT/OAuth        Per-user/      Input
       protection   TLS term,      validation,      per-endpoint   validation,
       bot mgmt     request        scope check      throttling     authZ check
                    validation
```

### API Gateway Security Features

| Feature | Kong | AWS API Gateway | Azure APIM | Envoy/Istio |
|---------|------|----------------|------------|-------------|
| **AuthN** | JWT, OAuth2, mTLS, API key | Cognito, Lambda auth, IAM | Azure AD, OAuth2, certificates | JWT, mTLS, ext auth |
| **Rate limiting** | Built-in (Redis-backed) | Built-in (per-stage) | Built-in (policies) | Envoy rate limit service |
| **WAF integration** | Plugin | AWS WAF native | Azure WAF native | External integration |
| **Input validation** | Schema validation plugin | Request validation | Policy-based | External filter |
| **mTLS** | Built-in | ACM integration | Built-in | Built-in (Istio) |
| **Logging** | Centralized logging plugins | CloudWatch, X-Ray | Azure Monitor | Access logging, tracing |

### Common API Vulnerabilities and Mitigations

| Vulnerability | Detection | Mitigation |
|--------------|-----------|------------|
| **BOLA (API1)** | Test accessing resources with different user tokens | Object-level authorization checks in every endpoint |
| **Mass Assignment** | Fuzz with extra fields in request bodies | Explicit allowlists for writable fields, DTOs |
| **Rate Limit Bypass** | Test with distributed IPs, header manipulation | Multi-factor rate limiting (IP + user + API key) |
| **SSRF via API params** | Supply internal URLs, cloud metadata URLs | URL allowlisting, block private IP ranges, disable redirects |
| **GraphQL attacks** | Deep nesting, field duplication, introspection | Query depth/complexity limits, disable introspection in prod |
| **JWT vulnerabilities** | Algorithm confusion, expired token reuse | Use asymmetric algorithms (RS256/ES256), validate exp/iss/aud |

### Security Headers Checklist

```
# Essential security headers for APIs
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Cache-Control: no-store
Content-Type: application/json; charset=utf-8

# CORS (restrict to known origins)
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Max-Age: 86400
```

---

## 7. Secure Coding Patterns

### Injection Prevention

**SQL Injection** — Always use parameterized queries:

```python
# Python (SQLAlchemy) - SAFE
result = db.execute(text("SELECT * FROM users WHERE email = :email"), {"email": user_email})

# Python - VULNERABLE (never do this)
result = db.execute(f"SELECT * FROM users WHERE email = '{user_email}'")
```

```go
// Go (database/sql) - SAFE
row := db.QueryRow("SELECT id, name FROM users WHERE email = $1", email)

// Go - VULNERABLE
row := db.QueryRow("SELECT id, name FROM users WHERE email = '" + email + "'")
```

```typescript
// TypeScript (Prisma) - SAFE by default (parameterized)
const user = await prisma.user.findUnique({ where: { email: userEmail } });

// TypeScript (raw SQL) - use tagged template for parameterization
const user = await prisma.$queryRaw`SELECT * FROM users WHERE email = ${userEmail}`;
```

### XSS Prevention

**Modern framework defaults** — React, Vue, Svelte, and Angular auto-escape by default. Danger zones:

```jsx
// React - VULNERABLE (dangerouslySetInnerHTML)
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// React - SAFE (use DOMPurify if you must render HTML)
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />

// React - SAFE (auto-escaped by default)
<div>{userContent}</div>
```

**Next.js App Router** — Server Components reduce XSS surface area because they don't ship JavaScript to the client. But Server Actions that return HTML or use `dangerouslySetInnerHTML` still need sanitization.

### SSRF Prevention

```python
# FastAPI - SSRF prevention middleware
import ipaddress
from urllib.parse import urlparse

BLOCKED_NETWORKS = [
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("169.254.169.254/32"),  # Cloud metadata
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("::1/128"),
]

def validate_url(url: str) -> bool:
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https"):
        return False
    try:
        ip = ipaddress.ip_address(parsed.hostname)
        return not any(ip in network for network in BLOCKED_NETWORKS)
    except ValueError:
        # Hostname, not IP — resolve and check
        import socket
        resolved = socket.getaddrinfo(parsed.hostname, None)
        for _, _, _, _, addr in resolved:
            ip = ipaddress.ip_address(addr[0])
            if any(ip in network for network in BLOCKED_NETWORKS):
                return False
        return True
```

### CSRF Protection

```typescript
// Next.js App Router - Server Actions have built-in CSRF protection via Origin header check
// For traditional REST APIs, use the double-submit cookie pattern:

// Middleware (Next.js)
import { NextResponse } from 'next/server';

export function middleware(request: Request) {
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(request.method)) {
    const origin = request.headers.get('origin');
    const host = request.headers.get('host');
    if (!origin || new URL(origin).host !== host) {
      return new NextResponse('CSRF validation failed', { status: 403 });
    }
  }
}
```

---

## 8. Supply Chain Security

### SLSA Framework (Supply-chain Levels for Software Artifacts)

| Level | Build Requirements | Provenance | What It Prevents |
|-------|-------------------|------------|------------------|
| **L0** | None | None | Nothing — baseline |
| **L1** | Documented build process | Auto-generated, distributable | Mistakes, ad-hoc builds |
| **L2** | Hosted build service | Signed provenance | Tampering after build |
| **L3** | Hardened, isolated, ephemeral builds | Non-falsifiable provenance | Compromised build environment |

### Artifact Signing with Sigstore

```yaml
# Sign container images (keyless, OIDC-based)
- uses: sigstore/cosign-installer@v3
- run: |
    cosign sign --yes \
      ghcr.io/org/app@${{ steps.build.outputs.digest }}

# Verify signatures
- run: |
    cosign verify \
      --certificate-identity=https://github.com/org/app/.github/workflows/build.yml@refs/heads/main \
      --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
      ghcr.io/org/app@${{ steps.build.outputs.digest }}
```

### Dependency Lockfile Integrity

Always commit and verify lockfiles:
- **npm**: `npm ci` (installs from lockfile exactly, fails if lockfile is out of sync)
- **pnpm**: `pnpm install --frozen-lockfile`
- **yarn**: `yarn install --immutable`
- **pip**: `pip install --require-hashes -r requirements.txt`
- **Go**: `go mod verify` (checks hashes in `go.sum`)

### GitHub Actions Supply Chain Security

```yaml
# Pin actions by SHA (not tag — tags can be moved)
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# Restrict permissions to minimum needed
permissions:
  contents: read
  packages: write
  id-token: write  # Only if OIDC is needed

# Use GitHub's dependency submission API for visibility
- uses: advanced-security/maven-dependency-submission-action@v4
```

---

## 9. Shift-Left Security in CI/CD

### Security Pipeline Architecture

```
Pre-commit         PR / CI              Build             Post-deploy
────────────       ──────────           ─────             ───────────
Secret scanning    SAST (Semgrep)       Container scan    DAST scan
Lint security      SCA (Snyk/Trivy)     SBOM generate     Runtime monitor
Commit signing     License check        Image sign        Bug bounty
                   Unit security tests  Provenance attest Pen test
                   IaC scanning                           Compliance scan
```

### Pre-commit Security Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: https://github.com/returntocorp/semgrep
    rev: v1.100.0
    hooks:
      - id: semgrep
        args: ['--config', 'auto', '--error']

  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint
```

### Security Quality Gate (GitHub Actions)

```yaml
name: Security Gate
on: pull_request

permissions:
  contents: read
  security-events: write

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: SAST - Semgrep
        uses: semgrep/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/security-audit
          generateSarif: "1"

      - name: SCA - Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
          format: 'sarif'
          output: 'trivy.sarif'

      - name: Secret Scan - Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: '.'
```

### Security Champions Program

A security champions program embeds security expertise across engineering teams:

| Aspect | Implementation |
|--------|---------------|
| **Selection** | 1 champion per 8-10 developers, voluntary with manager support |
| **Training** | Monthly security training, access to security team resources |
| **Responsibilities** | Triage security findings, security design reviews for team's PRs, threat modeling participation |
| **Tooling** | Access to security scanning tools, Slack channel with security team |
| **Recognition** | Quarterly recognition, career growth path, conference attendance |
| **Time allocation** | 10-20% of time dedicated to security champion activities |

---

## 10. AI-Powered Application Security

### Current AI Security Tools (2025-2026)

| Tool | AI Capability | Status |
|------|-------------|--------|
| **GitHub Copilot Autofix** | Generates fix PRs for CodeQL findings | GA |
| **Semgrep Assistant** | AI-powered triage, autofix, and custom rule generation | GA |
| **Snyk DeepCode AI Fix** | AI fix suggestions for vulnerabilities | GA |
| **SonarQube AI CodeFix** | AI-powered fix suggestions in IDE and PR | GA (2025) |
| **Amazon CodeGuru Security** | ML-based code analysis for AWS-specific patterns | GA |
| **Checkmarx AI Security** | AI-powered vulnerability detection and prioritization | GA |
| **Socket.dev** | AI-powered supply chain risk detection | GA |

### AI for Security Use Cases

| Use Case | How AI Helps | Limitations |
|----------|-------------|-------------|
| **Vulnerability detection** | Pattern recognition beyond regex rules | May miss novel attack vectors |
| **Fix generation** | Auto-generate security patches | Fixes need human review — AI can introduce new vulns |
| **Triage and prioritization** | Reduce noise by 50-80% | Still needs security expert validation for critical findings |
| **Custom rule generation** | Generate Semgrep/CodeQL rules from natural language | Rules need testing and tuning |
| **Security code review** | Flag suspicious patterns in PRs | Supplement to, not replacement for, human review |

---

## 11. Container and Cloud-Native AppSec

### Container Security Scanning Pipeline

```
Base image selection → Dockerfile linting → Build → Scan → Sign → Deploy → Runtime monitor
      |                      |                         |       |                  |
  Chainguard/           Hadolint,                  Trivy,  Cosign,          Falco,
  distroless            Dockle                     Grype,  Sigstore         Tetragon,
  minimal images                                   Docker                   KubeArmor
                                                   Scout
```

### Base Image Security

| Image Type | Size | CVEs (typical) | Use Case |
|-----------|------|----------------|----------|
| **Ubuntu/Debian** | 80-120 MB | 50-200+ | Development, debugging |
| **Alpine** | 5-8 MB | 0-10 | Small footprint, musl libc |
| **Distroless (Google)** | 2-20 MB | 0-5 | Production, no shell |
| **Chainguard Images** | 2-15 MB | 0 (target) | Highest security posture |
| **Wolfi-based** | 3-20 MB | 0-2 | Chainguard's OS, glibc-based |

### Runtime Application Security

| Tool | Approach | Overhead | Best For |
|------|---------|----------|----------|
| **Falco** | eBPF syscall monitoring | Low (1-3%) | Kubernetes runtime detection |
| **Tetragon** | eBPF with enforcement | Very low (<1%) | Cilium-based policy enforcement |
| **KubeArmor** | eBPF + LSM | Low | Pod-level least privilege enforcement |
| **RASP (commercial)** | In-process agent | Moderate (5-15%) | Legacy apps, deep inspection |

---

## 12. AppSec Tool Selection Framework

### Decision Tree

```
What do you need?
├── Finding vulnerabilities in YOUR code
│   ├── During development (IDE) → Semgrep, SonarLint, Snyk IDE
│   ├── In CI/CD (automated) → Semgrep + CodeQL (if GitHub) + SonarQube
│   └── Custom rules needed → Semgrep (easiest) or CodeQL (deepest)
│
├── Finding vulnerabilities in DEPENDENCIES
│   ├── Auto-fix PRs → Dependabot (GitHub) or Renovate (multi-platform)
│   ├── Deep analysis + reachability → Snyk
│   ├── Container images → Trivy or Grype
│   └── License compliance → Snyk, FOSSA, or Trivy
│
├── Finding vulnerabilities in RUNNING apps
│   ├── Automated CI/CD DAST → ZAP Automation Framework
│   ├── Manual + automated pentesting → Burp Suite Pro
│   ├── Large-scale scanning → Nuclei
│   └── Runtime protection → Falco, Tetragon, KubeArmor
│
├── Generating SBOMs
│   ├── Container-focused → Trivy (CycloneDX or SPDX)
│   ├── Multi-format → syft (Anchore)
│   └── License + security → Snyk
│
└── Signing and attestation
    ├── Container images → cosign (Sigstore)
    ├── Build provenance → SLSA + actions/attest-build-provenance
    └── Arbitrary artifacts → cosign sign-blob
```

### AppSec Maturity Progression

| Level | What to Deploy | Estimated Effort |
|-------|---------------|-----------------|
| **L1 — Basic** | Dependabot/Renovate + GitHub secret scanning + HTTPS + security headers | 1-2 days |
| **L2 — Automated** | Add Semgrep in CI + Trivy container scan + pre-commit hooks | 1 week |
| **L3 — Comprehensive** | Add CodeQL/SonarQube + DAST (ZAP) + SBOM generation + security gate in CI | 2-4 weeks |
| **L4 — Advanced** | Reachability analysis (Snyk) + artifact signing + security champions + custom rules | 1-3 months |
| **L5 — Mature** | Bug bounty + continuous pentesting + AI-powered triage + runtime protection (eBPF) | Ongoing |
