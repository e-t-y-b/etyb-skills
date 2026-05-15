# Cloud Infrastructure Pricing for Social Platforms

*Baseline pricing as of early-mid 2025. All prices US East / us-central1 unless noted. Use `WebSearch` for the latest numbers — cloud pricing changes incrementally.*

## Table of Contents
1. [AWS Pricing](#1-aws-pricing)
2. [GCP Pricing](#2-gcp-pricing)
3. [Cost Optimization Strategies](#3-cost-optimization-strategies)
4. [Scale Tier Cost Estimates](#4-scale-tier-cost-estimates)
5. [Open Source Alternatives](#5-open-source-alternatives)

---

## 1. AWS Pricing

### EC2 (Compute)

**On-Demand (per hour, Linux, US East):**

| Instance | vCPUs | RAM | $/hr | $/month |
|----------|-------|-----|------|---------|
| t3.medium | 2 | 4 GB | $0.042 | ~$30 |
| t3.xlarge | 4 | 16 GB | $0.166 | ~$121 |
| m6i.xlarge | 4 | 16 GB | $0.192 | ~$140 |
| m6i.2xlarge | 8 | 32 GB | $0.384 | ~$280 |
| c6i.xlarge | 4 | 8 GB | $0.170 | ~$124 |
| c6i.2xlarge | 8 | 16 GB | $0.340 | ~$248 |
| r6i.xlarge | 4 | 32 GB | $0.252 | ~$184 |
| r6i.2xlarge | 8 | 64 GB | $0.504 | ~$368 |

**Graviton ARM (~20% cheaper, often better perf):**
| Instance | vCPUs | RAM | $/hr | $/month |
|----------|-------|-----|------|---------|
| m7g.xlarge | 4 | 16 GB | $0.163 | ~$119 |
| c7g.xlarge | 4 | 8 GB | $0.145 | ~$106 |
| r7g.xlarge | 4 | 32 GB | $0.214 | ~$156 |

### ElastiCache (Redis)

| Node Type | RAM | $/hr | $/month |
|-----------|-----|------|---------|
| cache.t3.medium | 3 GB | $0.068 | ~$50 |
| cache.r6g.large | 13 GB | $0.228 | ~$166 |
| cache.r6g.xlarge | 26 GB | $0.455 | ~$332 |
| cache.r6g.2xlarge | 53 GB | $0.910 | ~$664 |

Serverless ElastiCache: ~$0.0034/ECPU-hour + $0.125/GB-hour stored

### Aurora (PostgreSQL/MySQL)

| Instance | vCPUs | RAM | $/hr | $/month |
|----------|-------|-----|------|---------|
| db.r6g.large | 2 | 16 GB | $0.260 | ~$190 |
| db.r6g.xlarge | 4 | 32 GB | $0.520 | ~$380 |
| db.r6g.2xlarge | 8 | 64 GB | $1.040 | ~$759 |

Storage: $0.10/GB-month. I/O: $0.20/M requests (Standard) or 0 with I/O-Optimized (+30% instance cost).
Aurora Serverless v2: ~$0.12/ACU-hour.

### DynamoDB

| Mode | Write Cost | Read Cost |
|------|-----------|-----------|
| On-Demand | $1.25/M WRU | $0.25/M RRU |
| Provisioned | $0.47/WCU-month | $0.09/RCU-month |

Storage: $0.25/GB-month. Global Tables: +~50% per replicated region.
DAX cache: dax.r5.large ~$0.269/hr (~$196/mo)

### S3 + CloudFront

**S3 Standard:** $0.023/GB-month (first 50 TB). PUT: $0.005/1K. GET: $0.0004/1K.
**S3 IA:** $0.0125/GB-month. **Intelligent-Tiering:** $0.023/GB + $0.0025/1K monitoring.

**CloudFront CDN:**
| Volume | $/GB (US/EU) |
|--------|-------------|
| First 10 TB | $0.085 |
| 10-50 TB | $0.080 |
| 50-150 TB | $0.060 |
| 500 TB-1 PB | $0.040 |

HTTPS requests: ~$0.01/10K

### MSK (Managed Kafka)

| Broker | $/hr | $/month (per broker) |
|--------|------|---------------------|
| kafka.m5.large | $0.21 | ~$153 |
| kafka.m5.xlarge | $0.42 | ~$307 |
| kafka.m7g.xlarge | $0.378 | ~$276 |

Minimum 3 brokers for production = ~$460-920/mo baseline.
Storage: $0.10/GB-month. Serverless: $0.75/cluster-hour + $0.10/GB.

### EKS
Control plane: $0.10/hr ($73/mo) per cluster.
Fargate pods: $0.04/vCPU-hr + $0.004/GB-hr (1 vCPU, 2GB pod ≈ $35/mo).

### Data Transfer (CRITICAL COST AT SCALE)
- Inbound: Free
- Outbound: First 100 GB free → $0.09/GB (up to 10 TB) → $0.085 → $0.07
- Cross-AZ: $0.01/GB each way ($0.02 round trip)
- Cross-region: $0.02/GB (US regions)
- NAT Gateway: $0.045/GB + $0.045/hr

**10 TB/mo outbound = ~$900.** Data transfer is a major hidden cost at scale.

### Lambda
Requests: $0.20/M. Compute: $0.0000167/GB-second. ARM: 20% cheaper.
Free tier: 1M requests + 400K GB-seconds/month.

---

## 2. GCP Pricing

### Compute Engine

| Machine | vCPUs | RAM | $/hr | $/month |
|---------|-------|-----|------|---------|
| e2-medium | 2 | 4 GB | $0.034 | ~$25 |
| e2-standard-4 | 4 | 16 GB | $0.134 | ~$98 |
| n2-standard-4 | 4 | 16 GB | $0.194 | ~$142 |
| n2-standard-8 | 8 | 32 GB | $0.388 | ~$283 |
| t2a-standard-4 (ARM) | 4 | 16 GB | $0.155 | ~$113 |

GCP offers **sustained use discounts** (SUDs) automatically: up to 30% off for running all month.

### Cloud Memorystore (Redis)
| Config | Monthly |
|--------|---------|
| Basic, 5 GB | ~$175 |
| Standard (HA), 5 GB | ~$350 |
| Standard (HA), 26 GB | ~$800 |

Generally 10-30% more expensive than ElastiCache.

### Cloud SQL (PostgreSQL)
| Instance | vCPUs | RAM | Monthly |
|----------|-------|-----|---------|
| db-custom-2-8192 | 2 | 8 GB | ~$130 |
| db-custom-4-16384 | 4 | 16 GB | ~$260 |
| db-custom-8-32768 | 8 | 32 GB | ~$520 |

HA adds ~2x cost. Storage: $0.17/GB-month (SSD).

### Cloud Spanner
Regional: $0.90/node-hour (~$657/mo). Multi-region: $2.70/node-hour (~$1,971/mo).
Powerful but expensive — use only when you need globally consistent distributed SQL.

### Cloud Storage + CDN
Storage: $0.020/GB-month (slightly cheaper than S3).
CDN: First 10 TB $0.08/GB (US/Canada), 10-150 TB $0.055/GB.

### GKE
Autopilot: No cluster fee, ~$0.045/vCPU-hr + $0.005/GB-hr.
Standard: $0.10/hr per cluster + node costs. 1 zonal cluster free.

### Pub/Sub (vs Kafka)
$40/TiB delivered. Much cheaper than managed Kafka for moderate throughput.
At very high throughput (>100 MB/s), self-hosted Kafka becomes more cost-effective.

### BigQuery
On-demand: $6.25/TB queried (first 1 TB/mo free).
Storage: $0.02/GB-month (active), $0.01/GB-month (long-term).

---

## 3. Cost Optimization Strategies

### Reserved/Committed Pricing

| Strategy | Savings |
|----------|---------|
| 1-year Reserved (no upfront, AWS) | 30-36% |
| 1-year Reserved (all upfront, AWS) | 36-40% |
| 3-year Reserved (all upfront, AWS) | 55-63% |
| 1-year CUD (GCP) | ~37% |
| 3-year CUD (GCP) | ~55% |
| Spot/Preemptible | 60-91% |
| GCP Sustained Use Discount | ~30% automatic |
| AWS Savings Plans | 30-60% |

**Recommendation:** Reserve baseline capacity (API servers, databases). Use spot for stateless background workers (feed generation, media transcoding, notifications). Use spot fleet with multiple instance types for availability.

### Multi-Region Cost Impact

| Component | Single-Region | Multi-Region Premium |
|-----------|--------------|---------------------|
| Compute | 1x | 2-3x |
| Aurora Global DB | 1x | ~2x + replication I/O |
| Spanner multi-region | 1x | ~3x |
| DynamoDB Global Tables | 1x | ~1.5x per region |
| S3 replication | 1x | +$0.02/GB transfer + storage |

**Recommendation:** Start single-region. Add CDN edge caching first (handles most read latency). Go multi-region for data only when you have genuine latency requirements or compliance needs.

### CDN Optimization
- Origin shield / cache fill reduction to minimize origin requests
- Long TTLs for media (immutable once uploaded)
- S3 directly for infrequent assets
- At >100 TB/mo, negotiate committed use with CloudFront
- **Cloudflare R2**: Zero egress fees for storage (S3-compatible, $0.015/GB-month)

### Database Optimization
- Read replicas for 90%+ read workloads: 1 primary + 2-3 replicas
- Redis in front of DB: single r6g.xlarge ($332/mo) handles 100K+ ops/sec
- Connection pooling (PgBouncer): smaller instances, less overhead
- Aurora I/O-Optimized: switch when I/O > 25% of DB bill
- DynamoDB auto-scaling with provisioned mode (40-50% cheaper than on-demand once patterns are predictable)
- Hot/cold data split: recent 30 days in fast storage, archive to S3/Glacier

---

## 4. Scale Tier Cost Estimates

### Startup: <100K MAU (~$1,100-1,500/mo)

| Component | Spec | Monthly |
|-----------|------|---------|
| API Servers | 2x t3.xlarge | $242 |
| Background Workers | 2x t3.large (spot) | $60 |
| PostgreSQL (Aurora) | db.r6g.large + 1 replica | $380 |
| Redis (ElastiCache) | cache.r6g.large | $166 |
| S3 Storage | 500 GB | $12 |
| CloudFront CDN | 1 TB transfer | $85 |
| EKS cluster | 1 cluster | $73 |
| Data transfer + misc | | $95 |
| **Total** | | **~$1,100-1,500** |

With reserved: **~$800-1,100/mo**

### Growth: ~1M MAU (~$6,700-8,000/mo)

| Component | Spec | Monthly |
|-----------|------|---------|
| API Servers | 6x m6i.xlarge (3 reserved) | $580 |
| Background Workers | 4x c6i.xlarge (spot) | $200 |
| Aurora PostgreSQL | db.r6g.2xlarge + 2 replicas | $2,277 |
| Redis cluster | 3x cache.r6g.xlarge | $996 |
| DynamoDB (feeds) | Provisioned | $500 |
| S3 Storage | 5 TB | $115 |
| CloudFront CDN | 10 TB | $850 |
| MSK (Kafka) | 3x kafka.m5.large | $460 |
| EKS + Lambda + monitoring | | $323 |
| Data transfer | 5 TB | $400 |
| **Total** | | **~$6,700-8,000** |

With optimization: **~$5,000-6,500/mo**

### Scale: 10M+ MAU (~$42,000-55,000/mo)

| Component | Spec | Monthly |
|-----------|------|---------|
| API Servers | 20x m7g.2xlarge (reserved) | $3,500 |
| Background Workers | 15x c7g.xlarge (spot) | $800 |
| Aurora PostgreSQL | Multi-AZ db.r6g.4xlarge + 5 replicas | $12,000 |
| Redis cluster | 6x cache.r6g.2xlarge (sharded) | $3,984 |
| DynamoDB + DAX | Heavy provisioned | $3,000 |
| S3 Storage | 50 TB | $1,150 |
| CloudFront CDN | 100 TB | $6,000 |
| MSK (Kafka) | 6x kafka.m7g.xlarge | $1,656 |
| EKS + Lambda | | $646 |
| Data transfer | 50 TB | $3,500 |
| WAF + Shield | DDoS protection | $3,000 |
| Media processing | Transcoding (spot GPU) | $2,000 |
| Monitoring | Full observability | $1,000 |
| **Total** | | **~$42,000-55,000** |

With 3yr reserved + spot + negotiated: **~$30,000-40,000/mo**

At 50M+ MAU: $150K-300K/mo. Negotiate Enterprise Discount Program (EDP) for 10-20% blanket discount.

---

## 5. Open Source Alternatives

### Self-Hosted Redis vs ElastiCache
| Factor | ElastiCache (26 GB HA) | Self-Hosted |
|--------|----------------------|-------------|
| Cost | ~$664/mo | ~$280/mo (EC2 r6g.xlarge) |
| Savings | Baseline | ~55-60% |
| Ops overhead | None | Moderate |

Consider **KeyDB** (multi-threaded Redis fork) for better per-instance performance.

### Self-Hosted Kafka vs MSK
| Factor | MSK (3-broker) | Self-Hosted |
|--------|---------------|-------------|
| Cost | ~$460-920/mo | ~$300-420/mo |
| Savings | Baseline | ~30-50% |

**Redpanda** (Kafka API-compatible, no JVM, no ZooKeeper): A 3-node cluster handles what typically takes 6-9 Kafka brokers.

### ScyllaDB vs DynamoDB
| Factor | DynamoDB (50K WCU/200K RCU) | ScyllaDB |
|--------|-----------------------------|----------|
| Cost | ~$12,000/mo | ~$2,400/mo |
| Savings | Baseline | ~75-80% |
| Latency | Single-digit ms | Sub-ms (P99) |

ScyllaDB Cloud (managed): ~50-60% of DynamoDB cost.

### Other Alternatives

| Managed | Open Source | Savings |
|---------|-----------|---------|
| Aurora | PostgreSQL + Patroni | ~40-50% |
| CloudWatch | Prometheus + Grafana + Loki | ~70-80% |
| AWS ALB | Nginx/Envoy on EC2 | ~50% |
| Elasticsearch Service | Self-hosted OpenSearch | ~50-60% |
| SQS/SNS | NATS or RabbitMQ | ~60-70% |

### Cloudflare R2 (Zero Egress)
S3-compatible, $0.015/GB-month storage, **$0 egress**.
At 10 TB/mo egress, saves ~$900/mo vs S3+CloudFront.
Best middle ground between self-hosted and fully managed.

---

## Summary: Cost Optimization Playbook

1. **Start on AWS** with Aurora PostgreSQL + ElastiCache + S3/CloudFront (~$1-2K/mo)
2. **At growth** (1M MAU): introduce DynamoDB or ScyllaDB for feeds, add Kafka/Redpanda, reserve instances (~$5-8K/mo)
3. **At scale** (10M+ MAU): biggest drivers are CDN egress, database compute, data transfer. Negotiate enterprise pricing, Graviton everywhere, consider R2 for media, evaluate self-hosted alternatives
4. **Cost levers** in order of impact: Reserved pricing (30-60%) → ARM instances (20%) → Spot workers (60-80%) → Aggressive caching → R2/CDN negotiation → Self-hosted at scale
