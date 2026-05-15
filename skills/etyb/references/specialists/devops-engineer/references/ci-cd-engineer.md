# CI/CD Engineering — Deep Reference

**Always use `WebSearch` to verify current tool versions, cloud service updates, and framework features before giving advice.**

## Table of Contents
1. [GitHub Actions](#1-github-actions)
2. [GitLab CI](#2-gitlab-ci)
3. [Jenkins](#3-jenkins)
4. [ArgoCD](#4-argocd)
5. [CircleCI](#5-circleci)
6. [Emerging Tools](#6-emerging-tools)
7. [Pipeline Design Patterns](#7-pipeline-design-patterns)
8. [Supply Chain Security](#8-supply-chain-security)
9. [GitOps — Flux CD vs ArgoCD](#9-gitops--flux-cd-vs-argocd)
10. [AI in CI/CD](#10-ai-in-cicd)
11. [CI/CD Platform Selection Framework](#11-cicd-platform-selection-framework)

---

## 1. GitHub Actions

### Runner Fleet (2025-2026)

| Runner Type | Specs | Availability | Plan Requirement |
|-------------|-------|--------------|------------------|
| **Standard Linux** | 4 vCPU, 16 GB RAM | GA | Free+ |
| **Larger runners** | Up to 96 vCPU | GA (Apr 2025) | Team / Enterprise Cloud |
| **GPU runners** | NVIDIA T4 / A10G | GA (2024) | Team / Enterprise Cloud |
| **Arm64 runners** | arm64 Linux | GA | Team / Enterprise Cloud |
| **M2 Pro macOS** | Apple M2 Pro | Public Preview (Jul 2025) | Team / Enterprise Cloud |
| **Windows VS 2026** | Visual Studio 2026 | Public Preview (Apr 2026) | Team / Enterprise Cloud |

### Reusable Workflows and Composite Actions

**Reusable workflows** (2025-2026 limits):
- Up to **10 nested** reusable workflows (previously 4)
- Up to **50 total** workflow calls per run (previously 20)
- Called with `uses: org/repo/.github/workflows/build.yml@v1`

**Composite actions** vs reusable workflows:

| Feature | Composite Action | Reusable Workflow |
|---------|-----------------|-------------------|
| Scope | Steps within a job | Entire jobs |
| Secrets access | Inherited from caller | Must be passed explicitly |
| Runner control | Runs on caller's runner | Can specify own `runs-on` |
| Nesting | Supports nesting | Up to 10 levels |
| Location | `.github/actions/` | `.github/workflows/` |
| Use case | Shared step sequences | Shared job definitions |

### Caching, Matrix, and Concurrency

**Dynamic matrix** for monorepo affected packages:
```yaml
jobs:
  detect:
    outputs:
      matrix: ${{ steps.changes.outputs.matrix }}
    steps:
      - id: changes
        run: |
          # detect changed packages, output JSON matrix
          echo "matrix={\"package\":[\"api\",\"web\"]}" >> "$GITHUB_OUTPUT"
  test:
    needs: detect
    strategy:
      matrix: ${{ fromJson(needs.detect.outputs.matrix) }}
      fail-fast: false
      max-parallel: 4
    steps:
      - run: npm test --workspace=${{ matrix.package }}
```

**Concurrency controls** -- cancel redundant runs:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### OIDC and Security (2026 Roadmap)

**OIDC for cloud auth** -- eliminate static secrets:
```yaml
permissions:
  id-token: write
  contents: read
jobs:
  deploy:
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-deploy
          aws-region: us-east-1
```

**2026 Security Roadmap features:**
- **`dependencies:` section** in workflow YAML -- locks all direct and transitive action dependencies by commit SHA (like `go.sum` for workflows)
- **Native egress firewall** -- Layer 7 firewall outside the runner VM, immutable even with root access inside the runner; block all traffic not explicitly permitted
- **Immutable releases** -- once marked immutable, release assets and Git tags cannot change; release attestations verify artifact integrity
- **SHA pinning enforcement** -- admin policy forces all actions to use SHA pins; unpinned workflows fail
- **Action allowlisting** -- available on all plans (Free, Team, Enterprise); prefix with `!` to block specific actions

---

## 2. GitLab CI

### CI/CD Components and Catalog

GitLab CI/CD components are reusable pipeline configuration units published to the CI/CD Catalog. Use partial versions for safe auto-updates:

```yaml
# .gitlab-ci.yml
include:
  - component: gitlab.com/components/sast@~1    # auto-update within 1.x
  - component: gitlab.com/components/secret-detection@1.2.3

build:
  stage: build
  script:
    - make build
  artifacts:
    paths:
      - dist/
```

**Context interpolation** (GA in GitLab 18.7) lets components adapt dynamically to the including pipeline.

**GitLab Functions** (formerly CI/CD Steps, experimental):
- Run inside jobs, replacing `script:` blocks
- Inputs/outputs typed and declared in function spec
- Available in Runner 17.11+
- Components operate at pipeline level; Functions operate at job level

### DAG Pipelines with `needs:`

The `needs:` keyword enables DAG execution -- jobs start when dependencies finish, bypassing stage ordering:

```yaml
stages: [build, test, deploy]

build-api:
  stage: build
  script: make build-api

build-web:
  stage: build
  script: make build-web

test-api:
  stage: test
  needs: [build-api]      # starts immediately after build-api
  script: make test-api

test-web:
  stage: test
  needs: [build-web]      # runs in parallel with test-api
  script: make test-web

deploy:
  stage: deploy
  needs: [test-api, test-web]
  script: make deploy
  when: manual
```

Documented outcomes: **400% increase** in automated code checks, **50% reduction** in feedback loop duration.

### Parent-Child and Downstream Pipelines

```yaml
# parent .gitlab-ci.yml
trigger-api:
  trigger:
    include: api/.gitlab-ci.yml
    strategy: depend         # parent waits for child

trigger-web:
  trigger:
    include: web/.gitlab-ci.yml
    strategy: depend
```

Unified reporting in merge requests for parent-child pipelines: unit tests, code quality, Terraform plans, custom metrics all visible without leaving the MR.

### GitLab Duo AI for CI/CD

- **Pipeline debugging** (GitLab 18.9+): Duo Chat analyzes failed job logs and suggests fixes in context
- **Root Cause Analysis**: forwards log segments to AI Gateway for automated failure analysis
- **Dynamic input options**: dropdown selections dynamically populate based on previous inputs

---

## 3. Jenkins

### Current Relevance (2025-2026)

Jenkins holds a **28% adoption rate**, ranking just behind GitHub Actions. It remains relevant for organizations with heavy customization needs, on-premise requirements, or deep plugin ecosystem dependencies.

| Aspect | Status |
|--------|--------|
| **Core Jenkins** | Active; rolling releases via CloudBees CI (latest: 2.504.2.5, May 2025) |
| **Jenkins X** | Low adoption; primary support from CloudBees only |
| **Blue Ocean** | EOL in July 2026 CloudBees CI release |
| **JCasC** | Active; the standard for Jenkins-as-code |
| **CloudBees CI** | Active; added workspace caching, AI pipeline explorer |

### JCasC (Configuration as Code)

Define full Jenkins config in YAML -- security realm, auth strategy, jobs, plugins -- version-controlled and reproducible. Bootstrap pipeline jobs using Job DSL within JCasC; store Jenkinsfiles in repositories.

**When to still choose Jenkins:** custom plugin requirements, existing investment, air-gapped environments, extreme customization needs. **When to migrate away:** greenfield projects, cloud-native stacks, teams without Jenkins expertise.

---

## 4. ArgoCD

### Version Timeline

| Version | Release | Key Features |
|---------|---------|-------------|
| **v3.0** | May 2025 | Fine-grained RBAC, improved memory efficiency, secure defaults |
| **v3.1** | Aug 2025 | Native OCI registry support, CLI plugins, Source Hydrator |
| **v3.2** | Nov 2025 | Stability improvements (v3.2.5 patch Jan 2026) |
| **v3.3** | Feb 2026 (GA) | Latest stable release |
| v2.14 | EOL Nov 2025 | No longer supported |

### ApplicationSets for Multi-Cluster

ApplicationSets generate Argo CD Applications automatically using generators:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices
spec:
  generators:
    - matrix:
        generators:
          - git:
              repoURL: https://github.com/org/apps.git
              directories:
                - path: 'services/*'
          - clusters:
              selector:
                matchLabels:
                  env: production
  template:
    metadata:
      name: '{{path.basename}}-{{name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/org/apps.git
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: '{{server}}'
        namespace: '{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

**Generator types:** List, Cluster, Git (directory/file), Matrix (combines generators), Merge, Pull Request, SCM Provider.

### Progressive Delivery with Argo Rollouts

Argo Rollouts provides blue-green and canary strategies with automated analysis. Canary steps: `setWeight` -> `pause` -> `analysis` (query Prometheus/Datadog/NewRelic) -> promote or auto-rollback. Integrates with Istio, NGINX, ALB, SMI, Traefik, and Ambassador for traffic shaping.

---

## 5. CircleCI

### Key Features

| Feature | Details |
|---------|---------|
| **Orbs** | Reusable config packages (public registry + private org orbs) for AWS, GCP, K8s, Terraform, Slack, security scanning |
| **Dynamic config** | Generate/modify pipeline graph at runtime based on file changes, branch, or custom logic |
| **Self-hosted runners** | Run on your infra (K8s, VMs, bare metal); auto-scaling support; parallelism and test splitting |
| **Insights** | Pipeline analytics, flaky test detection, performance trends |
| **Test splitting** | Distribute tests across parallel containers by timing data |

**Dynamic config example** -- only run changed service pipelines:
```yaml
# .circleci/config.yml
setup: true
orbs:
  path-filtering: circleci/path-filtering@1.0
workflows:
  setup:
    jobs:
      - path-filtering/filter:
          mapping: |
            api/.* run-api true
            web/.* run-web true
          config-path: .circleci/continue.yml
```

---

## 6. Emerging Tools

### Tool Comparison

| Tool | Architecture | Language | Status (2026) | Best For |
|------|-------------|----------|---------------|----------|
| **Dagger.io** (v0.20) | Pipelines as code via SDKs | Go, Python, TS, PHP, Java, .NET, Rust, Elixir | Active; v0.20.3 (Mar 2026) | Portable pipelines, local-CI parity |
| **Earthly** | Dockerfile-like syntax | Earthfile | **Shut down Jul 2025**; CLI maintenance-only | Do not adopt |
| **Buildkite** | Hybrid SaaS + self-hosted agents | YAML + plugins | Active | Large-scale, self-hosted infra |
| **Tekton** (v1.0) | K8s-native CRDs | YAML | Active; CNCF Incubation | K8s-native, supply chain (Tekton Chains) |
| **Woodpecker CI** | Container-based, lightweight | YAML | Active | Self-hosted, resource-constrained, Drone replacement |

### Dagger.io (v0.20)

Pipelines as code using real programming languages (Go, Python, TS, etc.) with full IDE support, type safety, and testability. Runs identically locally and in any CI. Modules shared via Daggerverse. SDKs expose a container-based API: chain `.from_()`, `.with_exec()`, `.with_directory()` calls to define reproducible build graphs.

### Buildkite (2025-2026)

Recent features:
- **GitHub merge queue** first-class support
- **Secrets in pipeline YAML** -- native `secrets` key, no plugin needed
- **Test Engine**: flaky test detection (auto-clears label after 100 clean runs or 7 days), Slack notifications, branch/state/tag filtering
- **Dynamic parallelism** (bktec): auto-sets parallelism to hit target build duration
- **AI pipeline converter**: translates GitHub Actions workflows to Buildkite pipelines
- **Package registries**: NuGet (.NET), GCP Private Storage Link, webhook notifications

### Tekton (v1.0 GA)

Kubernetes-native CI/CD using CRDs (Tasks, Pipelines, Triggers, Chains):
- **Tekton Chains**: automatic signing and attestation of build artifacts (Sigstore integration)
- **Pipelines-as-Code**: Git-native workflow in `.tekton/` directory; integrates with GitHub, GitLab, Bitbucket, Forgejo
- **Policy enforcement** via OPA and Kyverno
- **Observability** via OpenTelemetry
- Best suited for teams already committed to Kubernetes-native tooling

### Woodpecker CI

Community fork of Drone CI; fully open-source (Apache 2.0):
- Docker-container pipeline steps
- Multi-workflow support with inter-workflow dependencies
- ~100 MB RAM (server) + ~30 MB (agent) at idle
- SQLite default database
- Ideal for self-hosted, resource-constrained environments

---

## 7. Pipeline Design Patterns

### Monorepo CI Strategy

**Affected-only builds** -- the critical pattern for monorepo scale. Use `dorny/paths-filter@v3` or platform-native path rules to detect changes, then build a dynamic matrix with one job per affected package. Combine with Nx/Turborepo/Bazel for dependency-graph-aware task scheduling.

Tools: **Nx**, **Turborepo**, **Bazel**, **Pants**. Real-world impact: pipelines reduced from 52 min to 8 min with affected-only + caching.

### Caching Strategy Matrix

| Cache Layer | Tool | Scope | Invalidation |
|-------------|------|-------|-------------|
| **Dependency cache** | `actions/cache@v4`, built-in setup actions | Per-lockfile hash | Lockfile change |
| **Build cache** | Turborepo remote cache, Bazel remote cache, Nx Cloud | Per-content hash | Source change |
| **Docker layer cache** | BuildKit cache mount, `docker/build-push-action` cache | Per-layer | Dockerfile / source change |
| **Test result cache** | Bazel, Pants, Nx | Per-test-input hash | Test file or dependency change |

### Environment Promotion Pattern

```
Source -> Build -> Artifact Registry -> Dev -> Staging -> Production
                      |                  |        |          |
                    Sign +           Auto-deploy  QA gate  Manual
                    SBOM             (on merge)   + integ  approval
                    attest                        tests    + canary
```

**Key principle:** Build the artifact once, promote the same immutable artifact through environments. Never rebuild per environment.

### Deployment Gates and Approval Workflows

Use GitHub Actions `environment:` key with protection rules (required reviewers, wait timer, deployment branch rules). GitLab uses `when: manual` + `allow_failure: false` for gate jobs. Pattern: `deploy-staging` -> (auto QA) -> `deploy-production` (manual approval required).

---

## 8. Supply Chain Security

### SLSA Framework (v1.2)

| Level | Requirements | Provides |
|-------|-------------|----------|
| **L0** | None | No guarantees |
| **L1** | Build process documented; provenance auto-generated and distributable | Basic provenance |
| **L2** | Hosted build service; provenance auto-generated **and signed** | Tamper-resistant provenance |
| **L3** | Hardened build platform; isolated, ephemeral environments | High confidence in build integrity |

### Sigstore Ecosystem

| Component | Purpose |
|-----------|---------|
| **Cosign** | Sign and verify container images, SBOMs, and arbitrary artifacts |
| **Fulcio** | Issues short-lived certificates tied to OIDC identity (keyless signing) |
| **Rekor** | Immutable transparency log recording all signing events |

**Keyless signing in GitHub Actions:**
```yaml
jobs:
  sign:
    permissions:
      id-token: write
      packages: write
    steps:
      - uses: sigstore/cosign-installer@v3
      - run: |
          cosign sign --yes \
            ghcr.io/org/app@${{ steps.build.outputs.digest }}
      - run: |
          cosign verify \
            --certificate-identity=https://github.com/org/app/.github/workflows/build.yml@refs/heads/main \
            --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
            ghcr.io/org/app@${{ steps.build.outputs.digest }}
```

No long-lived signing keys -- identity tied to CI workflow via OIDC.

### SBOM Generation and Provenance

```yaml
# GitHub Actions: generate SBOM + attest provenance
steps:
  - uses: anchore/sbom-action@v0
    with:
      image: ghcr.io/org/app:${{ github.sha }}
      format: spdx-json
      output-file: sbom.spdx.json

  - uses: actions/attest-build-provenance@v2
    with:
      subject-name: ghcr.io/org/app
      subject-digest: ${{ steps.build.outputs.digest }}
```

### OIDC for Secretless Pipelines

The industry is converging on secretless CI/CD in 2026:
- **GitHub Actions OIDC** -> AWS IAM roles, GCP Workload Identity Federation, Azure federated credentials
- **npm** permanently revoked all classic tokens (Dec 2025); replaced with short-lived session tokens
- **Bitbucket** disabling all app passwords (Jun 2026); API tokens only
- **Cosign keyless signing** ties signatures to OIDC workflow identity

---

## 9. GitOps -- Flux CD vs ArgoCD

### Architecture Comparison

| Dimension | ArgoCD (v3.x) | Flux CD (v2.x) |
|-----------|---------------|-----------------|
| **Architecture** | Centralized control plane | Decentralized per-cluster reconciliation |
| **UI** | Rich built-in web UI | No built-in UI (use Grafana/Weave GitOps) |
| **Multi-tenancy** | Native RBAC, project-level isolation | Namespace-scoped, Kustomization-based |
| **Multi-cluster** | Central hub manages remote clusters | Each cluster autonomous with GitOps toolkit |
| **Helm support** | First-class; hooks, values, chart repos | First-class via HelmRelease CRD |
| **Kustomize** | First-class | First-class |
| **OCI support** | Native (v3.1+) | Native |
| **Drift detection** | `selfHeal: true` reverts manual edits | Auto-revert when cluster diverges from Git |
| **Progressive delivery** | Argo Rollouts integration | Flagger integration |
| **Resource footprint** | Higher (API server, UI, Redis) | Lower (controller-only) |
| **CNCF status** | Graduated | Graduated |

### Decision Guide

**Choose ArgoCD when:**
- Developer experience matters (web UI for visibility)
- Managing dozens of applications across clusters from a central hub
- Team needs visual deployment status and audit trail
- Progressive delivery with Argo Rollouts is required

**Choose Flux CD when:**
- Platform engineering with modular, composable infrastructure
- Air-gapped or resource-constrained clusters
- No UI needed (CLI-first, Grafana for dashboards)
- Preference for per-cluster autonomy over central control

### Drift Detection

**ArgoCD:** Set `syncPolicy.automated.selfHeal: true` -- any manual cluster edit is reverted to match Git. **Flux CD:** Set `prune: true` on Kustomization resources -- deleted Git resources are removed from cluster; reconciliation interval (default 5m) catches drift.

---

## 10. AI in CI/CD

### Current Capabilities (2026)

| Capability | Tools | Maturity |
|-----------|-------|----------|
| **Intelligent test selection** | CloudBees Smart Tests, Launchable, Buildkite Test Engine | Production-ready |
| **Flaky test detection** | Datadog Test Optimization, Buildkite Test Engine, CircleCI Insights | Production-ready |
| **Automated flaky test fixing** | Datadog Bits AI Dev Agent | Early adopter |
| **Pipeline debugging** | GitLab Duo (18.9+), CloudBees AI Pipeline Explorer | GA |
| **Build optimization** | Predictive resource allocation, cache optimization | Emerging |
| **Self-healing pipelines** | Auto-rollback based on observability data | Emerging |

**CloudBees Smart Tests:** Analyzes code changes to run only relevant tests; reduces CI feedback time by 50-80%; works across Jenkins, GitHub Actions, GitLab CI.

**Datadog Test Optimization:** Tracks results across hundreds of runs, identifies flaky tests (pass+fail on same SHA), and Bits AI Dev Agent generates verified fix PRs automatically.

**Industry adoption:** 81% of dev teams use AI in testing workflows (2025); 84% of developers using or planning AI tools (Stack Overflow 2025).

---

## 11. CI/CD Platform Selection Framework

### CI/CD Platform Selection Matrix

| Factor | GitHub Actions | GitLab CI | Jenkins | ArgoCD | CircleCI | Buildkite | Dagger |
|--------|---------------|-----------|---------|--------|----------|-----------|--------|
| **Source hosting** | GitHub | GitLab | Any | Any (K8s) | Any | Any | Any |
| **Self-hosted option** | Runners only | Full platform | Full platform | Full (K8s) | Runners + server | Agents only | Engine anywhere |
| **Pricing model** | Per-minute | Per-seat (CI free tier) | Free (OSS) | Free (OSS) | Per-credit | Per-agent | Free (OSS) |
| **Config language** | YAML | YAML | Groovy/YAML | YAML (K8s CRDs) | YAML | YAML | Go/Python/TS |
| **Container-native** | Yes | Yes | Plugin-based | Yes (K8s only) | Yes | Yes | Yes (core) |
| **Monorepo support** | Path filters + matrix | `rules:changes` + child pipelines | Multibranch | ApplicationSets | Path filtering orb | Dynamic pipelines | Native |
| **Secret management** | Encrypted secrets + OIDC | CI/CD variables + Vault | Credentials plugin | K8s secrets + Vault | Contexts + OIDC | Secrets key in YAML | Host env |
| **Supply chain security** | Attestations, OIDC, Sigstore | Sigstore, SBOM | Plugin-based | Git-based audit trail | OIDC, Sigstore orb | SLSA support | Container isolation |
| **AI features** | Copilot for Actions | Duo Chat, Root Cause Analysis | CloudBees Smart Tests | None native | Insights | AI pipeline converter | None |
| **Learning curve** | Low | Low-Medium | High | Medium (K8s req.) | Low | Low-Medium | Medium (SDK) |

### Decision Framework

**Start here:**

1. **Already on GitHub?** -> GitHub Actions (lowest friction, deepest integration)
2. **Already on GitLab?** -> GitLab CI (built-in, zero config overhead)
3. **Kubernetes-native deployment?** -> ArgoCD (GitOps) + GitHub Actions/GitLab CI (build)
4. **Need local-CI parity?** -> Dagger (runs identically local and CI)
5. **Self-hosted at scale?** -> Buildkite (hybrid model, your agents)
6. **Existing Jenkins investment?** -> Modernize with JCasC; migrate incrementally
7. **Air-gapped / minimal resources?** -> Woodpecker CI or Flux CD

**Anti-patterns to avoid:**
- Choosing Jenkins for greenfield cloud-native projects
- Adopting Earthly (shut down Jul 2025)
- Running ArgoCD without `selfHeal: true` (defeats GitOps)
- Storing long-lived secrets in CI when OIDC federation is available
- Building artifacts per-environment instead of promoting immutable artifacts
- Skipping SBOM generation and provenance attestation in 2026
