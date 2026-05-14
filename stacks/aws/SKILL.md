---
name: stack-aws
description: >
  AWS platform knowledge overlay for the ETYB team. Loads when work involves the
  AWS ecosystem — EC2, Lambda, ECS, EKS, Fargate, Karpenter, S3, RDS, Aurora,
  DynamoDB, ElastiCache, EventBridge, SQS, SNS, Kinesis, API Gateway, AppSync,
  CloudFront, Route 53, VPC, IAM, KMS, Secrets Manager, CloudWatch, X-Ray,
  CloudTrail, Config, GuardDuty, Bedrock, AgentCore, SageMaker, Step Functions,
  Glue, Athena, Redshift, OpenSearch, MSK, Cognito, Amplify, AWS CDK,
  CloudFormation, SAM, Copilot CLI, AWS Organizations, Control Tower, Q
  Developer. This is NOT a new team member; it is a context overlay that
  teaches each existing ETYB role what it needs to know to ship production-grade
  AWS work as of 2026-Q2.
  Triggers: aws, amazon web services, ec2, lambda, snapstart, ecs, ecs express,
  eks, eks auto mode, eks hybrid nodes, fargate, fargate spot, karpenter, karpenter v1,
  graviton, graviton4, graviton5, trainium, trainium2, trainium3, inferentia,
  s3, s3 express one zone, s3 tables, s3 intelligent tiering, ebs, gp3, io2,
  io2 block express, efs, fsx, fsx lustre, fsx ontap, rds, aurora, aurora serverless,
  aurora serverless v2, aurora limitless, aurora dsql, dsql, dynamodb,
  elasticache, valkey, memorydb, redshift, athena, glue, lake formation,
  opensearch, opensearch serverless, msk, msk serverless, kinesis, kinesis data streams,
  firehose, kinesis analytics, eventbridge, eventbridge pipes, eventbridge scheduler,
  sqs, sns, mq, api gateway, http api, rest api, websocket api, appsync,
  graphql, cloudfront, cloudfront functions, lambda edge, lambda@edge,
  route 53, route53, route 53 profiles, global accelerator, vpc, vpc lattice,
  transit gateway, tgw, direct connect, privatelink, vpc endpoint, nat gateway,
  iam, iam identity center, sso, scp, service control policy, organizations,
  control tower, landing zone, permission boundary, iam access analyzer, sts,
  kms, secrets manager, parameter store, certificate manager, acm, waf, shield,
  guardduty, security hub, inspector, macie, detective, audit manager, config,
  cloudtrail, cloudwatch, cloudwatch logs, cloudwatch metrics, cloudwatch alarms,
  application signals, container insights, internet monitor, x-ray, otel, adot,
  bedrock, bedrock agents, bedrock guardrails, bedrock knowledge bases,
  agentcore, agentcore runtime, agentcore browser, agentcore memory,
  strands agents, strands, sagemaker, sagemaker studio, sagemaker ai studio,
  sagemaker unified studio, sagemaker hyperpod, sagemaker pipelines, sagemaker jumpstart,
  step functions, jsonata, sfn, glue, glue catalog, athena, redshift serverless,
  cognito, cognito user pools, cognito identity pools, amplify, amplify gen 2,
  amplify hosting, app runner, app runner maintenance, copilot cli, copilot eol,
  cloudformation, cfn, cdk, cdk v2, cdk mixins, aws-cdk-lib, sam, sam cli,
  serverless application model, terraform on aws, opentofu on aws,
  cur, cost explorer, savings plans, reserved instances, spot, spot fleet,
  fargate spot, well-architected, well architected framework, war,
  q developer, amazon q developer, amazon q business, q business, codewhisperer,
  re:invent, reinvent, aws blog, aws whats new, hyperforce on aws, multi-account,
  account vending, control tower account factory, ram, resource access manager,
  cdk pipelines, codepipeline, codebuild, codedeploy, codeartifact, ecr,
  parallelcluster, batch, aws batch, neptune, documentdb, timestream, qldb,
  iot core, greengrass, sigv4, signature v4, eks pod identity, iam roles for service accounts, irsa.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_release: "2026-Q2"
  last_verified_on: "2026-05-14"
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
  primary:
    - { name: "AWS Documentation (canonical)",     url: "https://docs.aws.amazon.com/",                                  type: official_docs }
    - { name: "AWS CLI v2 Command Reference",      url: "https://docs.aws.amazon.com/cli/latest/reference/",             type: cli_reference }
    - { name: "AWS API Reference Hub",             url: "https://docs.aws.amazon.com/index.html",                        type: api_reference }
    - { name: "AWS What's New (changelog)",        url: "https://aws.amazon.com/about-aws/whats-new/recent/",            type: changelog }
    - { name: "AWS News Blog",                     url: "https://aws.amazon.com/blogs/aws/",                             type: changelog }
    - { name: "AWS Security Bulletins",            url: "https://aws.amazon.com/security/security-bulletins/",           type: security_advisories }
    - { name: "AWS Well-Architected Framework",    url: "https://aws.amazon.com/architecture/well-architected/",         type: architecture_guide }
    - { name: "AWS Health Dashboard",              url: "https://health.aws.amazon.com/health/status",                   type: status_page }
    - { name: "AWS Organization on GitHub",        url: "https://github.com/aws",                                        type: source }
    - { name: "AWS CDK v2 API Reference",          url: "https://docs.aws.amazon.com/cdk/api/v2/",                       type: api_reference }
    - { name: "Bedrock User Guide",                url: "https://docs.aws.amazon.com/bedrock/latest/userguide/",         type: official_docs }
    - { name: "AgentCore Documentation",           url: "https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/",type: official_docs }
delegate_to_skills:
  # No first-party AWS MCP server is GA in user environments as of last_verified_on.
  # Amazon Q Developer (formerly CodeWhisperer) is editor-embedded, not an installable skill/MCP.
  # AWS-hosted MCPs (e.g. AWS Documentation MCP, AWS Code MCP previews) are evolving in 2026.
  # Revisit when a stable, installable MCP surface ships in agent environments.
  []
products_covered:
  - { name: "Bedrock + AgentCore",              drift_risk: high,   notes: "Model gateway evolved twice in 2025; AgentCore Runtime/Browser/Memory are 2025-2026 GA — surfaces, IAM shape, and pricing still shifting" }
  - { name: "Strands Agents SDK",               drift_risk: high,   notes: "Open-sourced May 2025; API stabilizing; integration with AgentCore Runtime + Bedrock evolving release-over-release" }
  - { name: "Aurora DSQL",                      drift_risk: high,   notes: "GA May 2025; multi-region active-active patterns and pricing are post-cutoff for most LLMs; Express config (Mar 2026) is brand-new" }
  - { name: "EKS Auto Mode",                    drift_risk: high,   notes: "Launched re:Invent 2024; KMS encryption + capacity reservations + vended logs added through 2025-2026; still rapidly evolving" }
  - { name: "Karpenter v1",                     drift_risk: high,   notes: "v1 GA late 2024; CRD migration from v1beta1 is a hard step LLMs often miss; new NodePool/NodeClass shape" }
  - { name: "Lambda SnapStart",                 drift_risk: medium, notes: "Java since 2022, Python + .NET + Node.js added 2024-2025; SnapStart cost model changed, priming guidance shifted" }
  - { name: "VPC Lattice",                      drift_risk: medium, notes: "Custom domains (Nov 2025), IPv6 dual-stack (Aug 2025), Resource Gateway IP config (Oct 2025) — surface keeps growing" }
  - { name: "S3 Tables + S3 Express One Zone",  drift_risk: medium, notes: "S3 Tables (Iceberg-native) and Express One Zone conditional writes/deletes are 2024-2026 additions LLMs underweight" }
  - { name: "CDK v2 (aws-cdk-lib)",             drift_risk: medium, notes: "CDK v1 fully EOL; mixins, ECS deployment strategies, EKS Hybrid Nodes constructs added 2025-2026" }
  - { name: "ECS Express Mode",                 drift_risk: medium, notes: "Nov 2025 — replaces Copilot CLI (EOL June 2026) and App Runner (maintenance). Many guides still recommend the legacy two" }
  - { name: "Graviton4 / Graviton5",            drift_risk: medium, notes: "Graviton4 GA across families; Graviton5 (M9g) preview Dec 2025; ARM-first is the default — x86 is now the exception" }
  - { name: "Step Functions JSONata + Variables", drift_risk: medium, notes: "Re:Invent 2024 — replaces ResultPath/InputPath chains for new state machines; TestState API GA Mar 2026" }
  - { name: "Security Hub (next-gen)",          drift_risk: medium, notes: "Re:Invent 2025 upgrade adds risk analytics + auto-aggregation; older 'Security Hub' is being superseded" }
  - { name: "Q Developer + Q Business",         drift_risk: medium, notes: "CodeWhisperer renamed to Amazon Q Developer; Q Business is the enterprise RAG tier; pricing and capability lines moved in 2025" }
  - { name: "App Runner",                       drift_risk: high,   notes: "Maintenance mode — recommend ECS Express Mode for net-new; existing services still supported but no new feature investment" }
  - { name: "Copilot CLI",                      drift_risk: high,   notes: "End-of-support June 2026 — flag immediately if a user proposes it for new pipelines" }
  - { name: "AWS Lambda runtimes",              drift_risk: medium, notes: "Python 3.13, Node.js 22, Java 21 current; Python 3.8/3.9, Node.js 16/18, Java 8 deprecated — runtime end-of-life list shifts each quarter" }
  - { name: "Amazon Linux 2 (AL2)",             drift_risk: high,   notes: "Standard support ended June 2025; maintenance support ends June 2026 — flag if a user's AMI base is AL2 for net-new" }
  - { name: "EC2 + EBS",                        drift_risk: low,    notes: "Foundational surface stable; gp3 default, io2 Block Express for IOPS-critical, NVMe-only nitro instances assumed" }
  - { name: "DynamoDB",                         drift_risk: low,    notes: "API stable; zero-ETL to OpenSearch/Redshift the main 2024-2025 addition; on-demand pricing model unchanged" }
  - { name: "RDS / Aurora Postgres / MySQL",    drift_risk: low,    notes: "Mature surface; Blue/Green deployments + Aurora Global Database the main evolution" }
  - { name: "API Gateway",                      drift_risk: low,    notes: "HTTP API the default for new builds; REST API for full feature set; surface stable" }
  - { name: "CloudFront + Route 53",            drift_risk: low,    notes: "IPv6/BYOIP added 2025-2026 but core surface is mature; Route 53 Profiles is the main new pattern" }
  - { name: "AWS Organizations + SCPs",         drift_risk: low,    notes: "Foundational governance surface; multi-account patterns are stable" }
  - { name: "Control Tower",                    drift_risk: low,    notes: "Mature; account factory + guardrail set evolves but the contract is stable" }
  - { name: "Cognito",                          drift_risk: medium, notes: "User Pools + Identity Pools stable; managed login + passkey support 2024-2025; advanced security pricing changed" }
  - { name: "Amplify Gen 2",                    drift_risk: medium, notes: "Gen 2 (CDK-based) is the path for net-new; Gen 1 (CLI/CloudFormation-based) maintenance only" }
  - { name: "Kinesis + MSK",                    drift_risk: low,    notes: "Mature; MSK Serverless and Kinesis on-demand simplify provisioning; integration with EventBridge Pipes is the modern wiring" }
  - { name: "SageMaker AI Studio (Unified)",    drift_risk: high,   notes: "Unified Studio launched 2024; HyperPod additions 2025-2026 (NVL72, checkpointless training, dynamic scaling); fast-moving" }
  - { name: "AWS Backup + Resilience Hub",      drift_risk: low,    notes: "Cross-account, cross-region backup orchestration stable" }
  - { name: "Glacier vault APIs (legacy)",      drift_risk: high,   notes: "Glacier vault (vault locks aside) is in retirement track — S3 Glacier storage classes via S3 API are the supported path; flag if user wires `glacier:*` for new code" }
---

# AWS Stack Pack — Team Briefing

You're working on AWS. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — backend-architect writes the Lambda handlers, devops-engineer authors the CDK + pipeline, security-engineer designs the IAM + KMS posture, ai-ml-engineer wires Bedrock agents, sre-engineer defines the SLOs and CloudWatch alarms. This pack teaches each role what AWS expects in 2026-Q2.

**Currency stamp:** verified against AWS as of **2026-05-14**, covering re:Invent 2024 (Dec 2024) and re:Invent 2025 (Dec 2025) announcements plus the steady cadence of "What's New" through April-May 2026. If today's date is more than 6 months past `last_verified_on`, the pack is stale — warn the user and consult [AWS What's New](https://aws.amazon.com/about-aws/whats-new/recent/) and [the AWS News Blog](https://aws.amazon.com/blogs/aws/) before asserting service-specific specifics.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff (or earlier) will get these wrong unless explicitly corrected. Treat the following as non-negotiable corrections:

- **Bedrock now ships AgentCore** — the runtime layer for production agents. **AgentCore Runtime, AgentCore Browser, AgentCore Memory** GA'd through 2025-2026. Don't propose "raw Bedrock agents" as the deployment surface for new agentic workloads; AgentCore is the surface (see ai-ml-engineer overlay).
- **Strands Agents SDK** was open-sourced May 2025. It's the AWS-blessed agent authoring kit and pairs with AgentCore Runtime. Older guidance pointing at LangChain-only as the agent framework is incomplete.
- **Aurora DSQL** GA'd May 2025. Postgres-compatible, serverless, multi-region active-active with 99.999% availability. Express configuration (Mar 2026) gets you a DB in two clicks. Replaces large swathes of "we need a global Postgres" architecture.
- **EKS Auto Mode** (re:Invent 2024) — managed compute, networking, storage with a single API call. **Karpenter v1 GA'd late 2024** with a breaking CRD migration (`v1beta1` → `v1`, `NodePool`/`EC2NodeClass` replacing `Provisioner`/`AWSNodeTemplate`). New EKS clusters in 2026 default to Auto Mode + Karpenter v1.
- **Lambda SnapStart for Python, .NET, Node.js** added in 2024-2025. Java is no longer the only SnapStart language. Cold start guidance changed accordingly.
- **VPC Lattice** has matured into the default L7 service-to-service surface — IPv6 dual-stack, custom domains, configurable Resource Gateway IPs all landed in 2025.
- **ECS Express Mode** launched Nov 2025. **AWS Copilot CLI** is end-of-support **June 2026**. **App Runner** is in maintenance mode. Propose ECS Express Mode for "deploy a container to HTTPS in one step" — don't propose Copilot or App Runner for net-new.
- **CDK v1 is fully EOL.** **CDK v2 (`aws-cdk-lib`) is the only supported track.** Mixins, ECS deployment strategies (built-in Linear/Canary), EKS Hybrid Nodes constructs, and `cdk --revert-drift` are 2025-2026 additions.
- **AWS Copilot/CodeWhisperer renamed to Amazon Q Developer.** **Amazon Q Business** is the enterprise RAG/search tier. The "CodeWhisperer" name is dead.
- **External Connected Apps... is Salesforce, not AWS** — but the equivalent AWS gotcha is **Amazon Linux 2 (AL2) reached end of standard support June 2025; maintenance support ends June 2026.** New AMIs and base images should target AL2023.
- **Glacier vault APIs (`glacier:*`)** are on retirement track. S3 Glacier storage classes accessed via the S3 API are the supported pattern. Don't wire `glacier:UploadArchive` into new pipelines.
- **Step Functions JSONata + Variables** (re:Invent 2024) replace the ResultPath/InputPath dance for new state machines. **TestState API** GA Mar 2026 — test states in isolation before deploy.
- **Security Hub** got a major overhaul at re:Invent 2025 — near-real-time risk analytics, auto-aggregation across GuardDuty/Inspector/Macie/CSPM, one year of historical trends.
- **Aurora Serverless v1 reached EOL** Dec 2024. Migrate to Aurora Serverless v2 (or DSQL for new builds).
- **Salesforce Functions and Heroku Enterprise are dead/dying** — irrelevant on this pack, but worth flagging when users propose hybrid Salesforce+AWS architectures.
- **Graviton4 is the default.** ARM-first is now the AWS posture across Lambda, Fargate, RDS, ElastiCache, EC2, MemoryDB. x86 is the exception you justify, not the default you pick. **Graviton5 (M9g)** is in preview as of Dec 2025.

If you find yourself recommending CDK v1, Copilot CLI for new deployments, App Runner for new services, Aurora Serverless v1, the "Einstein Copilot"... wait, wrong pack — but the principle holds: **if you're naming a service that retired or got renamed in 2024-2026, you're using stale knowledge.** Read the references below.

## How this pack plugs in

ETYB's router detects AWS signals via the trigger keywords above and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md`.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The AWS overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform (e.g., TDD on Lambda = `pytest`/`vitest` against handler functions with mocked AWS SDK clients via `moto`/`aws-sdk-client-mock`; TDD on CDK = `aws-cdk-lib/assertions` snapshot + fine-grained assertions before `cdk deploy`).

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | **The architectural decision** — Lambda vs ECS vs EKS vs EC2; serverless vs containers vs IaaS; event-driven vs request-response; multi-region vs single-region with DR; multi-account strategy; well-architected pillar tradeoffs; when AWS is *not* the answer |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | Lambda idioms (SnapStart, Lambda Web Adapter, container images, layers, ephemeral storage); API Gateway vs Lambda URLs vs AppSync; EventBridge Pipes + Step Functions JSONata; SQS/SNS/Kinesis/MSK choice; idempotency, retries, DLQ patterns; ECS Express Mode + Fargate; signing with SigV4; SDK v3 patterns |
| `database-architect` | [`references/database-architect.md`](references/database-architect.md) | **Aurora DSQL** vs Aurora Serverless v2 vs Aurora Limitless vs RDS; DynamoDB design (single-table, GSI strategy, zero-ETL to OpenSearch/Redshift); ElastiCache (Valkey) vs MemoryDB; Redshift vs Athena+S3 Tables vs OpenSearch; pgvector on Aurora vs OpenSearch vector vs Bedrock Knowledge Bases |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | **CDK v2 patterns** (mixins, L1/L2/L3 constructs, deployment strategies); CodePipeline + CodeBuild + CodeDeploy; Terraform on AWS; multi-account release; ECR + image signing; SAM for serverless-only; **Karpenter v1** node pool design; cost monitoring; **don't propose Copilot CLI or App Runner for net-new** |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | IAM Identity Center, **permission boundaries**, SCPs, IAM Access Analyzer, KMS (multi-Region keys, key policies, grants), Secrets Manager rotation, GuardDuty + Security Hub (next-gen), WAF, Shield, mTLS via ACM PCA, IRSA + EKS Pod Identity, **least-privilege via Access Analyzer policy generation** |
| `sre-engineer` | [`references/sre-engineer.md`](references/sre-engineer.md) | CloudWatch Application Signals + Container Insights + Internet Monitor; **native OTel via OTLP** (preview Apr 2026); X-Ray cross-account tracing; alarms + composite alarms; SLO definition with Application Signals; incident response runbook patterns; chaos engineering with FIS |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **AgentCore Runtime + AgentCore Browser + AgentCore Memory**; Strands Agents SDK; Bedrock model gateway (Claude, Nova, Llama, Mistral, DeepSeek as available); Bedrock Guardrails; Bedrock Knowledge Bases vs OpenSearch vector; SageMaker AI Studio (unified) + HyperPod; Trainium2/3 vs Blackwell tradeoffs; pgvector vs OpenSearch vector vs OpenSearch Serverless for retrieval |
| `saas-architect` | [`references/saas-architect.md`](references/saas-architect.md) | **Multi-tenant patterns on AWS** — silo vs pool vs bridge; tenant isolation via IAM ABAC, KMS grants, separate VPCs/accounts; Cognito + Identity Pools for tenant auth; AWS SaaS Factory + Control Tower account vending; tier-based pool sharding; cost-per-tenant via CUR + tags |
| `fintech-architect` | [`references/fintech-architect.md`](references/fintech-architect.md) | **Thin overlay.** AWS PCI DSS scope reduction patterns, FedRAMP/SOC posture, KMS for tokenization, Aurora DSQL for ledger-adjacent multi-region writes (**not** the ledger itself), Bedrock for fraud analytics within Trust constraints. Defers to fintech-architect for ledger/PCI/PSD2/AML semantics |

## Top platform gotchas the team must know

Opinionated, named, with consequences. These cost real money or real reputation when missed.

1. **AL2 is dying.** Amazon Linux 2 end-of-life cadence: standard support ended June 2025, maintenance support ends June 2026. ParallelCluster 3.15 is the last release supporting AL2. New AMIs target AL2023. Consequence of missing this: a Lambda runtime upgrade or an AMI rebuild forced on you at the worst possible moment.

2. **Lambda payload limits cliff.** 6 MB sync invocation, 256 KB async (SQS, EventBridge, etc.). Hitting either silently fails or truncates in ways application code rarely handles. Default pattern: drop the payload to S3, pass a reference. Don't argue with the limit; design around it.

3. **Governor-cliff: 1,000 default Lambda concurrency, 10 TPS Bedrock model invocations per model+region by default.** Both are quota-bumpable but ship as defaults that surprise teams under load. Request increase **before** launch, not at 2am when the launch is live.

4. **DynamoDB single-table design or you'll regret it.** Multi-table-per-entity is the relational-modeling reflex. It's wrong on DynamoDB. Design access patterns first, derive a single (or 2-3) tables with GSI strategy. If the team can't enumerate the top-5 access patterns up front, they're not ready to model.

5. **VPC + NAT Gateway cost.** NAT Gateways are ~$0.045/hr + $0.045/GB processed. Multi-AZ HA = 3x. Cross-AZ data transfer ($0.01/GB each way) compounds. For Lambda-only or container-only architectures with no need for outbound internet, **put resources in private subnets without NAT** and use VPC endpoints (interface or gateway) for AWS service traffic. The "default VPC with NAT in every AZ" cookie-cutter has eaten more startup runway than any other AWS line item.

6. **CloudWatch Logs Insights ingestion is the silent budget killer.** Per-GB ingestion is cheap until it isn't. Multi-line stack traces blown up by debug logging in production = >$10K/mo bills routinely. Default retention is "Never Expire" — change it. Use log group-level retention, log groups per service, and route only INFO+ to CloudWatch; debug logs go to S3 via Kinesis Firehose at a 10x lower cost.

7. **IAM is the actual security boundary.** Network controls (VPC, SGs, NACLs) are belt; IAM is the buckle. A leaked credential with `AdministratorAccess` bypasses every VPC control you wrote. Permission boundaries on every IAM principal created by app teams; SCPs at the OU level for org-wide guardrails. IAM Access Analyzer **continuous** monitoring of cross-account access. Treat IAM Identity Center as the only path for human access — no IAM users, no long-lived access keys.

8. **Multi-Region is not active-active by default.** Most regional services are exactly that: regional. Cross-region replication for S3, DynamoDB Global Tables, Aurora Global Database, RDS read replicas — each has its own RPO/RTO contract and operational shape. Don't claim "multi-region resilience" until each tier of the stack has a documented replication strategy and you've tested cutover in game-day. Aurora DSQL with 99.999% multi-region active-active is genuinely new and worth picking specifically when you need it.

9. **Spot interruption is real.** 2-minute warning. On EC2 + ASG, mixed-instance policies with 3+ families and capacity-optimized allocation strategy. On EKS, Karpenter v1 handles spot well with consolidation. On Fargate Spot, task interruption signal arrives via SIGTERM 2 minutes before. Stateful workloads (databases, single-instance services, anything that holds session state) — never Spot. Stateless batch/CI/EKS worker — Spot first, on-demand fallback.

10. **CDK assets get expensive at scale.** Every `lambda.Code.fromAsset()` builds and uploads an asset bundle to S3 + ECR. In monorepos with 100+ Lambdas, this can take 10+ minutes per `cdk deploy` and rack up S3 storage you forget about. Use **CodeBuild project references**, monorepo asset deduplication, and `cdk deploy --hotswap` for dev loops. Set lifecycle policies on the CDK asset buckets.

11. **`re:Invent` announcements ≠ GA.** "Coming soon," "preview," "private preview," "limited availability" all mean *don't bet a production architecture on it yet*. Always check the official "What's New" page (not a re:Invent recap blog) for the exact GA date and the regional rollout map. Some 2024 announcements (Aurora DSQL, EKS Auto Mode) GA'd within months; some are still preview a year later.

12. **Region selection is a compliance + cost decision, not a latency decision alone.** us-east-1 is cheapest and has every service first, but **every multi-region failure of the last decade has started or peaked there**. For new architecture without us-east-1-specific dependencies, default to a different primary region (us-east-2 or us-west-2) and replicate to us-east-1 if you need it. Costs are higher in some regions (Stockholm, Sao Paulo, Hyderabad), data residency may force the region, and not every service is in every region — confirm before designing.

## Compliance composition — when AWS work touches a vertical

When the user's request hits a regulated vertical (fintech, healthcare, public sector), the AWS pack handles AWS-side patterns; the vertical's specialist owns the compliance semantics. Examples:

- **Healthcare on AWS (HIPAA):** AWS is HIPAA-eligible across most services with a BAA. The pack covers AWS BAA scope, eligible-services lists, KMS for PHI encryption, CloudTrail for audit. `healthcare-architect` (vertical) owns the HIPAA controls, PHI minimization, breach notification posture, FHIR semantics on AWS HealthLake.
- **Fintech on AWS (PCI DSS, SOX, PSD2):** The pack covers PCI DSS scope reduction via tokenization (KMS, Macie for PII discovery, Verified Permissions for fine-grained auth), reference architectures (CDE in a separate account with locked-down SCPs), audit trails (CloudTrail + Config + Audit Manager). `fintech-architect` (vertical) owns ledger design (AWS is not your ledger of record — see the fintech-architect overlay), PSD2 SCA, AML workflows.
- **Public sector / FedRAMP:** GovCloud (US-East, US-West), ITAR-controlled, separate account family. Most services GA in GovCloud lag 6-12 months. Treat as a distinct deployment shape. The pack flags GovCloud feature gaps; the public-sector vertical owns the compliance evidence.
- **EU data residency / GDPR:** eu-central-1 (Frankfurt), eu-west-1 (Ireland), eu-west-2 (London), eu-west-3 (Paris), eu-north-1 (Stockholm), eu-south-1 (Milan), eu-south-2 (Spain), eu-central-2 (Zurich). **AWS European Sovereign Cloud** (EUSC) is the new sovereign offering for highest-bar EU workloads — GA targeted late 2025/2026. Pack covers regional service availability + KMS-key-region constraints; security-engineer + the vertical own transfer impact assessments and DPA reviews.

If a user's AWS request collides with a vertical AND the vertical's specialist file exists in `references/specialists/`, route to both: AWS overlay for the AWS-shaped questions, vertical for the compliance/domain shape.

## Stack composition — when AWS isn't alone

If the user is on AWS **plus** another platform with a registered pack:

| Composition | AWS pack covers | Other pack covers |
|-------------|-----------------|-------------------|
| AWS + Salesforce | Named Credentials destination (API Gateway endpoint), Pub/Sub API receivers (EventBridge + Lambda), AWS Bedrock for non-Trust-Layer LLM workloads called from Salesforce | Salesforce-side Apex callouts, Trust Layer, External Client App config |
| AWS + Snowflake | DataLake source (S3 + Iceberg + Glue), Kinesis → Snowpipe Streaming, Aurora DSQL → Snowflake CDC | Snowflake compute, warehouses, materialized views, ML on Snowpark |
| AWS + Databricks | S3 + Unity Catalog source, Glue → Databricks, EKS-hosted custom workloads | Databricks workspace, MLflow, Delta Live Tables |
| AWS + Stripe | Webhook receiver (API Gateway + Lambda + Secrets Manager for signing secret), Eventbridge schema registry for Stripe events | Stripe API mechanics, billing logic, dunning |
| AWS + Vercel/Netlify | Backend (Lambda + API Gateway + Aurora DSQL); EventBridge for backend triggers | Frontend hosting, edge functions, CDN |
| AWS + Cloudflare | Origin (CloudFront → ALB), API origin, Workers KV vs DynamoDB tradeoffs | Cloudflare Workers, Workers AI, R2, Pages |

When the other stack lacks a registered pack, the AWS pack handles its side only — say so explicitly and don't fake the other side.

## Standing instructions for every role on an AWS engagement

1. **Anchor to currency.** Before recommending an API shape, service feature, or default behavior, check whether the overlay covers it. If yes, follow the overlay; do not pattern-match from 2023 muscle memory. If no, say so explicitly and verify against [AWS What's New](https://aws.amazon.com/about-aws/whats-new/recent/) before asserting specifics. Service GA dates and quota defaults are particularly easy to get wrong.

2. **Defer to verticals on compliance.** AWS supplies the controls; the vertical owns the compliance interpretation. AWS doesn't make a system HIPAA-compliant — your design does, on top of HIPAA-eligible AWS services with a BAA in place.

3. **Quotas before code.** Every AWS recommendation that involves Lambda concurrency, Bedrock TPS, DynamoDB WCU/RCU, API Gateway throttling, Step Functions execution rate, EC2 instance limits, or S3 PUT/GET request rates **must consider the default quota**. State the quota, the request rate the design implies, and whether a Service Quota increase is needed pre-launch. "We'll request more concurrency if we hit limits" is an outage waiting to happen.

4. **Least privilege via Access Analyzer.** Default to IAM Access Analyzer's policy-generation feature: deploy the workload with permissive-but-bounded IAM, capture CloudTrail activity, generate the least-privilege policy, then tighten. Don't write IAM policies by hand from memory; you'll either over-grant or break the workload.

5. **Account topology is a design decision.** "Production, staging, dev" accounts is the minimum. Real teams have Security OU (Log Archive + Security Tooling), Infrastructure OU (Networking + Shared Services), Workloads OU (per-env or per-app), Sandbox OU. Multi-account from day one is cheaper than splitting a monolithic account at year two.

6. **Region selection isn't a default.** Don't just pick us-east-1. Choose deliberately based on (a) data residency, (b) service availability for what you're deploying, (c) cost, (d) latency to users, (e) blast-radius separation from us-east-1's gravitational misfortunes.

7. **Cost as a non-functional requirement.** Every architecture must include a cost estimate (Cost Explorer historical baseline if migrating; Pricing Calculator if greenfield), a tagging strategy enforced via SCPs, and budget alerts via AWS Budgets. "We'll right-size later" is how teams burn 50% of their cloud spend on idle capacity.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics for healthcare (HIPAA/HITRUST/FHIR semantics) | `healthcare-architect` |
| Compliance specifics for fintech (PCI DSS scope, PSD2 SCA, AML, ledger semantics) | `fintech-architect` |
| ISV / multi-tenant SaaS on AWS (tenant isolation, billing, tier economics) | `saas-architect` (with this pack) |
| External system architecture beyond AWS | `system-architect` (without the pack overlay) |
| Frontend not deployed on AWS Amplify/CloudFront/S3 | `frontend-architect` (without the pack overlay) |
| Mobile app on AWS (Amplify Gen 2, AppSync, Cognito) | `mobile-architect` (with this pack) |
| Non-AWS backend service that AWS calls into | `backend-architect` (without the pack overlay) |

## Currency — when this pack is stale

If `today - last_verified_on > 6 months`, this pack is stale. Behavior:

1. **Warn the user.** "Pack last verified 2026-05-14; AWS ships ~3,000 What's New items per year, so version-specific guidance may be outdated."
2. **Triangulate before asserting.** Before claiming a service has a feature, check the [What's New search](https://aws.amazon.com/about-aws/whats-new/recent/) for the service name. Before claiming a quota, check Service Quotas console / AWS docs.
3. **Verify retirement dates.** [AWS deprecation pages](https://docs.aws.amazon.com/) and the [AWS Health Dashboard](https://health.aws.amazon.com/health/status) — runtime retirements (Lambda, AL2) hit quarterly.
4. **Trigger refresh.** Owner: stack maintainer. Cadence: every 3 months minimum, every re:Invent (early Dec) mandatory.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- No deep coverage of **IoT Core / Greengrass / Sitewise** — edge/IoT-specific workloads are a separate stack candidate.
- No **Game Tech (GameLift, GameSparks)** depth — niche, defer to game-specialist stack if demand arises.
- No **HPC depth beyond ParallelCluster reference** — HPC, scientific computing, weather/genomics workloads warrant their own overlay if demand justifies.
- **Quantum (Braket)** — preview/early-GA surface, low signal, skipped.
- **Snowmobile / Snowball Edge / Snowcone** — physical data transfer, niche, skipped.
- **Direct Connect / Cloud WAN deep design** — covered at the system-architect level, not exhaustively.
- **Outposts / Local Zones / Wavelength** — covered as boundary cases in system-architect, not exhaustively.
- **AWS Marketplace ISV publishing** — for product-led AWS distribution, separate from this pack's "consume AWS" framing.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation against authoritative sources above.
