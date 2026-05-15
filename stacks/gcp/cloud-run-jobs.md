---
title: Cloud Run Jobs
description: Run-to-completion containerized workloads on Cloud Run — batch processing, scheduled jobs, parallel task execution up to 24 hours.
product:
  name: Cloud Run Jobs
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/run/docs/create-jobs
  notes: "Stable; max 24-hour task timeout, parallel task execution; pairs with Cloud Scheduler"
---

## What it is

Cloud Run Jobs runs containerized workloads to completion — single invocation, finite work, exit code matters. Same runtime substrate as [Cloud Run services](/stacks/gcp/cloud-run/), but the unit of work is "execute and exit," not "serve HTTP requests."

Tasks within a job can run in parallel; a job can fan out to multiple tasks each processing a partition of the input. Task timeout up to 24 hours.

Authoritative reference: [cloud.google.com/run/docs/create-jobs](https://cloud.google.com/run/docs/create-jobs).

## When to use

Pick Cloud Run Jobs when:
- Batch processing with finite work (nightly reports, data migrations, ML batch scoring)
- Scheduled execution via Cloud Scheduler (cron-like)
- Run-to-completion ETL jobs that fit the container model
- Work parallelizable across N tasks with index-based partitioning

Don't use Cloud Run Jobs when:
- Workload is long-running orchestration with state — use [Workflows](/stacks/gcp/cloud-run/) or compose with [Pub/Sub](/stacks/gcp/pub-sub/) + Cloud Run services
- Work exceeds 24h task timeout — drop to GKE `Job` or [Dataflow](/stacks/gcp/dataflow/)
- Workload is data-parallel batch over massive datasets — [Dataflow](/stacks/gcp/dataflow/) is purpose-built

## 2025-2026 currency anchors

- **24-hour task timeout** is current (up from earlier limits). Long batch jobs feasible without splitting.
- **Parallelism + task index** environment variable (`CLOUD_RUN_TASK_INDEX`) lets a single job fan out across N tasks; each task handles its partition.
- **Cloud Scheduler → Cloud Run Jobs** is the standard scheduled-batch pattern; replaces the older "Cloud Run service + scheduler trigger" hack.
- **`gcloud run jobs execute --wait`** synchronously waits — useful for CI but watch for CI timeout.

## Patterns

### Create + schedule a nightly job

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

# Schedule via Cloud Scheduler
gcloud scheduler jobs create http nightly-report-trigger \
  --location=us-central1 \
  --schedule="0 2 * * *" \
  --time-zone="America/Los_Angeles" \
  --uri="https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/proj/jobs/nightly-report:run" \
  --http-method=POST \
  --oauth-service-account-email=scheduler@proj.iam.gserviceaccount.com
```

### Task fan-out

```python
import os

task_index = int(os.environ["CLOUD_RUN_TASK_INDEX"])
task_count = int(os.environ["CLOUD_RUN_TASK_COUNT"])

# Partition work by index
all_records = list_records()
my_records = all_records[task_index::task_count]
for record in my_records:
    process(record)
```

10 tasks running 5 in parallel processes ~2x faster than serial; cost is the same (paying for task-seconds either way).

## Anti-patterns

- **Cloud Run service + Cloud Scheduler + `/run-job` endpoint** when Cloud Run Jobs covers it natively — fragile, no retry semantics on the scheduler side.
- **Long-running orchestration as a single Job task** — past 24h, you need [Workflows](/stacks/gcp/cloud-run/) or GKE.
- **Parallelism without partitioning** — multiple tasks doing identical work isn't faster; partition by task index.
- **Polling for completion from CI** — use `--wait` or Pub/Sub completion event.

## Gotchas

- **Task timeout vs job timeout**: each task has its own timeout (up to 24h); the job orchestrates them. Configure both.
- **Cloud Scheduler → Cloud Run Job auth**: use `--oauth-service-account-email` with `roles/run.invoker` on the job, not a plain HTTPS call.
- **Logs are per-task**: filter Cloud Logging by `task_index` for debugging a specific shard.
- **Failed tasks don't auto-retry within a job execution** beyond the configured `--max-retries`; on permanent failure the execution is marked failed and orchestration is your responsibility.

## Cross-references

- Related: [Cloud Run](/stacks/gcp/cloud-run/), [Pub/Sub](/stacks/gcp/pub-sub/), [Dataflow](/stacks/gcp/dataflow/)
- Roles: [backend-architect on GCP](/stacks/gcp/backend-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/run/docs/create-jobs](https://cloud.google.com/run/docs/create-jobs)
