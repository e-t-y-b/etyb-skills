# AWS Cloud Engineering — Pointer

As of v4.0.0 (2026-05-14), all AWS-specific guidance — products, services, decision frameworks, 2025-2026 platform shifts, IAM patterns, IaC discipline, observability wiring, AI/ML infrastructure — lives in the **AWS Stack Pack** at [`stacks/aws/SKILL.md`](../../../../../../stacks/aws/SKILL.md). The Stack carries currency timestamps, authoritative-source URLs, per-product drift-risk ratings, and per-role overlays for every specialist that touches AWS work.

## Where that content lives now

| Topic | New location |
|-------|--------------|
| Compute selection (Graviton, Trainium, EKS Auto Mode, ECS Express, Karpenter v1) | `stacks/aws/references/system-architect.md`, `stacks/aws/references/devops-engineer.md` |
| Networking, VPC, Transit Gateway, CloudFront | `stacks/aws/references/system-architect.md`, `stacks/aws/references/security-engineer.md` |
| Storage, S3 Tables, EBS, FSx | `stacks/aws/references/database-architect.md` |
| Databases — Aurora (incl. DSQL), DynamoDB, ElastiCache/Valkey | `stacks/aws/references/database-architect.md` |
| Security & IAM (SCPs, permission boundaries, Security Hub overhaul, EKS Pod Identity) | `stacks/aws/references/security-engineer.md` |
| Serverless — Lambda + SnapStart, Step Functions, EventBridge | `stacks/aws/references/backend-architect.md` |
| IaC — CDK v2, SAM, multi-account pipeline shape | `stacks/aws/references/devops-engineer.md` |
| Observability — Application Signals, OTel preview, FIS chaos | `stacks/aws/references/sre-engineer.md` |
| AI/ML — Bedrock, AgentCore (Runtime/Browser/Memory), Strands Agents SDK, SageMaker | `stacks/aws/references/ai-ml-engineer.md` |
| Multi-account strategy + SaaS account-vending | `stacks/aws/references/system-architect.md`, `stacks/aws/references/saas-architect.md` |
| Fintech-specific Aurora DSQL + ledger separation | `stacks/aws/references/fintech-architect.md` |

## Why the move

Vendor knowledge drifts. AWS ships service changes weekly. v4.0.0 introduced the **knowledge-currency framework** (see `skills/etyb/core/knowledge-currency.md`) so that vendor specifics carry a `last_verified_on` timestamp, link to authoritative-source URLs for verification, declare vendor MCPs/skills to defer to when installed, and have per-product `drift_risk` ratings. Burying AWS content in this DevOps specialist file made all of that invisible — the Stack Pack model surfaces it.

ETYB's router (`skills/etyb/core/stack-registry.md`) detects AWS signals in the user's request and loads the Stack overlay alongside the engaged specialist. The DevOps Engineer specialist still owns *platform-neutral* DevOps patterns (CI/CD philosophy, GitOps discipline, release-engineering practices, IaC fundamentals); the AWS Stack adds the platform-specific layer.
