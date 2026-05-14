# Kubernetes Engineering — Deep Reference

**Always use `WebSearch` to verify current versions, release dates, and deprecation timelines before giving advice. The Kubernetes ecosystem evolves rapidly with three minor releases per year and a vast CNCF landscape.**

## Table of Contents
1. [Kubernetes Versions and Key Features](#1-kubernetes-versions-and-key-features)
2. [Helm — Package Management](#2-helm--package-management)
3. [Operators and Custom Controllers](#3-operators-and-custom-controllers)
4. [Service Mesh](#4-service-mesh)
5. [Autoscaling](#5-autoscaling)
6. [Networking](#6-networking)
7. [Storage](#7-storage)
8. [Security](#8-security)
9. [GitOps for Kubernetes](#9-gitops-for-kubernetes)
10. [Developer Experience](#10-developer-experience)
11. [Multi-Cluster Management](#11-multi-cluster-management)
12. [Observability](#12-observability)
13. [Cost Optimization](#13-cost-optimization)
14. [Managed Kubernetes Comparison](#14-managed-kubernetes-comparison)

---

## 1. Kubernetes Versions and Key Features

### Release Cadence

Three minor releases per year (~4 months apart). Each minor release supported ~14 months. The project maintains branches for the three most recent minor releases.

### Version Timeline

| Version | Release | Key Headlines |
|---------|---------|---------------|
| **1.32** | Dec 2024 | Custom resource field selectors (stable), dynamic memory-backed volume sizing, CEL mutating admission policies |
| **1.33** | Apr 2025 | Sidecar containers GA, in-place pod resize beta, DRA beta enabled, image volume type beta |
| **1.34** | Aug 2025 | DRA GA, kubelet tracing GA, swap support GA, ordered namespace deletion GA (58 enhancements) |
| **1.35** | Dec 2025 | In-place pod resize GA, gang scheduling alpha, image volume default-enabled |

### Feature Deep Dives

**Sidecar Containers (GA in 1.33):**
Init containers with `restartPolicy: Always`. Start before main containers, run for the entire pod lifecycle, terminate after main containers finish. Eliminates ordering hacks for logging agents, proxies, and vault sidecars.

```yaml
apiVersion: v1
kind: Pod
spec:
  initContainers:
    - name: log-shipper
      image: fluent/fluent-bit:3.2
      restartPolicy: Always          # This makes it a sidecar
      volumeMounts:
        - name: logs
          mountPath: /var/log/app
  containers:
    - name: app
      image: myapp:latest
      volumeMounts:
        - name: logs
          mountPath: /var/log/app
```

**In-Place Pod Resize (GA in 1.35):**
CPU and memory requests/limits are now mutable without pod restart. Graduated alpha (1.27) -> beta (1.33) -> stable (1.35). Memory limit decrease support added in 1.34.

**CEL for Admission (1.32+):**
Lightweight alternative to mutating admission webhooks. Declare mutations (setting labels, defaulting fields, injecting sidecars) in CEL expressions directly in API server config. No webhook infrastructure required.

**Dynamic Resource Allocation (GA in 1.34):**
Flexible framework for GPUs, FPGAs, and specialized hardware. Replaces device plugins for complex resource topologies. ResourceClaim status fields allow drivers to report device data (network interfaces, MAC/IP addresses).

---

## 2. Helm — Package Management

### Version Landscape

| Version | Status | Key Change |
|---------|--------|------------|
| **Helm 3.x** | Maintenance (dev-v3 branch) | Current 3.20.x, patches through 3.21 |
| **Helm 4.x** | Active (main branch) | Released Nov 2025 at KubeCon Atlanta, current 4.1.x |

### Helm 4 Breaking Changes

- **Server-Side Apply (SSA):** Replaces three-way merge. Use `--server-side` flag. Avoids conflicts between controllers managing the same resources.
- **WASM Plugin System:** Plugins optionally written in WASM for cross-OS/arch portability. Existing plugins continue to work.
- **Enhanced Chart API Framework:** Enables future chart features without breaking backwards compatibility.
- **Modern Kubernetes Only:** Targets recent K8s versions with SSA support.

### OCI Chart Distribution (GA since Helm 3.8+)

Store charts in container registries alongside images. Eliminates `index.yaml` scaling limitations. No extra plugins (cm-push) needed.

```bash
# Push chart to OCI registry
helm package ./my-chart
helm push my-chart-1.0.0.tgz oci://registry.example.com/charts

# Install from OCI
helm install my-release oci://registry.example.com/charts/my-chart --version 1.0.0
```

### Helmfile — Multi-Chart Orchestration

Declarative spec for deploying multiple Helm releases. Supports environment-specific values, dependency ordering, and diff previews via `helmfile diff`.

### Chart Testing and Secrets

- Use `helm test` with test hook pods in `templates/tests/` to validate deployments post-install.
- Use `helm-secrets` plugin with SOPS/age encryption. Never store plaintext secrets in chart repos.
- Run `helm lint` and `helm template` in CI before any deploy.

---

## 3. Operators and Custom Controllers

### Framework Comparison

| Framework | Language | Best For | Maturity |
|-----------|----------|----------|----------|
| **Kubebuilder** | Go | Pure Go operators, upstream K8s patterns | Production — kubernetes-sigs project |
| **Operator SDK** | Go/Ansible/Helm | Multi-language operators, Helm/Ansible wrapping | Production — uses Kubebuilder as library |
| **Metacontroller** | Any (webhook-based) | Lightweight controllers in any language | Stable — lambda controller pattern |
| **Crossplane** | Compositions (YAML) | Infrastructure-as-code via K8s API | CNCF Incubating — v2.2 current |

### Crossplane v2 (Aug 2025)

Major architectural shift:
- **Namespace-first approach** — composite resources and managed resources namespaced by default
- **Application support** — single YAML manifest deploys app + infrastructure together
- **Operation type** — declarative operational workflows
- AWS resources fully supported for namespaced mode; other providers following

### Notable Production Operators

| Operator | Purpose | Version | Notes |
|----------|---------|---------|-------|
| **CloudNativePG** | PostgreSQL on K8s | 1.29.0 | Revolutionized extension management via Image Catalogs |
| **Strimzi** | Apache Kafka on K8s | 0.51.0 | Requires K8s 1.30+, ingress listener deprecated (March 2026) |
| **Prometheus Operator** | Monitoring stack | kube-prometheus-stack | De facto standard for K8s metrics |

---

## 4. Service Mesh

### Comparison Matrix

| Feature | Istio (Ambient) | Linkerd 2.19 | Cilium Service Mesh |
|---------|----------------|--------------|---------------------|
| **Architecture** | ztunnel (L4) + waypoint (L7) | Ultra-light Rust proxy | eBPF kernel datapath |
| **P99 latency overhead** | ~8% at 3,200 RPS | 11.2ms lead over Istio at P99 | 40-60% less overhead than sidecars |
| **Control plane memory** | 1-2 GB (Istiod) | 200-300 MB | Embedded in cilium-agent |
| **Per-pod memory** | ~50 MB (Envoy) | 20-30 MB (linkerd2-proxy) | Zero (no sidecar) |
| **mTLS** | Yes (SPIFFE) | Yes (on by default) | Yes (WireGuard / IPsec) |
| **Gateway API** | Full support | Improved in 2.18 | Native 1.5 with GRPCRoute, CORS |
| **Multi-cluster** | Yes | GitOps-compatible (2.18) | ClusterMesh |
| **Windows support** | No | Beta (2.18), official (2.19) | No |
| **CNCF status** | Graduated | Graduated | Graduated |
| **Post-quantum crypto** | No | ML-KEM-768 default (2.19) | No |

### Decision Framework

- **Istio Ambient** — richest feature set, large ecosystem, higher resource cost. Choose when you need advanced traffic management, policy enforcement at scale.
- **Linkerd** — lowest overhead, simplest operations, smallest footprint. Choose for resource-constrained clusters, when latency matters most.
- **Cilium Service Mesh** — zero-sidecar eBPF approach, best for teams already using Cilium CNI. Choose when kernel-level networking performance is critical.

---

## 5. Autoscaling

### When to Use Each Autoscaler

| Autoscaler | Scales | Trigger | Best For |
|------------|--------|---------|----------|
| **HPA** | Pod replicas horizontally | CPU/memory/custom metrics | Stateless web services, API servers |
| **VPA** | Pod CPU/memory requests | Resource utilization history | Right-sizing long-running workloads |
| **KEDA** | Pod replicas (incl. to/from zero) | Event sources (queues, DBs, cron) | Event-driven workloads, batch jobs |
| **Cluster Autoscaler** | Nodes | Pending pods | Standard node scaling, node group-based |
| **Karpenter** | Nodes (any instance type) | Pending pods | Fast provisioning (<60s), spot optimization (AWS) |

### HPA with Container Metrics

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: ContainerResource
      containerResource:
        name: cpu
        container: api             # Target specific container
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

### KEDA Event-Driven Scaling

KEDA (CNCF Graduated) creates HPA resources behind the scenes. Scales to/from zero based on external event sources. Integrates with OpenTelemetry for observability.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-processor
spec:
  scaleTargetRef:
    name: order-processor
  minReplicaCount: 0              # Scale to zero when idle
  maxReplicaCount: 100
  triggers:
    - type: rabbitmq
      metadata:
        queueName: orders
        queueLength: "5"          # 1 pod per 5 messages
        host: amqp://rabbitmq.default.svc.cluster.local
```

### Karpenter v1.0+ (AWS)

Launched v1.0 in 2024 — all APIs stable. Provisions right-sized nodes in <60s. Supports spot instances, graviton, and GPU node classes. Use `NodePool` + `EC2NodeClass` CRDs.

**Recommended Stack:** HPA (CPU/memory) + KEDA (event-driven) + Karpenter (nodes). VPA in recommendation-only mode to inform HPA target values.

---

## 6. Networking

### CNI Comparison

| Feature | Cilium 1.17+ | Calico 3.31+ | Flannel |
|---------|-------------|--------------|---------|
| **Dataplane** | eBPF (kernel) | eBPF or iptables | VXLAN/host-gw |
| **NetworkPolicy** | K8s + Cilium extended (L3-L7) | K8s + Calico extended | K8s basic only |
| **Encryption** | WireGuard / IPsec | WireGuard | None native |
| **Service mesh** | Built-in (eBPF) | No (integrates with Istio) | No |
| **Gateway API** | Native 1.5 support | Via Envoy Gateway | No |
| **Bandwidth management** | EDT-based, eBPF | tc-based | No |
| **Observability** | Hubble (L3-L7 flow visibility) | Flow logs | None |
| **Multi-cluster** | ClusterMesh | Federation via Typha | No |
| **Best for** | Modern clusters, eBPF-native | Hybrid (eBPF or iptables fallback) | Simple clusters, k3s default |

### Gateway API vs Ingress

Gateway API (v1.4 GA, Oct 2025) is the successor to Ingress. Use Gateway API for all new deployments.

| Aspect | Ingress | Gateway API v1.4+ |
|--------|---------|-------------------|
| **Role separation** | Single resource | GatewayClass / Gateway / HTTPRoute (infra vs app teams) |
| **Protocols** | HTTP/HTTPS only | HTTP, gRPC, TCP, UDP, TLS |
| **Traffic features** | Basic path/host routing | Mirrors, rewrites, CORS, retry budgets, header mods |
| **Backend TLS** | Implementation-specific | BackendTLSPolicy (standard) |
| **Mesh support** | No | Experimental Mesh resource (v1.4) |

### NetworkPolicy Example

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: production
spec:
  podSelector:
    matchLabels: { app: api-server }
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - namespaceSelector: { matchLabels: { purpose: frontend } }
      ports: [{ protocol: TCP, port: 8080 }]
  egress:
    - to:
        - namespaceSelector: { matchLabels: { purpose: data } }
      ports: [{ protocol: TCP, port: 5432 }]
    - to: [{ namespaceSelector: {} }]   # DNS
      ports: [{ protocol: UDP, port: 53 }]
```

---

## 7. Storage

### CSI Drivers and Storage Solutions

| Solution | Type | Performance | Best For |
|----------|------|-------------|----------|
| **Rook-Ceph** | Block (RBD), File (CephFS), Object (RGW) | High (distributed) | Enterprise, multi-protocol, large-scale |
| **Longhorn** | Block (replicated) | Good | Small-medium clusters, k3s, simplicity |
| **OpenEBS** | Block (Mayastor NVMe, cStor) | Mayastor: high, cStor: moderate | Mixed workloads, NVMe-optimized |
| **Cloud CSI** | EBS/PD/Azure Disk | Native performance | Managed K8s, no operational overhead |

### StatefulSet Storage Pattern

Use `volumeClaimTemplates` in StatefulSets for per-replica persistent storage. Each pod gets its own PVC (e.g., `data-postgres-0`, `data-postgres-1`). Always specify `storageClassName` explicitly and set `accessModes: ["ReadWriteOnce"]` for database workloads.

### Storage Decision Guide

- **Managed K8s + cloud disks** — default choice, lowest operational overhead
- **Rook-Ceph** — when you need multi-protocol (block + file + object) or bare-metal clusters
- **Longhorn** — when you want simplicity on k3s/edge or clusters under 50 nodes
- **OpenEBS Mayastor** — when NVMe-optimized block storage is the priority

---

## 8. Security

### Pod Security Standards (PSS) and Admission (PSA)

Three levels enforced per namespace via labels:

| Level | What It Blocks | Use Case |
|-------|---------------|----------|
| **Privileged** | Nothing | System namespaces (kube-system) |
| **Baseline** | Known privilege escalations (hostNetwork, hostPID, privileged containers) | General workloads |
| **Restricted** | Non-root, no capabilities, read-only root FS, seccomp required | Sensitive workloads |

```yaml
# Enforce restricted PSS on a namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

### Kyverno vs OPA/Gatekeeper

| Aspect | Kyverno | OPA/Gatekeeper |
|--------|---------|----------------|
| **Policy language** | YAML (K8s-native) | Rego (general-purpose) |
| **Learning curve** | Low — if you know K8s manifests | High — Rego is a new language |
| **CNCF status** | Incubating | OPA is Graduated |
| **Generate resources** | Yes (ConfigMaps, NetworkPolicies) | No |
| **Mutate resources** | Yes (native) | Yes (with mutation feature) |
| **Image verification** | Built-in (Cosign, Notary) | Requires external webhook |
| **Best for** | K8s-only policy, teams wanting YAML | Complex cross-system policy, existing OPA investment |

### Kyverno Policy Example

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-limits
      match:
        any:
          - resources:
              kinds: ["Pod"]
      validate:
        message: "CPU and memory limits are required."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

### Falco Runtime Security

CNCF Graduated (2024). Latest: v0.43.0 (Jan 2026). Uses eBPF to detect anomalous syscalls, container escapes, and crypto-mining in real time. Under 1% CPU overhead.

### Secret Management Comparison

| Tool | Approach | GitOps-Safe | Auto Rotation | Complexity |
|------|----------|-------------|---------------|------------|
| **External Secrets Operator** | Sync from Vault/AWS SM/GCP SM | Yes | Depends on provider | Medium |
| **Sealed Secrets** | Encrypt in Git, decrypt in cluster | Yes | No | Low |
| **Vault CSI Provider** | Mount secrets as volumes | Yes | Yes (Vault-managed) | High |

Recommendation for 2026: External Secrets Operator as primary, with Vault as the backing store. Sealed Secrets only for simple setups being migrated.

---

## 9. GitOps for Kubernetes

### ArgoCD vs Flux Comparison

| Aspect | Argo CD 3.x | Flux CD v2 |
|--------|-------------|------------|
| **Architecture** | Centralized, UI + API server + Redis | Distributed, Git-native controllers |
| **UI** | Built-in web dashboard | None (Weave GitOps or third-party) |
| **Resource usage** | ~2x Flux (maintains app graph in memory) | Lighter footprint |
| **Adoption** | 60% of K8s clusters (CNCF 2025 survey), 97% in production | Microsoft-backed, strong Flux ecosystem |
| **OCI support** | Native (3.1+) | Native |
| **Multi-tenancy** | Projects + RBAC | Namespaced controllers |
| **Backed by** | AWS, Intuit, Red Hat | Microsoft, Weaveworks |

### Argo CD 3.x Timeline

| Version | Release | Headlines |
|---------|---------|-----------|
| **3.0** | Early 2025 | Fine-grained RBAC (resource-level), improved secrets management |
| **3.1** | Aug 2025 | Native OCI registry support, CLI plugins, Source Hydrator |
| **3.2** | Nov 2025 | ApplicationSet pprof profiling, sync deletion prevention |
| **3.3** | Early 2026 | Safer GitOps deletions, lifecycle completion |

### ApplicationSets

Template multiple Applications from a single spec. Generators: Git directory, Git file, cluster, list, pull request, matrix, merge.

### Progressive Delivery

| Tool | Engine | Strategies | Best With |
|------|--------|------------|-----------|
| **Argo Rollouts** | Standalone controller | Canary, Blue-Green, analysis runs | ArgoCD ecosystem |
| **Flagger** | Mesh-integrated | Canary, A/B, Blue-Green | Flux + Istio/Linkerd/Contour |

---

## 10. Developer Experience

### Local Kubernetes Tools

| Tool | Mechanism | Speed | K8s Conformance | Best For |
|------|-----------|-------|-----------------|----------|
| **kind** | K8s-in-Docker | Fast | Full conformance | CI/CD testing, conformance validation |
| **k3d** | k3s-in-Docker | Fastest | Lightweight (k3s) | Daily development, quick iteration |
| **minikube** | VM or Docker | Moderate | Full conformance | Beginners, full-feature local cluster |

### Inner-Loop Development Tools

| Tool | Approach | Hot Reload | Key Feature |
|------|----------|------------|-------------|
| **Telepresence** | Route cluster traffic to local | Yes (no container build) | Debug with local IDE, access cluster services |
| **Tilt** | Watch + build + deploy | Yes (on file change) | Web UI with build status, logs, service health |
| **Skaffold** | File watch -> build -> deploy | Yes | Pipeline automation, GCP integration |
| **DevSpace** | Sync + dev containers | Yes | File sync to running pods, port forwarding |

### vCluster — Virtual Clusters

Lightweight virtual K8s clusters inside existing clusters. Isolate dev/test without provisioning real clusters. 2025-2026: Private Nodes (hardware isolation), Auto Nodes (Karpenter-backed), GPU reference architecture, virtual container runtimes.

---

## 11. Multi-Cluster Management

### Tool Comparison

| Tool | Approach | CNCF Status | Best For |
|------|----------|-------------|----------|
| **Karmada** | Control plane federation (K8s API compatible) | Incubating | Multi-cloud workload propagation, cross-cluster failover |
| **Liqo** | Peer-to-peer cluster federation | Sandbox | Resource sharing across clusters |
| **Admiralty** | Cross-cluster scheduling controllers | -- | Spreading jobs/deployments across clusters |
| **Clusternet** | Hub-spoke with network tunnels | Sandbox | Managing thousands of edge/hybrid clusters |

### Karmada v1.15 (Oct 2025)

- Precise resource awareness for multi-template workloads
- Enhanced cluster-level failover
- Structured logging
- Significant performance improvements for controllers and schedulers

### Multi-Cluster Networking

| Solution | Layer | Throughput | Latency | Architecture |
|----------|-------|------------|---------|--------------|
| **Istio multi-cluster** | L7 | ~15 Gbps | Highest | Shared control plane or mesh federation |
| **Submariner** | L3 (VPN tunnels) | ~2.6 Gbps | Lowest | Gateway nodes with encrypted tunnels |
| **Skupper** | L7 (VAN) | ~8 Gbps | Moderate | Application-layer routers, no VPN |
| **Cilium ClusterMesh** | L3/L4 (eBPF) | Near-native | Low | Direct pod-to-pod across clusters |

---

## 12. Observability

### Recommended Stack (2026)

The production-proven observability stack for Kubernetes:

| Layer | Tool | Purpose |
|-------|------|---------|
| **Metrics** | Prometheus + Thanos/Mimir | Time-series metrics, alerting, long-term storage |
| **Logs** | Grafana Loki | Log aggregation (label-indexed, not full-text) |
| **Traces** | Grafana Tempo | Distributed tracing (100% trace sampling) |
| **Collection** | OpenTelemetry Collector | Vendor-neutral telemetry pipeline |
| **Visualization** | Grafana | Unified dashboards |
| **eBPF observability** | Pixie / Hubble / Beyla | Zero-instrumentation network + app visibility |

### OpenTelemetry Operator

Manages OTel Collectors and auto-instrumentation. Requires cert-manager for webhook TLS. 48.5% of orgs already using OTel (2025 Apica survey). 84% who adopted OTel saw 10%+ cost reduction.

### eBPF Observability (2026 Standard)

Under 1% CPU overhead. No sidecars or SDK changes needed. Production stack: Cilium + Hubble (network), Pixie (APM traces), Tetragon (security), Grafana Beyla (OTel spans). All are CNCF projects.

---

## 13. Cost Optimization

### Kubecost vs OpenCost

| Aspect | OpenCost | Kubecost |
|--------|----------|----------|
| **License** | Open source (CNCF Sandbox) | Enterprise (built on OpenCost) |
| **Pricing accuracy** | List prices only | RI, savings plans, spot, credits reconciled |
| **Recommendations** | No automation | Right-sizing, cluster optimization |
| **Multi-cluster** | Limited | Full aggregation |
| **Alerts** | Basic | Budget alerts, anomaly detection |

### Cost Reduction Strategies

**Spot / Preemptible Instances:**
Use Karpenter `NodePool` with spot priority. Run stateless workloads on spot, stateful on on-demand. Typical savings: 60-90% over on-demand.

**Right-Sizing:**
Use VPA in recommendation mode. Set requests = P95 utilization, limits = 2x requests. Implement LimitRanges per namespace to prevent unbounded resource claims.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      max:
        cpu: "4"
        memory: "8Gi"
```

**Resource Quotas:**
Enforce namespace-level budgets. Prevent any single team from consuming the entire cluster.

---

## 14. Managed Kubernetes Comparison

### Feature Matrix (2026)

| Feature | EKS (AWS) | GKE (Google) | AKS (Azure) |
|---------|-----------|-------------|-------------|
| **Version lag** | ~2-3 months | ~1-2 months (fastest) | ~2-3 months |
| **Control plane SLA** | 99.95% (uptime) | 99.95% (regional) | 99.95% (with zones) |
| **Node autoscaler** | Karpenter (native) | GKE Autopilot / NAP | KEDA + Cluster Autoscaler |
| **Serverless pods** | Fargate | Autopilot mode | Virtual Nodes (ACI) |
| **Service mesh** | App Mesh (deprecated) -> Istio | Anthos Service Mesh (Istio) | Istio-based or Open Service Mesh (deprecated) |
| **GitOps** | ArgoCD (via EKS Blueprints) | Config Sync (Flux-based) | Flux (Arc extension) |
| **GPU support** | P5/P4, Inferentia, Trainium | A3/A2, TPUs | NDm v4, A100, H100 |
| **Cost management** | Kubecost integration, split cost allocation tags | GKE cost allocation | Cost analysis in portal |
| **Networking** | VPC CNI (Cilium option) | Dataplane V2 (Cilium) | Azure CNI (Cilium overlay option) |
| **Windows nodes** | Supported | Supported | Supported |
| **Managed add-ons** | EKS Add-ons (CoreDNS, kube-proxy, VPC CNI) | GKE managed components | AKS extensions marketplace |
| **Multi-cluster** | EKS Connector | GKE Fleet / Anthos | Azure Arc |

### Decision Framework

- **EKS** — best for AWS-native teams. Karpenter is the standout feature for node management. Deepest AWS service integrations (IAM roles for service accounts, App Mesh -> Istio migration).
- **GKE** — fastest K8s version adoption, best Autopilot experience (true serverless K8s). Dataplane V2 (Cilium) by default. Best for teams wanting least operational overhead.
- **AKS** — best Azure integration, strong Flux-based GitOps via Arc. Good for enterprises already on Azure with AD/Entra ID requirements.
