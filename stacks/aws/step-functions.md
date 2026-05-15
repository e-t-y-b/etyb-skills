---
title: Step Functions
description: "Workflow orchestration on AWS — JSONata + Variables (re:Invent 2024) replace ResultPath/InputPath for new state machines; TestState API GA Mar 2026; Standard for long-running, Express for high-throughput."
product:
  name: Step Functions
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/step-functions/
  notes: "Re:Invent 2024 — JSONata + Variables replace ResultPath/InputPath chains for new state machines; TestState API GA Mar 2026."
---

## What it is

AWS Step Functions is the workflow orchestrator — declarative state machines with built-in error handling, retries, parallel branches, and 200+ optimized SDK integrations across AWS services. Two execution modes: **Standard** (long-running, up to 1 year, per-transition pricing) and **Express** (high-throughput, up to 5 min, per-request pricing).

Canonical surface: [docs.aws.amazon.com/step-functions](https://docs.aws.amazon.com/step-functions/).

## When to use

Reach for Step Functions when:
- The workflow has **state** that persists across steps.
- There's **branching logic** with explicit error compensation.
- You need **human approval** in the loop (wait-for-callback with task token).
- Multiple AWS services participate and you don't want Lambda-as-orchestration code.
- The workflow could take hours, days, weeks (Standard: 1-year max).

Don't reach for Step Functions when:
- The workflow is two Lambda invocations chained. Just chain them.
- High-throughput, short-duration (>50 RPS sustained, <1s execution) — Express fits, but evaluate whether SQS+Lambda fan-in is simpler.

## 2025-2026 currency anchors

- **JSONata + Variables** (re:Invent 2024) replace ResultPath/InputPath/OutputPath/Parameters for state input/output manipulation. Incrementally adoptable per state.
- **TestState API GA Mar 2026** — unit-test individual states before deploying state machines.
- **Distributed Map** state for large-scale fan-out (up to 10K parallel iterations).
- **Workflow Studio** improved visual editor.
- **Optimized SDK integrations** — direct service invocations without Lambda glue.

## Patterns

### JSONata over ResultPath chains (new state machines)

```json
// Old shape (avoid for new state machines)
{
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke",
  "Parameters": {
    "FunctionName": "FetchUser",
    "Payload.$": "$.userId"
  },
  "ResultPath": "$.user",
  "OutputPath": "$",
  "Next": "NextStep"
}

// New shape — JSONata
{
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke",
  "Arguments": "{% { 'FunctionName': 'FetchUser', 'Payload': $userId } %}",
  "Assign": {
    "user": "{% $states.result.Payload %}"
  },
  "Next": "NextStep"
}
```

`Variables` hold values across states without threading them through every state's input/output. Far cleaner than the ResultPath/InputPath/OutputPath/Parameters dance.

### Standard vs Express

| | Standard | Express |
|---|---|---|
| **Max duration** | 1 year | 5 minutes |
| **Throughput** | 2,000 starts/sec | 100,000 starts/sec |
| **Pricing** | Per state transition (~$0.025/1K) | Per request + duration (~$1/M + duration) |
| **History** | Full execution history (3 months) | CloudWatch Logs only |
| **Best for** | Long-running workflows, human-in-the-loop | High-throughput short workflows |

Default for typical workflows: **Standard**. Promote to Express only when measured >100 starts/sec sustained or unit economics demand it.

### TestState API (GA Mar 2026)

```bash
aws stepfunctions test-state \
  --definition file://state-definition.json \
  --role-arn arn:aws:iam::123456789012:role/MyStateMachineRole \
  --input '{"userId": "user-123"}'
```

Use in CI before deploying state machine changes. Catches input-shape errors that previously required full deploys.

### Wait-for-callback (human-in-the-loop)

```json
{
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
  "Parameters": {
    "FunctionName": "RequestApproval",
    "Payload": {
      "approvalRequest.$": "$",
      "taskToken.$": "$$.Task.Token"
    }
  },
  "Next": "ProcessApproval",
  "TimeoutSeconds": 86400
}
```

Lambda gets the task token, sends a notification (email/Slack with a link), and SendTaskSuccess/SendTaskFailure is called from the approval handler. Step Functions waits up to TimeoutSeconds.

### Distributed Map for fan-out

For workloads that need to process thousands-to-millions of items in parallel (e.g., S3 object processing, batch operations):

- Source: S3 prefix, JSON array, CSV, manifest file.
- Iteration: up to 10K parallel child executions.
- ItemBatcher for batching items per iteration.
- Results aggregated to S3.

### Error handling + retry

```json
"Retry": [{
  "ErrorEquals": ["States.TaskFailed"],
  "IntervalSeconds": 2,
  "MaxAttempts": 3,
  "BackoffRate": 2.0,
  "JitterStrategy": "FULL"
}],
"Catch": [{
  "ErrorEquals": ["States.ALL"],
  "Next": "HandleError",
  "ResultPath": "$.error"
}]
```

Use `JitterStrategy: "FULL"` to prevent retry storms.

### Optimized SDK integrations

Many services (Lambda, DynamoDB, SQS, SNS, EventBridge, Athena, etc.) have direct optimized integrations — no Lambda glue needed. Prefer these over invoking a Lambda that calls the SDK.

## Anti-patterns

- **ResultPath/InputPath chains in new state machines.** Use JSONata + Variables.
- **Step Functions for two-Lambda chains.** Just chain them in code.
- **Express for long-running workflows.** Express max = 5 min.
- **No retry/catch on Lambda invoke states.** Transient errors will pop your state machine.
- **Hard-coded ARNs in state machine definitions.** Use Variables and IaC parameters.
- **Lambda glue between two AWS services** — use optimized SDK integration.
- **No alarm on `ExecutionsFailed` metric.** Failed workflows go unnoticed.

## Gotchas

- **Standard execution history is 3 months** then expires. Archive critical run data.
- **Per-state-transition pricing for Standard** — chatty state machines with many small states can cost more than fewer larger states.
- **Express CloudWatch Logs cost** can dominate Express run cost — tune log level.
- **Distributed Map child count cap** — 10K. Larger fan-outs need orchestration via S3 + multiple Map states.
- **`States.IntrinsicFailure`** vs `States.TaskFailed` — different error class; handle separately.
- **Service-quota: max execution rate** is region-specific; verify before high-throughput design.

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — common task target
- [`/stacks/aws/eventbridge/`](/stacks/aws/eventbridge/) — Pipes can trigger Step Functions
- [`/stacks/aws/sqs/`](/stacks/aws/sqs/) — wait-for-callback uses SQS for the response
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — role view; orchestration vs choreography
- [Step Functions integrations list](https://docs.aws.amazon.com/step-functions/latest/dg/connect-supported-services.html)
