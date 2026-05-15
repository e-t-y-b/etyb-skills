---
title: Google Cloud Platform
description: GCP platform knowledge overlay — Cloud Run, GKE, BigQuery, Vertex AI, Spanner, AlloyDB, IAM, Cloud Armor, Workload Identity Federation. Current to 2026-Q2.
stack:
  vendor: gcp
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
  authoritative_sources:
    - { name: "Google Cloud Docs", url: "https://cloud.google.com/docs", type: official_docs }
    - { name: "gcloud CLI Reference", url: "https://cloud.google.com/sdk/gcloud/reference", type: cli_reference }
    - { name: "GCP Release Notes", url: "https://cloud.google.com/release-notes", type: changelog }
    - { name: "GCP Security Bulletins", url: "https://cloud.google.com/security-bulletins", type: security_advisories }
    - { name: "Google Cloud Architecture Center", url: "https://cloud.google.com/architecture", type: official_docs }
    - { name: "Vertex AI Docs", url: "https://cloud.google.com/vertex-ai/docs", type: official_docs }
    - { name: "BigQuery Docs", url: "https://cloud.google.com/bigquery/docs", type: official_docs }
    - { name: "GKE Docs", url: "https://cloud.google.com/kubernetes-engine/docs", type: official_docs }
    - { name: "Cloud Run Release Notes", url: "https://cloud.google.com/run/docs/release-notes", type: release_notes }
    - { name: "Terraform google provider", url: "https://registry.terraform.io/providers/hashicorp/google/latest/docs", type: api_reference }
  delegate_to_skills: []
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against GCP product surface — Gemini 2.5 (Pro/Flash/Flash-Lite), Vertex AI Agent Builder + Agentspace, BigQuery Studio, Cloud Run gen2 GPU + sidecars, AlloyDB AI, Spanner Graph + granular PU sizing, Memorystore for Valkey 9.0, Eventarc Advanced.</div>

GCP moves fast — model lineups, agent product boundaries, and Cloud Run feature surface churn quarterly. If today is more than 6 months past the last_verified_on above, bias toward the [authoritative sources](#authoritative-sources) for any time-sensitive claim. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

An LLM with a 2023 or even mid-2024 cutoff will get these wrong:

- **Cloud Functions gen2 is now officially "Cloud Run functions"** — same product, new branding. Gen1 is deprecated; new development goes to Cloud Run vocabulary.
- **Container Registry (`gcr.io`) is deprecated.** Artifact Registry (`<region>-docker.pkg.dev`) is the only path for new image pushes. Legacy `gcr.io` hostnames redirect for now.
- **Deployment Manager end-of-support: December 31, 2025.** Migrate to Infrastructure Manager (managed Terraform) or self-managed Terraform.
- **Duet AI for Developers → Gemini Code Assist** (Feb 2024 rebrand). Backend swapped to Gemini 2.5 in 2025; Code Assist Agents shipped in 2025-2026 for agentic IDE workflows.
- **Generative AI App Builder → Vertex AI Agent Builder.** Now layered with **Agentspace** (enterprise agent surface, 2025) and **Conversational Agents** (was Dialogflow CX, now generative-grounded).
- **Memorystore default is Valkey 9.0, not Redis.** +40% throughput from pipeline prefetching; +200% on BITCOUNT via SIMD. Existing Redis tiers still supported.
- **Spanner granular PU sizing**: starts at 100 PU (~$65/month). 1000 PU = 1 node. 3-year CUDs are 40% off. Old "Spanner minimum $750/month" intuition is wrong.
- **Spanner Graph + GraphQL endpoint** (2024). Spanner now offers a property graph + Cypher-like queries via `GRAPH_TABLE(...)`.
- **AlloyDB AI** (2024-2025) ships pgvector + Vertex embedding integration in-engine via `google_ml.embedding(...)`. Eliminates separate vector DB for most workloads.
- **Cloud Run GPU is GA** (NVIDIA L4) with RTX PRO 6000 Blackwell in Preview. Gen2 sidecars (multi-container) + Direct VPC egress + 60-min HTTP timeout (services), 24h (jobs).
- **Eventarc Advanced** (GA Aug 2025) introduces a centralized bus + distributed pipeline model alongside Eventarc Standard.
- **Workload Identity Federation** is the production answer for non-GCP workloads. Service account JSON keys are an audit red flag in 2026. SAML and X.509 federation now GA.
- **BigQuery Studio** (2024-2025) unifies SQL + notebook + Spark + Dataform IDE. **Vector search GA**, **continuous queries GA**, **`ML.GENERATE_TEXT` / `ML.GENERATE_EMBEDDING`** for Gemini-from-SQL.
- **Trace sinks deprecated Feb 2026** — migrate to Observability Analytics. New projects after March 2026 auto-enable the Telemetry API.
- **App Engine** is in maintenance mode — not retired, but actively discouraged for greenfield. Default to Cloud Run.
- **Firebase Studio** (was Project IDX) consolidates Firebase + GCP for prototyping.

If you find yourself recommending Cloud Functions gen1 syntax, `gcr.io` image paths, Deployment Manager, Duet AI, "Generative AI App Builder", Redis as the Memorystore default, Spanner-as-only-for-FAANG-scale, or App Engine for greenfield — your training is stale.

## Products covered

Per-product pages are linked below. Drift-risk reflects how fast the product surface moves; refresh thresholds are governed by the [knowledge currency model](/conventions/knowledge-currency/).

### Compute

| Product | Drift risk | Why |
|---|---|---|
| [Cloud Run](/stacks/gcp/cloud-run/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Gen2 sidecars + GPU GA, Direct VPC egress GA, 60-min HTTP timeout, multi-container — features moved fast 2025-2026 |
| [Cloud Run Jobs](/stacks/gcp/cloud-run-jobs/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Run-to-completion workloads with parallelism; up to 24h runtime |
| [Cloud Run functions](/stacks/gcp/cloud-functions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Cloud Functions gen2 rebranded; gen1 deprecated |
| [GKE](/stacks/gcp/gke/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Release channels (RAPID/REGULAR/STABLE); auto-upgrade discipline; Workload Identity standard |
| [GKE Autopilot](/stacks/gcp/gke-autopilot/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Per-pod billing model + GPU/TPU support evolving; default pod density changed 2025 |
| [App Engine](/stacks/gcp/app-engine/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Legacy. Standard & Flex supported but actively discouraged for greenfield |
| [Compute Engine](/stacks/gcp/compute-engine/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Foundational; C4A (Arm/Axion) cheaper for compatible workloads; Spot up to 91% off |
| [Anthos / GKE Enterprise](/stacks/gcp/anthos/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Multi-cluster fleet + Config Sync + Policy Controller; mature |

### Data & Databases

| Product | Drift risk | Why |
|---|---|---|
| [Cloud Storage](/stacks/gcp/cloud-storage/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Foundational; Autoclass auto-transitions classes |
| [Cloud SQL](/stacks/gcp/cloud-sql/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature; Enterprise Plus near-zero-downtime maintenance; up to 128 vCPUs |
| [AlloyDB](/stacks/gcp/alloydb/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | AlloyDB AI / columnar engine / vector search evolving; pgvector + Vertex coupling new in 2025 |
| [Spanner](/stacks/gcp/spanner/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | GraphQL endpoint (2024), Spanner Graph, granular PU sizing, managed autoscaler, PG dialect |
| [Firestore](/stacks/gcp/firestore/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | MongoDB compatibility (Preview), multi-database GA, Native vs Datastore mode confusion |
| [Bigtable](/stacks/gcp/bigtable/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Petabyte-scale wide-column; continuous materialized views Preview |
| [Memorystore](/stacks/gcp/memorystore/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Default engine shifted to Valkey 9.0; new builds default Valkey not Redis |
| [BigQuery](/stacks/gcp/bigquery/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | BigQuery Studio unification, vector search GA, continuous queries GA, editions repositioned |
| [BigQuery ML](/stacks/gcp/bigquery-ml/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Direct Vertex AI Gemini integration via `REMOTE MODEL`, in-engine embeddings |
| [BigLake](/stacks/gcp/biglake/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Cross-cloud querying of S3 + Azure Blob; cross-cloud joins GA |

### Data Pipelines & Streaming

| Product | Drift risk | Why |
|---|---|---|
| [Pub/Sub](/stacks/gcp/pub-sub/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Foundational; BigQuery subscription + Cloud Storage subscription mature |
| [Dataflow](/stacks/gcp/dataflow/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Dataflow Prime + GPU support; Apache Beam managed |
| [Dataproc](/stacks/gcp/dataproc/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Dataproc Serverless GA; default for new Spark workloads |
| [Dataform](/stacks/gcp/dataform/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Integrated into BigQuery Studio; SQL ELT orchestration |
| [Looker](/stacks/gcp/looker/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Embedded BI; LookML modeling; semantic layer |
| [Looker Studio](/stacks/gcp/looker-studio/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Free dashboarding; Looker Studio Pro for managed |

### AI & ML

| Product | Drift risk | Why |
|---|---|---|
| [Vertex AI](/stacks/gcp/vertex-ai/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Gemini 2.5 family, Imagen 4, Veo 3, model garden churns quarterly |
| [Gemini](/stacks/gcp/gemini/) | <span class="etyb-drift-badge" data-risk="high">high</span> | 2.5 Pro/Flash/Flash-Lite; 1M+ context; prompt caching; thinking budget |
| [Gemini Code Assist](/stacks/gcp/gemini-code-assist/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Was Duet AI; Gemini 2.5 backend; Code Assist Agents (agentic) added 2025-2026 |
| [Imagen](/stacks/gcp/imagen/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Imagen 4 text-to-image; SynthID watermark; via Vertex AI |
| [Veo](/stacks/gcp/veo/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Veo 3 text-to-video / image-to-video; via Vertex AI |
| [Vertex AI Agent Builder](/stacks/gcp/agent-builder/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Renamed twice (Gen AI App Builder → Agent Builder); framework boundaries shifted |
| [Agentspace](/stacks/gcp/agentspace/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2025; enterprise agent application surface; connectors evolving |

### Security & Identity

| Product | Drift risk | Why |
|---|---|---|
| [Cloud IAM](/stacks/gcp/cloud-iam/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Hierarchical model stable; deny policies + IAM Conditions mature |
| [Cloud KMS](/stacks/gcp/cloud-kms/) | <span class="etyb-drift-badge" data-risk="low">low</span> | CMEK + EKM patterns mature; default for regulated workloads |
| [Secret Manager](/stacks/gcp/secret-manager/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; Parameter Manager GA companion for non-secret config |
| [Cloud Armor](/stacks/gcp/cloud-armor/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | JA4 fingerprinting GA, hierarchical policies GA, body inspection raised 2025 |
| [Cloud CDN](/stacks/gcp/cloud-cdn/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; pairs with GLB + Cloud Armor for edge stack |
| [VPC](/stacks/gcp/vpc/) | <span class="etyb-drift-badge" data-risk="low">low</span> | VPC + Shared VPC + VPC-SC; default-network antipattern |

### Observability

| Product | Drift risk | Why |
|---|---|---|
| [Cloud Logging](/stacks/gcp/logging/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Log Analytics GA, Telemetry API auto-enabled March 2026, trace sinks deprecated Feb 2026 |
| [Cloud Monitoring](/stacks/gcp/monitoring/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | OTLP ingestion GA, PromQL + MQL, SLO service mature |

### CI/CD & Tooling

| Product | Drift risk | Why |
|---|---|---|
| [Cloud Build](/stacks/gcp/cloud-build/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Private pools GA, binauthz integration mature |
| [Cloud Deploy](/stacks/gcp/cloud-deploy/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Cloud Run + GKE + Anthos targets; canary via Service Mesh integration |
| [Artifact Registry](/stacks/gcp/artifact-registry/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Container Registry (`gcr.io`) deprecated; ALL new workloads use Artifact Registry |
| [gcloud CLI](/stacks/gcp/gcloud-cli/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable but constant additions; alpha/beta surfaces large; release-track flags matter for IaC |

## Role overlays

Composed role views — each stitches the products that role's work touches on GCP, with links into the per-product canonical pages.

- [system-architect on GCP](/stacks/gcp/system-architect/) — compute primitive selection, project hierarchy, multi-region DR
- [backend-architect on GCP](/stacks/gcp/backend-architect/) — Cloud Run patterns, Pub/Sub, Eventarc, Workflows, outbound auth
- [database-architect on GCP](/stacks/gcp/database-architect/) — Cloud SQL vs AlloyDB vs Spanner vs Firestore vs Bigtable; vector search
- [devops-engineer on GCP](/stacks/gcp/devops-engineer/) — gcloud, Terraform, Cloud Build, Cloud Deploy, Artifact Registry, WIF
- [security-engineer on GCP](/stacks/gcp/security-engineer/) — IAM hierarchy, WIF, VPC-SC, Cloud Armor, KMS, SCC
- [sre-engineer on GCP](/stacks/gcp/sre-engineer/) — SLOs in Cloud Monitoring, OTel + Ops Agent, on-call routing
- [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/) — Gemini routing, Vertex AI inference, accelerator selection, Agent Builder
- [saas-architect on GCP](/stacks/gcp/saas-architect/) — tenant isolation models, Identity Platform, Marketplace, cost attribution

## Authoritative sources

For verified-current behavior, the canonical Google surfaces:

- **[Google Cloud Docs](https://cloud.google.com/docs)** — canonical reference
- **[GCP Release Notes](https://cloud.google.com/release-notes)** — cross-product changelog
- **[GCP Security Bulletins](https://cloud.google.com/security-bulletins)** — CVEs and platform advisories
- **[Cloud Run Release Notes](https://cloud.google.com/run/docs/release-notes)** — for GPU / sidecar / timeout changes
- **[Vertex AI Release Notes](https://cloud.google.com/vertex-ai/docs/release-notes)** — model lineup + Agent Builder + Agentspace
- **[gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)** — authoritative command surface
- **[Google Cloud Architecture Center](https://cloud.google.com/architecture)** — reference architectures
- **[Terraform google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)** — IaC reference (pair with `google-beta`)

## Delegate skills

No first-party Google Cloud MCP server is generally available in current users' environments as of `last_verified_on`. Public-roadmap signals point to GCP MCP coverage in 2026 — when a Google-hosted MCP shipping path lands with a known skill identifier, it will be added to `delegate_to_skills` and ETYB will defer to it for matching products.

Until then, the Stack content here is the curated knowledge layer; the [authoritative sources](#authoritative-sources) above are the live truth.
