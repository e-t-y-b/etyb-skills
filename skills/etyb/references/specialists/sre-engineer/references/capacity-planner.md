# Capacity Planning & Cost Optimization — Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Auto-Scaling Strategies](#1-auto-scaling-strategies)
2. [Resource Right-Sizing](#2-resource-right-sizing)
3. [Load Testing & Capacity Modeling](#3-load-testing--capacity-modeling)
4. [FinOps & Cloud Cost Optimization](#4-finops--cloud-cost-optimization)
5. [Reserved Capacity & Spot Instances](#5-reserved-capacity--spot-instances)
6. [Kubernetes Cost Optimization](#6-kubernetes-cost-optimization)
7. [Database & Storage Capacity](#7-database--storage-capacity)
8. [Capacity Planning Process](#8-capacity-planning-process)
9. [CDN & Edge Capacity](#9-cdn--edge-capacity)
10. [Cost Monitoring & Reporting](#10-cost-monitoring--reporting)

---

## 1. Auto-Scaling Strategies

### Kubernetes Horizontal Pod Autoscaler (HPA)

HPA scales the number of pod replicas based on observed metrics. About 64% of organizations use HPA, but only 20% scale on custom metrics — most still rely on CPU alone, which is rarely the best signal.

**CPU/Memory Scaling (baseline):**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server
  namespace: production
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
          averageUtilization: 65
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 75
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
        - type: Pods
          value: 5
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 120
      selectPolicy: Min
```

**Custom Metrics HPA (production pattern):**

Work metrics (queue depth, request rate, tail latency) are leading indicators that reflect real-time activity. CPU is a lagging indicator — by the time CPU spikes, users are already degraded.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-processor
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-processor
  minReplicas: 2
  maxReplicas: 30
  metrics:
    # Primary: scale on queue depth per replica
    - type: Pods
      pods:
        metric:
          name: kafka_consumer_lag
        target:
          type: AverageValue
          averageValue: "100"
    # Secondary: scale on p99 latency via Prometheus adapter
    - type: Object
      object:
        describedObject:
          apiVersion: v1
          kind: Service
          name: order-processor
        metric:
          name: http_request_duration_p99
        target:
          type: Value
          value: "500m"   # 500ms
    # Safety net: CPU as a backstop
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30    # React fast to load spikes
      policies:
        - type: Percent
          value: 100
          periodSeconds: 30
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 600   # 10 min window prevents flapping
      policies:
        - type: Percent
          value: 10
          periodSeconds: 120
      selectPolicy: Min
```

**Scaling Behavior Tuning — Key Principles:**

| Parameter | Purpose | Guidance |
|-----------|---------|----------|
| `scaleUp.stabilizationWindowSeconds` | Delay before scaling up | 0-60s for latency-sensitive services, 120-300s for batch |
| `scaleDown.stabilizationWindowSeconds` | Delay before scaling down | 300-600s minimum — premature scale-down causes oscillation |
| `scaleUp.selectPolicy: Max` | Pick the policy that adds the most replicas | Use for aggressive scale-up |
| `scaleDown.selectPolicy: Min` | Pick the policy that removes the fewest replicas | Use for conservative scale-down |

**Multi-metric behavior:** When multiple metrics are defined, HPA calculates the desired replica count for each metric and uses the **highest** value. This means your primary scaling metric drives up, but a safety-net metric (like CPU) can also trigger scaling if the primary is quiet but resource pressure is high.

### Vertical Pod Autoscaler (VPA)

VPA adjusts container resource requests and limits based on observed usage. It has three components: the recommender (analyzes usage and generates recommendations), the updater (evicts pods to apply new resource values), and the admission controller webhook (applies recommendations to new pods).

**Update Modes:**

| Mode | Behavior | Pod Restart? | Use Case |
|------|----------|-------------|----------|
| **Off** | Recommendations only, no changes applied | No | Production observation; feed data to dashboards or Goldilocks |
| **Initial** | Sets resources only at pod creation time | Only on new pods | Low-risk adoption; new pods get right-sized, existing ones untouched |
| **Recreate** | Evicts and recreates pods when resources drift significantly | Yes (eviction) | Standard production use; respects PodDisruptionBudgets |
| **InPlaceOrRecreate** | Uses in-place resize (Kubernetes 1.33+ beta, 1.35 GA); falls back to eviction | Minimal (in-place preferred) | Preferred on Kubernetes 1.33+; avoids unnecessary restarts |

**Note:** The `Auto` mode is deprecated. Use explicit modes instead.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-server-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  updatePolicy:
    updateMode: "Off"               # Start in Off mode; review recommendations first
  resourcePolicy:
    containerPolicies:
      - containerName: api-server
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 4
          memory: 8Gi
        controlledResources: ["cpu", "memory"]
        controlledValues: RequestsOnly   # Only adjust requests, not limits
      - containerName: sidecar-proxy
        mode: "Off"                # Do not touch sidecar resources
```

**VPA and HPA Together — The Conflict:**

VPA and HPA both try to adjust pods, and they can fight each other. Safe patterns:

- **VPA on CPU/memory + HPA on custom metrics only**: VPA right-sizes resources; HPA scales on queue depth, request rate, or latency (not CPU/memory). This is the recommended pattern.
- **VPA in Off mode + HPA on everything**: Use VPA purely for visibility; feed recommendations into a human review process.
- **KEDA replaces both**: KEDA handles scaling replicas based on external events; pair with VPA in Off mode for right-sizing recommendations.

### KEDA (Kubernetes Event-Driven Autoscaling)

KEDA is a CNCF graduated project with 65+ scalers. It extends HPA by exposing external event sources (message queues, databases, cloud services) through the Kubernetes External Metrics API. The current version is 2.17/2.18 with 2.19 in development.

**KEDA Architecture:**

```
                 ┌──────────────────┐
                 │   Event Source    │   (Kafka, SQS, Prometheus, etc.)
                 └────────┬─────────┘
                          │ poll/subscribe
                 ┌────────▼─────────┐
                 │   KEDA Operator  │
                 │   (Metrics Svr)  │
                 └────────┬─────────┘
                          │ external metrics API
                 ┌────────▼─────────┐
                 │   Kubernetes HPA │
                 └────────┬─────────┘
                          │ scale
                 ┌────────▼─────────┐
                 │   Deployment     │
                 └──────────────────┘
```

**Kafka Consumer Lag Scaler:**

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-processor
  namespace: production
spec:
  scaleTargetRef:
    name: order-processor
  pollingInterval: 15
  cooldownPeriod: 300
  idleReplicaCount: 0             # Scale to zero when idle
  minReplicaCount: 0
  maxReplicaCount: 50
  fallback:
    failureThreshold: 3
    replicas: 5                   # Fallback replicas if scaler fails
  triggers:
    - type: kafka
      metadata:
        bootstrapServers: kafka-headless.kafka:9092
        consumerGroup: order-processor-group
        topic: orders
        lagThreshold: "100"       # Scale when lag > 100 messages per partition
        activationLagThreshold: "10"  # Activate from zero at lag > 10
        offsetResetPolicy: latest
      authenticationRef:
        name: kafka-credentials
```

**AWS SQS Scaler:**

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: sqs-worker
  namespace: production
spec:
  scaleTargetRef:
    name: sqs-worker
  pollingInterval: 10
  cooldownPeriod: 120
  minReplicaCount: 0
  maxReplicaCount: 100
  triggers:
    - type: aws-sqs-queue
      metadata:
        queueURL: https://sqs.us-east-1.amazonaws.com/123456789/orders-queue
        queueLength: "5"              # Target messages per replica
        activationQueueLength: "1"    # Wake from zero
        awsRegion: us-east-1
        scaleOnInFlight: "true"       # Include in-flight messages
      authenticationRef:
        name: aws-credentials
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: aws-credentials
  namespace: production
spec:
  podIdentity:
    provider: aws-eks                 # Use IRSA (IAM Roles for Service Accounts)
```

**Prometheus Scaler (scale on business metrics):**

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: web-frontend
  namespace: production
spec:
  scaleTargetRef:
    name: web-frontend
  pollingInterval: 15
  cooldownPeriod: 300
  minReplicaCount: 3
  maxReplicaCount: 40
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="web-frontend", namespace="production"}[2m]))
        threshold: "200"              # Scale when total RPS > 200 per replica
        activationThreshold: "5"
```

**Cron Scaler (predictive pre-scaling):**

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: api-presale
  namespace: production
spec:
  scaleTargetRef:
    name: api-server
  minReplicaCount: 3
  maxReplicaCount: 60
  triggers:
    # Pre-scale for known peak hours (business hours US Eastern)
    - type: cron
      metadata:
        timezone: America/New_York
        start: "0 8 * * 1-5"         # Mon-Fri 8 AM
        end: "0 20 * * 1-5"          # Mon-Fri 8 PM
        desiredReplicas: "15"
    # Normal off-hours
    - type: cron
      metadata:
        timezone: America/New_York
        start: "0 20 * * 1-5"
        end: "0 8 * * 2-6"
        desiredReplicas: "5"
    # Additional dynamic scaling via Prometheus
    - type: prometheus
      metadata:
        serverAddress: http://prometheus.monitoring:9090
        query: sum(rate(http_requests_total{service="api-server"}[2m]))
        threshold: "150"
```

### Karpenter (Node Provisioning)

Karpenter provisions right-sized compute nodes in response to unschedulable pods. Unlike Cluster Autoscaler (which relies on predefined node groups/ASGs), Karpenter makes direct cloud API calls, evaluating pod requirements and selecting optimal instance types in real time. Karpenter is now the preferred autoscaler over Cluster Autoscaler, with Salesforce migrating 1,000+ EKS clusters. Karpenter v1.5 (July 2025) introduced faster bin-packing, new disruption metrics, and "emptiness-first" consolidation.

**Cluster Autoscaler vs Karpenter:**

| Capability | Cluster Autoscaler | Karpenter |
|-----------|-------------------|-----------|
| Scaling model | Scales predefined node groups (ASGs/MIGs) | Provisions individual nodes on demand |
| Instance selection | Limited to instances in the node group | Evaluates 100+ instance types per scheduling decision |
| Bin-packing | Basic; constrained by node group definition | Advanced; selects optimal instance for pending pods |
| Scale-up latency | 3-4 min (ASG spin-up) | ~55 sec (direct API provisioning) |
| Spot handling | Manual ASG configuration per pool | Native Spot integration with automatic fallback |
| Consolidation | None (over-provisioning is common) | Active consolidation — replaces underutilized nodes |
| Multi-cloud | AWS, GCP, Azure | GA on AWS; beta on GCP, Azure, and CAPI |
| Cost savings | Baseline | 25-40% from bin-packing alone; double with Spot |

**NodePool Configuration (Karpenter v1):**

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: general-purpose
spec:
  template:
    metadata:
      labels:
        team: platform
        workload-type: general
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand", "spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]           # Compute, general, memory-optimized
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]                      # Only 6th gen+ (Graviton3, etc.)
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values: ["medium", "large", "xlarge", "2xlarge"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      expireAfter: 720h                     # 30-day max node lifetime
  limits:
    cpu: "1000"                             # Max 1000 vCPUs across all nodes in this pool
    memory: 2000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 60s                   # Consolidate quickly
  weight: 50                                # Priority vs other NodePools (higher = preferred)
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: KarpenterNodeRole-production        # IAM role for nodes
  amiSelectorTerms:
    - alias: al2023@latest                  # Amazon Linux 2023
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: production-cluster
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: production-cluster
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        iops: 5000
        throughput: 250
        encrypted: true
        deleteOnTermination: true
  tags:
    Environment: production
    ManagedBy: karpenter
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 1              # IMDSv2 only
    httpTokens: required                    # Enforce IMDSv2
```

**Spot-Optimized NodePool:**

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: spot-workers
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      taints:
        - key: capacity-type
          value: spot
          effect: NoSchedule              # Only pods that tolerate spot land here
  limits:
    cpu: "500"
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
  weight: 100                              # Prefer spot over on-demand
```

**Production tip:** Pin tested AMI versions in production clusters. Using `@latest` risks deploying untested AMIs. In non-production environments, `@latest` is acceptable for catching upstream changes early.

### Cloud-Native Autoscalers

| Service | Provider | Scaling Signal | Use Case |
|---------|----------|---------------|----------|
| **EC2 Auto Scaling** | AWS | Target tracking, step, simple, predictive | Legacy EC2 workloads, non-Kubernetes |
| **Managed Instance Groups** | GCP | CPU, LB, Pub/Sub, custom metrics | GCE-based workloads |
| **VM Scale Sets** | Azure | CPU, memory, custom metrics | Azure VM workloads |
| **Fargate Auto Scaling** | AWS | Target tracking on ECS metrics | Serverless container scaling |
| **Cloud Run** | GCP | Concurrency, CPU utilization | Serverless container scaling |

**Predictive Scaling (AWS):**

AWS Predictive Scaling uses ML to forecast load and pre-provision capacity. Enable it alongside reactive policies:

- Analyzes 14 days of historical data to build forecasting models
- Pre-scales 5 minutes before predicted load increase
- Works as a ceiling — reactive policies can still trigger if actual load exceeds prediction
- Best for workloads with recurring patterns (business-hours traffic, daily batch jobs)

Combine predictive scaling with KEDA cron triggers for Kubernetes workloads that have known traffic patterns.

---

## 2. Resource Right-Sizing

### The Requests and Limits Model

| Setting | Purpose | Impact if Too Low | Impact if Too High |
|---------|---------|-------------------|--------------------|
| **Requests** | Guaranteed resources; scheduler uses for placement | Pod eviction under pressure, throttling | Wasted capacity, poor bin-packing |
| **Limits** | Maximum resources; enforced by cgroup/kubelet | N/A (no limit = use whatever is available) | OOMKill if memory limit hit; CPU throttled at limit |

**The mental model:** Requests = what you need to function. Limits = what you tolerate before being dangerous to neighbors.

**Production rules of thumb:**

```
CPU requests:    p95 of actual usage over 7 days
CPU limits:      2-4x requests (or omit for non-noisy-neighbor environments)
Memory requests: p99 of actual usage over 7 days + 15% headroom
Memory limits:   1.2-1.5x requests (OOMKill is worse than throttle)
```

**Why CPU limits are controversial:** CPU limits cause throttling even when the node has spare CPU. Many production teams (including Google's internal guidance) recommend setting CPU requests but **not** CPU limits for non-burst workloads. Memory limits should always be set because memory is incompressible — an OOM situation affects the entire node.

### Pod Quality of Service Classes

| QoS Class | Condition | Eviction Priority | Use Case |
|-----------|-----------|-------------------|----------|
| **Guaranteed** | Requests == Limits for all containers | Last to be evicted | Latency-sensitive, critical services |
| **Burstable** | Requests < Limits (or limits set for some resources) | Middle priority | Most production workloads |
| **BestEffort** | No requests or limits set | First to be evicted | Development, batch jobs, non-critical workers |

**Recommendation:** Most production services should be **Burstable** with well-tuned requests. Only set Guaranteed for services where any resource contention is unacceptable (payment processing, real-time trading).

### Right-Sizing Tools

**Goldilocks (open source, by Fairwinds):**

Goldilocks deploys VPA in `Off` mode for every deployment in a namespace, then surfaces recommendations in a dashboard. It is the best starting point for organizations beginning their right-sizing journey. Typical savings: 30-50% on overprovisioned resources.

```bash
# Install Goldilocks
helm repo add fairwinds-stable https://charts.fairwinds.com/stable
helm install goldilocks fairwinds-stable/goldilocks \
  --namespace goldilocks --create-namespace

# Enable for a namespace
kubectl label namespace production goldilocks.fairwinds.com/enabled=true

# Access the dashboard
kubectl port-forward -n goldilocks svc/goldilocks-dashboard 8080:80
```

**Kubecost:**

Kubecost (built on OpenCost) provides Kubernetes cost allocation and right-sizing recommendations. Kubecost 3.0 expanded beyond Kubernetes to cover cloud service costs with budgets, forecasting, and anomaly detection.

```bash
# Install Kubecost
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm install kubecost kubecost/cost-analyzer \
  --namespace kubecost --create-namespace \
  --set kubecostToken="YOUR_TOKEN" \
  --set prometheus.server.global.external_labels.cluster_id="production"
```

**CAST AI:**

CAST AI uses ML to rebalance Kubernetes workloads, achieving 50-70% cost reductions via spot instance management, automated right-sizing, and intelligent bin-packing. Particularly effective for multi-cloud environments. A media streaming service reported 60% GKE cost reduction.

**Datadog Resource Optimization:**

Datadog's container resource optimization provides right-sizing recommendations directly in the Datadog UI, correlated with application performance data. Useful when Datadog is already the observability platform.

### Right-Sizing Decision Framework

```
1. Deploy VPA in Off mode (or Goldilocks) for all namespaces
2. Collect 7-14 days of usage data during normal AND peak traffic
3. Review recommendations:
   - CPU: Set requests to p95 of observed usage
   - Memory: Set requests to p99 of observed usage + 15% headroom
4. Apply changes incrementally — start with dev/staging
5. Monitor for 48 hours after each change
6. Iterate quarterly (traffic patterns shift)
```

### Over-Provisioning vs Under-Provisioning Tradeoffs

| Scenario | Risk | Cost | Mitigation |
|----------|------|------|------------|
| Over-provisioned CPU | Wasted spend, poor bin-packing | $$$$ | VPA recommendations, Goldilocks |
| Under-provisioned CPU | Throttling, increased latency | $ | CPU throttling alerts, load testing |
| Over-provisioned memory | Wasted spend | $$$ | VPA recommendations |
| Under-provisioned memory | OOMKills, pod restarts, data loss | $$ | Memory usage alerts, always set memory limits |

The cost of under-provisioned memory is higher than under-provisioned CPU because memory pressure causes OOMKills (data loss, connection drops) while CPU pressure causes throttling (slower but still functional).

---

## 3. Load Testing & Capacity Modeling

### Tool Selection Matrix

| Tool | Language | Strengths | Weaknesses | Best For |
|------|----------|-----------|------------|----------|
| **k6** | JavaScript/TypeScript | Low resource footprint, excellent CI/CD integration, k6 Operator for K8s (GA Sept 2025), built-in metrics | No browser rendering in OSS, requires JS knowledge | API load testing, CI/CD pipelines, K8s-native testing |
| **Locust** | Python | Python extensibility, distributed by default, easy custom logic, import any Python library | Higher resource consumption per VU, less CI/CD tooling | Python-native teams, complex user behavior modeling |
| **Gatling** | Scala/Java | Excellent HTML reports, very high concurrency (Akka-based), strong for JVM shops | Steep learning curve (Scala DSL), enterprise features behind paywall | JVM teams, high-concurrency scenarios, detailed reporting |
| **Artillery** | YAML/JavaScript | Simple YAML config, good for quick tests, scenario-based | Less flexible for complex scenarios, newer ecosystem | Quick API validation, scenario-based testing |
| **JMeter** | GUI/XML | Most feature-complete, huge plugin ecosystem, wide adoption | Resource-heavy, dated UI, XML config is unwieldy | Teams with existing JMeter expertise, protocol diversity |

**Recommendation:** k6 for most teams. Locust if the team is Python-native. Gatling for JVM shops needing high concurrency. Start with open source; use enterprise tooling only for pre-production compliance validation.

**Note on tool variance:** Running identical tests across tools produces 10-20% variance in results because each tool measures different slices of the request lifecycle. Pick one tool and standardize.

### k6 Load Test Script (Production Pattern)

```javascript
// load-test.js — API capacity validation
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const orderLatency = new Trend('order_latency', true);
const ordersCreated = new Counter('orders_created');

// Test configuration with multiple stages
export const options = {
  scenarios: {
    // Ramp-up test: validate scaling behavior
    ramp_up: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 50 },    // Warm up
        { duration: '5m', target: 200 },   // Ramp to expected peak
        { duration: '10m', target: 200 },  // Steady state at peak
        { duration: '2m', target: 400 },   // Spike beyond peak (2x)
        { duration: '5m', target: 400 },   // Sustain spike
        { duration: '3m', target: 0 },     // Cool down
      ],
      gracefulRampDown: '30s',
    },
    // Soak test: detect memory leaks and degradation (run separately)
    // soak: {
    //   executor: 'constant-vus',
    //   vus: 100,
    //   duration: '4h',
    // },
  },
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1500'],   // SLA targets
    errors: ['rate<0.01'],                              // <1% error rate
    http_req_failed: ['rate<0.01'],
    order_latency: ['p(95)<800'],
  },
  // Output to Prometheus for correlation with production metrics
  // Run with: k6 run --out experimental-prometheus-rw load-test.js
};

const BASE_URL = __ENV.BASE_URL || 'https://api-staging.example.com';
const API_KEY = __ENV.API_KEY;

export function setup() {
  // Seed test data, get auth tokens
  const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
    email: 'loadtest@example.com',
    password: __ENV.TEST_PASSWORD,
  }), { headers: { 'Content-Type': 'application/json' } });

  check(loginRes, { 'login succeeded': (r) => r.status === 200 });
  return { token: loginRes.json('access_token') };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.token}`,
  };

  group('Browse Products', () => {
    const catalog = http.get(`${BASE_URL}/products?page=1&limit=20`, { headers });
    check(catalog, {
      'catalog 200': (r) => r.status === 200,
      'has products': (r) => r.json('data').length > 0,
    });
    errorRate.add(catalog.status !== 200);
    sleep(Math.random() * 2 + 1);    // Realistic think time: 1-3s
  });

  group('Create Order', () => {
    const start = Date.now();
    const order = http.post(`${BASE_URL}/orders`, JSON.stringify({
      items: [{ sku: 'PROD-001', quantity: 1 }],
    }), { headers });

    const duration = Date.now() - start;
    orderLatency.add(duration);

    const success = check(order, {
      'order created': (r) => r.status === 201,
      'order has id': (r) => r.json('id') !== undefined,
    });

    if (success) ordersCreated.add(1);
    errorRate.add(order.status !== 201);
    sleep(Math.random() * 3 + 2);    // 2-5s think time
  });
}

export function teardown(data) {
  // Clean up test data if needed
  console.log(`Test complete. Orders created: ${ordersCreated}`);
}
```

### Load Test Design Patterns

| Pattern | Duration | Goal | When to Run |
|---------|----------|------|-------------|
| **Smoke** | 1-2 min, 1-5 VUs | Validate script works, basic sanity | Every deploy (CI/CD) |
| **Load** | 10-30 min, target VUs | Validate SLA at expected peak | Weekly or pre-release |
| **Stress** | 10-20 min, 2-3x target | Find the breaking point | Monthly or pre-major-release |
| **Spike** | 5 min ramp, 5 min sustain | Validate auto-scaling response | Monthly |
| **Soak** | 4-12 hours, steady load | Detect memory leaks, connection exhaustion | Quarterly or post-architecture-change |

**Data seeding is critical:** Load tests against empty databases produce unrealistic results. Seed with production-scale data volumes (or anonymized production data). Test read:write ratios that match production (typically 80:20 or 90:10).

### Capacity Modeling

**Linear Regression (simplest model):**

Plot peak request rate over the past 6 months. Fit a linear trend. Project forward 3-6 months. Add headroom.

```
Current peak:     10,000 RPS
Monthly growth:   12% MoM
6-month target:   10,000 * 1.12^6 = ~19,700 RPS
With 30% headroom: 25,600 RPS
```

**Queuing Theory Basics (Little's Law):**

```
L = lambda * W

Where:
  L = average number of requests in the system (concurrency)
  lambda = average arrival rate (requests/second)
  W = average time a request spends in the system (latency)

Example:
  lambda = 1,000 RPS
  W = 200ms = 0.2s
  L = 1,000 * 0.2 = 200 concurrent requests

  If each pod handles 20 concurrent requests:
  Minimum pods = 200 / 20 = 10 pods
  With 40% headroom: 14 pods
```

**Headroom Planning:**

| Criticality | Headroom | Rationale |
|-------------|----------|-----------|
| Payment processing, auth | 40-50% | Failure cost is extreme; over-provision |
| User-facing APIs | 25-35% | Balance cost with user experience |
| Internal services | 15-25% | Lower blast radius; can tolerate brief degradation |
| Batch/async workers | 10-15% | Can queue; autoscaling handles spikes |

---

## 4. FinOps & Cloud Cost Optimization

### The FinOps Framework

FinOps brings financial accountability to cloud spending. It operates in three iterative phases:

```
┌─────────────────────────────────────────────────────┐
│                   FinOps Lifecycle                    │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  INFORM  │──│ OPTIMIZE │──│ OPERATE  │──┐       │
│  │          │  │          │  │          │  │       │
│  │ See cost │  │ Reduce   │  │ Run      │  │       │
│  │ clearly  │  │ waste    │  │ ongoing  │  │       │
│  └──────────┘  └──────────┘  └──────────┘  │       │
│       ▲                                     │       │
│       └─────────────────────────────────────┘       │
│                                                      │
│  Maturity: Crawl → Walk → Run                       │
│  Run-phase teams achieve 20-30% savings             │
└─────────────────────────────────────────────────────┘
```

| Phase | Activities | Tools |
|-------|-----------|-------|
| **Inform** | Cost visibility, allocation, showback | Kubecost, OpenCost, cloud cost explorers, tagging |
| **Optimize** | Right-sizing, reserved capacity, spot, waste removal | VPA, Goldilocks, CAST AI, Infracost, Savings Plans |
| **Operate** | Budgets, anomaly detection, governance, continuous optimization | Cloud budgets, cost anomaly alerts, FinOps reviews |

### Cost Allocation and Tagging Strategy

**Mandatory tags (enforce via SCP/Organization Policy):**

| Tag | Purpose | Example Values |
|-----|---------|---------------|
| `Environment` | Separate prod/staging/dev costs | `production`, `staging`, `development`, `sandbox` |
| `Team` | Attribute cost to engineering teams | `platform`, `checkout`, `search`, `data` |
| `Service` | Map to specific service/microservice | `api-gateway`, `order-service`, `recommendation-engine` |
| `CostCenter` | Finance-level allocation | `CC-1001`, `CC-1002` |
| `Owner` | Point of contact for cost questions | `team-checkout@company.com` |

**Kubernetes namespace-level labels (for Kubecost/OpenCost allocation):**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: checkout
  labels:
    team: checkout
    cost-center: "CC-1001"
    environment: production
    business-unit: commerce
```

### Showback vs Chargeback

| Model | Mechanism | Adoption Stage | Pros | Cons |
|-------|-----------|---------------|------|------|
| **Showback** | Report costs to teams; no billing | Start here (Crawl/Walk) | Low friction, builds awareness | No financial incentive to optimize |
| **Chargeback** | Bill teams for actual usage | Mature orgs (Run) | Strong incentive, P&L accuracy | Requires accurate allocation, can cause friction |

**Recommendation:** Start with showback. Move to chargeback only after tagging is comprehensive and cost allocation is trusted. Premature chargeback creates political fights over shared costs.

### Cost Management Tools

**OpenCost (open source, CNCF sandbox):**

OpenCost is the open-source engine underneath Kubecost. It collects pod-level cost data using cloud pricing APIs and Kubernetes metrics. No UI — data is exposed via API and Prometheus metrics.

```bash
# Install OpenCost
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm install opencost opencost/opencost \
  --namespace opencost --create-namespace \
  --set opencost.prometheus.internal.serviceName=prometheus-server \
  --set opencost.prometheus.internal.namespaceName=monitoring
```

**Kubecost (commercial, built on OpenCost):**

Adds UI, analytics, budgets, anomaly detection, and multi-cloud support on top of OpenCost. Kubecost 3.0 covers cloud service costs beyond Kubernetes.

```bash
# Install Kubecost with Prometheus integration
helm install kubecost kubecost/cost-analyzer \
  --namespace kubecost --create-namespace \
  --set global.prometheus.enabled=true \
  --set global.prometheus.fqdn="http://prometheus-server.monitoring:80" \
  --set kubecostModel.etlBucketConfigSecret=kubecost-bucket \
  --set kubecostProductConfigs.clusterName="production" \
  --set kubecostProductConfigs.currencyCode="USD"
```

**Infracost (shift-left cost estimation):**

Infracost shows cost estimates for Terraform changes in pull requests before deployment. Currently at v2.15+ with support for AWS, Azure, and GCP. Integrates with GitHub, GitLab, and Azure DevOps.

```bash
# Install Infracost CLI
brew install infracost

# Generate cost breakdown
infracost breakdown --path /path/to/terraform

# In CI/CD — comment cost diff on PRs
infracost diff --path /path/to/terraform \
  --compare-to infracost-base.json \
  --format json --out-file infracost-diff.json

infracost comment github \
  --path infracost-diff.json \
  --repo my-org/my-repo \
  --pull-request $PR_NUMBER \
  --github-token $GITHUB_TOKEN
```

### Unit Economics

Track cost per business unit, not just total spend:

| Metric | Formula | Target | Action if Exceeded |
|--------|---------|--------|--------------------|
| **Cost per request** | Monthly infra cost / total requests | <$0.0001 for APIs | Right-size, cache aggressively |
| **Cost per user** | Monthly infra cost / MAU | Track trend, not absolute | Investigate if growing faster than revenue |
| **Cost per order** | Infra cost / orders processed | Compare to order margin | Optimize the critical path |
| **Cost per GB stored** | Storage cost / data volume | Compare across tiers | Lifecycle policies, tiered storage |

---

## 5. Reserved Capacity & Spot Instances

### AWS: The Layered Commitment Strategy

In 2026, the recommended approach is layering commitments, not choosing one type:

```
┌──────────────────────────────────────────────────────────┐
│                    AWS Compute Cost Layers                 │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Layer 1: Compute Savings Plans (60-72% discount)    │ │
│  │ Cover baseline compute: EC2, Fargate, Lambda        │ │
│  │ Most flexible — cross-region, cross-family           │ │
│  │ Size to p10 of hourly spend (never your average)    │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Layer 2: Reserved Instances (databases)              │ │
│  │ RDS RI, ElastiCache RI, OpenSearch RI               │ │
│  │ Higher discount for stable data tier workloads      │ │
│  │ Capacity reservation when needed                     │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Layer 3: Spot Instances (60-90% discount)           │ │
│  │ Fault-tolerant workloads, batch processing          │ │
│  │ Karpenter spot pools, Spot Fleet diversification    │ │
│  │ 2-minute termination notice                          │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Layer 4: On-Demand (full price)                     │ │
│  │ Burst above committed baseline                      │ │
│  │ New workloads not yet baselined                      │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

**Key 2025-2026 AWS policy change:** Effective June 1, 2025, RIs and Savings Plans are restricted to a single end customer's AWS usage. This affects resellers and multi-tenant managed service providers.

**Sizing your commitment (critical rule):** Size against your **p10** hourly spend, not your average. If your hourly commitment is $3.00 and only $2.00 runs that hour, the remaining $1.00 is wasted — it does not roll over. Under-commitment (at on-demand rates) is better than over-commitment (wasted commitment).

| Type | Discount | Flexibility | Best For |
|------|----------|-------------|----------|
| **Compute Savings Plans** | Up to 66% (3-year) | Cross-region, cross-family, covers Fargate + Lambda | Primary commitment vehicle for most teams |
| **EC2 Instance Savings Plans** | Up to 72% (3-year) | Locked to instance family + region; size-flexible | Stable EC2 workloads where you know the family |
| **Standard RIs** | Up to 72% (3-year) | Locked to instance type + region + AZ | Databases needing capacity reservation |
| **Convertible RIs** | Up to 66% (3-year) | Can change instance family | Rarely better than Compute Savings Plans now |

### GCP: CUDs, SUDs, and Spot VMs

| Type | Discount | Commitment | Behavior |
|------|----------|-----------|----------|
| **Sustained Use Discounts (SUDs)** | Up to 20-30% | None (automatic) | Kicks in after 25% monthly usage; fully automatic |
| **Resource-based CUDs** | Up to 57% (3-year) | 1 or 3 year | Locked to machine type in a region |
| **Spend-based CUDs** | Up to 40-50% | 1 or 3 year, $/hr commitment | Flexible across machine types; new discount model rolled out July 2025 |
| **Spot VMs** | Up to 91% | None (interruptible) | 30-second termination notice; can run >24 hours (unlike old preemptible VMs) |

**Key GCP interaction:** CUDs and SUDs do not stack. CUDs take priority; any usage beyond the commitment gets SUDs automatically.

**2025-2026 GCP updates:** New spend-based CUD model (multi-price/discount-based) effective July 15, 2025. Compute Flex CUD coverage expanded September 5, 2025. Automatic migration from legacy "credits" to "discounts" model with January 21, 2026 effective date.

### Azure: Reservations, Savings Plans, Spot VMs

| Type | Discount | Flexibility | Best For |
|------|----------|-------------|----------|
| **Azure Reservations** | Up to 72% (3-year) | Locked to VM size + region | Stable, predictable VMs |
| **Azure Savings Plans** | Up to 65% (3-year) | Cross-region, cross-VM-series | Flexible compute commitment |
| **Spot VMs** | Up to 90% | Evictable | Batch, CI/CD, fault-tolerant workloads |

### Spot Instance Production Patterns

**When to use Spot:**

- Stateless web workers behind a load balancer
- Async queue consumers (SQS, Kafka, RabbitMQ)
- Batch processing and data pipelines
- CI/CD build agents
- Development and staging environments
- Machine learning training jobs

**When NOT to use Spot:**

- Databases and stateful services
- Single-replica critical services
- Services without graceful shutdown handling
- Anything where a 2-minute (AWS) or 30-second (GCP) termination notice is insufficient

**Graceful termination pattern (Kubernetes):**

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 120     # Match cloud termination notice
      containers:
        - name: worker
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - |
                    # Stop accepting new work
                    touch /tmp/shutdown
                    # Wait for in-flight work to complete
                    while [ $(curl -s localhost:8080/metrics | grep in_flight_requests | awk '{print $2}') -gt 0 ]; do
                      sleep 5
                    done
      tolerations:
        - key: capacity-type
          value: spot
          operator: Equal
          effect: NoSchedule
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              preference:
                matchExpressions:
                  - key: karpenter.sh/capacity-type
                    operator: In
                    values: ["spot"]
```

**Spot diversification:** Use Karpenter with broad instance type requirements. The more instance types and AZs Karpenter can choose from, the lower the interruption rate. Never constrain Spot to a single instance type.

---

## 6. Kubernetes Cost Optimization

### Namespace Cost Allocation

Every namespace should have cost-relevant labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: checkout-service
  labels:
    team: checkout
    cost-center: "CC-1001"
    environment: production
    tier: critical           # Maps to SLO tier for cost/reliability tradeoff
  annotations:
    kubecost.com/budget: "5000"    # Monthly budget in USD
```

**ResourceQuotas for cost guardrails:**

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: checkout-quota
  namespace: checkout-service
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    pods: "100"
    persistentvolumeclaims: "10"
```

### Request/Limit Tuning for Cost

**The waste formula:**

```
Waste = (Requested resources - Actual usage) * Cost per resource unit * Time

Example:
  Pod requests 2 CPU, uses 0.3 CPU on average
  Waste = (2 - 0.3) * $0.048/hr * 720 hrs/month = $58.75/month per pod
  With 50 such pods: $2,937/month wasted on a single service
```

**Automated right-sizing pipeline:**

```
1. VPA in Off mode → collects usage data (7-14 days)
2. Goldilocks dashboard → visualizes recommendations
3. Review recommendations in weekly capacity meeting
4. Apply changes via GitOps (update manifests in repo)
5. Monitor for 48 hours post-change
6. Repeat quarterly
```

### Bin-Packing Optimization

Bin-packing is about fitting pods onto nodes with minimal wasted capacity.

**Problem:**

```
Node:   4 CPU, 16Gi memory
Pod A:  requests 1.5 CPU, 2Gi memory
Pod B:  requests 1.5 CPU, 2Gi memory
Pod C:  requests 1.5 CPU, 2Gi memory (does NOT fit — CPU exhausted)

Wasted: 0.5 CPU unused (12.5%), 10Gi memory unused (62.5%)
```

**Solutions:**

1. **Karpenter** selects the right instance type per workload mix (e.g., picks c6g.large instead of m6g.xlarge when workloads are CPU-heavy)
2. **Diverse pod sizes** — avoid all pods requesting identical resources; natural variance improves packing
3. **Pod Topology Spread Constraints** with `maxSkew` to distribute evenly
4. **Avoid memory-heavy requests on CPU-optimized nodes** — match pod resource profiles to node types

### Node Pool Strategy

```
┌───────────────────────────────────────────────────────┐
│                   Node Pool Strategy                    │
│                                                        │
│  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │ On-Demand Pool   │  │ Spot Pool                   │ │
│  │                  │  │                              │ │
│  │ Critical services│  │ Stateless workers            │ │
│  │ Databases        │  │ Queue consumers              │ │
│  │ Stateful sets    │  │ Batch jobs                   │ │
│  │ Control plane    │  │ Dev/staging workloads        │ │
│  │                  │  │                              │ │
│  │ Karpenter weight │  │ Karpenter weight: 100        │ │
│  │ 50 (fallback)    │  │ (preferred)                  │ │
│  └─────────────────┘  └─────────────────────────────┘ │
│                                                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │ GPU/Specialized Pool (optional)                 │   │
│  │ ML inference, video processing                  │   │
│  │ Specific instance types (g5, p4d, inf2)         │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────┘
```

### Pod Disruption Budgets for Cost Operations

PDBs prevent cost-saving operations (consolidation, spot reclamation) from causing outages:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
  namespace: production
spec:
  maxUnavailable: 1            # At most 1 pod disrupted at a time
  selector:
    matchLabels:
      app: api-server
---
# For batch workers, allow more aggressive disruption
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: batch-worker-pdb
  namespace: batch
spec:
  maxUnavailable: "50%"        # Half the fleet can be disrupted
  selector:
    matchLabels:
      app: batch-worker
```

### Idle Resource Detection

Common sources of waste:

| Waste Type | Detection | Remediation |
|-----------|-----------|-------------|
| Orphaned PVCs | No pod mounting the PVC for >7 days | Alert + auto-delete policy |
| Idle load balancers | No traffic for >7 days | Alert + review |
| Overprovisioned dev/staging | Usage consistently <10% of requests | Aggressive right-sizing, scheduled scale-down |
| Zombie namespaces | No deployments or pods, stale annotations | Namespace lifecycle policy |
| Unused ConfigMaps/Secrets | Not referenced by any pod | Periodic audit |

**Development environment cost control:**

```yaml
# KEDA ScaledObject to scale dev environments to zero outside business hours
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: dev-scale-to-zero
  namespace: development
spec:
  scaleTargetRef:
    name: dev-api
  minReplicaCount: 0
  maxReplicaCount: 3
  triggers:
    - type: cron
      metadata:
        timezone: America/New_York
        start: "0 8 * * 1-5"         # Scale up Mon-Fri 8 AM
        end: "0 19 * * 1-5"          # Scale down Mon-Fri 7 PM
        desiredReplicas: "2"
```

### Multi-Tenancy Cost Isolation

For platform teams serving multiple product teams:

1. **Namespace per team** with ResourceQuotas
2. **Kubecost allocation** reports per namespace/team label
3. **LimitRanges** to set default requests/limits (prevent BestEffort pods)
4. **Network policies** to prevent noisy-neighbor network effects
5. **Priority classes** to ensure critical workloads get resources first

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: checkout-service
spec:
  limits:
    - default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      type: Container
```

---

## 7. Database & Storage Capacity

### Read Replica Scaling Triggers

| Metric | Threshold | Action |
|--------|-----------|--------|
| Read query latency p99 | > 100ms sustained for 5 min | Add read replica |
| CPU utilization (primary) | > 70% sustained | Add read replica or scale up |
| Connection count | > 80% of max_connections | Add replica + connection pooling |
| Replication lag | > 1 second | Scale up replica instance size |
| Read:write ratio | > 10:1 | Strong candidate for replica scaling |

**Decision framework:** Add read replicas when the primary is read-bound. If the primary is write-bound, replicas will not help — consider vertical scaling, sharding, or write optimization first.

### Connection Pooling

**PgBouncer (PostgreSQL — de facto standard):**

PostgreSQL creates a new process per connection, each consuming 5-10MB RAM. PgBouncer multiplexes 500+ app connections through 20-50 actual database connections.

```ini
; pgbouncer.ini — production configuration
[databases]
mydb = host=primary.rds.amazonaws.com port=5432 dbname=mydb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

; Pool sizing
pool_mode = transaction           ; Recommended for most apps
default_pool_size = 25            ; Backend connections per user/db pair
min_pool_size = 5                 ; Keep warm connections
reserve_pool_size = 5             ; Emergency overflow
reserve_pool_timeout = 3          ; Seconds before using reserve

; Limits
max_client_conn = 1000            ; Max frontend connections
max_db_connections = 100          ; Hard cap on backend connections

; Timeouts
server_idle_timeout = 300         ; Close idle backend connections after 5 min
client_idle_timeout = 0           ; No timeout on idle clients
query_timeout = 30                ; Kill queries running longer than 30s
client_login_timeout = 15

; Monitoring
stats_period = 60                 ; Stats update interval
admin_users = pgbouncer_admin
stats_users = pgbouncer_stats
```

**Pool sizing formula:** `default_pool_size = (Available RAM / 20MB) / number_of_databases`, capped at 100-200 per server.

**Key PgBouncer metrics to monitor:**

| Metric | Warning Threshold | Critical Threshold |
|--------|------------------|--------------------|
| `cl_waiting` (clients waiting for connection) | > 0 sustained | > 10 sustained |
| `sv_active` / `default_pool_size` | > 80% | > 95% |
| `avg_query_time` | > 50ms | > 200ms |
| `total_xact_time` | Increasing trend | Sudden spike |

**ProxySQL (MySQL):**

ProxySQL provides connection pooling, query routing, read/write splitting, and query caching for MySQL. Deploy as a sidecar or centralized proxy.

### Sharding Decision Framework

**Do NOT shard prematurely.** Exhaust these options first:

```
1. Optimize queries (indexes, query rewriting)           ← Start here
2. Vertical scaling (bigger instance)                    ← Cheap and simple
3. Read replicas (for read-heavy workloads)              ← Moderate complexity
4. Connection pooling (PgBouncer/ProxySQL)               ← Low complexity
5. Partitioning (table-level, same database)             ← Moderate complexity
6. Caching layer (Redis/Memcached for hot reads)         ← Moderate complexity
7. Sharding (distribute data across multiple databases)  ← High complexity, last resort
```

**When sharding is justified:**

- Single database exceeds maximum instance size of your cloud provider
- Write volume exceeds what a single primary can handle
- Data volume exceeds practical backup/restore windows (>5TB)
- Regulatory requirements mandate data residency (shard by geography)

**Sharding key selection criteria:**

| Criterion | Good Key | Bad Key |
|-----------|----------|---------|
| Even distribution | `user_id` with hash-based routing | `country` (skewed distribution) |
| Query locality | Key used in most WHERE clauses | Key rarely queried |
| Growth predictability | Monotonically increasing IDs with consistent ranges | Timestamps (hotspot on recent partition) |

### Storage Tiering

**S3 Intelligent-Tiering (recommended default for most S3 data):**

S3 Intelligent-Tiering automatically moves data between tiers based on access patterns. No retrieval charges. Monitoring fee of $0.0025 per 1,000 objects/month for objects >= 128KB.

| Tier | Access Pattern | Savings vs Standard |
|------|---------------|---------------------|
| Frequent Access | Default (accessed regularly) | 0% (same as Standard) |
| Infrequent Access | Not accessed for 30 days | ~40% |
| Archive Instant Access | Not accessed for 90 days | ~68% |
| Archive Access (optional) | Not accessed for 90+ days | ~71% |
| Deep Archive Access (optional) | Not accessed for 180+ days | ~95% |

Combined S3 optimization strategies (lifecycle policies, Intelligent-Tiering, right storage class) routinely cut S3 bills by 40-80%.

**EBS Volume Optimization:**

| Volume Type | Cost (approx) | IOPS | Use Case |
|-------------|--------------|------|----------|
| gp3 | $0.08/GB + IOPS/throughput | 3,000 baseline (scalable to 16,000) | Default for most workloads |
| gp2 | $0.10/GB (burst IOPS) | 3 IOPS/GB | Legacy; migrate to gp3 |
| io2 Block Express | $0.125/GB + $0.065/IOPS | Up to 256,000 | Databases needing sustained high IOPS |
| st1 | $0.045/GB | Throughput-optimized | Log processing, data warehousing |
| sc1 | $0.015/GB | Cold storage | Infrequent access archives |

**Quick wins:** Migrate gp2 to gp3 (same or better performance, ~20% cheaper). Delete unattached EBS volumes (common waste). Snapshot old volumes to S3 and delete the EBS volume.

### Caching to Reduce Database Load

**Redis/Memcached sizing:**

```
Cache memory = (Average object size) * (Number of hot objects) * (1 + overhead factor)

Example:
  Average cached object:  2KB
  Hot objects:            500,000
  Overhead (Redis):       ~1.5x (pointers, hash table, expiry metadata)
  
  Cache memory = 2KB * 500,000 * 1.5 = 1.5GB
  Instance:     cache.r7g.large (13GB) — provides headroom for growth
```

**Cache hit ratio targets:**

| Ratio | Assessment | Action |
|-------|-----------|--------|
| > 95% | Excellent | Monitor for staleness; consider smaller cache |
| 85-95% | Good | Tune TTLs, review eviction policies |
| 70-85% | Needs work | Analyze miss patterns; pre-warm cache; review key design |
| < 70% | Poor | Cache design likely wrong; rethink what to cache |

---

## 8. Capacity Planning Process

### Capacity Planning Cadence

| Cadence | Activity | Participants |
|---------|----------|-------------|
| **Weekly** | Review cost dashboards, check anomalies | SRE on-call, FinOps lead |
| **Monthly** | Right-sizing review, commitment utilization, idle resource cleanup | SRE team, engineering managers |
| **Quarterly** | Full capacity planning review, growth projections, commitment purchases | SRE, engineering, finance, product |
| **Annually** | Strategic planning, major commitment decisions (3-year RIs/SPs), architecture cost review | CTO, VP Eng, Finance |

### Growth Projection Models

**Simple exponential model:**

```
Future_capacity = Current_capacity * (1 + growth_rate)^months

Inputs:
  - Current peak usage (from monitoring)
  - Historical growth rate (from metrics over 3-6 months)
  - Known upcoming events (launches, marketing campaigns)
  
Example:
  Current peak:     500 RPS
  Growth rate:      15% month-over-month
  3-month target:   500 * 1.15^3 = 760 RPS
  6-month target:   500 * 1.15^6 = 1,156 RPS
  Add 30% headroom: 1,503 RPS capacity needed in 6 months
```

**When simple models fail:** Exponential models break down for products with seasonal patterns, viral growth events, or step-function changes (new enterprise customer onboarding). For these, use scenario-based planning:

| Scenario | Description | Capacity Target |
|----------|-------------|-----------------|
| Base case | Organic growth continues at current rate | Current + 15% MoM for 6 months |
| Bull case | Marketing campaign drives 3x traffic spike | 3x current peak, sustained for 2 weeks |
| Enterprise onboarding | New client adds 50% more data volume | 1.5x database, 1.3x compute |
| Viral event | Social media drives 10x traffic for 2 hours | 10x for 2 hours, then decay over 24 hours |

### Saturation Analysis and Forecasting

Track saturation (current usage / maximum capacity) for every critical resource:

| Resource | Current Usage | Max Capacity | Saturation | Months to Full (at 15% MoM) |
|----------|--------------|-------------|------------|------------------------------|
| CPU (cluster) | 340 cores | 500 cores | 68% | ~3 months |
| Memory (cluster) | 800Gi | 1200Gi | 67% | ~3.5 months |
| Database connections | 180 | 300 | 60% | ~4 months |
| Kafka partitions | 120 | 200 | 60% | ~4 months |
| S3 storage | 12TB | No hard limit | N/A | Cost projection only |
| RDS IOPS | 8,000 | 16,000 (gp3 max) | 50% | ~5 months |

**Alert on saturation:**

```yaml
# Prometheus alerting rule for saturation forecasting
groups:
  - name: capacity-saturation
    rules:
      - alert: ClusterCPUSaturationHigh
        expr: |
          sum(kube_pod_container_resource_requests{resource="cpu"}) 
          / sum(kube_node_status_allocatable{resource="cpu"}) 
          > 0.80
        for: 30m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "Cluster CPU saturation at {{ $value | humanizePercentage }}"
          description: "Cluster CPU request saturation has exceeded 80% for 30 minutes. Plan capacity expansion."
          runbook: "https://wiki.internal/runbooks/cluster-capacity"

      - alert: ClusterCPUSaturationCritical
        expr: |
          sum(kube_pod_container_resource_requests{resource="cpu"}) 
          / sum(kube_node_status_allocatable{resource="cpu"}) 
          > 0.90
        for: 15m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "Cluster CPU saturation critical at {{ $value | humanizePercentage }}"
          description: "Cluster CPU request saturation has exceeded 90%. New pods may fail to schedule."

      - alert: PredictedCPUExhaustion
        expr: |
          predict_linear(
            sum(kube_pod_container_resource_requests{resource="cpu"})[7d:1h],
            30 * 24 * 3600
          ) > sum(kube_node_status_allocatable{resource="cpu"})
        for: 1h
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "CPU capacity predicted to exhaust within 30 days"
          description: "Linear projection of CPU request growth predicts exhaustion in ~30 days."
```

### Peak Planning

**Black Friday / Major Event Checklist:**

```
Pre-Event (4-6 weeks before):
  [ ] Run load test at 3x expected peak
  [ ] Identify bottlenecks and capacity ceilings
  [ ] Pre-provision additional nodes (don't rely solely on autoscaling for >2x)
  [ ] Verify auto-scaling policies and test scale-up/down
  [ ] Increase reserved database connections
  [ ] Pre-warm caches
  [ ] Increase CDN capacity / enable origin shields
  [ ] Verify Spot capacity in target AZs (consider on-demand surge pool)
  [ ] Update PDBs to allow faster draining if needed
  [ ] Scale monitoring infrastructure (Prometheus/Loki retention, storage)

Pre-Event (1 week before):
  [ ] Freeze deployments (code freeze)
  [ ] Verify rollback procedures
  [ ] Staff on-call with senior engineers
  [ ] Pre-scale to 2x baseline
  [ ] Validate alerting thresholds (lower sensitivity for expected high traffic)
  [ ] Communicate to status page subscribers

During Event:
  [ ] Active monitoring (dedicated war room / Slack channel)
  [ ] Manual scaling triggers ready if autoscaling lags
  [ ] Incident response team on standby
  [ ] Regular status updates to stakeholders

Post-Event (within 1 week):
  [ ] Scale down gracefully (not all at once)
  [ ] Review actual vs projected traffic
  [ ] Document lessons learned
  [ ] Update capacity model with actual data
  [ ] Review cost impact
```

### Capacity Plan Document Template

```markdown
# Capacity Plan — [Service Name] — Q[X] [Year]

## Executive Summary
- Current headroom: [X]% across [resource types]
- Projected headroom in 3 months: [X]%
- Action required: [Yes/No] — [brief summary]
- Estimated cost impact: $[X]/month

## Current State
| Resource | Current Usage | Capacity | Saturation | Trend (MoM) |
|----------|--------------|----------|------------|-------------|
| CPU      |              |          |            |             |
| Memory   |              |          |            |             |
| Storage  |              |          |            |             |
| DB IOPS  |              |          |            |             |
| Network  |              |          |            |             |

## Growth Projections
| Scenario | 3-Month | 6-Month | Assumption |
|----------|---------|---------|------------|
| Base     |         |         |            |
| Bull     |         |         |            |
| Event    |         |         |            |

## Recommended Actions
1. [Action] — [Effort] — [Cost impact] — [Timeline]
2. ...

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
|      |           |        |            |

## Cost Summary
| Item | Current Monthly | Projected Monthly | Delta |
|------|----------------|-------------------|-------|
|      |                |                   |       |
```

### Headroom Targets

| Service Tier | Headroom Target | Rationale |
|-------------|----------------|-----------|
| **Tier 0 (Revenue-critical)** | 40-50% | Payment, auth, checkout — failure costs revenue per minute |
| **Tier 1 (User-facing)** | 25-35% | APIs, web, mobile backends — degradation affects users |
| **Tier 2 (Internal)** | 15-25% | Admin tools, internal APIs — lower blast radius |
| **Tier 3 (Batch/Async)** | 10-15% | Workers, pipelines — can queue and catch up |

---

## 9. CDN & Edge Capacity

### CDN Provider Selection

| Provider | Strengths | Edge Locations | Best For |
|----------|-----------|---------------|----------|
| **CloudFront** | Deep AWS integration, Lambda@Edge, competitive pricing | 600+ | AWS-native architectures, global distribution |
| **Cloudflare** | Largest free tier, Workers edge compute, DDoS protection | 310+ cities | Wide range of use cases, developer experience, edge compute |
| **Fastly** | Instant purging, Compute@Edge (Wasm), real-time logging | 90+ PoPs | Dynamic content, real-time apps, streaming |
| **Akamai** | Largest network, deepest embedding, enterprise features | 4,100+ nodes in 130+ countries | Enterprise, media, gaming, lowest-latency requirements |
| **Google Cloud CDN** | GCP integration, Anycast IP, Cloud Armor integration | 150+ PoPs | GCP-native architectures |

### Cache Hit Ratio Optimization

**Target:** 90%+ cache hit ratio for static assets, 70%+ for semi-dynamic content.

**Optimization levers:**

| Lever | Impact | Implementation |
|-------|--------|---------------|
| Normalize query strings | High | Sort, remove tracking params before cache key |
| Cache-Control headers | High | `max-age=31536000` for versioned assets, `s-maxage=300` for APIs |
| Vary header discipline | Medium | Only vary on necessary headers (Accept-Encoding, not User-Agent) |
| Origin shield | Medium | Single intermediate cache tier reduces origin hits |
| Cache warming | Medium | Pre-populate cache before traffic shifts (new deploys, CDN migration) |
| Stale-while-revalidate | Medium | Serve stale content while refreshing in background |

### Origin Shield Pattern

```
User → Edge PoP → [Shield PoP] → Origin

Without shield:
  - 200 edge PoPs each independently request from origin
  - Origin sees 200x amplification on cache misses

With shield:
  - 200 edge PoPs consolidate through 1-3 shield PoPs
  - Origin sees 1-3x amplification on cache misses
  - Reduces origin load by 90%+
```

Enable origin shield when:
- Origin is expensive to scale (database-backed APIs)
- Content is semi-dynamic (5-60 second TTLs)
- Global distribution means many edge PoPs

### Edge Compute Scaling

| Platform | Runtime | Cold Start | Use Cases |
|----------|---------|-----------|-----------|
| **Cloudflare Workers** | V8 isolates | ~0ms | Request routing, A/B testing, auth at edge, personalization |
| **Lambda@Edge** | Node.js, Python | 50-200ms | CloudFront request/response manipulation |
| **CloudFront Functions** | JavaScript (limited) | <1ms | Header manipulation, URL rewrites, simple redirects |
| **Fastly Compute** | Wasm (Rust, Go, JS) | ~0ms | Complex logic at edge, real-time content assembly |

**Edge compute cost model:** Typically priced per invocation + compute duration. For high-traffic sites (>100M requests/month), edge compute can be more cost-effective than origin compute for simple transformations.

### Geographic Distribution Strategy

```
Traffic Analysis → Identify top regions → Place PoPs/origins accordingly

Example distribution:
  North America: 60% traffic → Primary origin us-east-1, secondary us-west-2
  Europe:        25% traffic → Origin eu-west-1
  Asia-Pacific:  15% traffic → Origin ap-southeast-1

CDN covers global edge caching regardless of origin placement.
Origin placement reduces cache-miss latency for regional users.
```

---

## 10. Cost Monitoring & Reporting

### Dashboard Design for Cost Visibility

**Executive dashboard (weekly review):**

| Panel | Metric | Visualization |
|-------|--------|---------------|
| Total monthly spend | Actual vs budget | Gauge with red/yellow/green zones |
| Spend trend | Daily cost, 30-day rolling average | Time series with trend line |
| Cost by team | Top 10 teams by spend | Horizontal bar chart |
| Savings opportunities | Identified waste | Table with estimated savings |
| Commitment utilization | RI/SP coverage and utilization | Gauge per commitment type |
| Cost per unit | Cost/request, cost/user, cost/order | Time series — should be flat or declining |

**Engineering team dashboard (daily review):**

| Panel | Metric | Visualization |
|-------|--------|---------------|
| My team's spend | Namespace-level cost breakdown | Stacked area chart by service |
| Resource efficiency | Requested vs used (CPU, memory) | Dual-axis chart |
| Idle resources | Unattached volumes, unused LBs | Alert list |
| Top cost drivers | Top 5 services by cost | Table with week-over-week delta |
| Spot vs on-demand mix | Capacity type breakdown | Pie chart |

### Cost Alerting Rules

```yaml
# Prometheus alerting rules for cost anomalies
# (Requires Kubecost/OpenCost metrics)
groups:
  - name: cost-alerts
    rules:
      - alert: DailyCostSpike
        expr: |
          (
            sum(kubecost_cluster_costs_daily) 
            / avg_over_time(sum(kubecost_cluster_costs_daily)[7d:1d])
          ) > 1.3
        for: 2h
        labels:
          severity: warning
          team: finops
        annotations:
          summary: "Daily cost is 30%+ above 7-day average"
          description: "Current daily cost: ${{ $value | humanize }}. Investigate for unexpected scaling or resource creation."

      - alert: NamespaceBudgetExceeded
        expr: |
          sum by (namespace) (kubecost_namespace_costs_monthly) 
          > on(namespace) kubecost_namespace_budget
        for: 1h
        labels:
          severity: warning
          team: finops
        annotations:
          summary: "Namespace {{ $labels.namespace }} has exceeded its monthly budget"

      - alert: LowCommitmentUtilization
        expr: |
          aws_savings_plan_utilization_percentage < 80
        for: 24h
        labels:
          severity: warning
          team: finops
        annotations:
          summary: "Savings Plan utilization below 80%"
          description: "Under-utilized commitment is wasted spend. Review commitment sizing."

      - alert: SpotInterruptionRateHigh
        expr: |
          rate(karpenter_nodes_terminated_total{reason="interruption"}[1h]) > 0.1
        for: 30m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "Spot interruption rate elevated"
          description: "High Spot interruption rate. Consider diversifying instance types or increasing on-demand ratio."
```

### Daily/Weekly Cost Reports

**Automated weekly cost report (structure):**

```
Weekly Cloud Cost Report — Week of [Date]
========================================

SUMMARY
  Total spend this week:           $X,XXX
  Change vs last week:             +X% / -X%
  Monthly projected spend:         $XX,XXX
  Monthly budget:                  $XX,XXX
  Budget utilization:              XX%

TOP MOVERS (biggest week-over-week changes)
  1. [Service/Team] — +$XXX (+XX%) — [reason if known]
  2. [Service/Team] — -$XXX (-XX%) — [reason if known]

SAVINGS OPPORTUNITIES
  1. [XX idle resources] — potential savings: $XXX/month
  2. [XX overprovisioned services] — potential savings: $XXX/month
  3. [XX gp2 volumes to migrate to gp3] — potential savings: $XXX/month

COMMITMENT STATUS
  Savings Plan utilization:  XX%
  RI utilization:            XX%
  Spot coverage:             XX% of eligible workloads

ACTION ITEMS
  - [Action] — [Owner] — [Due date]
```

### Executive Cost Reporting

**Monthly executive report structure:**

| Section | Content | Audience |
|---------|---------|----------|
| Total cloud spend | Actual vs budget vs forecast | CFO, CTO |
| Unit economics | Cost per request/user/transaction trend | CTO, VP Eng |
| Team attribution | Spend by business unit / product line | VP Eng, Engineering Managers |
| Optimization wins | Savings achieved this month | CFO (justifies FinOps investment) |
| Commitment coverage | RI/SP utilization and expiration | Finance, SRE |
| Recommendations | Top 3 actions with estimated savings | CTO, VP Eng |

### Cost Per Environment

| Environment | Typical % of Total | Cost Control Strategy |
|-------------|-------------------|----------------------|
| Production | 60-75% | Right-sizing, commitments, spot for eligible workloads |
| Staging | 10-15% | Scale-down outside business hours, smaller instance sizes |
| Development | 5-15% | Scale to zero when idle (KEDA cron), ephemeral environments |
| CI/CD | 5-10% | Spot instances, right-sized runners, caching to reduce build time |
| Sandbox/Testing | 2-5% | Auto-delete after TTL, strict ResourceQuotas |

### Development Environment Cost Control

Tactics that typically save 40-70% on non-production environments:

1. **Scheduled scale-down**: KEDA cron scaler to zero replicas outside business hours (saves ~65% for Mon-Fri 8-7 schedules)
2. **Smaller instance types**: dev/staging does not need production-sized nodes
3. **Spot-only node pools**: all dev/staging workloads on Spot
4. **Ephemeral environments**: PR-based environments that auto-destroy on merge (tools: Argo CD ApplicationSets, Crossplane)
5. **Shared databases**: dev teams share a single RDS instance with schema-per-tenant isolation
6. **TTL-based cleanup**: label resources with `ttl: 7d`; cron job deletes expired resources
7. **Resource quotas**: hard caps prevent runaway dev experiments

```yaml
# Example: namespace-level TTL annotation for auto-cleanup
apiVersion: v1
kind: Namespace
metadata:
  name: pr-1234
  labels:
    environment: ephemeral
    pr-number: "1234"
  annotations:
    janitor/ttl: "72h"          # Auto-delete after 72 hours
    janitor/created-by: "ci-pipeline"
```

---

## Quick Reference: Decision Trees

### "Should I use HPA, VPA, or KEDA?"

```
Is the scaling signal a cloud event (queue depth, stream lag, cron)?
  YES → KEDA
  NO  → Is the bottleneck CPU/memory per pod (pod is too small)?
          YES → VPA (or manual right-sizing if VPA is too risky)
          NO  → HPA
                  On CPU/memory? → Standard HPA
                  On custom metric? → HPA with Prometheus adapter, or KEDA with Prometheus scaler
```

### "Should I use Cluster Autoscaler or Karpenter?"

```
Are you on AWS EKS?
  YES → Karpenter (unless you need specific ASG features like lifecycle hooks)
  NO  → Is the provider supported by Karpenter (GCP/Azure beta)?
          YES and willing to run beta → Karpenter
          NO  → Cluster Autoscaler
```

### "Should I buy Reserved Instances or Savings Plans?"

```
Is the workload EC2 compute (not databases)?
  YES → Compute Savings Plans (most flexible)
  NO  → Is it RDS/ElastiCache/OpenSearch?
          YES → Reserved Instances (higher discount for data tier)
          NO  → Evaluate Savings Plans coverage for the service (Fargate, Lambda)

How much to commit?
  → p10 of your hourly spend (NEVER your average or peak)
  → Review and adjust quarterly
```

### "When do I need to shard my database?"

```
Is the primary CPU > 70% sustained?
  NO  → Not yet. Optimize queries, add caching.
  YES → Is it read-heavy (>80% reads)?
          YES → Add read replicas first
          NO  → Is vertical scaling still an option?
                  YES → Scale up the instance
                  NO  → Is the dataset > 5TB or write IOPS maxed?
                          YES → Time to shard
                          NO  → Add connection pooling, optimize writes
```
