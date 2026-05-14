---
role: backend-architect
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — backend-architect

You are backend-architect on a GCP engagement. Your runtime is Cloud Run gen2 (default), Cloud Run functions, or GKE Autopilot — not Lambda, not ECS. Your event bus is Pub/Sub + Eventarc Advanced, not EventBridge. Your async orchestration is Workflows + Cloud Tasks + Cloud Scheduler. Your outbound auth pattern is Workload Identity Federation, not access keys. The runtime feature surface shifted meaningfully through 2025-2026 — sidecars, GPU, Direct VPC egress, 60-minute timeouts, gen2 branding rename — and pre-2024 mental models will produce code that runs but misses better defaults.

**Currency:** verified against GCP product surface as of 2026-05-14. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **Cloud Functions gen2 is now officially Cloud Run functions** — same product, new branding. Gen1 deprecated. `gcloud functions deploy --gen2` still works but the doc surface is shifting to Cloud Run vocabulary.
- **Cloud Run gen2 sidecars** (GA) let you run an OpenTelemetry Collector, Envoy, Nginx, or any auxiliary container alongside your main container in the same service. Shared localhost + shared volumes. Major architectural unlock — the "must use GKE for sidecars" claim is obsolete.
- **Cloud Run GPU** is GA (NVIDIA L4, min 4 vCPU / 16 GiB); RTX PRO 6000 Blackwell in Preview. Inference workloads no longer need GKE just for GPU access.
- **Cloud Run Direct VPC egress** (GA) eliminates the Serverless VPC Access connector for most cases. The connector is still required for some edge cases (high-fan-out, specific subnet types) but new builds default to Direct VPC egress.
- **Cloud Run HTTP timeout: 60 minutes** (services), 24 hours (jobs). Old "Cloud Run is for short requests" intuition is wrong.
- **Cloud Run concurrency** is configurable per-instance up to 1000 (gen2). Default 80. Set deliberately based on request shape.
- **Pub/Sub BigQuery subscription** (GA) writes Pub/Sub messages directly into BigQuery tables — no Cloud Run function needed for the simple ingest case.
- **Pub/Sub exactly-once delivery** (GA) — opt-in per subscription; trade throughput for guarantee.
- **Eventarc Advanced** (GA Aug 2025) introduces centralized bus + distributed pipeline model. Eventarc Standard is the point-to-point shape.
- **Workflows** matured into a solid orchestration primitive — YAML/JSON state machines with retries, error handling, parallel execution, connectors to most GCP services.
- **Artifact Registry** is the only path; Container Registry (`gcr.io`) is deprecated.
- **gcloud auth via WIF**: from a CI runner, you authenticate via WIF and run gcloud without ever holding a key file.

If you're recommending `gcloud functions deploy --runtime=nodejs14 --gen2`, Serverless VPC Access connector by default, Container Registry image paths, App Engine for greenfield, or service account JSON keys for CI auth — your training is stale.

## Cloud Run service — production-grade defaults

Cloud Run is the default backend runtime on GCP in 2026. Start here and only escalate to GKE when you have a specific reason.

### Concurrency, CPU, memory — pick deliberately

| Dimension | Default | When to change |
|-----------|---------|----------------|
| Concurrency | 80 requests/instance | Increase to 200-1000 for IO-bound services; reduce to 1-10 for CPU-bound or memory-fat-per-request services |
| CPU | 1 vCPU, throttled-when-idle | Set "Always allocated" (a.k.a. "CPU always on") for background work; raise to 2/4/8 for CPU-bound |
| Memory | 512 MiB | Raise to match working set; OOM-killing is loud and obvious in logs |
| Min instances | 0 | Set to 1+ when cold-start latency matters (>500ms p99 unacceptable) |
| Max instances | 100 | Tune to protect downstream services; pair with max-concurrency for predictable load shape |
| Timeout | 300s | Raise up to 3600s (60min) for long requests; consider Cloud Run Jobs instead if request is truly batch |

```bash
# Production Cloud Run service with reasonable defaults
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

**Authentication shape:** default to `--no-allow-unauthenticated` and put the service behind Identity-Aware Proxy or an internal GLB. Public services use `--ingress=all` + IAM-bound invokers explicitly.

### Sidecar pattern (Cloud Run gen2)

The most underused Cloud Run gen2 feature. Use cases:
- **OpenTelemetry Collector sidecar** — main app exports OTLP to localhost:4317, sidecar batches and forwards to Cloud Trace / Monitoring / Logging or a non-GCP backend
- **Envoy sidecar** for mTLS or advanced traffic shaping (rarely needed on Cloud Run; GKE is usually a better fit)
- **Nginx sidecar** for static file serving alongside an app server
- **SQL proxy sidecar** (`cloud-sql-auth-proxy`) for Cloud SQL connectivity — though Direct VPC egress + Private Service Connect is the cleaner pattern in 2026

```bash
gcloud run deploy api \
  --image=us-central1-docker.pkg.dev/proj/repo/api:latest \
  --add-containers=name=otel-collector,image=otel/opentelemetry-collector-contrib:latest \
  --region=us-central1
```

### Cloud Run Jobs

Run-to-completion workloads. Replaces the "Cloud Run service + Cloud Scheduler trigger" hack for batch.

```bash
gcloud run jobs create nightly-report \
  --image=us-central1-docker.pkg.dev/proj/repo/report:latest \
  --region=us-central1 \
  --tasks=10 \
  --parallelism=5 \
  --task-timeout=3600 \
  --memory=4Gi \
  --service-account=report-runner@proj.iam.gserviceaccount.com

gcloud run jobs execute nightly-report --region=us-central1 --wait
```

Schedule via Cloud Scheduler:
```bash
gcloud scheduler jobs create http nightly-report-trigger \
  --location=us-central1 \
  --schedule="0 2 * * *" \
  --time-zone="America/Los_Angeles" \
  --uri="https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/proj/jobs/nightly-report:run" \
  --http-method=POST \
  --oauth-service-account-email=scheduler@proj.iam.gserviceaccount.com
```

## Cloud Run functions — when functions still make sense

Cloud Run functions (gen2) is the right answer when:
- Single-purpose, event-driven handler (Pub/Sub message → process → done)
- You want Buildpack-built code without authoring a Dockerfile
- Cold-start sensitivity is low (gen2 cold starts are good but Cloud Run service with min-instances=1 is still better for latency-critical paths)

When the function grows beyond one entry point or accumulates shared state, promote to a Cloud Run service.

```python
# main.py
import functions_framework

@functions_framework.cloud_event
def process_order(cloud_event):
    payload = cloud_event.data
    # ... do work
    return ("ok", 200)
```

```bash
gcloud run functions deploy process-order \
  --gen2 \
  --runtime=python313 \
  --region=us-central1 \
  --source=. \
  --entry-point=process_order \
  --trigger-topic=orders \
  --memory=512Mi \
  --concurrency=10 \
  --max-instances=20
```

**The gen2 quirk:** under the hood, `gcloud run functions deploy --gen2` creates a Cloud Run service. You can manage it via Cloud Run console, set min-instances, add sidecars — but the Functions API + tooling still applies. Don't manage the same function via both surfaces.

### Cloud Functions gen1 — migration path

If you inherit a gen1 codebase: gen1 runs but is deprecated. Migration to gen2 / Cloud Run functions:
1. Update function signature (gen2 uses Functions Framework SDK; signature changed subtly)
2. Rewrite triggers (gen1 used `--trigger-event` for Cloud Storage; gen2 uses Eventarc-style event types)
3. Test concurrency — gen1 was always 1-per-instance; gen2 defaults to higher concurrency, which may surface shared-state bugs
4. Rebuild CI/CD to target the Cloud Run path
5. Cutover with a rolling deployment

## Pub/Sub patterns

Pub/Sub is the default messaging substrate on GCP. Patterns to know:

### Topic + push subscription to Cloud Run

Most common pattern. Pub/Sub pushes an authenticated HTTP request to a Cloud Run endpoint:

```bash
gcloud pubsub topics create orders
gcloud pubsub subscriptions create orders-processor \
  --topic=orders \
  --push-endpoint="https://order-processor-xxxxx-uc.a.run.app/" \
  --push-auth-service-account=pubsub-pusher@proj.iam.gserviceaccount.com \
  --ack-deadline=60 \
  --message-retention-duration=7d \
  --dead-letter-topic=orders-dlq \
  --max-delivery-attempts=5
```

Cloud Run side: verify the OIDC token Pub/Sub attaches; respond 200 to ACK, 4xx/5xx to NACK and retry.

### Topic + BigQuery subscription

When the only downstream is BigQuery, skip the Cloud Run hop:

```bash
gcloud pubsub subscriptions create events-to-bq \
  --topic=events \
  --bigquery-table=proj:dataset.events_raw \
  --use-topic-schema \
  --write-metadata
```

Pub/Sub validates schema (Avro/Protobuf), writes directly. Faster, cheaper, fewer moving parts than the "Pub/Sub → Cloud Run function → BigQuery streaming insert" antipattern.

### Topic + Cloud Storage subscription

Buffer Pub/Sub messages to Cloud Storage files (batched by time or size). Useful for cold-archive of event streams.

### Exactly-once delivery

Opt-in per subscription (`--enable-exactly-once-delivery`). Throughput is lower; only enable when the downstream is not idempotent and you can't make it so. **Idempotent handlers are always cheaper than exactly-once.**

### Dead-letter topics

Always configure. Without a DLQ, poison messages retry forever and exhaust your downstream.

## Eventarc — the routing layer

Eventarc Standard routes events from a single source to a single destination (Cloud Run, Cloud Run functions, Workflows). Use for simple decoupling — Cloud Storage object → Cloud Run handler.

Eventarc Advanced (GA Aug 2025) is the enterprise shape:
- **Bus**: centralized event ingestion (governance layer)
- **Pipeline**: per-consumer filtering, transformation, fan-out
- 125+ event sources (every GCP service + third-party via Pub/Sub bridging)

Use Advanced when:
- Multiple teams consume different subsets of the same event stream
- You want centralized event governance with decentralized consumption
- You're standing up an event-driven architecture across many services

```bash
# Eventarc Advanced bus
gcloud eventarc buses create platform-events \
  --location=us-central1 \
  --display-name="Platform Event Bus"

# Pipeline filtering for one consumer
gcloud eventarc pipelines create order-processor \
  --location=us-central1 \
  --bus=platform-events \
  --destination=...
```

## Workflows — stateful orchestration

Workflows is Google's serverless state machine. YAML/JSON definitions with retries, conditional logic, parallel execution, error handling. Use when:
- Multi-step process that must survive process restarts
- Long-running orchestration (>60 min) where Cloud Run service timeout isn't enough
- Cross-service coordination with retry semantics
- Sagas — compensating-transaction patterns for distributed work

Avoid Workflows when:
- The orchestration is simple enough for a Cloud Run handler
- You need millisecond-grained control flow — Workflows step latency is higher
- The team's mental model is "code in Python," not "config in YAML" — adoption friction is real

```yaml
main:
  params: [event]
  steps:
    - validate:
        call: http.post
        args:
          url: https://validator-xxxxx-uc.a.run.app/
          body: ${event}
          auth: { type: OIDC }
        result: validation
    - branch:
        switch:
          - condition: ${validation.body.valid}
            next: process
          - condition: true
            next: reject
    - process:
        call: http.post
        args:
          url: https://processor-xxxxx-uc.a.run.app/
          body: ${event}
          auth: { type: OIDC }
        retry:
          predicate: ${http.default_retry_predicate}
          max_retries: 3
          backoff: { initial_delay: 1, max_delay: 60, multiplier: 2 }
        result: result
    - return:
        return: ${result.body}
    - reject:
        return: { status: "rejected", reason: ${validation.body.reason} }
```

## Cloud Tasks vs Cloud Scheduler vs Pub/Sub

| Need | Use |
|------|-----|
| **Cron-like scheduled trigger** (run X at 2am daily) | Cloud Scheduler |
| **Async dispatch with deferred execution / rate control** (run X within N seconds, max Y RPS) | Cloud Tasks |
| **Fan-out event broadcast to multiple consumers** | Pub/Sub |
| **Long-running multi-step workflow with state** | Workflows |

The most common mistake: using Pub/Sub for "delayed execution" — Pub/Sub doesn't natively support delayed delivery beyond the very short delay window. Use Cloud Tasks with `scheduleTime` for "run this task in 5 minutes" patterns.

## Outbound authentication — Workload Identity Federation

When a Cloud Run service / GKE workload calls another GCP service, it uses its **runtime service account** — no key, no token management. The platform handles it.

When a GCP workload calls an external service (Stripe, GitHub, OpenAI):
- Store the API key in Secret Manager
- Mount as env var or volume in Cloud Run / GKE
- Service account needs `roles/secretmanager.secretAccessor` on the secret

When a GCP workload calls another GCP service in a different project:
- Grant the runtime SA the appropriate IAM role on the target project resource
- Cross-project IAM is fine and well-supported

When a non-GCP workload (GitHub Actions, AWS Lambda, on-prem service) calls GCP:
- Use **Workload Identity Federation**. Configure a workload identity pool + provider, bind it to a GCP service account, and the external workload mints a short-lived federated token.

```bash
# WIF for GitHub Actions
gcloud iam workload-identity-pools create github-pool \
  --location=global \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.aud=assertion.aud" \
  --attribute-condition="assertion.repository_owner == 'my-org'"

gcloud iam service-accounts add-iam-policy-binding deploy@proj.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/github-pool/attribute.repository/my-org/my-repo"
```

In the GitHub Actions workflow:
```yaml
permissions:
  id-token: write
  contents: read
steps:
  - uses: google-github-actions/auth@v2
    with:
      workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider
      service_account: deploy@proj.iam.gserviceaccount.com
  - run: gcloud auth list  # now authenticated
```

**No JSON key file. No long-lived credential.** This is the 2026 baseline.

## Inbound authentication — IAM, IAP, API Gateway

Decision frame for "how do users / clients reach my service":

| Pattern | When |
|---------|------|
| **Public Cloud Run + Cloud Armor + Cloud CDN + GLB** | Public web/API for end users |
| **Cloud Run + Identity-Aware Proxy (IAP)** | Internal tools, employee-facing apps; SSO via Google Identity or external IdP |
| **Cloud Run + custom JWT verification** | API for authenticated end users (Identity Platform handles user identity) |
| **API Gateway + Cloud Run backends** | Multi-team API surface with per-route auth + quota + rate limiting |
| **Apigee** | API-management depth: API products, monetization, advanced policy, developer portal |

Default: public Cloud Run + Cloud Armor + Cloud CDN behind a Global External Application Load Balancer. The GLB gives you a global anycast IP, TLS termination, Cloud CDN integration, and Cloud Armor WAF in one shape.

```bash
# Cloud Armor policy with rate limit + SQLi + XSS preconfigured rules
gcloud compute security-policies create api-protection
gcloud compute security-policies rules create 1000 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable')" \
  --action=deny-403
gcloud compute security-policies rules create 1010 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
  --action=deny-403
gcloud compute security-policies rules create 2000 \
  --security-policy=api-protection \
  --expression="true" \
  --action=throttle \
  --rate-limit-threshold-count=100 \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --enforce-on-key=IP
```

## Cloud SQL / AlloyDB connectivity from Cloud Run

Three patterns, in 2026 order of preference:

1. **Direct VPC egress + Private Service Connect** to Cloud SQL/AlloyDB. Clean, no sidecar, supported on Cloud Run gen2.
2. **Cloud SQL Auth Proxy sidecar** (gen2 sidecar) — still common, slightly more complex; useful when you need IAM database authentication and per-request rotation.
3. **Public IP + authorized networks** — only for dev / non-prod / regulated cases where private connectivity is unavailable.

```bash
# Cloud Run with Direct VPC egress to AlloyDB via PSC
gcloud run deploy api \
  --image=... \
  --vpc-egress=private-ranges-only \
  --network=projects/proj/global/networks/prod-vpc \
  --subnet=projects/proj/regions/us-central1/subnetworks/run-subnet \
  --set-env-vars=DB_HOST=10.40.0.5  # PSC endpoint for AlloyDB
```

## API design patterns

GCP is opinion-light on REST vs gRPC vs GraphQL — pick what fits the workload. Notes:

- **gRPC on Cloud Run** works well; HTTP/2 is supported end-to-end via the GLB; bidirectional streaming has some gotchas (request-scoped containers vs long-lived connections) — verify against current docs.
- **GraphQL on Cloud Run** is fine; consider Apollo Server / Helix / yoga depending on stack. Watch out for per-request CPU pricing when GraphQL queries fan out wide.
- **REST + OpenAPI** remains the default for public APIs; pair with API Gateway or Apigee for management.
- **Async API** patterns (Pub/Sub-driven workflows) — surface them as REST endpoints for client consumption, with the actual work done async via Pub/Sub and Workflows.

## Anti-patterns specific to GCP backend work

- **`gcloud functions deploy --runtime=nodejs14`** — gen1 syntax. Use `--gen2` or migrate to Cloud Run functions vocabulary.
- **`gcr.io/proj/image:tag`** in new Dockerfile FROM lines or in deploy commands. Use Artifact Registry: `<region>-docker.pkg.dev/proj/repo/image:tag`.
- **Service account JSON key in repo / env var** — security antipattern. Use WIF for external workloads, runtime SA for in-GCP workloads.
- **Serverless VPC Access connector** for every Cloud Run VPC need — Direct VPC egress is the gen2 default for most cases.
- **Cloud SQL via public IP + authorized networks** in production — use Private Service Connect.
- **No DLQ on Pub/Sub subscriptions** — guaranteed pain when poison messages arrive.
- **Exactly-once delivery enabled reflexively** — usually idempotent handlers are cheaper.
- **Cloud Run min-instances = max-instances** in production without rationale — you're paying for capacity you might not need; let autoscaling work.
- **No Cloud Armor on public Cloud Run / GKE Ingress** — you're inviting the bots.
- **Polling Pub/Sub from a Cloud Run service** — use push subscription instead; pull only when you need explicit flow control.
- **Synchronous chains of Cloud Run calls** that exceed user-tolerance latency — break into async via Pub/Sub + Workflows.
- **Building a custom retry/backoff layer when Workflows would handle it natively** — the GCP-native primitive is cheaper.

## Tooling specifics

| Tool | Purpose |
|------|---------|
| **gcloud CLI** | Authoritative for all backend deploys; pair with `gcloud config configurations` for multi-env work |
| **Functions Framework SDK** | Standard for Cloud Run functions in Python / Node / Go / Java |
| **`cloud-sql-auth-proxy`** | Local dev connectivity to Cloud SQL/AlloyDB without exposing IPs |
| **Cloud Code** (VS Code / IntelliJ plugin) | Local Cloud Run + GKE dev loop; Gemini Code Assist integration |
| **Buf / Protoc** | gRPC service definitions; pair with Cloud Run / GKE |
| **Testcontainers** | Local integration tests against real Cloud SQL Postgres / AlloyDB Postgres / Spanner emulator |
| **Spanner emulator** | Local Spanner for unit / CI tests; use `gcloud emulators spanner start` |
| **Pub/Sub emulator** | Local Pub/Sub for unit / CI tests; emulator differs from prod on some edge cases — integration tests against real Pub/Sub on a per-project basis |

## Integration with always-on protocols

- **TDD on Cloud Run services**: write the API contract test against a local container (`docker run`) or against an in-process test server before deploying. For Pub/Sub handlers, use the Pub/Sub emulator for unit tests; integration test against a real ephemeral topic.
- **Verification**: every deploy must produce evidence — `gcloud run services describe <name>` output, observed latency in Cloud Monitoring, Cloud Trace span graph for the request path. "It deployed" is not verification.
- **Debugging**: Cloud Trace is the first stop for "why is this slow" — distributed traces from the GLB through Cloud Run to downstream services. Cloud Logging Log Analytics (BigQuery SQL on logs) is the second.
- **Plan execution**: every deploy task in the plan specifies the post-deploy verification (smoke test, contract test, canary metric check).
- **Branch safety**: pre-merge CI runs `terraform plan` (for infra) + container build + contract tests. Direct VPC egress and Cloud SQL connectivity must be tested in staging before prod merge — they're easy to misconfigure and only fail at runtime.

## Verification checklist for backend-architect on GCP

- [ ] Service runtime selected deliberately: Cloud Run service (default), Cloud Run functions (event handlers), GKE Autopilot (K8s API need)
- [ ] Concurrency / CPU / memory / min-instances / max-instances tuned per service shape; no copy-paste defaults
- [ ] Authentication: runtime SA bound to least-privilege roles; no service account JSON keys
- [ ] Outbound auth via WIF for non-GCP callers, runtime SA for in-GCP, Secret Manager for external API keys
- [ ] Pub/Sub subscriptions have DLQ; ack-deadline tuned to handler p99 latency
- [ ] Idempotency posture documented per handler; exactly-once delivery only where justified
- [ ] Cloud Run + database connectivity via Direct VPC egress + PSC, not public IP
- [ ] Cloud Armor + GLB in front of public services
- [ ] No legacy paths: no gcr.io, no Cloud Functions gen1 new development, no Serverless VPC Access connector by default
- [ ] Observability: OpenTelemetry SDK in the service exporting OTLP to Cloud Trace / Monitoring (sidecar collector preferred for fleet consistency)
- [ ] Currency check: feature/syntax recommended is GA or explicitly accepted as Preview; verified against release notes
