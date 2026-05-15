---
name: stack-gcp
description: >
  Google Cloud Platform knowledge overlay for the ETYB team. Loads when work involves the GCP ecosystem — Compute Engine, GKE, GKE Autopilot, Cloud Run, Cloud Run Jobs, Cloud Run functions (formerly Cloud Functions gen 2), App Engine, Cloud Storage, Cloud SQL, AlloyDB, Spanner, Firestore, Bigtable, Memorystore for Valkey/Redis, Pub/Sub, Dataflow, Dataproc, Dataform, BigQuery, BigQuery Studio, BigQuery ML, BigLake, BigQuery Omni, Looker, Looker Studio, Vertex AI, Vertex AI Agent Builder, Agentspace, Conversational Agents, Gemini for Google Cloud, Gemini Code Assist, Imagen, Veo, Model Garden, Cloud IAM, Workload Identity Federation, Cloud KMS, Secret Manager, Cloud Armor, Cloud CDN, Cloud Load Balancing, VPC, VPC Service Controls, Private Service Connect, Cloud DNS, Security Command Center, Chronicle, BeyondCorp, Cloud Logging, Cloud Monitoring, Cloud Trace, Cloud Profiler, Cloud Build, Cloud Deploy, Artifact Registry, Cloud Code, gcloud CLI, Terraform google provider, Config Connector, Infrastructure Manager, Anthos / GKE Enterprise, Firebase, Firebase Studio. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade GCP work as of 2026-Q2.
  Triggers: gcp, google cloud, google cloud platform, gcloud, gke, gke autopilot, gke enterprise, anthos, cloud run, cloud run functions, cloud run jobs, cloud functions, app engine, compute engine, gce, c4a, axion, tau t2a, n4, e2, cloud storage, gcs, autoclass, cloud sql, alloydb, alloydb ai, spanner, cloud spanner, firestore, datastore, bigtable, memorystore, valkey, pub/sub, pubsub, dataflow, dataproc, dataform, bigquery, bigquery studio, bigquery ml, bqml, biglake, bigquery omni, looker, looker studio, vertex ai, vertex ai studio, vertex ai agent builder, agent builder, agentspace, conversational agents, model garden, gemini, gemini for google cloud, gemini code assist, duet ai, imagen, veo, tpu, trillium, ironwood, cloud iam, workload identity federation, wif, cloud kms, secret manager, parameter manager, cloud armor, cloud cdn, cloud load balancing, vpc, vpc service controls, vpc-sc, private service connect, psc, cloud dns, security command center, scc, chronicle, beyondcorp, cloud logging, cloud monitoring, ops agent, cloud trace, cloud profiler, error reporting, cloud build, cloud deploy, artifact registry, container registry, cloud code, terraform google provider, config connector, infrastructure manager, deployment manager, firebase, firebase studio, firebase data connect, firebase app hosting, eventarc, workflows, cloud tasks, cloud scheduler, dataplex, datastream, dataform, looker studio pro, gcp release notes, gcp security bulletins, assured workloads, sovereign controls, cloud cdn, document ai, contact center ai.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
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
authoritative_sources:
  primary:
    - { name: "Google Cloud Docs",              url: "https://cloud.google.com/docs",                                type: official_docs }
    - { name: "gcloud CLI Reference",            url: "https://cloud.google.com/sdk/gcloud/reference",                type: cli_reference }
    - { name: "GCP Release Notes",               url: "https://cloud.google.com/release-notes",                       type: changelog }
    - { name: "GCP Security Bulletins",          url: "https://cloud.google.com/security-bulletins",                  type: security_advisories }
    - { name: "Google Cloud Architecture Center", url: "https://cloud.google.com/architecture",                       type: reference_architectures }
    - { name: "GoogleCloudPlatform GitHub",      url: "https://github.com/GoogleCloudPlatform",                       type: source_code }
    - { name: "Vertex AI Docs",                  url: "https://cloud.google.com/vertex-ai/docs",                      type: official_docs }
    - { name: "BigQuery Docs",                   url: "https://cloud.google.com/bigquery/docs",                       type: official_docs }
    - { name: "GKE Docs",                        url: "https://cloud.google.com/kubernetes-engine/docs",              type: official_docs }
    - { name: "Terraform google provider",       url: "https://registry.terraform.io/providers/hashicorp/google/latest/docs", type: api_reference }
delegate_to_skills:
  # No first-party Google Cloud MCP server is generally available in current users' environments
  # as of last_verified_on. Public-roadmap signals point to GCP MCP coverage in 2026 — revisit
  # this list when a Google-hosted MCP shipping path lands.
  []
products_covered:
  - { name: "Cloud Run",                     drift_risk: high,   notes: "Gen2 sidecars + GPU GA (L4 + RTX PRO 6000 Preview), Direct VPC egress GA, 60-min HTTP timeout, multi-container support — features moved fast through 2025-2026" }
  - { name: "Cloud Run functions",           drift_risk: high,   notes: "Branding shift: Cloud Functions gen2 is now officially Cloud Run functions; gen1 deprecated and end-of-support glide path through 2026" }
  - { name: "GKE Autopilot",                 drift_risk: medium, notes: "Per-pod billing model + GPU/TPU support evolving; default pod density and quota defaults changed in 2025" }
  - { name: "Vertex AI",                     drift_risk: high,   notes: "Gemini 2.5 family (Pro / Flash / Flash-Lite), Vertex AI Agent Builder generations, Imagen 4, Veo 3 — model lineup churns every quarter" }
  - { name: "Vertex AI Agent Builder",       drift_risk: high,   notes: "Was Generative AI App Builder → Vertex AI Agent Builder → now layered with Conversational Agents + Agentspace; framework boundaries shifted in 2025-2026" }
  - { name: "Agentspace",                    drift_risk: high,   notes: "GA'd 2025; enterprise agent surface; integrations and licensing model still moving" }
  - { name: "Gemini Code Assist",            drift_risk: high,   notes: "Was Duet AI for Developers; rebrand Feb 2024, Gemini 2.5 backend swap 2025; agentic mode (Code Assist Agents) added 2025-2026" }
  - { name: "AlloyDB",                       drift_risk: medium, notes: "AlloyDB AI / columnar engine / vector search evolving; pgvector + Vertex embedding tight coupling new in 2025" }
  - { name: "Cloud Spanner",                 drift_risk: medium, notes: "GraphQL endpoint (2024), Spanner Graph, granular PU sizing, managed autoscaler, PG dialect — feature surface widened materially" }
  - { name: "Firestore",                     drift_risk: medium, notes: "MongoDB compatibility (Preview), Firestore for Datastore mode unification, Firestore in Native vs Datastore mode confusion still common" }
  - { name: "BigQuery",                      drift_risk: medium, notes: "BigQuery Studio unification 2024-2025, vector search GA, continuous queries GA, BigQuery editions vs on-demand pricing repositioned" }
  - { name: "BigQuery ML",                   drift_risk: medium, notes: "Direct Vertex AI Gemini integration, REMOTE MODEL syntax for LLMs in SQL, vector embedding generation in-engine" }
  - { name: "Memorystore for Valkey",        drift_risk: high,   notes: "Default engine shifted from Redis to Valkey 9.0; existing Redis instances OK but new builds should default to Valkey" }
  - { name: "Cloud Armor",                   drift_risk: medium, notes: "JA4 fingerprinting GA, hierarchical policies GA, body inspection ceiling raised in 2025" }
  - { name: "Workload Identity Federation",  drift_risk: medium, notes: "SAML + X.509 federation GA; mandatory pattern — service account keys are now an audit red flag" }
  - { name: "Secret Manager",                drift_risk: low,    notes: "Stable; Parameter Manager GA companion service for non-secret config" }
  - { name: "Cloud KMS",                     drift_risk: low,    notes: "Stable; CMEK + EKM patterns mature; default for regulated workloads" }
  - { name: "VPC Service Controls",          drift_risk: low,    notes: "Foundational data exfiltration boundary; perimeter design stable" }
  - { name: "Private Service Connect",       drift_risk: medium, notes: "IPv6 NAT + propagated connections GA in 2025; replacement path for legacy Private Google Access patterns" }
  - { name: "Cloud Logging / Monitoring",    drift_risk: medium, notes: "Telemetry API auto-enabled for new projects from March 2026; OTLP ingestion GA; trace sinks deprecated Feb 2026" }
  - { name: "Cloud Trace + Profiler",        drift_risk: low,    notes: "Stable; Cloud Trace ingestion path moving to OTLP and Telemetry API" }
  - { name: "Cloud Build / Cloud Deploy",    drift_risk: medium, notes: "Cloud Deploy supports Cloud Run + GKE + Anthos targets; Cloud Build private pools + binauthz integration mature" }
  - { name: "Artifact Registry",             drift_risk: medium, notes: "Container Registry (gcr.io) deprecated; ALL new workloads must use Artifact Registry; redirect of legacy hosts in 2025-2026" }
  - { name: "Cloud Code / Gemini Code Assist", drift_risk: high, notes: "Cloud Code is the IDE plugin; Gemini Code Assist is its AI brain — both rebranded and feature-extended in 2025-2026" }
  - { name: "gcloud CLI",                    drift_risk: medium, notes: "Stable but constant additions; `gcloud alpha` and `gcloud beta` surfaces large; release-track flags matter for IaC" }
  - { name: "Terraform google provider",     drift_risk: medium, notes: "Versioned provider; pin minor version, beta resources in `google-beta` provider; breaking changes telegraphed in CHANGELOG" }
  - { name: "Infrastructure Manager",        drift_risk: medium, notes: "Google-managed Terraform execution; replaces Deployment Manager (end-of-support Dec 31, 2025)" }
  - { name: "Config Connector",              drift_risk: low,    notes: "GCP resources as K8s CRDs; mature; pairs with Config Sync for GitOps on GKE" }
  - { name: "GKE Enterprise (Anthos)",       drift_risk: low,    notes: "Multi-cluster fleet + Config Sync + Policy Controller; rebranded from Anthos but architecture stable" }
  - { name: "BigLake / BigQuery Omni",       drift_risk: medium, notes: "Cross-cloud querying of S3 + Azure Blob; cross-cloud joins GA; materialized views to dodge egress" }
  - { name: "Pub/Sub",                       drift_risk: low,    notes: "Foundational; BigQuery subscription + Cloud Storage subscription patterns mature" }
  - { name: "Dataflow / Dataproc / Dataform", drift_risk: medium, notes: "Dataflow Prime + GPU support, Dataproc Serverless GA, Dataform integrated into BigQuery Studio" }
  - { name: "Eventarc",                      drift_risk: medium, notes: "Eventarc Advanced GA Aug 2025 (bus + pipeline model); 125+ event sources" }
  - { name: "App Engine",                    drift_risk: high,   notes: "Legacy. Standard & Flex still supported but actively discouraged for new builds — Cloud Run is the path forward. Flag if mentioned for greenfield" }
  - { name: "Firebase Studio",               drift_risk: high,   notes: "Consolidation surface between Firebase and Google Cloud; Project IDX evolved into Firebase Studio in 2025; product positioning still moving" }
  - { name: "Cloud Functions (gen1)",        drift_risk: high,   notes: "Deprecated path; existing gen1 functions run but new development goes to Cloud Run functions (the gen2 successor)" }
  - { name: "Container Registry (gcr.io)",   drift_risk: high,   notes: "Deprecated; migrate to Artifact Registry; legacy hostname redirected" }
  - { name: "Deployment Manager",            drift_risk: high,   notes: "End-of-support Dec 31, 2025 — migrate to Infrastructure Manager or Terraform now" }
---

# Google Cloud Platform Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Google Cloud Platform knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/gcp/index.md`](index.md)
- **Per-product pages:** `stacks/gcp/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/gcp/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/gcp/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Cloud Functions gen2 is now officially "Cloud Run functions"** — same product, new branding (mid-2024). Gen1 is deprecated. Don't recommend `gcloud functions deploy --gen2` in new docs; use the Cloud Run path.
- **Container Registry (`gcr.io`) is deprecated.** Artifact Registry is the only path for new image pushes. The `gcr.io` hostname now redirects but new repos must live in Artifact Registry.
- **Deployment Manager end-of-support: December 31, 2025.** If a customer is still running Deployment Manager, migration to Infrastructure Manager (managed Terraform) or self-managed Terraform is overdue, not aspirational.
- **Duet AI for Developers is now Gemini Code Assist** (Feb 2024 rebrand). The backend swapped to Gemini 2.5 across 2025. **Gemini Code Assist Agents** (agentic mode) shipped in 2025-2026.
- **Generative AI App Builder → Vertex AI Agent Builder → now augmented by Agentspace and Conversational Agents.** The agent product line has been renamed twice; older training will reach for the wrong console paths and SDK names.
- **Agentspace** (2025) is Google's enterprise agent surface — search + agent assistant + connectors across Workspace/M365/Salesforce/etc. It is distinct from Agent Builder.
- **Memorystore default engine is Valkey, not Redis.** Valkey 9.0 ships pipeline prefetching (+40% throughput) and SIMD BITCOUNT (+200%). Existing Redis tiers still work; new builds default to Valkey.
- **Spanner has a GraphQL endpoint and Spanner Graph** (2024). Spanner is no longer just "expensive global SQL." Granular Processing Units start at **100 PU (~$65/month)**; old "minimum 1 node" pricing intuition is obsolete.
- **AlloyDB AI** (2024-2025) ships pgvector + Vertex AI embedding integration in-engine. AlloyDB columnar engine accelerates analytical SQL on transactional data.
- **Cloud Run GPU is GA** (NVIDIA L4) with RTX PRO 6000 Blackwell in Preview. Cloud Run with sidecars (GA) makes the OTel-collector-in-sidecar pattern trivial. Direct VPC egress (GA) replaces the old Serverless VPC Access connector for most cases. Cloud Run gen2 raised the HTTP timeout to **60 minutes** (services), 24 hours (jobs).
- **Workload Identity Federation** is the production answer for non-GCP workloads (GitHub Actions, AWS, on-prem). Service account keys are an audit red flag in 2026.
- **BigQuery Studio** (2024-2025) is the unified SQL + notebook + Spark + Dataform IDE inside BigQuery. BigQuery has vector search GA, continuous queries GA, and a `REMOTE MODEL` syntax for Gemini calls in SQL.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on a Google Cloud Platform engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **The project is the unit of isolation.** Treat the GCP project as the blast radius for IAM, billing, quota, networking, and ops alike. Default to "new project per concern" not "shared project, more roles." Use Workload Identity Federation, never service account keys.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Google Cloud Platform | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Google Cloud Platform alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
