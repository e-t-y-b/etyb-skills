---
role: system-architect
stack: aws
last_verified_on: "2026-05-14"
---

# AWS Overlay — system-architect

You are the system-architect on an AWS engagement. This overlay covers the architectural decisions that don't lift cleanly from general system-design thinking: AWS has its own primitives, its own scaling envelope, its own multi-account topology, its own resilience contracts. Get the *shape* right here and the role-specific overlays handle execution.

**Currency:** AWS as of **2026-Q2** — re:Invent 2024 + re:Invent 2025 announcements GA'd, What's New through May 2026. See parent [`SKILL.md`](../SKILL.md) for the full currency context.

## Your primary decision — pick the right compute primitive

On AWS, almost every workload could be implemented five ways. The cost of choosing wrong is high: lock-in, surprise bills, multi-quarter migrations, scaling cliffs. Use this decision frame.

| Need | Default primitive | When to escape |
|------|-------------------|----------------|
| Stateless HTTP API, request <15 min, p99 latency tolerates cold starts | **Lambda + API Gateway HTTP API** (or AppSync for GraphQL) | Move to ECS Express Mode when cold start is intolerable even with SnapStart, or you need >15-min execution, or you've outgrown 1,000 default concurrency and the unit economics flip toward a sustained container |
| Stateless HTTP API, "ship a container to HTTPS" | **ECS Express Mode** (Nov 2025) on Fargate | Move to EKS Auto Mode when you need K8s ecosystem (Helm, Argo, Istio, GPU operators, Karpenter); move to plain ECS+Fargate when you need fine-grained service definition control |
| Container microservices, team owns Kubernetes | **EKS Auto Mode** with Karpenter v1 | Move to self-managed EKS only when you need cluster-level customization Auto Mode doesn't expose. EKS Hybrid Nodes for on-prem extensions |
| Long-running stateful (databases, message brokers, single-tenant services) | **EC2 (Graviton4) + ASG + Reserved Instances or Savings Plans** | Aurora/RDS for managed databases; ElastiCache for cache; MSK for Kafka — escape to managed services where the AWS-managed shape fits |
| Batch / ML training / fault-tolerant compute | **EC2 Spot via ASG** with mixed-instance policies, or **AWS Batch** for orchestration, or **Karpenter** on EKS with `nodepool.spec.disruption.consolidationPolicy: WhenEmpty` | Move to dedicated training infrastructure (SageMaker HyperPod, ParallelCluster) when scale and accelerator coordination demand it |
| GPU inference, accelerator-bound | **Inf2 / Trn2 instances** (custom silicon), or **P5/P6 (Blackwell)** for state-of-the-art, or **Bedrock-hosted models** when you don't need your own weights | Move to SageMaker endpoints (real-time or async) when you need the managed model serving + autoscaling shape |
| HPC clusters, MPI workloads | **ParallelCluster 3.15** with Slurm + EFA | EKS + custom operators only when you need K8s scheduling primitives MPI doesn't offer |
| Event-driven workflow, multi-step | **Step Functions** with JSONata (re:Invent 2024) for the wiring; Lambda for the work | EventBridge Pipes for simple source → enrichment → target chains without state; SQS + Lambda for fire-and-forget; raw EventBridge bus for fan-out |
| Pub/sub, ordered, replayable | **Kinesis Data Streams** (on-demand mode) or **MSK Serverless** (Kafka shape) | SNS topics for fan-out without ordering; SQS for queue semantics with at-least-once; EventBridge for routing-with-rules across services/accounts |
| API for static SPA / mobile | **AppSync GraphQL** or **API Gateway HTTP API** with Cognito auth | Lambda URLs only for simple internal endpoints (no IAM custom auth, no API mgmt features) |

The most common architecture mistake on AWS today: **defaulting to Lambda for everything** (cold starts compound, concurrency limits become real, $0-and-pennies pricing breaks down at high RPS), or **defaulting to EKS for everything** (Kubernetes operational cost overwhelms the team that doesn't actually need K8s). Match the primitive to the actual workload shape, not the team's "we're a serverless shop" / "we're a containers shop" identity.

## Lambda vs ECS vs EKS vs EC2 — the call most teams flip-flop on

The four-option decision is genuinely important. Use this concrete matrix.

| Dimension | Lambda | ECS (Fargate) | EKS (Auto Mode) | EC2 (Graviton4 + ASG) |
|-----------|--------|---------------|-----------------|------------------------|
| **Ops overhead** | Lowest | Low | Medium | Highest |
| **Time to first request** | Minutes | Minutes | Hours (first cluster) | Hours to days |
| **Cold start** | 100ms-3s (SnapStart helps Java/Python/.NET/Node) | None (warm always) | None | None |
| **Max execution** | 15 min | Unbounded | Unbounded | Unbounded |
| **Memory** | 128 MB - 10 GB | 0.25-120 GB (Fargate); larger on EC2 launch type | Pod-defined, up to instance limits | Up to 24 TB (x2iezn) |
| **Concurrency model** | Function-level concurrency limits | Task count, ALB / Service Connect | Pod count, HPA, Karpenter scaling | Instances + Auto Scaling Group |
| **Cost shape** | Per ms × MB-second | Per vCPU-second + GB-second | Pod resources × hours + $0.10/hr control plane | Per instance-hour |
| **Pricing efficiency at scale** | Worst at very high RPS sustained | Good with Savings Plans | Best with right-sizing + Spot | Best with RIs / 3yr Savings Plans |
| **Networking** | Optional VPC attach (cold-start penalty was retired) | VPC-native | VPC-native, CNI | VPC-native |
| **Stateful** | No (use EFS for shared state, but watch the limits) | Possible with EBS attach | Stateful sets work | Yes, full control |
| **Hybrid / on-prem** | No | No | Yes (EKS Hybrid Nodes) | Yes (Outposts, Snow family) |
| **Best for** | Event-driven, spiky, short-lived, glue logic | "Ship a container to HTTPS", microservices, batch | K8s-ecosystem workloads, multi-cloud portability stance, ML/GPU | Databases, message brokers, anything needing kernel/OS control |

**Decision heuristic:**
1. If the workload is event-driven and each invocation is <15min: **Lambda**.
2. If the team writes containers and wants minimal AWS-specific lock-in but doesn't need K8s ecosystem: **ECS Express Mode → ECS+Fargate**.
3. If the team is K8s-native, runs Helm charts, needs operators (Argo, Istio, GPU): **EKS Auto Mode**.
4. If the workload needs full OS/kernel control, or is a database/broker that AWS doesn't manage for you: **EC2 (Graviton4)** with ASG + Savings Plans.

Where teams *flip-flop*: starting with Lambda, hitting cold-start or unit-economics walls, "migrating to ECS," then "we should have done EKS." The reverse also happens: starting with EKS for a 5-person team that genuinely needed Lambda + a queue. **Make the call up front based on workload shape, not team fashion.**

## Serverless vs containers — beyond the religion

A modern AWS architecture mixes both. Recognize the shape:

- **Serverless (Lambda + API Gateway + DynamoDB + EventBridge + Step Functions)** wins when traffic is spiky, work is short, and the team values not having capacity planning. The "scale to zero" line item matters when you have many low-traffic services.
- **Containers (ECS/EKS + RDS/Aurora + Fargate)** win when traffic is sustained and predictable, when cold start is unacceptable, when workloads need specific language runtimes/libraries Lambda doesn't support (or supports awkwardly), or when you want one deployment model for a heterogeneous service portfolio.
- **The mixed pattern**: Lambda + API Gateway for the front door; ECS/EKS for sustained compute (e.g., the GraphQL resolver layer or a recommender service); EC2 only for things AWS doesn't manage. This is the modal 2026 AWS architecture.

If you find yourself defaulting one way for ideology rather than workload fit, audit it.

## Multi-region — when and how

Multi-region is not a default. It costs real money (replication, cross-region data transfer, operational complexity), and many teams claim multi-region resilience without having tested cutover. Use these tiers:

### Tier 0: Single-region, multi-AZ
Default. Three AZs in one region. RDS Multi-AZ, ASG across AZs, ALB cross-zone load balancing. RPO=0, RTO seconds-to-minutes for AZ failure. **Most workloads do not need more than this.**

### Tier 1: Active-passive across regions, manual failover
Backup region with replicated data (DynamoDB Global Tables, RDS read replicas, S3 CRR, ECR replication). Application infrastructure provisioned but cold; Route 53 health checks + manual DNS cutover. RPO seconds-to-minutes, RTO minutes-to-hours.

### Tier 2: Active-active read, active-passive write
Read traffic served from nearest region (Aurora Global Database, DynamoDB Global Tables). Writes funnel to primary region. Failover involves promoting a secondary's writer. RPO seconds, RTO minutes.

### Tier 3: Active-active multi-region
**Aurora DSQL** (GA May 2025) makes this finally tractable for relational workloads — 99.999% multi-region active-active, Postgres-compatible. DynamoDB Global Tables give you multi-region active-active KV. **Application logic must handle cross-region read-your-writes anomalies** — DSQL provides strong consistency but cross-region writes still carry the speed-of-light latency floor. RPO=0 effectively, RTO seconds.

**The call:** start Tier 0. Move to Tier 1 when a regulatory or contractual RTO/RPO demands it. Tier 2/3 when the business case (revenue impact of region outage × probability) justifies the operational complexity. Don't sell Tier 3 to a startup just because it's possible.

### us-east-1 has bad gravity

Every major multi-region failure of the last decade has started, peaked, or been exacerbated in us-east-1. It's the cheapest, has every service first, and is the highest-risk single region. For new architectures without us-east-1-specific dependencies (e.g., CloudFront origin needs, marketplace tools rooted there, Organizations management account in us-east-1), **default to us-east-2 or us-west-2 as primary** and replicate to us-east-1 if needed.

## Multi-account topology — the upstream decision

Account topology is the most consequential upstream AWS architecture decision. Hard to undo. Defaults:

```
Management Account (billing + SCPs only — NO workloads)
  |
  +-- Security OU
  |     +-- Log Archive  (centralized CloudTrail, Config, VPC Flow Logs, S3 + KMS keys with retain policies)
  |     +-- Security Tooling  (Security Hub, GuardDuty, Inspector, Macie delegated admin)
  |
  +-- Infrastructure OU
  |     +-- Networking  (Transit Gateway, Direct Connect, Route 53 private hosted zones, centralized firewalls)
  |     +-- Shared Services  (CI/CD, ECR, artifact repos, AD/Identity)
  |
  +-- Workloads OU
  |     +-- Dev Account(s)
  |     +-- Staging Account(s)
  |     +-- Production Account(s)
  |
  +-- Sandbox OU  (budget-capped developer experimentation accounts)
  |
  +-- Suspended OU  (accounts being decommissioned; deny-all SCP attached)
```

**Account vending via Control Tower Account Factory** (or Customizations for Control Tower / Account Factory for Terraform). Bootstrap each new account with:
- CloudTrail + Config + VPC Flow Logs centralized to Log Archive
- GuardDuty + Inspector + Security Hub enabled
- IAM Identity Center permission sets attached
- VPC with private subnets + endpoints (no NAT unless explicitly needed)
- Default SCPs deny: leave organization, disable CloudTrail, S3 public access, IMDSv1
- AWS Budgets with per-environment thresholds

**Anti-pattern: putting workloads in the management account.** The management account is for billing + SCPs only. No EC2, no Lambda, no S3 buckets containing customer data. Compromise of the management account = compromise of everything; defense-in-depth requires isolation.

**Anti-pattern: one account for all environments.** "Dev, staging, prod tags in one account" is how blast radius becomes the whole company. Separate accounts per environment is the cheapest, most effective isolation AWS offers.

**Anti-pattern: spinning up accounts ad hoc without Control Tower.** Without account factory baselines, security baseline drift becomes inevitable. Force account creation through Control Tower or a Terraform-equivalent factory.

## Event-driven vs request-response — pick by SLA shape

When the team asks "what's our communication pattern," map it to SLA:

| Pattern | When | AWS shape |
|---------|------|-----------|
| **Synchronous request-response** | Caller blocks for result; user-facing latency-bound | API Gateway → Lambda or ECS/EKS service; gRPC for service-to-service |
| **Async fire-and-forget** | Caller doesn't need the result; eventual consistency tolerated | SQS standard queue → Lambda or ECS consumer |
| **Async with delivery ordering + replay** | Need order within partition + reprocess capability | Kinesis Data Streams or MSK (Kafka) |
| **Event broadcast (fan-out)** | Many consumers need each event | SNS or EventBridge (rules + targets) |
| **Event routing across accounts/orgs** | Cross-account, cross-region event flow | EventBridge with cross-account event bus targets |
| **Workflow orchestration** | Multi-step with state, retries, compensation | Step Functions (Standard for long-running; Express for high-throughput short workflows) |
| **CDC** | Database changes propagated to downstream | DynamoDB Streams → EventBridge Pipes → target; Aurora CDC via DMS or zero-ETL |

EventBridge Pipes (re:Invent 2022, mature now) eliminates Lambda-as-glue for the common "source → filter → enrich → target" pattern. If the team's writing a Lambda that just maps SQS to Step Functions or DynamoDB Streams to EventBridge, replace it with a Pipe.

## Step Functions: when to reach for it

Step Functions is the workflow engine. Reach for it when:

- The workflow has **state** that must persist across steps.
- There's **branching logic** with explicit error compensation.
- You need **human approval** in the loop (Step Functions wait-for-callback pattern with a task token).
- Multiple AWS services participate and you don't want to write the orchestration in code (Step Functions has 200+ optimized SDK integrations — no Lambda glue).
- The workflow could take hours, days, or weeks (Standard workflows: 1-year max execution).

Don't reach for Step Functions when:
- The workflow is two Lambda invocations chained. Just chain them.
- High-throughput, short-duration (>50 RPS sustained, <1s execution) — Express workflows fit, but evaluate whether SQS+Lambda fan-in is simpler.

**JSONata + Variables (re:Invent 2024)** replaced ResultPath/InputPath/OutputPath/Parameters for state input/output manipulation. Start new state machines with JSONata; migrate older ones opportunistically.

## API Gateway vs AppSync vs Lambda URLs vs ALB

When the front door is HTTP:

| Choice | Use when | Avoid when |
|--------|----------|------------|
| **API Gateway HTTP API** | Simple REST/HTTP, JWT auth, cheap | You need WAF integration (HTTP API supports WAF via CloudFront, but REST API has native), API key plans, request validation |
| **API Gateway REST API** | Full API management — keys, usage plans, request/response transformation, WAF, models, SDKs | Cost matters at scale (REST is ~3.5x cost of HTTP API) |
| **API Gateway WebSocket API** | Bidirectional WebSocket connections | HTTP-only workloads |
| **AppSync** | GraphQL — schema-first, subscriptions, multi-source (DynamoDB + Lambda + RDS + HTTP) | Pure REST, or workloads that don't want a GraphQL learning curve |
| **Lambda URLs** | Internal endpoints, webhooks, no API mgmt features needed, IAM or no auth | Anything external-facing that needs throttling, API keys, WAF |
| **ALB + Lambda target** | Existing ALB infrastructure, want the same load balancer for containers + Lambda | New build with no existing ALB |
| **ECS/EKS service behind ALB** | Sustained traffic, longer execution, containers | Spiky traffic where Lambda concurrency math wins |

Default for new public APIs in 2026: **API Gateway HTTP API + Lambda + Cognito or JWT authorizer**. Upgrade to REST API if you need request validation models, usage plans, or full API key management. Use AppSync if the team already speaks GraphQL.

## When AWS is *not* the answer

A system-architect's job includes saying "AWS isn't the right primary platform here." Cases:

- **The team has zero cloud experience and the workload is small.** Vercel/Netlify/Render/Fly.io handle the 80% case with less ops cognitive load. AWS becomes the right answer when you've outgrown those.
- **Single-region B2B SaaS with a small ops team.** Heroku, Render, Fly.io, Railway can be cheaper TCO. AWS wins when you need the depth of service portfolio or compliance posture.
- **Frontend-only application.** Cloudflare Pages / Vercel / Netlify usually beat S3+CloudFront on developer experience even though the underlying cost is similar.
- **A specific vendor's specialized service is materially better** — Snowflake for analytics SQL (vs Redshift), Databricks for Spark+ML (vs Glue+EMR+SageMaker), Stripe for billing (vs the Marketplace Metering API), Auth0/Clerk/WorkOS for auth (vs Cognito) — pick the specialist and integrate.
- **AWS GovCloud unavailable for the customer's region.** The actual customer requirement (e.g., EU sovereign cloud, India data residency) may push you to Azure / GCP / OCI regions or local sovereign clouds.

If the team is on AWS by inertia and the architecture would be materially better elsewhere, say so. "AWS, because we're an AWS shop" is not a system-architecture argument.

## Well-Architected: the six pillars as a framing tool

Use the Well-Architected Framework as your structured-review prompt, not a checklist:

1. **Operational Excellence** — Can the team run this? Runbooks, observability, deployment, rollback, post-incident review hooks. "How would on-call know something's wrong at 3am?"
2. **Security** — IAM, network, data protection, incident response, app security. **The pillar that subsumes most others when violated.**
3. **Reliability** — Multi-AZ, multi-region, backup/restore tested, failure-mode analysis. Distinct from availability; reliability is "behaves correctly under failure," not just "stays up."
4. **Performance Efficiency** — Right primitive (see compute matrix), right instance family, scaling shape, edge optimization.
5. **Cost Optimization** — Right-sized, baseline committed, Spot where eligible, storage tiered, tagged for attribution. "Per-tenant" or "per-transaction" cost is the unit economics view.
6. **Sustainability** — Graviton, region selection, off-peak workload shifting, model efficiency. The newest pillar; quantify with Customer Carbon Footprint tool.

For complex architectures (>10 services, multi-region, regulated industry), schedule a formal Well-Architected Review with AWS Solutions Architect — it's free if your account is supported, and you get credits for remediating findings.

### AI/ML Lenses (re:Invent 2025)

Three Well-Architected lenses specifically for AI/ML workloads:

- **Responsible AI Lens (NEW)**: ten dimensions — controllability, privacy, security, safety, veracity, robustness, fairness, explainability, transparency, governance. Use this when designing any user-facing AI feature, not just model training.
- **Machine Learning Lens (updated)**: aligned with the six-stage ML lifecycle (problem definition, data prep, model dev, deployment, ops, monitoring). SageMaker AI Studio is the canonical platform reference.
- **Generative AI Lens (updated)**: intelligent assistants, content generation, enterprise copilots. Sustainability emphasis on training/inference compute.

If the design involves Bedrock + AgentCore, run it through the Responsible AI Lens before launch — and route deep agent design to `ai-ml-engineer` with this pack.

## Cost as a non-functional requirement

A 2026 AWS architecture without a cost model is incomplete. Mandatory artifacts:

1. **Pricing Calculator estimate** for greenfield, or **Cost Explorer baseline** for migration. Treat as a design constraint, not an afterthought.
2. **Cost-allocation tagging strategy** enforced via SCPs and AWS Config. Minimum tags: `Environment`, `Owner`, `CostCenter`, `Application`, `Tier`. Tag policies in Organizations to enforce.
3. **Budgets with alerts** per account, per environment, per workload tag. CloudWatch Cost Anomaly Detection on the master payer.
4. **Right-sizing review cadence** — Compute Optimizer recommendations reviewed monthly; Cost Explorer reservations + Savings Plans review quarterly.
5. **Unit economics target** — cost-per-tenant, cost-per-transaction, cost-per-user — not just absolute spend. SaaS workloads especially.

The cost optimization hierarchy:

```
1. Right-size first
   - Compute Optimizer recommendations (ML-powered)
   - Migrate to Graviton (20-40% savings, mostly drop-in for Linux)
   |
2. Commit baseline
   - 1yr Compute Savings Plans (66% discount, broadest coverage: EC2 + Fargate + Lambda)
   - 3yr EC2 Instance Savings Plans for predictable workloads (72%)
   |
3. Use Spot for eligible workloads
   - Batch, CI/CD, EKS workers (Karpenter), EMR, rendering (up to 90%)
   - Mixed instance policies, capacity-optimized allocation
   |
4. Architect for serverless where unit economics flip
   - Lambda, Fargate, Aurora Serverless v2 (or DSQL), DynamoDB on-demand
   |
5. Storage tiering
   - S3 Intelligent-Tiering (no retrieval cost surprises)
   - gp3 over gp2 (20% cheaper baseline, 4x IOPS)
   - S3 Glacier Instant/Flexible/Deep via S3 lifecycle, NOT Glacier vault APIs
   |
6. Monitor continuously
   - Cost Explorer, Budgets, Trusted Advisor, Cost Anomaly Detection
   - CUR + Athena for custom queries; CUR 2.0 for the modern schema
```

## Integration boundaries — what stays on AWS, what leaves

Decide deliberately:

- **Stays on AWS when:** workload benefits from tight integration with AWS-managed services (IAM, KMS, VPC, CloudWatch, S3); team has AWS expertise; data gravity is on AWS; regulatory posture requires the AWS BAA / compliance certifications.
- **Leaves AWS when:** a specialist SaaS materially outperforms (Snowflake, Databricks, Stripe, Algolia, Cloudflare Workers, Auth0); the workload has cross-cloud / hybrid requirements; the team's existing investment is elsewhere.
- **Boundary technology:** API Gateway / AppSync as inbound front door; EventBridge for outbound event integration (third-party SaaS event partners); Direct Connect / VPN for hybrid; Transit Gateway / VPC Lattice for cross-VPC; PrivateLink for service-as-a-service across accounts; Secrets Manager + cross-account KMS for shared credentials.

When the architecture spans AWS + Salesforce or AWS + Snowflake, check the corresponding stack pack — both packs load and own their sides of the integration.

## Anti-patterns specific to AWS architecture

- **"NAT Gateway in every AZ for everything."** $0.045/hr × 3 AZs + data processing + cross-AZ traffic = $100s/month minimum, $1000s/month routinely. If outbound internet isn't needed, **don't have one.** VPC endpoints (interface for most services, gateway for S3 and DynamoDB) cost less and keep traffic on AWS backbone.
- **"Everything in us-east-1 because that's where the docs default."** us-east-1 has bad gravity. New architectures: pick primary deliberately.
- **"We'll add multi-region later."** Multi-region is an architectural pattern, not a feature flag. Adding it later costs more than building it in — but building Tier 3 for a workload that needs Tier 0 is wasted effort. Decide the tier up front.
- **"Lambda for everything, scale to zero saves money."** Until you hit 100 RPS sustained and the per-invocation pricing dominates a Fargate task's hourly cost. Math it out: a Lambda at 100 RPS, 200ms p50, 256MB ≈ $750/mo just for Lambda compute (excluding API Gateway). A Fargate task running 24/7 at 0.25 vCPU + 0.5 GB ≈ $9/mo. Cross-over point varies, but it's not infinite.
- **"EKS because we want Kubernetes."** EKS adds an operational tax. If the team isn't already running K8s elsewhere and the workload doesn't need K8s-ecosystem tooling (Argo, Helm, GPU operators, Istio), pick ECS Express Mode and save 3-6 months of platform plumbing.
- **"Single AWS account because it's simpler."** It's simpler until something breaks. Blast radius isolation, IAM scoping, cost attribution, and regulatory boundary all push toward multi-account. Use Control Tower from day one.
- **"We'll just use IAM users for service accounts."** Long-lived access keys are a leak waiting to happen. Use IAM roles + IRSA (on EKS) or EKS Pod Identity for pod-level; Lambda execution roles; ECS task roles; EC2 instance profiles; **IAM Identity Center** for humans. Never `aws_access_key_id` in a config file in 2026.
- **"Copilot CLI / App Runner for new deployment."** Both are sunset paths — Copilot CLI EOL June 2026, App Runner in maintenance. Use ECS Express Mode for "ship a container to HTTPS in one step," CDK or Terraform for everything else.
- **"Glacier API for archives."** Use S3 Glacier *storage classes* via S3 API. Glacier vault APIs (`glacier:*`) are retirement track.
- **"Aurora Serverless v1 for new workloads."** EOL Dec 2024. Use Aurora Serverless v2 or Aurora DSQL.
- **"CDK v1 because we have it."** Fully EOL. Migration is non-trivial but mandatory. Plan it; don't wait for it to break.
- **"`re:Invent announcement = available.`"** Confirm GA status and regional availability before designing around an announcement. Some announcements take 12+ months to ship.

## Verification checklist for system-architect on AWS

Before declaring the architecture done, prove:

- [ ] Each major capability mapped to a specific compute/data/network/identity primitive with explicit reasoning — not "because Lambda is cool" or "we always use EKS."
- [ ] Quota check: state default quotas for every service in the critical path, the request rate the design implies, and whether a Service Quota increase is needed before launch.
- [ ] Account topology documented: management, security OU, infrastructure OU, workloads OU per environment. Control Tower or equivalent factory specified.
- [ ] Region selection deliberate (not just us-east-1), with rationale for cost/compliance/latency/blast-radius.
- [ ] Multi-AZ at minimum; multi-region tier (0/1/2/3) explicitly chosen, with RPO/RTO target named.
- [ ] IAM strategy: Identity Center for humans, permission boundaries for app-team-created roles, least-privilege via Access Analyzer policy generation, no IAM users for service accounts.
- [ ] Cost model: Pricing Calculator estimate, tagging strategy, budgets, unit-economics target.
- [ ] Observability strategy: CloudWatch + Application Signals + X-Ray + OTel, log retention policies set (not "Never Expire").
- [ ] Compliance posture explicit when applicable: HIPAA BAA scope, PCI DSS scope, FedRAMP / GovCloud requirement, EU data residency.
- [ ] No legacy paths: no Copilot CLI for new pipelines, no App Runner for new services, no Aurora Serverless v1, no CDK v1, no Salesforce Functions, no Heroku Enterprise, no AL2 AMIs.
- [ ] Composition: if other stacks involved (Salesforce, Snowflake, Stripe), their boundaries and ownership specified.
- [ ] Currency check: every announced feature recommended is GA in the target region, not just "announced."

## Escalation map

| If the request becomes about... | Hand off to |
|---------------------------------|-------------|
| Writing the actual Lambda / ECS / Step Functions / EventBridge code | `backend-architect` with this pack |
| Designing the actual DynamoDB / Aurora / OpenSearch schema + queries | `database-architect` with this pack |
| CDK / CodePipeline / Karpenter pipeline plumbing | `devops-engineer` with this pack |
| IAM + KMS + GuardDuty deep posture | `security-engineer` with this pack |
| SLOs, alarms, OTel pipelines, on-call runbooks | `sre-engineer` with this pack |
| Bedrock + AgentCore + Strands + RAG + SageMaker | `ai-ml-engineer` with this pack |
| ISV / multi-tenant SaaS on AWS | `saas-architect` with this pack |
| Healthcare/HIPAA workloads (compliance semantics) | `healthcare-architect` (vertical) + this pack |
| Fintech workloads (compliance semantics, ledger) | `fintech-architect` (vertical) + this pack |
| Architecture beyond AWS (other cloud, on-prem only) | `system-architect` without the pack overlay |

## Working with the always-on protocols on AWS

- **TDD on AWS**: tests run before infrastructure deploys. CDK assertions (`aws-cdk-lib/assertions`) for the IaC layer; `moto` / `aws-sdk-client-mock` for SDK-touching code; LocalStack for offline integration (when accuracy is sufficient). Don't `cdk deploy` your way to "it works."
- **Verification on AWS**: claims about service availability, quotas, retirement dates must cite the AWS docs URL or the What's New page. "I think Lambda supports X" is not verification; the docs page that says so is.
- **Debugging on AWS**: CloudTrail is the audit truth; CloudWatch Logs is the runtime truth; X-Ray is the request-flow truth. Reproduce locally where possible (SAM local invoke, LocalStack); otherwise deploy to a dev account and capture logs/traces. Never debug in production unless production is the only environment showing the bug — and then with read-only access if at all possible.
- **Branch safety on AWS**: changes deploy via CDK + pipeline, not via `aws ...` CLI. Production deploys go through a green-tests pipeline with manual approval for the high-blast-radius stages.
