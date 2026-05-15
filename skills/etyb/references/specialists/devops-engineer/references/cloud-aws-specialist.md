# AWS Cloud Engineering — Pointer

As of v4.0.0 (2026-05-14), all AWS-specific guidance — products, services, decision frameworks, 2025-2026 platform shifts, IAM patterns, IaC discipline, observability wiring, AI/ML infrastructure — lives across two layers: the slim local detection pointer at [`stacks/aws/SKILL.md`](../../../../../../stacks/aws/SKILL.md) (currency stamps, `delegate_to_skills`, products covered, top gotchas) and the canonical per-product + per-role pages at **<https://docs.etyb.ai/stacks/aws/>**, fetched at runtime per the contract in `skills/etyb/core/knowledge-currency.md`.

## Where that content lives now

| Topic | Canonical location on docs.etyb.ai |
|-------|------------------------------------|
| Compute selection (Graviton, Trainium, EKS Auto Mode, ECS Express, Karpenter v1) | <https://docs.etyb.ai/stacks/aws/system-architect/>, <https://docs.etyb.ai/stacks/aws/devops-engineer/> |
| Networking, VPC, Transit Gateway, CloudFront | <https://docs.etyb.ai/stacks/aws/system-architect/>, <https://docs.etyb.ai/stacks/aws/security-engineer/> |
| Storage, S3 Tables, EBS, FSx | <https://docs.etyb.ai/stacks/aws/database-architect/> |
| Databases — Aurora (incl. DSQL), DynamoDB, ElastiCache/Valkey | <https://docs.etyb.ai/stacks/aws/database-architect/> |
| Security & IAM (SCPs, permission boundaries, Security Hub overhaul, EKS Pod Identity) | <https://docs.etyb.ai/stacks/aws/security-engineer/> |
| Serverless — Lambda + SnapStart, Step Functions, EventBridge | <https://docs.etyb.ai/stacks/aws/backend-architect/> |
| IaC — CDK v2, SAM, multi-account pipeline shape | <https://docs.etyb.ai/stacks/aws/devops-engineer/> |
| Observability — Application Signals, OTel preview, FIS chaos | <https://docs.etyb.ai/stacks/aws/sre-engineer/> |
| AI/ML — Bedrock, AgentCore (Runtime/Browser/Memory), Strands Agents SDK, SageMaker | <https://docs.etyb.ai/stacks/aws/ai-ml-engineer/> |
| Multi-account strategy + SaaS account-vending | <https://docs.etyb.ai/stacks/aws/system-architect/>, <https://docs.etyb.ai/stacks/aws/saas-architect/> |
| Fintech-specific Aurora DSQL + ledger separation | <https://docs.etyb.ai/stacks/aws/fintech-architect/> |

## Why the move

Vendor knowledge drifts. AWS ships service changes weekly. v4.0.0 introduced the **knowledge-currency framework** (see `skills/etyb/core/knowledge-currency.md`) so that vendor specifics carry a `last_verified_on` timestamp, link to authoritative-source URLs for verification, declare vendor MCPs/skills to defer to when installed, and have per-product `drift_risk` ratings. Burying AWS content in this DevOps specialist file made all of that invisible — the Stack Pack model surfaces it.

ETYB's router (`skills/etyb/core/stack-registry.md`) detects AWS signals in the user's request and loads the Stack overlay alongside the engaged specialist. The DevOps Engineer specialist still owns *platform-neutral* DevOps patterns (CI/CD philosophy, GitOps discipline, release-engineering practices, IaC fundamentals); the AWS Stack adds the platform-specific layer.
