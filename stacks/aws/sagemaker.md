---
title: SageMaker
description: ML lifecycle on AWS — SageMaker AI Studio (Unified) for data + ML workflow, HyperPod for distributed training (NVL72 + Trainium2/3), endpoints (real-time / async / serverless / batch / multi-model).
product:
  name: SageMaker
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, database-architect]
  authoritative_url: https://docs.aws.amazon.com/sagemaker/
  notes: "Unified Studio launched 2024; HyperPod additions 2025-2026 (NVL72, checkpointless training, dynamic scaling); fast-moving."
---

## What it is

Amazon SageMaker is AWS's end-to-end ML platform — data prep, notebooks, training (single-node + distributed), deployment, monitoring. **SageMaker AI Studio (Unified)** is the 2024 unified workspace covering data + ML + analytics. **HyperPod** is the distributed training infrastructure for large-model training. **Endpoints** serve inference in real-time, async, serverless, batch, or multi-model modes.

Canonical surface: [docs.aws.amazon.com/sagemaker](https://docs.aws.amazon.com/sagemaker/).

## When to use

| Need | Use SageMaker? |
|---|---|
| Building custom models (not just using [Bedrock](/stacks/aws/bedrock/)) | Yes |
| Full ML lifecycle (data → train → deploy → monitor) | Yes |
| Distributed training (>100 GPUs, >10B parameters) | Yes — HyperPod |
| Just calling pre-trained foundation models | No — use Bedrock |
| Just doing inference with no training | Yes if scale/cost justifies; otherwise Bedrock |
| Team is app engineers, not data scientists | Bedrock first; SageMaker when training is required |

## 2025-2026 currency anchors

- **SageMaker Unified Studio / SageMaker AI Studio** — one-click onboarding with existing AWS data (Athena, Redshift, S3); unified workspace.
- **SageMaker HyperPod** — distributed training infrastructure:
  - **Checkpointless training** — auto-recovery in minutes, >95% goodput.
  - **Dynamic scaling** — expand/contract running jobs to absorb idle accelerators.
  - **NVL72 UltraServer** — 18 instances × 72 Blackwell GPUs via NVLink.
  - **JupyterLab + Code Editor** on persistent EKS clusters (Nov 2025).
  - **Managed Grafana dashboards** for GPU/network/cluster health (Mar 2026).
- **Trainium2 GA**, **Trainium3 preview end 2025 → volume 2026**. Majority of [Bedrock](/stacks/aws/bedrock/) token usage already on Trainium.
- **Inferentia2** GA (de-emphasized for GenAI; used for traditional ML serving).

## Patterns

### Endpoint type selection

| Type | Use for |
|---|---|
| **Real-time** | Sync inference, latency-sensitive |
| **Serverless** | Variable load, scale-to-zero acceptable |
| **Async** | Long-running inference (>1min) |
| **Batch transform** | Offline bulk inference |
| **Multi-model endpoint** | Many models, infrequent traffic each |

Default for new endpoints: **Serverless** for spiky workloads, **Real-time** for steady high-RPS, **Async** when input/output are large or compute is long.

### Custom silicon — Trainium / Inferentia

| Chip | Status | Use for |
|---|---|---|
| **Trainium2** | GA | Training + inference; 30-40% better price-perf vs GPUs |
| **Trainium3** | Preview end 2025, volume 2026 | 4.4x perf vs Trn2 |
| **Inferentia2** | GA (de-emphasized for GenAI) | Cost-optimized traditional ML serving |

For your own training: Trn2 is cost-effective vs P4/P5/P6 GPUs. Catch: compile for Neuron (Trainium SDK) — most models work; custom ops may not.

For inference: P5/P6 GPU is safer for broad model + framework support; Inf2/Trn2 when cost is the priority and the model compiles cleanly.

### Fine-tuning on SageMaker

For deeper customization than Bedrock fine-tuning: SageMaker Training Jobs + your data + HuggingFace / PyTorch + deploy to SageMaker endpoint.

- **LoRA / QLoRA** via HuggingFace PEFT — most cost-effective for adapter-style fine-tuning.
- **Full fine-tuning** on Trainium2 — when adapters aren't enough.
- **Continued pretraining** for domain adaptation (rare in 2026 — RAG usually wins).

### Model Monitor + Clarify

- **Model Monitor**: data drift + model drift detection on deployed endpoints. Scheduled jobs compare baseline statistics vs production traffic.
- **Clarify**: bias detection + explainability (SHAP). Pre-deploy fairness audits; integrate into Model Monitor for continuous bias monitoring.

For any production model, both are non-negotiable.

### Pipelines

SageMaker Pipelines for ML lifecycle orchestration:
- Data prep → training → evaluation → registration → deployment.
- Conditional steps (deploy only if model beats baseline).
- Integration with Step Functions for broader workflows.

### When NOT to fine-tune

- **Better prompts + RAG can usually beat fine-tuning** for knowledge updates. Try first.
- **Fine-tuned models go stale** as base models improve.
- **The data isn't there.** Fine-tuning needs hundreds-thousands of high-quality examples.

## Anti-patterns

- **SageMaker when Bedrock fits.** For foundation-model inference, Bedrock + AgentCore is simpler.
- **Self-managed training on EC2** when SageMaker / HyperPod offers managed orchestration with similar GPUs at similar cost.
- **No drift / bias monitoring on production endpoints.** Silent quality degradation.
- **Training without checkpoints** on long jobs. HyperPod's checkpointless training helps but isn't free.
- **Real-time endpoint for batch workloads.** Use batch transform.

## Gotchas

- **Trainium SDK (Neuron) requires compilation step** — most models work, custom ops may not.
- **HyperPod is for large-scale** — small training jobs use SageMaker Training Jobs.
- **SageMaker endpoint cold start** for serverless can be tens of seconds.
- **GPU spot quotas** are per-region and often constrained — request increases before launch.
- **Per-region service availability** for SageMaker features varies; verify against the [SageMaker Regions page](https://docs.aws.amazon.com/general/latest/gr/sagemaker.html).

## Cross-references

- [`/stacks/aws/bedrock/`](/stacks/aws/bedrock/) — foundation models without custom training
- [`/stacks/aws/agentcore/`](/stacks/aws/agentcore/) — production agent layer
- [`/stacks/aws/s3/`](/stacks/aws/s3/) — data source for training
- [`/stacks/aws/glue/`](/stacks/aws/glue/) — ETL prep
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — role view; model selection + training strategy
- [SageMaker HyperPod docs](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-hyperpod.html)
