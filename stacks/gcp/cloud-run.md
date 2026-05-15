---
title: Cloud Run
description: Serverless container runtime on GCP — gen2 with sidecars, GPU, Direct VPC egress, 60-minute timeouts. The default backend compute primitive.
product:
  name: Cloud Run
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect, devops-engineer, ai-ml-engineer, sre-engineer]
  authoritative_url: https://cloud.google.com/run/docs
  notes: "Gen2 sidecars + GPU GA (L4 + RTX PRO 6000 Preview), Direct VPC egress GA, 60-min HTTP timeout, multi-container — features moved fast through 2025-2026."
---

## What it is

Cloud Run is GCP's serverless container runtime. You hand it an OCI image; Google runs it, autoscales it (to zero by default), terminates TLS, integrates with IAM, and bills per request CPU/memory time. Gen2 (the current execution environment) added sidecars, GPU, Direct VPC egress, and 60-minute HTTP timeouts — closing most of the gaps that used to push teams toward GKE.

Cloud Run is the **default backend compute primitive on GCP in 2026**. Start here; promote to GKE only when you have a specific K8s-API need. Authoritative reference: [cloud.google.com/run/docs](https://cloud.google.com/run/docs).

## When to use

Pick Cloud Run when:

- Stateless HTTP / gRPC service, request/response shape
- You want autoscale-to-zero (sparse traffic, dev/staging)
- The team doesn't want to operate Kubernetes
- You need GPU inference but not multi-GPU model parallelism
- Multi-container service is enough — you don't need DaemonSets, privileged containers, custom CNI

Escalate to **GKE Autopilot** when:
- You need K8s APIs (CRDs, custom controllers, Service Mesh)
- Sustained utilization >70% (GKE Autopilot wins on cost)
- Multi-pod coordination, StatefulSets, persistent volumes with specific topology

Escalate to **GKE Standard** when:
- Autopilot blocks something you need (DaemonSets, privileged pods, eBPF, specific node topology)
- Multi-GPU model parallelism, custom hardware

Don't use **App Engine** for greenfield. Cloud Run is simpler and not in maintenance mode.

For deeper compute-primitive selection, see [system-architect on GCP](/stacks/gcp/system-architect/).

## 2025-2026 currency anchors

What changed that older training data misses:

- **Gen2 is the default execution environment.** Gen2 sidecars (multi-container per service), gen2 GPU (NVIDIA L4 GA, RTX PRO 6000 Blackwell in Preview), gen2 Direct VPC egress (no Serverless VPC Access connector for most cases), gen2 jobs with parallelism.
- **HTTP timeout: 60 minutes** (services), 24 hours (jobs). Old "Cloud Run is for sub-5-minute requests" claim is wrong.
- **Concurrency configurable up to 1000 per instance** (gen2). Default 80. Set deliberately.
- **Direct VPC egress** (GA) replaces Serverless VPC Access connector for most cases. Connector is still required for some edge cases.
- **`gcloud run functions deploy --gen2`** under the hood creates a Cloud Run service — the Cloud Run vocabulary is now canonical even for what was "Cloud Functions gen2."
- **`gcr.io` is deprecated** as an image source — point Cloud Run at Artifact Registry (`<region>-docker.pkg.dev/...`).

## Patterns

### Production-grade deploy defaults

```bash
gcloud run deploy api \
  --image=us-central1-docker.pkg.dev/proj/repo/api:v1.2.3 \
  --region=us-central1 \
  --concurrency=200 \
  --cpu=2 \
  --memory=1Gi \
  --min-instances=1 \
  --max-instances=50 \
  --timeout=120s \
  --service-account=api-runtime@proj.iam.gserviceaccount.com \
  --set-secrets=DB_PASSWORD=db-password:latest \
  --vpc-egress=private-ranges-only \
  --network=projects/proj/global/networks/prod-vpc \
  --subnet=projects/proj/regions/us-central1/subnetworks/run-subnet \
  --ingress=internal-and-cloud-load-balancing \
  --no-allow-unauthenticated
```

Key choices, in order:
- **`--service-account`** is mandatory in prod. Default Compute SA has way too much. Bind a per-service runtime SA with least-privilege roles.
- **`--no-allow-unauthenticated`** + GLB / IAP for public ingress; never put a service directly on the public internet without Cloud Armor in front.
- **`--vpc-egress=private-ranges-only`** + Direct VPC egress for database connectivity. No Serverless VPC Access connector for new builds.
- **`--min-instances=1`** only when latency-sensitive (cold start > tolerance). Otherwise 0; let it scale to zero.
- **`--max-instances`** caps downstream blast — set it deliberately based on what the database / API / third-party can absorb.

### Sidecar pattern (gen2)

The most underused Cloud Run feature. Run an auxiliary container alongside your main app in the same service:

```bash
gcloud run deploy api \
  --image=us-central1-docker.pkg.dev/proj/repo/api:latest \
  --add-containers=name=otel-collector,image=otel/opentelemetry-collector-contrib:latest \
  --region=us-central1
```

Common sidecar uses:
- **OpenTelemetry Collector** — app exports OTLP to localhost:4317, sidecar batches and forwards to Cloud Trace / Monitoring or a non-GCP backend
- **Nginx** for static file serving alongside an app server
- **Cloud SQL Auth Proxy** — though Direct VPC egress + PSC is the cleaner pattern in 2026

### Concurrency / CPU / memory tuning

| Dimension | Default | When to change |
|-----------|---------|----------------|
| Concurrency | 80 requests/instance | Raise to 200-1000 for IO-bound; reduce to 1-10 for CPU-bound or memory-fat-per-request |
| CPU | 1 vCPU, throttled when idle | Set "Always allocated" for background work; raise to 2/4/8 for CPU-bound |
| Memory | 512 MiB | Raise to match working set; OOM-killing is loud and obvious in logs |
| Min instances | 0 | Set 1+ when cold-start latency unacceptable (>500ms p99) |
| Max instances | 100 | Tune to protect downstreams; pair with max-concurrency for predictable load shape |
| Timeout | 300s | Raise up to 3600s (60min) for long requests; consider Cloud Run Jobs if truly batch |

### Cloud SQL / AlloyDB connectivity

Three patterns, in 2026 order of preference:

1. **Direct VPC egress + Private Service Connect** to Cloud SQL/AlloyDB. Clean, no sidecar, supported on gen2. Default.
2. **Cloud SQL Auth Proxy sidecar** — when you need IAM database authentication and per-request rotation.
3. **Public IP + authorized networks** — only for dev / non-prod / regulated cases where private connectivity is unavailable.

### Traffic splitting + canary

Built-in. Deploy a new revision with no traffic, then route gradually:

```bash
gcloud run deploy api --image=... --tag=canary --no-traffic
gcloud run services update-traffic api --to-tags=canary=10
# verify metrics; if good:
gcloud run services update-traffic api --to-tags=canary=100
```

The cheapest production canary path on GCP. See [Cloud Deploy](/stacks/gcp/cloud-deploy/) for delivery pipelines with approval gates.

## Anti-patterns

- **`gcr.io/proj/image:tag` in `--image`** — deprecated; use Artifact Registry hostnames.
- **`--allow-unauthenticated`** on a public service without Cloud Armor + GLB in front — inviting bots and DDoS.
- **Service account JSON key in env var** — use a runtime SA (no key); use WIF for outbound to non-GCP.
- **Serverless VPC Access connector** as default for VPC egress — Direct VPC egress is the gen2 default.
- **`--min-instances` = `--max-instances`** with no rationale — you're paying for capacity you may not need; let autoscaling work.
- **Polling Pub/Sub from a Cloud Run service** — use push subscription instead; pull only when you need explicit flow control.
- **Synchronous chains of Cloud Run calls** that exceed user-tolerance latency — break into async via [Pub/Sub](/stacks/gcp/pub-sub/) + [Workflows](/stacks/gcp/cloud-run/).
- **Default Compute Engine SA** as the runtime SA — over-privileged; bind a per-service SA.

## Gotchas

- **Cold starts** for gen2 are good but not zero. `min-instances=1` eliminates them at the cost of an always-on instance. Tune for the latency contract, not aspirationally.
- **Concurrency interacts with downstream pooling.** A service with `--concurrency=200` and an undersized Cloud SQL connection pool will starve. Right-size the pool to match `max-instances × pool-per-instance`.
- **Direct VPC egress requires a `/26` subnet** dedicated to Cloud Run. Plan IP space accordingly.
- **HTTP/2 + gRPC** work end-to-end via the GLB; bidirectional streaming has gotchas (request-scoped containers vs long-lived connections). Verify against current Cloud Run docs.
- **Logs and traces correlate via the `trace` field** in structured logs — set it explicitly via `X-Cloud-Trace-Context` or OTLP context propagation.
- **Pub/Sub push to Cloud Run** authenticates via OIDC token — verify it; respond 200 to ACK, 4xx/5xx to NACK.

## Cross-references

- Related products in this Stack: [Cloud Run Jobs](/stacks/gcp/cloud-run-jobs/), [Cloud Run functions](/stacks/gcp/cloud-functions/), [GKE Autopilot](/stacks/gcp/gke-autopilot/), [GKE](/stacks/gcp/gke/), [Pub/Sub](/stacks/gcp/pub-sub/), [Cloud Armor](/stacks/gcp/cloud-armor/), [Artifact Registry](/stacks/gcp/artifact-registry/)
- Role overlays: [backend-architect on GCP](/stacks/gcp/backend-architect/), [system-architect on GCP](/stacks/gcp/system-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/) (for GPU)
- Authoritative source: [cloud.google.com/run/docs](https://cloud.google.com/run/docs) — [release notes](https://cloud.google.com/run/docs/release-notes)
