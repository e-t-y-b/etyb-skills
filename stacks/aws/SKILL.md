---
name: stack-aws
description: |-
  AWS platform knowledge overlay for the ETYB team. Loads when work involves the AWS ecosystem — EC2, Lambda, ECS, EKS, Fargate, Karpenter, S3, RDS, Aurora, DynamoDB, ElastiCache, EventBridge, SQS, SNS, Kinesis, API Gateway, AppSync, CloudFront, Route 53, VPC, IAM, KMS, Secrets Manager, CloudWatch, X-Ray, CloudTrail, Config, GuardDuty, Bedrock, AgentCore, SageMaker, Step Functions, Glue, Athena, Redshift, OpenSearch, MSK, Cognito, Amplify, AWS CDK, CloudFormation, SAM, Copilot CLI, AWS Organizations, Control Tower, Q Developer.
  Triggers: aws, amazon web services, ec2, lambda, snapstart, ecs, ecs express, eks, eks auto mode, eks hybrid nodes, fargate, fargate spot, karpenter, karpenter v1, graviton, graviton4, graviton5, trainium, trainium2, trainium3, inferentia, s3, s3 express one zone, s3 tables, s3 intelligent tiering, ebs, gp3, io2, io2 block express, efs, fsx, fsx lustre, fsx ontap, rds, aurora, aurora serverless, aurora serverless v2, aurora limitless, aurora dsql, dsql.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "5.0.0-dev"
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

# AWS Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current AWS knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/aws/index.md`](index.md)
- **Per-product pages:** `stacks/aws/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/aws/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/aws/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Bedrock now ships AgentCore** — the runtime layer for production agents. **AgentCore Runtime, AgentCore Browser, AgentCore Memory** GA'd through 2025-2026. Don't propose "raw Bedrock agents" as the deployment surface for new agentic workloads; AgentCore is the surface (see ai-ml-engineer overlay).
- **Strands Agents SDK** was open-sourced May 2025. It's the AWS-blessed agent authoring kit and pairs with AgentCore Runtime. Older guidance pointing at LangChain-only as the agent framework is incomplete.
- **Aurora DSQL** GA'd May 2025. Postgres-compatible, serverless, multi-region active-active with 99.999% availability. Express configuration (Mar 2026) gets you a DB in two clicks. Replaces large swathes of "we need a global Postgres" architecture.
- **EKS Auto Mode** (re:Invent 2024) — managed compute, networking, storage with a single API call. **Karpenter v1 GA'd late 2024** with a breaking CRD migration (`v1beta1` → `v1`, `NodePool`/`EC2NodeClass` replacing `Provisioner`/`AWSNodeTemplate`). New EKS clusters in 2026 default to Auto Mode + Karpenter v1.
- **Lambda SnapStart for Python, .NET, Node.js** added in 2024-2025. Java is no longer the only SnapStart language. Cold start guidance changed accordingly.
- **VPC Lattice** has matured into the default L7 service-to-service surface — IPv6 dual-stack, custom domains, configurable Resource Gateway IPs all landed in 2025.
- **ECS Express Mode** launched Nov 2025. **AWS Copilot CLI** is end-of-support **June 2026**. **App Runner** is in maintenance mode. Propose ECS Express Mode for "deploy a container to HTTPS in one step" — don't propose Copilot or App Runner for net-new.
- **CDK v1 is fully EOL.** **CDK v2 (`aws-cdk-lib`) is the only supported track.** Mixins, ECS deployment strategies (built-in Linear/Canary), EKS Hybrid Nodes constructs, and `cdk --revert-drift` are 2025-2026 additions.
- **AWS Copilot/CodeWhisperer renamed to Amazon Q Developer.** **Amazon Q Business** is the enterprise RAG/search tier. The "CodeWhisperer" name is dead.
- **Amazon Linux 2 (AL2) reached end of standard support June 2025; maintenance support ends June 2026.** New AMIs and base images should target AL2023.
- **Step Functions JSONata + Variables** (re:Invent 2024) replace the ResultPath/InputPath dance for new state machines. **TestState API** GA Mar 2026 — test states in isolation before deploy.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on an AWS engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Least privilege via IAM Access Analyzer.** Default to Access Analyzer's policy-generation feature: deploy permissive-but-bounded IAM, capture CloudTrail activity, generate the least-privilege policy, then tighten. Don't write IAM policies by hand from memory.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch AWS | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running AWS alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
