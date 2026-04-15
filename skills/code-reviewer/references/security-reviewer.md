# Security Reviewer — Deep Reference

**Always use `WebSearch` to verify current OWASP updates, CVE databases, tool versions, and vulnerability disclosures before giving security review advice. The threat landscape changes daily — what was secure last month may have a disclosed vulnerability today.**

## Table of Contents
1. [OWASP Top 10 (2025) for Code Review](#1-owasp-top-10-2025-for-code-review)
2. [Injection Vulnerabilities](#2-injection-vulnerabilities)
3. [Authentication and Authorization Flaws](#3-authentication-and-authorization-flaws)
4. [Sensitive Data Exposure](#4-sensitive-data-exposure)
5. [Dependency and Supply Chain Security](#5-dependency-and-supply-chain-security)
6. [Secrets Detection](#6-secrets-detection)
7. [SAST Tools for Code Review](#7-sast-tools-for-code-review)
8. [Security Headers and Configuration](#8-security-headers-and-configuration)
9. [API Security Review](#9-api-security-review)
10. [Language-Specific Security Patterns](#10-language-specific-security-patterns)
11. [Automated vs. Manual Security Review](#11-automated-vs-manual-security-review)
12. [Security Review Checklist](#12-security-review-checklist)

---

## 1. OWASP Top 10 (2025) for Code Review

The OWASP Top 10 is the most widely referenced standard for web application security. The 2025 edition reflects shifts in the threat landscape:

| # | Category | Key Changes from 2021 | What to Look For in Code |
|---|----------|-----------------------|-------------------------|
| A01 | **Broken Access Control** | Now absorbs SSRF (was A10:2021); stays #1 | Missing authz checks on endpoints, IDOR (direct object references without ownership validation), path traversal, CORS misconfiguration, SSRF |
| A02 | **Security Misconfiguration** | Up from #5 | Default credentials, verbose error messages in production, unnecessary features enabled, missing security headers, debug mode in production |
| A03 | **Software Supply Chain Failures** | **NEW** — expands "Vulnerable Components" | Unvetted dependencies, no lock file integrity, missing SCA scanning, no SBOM, pulling from unverified registries |
| A04 | **Cryptographic Failures** | Down from #2 | Weak algorithms (MD5, SHA1 for passwords), hardcoded keys, missing encryption at rest/transit, improper certificate validation |
| A05 | **Injection** | Down from #3 | SQL injection, XSS, command injection, LDAP injection, template injection, header injection |
| A06 | **Insecure Design** | Down from #4 | Missing threat modeling, no rate limiting on sensitive operations, missing business logic validation, no abuse case analysis |
| A07 | **Authentication Failures** | Stable | Weak password requirements, missing MFA, session fixation, credential stuffing vulnerability, insecure password storage |
| A08 | **Software or Data Integrity Failures** | Stable | Insecure deserialization, missing integrity verification of updates/data, CI/CD pipeline compromise |
| A09 | **Logging & Alerting Failures** | Renamed | Missing audit logging for sensitive operations, PII in logs, no alerting on auth failures, insufficient log retention |
| A10 | **Mishandling of Exceptional Conditions** | **NEW** | Unhandled errors exposing stack traces, error paths bypassing security controls, resource exhaustion from uncaught exceptions |

---

## 2. Injection Vulnerabilities

### SQL Injection

**How to spot in review**: Look for string concatenation or interpolation in SQL queries.

```python
# VULNERABLE — string formatting
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")
cursor.execute("SELECT * FROM users WHERE email = '%s'" % email)
cursor.execute("SELECT * FROM users WHERE email = '" + email + "'")

# SAFE — parameterized queries
cursor.execute("SELECT * FROM users WHERE email = %s", [email])
```

```javascript
// VULNERABLE — template literal in SQL
const result = await db.query(`SELECT * FROM users WHERE id = ${userId}`);

// SAFE — parameterized
const result = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
```

```java
// VULNERABLE — string concatenation
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("SELECT * FROM users WHERE id = " + userId);

// SAFE — PreparedStatement
PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
pstmt.setInt(1, userId);
```

**ORM-specific risks**: Even ORMs can have injection if raw queries or unsanitized values are used in `.extra()`, `.raw()`, `RawSQL`, or Knex `.whereRaw()`.

### Cross-Site Scripting (XSS)

| Type | Vector | Example |
|------|--------|---------|
| **Reflected** | User input in URL reflected in response | Search results page showing query unescaped |
| **Stored** | User input saved to DB and rendered to other users | Comment with `<script>` tag stored and displayed |
| **DOM-based** | Client-side JS writes user input to DOM | `document.innerHTML = location.hash` |

**Framework-specific review**:

| Framework | Default Protection | Watch For |
|-----------|-------------------|-----------|
| React | Auto-escapes JSX output | `dangerouslySetInnerHTML`, `href={userInput}` (javascript: URLs) |
| Angular | Auto-sanitizes bindings | `bypassSecurityTrustHtml()`, `[innerHTML]` with unsanitized data |
| Vue | Auto-escapes template output | `v-html` directive with user content |
| Go templates | `html/template` auto-escapes | Using `text/template` for HTML, `template.HTML()` casting |
| Django | Auto-escapes templates | `|safe` filter, `mark_safe()`, `{% autoescape off %}` |
| Rails | Auto-escapes ERB | `raw()`, `html_safe`, `<%==` |

### Server-Side Request Forgery (SSRF)

**How to spot**: Any endpoint that takes a URL as input and makes a server-side HTTP request.

```python
# VULNERABLE — user controls the URL
@app.route('/fetch')
def fetch_url():
    url = request.args.get('url')
    response = requests.get(url)  # Can access internal services, metadata APIs
    return response.text

# Attacks:
# /fetch?url=http://169.254.169.254/latest/meta-data/  (AWS metadata)
# /fetch?url=http://localhost:6379/  (Internal Redis)
# /fetch?url=file:///etc/passwd  (Local file read)
```

**Mitigations**:
- Allowlist permitted domains/IPs
- Block RFC 1918 private ranges (10.x, 172.16-31.x, 192.168.x), link-local (169.254.x), localhost
- Block cloud metadata endpoints (169.254.169.254, metadata.google.internal)
- Use a dedicated egress proxy with allowlisting
- Disable redirects or validate redirect targets

### Command Injection

**How to spot**: Any use of `os.system()`, `subprocess.run(shell=True)`, `exec()`, `eval()`, backtick operators.

```python
# VULNERABLE
os.system(f"convert {filename} output.png")  # filename could be "; rm -rf /"

# SAFE — use array form, no shell
subprocess.run(["convert", filename, "output.png"], shell=False)
```

```javascript
// VULNERABLE
const { exec } = require('child_process');
exec(`git log --author="${author}"`, callback);  // author could be "; cat /etc/passwd"

// SAFE — use execFile or spawn with array args
const { execFile } = require('child_process');
execFile('git', ['log', `--author=${author}`], callback);
```

---

## 3. Authentication and Authorization Flaws

### Authentication Review

**What to check**:

| Area | What to Review | Red Flags |
|------|---------------|-----------|
| **Password storage** | Hashing algorithm and work factor | MD5, SHA1, SHA256 for passwords; use bcrypt (cost 12+), scrypt, or Argon2id |
| **Session management** | Cookie attributes, token lifecycle | Missing `HttpOnly`, `Secure`, `SameSite`; no session expiry; no rotation after login |
| **JWT implementation** | Algorithm, validation, claims | `alg: none` accepted, symmetric key for multi-party, no `exp` claim, secret in code |
| **MFA** | Implementation correctness | TOTP window too large, backup codes not hashed, MFA bypass in error paths |
| **Rate limiting** | Brute force protection | No rate limit on login, OTP verification, password reset |
| **Password reset** | Token security | Predictable tokens, no expiry, token reuse, no invalidation on password change |

### Authorization Review (Broken Access Control)

This is the #1 OWASP risk. Look for:

**Missing authorization checks**:
```python
# VULNERABLE — no ownership check (IDOR)
@app.route('/api/invoices/<invoice_id>')
def get_invoice(invoice_id):
    invoice = Invoice.query.get(invoice_id)  # Any user can access any invoice
    return jsonify(invoice.to_dict())

# SAFE — verify ownership
@app.route('/api/invoices/<invoice_id>')
@login_required
def get_invoice(invoice_id):
    invoice = Invoice.query.get(invoice_id)
    if invoice.user_id != current_user.id:
        abort(403)
    return jsonify(invoice.to_dict())
```

**Common access control flaws**:
- Relying solely on UI to hide unauthorized actions (server must enforce)
- Missing role checks on admin endpoints
- Horizontal privilege escalation (accessing another user's resources)
- Vertical privilege escalation (acting as admin without admin role)
- Mass assignment (allowing users to set `is_admin=true` via request body)
- Path traversal (`../../etc/passwd` in file parameters)

---

## 4. Sensitive Data Exposure

### What to Look For in Code Review

**Data at rest**:
- Passwords stored in plaintext or with weak hashing
- PII (emails, SSNs, phone numbers) stored unencrypted when regulations require encryption
- Sensitive data in logs (`logger.info(f"User {email} logged in with password {password}")`)
- Sensitive data in URLs/query parameters (appears in server logs, browser history, referrer headers)
- Database backups without encryption

**Data in transit**:
- HTTP instead of HTTPS for any sensitive data
- Missing TLS certificate validation (`verify=False` in Python requests, `NODE_TLS_REJECT_UNAUTHORIZED=0`)
- Weak TLS versions (TLS 1.0, 1.1) still permitted
- Sensitive data in WebSocket connections without WSS

**Data in code/config**:
- API keys, database passwords, secrets hardcoded in source
- `.env` files committed to git
- Secrets in CI/CD configuration files
- AWS/GCP/Azure credentials in source code
- Private keys in the repository

### PII in Logs

**Common mistake**: Logging request/response bodies that contain user data.

```python
# VULNERABLE — logs everything including passwords, SSNs
logger.info(f"Request body: {request.json}")

# SAFE — log only non-sensitive fields
logger.info(f"User login attempt: user_id={request.json.get('email')}")
```

**Remediation**: Implement structured logging with field-level redaction. Use allow-lists (log only known-safe fields) rather than deny-lists (try to filter sensitive fields).

---

## 5. Dependency and Supply Chain Security

### The Threat Landscape (2025-2026)

Software supply chain attacks have exploded — malicious npm packages surged from 38 in 2018 to 2,168+ in 2024. Supply chain attacks more than doubled in 2025, with 30% of data breaches now linked to third-party/supply chain issues. The OWASP Top 10 (2025) elevated this to its own category (A03).

### Dependency Scanning Tools

| Tool | Approach | Strength | Weakness |
|------|----------|----------|----------|
| **Dependabot** | Known CVE matching | Free on GitHub, auto-PRs | Reactive — only catches known CVEs |
| **Snyk** | CVE matching + reachability | Developer-friendly, IDE integration, fix suggestions | Can be noisy, per-developer cost |
| **Socket.dev** | Behavioral analysis | Proactive — detects malicious behavior BEFORE CVE | Newer, smaller rule set |
| **Sonatype Repository Firewall** | Registry proxy | Blocks malicious packages at install time | Enterprise pricing |
| **npm audit / yarn audit** | Built-in CVE check | Free, no setup | Limited to known CVEs, high false positive rate |

**Recommended strategy**: Layer reactive + proactive scanning:
1. **Dependabot/Snyk** for known CVE monitoring (reactive)
2. **Socket.dev** for behavioral analysis of new dependencies (proactive)
3. **Lock file integrity** — always commit lock files, verify checksums
4. **Pin major versions** — avoid `^` or `~` for critical dependencies in production
5. **Review new dependencies before adding** — check package age, maintainer reputation, download stats, security posture

### What to Check in Review When a New Dependency Is Added

- Is this dependency necessary? Could the functionality be achieved with existing deps or a few lines of code?
- What permissions does it need? (network access, file system, native bindings)
- Who maintains it? (single developer? organization? last commit date?)
- What's the download count? (very new or very unpopular packages are higher risk)
- Does it have known vulnerabilities? (check Snyk, npm audit)
- Is it pulling in a large transitive dependency tree? (more deps = more attack surface)
- Is there an alternative from a well-known publisher?

---

## 6. Secrets Detection

### Tools Comparison

| Tool | Method | Speed | Depth | Best Deployment |
|------|--------|-------|-------|----------------|
| **Gitleaks** | Regex-based pattern matching | Very fast | Surface-level | Pre-commit hook + CI |
| **TruffleHog** | 800+ purpose-built detectors + credential verification | Slower | Deep (verifies if credentials are live) | CI/CD pipeline |
| **detect-secrets** (Yelp) | Entropy-based + regex | Fast | Good at detecting high-entropy strings | Pre-commit |
| **git-secrets** (AWS) | AWS-specific patterns | Very fast | AWS-focused | Pre-commit for AWS projects |

**Recommended deployment**: Run Gitleaks pre-commit (fast feedback before secrets enter git history) + TruffleHog in CI (deep analysis with verification that caught secrets are actually live).

### Common Secret Patterns to Catch in Review

| Secret Type | Pattern Examples |
|-------------|----------------|
| AWS Keys | `AKIA[0-9A-Z]{16}`, `aws_secret_access_key` |
| GCP Service Account | `"type": "service_account"` in JSON |
| GitHub Tokens | `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_` prefixes |
| Stripe Keys | `sk_live_`, `rk_live_` |
| Database URLs | `postgres://`, `mysql://`, `mongodb://` with credentials |
| JWT Secrets | Base64-encoded symmetric keys, `JWT_SECRET` variables |
| Generic API Keys | High-entropy strings assigned to `*_KEY`, `*_SECRET`, `*_TOKEN` variables |

### When You Find a Secret in Review

1. **Don't merge** — block the PR immediately
2. **Rotate the credential** — assume it's already compromised (it's been in a PR diff that may have been viewed)
3. **Remove from code** — use environment variables, secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager)
4. **Scrub git history** — `git filter-repo` or BFG Repo-Cleaner (force push required)
5. **Add prevention** — install Gitleaks pre-commit hook to prevent recurrence

---

## 7. SAST Tools for Code Review

### Tool Comparison

| Tool | Analysis Type | Speed | Languages | Custom Rules | Cost |
|------|-------------|-------|-----------|-------------|------|
| **Semgrep** | Pattern-based | ~10s in CI | 30+ | YAML (easy to write) | Free OSS / $30/committer |
| **CodeQL** | Semantic (data/taint flow) | Minutes to 30+ min | 12 deep | QL language (learning curve) | Free for public repos / $30/committer |
| **SonarQube** | Rule-based + data flow | Minutes | 27+ | Java SDK | Free Community / paid |
| **Snyk Code** | AI-powered + rules | Seconds in IDE | 15+ | Limited | Free tier / $25+/dev |

**Layered deployment strategy**:

```
Every PR (fast feedback, < 30s):
  └── Semgrep — pattern-based scanning for OWASP Top 10

Nightly/weekly (deep analysis):
  └── CodeQL — semantic taint analysis, data flow tracking

Full analysis (scheduled):
  └── SonarQube — comprehensive quality + security
```

### Writing Custom Semgrep Rules

For project-specific patterns (e.g., "never call our internal API without the auth header"), Semgrep rules are straightforward:

```yaml
rules:
  - id: no-raw-sql-in-django
    patterns:
      - pattern: |
          $MODEL.objects.raw($QUERY)
      - pattern-not: |
          $MODEL.objects.raw($QUERY, $PARAMS)
    message: "Use parameterized queries with .raw() to prevent SQL injection"
    severity: ERROR
    languages: [python]
```

---

## 8. Security Headers and Configuration

### HTTP Security Headers Checklist

| Header | Value | Purpose | Risk If Missing |
|--------|-------|---------|----------------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Force HTTPS | Downgrade attacks, cookie theft |
| `Content-Security-Policy` | Restrictive policy | Prevent XSS, data injection | XSS exploitation |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing | File-based XSS |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` | Prevent clickjacking | UI redress attacks |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Control referrer leakage | URL data leaked to third parties |
| `Permissions-Policy` | Restrict features | Disable unused browser APIs | Feature abuse |

### CORS Configuration Review

**Common mistakes**:
- `Access-Control-Allow-Origin: *` with `Access-Control-Allow-Credentials: true` — allows any site to make authenticated requests
- Reflecting the `Origin` header without validation — effectively the same as `*`
- Allowing `null` origin — exploitable via sandboxed iframes and data URIs

**What to check**:
- Origin is validated against an explicit allowlist (not reflected or wildcarded)
- Credentials are only allowed for trusted origins
- `Access-Control-Allow-Methods` and `Access-Control-Allow-Headers` are minimally scoped
- Preflight responses are cached appropriately (`Access-Control-Max-Age`)

### Content Security Policy (CSP) Review

**Starting point** (restrictive):
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self';
  style-src 'self';
  img-src 'self' data:;
  connect-src 'self';
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
```

**Red flags in CSP**:
- `unsafe-inline` for script-src (defeats XSS protection — use nonce or hash instead)
- `unsafe-eval` (allows `eval()` — almost never necessary)
- `*` wildcards in any directive
- Missing `frame-ancestors` (clickjacking risk)
- CDN domains in script-src without SRI (subresource integrity) hash

---

## 9. API Security Review

### API-Specific Vulnerabilities

| Vulnerability | What to Check | Example |
|---------------|--------------|---------|
| **Broken Object-Level Authorization** | Every endpoint verifies resource ownership | `GET /api/users/123/orders` — does it check if the caller is user 123? |
| **Broken Function-Level Authorization** | Admin endpoints require admin role | `DELETE /api/users/123` — is admin check enforced server-side? |
| **Mass Assignment** | Request body fields are explicitly allowed | `POST /api/users` with `{"name":"...", "is_admin": true}` |
| **Rate Limiting** | Sensitive endpoints have rate limits | Login, OTP verification, password reset, API key generation |
| **Excessive Data Exposure** | API returns only needed fields | `GET /api/users` returning password hashes, internal IDs, PII |
| **Missing Input Validation** | All inputs validated for type, length, format | String fields with no max length, numeric fields accepting negative values |

### Request/Response Review

**Requests**:
- All input validated and sanitized (type, length, format, allowlist)
- Content-Type enforced (reject requests with unexpected content types)
- Large payloads limited (request body size limits)
- File uploads validated (type, size, content — not just extension)

**Responses**:
- No sensitive data in error messages (stack traces, SQL errors, internal paths)
- Consistent error format (don't leak implementation details via different error structures)
- Pagination enforced (prevent returning unbounded result sets)
- No internal identifiers exposed unnecessarily

---

## 10. Language-Specific Security Patterns

### JavaScript/TypeScript

| Issue | Pattern to Flag | Fix |
|-------|----------------|-----|
| XSS via `dangerouslySetInnerHTML` | React component using `dangerouslySetInnerHTML` with user data | Sanitize with DOMPurify, or use plain text |
| Prototype pollution | `Object.assign(target, userInput)`, `lodash.merge({}, userInput)` | Freeze prototypes, validate input keys, use `Map` |
| ReDoS | Complex regex with nested quantifiers | Use `re2` library, test regex with rxxr2, set timeout |
| `eval()` / `new Function()` | Dynamic code execution with user input | Never evaluate user-controlled strings |
| `javascript:` URLs | `href={userInput}` in React/Vue | Validate URL scheme, only allow `http:` / `https:` |
| Insecure randomness | `Math.random()` for tokens/secrets | Use `crypto.randomUUID()` or `crypto.getRandomValues()` |

### Python

| Issue | Pattern to Flag | Fix |
|-------|----------------|-----|
| SQL injection | String formatting in SQL | Use parameterized queries / ORM |
| Command injection | `os.system()`, `subprocess.run(shell=True)` | `subprocess.run(args_list, shell=False)` |
| SSRF | `requests.get(user_url)` | Allowlist domains, block private IPs |
| Insecure deserialization | `pickle.loads(user_data)`, `yaml.load()` | Use `yaml.safe_load()`, avoid `pickle` for untrusted data |
| Path traversal | `open(base_path + user_filename)` | Use `pathlib.resolve()` and validate against base directory |
| Weak hashing | `hashlib.md5(password)` for password storage | Use `bcrypt`, `scrypt`, or `argon2` |

### Go

| Issue | Pattern to Flag | Fix |
|-------|----------------|-----|
| SSRF | `http.Get(userURL)` | Validate URL, block private IPs, use allowlist |
| SQL injection | `fmt.Sprintf("... WHERE id = %s", id)` | Use `db.Query(sql, id)` with placeholder |
| Integer overflow | `int32(int64Value)` without bounds check | Check bounds before conversion |
| Race condition | Shared state without mutex | Use `sync.Mutex`, `sync.RWMutex`, or channels |
| Weak crypto | `math/rand` for security-sensitive values | Use `crypto/rand` |
| Template injection | `text/template` for HTML | Use `html/template` which auto-escapes |
| Path traversal | `filepath.Join(base, userInput)` | Use `filepath.Rel()` and verify result is under base |

### Java

| Issue | Pattern to Flag | Fix |
|-------|----------------|-----|
| Deserialization | `ObjectInputStream.readObject()` with untrusted data | Use allow-list deserialization filter, avoid Java serialization |
| XXE | `DocumentBuilderFactory` without disabling external entities | Disable external entities and DTDs |
| JNDI injection | User input in JNDI lookups (Log4Shell class) | Disable JNDI lookups, filter input |
| SQL injection | `Statement.executeQuery(userSQL)` | Use `PreparedStatement` |
| Path traversal | `new File(base, userInput)` | Canonicalize path and verify under base |
| Insecure random | `java.util.Random` for security | Use `java.security.SecureRandom` |

### Rust

| Issue | Pattern to Flag | Fix |
|-------|----------------|-----|
| `unsafe` blocks | Any `unsafe` code | Review carefully, minimize scope, document invariants |
| SQL injection | String formatting in SQL queries | Use sqlx query macros or parameterized queries |
| Integer overflow | Arithmetic in release mode (wraps silently) | Use `checked_*`, `saturating_*`, or `overflowing_*` methods |
| FFI boundary issues | Passing raw pointers to/from C | Validate all data crossing FFI boundary |
| Panics in library code | `.unwrap()`, `.expect()`, `panic!()` | Return `Result` types, use `?` operator |

---

## 11. Automated vs. Manual Security Review

### What to Automate

| Category | Tool | When to Run |
|----------|------|-------------|
| Known vulnerability patterns | Semgrep | Every PR (< 30s) |
| Taint analysis / data flow | CodeQL | Nightly/weekly |
| Dependency CVEs | Dependabot, Snyk | Continuous |
| Malicious dependency behavior | Socket.dev | On dependency changes |
| Secrets in code | Gitleaks (pre-commit), TruffleHog (CI) | Every commit/PR |
| Security headers | Mozilla Observatory, securityheaders.com | Scheduled |
| TLS configuration | testssl.sh | Scheduled |

### What Requires Human Review

- Business logic authorization (can user A access user B's data in this specific flow?)
- Threat modeling for new features (what are the attack vectors?)
- Crypto protocol correctness (not just "is this using AES?" but "is the mode correct? Is the IV handled properly?")
- Race conditions in authentication/authorization flows
- Complex SSRF bypass scenarios
- Cross-service authorization in microservices
- Data flow analysis across system boundaries (where does PII go?)

---

## 12. Security Review Checklist

### Input Handling
- [ ] All user input validated (type, length, format, allowlist)
- [ ] No string concatenation/interpolation in SQL queries
- [ ] No `eval()`, `exec()`, `os.system()` with user input
- [ ] File uploads validated (type, size, content — not just extension)
- [ ] URLs validated against allowlist before server-side fetching

### Authentication & Authorization
- [ ] Every endpoint has appropriate auth checks (not just UI hiding)
- [ ] Resource ownership verified (IDOR prevention)
- [ ] Admin functions require admin role (server-enforced)
- [ ] Mass assignment prevented (explicit field allowlisting)
- [ ] Rate limiting on auth-related endpoints

### Data Protection
- [ ] No secrets/credentials hardcoded in source
- [ ] Sensitive data not logged
- [ ] PII encrypted at rest where required
- [ ] HTTPS enforced, TLS properly configured
- [ ] Sensitive data not in URLs/query parameters

### Dependencies
- [ ] New dependencies vetted (maintainer, age, downloads, security posture)
- [ ] Lock file updated and committed
- [ ] No known CVEs in dependencies
- [ ] Dependency scanning in CI

### Configuration
- [ ] Security headers configured (HSTS, CSP, X-Content-Type-Options)
- [ ] CORS restrictive (no `*` with credentials)
- [ ] Debug/development features disabled in production
- [ ] Error messages don't expose internal details
