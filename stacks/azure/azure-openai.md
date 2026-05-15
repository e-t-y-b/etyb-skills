---
title: Azure OpenAI
description: OpenAI frontier models on Azure — folded into AI Foundry experience. PTU + Standard + Batch + Global + Data Zone deployment types. PTU quotas region-bound and contended.
product:
  name: Azure OpenAI Service
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/ai-services/openai/
  notes: "Folded into AI Foundry; PTU + Standard + Batch + Global + Data Zone; model catalog and pricing shift quarterly."
---

## What it is

Azure OpenAI Service hosts OpenAI's frontier models (GPT-4o, GPT-5.2, o3, o4-mini, DALL-E 3, Whisper, embeddings) under Microsoft's commercial terms + Azure SLA. As of 2024-25, the surface is folded into the **AI Foundry experience** — same models, broader catalog. Canonical reference: [Azure OpenAI docs](https://learn.microsoft.com/azure/ai-services/openai/).

## When to use

Pick Azure OpenAI when:

- You want **OpenAI frontier models** with Microsoft commercial terms / SLA / data handling.
- You need **PTU** (Provisioned Throughput Units) for predictable production capacity.
- You want **Batch API** for 50% discount on async high-throughput.
- Your data sovereignty mandates **Data Zone** routing (geo-restricted).

For non-OpenAI models (Anthropic Claude, Mistral, Llama, Phi), use [AI Foundry](/stacks/azure/ai-foundry/) — same portal, same model catalog.

## 2025-2026 currency anchors

- **Deployment types**:
  - **Standard** — dev / prototyping / variable load. Shared, TPM-rate-limited. Per-token billing.
  - **Provisioned Throughput Units (PTU)** — production with predictable load. Reserved regional capacity. Hourly per PTU.
  - **Batch API** — async high-throughput; up to 24h; **50% cost discount**.
  - **Global** — highest availability via cross-region routing. Per-token (slightly higher).
  - **Data Zone** — regulatory data residency; restricted geographic routing.
- **Models available (2026-Q2)**: GPT-4o, GPT-4o-mini, GPT-4.5, **GPT-5.2 (latest)**, o1, o3, o4-mini, DALL-E 3, Whisper, text-embedding-3-small / -large.
- **Content Safety** built-in by default — medium severity blocked across hate / sexual / violence / self-harm categories.
- **Prompt Shields** for jailbreak detection.
- **Indirect Prompt Shields** for retrieved-content injection.
- **Defender for AI Services** — threat detection (prompt injection, abuse).

## Patterns + anti-patterns

### Pattern: PTU baseline + Standard burst for production

PTU at 70-80% expected steady-state; Standard spillover handles bursts. Code routes by checking rate-limit headers.

### Pattern: Batch API for async high-throughput

Embedding ingestion, document summarization, content generation at scale — 50% discount.

### Pattern: Right-size the model to the task

GPT-4o-mini / Phi-4 for classification, extraction, simple summarization (10-100× cheaper than GPT-4/5). Reserve frontier models (GPT-5.2 / o3 / Claude Opus) for hard cases.

### Pattern: Content Safety on every endpoint

Filter user input (Prompt Shields), filter LLM output, filter retrieved content (Indirect Prompt Shields). Defense in depth.

### Anti-pattern: PTU at 100% expected peak

You're paying for unused capacity off-peak. Right-size to 70-80%; let Standard handle bursts.

### Anti-pattern: Starting at PTU without baseline data

Run on Standard for 2-4 weeks to establish actual TPM patterns; then size PTU.

### Anti-pattern: Defaulting to GPT-4 / GPT-5 for everything

10× cost vs Phi-4 / GPT-4o-mini for simple tasks. Match model to task complexity.

### Anti-pattern: Disabling Content Safety in production

If filters block legitimate traffic, tune thresholds — don't blanket-disable.

### Anti-pattern: Assuming PTU capacity is on-demand

PTU is region-bound + contended. Plan allocation with the AI program lead; have Standard fallback for bursts.

## Gotchas

- **PTU regional capacity** — queue for negotiation. Don't assume "we'll provision more when we need it."
- **Standard tier rate limits** are TPM-based per deployment per region. Hit them and you get 429s.
- **Data Zone vs Global** — verify your data residency commitments.
- **Content filter customization** is per-deployment.
- **Model deprecation** happens — read Azure OpenAI model lifecycle docs.

## Cross-references

- [AI Foundry](/stacks/azure/ai-foundry/) — broader model catalog (Anthropic, Mistral, Llama, Phi)
- [Foundry Agents](/stacks/azure/foundry-agents/) — managed agent runtime
- [Azure AI Search](/stacks/azure/ai-search/) — RAG retrieval
- [Microsoft Purview](/stacks/azure/microsoft-purview/) — AI Hub for prompt visibility
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — model selection, PTU strategy, evaluation
- [Azure OpenAI deployment types](https://learn.microsoft.com/azure/ai-services/openai/concepts/deployment-types)
- [PTU concepts](https://learn.microsoft.com/azure/ai-services/openai/concepts/provisioned-throughput)
