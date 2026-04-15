# AWS Cloud Engineering — Deep Reference

**Always use `WebSearch` to verify version numbers, pricing, service limits, and features before giving advice. AWS evolves rapidly; this reference provides architectural context and decision frameworks current as of early 2026.**

## Table of Contents
1. [Compute Selection](#1-compute-selection)
2. [Networking](#2-networking)
3. [Storage](#3-storage)
4. [Databases](#4-databases)
5. [Security and IAM](#5-security-and-iam)
6. [Serverless](#6-serverless)
7. [Containers](#7-containers)
8. [Infrastructure as Code](#8-infrastructure-as-code)
9. [Observability](#9-observability)
10. [Cost Optimization](#10-cost-optimization)
11. [Well-Architected Framework](#11-well-architected-framework)
12. [AI/ML Infrastructure](#12-aiml-infrastructure)
13. [Multi-Account Strategy](#13-multi-account-strategy)

---

## 1. Compute Selection

### Graviton4 Instance Families (8th Generation)

| Family | Use Case | Max Size | Key Advantage |
|--------|----------|----------|---------------|
| **C8g/C8gb** | Compute-intensive | 48xlarge | 30% better perf vs Graviton3 |
| **M8g/M8gn/M8gb** | General-purpose | 48xlarge | Balanced compute/memory, enhanced networking |
| **R8g/R8gd** | Memory-intensive | 48xlarge, 1.5 TB RAM | 3x more vCPU than R7g |
| **I8g** | Storage-intensive | -- | NVMe local storage |
| **X8g** | In-memory (SAP, etc.) | -- | Largest memory footprint |

**Graviton5 (9th-gen, preview Dec 2025):**
- Up to 192 cores per chip, 5x larger L3 cache
- M9g in preview: 25% better compute, 30% faster databases vs M8g
- C9g and R9g planned for 2026

**Migration guidance:** Graviton is the single most impactful cost optimization lever on AWS (20-40% savings). Most Linux workloads run unmodified on ARM. Test with `aarch64` container images. Exceptions: x86 assembly, Windows-only software, ISV licensing tied to x86.

### AI/ML Instances

| Chip | Instance | Use Case | Key Metric |
|------|----------|----------|------------|
| **Trainium3** (3nm) | Trn3 UltraServers (up to 144 chips) | Training | 4.4x perf vs Trn2, 4x energy efficiency |
| **Trainium2** | Trn2/Trn2n | Training/Inference | 30-40% better price-perf vs GPUs |
| **Inferentia2** | Inf2 | Inference | Cost-optimized (de-emphasized for GenAI) |
| **NVIDIA H200** | P5en | Training/Inference | Current-gen GPU |
| **NVIDIA Blackwell B200** | P6-B200 | Training | ParallelCluster 3.14+ |
| **NVIDIA GB200 NVL72** | P6e-GB200 UltraServers | Training | 72 GPUs via NVLink |

### Compute Decision Matrix

| Workload | Recommended Service | Why |
|----------|-------------------|-----|
| Stateless web API, <15 min | Lambda | Zero ops, pay-per-invocation |
| Stateless web API, quick deploy | ECS Express Mode | Image to HTTPS in seconds, no infra config |
| Container microservices, team owns K8s | EKS Auto Mode | Managed K8s, auto compute/networking/storage |
| Long-running stateful (databases, queues) | EC2 (Graviton4) + ASG | Full control, Reserved/Savings Plans |
| Batch/ML training | EC2 Spot + Graviton4/Trn2 | Up to 90% savings |
| GPU inference | Inf2 / Trn2 | Custom silicon, best price-perf |
| HPC clusters | ParallelCluster 3.15 | Slurm 25.11, Blackwell support, EFA |

### ECS Express Mode (Nov 2025)

Replaces AWS Copilot CLI (end-of-support June 2026) and App Runner (maintenance mode). Auto-provisions Fargate service, ALB with TLS, auto-scaling, monitoring, networking.

```bash
# Deploy a container to production in one step
aws ecs create-service \
  --cluster default \
  --service-name my-api \
  --launch-type FARGATE \
  --express-mode-config enabled=true \
  --task-definition my-api:1
```

No additional charge beyond standard Fargate/ALB pricing. Available in all ECS+Fargate regions.

### EKS Auto Mode

Launched re:Invent 2024, GA in all commercial regions plus GovCloud. Fully managed compute, networking, and storage with a single API call.

```bash
aws eks update-cluster-config \
  --name my-cluster \
  --compute-config enabled=true,nodePools=["system","general-purpose"] \
  --kubernetes-network-config '{"elasticLoadBalancing":{"enabled":true}}' \
  --storage-config '{"blockStorage":{"enabled":true}}'
```

2025-2026 enhancements:
- EC2 capacity reservation support for guaranteed GPU access
- AWS KMS encryption for ephemeral and root storage volumes
- Enhanced logging via CloudWatch Vended Logs (Feb 2026)
- Open-sourced Node Monitoring Agent for infrastructure health
- Requires Kubernetes 1.29+

---

## 2. Networking

### VPC Design Patterns

| Pattern | When to Use | Key Services |
|---------|------------|--------------|
| **Single VPC** | Small teams, single app | VPC, subnets, NACLs |
| **Hub-and-spoke** | Multi-account, shared services | Transit Gateway, RAM |
| **Service mesh** | Microservices cross-VPC/account | VPC Lattice |
| **Hybrid** | On-prem + AWS | Transit Gateway + Direct Connect/VPN |

### VPC Lattice

Application-layer (L7) networking for service-to-service communication across VPCs and accounts. Supports HTTP/HTTPS, gRPC, TLS, TCP. Built-in IAM auth policies for zero-trust.

2025-2026 updates:
- Custom domain names for resource configurations (Nov 2025)
- Configurable IP addresses for Resource Gateway ENIs (Oct 2025)
- IPv6 dual-stack management API (Aug 2025)
- Native ECS/Fargate, EC2, EKS, and Lambda integration

### Transit Gateway vs VPC Lattice

| Feature | Transit Gateway | VPC Lattice |
|---------|----------------|-------------|
| **Layer** | L3/L4 (IP routing) | L7 (application) |
| **Use case** | VPC-to-VPC routing, hybrid | Service-to-service networking |
| **Auth** | Security groups, NACLs | IAM auth policies (zero trust) |
| **Protocol** | Any IP traffic | HTTP/HTTPS, gRPC, TLS, TCP |
| **Observability** | Flow logs | Access logs, CloudWatch metrics |
| **Cost model** | Per attachment + data | Per request + data |

### Route 53 Updates (2025-2026)

- **Route 53 Profiles**: Simplifies multi-VPC DNS management, replaces complex TGW + Resolver patterns
- Route 53 DNS service supports PrivateLink (Nov 2025)
- Route 53 Profiles supports PrivateLink (Oct 2025)
- Centralized PrivateLink: endpoints in Shared Services VPC, spoke access via Transit Gateway

### CloudFront and Global Accelerator

| Feature | CloudFront | Global Accelerator |
|---------|-----------|-------------------|
| **Type** | CDN (caches content) | Network routing (no caching) |
| **IPv6** | Full support + BYOIP (Mar 2026) | Not supported |
| **Protocol** | HTTP/HTTPS | TCP/UDP |
| **Edge locations** | 225+ PoPs | AWS backbone routing |
| **Static IPs** | Anycast static IPs available | 2 static Anycast IPs per accelerator |
| **Use case** | Web content, APIs, streaming | Non-HTTP (gaming, IoT), TCP acceleration |

CloudFront 2025-2026:
- IPv6 origins for end-to-end dual-stack delivery (Sep 2025)
- BYOIP for IPv6 via VPC IPAM integration (Mar 2026)

### Edge Compute Comparison

| Feature | CloudFront Functions | Lambda@Edge |
|---------|---------------------|-------------|
| **Runtime** | JavaScript | Node.js, Python |
| **Max execution** | <1 ms | 5s (viewer) / 30s (origin) |
| **Memory** | 2 MB | 128 MB - 3 GB |
| **Package size** | 10 KB | 1-50 MB |
| **Network access** | No | Yes |
| **Scale** | 10M+ RPS | 10K RPS per Region |
| **Triggers** | Viewer request/response only | Viewer + origin request/response |
| **Use case** | URL rewrites, header manipulation | Auth, origin selection, A/B testing |

---

## 3. Storage

### S3 Feature Matrix

| Feature | Standard | Express One Zone | S3 Tables |
|---------|----------|-----------------|-----------|
| **Latency** | ~100 ms | Single-digit ms | Iceberg-optimized |
| **Durability** | 99.999999999% | 99.95% (single AZ) | Managed |
| **Use case** | General storage | Hot data, caching, ML staging | Analytics (Apache Iceberg) |
| **Conditional writes** | If-None-Match | If-None-Match + conditional deletes | N/A |
| **Pricing** | Lowest per GB | Higher per GB, lower per request | Query-based |

S3 Express One Zone 2025-2026:
- Conditional deletes via `x-amz-if-match-last-modified-time`, `x-amz-if-match-size`, `If-Match` headers
- CloudWatch request metrics (Mar 2026)
- 10x faster writes vs standard S3

S3 Tables: Fully managed Apache Iceberg tables. S3 Storage Lens auto-exports metrics to S3 Tables for immediate querying.

### S3 Conditional Writes Example

```bash
# Upload only if the object does not already exist
aws s3api put-object \
  --bucket my-bucket \
  --key config.json \
  --body config.json \
  --if-none-match "*"

# Enforce conditional writes across the entire bucket
aws s3api put-bucket-policy \
  --bucket my-bucket \
  --policy '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Deny",
      "Principal":"*",
      "Action":"s3:PutObject",
      "Resource":"arn:aws:s3:::my-bucket/*",
      "Condition":{"StringNotEquals":{"s3:if-none-match":"*"}}
    }]
  }'
```

### EBS Volume Types

| Type | Max IOPS | Max Throughput | Max Size | Use Case |
|------|----------|---------------|----------|----------|
| **gp3** | 80,000 | 2 GiB/s | 64 TiB | Default for most workloads |
| **io2 Block Express** | 256,000 | 4 GiB/s | 64 TiB | Databases, latency-critical |
| **st1** | 500 | 500 MiB/s | 16 TiB | Sequential throughput (logs, data lakes) |
| **sc1** | 250 | 250 MiB/s | 16 TiB | Cold data, infrequent access |

gp3 improvements (2025): 4x max capacity (16 to 64 TiB), 5x max IOPS (16K to 80K), 2x throughput (1 to 2 GiB/s). IOPS/throughput decoupled from capacity.

io2 Block Express: 99.999% durability, SRD protocol (same as EFA). GA in all commercial + GovCloud regions (Jul 2025). Provisioned Rate for Volume Initialization: specify completion from 15 min to 48 hours for DR scenarios.

### File Storage

| Service | Protocol | Use Case | Scaling |
|---------|----------|----------|---------|
| **EFS** | NFS 4.1 | Shared Linux storage | Auto-scale, mount across AZs |
| **FSx for Lustre** | Lustre | HPC, ML training | Sub-ms latency, S3 integration |
| **FSx for NetApp ONTAP** | NFS, SMB, iSCSI | Multi-protocol enterprise | Auto data tiering |
| **FSx for Windows** | SMB | Windows workloads | Active Directory integration |

---

## 4. Databases

### Database Selection Matrix

| Workload | Service | Key Feature |
|----------|---------|-------------|
| General OLTP (PostgreSQL/MySQL) | **Aurora Serverless v2** | Auto-scale 0.5-256 ACUs, multi-AZ |
| Distributed SQL, multi-region | **Aurora DSQL** | 99.999% multi-region active-active |
| Horizontal write scaling | **Aurora Limitless** | Millions of write TPS, petabyte scale |
| Key-value, <10 ms | **DynamoDB** | Serverless, zero-ETL to OpenSearch/Redshift |
| Caching (<1 ms) | **ElastiCache (Valkey)** | 33% cheaper than Redis OSS engine |
| Durable in-memory, multi-region | **MemoryDB** | 99.999% avail, microsecond reads |
| Legacy Oracle/SQL Server | **RDS** | Blue-green deployments, Extended Support |

### Aurora DSQL

Serverless distributed SQL (PostgreSQL-compatible). Announced re:Invent 2024.
- 99.99% single-region, 99.999% multi-region active-active
- Horizontal scaling, connection management, scale-to-zero
- Express configuration: database ready in seconds with two clicks (Mar 2026)

### Aurora Limitless Database

Automated horizontal scaling for Aurora PostgreSQL:
- Millions of write transactions per second
- Petabyte-scale data management
- Operates as a single database -- no application-level sharding needed

### RDS Updates (2025-2026)

- Blue-green deployments support Aurora Global Database (Nov 2025)
- Multi-AZ DB clusters: one writer + two readers across 3 AZs
- Extended Support: continue running EOL engine versions (per-vCPU-hour fee)
- Aurora Serverless v1 EOL Dec 2024 (migrate to v2)

### ElastiCache and MemoryDB

```bash
# Create ElastiCache Serverless with Valkey engine
aws elasticache create-serverless-cache \
  --serverless-cache-name my-cache \
  --engine valkey \
  --major-engine-version 7.2
```

**Valkey 7.2 pricing advantage:** 33% lower Serverless pricing, 20% lower node-based pricing vs Redis OSS engine. Blue/green migration from Redis OSS to Valkey is a managed in-place upgrade.

**ElastiCache Multi-AZ:** 99.99% availability with automatic failover.

**MemoryDB Multi-Region:** Active-active replication, microsecond reads, single-digit ms writes, 99.999% availability.

### DynamoDB Zero-ETL Integrations

```python
# CDK: DynamoDB table with zero-ETL to OpenSearch
from aws_cdk import aws_dynamodb as dynamodb

table = dynamodb.Table(self, "Orders",
    partition_key=dynamodb.Attribute(name="pk", type=dynamodb.AttributeType.STRING),
    sort_key=dynamodb.Attribute(name="sk", type=dynamodb.AttributeType.STRING),
    point_in_time_recovery=True,  # Required for zero-ETL export
    stream=dynamodb.StreamViewType.NEW_AND_OLD_IMAGES,  # Required for real-time sync
)
```

- Zero-ETL to OpenSearch: full-text search, fuzzy search, vector search on DynamoDB data
- Zero-ETL to Redshift: analytics without ETL pipelines
- Uses DynamoDB export to S3 (PITR required) + Streams for near real-time sync
- No impact on table read/write throughput

---

## 5. Security and IAM

### Defense-in-Depth Architecture

```
Organizations (SCPs) -- org-wide guardrails
  |
IAM Identity Center (SSO) -- centralized human access
  |
Permission Boundaries -- max permissions cap for delegated IAM
  |
IAM Policies + Resource Policies -- least privilege
  |
Access Analyzer -- detect unused/external access, generate least-privilege policies
  |
Security Hub -- aggregate findings from GuardDuty + Inspector + Macie
  |
KMS + CloudTrail -- encryption + audit trail
```

### Security Hub (Upgraded re:Invent 2025)

- Near real-time risk analytics, unified security operations
- Auto-aggregation across GuardDuty, Inspector, Macie, CSPM
- Up to 1 year of historical trend data, period-over-period analysis
- Cross-region aggregation, severity-based filtering
- Deployment coverage visibility across accounts/regions

### GuardDuty Extended Threat Detection

- Attack sequence findings for EC2 instances and ECS tasks (2025)
- Existing: IAM credential misuse, S3 activity, EKS cluster compromise
- Unified multistage attack visibility across VMs, containers, and identity

### IAM Access Analyzer (2025-2026)

| Capability | What It Does |
|-----------|--------------|
| External access | Continuous monitoring of S3, KMS, SQS, Lambda, IAM for cross-account access |
| Unused access | Identify roles/policies with unexercised permissions |
| Policy generation | Generate least-privilege policies from CloudTrail activity |
| Policy validation | Check policies against IAM best practices |

### SCP Production Patterns

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeaveOrg",
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    },
    {
      "Sid": "DenyRootUser",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": { "aws:PrincipalArn": "arn:aws:iam::*:root" }
      }
    },
    {
      "Sid": "RequireIMDSv2",
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringNotEquals": { "ec2:MetadataHttpTokens": "required" }
      }
    },
    {
      "Sid": "DenyPublicS3",
      "Effect": "Deny",
      "Action": ["s3:PutBucketPublicAccessBlock"],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:publicAccessBlockConfiguration/BlockPublicAcls": "true"
        }
      }
    }
  ]
}
```

### Permission Boundaries

Define max permissions for delegated IAM. Prevent privilege escalation even if more permissive policies are attached. Essential for platform teams delegating IAM to application teams.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*", "dynamodb:*", "lambda:*", "logs:*", "sqs:*"],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": ["iam:*", "organizations:*", "account:*"],
      "Resource": "*"
    }
  ]
}
```

---

## 6. Serverless

### Lambda Limits and Configuration

| Setting | Limit | Notes |
|---------|-------|-------|
| Memory | 128 MB - 10,240 MB | CPU scales proportionally |
| Timeout | 15 minutes | Use Step Functions for longer |
| Ephemeral storage | 512 MB - 10 GB | SnapStart limited to 512 MB |
| Payload (sync) | 6 MB | Use S3 for larger payloads |
| Payload (async) | 256 KB | Use S3 reference pattern |
| Concurrency | 1,000 default (adjustable) | Request increase for production |
| Package size (zip) | 50 MB (250 MB unzipped) | Use layers or container images |
| Container image | 10 GB | Supports ECR images |

### Lambda SnapStart

Reduces cold starts to sub-second. Available for Java, Python (3.12+), and .NET 8 AOT.

**Constraints:** Incompatible with Provisioned Concurrency, EFS, ephemeral storage >512 MB, and container images.

**Priming strategies:**
- **Invoke Priming**: Execute critical endpoints during snapshot creation
- **Class Priming**: Preload classes without triggering business logic

### Lambda Web Adapter

Run existing web frameworks (Express, Flask, FastAPI, Spring Boot) on Lambda without code changes. Supports response streaming for improved TTFB.

```dockerfile
# Lambda Web Adapter with FastAPI
FROM public.ecr.aws/docker/library/python:3.12-slim
COPY --from=public.ecr.aws/awsguru/aws-lambda-web-adapter:0.8.4 /lambda-adapter /opt/extensions/
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Step Functions (2025-2026)

**JSONata support (re:Invent 2024):** Replaces complex ResultPath/InputPath chains. Supports string manipulation, date-time conversion, regex, math, array/object operations, aggregation. Version 2.0.6.

**Variables:** Assign data in one state, reference in any subsequent state. Incrementally adopt JSONata per state without upgrading entire state machine.

**HTTPS endpoints:** Direct API calls without Lambda glue. Use JSONata for payload transformation.

**TestState API (Mar 2026):** Test individual states in isolation or complete workflows before deploying to AWS.

### API Endpoint Decision Matrix

| Feature | API Gateway | Lambda URLs | App Runner (maintenance) |
|---------|------------|-------------|--------------------------|
| **Auth** | IAM, Cognito, API keys, custom | IAM resource policy only | IAM |
| **Caching** | Built-in | None | None |
| **Rate limiting** | Built-in | None | Auto-scale only |
| **WebSocket** | Yes | No | No |
| **Timeout** | 29 seconds | 15 minutes | No limit |
| **Cost** | Per request + data | Free (Lambda cost only) | Per vCPU-hour |
| **Best for** | Full API management, SaaS | Webhooks, internal APIs | Web apps (legacy, migrating) |

### EventBridge Pipes

Connect event sources directly to targets with filtering, enrichment, and transformation. Eliminates Lambda glue for common patterns:
- SQS to Step Functions
- DynamoDB Streams to EventBridge
- Kinesis to Lambda with enrichment

---

## 7. Containers

### ECS vs EKS Decision Framework

| Factor | ECS | EKS |
|--------|-----|-----|
| **Team expertise** | AWS-native teams | Teams with K8s experience |
| **Portability** | AWS-locked | Multi-cloud, hybrid (CNCF) |
| **Complexity** | Lower (Express Mode for simplest) | Higher (K8s learning curve) |
| **Ecosystem** | AWS integrations | Helm, Argo, Istio, Karpenter |
| **Cost** | Fargate or EC2 | Control plane $0.10/hr + compute |
| **Quick start** | ECS Express Mode | EKS Auto Mode |
| **Hybrid/on-prem** | No | EKS Hybrid Nodes |
| **GPU/ML** | Supported | Better ecosystem (GPU operators, Karpenter) |
| **Service mesh** | VPC Lattice | VPC Lattice / Istio / Linkerd |

### Fargate Pricing and Optimization

- Pay per vCPU-second and GB-second, no upfront costs
- Fargate Spot: up to 70% savings for fault-tolerant batch workloads
- Compute Savings Plans apply (up to 66% discount)
- Price premium ~58% vs self-managed EC2 but eliminates node management
- Graviton4 available for Fargate tasks
- EBS volume attachments supported for persistent storage

### EKS Hybrid Nodes

Run on-premises hardware or VMs as EKS nodes. GA in all commercial regions.
- Supports EKS add-ons, Pod Identity, cluster access entries
- Per-hour pricing based on vCPU of attached hybrid nodes
- Configuration insights for webhook/control plane diagnostics (Aug 2025)
- No minimum fees or upfront commitments

### Container Migration Path (2026)

```
App Runner (maintenance mode)  ---->  ECS Express Mode
AWS Copilot CLI (EOL June 2026)  -->  ECS Express Mode or CDK L3 constructs
Self-managed EC2 containers  ------>  ECS + Fargate (auto-managed)
Need Kubernetes  ----------------->  EKS Auto Mode (least ops)
Need hybrid/on-prem K8s  --------->  EKS Hybrid Nodes
```

---

## 8. Infrastructure as Code

### IaC Comparison Matrix

| Feature | CloudFormation | CDK v2 | Terraform | SAM |
|---------|---------------|--------|-----------|-----|
| **Language** | YAML/JSON | TS, Python, Go, Java, C# | HCL | YAML (CFN superset) |
| **State** | AWS-managed | AWS-managed (via CFN) | Self-managed (.tfstate) | AWS-managed |
| **Multi-cloud** | No | No | Yes | No |
| **Abstractions** | None | L1/L2/L3 constructs | Modules | Serverless transforms |
| **Drift detection** | Yes | Yes (via CFN) | `terraform plan` | Via CFN |
| **Testing** | cfn-lint | CDK assertions, integ tests | validate, Sentinel | SAM local invoke |
| **Ecosystem** | Limited | Construct Hub (9,000+) | Registry (15,000+) | Serverless patterns |
| **Best for** | Legacy/compliance | New AWS projects | Multi-cloud teams | Serverless-only |

### CDK v2 Updates (2025-2026)

**CDK Mixins (stable in aws-cdk-lib):** Compose reusable infrastructure behaviors via `.with()` on any construct. No extra packages needed.

**Key additions:**
- ECS deployment strategies: built-in Linear/Canary for safer rollouts
- CloudWatch Logs deletion protection
- EKS Hybrid Nodes construct for on-prem integration
- CLI `--revert-drift`: fix drifted resources in a single command
- 150+ PRs merged Dec 2025 - Feb 2026 spanning EKS, Bedrock, ECS, 15+ services
- SAM CLI supports local dev/test of CDK projects (public preview)

```typescript
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecs_patterns from 'aws-cdk-lib/aws-ecs-patterns';

// Production-ready Fargate service with ALB, auto-scaling, and circuit breaker
const service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Api', {
  cluster,
  taskImageOptions: {
    image: ecs.ContainerImage.fromEcrRepository(repo, 'latest'),
    containerPort: 8080,
    environment: { NODE_ENV: 'production' },
  },
  desiredCount: 2,
  runtimePlatform: {
    cpuArchitecture: ecs.CpuArchitecture.ARM64,  // Graviton
    operatingSystemFamily: ecs.OperatingSystemFamily.LINUX,
  },
  circuitBreaker: { enable: true, rollback: true },
});

service.targetGroup.configureHealthCheck({ path: '/health' });
service.service.autoScaleTaskCount({ minCapacity: 2, maxCapacity: 20 })
  .scaleOnCpuUtilization('CpuScaling', { targetUtilizationPercent: 70 });
```

### SAM (v1.155.2+)

- Enhanced container-based builds and CI/CD compatibility
- Local dev/test for CDK projects (preview)
- Works alongside CDK for serverless resources

### CloudFormation Best Practices

- Use `DeletionPolicy: Retain` for stateful resources (databases, S3 buckets)
- Enable drift detection via scheduled Config rules
- Use nested stacks or StackSets for multi-account deployments
- Use `cfn-guard` for policy-as-code validation

---

## 9. Observability

### CloudWatch Observability Stack (2025-2026)

| Service | Purpose | Key Update |
|---------|---------|------------|
| **Application Signals** | APM for services/SLOs | EKS, ECS, Lambda integration |
| **Container Insights (OTel)** | EKS cluster metrics | 150+ enriched labels/metric (preview Apr 2026) |
| **Internet Monitor** | End-user experience | Cross-account observability |
| **Cross-Account** | Unified multi-account view | Up to 100K source accounts per monitor |
| **Native OTel metrics** | Vendor-neutral ingestion | OTLP direct + PromQL queries (preview Apr 2026) |

### OpenTelemetry Integration

CloudWatch now supports native OTel metrics via OTLP -- no custom conversion logic needed. Combine custom OTel metrics with AWS vended metrics from 70+ services, query with PromQL.

```yaml
# AWS Distro for OpenTelemetry (ADOT) Collector config for EKS
receivers:
  awscontainerinsightreceiver:
    collection_interval: 30s
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 60s

exporters:
  awsemf:
    namespace: ContainerInsights
    log_group_name: /aws/containerinsights/{ClusterName}/performance
    resource_to_telemetry_conversion:
      enabled: true
  awsxray:

service:
  pipelines:
    metrics:
      receivers: [awscontainerinsightreceiver, otlp]
      processors: [batch]
      exporters: [awsemf]
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [awsxray]
```

### X-Ray Cross-Account Tracing

- Trace Map visualization across accounts within a Region
- Monitoring account links to up to 100,000 source accounts
- Source account shares with up to 5 monitoring accounts
- First trace copy free; additional copies at standard pricing
- Supports CloudWatch cross-account for metrics, logs, traces, Application Signals, Internet Monitor

### Observability Strategy

```
Application tier:  Application Signals (APM, SLOs, service maps)
                   |
Container tier:    Container Insights + OTel (150+ enriched labels)
                   |
Infrastructure:    CloudWatch Metrics + Alarms + Dashboards
                   |
Network:           VPC Flow Logs + Internet Monitor
                   |
Tracing:           X-Ray + ADOT (OpenTelemetry)
                   |
Cross-account:     CloudWatch Observability Access Manager (up to 100K accounts)
```

---

## 10. Cost Optimization

### Pricing Model Comparison

| Model | Discount | Commitment | Flexibility | Best For |
|-------|----------|-----------|-------------|----------|
| **On-Demand** | 0% | None | Full | Unpredictable, spiky |
| **Compute Savings Plans** | Up to 66% | 1 or 3 year | EC2, Fargate, Lambda | Steady baseline across services |
| **EC2 Instance Savings Plans** | Up to 72% | 1 or 3 year | Specific instance family | Predictable EC2 workloads |
| **Reserved Instances** | Up to 72% | 1 or 3 year | Specific type + AZ | Legacy, capacity reservation |
| **Spot Instances** | Up to 90% | None | 2-min interruption warning | Batch, stateless, fault-tolerant |
| **Fargate Spot** | Up to 70% | None | Task interruption | Fault-tolerant containers |

### Cost Optimization Hierarchy

```
1. Right-size first
   - Compute Optimizer recommendations (ML-powered)
   - Migrate to Graviton (20-40% savings, typically no code changes)
   |
2. Commit baseline
   - 1yr Compute Savings Plans for flexibility (66%)
   - 3yr EC2 Instance Savings Plans for predictable (72%)
   |
3. Use Spot for eligible workloads
   - Batch processing, CI/CD, EKS worker nodes (up to 90%)
   - Mixed instance policies in ASGs (multiple families)
   |
4. Architect for serverless
   - Lambda, Fargate, Aurora Serverless, DynamoDB on-demand
   |
5. Storage tiering
   - S3 Intelligent-Tiering (auto-tiering at no retrieval cost)
   - gp3 over gp2 (20% cheaper baseline, 4x more IOPS)
   |
6. Monitor continuously
   - Cost Explorer, Budgets, Trusted Advisor, Cost Anomaly Detection
```

### Spot Instance Patterns

- Use mixed instance policies in ASGs (3+ instance families)
- Implement graceful shutdown via instance metadata (2-minute warning)
- Best for: CI/CD runners, batch processing, EKS workers (Karpenter), EMR, rendering
- Never for: databases, single-instance stateful workloads, time-sensitive SLA

### FinOps Practices

- **Tagging strategy**: Enforce cost allocation tags via SCPs and AWS Config rules
- **Showback/chargeback**: Use Cost Explorer + Cost and Usage Report (CUR) to attribute spend
- **Anomaly detection**: CloudWatch Cost Anomaly Detection for automated alerting
- **Unit economics**: Track cost-per-transaction, cost-per-user, not just total spend

---

## 11. Well-Architected Framework

### Six Pillars

| Pillar | Focus | Key Question |
|--------|-------|-------------|
| **Operational Excellence** | Run and monitor systems | How do you evolve operations? |
| **Security** | Protect data and systems | How do you manage identities? |
| **Reliability** | Recover from failures | How do you handle change? |
| **Performance Efficiency** | Use resources efficiently | How do you select compute? |
| **Cost Optimization** | Avoid unnecessary spend | How do you manage demand? |
| **Sustainability** | Minimize environmental impact | How do you reduce downstream waste? |

### AI/ML Lenses (re:Invent 2025)

Three specialized lenses launched/updated:

**Responsible AI Lens (NEW):** Ethics, transparency, risk management across AI lifecycle. Ten dimensions: controllability, privacy, security, safety, veracity, robustness, fairness, explainability, transparency, governance.

**Machine Learning Lens (Updated):** Aligns with 6-stage ML lifecycle (problem definition, data prep, model dev, deployment, ops, monitoring). Guidance on SageMaker Unified Studio, HyperPod distributed training, Clarify bias assessment.

**Generative AI Lens (Updated):** Patterns for intelligent assistants, content generation, enterprise copilots. Sustainability emphasis on minimizing compute for training/inference.

### Sustainability Pillar Best Practices

- Use Graviton instances for better performance-per-watt
- Leverage serverless to eliminate idle compute
- Apply model efficiency techniques (quantization, distillation, pruning)
- Right-size with Compute Optimizer
- Use S3 Intelligent-Tiering to avoid over-provisioned storage
- Select regions with lower carbon intensity

---

## 12. AI/ML Infrastructure

### SageMaker Ecosystem

**SageMaker Unified Studio:** One-click onboarding with existing AWS data (Athena, Redshift, S3). Unified workspace for data, ML, and analytics.

**SageMaker HyperPod:**
- NVL72 UltraServer: 18 instances with 72 Blackwell GPUs via NVLink
- Checkpointless training: auto-recovery in minutes, >95% training goodput
- Dynamic scaling: expand/contract running jobs to absorb idle accelerators
- IDE support: JupyterLab and Code Editor on persistent EKS clusters (Nov 2025)
- Observability: Managed Grafana dashboards for GPU, network, cluster health (Mar 2026)
- Continuous provisioning: partial provisioning, rolling updates, concurrent scaling

### Amazon Bedrock

**Guardrails (6 safeguard policies):**
- Content moderation, prompt attack detection, topic classification
- PII redaction, hallucination detection, automated reasoning
- Centralized enforcement across Organizations (2026)
- Image + text input evaluation
- Policy guardrails: natural language to Cedar (Dec 2025)

**Agents and Integration:**
- Strands Agents framework integration
- AgentCore for deployment
- Knowledge Bases with guardrails

### Custom Silicon Strategy

| Chip | Status | Key Specs |
|------|--------|-----------|
| **Trainium3** | Preview end 2025, volume early 2026 | 3nm, 144 chips/UltraServer, 4.4x vs Trn2 |
| **Trainium2** | GA, Project Ranier (500K-1M chips) | 30-40% better price-perf vs GPUs |
| **Inferentia2** | GA (de-emphasized for GenAI) | Cost-optimized inference |

Majority of Bedrock token usage already runs on Trainium. Customers report up to 50% cost reduction for training and inference.

### ParallelCluster (HPC)

Latest: ParallelCluster 3.15 (Mar 2026)
- P6-B300 (NVIDIA Blackwell B300) support
- Slurm 25.11 with expedited job requeue
- Ubuntu 24.04, CUDA 12.8.0
- Last release supporting Amazon Linux 2 (EOL June 2026)

---

## 13. Multi-Account Strategy

### AWS Organizations Structure

```
Management Account (billing + SCPs only -- no workloads here)
  |
  +-- Security OU
  |     +-- Log Archive (CloudTrail, Config, VPC Flow Logs)
  |     +-- Security Tooling (Security Hub, GuardDuty delegated admin)
  |
  +-- Infrastructure OU
  |     +-- Networking (Transit Gateway, Direct Connect, Route 53)
  |     +-- Shared Services (AD, CI/CD, ECR, artifact repos)
  |
  +-- Workloads OU
  |     +-- Dev Account
  |     +-- Staging Account
  |     +-- Production Account
  |
  +-- Sandbox OU (budget-capped developer accounts)
```

### Control Tower

Automates multi-account landing zone with guardrails and account factory:
- **Mandatory guardrails** (SCPs): prevent CloudTrail disabling, S3 public access
- **Strongly recommended**: encryption, logging, IMDSv2
- **Account Factory**: self-service provisioning with baselines
- **Customizations for Control Tower (CfCT)**: CloudFormation-based customization

### Cross-Account Access Patterns

| Pattern | Use Case | Mechanism |
|---------|----------|-----------|
| **IAM Identity Center** | Human SSO to all accounts | Permission sets, SAML/OIDC IdP |
| **Cross-account roles** | Service-to-service | `sts:AssumeRole` with external ID |
| **Resource policies** | Shared resources (S3, KMS, SNS) | Principal ARN in policy |
| **RAM** | VPC subnets, TGW, Route 53 rules | Resource Access Manager |
| **PrivateLink** | Private service endpoints | VPC endpoint services |
| **Delegated admin** | Security Hub, GuardDuty, Config | Delegate to security account |

### Multi-Account Networking

```
                    +------------------+
                    | Transit Gateway  |
                    | (Networking Acct)|
                    +--------+---------+
                             |
          +------------------+------------------+
          |                  |                  |
  +-------+------+  +-------+------+  +-------+------+
  | Shared Svcs  |  | Production   |  | Dev/Staging  |
  | VPC          |  | VPC          |  | VPC          |
  | (PrivateLink |  | (workloads)  |  | (workloads)  |
  |  endpoints)  |  |              |  |              |
  +--------------+  +--------------+  +--------------+
```

- Centralize PrivateLink endpoints in Shared Services VPC
- Spoke VPCs access via Transit Gateway attachments
- Use Route 53 Profiles for simplified DNS management across VPCs
- VPC Lattice for service-to-service networking across accounts

### Account Vending Best Practices

1. Use Control Tower Account Factory or Service Catalog for provisioning
2. Apply baseline SCPs at OU level (never at individual account)
3. Deploy security baselines (GuardDuty, Config, CloudTrail) via StackSets
4. Enforce tagging via Tag Policies in Organizations
5. Set AWS Budgets with alerts per account
6. Use IAM Identity Center permission sets (never long-lived IAM users)

---

## Quick Reference: Decision Trees

### Compute

```
Need containers?
  Yes -> Need K8s ecosystem/portability?
    Yes -> EKS Auto Mode (least ops) or EKS + Karpenter (custom)
    No  -> ECS Express Mode (simple) or ECS + Fargate (custom)
  No -> Event-driven / short-lived?
    Yes -> Lambda (SnapStart for Java/Python/.NET cold starts)
    No  -> EC2 Graviton4 (Savings Plans for baseline, Spot for batch)
```

### Database

```
Relational?
  Yes -> Need global distribution?
    Yes -> Aurora DSQL or Aurora Global Database
    No  -> Need auto-scaling?
      Yes -> Aurora Serverless v2
      No  -> RDS Multi-AZ cluster
  No -> Key-value, single-digit ms?
    Yes -> DynamoDB (+ OpenSearch via zero-ETL for search)
    No  -> Need durable in-memory?
      Yes -> MemoryDB Multi-Region
      No  -> ElastiCache (Valkey over Redis OSS)
```

### Storage

```
Object storage?
  Yes -> Need low latency?
    Yes -> S3 Express One Zone
    No  -> Need analytics tables?
      Yes -> S3 Tables (Apache Iceberg)
      No  -> S3 Standard / Intelligent-Tiering
  No -> Block storage?
    Yes -> io2 Block Express (databases) or gp3 (general)
    No  -> Shared file system?
      Yes -> EFS (Linux) / FSx (Windows/Lustre/ONTAP)
```
