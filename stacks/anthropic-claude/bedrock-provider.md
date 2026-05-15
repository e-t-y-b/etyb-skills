---
title: Bedrock Provider
description: "Claude-on-AWS via Bedrock InvokeModel/Converse. Same Messages API surface, different model IDs (`anthropic.claude-sonnet-4-7-20260301-v1:0`), AWS IAM credentials, AWS billing, AWS region availability."
product:
  name: Bedrock provider
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/api/claude-on-amazon-bedrock
  notes: "AWS-resident customers only; verify regional availability per model; feature parity lags Anthropic API by weeks-to-months."
---

## What it is

Claude-on-AWS via Amazon Bedrock. The same Claude models accessible through Bedrock's InvokeModel / Converse APIs, with AWS-native auth (IAM), AWS billing, and per-region availability. Same Messages API surface as the [Anthropic API](/stacks/anthropic-claude/claude-api/); different model ID format (`anthropic.claude-sonnet-4-7-20260301-v1:0`-style ARN); different credential handling.

The [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) provides `AnthropicBedrock` as a drop-in alternative to `Anthropic`:

```python
from anthropic import AnthropicBedrock
client = AnthropicBedrock(aws_region="us-east-1")
```

See [Anthropic on Amazon Bedrock](https://docs.anthropic.com/en/api/claude-on-amazon-bedrock).

## When to use

Bedrock is right when:

- **You're AWS-resident** with VPC / PrivateLink requirements.
- **AWS-consolidated billing** matters — single invoice, AWS Marketplace credits apply.
- **AWS-native compliance posture** is required — Bedrock inherits AWS's BAA / SOC 2 / ISO 27001 / FedRAMP, etc.
- **EU data residency** — Bedrock EU regions (Frankfurt, Ireland, etc.) keep data in-region.
- **No separate Anthropic relationship needed.** You don't need an Anthropic enterprise contract; the relationship is with AWS.
- **IAM credential model** simplifies your auth story (and audit trail).

Use the [Anthropic API](/stacks/anthropic-claude/claude-api/) instead when:

- **You need bleeding-edge features** (beta flags, day-1 model availability, latest tool versions). Anthropic API ships first; Bedrock lags weeks-to-months.
- **You're not AWS-resident.** Provider mostly matters for cloud-native reasons; without those, Anthropic API is lower-friction.

## 2025-2026 currency anchors

- **Bedrock + Vertex + Anthropic API parity** is now real but lagging. Verify per-feature in current docs before committing.
- **Models:** parity within ~2-4 weeks of Anthropic API release (verify per-model).
- **Prompt caching:** available on Bedrock; verify exact behavior — historically had different limits or invalidation rules.
- **Tool use:** parity.
- **Extended Thinking:** parity on current 4.x models.
- **Computer Use:** historically Anthropic-API-first; check current Bedrock status.
- **Memory tool:** newer feature; verify Bedrock availability.
- **Files API:** verify per-provider; sometimes Anthropic-API-only initially. Bedrock has its own batch inference and S3-based document handling that doesn't 1:1 map.
- **Bedrock Batches** — Bedrock has its own batch inference surface (different API from Anthropic's [Batches API](/stacks/anthropic-claude/batches-api/)).
- **Beta flags / preview features:** Bedrock usually doesn't carry beta surfaces.

## Patterns + anti-patterns

### Pattern — pin model IDs in Bedrock format

`anthropic.claude-sonnet-4-7-20260301-v1:0` is the Bedrock model ID format. Maintain a canonical-model → per-provider-ID mapping in your config:

```python
MODELS = {
    "sonnet": {
        "anthropic": "claude-sonnet-4-7-20260301",
        "bedrock": "anthropic.claude-sonnet-4-7-20260301-v1:0",
        "vertex": "claude-sonnet-4-7@20260301",
    },
}
```

### Pattern — IAM role with least privilege

Bedrock auth uses AWS IAM. Scope the role to specific Bedrock model ARNs needed; don't reuse a broad role. Use IAM conditions to restrict by VPC endpoint, source IP, or tag.

### Pattern — PrivateLink for in-VPC traffic

For AWS-resident workloads with strict network isolation, use Bedrock VPC endpoints (PrivateLink). Traffic stays inside your VPC; no internet egress.

### Pattern — region proximity for latency

Bedrock's regional control gives you latency wins. Run your service in the same region as your Bedrock endpoint. `us-east-1` Bedrock with `us-east-1` Lambda beats `us-east-1` Bedrock with `eu-west-1` Lambda.

### Pattern — Bedrock as failover for Anthropic API

For mission-critical: primary on Anthropic API, secondary on Bedrock. Account for:

- Different credentials per provider.
- Different model ID mappings.
- Cold cache on the secondary (caches are provider-scoped).
- Feature-parity gaps (the secondary may lack a beta flag the primary used).
- Bedrock rate-limit profile (quotas per AWS account / region, not Anthropic-tier).

### Anti-pattern — Bedrock with Anthropic-API-only features

Service depends on a beta flag that ships Anthropic-API-first. You set up Bedrock for compliance. Feature doesn't work. Design for lowest-common-denominator, or accept partial degradation. See [system-architect overlay anti-patterns](/stacks/anthropic-claude/system-architect/#anti-pattern--claude-on-bedrock-with-anthropic-api-only-features).

### Anti-pattern — assuming Bedrock parity without verification

"It works on Anthropic API, should work on Bedrock." Verify per-feature against [docs.anthropic.com/en/api/claude-on-amazon-bedrock](https://docs.anthropic.com/en/api/claude-on-amazon-bedrock).

### Anti-pattern — Bedrock configured but not benchmarked

If you'll commit a workload to Bedrock, run the workload on Bedrock for a day before committing. Latency, rate limits, and feature behavior can differ.

## Gotchas

- **Model availability is per-region per-model.** Not all models in all regions. Check current AWS docs for the model × region matrix.
- **Bedrock model access requires enablement.** First-time use requires requesting model access in the Bedrock console per-region — a one-time step (sometimes with a brief approval delay).
- **Bedrock quotas differ from Anthropic API rate limits.** Bedrock uses AWS-style service quotas (RPS, TPS) configurable per AWS account / region. Don't assume your Anthropic API tier maps directly.
- **Billing is on AWS.** No separate Anthropic invoice; consumption shows up in AWS billing under the Bedrock line item.
- **Bedrock's `Converse` API vs `InvokeModel` API** — the [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) abstracts most of this. If you drop down to raw AWS SDK calls, Converse is the newer unified interface.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — same protocol
- [Vertex AI Provider](/stacks/anthropic-claude/vertex-ai-provider/) — GCP-side alternative
- [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) — `AnthropicBedrock` client
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — provider-choice framework
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — failover topology
- [Anthropic on Amazon Bedrock](https://docs.anthropic.com/en/api/claude-on-amazon-bedrock)
