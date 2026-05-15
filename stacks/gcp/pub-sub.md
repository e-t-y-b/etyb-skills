---
title: Pub/Sub
description: GCP's foundational messaging substrate — push/pull subscriptions, BigQuery + Cloud Storage subscriptions, exactly-once delivery (opt-in), DLQs.
product:
  name: Pub/Sub
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/pubsub/docs
  notes: "Foundational. BigQuery subscription + Cloud Storage subscription patterns mature; exactly-once delivery GA but use sparingly."
---

## What it is

Pub/Sub is GCP's foundational asynchronous messaging service — publish to topics, subscribers consume via push (HTTP webhook) or pull (client polls). Global, durable, at-least-once delivery by default with opt-in exactly-once.

Pub/Sub is the default event bus on GCP. Pair with [Eventarc](/stacks/gcp/cloud-run/) for centralized routing patterns, [Cloud Run](/stacks/gcp/cloud-run/) for consumer endpoints, and direct subscriptions to [BigQuery](/stacks/gcp/bigquery/) / [Cloud Storage](/stacks/gcp/cloud-storage/) when you don't need a compute hop.

Authoritative reference: [cloud.google.com/pubsub/docs](https://cloud.google.com/pubsub/docs).

## When to use

Pick Pub/Sub when:
- Fan-out event broadcast to multiple consumers
- Decoupling producers from consumers
- Backpressure-resilient async dispatch
- Stream ingestion into BigQuery / Cloud Storage / Cloud Run

When you need:
- **Cron-like scheduled trigger** (run X at 2am daily) → Cloud Scheduler
- **Async dispatch with deferred execution / rate control** (run X within N seconds, max Y RPS) → Cloud Tasks
- **Long-running multi-step workflow with state** → [Workflows](/stacks/gcp/cloud-run/)
- **Centralized event governance with multi-consumer pipelines** → Eventarc Advanced

## 2025-2026 currency anchors

- **BigQuery subscription** (GA) — Pub/Sub messages written directly to BigQuery tables; no Cloud Run hop for the simple ingest case.
- **Cloud Storage subscription** (GA) — buffer Pub/Sub messages to Cloud Storage files (batched by time or size); cold-archive of event streams.
- **Exactly-once delivery** (GA, opt-in per subscription) — trade throughput for guarantee. **Idempotent handlers are always cheaper than exactly-once.**
- **Eventarc Advanced** (GA Aug 2025) layers a centralized bus + distributed pipelines on top of Pub/Sub.

## Patterns

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

Skip the Cloud Run hop when downstream is BigQuery:

```bash
gcloud pubsub subscriptions create events-to-bq \
  --topic=events \
  --bigquery-table=proj:dataset.events_raw \
  --use-topic-schema \
  --write-metadata
```

Pub/Sub validates schema (Avro/Protobuf), writes directly. Faster, cheaper, fewer moving parts than "Pub/Sub → Cloud Run function → BigQuery streaming insert."

### Topic + Cloud Storage subscription

```bash
gcloud pubsub subscriptions create events-to-gcs \
  --topic=events \
  --cloud-storage-bucket=event-archive \
  --cloud-storage-file-prefix=events- \
  --cloud-storage-max-bytes=10MB \
  --cloud-storage-max-duration=300s
```

Batched archive for cold storage of event streams.

### Dead-letter topic

Always configure on production subscriptions. Without a DLQ, poison messages retry forever and exhaust your downstream.

```bash
gcloud pubsub topics create orders-dlq
gcloud pubsub subscriptions create orders-dlq-sub --topic=orders-dlq
```

## Anti-patterns

- **No DLQ on Pub/Sub subscriptions** — guaranteed pain when poison messages arrive.
- **Exactly-once delivery enabled reflexively** — throughput cost is real; idempotent handlers are usually cheaper.
- **Pub/Sub for delayed execution** — Pub/Sub doesn't natively support delayed delivery beyond a very short window. Use **Cloud Tasks** with `scheduleTime`.
- **Polling Pub/Sub from a Cloud Run service** — use push subscription instead; pull only with explicit flow control needs.
- **Pub/Sub → Cloud Run function → BigQuery insert** when BigQuery subscription would do — extra hop, extra cost, extra failure surface.

## Gotchas

- **Ack-deadline** must exceed your handler's p99 latency, or you'll see redeliveries during slow requests.
- **Message ordering** is opt-in per topic + subscription with `--enable-message-ordering`; without it, order is not guaranteed.
- **Schema enforcement** via topic schemas (Avro / Protobuf) lets BigQuery / consumers reject malformed payloads at publish time.
- **Pub/Sub emulator** for local development; differs from prod on some edge cases (e.g., flow control).

## Cross-references

- Related: [Cloud Run](/stacks/gcp/cloud-run/), [BigQuery](/stacks/gcp/bigquery/), [Cloud Storage](/stacks/gcp/cloud-storage/), [Dataflow](/stacks/gcp/dataflow/)
- Roles: [backend-architect on GCP](/stacks/gcp/backend-architect/), [system-architect on GCP](/stacks/gcp/system-architect/)
- Authoritative: [cloud.google.com/pubsub/docs](https://cloud.google.com/pubsub/docs)
