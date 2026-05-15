---
title: Secrets Manager
description: AWS managed secret storage with rotation — managed rotation for RDS/Aurora/Redshift/DocumentDB; custom rotation Lambda for non-AWS secrets; KMS-encrypted always.
product:
  name: Secrets Manager
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, devops-engineer]
  authoritative_url: https://docs.aws.amazon.com/secretsmanager/
  notes: "Mature; managed rotation for RDS/Aurora/Redshift/DocumentDB; single-user vs multi-user rotation patterns stable."
---

## What it is

AWS Secrets Manager is the managed secret storage service — rotation-aware, KMS-encrypted, IAM-controlled, with first-class support for database credentials and custom rotation Lambdas for third-party secrets.

Canonical surface: [docs.aws.amazon.com/secretsmanager](https://docs.aws.amazon.com/secretsmanager/).

## When to use

| Need | Use Secrets Manager? |
|---|---|
| Rotated secrets (DB passwords, API keys) | Yes — managed rotation for AWS DBs; custom Lambda for others |
| Non-rotated config (feature flags, hostnames) | No — use SSM Parameter Store (Standard tier is free up to 10K params) |
| Application secrets without rotation needed | Parameter Store SecureString is cheaper |
| Third-party API keys with no rotation | Either — Secrets Manager if you want rotation later; Parameter Store if not |

Cost: Secrets Manager is $0.40/secret/month + API calls. Parameter Store Standard is free up to 10K params; Advanced (larger params, policies) is $0.05/param/month.

## 2025-2026 currency anchors

- **Managed rotation** for RDS, Aurora, Redshift, DocumentDB (single-user and multi-user patterns).
- **Multi-user rotation** zero-downtime — two app users alternate.
- **Custom rotation Lambda** for non-AWS secrets — vendor key rotation API integration.
- **AWS Parameters and Secrets Lambda Extension** caches secrets via a local HTTP endpoint — avoids per-invocation API calls for high-RPS Lambda.

## Patterns

### Database credentials with managed rotation

```typescript
const dbSecret = new secretsmanager.Secret(this, 'DbSecret', {
  secretName: 'rds/app/credentials',
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ username: 'admin' }),
    generateStringKey: 'password',
    excludePunctuation: true,
    passwordLength: 32,
  },
  encryptionKey: appKey,
});

dbSecret.addRotationSchedule('Rotation', {
  hostedRotation: secretsmanager.HostedRotation.postgreSqlSingleUser(),
  automaticallyAfter: Duration.days(30),
});
```

Rotation modes:
- **Single-user rotation**: app must reconnect during rotation window. Brief downtime.
- **Multi-user rotation**: two app users alternate; zero-downtime rotation.

### Fetching at runtime (Powertools)

```python
from aws_lambda_powertools.utilities.parameters import get_secret

# Cached for 5 minutes by default
db_creds = get_secret('rds/app/credentials', transform='json', max_age=300)
```

### Lambda Extension for hot paths

For high-RPS Lambda, the **AWS Parameters and Secrets Lambda Extension** caches via a local HTTP endpoint — avoids per-invocation API calls.

```python
import os, requests

def get_secret_via_extension(name):
    port = os.environ.get('PARAMETERS_SECRETS_EXTENSION_HTTP_PORT', '2773')
    headers = {'X-Aws-Parameters-Secrets-Token': os.environ['AWS_SESSION_TOKEN']}
    r = requests.get(f'http://localhost:{port}/secretsmanager/get?secretId={name}', headers=headers)
    return r.json()['SecretString']
```

### Custom rotation Lambda

For non-AWS secrets (third-party API keys), write a custom rotation Lambda:
1. `createSecret` — generate new credential version, stage as `AWSPENDING`.
2. `setSecret` — call vendor's API to rotate at the vendor side.
3. `testSecret` — verify new credential works.
4. `finishSecret` — promote `AWSPENDING` to `AWSCURRENT`.

### Cross-account secret access

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "AWS": "arn:aws:iam::OTHER_ACCOUNT:role/ConsumerRole" },
    "Action": "secretsmanager:GetSecretValue",
    "Resource": "*",
    "Condition": {
      "StringEquals": { "aws:SourceVpce": "vpce-xxxxx" }
    }
  }]
}
```

Resource-based policy on the secret + KMS key policy allowing the consumer account = cross-account secret access.

## Anti-patterns

- **Secrets in environment variables in source code or repo.** Never.
- **Plaintext secrets in Lambda env vars (unencrypted).** Use Secrets Manager + retrieve at runtime.
- **Hard-coded DB credentials.** Always Secrets Manager with rotation.
- **Calling Secrets Manager every Lambda invocation.** Use Powertools caching or the Lambda Extension.
- **No rotation on production secrets.** Even if vendor doesn't support automated rotation, schedule manual rotation.
- **Pre-commit secret detection skipped.** Use `detect-secrets`, `gitleaks`, or `trufflehog`.
- **Single-user rotation on critical writeable services.** Use multi-user for zero-downtime.

## Gotchas

- **Recovery window** for deleted secrets is 7-30 days. Default 30. Schedule, don't immediate.
- **Secrets cost $0.40/mo each.** For thousands of secrets, evaluate Parameter Store SecureString.
- **API call cost** — $0.05 per 10K API calls. High-RPS workloads need the Lambda Extension or caching.
- **JSON parsing** — secret values stored as strings; structured secrets need JSON parse at consumer.
- **Region-scoped** — replicate manually for multi-region.
- **Cross-account requires both resource policy on secret AND KMS key policy access.**

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — runtime secret fetch + caching
- [`/stacks/aws/rds/`](/stacks/aws/rds/) — managed rotation target
- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — managed rotation target
- [`/stacks/aws/kms/`](/stacks/aws/kms/) — encryption key for secrets
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — access control
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; rotation discipline
- [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) — alternative for non-rotated config
