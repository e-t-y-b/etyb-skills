# GCP Cloud Engineering — Pointer

As of v4.0.0 (2026-05-14), all GCP-specific guidance — compute (Cloud Run, GKE Autopilot, Functions), data (BigQuery, AlloyDB, Spanner, Firestore), networking, IAM, observability, AI/ML (Vertex AI, Gemini, Agent Builder, Agentspace, TPU v7 Ironwood), and 2025-2026 platform shifts — lives across two layers: the slim local detection pointer at [`stacks/gcp/SKILL.md`](../../../../../../stacks/gcp/SKILL.md) and the canonical per-product + per-role pages at **<https://docs.etyb.ai/stacks/gcp/>**, fetched at runtime per `skills/etyb/core/knowledge-currency.md`.

## Where that content lives now

| Topic | Canonical location on docs.etyb.ai |
|-------|------------------------------------|
| Compute selection (Cloud Run gen2, GKE, Cloud Functions, App Engine) | <https://docs.etyb.ai/stacks/gcp/system-architect/>, <https://docs.etyb.ai/stacks/gcp/backend-architect/> |
| Networking, Cloud Armor, Cloud CDN, VPC | <https://docs.etyb.ai/stacks/gcp/system-architect/>, <https://docs.etyb.ai/stacks/gcp/security-engineer/> |
| Databases — Cloud SQL, AlloyDB (incl. AI), Spanner (incl. GraphQL), Firestore, Bigtable, BigQuery | <https://docs.etyb.ai/stacks/gcp/database-architect/> |
| IAM, Workload Identity Federation, VPC-SC, Secret Manager, Cloud KMS | <https://docs.etyb.ai/stacks/gcp/security-engineer/> |
| Serverless + Eventarc + Workflows + Cloud Tasks | <https://docs.etyb.ai/stacks/gcp/backend-architect/> |
| IaC — Terraform google provider, Config Connector, Infrastructure Manager | <https://docs.etyb.ai/stacks/gcp/devops-engineer/> |
| Observability — Cloud Ops, Managed OTel, Managed Prometheus | <https://docs.etyb.ai/stacks/gcp/sre-engineer/> |
| AI/ML — Vertex AI, Gemini Code Assist, Agent Builder, Agentspace, TPUs, Model Garden, AlloyDB AI | <https://docs.etyb.ai/stacks/gcp/ai-ml-engineer/> |
| Cost optimization — CUDs, Spot, FinOps Hub | distributed across the system-architect, devops-engineer, sre-engineer role views |
| Multi-cloud — Anthos, BigLake, BigQuery Omni | <https://docs.etyb.ai/stacks/gcp/system-architect/>, <https://docs.etyb.ai/stacks/gcp/saas-architect/> |

## Why the move

Vendor knowledge drifts. GCP's product naming has shifted heavily in 2024-2025 (Duet AI → Gemini Code Assist, Generative AI App Builder → Vertex AI Agent Builder, Container Registry → Artifact Registry, Cloud Functions terminology consolidation into Cloud Run functions, etc.). The v4.0.0 knowledge-currency framework (`skills/etyb/core/knowledge-currency.md`) makes drift visible: every Stack carries `last_verified_on`, authoritative-source URLs, and per-product `drift_risk` ratings. The DevOps Engineer specialist owns *platform-neutral* DevOps patterns; the GCP Stack adds the platform-specific layer when ETYB's router detects GCP signals.
