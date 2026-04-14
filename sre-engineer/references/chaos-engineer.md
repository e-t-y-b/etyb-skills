# Chaos Engineering & Resilience Testing -- Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Chaos Engineering Tool Selection](#1-chaos-engineering-tool-selection)
2. [The Chaos Engineering Process](#2-the-chaos-engineering-process)
3. [Fault Injection Patterns](#3-fault-injection-patterns)
4. [Litmus Chaos Deep Dive](#4-litmus-chaos-deep-dive)
5. [Chaos Mesh Deep Dive](#5-chaos-mesh-deep-dive)
6. [Game Day Planning](#6-game-day-planning)
7. [Resilience Patterns](#7-resilience-patterns)
8. [Failure Mode and Effects Analysis (FMEA)](#8-failure-mode-and-effects-analysis-fmea)
9. [Chaos in CI/CD](#9-chaos-in-cicd)
10. [Production Chaos Experiments](#10-production-chaos-experiments)
11. [Resilience Scoring & Maturity](#11-resilience-scoring--maturity)

---

## 1. Chaos Engineering Tool Selection

### Tool Comparison Matrix

| Feature | Litmus Chaos | Chaos Mesh | Gremlin | Steadybit | AWS FIS | Chaos Monkey | Chaos Toolkit |
|---|---|---|---|---|---|---|---|
| **License** | Apache 2.0 | Apache 2.0 | Commercial | Commercial (OSS extensions) | AWS Service | Apache 2.0 | Apache 2.0 |
| **Type** | K8s-native | K8s-native | SaaS + Agent | SaaS + Agent | Cloud-native (AWS) | Spinnaker plugin | Framework / CLI |
| **K8s Support** | Native CRDs | Native CRDs | Agent-based | Agent-based | EKS via SSM | Spinnaker integration | Driver-based |
| **Non-K8s Support** | Limited | No | Yes (VMs, containers, cloud) | Yes (VMs, containers) | AWS services only | EC2 instances | Yes (any platform) |
| **UI / Dashboard** | ChaosCenter (React) | Chaos Dashboard | Web console | Web console | AWS Console | None (CLI) | None (CLI / Reliably) |
| **Experiment Library** | ChaosHub (60+ experiments) | 15+ fault types built-in | 100+ attack scenarios | Extensible catalog | Scenario library | Instance termination only | Community drivers |
| **Probes / Checks** | HTTP, CMD, Prometheus, K8s | StatusCheck | SLO-based gating | Resilience policies | CloudWatch alarms | None | Steady-state probes |
| **CI/CD Integration** | GitHub Actions, GitLab CI | kubectl / API | API + CLI | API + CLI | CloudFormation, Terraform | Spinnaker only | Native CLI, any CI |
| **RBAC** | Project-level, role-based | K8s RBAC, namespace scoping | Enterprise RBAC | Enterprise RBAC | IAM policies | Spinnaker RBAC | None built-in |
| **Resilience Scoring** | Yes (built-in) | No | Yes (reliability management) | Yes (resilience policies) | No | No | No |
| **Scheduling** | Cron-based workflows | Cron schedules | Recurring attacks | Recurring experiments | EventBridge triggers | Continuous | Cron via CI |
| **Pricing** | Free | Free | Custom quote (contact sales) | Free tier + Enterprise | Pay per action-minute | Free | Free (Reliably SaaS extra) |
| **Best For** | K8s teams wanting full OSS platform | K8s teams wanting lightweight CRD-based chaos | Enterprises wanting managed platform + support | Teams wanting extensible platform with discovery | AWS-heavy shops, compliance-driven orgs | Netflix-style random termination | Multi-platform, script-driven teams |
| **MCP Server** | Yes (2025) | No | No | Yes (2025) | No | No | No |

### Decision Framework: Choosing the Right Tool

```
START
  |
  v
Is your workload on Kubernetes?
  |
  +-- NO --> Is it on AWS exclusively?
  |            |
  |            +-- YES --> AWS FIS (native integration, IAM-based, compliance-friendly)
  |            +-- NO  --> Gremlin (multi-cloud, VM/container/cloud support)
  |                        OR Chaos Toolkit (open source, any platform)
  |
  +-- YES --> Do you need a managed/commercial platform?
               |
               +-- YES --> Budget for enterprise support?
               |            |
               |            +-- YES --> Gremlin (most mature commercial)
               |            |          OR Steadybit (extensible, discovery-driven)
               |            +-- NO  --> Litmus Chaos (free, full-featured)
               |
               +-- NO --> Do you want a full platform with UI?
                           |
                           +-- YES --> Litmus Chaos (ChaosCenter, ChaosHub, resilience scoring)
                           +-- NO  --> Chaos Mesh (lightweight CRDs, minimal overhead)
```

### Tool Deep Comparisons

**Litmus Chaos vs Chaos Mesh** -- The two leading open-source Kubernetes-native options:

| Dimension | Litmus Chaos | Chaos Mesh |
|---|---|---|
| Architecture | ChaosCenter (control plane) + Chaos Infrastructure (execution plane) | Chaos Dashboard + Controller Manager |
| Experiment definition | Workflow YAML with embedded fault specs | Individual CRD manifests (PodChaos, NetworkChaos, etc.) |
| Learning curve | Steeper (ChaosCenter concepts, probes, workflows) | Gentler (standard K8s CRDs, apply and go) |
| Observability integration | Prometheus probes, resilience score dashboard | StatusCheck, but less integrated |
| Custom experiments | Yes (custom chaos hub) | Yes (custom CRDs, but more limited) |
| Workflow orchestration | Built-in multi-step workflows with conditions | Workflow CRD for chaining experiments |
| Resource footprint | Heavier (ChaosCenter services, MongoDB, auth server) | Lighter (controller manager + dashboard) |
| Community & CNCF | CNCF Incubating | CNCF Incubating |

**Gremlin vs Steadybit** -- The two leading commercial platforms:

| Dimension | Gremlin | Steadybit |
|---|---|---|
| Founded | 2016 (ex-Amazon, ex-Netflix engineers) | 2019 |
| Platform scope | Reliability management (chaos + DR testing + dashboards) | Chaos engineering with environment discovery |
| Unique feature | Disaster Recovery Testing product (zone/region failover) | Auto-discovery of reliability risks + recommended experiments |
| AI capabilities | AI-powered experiment suggestions based on telemetry | MCP Server for LLM-driven experiment analysis |
| Deployment | SaaS only | SaaS and On-Premises (full feature parity) |
| Extension model | Fixed attack catalog | Open-source extension framework (community-driven) |
| Target audience | Large enterprises, compliance-heavy orgs | Engineering teams wanting extensibility |

**AWS FIS vs Multi-Cloud Tools**:

AWS FIS is the only option that can inject faults at the AWS API layer (throttle DynamoDB, disrupt RDS, inject AZ power interruption). No third-party tool can do this because it requires AWS service-level integration. Use FIS for AWS-specific failure modes and combine it with Litmus/Chaos Mesh for Kubernetes-level faults.

---

## 2. The Chaos Engineering Process

### The Scientific Method for Chaos

Chaos engineering is not "break things in production." It is a disciplined, scientific practice for proactively discovering systemic weaknesses. The core methodology follows the scientific method:

```
1. STEADY STATE HYPOTHESIS
   Define what "normal" looks like using measurable outputs.
   "Our API returns 200 OK for 99.9% of requests with p99 < 300ms"

2. DEFINE EXPERIMENT
   Choose a real-world failure scenario to introduce.
   "Terminate 1 of 3 API pods in the primary AZ"

3. CONTROL VARIABLES
   Document what is NOT changing during the experiment.
   "Traffic volume stays constant, no deployments during window"

4. RUN EXPERIMENT
   Inject the fault in a controlled, time-boxed manner.
   "Kill pod at 14:00 UTC, observe for 10 minutes"

5. OBSERVE
   Monitor the steady-state metrics during and after injection.
   "Error rate spiked to 2% for 45 seconds, then recovered"

6. ANALYZE
   Compare actual behavior against the hypothesis.
   "Hypothesis disproved: expected 0% user impact, observed 2% errors"

7. IMPROVE
   Fix the weakness and re-run the experiment to verify the fix.
   "Added PDB, increased replica count, configured circuit breaker"
```

### Principles of Chaos Engineering

From principlesofchaos.org, the foundational principles that guide the practice:

**1. Build a Hypothesis around Steady State Behavior**
Focus on the measurable output of a system, not internal attributes. The steady state is what users experience: response times, error rates, throughput. Not CPU utilization or memory usage -- those are internal signals, not user-facing behavior.

**2. Vary Real-World Events**
Chaos variables should reflect real-world events. Prioritize by estimated frequency or potential impact:
- Hardware failures: server crashes, disk failures, NIC failures
- Software failures: malformed responses, memory leaks, thread exhaustion
- Non-failure events: traffic spikes, scaling events, config changes
- Dependency failures: third-party API outages, DNS failures, certificate expiration

**3. Run Experiments in Production**
Chaos engineering strongly prefers production traffic for authenticity. Staging environments differ from production in traffic patterns, data volume, infrastructure configuration, and concurrent load. However, start in staging if you lack the safety controls for production (see Section 10).

**4. Automate Experiments to Run Continuously**
Manual game days are a starting point, not the destination. Mature chaos programs automate experiments and run them continuously, driving both orchestration and analysis. Treat chaos experiments like tests -- they should run regularly and flag regressions.

**5. Minimize Blast Radius**
Every experiment must have bounds. Start with the smallest possible blast radius and increase scope as confidence grows. Always have abort conditions that automatically halt experiments when impact exceeds expectations.

### Build vs Break Distinction

This is critical for getting organizational buy-in:

| Chaos Engineering IS | Chaos Engineering IS NOT |
|---|---|
| Discovering unknown weaknesses before users do | Breaking things for fun |
| Controlled, hypothesis-driven experiments | Random destruction |
| Building confidence in system resilience | Proving systems are fragile |
| A practice with safety controls and rollbacks | Uncontrolled fault injection |
| Measurable with defined success criteria | Ad-hoc testing without metrics |
| Collaborative (involves all stakeholders) | Adversarial (surprising teams) |

### Safety Controls and Abort Conditions

Every chaos experiment MUST have:

```yaml
# Safety controls checklist
safety:
  blast_radius:
    max_affected_pods: "10%"           # Never more than X% of a service
    max_affected_zones: 1              # Single AZ at a time
    excluded_namespaces:               # Never touch these
      - kube-system
      - monitoring
      - cert-manager

  abort_conditions:
    - metric: error_rate
      threshold: "> 5%"
      action: "immediate_rollback"
    - metric: p99_latency
      threshold: "> 2000ms"
      action: "immediate_rollback"
    - metric: active_alerts
      threshold: "> 0 SEV1 alerts"
      action: "immediate_rollback"

  duration:
    max_experiment_time: "15m"         # Hard cap on experiment duration
    cooldown_between_experiments: "5m" # Recovery time between experiments

  approvals:
    required_approvers: 2
    notify_channels:
      - "#sre-chaos"
      - "#incident-response"

  rollback:
    automatic: true                    # Auto-rollback on abort condition
    manual_override: true              # Human can abort at any time
    rollback_verification: true        # Verify system recovers after rollback
```

---

## 3. Fault Injection Patterns

### Fault Taxonomy

```
FAULT INJECTION PATTERNS
|
+-- Infrastructure Faults
|   +-- Pod/Container: kill, crash loop, OOM kill, CPU throttle
|   +-- Node: drain, cordon, reboot, kernel panic
|   +-- Zone/Region: AZ failure, region evacuation
|   +-- Cluster: API server overload, etcd latency
|
+-- Application Faults
|   +-- Latency: add delay to responses (50ms, 200ms, 2s, 10s)
|   +-- Errors: inject HTTP 500/503, gRPC UNAVAILABLE
|   +-- Resource Exhaustion: memory leak, file descriptor leak, thread pool saturation
|   +-- Process: crash, hang, infinite loop
|
+-- Network Faults
|   +-- Latency: add network delay (affects all traffic, not just app)
|   +-- Packet Loss: drop X% of packets
|   +-- Bandwidth Limitation: throttle to X Mbps
|   +-- DNS Failure: NXDOMAIN, slow resolution, wrong IP
|   +-- Partition: block traffic between services or AZs
|   +-- Corruption: bit flips in packets (rare but devastating)
|
+-- Storage Faults
|   +-- Disk Fill: consume disk space until threshold
|   +-- I/O Latency: slow reads/writes by Xms
|   +-- I/O Errors: return EIO on read/write calls
|   +-- Filesystem Corruption: simulate corrupted blocks
|
+-- Dependency Faults
|   +-- Downstream Timeout: dependency does not respond
|   +-- Downstream Error: dependency returns errors
|   +-- Upstream Overload: sudden traffic spike from upstream
|   +-- Third-Party Outage: external API unavailability
|   +-- Certificate Expiration: TLS handshake failure
|   +-- Authentication Failure: token/credential rejection
```

### Infrastructure Faults -- Detailed Patterns

**Pod Kill / Pod Failure:**
The most basic and common chaos experiment. Validates that your service handles pod loss gracefully (PodDisruptionBudgets work, replica count is sufficient, load balancer removes unhealthy pods quickly).

| Parameter | Conservative | Moderate | Aggressive |
|---|---|---|---|
| Pods killed | 1 pod | 33% of pods | 50% of pods |
| Kill method | Graceful (SIGTERM) | Immediate (SIGKILL) | Immediate + no restart for 60s |
| Duration | One-shot | Repeated every 30s for 5m | Continuous for 15m |
| Expected recovery | < 30s | < 60s | < 120s |

**Node Drain:**
Simulates node maintenance or spot instance reclamation. Validates that pods reschedule successfully, PDBs are respected, and services remain available during the drain.

**Zone Failure:**
The most impactful infrastructure experiment. Simulates an entire AZ going down by draining all nodes in the target AZ, blocking cross-AZ network traffic, and/or disabling AZ-specific resources. Validates multi-AZ deployment topology and failover.

### Network Faults -- Detailed Patterns

**Latency Injection:**
The most useful network fault. Real-world networks have variable latency, and many bugs only manifest under elevated latency (timeouts too short, retry storms, cascading failures).

| Scenario | Latency Added | Where to Inject | What It Tests |
|---|---|---|---|
| Mild degradation | 50-100ms | Between services | Timeout configuration, user experience |
| Significant delay | 200-500ms | To database/cache | Connection pool exhaustion, circuit breakers |
| Near-timeout | Just under timeout value | To external APIs | Retry behavior, timeout boundaries |
| Full timeout | Beyond timeout value | To critical dependency | Fallback behavior, graceful degradation |

**Packet Loss:**
Real-world networks lose packets. Even 1-5% packet loss causes significant TCP retransmission delays and can degrade throughput dramatically.

**DNS Failure:**
Often overlooked but devastating in production. DNS failures can cascade across an entire cluster because most services resolve hostnames on every request (or when TTL expires). Test with: NXDOMAIN responses, slow DNS resolution (5-10s delay), and DNS returning wrong IP addresses.

### Application Faults -- Detailed Patterns

**Resource Exhaustion:**
Simulates memory leaks, file descriptor exhaustion, or thread pool saturation. These are among the hardest bugs to reproduce in testing but common in production under sustained load.

**Error Injection:**
Return HTTP 500/503 or gRPC UNAVAILABLE from a percentage of requests. Validates client-side retry logic, circuit breaker configuration, and user-facing error handling.

### Dependency Faults -- Detailed Patterns

**Downstream Timeout:**
The most common real-world failure. A dependency becomes slow but does not fail outright (the "gray failure" pattern). This is harder to detect than a full outage because health checks may still pass.

**Cascading Failure Test:**
The most important dependency fault pattern. Inject latency or errors into a downstream service and observe whether failures cascade upstream through the call chain. If a single slow dependency causes the entire system to degrade, you need circuit breakers and bulkhead isolation.

---

## 4. Litmus Chaos Deep Dive

### Architecture Overview

Litmus Chaos uses a two-plane architecture:

```
CONTROL PLANE (ChaosCenter)
+-------------------------------------------------------+
|  ChaosCenter Web UI (React.js)                        |
|  - Experiment creation and scheduling                  |
|  - Resilience dashboard and analytics                  |
|  - Team collaboration, RBAC, projects                  |
+-------------------------------------------------------+
|  Backend Server (GraphQL, Golang)                      |
|  - Experiment orchestration                            |
|  - Data aggregation and API layer                      |
+-------------------------------------------------------+
|  Auth Server (Golang)                                  |
|  - User/project management                             |
|  - Token-based auth, SSO integration                   |
+-------------------------------------------------------+
|  MongoDB                                               |
|  - Experiment metadata, results, user data             |
+-------------------------------------------------------+

EXECUTION PLANE (Chaos Infrastructure)
+-------------------------------------------------------+
|  Subscriber (Golang agent, per-cluster)                |
|  - Communicates with ChaosCenter via WebSocket         |
|  - Receives experiment specs, reports status            |
+-------------------------------------------------------+
|  Workflow Controller (Argo Workflows)                   |
|  - Orchestrates multi-step chaos experiments            |
|  - Handles sequencing, parallelism, conditions          |
+-------------------------------------------------------+
|  Chaos Runner                                          |
|  - Executes individual fault injections                 |
|  - Manages experiment lifecycle                         |
+-------------------------------------------------------+
```

### ChaosExperiment CRD -- Pod Delete with Probes

```yaml
# Litmus 3.x Chaos Experiment: Pod Delete with HTTP and Prometheus Probes
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-delete-engine
  namespace: litmus
spec:
  engineState: "active"
  appinfo:
    appns: "production"
    applabel: "app=payment-service"
    appkind: "deployment"
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        probe:
          # HTTP Probe: Verify the service endpoint stays healthy
          - name: "payment-api-health"
            type: "httpProbe"
            mode: "Continuous"           # Check throughout experiment
            httpProbe/inputs:
              url: "http://payment-service.production.svc:8080/healthz"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
              insecureSkipVerify: false
            runProperties:
              probeTimeout: 5s
              interval: 5s
              retry: 3
              probePollingInterval: 2s
              evaluationTimeout: 60s

          # Prometheus Probe: Verify error rate stays below threshold
          - name: "error-rate-check"
            type: "promProbe"
            mode: "Edge"                 # Check at start and end
            promProbe/inputs:
              endpoint: "http://prometheus.monitoring.svc:9090"
              query: >
                sum(rate(http_requests_total{service="payment-service",
                  code=~"5.."}[2m])) /
                sum(rate(http_requests_total{service="payment-service"}[2m]))
                * 100
              comparator:
                type: "float"
                criteria: "<="
                value: "1.0"             # Error rate must stay under 1%
            runProperties:
              probeTimeout: 10s
              interval: 10s
              retry: 2

          # Kubernetes Probe: Verify minimum replicas are maintained
          - name: "min-replicas-check"
            type: "k8sProbe"
            mode: "Continuous"
            k8sProbe/inputs:
              group: "apps"
              version: "v1"
              resource: "deployments"
              namespace: "production"
              fieldSelector: "metadata.name=payment-service"
              operation: "present"
            runProperties:
              probeTimeout: 5s
              interval: 10s
              retry: 3

        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"                # 60 seconds of chaos
            - name: CHAOS_INTERVAL
              value: "10"                # Kill a pod every 10 seconds
            - name: FORCE
              value: "false"             # Graceful delete (SIGTERM)
            - name: PODS_AFFECTED_PERC
              value: "50"                # Kill 50% of targeted pods
            - name: SEQUENCE
              value: "parallel"          # Kill selected pods simultaneously
```

### ChaosHub -- Pre-Built Experiment Catalog

Litmus ChaosHub provides 60+ pre-built experiments organized by category:

| Category | Experiments | Key Use Cases |
|---|---|---|
| **Pod-level** | pod-delete, pod-cpu-hog, pod-memory-hog, pod-io-stress, pod-dns-error, pod-dns-spoof, pod-network-latency, pod-network-loss, pod-network-corruption, pod-network-duplication, pod-http-latency, pod-http-status-code, pod-http-modify-header, pod-http-modify-body, pod-http-reset-peer | Service resilience, resource contention, network faults |
| **Node-level** | node-drain, node-taint, node-io-stress, node-cpu-hog, node-memory-hog, node-restart | Infrastructure resilience, scheduling, PDB validation |
| **AWS** | ec2-stop, ebs-loss, ec2-terminate | AWS infrastructure failure |
| **GCP** | gcp-vm-instance-stop, gcp-vm-disk-loss | GCP infrastructure failure |
| **Azure** | azure-instance-stop, azure-disk-loss | Azure infrastructure failure |

### Custom Experiment Creation

You can create custom experiments by:

1. Building a custom experiment image with chaos logic
2. Registering it in your private ChaosHub (Git-backed)
3. Defining the ChaosExperiment CRD with environment variables and permissions
4. Using it in workflows like any built-in experiment

### Probes -- The Validation Layer

Probes are what elevate Litmus from "break things" to "validate resilience." Each probe type serves a purpose:

| Probe Type | Purpose | Typical Use |
|---|---|---|
| **httpProbe** | Verify HTTP endpoints respond correctly | Health checks, API availability |
| **cmdProbe** | Run arbitrary commands and validate output | Custom validation scripts, DB queries |
| **promProbe** | Query Prometheus and validate metric values | Error rates, latency percentiles, SLO checks |
| **k8sProbe** | Validate Kubernetes resource state | Deployment replicas, PVC status, pod readiness |

Probe modes control when validation occurs:

| Mode | Behavior | Best For |
|---|---|---|
| **SOT** (Start of Test) | Runs once before chaos injection | Pre-condition checks |
| **EOT** (End of Test) | Runs once after chaos injection | Post-recovery validation |
| **Edge** | Runs at both SOT and EOT | Before/after comparison |
| **Continuous** | Runs repeatedly throughout experiment | Ongoing SLO validation |
| **OnChaos** | Runs only during active chaos injection | Impact measurement |

### Resilience Scoring

Litmus calculates a resilience score for each experiment run:

```
Resilience Score = (Sum of probe weights for passed probes / Total probe weights) * 100

Example:
- HTTP Probe (weight 10): PASSED   -> 10
- Prom Probe (weight 7):  PASSED   -> 7
- K8s Probe (weight 3):   FAILED   -> 0
- Resilience Score = (17 / 20) * 100 = 85%
```

Track resilience scores over time to measure improvement. A decreasing score after a deployment indicates a resilience regression.

### Litmus Workflows

Workflows allow multi-step chaos experiments with:
- Sequential and parallel fault execution
- Conditional branching based on probe results
- Suspend/resume for manual approval gates
- Cron scheduling for recurring experiments

---

## 5. Chaos Mesh Deep Dive

### Architecture Overview

```
CHAOS MESH ARCHITECTURE
+----------------------------------------------------------+
|  Chaos Dashboard (Optional, Web UI)                       |
|  - Experiment creation and monitoring                     |
|  - Event timeline visualization                           |
|  - RBAC management                                        |
+----------------------------------------------------------+
|  Chaos Controller Manager (Core)                          |
|  - Watches Chaos CRDs, reconciles desired state           |
|  - Manages experiment lifecycle (create/pause/delete)     |
|  - One controller per CRD type (PodChaos, NetworkChaos..) |
+----------------------------------------------------------+
|  Chaos Daemon (DaemonSet, per-node)                       |
|  - Privileged container on each node                      |
|  - Executes fault injection at the OS/network level       |
|  - Uses Linux namespaces, cgroups, tc, iptables           |
+----------------------------------------------------------+
```

Key architectural difference from Litmus: Chaos Mesh uses DaemonSets for fault injection, which means it can manipulate network and I/O at the node level. Litmus uses sidecar/runner pods.

### Experiment Types -- Complete Reference

**PodChaos -- Pod Failure Injection:**

```yaml
# Kill a random API pod every 60 seconds for 5 minutes
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: api-pod-failure
  namespace: chaos-mesh
spec:
  action: pod-kill          # Options: pod-kill, pod-failure, container-kill
  mode: one                 # Options: one, all, fixed, fixed-percent, random-max-percent
  selector:
    namespaces:
      - production
    labelSelectors:
      app: api-gateway
      tier: frontend
  gracePeriod: 0            # 0 = immediate kill (SIGKILL), >0 = graceful
  duration: "5m"
  scheduler:
    cron: "@every 60s"      # Kill one pod every 60 seconds
```

**NetworkChaos -- Latency Injection Between Services:**

```yaml
# Add 200ms latency with jitter between frontend and API
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: frontend-to-api-latency
  namespace: chaos-mesh
spec:
  action: delay             # Options: delay, loss, duplicate, corrupt, partition, bandwidth
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: frontend
  delay:
    latency: "200ms"
    correlation: "25"       # 25% correlation with previous packet delay
    jitter: "50ms"          # +/- 50ms random jitter
  direction: to             # Options: to, from, both
  target:
    selector:
      namespaces:
        - production
      labelSelectors:
        app: api-service
    mode: all
  duration: "10m"
```

**NetworkChaos -- Packet Loss:**

```yaml
# 10% packet loss to database connections
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: db-packet-loss
  namespace: chaos-mesh
spec:
  action: loss
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: order-service
  loss:
    loss: "10"              # 10% packet loss
    correlation: "50"       # 50% correlation
  direction: to
  target:
    selector:
      namespaces:
        - production
      labelSelectors:
        app: postgresql
    mode: all
  duration: "5m"
```

**NetworkChaos -- Network Partition:**

```yaml
# Complete network partition between service A and service B
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: partition-a-from-b
  namespace: chaos-mesh
spec:
  action: partition
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: service-a
  direction: both
  target:
    selector:
      namespaces:
        - production
      labelSelectors:
        app: service-b
    mode: all
  duration: "3m"
```

**StressChaos -- CPU and Memory Stress:**

```yaml
# Stress CPU and memory on worker pods
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: worker-resource-stress
  namespace: chaos-mesh
spec:
  mode: fixed-percent
  value: "50"               # Target 50% of matching pods
  selector:
    namespaces:
      - production
    labelSelectors:
      app: background-worker
  stressors:
    cpu:
      workers: 2            # Number of CPU stress workers
      load: 80              # Target 80% CPU utilization
    memory:
      workers: 1
      size: "512Mi"         # Consume 512Mi of memory
  duration: "10m"
```

**IOChaos -- Disk I/O Faults:**

```yaml
# Add 100ms latency to all write operations
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: slow-disk-writes
  namespace: chaos-mesh
spec:
  action: latency           # Options: latency, fault, attrOverride, mistake
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      app: database
  volumePath: /data
  path: "*"                 # Affect all files in the volume
  delay: "100ms"
  methods:
    - write                 # Only affect write operations
    - pwrite
  percent: 100              # Affect 100% of matching I/O calls
  duration: "5m"
```

**DNSChaos -- DNS Resolution Failures:**

```yaml
# Make DNS resolution fail for external APIs
apiVersion: chaos-mesh.org/v1alpha1
kind: DNSChaos
metadata:
  name: external-dns-failure
  namespace: chaos-mesh
spec:
  action: error             # Options: error (NXDOMAIN), random (wrong IP)
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: notification-service
  patterns:
    - "api.sendgrid.com"    # Target specific domains
    - "smtp.mailgun.org"
  duration: "5m"
```

**HTTPChaos -- Application-Layer HTTP Faults:**

```yaml
# Inject 500 errors for 30% of requests to a specific endpoint
apiVersion: chaos-mesh.org/v1alpha1
kind: HTTPChaos
metadata:
  name: payment-endpoint-errors
  namespace: chaos-mesh
spec:
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: payment-service
  target: Response
  port: 8080
  path: "/api/v1/payments"
  method: "POST"
  code: 500                 # Return HTTP 500
  replace:
    body: '{"error": "simulated_chaos_failure"}'
  percent: 30               # Affect 30% of matching requests
  duration: "5m"
```

**TimeChaos -- Clock Skew:**

```yaml
# Shift time forward by 1 hour (test cert expiry, token expiry, cron jobs)
apiVersion: chaos-mesh.org/v1alpha1
kind: TimeChaos
metadata:
  name: time-skew
  namespace: chaos-mesh
spec:
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      app: scheduler-service
  timeOffset: "1h"          # Shift clock forward 1 hour
  clockIds:
    - CLOCK_REALTIME        # Affect system clock
  containerNames:
    - scheduler             # Target specific container
  duration: "10m"
```

### Workflows and Schedules

Chaos Mesh Workflows allow chaining experiments with serial, parallel, suspend, and conditional steps:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: resilience-validation-workflow
  namespace: chaos-mesh
spec:
  entry: entry-step
  templates:
    - name: entry-step
      templateType: Serial
      children:
        - network-delay-phase
        - recovery-wait
        - pod-kill-phase
        - recovery-wait-2
        - stress-phase

    - name: network-delay-phase
      templateType: NetworkChaos
      deadline: 5m
      networkChaos:
        action: delay
        mode: all
        selector:
          namespaces: [production]
          labelSelectors:
            app: api-service
        delay:
          latency: "300ms"
          jitter: "100ms"
        duration: "5m"

    - name: recovery-wait
      templateType: Suspend
      deadline: 2m           # Wait 2 minutes for recovery

    - name: pod-kill-phase
      templateType: PodChaos
      deadline: 3m
      podChaos:
        action: pod-kill
        mode: fixed-percent
        value: "33"
        selector:
          namespaces: [production]
          labelSelectors:
            app: api-service

    - name: recovery-wait-2
      templateType: Suspend
      deadline: 2m

    - name: stress-phase
      templateType: StressChaos
      deadline: 5m
      stressChaos:
        mode: all
        selector:
          namespaces: [production]
          labelSelectors:
            app: api-service
        stressors:
          cpu:
            workers: 2
            load: 90
        duration: "5m"
```

### RBAC and Namespace Scoping

Chaos Mesh respects Kubernetes RBAC. Limit chaos experiments by namespace:

```yaml
# ClusterRole that only allows chaos in specific namespaces
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: chaos-operator-staging
  namespace: staging
rules:
  - apiGroups: ["chaos-mesh.org"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: chaos-operator-staging-binding
  namespace: staging
subjects:
  - kind: ServiceAccount
    name: chaos-runner
    namespace: staging
roleRef:
  kind: Role
  name: chaos-operator-staging
  apiGroup: rbac.authorization.k8s.io
```

### StatusCheck for Automated Verification

StatusCheck is Chaos Mesh's mechanism for verifying system health during and after experiments:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StatusCheck
metadata:
  name: api-health-check
  namespace: chaos-mesh
spec:
  mode: Continuous
  type: HTTP
  http:
    url: "http://api-service.production.svc:8080/healthz"
    method: GET
    criteria:
      statusCode: "200"
  intervalSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3       # Mark unhealthy after 3 consecutive failures
  successThreshold: 1
  duration: "10m"
```

---

## 6. Game Day Planning

### End-to-End Game Day Guide

A game day is a planned, collaborative event where teams intentionally inject failures while engineering actively participates. Unlike automated chaos experiments, game days test both technical systems AND human response processes.

### Phase 1: Planning (1-2 Weeks Before)

**Scope Definition:**

```
GAME DAY PLANNING CHECKLIST
----------------------------
[ ] Define objectives (what are we testing and why?)
[ ] Choose failure scenarios (2-4 per game day)
[ ] Identify target systems and blast radius
[ ] Define steady-state hypothesis for each scenario
[ ] Set success criteria (what does "pass" look like?)
[ ] Set abort criteria (when do we stop the experiment?)
[ ] Schedule the event (4-6 hour block, avoid peak traffic)
[ ] Notify all stakeholders (product, engineering, support, leadership)
[ ] Prepare monitoring dashboards (pre-built, shared screen)
[ ] Verify rollback procedures work (test rollback BEFORE game day)
[ ] Assign roles (facilitator, experimenter, observer, scribe)
[ ] Prepare communication templates (status updates, escalation)
[ ] Create a shared document for real-time notes
[ ] Verify chaos tooling is installed and configured
[ ] Run a dry-run of each experiment in staging first
```

**Role Assignments:**

| Role | Responsibility | Who |
|---|---|---|
| **Facilitator** | Runs the game day, manages time, keeps scope | SRE Lead / Chaos Engineer |
| **Experimenter** | Executes fault injections, monitors chaos tool | SRE / Platform Engineer |
| **Observer** | Watches monitoring dashboards, calls out anomalies | On-call engineer, service owners |
| **Scribe** | Documents everything in real-time (timestamps, observations) | Any team member |
| **Incident Commander** | Takes over if experiment causes real impact | Senior SRE (on standby) |

### Phase 2: Execution (Game Day)

**Time Block Structure (5-6 hours):**

```
09:00 - 09:30  Kickoff briefing (objectives, scenarios, roles, abort criteria)
09:30 - 10:00  Verify steady state (all metrics nominal, no active incidents)
10:00 - 10:45  Scenario 1: Execute, observe, document
10:45 - 11:00  Break + quick debrief on Scenario 1
11:00 - 11:45  Scenario 2: Execute, observe, document
11:45 - 12:00  Break + quick debrief on Scenario 2
12:00 - 13:00  Lunch break
13:00 - 13:45  Scenario 3: Execute, observe, document
13:45 - 14:00  Break + quick debrief on Scenario 3
14:00 - 14:45  Scenario 4 (if time and energy allow)
14:45 - 15:30  Full debrief: findings, surprises, action items
```

**During Each Scenario:**

```
PRE-INJECTION (5 min)
  - Verify steady-state metrics (screenshot dashboards)
  - Confirm all participants are ready
  - Announce: "Injecting [fault] into [system] in 30 seconds"

INJECTION (variable, 5-30 min per scenario)
  - Execute the experiment
  - Scribe: timestamp every observation
  - Observers: call out ANY anomaly, even if "probably fine"
  - Facilitator: monitor abort criteria continuously
  - Do NOT intervene unless abort criteria are met

POST-INJECTION (10 min)
  - Stop the experiment (or let it auto-expire)
  - Wait for full recovery
  - Screenshot final dashboard state
  - Quick round-robin: "What did you see? Were you surprised?"
```

### Phase 3: Follow-Up (1 Week After)

**Game Day Report Template:**

```markdown
# Game Day Report: [Date]

## Summary
- **Date:** YYYY-MM-DD
- **Duration:** X hours
- **Participants:** [names and roles]
- **Systems Tested:** [services/infra]
- **Overall Result:** [X of Y scenarios passed]

## Scenario Results

### Scenario 1: [Name]
- **Hypothesis:** [What we expected]
- **Fault Injected:** [What we did]
- **Result:** PASS / FAIL / PARTIAL
- **Observations:**
  - [Timestamped observation 1]
  - [Timestamped observation 2]
- **Surprises:**
  - [Things we did not expect]
- **Action Items:**
  - [ ] [Action item with owner and due date]

## Key Findings
1. [Finding 1]
2. [Finding 2]

## Action Items (Consolidated)
| # | Action | Owner | Priority | Due Date |
|---|--------|-------|----------|----------|
| 1 | [Action] | [Name] | P1/P2/P3 | YYYY-MM-DD |

## Recommendations for Next Game Day
- [Increase scope to include...]
- [Test in production next time because...]
```

### Frequency Recommendations

| Maturity Level | Frequency | Scope |
|---|---|---|
| **Getting started** | Quarterly | Single service, staging environment |
| **Established** | Monthly | Multiple services, staging + pre-prod |
| **Mature** | Bi-weekly game days + continuous automated | All critical paths, including production |
| **Advanced** | Weekly automated + quarterly large-scale | Full system, multi-region, with DR |

### Escalation of Complexity Over Time

```
Quarter 1: Foundation
  - Pod kill on non-critical services in staging
  - Single fault, short duration, small blast radius
  - Goal: build confidence in tooling and process

Quarter 2: Service Resilience
  - Pod kill, network latency on critical services in staging
  - Multiple faults per game day, medium duration
  - Goal: validate circuit breakers, retries, fallbacks

Quarter 3: Infrastructure Resilience
  - Node drain, AZ failure simulation in pre-production
  - Combined faults (network + pod + stress)
  - Goal: validate infrastructure redundancy and failover

Quarter 4: Production Readiness
  - First production experiments (single pod kill, small blast radius)
  - Full game days with incident response integration
  - Goal: build confidence in production resilience
```

### Example Game Day Scenarios

**Scenario: Region Failure Simulation**
```
Hypothesis: "Our application can serve traffic from a single region if the primary
region becomes unavailable, with < 30s failover time and < 1% error rate during
failover."

Steps:
1. Verify traffic is balanced across both regions
2. Inject: Block all ingress traffic to primary region (DNS failover or LB drain)
3. Observe: Does traffic shift to secondary region?
4. Measure: Failover time, error rate during transition, latency from secondary
5. Verify: All data remains consistent after failover
6. Restore: Re-enable primary region traffic
7. Verify: Traffic rebalances without issues
```

**Scenario: Database Failover**
```
Hypothesis: "When the primary database becomes unavailable, the application
automatically fails over to the replica with < 60s downtime and zero data loss."

Steps:
1. Verify primary database health and replication lag
2. Inject: Kill the primary database pod (or trigger AWS RDS failover)
3. Observe: Does the application detect the failure? How long until reconnection?
4. Measure: Downtime duration, number of failed requests, data consistency
5. Verify: Write operations resume on new primary
6. Restore: Bring original primary back as replica
```

**Scenario: Cache Stampede**
```
Hypothesis: "When the Redis cache becomes unavailable, the application gracefully
degrades to direct database queries without overwhelming the database."

Steps:
1. Verify cache hit rate and database query load at steady state
2. Inject: Kill all Redis pods simultaneously
3. Observe: Does database query load spike? Does the DB handle it?
4. Measure: p99 latency increase, error rate, database CPU/connections
5. Verify: Application serves requests (possibly slower) without errors
6. Restore: Bring Redis back, verify cache warms up correctly
```

**Scenario: Cascading Failure**
```
Hypothesis: "A failure in the recommendation service does not cascade to the
product listing service or checkout flow."

Steps:
1. Verify all services healthy, map the dependency graph
2. Inject: Add 5s latency to the recommendation service
3. Observe: Does the product page still load? Does checkout work?
4. Measure: Are thread pools in calling services getting exhausted?
5. Verify: Circuit breakers trip, fallback content is served
6. Restore: Remove latency injection, verify circuit breakers reset
```

### Game Day Runbook Template

```yaml
# game-day-runbook.yaml
game_day:
  name: "Q2 2025 Resilience Validation"
  date: "2025-06-15"
  time: "09:00-15:00 UTC"
  facilitator: "Jane Smith (SRE Lead)"
  experimenter: "Bob Chen (Platform Eng)"
  observers:
    - "Alice Johnson (Payment Team Lead)"
    - "Carlos Garcia (API Team Lead)"
  scribe: "Diana Park (SRE)"
  incident_commander_on_standby: "Eve Wilson (Senior SRE)"

  prerequisites:
    - "All participants have access to monitoring dashboards"
    - "Chaos Mesh is installed and configured in staging cluster"
    - "Rollback procedures tested in previous sprint"
    - "No planned deployments during game day window"
    - "On-call engineer briefed (separate from game day participants)"
    - "Communication channel: #game-day-q2-2025 (Slack)"

  abort_criteria:
    - "Any SEV1 alert fires (real or game-day-induced)"
    - "Error rate exceeds 10% for more than 2 minutes"
    - "p99 latency exceeds 5 seconds for more than 2 minutes"
    - "Any team member calls ABORT (no justification needed)"
    - "External customers report issues"

  scenarios:
    - name: "Pod Failure - Payment Service"
      hypothesis: "Payment service handles loss of 1/3 pods with <1% error increase"
      tool: "Chaos Mesh PodChaos"
      duration: "10 minutes"
      blast_radius: "1 of 3 payment-service pods"
      metrics_to_watch:
        - "payment_request_error_rate"
        - "payment_p99_latency"
        - "payment_pod_count"
      success_criteria:
        - "Error rate increase < 1%"
        - "p99 latency increase < 200ms"
        - "Pod rescheduled within 30 seconds"
      rollback: "Chaos Mesh experiment auto-expires; verify pod is recreated"

    - name: "Network Latency - DB Connection"
      hypothesis: "API service handles 500ms DB latency with graceful degradation"
      tool: "Chaos Mesh NetworkChaos"
      duration: "5 minutes"
      blast_radius: "All traffic from api-service to postgresql"
      metrics_to_watch:
        - "api_request_duration_seconds"
        - "db_connection_pool_active"
        - "db_query_duration_seconds"
      success_criteria:
        - "API still responds (may be slower)"
        - "Connection pool does not exhaust"
        - "Circuit breaker trips for non-critical queries"
      rollback: "Delete NetworkChaos resource; verify connectivity restored"
```

---

## 7. Resilience Patterns

### Pattern Overview

```
RESILIENCE PATTERNS
|
+-- Failure Prevention
|   +-- Circuit Breaker (stop calling failing dependencies)
|   +-- Bulkhead Isolation (isolate failures to compartments)
|   +-- Rate Limiting (prevent overload)
|   +-- Load Shedding (drop low-priority work under pressure)
|
+-- Failure Handling
|   +-- Retry with Backoff (handle transient failures)
|   +-- Timeout (don't wait forever)
|   +-- Fallback (provide degraded but functional response)
|   +-- Queue-Based Load Leveling (absorb spikes)
|
+-- Failure Recovery
|   +-- Saga Pattern (coordinate distributed transactions)
|   +-- Compensating Transaction (undo partial work)
|   +-- Health Endpoint Monitoring (detect and route around failures)
```

### Circuit Breaker

The circuit breaker is the most important resilience pattern. It prevents a failing dependency from taking down the calling service by "breaking the circuit" when failures exceed a threshold.

**States:**
```
CLOSED (normal operation)
  |
  | Failure rate exceeds threshold
  v
OPEN (all calls rejected immediately, return fallback)
  |
  | Wait timeout expires
  v
HALF-OPEN (allow limited calls to test recovery)
  |
  +-- Calls succeed --> CLOSED
  +-- Calls fail    --> OPEN
```

**Circuit Breaker Implementation -- Go (using sony/gobreaker):**

```go
package resilience

import (
    "fmt"
    "net/http"
    "time"

    "github.com/sony/gobreaker/v2"
)

// NewCircuitBreaker creates a production-ready circuit breaker
// for an external dependency.
func NewCircuitBreaker(name string) *gobreaker.CircuitBreaker[[]byte] {
    settings := gobreaker.Settings{
        Name:        name,
        MaxRequests: 3,                    // Allow 3 requests in half-open state
        Interval:    30 * time.Second,     // Reset failure count every 30s in closed state
        Timeout:     60 * time.Second,     // Stay open for 60s before moving to half-open

        // ReadyToTrip determines when to open the circuit.
        // Trip when: >5 requests AND >60% failure rate
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
            return counts.Requests >= 5 && failureRatio >= 0.6
        },

        // OnStateChange logs circuit breaker state transitions for observability.
        OnStateChange: func(name string, from gobreaker.State, to gobreaker.State) {
            // Emit metric for dashboards and alerting
            fmt.Printf("circuit_breaker_state_change{name=%q, from=%q, to=%q}\n",
                name, from, to)
        },

        // IsSuccessful determines whether a response is considered a success.
        // 5xx errors and timeouts are failures; 4xx are successes (client error, not our fault).
        IsSuccessful: func(err error) bool {
            return err == nil
        },
    }

    return gobreaker.NewCircuitBreaker[[]byte](settings)
}

// CallWithCircuitBreaker wraps an HTTP call with circuit breaker protection.
func CallWithCircuitBreaker(cb *gobreaker.CircuitBreaker[[]byte], url string) ([]byte, error) {
    body, err := cb.Execute(func() ([]byte, error) {
        client := &http.Client{
            Timeout: 5 * time.Second,      // Hard timeout per request
        }

        resp, err := client.Get(url)
        if err != nil {
            return nil, fmt.Errorf("request failed: %w", err)
        }
        defer resp.Body.Close()

        if resp.StatusCode >= 500 {
            return nil, fmt.Errorf("server error: %d", resp.StatusCode)
        }

        // Read body (simplified)
        buf := make([]byte, 0, 1024)
        // ... read response body ...
        return buf, nil
    })

    if err != nil {
        // Check if the circuit is open (fast-fail, no actual request made)
        if err == gobreaker.ErrOpenState {
            // Return cached/fallback data instead
            return getFallbackResponse(url)
        }
        return nil, err
    }
    return body, nil
}

func getFallbackResponse(url string) ([]byte, error) {
    // Return cached data, default values, or gracefully degraded response
    return []byte(`{"status": "degraded", "data": null, "cached": true}`), nil
}
```

**Circuit Breaker -- Java (Resilience4j v2.4.x):**

```java
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.decorators.Decorators;
import io.vavr.control.Try;

import java.time.Duration;
import java.util.function.Supplier;

public class PaymentServiceClient {

    private final CircuitBreaker circuitBreaker;

    public PaymentServiceClient() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
            // Use a sliding window of the last 10 calls
            .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
            .slidingWindowSize(10)
            // Open circuit when 50% of calls fail
            .failureRateThreshold(50)
            // Also open if 80% of calls are slow (> 2s)
            .slowCallRateThreshold(80)
            .slowCallDurationThreshold(Duration.ofSeconds(2))
            // Stay open for 30 seconds before moving to half-open
            .waitDurationInOpenState(Duration.ofSeconds(30))
            // Allow 5 calls in half-open state
            .permittedNumberOfCallsInHalfOpenState(5)
            // Minimum 5 calls before evaluating failure rate
            .minimumNumberOfCalls(5)
            // Automatically transition from open to half-open (don't wait for a call)
            .automaticTransitionFromOpenToHalfOpenEnabled(true)
            // Record these exceptions as failures
            .recordExceptions(
                java.io.IOException.class,
                java.util.concurrent.TimeoutException.class,
                org.springframework.web.client.HttpServerErrorException.class
            )
            // Do NOT record these as failures (client errors are not our fault)
            .ignoreExceptions(
                org.springframework.web.client.HttpClientErrorException.class
            )
            .build();

        CircuitBreakerRegistry registry = CircuitBreakerRegistry.of(config);
        this.circuitBreaker = registry.circuitBreaker("paymentService");

        // Register event handlers for observability
        circuitBreaker.getEventPublisher()
            .onStateTransition(event ->
                System.out.printf("Circuit breaker '%s': %s -> %s%n",
                    event.getCircuitBreakerName(),
                    event.getStateTransition().getFromState(),
                    event.getStateTransition().getToState()));
    }

    public PaymentResult processPayment(PaymentRequest request) {
        Supplier<PaymentResult> decoratedSupplier = Decorators
            .ofSupplier(() -> callPaymentApi(request))
            .withCircuitBreaker(circuitBreaker)
            .withFallback(List.of(
                CallNotPermittedException.class,   // Circuit is open
                IOException.class                   // Network failure
            ), e -> getFallbackResult(request, e))
            .decorate();

        return Try.ofSupplier(decoratedSupplier)
            .recover(throwable -> getFallbackResult(request, throwable))
            .get();
    }

    private PaymentResult getFallbackResult(PaymentRequest request, Throwable t) {
        // Queue for async retry, return pending status to user
        asyncRetryQueue.enqueue(request);
        return PaymentResult.pending("Payment queued for processing");
    }
}
```

**Circuit Breaker -- Istio (Service Mesh, no code changes):**

```yaml
# Istio DestinationRule with circuit breaker and outlier detection
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: payment-service-cb
  namespace: production
spec:
  host: payment-service.production.svc.cluster.local
  trafficPolicy:
    # Connection pool limits (prevent resource exhaustion)
    connectionPool:
      tcp:
        maxConnections: 100           # Max TCP connections
        connectTimeout: 5s            # TCP connection timeout
      http:
        h2UpgradePolicy: DEFAULT
        http1MaxPendingRequests: 50   # Max queued requests
        http2MaxRequests: 100         # Max concurrent requests
        maxRequestsPerConnection: 10  # Recycle connections
        maxRetries: 3                 # Max concurrent retries

    # Outlier detection (circuit breaker)
    outlierDetection:
      consecutive5xxErrors: 3         # Eject after 3 consecutive 5xx errors
      interval: 10s                   # Check every 10 seconds
      baseEjectionTime: 30s           # Minimum ejection time
      maxEjectionPercent: 50          # Never eject more than 50% of endpoints
      minHealthPercent: 30            # Only eject if >30% of endpoints are healthy
```

### Retry with Exponential Backoff and Jitter

Never retry without backoff. Never use constant backoff. Always add jitter.

```
Attempt 1: immediate
Attempt 2: wait 100ms + random(0-100ms)
Attempt 3: wait 200ms + random(0-200ms)
Attempt 4: wait 400ms + random(0-400ms)
Attempt 5: wait 800ms + random(0-800ms)
(cap at max_delay)
```

**Why jitter matters:** Without jitter, all clients retry at the same intervals, creating "thundering herd" retry storms that amplify the original failure.

**What to retry:**
- Network timeouts and connection errors
- HTTP 500, 502, 503, 429 (with Retry-After header)
- Database connection pool exhaustion
- Temporary DNS resolution failures

**What NOT to retry:**
- HTTP 400, 401, 403, 404 (client errors, retrying will not help)
- Request validation failures
- Business logic errors
- Any operation that is not idempotent (unless you have idempotency keys)

### Bulkhead Isolation

Prevent a single slow dependency from consuming all resources (threads, connections, memory) in the calling service.

**Thread Pool Bulkhead:**
```
Service A
+----------------------------------+
|  Thread Pool: "payment-api"      |  <-- 10 threads max
|  [||||||||..]                    |
+----------------------------------+
|  Thread Pool: "inventory-api"    |  <-- 10 threads max
|  [||........]                    |
+----------------------------------+
|  Thread Pool: "notification-api" |  <-- 5 threads max
|  [|....]                         |
+----------------------------------+

If payment-api exhausts its 10 threads, inventory-api and notification-api
are unaffected. Without bulkheads, all 25 threads would be shared and a
slow payment-api could block everything.
```

### Timeout Patterns

Every external call MUST have a timeout. The hierarchy:

```
Connection timeout:  3-5 seconds (time to establish TCP connection)
Request timeout:     5-30 seconds (time to get a response)
Circuit breaker:     Wraps multiple timeouts (opens after repeated failures)
Global timeout:      End-to-end request timeout (e.g., 30s for user-facing APIs)
```

**Rule of thumb:** The timeout for a downstream call should be less than your own timeout. If your API has a 30s timeout and you call a dependency with a 30s timeout, a slow dependency will consume your entire budget.

### Fallback Strategies

When the primary path fails, what do you do? Options ranked from best to worst user experience:

| Strategy | Description | Example |
|---|---|---|
| **Cached response** | Return the last known good data | Product catalog from cache when DB is down |
| **Default value** | Return a sensible default | "0 items in cart" when cart service is down |
| **Graceful degradation** | Disable non-critical features | Show products without recommendations |
| **Queued processing** | Accept the request, process later | Queue payment for async processing |
| **Informative error** | Tell the user exactly what happened | "Recommendations unavailable, try again later" |
| **Fail fast** | Return an error immediately | 503 Service Unavailable with retry hint |

### Rate Limiting and Load Shedding

**Rate Limiting** (protect against excessive requests):
- Token bucket (bursty traffic OK, smooth over time)
- Sliding window (strict per-second/minute limits)
- Apply at API gateway, service mesh, or application level

**Load Shedding** (drop work when overloaded):
- Priority-based: drop low-priority requests first (analytics, prefetch)
- LIFO: drop oldest queued requests (they are likely already timed out)
- Percentage: randomly drop X% of requests when load exceeds threshold
- Critical path protection: always serve checkout, degrade product pages

### Saga Pattern for Distributed Transactions

When a business operation spans multiple services (e.g., place order = charge payment + deduct inventory + send confirmation), use the saga pattern instead of distributed transactions:

```
CHOREOGRAPHY SAGA (event-driven):

Order Service          Payment Service       Inventory Service
     |                       |                      |
     |-- OrderCreated ------>|                      |
     |                       |-- PaymentCharged --->|
     |                       |                      |-- InventoryReserved
     |<----------------------------------------------|
     |-- OrderConfirmed

If Payment fails:
     |                       |-- PaymentFailed ---->|
     |<-- CompensateOrder ---|                      |
     |-- OrderCancelled

ORCHESTRATION SAGA (central coordinator):

Order Saga Orchestrator
     |
     |-- 1. Create Order (Order Service)
     |-- 2. Charge Payment (Payment Service)
     |       |-- If fails: Cancel Order (compensate step 1)
     |-- 3. Reserve Inventory (Inventory Service)
     |       |-- If fails: Refund Payment (compensate step 2), Cancel Order
     |-- 4. Confirm Order
```

---

## 8. Failure Mode and Effects Analysis (FMEA)

### FMEA for Distributed Systems

FMEA is a systematic method for identifying potential failures, assessing their impact, and prioritizing mitigation. In the chaos engineering context, FMEA drives which experiments to run first.

### Risk Priority Number (RPN)

```
RPN = Severity x Occurrence x Detection

Severity (S):     How bad is the impact if this failure occurs? (1-10)
Occurrence (O):   How likely is this failure to happen? (1-10)
Detection (D):    How hard is it to detect before users are impacted? (1-10)

RPN Range: 1-1000 (higher = more critical, address first)
```

### Severity Scale for Distributed Systems

| Score | Severity | Description | Example |
|---|---|---|---|
| 1-2 | Negligible | No user-visible impact | Background job delay < 5 min |
| 3-4 | Minor | Minor degradation, workaround exists | Slow recommendations, cached data served |
| 5-6 | Moderate | Noticeable degradation for some users | Elevated latency, partial feature unavailability |
| 7-8 | Major | Significant impact on core functionality | Checkout failures, data inconsistency |
| 9 | Critical | Service-wide outage | Complete API unavailability |
| 10 | Catastrophic | Data loss or security breach | Database corruption, unauthorized access |

### Occurrence Scale

| Score | Occurrence | Description |
|---|---|---|
| 1-2 | Extremely rare | Once per year or less |
| 3-4 | Rare | Once per quarter |
| 5-6 | Occasional | Once per month |
| 7-8 | Frequent | Once per week |
| 9-10 | Very frequent | Daily or more |

### Detection Scale

| Score | Detection | Description |
|---|---|---|
| 1-2 | Almost certain | Automated detection + auto-remediation < 1 min |
| 3-4 | High | Automated alerting, MTTD < 5 min |
| 5-6 | Moderate | Dashboard-visible, MTTD 5-30 min |
| 7-8 | Low | Requires manual investigation, MTTD 30 min - 2 hr |
| 9-10 | Very low | Discovered by users or external monitoring |

### FMEA Worksheet Template

```markdown
# FMEA Worksheet: [Service/System Name]
# Date: YYYY-MM-DD
# Participants: [Names]

| ID | Component | Failure Mode | Failure Effect | S | O | D | RPN | Current Controls | Recommended Action | Owner | Chaos Experiment |
|----|-----------|-------------|----------------|---|---|---|-----|-----------------|-------------------|-------|-----------------|
| F-001 | API Gateway | High latency (>5s) | User requests timeout, poor UX | 7 | 6 | 3 | 126 | Health checks, HPA | Add circuit breaker, increase replicas | @alice | NetworkChaos: 5s latency to upstream |
| F-002 | Payment DB | Primary failure | Payment processing halted | 9 | 3 | 4 | 108 | Multi-AZ RDS, auto-failover | Test failover time, verify zero data loss | @bob | AWS FIS: RDS failover |
| F-003 | Redis Cache | Complete outage | Cache stampede overwhelms DB | 8 | 4 | 5 | 160 | Redis Sentinel | Add fallback to DB with rate limit, cache warming | @carol | PodChaos: kill all Redis pods |
| F-004 | Order Service | Memory leak | OOM kill, request failures | 7 | 5 | 6 | 210 | Memory limits, restart policy | Add memory profiling, GC tuning, pod memory alerts | @dave | StressChaos: memory pressure |
| F-005 | DNS | Resolution failure | All inter-service calls fail | 10 | 2 | 7 | 140 | CoreDNS redundancy | Add DNS caching sidecar, test DNS failure | @eve | DNSChaos: error on internal domains |
| F-006 | Notification Svc | Third-party API down | Email/SMS not sent | 4 | 6 | 3 | 72 | Retry queue, dead letter | Add fallback provider, increase queue retention | @frank | HTTPChaos: 503 on SendGrid API |
```

**Prioritization by RPN:**

| RPN Range | Priority | Action |
|---|---|---|
| 200+ | Critical | Address immediately, chaos test this sprint |
| 100-199 | High | Chaos test within 2 sprints, add monitoring |
| 50-99 | Medium | Schedule chaos test, verify existing controls |
| < 50 | Low | Monitor, revisit in next FMEA cycle |

### Using FMEA to Prioritize Chaos Experiments

The FMEA worksheet directly maps to chaos experiments:

1. Sort by RPN (descending)
2. For each high-RPN failure mode, design a chaos experiment
3. Run the experiment to validate (or invalidate) the "Current Controls" column
4. If the experiment reveals gaps, update "Recommended Action" and assign an owner
5. After fixes are implemented, re-run the experiment to verify
6. Update the RPN (Detection score should decrease if you added alerting)

### FMEA Review Cadence

| Trigger | Action |
|---|---|
| New service deployed | Add to FMEA worksheet, assess failure modes |
| Post-incident | Review FMEA for the affected component, update scores |
| Architecture change | Re-assess affected failure modes |
| Quarterly review | Full FMEA review, update all scores, reprioritize |
| After game day | Update "Current Controls" and Detection scores based on findings |

---

## 9. Chaos in CI/CD

### The Shift-Left Chaos Model

```
TRADITIONAL CHAOS:
  Dev -> Test -> Stage -> Prod -> [Chaos Experiments] -> Find Issues

SHIFT-LEFT CHAOS:
  Dev -> [Unit Resilience Tests] -> [Integration Chaos] -> Stage -> [Automated Chaos Gates] -> Prod -> [Continuous Chaos]
```

### Automated Resilience Validation in Pipelines

Chaos experiments as deployment gates: run automated chaos experiments before promoting a deployment. If the experiment fails (resilience score drops below threshold), block the deployment.

### GitHub Actions Integration with Litmus Chaos

```yaml
# .github/workflows/chaos-gate.yml
name: Resilience Validation Gate

on:
  pull_request:
    branches: [main]
    paths:
      - 'services/payment-service/**'

env:
  LITMUS_API_URL: "https://chaoscenter.internal.company.com"
  LITMUS_PROJECT_ID: "proj-abc123"
  CLUSTER_NAME: "staging-cluster"

jobs:
  deploy-to-staging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to staging
        run: |
          kubectl apply -f k8s/staging/ --namespace staging
          kubectl rollout status deployment/payment-service -n staging --timeout=300s

      - name: Wait for stabilization
        run: sleep 60  # Allow metrics to establish baseline

  chaos-validation:
    needs: deploy-to-staging
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install litmusctl
        run: |
          curl -sL https://github.com/litmuschaos/litmusctl/releases/latest/download/litmusctl-linux-amd64 -o litmusctl
          chmod +x litmusctl
          sudo mv litmusctl /usr/local/bin/

      - name: Configure litmusctl
        run: |
          litmusctl config set-account \
            --endpoint="${LITMUS_API_URL}" \
            --access_id="${{ secrets.LITMUS_ACCESS_KEY }}" \
            --access_key="${{ secrets.LITMUS_SECRET_KEY }}"

      - name: Run chaos experiment - Pod Delete
        id: chaos-pod-delete
        run: |
          # Trigger the pre-configured chaos workflow
          RUN_ID=$(litmusctl run chaos-experiment \
            --project-id="${LITMUS_PROJECT_ID}" \
            --workflow-id="wf-pod-delete-payment" \
            --output=json | jq -r '.runId')
          echo "run_id=${RUN_ID}" >> $GITHUB_OUTPUT

      - name: Wait for experiment completion
        run: |
          litmusctl get chaos-experiment-run \
            --project-id="${LITMUS_PROJECT_ID}" \
            --workflow-run-id="${{ steps.chaos-pod-delete.outputs.run_id }}" \
            --wait --timeout=600

      - name: Check resilience score
        id: score-check
        run: |
          SCORE=$(litmusctl get chaos-experiment-run \
            --project-id="${LITMUS_PROJECT_ID}" \
            --workflow-run-id="${{ steps.chaos-pod-delete.outputs.run_id }}" \
            --output=json | jq -r '.resilienceScore')

          echo "Resilience Score: ${SCORE}%"
          echo "score=${SCORE}" >> $GITHUB_OUTPUT

          if (( $(echo "$SCORE < 80" | bc -l) )); then
            echo "::error::Resilience score ${SCORE}% is below the 80% threshold"
            exit 1
          fi

      - name: Post results to PR
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const score = '${{ steps.score-check.outputs.score }}';
            const passed = parseFloat(score) >= 80;
            const emoji = passed ? ':white_check_mark:' : ':x:';
            const status = passed ? 'PASSED' : 'FAILED';

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## ${emoji} Chaos Resilience Gate: ${status}\n\n` +
                    `**Resilience Score:** ${score}%\n` +
                    `**Threshold:** 80%\n` +
                    `**Experiment:** Pod Delete - Payment Service\n\n` +
                    `[View full results](${process.env.LITMUS_API_URL}/experiments)`
            });
```

### GitLab CI Integration

```yaml
# .gitlab-ci.yml (chaos stage)
chaos-validation:
  stage: resilience
  image: litmuschaos/litmusctl:latest
  needs: ["deploy-staging"]
  variables:
    LITMUS_API_URL: "https://chaoscenter.internal.company.com"
  script:
    - litmusctl config set-account
        --endpoint="${LITMUS_API_URL}"
        --access_id="${LITMUS_ACCESS_KEY}"
        --access_key="${LITMUS_SECRET_KEY}"
    - |
      RUN_ID=$(litmusctl run chaos-experiment \
        --project-id="${LITMUS_PROJECT_ID}" \
        --workflow-id="wf-resilience-suite" \
        --output=json | jq -r '.runId')
    - litmusctl get chaos-experiment-run
        --project-id="${LITMUS_PROJECT_ID}"
        --workflow-run-id="${RUN_ID}"
        --wait --timeout=600
    - |
      SCORE=$(litmusctl get chaos-experiment-run \
        --project-id="${LITMUS_PROJECT_ID}" \
        --workflow-run-id="${RUN_ID}" \
        --output=json | jq -r '.resilienceScore')
      echo "Resilience Score: ${SCORE}%"
      if (( $(echo "$SCORE < 80" | bc -l) )); then
        echo "FAILED: Score below threshold"
        exit 1
      fi
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      changes:
        - services/payment-service/**
```

### Integration with Argo Rollouts for Canary Analysis

```yaml
# Argo Rollout with chaos experiment during canary analysis
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: payment-service
  namespace: production
spec:
  replicas: 6
  strategy:
    canary:
      steps:
        # Step 1: Route 10% traffic to canary
        - setWeight: 10
        - pause: { duration: 2m }

        # Step 2: Run chaos experiment on canary
        - analysis:
            templates:
              - templateName: canary-chaos-analysis
            args:
              - name: canary-hash
                valueFrom:
                  podTemplateHashValue: Latest

        # Step 3: If chaos passes, scale to 50%
        - setWeight: 50
        - pause: { duration: 5m }

        # Step 4: Full rollout
        - setWeight: 100

---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-chaos-analysis
spec:
  args:
    - name: canary-hash
  metrics:
    # Metric 1: Error rate during chaos must stay below 2%
    - name: error-rate-during-chaos
      provider:
        prometheus:
          address: http://prometheus.monitoring.svc:9090
          query: |
            sum(rate(http_requests_total{
              app="payment-service",
              rollouts_pod_template_hash="{{args.canary-hash}}",
              code=~"5.."
            }[2m])) /
            sum(rate(http_requests_total{
              app="payment-service",
              rollouts_pod_template_hash="{{args.canary-hash}}"
            }[2m])) * 100
      successCondition: result[0] < 2.0
      interval: 30s
      count: 10
      failureLimit: 2

    # Metric 2: p99 latency during chaos must stay below 500ms
    - name: latency-during-chaos
      provider:
        prometheus:
          address: http://prometheus.monitoring.svc:9090
          query: |
            histogram_quantile(0.99,
              sum(rate(http_request_duration_seconds_bucket{
                app="payment-service",
                rollouts_pod_template_hash="{{args.canary-hash}}"
              }[2m])) by (le)
            )
      successCondition: result[0] < 0.5
      interval: 30s
      count: 10
      failureLimit: 2
```

### Pre-Production Chaos Experiments Matrix

Define which experiments gate which deployment types:

| Deployment Type | Required Chaos Experiments | Resilience Threshold |
|---|---|---|
| Hotfix (P1 bug) | None (skip chaos gate) | N/A |
| Regular deployment | Pod delete (1 pod) | 80% |
| Major version bump | Pod delete + network latency + DNS failure | 85% |
| Infrastructure change | Full resilience suite (5+ experiments) | 90% |
| Database migration | DB failover + connection pool stress | 95% |

---

## 10. Production Chaos Experiments

### Safety Controls for Production

Production chaos is the gold standard but requires rigorous safety measures.

**Non-Negotiable Requirements:**

```
PRODUCTION CHAOS READINESS CHECKLIST
-------------------------------------
[ ] Observability: Real-time dashboards for all affected services
[ ] Alerting: SLO-based alerts configured and verified
[ ] Rollback: Automatic rollback on abort conditions (tested)
[ ] Blast Radius: Strictly limited (< 10% of traffic/pods affected)
[ ] Duration: Hard time limit on all experiments (< 15 min)
[ ] Communication: All stakeholders notified before experiment
[ ] Incident Process: On-call engineer aware and ready to respond
[ ] Business Hours: Run during low-traffic periods initially
[ ] Excluded: Payment processing, data stores, authentication (until mature)
[ ] Approval: Two-person approval for production experiments
[ ] Audit Trail: All experiments logged with who/what/when/why
```

### Blast Radius Containment

```
PROGRESSIVE BLAST RADIUS EXPANSION

Level 1: Single Pod (Week 1-4)
  - Kill 1 pod of a non-critical service
  - Expected: Zero user impact if PDB and replicas are correct
  - If this fails, you are not ready for anything more

Level 2: Service Percentage (Week 5-8)
  - Kill 33% of pods for a critical service
  - Expected: Brief latency spike, auto-recovery < 60s
  - Test: PDB limits, HPA scaling, load balancer health checks

Level 3: Network Partition (Week 9-12)
  - Add latency between two services in the critical path
  - Expected: Circuit breaker trips, fallback serves degraded data
  - Test: Timeout configuration, retry behavior, fallback logic

Level 4: Dependency Failure (Week 13-16)
  - Simulate downstream service complete outage
  - Expected: Graceful degradation, users see reduced functionality
  - Test: Circuit breaker, cached data, queue-based processing

Level 5: Zone Failure (Week 17-20)
  - Drain all pods in one AZ for a critical service
  - Expected: Traffic shifts to remaining AZs, < 30s impact
  - Test: Multi-AZ deployment, anti-affinity rules, DNS failover

Level 6: Regional Failure (Quarter 3+)
  - Simulate full region unavailability
  - Expected: DR plan activates, traffic routes to secondary region
  - Test: Full disaster recovery plan
```

### Monitoring During Experiments

Every production experiment requires a dedicated monitoring view:

```
EXPERIMENT MONITORING DASHBOARD
+----------------------------------------------+
| EXPERIMENT: pod-kill-payment-service          |
| STATUS: RUNNING | DURATION: 3m 42s / 15m     |
+----------------------------------------------+
|                                               |
| Error Rate:  0.3% [====.....] (SLO: < 1%)   |
| p99 Latency: 247ms [===......] (SLO: < 500) |
| Throughput:  1,245 rps [========.]            |
| Pod Count:   5/6 (1 killed)                  |
|                                               |
| ABORT CONDITIONS:                             |
| [ ] Error rate > 5%                           |
| [ ] p99 > 2000ms                              |
| [ ] Any SEV1 alert                            |
| [ ] Manual abort                              |
+----------------------------------------------+
```

### Communication Plan

```
BEFORE EXPERIMENT (30 min prior):
  #sre-chaos: "Starting production chaos experiment at 14:00 UTC.
    Target: payment-service (1 pod kill)
    Duration: 10 minutes max
    Blast radius: 1 of 6 pods
    Abort conditions: error rate > 5% or p99 > 2s
    On-call engineer: @alice (aware and standing by)"

DURING EXPERIMENT:
  #sre-chaos: "Experiment in progress. Pod killed at 14:00:15 UTC.
    Current metrics: error rate 0.2%, p99 189ms. All nominal."

AFTER EXPERIMENT:
  #sre-chaos: "Experiment complete at 14:10:00 UTC.
    Result: PASSED
    Resilience Score: 92%
    Findings: Recovery took 28s (within 30s target)
    Action items: None
    Full report: [link]"
```

### Legal and Compliance Considerations

For regulated industries (financial services, healthcare, government):

| Concern | Mitigation |
|---|---|
| **Regulatory audit** | Maintain complete audit trail of all experiments (who, what, when, why, result) |
| **Data protection** | Chaos experiments must not expose, corrupt, or lose customer data |
| **Service availability** | Document that chaos engineering improves availability (required by some regulators) |
| **Change management** | Register chaos experiments as planned changes in your ITSM system |
| **Incident classification** | Chaos-induced issues are NOT incidents (unless blast radius is exceeded) |
| **SOC 2 / ISO 27001** | Chaos experiments can be evidence of resilience testing controls |

### AWS FIS Experiment Template

```json
{
  "description": "Terminate 30% of EC2 instances in production ASG to validate auto-scaling recovery",
  "targets": {
    "productionInstances": {
      "resourceType": "aws:ec2:instance",
      "resourceTags": {
        "Environment": "production",
        "Service": "api-gateway"
      },
      "filters": [
        {
          "path": "State.Name",
          "values": ["running"]
        }
      ],
      "selectionMode": "PERCENT(30)"
    }
  },
  "actions": {
    "terminateInstances": {
      "actionId": "aws:ec2:terminate-instances",
      "description": "Terminate 30% of API gateway instances",
      "parameters": {},
      "targets": {
        "Instances": "productionInstances"
      }
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:123456789012:alarm:HighErrorRate-ApiGateway"
    },
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:123456789012:alarm:HighLatency-ApiGateway"
    }
  ],
  "roleArn": "arn:aws:iam::123456789012:role/FISExperimentRole",
  "tags": {
    "Team": "sre",
    "Purpose": "chaos-engineering",
    "Experiment": "asg-recovery-validation"
  },
  "logConfiguration": {
    "cloudWatchLogsConfiguration": {
      "logGroupArn": "arn:aws:logs:us-east-1:123456789012:log-group:/fis/experiments:*"
    },
    "logSchemaVersion": 2
  }
}
```

**AWS FIS -- AZ Availability Disruption (2025 Scenario):**

```json
{
  "description": "Simulate AZ degradation using FIS AZ scenario",
  "targets": {
    "azTarget": {
      "resourceType": "aws:ec2:instance",
      "resourceTags": {
        "Environment": "production"
      },
      "filters": [
        {
          "path": "Placement.AvailabilityZone",
          "values": ["us-east-1a"]
        }
      ],
      "selectionMode": "ALL"
    }
  },
  "actions": {
    "azDisruption": {
      "actionId": "aws:ec2:api-insufficient-instance-capacity-error",
      "description": "Simulate capacity issues in us-east-1a",
      "parameters": {
        "duration": "PT10M",
        "percentage": "100",
        "availabilityZoneIdentifiers": "use1-az1"
      },
      "targets": {}
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:123456789012:alarm:CriticalServiceDown"
    }
  ],
  "roleArn": "arn:aws:iam::123456789012:role/FISExperimentRole",
  "tags": {
    "Purpose": "az-resilience-validation"
  }
}
```

### Gremlin Attack Configuration

```yaml
# Gremlin CPU attack configuration (API call)
# POST https://api.gremlin.com/v1/attacks/new
{
  "command": {
    "type": "cpu",
    "args": [
      "-c", "2",           # Number of CPU cores to stress
      "-l", "80",          # Target CPU utilization (80%)
      "--length", "300"    # Duration in seconds (5 minutes)
    ]
  },
  "target": {
    "type": "Exact",
    "exact": {
      "ids": ["host-abc123", "host-def456"]    # Specific target hosts
    }
  }
}

# Gremlin Latency attack (network delay)
{
  "command": {
    "type": "latency",
    "args": [
      "-m", "200",         # 200ms delay
      "-j", "50",          # 50ms jitter
      "-l", "300",         # 5 minutes
      "-h", "^api\\.upstream\\.svc",  # Target hostname pattern
      "-p", "443"          # Target port
    ]
  },
  "target": {
    "type": "Random",
    "tags": {
      "service": "frontend",
      "env": "production"
    },
    "percent": 50          # Affect 50% of matching targets
  }
}

# Gremlin Scenario (multi-step attack)
{
  "name": "Payment Service Resilience",
  "description": "Progressive failure injection to validate payment service resilience",
  "hypothesis": "Payment service maintains < 1% error rate under combined faults",
  "steps": [
    {
      "delay": 0,
      "attacks": [{
        "command": { "type": "latency", "args": ["-m", "100", "-l", "120"] },
        "target": { "type": "Exact", "exact": { "ids": ["payment-host-1"] } }
      }]
    },
    {
      "delay": 120,
      "attacks": [{
        "command": { "type": "cpu", "args": ["-c", "1", "-l", "90", "--length", "120"] },
        "target": { "type": "Exact", "exact": { "ids": ["payment-host-1"] } }
      }]
    },
    {
      "delay": 240,
      "attacks": [{
        "command": { "type": "blackhole", "args": ["-l", "60", "-h", "^db\\.internal"] },
        "target": { "type": "Exact", "exact": { "ids": ["payment-host-1"] } }
      }]
    }
  ]
}
```

### Production Readiness Checklist

Before running your first production chaos experiment:

```
TIER 1: Prerequisites (must have ALL before any production chaos)
[ ] Service has defined SLOs with burn-rate alerting
[ ] Real-time monitoring dashboards exist and are accessible
[ ] On-call rotation is established and trained
[ ] Runbooks exist for common failure scenarios
[ ] Auto-scaling is configured and tested
[ ] PodDisruptionBudgets are defined for all critical services
[ ] Circuit breakers are implemented for all downstream calls
[ ] Rollback procedure is documented and tested

TIER 2: Chaos Infrastructure
[ ] Chaos tool is installed and configured in the production cluster
[ ] RBAC restricts who can run production experiments
[ ] Automatic abort conditions are configured (SLO-based)
[ ] Audit logging captures all experiment details
[ ] Communication channel is set up for experiment notifications
[ ] Two-person approval process is in place

TIER 3: Organizational
[ ] Leadership has approved production chaos experiments
[ ] Legal/compliance has reviewed (for regulated industries)
[ ] Support team is aware of experiment schedule
[ ] Incident process accounts for chaos-induced issues
[ ] Post-experiment reporting process is defined
```

---

## 11. Resilience Scoring & Maturity

### Resilience Score Calculation

A resilience score quantifies how well a system handles failure. Different tools calculate it differently, but the concept is universal:

```
LITMUS RESILIENCE SCORE:
  Score = (Passed Probe Weights / Total Probe Weights) * 100

CUSTOM RESILIENCE SCORE (for organizations building their own):

  Component Score = weighted average of:
    - Experiment Pass Rate:     40%  (% of chaos experiments passed)
    - Recovery Time:            25%  (how fast the system recovers)
    - Blast Radius Containment: 20%  (did failure stay contained?)
    - Data Integrity:           15%  (was data preserved?)

  System Score = weighted average of component scores
    (weighted by component criticality)
```

### Tracking Example

```
SERVICE: payment-service
+-------+------------+--------+--------+--------+--------+
| Month | Experiments| Passed | Failed | Score  | Trend  |
+-------+------------+--------+--------+--------+--------+
| Jan   | 4          | 2      | 2      | 50%    | --     |
| Feb   | 6          | 4      | 2      | 67%    | +17%   |
| Mar   | 8          | 7      | 1      | 88%    | +21%   |
| Apr   | 10         | 9      | 1      | 90%    | +2%    |
| May   | 12         | 11     | 1      | 92%    | +2%    |
| Jun   | 12         | 12     | 0      | 100%   | +8%    |
+-------+------------+--------+--------+--------+--------+

NOTE: A sustained 100% is suspicious -- it means experiments are not
challenging enough. Increase experiment complexity.
```

### Chaos Engineering Maturity Model

| Level | Name | Characteristics | Experiments | Frequency | Environment | Org Support |
|---|---|---|---|---|---|---|
| **L0** | None | No chaos engineering practice | None | Never | N/A | None |
| **L1** | Ad-hoc | Individual SREs run experiments manually | Pod kill, basic network | After incidents | Staging only | Informal |
| **L2** | Systematic | Defined experiment catalog, game days | Pod, network, stress, DNS | Quarterly game days | Staging + pre-prod | Team-level buy-in |
| **L3** | Automated | Chaos in CI/CD, automated experiments | Full fault taxonomy | Monthly game days + CI gates | Pre-prod + limited prod | Engineering-wide buy-in |
| **L4** | Continuous | Always-running chaos, production experiments | Multi-fault, cascading, AZ-level | Weekly automated + monthly game days | Full production | Leadership + compliance buy-in |
| **L5** | Adaptive | AI-driven experiment design, self-healing validation | Auto-generated based on architecture + incidents | Continuous, event-triggered | Everywhere | Cultural norm |

### Moving Between Maturity Levels

**L0 to L1 (1-2 months):**
- Install Chaos Mesh or Litmus in staging
- Run your first pod-kill experiment manually
- Document the result and share with the team
- No approval process needed, just do it

**L1 to L2 (2-4 months):**
- Create an experiment catalog (10+ experiments)
- Schedule your first game day
- Define steady-state hypotheses for critical services
- Create an FMEA worksheet for top 3 services
- Get team lead buy-in

**L2 to L3 (3-6 months):**
- Add chaos experiments to CI/CD pipeline
- Automate experiment scheduling (cron)
- Define resilience score thresholds for deployments
- Run first production experiment (pod kill, single pod)
- Get engineering leadership buy-in

**L3 to L4 (6-12 months):**
- Expand production experiments to network faults, dependency faults
- Implement continuous chaos (always running, low intensity)
- Integrate with incident management (chaos findings feed into FMEA)
- AZ failure testing in production
- Get compliance/legal buy-in for regulated industries

**L4 to L5 (12+ months):**
- AI-driven experiment recommendations based on architecture changes
- Automatic resilience regression detection
- Self-healing validation (chaos verifies that auto-remediation works)
- Chaos experiments triggered by deployment events, not just schedules
- Chaos engineering is a cultural expectation, not a specialized practice

### Reporting to Leadership

Leaders need a different view than engineers. Provide:

```
EXECUTIVE RESILIENCE DASHBOARD

Overall Resilience Score: 87% (+5% from last quarter)

  Critical Services:
    Payment Processing:  92%  [===========.]  STRONG
    User Authentication: 88%  [==========..]  GOOD
    Order Management:    85%  [=========...]  GOOD
    Product Catalog:     78%  [========....]  NEEDS ATTENTION
    Notification:        95%  [============]  STRONG

  Key Metrics:
    Chaos experiments run this quarter:     142
    Production experiments:                  38
    Failures discovered before production:   12
    Estimated incidents prevented:            4
    Mean recovery time improvement:          35%

  Risk Areas:
    - Product Catalog: No circuit breaker to search service (RPN: 180)
    - Order Management: Single-AZ database (RPN: 160)

  Next Quarter Focus:
    - AZ failure testing for Product Catalog
    - Database multi-AZ migration for Order Management
    - Expand chaos to CI/CD for all critical services
```

### Benchmarking Against Industry Standards

Based on Gartner and industry surveys (2025):

| Metric | Bottom 25% | Median | Top 25% | Elite |
|---|---|---|---|---|
| Chaos experiment frequency | Quarterly | Monthly | Weekly | Daily/Continuous |
| Production chaos experiments | None | < 10% of experiments | 30-50% in production | > 50% in production |
| Resilience score (critical services) | < 50% | 60-75% | 75-90% | > 90% |
| MTTR improvement from chaos | None measured | 10-20% | 20-40% | > 40% |
| Services covered by chaos | < 10% | 20-40% | 40-70% | > 70% |
| Game day frequency | Never / annual | Quarterly | Monthly | Bi-weekly + continuous |
| Chaos in CI/CD | None | Manual gate | Automated for critical | All services gated |

---

*This reference is a living document. Chaos engineering tooling evolves rapidly -- always use `WebSearch` to verify current tool versions, API changes, and emerging best practices before advising on specific implementations.*
