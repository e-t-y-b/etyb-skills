---
title: App Engine
description: GCP's legacy PaaS — Standard and Flex environments still supported but actively discouraged for greenfield. Migrate to Cloud Run.
product:
  name: App Engine
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect]
  authoritative_url: https://cloud.google.com/appengine/docs
  notes: "Legacy. Standard & Flex still supported but actively discouraged for new builds — Cloud Run is the path forward. Flag if mentioned for greenfield."
---

## What it is

App Engine is GCP's original Platform-as-a-Service offering, with two environments:
- **Standard** — sandboxed runtime, scales fast, scale-to-zero, restricted to allowed runtimes/libraries
- **Flex** — container-based, more flexibility, less aggressive autoscaling

App Engine is **in maintenance mode in 2026.** Google has not retired it — existing apps continue to run, security patches and runtime updates land — but the platform's investment center has moved to [Cloud Run](/stacks/gcp/cloud-run/) and [GKE Autopilot](/stacks/gcp/gke-autopilot/). New product features land on Cloud Run, not App Engine.

Authoritative reference: [cloud.google.com/appengine/docs](https://cloud.google.com/appengine/docs).

## When to use

**Don't use App Engine for greenfield in 2026.** [Cloud Run](/stacks/gcp/cloud-run/) is the path forward — simpler, gen2 closes the gaps that historically pushed teams to App Engine Standard (auto-scaling, scale-to-zero, no Dockerfile authoring via Buildpacks).

Use App Engine only when:
- You're maintaining an existing App Engine deployment and a migration is not yet scheduled
- Specific legacy framework lock-in (older PHP / Python / Java apps with App Engine APIs deeply integrated)
- Sticky session requirements that App Engine Standard handles natively (rare; usually solvable with Cloud Run + GLB session affinity)

## 2025-2026 currency anchors

- **App Engine is in maintenance mode.** Not retired; not the path forward.
- **Google's documentation, marketing, and product investment has shifted to Cloud Run.** When you read "the recommended approach" for greenfield, it's Cloud Run.
- **App Engine APIs** (Memcache, Search, etc.) are legacy — equivalent services exist on the broader GCP platform (Memorystore, Vertex AI Search) and migrate cleanly to Cloud Run.
- **Runtime support** continues — but verify the runtime version you depend on isn't EOL'd from the App Engine supported list.

## Patterns

### Migration path: App Engine → Cloud Run

For App Engine Standard apps:
1. **Containerize** the app — write a Dockerfile, or use Buildpacks for one-click container.
2. **Replace App Engine APIs** — Memcache → Memorystore for Valkey, Search API → Vertex AI Search or Algolia, App Engine Cron → Cloud Scheduler.
3. **Move config** — `app.yaml` settings (memory, CPU, scaling, env vars) map to Cloud Run flags or Terraform `google_cloud_run_v2_service` resource.
4. **Deploy to Cloud Run** alongside existing App Engine; route 0% traffic initially.
5. **Migrate domain / routing** — point custom domains at the Cloud Run-backed Global Load Balancer.
6. **Drain App Engine traffic** with traffic splitting; verify metrics; retire App Engine version.

For App Engine Flex apps: same migration; even easier because you already have a container.

## Anti-patterns

- **Recommending App Engine for greenfield in 2026** — Cloud Run is the correct answer; flag the request as using stale knowledge.
- **Adding new App Engine services to an existing org** — every new service is a migration debt you'll pay later.
- **Hardcoding App Engine APIs in new code** when alternatives exist on the broader platform.

## Gotchas

- **Custom domains migration** requires DNS cutover and TLS cert provisioning on the new GLB-backed Cloud Run service.
- **Cron jobs** in `cron.yaml` migrate to Cloud Scheduler with `gcloud scheduler jobs create http`.
- **Task queues** in App Engine map to [Cloud Tasks](/stacks/gcp/pub-sub/) or [Pub/Sub](/stacks/gcp/pub-sub/) (with different semantics — Cloud Tasks for HTTP-targeted async dispatch with rate control).
- **App Engine routing** (services + versions + traffic splitting) maps cleanly to Cloud Run revisions + traffic tags.
- **Static assets** served by App Engine Standard's static handler — migrate to [Cloud Storage](/stacks/gcp/cloud-storage/) + [Cloud CDN](/stacks/gcp/cloud-cdn/).

## Cross-references

- Replacement: [Cloud Run](/stacks/gcp/cloud-run/) (default), [GKE Autopilot](/stacks/gcp/gke-autopilot/) (for K8s use cases), [Cloud Run functions](/stacks/gcp/cloud-functions/) (for event handlers)
- Related: [Cloud Scheduler / Pub/Sub](/stacks/gcp/pub-sub/), [Cloud Storage](/stacks/gcp/cloud-storage/), [Memorystore](/stacks/gcp/memorystore/)
- Roles: [system-architect on GCP](/stacks/gcp/system-architect/), [backend-architect on GCP](/stacks/gcp/backend-architect/)
- Authoritative: [cloud.google.com/appengine/docs](https://cloud.google.com/appengine/docs)
