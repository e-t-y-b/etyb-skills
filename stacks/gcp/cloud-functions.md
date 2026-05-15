---
title: Cloud Run functions
description: Event-driven single-purpose function handlers on GCP — formerly Cloud Functions gen2, now branded as Cloud Run functions. Gen1 deprecated.
product:
  name: Cloud Run functions
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://cloud.google.com/functions/docs
  notes: "Branding shift: Cloud Functions gen2 is now officially Cloud Run functions; gen1 deprecated and end-of-support glide path through 2026."
---

## What it is

Cloud Run functions (formerly Cloud Functions gen2) is the function-shaped handler runtime on GCP. Under the hood it creates a [Cloud Run service](/stacks/gcp/cloud-run/) — same substrate, same gen2 features (sidecars, GPU, Direct VPC egress, concurrency control), but with Functions Framework SDK ergonomics: handler signature, Buildpack-built source, event-trigger bindings.

The branding shift in mid-2024 was substantive: the documentation, console, and tooling now bias toward "Cloud Run functions" vocabulary. **Gen1 is deprecated.** New development must use gen2 (or migrate to a Cloud Run service when the handler grows).

Authoritative reference: [cloud.google.com/functions/docs](https://cloud.google.com/functions/docs).

## When to use

Pick Cloud Run functions when:
- Single-purpose event-driven handler (Pub/Sub message → process → done)
- You want Buildpack-built code without authoring a Dockerfile
- One handler per repo / one entry point per deployment
- Cold-start sensitivity is moderate (gen2 cold starts are good, but Cloud Run service with `min-instances=1` is still better for latency-critical paths)

Promote to a **Cloud Run service** when:
- Handler grows beyond one entry point
- You need shared state, custom middleware, sidecars, or finer-grained traffic management
- You want explicit control over container build

Don't use Cloud Functions **gen1**:
- Deprecated. Existing gen1 functions run but new development must target gen2.

## 2025-2026 currency anchors

- **Cloud Functions gen2 is now officially "Cloud Run functions"** — branding shift mid-2024. Same product, new vocabulary.
- **Gen1 deprecated.** End-of-support glide path through 2026. Migrate before pressure mounts.
- **`gcloud run functions deploy --gen2`** under the hood creates a Cloud Run service — manageable via either surface, but **don't mix** the two control planes for the same function.
- **Concurrency is configurable** (up to 1000 in gen2; default 80). Gen1 was always 1-per-instance — gen2 will surface concurrency bugs in handlers that assumed otherwise.
- **GPU support** via Cloud Run substrate is available.

## Patterns

### Pub/Sub-triggered handler (Python)

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
  --max-instances=20 \
  --service-account=fn-runtime@proj.iam.gserviceaccount.com
```

### HTTP-triggered handler

```python
import functions_framework

@functions_framework.http
def hello(request):
    name = request.args.get("name", "world")
    return f"Hello, {name}!"
```

```bash
gcloud run functions deploy hello \
  --gen2 \
  --runtime=python313 \
  --region=us-central1 \
  --source=. \
  --entry-point=hello \
  --trigger-http \
  --no-allow-unauthenticated
```

### Migration from gen1

If you inherit a gen1 codebase:
1. **Update function signature** — gen2 uses Functions Framework SDK; signature changed subtly.
2. **Rewrite triggers** — gen1 used `--trigger-event` for Cloud Storage; gen2 uses Eventarc-style event types.
3. **Test concurrency** — gen1 was always 1-per-instance; gen2 defaults higher, which may surface shared-state bugs.
4. **Rebuild CI/CD** to target the Cloud Run path.
5. **Cutover with rolling deployment** — keep gen1 alive until gen2 is verified, then retire.

## Anti-patterns

- **`gcloud functions deploy --runtime=nodejs14 --gen2`** without auditing whether the runtime is still supported — runtimes age out; check the supported list.
- **No `--gen2` flag on new deploys** — produces deprecated gen1 artifacts.
- **Mixing Cloud Run console and Cloud Functions tooling** on the same deployed function — pick one control plane.
- **Shared state in module globals** — gen2 concurrency means multiple requests share the same process; race conditions appear that gen1's serial model masked.
- **No DLQ on Pub/Sub-triggered functions** — poison messages retry forever.
- **Long-running work in a function** — past a few minutes, escalate to a Cloud Run service or Cloud Run Job.

## Gotchas

- **Buildpacks vs Dockerfile**: Functions Framework defaults to Buildpacks. If you have system dependencies, switch to a Dockerfile and deploy as a Cloud Run service instead — you've outgrown functions.
- **Cold start** for gen2 Python / Node is sub-second for small handlers; large dependency trees push it past 2-3s. Profile.
- **Trigger filters** in Eventarc support attribute-based filtering — use them to avoid waking handlers for irrelevant events.
- **Logs vs Cloud Trace**: structured logging + trace correlation works the same as Cloud Run services. Use [Cloud Logging](/stacks/gcp/logging/) Log Analytics for diagnosis.

## Cross-references

- Related: [Cloud Run](/stacks/gcp/cloud-run/), [Pub/Sub](/stacks/gcp/pub-sub/), [Cloud Run Jobs](/stacks/gcp/cloud-run-jobs/), [Artifact Registry](/stacks/gcp/artifact-registry/)
- Roles: [backend-architect on GCP](/stacks/gcp/backend-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/functions/docs](https://cloud.google.com/functions/docs)
