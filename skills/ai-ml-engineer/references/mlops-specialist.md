# MLOps — Deep Reference

**Always use `WebSearch` to verify version numbers, tooling, and best practices. MLOps tooling evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Model Serving & Inference](#1-model-serving--inference)
2. [ML Pipelines & Orchestration](#2-ml-pipelines--orchestration)
3. [Model Registry & Versioning](#3-model-registry--versioning)
4. [CI/CD for ML](#4-cicd-for-ml)
5. [Model Monitoring & Drift Detection](#5-model-monitoring--drift-detection)
6. [Infrastructure & Compute](#6-infrastructure--compute)
7. [Data Management for ML](#7-data-management-for-ml)
8. [Decision Frameworks](#8-decision-frameworks)

---

## 1. Model Serving & Inference

### LLM Serving

| Engine | Version | Throughput | Best For |
|--------|---------|-----------|----------|
| **vLLM** | v0.19.0 | ~12,500 tok/s (H100) | Default LLM serving — broadest model/hardware support, OpenAI-compatible API |
| **SGLang** | Active | ~16,200 tok/s (H100) | Prefix-heavy workloads (RAG, multi-turn) — RadixAttention gives up to 6.4x gains |
| **TensorRT-LLM** | 1.2.0 | Highest on NVIDIA | Max throughput on NVIDIA GPUs, latency-critical production |

**vLLM (v0.19.0) — Industry Standard:**
- Powers Amazon Rufus (250M customers), LinkedIn, Roblox (4B tokens/week), Meta, Mistral, IBM, Stripe
- GPU-less render serving (`vllm launch render`), NGram speculative decoding, smart CPU KV cache offloading (FlexKV)
- Full NVIDIA Blackwell SM120 and H200 support
- OpenAI-compatible API for drop-in replacement of closed APIs
- **When to use**: Default choice. Best when you need rapid iteration, broad model support, and near-state-of-art performance without engine compilation

**SGLang — Faster for Specific Workloads:**
- 29% higher throughput over vLLM on general benchmarks
- RadixAttention: up to 6.4x gains on prefix-heavy workloads (shared document context, RAG)
- 3.1x faster on DeepSeek V3 specifically
- 3x faster constrained JSON decoding
- **When to use**: Multi-turn chat, shared document context, structured output workloads

**TensorRT-LLM (1.2.0) — Maximum NVIDIA Performance:**
- LLM-optimized, supports DeepSeek V3/R1, Llava-Next, BERT
- Requires compilation step but delivers highest throughput on NVIDIA hardware
- **When to use**: Latency-critical, maximum-throughput production serving on NVIDIA GPUs

### NVIDIA Dynamo (NEW — Major 2026 Development)

Orchestration layer ABOVE inference engines — coordinates SGLang, TensorRT-LLM, and vLLM into distributed multi-node inference systems.

- **Version**: 1.0 (open-source, March 2026)
- Up to 7x inference performance on Blackwell GPUs
- Disaggregates inference phases across GPUs, intelligent request routing
- Adopted by AWS, Azure, Google Cloud, OCI, CoreWeave, Together AI
- **When to use**: Datacenter-scale distributed inference, multi-node reasoning model serving

### Traditional Model Serving

| Engine | Best For | Key Feature |
|--------|----------|-------------|
| **Triton** (2.67.0) | Multi-framework enterprise pipelines | Supports TensorRT, PyTorch, ONNX, Python; dynamic batching, model ensembles |
| **TorchServe** | PyTorch-native deployments | MAR packaging, custom handlers, model versioning, Prometheus metrics |
| **TF Serving** | TensorFlow models | Battle-tested since 2016, SavedModel format, stability |
| **BentoML** | Multi-framework, fast deployment | Python-first, auto Docker images, deploys to any cloud |
| **Ray Serve** (2.54.1) | Unified ML platform | Three-tier architecture, custom autoscaling, token-count batching |

### NVIDIA NIM

Pre-built containers powered by Triton + TensorRT-LLM:
- Deploy models in 5 minutes with standard APIs
- Production-grade runtimes with ongoing security updates
- Free tier for NVIDIA Developer Program (up to 16 GPUs)
- **When to use**: Fastest path from model selection to production on NVIDIA hardware

### Kubernetes-Native Serving

**KServe (v0.15 — CNCF project):**
- New `LLMInferenceService` CRD for GenAI workloads
- KEDA integration for LLM-specific scaling metrics
- Envoy AI Gateway for traffic management
- Lightweight install option for LLM hosting
- **When to use**: Kubernetes-native standardized model serving with autoscaling abstracted away

**Seldon Core (2.9.1):**
- Kafka for real-time data streaming between pipeline components
- MLServer and Triton backends
- Built-in A/B testing and canary rollouts
- **When to use**: Enterprises needing advanced deployment strategies and multi-model pipelines

### Serverless Inference

| Platform | Strength | Best For |
|----------|----------|----------|
| **AWS SageMaker** | Most feature-rich, Unified Studio | AWS-native orgs, flexible scaling |
| **Google Vertex AI** | TPU support, Gemini access, automation | Google Cloud users, TPU workloads |
| **Azure ML** | AutoML, governance, compliance | Microsoft shops, regulated industries |

**SageMaker Serverless**: Pay-per-millisecond for low-traffic endpoints, can scale to zero. SageMaker Unified Studio (late 2025) unifies EMR, Glue, Athena, Bedrock, and SageMaker AI.

**Vertex AI**: TPU support (unique advantage), BigQuery integration, serverless training/prediction billed by the second. Wins on automation and simplicity.

---

## 2. ML Pipelines & Orchestration

### Tool Comparison

| Tool | Version | Architecture | Best For |
|------|---------|-------------|----------|
| **Apache Airflow** | 3.2.0 | DAG-based, task-centric | General-purpose, large ecosystem, complex dependencies |
| **Kubeflow Pipelines** | kfp 2.16.0 | K8s-native, component-based | End-to-end ML on Kubernetes |
| **Prefect** | 3.6.26 | Event-driven, Python-first | Dynamic workflows, operational resilience |
| **Dagster** | 1.13.0 | Asset-centric | Data lineage, strong typing, dev experience |
| **ZenML** | Active | Meta-orchestrator | Multi-tool combination, no vendor lock-in |
| **Metaflow** | 2.19.22 | Human-centric, AWS-native | Python simplicity, rapid prototyping to production |

### Apache Airflow 3.x

The most widely adopted orchestrator. Key 2026 features:
- **Human-in-the-Loop (HITL)**: `HITLOperator` for manual approval steps in ML pipelines
- React-based UI components embeddable in the Airflow interface
- Production-ready monitoring with Airflow notifiers and listeners
- **Strengths**: Automatic retries, complex branching, dynamic pipelines, massive ecosystem
- **When to use**: Teams already using Airflow for data engineering who want to add ML workflows

### Kubeflow Pipelines (kfp 2.16.0)

- UI modernized (React 16 to 19)
- Pod-to-pod TLS for security
- Kubernetes native mode: pipeline definitions stored as CRDs for GitOps integration
- **When to use**: Kubernetes-native teams wanting tight K8s integration and end-to-end ML orchestration

### Prefect 3

- 10x faster than Prefect 2
- `prefect sdk generate` CLI for typed Python SDKs from deployments
- Transaction-based task execution preventing re-execution
- **When to use**: Dynamic, Python-first, event-driven workflows; maximum flexibility without rigid DAG structures

### Dagster (1.13.0)

- AI-assisted development (dagster-io/skills for Claude Code, MCP server integration)
- Asset-based approach naturally maps to ML artifacts, experiments, and model versions
- Partitioned asset checks, virtual assets (preview)
- **When to use**: Teams wanting data asset lineage, well-tested pipelines, strong local dev experience

### ZenML

Meta-orchestrator connecting 50+ MLOps tools:
- Switch between Airflow, Kubeflow, etc. without rewriting code
- Manages both classical ML and AI agents
- **When to use**: Multi-environment workflows; organizations migrating between orchestrators

### Metaflow (2.19.22)

Developed by Netflix; powers 3000+ AI/ML projects:
- Config object for flow-level configuration resolved at deployment time
- Human-centric workflow design
- **When to use**: AWS-centric teams; rapid prototyping to production; Python simplicity

### Pipeline Selection Guide

```
1. Do you already use an orchestrator?
   - Yes, Airflow → Add ML tasks to Airflow (don't introduce a second orchestrator)
   - Yes, another → Evaluate if it meets ML needs before switching
   
2. Are you on Kubernetes?
   - Yes, all-in on K8s → Kubeflow Pipelines
   - Yes, but want flexibility → Dagster or Prefect (both K8s-friendly)
   
3. Team profile?
   - Data engineers adding ML → Airflow (familiar, large ecosystem)
   - ML engineers, Python-first → Prefect or Metaflow
   - Platform team building for others → Dagster (asset lineage, strong typing)
   - Multi-tool shop, no lock-in → ZenML
```

---

## 3. Model Registry & Versioning

### MLflow Model Registry (MLflow 3.10)

The most widely adopted open-source registry:
- `LoggedModel` as first-class entity (beyond run-centric)
- `mlflow.search_logged_models()` with SQL-like syntax
- Multi-workspace support
- Comprehensive lineage tracking: models ↔ runs ↔ traces ↔ prompts ↔ metrics
- Default registry URI now `databricks-uc` (Unity Catalog)
- **Breaking in MLflow 3**: Removed MLflow Recipes, fastai and mleap flavors

### DVC (Data Version Control)

- Open-source, platform-agnostic versioning for data, models, and experiments
- Large files replaced by metafiles pointing to remote storage (S3, GCS, Azure)
- lakeFS acquired DVC in November 2025 — deeper data lake integration
- **When to use**: Git-native teams wanting data/model versioning alongside code

### W&B Model Registry

- Centralized registry with versioning, aliases, lineage tracking
- Improved type-ahead search, drag-and-drop lineage graphs
- Multi-metric plots with regex, baseline comparisons
- **When to use**: Teams already using W&B for experiment tracking wanting unified registry

### HuggingFace Hub

- Git + Git LFS based versioning with commit history, diffs, branches
- 12+ library integrations; Enterprise Hub with SLAs
- **When to use**: Open-source model distribution; LLM/transformer model hosting; community sharing

### Model Versioning Best Practices

1. **Treat models as first-class artifacts** with lineage back to training data, code, and hyperparameters
2. **Use aliases** ("production", "staging", "champion") rather than hard-coded version numbers
3. **Store metadata** (metrics, training data hash, framework version) alongside the artifact
4. **Automate promotion** through CI/CD gates with evaluation thresholds
5. **Maintain immutable artifacts** — never overwrite a version
6. **Version training data alongside models** — use DVC or lakeFS

---

## 4. CI/CD for ML

### ML-Specific CI/CD Patterns

ML CI/CD extends traditional CI/CD with three additional continuous processes:

| Process | Trigger | What It Does |
|---------|---------|-------------|
| **Continuous Integration** | Code change | Lint, unit tests, data validation |
| **Continuous Delivery** | Model promoted | Package model, integration tests, deploy to staging |
| **Continuous Training (CT)** | Drift detected / schedule | Automated retraining pipeline |
| **Continuous Monitoring (CM)** | Always running | Drift detection, performance tracking, alerting |

### CML (Continuous Machine Learning)

Open-source by Iterative (now lakeFS); integrates with GitHub Actions and GitLab CI:
- Generates reports on every PR with metrics, plots, hyperparameter changes
- Auto-allocates cloud GPUs via `cml runner` on AWS, Azure, GCP, or Kubernetes
- Codifies data and models with DVC
- **Pattern**: PR triggers training → CML posts evaluation report → human review → merge triggers deployment

### A/B Testing Models in Production

Deploy new model to subset of traffic alongside champion model:
- Statistical significance testing on business metrics before full rollout
- Gradual traffic shifting to best-performing model based on live metrics
- **Tools**: Seldon Core (built-in A/B), SageMaker (production variant routing), Istio (traffic splitting)

### Automated Retraining Pipeline

```
1. Drift Detection → Data drift or performance degradation detected
2. Data Validation → Verify new training data quality (Great Expectations)
3. Automated Training → Retrain with new data, track in MLflow/W&B
4. Evaluation Gate → Compare against champion model on holdout set
5. Shadow Deployment → Run new model alongside champion, compare outputs
6. Canary Rollout → Route small percentage of traffic to new model
7. Full Promotion → Replace champion if canary metrics are good
```

**Trigger strategies:**
- **Performance threshold**: Accuracy/F1 drops below threshold
- **Data drift threshold**: PSI or KS test exceeds threshold
- **Schedule-based**: Daily/weekly retraining regardless of drift
- **Online learning**: Continuous retraining with sliding time windows

---

## 5. Model Monitoring & Drift Detection

### Types of Drift

| Type | What Changes | Detection Methods | Example |
|------|-------------|-------------------|---------|
| **Data drift** | Input feature distributions | PSI, KS test, Wasserstein distance, JS/KL divergence | User demographics shift |
| **Concept drift** | Input → output relationship | DDM, EDDM, ADWIN (monitor error rate) | Fraud patterns evolve |
| **Prediction drift** | Model output distribution | Distribution tests on predictions | Model becomes over/under-confident |

**Key insight**: A model can drift without obvious performance loss (benign drift), and performance can drop without obvious drift metrics (silent concept drift or pipeline bug). Monitor multiple signals.

### Monitoring Tools

| Tool | Type | Key Strength | Best For |
|------|------|-------------|----------|
| **Evidently AI** | Open-source | 100+ metrics, 20+ drift methods, LLM tracing, PII detection | Most comprehensive open-source option |
| **NannyML** | Open-source | Performance estimation WITHOUT ground truth | When labels are delayed (weeks/months) |
| **WhyLabs** | Open-source (Apache 2.0) | Privacy-preserving, real-time monitoring | Enterprise with privacy requirements |
| **Arize** | Commercial | Full observability platform, SHAP-based monitoring | Enterprise with budget |
| **Fiddler** | Commercial | Explainability-first monitoring | Regulated industries |

### Drift Detection Methods

**Statistical tests:**
- **PSI (Population Stability Index)**: < 0.1 no drift, 0.1-0.25 moderate, > 0.25 significant
- **KS test**: Non-parametric, good for continuous features
- **Chi-square**: Categorical features
- **Wasserstein distance**: Measures distribution shift magnitude

**Windowing strategies:**
- **Fixed reference**: Compare against training distribution (simple, clear baseline)
- **Sliding window**: Compare recent window against previous window (detects gradual drift)
- **Expanding window**: Growing reference (averages out noise but can miss drift)

### Alerting Best Practices

Layered monitoring signals (from fastest to most reliable):
1. **Data quality**: Missing values, schema violations, out-of-range values
2. **Feature drift**: Distribution shifts in input features
3. **Prediction distribution**: Shifts in model output patterns
4. **Confidence calibration**: Are predicted probabilities still well-calibrated?
5. **Business KPIs**: Conversion rate, revenue, user satisfaction
6. **Periodic human review**: Spot-check predictions on a schedule

**Alert hygiene:**
- Use warning vs critical thresholds
- Require persistence across multiple time windows before alerting
- Prioritize high-importance features and business-critical data slices
- Tie every alert to a runbook action

---

## 6. Infrastructure & Compute

### GPU Orchestration

**NVIDIA Run:ai** (now NVIDIA-owned):
- Kubernetes-native AI orchestration with fractional GPU allocation
- Dynamic scheduling by priority, queue, and availability
- Production deployments achieve 70-80% GPU utilization (vs 20-30% baseline)
- 50-70% infrastructure cost reduction

**Kubernetes DRA (Dynamic Resource Allocation):**
- NVIDIA donated DRA driver to CNCF at KubeCon Europe 2026
- Fundamental change to K8s GPU scheduling for platform engineers
- KAI Scheduler + Grove: New K8s GPU orchestration components

### Cloud ML Platform Comparison

| Dimension | AWS SageMaker | Google Vertex AI | Azure ML |
|-----------|---------------|-----------------|----------|
| **Strength** | Flexibility, scale, ecosystem | Automation, simplicity, TPUs | Governance, compliance |
| **2026 update** | Unified Studio | Gemini + BigQuery integration | AutoML + visual Designer |
| **Savings** | 60-70% via Savings Plans + Spot | Faster auto-scaling | Similar to SageMaker |
| **Best for** | AWS-native orgs | GCP users, TPU workloads | Microsoft shops |

### Cost Optimization

**Spot/preemptible instances:**
- AWS Spot GPU prices 70-91% below on-demand (p5.48xlarge: $98.32 vs $19.66 Spot = 80% savings)
- Google Preemptible: fixed 60-80% discount, 24hr max runtime
- AWS cut H100 on-demand prices 44% in June 2025 — gap is narrowing

**Budget cloud providers:**
- Hyperbolic: H100 at $1.49/hr, H200 at $2.15/hr
- CoreWeave: H100 at $2.23/hr
- Lambda: $2.49-$3.99/hr

**Critical practices for spot instances:**
- Checkpoint every 500-1000 steps to durable storage (S3, GCS)
- Diversify across 10-15 instance types
- Handle termination notices (AWS: 2 min, GCP: 30 sec)
- Target >70% GPU utilization
- Use BF16 mixed precision (2-4x throughput, ~10 lines of code)
- Use Flash Attention (2-4x faster, 5-20x less memory for long sequences)

---

## 7. Data Management for ML

### Data Labeling Platforms

| Platform | Type | Best For |
|----------|------|----------|
| **Label Studio** | Open-source | Budget-friendly, self-hosted, maximum flexibility |
| **Labelbox** | Enterprise | Developer-friendly APIs, Model-Assisted Labeling |
| **Scale AI** | Full-stack service | Large-scale, high-stakes (autonomous vehicles, defense) |
| **CVAT** | Open-source | Computer vision and video annotation |

**Scale AI "AutoPilot"**: LLM pre-labeling + human review — reduces labeling time by 50-80%.

### Data Quality

| Tool | Type | Key Feature |
|------|------|-------------|
| **Great Expectations (GX Core)** | Open-source | Expressive Python-based expectations, CI integration |
| **Soda Core** | Open-source | Data quality checks as code |
| **Monte Carlo** | Commercial | End-to-end data reliability, anomaly detection, root-cause analysis |
| **Bigeye** | Commercial | Rule-based + ML-driven checks for Snowflake/BigQuery |

### Dataset Versioning

| Tool | Approach | Best For |
|------|----------|----------|
| **lakeFS** | Git-like branching for data lakes | Version raw data, feature sets, training datasets; instant rollback |
| **DVC** | Git-based metafiles pointing to remote storage | Git-native teams, code + data versioning |
| **HuggingFace Hub** | Git LFS based | Open-source dataset distribution |

**Best practice**: Pair transformation tools with data versioning (lakeFS branches), validate outputs before promoting to production.

### Synthetic Data Generation

| Tool | Type | Best For |
|------|------|----------|
| **Gretel** | Developer-focused | API-first, structured + unstructured data |
| **MOSTLY AI** | Platform | Privacy-safe synthetic from production data |
| **YData Fabric** | Platform | Automated profiling + generation, no-code + SDK |
| **SDV** | Open-source Python | CTGAN, CopulaGAN for tabular/relational/time-series |

Gartner estimates 3 out of 4 businesses will use generative AI for synthetic customer data by 2026.

---

## 8. Decision Frameworks

### Model Serving Selection

| Scenario | Recommended Tool |
|----------|-----------------|
| LLM serving (general) | vLLM |
| LLM with prefix-heavy workloads (RAG, multi-turn) | SGLang |
| Max throughput on NVIDIA, latency-critical | TensorRT-LLM + Triton |
| Datacenter-scale distributed LLM inference | NVIDIA Dynamo 1.0 |
| Quick NVIDIA model deployment | NVIDIA NIM |
| PyTorch traditional ML/DL | TorchServe |
| TensorFlow models | TF Serving |
| Multi-framework composition, startup speed | BentoML |
| Unified ML platform (train + serve) | Ray Serve |
| Kubernetes enterprise, advanced rollouts | Seldon Core or KServe |
| Low-traffic / pay-per-use | SageMaker Serverless or Vertex AI |

### Pipeline Orchestration Selection

| Scenario | Recommended Tool |
|----------|-----------------|
| General-purpose, large ecosystem | Apache Airflow 3.x |
| Kubernetes-native end-to-end ML | Kubeflow Pipelines |
| Dynamic Python workflows, event-driven | Prefect 3 |
| Asset-centric, strong typing, dev experience | Dagster |
| Multi-tool meta-orchestration, no lock-in | ZenML |
| Python simplicity, AWS-native | Metaflow |

### MLOps Maturity Levels

| Level | Characteristics | Key Tools |
|-------|----------------|-----------|
| **0 — Manual** | Jupyter notebooks, manual deployment, no versioning | None (this is the problem) |
| **1 — Automated Training** | Scripted training, basic experiment tracking | MLflow, W&B, DVC |
| **2 — Automated Pipeline** | End-to-end pipeline, model registry, basic monitoring | + Airflow/Prefect/Dagster, model registry |
| **3 — Continuous Training** | Drift detection triggers retraining, A/B testing | + Evidently, automated retraining, CI/CD for ML |
| **4 — Full Automation** | Self-managing pipelines, auto-optimization, governance | + Platform team, cost optimization, compliance |

**Most organizations are at Level 1-2.** Don't jump to Level 4 prematurely — each level builds on the previous one. Get Level 2 solid before investing in continuous training.
