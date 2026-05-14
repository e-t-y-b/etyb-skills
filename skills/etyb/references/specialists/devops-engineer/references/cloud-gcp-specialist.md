# GCP Cloud Engineering — Deep Reference

**Always use `WebSearch` to verify service names, pricing, quotas, and feature GA status before giving advice. GCP evolves rapidly; this reference provides architectural context verified as of early 2026.**

## Table of Contents
1. [Compute Selection](#1-compute-selection)
2. [Networking](#2-networking)
3. [Storage](#3-storage)
4. [Databases](#4-databases)
5. [Data and Analytics](#5-data-and-analytics)
6. [Security](#6-security)
7. [Serverless](#7-serverless)
8. [Infrastructure as Code](#8-infrastructure-as-code)
9. [Observability](#9-observability)
10. [Cost Optimization](#10-cost-optimization)
11. [AI/ML Infrastructure](#11-aiml-infrastructure)
12. [Multi-Cloud and Hybrid](#12-multi-cloud-and-hybrid)

---

## 1. Compute Selection

### VM Families — Current Generation

| Family | Processor | Max vCPUs | Max RAM | Use Case |
|--------|-----------|-----------|---------|----------|
| **C4** | Intel Xeon (Emerald/Granite Rapids) | 288 | 2.2 TB DDR5 | Compute-intensive: HPC, game servers, CPU-based ML inference |
| **C4A** | Google Axion (Arm Neoverse V2) | 72 (+96 bare metal) | 576 GB DDR5 | Price-perf leader: web serving, microservices, Arm-native workloads |
| **C4D** | AMD EPYC (5th Gen) | 384 | 2.8 TB | General compute with AMD price-perf, mixed workloads |
| **Tau T2A** | Ampere Altra (Arm N1) | 48 | 192 GB | Scale-out: web frontends, containerized microservices (4 GB/vCPU) |
| **N4** | Intel Xeon (Emerald Rapids) | 240 | 2.9 TB | General purpose, balanced price-perf |
| **E2** | Intel/AMD (auto-selected) | 32 | 128 GB | Dev/test, small workloads, cost-sensitive |

**Arm selection guidance:** C4A for production (Neoverse V2, higher single-thread perf, up to 100 Gbps Tier_1 networking, bare metal option); T2A for scale-out where per-vCPU cost matters most.

### GKE — Autopilot vs Standard

| Dimension | Autopilot | Standard |
|-----------|-----------|----------|
| **Node management** | Google-managed (zero ops) | User-managed node pools |
| **Billing** | Per-pod (CPU + memory + ephemeral storage) | Per-VM instance (regardless of utilization) |
| **Cost breakeven** | Cheaper below ~60-70% utilization | Cheaper above ~60-70% utilization |
| **GPU/TPU support** | Yes (request via pod spec) | Yes (dedicated node pools) |
| **DaemonSets** | Limited (Google-managed) | Full control |
| **Privileged pods** | Restricted | Allowed |
| **Max pods/node** | 32 (default) | 110 (configurable) |
| **GKE Enterprise** | Supported | Supported |

**Decision rule:** Start with Autopilot for new workloads. Move to Standard only if you need DaemonSets, privileged containers, eBPF tooling, or run consistently above 70% utilization.

```bash
# Create Autopilot cluster
gcloud container clusters create-auto prod-cluster \
  --region=us-central1 \
  --release-channel=regular \
  --enable-master-authorized-networks \
  --master-authorized-networks=10.0.0.0/8

# Create Standard cluster with Arm node pool
gcloud container clusters create prod-standard \
  --region=us-central1 \
  --num-nodes=3 \
  --machine-type=c4a-standard-4 \
  --release-channel=regular

# GKE Enterprise: register cluster to fleet
gcloud container fleet memberships register prod-cluster \
  --gke-cluster=us-central1/prod-cluster \
  --enable-workload-identity
```

### Cloud Run — Production Features

Cloud Run is the default serverless container platform. Key capabilities (2025-2026):

- **GPU support** (GA): NVIDIA L4 GPUs (min 4 vCPU, 16 GiB); NVIDIA RTX PRO 6000 Blackwell (Preview)
- **Multi-container sidecars** (GA): shared localhost networking + shared volumes between containers
- **Jobs** (GA): run-to-completion workloads with task parallelism
- **Min instances** (GA): keep warm instances to eliminate cold starts
- **Always-on CPU**: CPU not throttled outside request processing
- **Direct VPC egress** (GA): connect to VPC without Serverless VPC Access connector (2x IP usage)
- **60-min timeout**: HTTP functions up to 60 minutes, jobs up to 24 hours

```bash
# Deploy with GPU and min instances
gcloud run deploy ml-service \
  --image=us-docker.pkg.dev/proj/repo/ml-service:latest \
  --gpu=1 --gpu-type=nvidia-l4 \
  --cpu=4 --memory=16Gi \
  --min-instances=1 \
  --region=us-central1 \
  --allow-unauthenticated

# Deploy with sidecar (multi-container)
gcloud run deploy api-service \
  --image=us-docker.pkg.dev/proj/repo/api:latest \
  --add-containers=name=otel-collector,image=otel/opentelemetry-collector:latest \
  --region=us-central1
```

### Cloud Functions (2nd Gen) — Now Cloud Run Functions

Cloud Functions 2nd gen is built on Cloud Run infrastructure. It is now officially branded **Cloud Run functions**.

- Concurrency up to 1,000 requests per instance (vs 1 in 1st gen)
- Up to 16 GB memory, 4 vCPUs per instance
- 60-minute HTTP timeout
- Eventarc triggers for 125+ event sources
- All new Cloud Run features automatically available (including GPUs)
- Runtime support: Go 1.26, Python 3.14, Java 25, PHP 8.5, Node.js 22, Ruby 3.3, .NET 9

---

## 2. Networking

### Cloud Load Balancing

| Load Balancer Type | Scope | Protocol | Use Case |
|--------------------|-------|----------|----------|
| **Global external ALB** | Global | HTTP/S, HTTP/2, gRPC | Public web apps, API gateways |
| **Regional external ALB** | Regional | HTTP/S | Compliance-restricted regions |
| **Global external proxy NLB** | Global | TCP/SSL | Non-HTTP TCP services |
| **Regional internal ALB** | Regional | HTTP/S | Service-to-service inside VPC |
| **Internal passthrough NLB** | Regional | TCP/UDP | Internal TCP/UDP (lowest latency) |

### Cloud CDN

- Integrated with global external ALB at Google edge PoPs
- Cache static and dynamic content close to users
- Signed URLs and signed cookies for access control
- Cache invalidation via gcloud or API
- Combine with Cloud Armor for security at the edge

### Cloud Armor WAF (2025-2026 Features)

- **Enhanced body inspection**: 8 KB to 64 KB for all preconfigured WAF rules
- **JA4 network fingerprinting** (GA): advanced TLS client identification beyond JA3
- **JA4 rate limiting key** (GA): rate limit by TLS fingerprint
- **Hierarchical security policies** (GA): org/folder/project policy inheritance
- **Organization-scoped address groups** (GA): reuse IP lists across policies
- **ModSecurity CRS 3.3** (GA): updated preconfigured rule set
- **Regional internal ALB support** (GA): protect internal services

```bash
# Create Cloud Armor policy with rate limiting and SQLi protection
gcloud compute security-policies create api-protection \
  --description="API rate limiting and WAF"

gcloud compute security-policies rules create 1000 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable')" \
  --action=deny-403

gcloud compute security-policies rules create 2000 \
  --security-policy=api-protection \
  --expression="true" \
  --action=throttle \
  --rate-limit-threshold-count=100 \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --enforce-on-key=IP
```

### VPC Service Controls

VPC Service Controls create security perimeters around GCP resources to prevent data exfiltration:
- Supports identity groups and third-party identities in ingress/egress rules (Preview)
- Combine with Private Service Connect for defense-in-depth
- Covers 100+ GCP services (BigQuery, Cloud Storage, GKE, etc.)

```bash
# Create a service perimeter
gcloud access-context-manager perimeters create prod-perimeter \
  --title="Production Perimeter" \
  --resources="projects/123456789" \
  --restricted-services="bigquery.googleapis.com,storage.googleapis.com" \
  --policy=POLICY_ID
```

### Private Service Connect

- Access managed services privately from inside VPC (no public internet traversal)
- Physical host NAT: latency limited only by host bandwidth capacity
- **IPv6-only NAT subnets** (GA): publish services over IPv6
- **Propagated connections** (GA): service accessible in one VPC spoke available to all spokes via Network Connectivity Center hub
- **Service connectivity automation with IPv6** (GA)

---

## 3. Storage

### Cloud Storage

| Feature | Details |
|---------|---------|
| **Autoclass** | Automatic storage class transitions (Standard -> Nearline -> Coldline -> Archive) based on access patterns |
| **Dual-region** | Continental-scale buckets across 9 regions, 3 continents; RTO of zero |
| **Hierarchical Namespaces (HNS)** | Folder-based organization for data lake workloads (Preview -- not yet production; no soft delete or Autoclass) |
| **Storage classes** | Standard (~$0.020/GB/mo), Nearline (~$0.010), Coldline (~$0.004), Archive (~$0.0012) |

```bash
# Create bucket with Autoclass
gcloud storage buckets create gs://my-data-lake \
  --location=us \
  --autoclass-terminal-storage-class=ARCHIVE \
  --uniform-bucket-level-access

# Lifecycle rule for cost optimization
cat > lifecycle.json << 'EOF'
{
  "rule": [
    {"action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
     "condition": {"age": 30, "matchesStorageClass": ["STANDARD"]}},
    {"action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
     "condition": {"age": 90, "matchesStorageClass": ["NEARLINE"]}},
    {"action": {"type": "Delete"},
     "condition": {"age": 365}}
  ]
}
EOF
gcloud storage buckets update gs://my-data-lake --lifecycle-file=lifecycle.json
```

### Block and File Storage

| Service | Type | IOPS | Use Case |
|---------|------|------|----------|
| **pd-balanced** | Block (SSD) | 80K read, 30K write | General-purpose boot/data disks |
| **pd-ssd** | Block (SSD) | 100K read, 70K write | Databases, latency-sensitive |
| **pd-extreme** | Block (SSD) | 120K IOPS | SAP HANA, large databases |
| **Hyperdisk Extreme** | Block (SSD) | 350K IOPS | Highest IOPS, independent scaling |
| **Filestore Basic** | NFS | 12K-36K | Shared file systems, home dirs |
| **Filestore Enterprise** | NFS | 120K+ | Regional HA, snapshots, backups |
| **Parallelstore** | Parallel FS | Millions | HPC, ML training data, scratch |

---

## 4. Databases

### Database Selection Matrix

| Requirement | Service | Why |
|-------------|---------|-----|
| PostgreSQL workloads (standard) | **Cloud SQL** | Managed PG, up to 128 vCPUs, Enterprise Plus for HA |
| PostgreSQL (high perf, analytics) | **AlloyDB** | 4x faster transactions, 100x faster analytical queries vs standard PG |
| Global ACID, unlimited scale | **Cloud Spanner** | Five 9s SLA, auto-sharding, PG interface available |
| Document database | **Firestore** | Serverless, multi-region strong consistency, 99.999% SLA |
| Wide-column (petabyte-scale) | **Bigtable** | <10ms latency at any scale, time-series, IoT, ad-tech |
| In-memory cache | **Memorystore for Valkey** | 2x QPS of Redis Cluster, open-source (Valkey 9.0 GA) |
| MySQL/SQL Server managed | **Cloud SQL** | Standard managed RDBMS |

### Cloud SQL

- **Enterprise Plus**: highest availability tier with near-zero downtime maintenance
- Up to 128 vCPUs, supports PostgreSQL 16, MySQL 8.4, SQL Server 2022
- Memory Agent for PostgreSQL (GA): automated memory tuning
- Read replicas, automatic storage increase, point-in-time recovery

### AlloyDB

- PostgreSQL-compatible with separate compute and storage architecture
- **Horizontal autoscaling for read pool instances** (Preview)
- Automatic replication across AZs, patching with minimal downtime
- Columnar engine for analytical queries on transactional data
- AI integration: built-in vector embeddings with `google_ml_integration`

### Cloud Spanner

- **Managed autoscaler** (GA): scales read-only replicas independently from read-write
- **PostgreSQL interface**: portable schemas and queries to/from standard PG
- **Granular instance sizing**: start at 100 Processing Units (~$65/month); 1000 PU = 1 node
- **CUD pricing**: 1-year = 20% discount, 3-year = 40% discount (100 PU 3yr CUD < $40/month)
- Editions: Standard, Enterprise, Enterprise Plus

```bash
# Create Spanner instance with granular sizing
gcloud spanner instances create my-instance \
  --config=regional-us-central1 \
  --processing-units=100 \
  --description="Dev instance"

# Create database with PG dialect
gcloud spanner databases create my-db \
  --instance=my-instance \
  --database-dialect=POSTGRESQL
```

### Firestore

- **MongoDB compatibility** (Preview): use MongoDB drivers/tools against Firestore backend
- Multi-region replication with strong consistency
- Up to 99.999% availability SLA
- Single-digit millisecond read latency

### Bigtable

- Wide-column NoSQL for petabyte-scale, single-digit millisecond latency
- **Continuous materialized views** (Preview): real-time aggregation for reporting
- Database Center integration: proactive monitoring and issue resolution
- Ideal for time-series, IoT telemetry, financial ticks, ad-tech

### Memorystore for Valkey

Valkey is the Linux Foundation open-source fork of Redis (BSD-licensed). Memorystore now defaults to Valkey:

- **Valkey 8.0**: 2x QPS of Redis Cluster, improved memory management, automatic failover for empty shards
- **Valkey 9.0** (GA): pipeline memory prefetching (+40% throughput), SIMD BITCOUNT/HyperLogLog (+200%)
- Up to 5 replica nodes per primary
- 99.99% SLA, Private Service Connect, cross-region replication, persistence
- Fully compatible with existing Redis clients

---

## 5. Data and Analytics

### BigQuery

| Feature | Status | Description |
|---------|--------|-------------|
| **BigQuery Omni** | GA | Query data in AWS S3 and Azure Blob via BigLake tables |
| **Cross-cloud joins** | GA | JOIN across Google Cloud and Omni regions |
| **BI Engine** | GA | Sub-second interactive analysis; auto-accelerates leaf-level queries |
| **Vector search** | GA | Embedding columns with auto-generation via Vertex AI models |
| **Continuous queries** | GA | Real-time streaming pipelines integrated with Pub/Sub and Bigtable |
| **Materialized views over BigLake** | GA | Avoid S3 egress costs with precomputed views |
| **Object tables** | GA | Query unstructured data (images, audio) in Cloud Storage |

```sql
-- BigQuery vector search example
SELECT base.id, base.title, distance
FROM VECTOR_SEARCH(
  TABLE `project.dataset.embeddings`,
  'embedding_column',
  (SELECT embedding FROM ML.GENERATE_EMBEDDING(
    MODEL `project.dataset.text_model`,
    (SELECT 'search query' AS content)
  )),
  top_k => 10
);

-- Continuous query to Bigtable
CREATE CONTINUOUS QUERY my_agg
OPTIONS(target_dataset='streaming_output')
AS SELECT
  window_start, user_id, COUNT(*) as event_count
FROM TABLE(TUMBLE(TABLE `events`, DESCRIPTOR(event_time), 'INTERVAL 1 MINUTE'))
GROUP BY window_start, user_id;
```

### Data Pipeline Services

| Service | Engine | Best For |
|---------|--------|----------|
| **Dataflow** | Apache Beam (managed) | Stream + batch ETL, autoscaling, dynamic rebalancing |
| **Dataproc** | Spark/Hadoop/Flink/Presto (managed) | Existing Spark jobs, ML pipelines, ad-hoc analytics |
| **Pub/Sub** | Google-native | Event ingestion, decoupling; BigQuery subscription for direct-to-BQ streaming |
| **Dataform** | SQL-based | ELT orchestration, data transformation in BigQuery with version control |

**Decision rule:** Dataflow for new streaming/batch pipelines (Apache Beam); Dataproc for existing Spark/Hadoop migrations; Pub/Sub BigQuery subscription when you just need events into BQ without transformation.

```bash
# Create Pub/Sub topic with BigQuery subscription
gcloud pubsub topics create events-topic

gcloud pubsub subscriptions create events-to-bq \
  --topic=events-topic \
  --bigquery-table=project:dataset.events_raw \
  --use-topic-schema \
  --write-metadata
```

---

## 6. Security

### IAM and Identity

**Workload Identity Federation** eliminates service account keys for external workloads:

```bash
# Create workload identity pool for GitHub Actions
gcloud iam workload-identity-pools create github-pool \
  --location=global \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"

# Grant access to service account
gcloud iam service-accounts add-iam-policy-binding deploy@project.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/github-pool/attribute.repository/org/repo"
```

- **SAML 2.0 federation** (GA): any SAML-compatible IdP
- **X.509 certificate federation** (GA): certificate-based workload auth
- **IAM Conditions**: attribute-based access control (time, resource tags, IP)
- **Policy Intelligence**: recommender for least-privilege, unused role detection

### Security Command Center (SCC)

- Centralized vulnerability and threat management
- Findings from Security Health Analytics, Web Security Scanner, Event Threat Detection
- Integration with Chronicle SIEM for advanced threat hunting
- Compliance monitoring dashboards (CIS Benchmarks, PCI-DSS, NIST 800-53)

### BeyondCorp Enterprise

- Zero-trust access model: verify users before granting access
- Context-aware access policies (device state, location, identity)
- Replaces VPN-based perimeter security
- Focus on least privilege, just-in-time access, robust delegation
- CIEM for non-human identity governance (service accounts, workload identities)

### Secret Manager

- Store and manage API keys, passwords, certificates
- Automatic rotation, versioning, audit logging
- **Parameter Manager** (GA): manage workload parameters alongside secrets
- Integration with Cloud Run, GKE, Cloud Functions via volume mounts or env vars

```bash
# Create and access a secret
gcloud secrets create db-password --replication-policy="automatic"
echo -n "s3cur3P@ss" | gcloud secrets versions add db-password --data-file=-

# Access in Cloud Run via env var
gcloud run deploy my-service \
  --set-secrets=DB_PASSWORD=db-password:latest
```

### Assured Workloads

- Sovereign data and access boundary controls (residency, personnel, encryption)
- FIPS 140-2 validated encryption via Cloud KMS by default
- Compliance packages: FedRAMP High, IL4/IL5, CJIS, ITAR, EU Sovereign, HIPAA

---

## 7. Serverless

### Serverless Decision Framework

```
                     START
                       |
            Need full K8s API?
           /                    \
         Yes                    No
          |                      |
    GKE Autopilot       Container or function?
                        /                  \
                   Container              Function
                      |                      |
                  Cloud Run          Cloud Run functions
                      |             (event-driven, single-purpose)
               Need GPU? ──Yes──> Cloud Run + GPU
```

| Dimension | Cloud Run | Cloud Run functions | GKE Autopilot |
|-----------|-----------|-------------------|---------------|
| **Unit of deployment** | Container image | Function code | K8s Pod/Deployment |
| **Concurrency** | Configurable (up to 1000) | Configurable (up to 1000, 2nd gen) | Pod-level |
| **Max timeout** | 60 min (services), 24h (jobs) | 60 min | Unlimited |
| **GPU support** | Yes (L4, RTX PRO 6000) | Yes (via Cloud Run) | Yes (node pools) |
| **Scale to zero** | Yes | Yes | No (min 1 node) |
| **Stateful workloads** | No (use jobs for batch) | No | Yes (StatefulSets, PVCs) |
| **Custom networking** | Direct VPC egress | Direct VPC egress | Full VPC native |
| **When to use** | Default for stateless services | Lightweight event handlers | Stateful, multi-service, K8s ecosystem |

### Eventarc

- **Eventarc Standard**: point-to-point event routing from Google sources
- **Eventarc Advanced** (GA, Aug 2025): centralized bus + distributed pipelines
  - Governance layer (bus) separated from processing layer (pipeline)
  - Destinations: Cloud Run, Cloud Run functions, HTTP endpoints, Workflows, another bus
  - 125+ event sources (Google services + third-party via Pub/Sub)

### Workflows

- Serverless orchestration of microservices, APIs, and functions
- YAML/JSON-based workflow definitions with built-in connectors
- Error handling, retries, conditional logic, parallel execution
- Integration with Cloud Tasks (async dispatch) and Cloud Scheduler (cron)

```yaml
# Workflows example: process uploaded file
main:
  params: [event]
  steps:
    - extract_info:
        assign:
          - bucket: ${event.data.bucket}
          - file: ${event.data.name}
    - process_file:
        call: http.post
        args:
          url: https://api-service-xxxxx-uc.a.run.app/process
          body:
            bucket: ${bucket}
            file: ${file}
          auth:
            type: OIDC
        result: process_result
    - store_result:
        call: googleapis.bigquery.v2.tabledata.insertAll
        args:
          projectId: my-project
          datasetId: results
          tableId: processed
          body:
            rows:
              - json: ${process_result.body}
```

---

## 8. Infrastructure as Code

### IaC Tool Comparison

| Tool | Language | GCP Support | Status |
|------|----------|-------------|--------|
| **Terraform** (google provider) | HCL | First-class, 1000+ resources | Industry standard; actively maintained by HashiCorp |
| **Pulumi** (gcp package) | TypeScript, Python, Go, C# | First-class (bridged from Terraform provider) | Growing adoption; real programming languages |
| **Config Connector** | Kubernetes YAML | Native K8s CRDs for GCP resources | Best for GKE-centric teams; GitOps with Config Sync |
| **Infrastructure Manager** | Terraform blueprints | Google-managed Terraform execution | Replacement for Deployment Manager |
| **Deployment Manager** | YAML/Jinja/Python | Legacy | **End of support: Dec 31, 2025** -- migrate now |

### Terraform GCP Patterns

```hcl
# Cloud Run service with VPC connector
resource "google_cloud_run_v2_service" "api" {
  name     = "api-service"
  location = "us-central1"

  template {
    containers {
      image = "us-docker.pkg.dev/proj/repo/api:latest"
      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }
    }
    scaling {
      min_instance_count = 1
      max_instance_count = 100
    }
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = google_compute_network.vpc.id
        subnetwork = google_compute_subnetwork.subnet.id
      }
    }
  }
}

# GKE Autopilot cluster
resource "google_container_cluster" "autopilot" {
  name     = "prod-autopilot"
  location = "us-central1"

  enable_autopilot = true

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal"
    }
  }
}

# Workload Identity binding
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.ksa_name}]"
}
```

### Config Connector (K8s-Native IaC)

```yaml
# Config Connector: manage GCP resources as K8s objects
apiVersion: sql.cnrm.cloud.google.com/v1beta1
kind: SQLInstance
metadata:
  name: prod-postgres
spec:
  databaseVersion: POSTGRES_16
  region: us-central1
  settings:
    tier: db-custom-4-16384
    availabilityType: REGIONAL
    backupConfiguration:
      enabled: true
      pointInTimeRecoveryEnabled: true
    ipConfiguration:
      privateNetworkRef:
        name: prod-vpc
      ipv4Enabled: false
---
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: app-sa
spec:
  displayName: Application Service Account
```

---

## 9. Observability

### Google Cloud Observability Stack

| Service | Purpose | Key Feature |
|---------|---------|-------------|
| **Cloud Monitoring** | Metrics, dashboards, alerts | OTLP metrics ingestion (GA); MQL + PromQL query languages |
| **Cloud Logging** | Centralized log management | Log Analytics (BigQuery-based SQL on logs) |
| **Cloud Trace** | Distributed tracing | Auto-instrumentation for GCP services; OTLP traces |
| **Cloud Profiler** | Continuous CPU/heap profiling | Production profiling with <1% overhead |
| **Error Reporting** | Error aggregation | Auto-groups exceptions across services |

### Ops Agent and OpenTelemetry

The **Ops Agent** (v2.37.0+) is the primary telemetry collector for Compute Engine:
- Combines Fluent Bit (logs) + OpenTelemetry Collector (metrics + traces)
- **OTLP receiver** (GA): collect custom metrics and traces from OTel SDKs
- Replaces legacy Monitoring Agent and Logging Agent

**Managed OpenTelemetry for GKE**: fully managed OTel Collector deployment for Kubernetes workloads -- auto-scales, no manual DaemonSet management.

```yaml
# OpenTelemetry Collector config for GCP export
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  googlecloud:
    project: my-project-id

processors:
  batch:
    timeout: 5s
    send_batch_size: 200
  resourcedetection:
    detectors: [gcp]

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resourcedetection]
      exporters: [googlecloud]
    metrics:
      receivers: [otlp]
      processors: [batch, resourcedetection]
      exporters: [googlecloud]
```

```bash
# Install Ops Agent on Compute Engine
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Create uptime check
gcloud monitoring uptime create my-api-check \
  --display-name="API Health Check" \
  --monitored-resource-type=uptime-url \
  --host=api.example.com \
  --path=/health \
  --check-interval=60s
```

### Key Deprecation

Trace sinks deprecated as of Feb 2026 -- migrate to Observability Analytics. New projects after March 2026 auto-enable the Telemetry API alongside Cloud Logging API.

---

## 10. Cost Optimization

### Discount Mechanisms

| Mechanism | Savings | Commitment | Applies To |
|-----------|---------|------------|------------|
| **Committed Use Discounts (CUDs)** | Up to 57% | 1-year or 3-year | Compute Engine, Cloud SQL, GKE, Memorystore |
| **Sustained Use Discounts (SUDs)** | Up to 30% | Automatic (no commitment) | N1, N2 VMs running >25% of month |
| **Spot VMs** | Up to 91% | None (preemptible) | Fault-tolerant batch, CI/CD, data processing |
| **Flex CUDs** | Up to 46% | 1-year (flexible across machine types) | Any VM in same region |

**Spot vs Preemptible**: Spot VMs can run >24 hours (30-second termination notice); preemptible VMs hard-capped at 24 hours. Always prefer Spot.

### FinOps Tooling

```bash
# List active CUD recommendations
gcloud recommender recommendations list \
  --project=my-project \
  --recommender=google.compute.commitment.UsageCommitmentRecommender \
  --location=us-central1

# List idle VM recommendations
gcloud recommender recommendations list \
  --project=my-project \
  --recommender=google.compute.instance.IdleResourceRecommender \
  --location=us-central1-a

# Export billing data to BigQuery for analysis
bq mk --dataset billing_export
# Enable export in Cloud Console > Billing > Billing Export
```

**FinOps Hub**: unified dashboard showing active savings, optimization opportunities, and CUD utilization. Combines Recommender, Active Assist, and Cloud Billing in a single view.

### Cost Optimization Checklist

1. **Right-size VMs**: Apply Recommender suggestions for oversized instances
2. **Use Arm (C4A/T2A)**: 20-40% cheaper than x86 for compatible workloads
3. **CUDs for baseline**: Commit steady-state compute for 1-3 years
4. **Spot for batch**: CI/CD runners, data processing, ML training
5. **Autoscaling everywhere**: GKE HPA/VPA, Cloud Run min/max, Spanner autoscaler
6. **Storage lifecycle**: Autoclass for Cloud Storage, archive cold data
7. **BigQuery editions**: Standard/Enterprise slots instead of on-demand for predictable spend
8. **Label everything**: enforce labels for cost attribution (`team`, `env`, `service`)

---

## 11. AI/ML Infrastructure

### Accelerator Hardware

| Accelerator | Type | Peak Perf | Memory | Use Case |
|-------------|------|-----------|--------|----------|
| **TPU v5e** | Google TPU | Cost-optimized | 16 GB HBM2e/chip | Training + inference for mid-size models |
| **TPU v6e (Trillium)** | Google TPU | 4x v5e training perf | 32 GB HBM3/chip | Large model training (Gemma 2-27b, Llama 70B) |
| **TPU v7 (Ironwood)** | Google TPU | 4614 TFLOPs FP8/chip | HBM3e | Inference-optimized (first inference-specific gen) |
| **A3 High** | NVIDIA H100 | 3958 TFLOPS FP8 | 80 GB HBM3/GPU | LLM training, multi-node |
| **A3 Ultra** | NVIDIA H200 | 3.2 Tbps GPU-to-GPU | 141 GB HBM3e/GPU | RDMA over Converged Ethernet, largest models |
| **G2** | NVIDIA L4 | 485 TFLOPS INT8 | 24 GB GDDR6 | Inference, video transcoding, small training |

### Vertex AI Platform

- **Model Garden**: deploy open models (Llama, Gemma, Mistral) with one click; vLLM TPU serving
- **Gemini API**: Gemini 3.1 Flash-Lite (Preview) -- most cost-efficient for high-volume inference
- **Custom training**: distributed training on TPU pods or GPU clusters
- **Vertex AI Pipelines**: ML workflow orchestration (Kubeflow Pipelines or TFX)
- **Feature Store**: managed feature serving for online/offline ML

```bash
# Deploy model from Model Garden to endpoint
gcloud ai endpoints create \
  --region=us-central1 \
  --display-name=llama-endpoint

gcloud ai models upload \
  --region=us-central1 \
  --display-name=llama-3-8b \
  --container-image-uri=us-docker.pkg.dev/vertex-ai/prediction/vllm-tpu:latest \
  --artifact-uri=gs://model-artifacts/llama-3-8b/

# Cloud Run with GPU for lightweight inference
gcloud run deploy inference-service \
  --image=us-docker.pkg.dev/proj/repo/inference:latest \
  --gpu=1 --gpu-type=nvidia-l4 \
  --cpu=8 --memory=32Gi \
  --concurrency=4 \
  --region=us-central1
```

---

## 12. Multi-Cloud and Hybrid

### GKE Enterprise (formerly Anthos)

GKE Enterprise provides a consistent Kubernetes platform across environments:

| Capability | Description |
|------------|-------------|
| **Multi-cluster management** | Fleet API for unified cluster management |
| **Config Sync** | GitOps-based policy and config distribution |
| **Policy Controller** | OPA Gatekeeper-based guardrails |
| **Service Mesh** | Managed Istio (Cloud Service Mesh) |
| **Connect Gateway** | Secure access to registered clusters from anywhere |
| **Multi-team isolation** | Hierarchical resource management (team scopes, fleet namespaces) |

**Supported environments**: GCP, AWS (GKE on AWS), Azure (GKE on Azure), bare metal (Distributed Cloud), VMware (Distributed Cloud for VMware).

### BigQuery Omni

- Query data in **AWS S3** and **Azure Blob Storage** without moving it
- Powered by managed Anthos clusters in customer's cloud account
- Cross-cloud joins between Google Cloud and Omni regions (GA)
- Materialized views over S3 BigLake tables to reduce egress costs
- Same BigQuery SQL, same console, same IAM

### Google Distributed Cloud

- **Software-only (bare metal)**: GKE on customer hardware, air-gapped environments
- **Connected**: hybrid topology with control plane in Google Cloud
- **Edge**: Google-managed hardware at customer edge locations
- Currently on GKE 1.34 release track; Ubuntu 20.04 support removed (May 2025 EOL)

```bash
# Register an on-prem cluster to the fleet
gcloud container fleet memberships register on-prem-cluster \
  --context=on-prem-context \
  --kubeconfig=/path/to/kubeconfig \
  --enable-workload-identity \
  --project=my-project

# Enable Config Sync for GitOps
gcloud beta container fleet config-management apply \
  --membership=on-prem-cluster \
  --config=config-management.yaml
```

### Multi-Cloud Decision Framework

| Scenario | Recommendation |
|----------|---------------|
| K8s workloads across clouds | GKE Enterprise (fleet management, consistent API) |
| Analytics on data in AWS/Azure | BigQuery Omni (avoid data movement) |
| Regulated on-prem + cloud | Distributed Cloud (connected or air-gapped) |
| Edge/retail locations | Distributed Cloud Edge |
| Single cloud, GCP-native | Standard GKE + managed services (simplest path) |
