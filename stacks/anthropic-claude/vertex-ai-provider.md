---
title: Vertex AI Provider
description: "Claude-on-GCP via Vertex AI. Same Messages API surface; current-gen model IDs match the Claude API (`claude-sonnet-5`), dated snapshots use `@` (`claude-haiku-4-5@20251001`); GCP credentials, GCP billing, GCP region availability."
product:
  name: Vertex provider
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-07-05"
  applies_to_roles: [system-architect, backend-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/api/claude-on-vertex-ai
  notes: "GCP-resident customers only; verify regional availability per model; feature parity lags Anthropic API by weeks-to-months."
---

## What it is

Claude-on-GCP via Vertex AI. The same Claude models accessible through Vertex's model garden, with GCP-native auth (service accounts), GCP billing, and per-region availability. Same Messages API surface as the [Anthropic API](/stacks/anthropic-claude/claude-api/); model IDs for the 4.6 generation and later match the Claude API exactly (`claude-sonnet-5`, `claude-opus-4-8`), while pre-4.6 dated snapshots use an `@` separator (`claude-haiku-4-5@20251001`); different credential handling.

The [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) provides `AnthropicVertex` as a drop-in alternative to `Anthropic`:

```python
from anthropic import AnthropicVertex
client = AnthropicVertex(project_id="my-gcp-project", region="us-east5")
```

See [Anthropic on Vertex AI](https://docs.anthropic.com/en/api/claude-on-vertex-ai).

## When to use

Vertex is right when:

- **You're GCP-resident** with VPC / Private Service Connect requirements.
- **GCP-consolidated billing** matters — single invoice, GCP credits apply.
- **GCP-native compliance posture** is required — Vertex inherits GCP's BAA / SOC 2 / ISO 27001.
- **EU data residency** — Vertex EU regions (Frankfurt, etc.) keep data in-region.
- **Service-account credential model** simplifies your auth story.

Use the [Anthropic API](/stacks/anthropic-claude/claude-api/) instead when:

- **You need bleeding-edge features** (beta flags, day-1 model availability, latest tool versions). Anthropic API ships first; Vertex lags weeks-to-months.
- **You're not GCP-resident.** The provider mostly matters for cloud-native compliance/billing reasons; without those, Anthropic API is lower-friction.

## 2025-2026 currency anchors

- **Bedrock + Vertex + Anthropic API parity** is now real but lagging. Verify per-feature in current docs before committing.
- **Models:** parity within ~2-4 weeks of Anthropic API release (verify per-model).
- **Prompt caching:** available; verify exact behavior on Vertex (historically had different limits or invalidation rules).
- **Tool use:** parity.
- **Extended / adaptive thinking:** parity on current models. Claude Fable 5, Opus 4.8, and Sonnet 5 are available on Vertex (Google Cloud).
- **Computer Use, Memory, Files API:** historically Anthropic-API-first; verify Vertex status.
- **Batches API:** Anthropic-API-first; Vertex has its own batch inference path with different semantics.
- **Beta flags / preview features:** Vertex usually doesn't carry beta surfaces.

## Patterns + anti-patterns

### Pattern — pin model IDs in Vertex format

Current-generation IDs on Vertex are the bare first-party IDs (`claude-sonnet-5`); only pre-4.6 dated snapshots use the Vertex-specific `@<date>` suffix. Maintain a canonical-model → per-provider-ID mapping in your config:

```python
MODELS = {
    "sonnet": {
        "anthropic": "claude-sonnet-5",
        "bedrock": "anthropic.claude-sonnet-5",
        "vertex": "claude-sonnet-5",
    },
    "haiku": {  # pre-4.6-generation dated-snapshot style
        "anthropic": "claude-haiku-4-5-20251001",
        "bedrock": "anthropic.claude-haiku-4-5-20251001-v1:0",
        "vertex": "claude-haiku-4-5@20251001",
    },
}
```

### Pattern — service account with least privilege

Vertex auth uses GCP service accounts. Scope the SA to the specific Vertex API permissions needed; don't reuse a broad SA.

### Pattern — region proximity for latency

Vertex's regional control gives you latency wins. Run your service in the same region as your Vertex model endpoint. `us-east5` Vertex with `us-east1` Cloud Run beats `us-east5` Vertex with `eu-west1` Cloud Run.

### Pattern — Vertex as failover for Anthropic API

For mission-critical: primary on Anthropic API, secondary on Vertex (or [Bedrock](/stacks/anthropic-claude/bedrock-provider/)). Account for:

- Different credentials per provider.
- Different model ID mappings.
- Cold cache on the secondary (caches are provider-scoped).
- Feature-parity gaps (the secondary may lack a beta flag the primary used).

### Anti-pattern — Vertex with Anthropic-API-only features

Service depends on a beta flag that ships Anthropic-API-first. You set up Vertex for compliance. Feature doesn't work. Design for lowest-common-denominator features, or accept partial degradation.

### Anti-pattern — assuming Vertex parity without verification

"It works on Anthropic API, should work on Vertex." Verify per-feature against [docs.anthropic.com/en/api/claude-on-vertex-ai](https://docs.anthropic.com/en/api/claude-on-vertex-ai) — parity gaps exist and shift.

### Anti-pattern — Vertex configured but not benchmarked

If you'll commit a workload to Vertex, run the workload on Vertex for a day before committing. Latency, rate limits, and feature behavior can differ subtly.

## Gotchas

- **Model availability is per-region per-model.** Not all models in all regions. Verify [Vertex Model Garden](https://console.cloud.google.com/vertex-ai/model-garden) for current availability.
- **GCP project must enable the model.** First-time use requires enabling each Claude model in the model garden UI — a one-time step.
- **Vertex quotas differ from Anthropic API rate limits.** Vertex uses GCP-style quotas (QPS, tokens per minute) configurable per project. Don't assume your Anthropic API tier maps directly.
- **Billing is on GCP.** No separate Anthropic invoice; consumption shows up in GCP billing under the Vertex AI line item.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — same protocol
- [Bedrock Provider](/stacks/anthropic-claude/bedrock-provider/) — AWS-side alternative
- [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) — `AnthropicVertex` client
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — provider-choice framework
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — failover topology
- [Anthropic on Vertex AI](https://docs.anthropic.com/en/api/claude-on-vertex-ai)
