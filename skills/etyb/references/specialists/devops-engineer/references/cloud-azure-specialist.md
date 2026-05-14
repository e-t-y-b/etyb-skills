# Azure Cloud Specialist — Deep Reference

**Always use `WebSearch` to verify version numbers, pricing, and feature availability before giving advice. Azure evolves rapidly — this reference provides architectural context and decision frameworks current as of early 2026.**

## Table of Contents
1. [Compute](#1-compute)
2. [Networking](#2-networking)
3. [Storage](#3-storage)
4. [Databases](#4-databases)
5. [Security & Identity](#5-security--identity)
6. [Serverless & Event-Driven](#6-serverless--event-driven)
7. [DevOps & Developer Tools](#7-devops--developer-tools)
8. [Infrastructure as Code](#8-infrastructure-as-code)
9. [Observability](#9-observability)
10. [AI/ML Infrastructure](#10-aiml-infrastructure)
11. [Cost Optimization](#11-cost-optimization)
12. [Hybrid & Multi-Cloud](#12-hybrid--multi-cloud)
13. [Decision Frameworks](#13-decision-frameworks)

---

## 1. Compute

### Azure Virtual Machines — Latest Series

#### Cobalt 100 Arm-Based VMs (GA)
- **Series**: Dpsv6, Dplsv6 (general purpose), Epsv6, Epdsv6 (memory-optimized)
- **Processor**: Microsoft Cobalt 100 — first-generation custom Arm-based CPU at 3.4 GHz
- **Key benefit**: Up to 50% improved price-performance over x86 equivalents with energy-efficient Arm architecture
- **Each vCPU = one physical core** — no hyper-threading ambiguity
- **Best for**: Linux workloads, web servers, microservices, dev/test, Java/.NET/Node apps compiled for Arm
- **Not ideal for**: Windows-only workloads, legacy x86 dependencies

#### Dv6/Ev6 Series — Intel-Based (GA)
- **Processor**: 5th Gen Intel Xeon (Emerald Rapids) with Azure Boost
- **Dv6 (general purpose)**: Up to 128 vCPUs, 512 GiB RAM
- **Ev6 (memory-optimized)**: Up to 192 vCPUs, 1.8 TiB RAM
- **Azure Boost**: Offloads networking and storage to dedicated hardware — reduces host CPU overhead, improves latency
- **Best for**: Enterprise workloads requiring x86 compatibility, SQL Server, Windows Server

#### GPU-Accelerated VMs (NC/ND Series)
- **NCads H100 v5**: Up to 2x NVIDIA H100 NVL GPUs (94 GB each), 96 AMD EPYC Genoa cores, 640 GiB RAM — for AI training and batch inference
- **NCv6 (Preview Nov 2025)**: NVIDIA RTX PRO 6000 Blackwell Server Edition — dual engine for industrial digitalization + cost-effective LLM inference
- **ND H200 v5**: NVIDIA H200 with 141 GB HBM3e per GPU — for large-scale distributed training
- **GPU stack**: T4, A10, A100, H100, H200, and GB200 Grace Blackwell Superchip available across series

#### VM Decision Quick Reference
| Workload | Recommended Series | Key Advantage |
|----------|-------------------|---------------|
| Web/API (Linux) | Dpsv6 (Cobalt 100) | Best price-performance |
| General purpose (Windows) | Dv6 | Intel compatibility + Azure Boost |
| Memory-intensive DBs | Ev6 / Epdsv6 | Up to 1.8 TiB RAM |
| AI/ML training | NCads H100 v5 / ND H200 v5 | NVIDIA H100/H200 GPUs |
| AI inference (cost-effective) | NCv6 (Blackwell) | RTX PRO 6000 |
| Burstable dev/test | B-series v2 | Low cost, credit-based bursting |

### Azure Kubernetes Service (AKS)

#### AKS Automatic Mode (GA)
- **Production-ready clusters with intelligent defaults** — Azure handles node setup, networking, security policies, and service integrations
- **Enabled by default**: HPA (Horizontal Pod Autoscaler), VPA (Vertical Pod Autoscaler), KEDA (event-driven autoscaling), Node Autoprovision
- **Managed add-ons**: Azure Monitor, Azure Policy, Key Vault CSI driver, Workload Identity pre-configured
- **Best for**: Teams that want Kubernetes without the operational overhead of cluster configuration
- **Limitation**: Less customization than standard AKS mode — use standard mode for advanced networking/security scenarios

#### KEDA Integration (Event-Driven Autoscaling)
- **Current versions**: KEDA 2.16 on K8s >= 1.32; KEDA 2.14 on K8s 1.30/1.31
- **Now supported in AKS Long-Term Support (LTS)**
- **Breaking change in 2.15+**: Pod identity support removed — must migrate to Workload Identity for authentication
- **Scale-to-zero**: Core capability — event-driven scaling for sustainable, cost-efficient resource usage
- **Scalers**: 60+ built-in scalers for Azure Service Bus, Event Hubs, Storage Queues, Cosmos DB, Kafka, Prometheus metrics, cron, and more
- **Install**: Built into AKS Automatic; available as an add-on in standard AKS

#### AKS Best Practices (2025-2026)
- **Use AKS Automatic** for new projects unless you need advanced customization
- **Workload Identity** is the standard auth model (replaces Pod Identity and Pod Identity v2)
- **Azure CNI Overlay** recommended for new clusters — better IP address management
- **Istio-based service mesh** add-on available as managed option
- **Artifact Streaming (Preview)**: Lazy-load container images to reduce cold start times
- **Draft for AKS**: CLI tool to generate Dockerfiles, Helm charts, K8s manifests, and GitHub Actions workflows

### Azure Container Apps (ACA)

#### Core Capabilities
- **Serverless containers on Kubernetes** — fully managed, no cluster management
- **Automatic scaling**: HTTP-based, KEDA event-driven, or schedule-based; supports scale-to-zero
- **Revisions and traffic splitting**: Canary deployments, A/B testing with percentage-based routing
- **Built-in auth (Easy Auth)**: Azure AD, Google, Facebook, Twitter, custom OIDC providers — no code changes needed
- **Custom domains with managed certificates**: Automatic TLS certificate provisioning and renewal
- **Private networking**: VNet integration, internal-only ingress

#### Dapr Integration
- **Dapr sidecar as a managed feature** — enable per container app
- **Current version**: Dapr 1.13.6-msft.6+ (Microsoft-managed fork with Azure-specific enhancements)
- **Supported building blocks**: Service invocation, state management, pub/sub, bindings, secrets, configuration, actors
- **Versions include `-msft` suffix** for Azure-specific patches
- **Auto-updated**: Latest secure versions applied automatically

#### Container Apps Jobs
- **Event-driven, scheduled, or manual job execution** — not long-running services
- **Supports Dapr, Ingress with custom domains/SSL**
- **Job types**: Scheduled (cron), event-triggered (KEDA scalers), manual
- **Use cases**: Batch processing, ETL pipelines, ML training, data migrations

#### Azure Functions on Container Apps
- **Run Azure Functions runtime inside Container Apps** — get the Functions programming model with ACA's scaling
- **Deployed as ACA resources** when used with .NET Aspire
- **Caveat**: Event-driven scaling not yet available for Functions on ACA in Aspire deployments

### Azure Functions

#### Flex Consumption Plan (GA)
- **Pay-per-execution with pre-provisioned instances** — eliminates cold starts for critical paths
- **Instance sizes**: 512 MB and 2048 MB options
- **Zone redundancy**: Generally available — deploy across availability zones
- **Always-ready instances**: Specify minimum instances to keep warm
- **Concurrency**: Configure HTTP and non-HTTP per-instance concurrency
- **Networking**: Full VNet integration with private endpoints
- **Best for**: Production serverless workloads that need both cost efficiency and consistent performance

#### Durable Functions v3 (GA)
- **Durable Task Scheduler**: New storage provider — managed, lower-latency alternative to Azure Storage tables
- **Azure Storage v2 accounts**: Improved cost efficiency with upgraded SDKs
- **Distributed Tracing**: Track orchestrations and activities across function invocations
- **Extended Sessions**: Available in .NET isolated worker model for improved performance
- **Supported storage providers on Flex Consumption**: Azure Storage and Durable Task Scheduler only

#### .NET Aspire Integration
- **First-class support** for .NET 8 and .NET 9 projects
- **Deploy as ACA resources** when deploying Aspire solutions to Azure
- **Local development**: F5 debugging with Aspire dashboard for distributed tracing
- **Current limitation**: Functions projects in Aspire deploy without event-driven scaling

#### Runtime Evolution
- **Isolated worker model is the future** — in-process model deprecated, phased out by 2026
- **.NET 10 with Native AOT**: Sub-50ms startup times, 60-80% memory reduction — changes cold-start economics
- **Language support**: .NET, Java, Python, JavaScript/TypeScript, PowerShell, Go (custom handler)

---

## 2. Networking

### Azure Front Door (Standard/Premium)

#### Architecture
- **Global Layer 7 load balancer + CDN + WAF** in a single service
- **118+ edge locations** across 100+ metro areas
- **Anycast routing**: Users connect to the nearest edge POP
- **Azure Private WAN backbone**: Traffic stays on Microsoft's network after entering the edge

#### Key Features
- **WAF (Web Application Firewall)**:
  - Premium SKU: Microsoft Threat Intelligence rules, CRS 3.2 signatures, Bot Manager
  - Protection against OWASP Top 10 and automated bot threats
  - Custom rules for geo-filtering, rate limiting, IP restriction
- **Private Link origins** (Premium only): Connect to origins via Private Link — zero public-internet exposure, zero-trust model
  - Supports: Azure App Service, Azure Storage, Azure Load Balancer (internal), any Private Link-enabled service
  - **Industry first**: CDN with native private endpoint origin support
- **CDN capabilities**: Dynamic site acceleration, large file optimization, media streaming, rules engine
- **Configuration propagation**: Up to 20 minutes for create/update/delete/WAF/cache purge operations

#### Migration Note
- **Azure CDN from Microsoft (classic)** is being retired — migrate to Azure Front Door Standard/Premium
- Front Door subsumes all CDN Classic functionality plus adds WAF and Private Link

### Azure Application Gateway v2

- **Layer 7 (HTTP/HTTPS) regional load balancer** with WAF integration
- **Layer 4 (TCP/TLS) proxy support**: Now in public preview — extends beyond HTTP
- **Autoscaling**: Elastic scaling based on traffic load — no pre-provisioned capacity needed
- **Zone redundancy**: Automatic multi-AZ deployment
- **Static VIP**: Guaranteed stable IP for the lifetime of the deployment
- **URL rewriting + header manipulation**: Request/response header add/remove/update, URL rewrite, query string modification
- **Private deployment**: Fully private Application Gateway with no public IP for internal-only traffic
- **FIPS 140-2 validated mode**: For regulated workloads (government, finance)
- **5x TLS offload performance** improvement over v1 SKU
- **When to use**: Regional L7 load balancing, SSL termination, path-based routing, WAF for a single region

### Azure Load Balancer

- **Layer 4 (TCP/UDP) load balancer** — ultra-low latency, millions of flows per second
- **Standard SKU** (recommended): Zone-redundant, supports Availability Zones, health probes, outbound rules
- **Gateway Load Balancer**: Chain third-party NVAs (firewalls, packet analyzers) transparently
- **Cross-region Load Balancer**: Global L4 load balancing across Azure regions
- **When to use**: Non-HTTP traffic, high-throughput scenarios, NVA chaining, backend for Application Gateway

### Azure Virtual WAN

- **Hub-and-spoke network topology as a managed service**
- **Integrated services**: VPN Gateway (site-to-site, point-to-site), ExpressRoute Gateway, Azure Firewall, NVAs
- **Forced tunneling for Secure Virtual Hubs** (Preview): Route all internet-bound traffic through central hub for inspection
- **Azure Route Server**: Now supports up to 500 VNet connections (spokes) per route server
- **VPN Gateway throughput**: Up to 20 Gbps aggregate, 5 Gbps per tunnel (GA upgrade)
- **Best for**: Organizations with multiple branches, complex hybrid connectivity requirements

### Azure Private Link / Private Endpoints

- **Private connectivity to Azure PaaS services** over your VNet — no public internet traversal
- **Supported services**: 100+ Azure services including Storage, SQL, Cosmos DB, Key Vault, App Service, AKS API server
- **Private DNS Zones**: Automatic DNS resolution for private endpoints
- **Cross-subscription and cross-tenant**: Connect to services in different subscriptions/tenants
- **Works with Virtual WAN**: Traffic routed through hub components (ExpressRoute/VPN Gateway, Azure Firewall)
- **Best practice**: Enable Private Link for all PaaS services in production environments

### Azure ExpressRoute

- **Dedicated private fiber connections** from on-premises to Azure (not over public internet)
- **Bandwidth**: 50 Mbps to 100 Gbps; **400 Gbps Direct ports** announced for 2026 (for AI supercomputing)
- **Global Reach**: Connect on-premises sites through Microsoft backbone
- **FastPath**: Bypass ExpressRoute Gateway for improved data path performance to VMs
- **IPsec over ExpressRoute**: Encrypted private links via Virtual WAN
- **Peering types**: Azure private peering, Microsoft peering

### Azure Firewall

- **Cloud-native, stateful firewall as a service** with built-in HA and cloud scalability
- **Premium SKU**: TLS inspection, IDPS (Intrusion Detection and Prevention), URL filtering, web categories
- **Basic SKU**: For SMBs with simplified threat protection needs
- **Integrates with Virtual WAN** as Secure Virtual Hub
- **Firewall Policy**: Hierarchical policies for enterprise-wide rule management
- **Threat intelligence**: Microsoft Threat Intelligence feed for known malicious IPs/domains

### Azure Network Watcher

- **Diagnostic and monitoring tool suite** for Azure networking
- **Key tools**: Connection Monitor, NSG Flow Logs (migrating to VNet Flow Logs by mid-2025), IP flow verify, next hop analysis, packet capture
- **Traffic Analytics**: Visualizes network activity, identifies hotspots, detects malicious IPs using Microsoft Threat Intelligence
- **VNet Flow Logs**: Successor to NSG flow logs — addresses limitations, mandatory migration by June 2025
- **Processing intervals**: 60 min default or 10 min accelerated

### Azure Traffic Manager

- **DNS-based global traffic distribution** — routes at the DNS level, not the data path
- **Routing methods**: Priority, Weighted, Performance, Geographic, Multivalue, Subnet
- **Health monitoring**: Endpoint health probes with automatic failover
- **When to use over Front Door**: Non-HTTP protocols, DNS-level routing, simpler global distribution needs
- **Limitation**: No WAF, no SSL termination, no connection-level load balancing (DNS only)

---

## 3. Storage

### Azure Blob Storage

#### Access Tiers
| Tier | Use Case | Access Cost | Storage Cost | Minimum Retention |
|------|----------|-------------|--------------|-------------------|
| **Premium** | Performance-sensitive, low-latency | Low | Highest | None |
| **Hot** | Frequently accessed data | Low | High | None |
| **Cool** | Infrequent access (30+ days) | Medium | Medium | 30 days |
| **Cold** | Rare access (90+ days) | Higher | Lower | 90 days |
| **Archive** | Compliance/backup (180+ days) | Highest (rehydration) | Lowest | 180 days |

#### Lifecycle Management Policies
- **Automated tiering**: Rules to move data between Hot -> Cool -> Cold -> Archive based on last access time or creation date
- **Automated deletion**: Delete blobs after specified period
- **Scope**: Apply per container, per blob prefix, or across entire storage account
- **Immutability interaction**: `Set Blob Tier` works even with locked immutability policies (rehydration allowed) — but `delete` action blocked by immutability
- **Best practice**: Combine lifecycle policies with access tracking to move rarely accessed data to Cold/Archive automatically

#### Immutable Storage (WORM)
- **Time-based retention policies**: Data cannot be modified or deleted for specified period
- **Legal holds**: Indefinite immutability until hold is removed
- **Version-level immutability**: Apply policies per blob version
- **Compliance**: SEC 17a-4(f), CFTC 1.31, FINRA 4511 compliant
- **Important**: Once locked, retention period can only be extended, never shortened

### Azure Files

- **Fully managed SMB/NFS file shares** in the cloud
- **SMB 3.0/3.1.1**: Windows, Linux, macOS compatible; Active Directory authentication
- **NFS 4.1**: Linux workloads; Premium tier only
- **Tiers**: Premium (SSD, provisioned), Transaction Optimized (HDD), Hot, Cool
- **Azure File Sync**: Cache Azure file shares on Windows Server for local performance with cloud tiering
- **Snapshot support**: Share-level snapshots for point-in-time recovery
- **Maximum share size**: 100 TiB with large file share support
- **Identity-based auth**: Azure AD DS, on-premises AD DS, Azure AD Kerberos

### Azure Managed Disks

#### Disk Types (2025)
| Type | Max Size | Max IOPS | Max Throughput | Latency | Use Case |
|------|----------|----------|----------------|---------|----------|
| **Ultra Disk** | 64 TiB | 400K | 10 Gbps | Sub-ms | SAP HANA, tier-1 DBs |
| **Premium SSD v2** | 64 TiB | 80K | 1.2 Gbps | Sub-ms | Most production workloads |
| **Premium SSD** | 32 TiB | 20K | 900 MBps | Single-digit ms | Production VMs |
| **Standard SSD** | 32 TiB | 6K | 750 MBps | Single-digit ms | Web servers, dev/test |
| **Standard HDD** | 32 TiB | 2K | 500 MBps | Variable | Backups, non-critical |

#### Premium SSD v2 Key Features
- **Granular IOPS/throughput tuning**: Adjust independently of capacity — up to 4 changes per 24 hours
- **Baseline**: 3,000 IOPS + 125 MB/s at no additional cost regardless of size
- **No downtime disk expansion**: Dynamically expand capacity using NVMe controllers
- **Direct conversion**: Convert Standard HDD/SSD and Premium SSD to Premium SSD v2 in-place (GA)
- **Instant Access Snapshots**: Restore disks immediately after snapshot creation while hydration continues in background
- **Azure Site Recovery support**: GA for VMs with Premium SSD v2 and Ultra Disks

### Azure Data Lake Storage Gen2

- **Built on Azure Blob Storage** with hierarchical namespace (HNS) for file system semantics
- **Petabyte-scale**: Hundreds of gigabits throughput sustained
- **ABFS driver**: Optimized for big data analytics workloads (Spark, Databricks, Synapse)
- **Access control**: POSIX ACLs + Azure RBAC — fine-grained file/directory permissions
- **Integration**: Native connector for Azure Synapse, Azure Databricks, Azure HDInsight, Microsoft Fabric
- **Cost**: Same pricing as Blob Storage tiers (Hot/Cool/Archive)
- **Best practice**: Enable HNS at storage account creation — cannot be enabled retroactively on existing accounts

### Azure NetApp Files

- **Enterprise-grade NAS** — NFS, SMB, and REST API access on Azure
- **Recent enhancements (2025)**:
  - **Large volumes**: Up to 7.2 PiB on dedicated capacity (extended from 2 PiB limit)
  - **Small volumes**: Now supports volumes as small as 50 GiB
  - **Cache volumes**: Cloud-based caches of external origin volumes for reduced WAN latency
  - **Cool access**: Extended to large volumes for cost-effective storage of infrequently accessed data
  - **Windows Server 2025 AD support**: For SMB and dual-protocol volumes
  - **Quota reporting**: Visibility into limits, used capacity, percentage utilization
- **Service levels**: Standard (16 MiB/s per TiB), Premium (64 MiB/s per TiB), Ultra (128 MiB/s per TiB)
- **AI integration**: Tight integration with Azure AI Search, Microsoft Foundry, Databricks, OneLake
- **When to use over Azure Files**: SAP HANA, Oracle, high-performance Linux workloads, lift-and-shift NAS migrations

---

## 4. Databases

### Azure SQL Database

#### Hyperscale Tier
- **Auto-scaling storage**: Up to 100 TB — storage grows automatically, no pre-provisioning
- **Rapid scale-out**: Up to 4 named read replicas for read-heavy workloads
- **Fast backups**: Near-instantaneous regardless of database size (snapshot-based)
- **Serverless compute**: Automatic scale-up/down based on workload demand (note: auto-pause NOT supported in Hyperscale)
- **RBPEX cache**: Resilient buffer pool extension — auto-grows and shrinks with workload demand in serverless
- **Simplified pricing** (since Dec 2023): Reduced compute prices for all new Hyperscale databases, serverless, and elastic pools

#### Hyperscale Elastic Pools (GA)
- **Pool Hyperscale databases** to share compute resources and optimize cost
- **Zone redundancy**: Available for Hyperscale elastic pools
- **Premium-series hardware**: PRMS / MOPRMS with reserved capacity
- **Maintenance windows**: Configurable for Hyperscale elastic pools
- **Best for**: Multi-tenant SaaS workloads with varying resource demands across databases

#### Serverless Compute
- **Auto-pause**: Available in General Purpose tier (not Hyperscale)
- **Billing**: Pay only for compute used, billed per second
- **Min/max vCores**: Configure bounds for auto-scaling
- **Best for**: Intermittent, unpredictable workloads; dev/test environments

### Azure Cosmos DB

#### API Models
| API | Best For | Wire Protocol |
|-----|----------|---------------|
| **NoSQL** | New apps, document data, vector search | Native REST/SDK |
| **MongoDB (vCore)** | MongoDB-compatible apps, vector search | MongoDB 6.0+ wire protocol |
| **PostgreSQL** (Retiring) | Distributed PostgreSQL — **use Azure DB for PostgreSQL Elastic Clusters instead** | PostgreSQL wire protocol |
| **Apache Cassandra** | Cassandra-compatible wide-column | CQL wire protocol |
| **Apache Gremlin** | Graph databases | Gremlin/TinkerPop |
| **Table** | Key-value, Azure Table migration | Table Storage REST API |

#### Vector Search (GA)
- **NoSQL API**: DiskANN-based vector indexing — multi-modal, high-dimensional vectors at any scale
  - Millions of QPS with predictable low latency
  - Supports quantized flat, flat, and DiskANN index types
  - Integrated with Azure OpenAI for embedding generation
- **MongoDB vCore API**: `$vectorSearch` operator with MongoDB-compatible syntax
  - HNSW and IVF index types
  - Ideal for teams with existing MongoDB expertise
- **Enhanced features in development**: Larger vector datasets, ultra-high throughput inserts

#### Azure DocumentDB (formerly Cosmos DB for MongoDB vCore)
- **Rebranded**: Now built on open-source DocumentDB engine
- **MongoDB-compatible** with built-in vector search, full-text search
- **Enterprise security**: Azure AD integration, private endpoints, encryption at rest
- **Cost efficiency**: Pay for provisioned compute + storage (not RU-based)

#### Cosmos DB for PostgreSQL — RETIREMENT NOTICE
- **No longer recommended for new projects**
- **Replacement**: Azure Database for PostgreSQL with Elastic Clusters (Citus extension)
- **Action**: Migrate existing workloads to Azure DB for PostgreSQL Flex Server with Elastic Clusters

### Azure Database for PostgreSQL Flexible Server

- **The primary Azure managed PostgreSQL service** — Single Server is retired (March 2025)
- **PostgreSQL versions**: 13, 14, 15, 16 supported
- **Elastic Clusters (Citus)**: Horizontal scale-out / distributed PostgreSQL — replacement for Cosmos DB for PostgreSQL
- **Zone-resilient HA**: Synchronous replication across AZs with automatic failover
- **Read replicas**: Up to 5 read replicas for read scale-out
- **Predictable performance**: Configurable IOPS with Premium SSD v2 support
- **Custom maintenance windows**: Schedule update windows
- **PgBouncer built-in**: Connection pooling as a managed feature
- **Extensions**: PostGIS, pgvector, pg_cron, pg_stat_statements, and 50+ others
- **AI integration**: pgvector extension for vector similarity search

### Azure Cache for Redis / Azure Managed Redis

#### Service Evolution (2025-2026)
- **Azure Cache for Redis** (classic): Basic, Standard, Premium tiers — **retirement in progress**, migration tooling phased rollout:
  - Basic/Standard/Premium: Tooling from Nov 2025
  - Enterprise/EnterpriseFlash: Tooling from March 2026
  - Expect brief DNS blip (seconds) during migration

- **Azure Managed Redis** (new, GA): The successor service, powered by Redis Ltd. enterprise technology
  - **Tiers**: Compute Optimized, Balanced, Memory Optimized, Flash Optimized
  - **SKU sizes**: 150 and 250 SKUs now GA (Ignite 2025 announcement)
  - **Flash Optimized**: Auto-moves cold data from memory to NVMe — large cache at lower cost
  - **Reserved Instances**: 35% discount (1-year), 55% discount (3-year) in 30+ regions
  - **Features**: Active geo-replication, RediSearch, RedisJSON, RedisTimeSeries, RedisBloom

#### Valkey Status on Azure
- **No managed Valkey offering** — Azure partners with Redis Ltd., unlike AWS (ElastiCache/Valkey) and GCP
- **Self-hosted Valkey**: Can run on AKS or VMs if needed
- **Guidance**: Use Azure Managed Redis for managed experience; self-host Valkey only if license/strategic concerns require it

### Azure SQL Managed Instance

#### SQL Server 2025 Update Policy (GA — March 2026)
- **Update policy as instance configuration** — choose between:
  - Latest SQL engine features (rolling updates)
  - Fixed SQL Server 2022 or 2025 feature set
- SQL Server 2025 becomes the default policy in Azure portal March 2026

#### Key SQL Server 2025 Features on Managed Instance
- **Vector data type and functions**: Native vector operations for AI workloads
- **Optimized locking**: Enabled by default for all user databases
- **Change Event Streaming**: Near real-time DML change capture published to Azure Event Hubs
- **sp_invoke_external_rest_endpoint**: Call external HTTPS REST APIs directly from T-SQL
- **UNISTR syntax**: Unicode string literals support

#### Managed Instance Link (GA)
- **Distributed availability group** connecting on-premises SQL Server to Azure SQL MI
- **Near real-time data replication** from SQL Server 2022/2025
- **Disaster recovery**: Manual failover to MI during disaster, fail back after mitigation
- **Use cases**: Hybrid cloud, migration with minimal downtime, offload reporting to cloud

---

## 5. Security & Identity

### Microsoft Entra ID (formerly Azure AD)

#### Core Capabilities
- **Cloud identity provider**: SSO, MFA, Conditional Access, Identity Protection
- **Hybrid identity**: Azure AD Connect Sync (now supports Windows Server 2025), Azure AD Connect Cloud Sync
- **B2B/B2C**: External identity collaboration and customer-facing identity management
- **App registrations**: OAuth 2.0 / OIDC / SAML for applications

#### Entra Agent ID (Ignite 2025 — NEW)
- **First-class identity for AI agents** — extends Zero Trust to AI workloads
- **Manage, authenticate, and authorize AI agents** the same way as human users
- **Governance policies**: Apply Conditional Access, PIM, and audit logging to agent identities
- **Significance**: Critical for organizations deploying autonomous AI agents in production

#### Workload Identity Federation (WIF)
- **Secretless authentication** for non-human workloads — no stored credentials
- **Supported platforms**: GitHub Actions, AKS, AWS EKS, GKE, on-premises Kubernetes, any OIDC provider
- **How it works**: External IdP issues short-lived OIDC token -> exchanged for Entra access token
- **Limit**: 20 federated identity credentials per app/managed identity
- **Best practice for CI/CD**: Use WIF for GitHub Actions -> Azure deployments (replaces service principal secrets)

### Managed Identities

- **System-assigned**: Tied to resource lifecycle; auto-created and destroyed with the resource
- **User-assigned**: Independent lifecycle; can be shared across multiple resources
- **No credential management**: Azure handles token issuance and rotation
- **Supported by**: VMs, App Service, Functions, AKS, Container Apps, Logic Apps, ADF, and 50+ services
- **Best practice**: Always prefer Managed Identities over service principal secrets or connection strings

### Azure RBAC

- **2000+ built-in roles** across Azure services
- **Custom roles**: Define granular permissions scoped to management group, subscription, resource group, or resource
- **Deny assignments**: Block specific actions even if a role grants them
- **Conditions (ABAC)**: Attribute-based access control — conditions on role assignments (e.g., "only if tag = X")
- **Integration with PIM**: Just-in-time role activation with approval workflows

### Privileged Identity Management (PIM)

- **Just-in-time (JIT) access**: Temporary elevation for privileged roles
- **Approval workflows**: Require approval before activation
- **MFA enforcement**: Require MFA for role activation
- **Access reviews**: Periodic recertification of role assignments
- **Audit trail**: Full logging of all privilege activations
- **Best practice**: No permanent Global Admin assignments — use PIM for all admin roles

### Azure Conditional Access

- **Signal-based access decisions**: User, device, location, app, risk level, session
- **Common policies**: Require MFA for admins, block legacy auth, require compliant device, location-based restrictions
- **Token protection**: Bind tokens to specific devices (prevents token theft)
- **Continuous access evaluation (CAE)**: Real-time policy enforcement, revoke sessions immediately
- **Authentication strengths**: Define which MFA methods are acceptable per policy

### Azure Policy

- **Governance at scale**: Enforce organizational standards across subscriptions
- **Policy effects**: Audit, Deny, Modify, DeployIfNotExists, Append, AuditIfNotExists
- **Policy initiatives**: Bundle multiple policies together
- **Compliance dashboard**: Track compliance across all resources
- **Key built-in policies for Key Vault**: Enforce RBAC (not legacy access policies), require soft-delete, enforce key rotation
- **Regulatory compliance**: Built-in initiatives for CIS, NIST, PCI-DSS, ISO 27001, HIPAA

### Microsoft Defender for Cloud

#### CSPM (Cloud Security Posture Management)
- **Secure Score**: Quantified security posture with prioritized recommendations
- **Attack path analysis**: Visualize how attackers could chain vulnerabilities (now includes compromised Entra OAuth apps)
- **API Security Posture** (GA): Unified API inventory with posture insights for API risk identification
- **Sensitivity scanning**: Now covers Azure file shares (GA) in addition to blob containers
- **AI security posture**: Extended to GCP Vertex AI workloads — discovery, posture strengthening, attack path analysis

#### CWPP (Cloud Workload Protection)
- **Defender for Servers**: Vulnerability assessment, adaptive application controls, file integrity monitoring
- **Defender for Containers**: AKS runtime protection, image scanning, K8s admission control
- **Defender for Storage**: Malware scanning on upload and on-demand; auto soft-delete malicious blobs
- **Defender for Databases**: SQL, Cosmos DB, PostgreSQL, MySQL threat detection
- **Defender for App Service**: Web app threat detection
- **Multicloud**: Extends to AWS and GCP workloads

### Azure Key Vault

- **Secrets, keys, and certificates management** — HSM-backed for keys
- **Access control**: Azure RBAC recommended (legacy access policies have known security gaps)
- **Integration with PIM**: JIT access to Key Vault operations for elevated scenarios
- **Azure Policy enforcement**: Built-in policies for soft-delete, purge protection, key rotation
- **Certificate auto-renewal**: Integrated with DigiCert, GlobalSign
- **Managed HSM**: FIPS 140-2 Level 3 validated single-tenant HSM for highest security
- **Best practice**: Migrate from legacy access policies to Azure RBAC; enable soft-delete and purge protection

---

## 6. Serverless & Event-Driven

### Compute Decision Framework

| Criteria | Azure Functions | Container Apps | AKS |
|----------|----------------|----------------|-----|
| **Abstraction level** | Code (FaaS) | Container (CaaS) | Kubernetes (full) |
| **Scale-to-zero** | Yes | Yes | No (Nodes always running) |
| **Cold start** | Yes (mitigated by Flex Consumption) | No (always warm) | N/A |
| **K8s knowledge needed** | None | Minimal | Expert level |
| **Custom containers** | Optional (custom handlers) | Required | Required |
| **Dapr support** | No | Yes (native) | Yes (manual install) |
| **Traffic splitting** | No | Yes (native) | Yes (Istio/manual) |
| **Cost model** | Per-execution | Per-vCPU-second | Per-node |
| **Max execution time** | Flex: unlimited; Consumption: 10 min | Unlimited | Unlimited |
| **Team size sweet spot** | Small/medium | Medium | Medium/large |

#### When to Choose What
- **Azure Functions**: Small, focused event-driven code; rapid prototyping; infrequent executions; strong Azure service triggers
- **Container Apps**: Modern microservices; Dapr-based architectures; teams wanting serverless without K8s complexity; avoid cold start issues
- **AKS**: Enterprise-scale platform; multi-team with shared cluster; advanced networking/security; third-party K8s ecosystem tools
- **Key 2025-2026 insight**: .NET 10 Native AOT reduces cold starts to <50ms with 60-80% memory reduction — makes Functions more competitive for always-warm scenarios

### Azure Logic Apps

- **Visual workflow orchestration** — 400+ connectors to SaaS and enterprise systems
- **Consumption (serverless)**: Pay per action execution; auto-scales
- **Standard (dedicated)**: Runs on App Service plan; supports VNet integration, stateful workflows, local development
- **Integration with Event Grid, Service Bus, Functions** for complex event-driven architectures
- **Use cases**: B2B integration, SaaS-to-SaaS automation, approval workflows, data transformation pipelines

### Azure Event Grid

- **Serverless event broker** — millions of events/second with consistent low latency
- **Event sources**: Azure services (Blob Storage, Resource Manager, IoT Hub), custom topics, partner events
- **Event delivery**: Push-based with retry policies, dead-letter queues
- **Event types**: Cloud Events 1.0 schema support
- **Filtering**: Advanced event filtering with subject/event type/data field filters
- **Integration**: Delivers to Functions, Logic Apps, Event Hubs, Service Bus, Webhooks, Storage Queues
- **Use cases**: Real-time event processing, IoT data ingestion, resource event reactions

### Azure Service Bus

- **Enterprise message broker** — queues and pub/sub topics
- **Features**: Sessions, dead-letter queues, scheduled delivery, auto-forwarding, duplicate detection, transactions
- **Premium tier**: Dedicated resources, message size up to 100 MB, VNet integration, CMK encryption
- **Integration with Event Grid**: Event Grid can trigger on Service Bus events (message arrival, dead-letter)
- **vs. Event Grid**: Service Bus for enterprise messaging (guaranteed delivery, ordering); Event Grid for reactive event-driven patterns
- **vs. Event Hubs**: Service Bus for transactional messaging; Event Hubs for high-throughput streaming

### Azure Static Web Apps

- **Globally distributed hosting** for static frontends + serverless API backends
- **Enterprise-grade edge**: Powered by Azure Front Door CDN
- **Auto-deployment**: GitHub Actions / Azure DevOps integration with preview environments per PR
- **Built-in auth**: Azure AD, GitHub, Twitter, custom OIDC
- **Custom domains with free SSL**: Automatic certificate management
- **Pricing**: Free tier available; Standard at $9/month (5 custom domains, 10 staging environments, SLA)
- **Private endpoints**: VNet integration for backend access restriction
- **Note**: Service has slower development momentum as of 2025 — evaluate alternatives (Vercel, Cloudflare Pages) for cutting-edge frontend needs

---

## 7. DevOps & Developer Tools

### Azure DevOps Services

#### Pipelines
- **YAML-first pipelines**: Multi-stage, template-based, reusable pipeline components
- **Self-hosted and Microsoft-hosted agents**: Ubuntu, Windows, macOS runners
- **Environments and approvals**: Deployment gates, manual approvals, auto-rollback
- **Container jobs**: Run pipeline stages in containers for reproducible builds
- **Service connections**: Workload Identity Federation (WIF) with Entra-issued tokens — secretless deployments
- **Integration**: ARM/Bicep deployments, Terraform tasks, Helm/K8s tasks

#### Boards
- **Agile work tracking**: Epics, Features, User Stories, Tasks, Bugs
- **Kanban boards, backlogs, sprints**: Full Scrum/Kanban support
- **GitHub integration**: Link work items to GitHub PRs and commits
- **Analytics and dashboards**: Built-in analytics views and customizable dashboards

#### Repos
- **Git repositories**: Branch policies, PR reviews, branch protection
- **Integration with Pipelines**: CI triggers on PRs, build validation policies
- **vs. GitHub Repos**: Azure Repos for organizations deeply invested in Azure DevOps ecosystem

#### Artifacts
- **Universal Package Management**: npm, NuGet, Maven, Gradle, Python (PyPI), Cargo
- **Upstream sources**: Proxy packages from public registries
- **Retention policies**: Automated cleanup of old package versions

### GitHub Actions with Azure

- **Recommended for greenfield projects** — GitHub is the default for new Azure integrations
- **Azure Login Action**: `azure/login@v2` with Workload Identity Federation (OIDC) — no stored secrets
- **Key actions**: `azure/webapps-deploy`, `azure/aks-set-context`, `azure/functions-action`, `azure/arm-deploy`
- **azd integration**: `azure/setup-azd` action for Azure Developer CLI in workflows
- **Environments and secrets**: GitHub Environments with protection rules, required reviewers, deployment gates

### Azure Developer CLI (azd)

#### Latest Features (March 2026)
- **AI agent local development**: `azd ai agent show` (container status/health), `azd ai agent monitor` (stream logs)
- **GitHub Copilot integration**: `azd init` offers "Set up with GitHub Copilot (Preview)" — AI-scaffolded project setup
- **Container App Jobs**: Deploy via `host: containerapp` config — Bicep template determines if Container App or Job
- **Package manager detection**: Auto-detects pnpm, yarn for JS/TS services; overridable in azure.yaml

#### Core Capabilities
- **`azd init`**: Scaffold project from template or existing code
- **`azd provision`**: Deploy infrastructure (Bicep/Terraform)
- **`azd deploy`**: Deploy application code
- **`azd pipeline config`**: Set up CI/CD (GitHub Actions or Azure Pipelines) with OIDC auth by default
- **`azd up`**: One-command provision + deploy
- **Template gallery**: 100+ starter templates for common architectures (web apps, APIs, AI apps)

### Azure Deployment Environments

- **Managed self-service infrastructure** for developer environments
- **IaC templates**: ARM, Bicep, Terraform templates curated by platform teams
- **Dev/test/staging/prod**: Map project types to environment types with appropriate permissions
- **Security policies per environment type**: Increasing protection from dev through production
- **Cost**: Service itself is free — pay only for provisioned Azure resources
- **Integration**: Azure DevOps, GitHub Actions, azd
- **Platform engineering**: Platform teams curate templates; developers self-serve without tickets

---

## 8. Infrastructure as Code

### Azure Bicep (Recommended for Azure-only)

#### Current Status
- **Domain-specific language (DSL)** for Azure Resource Manager — transpiles to ARM JSON
- **First-class Azure citizen**: IntelliSense, type safety, validation in VS Code
- **Module system**: Public Bicep Registry + private module registries (ACR)
- **Deployment Stacks** (GA): Lifecycle management — tracks resources and auto-cleans resources no longer in template (like Terraform state but native to Azure)
- **.bicepparam files**: Parameter files with IntelliSense, Bicep functions, and type checking

#### Azure Verified Modules (AVM)
- **Enterprise-grade, Microsoft-maintained Bicep/Terraform modules**
- **Platform Landing Zone module** (GA — Jan 2026): Composed of 19 AVM modules (16 resource + 3 pattern)
  - Configurable via `platform-landing-zone.yaml`: Management groups, resource naming, network architecture, regions
  - Replaces classic ALZ-Bicep (removed from Accelerator Feb 2026; archived Feb 2027)
- **Standards**: Consistent naming, testing, versioning, documentation across all modules
- **Registry**: Public Bicep Module Registry (`br:mcr.microsoft.com/bicep/avm/...`)

#### When to Use Bicep
- Azure-only deployments
- Teams preferring Azure-native tooling
- Organizations standardizing on AVM for landing zones
- Integration with Azure Deployment Stacks for lifecycle management

### ARM Templates
- **JSON-based Azure Resource Manager templates** — the underlying format Bicep compiles to
- **Still supported** but Bicep is the recommended authoring experience
- **Use directly only when**: Bicep doesn't support a specific feature (rare), or maintaining legacy templates

### Terraform AzureRM Provider

#### Version 4.0 (Current)
- **Provider-defined functions**: Azure-specific functions for resource ID casing and component access
- **Resource provider registration control**: New feature flags `resource_provider_registrations` and `resource_providers_to_register`
- **Regular updates**: New resources for MySQL Flexible Server, App Service language versions, updated Azure API versions

#### Azure Verified Modules for Terraform
- **Same AVM initiative** as Bicep — standardized, tested Terraform modules
- **Registry**: Terraform Registry (`hashicorp/azurerm`)
- **When to use**: Multi-cloud teams, existing Terraform expertise, organizations with Terraform Cloud/Enterprise investment

### Pulumi Azure Native

#### Version 3 (Current)
- **75% SDK size reduction** while maintaining complete Azure coverage
- **890 resource types** at launch — nearly double previous version
- **100% Azure Resource Manager coverage**: Auto-generated from Azure API specs
- **Updated default API versions**: EventGrid (2025-02-15), MachineLearningServices (2024-10-01), Storage (2024-01-01)
- **Automatic updates**: New resources published within hours of Azure API spec merges
- **Languages**: JavaScript, TypeScript, Python, Go, .NET, Java, YAML
- **When to use**: Teams wanting general-purpose language (TypeScript/Python/Go) instead of DSL, existing Pulumi investment

### IaC Decision Matrix

| Tool | Best For | Multi-Cloud | Language | State Management |
|------|----------|-------------|----------|-----------------|
| **Bicep** | Azure-only, Azure-native teams | No | DSL | Azure Deployment Stacks |
| **Terraform** | Multi-cloud, large ecosystems | Yes | HCL | Terraform Cloud/State files |
| **Pulumi** | Developers preferring real languages | Yes | TS/Python/Go/.NET/Java | Pulumi Cloud/State files |
| **ARM** | Legacy/generated templates | No | JSON | Azure (stateless) |

---

## 9. Observability

### Azure Monitor — Unified Platform

#### Core Components
- **Metrics**: Time-series numerical data — CPU, memory, request rates, custom metrics
- **Logs (Log Analytics)**: KQL-based log querying — diagnostic logs, custom logs, Application Insights telemetry
- **Application Insights**: APM for web applications — distributed tracing, dependency tracking, exception logging, availability tests
- **Change Analysis**: Detect configuration changes correlated with issues
- **Alerts**: Metric alerts, log alerts, activity log alerts, smart detection

#### OpenTelemetry — The Standard (2025-2026)
- **Microsoft's official direction**: No new features for legacy Application Insights SDKs — all investment in OpenTelemetry
- **Azure Monitor OpenTelemetry Distro**: Pre-configured OTel SDK with Azure Monitor exporter
  - Auto-instrumentation for .NET, Java, Node.js, Python
  - Exports traces, metrics, and logs to Application Insights / Log Analytics
- **Why migrate**: Vendor-neutral, portable telemetry; community-driven standard; easy to switch backends
- **Migration path**: Replace Application Insights SDK with Azure Monitor OpenTelemetry Distro — same backend, standards-based collection

#### Azure Monitor Workspaces
- **New container for Prometheus metrics** — separate from Log Analytics Workspaces
- **Query**: PromQL for Prometheus metrics; KQL for logs
- **Managed Prometheus integration**: Metrics collected by Azure Managed Prometheus stored in Monitor Workspace

### Azure Managed Grafana

- **Fully managed Grafana service** — Azure AD authentication, managed upgrades
- **Pre-built Azure dashboards**: Azure Monitor, Prometheus, Application Insights data sources pre-configured
- **Data sources**: Azure Monitor, Azure Data Explorer, Prometheus, Azure Managed Prometheus, and standard Grafana data sources
- **Essential tier**: Simplified for Azure-only monitoring
- **Standard tier**: Full Grafana feature set including alerting, reporting, and additional data sources
- **Best practice**: Use Managed Grafana as visualization layer on top of Azure Monitor + Managed Prometheus

### Azure Managed Prometheus

- **Fully managed Prometheus-compatible monitoring** — no Prometheus server management
- **Collection**: Azure Monitor Agent (AMA) collects Prometheus metrics from AKS and Arc-enabled K8s
- **Storage**: Azure Monitor Workspace
- **Query**: Standard PromQL
- **Rule evaluation**: Prometheus recording rules and alerting rules
- **Integration**: Native data source in Azure Managed Grafana
- **Best practice**: Use for Kubernetes/container workload metrics; combine with Application Insights for application-level telemetry

### Observability Stack Recommendation (2025-2026)

```
Application Code
    |
    v
OpenTelemetry SDK (Azure Monitor Distro)
    |
    ├── Traces/Logs ──> Application Insights (Log Analytics Workspace)
    |                       └── KQL queries, smart detection, alerts
    └── Metrics ──> Azure Managed Prometheus (Monitor Workspace)
                       └── PromQL queries, recording rules
                              |
                              v
                    Azure Managed Grafana (Dashboards)
                       ├── Prometheus data source
                       ├── Azure Monitor data source
                       └── Custom dashboards + alerting
```

---

## 10. AI/ML Infrastructure

### Azure OpenAI Service

- **Managed access to OpenAI models**: GPT-4o, GPT-4.5, o1, o3, o4-mini, DALL-E 3, Whisper, Embeddings
- **Enterprise features**: VNet integration, Private Link, CMK encryption, content filtering, abuse monitoring
- **Deployment types**:
  - **Standard**: Shared capacity with rate limits (TPM-based)
  - **Provisioned Throughput Units (PTU)**: Reserved capacity for consistent performance
  - **Global / Data Zone**: Route traffic across regions for highest availability
- **Batch API**: Asynchronous processing for large-scale inference at 50% cost reduction
- **Fine-tuning**: Available for GPT-4o-mini, GPT-3.5 Turbo
- **On Your Data**: RAG pattern with Azure AI Search, Blob Storage, Cosmos DB — no custom code needed

### Microsoft Foundry (formerly Azure AI Studio)

#### Model Catalog (1,900+ models)
- **Models sold by Azure**: GPT-5.2 (GA), Claude Opus/Sonnet/Haiku, Mistral, Llama, Phi — covered by Azure SLA
- **Partner/community models**: DeepSeek V3.2, Kimi-K2, Stable Diffusion, and hundreds more
- **Azure is the only cloud** with both OpenAI and Anthropic frontier models in one catalog
- **Deployment options**: Managed compute, serverless API (MaaS), self-hosted on AKS/VMs

#### Key Features
- **Tools tab**: 1,400+ agentic integrations across business systems
- **Fine-tuning as a service**: Model customization without managing compute
- **Evaluation framework**: Built-in metrics for quality, safety, groundedness
- **Prompt flow**: Visual orchestration for RAG pipelines and agent workflows
- **Content safety**: Built-in content filtering, jailbreak detection, groundedness detection

### Maia 100 AI Chip

- **Microsoft's first custom AI accelerator** — designed for Azure AI infrastructure
- **Specs**: ~820mm2, TSMC N5, 4x HBM2E (64 GB capacity, 1.8 TB/s bandwidth)
- **Networking**: 4.8 Tbps Ethernet per accelerator, custom protocol
- **Cooling**: Rack-level closed-loop liquid cooling
- **Software stack (Maia SDK)**: PyTorch backend (eager + graph mode), Triton programming model, debugger, profiler, quantization tools
- **Current use**: Running internal Microsoft services — Copilot, Defender AI, Azure OpenAI
- **Maia 200 (Braga)**: Delayed to 2026 — features requested by OpenAI, staffing constraints affected timeline

### Azure Machine Learning

- **End-to-end ML platform**: Data labeling, training, deployment, monitoring
- **Compute options**: Managed compute clusters (CPU/GPU), compute instances, serverless compute
- **MLflow integration**: Native MLflow tracking, model registry
- **Managed online endpoints**: Blue-green deployments for models with autoscaling
- **Responsible AI dashboard**: Fairness, explainability, error analysis
- **Prompt flow**: Also available in AML for RAG and agent orchestration

### GPU VM Summary for AI/ML

| Series | GPU | Memory/GPU | Use Case |
|--------|-----|------------|----------|
| NC T4 v3 | NVIDIA T4 | 16 GB | Inference, light training |
| NC A100 v4 | NVIDIA A100 | 80 GB | Training, large models |
| NCads H100 v5 | NVIDIA H100 NVL | 94 GB | Training, batch inference |
| ND H100 v4 | NVIDIA H100 | 80 GB | Large-scale distributed training |
| ND H200 v5 | NVIDIA H200 | 141 GB | Largest models, highest throughput |
| NCv6 (Preview) | NVIDIA RTX PRO 6000 | TBD | Visual computing, cost-effective inference |

---

## 11. Cost Optimization

### Azure Reservations

- **Discount**: Up to 72% (1-year) or 80% (3-year) vs pay-as-you-go
- **Scope**: Specific VM SKU + region (not tied to specific VMs)
- **5-year term**: Available for some services (Cosmos DB, SQL Database)
- **Exchangeable**: Can exchange for different SKU/region within same service
- **Cancellation**: Pro-rated refund up to $50K lifetime limit
- **Best for**: Steady-state workloads running 24/7 in a known region and SKU

### Azure Savings Plans for Compute

- **Discount**: Up to 65% vs pay-as-you-go
- **Commitment**: Hourly spend amount for 1 or 3 years
- **Flexibility**: Not locked to VM family, size, or region — applies automatically to eligible compute
- **Eligible services**: VMs, App Service, Container Instances, Azure Functions Premium, Dedicated Hosts
- **Complementary to Reservations**: Use Reservations for known, stable workloads; Savings Plans for flexible/dynamic compute
- **Best practice**: Start with smaller commitments than recommended, observe impact, gradually increase

### Azure Spot VMs

- **Discount**: Up to 90% vs pay-as-you-go
- **Eviction**: Azure can reclaim capacity with 30-second notice
- **Eviction types**: Capacity-based or max-price-based
- **Best for**: Batch processing, CI/CD build agents, dev/test, fault-tolerant HPC, training ML models with checkpointing
- **Not for**: Production web servers, stateful services, anything requiring guaranteed uptime

### Azure Advisor

- **Personalized recommendations** across: Cost, Security, Reliability, Operational Excellence, Performance
- **Cost recommendations**: Right-size VMs, purchase Reservations/Savings Plans, delete idle resources, optimize storage
- **Savings plan simulation**: Based on 30-day usage patterns
- **Digests**: Weekly/monthly recommendation summaries via email

### Azure Cost Management + Billing

- **Cost analysis**: Breakdown by service, resource group, tag, meter, location
- **Budgets**: Set spending thresholds with alerts at configurable percentages
- **Cost allocation**: Tag-based cost allocation rules for shared resources
- **Exports**: Scheduled export of cost data to storage account for custom analysis
- **Anomaly detection**: Automated detection of spending anomalies with root cause analysis
- **Integration**: Power BI connector for cost reporting, Azure Advisor for optimization

### Azure Hybrid Benefit

- **Windows Server**: Average 36% savings (23% when factoring in licensing costs); requires Software Assurance
- **SQL Server**: Average 29-30% savings on Azure SQL Database and SQL Managed Instance
- **Combined savings**: Up to 85% when stacking AHB + Reserved Instances + Extended Security Updates
- **Dual-use rights**: 180-day migration window — run workloads both on-premises and Azure simultaneously
- **Centralized management**: Manage AHB assignments at subscription scope via Cost Management
- **Linux**: RHEL and SUSE subscriptions can also be used for Azure VMs

### Cost Optimization Priority Order

1. **Delete unused resources** — idle VMs, unattached disks, empty App Service plans
2. **Right-size** — Azure Advisor recommendations for underutilized VMs
3. **Reserved Instances** — for stable, predictable workloads
4. **Savings Plans** — for flexible compute that changes SKU/region
5. **Spot VMs** — for interruptible workloads
6. **Hybrid Benefit** — if you have existing Windows/SQL licenses with SA
7. **Dev/test pricing** — use Azure Dev/Test subscription for non-production
8. **Auto-shutdown** — schedule dev/test VMs to stop overnight/weekends
9. **Storage tiering** — lifecycle policies to move cold data to cheaper tiers
10. **Serverless** — scale-to-zero for intermittent workloads (Functions, Container Apps)

---

## 12. Hybrid & Multi-Cloud

### Azure Arc

#### Arc-Enabled Servers
- **Project any server into Azure Resource Manager** — on-premises, AWS, GCP, edge
- **Capabilities**: Azure Policy, Update Management, Change Tracking, Log Analytics, Defender for Cloud
- **Windows Server 2025 integration**: Deploy directly from Azure with Arc-enabled capabilities
- **Azure Machine Configuration**: DSC-like configuration management via Azure Policy
- **Extensions**: Deploy Azure Monitor Agent, Defender for Servers, Custom Script extensions to Arc-managed servers

#### Arc-Enabled Kubernetes
- **Manage any CNCF-conformant K8s cluster** from Azure — AKS on-prem, EKS, GKE, Rancher, OpenShift
- **GitOps (Flux v2)**: Built-in GitOps configuration management
- **Azure services on any K8s**: Deploy App Service, Functions, Logic Apps, Event Grid, API Management on Arc clusters
- **Azure Policy for K8s**: Enforce OPA Gatekeeper policies from Azure
- **Azure Monitor Container Insights**: Same monitoring experience regardless of cluster location

#### Arc-Enabled Data Services
- **Azure SQL Managed Instance** on any infrastructure — on-premises, edge, other clouds
- **Azure PostgreSQL** (public preview) — distributed PostgreSQL anywhere
- **Direct connected mode** (recommended): Full Azure management plane integration
- **Indirect mode**: Retired as of September 2025
- **Use cases**: Data sovereignty, edge computing, regulated environments requiring on-premises data residency

#### Arc-Enabled SQL Server
- **Manage SQL Server instances** across environments from Azure portal
- **Pay-as-you-go billing**: License SQL Server through Azure billing without SA
- **Azure AD authentication**: For on-premises SQL Server via Arc
- **Microsoft Purview integration**: Data governance and classification

### Azure Stack HCI / Azure Local

- **Hyperconverged infrastructure** running Azure services on-premises
- **Rebranded**: Azure Stack HCI is now "Azure Local" in current documentation
- **Version 23H2**: End of support April 2026 — migrate to 24H2
- **Version 24H2**: Current release with 6-month support cadence
- **Lifecycle Manager (LCM)**: Unified update orchestrator for OS, agents, services, and solution extensions
- **Key capabilities**:
  - Run Azure VMs and Azure Container Host on-premises
  - Azure Portal management — same experience as cloud resources
  - Azure Kubernetes Service on Azure Local
  - Azure Virtual Desktop on Azure Local
  - Azure Arc integration for hybrid management
- **Use cases**: Branch offices, edge locations, regulated environments, latency-sensitive workloads
- **Licensing**: Per-physical-core subscription model billed through Azure

---

## 13. Decision Frameworks

### Cloud Service Selection Checklist

```
Question 1: Does the workload need to run on Azure only?
├── Yes → Consider Bicep + AVM, Azure-native services
└── No → Consider Terraform/Pulumi, portable architectures

Question 2: What is the compute model?
├── Event-driven, short-lived → Azure Functions (Flex Consumption)
├── Containerized microservices → Container Apps (simple) or AKS (complex)
├── Long-running VMs → Azure VMs (Cobalt 100 for Linux, Dv6 for Windows)
└── Batch/periodic jobs → Container Apps Jobs or AKS Jobs

Question 3: What is the data model?
├── Relational → Azure SQL Database (Hyperscale for scale) or PostgreSQL Flex
├── Document/NoSQL → Cosmos DB for NoSQL
├── MongoDB-compatible → Azure DocumentDB (Cosmos DB MongoDB vCore)
├── Key-value/Cache → Azure Managed Redis
├── Time-series/Analytics → Azure Data Explorer or Cosmos DB
└── Vector/AI → Cosmos DB NoSQL (DiskANN) or PostgreSQL (pgvector)

Question 4: Does the workload span on-premises?
├── Yes → Azure Arc (servers, K8s, data services) + ExpressRoute/VPN
└── No → Cloud-native Azure services

Question 5: What security posture is required?
├── Zero-trust → Private Link + Managed Identities + Conditional Access + PIM
├── Compliance (SOC2/HIPAA/PCI) → Azure Policy + Defender for Cloud + Key Vault
└── Standard → NSGs + RBAC + Managed Identities
```

### Azure Well-Architected Framework Pillars

1. **Reliability**: Availability Zones, cross-region replication, health probes, auto-failover
2. **Security**: Zero Trust, Entra ID, Managed Identities, Private Link, Defender for Cloud
3. **Cost Optimization**: Right-sizing, Reservations, Savings Plans, lifecycle policies, scale-to-zero
4. **Operational Excellence**: IaC (Bicep/Terraform), CI/CD, monitoring, incident response
5. **Performance Efficiency**: Appropriate VM series, caching, CDN, database tuning, autoscaling

### Landing Zone Architecture (Recommended Starting Point)

```
Management Group Hierarchy:
├── Root Management Group
│   ├── Platform
│   │   ├── Identity (Entra ID, Domain Controllers)
│   │   ├── Management (Log Analytics, Automation, Monitoring)
│   │   └── Connectivity (Virtual WAN/Hub, ExpressRoute, DNS)
│   ├── Landing Zones
│   │   ├── Corp (internal workloads with hybrid connectivity)
│   │   └── Online (internet-facing workloads)
│   ├── Decommissioned
│   └── Sandbox (dev/test, relaxed policies)
```

- **Deploy with**: Bicep AVM Platform Landing Zone module (GA Jan 2026)
- **Configure via**: `platform-landing-zone.yaml` for management groups, naming, networking, regions
- **Manage with**: Azure Deployment Stacks for lifecycle tracking and cleanup
