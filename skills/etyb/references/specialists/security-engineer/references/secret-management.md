# Secret Management — Deep Reference

**Always use `WebSearch` to verify current tool versions, pricing changes, and cloud service updates before giving advice. Secret management tooling and best practices evolve rapidly.**

## Table of Contents
1. [HashiCorp Vault](#1-hashicorp-vault)
2. [OpenBao (Vault Fork)](#2-openbao-vault-fork)
3. [Cloud Secrets Managers](#3-cloud-secrets-managers)
4. [Certificate Management](#4-certificate-management)
5. [Key Management Services (KMS)](#5-key-management-services-kms)
6. [Secret Scanning](#6-secret-scanning)
7. [Secret Rotation Strategies](#7-secret-rotation-strategies)
8. [Kubernetes Secrets Patterns](#8-kubernetes-secrets-patterns)
9. [OIDC Federation for Secretless Pipelines](#9-oidc-federation-for-secretless-pipelines)
10. [Environment Variable Hygiene](#10-environment-variable-hygiene)
11. [Confidential Computing](#11-confidential-computing)
12. [Secret Management Selection Framework](#12-secret-management-selection-framework)

---

## 1. HashiCorp Vault

### Version History and License

| Version | Release | Key Features | License |
|---------|---------|-------------|---------|
| **1.15** | Sep 2023 | Last MPL-licensed release | MPL 2.0 (open source) |
| **1.16+** | 2024+ | BSL (Business Source License) | BSL 1.1 |
| **1.21.0** | Mar 2026 | SPIFFE Auth, KV v2 Attribution, VSO CSI Driver, FIPS 140-3 Level 1 (Enterprise) | BSL 1.1 |

**BSL License Impact**: Vault 1.16+ uses BSL 1.1, which restricts hosting Vault as a competing managed service. Self-hosted use for internal purposes is unaffected. Organizations concerned about the license change can use OpenBao (MPL fork) or cloud-native alternatives.

**IBM Acquisition**: IBM completed its $6.4B acquisition of HashiCorp in February 2025.

**HCP Vault Secrets (SaaS)**: Discontinued — end of sale June 30, 2025; end of life July 1, 2026. Use HCP Vault Dedicated (managed single-tenant) or self-hosted Vault Enterprise instead.

### Vault Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Vault Cluster                         │
│                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐                │
│  │  Active   │   │ Standby  │   │ Standby  │   (HA Cluster) │
│  │  Node     │   │  Node    │   │  Node    │                │
│  └────┬─────┘   └──────────┘   └──────────┘                │
│       │                                                      │
│  ┌────┴───────────────────────────────────────┐             │
│  │              Storage Backend                │             │
│  │  (Raft / Consul / DynamoDB / PostgreSQL)   │             │
│  └────────────────────────────────────────────┘             │
│                                                              │
│  Secret Engines:  KV | Transit | PKI | Database | AWS | SSH │
│  Auth Methods:    OIDC | K8s | AWS IAM | AppRole | LDAP    │
│  Policies:        HCL-based ACL policies                     │
│  Audit:           File | Syslog | Socket                     │
└──────────────────────────────────────────────────────────────┘
```

### Key Vault Features

**Dynamic Secrets** — Vault generates short-lived credentials on demand:
```bash
# Database dynamic secret (PostgreSQL)
vault read database/creds/my-role
# Returns: username=v-token-my-role-xxx, password=xxx, ttl=1h

# AWS dynamic credentials
vault read aws/creds/deploy-role
# Returns: access_key=AKIA..., secret_key=xxx, ttl=1h
```

**Transit Encryption (Encryption-as-a-Service)**:
```bash
# Encrypt data without storing it in Vault
vault write transit/encrypt/my-key plaintext=$(echo "sensitive" | base64)
# Returns: ciphertext=vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok481zoCmHnSeDX9vyf7w==

# Decrypt
vault write transit/decrypt/my-key ciphertext=vault:v1:8SDd...
# Returns: plaintext=c2Vuc2l0aXZl (base64 encoded)
```

**PKI Secrets Engine**:
```bash
# Generate intermediate CA
vault write pki_int/intermediate/generate/internal \
  common_name="Internal CA" \
  ttl=43800h

# Issue short-lived TLS certificates
vault write pki_int/issue/web-server \
  common_name="api.internal.example.com" \
  ttl=24h
```

### Vault Deployment Patterns

| Pattern | Description | When to Use |
|---------|-------------|-------------|
| **Single cluster** | One Vault cluster, HA with 3-5 nodes | Most deployments, single region |
| **Performance replication** | Read replicas in multiple regions | Multi-region, read-heavy workloads |
| **DR replication** | Warm standby cluster for disaster recovery | Business continuity requirements |
| **HCP Vault** | Managed Vault service (HashiCorp Cloud Platform) | Teams without Vault operational expertise |
| **Vault Secrets Operator** | K8s operator that syncs Vault secrets to K8s | Kubernetes-native deployments |
| **Vault Agent** | Sidecar that handles auth and secret caching | Legacy apps that can't integrate natively |

### HCP Vault vs Self-Hosted

| Feature | HCP Vault (Managed) | Self-Hosted |
|---------|---------------------|-------------|
| **Operations** | HashiCorp manages upgrades, backups, HA | Your team manages everything |
| **Networking** | HVN (HashiCorp Virtual Network) peered to your VPC | Your network, your responsibility |
| **Compliance** | SOC 2, ISO 27001 certified | You manage compliance |
| **Secret engines** | All major engines supported | All engines |
| **Pricing** | Per-secret-operation + cluster size | License cost + infrastructure + operations |
| **Best for** | Teams without Vault ops expertise | Full control, air-gapped, compliance-specific |

---

## 2. OpenBao (Vault Fork)

### Background

OpenBao is a community-maintained fork of HashiCorp Vault, created after Vault's license change to BSL:

**Current Version**: OpenBao **v2.5.2** (March 2026). Active development.

| Feature | OpenBao | Vault (BSL) |
|---------|---------|-------------|
| **License** | MPL 2.0 (truly open source) | BSL 1.1 |
| **Governance** | Linux Foundation | HashiCorp (IBM) |
| **API compatibility** | Compatible with Vault API | N/A |
| **Namespaces** | Yes (was Vault Enterprise-only) | Enterprise only |
| **Read scalability** | Horizontal read replicas (v2.5.0+) | Enterprise Performance Standby Nodes |
| **Enterprise features** | Growing (namespaces, read scaling now available) | Full feature set (replication, HSM, etc.) |
| **Support** | Community | HashiCorp/IBM commercial support |
| **When to choose** | License concerns, OSS principles, need namespaces without Enterprise | Need full enterprise features, vendor support, HCP |

### Migration Path

OpenBao maintains API compatibility with Vault, meaning most plugins, CLI commands, and integrations work. Organizations on Vault 1.15 or earlier can migrate with minimal disruption. Notable: IBM engineers are among key OpenBao contributors despite IBM owning HashiCorp.

---

## 3. Cloud Secrets Managers

### Comparison Matrix

| Feature | AWS Secrets Manager | AWS SSM Parameter Store | Azure Key Vault | GCP Secret Manager |
|---------|--------------------|-----------------------|-----------------|-------------------|
| **Secret rotation** | Built-in (Lambda-based) | No built-in rotation | Manual or Azure Function | Manual or Cloud Function |
| **Versioning** | Automatic versioning | Versioned parameters | Versioned secrets | Automatic versioning |
| **Encryption** | AWS KMS (mandatory) | AWS KMS (optional) | Azure-managed or BYOK | Google-managed or CMEK |
| **Cross-region** | Replication supported | No cross-region | Geo-replication (Premium) | Replication supported |
| **Access control** | IAM policies + resource policies | IAM policies | Azure RBAC + Access Policies | IAM policies |
| **Audit** | CloudTrail | CloudTrail | Azure Monitor + Diagnostic Logs | Cloud Audit Logs |
| **Max secret size** | 64 KB | 8 KB (Advanced: 8 KB) | 25 KB | 64 KB |
| **Pricing** | $0.40/secret/month + $0.05/10K API calls | Free (Standard) / $0.05/adv param/month | Secrets: $0.03/10K ops | $0.06/secret version/month + $0.03/10K access ops |
| **Best for** | Primary secrets store, auto-rotation | Config values, feature flags, non-rotating secrets | Azure-native apps, certificate management | GCP-native apps |

### AWS Secrets Manager Auto-Rotation

```python
# Lambda rotation function structure
import boto3
import json

def lambda_handler(event, context):
    step = event['Step']
    secret_id = event['SecretId']
    token = event['ClientRequestToken']

    client = boto3.client('secretsmanager')

    if step == 'createSecret':
        # Generate new secret value
        new_password = generate_password()
        client.put_secret_value(
            SecretId=secret_id,
            ClientRequestToken=token,
            SecretString=json.dumps({'password': new_password}),
            VersionStages=['AWSPENDING']
        )

    elif step == 'setSecret':
        # Apply new secret to the target service (e.g., RDS)
        pending = get_secret_value(client, secret_id, 'AWSPENDING')
        update_database_password(pending['password'])

    elif step == 'testSecret':
        # Verify the new secret works
        pending = get_secret_value(client, secret_id, 'AWSPENDING')
        test_database_connection(pending['password'])

    elif step == 'finishSecret':
        # Promote AWSPENDING to AWSCURRENT
        client.update_secret_version_stage(
            SecretId=secret_id,
            VersionStage='AWSCURRENT',
            MoveToVersionId=token,
            RemoveFromVersionId=get_current_version(client, secret_id)
        )
```

---

## 4. Certificate Management

### cert-manager (Kubernetes)

The standard for automated certificate management in Kubernetes. **Latest: v1.20.0** (March 2026) — HTTPS config for HTTPRoute, Gateway API 1.3 ListenerSet support.

```yaml
# ClusterIssuer for Let's Encrypt
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: security@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
      - dns01:
          cloudDNS:
            project: my-gcp-project
            serviceAccountSecretRef:
              name: clouddns-dns01-solver

---
# Certificate resource
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-tls
  namespace: production
spec:
  secretName: api-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - api.example.com
    - api-internal.example.com
  duration: 2160h    # 90 days
  renewBefore: 360h  # Renew 15 days before expiry
```

### Certificate Lifecycle Management

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────────┐
│   Request    │ ──→ │    Issue     │ ──→ │   Monitor    │ ──→ │   Renew     │
│   (CSR)      │     │   (CA signs) │     │   (expiry)   │     │   (auto)    │
└─────────────┘     └──────────────┘     └──────────────┘     └─────────────┘
                                                │
                                          ┌─────┴─────┐
                                          │  Revoke   │
                                          │  (if key  │
                                          │ compromised)│
                                          └───────────┘
```

### Let's Encrypt and ACME

| Feature | Let's Encrypt | Details |
|---------|--------------|---------|
| **Protocol** | ACME v2 (RFC 8555) | Automated certificate issuance |
| **Certificate types** | DV (Domain Validated) only | No OV or EV certificates |
| **Validity (current)** | 90 days | Short-lived by design, encourages automation |
| **6-day certs** | Available since Feb 2025 | Select "shortlived" ACME profile, renew every 2-3 days |
| **45-day cert timeline** | May 2026: `tlsserver` profile → 45 days; Feb 2027: default → 64 days; Feb 2028: default → 45 days | Gradual transition |
| **Rate limits** | 300 new orders/account/day; 50 certs/domain/week | ARI renewals exempt from all rate limits |
| **Wildcard certs** | Yes (DNS-01 challenge required) | *.example.com |
| **Multi-domain (SAN)** | Up to 100 SANs per certificate | Combine multiple domains |
| **Cost** | Free | Funded by sponsors and donations |
| **Issuance volume** | 400M+ active certificates | Largest CA by certificate count |

### Internal PKI

For internal service-to-service mTLS, don't use public CAs — run your own internal PKI:

| Tool | Use Case | Features |
|------|----------|---------|
| **Vault PKI** | Enterprise internal CA | Dynamic cert issuance, short-lived, role-based, audit trail |
| **step-ca** (Smallstep) | Lightweight internal CA | ACME server, SSH certs, OIDC provisioner, open source |
| **AWS Private CA** | AWS-native internal CA | Managed CA, ACM integration, S/MIME, code signing |
| **cert-manager + internal issuer** | K8s-native | Combines with Vault, step-ca, or cloud CAs |
| **CFSSL** (Cloudflare) | Simple CA toolkit | CLI and API for cert issuance, open source |

---

## 5. Key Management Services (KMS)

### Cloud KMS Comparison

| Feature | AWS KMS | Azure Key Vault | GCP Cloud KMS |
|---------|---------|-----------------|---------------|
| **Key types** | Symmetric (AES-256), Asymmetric (RSA, ECC) | Symmetric, Asymmetric, EC | Symmetric, Asymmetric, MAC |
| **HSM-backed** | Yes (all keys), dedicated HSM available | Premium tier = HSM, Managed HSM available | HSM protection level |
| **BYOK** | Yes (import key material) | Yes (import or transfer) | Yes (import key material) |
| **External keys** | External Key Store (XKS) — keys in customer HSM | Managed HSM | External Key Manager (EKM) |
| **Automatic rotation** | Yes (1 year default, configurable) | Configurable (manual or auto) | Configurable |
| **Multi-region** | Multi-Region Keys | Geo-replication (Premium) | Global keys |
| **Integration** | All AWS services | All Azure services | All GCP services |
| **Pricing** | $1/key/month + $0.03/10K requests | $0.03/10K ops | $0.06/key version/month + $0.03/10K ops |
| **Compliance** | FIPS 140-2 Level 2 (standard), Level 3 (CloudHSM) | FIPS 140-2 Level 2 (Standard), Level 3 (Premium/Managed HSM) | FIPS 140-2 Level 3 (HSM) |

### Envelope Encryption Pattern

```
1. Generate Data Encryption Key (DEK) from KMS
2. Encrypt data with DEK (locally, fast)
3. Encrypt DEK with KMS Master Key (Key Encryption Key, KEK)
4. Store encrypted data + encrypted DEK together
5. Discard plaintext DEK from memory

Decryption:
1. Send encrypted DEK to KMS for decryption
2. Use plaintext DEK to decrypt data locally
3. Discard plaintext DEK from memory

Benefits:
- Data never leaves your service (only the small DEK goes to KMS)
- Performance: local symmetric encryption is fast
- KMS only handles key operations, not bulk data
```

```python
# AWS KMS envelope encryption example
import boto3
from cryptography.fernet import Fernet
import base64

kms = boto3.client('kms')

# Generate data key
response = kms.generate_data_key(KeyId='alias/my-app-key', KeySpec='AES_256')
plaintext_key = response['Plaintext']
encrypted_key = response['CiphertextBlob']

# Encrypt data locally
fernet_key = base64.urlsafe_b64encode(plaintext_key)
cipher = Fernet(fernet_key)
encrypted_data = cipher.encrypt(b"sensitive data")

# Store encrypted_key + encrypted_data
# Discard plaintext_key from memory
del plaintext_key, fernet_key
```

---

## 6. Secret Scanning

### Tool Comparison

| Tool | Type | Detection Method | Pre-commit | CI/CD | Pricing |
|------|------|-----------------|------------|-------|---------|
| **GitHub Secret Scanning** | Platform-native | Pattern matching + partner alerts | Push protection | Automatic | Free (public repos), GHAS (private) |
| **GitLeaks** | CLI | Regex + entropy | Yes (pre-commit hook) | Yes | Free (open source) |
| **TruffleHog** | CLI | Regex + entropy + verification | Yes | Yes | Free OSS + paid Enterprise |
| **detect-secrets** | CLI (Yelp) | Regex + entropy + plugins | Yes (pre-commit hook) | Yes | Free (open source) |
| **Semgrep Secrets** | Platform | Pattern + Semgrep rules | Yes | Yes | Free Community + paid |

**GitGuardian State of Secrets Sprawl 2026**: 28.65M new hardcoded secrets on public GitHub in 2025 (+34% YoY). 1.275M leaked secrets tied to AI services (+81%). 64% of valid secrets from 2022 still not revoked in 2026. Secrets leak 1.6x faster than developer population growth.

### GitHub Secret Scanning

GitHub's built-in secret scanning:
- **Push protection**: Blocks commits containing detected secrets before they reach the repository
- **Partner program**: 200+ service providers (AWS, Azure, GCP, Stripe, Twilio, etc.) are notified when their credentials are detected
- **Custom patterns**: Define org-specific secret patterns (regex)
- **Validity checking**: Verifies if detected secrets are still active (for partner patterns)
- **Non-provider patterns**: Detects generic high-entropy strings, private keys, database connection strings

### GitLeaks Configuration

```toml
# .gitleaks.toml
title = "Gitleaks config"

[allowlist]
  paths = [
    '''\.gitleaks\.toml$''',
    '''test/fixtures/.*''',
    '''vendor/.*''',
  ]

[[rules]]
  id = "custom-api-key"
  description = "Custom internal API key format"
  regex = '''MYAPP_[A-Z0-9]{32}'''
  secretGroup = 0
  entropy = 3.5
  tags = ["api", "internal"]

[[rules]]
  id = "private-key"
  description = "Private key file content"
  regex = '''-----BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY-----'''
  tags = ["key", "private"]
```

### Secret Remediation Process

```
Secret detected in code:
│
├── 1. IMMEDIATE: Rotate the secret
│      The secret is compromised the moment it touches git
│      (even if the commit is reverted — it's in git history)
│
├── 2. Revoke old credentials
│      Disable the leaked key/token/password at the provider
│
├── 3. Audit access logs
│      Check if the secret was used by unauthorized parties
│
├── 4. Remove from git history (if needed)
│      git filter-repo or BFG Repo-Cleaner
│      (but assume it was already scraped)
│
├── 5. Add secret to scanning baseline
│      So it's detected in future commits
│
└── 6. Root cause analysis
       Why did it end up in code? Fix the process:
       - Enable pre-commit hooks
       - Enable push protection
       - Improve developer training
       - Provide better secret injection mechanisms
```

---

## 7. Secret Rotation Strategies

### Zero-Downtime Rotation Patterns

**Dual-read pattern** (most common):
```
Phase 1: Old secret active, new secret created
  → Application reads BOTH old and new secrets
  → New secret is set on the target service (e.g., database password)

Phase 2: Cutover
  → Application switches to new secret
  → Verify all connections use new secret

Phase 3: Cleanup
  → Old secret is revoked/deleted
  → Monitoring confirms no failures

Key: There's always a window where both secrets are valid
```

**Blue-green pattern** for database credentials:
```
1. Database has two users: app_blue (current) and app_green (standby)
2. Rotate app_green's password
3. Update application config to use app_green
4. Verify all connections healthy
5. Disable app_blue user
6. On next rotation: reverse (rotate app_blue, switch to it)
```

### Rotation Frequencies by Secret Type

| Secret Type | Recommended Rotation | Automation |
|------------|---------------------|------------|
| **Database passwords** | 30-90 days | Vault dynamic secrets (per-request), AWS Secrets Manager auto-rotation |
| **API keys (third-party)** | 90 days | Provider-specific rotation APIs |
| **Service account keys** | Avoid — use OIDC federation | N/A (eliminate, don't rotate) |
| **TLS certificates** | 90 days (Let's Encrypt default) | cert-manager auto-renewal |
| **Internal CA certs** | 1-5 years (CA), 24h-90 days (leaf) | Vault PKI, step-ca |
| **Encryption keys** | 1 year (enable auto-rotation in KMS) | Cloud KMS auto-rotation |
| **SSH keys** | 90 days, or use certificates | Vault SSH signed keys (per-session) |
| **Personal access tokens** | 90 days max, prefer short-lived | Require expiration on creation |

---

## 8. Kubernetes Secrets Patterns

### Tool Comparison

| Tool | Approach | Secret Source | GitOps Compatible | Encryption |
|------|----------|-------------|-------------------|------------|
| **External Secrets Operator** | Sync external secrets to K8s Secrets | Vault, AWS SM, Azure KV, GCP SM, more | Yes | External store encryption |
| **Sealed Secrets** | Encrypt secrets for storage in Git | Cluster-specific encryption | Yes (designed for it) | Asymmetric (cluster public key) |
| **Vault CSI Provider** | Mount Vault secrets as files in pods | HashiCorp Vault | Partial | Vault encryption |
| **Vault Agent Injector** | Sidecar injects secrets into pods | HashiCorp Vault | Yes | Vault encryption |
| **SOPS** | Encrypt files with cloud KMS | Git (encrypted YAML/JSON) | Yes (Flux/ArgoCD native) | Cloud KMS, PGP, age |

### External Secrets Operator Example

```yaml
# SecretStore (cluster-wide or namespace-scoped)
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets

---
# ExternalSecret (sync AWS secret to K8s Secret)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets
    kind: ClusterSecretStore
  target:
    name: db-credentials          # K8s Secret name
    creationPolicy: Owner
  data:
    - secretKey: username         # Key in K8s Secret
      remoteRef:
        key: production/database  # AWS Secrets Manager path
        property: username        # JSON property
    - secretKey: password
      remoteRef:
        key: production/database
        property: password
```

### SOPS with ArgoCD/Flux

```yaml
# Encrypt a secret with SOPS + AWS KMS
# sops --encrypt --kms arn:aws:kms:us-east-1:123:key/abc secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: my-secret
data:
  password: ENC[AES256_GCM,data:xyz123...,tag:abc...,type:str]
sops:
  kms:
    - arn: arn:aws:kms:us-east-1:123:key/abc
      created_at: "2026-01-15T10:30:00Z"
      enc: AQIDAHh...
  version: 3.9.0
  # Flux and ArgoCD have native SOPS decryption support
```

---

## 9. OIDC Federation for Secretless Pipelines

### The Shift: From Secrets to Identity

```
Old pattern (long-lived secrets):
  CI/CD → Static AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY → AWS
  Problem: Keys can be stolen, rarely rotated, over-privileged

New pattern (OIDC federation):
  CI/CD → Short-lived OIDC token → Cloud IAM Role → Temporary credentials
  Benefits: No secrets to steal, auto-expires, scoped to workflow
```

### Multi-Cloud OIDC Setup

**GitHub Actions → AWS:**
```json
// AWS IAM trust policy for GitHub OIDC
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::123456789:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:ref:refs/heads/main"
      }
    }
  }]
}
```

**GitHub Actions → GCP:**
```bash
# Create workload identity pool
gcloud iam workload-identity-pools create "github" \
  --location="global" \
  --display-name="GitHub Actions"

# Create provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository == 'my-org/my-repo'"

# Grant SA access
gcloud iam service-accounts add-iam-policy-binding deploy@project.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/github/attribute.repository/my-org/my-repo"
```

### Platforms Supporting OIDC Federation

| CI/CD Platform | OIDC Support | AWS | GCP | Azure |
|---------------|-------------|-----|-----|-------|
| **GitHub Actions** | GA | Yes | Yes | Yes |
| **GitLab CI** | GA | Yes | Yes | Yes |
| **CircleCI** | GA | Yes | Yes | Yes |
| **Bitbucket Pipelines** | GA | Yes | Yes | Yes |
| **Jenkins** | Plugin | Yes | Yes | Yes |
| **GCP Cloud Build** | Native | Yes | Native | Yes |
| **AWS CodeBuild** | Native | Native | Yes | Yes |

---

## 10. Environment Variable Hygiene

### The .env Problem

```
Risks of .env files:
1. Accidentally committed to git (most common secret leak)
2. Shared via Slack, email, or documentation
3. Different values across developer machines (drift)
4. No audit trail for who changed what
5. No encryption at rest
6. No access control (anyone who can read the file has all secrets)
```

### Solutions

| Tool | Approach | Encryption | Team Sync | Git-Safe |
|------|----------|-----------|-----------|----------|
| **dotenvx** | Encrypted .env files | AES-256-GCM | Yes (shared key) | Yes (encrypted) |
| **SOPS** | Encrypt any YAML/JSON/env file | Cloud KMS, age, PGP | Yes (KMS-based) | Yes (encrypted) |
| **direnv** | Directory-specific env vars | No (plaintext .envrc) | No | No |
| **1Password CLI** | Inject from 1Password vault | 1Password encryption | Yes (shared vaults) | Yes (references, not values) |
| **Doppler** | Centralized secret management | Doppler encryption | Yes (team sync) | Yes (never stored locally) |
| **Infisical** | Open-source secret management | AES-256-GCM | Yes (team sync) | Yes (never stored locally) |

### Best Practices

```
1. NEVER commit .env files to git
   → Add .env* to .gitignore (keep .env.example with placeholder values)

2. Use different secrets per environment
   → production ≠ staging ≠ development

3. Prefer injected secrets over files
   → Cloud secrets manager → application at runtime
   → Not: developer copies .env file to server

4. Use a .env.example file
   → Document required variables with placeholder values
   → New developers know what they need without seeing real secrets

5. For local development, use a secret manager
   → 1Password CLI, Doppler, or Infisical
   → Developers authenticate, secrets are injected, never on disk
```

---

## 11. Confidential Computing

### Technologies

| Technology | Provider | Protection | Status |
|-----------|----------|-----------|--------|
| **AWS Nitro Enclaves** | AWS | Isolated compute environment, no persistent storage, no admin access | GA |
| **AMD SEV-SNP** | AMD (AWS, Azure, GCP) | Memory encryption per VM, hardware attestation | GA on all major clouds |
| **Intel TDX** | Intel (Azure, GCP) | VM-level isolation with hardware attestation | GA on Azure, GCP |
| **Azure Confidential VMs** | Azure | SEV-SNP or TDX, confidential OS disk encryption | GA |
| **GCP Confidential VMs** | GCP | SEV-SNP or TDX, attestation verification | GA |
| **Apple Private Cloud Compute** | Apple | Custom silicon, no persistent storage, code transparency | GA (Apple Intelligence) |
| **ARM CCA (Confidential Compute Architecture)** | ARM | Realm-based isolation for ARMv9 | Preview |

### When to Use Confidential Computing

```
Use confidential computing when:
├── Processing data you don't fully trust the cloud provider to see
│   (regulated industries: healthcare, finance, government)
├── Multi-party computation where parties don't trust each other
├── Running AI/ML on sensitive data
├── Key management (processing encryption keys)
└── Compliance requires it (certain government/defense contracts)

Don't use when:
├── Standard cloud security is sufficient (most applications)
├── Performance overhead is unacceptable (5-15% compute overhead)
└── You trust your cloud provider's existing security controls
```

---

## 12. Secret Management Selection Framework

### Decision Tree

```
What are you managing?
│
├── Application secrets (DB passwords, API keys, config)
│   ├── Cloud-native, single cloud → Cloud Secrets Manager (AWS SM, Azure KV, GCP SM)
│   ├── Multi-cloud or complex needs → HashiCorp Vault or OpenBao
│   ├── Kubernetes-native → External Secrets Operator + cloud store
│   └── Startup / simple needs → Cloud Secrets Manager + Doppler/Infisical
│
├── Encryption keys
│   ├── Cloud services encryption → Cloud KMS (no question)
│   ├── Application-level encryption → Cloud KMS envelope encryption or Vault Transit
│   ├── HSM required (compliance) → Cloud HSM (CloudHSM, Managed HSM) or on-prem HSM
│   └── BYOK / external keys → Cloud KMS External Key Store
│
├── TLS certificates
│   ├── Public-facing → Let's Encrypt + cert-manager
│   ├── Internal services → Vault PKI or step-ca + cert-manager
│   ├── Cloud-managed → AWS ACM, Azure App Service certs, GCP managed certs
│   └── Code signing → Cloud CA or dedicated signing service
│
├── CI/CD credentials
│   ├── Cloud access → OIDC federation (eliminate secrets entirely)
│   ├── Third-party services → CI/CD secrets store (Actions secrets, GitLab CI variables)
│   └── Dynamic environments → Vault dynamic secrets
│
└── Developer local secrets
    ├── Team sync needed → Doppler, Infisical, or 1Password CLI
    ├── Encrypted .env → dotenvx or SOPS
    └── Simple → .env + .gitignore + secret scanning pre-commit hook
```

### Maturity Progression

| Level | What to Deploy | Effort |
|-------|---------------|--------|
| **L1 — Basic** | .gitignore for .env, secret scanning (GitLeaks/GitHub), cloud secrets for production | 1-2 days |
| **L2 — Structured** | Centralized cloud secrets manager, OIDC for CI/CD, cert-manager for TLS | 1-2 weeks |
| **L3 — Automated** | Auto-rotation for databases, External Secrets Operator, secret scanning in CI | 2-4 weeks |
| **L4 — Mature** | Vault/OpenBao for dynamic secrets, PKI for mTLS, JIT access to secrets | 1-3 months |
| **L5 — Advanced** | Zero-standing secrets, confidential computing, HSM-backed keys, full audit | 3-6 months |
