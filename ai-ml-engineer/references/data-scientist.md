# Data Science — Deep Reference

**Always use `WebSearch` to verify version numbers, tooling, and best practices. Data science tooling evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Statistical Analysis](#1-statistical-analysis)
2. [Experimentation & A/B Testing](#2-experimentation--ab-testing)
3. [Data Exploration & Visualization](#3-data-exploration--visualization)
4. [Feature Engineering & Selection](#4-feature-engineering--selection)
5. [Time Series Analysis](#5-time-series-analysis)
6. [Natural Language Processing (Non-LLM)](#6-natural-language-processing-non-llm)
7. [Recommender Systems](#7-recommender-systems)
8. [Data Processing at Scale](#8-data-processing-at-scale)
9. [Decision Frameworks](#9-decision-frameworks)

---

## 1. Statistical Analysis

### Core Libraries

| Library | Version | Best For |
|---------|---------|----------|
| **SciPy** | 1.17.1 | Optimization, linear algebra, integration, signal processing, statistical tests |
| **statsmodels** | 0.14.6 | GLMs, ARIMA, hypothesis tests, econometrics, R-style formula syntax |
| **scikit-learn** | 1.8.0 | ML pipelines, preprocessing, evaluation, feature importance |

**SciPy 1.17.1**: Requires Python 3.11-3.14. Native batching of N-dimensional array input, expanded Array API support, improved sparse array indexing.

**statsmodels 0.14.6**: GLMs, generalized linear models, random effects, GAMs, ARIMA, seasonal decomposition, hypothesis tests. R-style formula syntax (`y ~ x1 + x2`). Strong for econometrics and survey analysis.

### Bayesian Analysis

| Tool | Type | Key Strength |
|------|------|-------------|
| **PyMC** (5.28.1) | Probabilistic programming | MCMC (NUTS, Metropolis) + variational inference. Backends: C, JAX, Numba. Supports discrete variables |
| **CmdStanPy** | Stan interface | Gold standard for HMC. Compiled C++ speed. Best for constrained parameter spaces |
| **ArviZ** (0.23.4) | Posterior analysis | 30+ plotting functions, MCMC diagnostics (R-hat, ESS), model comparison (WAIC, LOO-CV) |

**When to use PyMC vs Stan:**
- **PyMC**: Python-native workflow, discrete variables, integration with JAX/NumPy ecosystem
- **Stan**: Maximum HMC performance, constrained parameter spaces, deep statistical community

**ArviZ** integrates with both — use it for all posterior visualization and diagnostics regardless of inference engine.

### Causal Inference

| Framework | Version | Focus | Key Feature |
|-----------|---------|-------|-------------|
| **DoWhy** | 0.14+ | End-to-end causal inference | Model DAGs → identify → estimate → refute (the refutation API is unique) |
| **EconML** | 0.16.0 | Heterogeneous treatment effects | DML, orthogonal forests, causal forests, DRIV |
| **CausalML** | 0.16.0 | Uplift modeling | T/S/X/R-learners, causal trees, causal forests |

**Production pattern:** Use DoWhy for the full causal pipeline (graph → identify → estimate → refute), plug in EconML estimators for heterogeneous effects, and use CausalML for uplift modeling in marketing/product contexts.

### Common Statistical Tests

| Test | Use Case | SciPy Function |
|------|----------|---------------|
| **t-test** (independent) | Compare means of two groups | `scipy.stats.ttest_ind` |
| **t-test** (paired) | Compare means of paired observations | `scipy.stats.ttest_rel` |
| **Chi-square** | Association between categorical variables | `scipy.stats.chi2_contingency` |
| **Mann-Whitney U** | Non-parametric mean comparison | `scipy.stats.mannwhitneyu` |
| **KS test** | Distribution comparison | `scipy.stats.ks_2samp` |
| **ANOVA** | Compare means of 3+ groups | `scipy.stats.f_oneway` |
| **Kruskal-Wallis** | Non-parametric ANOVA | `scipy.stats.kruskal` |

---

## 2. Experimentation & A/B Testing

### A/B Test Design

**Power analysis / sample size:**
- Use `statsmodels.stats.power.TTestIndPower` or `NormalIndPower`
- Inputs: baseline rate, MDE (minimum detectable effect), alpha (0.05), power (0.80)
- Rule of thumb: Smaller effects need exponentially more samples
- For Bayesian: dynamic stopping — use risk measures as stopping rules rather than fixed sample sizes

### Statistical Testing Approaches

| Approach | Framework | Advantage | Disadvantage |
|----------|-----------|-----------|-------------|
| **Frequentist** | scipy.stats | Well-understood, standard | Can't peek at results early |
| **Bayesian** | PyMC | No peeking problem, intuitive probabilities | Requires prior specification |
| **Sequential** | Always-valid p-values (SPRT) | Principled early stopping | More complex implementation |

**Bayesian A/B testing pattern:**
- Beta-Binomial model with Beta(1,1) prior
- Compute `P(variant_B > variant_A)` from posterior samples
- Decision rule: "probability of being best" threshold (e.g., >95%)
- No peeking problem — posterior updates continuously

**Multiple comparison corrections:**
- **Bonferroni**: Controls FWER (conservative)
- **Benjamini-Hochberg**: Controls FDR (less conservative, better for many tests)
- `statsmodels.stats.multitest.multipletests` implements both

### Experiment Platforms (2026)

| Platform | Status | Stats Engine | Key Strength |
|----------|--------|-------------|-------------|
| **Eppo** | Acquired by Datadog (~$220M, May 2025) | Fixed-sample, Sequential, Bayesian | Warehouse-native, CUPED/CUPED++ (65% faster experiments) |
| **Statsig** | Acquired by OpenAI ($1.1B, Sep 2025) | Frequentist, Bayesian | Unified flags + A/B + analytics + session replay |
| **GrowthBook** | Independent, open-source | Bayesian (default), Frequentist, Sequential | Self-hostable, warehouse-native, CUPED, SRM checks |
| **LaunchDarkly** | Independent | Frequentist | Best-in-class feature flagging, enterprise governance |

**Best open-source option**: GrowthBook — self-hostable, warehouse-native, Bayesian by default, CUPED support, SRM auto-detection.

### Multi-Armed Bandits

| Library | Key Feature |
|---------|-------------|
| **MABWiser** (2.7.4) | Parallelizable. Thompson Sampling, UCB1, LinUCB, Softmax, epsilon-greedy |
| **PyBandits** | Thompson Sampling for stochastic and contextual MABs |
| **contextualbandits** | LinUCB, epsilon-greedy, bootstrapped variants |

**When to use bandits vs A/B tests:**
- A/B test: Need precise treatment effect estimate, have enough traffic, one-shot decision
- Bandit: Continuous optimization, high opportunity cost of showing inferior variant, many variants

### Common Pitfalls

| Pitfall | What Goes Wrong | Mitigation |
|---------|----------------|-----------|
| **Peeking** | Looking at results early inflates false positives | Sequential testing or Bayesian methods |
| **Multiple comparisons** | Testing many metrics inflates Type I error | Bonferroni/FDR correction, or platforms with built-in adjustment |
| **Simpson's paradox** | Aggregated results reverse subgroup trends | Maintain consistent allocation; segment analysis |
| **SRM** | Unequal group sizes signal implementation bugs | Auto-detect with GrowthBook/Eppo |
| **Survivorship bias** | Only analyzing users who completed the experiment | Intent-to-treat analysis |
| **Novelty/primacy** | New features get temporary boost/resistance | Run experiments long enough (2-4 weeks) |

---

## 3. Data Exploration & Visualization

### Visualization Libraries

| Library | Version | Paradigm | Best For |
|---------|---------|----------|----------|
| **matplotlib** | 3.10.8 | Imperative | Publication-quality static plots, full control |
| **seaborn** | 0.13.2 | Declarative (on matplotlib) | Statistical visualizations, distribution plots |
| **Plotly** | 6.7.0 | Interactive | Interactive dashboards, 3D plots, web-ready |
| **Altair** | 6.0.0 | Declarative (Vega-Lite) | Concise grammar, interactive linked views |

**Selection guide:**
- **EDA and publications**: matplotlib + seaborn
- **Interactive dashboards**: Plotly
- **Rapid declarative exploration**: Altair
- All integrate with pandas/Polars DataFrames directly

### Dashboard & App Tools

| Tool | Version | Best For |
|------|---------|----------|
| **Streamlit** | 1.56.0 | Data dashboards, analytics apps. Free Community Cloud deployment |
| **Gradio** | 6.12.0 | ML model demos, HuggingFace ecosystem, non-text inputs (images, audio) |
| **Panel** (HoloViz) | Active | Complex multi-page dashboards, any plotting library. Steeper learning curve |

**Streamlit 1.56.0**: `on_change` for dynamic containers, widget binding to URL query params for bookmarkable state.

### Notebook Environments

| Environment | Best For | Key Tradeoff |
|-------------|----------|-------------|
| **Jupyter** (JupyterLab) | Default, universal | Hidden state, non-reproducible cell order, poor git diffs |
| **marimo** | Reproducibility-critical work | Reactive notebooks as pure `.py` files, auto-reruns dependent cells |
| **VS Code Notebooks** | Developers already in VS Code | Integrated debugging/git, not standalone |
| **Hex** | Team analytics with SQL-heavy workflows | Cloud-native, mixes SQL + Python |
| **Deepnote** | Real-time collaboration | Built-in data connectors (BigQuery, Snowflake) |

**marimo** is the rising star — solves Jupyter's hidden state and version control problems by storing notebooks as pure Python scripts with reactive cell dependencies.

---

## 4. Feature Engineering & Selection

### Feature Importance Methods

| Method | Type | Key Property |
|--------|------|-------------|
| **SHAP** (0.51.0) | Game-theoretic | Consistent, theoretically grounded. TreeExplainer (fast), KernelExplainer (model-agnostic) |
| **Permutation importance** | Model-agnostic | Loss-based: how much does performance degrade? `sklearn.inspection.permutation_importance` |
| **Tree-based importance** | Built-in | Fast but biased toward high-cardinality features |

### Automated Feature Engineering

**Featuretools** (Alteryx, open-source):
- Deep Feature Synthesis (DFS): automatically generates features from relational datasets
- Define EntitySets and relationships, then `ft.dfs()` generates features recursively
- Built-in feature selection: removes all-null and single-class features

**Featurewiz**: ML-based automatic feature selection using SULOV + recursive XGBoost.

### Feature Selection Techniques

| Category | Methods | When to Use |
|----------|---------|-------------|
| **Filter** (fast, pre-model) | Mutual information, correlation, variance threshold, chi-squared | Initial screening, large feature sets |
| **Wrapper** (model-dependent) | RFE, forward/backward selection | Moderate feature sets, need optimal subset |
| **Embedded** (built into training) | L1 (Lasso), tree importance, ElasticNet | During model training, automatic |

### Handling Data Quality Issues

**Missing data:**
- `SimpleImputer` (mean/median/mode), `KNNImputer`, `IterativeImputer` (MICE)
- Understand missingness mechanism (MCAR/MAR/MNAR) before choosing method
- Best practice: create "is_missing" indicator features alongside imputed values

**Outliers:**
- IQR method, Z-score, Isolation Forest (`sklearn.ensemble.IsolationForest`)
- Winsorizing: cap at percentiles rather than removing
- `sklearn.preprocessing.RobustScaler` for scaling robust to outliers

**Imbalanced datasets:**
- **imbalanced-learn** (0.14.1): SMOTE, ADASYN, Borderline-SMOTE, SMOTE-ENN
- SMOTE: synthetic minority samples via k-NN interpolation. Apply ONLY to training data
- Class weights: `class_weight='balanced'` in scikit-learn estimators
- Evaluation: use precision-recall AUC, F1, Matthews Correlation Coefficient — not accuracy

---

## 5. Time Series Analysis

### Classical Methods

| Method | Library | Best For |
|--------|---------|----------|
| **ARIMA/SARIMAX** | `statsmodels.tsa.arima` | Univariate, stationary or differenced series |
| **Prophet** | `prophet` (Meta) | Business time series with strong seasonality, holidays |
| **NeuralProphet** | `neuralprophet` | 55-92% better than Prophet on short-to-medium forecasts |
| **ETS** | `statsmodels.tsa.holtwinters` | Exponential smoothing with error/trend/seasonality |
| **Auto-ARIMA** | `pmdarima` | Automatic order selection for ARIMA |

### Foundation Models for Time Series (2026)

| Model | Provider | Key Strength |
|-------|----------|-------------|
| **Chronos-2** | Amazon | Most mature, SOTA zero-shot, 300+ forecasts/sec on single GPU, millions of HF downloads |
| **TimesFM** | Google | Battle-tested in Google production, balanced performance/efficiency |
| **Moirai** | Salesforce | Multi-variate foundation model |
| **TimeGPT** | Nixtla | API-based, trained on 100B+ data points, zero-shot across domains |

**When to use foundation models:** Zero-shot forecasting on new datasets without per-dataset training. Production-ready in 2026 — significantly reduces model development time.

### Forecasting Frameworks (Nixtla Ecosystem)

| Framework | Type | Best For |
|-----------|------|----------|
| **StatsForecast** | Statistical | Lightning-fast auto-ARIMA, ETS, CES, Theta. scikit-learn API |
| **MLForecast** | ML-based | Automated lag features, rolling stats, scales to clusters |
| **NeuralForecast** | Deep learning | N-BEATS, TFT, NHITS, PatchTST |
| **HierarchicalForecast** | Reconciliation | Hierarchical time series (e.g., region → country → store) |

### Anomaly Detection in Time Series

| Tool | Approach | Best For |
|------|----------|----------|
| **STL decomposition** | `statsmodels.tsa.seasonal.STL` + Z-score on residuals | First approach, simple and effective |
| **PyOD** | 30+ outlier detection algorithms | Complex patterns, multiple algorithms |
| **Isolation Forest** | Tree-based isolation | General-purpose, scalable |
| **ADTK** | Rule-based unsupervised | Simple, interpretable rules |
| **Ruptures** | Changepoint detection | Detecting regime changes |

**Production pattern:** Start with STL decomposition + Z-score on residuals. For complex patterns, use Isolation Forest or autoencoders. For changepoint detection, use Ruptures.

---

## 6. Natural Language Processing (Non-LLM)

### Core Libraries

| Library | Version | Best For |
|---------|---------|----------|
| **spaCy** | 3.8.13 | Industrial-strength NLP: NER, POS, dependency parsing, text classification. Cython-optimized |
| **NLTK** | Active | Educational/research, VADER sentiment, comprehensive toolkit |
| **TextBlob** | Active | Simple API wrapping NLTK for quick text processing |

**spaCy 3.8.13**: Pretrained pipelines for 25+ languages. `spacy-llm` package integrates LLMs for zero-shot tasks within spaCy pipelines.

### Classical NLP vs LLMs

| Task | Classical Approach | Use LLM When |
|------|-------------------|-------------|
| **NER** | spaCy pretrained pipelines | Novel entity types without training data, zero-shot |
| **Sentiment** | VADER (social media), fine-tuned DistilBERT | Sarcasm/nuance, multi-language, implicit sentiment |
| **Text Classification** | TF-IDF + logistic regression, spaCy TextCategorizer | Complex taxonomies, few-shot, evolving categories |
| **Tokenization** | spaCy tokenizer, sentencepiece BPE | Generally not needed — preprocessing step |

**Use classical NLP when:**
- High throughput (thousands of docs/sec)
- Budget constraints (no API costs or GPU inference)
- Well-defined tasks with training data
- Interpretability/auditability required

**Use LLMs when:**
- Complex/nuanced understanding (sarcasm, implicit meaning)
- Zero-shot or few-shot (no labeled data)
- Reasoning over context (multi-document QA)
- Rapid prototyping

**Hybrid production pattern:** spaCy for preprocessing, NER, and structured extraction. `spacy-llm` for complex classification within spaCy pipelines. Fine-tuned DistilBERT for production sentiment at scale.

---

## 7. Recommender Systems

### Approaches & Libraries

| Library | Focus | Key Feature |
|---------|-------|-------------|
| **LightFM** | Hybrid (implicit + explicit) | Incorporates user/item metadata into MF; BPR, WARP losses |
| **Surprise** | Explicit feedback (ratings) | scikit-learn API; SVD, NMF, KNN; built-in cross-validation |
| **implicit** | Implicit feedback | ALS, BPR, logistic MF; GPU support; fast for large-scale |
| **TorchRec** (1.4.0) | Production deep learning | Distributed embeddings, pipelined training, sharding strategies |
| **TFRS** | Deep learning | Two-tower models, retrieval + ranking stages |

### Two-Tower Architecture

The dominant architecture for large-scale recommendations:
- Separate neural networks for user and item → shared embedding space
- Fast candidate generation via ANN (FAISS, ScaNN, Milvus, Pinecone)
- Scales to millions of items
- Libraries: TorchRec (PyTorch), TFRS (TensorFlow)

### Production Recommendation Pipeline

```
1. Retrieval: Two-tower model generates ~1000 candidates via ANN
2. Ranking: Cross-attention or feature-interaction model (DeepFM, DCN) scores candidates
3. Re-ranking: Business rules, diversity, freshness constraints
```

### Evaluation Metrics

| Metric | What It Measures | When to Use |
|--------|-----------------|-------------|
| **NDCG@k** | Ranking quality with graded relevance | Default for ranking quality |
| **MAP@k** | Mean average precision | Binary relevance |
| **Precision@k** | Fraction of top-k that are relevant | When top results matter most |
| **Recall@k** | Fraction of relevant items in top-k | Coverage of relevant items |
| **MRR** | Reciprocal rank of first relevant item | Single-answer scenarios (search) |
| **Coverage** | Fraction of catalog recommended | Detecting popularity bias |
| **Diversity** | Intra-list diversity | User experience quality |

**Always evaluate both accuracy and beyond-accuracy metrics** (coverage, diversity, novelty). A system with high NDCG but low coverage is just recommending popular items.

---

## 8. Data Processing at Scale

### Tool Comparison

| Tool | Version | Best For | Scale |
|------|---------|----------|-------|
| **pandas** | 3.0.2 | Quick analysis, broad ecosystem | <1M rows |
| **Polars** | 1.39.x | Performance-critical pipelines | 1M-100M rows |
| **DuckDB** | 1.5.0 | SQL-centric analysis, Parquet files | Single-node, larger-than-memory |
| **PySpark** | 4.1.1 | Distributed cluster processing | >100M rows, multi-TB |
| **Dask** | 2026.3.0 | Scale pandas code to cluster | Distributed, lazy |
| **Modin** | Active | Drop-in pandas speedup | Moderate scale |

### pandas 3.0 (January 2026)

Major breaking changes:
- **Dedicated `str` dtype** by default (not `object`)
- **Copy-on-Write (CoW)** semantics — all indexing returns copies, eliminating copy/view confusion
- Requires Python ≥3.11
- Arrow-backed dtypes narrow the performance gap with Polars for some operations

### Polars vs pandas Performance (2026 Benchmarks)

| Operation | Polars | pandas | Speedup |
|-----------|--------|--------|---------|
| File reading | Fast | Slower | **11x** |
| Filtering 100M rows | 1.89s | ~9.5s | **5x** |
| GroupBy | Fast | Slower | **2.6-3x** |
| Joins | Fast | Slower | Significant |
| Memory usage | 2-4x data size | 5-10x data size | **2-3x less** |

**Polars advantages:** Lazy evaluation, automatic multi-threading, query optimizer, Rust-powered performance.

### DuckDB

In-process OLAP database with zero dependencies:
- Queries pandas, Polars, Arrow objects directly: `duckdb.sql("SELECT * FROM df WHERE x > 5")`
- SQL features: window functions, CTEs, pivots, macros, recursive queries
- Reads Parquet, CSV, JSON natively
- Excellent for ad-hoc analytical queries and larger-than-memory workloads on single machines

### Selection Guide

| Scenario | Recommended Tool |
|----------|-----------------|
| <1M rows, quick analysis, broad ecosystem | pandas |
| 1M-100M rows, performance-critical | Polars |
| SQL-centric analysis, ad-hoc queries | DuckDB |
| >100M rows, distributed cluster | PySpark |
| Scale pandas code to cluster without rewrite | Dask |
| Drop-in pandas speedup (minimal code change) | Modin |

**Production patterns:**
- **pandas + DuckDB**: Use DuckDB for heavy SQL transforms, convert to pandas for ML model input
- **Polars**: Increasingly the default for new data pipeline projects; lazy API enables query optimization
- **PySpark**: Essential for truly distributed workloads (multi-TB datasets across clusters)
- **Vaex**: Development has slowed; Polars has largely subsumed its use case

---

## 9. Decision Frameworks

### Statistical Method Selection

| Question | Method |
|----------|--------|
| Compare two group means | t-test (normal) or Mann-Whitney U (non-normal) |
| Compare 3+ group means | ANOVA (normal) or Kruskal-Wallis (non-normal) |
| Association between categoricals | Chi-square test |
| Distribution comparison | KS test |
| Causal effect estimation | DoWhy + EconML |
| Uplift / treatment heterogeneity | CausalML |
| Bayesian posterior estimation | PyMC or Stan |

### Experimentation Approach

| Scenario | Recommended Approach |
|----------|---------------------|
| Standard A/B test, enough traffic | Frequentist (scipy.stats) or Bayesian (PyMC) |
| Want to peek at results safely | Sequential testing or Bayesian |
| Many variants, continuous optimization | Multi-armed bandits (MABWiser) |
| Need causal effect estimate | A/B test + DoWhy for analysis |
| Self-hosted, open-source platform | GrowthBook |

### Data Processing Tool Selection

| Data Size | Primary Tool | SQL Companion |
|-----------|-------------|--------------|
| <1M rows | pandas | DuckDB (optional) |
| 1M-100M rows | Polars | DuckDB |
| >100M rows (single node) | Polars (lazy) | DuckDB |
| Multi-TB distributed | PySpark | Spark SQL |

### Time Series Approach

| Scenario | Recommended |
|----------|-------------|
| Business forecasting with seasonality | Prophet / NeuralProphet |
| Zero-shot on new dataset | Chronos-2 / TimesFM |
| Fast statistical baselines | Nixtla StatsForecast |
| Deep learning forecasting | Nixtla NeuralForecast (N-BEATS, TFT) |
| Hierarchical reconciliation | Nixtla HierarchicalForecast |
| Anomaly detection | STL + Z-score → Isolation Forest → PyOD |
