---
title: system-architect on GCP
description: System architecture on Google Cloud — picking the compute primitive, org/folder/project hierarchy, multi-region DR, integration boundaries, multi-cloud composition.
role_overlay:
  role: system-architect
  stack: gcp
  last_verified_on: "2026-05-14"
  products_covered:
    - cloud-run
    - cloud-run-jobs
    - cloud-functions
    - gke
    - gke-autopilot
    - app-engine
    - compute-engine
    - anthos
    - spanner
    - alloydb
    - cloud-sql
    - firestore
    - bigtable
    - bigquery
    - cloud-storage
    - pub-sub
    - vpc
    - cloud-iam
    - cloud-kms
    - vertex-ai
    - agent-builder
    - agentspace
---

## Role briefing

You are the system-architect on a GCP engagement. GCP has its own resource hierarchy (org → folder → project → resource), its own compute spectrum (5+ valid options for almost any workload), its own integration primitives ([Pub/Sub](/stacks/gcp/pub-sub/), Eventarc, Workflows), and its own residency and compliance shape (Assured Workloads, region constraints, BAA-eligible services). Get the shape right here and the role-specific overlays handle execution.

The primary architectural decisions you own on GCP:
1. **Compute primitive selection** — Cloud Run vs Cloud Run functions vs GKE Autopilot vs GKE Standard vs Compute Engine vs App Engine
2. **Resource hierarchy** — org → folder → project structure; project split strategy
3. **Networking topology** — Shared VPC vs standalone; VPC-SC perimeters
4. **Multi-region + DR posture**
5. **Integration boundaries** — what lives in GCP vs elsewhere
6. **Multi-cloud composition**
7. **Agent-driven / headless architecture**

This overlay teaches you what's distinctive about that lens on GCP in 2026.

## Decision framework — pick the right compute primitive

On GCP, the compute spectrum is broader than AWS's and the right answer depends on more than "containers vs functions vs VMs." Use this frame, in order:

| Need | Default primitive | Escape upward when |
|------|-------------------|---------------------|
| Stateless HTTP/gRPC service, autoscale-to-zero | **[Cloud Run](/stacks/gcp/cloud-run/) service** | DaemonSets, privileged containers, eBPF, custom CNI, sustained >70% utilization |
| Event-driven single-purpose handler | **[Cloud Run functions](/stacks/gcp/cloud-functions/)** (gen2) | Handler grows to multiple endpoints or shared state — promote to a Cloud Run service |
| Run-to-completion batch, scheduled or triggered | **[Cloud Run Jobs](/stacks/gcp/cloud-run-jobs/)** | Job >24h or stateful coordination across tasks — GKE `Job`/`CronJob` or [Dataflow](/stacks/gcp/dataflow/) |
| Multi-service K8s workload, mesh, GitOps | **[GKE Autopilot](/stacks/gcp/gke-autopilot/)** | DaemonSets, privileged pods, CRDs Autopilot blocks, specific node topology — [GKE Standard](/stacks/gcp/gke/) |
| Stateful, persistent volumes, custom kernel, GPU/TPU placement | **GKE Standard** with explicit node pools | Raw hardware, custom OS, non-K8s runtimes — [Compute Engine](/stacks/gcp/compute-engine/) with MIGs |
| HPC, ML training, custom OS, SAP, Windows | **Compute Engine** | Multi-cluster fleet across clouds — **[GKE Enterprise / Anthos](/stacks/gcp/anthos/)** |
| Greenfield web/API | **Cloud Run** — never [App Engine](/stacks/gcp/app-engine/) for new builds | App Engine is in maintenance mode |

**The most common GCP architecture mistake**: reaching for GKE when Cloud Run suffices. Cloud Run gen2 supports sidecars, GPU, Direct VPC egress, 60-min HTTP timeouts, and per-pod billing — most "we need K8s" reasoning from 2022 is obsolete. Default to Cloud Run; promote to GKE Autopilot only when you have a specific K8s-API need.

The second most common mistake: choosing GKE Standard when Autopilot would do — you pay for idle nodes and inherit upgrade discipline you don't need.

## Resource hierarchy — the upstream decision most teams skip

```
Organization (your company / domain)
├── Folder: Production
│   ├── Project: prod-web
│   ├── Project: prod-data
│   └── Project: prod-shared (networking, KMS, Artifact Registry)
├── Folder: Non-Production
│   ├── Project: dev-web
│   ├── Project: staging-web
│   └── Project: shared-tools (CI, monitoring, security tooling)
└── Folder: Sandbox
    ├── Project: sandbox-team-a
    └── Project: sandbox-team-b
```

### Project strategy

**Default: more projects, not fewer.** GCP gives you 1000s of projects per org and there's no per-project cost.

Benefits of project-as-boundary:
- **IAM blast radius** — a grant at project scope only affects that project
- **Quota and capacity** — Compute Engine quotas are per-project per-region
- **Billing and chargeback** — project-level billing labels make cost attribution trivial
- **Org policy inheritance** — policies attach to folders/projects and inherit downward
- **Audit trail** — Cloud Audit Logs are per-project; project boundaries ease incident scoping

**Split projects by**: environment (prod/staging/dev), workload domain (web/data/ML/shared-infra), tenant for SaaS with hard isolation. **Don't split by**: team (use folders), microservice (use namespaces / labels), or feature branch.

### Shared VPC vs standalone

| Pattern | When |
|---------|------|
| **Shared VPC** (host project + service projects) | Centralized network admin while application teams own compute. Default for enterprise landing zones. |
| **Standalone VPC per project** | Small teams, no central network governance, or strict isolation requirements |
| **Network Connectivity Center hub-and-spoke** | Multi-region / hybrid-cloud topologies |

Default for new orgs: **Shared VPC with a single host project per environment** (e.g., `shared-vpc-prod`, `shared-vpc-nonprod`).

### Landing zone foundation

Before any application code:
1. **Org policies** at org scope: disable default network creation, enforce CMEK on supported services, restrict allowed image sources, restrict allowed locations for residency
2. **Folder structure**: at minimum `Production` / `Non-Production` / `Shared-Services` / `Sandbox`
3. **Shared services projects**: networking (Shared VPC host), security (KMS keys, SCC), CI/CD (Cloud Build, Artifact Registry), observability (centralized log sink to BigQuery + GCS archive)
4. **Workload projects** under environment folders, attached as Shared VPC service projects
5. **Audit log aggregation**: org-level aggregated sink → BigQuery dataset in a security project
6. **Billing export**: org-level export to BigQuery, dashboarded in Looker Studio or FinOps Hub

Google's [Cloud Foundation Toolkit](https://cloud.google.com/foundation-toolkit) and [Terraform Example Foundation](https://github.com/terraform-google-modules/terraform-example-foundation) are the reference implementations.

## Multi-region and disaster recovery

| Tier | Topology | Rationale |
|------|----------|-----------|
| **Single-zone (dev/test)** | One zone | No HA, lowest cost |
| **Regional HA** | 2-3 zones in one region | Standard production |
| **Multi-region active-passive** | Primary + failover region | Critical workloads with RPO measured in minutes |
| **Multi-region active-active** | [Spanner](/stacks/gcp/spanner/) / [Firestore](/stacks/gcp/firestore/) multi-region + Cloud Run multi-region behind GLB | Mission-critical, RPO near zero |
| **Global** | Spanner, GCS multi-region, GLB | Global latency-sensitive |

**Region selection** is a residency + latency decision before it's a cost decision. EU customer → EU regions (and check Assured Workloads if regulated).

### DR shape

- **Cloud SQL Enterprise Plus** with cross-region read replicas and automated failover
- **AlloyDB** with cross-region async replication
- **Spanner** multi-region configs (`nam-eur-asia1`, `nam3`) — transparent at write-latency cost
- **Cloud Storage** dual-region and multi-region buckets — RTO zero, no app changes
- **GKE** regional clusters (always pick regional for prod) — see [GKE](/stacks/gcp/gke/)
- **Cloud Run** is regional but easy to multi-region behind a GLB; cross-region service-to-service via Direct VPC egress + Network Connectivity Center

**The compliance trap**: "Multi-region" for an EU customer must mean "multiple EU regions" — not "EU + US." Bake residency into architecture, don't bolt it on.

## Integration boundaries — what lives in GCP

- **Stays in GCP when**: GCP-native services provide leverage ([BigQuery](/stacks/gcp/bigquery/) for analytics, [Vertex AI](/stacks/gcp/vertex-ai/) for ML, [Spanner](/stacks/gcp/spanner/) for global ACID, [Cloud Run](/stacks/gcp/cloud-run/) for low-ops compute); data has gravity in GCP; team has GCP fluency.
- **Leaves GCP when**: best-of-breed elsewhere (Snowflake, Databricks, Salesforce); regulatory residency forces another cloud; team has zero GCP fluency.
- **Boundary technology, 2026 order of preference**:
  1. **Eventarc Advanced** for cross-system event routing — bus + pipeline model
  2. **Pub/Sub** with HTTP push subscription to external systems
  3. **Cloud Run** as the boundary service (call external API, expose external-friendly endpoint)
  4. **Workflows** for stateful multi-step orchestration
  5. **MuleSoft / Apigee** when API-management discipline matters
  6. **[BigLake / BigQuery Omni](/stacks/gcp/biglake/)** when boundary is "query without moving"

## Headless / agent-driven architecture

New shape in 2025-2026: building apps where the user-facing surface is an AI client and GCP services are the action plane.

- **[Agentspace](/stacks/gcp/agentspace/)** for enterprise-wide AI assistant
- **[Vertex AI Agent Builder](/stacks/gcp/agent-builder/)** for product-specific agents
- **Custom MCP-style exposure** of GCP services via Cloud Run; no first-party GCP MCP server GA in user environments today (2026-05)
- **Gemini Code Assist Agents** for IDE-side autonomous workflows — see [Gemini Code Assist](/stacks/gcp/gemini-code-assist/)

When UI is an agent client, not a GCP UI:
- GCP becomes system-of-record + action plane
- [Vertex AI](/stacks/gcp/vertex-ai/) provides the model layer
- Cloud Run hosts the action endpoints
- Eventarc Advanced provides event substrate
- [BigQuery](/stacks/gcp/bigquery/) + [AlloyDB AI](/stacks/gcp/alloydb/) + Vertex AI Vector Search provide grounding

Agent design depth in [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/).

## Multi-cloud composition

| Composition | GCP side | Other side |
|-------------|----------|------------|
| **GCP + AWS** | [BigQuery Omni](/stacks/gcp/biglake/) for cross-cloud analytics; GKE on AWS; Pub/Sub egress to AWS via Eventarc; BigLake on S3 | Lambda/ECS/Bedrock, RDS, S3 lifecycle |
| **GCP + Azure** | BigQuery Omni for Azure Blob; Anthos clusters on Azure; Azure AD as IdP via WIF | Azure Functions, AKS, Azure OpenAI |
| **GCP + Salesforce** | Pub/Sub ingestion of Salesforce Platform Events; BigQuery via Data 360 Zero Copy; Vertex AI for embedding | Salesforce-side schema, Data 360 outbound |
| **GCP + Snowflake** | BigQuery Omni vs Snowflake on GCP region tradeoff; Datastream into Snowflake; Pub/Sub → Snowpipe Streaming | Snowflake warehouses, Snowflake security |
| **GCP + Databricks** | Databricks on GCP region; Unity Catalog vs Dataplex; Vertex AI as serving layer | Databricks notebooks, MLflow |

When the other side has no registered pack, GCP pack handles the GCP-side patterns only — say so explicitly.

## 2025-2026 platform-reset items

- **App Engine in maintenance mode** — don't recommend for greenfield. See [App Engine](/stacks/gcp/app-engine/).
- **Cloud Functions gen1 deprecated** — use [Cloud Run functions](/stacks/gcp/cloud-functions/) (gen2) or Cloud Run service.
- **Container Registry (`gcr.io`) deprecated** — see [Artifact Registry](/stacks/gcp/artifact-registry/).
- **Deployment Manager EOL Dec 31, 2025** — see [devops-engineer on GCP](/stacks/gcp/devops-engineer/) for Infrastructure Manager / Terraform.
- **App Engine Standard for greenfield** is an antipattern in 2026.
- **Spanner pricing** intuition has shifted — granular PU sizing makes dev/staging viable.
- **Memorystore default is Valkey, not Redis** — see [Memorystore](/stacks/gcp/memorystore/).

## Anti-patterns specific to GCP architecture

- **"We'll just use GKE Standard for everything."** Default Cloud Run; promote to GKE Autopilot for K8s API need; Standard only when Autopilot blocks something.
- **"App Engine is the simplest option."** App Engine is in maintenance mode.
- **"Spanner is too expensive."** Old advice; granular PU sizing starts at $65/month.
- **"Firestore and Datastore are interchangeable."** Modes of the same product; choice is irreversible per database.
- **"Cloud SQL HA is enough for our DR."** Cloud SQL HA is zonal; regional outage takes it down.
- **"We'll use the default VPC."** Disable at org policy level.
- **"Everything in one project."** Inviting an IAM blast radius.
- **"BigQuery editions are cheaper than on-demand."** Only for sustained workloads.

## Verification checklist for system-architect on GCP

- [ ] Org → folder → project hierarchy defined; project split is deliberate
- [ ] Compute primitive selection mapped to workloads; no App Engine for greenfield
- [ ] Region(s) selected with explicit residency + latency rationale; Assured Workloads engaged if regulated
- [ ] DR topology specified per data store and RPO/RTO documented
- [ ] Network topology: Shared VPC vs standalone, firewall posture, PSC for managed-service access, no default network
- [ ] WIF specified for all non-GCP-workload authentication; no service account keys planned
- [ ] CMEK with [Cloud KMS](/stacks/gcp/cloud-kms/) for regulated data
- [ ] VPC-SC perimeter design if data exfiltration is in the threat model
- [ ] Observability path: OTLP via Ops Agent / Managed OTel / Cloud Run native; centralized log sink
- [ ] CI/CD identity model: GitHub Actions / GitLab via WIF
- [ ] Cost model: CUD strategy, Spot for fault-tolerant workloads, BigQuery editions decision, FinOps Hub configured
- [ ] No legacy paths: no Container Registry, no Deployment Manager, no Cloud Functions gen1, no App Engine for new builds
- [ ] Currency check: every API/feature recommended is GA and verified against release notes
- [ ] Multi-cloud composition: if other stacks involved, boundaries and ownership specified

## Integration with always-on protocols

- **TDD**: Architectural decisions don't get TDD'd; downstream implementation does. Handoff to backend-architect includes a contract spec (OpenAPI / proto / event schema).
- **Verification**: Every claim cites a GCP doc URL or release note.
- **Brainstorm-first**: For ambiguous greenfield, run brainstorm *before* picking primitives — GCP has 5+ valid options for almost any workload.
- **Plan execution**: Architecture deliverables go in the plan as artifacts (landing zone Terraform module, ADRs, compute decision matrix).
- **Review**: Architecture review on GCP must include explicit currency checks against release notes.

## Cross-references

- Other roles on GCP: [backend-architect](/stacks/gcp/backend-architect/), [database-architect](/stacks/gcp/database-architect/), [devops-engineer](/stacks/gcp/devops-engineer/), [security-engineer](/stacks/gcp/security-engineer/), [sre-engineer](/stacks/gcp/sre-engineer/), [ai-ml-engineer](/stacks/gcp/ai-ml-engineer/), [saas-architect](/stacks/gcp/saas-architect/)
- Stack index: [GCP](/stacks/gcp/)
