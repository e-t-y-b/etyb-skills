# GCP Cloud Engineering — Pointer

As of v4.0.0 (2026-05-14), all GCP-specific guidance — compute (Cloud Run, GKE Autopilot, Functions), data (BigQuery, AlloyDB, Spanner, Firestore), networking, IAM, observability, AI/ML (Vertex AI, Gemini, Agent Builder, Agentspace, TPU v7 Ironwood), and 2025-2026 platform shifts — lives in this repo under `stacks/<vendor>/`: a slim trigger pointer at the SKILL.md plus per-product canonical pages and per-role composed views as siblings. ETYB reads these directly when installed.

## Where that content lives now

| Topic | In-repo location |
|-------|------------------------------------|
| Compute selection (Cloud Run gen2, GKE, Cloud Functions, App Engine) | `stacks/gcp/system-architect.md`, `stacks/gcp/backend-architect.md` |
| Networking, Cloud Armor, Cloud CDN, VPC | `stacks/gcp/system-architect.md`, `stacks/gcp/security-engineer.md` |
| Databases — Cloud SQL, AlloyDB (incl. AI), Spanner (incl. GraphQL), Firestore, Bigtable, BigQuery | `stacks/gcp/database-architect.md` |
| IAM, Workload Identity Federation, VPC-SC, Secret Manager, Cloud KMS | `stacks/gcp/security-engineer.md` |
| Serverless + Eventarc + Workflows + Cloud Tasks | `stacks/gcp/backend-architect.md` |
| IaC — Terraform google provider, Config Connector, Infrastructure Manager | `stacks/gcp/devops-engineer.md` |
| Observability — Cloud Ops, Managed OTel, Managed Prometheus | `stacks/gcp/sre-engineer.md` |
| AI/ML — Vertex AI, Gemini Code Assist, Agent Builder, Agentspace, TPUs, Model Garden, AlloyDB AI | `stacks/gcp/ai-ml-engineer.md` |
| Cost optimization — CUDs, Spot, FinOps Hub | distributed across the system-architect, devops-engineer, sre-engineer role views |
| Multi-cloud — Anthos, BigLake, BigQuery Omni | `stacks/gcp/system-architect.md`, `stacks/gcp/saas-architect.md` |

## Why the move

Vendor knowledge drifts. GCP's product naming has shifted heavily in 2024-2025 (Duet AI → Gemini Code Assist, Generative AI App Builder → Vertex AI Agent Builder, Container Registry → Artifact Registry, Cloud Functions terminology consolidation into Cloud Run functions, etc.). The v4.0.0 knowledge-currency framework (`skills/etyb/core/knowledge-currency.md`) makes drift visible: every Stack carries `last_verified_on`, authoritative-source URLs, and per-product `drift_risk` ratings. The DevOps Engineer specialist owns *platform-neutral* DevOps patterns; the GCP Stack adds the platform-specific layer when ETYB's router detects GCP signals.
