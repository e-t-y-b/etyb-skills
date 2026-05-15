# Release Engineering — Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Deployment Strategies](#1-deployment-strategies)
2. [Progressive Delivery](#2-progressive-delivery)
3. [Feature Flags](#3-feature-flags)
4. [GitOps](#4-gitops)
5. [Rollback Strategies](#5-rollback-strategies)
6. [Release Versioning](#6-release-versioning)
7. [Artifact Management](#7-artifact-management)
8. [Release Orchestration](#8-release-orchestration)
9. [Testing in Production](#9-testing-in-production)
10. [Compliance and Auditing](#10-compliance-and-auditing)
11. [Deployment Strategy Selection Framework](#11-deployment-strategy-selection-framework)

---

## 1. Deployment Strategies

### Comparison Matrix

| Strategy | Risk | Complexity | Infra Cost | Rollback Speed | Zero Downtime | Traffic Control |
|----------|------|-----------|------------|---------------|---------------|-----------------|
| **Blue-Green** | Low | Medium | 2x (dual environments) | Instant (switch back) | Yes | All-or-nothing |
| **Canary** | Low | High | +5-10% | Fast (shift traffic) | Yes | Percentage-based |
| **Rolling** | Medium | Low | +0-25% | Slow (roll forward) | Yes (with surge) | Per-pod |
| **A/B Testing** | Low | High | +10-50% | Fast | Yes | User-segment |
| **Shadow/Dark** | Very Low | Very High | 2x (mirrored) | N/A (not serving) | Yes | Mirrored copy |

### Blue-Green Deployments

Two identical environments (Blue = live, Green = new). Traffic switches atomically.

**Argo Rollouts blue-green:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: my-app-active
      previewService: my-app-preview
      autoPromotionEnabled: false
      prePromotionAnalysis:
        templates:
        - templateName: smoke-tests
        args:
        - name: service-name
          value: my-app-preview
      scaleDownDelaySeconds: 600   # keep blue for 10 min rollback window
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:2.0.0
```

**AWS ECS native blue/green (July 2025):** Built-in blue/green without CodeDeploy. All-at-once switch with configurable bake time. Use CodeDeploy only if you need canary/linear traffic shifting.

**GCP Cloud Run:** Revision-based traffic splitting via `gcloud run services update-traffic SERVICE --to-revisions REV1=90,REV2=10`. Cloud Run Release Manager adds automated metric-driven promotion.

### Canary Releases

Deploy to small subset, increase traffic based on metrics: `5% -> 10% -> 25% -> 50% -> 100%`, pausing at each step to check error rate (5xx), latency (p99), saturation (CPU/memory), and business metrics (conversion).

### Rolling Updates

Kubernetes default. Replaces pods incrementally (`maxSurge: 25%`, `maxUnavailable: 25%`). No traffic control -- pods receive traffic by replica ratio. Use readiness probes aggressively.

### Shadow / Dark Launch

Mirror production traffic to new version without serving responses. Validates behavior under real load.

**Istio traffic mirroring:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
  - my-service
  http:
  - route:
    - destination:
        host: my-service
        subset: v1
      weight: 100
    mirror:
      host: my-service
      subset: v2
    mirrorPercentage:
      value: 100.0
```

**Critical constraint:** Shadow environments must not write to production databases or trigger side effects (emails, payments). Use read-only replicas or separate data stores for the shadow path.

---

## 2. Progressive Delivery

### Argo Rollouts

Kubernetes controller providing canary, blue-green, and analysis-driven rollouts via custom `Rollout` CRD.

**Canary with automated analysis:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 5
      - pause: {duration: 5m}
      - analysis:
          templates:
          - templateName: success-rate
          args:
          - name: service-name
            value: my-app-canary
      - setWeight: 25
      - pause: {duration: 10m}
      - analysis:
          templates:
          - templateName: success-rate
      - setWeight: 50
      - pause: {duration: 15m}
      - setWeight: 100
      canaryService: my-app-canary
      stableService: my-app-stable
      trafficRouting:
        istio:
          virtualServices:
          - name: my-app-vsvc
            routes:
            - primary
```

**AnalysisTemplate — Prometheus success rate:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 60s
    count: 5
    failureLimit: 2
    successCondition: result[0] >= 0.95
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status=~"2.."}[5m]))
          /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

**Experiments:** Run baseline vs. canary ReplicaSets in parallel for equal comparison. Use `measurementRetention` to keep analysis history. `dryRun` mode tests analysis pipelines without affecting rollout state. `ttlStrategy` auto-cleans completed AnalysisRuns.

### Flagger

Progressive delivery operator that works with standard Kubernetes Deployments (no manifest changes required).

**Flagger with Istio:**
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: my-app
  namespace: default
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  service:
    port: 80
    targetPort: 8080
    gateways:
    - public-gateway.istio-system.svc.cluster.local
    hosts:
    - my-app.example.com
  analysis:
    interval: 1m
    threshold: 5           # max failed checks before rollback
    maxWeight: 50          # max canary traffic percentage
    stepWeight: 10         # traffic increment per interval
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
    webhooks:
    - name: load-test
      url: http://flagger-loadtester.test/
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://my-app-canary.default:80/"
```

**Flagger with Gateway API:**
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: my-app
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  service:
    port: 80
    apex: my-app
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
  provider: gatewayapi
  routeRef:
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    name: my-app
```

### Argo Rollouts vs. Flagger

| Feature | Argo Rollouts | Flagger |
|---------|--------------|---------|
| **Manifest changes** | Requires `Rollout` CRD (replaces Deployment) | Works with standard Deployments |
| **Step control** | Explicit step-by-step definition | Declarative analysis with auto-progression |
| **Metric providers** | Prometheus, Datadog, NewRelic, Wavefront, CloudWatch, Kayenta | Prometheus, Datadog, CloudWatch, NewRelic + webhooks |
| **Service mesh** | Istio, Linkerd, SMI, NGINX, ALB, Gateway API (plugin) | Istio, Linkerd, Gateway API (native), Contour, Gloo, NGINX |
| **GitOps fit** | Native ArgoCD integration | Native FluxCD integration (works with ArgoCD) |
| **Blue-green** | Full support | Full support |
| **Experiments** | Built-in baseline vs. canary | Not built-in |
| **Best for** | Teams wanting explicit control and ArgoCD | Teams wanting automation and FluxCD |

---

## 3. Feature Flags

### Platform Comparison

| Platform | Type | OpenFeature | Pricing Model | Experimentation | Best For |
|----------|------|-------------|---------------|-----------------|----------|
| **LaunchDarkly** | SaaS | Provider available | Per-seat + MAU | Built-in (Guarded Releases) | Enterprise, full-featured |
| **Unleash** | OSS / SaaS | Official provider | Free self-host, paid cloud | Basic (via strategies) | Self-hosted, open source |
| **Flagsmith** | OSS / SaaS | Founding member | Free tier, usage-based | Basic A/B | OpenFeature-first teams |
| **Statsig** | SaaS | Provider available | Free flags, paid analytics | Advanced (CUPED, sequential) | Data-driven orgs (acquired by OpenAI) |
| **Split.io** | SaaS | Provider available | Enterprise pricing | Built-in | Regulated enterprises |
| **ConfigCat** | SaaS | Provider available | Usage-based (affordable) | Basic (percentage rollouts) | Small teams, budget-conscious |

### OpenFeature Standard (CNCF Incubating)

Vendor-neutral, language-agnostic abstraction layer for feature flags. Write code against OpenFeature API; swap providers without code changes.

```typescript
// OpenFeature SDK -- provider-agnostic code
import { OpenFeature } from '@openfeature/server-sdk';
import { LaunchDarklyProvider } from '@launchdarkly/openfeature-node-server';

// Configure provider once at startup
OpenFeature.setProvider(new LaunchDarklyProvider('sdk-key'));
const client = OpenFeature.getClient();

// Evaluate flags -- same code regardless of provider
const showNewCheckout = await client.getBooleanValue(
  'new-checkout-flow',
  false,  // default value
  { targetingKey: user.id, email: user.email }
);

if (showNewCheckout) {
  renderNewCheckout();
} else {
  renderLegacyCheckout();
}
```

**Why OpenFeature matters (2025):** The October 2025 AWS US-East-1 outage took LaunchDarkly offline, driving adoption of vendor-neutral abstractions that enable provider failover.

### LaunchDarkly (2025 Features)

- **Guarded Releases:** Smart Minimums dynamically adjust sample sizes; Health Checks validate flag config upfront; Auto-Generated Metrics provide out-of-the-box telemetry
- **Error Monitoring + Session Replay:** Detects exceptions triggered by rollouts with full stack traces and pixel-perfect session playback
- **AI Configs:** Runtime control of AI prompts and model configurations behind feature flags
- **Warehouse-Native Experimentation:** Product analytics integrated with experimentation

### Unleash (OSS)

Largest open-source feature flag platform (Apache 2.0). Node.js API server backed by PostgreSQL.

- **Flag lifecycle types:** release (40-day expected lifetime), experiment, operational, kill-switch, permission
- **Unleash Edge:** Rust-based edge evaluator replacing the older Node.js proxy -- evaluates flags at network edge for sub-millisecond latency
- **30+ SDKs** across all major languages
- **Activation strategies:** gradual rollout, user IDs, IPs, hostnames, custom constraints

### Feature Flag Lifecycle Management

**Flag debt is real technical debt.** Production-proven lifecycle:

1. **Creation:** Create cleanup ticket simultaneously. Tag with owner, team, expected lifetime, flag type
2. **Rollout:** Progressive rollout with metric monitoring. Document rollback procedure
3. **Full rollout:** Flag serving 100% to all users. Clock starts on cleanup window
4. **Stale detection:** Automated alerts when flags exceed expected lifetime (e.g., release flags > 40 days)
5. **Cleanup:** Remove flag evaluations from code, delete flag from platform, close cleanup ticket

**Server-side vs. client-side flags:**

| Aspect | Server-Side | Client-Side |
|--------|-------------|-------------|
| **Latency** | <1ms (in-memory) | Network round-trip or cached |
| **Security** | Flag rules hidden from users | Rules visible in payload |
| **Use cases** | Backend features, kill switches, infrastructure | UI features, A/B tests, personalization |
| **Caching** | Server memory, shared across requests | Local storage, per-user |
| **SDK examples** | Node, Python, Java, Go SDKs | JavaScript, React, iOS, Android SDKs |

---

## 4. GitOps

### ArgoCD vs. Flux CD (2025)

| Feature | ArgoCD | Flux CD |
|---------|--------|---------|
| **CNCF status** | Graduated | Graduated |
| **Architecture** | Centralized UI + API server | Lightweight, CLI-driven controllers |
| **Web UI** | Rich built-in dashboard (diff, sync, logs) | No built-in UI (use Grafana, Weave GitOps) |
| **Multi-cluster** | Native centralized management | Per-cluster install, federated |
| **RBAC** | Built-in SSO + RBAC | Relies on Kubernetes RBAC |
| **Secrets** | External Secrets Operator, Sealed Secrets | Native SOPS integration (configure once) |
| **Helm support** | Full | Full |
| **Kustomize** | Full | Full |
| **Progressive delivery** | Argo Rollouts (native integration) | Flagger (native integration) |
| **Best for** | Teams transitioning from CI/CD, centralized ops | Cloud-native teams, CLI-first, minimal overhead |

**Choose ArgoCD** when you want centralized visibility, SSO, and multi-cluster oversight from a single pane.
**Choose Flux CD** when you want lightweight, per-cluster GitOps with minimal resource footprint.

### Environment Promotion Patterns

**Folder-per-environment (recommended for most teams):**
```
gitops-repo/
  base/                    # shared manifests
    deployment.yaml
    service.yaml
  overlays/
    dev/
      kustomization.yaml   # patches for dev
    staging/
      kustomization.yaml   # patches for staging
    production/
      kustomization.yaml   # patches for production
```

**Promotion flow:** Commit to `dev/` overlay -> automated tests pass -> PR to update `staging/` overlay -> smoke tests pass -> PR to update `production/` overlay. Each promotion is a Git commit with full audit trail.

**GitOps Promoter (ArgoCD ecosystem):** Automated tool that creates PRs for environment promotion based on health checks and policy, replacing manual overlay updates.

### Pull-Based vs. Push-Based

| Model | How It Works | Pros | Cons |
|-------|-------------|------|------|
| **Pull (GitOps)** | Controller polls Git, reconciles cluster | Git is single source of truth, drift detection, audit trail | Requires controller in cluster, reconciliation delay |
| **Push (CI/CD)** | Pipeline pushes to cluster via kubectl/helm | Simple, immediate, works with existing CI | No drift detection, credentials in CI, no reconciliation |

**2025 consensus:** Pull-based is the standard for production Kubernetes. Push-based remains common for non-K8s targets and legacy pipelines.

---

## 5. Rollback Strategies

### Automated Rollback Triggers

| Trigger | Signal Source | Threshold Example | Action |
|---------|--------------|-------------------|--------|
| **Error rate spike** | Prometheus, Datadog | >1% 5xx over 5 min | Auto-rollback |
| **Latency degradation** | APM (NewRelic, Datadog) | p99 > 2x baseline | Pause + alert |
| **Failed health checks** | Kubernetes readiness | 3 consecutive failures | Pod restart / rollback |
| **Error budget burn** | SLO platform (Nobl9, Datadog) | >5x burn rate | Block deployments |
| **Business metric drop** | Custom metrics | Conversion < 95% baseline | Alert + manual decision |

### Database-Aware Rollbacks

Database migrations are the hardest part of rollback. Production-proven rules:

1. **Expand-contract migrations:** Never make breaking schema changes in one step. Add new column -> deploy code that writes both -> migrate data -> deploy code that reads new -> drop old column
2. **Forward-only migrations:** Treat migrations as irreversible. If rollback is needed, write a new forward migration that reverses the effect
3. **Versioned migrations alongside code:** Store migration version in deployment metadata. Rollback tooling checks if target version requires migration rollback
4. **Blue-green database pattern:** For critical changes, run parallel database schemas with data sync

### Kubernetes Rollback Commands

```bash
# View rollout history
kubectl rollout history deployment/my-app

# Rollback to previous revision
kubectl rollout undo deployment/my-app

# Rollback to specific revision
kubectl rollout undo deployment/my-app --to-revision=3

# Argo Rollouts abort (stops canary, shifts traffic to stable)
kubectl argo rollouts abort my-app

# Argo Rollouts retry (after fixing issue)
kubectl argo rollouts retry rollout my-app
```

### Immutable Deployment Pattern

Every deployment is a new, immutable artifact. Never patch in place.

- Container images tagged by SHA, never `latest`
- Helm charts versioned and stored in chart registry
- Terraform state versioned; rollback = apply previous state
- Rollback = redeploy previous known-good artifact

---

## 6. Release Versioning

### Versioning Strategy Comparison

| Strategy | Format | Best For | Automation | Example |
|----------|--------|----------|------------|---------|
| **SemVer** | MAJOR.MINOR.PATCH | Libraries, APIs, packages | semantic-release | `3.2.1` |
| **CalVer** | YYYY.MM.DD or YYYY.MM.MICRO | Applications, SaaS, internal tools | Custom scripts | `2025.04.2` |
| **SemVer + pre-release** | MAJOR.MINOR.PATCH-rc.N | Release candidates | semantic-release | `3.2.1-rc.1` |
| **Hybrid** | SemVer for libs, CalVer for apps | Monorepos with mixed artifacts | Per-package config | -- |

**2025 guidance:** SemVer for anything consumed as a dependency (libraries, APIs). CalVer for applications and SaaS products where release timing matters more than compatibility signaling.

### Automated Changelog Tools

| Tool | Approach | Monorepo | Language | Best For |
|------|----------|----------|----------|----------|
| **semantic-release** | Analyzes conventional commits | Via plugins (semantic-release-monorepo) | JavaScript (Node.js) | npm packages, CI-first automation |
| **release-please** | Creates release PRs from conventional commits | Native multi-package support | Any (GitHub Actions) | Google-style release workflow |
| **changesets** | Developers declare version intent per PR | Native (designed for monorepos) | JavaScript (Node.js) | Monorepos with human-curated changelogs |

**Conventional Commits standard:**
```
feat: add user avatar upload          -> MINOR bump
fix: correct timezone in scheduler    -> PATCH bump
feat!: redesign auth API              -> MAJOR bump (breaking)
chore: update dependencies            -> no version bump
```

**semantic-release in CI:**
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    branches: [main]
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 22
    - run: npm ci
    - run: npx semantic-release
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**changesets workflow (monorepo):**
```bash
# Developer creates changeset with PR
npx changeset add
# Selects packages affected, bump type, writes summary

# CI creates "Version Packages" PR aggregating changesets
# On merge, changesets publishes all affected packages
npx changeset version   # updates package.json + CHANGELOG
npx changeset publish   # publishes to npm
```

---

## 7. Artifact Management

### Container Image Security Pipeline

```
Build -> Scan (Trivy/Grype) -> Sign (cosign) -> Generate SBOM (Syft) -> Attest provenance (SLSA) -> Push to registry
```

### Cosign Keyless Signing (Sigstore)

Sigstore issues short-lived certificates via OIDC. No long-lived keys to manage.

```bash
# Sign container image (keyless -- uses OIDC identity)
cosign sign --yes ghcr.io/myorg/myapp@sha256:abc123...

# Verify signature with identity constraints
cosign verify \
  --certificate-identity "https://github.com/myorg/myapp/.github/workflows/build.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/myorg/myapp@sha256:abc123...

# Attach SBOM to image
cosign attach sbom --sbom sbom.cyclonedx.json ghcr.io/myorg/myapp@sha256:abc123...

# Sign the attached SBOM
cosign sign --yes ghcr.io/myorg/myapp:sha256-abc123.sbom
```

**Critical:** Always sign by digest (`@sha256:...`), never by tag. Tags are mutable.

### SBOM Generation

| Tool | Formats | Strengths | Use When |
|------|---------|-----------|----------|
| **Syft** (Anchore) | CycloneDX, SPDX | Fastest, broadest language support, containers + filesystems | Default choice for most pipelines |
| **cdxgen** | CycloneDX | Deep dependency resolution, reachability analysis | Security-first workflows |
| **Trivy** (Aqua) | CycloneDX, SPDX | Combined SBOM + vulnerability scanning | Already using Trivy for scanning |
| **Tern** | SPDX | Layer-by-layer container analysis | Container compliance audits |

**Syft in CI:**
```bash
# Generate CycloneDX SBOM from container image
syft ghcr.io/myorg/myapp:latest -o cyclonedx-json > sbom.cyclonedx.json

# Generate SPDX SBOM from source directory
syft dir:./src -o spdx-json > sbom.spdx.json
```

**Regulatory drivers (2025-2026):** EU Cyber Resilience Act (effective September 2026) and US Executive Order 14028 both require SBOM generation. This is now a compliance necessity.

### SLSA Framework (Supply-chain Levels for Software Artifacts)

| Level | Requirement | What It Proves |
|-------|------------|----------------|
| **SLSA 1** | Provenance exists | Build process is documented |
| **SLSA 2** | Hosted build platform, signed provenance | Build was not tampered locally |
| **SLSA 3** | Hardened, tamper-resistant build platform | Build environment was isolated and protected |
| **SLSA 4** | Two-party review, hermetic builds | Human review + reproducible builds |

**GitHub Actions attestation (achieves SLSA Level 3):**
```yaml
- uses: actions/attest-build-provenance@v2
  with:
    subject-path: 'dist/my-artifact.tar.gz'
    subject-name: 'my-artifact'
```

**2025 reality:** The GhostAction attack (early 2025) compromised a widely-used GitHub Action, underscoring the need for provenance verification. GitHub's built-in attestation + `slsa-github-generator` can reach SLSA Level 2-3 in an afternoon.

---

## 8. Release Orchestration

### Branching Strategies

| Strategy | Merge Frequency | Release Cadence | Best For |
|----------|----------------|-----------------|----------|
| **Trunk-based** | Multiple times/day | Continuous | High-performing teams, SaaS |
| **Release branches** | Per release cycle | Scheduled (weekly, biweekly) | Mobile apps, regulated environments |
| **Release trains** | Per train schedule | Fixed cadence (e.g., every 2 weeks) | Large orgs, coordinated releases |
| **GitFlow** | Per feature completion | Scheduled | Legacy, rarely recommended in 2025 |

**2025 consensus:** Trunk-based development is the standard for elite DevOps teams. Feature flags replace long-lived branches. Release branches reserved for environments requiring extended stabilization (mobile, embedded).

### Environment Promotion Pipeline

```
Commit to main
  -> Build + test (unit, integration)
  -> Deploy to dev (auto)
  -> Integration tests pass
  -> Deploy to staging (auto or approval)
  -> E2E tests + smoke tests
  -> Deploy to production (approval gate)
  -> Canary analysis (5% -> 25% -> 50% -> 100%)
  -> Post-deploy verification
```

**Key principle:** Every environment deploys from the same artifact. No rebuilding between stages. Configuration differs; binaries do not.

### Release Trains

Fixed-cadence releases where features either make the train or wait for the next one.

- **Cadence:** Typically biweekly or monthly
- **Cut-off:** Feature freeze N days before release
- **Stabilization:** Release branch created at cut-off; only bugfixes merged
- **Skip rule:** If a feature is not ready, it rides the next train (no delays)
- **89% reduction** in deployment-related incidents reported by organizations using feature flags with release trains (Nudge, 2025)

---

## 9. Testing in Production

### Traffic Mirroring / Shadow Testing

Duplicate production traffic to new version without serving responses. Validates performance and correctness under real load.

**Implementation checklist:**
- Configure service mesh mirroring (Istio `mirror` field or Envoy config)
- Ensure shadow path has NO write side effects (payments, emails, database mutations)
- Compare response bodies, latency distributions, and error rates between live and shadow
- Use dashboards to surface divergence (Grafana, Datadog)

### Synthetic Monitoring

Proactive health checks simulating real user journeys in production.

- **Tools:** Datadog Synthetic, Grafana k6, Checkly, Playwright (headless)
- **Patterns:** Run synthetic tests immediately post-deploy as smoke checks
- **Coverage:** Critical user flows (login, checkout, search, API health)

### Chaos Engineering Integration

| Tool | Type | Best For |
|------|------|----------|
| **LitmusChaos** | CNCF OSS | Kubernetes-native, CI/CD integration, ChaosHub experiments |
| **Chaos Mesh** | CNCF OSS | Cloud-native failure simulation |
| **Gremlin** | SaaS | Enterprise, reliability dashboards, automated testing |
| **Steadybit** | SaaS | Resilience policies, declarative experiment rules |
| **AWS FIS** | Managed | AWS-native fault injection |

**Integration pattern:** Run chaos experiments as post-deploy validation. Inject network latency, pod failures, or resource exhaustion to verify the new version handles degraded conditions.

### Error Budget Burn Rate

SLO-based release gating integrates error budgets into deployment decisions.

| Budget Remaining | Deployment Action |
|-----------------|-------------------|
| **>50%** | Proceed normally |
| **20-50%** | Proceed with extra monitoring, reduced blast radius |
| **<20%** | Block non-critical releases until budget recovers |
| **Exhausted** | Emergency only, requires VP approval |

**Burn rate alerting:** A 5x burn rate over 1 hour means you will exhaust your monthly error budget in ~6 days. Alert immediately. A 1x burn rate is normal consumption.

**2025 trend -- Error Budgets 2.0:** AI-driven systems evaluate error budget status in real-time, automatically blocking or rolling back deployments. Traditional reactive workflows are being replaced by SLO-apprehensive deployment agents.

---

## 10. Compliance and Auditing

### SOC 2 Deployment Controls (CC8 — Change Management)

| Control | Implementation | Evidence |
|---------|---------------|----------|
| **Change authorization** | PR approvals, CODEOWNERS, branch protection | Git log, PR merge records |
| **Separation of duties** | Developers cannot approve own PRs or deploy own code | RBAC config, approval logs |
| **Testing before production** | CI pipeline gates, staging validation | Pipeline execution logs |
| **Rollback capability** | Documented rollback procedures, tested regularly | Rollback runbooks, drill records |
| **Change tracking** | All changes via Git, deployment audit logs | Git history, deployment platform logs |
| **Emergency changes** | Documented expedited process with after-the-fact review | Incident tickets, retrospective docs |

**2025 AWS SOC 2 guidance (July 2025):** Reframes compliance toward risk-based, evidence-driven assurance rather than checkbox compliance. Evidence must demonstrate controls operate continuously, not just at audit time.

### Compliance-as-Code

Policy engines enforce deployment standards automatically.

**Kyverno policy (block unverified images):**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: verify-cosign-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "ghcr.io/myorg/*"
      attestors:
      - entries:
        - keyless:
            subject: "https://github.com/myorg/*"
            issuer: "https://token.actions.githubusercontent.com"
```

**OPA/Gatekeeper vs. Kyverno (2025-2026):**

| Feature | OPA/Gatekeeper | Kyverno |
|---------|---------------|---------|
| **Policy language** | Rego (learning curve) | YAML or CEL (K8s-native) |
| **Mutation** | Limited | Full support |
| **Image verification** | Via external tools | Built-in cosign/Notary verification |
| **Generation** | Not supported | Generate resources from policies |
| **Latest (2026)** | Gatekeeper v3.22: ValidatingAdmissionPolicy alignment | Kyverno 1.17: CEL engine promoted to v1 |

### Deployment Approval Patterns

```
Developer -> PR (requires 1+ approvals via CODEOWNERS)
  -> CI passes (lint, test, security scan)
  -> Merge to main
  -> Auto-deploy to staging
  -> Staging validation
  -> Production deploy (requires separate approver group)
  -> Post-deploy verification
```

**No single identity can both create and promote a release.** Enforce via:
- GitHub CODEOWNERS + branch protection rules
- CI/CD platform approval gates (separate production approver group)
- Signed commits required for production branches

---

## 11. Deployment Strategy Selection Framework

### Decision Tree

```
START
  |
  v
Is this a library/API consumed by others?
  YES -> Use canary + SemVer versioning
  NO  -> Continue
  |
  v
Can you afford 2x infrastructure temporarily?
  YES -> Blue-green is simplest for zero-downtime
  NO  -> Rolling update (K8s default)
  |
  v
Do you need percentage-based traffic control?
  YES -> Canary with service mesh (Istio/Linkerd)
  NO  -> Blue-green or rolling is sufficient
  |
  v
Do you need to validate under real production load without risk?
  YES -> Shadow/dark launch first, then canary
  NO  -> Skip shadow
  |
  v
Do you need user-segment targeting (A/B)?
  YES -> Feature flags (LaunchDarkly/Statsig) + canary infra
  NO  -> Standard progressive delivery
  |
  v
Is this a regulated environment (SOC2, HIPAA, PCI)?
  YES -> Add approval gates, signed artifacts, audit trails
  NO  -> Standard pipeline gates
```

### Quick Reference by Team Size

| Team Size | Recommended Stack | Why |
|-----------|-------------------|-----|
| **1-5 engineers** | Rolling updates + feature flags (Unleash OSS) + trunk-based | Minimal overhead, fast iteration |
| **5-20 engineers** | Canary (Argo Rollouts) + ArgoCD + LaunchDarkly/Flagsmith + SemVer | Controlled rollouts, good visibility |
| **20-100 engineers** | Full progressive delivery + release trains + SLSA + compliance-as-code | Coordination, audit, governance |
| **100+ engineers** | Platform team providing deployment APIs + policy guardrails + SLO gating | Self-service with safety nets |

### Risk-Based Selection Matrix

| Risk Tolerance | Strategy | Feature Flags | Rollback | Monitoring |
|---------------|----------|---------------|----------|------------|
| **Low (fintech, healthcare)** | Blue-green + canary analysis | Required (kill switches) | Automated + manual gates | Real-time + error budget gating |
| **Medium (SaaS, e-commerce)** | Canary with progressive delivery | Recommended | Automated triggers | APM + canary metrics |
| **High (internal tools, dev)** | Rolling updates | Optional | `kubectl rollout undo` | Basic health checks |
