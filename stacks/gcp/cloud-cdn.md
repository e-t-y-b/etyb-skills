---
title: Cloud CDN
description: Google's global content delivery network — pairs with GLB for edge caching, integrates with Cloud Armor for protection, signed URLs for paywalled content.
product:
  name: Cloud CDN
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect, devops-engineer]
  authoritative_url: https://cloud.google.com/cdn/docs
  notes: "Mature. Pairs with Global External Application LB; integrated with Cloud Armor; signed URLs for paywalled content; backed by Google's global edge."
---

## What it is

Cloud CDN is GCP's edge caching layer on top of Global External Application Load Balancers. Serves cached responses from Google's edge POPs; passes through to backend services on cache miss; integrates natively with [Cloud Armor](/stacks/gcp/cloud-armor/), Cloud Storage (backend buckets), and Cloud Run / GKE backends.

Authoritative reference: [cloud.google.com/cdn/docs](https://cloud.google.com/cdn/docs).

## When to use

Pick Cloud CDN when:
- Public web / API surface with cacheable responses (static assets, immutable resources, GET endpoints with cache-control headers)
- Global audience — Google's edge POPs are extensive
- Stack is already GLB + Cloud Run / GKE / Cloud Storage — CDN adds with a flag

Don't pick Cloud CDN when:
- Traffic pattern is mostly cache-miss (highly dynamic) — caching adds no value
- Backend egress is the cost driver — caching only helps with repeat content
- Existing CDN (Cloudflare, Fastly) is in place and works

## 2025-2026 currency anchors

- **Cache key customization** for fine-grained cache hit ratio.
- **Signed URLs / Signed Cookies** for paywalled content.
- **Cloud CDN logs** integrate into Cloud Logging.
- **Origin failover** through GLB backend health checks.

## Patterns

### Enable CDN on a backend service

```bash
gcloud compute backend-services update my-backend \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400
```

Cache modes:
- `CACHE_ALL_STATIC` — heuristics cache static-typed responses
- `USE_ORIGIN_HEADERS` — respect Cache-Control / Expires
- `FORCE_CACHE_ALL` — cache everything regardless of headers (use carefully)

### Backend bucket for Cloud Storage origin

```bash
gcloud compute backend-buckets create public-assets \
  --gcs-bucket-name=my-public-assets \
  --enable-cdn

gcloud compute url-maps add-path-matcher my-url-map \
  --path-matcher-name=assets \
  --default-service=my-app \
  --backend-bucket-path-rules="/assets/*=public-assets"
```

Static assets served from Cloud Storage through Cloud CDN with no app-server hop.

## Anti-patterns

- **CDN without explicit Cache-Control headers** — relying on heuristics is fragile.
- **No purge mechanism** for emergency content removal — purge via gcloud or Cache Invalidation API.
- **Caching authenticated responses** without `Vary: Authorization` — cross-user data leak.
- **No Cloud Armor in front** — caching attack traffic.

## Gotchas

- **Cache invalidation** is best-effort with a few-minute propagation; design URLs with content hashes to bust cache deterministically.
- **CDN logs** can be voluminous; route to BigQuery via log sink for analysis.
- **Pricing** distinguishes cache hits (cheap) from cache fills (slightly more expensive than origin egress). Tune cache TTLs.

## Cross-references

- Related: [Cloud Armor](/stacks/gcp/cloud-armor/), [Cloud Storage](/stacks/gcp/cloud-storage/), [Cloud Run](/stacks/gcp/cloud-run/), [VPC](/stacks/gcp/vpc/)
- Roles: [system-architect on GCP](/stacks/gcp/system-architect/), [backend-architect on GCP](/stacks/gcp/backend-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/cdn/docs](https://cloud.google.com/cdn/docs)
