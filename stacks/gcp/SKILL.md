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

# GCP Stack Pack — Team Briefing

You're working on Google Cloud Platform. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — backend-architect picks the runtime, database-architect picks Spanner vs AlloyDB vs Cloud SQL, ai-ml-engineer orchestrates Vertex AI and Agent Builder, security-engineer enforces Workload Identity Federation and VPC Service Controls. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against GCP product surface as of **2026-05-14** — Gemini 2.5 family (Pro, Flash, Flash-Lite), Vertex AI Agent Builder + Agentspace, BigQuery Studio unification (2024-2025), Cloud Run gen2 with sidecars and GPU, AlloyDB AI, Spanner Graph + granular PU sizing, Memorystore for Valkey 9.0, Eventarc Advanced (Aug 2025), Deployment Manager end-of-support Dec 31, 2025, Container Registry → Artifact Registry redirect. If today's date is more than 6 months past `last_verified_on`, the pack is stale — warn the user and consult [GCP release notes](https://cloud.google.com/release-notes) before recommending API-level details.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2023 or even mid-2024 cutoff will get these wrong:

- **Cloud Functions gen2 is now officially "Cloud Run functions"** — same product, new branding (mid-2024). Gen1 is deprecated. Don't recommend `gcloud functions deploy --gen2` in new docs; use the Cloud Run path.
- **Container Registry (`gcr.io`) is deprecated.** Artifact Registry is the only path for new image pushes. The `gcr.io` hostname now redirects but new repos must live in Artifact Registry.
- **Deployment Manager end-of-support: December 31, 2025.** If a customer is still running Deployment Manager, migration to Infrastructure Manager (managed Terraform) or self-managed Terraform is overdue, not aspirational.
- **Duet AI for Developers is now Gemini Code Assist** (Feb 2024 rebrand). The backend swapped to Gemini 2.5 across 2025. **Gemini Code Assist Agents** (agentic mode) shipped in 2025-2026 — IDE-side autonomous workflows.
- **Generative AI App Builder → Vertex AI Agent Builder → now augmented by Agentspace and Conversational Agents.** The agent product line has been renamed twice; older training will reach for the wrong console paths and SDK names.
- **Agentspace** (2025) is Google's enterprise agent surface — search + agent assistant + connectors across Workspace/M365/Salesforce/etc. It is distinct from Agent Builder (which builds agents) — Agentspace consumes agents at the enterprise application layer.
- **Memorystore default engine is Valkey, not Redis.** Valkey 9.0 ships pipeline prefetching (+40% throughput) and SIMD BITCOUNT (+200%). Existing Redis tiers still work; new builds default to Valkey.
- **Spanner has a GraphQL endpoint and Spanner Graph** (2024). Spanner is no longer just "expensive global SQL." Granular PU sizing starts at 100 PU (~$65/month); old "minimum 1 node" pricing intuition is obsolete.
- **AlloyDB AI** (2024-2025) ships pgvector + Vertex AI embedding integration in-engine. AlloyDB columnar engine accelerates analytical SQL on transactional data. Don't reach for a separate analytical store reflexively.
- **Cloud Run GPU is GA** (NVIDIA L4) with RTX PRO 6000 Blackwell in Preview. Cloud Run with sidecars (GA) makes the OTel-collector-in-sidecar pattern trivial. Direct VPC egress (GA) replaces the old Serverless VPC Access connector for most cases.
- **Eventarc Advanced** (GA, Aug 2025) introduces a centralized bus + distributed pipelines model. Eventarc Standard still works for point-to-point; Advanced is the multi-team enterprise shape.
- **Workload Identity Federation** is the production answer for non-GCP workloads (GitHub Actions, AWS, on-prem). Service account keys are an audit red flag in 2026.
- **BigQuery Studio** (2024-2025) is the unified SQL + notebook + Spark + Dataform IDE inside BigQuery. Older "BigQuery Console + separate Dataform UI" mental model is wrong.
- **BigQuery has vector search GA, continuous queries GA, and a `REMOTE MODEL` syntax** for Gemini calls in SQL. ML-in-the-warehouse is real here, not just a slide.
- **Trace sinks deprecated Feb 2026** — migrate to Observability Analytics. New projects after **March 2026 auto-enable the Telemetry API** alongside Cloud Logging.
- **App Engine** is in maintenance mode — not retired, but actively discouraged for new builds. Default to Cloud Run.
- **Firebase Studio** (was Project IDX) is consolidating with GCP — the boundary between "Firebase product" and "GCP product" is blurring rapidly. Treat them as one ecosystem for greenfield.
- **Cloud Run gen2** quietly raised the HTTP timeout to **60 minutes** (services), 24 hours (jobs). Old "Cloud Run is for sub-5-minute requests" claim is wrong.

If you find yourself recommending Cloud Functions gen1 syntax, `gcr.io` image paths, Deployment Manager, Duet AI, "Generative AI App Builder", Redis as the Memorystore default, Spanner-as-only-for-FAANG-scale, or App Engine for greenfield — you're using stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects GCP signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists. Always-on protocols (TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement) apply unchanged. The GCP overlay shapes *how* those protocols apply (e.g., TDD on a Cloud Run service = Cloud Build trigger running `pytest` in a Cloud Build private pool; verification on Terraform = `terraform plan` artifact attached to the PR + Infrastructure Manager preview).

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | **The architectural decision** — Cloud Run vs GKE vs Functions vs App Engine; multi-region vs single-region; project / folder / org hierarchy; landing zone shape; Anthos vs single-cloud; integration boundaries; data residency posture |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | Cloud Run (sidecars, GPU, jobs, gen2 quirks); Cloud Run functions migration from gen1; Pub/Sub patterns (BigQuery subscription, exactly-once); Eventarc Advanced bus/pipeline; Workflows for orchestration; Cloud Tasks vs Cloud Scheduler; Named-credential equivalents (Workload Identity Federation outbound) |
| `database-architect` | [`references/database-architect.md`](references/database-architect.md) | Cloud SQL vs AlloyDB vs Spanner vs Firestore vs Bigtable decision matrix; AlloyDB AI + columnar engine; Spanner sizing (PU, CUDs, autoscaler); BigQuery editions vs on-demand; BigLake / BigQuery Omni; Memorystore for Valkey; Datastream / CDC patterns |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | gcloud CLI, Terraform google provider (+google-beta), Infrastructure Manager, Config Connector, Cloud Build, Cloud Deploy, Artifact Registry, Binary Authorization, release tracks (REGULAR/RAPID/STABLE), GKE upgrade discipline, deployment-strategy choices (blue/green, canary), Workload Identity Federation for CI |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | IAM hierarchy + IAM Conditions, Workload Identity Federation (mandatory pattern), VPC Service Controls perimeters, Cloud Armor (JA4, hierarchical), Secret Manager + Parameter Manager, Cloud KMS / EKM, BeyondCorp Enterprise, Security Command Center, Chronicle, Assured Workloads |
| `sre-engineer` | [`references/sre-engineer.md`](references/sre-engineer.md) | SLO authoring with Cloud Monitoring, log-based metrics, OTel ingestion via Ops Agent + Managed OTel for GKE, alert policy design, on-call routing via PagerDuty integration, error budgets, capacity planning with Recommender + Active Assist, telemetry API migration |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **Gemini 2.5 routing** (Pro vs Flash vs Flash-Lite), Vertex AI inference architectures, Vertex AI Agent Builder + Conversational Agents + Agentspace, Model Garden (Llama, Gemma, Mistral, Claude on Vertex), BYOM, Vertex AI Pipelines, Feature Store, BigQuery ML `REMOTE MODEL`, accelerator selection (TPU v5e/Trillium/Ironwood vs A3 Ultra vs G2), Imagen 4 and Veo 3 |
| `saas-architect` | [`references/saas-architect.md`](references/saas-architect.md) | Multi-tenant patterns on GCP — project-per-tenant vs shared-project + label/folder, Cloud Run + Firestore namespace strategies, tenant isolation via VPC-SC, billing-account routing for charge-back, Identity Platform vs Identity-Aware Proxy, Marketplace publishing for SaaS distribution |

## Top GCP gotchas the team must know

Opinionated, named, with consequences. These are the calls a 2024-trained model gets wrong most often.

1. **The project is the IAM blast radius.** Not the resource, not the folder — the project. Most over-permissioned IAM grants happen because someone granted `roles/editor` at the project level instead of a least-privilege role at the resource level. Default: deny `roles/owner`, `roles/editor`, `roles/viewer` at project scope for human users; use predefined roles or custom roles bound to specific resources. Inherited from the folder/org you set up under: **the org policy hierarchy is your first line of defense**.

2. **Service account keys are an audit red flag in 2026.** Workload Identity Federation (WIF) is the production answer for GitHub Actions, AWS, on-prem. If you find yourself running `gcloud iam service-accounts keys create`, stop — that key will leak. The only legitimate use of a downloaded key in 2026 is bootstrap onto a non-WIF-capable system, with key rotation automated.

3. **`gcr.io` and Container Registry are deprecated.** New image pushes must go to Artifact Registry (`<region>-docker.pkg.dev`). Existing `gcr.io` hostnames redirect for now but new builds must target Artifact Registry. CI/CD that still pushes to `gcr.io` will break silently when a regional repo isn't there.

4. **App Engine is in maintenance mode.** Standard and Flex still work, but Google is actively pushing greenfield to Cloud Run. If a customer is on App Engine Standard with no specific reason (sticky session, legacy framework), the migration to Cloud Run is straightforward and worth the budget. Don't recommend App Engine for new builds.

5. **Cloud Run gen2 is NOT just "Cloud Run."** Gen2 sidecars (multi-container per service), gen2 GPU (L4 GA, RTX PRO 6000 Preview), gen2 Direct VPC egress (no more Serverless VPC Access connector for most cases), gen2 60-minute timeout, gen2 jobs with parallelism. Pre-2024 "Cloud Run is just stateless containers under 5 minutes" mental model is wrong.

6. **VPC default networks are a security antipattern in production.** The auto-created `default` VPC has open ingress rules and broad firewall scope. Turn it off at org policy level (`compute.skipDefaultNetworkCreation`) and create explicit VPCs per environment with deliberate subnet + firewall design.

7. **BigQuery on-demand vs editions pricing flips the cost equation.** On-demand ($6.25/TB scanned) is the default and the right answer for low query volume. Editions (Standard / Enterprise / Enterprise Plus) sell **slots** (compute capacity) — cheaper for predictable, high-volume analytic workloads, especially with autoscaling slots + CUDs. **Don't recommend editions reflexively** — small workloads pay more on editions than on-demand.

8. **Spanner's pricing model is granular now.** Old "Spanner is too expensive, minimum 1 node = $750/month" advice is wrong. Granular Processing Units start at **100 PU (~$65/month)**; 1000 PU = 1 node. 3-year CUDs are 40% off. For globally consistent workloads where Cloud SQL's HA model doesn't fit, Spanner is no longer cost-prohibitive at dev/staging scale.

9. **Firestore in Native mode ≠ Firestore in Datastore mode.** These are two product modes, set at database creation, irreversible. Native is the modern path (real-time listeners, mobile SDKs, MongoDB compatibility Preview). Datastore mode is the legacy Cloud Datastore API. Customers asking for "Firestore" usually mean Native; clarify before provisioning.

10. **Trace sinks are deprecated and the Telemetry API is auto-enabled on new projects from March 2026.** Customers wiring up trace export today must use OTLP into Cloud Trace (via the Ops Agent or Managed OTel for GKE), not trace sinks. The Telemetry API consolidates Cloud Logging + Monitoring + Trace ingestion; old code paths still work but new builds should target Telemetry API endpoints.

## Compliance composition — when vertical packs load alongside

When the GCP work touches a regulated vertical, the vertical pack handles compliance semantics; this pack handles GCP-specific *enablers*:

| Vertical | GCP pack provides | Vertical pack owns |
|----------|------------------|---------------------|
| `healthcare-architect` (HIPAA, FHIR) | Assured Workloads HIPAA package, BAA-eligible services list, Cloud Healthcare API (FHIR R4 store + DICOM + HL7 v2), VPC-SC perimeter design, CMEK with HSM-backed KMS | HIPAA controls themselves, audit discipline, BAA scope, FHIR semantics, PHI handling |
| `fintech-architect` (PCI, PSD2, SOX) | Assured Workloads PCI package, CMEK + EKM patterns, Confidential Computing (Confidential VMs / GKE), VPC-SC perimeter, Spanner for global ACID ledger underlay | PCI controls, ledger design, AML/KYC integration, financial reconciliation, regulator-specific audit trail |
| `e-commerce-architect` | Cloud CDN + Cloud Armor + GLB for storefront, Spanner / AlloyDB for catalog + inventory, Pub/Sub for order events, BigQuery for analytics, Vertex AI for personalization/search | Cart/checkout/order patterns, payment integration, fraud architecture |
| `social-platform-architect` | Bigtable for feed timelines, Pub/Sub fan-out, Spanner for social graph, Cloud CDN for media, Vertex AI for moderation/ranking | Feed ranking, fan-out strategy, moderation policy, social graph patterns |
| `real-time-architect` | Cloud Pub/Sub low-latency, Memorystore for Valkey, Cloud Run with min-instances + WebSocket support, Firestore real-time listeners, Eventarc Advanced for event-driven systems | WebSocket scaling, real-time protocol selection, conflict resolution |

Never restate compliance content from this pack. Route to the vertical. The vertical pack should never re-derive Cloud Healthcare API semantics — that's our job.

## Stack composition — when GCP runs alongside another cloud

Multi-cloud is real in 2026. Common patterns and what each pack owns:

| Composition | GCP side | Other side |
|-------------|----------|------------|
| GCP + AWS | BigQuery Omni for cross-cloud analytics, GKE on AWS for K8s consistency, Pub/Sub egress to AWS via Eventarc, BigLake on S3 | Lambda/ECS/Bedrock, RDS, S3 lifecycle, AWS-native networking |
| GCP + Azure | BigQuery Omni for Azure Blob, Anthos clusters on Azure, Azure AD as IdP via WIF | Azure Functions, AKS, Azure OpenAI, Azure DevOps |
| GCP + Salesforce | Pub/Sub ingestion of Salesforce Platform Events, BigQuery via Data Cloud Zero Copy, Vertex AI for embedding/grounding, Cloud Run as Named Credential target | Data 360 Zero Copy outbound, Salesforce-side schema |
| GCP + Snowflake | BigQuery Omni vs Snowflake on GCP region tradeoff, Datastream into Snowflake, Pub/Sub → Snowpipe Streaming | Snowflake compute warehouses, Snowflake security model |
| GCP + Databricks | Databricks on GCP region selection, Unity Catalog vs Dataplex, Vertex AI as serving layer for Databricks models | Databricks notebooks, MLflow, Lakehouse architecture |

When the other side has no registered pack, the GCP pack handles GCP-side patterns only — say so explicitly and don't fake the other side's depth.

## Standing instructions for every role on a GCP engagement

1. **Anchor to currency.** Before recommending API shapes, IAM role names, gcloud syntax, or product positioning, check whether your role's overlay covers the area. If covered, follow it. If not, say so and consult [GCP release notes](https://cloud.google.com/release-notes) or [security bulletins](https://cloud.google.com/security-bulletins) before asserting specifics. **Especially true for Vertex AI** — the model lineup and Agent Builder/Agentspace boundaries shift every quarter.

2. **The project is the unit of isolation.** Treat the GCP project as the blast radius for IAM, billing, quota, networking, and ops alike. Default to "new project per concern" not "shared project, more roles." The org policy hierarchy is the only sustainable way to enforce baseline guardrails across many projects.

3. **Workload Identity Federation is the default for non-GCP workloads.** GitHub Actions, AWS workloads calling GCP, on-prem services, third-party CI — all should use WIF. Service account keys are reserved for bootstrap-only scenarios with rotation automation. If a recommendation calls for downloading a JSON key, flag it as a security gap and route to security-engineer.

4. **Honor governor-equivalent limits.** GCP has fewer hard governor limits than Salesforce but plenty of soft ones — quotas, region capacity, Cloud Run concurrency caps, BigQuery slot fairness, Spanner PU minimums, Memorystore tier maximums. Every "what's the limit on X?" answer must reference current quotas (which the user can list with `gcloud compute project-info describe --project <p>` or via the Quotas console), not assumed defaults.

5. **Default to Cloud Run for new compute.** GKE Autopilot when you need full K8s. Cloud Run functions for event-driven single-purpose handlers. **App Engine is not the answer for greenfield.** Cloud Functions gen1 is not the answer either — those calls become `gcloud functions deploy --runtime=...` muscle memory that will produce gen1 artifacts you'll need to migrate.

6. **Stay specific about regions and data residency.** "GCP" is not one location. Regional vs multi-regional vs dual-region resources differ in cost, latency, and compliance posture. Customer in EU? Assume EU data residency requirements until told otherwise; consult Assured Workloads if regulated.

7. **Defer to verticals on domain compliance.** Cloud Healthcare API is the GCP product; HIPAA control posture is healthcare-architect's territory. Assured Workloads PCI package is the GCP enabler; PCI control implementation is fintech-architect's territory. Don't re-derive compliance specifics from this pack.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| HIPAA/FHIR specifics for Cloud Healthcare API workloads | `healthcare-architect` |
| PCI/SOX/PSD2 specifics for fintech workloads | `fintech-architect` |
| ISV/multi-tenant SaaS distribution on GCP Marketplace | `saas-architect` |
| Generic system architecture beyond GCP | `system-architect` (without the pack overlay) |
| Generic CI/CD discipline not GCP-specific | `devops-engineer` (without the pack overlay) |
| Cross-cloud architecture (AWS + GCP + Azure) | `system-architect` with both vendor packs loaded |
| Frontend/mobile work that just consumes GCP APIs | `frontend-architect` / `mobile-architect` (no GCP pack overlay needed) |

## Currency — when this pack is stale

If today's date is **more than 6 months past `last_verified_on`** above, treat the pack as stale. Specifically:

- **Model names** (Gemini 2.5 → Gemini 3.x is the obvious next rev) — verify via [Vertex AI Model Garden](https://cloud.google.com/vertex-ai/docs/start/explore-models)
- **Agent Builder / Agentspace boundaries** — verify via [Vertex AI Agent Builder docs](https://cloud.google.com/agent-builder/docs)
- **Cloud Run feature surface** (GPU types, sidecar limits, timeout caps) — verify via [Cloud Run release notes](https://cloud.google.com/run/docs/release-notes)
- **Spanner PU pricing** and CUD discount percentages — verify via the [Spanner pricing page](https://cloud.google.com/spanner/pricing)
- **Deprecation deadlines** (Deployment Manager Dec 31 2025, Container Registry redirect, trace sinks Feb 2026) — verify against [GCP release notes](https://cloud.google.com/release-notes) for status
- **IAM role names** — predefined roles get added/renamed; verify via the [IAM roles reference](https://cloud.google.com/iam/docs/understanding-roles)

When stale, the pack should still be loaded — it's directionally correct — but every release-note-sensitive claim needs verification before delivery to the user.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- **Looker / Looker Studio** coverage is shallow — covered as BI surfaces but no deep BI authoring guidance (deferred to a future BI sub-pack if demand justifies).
- **Apigee** for API management is mentioned only as a boundary technology; no per-role deep dive (full API-management story is separate stack candidate).
- **Document AI, Contact Center AI, Translation Hub** — referenced under Vertex AI but no role-specific overlay (specialized; engage Google PSO for high-stakes builds).
- **Anthos Service Mesh** is referenced under GKE Enterprise; deep service-mesh design lives in `system-architect` and `devops-engineer` rather than its own surface.
- **Firebase product depth** (Auth, Realtime Database, Crashlytics) — `mobile-architect` and `frontend-architect` are not in this pack's `applies_to_roles` because Firebase is consumed mostly from app code; mention the consolidation with Firebase Studio but defer mobile/web app patterns to those roles' base skill plus Firebase-specific skills.
- **Google Distributed Cloud (air-gapped / edge)** — covered briefly under multi-cloud composition; deep coverage if regulated/sovereign workload demand justifies.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation against the [Google Cloud Architecture Center](https://cloud.google.com/architecture).
