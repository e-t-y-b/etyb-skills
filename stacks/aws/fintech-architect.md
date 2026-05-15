---
title: Fintech Architect on AWS
description: Thin AWS overlay — PCI DSS scope reduction via tokenization + CDE isolation, Aurora DSQL for ledger-adjacent (not ledger itself), AWS Payment Cryptography for HSM crypto, audit trail discipline.
role_overlay:
  role: fintech-architect
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [aurora, kms, cloudtrail, iam, bedrock, secrets-manager]
---

## Role briefing — fintech-architect on AWS

**This is a thin overlay.** Fintech compliance (PCI DSS scope, PSD2 SCA, AML, ledger semantics, double-entry accounting, reconciliation discipline) lives in the fintech-architect specialist. This overlay covers only the **AWS-specific** patterns that apply when you're building fintech workloads on AWS.

If you're asking "how do I build a ledger?" — that's the fintech-architect specialist. If you're asking "how do I run my ledger on AWS without PCI scope leaking everywhere?" — that's this overlay.

## Core stance: AWS is not your ledger

**AWS is the infrastructure. AWS is not the ledger of record.** No AWS service is a financial ledger out of the box.

- DynamoDB is a key-value store, not a ledger.
- [Aurora DSQL](/stacks/aws/aurora/) is a Postgres database, not a ledger.
- **QLDB was the closest AWS service to "managed ledger" — it's in maintenance mode** as of 2024-2025; AWS steers customers to Aurora Postgres + application-level append-only patterns for new builds.

If the request is "build us a ledger on DynamoDB" — the answer is "you build a ledger on top of DynamoDB; DynamoDB doesn't make it a ledger." The ledger design (double-entry, immutability, audit trail, balance reconciliation, transaction lineage) is application-level and lives in fintech-architect's specialist.

The AWS contribution: durable storage, encryption, audit logging ([CloudTrail](/stacks/aws/cloudtrail/)), regional/cross-region replication, compute. The ledger contribution from your application: account model, transaction model, posting rules, idempotency keys, balance materializations, reconciliation jobs.

## Decision frameworks specific to this role's lens on AWS

### Storage for fintech workloads

| Need | AWS shape |
|---|---|
| **Source-of-truth ledger** | [Aurora Postgres / Aurora DSQL](/stacks/aws/aurora/) with application-level append-only + hash chains |
| **Append-only event log** | Kinesis Data Streams + S3 (Iceberg via [S3 Tables](/stacks/aws/s3/)) for archival |
| **Idempotency store** | [DynamoDB](/stacks/aws/dynamodb/) with PK = idempotency key, TTL |
| **Balance materialized view** | Aurora read replica or DynamoDB (denormalized) |
| **Reconciliation results** | S3 + Athena for historical; Aurora for queryable |
| **Audit trail** | CloudTrail for AWS API audit; application-level audit in append-only Aurora table |

### Aurora DSQL for ledger-adjacent — not for the ledger itself

DSQL's multi-region active-active is useful when:
- Customer-balance reads must work from any region (low-latency UX).
- Customer-account writes can happen in any region (multi-region active customers).

But the **canonical ledger entry** should be processed at a single region (or a tightly coordinated single-writer pattern) — multi-region active-active makes "definitive ordering" harder. Use DSQL for derived state (balances), not source-of-truth ledger.

```
[Authoritative ledger writes]
   - Single region (or single writer with synchronous secondary)
   - Aurora Postgres with strict serializable isolation
   - Append-only with idempotency keys
       |
       v
[CDC → DSQL multi-region cluster]
   - Eventually-consistent balance views
   - Read from any region
   - Application aware DSQL view may lag the ledger by milliseconds
```

## Product references

### PCI DSS scope reduction on AWS

**PCI DSS scope is the budget.** Less scope = less cost, less audit, less risk.

**Tokenization** — replace card numbers with tokens at the earliest possible point. The token is meaningless outside the gateway's vault; your systems only ever see tokens.
- **Stripe / Adyen / Braintree** — hosted card capture; you never touch the PAN.
- **AWS Payment Cryptography** — managed HSM-backed crypto operations for payment processors (DUKPT, PIN block translation, EMV).
- **Custom tokenization with [KMS](/stacks/aws/kms/) + DynamoDB** — for in-house tokenization, store PAN encrypted with KMS in a strictly-scoped DynamoDB table within the CDE account.

**Anti-pattern**: PAN in S3 buckets or DynamoDB tables outside the CDE account. Even encrypted, the storage is in scope.

**Account-level isolation (CDE)** — separate AWS account in a dedicated OU. Strict SCPs: no internet egress, no public S3, no VPC peering to non-CDE. Only PCI-eligible AWS services. All access logged via CloudTrail; daily review. Annual ASV scan + quarterly internal scans + annual pen test.

**Network segmentation** — no connectivity between CDE VPCs and non-CDE VPCs except through tightly controlled, audited bridges (e.g., a PrivateLink endpoint exposing a token-validation API). No outbound internet from CDE; only VPC endpoints to PCI-eligible AWS services.

**KMS for PCI** — customer-managed CMK with HSM-backed material (CloudHSM-key-backed for highest assurance). Key policy allows only the CDE account's principals. Annual rotation. KMS grant audit via CloudTrail.

### Idempotency on financial APIs

```python
from aws_lambda_powertools.utilities.idempotency import (
    IdempotencyConfig, idempotent, DynamoDBPersistenceLayer,
)

persistence = DynamoDBPersistenceLayer(
    table_name='LedgerIdempotency',
    key_attr='idempotency_key',
    expiry_attr='ttl',
    in_progress_expiry_attr='in_progress_ttl',
    status_attr='status',
    data_attr='response_data',
)

config = IdempotencyConfig(
    event_key_jmespath='headers."Idempotency-Key"',
    expires_after_seconds=86400,  # 24h client retry window
    use_local_cache=False,  # Distributed-only for ledger ops
)

@idempotent(persistence_store=persistence, config=config)
def transfer_funds(event, context):
    # Process transfer — guaranteed once-per-idempotency-key
    ...
```

**Requirements**:
- Idempotency key from the client (`Idempotency-Key` HTTP header) — never derived from event content alone.
- Persisted in DynamoDB with TTL exceeding client retry window (24h+).
- Block in-flight duplicates (in_progress lock with TTL).
- Return identical response on retry.

### Audit trail

- **[CloudTrail](/stacks/aws/cloudtrail/)** for AWS API calls (control plane).
- **Application audit log** in a separate append-only table, never deleted, retained per regulatory requirement (typically 7+ years).
- **S3 with Object Lock** for archival audit logs — write-once-read-many.

### Reconciliation

Continuous reconciliation between source-of-truth ledger and:
- Customer balance materialized views.
- External system records (payment processor, bank statement).
- Internal subsystems (rewards, refund records).

Daily reconciliation jobs (Step Functions + Lambda + Athena) compare expected vs actual; alert on discrepancies; correct via compensating entries (never silent fix).

### Multi-region for fintech

Three different purposes:
1. **High availability** within a customer geography — Aurora DSQL active-active within a regulatory zone.
2. **Disaster recovery** — primary in eu-west-1, DR in eu-central-1; documented RTO/RPO; tested quarterly.
3. **Data residency** — EU customer data only in EU regions; tenant routing enforces.

**Don't confuse them.** Multi-region active-active does not give you data residency (without per-tenant region pinning); data residency does not require multi-region active-active.

### Real-time fraud detection

Kinesis Data Streams as event bus → KCL consumer or Lambda + Kinesis Analytics for in-flight enrichment → [Bedrock](/stacks/aws/bedrock/) (or SageMaker) for scoring → Step Functions for fraud workflow (suspect → review → approve/reject/escalate) → DynamoDB for fraud-flag state.

## 2025-2026 platform-reset items relevant to this role

- **QLDB in maintenance mode.** Don't propose for new builds.
- **Aurora DSQL** (GA 2025) — multi-region active-active for ledger-adjacent (not ledger itself).
- **AWS Verified Permissions** (Cedar) — formal policy decisions for fine-grained auth on financial operations.
- **AWS Audit Manager** has SOC 2, PCI DSS, ISO 27001 frameworks built in.
- **AWS Payment Cryptography** — managed HSM-backed crypto for payment processing.
- **AWS Clean Rooms** — data collaboration without data sharing. Useful for partnered analytics.

## Compliance specifics on AWS

- **PCI DSS Level 1** — AWS certified; customer responsibility: CDE isolation, tokenization, encryption, scans, pen test, annual SAQ/ROC.
- **PSD2 SCA (EU)** — MFA via Cognito + WebAuthn / passkeys + risk-based auth. Transaction-specific authentication. Application-level SCA logic.
- **AML / KYC** — vendor integrations (Onfido, Persona, Jumio); sanctions screening (LexisNexis, Refinitiv) via Lambda + API call; transaction monitoring; SAR workflow via Step Functions + S3 Object Lock.
- **SOX** — change management, separation of duties, evidence collection via Audit Manager. Strict CI/CD: developer can't deploy, deployer can't write code.
- **Open Banking (PSD2 + UK Open Banking)** — OAuth 2.0 + FAPI profile. Strong consent management. API Gateway + Cognito + Lambda + Verified Permissions.

## Patterns the role applies

- **Tokenize early** — PAN never leaves the payment gateway / vault.
- **CDE in a separate account** with locked-down SCPs.
- **Aurora Postgres / DSQL for ledger storage** with application-level append-only + idempotency.
- **DynamoDB idempotency table** with TTL exceeding retry windows.
- **Step Functions for compensating transactions.**
- **Daily reconciliation jobs.**
- **S3 with Object Lock** for audit log archival.
- **HSM-backed KMS keys** for CDE encryption.
- **Bedrock for fraud + risk scoring** — with guardrails + audit.

## When to escalate to the fintech-architect specialist

This overlay is intentionally thin. Escalate for:
- **Ledger design**: double-entry accounting, account models, posting rules, transaction lineage.
- **PCI scope assessment**: where exactly your CDE boundaries are.
- **PSD2 SCA flow**: which transactions need MFA, exemptions, dispute handling.
- **AML / KYC vendor selection** and workflow design.
- **Open Banking API contract** (FAPI profile, consent management).
- **Treasury / settlement / clearing** patterns.
- **Reconciliation algorithm design** beyond "count rows."
- **Real-time fraud-scoring model selection** and feature engineering.
- **Cross-border payment** routing, FX, compliance.

The AWS overlay covers AWS-specific implementation; the specialist covers domain semantics.

## Anti-patterns

- **QLDB for new ledger workloads** — maintenance mode.
- **Storing PAN in non-CDE accounts** — even encrypted, it's in scope.
- **No idempotency on financial APIs** — duplicate charges incoming.
- **No reconciliation** — drift goes undetected.
- **"AWS encryption is enough, no app-level encryption needed"** — for fintech, app-level encryption on top of KMS is often required.
- **One AWS account for everything** — CDE must be isolated.
- **Long-lived access keys** — financial services demand short-lived, federation-based.
- **Multi-region active-active for the ledger itself** — definitive ordering breaks under multi-master writes; use single-writer for source-of-truth.
- **"It's PCI compliant because it's on AWS"** — AWS is PCI-certified infra; compliance of the application is still your job.

## Patterns the role applies (verification, debugging, TDD)

### TDD on fintech

- **Idempotency tests** — send same idempotency key twice; assert identical response, no duplicate side effects.
- **Reconciliation tests** — simulate drift; assert reconciliation detects + alarms.
- **Audit-trail tests** — every financial operation writes an audit entry; assert.
- **Authorization tests** — per Cedar policy, assert access decisions for representative principals.

### Verification on fintech AWS

Claims must cite:
- "AWS is PCI DSS Level 1 certified" → AWS Compliance docs.
- "Aurora DSQL provides 99.999% multi-region availability" → DSQL service-level docs.
- "Cognito supports MFA via WebAuthn / passkeys" → Cognito docs.

### Debugging financial issues

1. **Reproduce in a sandbox / non-production environment with synthetic data.** Never debug financial issues by writing to production with real customer money.
2. **The audit trail is the source of truth** for "what happened." Reconstruct from append-only logs, not from current state of derived views.
3. **One variable at a time** during remediation.
4. **Three-failure escalation** — escalate to compliance + engineering leadership before a fourth attempt.

### Branch safety on fintech

- **All financial-flow code changes require two reviewers**, including at least one with financial systems experience.
- **Deploy windows** for financial systems often have business constraints.
- **Rollback plan documented** before deploy, not after.
- **Idempotency + audit trail are PR review checkpoints.**

## Cross-references

- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — CloudTrail + Audit Manager, HSM-backed KMS
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — Aurora / DSQL ledger storage design
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — Bedrock for fraud scoring
- [`/stacks/aws/`](/stacks/aws/) — Stack index
