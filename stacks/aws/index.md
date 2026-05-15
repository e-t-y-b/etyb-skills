---
title: AWS
description: AWS platform knowledge overlay — Lambda, ECS, EKS, Aurora DSQL, DynamoDB, Bedrock, AgentCore, Strands, CDK v2, IAM, KMS, observability, and multi-account governance. Current to 2026-Q2.
stack:
  vendor: aws
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - system-architect
    - backend-architect
    - database-architect
    - devops-engineer
    - security-engineer
    - sre-engineer
    - ai-ml-engineer
    - saas-architect
    - fintech-architect
  authoritative_sources:
    - { name: "AWS Documentation (canonical)",     url: "https://docs.aws.amazon.com/", type: official_docs }
    - { name: "AWS CLI v2 Command Reference",      url: "https://docs.aws.amazon.com/cli/latest/reference/", type: cli_reference }
    - { name: "AWS What's New (changelog)",        url: "https://aws.amazon.com/about-aws/whats-new/recent/", type: changelog }
    - { name: "AWS News Blog",                     url: "https://aws.amazon.com/blogs/aws/", type: changelog }
    - { name: "AWS Security Bulletins",            url: "https://aws.amazon.com/security/security-bulletins/", type: security_advisories }
    - { name: "AWS Well-Architected Framework",    url: "https://aws.amazon.com/architecture/well-architected/", type: official_docs }
    - { name: "AWS CDK v2 API Reference",          url: "https://docs.aws.amazon.com/cdk/api/v2/", type: api_reference }
    - { name: "Bedrock User Guide",                url: "https://docs.aws.amazon.com/bedrock/latest/userguide/", type: official_docs }
    - { name: "AgentCore Documentation",           url: "https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/", type: official_docs }
    - { name: "AWS Health Dashboard",              url: "https://health.aws.amazon.com/health/status", type: official_docs }
  delegate_to_skills: []
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="note" title="Migration in progress">
This Stack's per-product pages and composed role views are being authored from the etyb-skills v4 overlay. The original `stacks/aws/SKILL.md` in [etyb-skills](https://github.com/e-t-y-b/etyb-skills) carries the team-briefing form of this content; here it is decomposed by product (canonical, deep) and by role (composed lenses that link into products).
</Aside>

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against AWS as of 2026-Q2 — re:Invent 2024 + re:Invent 2025 GA'd, plus "What's New" through April-May 2026.</div>

AWS ships ~3,000 "What's New" items per year. If today's date is more than 6 months past the `last_verified_on` above, treat platform specifics with extra care — bias toward [AWS What's New](https://aws.amazon.com/about-aws/whats-new/recent/) and [AWS News Blog](https://aws.amazon.com/blogs/aws/) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff (or earlier) will get these wrong unless explicitly corrected:

- **Bedrock AgentCore** (Runtime + Browser + Memory) is the production agent layer — GA'd through 2025-2026. Don't propose "raw Bedrock Agents" for new agentic workloads.
- **Strands Agents SDK** open-sourced May 2025 — AWS-blessed agent authoring kit; pairs with AgentCore Runtime.
- **Aurora DSQL** GA May 2025 — Postgres-compatible, serverless, multi-region active-active, 99.999% availability. Express configuration (Mar 2026) lands you a DB in two clicks.
- **EKS Auto Mode** (re:Invent 2024) — managed compute/networking/storage with a single API call.
- **Karpenter v1** GA late 2024 — breaking CRD migration (`v1beta1` → `v1`, `NodePool`/`EC2NodeClass` replacing `Provisioner`/`AWSNodeTemplate`).
- **Lambda SnapStart** added Python 3.12+, .NET 8 AOT, Node.js 22 — no longer Java-only.
- **VPC Lattice** matured into the default L7 service-to-service surface; IPv6 dual-stack + custom domains + Resource Gateway IPs landed in 2025.
- **ECS Express Mode** (Nov 2025) — "container to HTTPS in one step." **AWS Copilot CLI** end-of-support **June 2026**. **App Runner** in maintenance mode.
- **CDK v1 fully EOL.** CDK v2 (`aws-cdk-lib`) is the only supported track. Mixins, ECS built-in Linear/Canary, EKS Hybrid Nodes constructs added 2025-2026.
- **CodeWhisperer renamed to Amazon Q Developer.** **Amazon Q Business** is the enterprise RAG/search tier.
- **Amazon Linux 2 (AL2)** standard support ended June 2025; maintenance support ends June 2026. New AMIs target AL2023.
- **Glacier vault APIs (`glacier:*`)** on retirement track — use S3 Glacier storage classes via the S3 API.
- **Step Functions JSONata + Variables** (re:Invent 2024) replace ResultPath/InputPath chains for new state machines. **TestState API** GA Mar 2026.
- **Security Hub** got a major overhaul at re:Invent 2025 — near-real-time risk analytics, auto-aggregation across GuardDuty/Inspector/Macie/CSPM, one year of historical trends.
- **Aurora Serverless v1** reached EOL Dec 2024 — migrate to Aurora Serverless v2 or DSQL.
- **Graviton4** is the default — ARM-first is now the AWS posture across Lambda, Fargate, RDS, ElastiCache, EC2, MemoryDB. **Graviton5 (M9g)** preview Dec 2025.
- **Trainium2** GA; **Trainium3** preview end 2025 → volume 2026. Majority of Bedrock token usage already on Trainium.
- **CloudWatch Application Signals** matured 2025; **native OTLP metrics ingestion** preview Apr 2026.

If you find yourself recommending CDK v1, Copilot CLI for new deployments, App Runner for new services, Aurora Serverless v1, AWS SDK v2 (JS), AL2 base AMIs, or `glacier:*` archive APIs — your training is stale. Read the per-product pages below.

## Products covered

Per-product pages are canonical — link them from any role view, code review, or architecture doc that mentions the product.

| Product | Drift risk | Why |
|---|---|---|
| [Bedrock](/stacks/aws/bedrock/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Model gateway evolved twice in 2025; Converse API replaces invoke_model; cross-region inference + Provisioned Throughput evolving |
| [AgentCore](/stacks/aws/agentcore/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Runtime/Browser/Memory are 2025-2026 GA; SDK + IAM shape + pricing still shifting |
| [Strands Agents SDK](/stacks/aws/strands-agents/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Open-sourced May 2025; API stabilizing; integration with AgentCore Runtime + Bedrock evolving release-over-release |
| [Aurora](/stacks/aws/aurora/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Aurora DSQL GA May 2025, Express config Mar 2026; Aurora Serverless v1 EOL Dec 2024; Limitless GA |
| [EKS](/stacks/aws/eks/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Auto Mode + Karpenter v1 + Pod Identity + Hybrid Nodes all 2024-2026 additions |
| [Karpenter](/stacks/aws/karpenter/) | <span class="etyb-drift-badge" data-risk="high">high</span> | v1 GA late 2024 with breaking CRD migration; older guides are wrong |
| [Lambda](/stacks/aws/lambda/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | SnapStart for Python/.NET/Node 2024-2025; Powertools idioms; runtime EOL list shifts quarterly |
| [ECS](/stacks/aws/ecs/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Express Mode (Nov 2025) replaces Copilot CLI (EOL June 2026); ECS Service Connect mature |
| [Fargate](/stacks/aws/fargate/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature compute substrate for ECS/EKS; Graviton default; Spot semantics stable |
| [VPC](/stacks/aws/vpc/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | VPC Lattice + Resource Gateway IPs (Oct 2025), IPv6 dual-stack (Aug 2025), custom domains (Nov 2025) keep evolving |
| [API Gateway](/stacks/aws/api-gateway/) | <span class="etyb-drift-badge" data-risk="low">low</span> | HTTP API the default for new builds; REST API for full feature set; mature |
| [Step Functions](/stacks/aws/step-functions/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | JSONata + Variables (re:Invent 2024) replace ResultPath; TestState API GA Mar 2026 |
| [EventBridge](/stacks/aws/eventbridge/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Pipes mature; Scheduler GA; partner event buses expanded |
| [SQS](/stacks/aws/sqs/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature; FIFO high-throughput mode, partial batch failure pattern |
| [S3](/stacks/aws/s3/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | S3 Tables (Iceberg) + Express One Zone conditional writes/deletes are 2024-2026 additions LLMs underweight |
| [DynamoDB](/stacks/aws/dynamodb/) | <span class="etyb-drift-badge" data-risk="low">low</span> | API stable; zero-ETL to OpenSearch/Redshift added 2024-2025; on-demand pricing dropped ~25% in 2025 |
| [RDS](/stacks/aws/rds/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature surface; Blue/Green deployments + Extended Support are the main evolution |
| [ElastiCache](/stacks/aws/elasticache/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Valkey 7.2 is 33% cheaper than Redis OSS — net-new caches: Valkey |
| [OpenSearch](/stacks/aws/opensearch/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Serverless workload types (SEARCH / TIME_SERIES / VECTORSEARCH); vector search matured 2025 |
| [Redshift](/stacks/aws/redshift/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Serverless mature; RA3 + Spectrum stable |
| [CloudFront](/stacks/aws/cloudfront/) | <span class="etyb-drift-badge" data-risk="low">low</span> | IPv6/BYOIP added 2025-2026; mature core surface |
| [Route 53](/stacks/aws/route-53/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature DNS surface; Route 53 Profiles the main new pattern |
| [IAM](/stacks/aws/iam/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Identity Center the only path for humans; Access Analyzer continuous + policy generation; EKS Pod Identity preferred over IRSA |
| [KMS](/stacks/aws/kms/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature; multi-Region keys + XKS evolving for sovereign use cases |
| [Secrets Manager](/stacks/aws/secrets-manager/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature; managed rotation for RDS/Aurora/Redshift/DocumentDB |
| [Cognito](/stacks/aws/cognito/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | User Pools + Identity Pools stable; managed login + passkey support 2024-2025; advanced security pricing changed |
| [Security Hub](/stacks/aws/security-hub/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Re:Invent 2025 overhaul — near-real-time risk analytics, cross-region aggregation, auto-aggregation across detection services |
| [GuardDuty](/stacks/aws/guardduty/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Extended Threat Detection for EC2 + ECS (2025); EKS + Lambda + S3 coverage mature |
| [CloudWatch](/stacks/aws/cloudwatch/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Application Signals matured; native OTLP preview Apr 2026; cross-account observability to 100K accounts |
| [X-Ray](/stacks/aws/x-ray/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Cross-account Trace Map mature; sampling rules well-understood |
| [CloudTrail](/stacks/aws/cloudtrail/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature audit trail surface; CloudTrail Lake SQL queries |
| [SageMaker](/stacks/aws/sagemaker/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Unified Studio launched 2024; HyperPod additions 2025-2026 (NVL72, checkpointless training, dynamic scaling) |
| [Glue](/stacks/aws/glue/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature serverless ETL; Glue Catalog the canonical metastore |
| [CDK](/stacks/aws/cdk/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | v1 fully EOL; mixins + ECS deployment strategies + EKS Hybrid Nodes constructs added 2025-2026 |
| [SAM](/stacks/aws/sam/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature CloudFormation transform for serverless; CDK integration preview 2025 |
| [CloudFormation](/stacks/aws/cloudformation/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; mostly used via CDK; StackSets + Organizations integration |
| [EC2](/stacks/aws/ec2/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Foundational; Graviton4 default, gp3 default; mature surface |
| [Karpenter](/stacks/aws/karpenter/) | <span class="etyb-drift-badge" data-risk="high">high</span> | v1 GA late 2024 with breaking CRD migration |

## Role overlays

Composed views — each stitches together the products that role touches into a single lens. Read the role you're working as, then follow links into product pages.

- [`/stacks/aws/system-architect/`](/stacks/aws/system-architect/) — pick the right compute primitive, multi-region tier, account topology, when AWS isn't the answer
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — Lambda idioms, API Gateway choices, Step Functions JSONata, EventBridge Pipes, SDK v3 patterns
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — Aurora DSQL vs Aurora Serverless v2 vs RDS, DynamoDB single-table, vector search, S3 Tables
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — CDK v2 patterns, CodePipeline V2, Karpenter v1, GitHub Actions OIDC, multi-account release
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — IAM Identity Center, permission boundaries, SCPs/RCPs, KMS, Security Hub (next-gen), incident response
- [`/stacks/aws/sre-engineer/`](/stacks/aws/sre-engineer/) — CloudWatch Application Signals, OTel via ADOT, FIS chaos, SLOs + burn-rate alerts
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — AgentCore Runtime + Strands, Bedrock model gateway, Knowledge Bases, SageMaker HyperPod
- [`/stacks/aws/saas-architect/`](/stacks/aws/saas-architect/) — tenancy models (silo/pool/bridge), tenant isolation via ABAC + KMS, Cognito patterns, AWS SaaS Factory
- [`/stacks/aws/fintech-architect/`](/stacks/aws/fintech-architect/) — thin overlay; PCI DSS scope reduction, ledger-adjacent (not ledger) Aurora DSQL, AWS Payment Cryptography

## Authoritative sources

For verified-current behavior, see the official AWS surfaces:

- **[AWS Documentation](https://docs.aws.amazon.com/)** — canonical reference for every service
- **[AWS CLI v2 Reference](https://docs.aws.amazon.com/cli/latest/reference/)** — command + flag reference
- **[AWS What's New](https://aws.amazon.com/about-aws/whats-new/recent/)** — release feed; check before asserting any feature added 2024-2026
- **[AWS News Blog](https://aws.amazon.com/blogs/aws/)** — feature deep-dives and re:Invent recaps
- **[AWS Security Bulletins](https://aws.amazon.com/security/security-bulletins/)** — CVE + service security advisories
- **[AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)** — Operational Excellence, Security, Reliability, Performance, Cost, Sustainability pillars + AI/ML lenses
- **[AWS Health Dashboard](https://health.aws.amazon.com/health/status)** — region/service status
- **[AWS CDK v2 API Reference](https://docs.aws.amazon.com/cdk/api/v2/)** — construct library reference
- **[Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/)** — model gateway, Guardrails, Knowledge Bases
- **[AgentCore Developer Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)** — Runtime, Browser, Memory

## Delegate skills

No first-party AWS MCP server is GA in user environments as of `last_verified_on`. **Amazon Q Developer** (formerly CodeWhisperer) is editor-embedded — not an installable skill/MCP. AWS-hosted MCPs (AWS Documentation MCP, AWS Code MCP previews) are evolving in 2026. Once an installable MCP client surface ships with a known skill identifier, it will be added to `delegate_to_skills` and ETYB will defer to it for matching products.

## Stack composition — when AWS isn't alone

If the workload is on AWS **plus** another platform with a registered Stack pack, both packs apply and own their sides:

| Composition | AWS pack covers | Other pack covers |
|-------------|-----------------|-------------------|
| AWS + Salesforce | Named Credentials destination, Pub/Sub API receivers (EventBridge + Lambda), Bedrock for non-Trust-Layer LLM workloads | Apex callouts, Trust Layer, External Client App config |
| AWS + Snowflake | DataLake source (S3 + Iceberg + Glue), Kinesis → Snowpipe, Aurora DSQL → Snowflake CDC | Snowflake compute, warehouses, Snowpark ML |
| AWS + Databricks | S3 + Unity Catalog source, Glue → Databricks, EKS-hosted workloads | Databricks workspace, MLflow, Delta Live Tables |
| AWS + Stripe | Webhook receiver (API Gateway + Lambda + Secrets Manager for signing), EventBridge schema registry for Stripe events | Stripe API mechanics, billing logic, dunning |
| AWS + Vercel/Netlify | Backend (Lambda + API Gateway + Aurora DSQL); EventBridge for backend triggers | Frontend hosting, edge functions, CDN |
| AWS + Cloudflare | Origin (CloudFront → ALB), API origin, Workers KV vs DynamoDB tradeoffs | Cloudflare Workers, Workers AI, R2, Pages |

When the other Stack lacks a registered pack, ETYB handles AWS only — explicitly, without faking the other side.
