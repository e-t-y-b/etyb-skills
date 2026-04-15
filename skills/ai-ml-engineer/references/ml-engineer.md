# ML Engineering — Deep Reference

**Always use `WebSearch` to verify version numbers, tooling, and best practices. The ML ecosystem evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [ML Frameworks](#1-ml-frameworks)
2. [Feature Engineering](#2-feature-engineering)
3. [Model Training](#3-model-training)
4. [Distributed Training](#4-distributed-training)
5. [Experiment Tracking](#5-experiment-tracking)
6. [Model Evaluation](#6-model-evaluation)
7. [AutoML & Hyperparameter Tuning](#7-automl--hyperparameter-tuning)
8. [Model Optimization](#8-model-optimization)
9. [Model Interpretability & Explainability](#9-model-interpretability--explainability)
10. [Decision Frameworks](#10-decision-frameworks)

---

## 1. ML Frameworks

### PyTorch (v2.11 — Current Standard)

PyTorch dominates ~85% of deep learning research and has reached ~55% production share. The 2.x era brought compiler-first optimization.

**Key features in PyTorch 2.x:**

| Feature | Status | What It Does |
|---------|--------|-------------|
| `torch.compile` | Production-ready | JIT-compiles models via TorchInductor, near 100% GPU utilization. Float16 on x86 CPUs now beta. |
| FSDP2 | Stable (replaces FSDP1) | DTensor-based per-parameter sharding, deterministic GPU memory, best torch.compile integration |
| Flex Attention | Stable | Generates fused FlashAttention kernels via torch.compile, eliminates extra memory allocation |
| Compiled Autograd | Beta | Captures entire backward pass for training optimization |
| torch.export | Stable | Export models to a standardized IR for deployment |

**When to use PyTorch:**
- Default choice for any new deep learning project
- Best ecosystem (HuggingFace, Lightning, torchvision, torchaudio)
- Research → production pipeline is smoothest
- torch.compile eliminates the "PyTorch is slower in production" argument

### JAX (v0.9.2)

Google's functional ML framework. Minimum Python 3.11. Ships Python 3.14 wheels. Built with CUDA 12.9.

**When to use JAX over PyTorch:**
- Research requiring functional transformations (`vmap`, `pmap`, `jit`)
- TPU-first workloads (JAX is native to TPUs)
- Large-scale parallelism where JAX's sharding model is cleaner
- Robotics and scientific computing
- Google DeepMind research workflows

**When to stay with PyTorch:**
- Ecosystem gravity matters (most libraries, tutorials, hiring)
- Production systems needing mature MLOps integration
- Team already knows PyTorch (switching cost rarely justified)
- HuggingFace-centric workflows

### TensorFlow (v2.21)

Still commands ~37% market share with 25,000+ companies. Not dead, but research has moved to PyTorch.

**Where TensorFlow still wins:**
- **Mobile/edge**: TensorFlow Lite remains the gold standard (Google Photos, Snapchat depend on it)
- **Enterprise deployment**: Mature serving infrastructure (TFServing)
- **Existing codebases**: Don't rewrite working TF systems for the sake of it
- **Keras 3.14**: Now backend-agnostic — runs on TF, PyTorch, JAX, or OpenVINO

**Practical pattern (2026):** ~40% of teams prototype in PyTorch and deploy via TensorFlow/TFLite for mobile/edge.

### scikit-learn (v1.8)

The workhorse of classical ML. Still the right choice for tabular data, preprocessing, and model evaluation.

**Key 1.8 features:**
- **Array API support**: GPU computation via PyTorch and CuPy arrays directly
- **Free-threaded CPython**: Python 3.11-3.14 removes GIL dependency
- **Temperature scaling**: `CalibratedClassifierCV(method="temperature")` for probability calibration
- **Performance**: Massive fit-time reduction for L1-penalty estimators (ElasticNet, Lasso)

**When to use scikit-learn:**
- Tabular data with well-defined features
- Classical ML algorithms (random forests, SVMs, linear models, clustering)
- Preprocessing pipelines (StandardScaler, OneHotEncoder, Pipeline)
- Model evaluation utilities (cross_val_score, GridSearchCV)
- Prototyping before graduating to deep learning

### Gradient Boosting Libraries

| Library | Version | Key Strength | Best For |
|---------|---------|-------------|----------|
| **XGBoost** | 3.2.0 | Regularization, broadest ecosystem, Kaggle-proven | General tabular ML, widest tool integration |
| **LightGBM** | 4.6.0 | Histogram-based, leaf-wise, fastest on large numeric data | Large datasets with numeric features, speed-critical |
| **CatBoost** | 1.2.10 | Native categorical features, ordered boosting | Categorical-heavy data, fewer preprocessing steps |

**Selection guide:**
- **Default**: XGBoost (best documentation, largest community)
- **Categorical-heavy data**: CatBoost (handles categoricals natively, no one-hot encoding)
- **Speed on large numeric data**: LightGBM (fastest iteration time)
- **Kaggle/competition**: Try all three, ensemble the best

**Tabular data truth (2026):** Gradient boosting (XGBoost/LightGBM/CatBoost) still beats deep learning on most tabular tasks. Deep learning wins on tabular data only when: very large datasets (millions+), multi-modal inputs (tabular + text/images), or self-supervised pretraining is applicable.

---

## 2. Feature Engineering

### Feature Stores

Feature stores solve the "training-serving skew" problem — ensuring features computed during training match features served at inference time.

| Store | Type | Best For | Key Strength |
|-------|------|----------|-------------|
| **Feast** (v0.58) | Open-source | Max flexibility, avoid vendor lock-in | Modular, Java gRPC + Redis for low-latency serving |
| **Tecton** | Managed | Business-critical real-time ML | Built by Uber Michelangelo team, automated governance |
| **Hopsworks** | Platform | Regulated industries (healthcare, finance) | End-to-end feature + model management, compliance |

**When you need a feature store:**
- Multiple models share the same features
- Real-time features (fraud detection, recommendations) that must match training-time features
- Feature computation is expensive and should be shared
- Governance and lineage tracking are required

**When you don't:**
- Single model, batch inference only
- Small team with simple feature pipelines
- Features are computed inline at training and serving time

### Feature Engineering Patterns

**Numerical features:**
- Log transforms for skewed distributions
- Standardization (zero mean, unit variance) for linear models and neural networks
- Min-max scaling when bounded range is needed
- Binning/bucketing for non-linear relationships in linear models

**Categorical features:**
- Target encoding (with proper cross-validation to prevent leakage)
- Frequency encoding for high-cardinality categoricals
- Embedding layers in deep learning (better than one-hot for high cardinality)
- CatBoost handles categoricals natively — no preprocessing needed

**Time-based features:**
- Hour of day, day of week, month, quarter (cyclical encoding)
- Time since last event, rolling aggregations
- Lag features (previous N time steps)
- Trend and seasonality decomposition

**Text features (non-LLM):**
- TF-IDF for classical ML baselines
- Sentence embeddings (sentence-transformers) for richer representations
- Named entity counts, sentiment scores as features

**Feature pipelines:**
- **Batch**: Polars/pandas for feature computation, scheduled via Airflow/Prefect
- **Real-time**: Apache Kafka for streaming ingestion, Apache Flink for stateful computation
- **Incremental processing**: Process only new/updated data rather than full reprocessing

### Feature Selection

**Filter methods** (fast, pre-model):
- Correlation analysis (drop highly correlated features)
- Mutual information
- Chi-squared test (categorical → categorical)

**Wrapper methods** (model-dependent):
- Recursive Feature Elimination (RFE)
- Forward/backward stepwise selection

**Embedded methods** (built into training):
- L1 regularization (Lasso) drives coefficients to zero
- Feature importance from tree-based models
- SHAP values for principled feature importance

**Best practice**: Start with all features, use tree-based feature importance to rank, then prune and retrain. Monitor feature drift in production.

---

## 3. Model Training

### Training Best Practices

**Data splitting:**
- Train/validation/test split: 70/15/15 or 80/10/10 for large datasets
- **Never** use the test set for hyperparameter tuning or model selection
- Stratified splits for imbalanced classification
- Time-based splits for temporal data (no random shuffling)
- Group-based splits when data has group structure (patients, users)

**Avoiding data leakage:**
- Fit preprocessing (scaling, encoding) on training set only, transform val/test
- No future information in features for time series
- Cross-validation folds must respect group/time boundaries
- Feature selection must happen inside cross-validation, not before

**Handling imbalanced data:**
| Technique | When to Use | Notes |
|-----------|-------------|-------|
| Class weights | First approach | `class_weight='balanced'` in scikit-learn |
| SMOTE | Moderate imbalance, tabular data | Synthetic oversampling, use with care |
| Threshold tuning | When precision/recall tradeoff matters | Adjust decision threshold, not sampling |
| Focal loss | Deep learning, severe imbalance | Down-weights easy examples |
| Stratified sampling | Always | Ensure minority class in all folds |

**Learning rate scheduling:**
- Cosine annealing with warm restarts (most common in 2026)
- Linear warmup followed by cosine decay
- OneCycleLR for super-convergence
- ReduceLROnPlateau as fallback (reactive, not proactive)

### Mixed-Precision Training

Mixed precision is now standard practice — there's rarely a reason not to use it.

| Format | Hardware | Use Case | Notes |
|--------|----------|----------|-------|
| **BF16** | Ampere+ (A100, RTX 30/40) | Default for training | Wider dynamic range than FP16, no GradScaler needed |
| **FP16** | Older GPUs | Training with GradScaler | Needs loss scaling to prevent underflow |
| **FP8** | Hopper (H100/H200) | Advanced training | Requires torch.compile for speedups. Keep first/last layers in FP32/BF16 |
| **FP4** | Blackwell (B200) | Emerging | ~1.32x speed over FP8, native tensor core support |

**PyTorch mixed precision:**
```python
# BF16 (recommended on Ampere+)
with torch.cuda.amp.autocast(dtype=torch.bfloat16):
    output = model(input)
    loss = criterion(output, target)
loss.backward()
optimizer.step()
```

**Rules of thumb:**
- BF16 is the default on capable hardware — just use it
- Heavy ops (matmul, conv) run in lower precision; sensitive ops (softmax, reductions) stay FP32
- FP8 on H100/H200: 1.5-2x training speedup with minimal accuracy loss
- Always validate that mixed precision doesn't degrade your specific model's quality

### GPU Landscape (April 2026)

| GPU | Memory | Approx. Cloud Cost | Best For |
|-----|--------|-------------------|----------|
| **H100** | 80GB HBM3 | $1.49-$6.98/hr | Standard training and inference |
| **H200** | 141GB HBM3e | $1.50-$13.78/hr | Memory-bound large models |
| **B200** | 192GB HBM3e | $2.25-$16/hr | 2.25x perf over H100, FP4 support |
| **A100** | 40/80GB HBM2e | $0.70-$3.50/hr | Budget training, widely available |

**Cloud pricing reality:**
- Neo-clouds (CoreWeave, Lambda, Vast.ai) deliver 40-85% lower costs than hyperscalers
- Spot/preemptible instances save 50-70% but require checkpoint management
- B200 supply remains constrained through mid-2026

---

## 4. Distributed Training

### Framework Comparison

| Framework | Best For | Key Features |
|-----------|----------|-------------|
| **PyTorch FSDP2** | Default for PyTorch teams, fine-tuning up to 70B on 4-8 GPUs | DTensor-based per-parameter sharding, deterministic GPU memory, best torch.compile integration |
| **DeepSpeed** (v0.18.9) | 70B+ models, NVME offloading, scaling across many nodes | ZeRO Stages 1/2/3, CPU/NVME offload, MoE support, Ulysses sequence parallelism |
| **Megatron-LM** | Pre-training at trillion-parameter scale | TP + PP + DP + EP + CP parallelism, FP8/FP4 support, Dynamic Context Parallelism |

### Parallelism Strategies

| Strategy | What It Splits | When to Use |
|----------|---------------|-------------|
| **Data Parallelism (DP)** | Data across GPUs, model replicated | Model fits on one GPU, want faster training |
| **Fully Sharded DP (FSDP)** | Model parameters + optimizer state across GPUs | Model doesn't fit on one GPU (7B-70B range) |
| **Tensor Parallelism (TP)** | Individual layers across GPUs | Very large layers, low-latency requirement |
| **Pipeline Parallelism (PP)** | Model layers across GPUs | Very deep models, inter-node communication |
| **Expert Parallelism (EP)** | MoE experts across GPUs | Mixture of Experts models |
| **Context Parallelism (CP)** | Sequence length across GPUs | Very long sequences (128K+) |

**Practical guidance:**
- **Fine-tuning 7-13B**: FSDP2 on 2-4 GPUs is sufficient
- **Fine-tuning 70B**: FSDP2 on 4-8 GPUs with CPU offloading, or DeepSpeed ZeRO-3
- **Pre-training 70B+**: DeepSpeed or Megatron-LM with multi-node setup
- **Pre-training 100B+**: Megatron-LM with full parallelism stack (TP+PP+DP+EP+CP)

### FSDP2 (Recommended Default)

FSDP2 replaces FSDP1 (now deprecated) with a cleaner design:
- Per-parameter dim-0 sharding (not flat parameters)
- Lower and deterministic GPU memory usage
- Communication-computation overlap via TorchInductor
- Best integration with torch.compile

### DeepSpeed ZeRO Stages

| Stage | What It Shards | Memory Savings | Communication |
|-------|---------------|----------------|--------------|
| **ZeRO-1** | Optimizer states | ~4x | Low overhead |
| **ZeRO-2** | + Gradients | ~8x | Moderate overhead |
| **ZeRO-3** | + Parameters | ~Nx (N = GPU count) | Higher overhead |
| **+ CPU Offload** | Offload to CPU/NVME | 8-12x beyond GPU memory | I/O bound |

---

## 5. Experiment Tracking

### Tool Comparison

| Tool | Version | Best For | Key Feature |
|------|---------|----------|-------------|
| **MLflow** | 3.10 | Open-source teams, GenAI tracing | AI Gateway analytics, multi-turn eval, comprehensive lineage tracking |
| **W&B** | 0.77 | Teams wanting best visualization and collaboration | Weave for AI agents, iOS app, LEET terminal UI, NVIDIA NeMo integration |
| **Comet** | Active | Quick integration (2 lines) | Opik LLM tracing, real-time logging |
| **DVCLive** | 3.0 | Git-native teams, minimal overhead | Plain text/JSON logs, no server needed |

**Note:** Neptune was acquired by OpenAI and shut down SaaS in March 2026. Migrate to MLflow or W&B.

**MLflow 3 highlights:**
- `mlflow.search_logged_models()` with SQL-like syntax
- Multi-turn conversation evaluation for GenAI
- Comprehensive lineage tracking: models ↔ runs ↔ traces ↔ prompts ↔ metrics
- AI Gateway usage analytics

**Selection guide:**
- **Default open-source**: MLflow (broadest adoption, Databricks backing)
- **Best UX and collaboration**: W&B (paid but worth it for larger teams)
- **Minimal setup**: DVCLive (git-native, works offline, zero infrastructure)
- **Quick start**: Comet (2-line integration, generous free tier)

### Experiment Tracking Best Practices

- Log everything: hyperparameters, metrics, model artifacts, data versions, environment info
- Use meaningful run names (not auto-generated UUIDs)
- Tag experiments by project, hypothesis, and data version
- Compare runs visually before drawing conclusions
- Register promising models in a model registry for production promotion
- Track compute cost alongside model metrics

---

## 6. Model Evaluation

### Metrics by Task Type

**Classification:**
| Metric | When to Use | Watch Out For |
|--------|-------------|---------------|
| Accuracy | Balanced classes only | Misleading for imbalanced data |
| Precision | When false positives are costly (spam filter) | Ignores false negatives |
| Recall | When false negatives are costly (medical diagnosis) | Ignores false positives |
| F1-Score | Balance precision and recall | Assumes equal cost of FP and FN |
| AUC-ROC | Threshold-independent comparison | Can be misleading for severe imbalance |
| AUC-PR | Imbalanced datasets | Better than AUC-ROC for imbalanced data |
| Log-Loss | Probabilistic predictions | Penalizes confident wrong predictions heavily |

**Regression:**
| Metric | When to Use | Notes |
|--------|-------------|-------|
| RMSE | Default, penalizes large errors | Same units as target |
| MAE | Robust to outliers | Median-like behavior |
| MAPE | Percentage-based comparison | Fails for near-zero values |
| R-squared | Model vs baseline comparison | Can be negative for bad models |

**Ranking:**
- **NDCG**: Position-weighted, graded relevance
- **MAP**: Binary relevance, position-weighted
- **MRR**: First relevant result matters most
- **Precision@k / Recall@k**: Top-k focused

### Cross-Validation Strategies

| Strategy | Use Case | Key Property |
|----------|----------|-------------|
| **StratifiedKFold** | Classification | Preserves class distribution |
| **KFold** | Regression | Standard k-fold |
| **TimeSeriesSplit** | Temporal data | Respects chronological order |
| **GroupKFold** | Grouped data (patients, users) | No group leakage across folds |
| **RepeatedStratifiedKFold** | Robust estimates | Multiple random splits |

**Practical guidance:**
- k=5 for quick iteration, k=10 for final evaluation
- Always use stratified for classification
- Never shuffle time series data
- Report mean ± std across folds, not just mean

---

## 7. AutoML & Hyperparameter Tuning

### AutoML Tools

| Tool | Maintainer | Best For | Notes |
|------|-----------|----------|-------|
| **AutoGluon** | AWS | Highest accuracy, multi-modal | Multi-layered ensembling, dominates benchmarks |
| **FLAML** | Microsoft | Compute-efficient, budget-aware | Lightweight, fast iteration, good for resource-constrained |
| **Auto-sklearn** | Uni Freiburg | **Abandoned** (last release 2023) | Do not use for new projects |

**Selection guide:**
- **Maximize accuracy**: AutoGluon (try it first for any tabular task)
- **Minimize compute**: FLAML (10-100x less compute than AutoGluon, still competitive)
- **Deep learning**: Neither — use manual architecture design or HuggingFace AutoTrain

### Hyperparameter Tuning

| Tool | Type | Best For |
|------|------|----------|
| **Optuna** | Bayesian optimization | Most flexible, Python-native, pruning support |
| **Ray Tune** | Distributed tuning | Large search spaces, distributed across GPUs |
| **scikit-learn GridSearchCV** | Exhaustive search | Small search spaces, quick experiments |
| **W&B Sweeps** | Bayesian + grid + random | Integrated with W&B tracking |

**Optuna best practices:**
- Use `TPESampler` (default) for most problems
- Enable pruning with `MedianPruner` or `HyperbandPruner` to kill bad trials early
- Define search space with `suggest_float`, `suggest_int`, `suggest_categorical`
- Use `optuna.visualization` for parameter importance analysis
- Log Optuna studies to MLflow/W&B for full traceability

**What to tune (priority order):**
1. Learning rate (most impactful hyperparameter)
2. Regularization (weight decay, dropout)
3. Architecture (layers, hidden size, heads)
4. Batch size (affects generalization and training speed)
5. Data augmentation parameters

---

## 8. Model Optimization

### Quantization

| Method | Precision | Memory Savings | Accuracy Impact | Best For |
|--------|-----------|---------------|----------------|----------|
| **INT8 PTQ** | 8-bit integer | 4x | Minimal (<1%) | CPU deployment, broad compatibility |
| **FP8** | 8-bit float | 4x | Minimal | H100/H200 GPUs |
| **INT4/NF4** | 4-bit | 8x | Small (1-3%) | LLM inference, memory-constrained |
| **FP4** | 4-bit float | 8x | Small | B200 (Blackwell) GPUs |

**Quantization approaches:**
- **PTQ (Post-Training Quantization)**: Quantize after training. Start here — it's fast and often sufficient
- **QAT (Quantization-Aware Training)**: Simulate quantization during training. Use when PTQ degrades accuracy too much
- **AWQ (Activation-Aware Weight)**: Best for INT4 LLM quantization in production
- **GPTQ**: GPU-friendly INT4 quantization for LLMs

**Tools:**
- NVIDIA TensorRT Model Optimizer (ModelOpt) for TensorRT deployment
- bitsandbytes for NF4 in HuggingFace ecosystem
- LLM Compressor for vLLM deployment
- PyTorch native quantization API

### Pruning

**Approaches:**
- **Depth pruning**: Drop entire layers. Use perplexity or Block Importance scoring
- **Width pruning**: Remove neurons, attention heads, or embedding channels. Use activation-based importance
- **Unstructured**: Zero out individual weights. Highest compression but needs sparse hardware support
- **Structured**: Remove entire filters/heads. Works on standard hardware

**Best practice pipeline:** Prune → Quantize → Distill (order matters for best accuracy-size-latency tradeoff)

### Knowledge Distillation

Train a smaller "student" model to mimic a larger "teacher" model:
- **Logits-based**: Student matches teacher's output distribution. Using logits loss alone outperforms weighted combinations
- **Feature-based**: Student matches teacher's intermediate representations
- **Savings**: Distilled models require up to 40x fewer training tokens vs training from scratch

### ONNX Export

ONNX Runtime (v1.23.2) provides cross-platform inference with up to 9x speedup:
- Auto EP (Execution Provider) selection for optimal hardware utilization
- NVIDIA RTX EP via TensorRT
- MatMulNBits for 8-bit weight quantization
- Level 3 graph optimizations (constant folding, node fusion)

**Export workflow:**
1. Train in PyTorch
2. Export via `torch.onnx.export()` or `torch.export` → ONNX
3. Optimize with ONNX Runtime graph optimizations
4. Deploy with ONNX Runtime (supports CPU, GPU, mobile, edge)

### Inference Engines

| Engine | Target | Key Strength |
|--------|--------|-------------|
| **TensorRT** (10.x) | NVIDIA GPUs | Fastest GPU inference |
| **TensorRT-LLM** (1.2.0) | NVIDIA GPUs | LLM-optimized, DeepSeek/Llava support |
| **OpenVINO** (2026.1) | Intel CPUs/GPUs/NPUs | llama.cpp backend, broadest Intel hardware |
| **ONNX Runtime** (1.23.2) | Cross-platform | Widest hardware support |
| **Core ML** | Apple Silicon | Best for iOS/macOS deployment |

---

## 9. Model Interpretability & Explainability

### Tool Comparison

| Tool | Version | Approach | Best For |
|------|---------|----------|----------|
| **SHAP** | 0.51.0 | Shapley values (game theory) | Global + local explanations, theoretically consistent, thorough analysis |
| **LIME** | Active | Local surrogate models | Quick individual predictions, intuitive explanations |
| **Captum** | Active | Gradient-based attribution | PyTorch models, deep learning, Integrated Gradients |

**When to use which:**
- **SHAP**: Default choice. Consistent, theoretically grounded. Use for feature importance (global) and individual prediction explanations (local)
- **LIME**: Quick, intuitive explanations for non-technical stakeholders. Faster but less consistent than SHAP
- **Captum**: PyTorch-specific. Use for deep learning models where gradient-based methods (Integrated Gradients, DeepLIFT) provide better insight into learned representations

### Bias and Fairness

| Tool | Maintainer | Key Features |
|------|-----------|-------------|
| **Fairlearn** | Microsoft | Python-native, scikit-learn conventions, mitigation algorithms |
| **AI Fairness 360** | IBM | 70+ metrics, Python + R, comprehensive |
| **What-If Tool** | Google | Visual exploration, no code needed |

**EU AI Act context (August 2026 deadline):** Fairness evaluation is becoming a legal obligation for high-risk AI systems. Document fairness metrics, mitigation steps, and ongoing monitoring in model cards.

**Key fairness metrics:**
- Demographic parity: Equal positive prediction rates across groups
- Equalized odds: Equal TPR and FPR across groups
- Calibration: Predicted probabilities match actual outcomes for all groups

---

## 10. Decision Frameworks

### Framework Selection

| Decision | Default | Switch When |
|----------|---------|-------------|
| ML framework | PyTorch 2.11 | TPU workloads or functional style needed (JAX), mobile/edge (TensorFlow Lite) |
| Tabular ML | XGBoost | Categorical-heavy (CatBoost), speed-critical (LightGBM) |
| Experiment tracking | MLflow | Best UX needed (W&B), git-native minimal (DVCLive) |
| Distributed training | FSDP2 | 70B+ with offloading (DeepSpeed), trillion-scale pre-training (Megatron-LM) |
| Hyperparameter tuning | Optuna | Distributed (Ray Tune), simple (GridSearchCV) |
| AutoML | AutoGluon | Compute-constrained (FLAML) |
| Quantization | INT8 PTQ | H100/H200 (FP8), memory-constrained (INT4/NF4) |
| Interpretability | SHAP | Quick explanations (LIME), PyTorch deep learning (Captum) |
| Feature store | Feast | Enterprise/turnkey (Tecton), regulated (Hopsworks) |

### Classical ML vs Deep Learning

| Factor | Classical ML | Deep Learning |
|--------|-------------|---------------|
| **Data size** | Hundreds to low thousands | Tens of thousands+ |
| **Data type** | Structured/tabular | Unstructured (images, text, audio) |
| **Interpretability** | High (feature importance, coefficients) | Low (black box, needs SHAP/LIME) |
| **Training time** | Minutes to hours | Hours to days |
| **Inference latency** | Sub-millisecond | Milliseconds to seconds |
| **GPU required** | No | Usually yes |
| **When it wins** | Fraud detection, credit scoring, churn, pricing | CV, NLP, speech, recommendations at scale |

**The uncomfortable truth:** For most tabular data problems in production, a well-tuned XGBoost model with good features outperforms deep learning. Save deep learning for problems where it has a clear structural advantage (images, sequences, multi-modal).
