---
title: AI Foundry
description: Renamed from Azure AI Studio (2024-25). 1,900+ model catalog including OpenAI + Anthropic Claude + Mistral + Llama + Phi. Azure is the only hyperscaler with both OpenAI and Anthropic frontier.
product:
  name: AI Foundry
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, backend-architect]
  authoritative_url: https://learn.microsoft.com/azure/ai-foundry/
  notes: "Renamed from Azure AI Studio 2024-25; Foundry Agents GA 2025; 1,900+ model catalog."
---

## What it is

Microsoft Foundry (Azure AI Foundry) is the unified AI development portal — model catalog, [Foundry Agents](/stacks/azure/foundry-agents/) runtime, evaluation framework, prompt flow, fine-tuning, model deployment. Renamed from Azure AI Studio in 2024-25. Canonical reference: [AI Foundry docs](https://learn.microsoft.com/azure/ai-foundry/).

## When to use

Pick AI Foundry as the entry point for any new AI work on Azure:

- **Model selection** from a 1,900+ catalog.
- **Agent design** with Foundry Agents.
- **Prompt flow** for orchestration.
- **Fine-tuning** managed or open-weight models.
- **Evaluation** of quality + safety metrics.
- **Deployment** as managed online endpoint or serverless.

## 2025-2026 currency anchors

- **Renamed from Azure AI Studio** (2024-25). Use "Foundry" or "AI Foundry" in current voice.
- **1,900+ model catalog** as of 2026-Q2.
- **Models sold by Azure** (covered by Azure SLA + Microsoft commercial terms):
  - GPT-4o, GPT-4o-mini, GPT-4.5, **GPT-5.2 (latest)**, o1, o3, o4-mini
  - DALL-E 3, Whisper, text-embedding-3-large
  - **Anthropic Claude Opus, Sonnet, Haiku** — Azure is the **only hyperscaler with both OpenAI and Anthropic frontier in one managed catalog**.
  - Mistral Large, Mistral Small, Codestral
  - Meta Llama 3 / 3.1 / 4 (8B, 70B, 405B variants)
  - Microsoft **Phi (3 / 4)** — small, efficient, fine-tunable.
- **Partner / community models** (Microsoft hosts, partner provides; not covered by Azure SLA): DeepSeek V3/V3.2, Kimi K2, Stable Diffusion variants, many specialized.
- **Deployment options**: managed compute (real-time endpoint, dedicated GPU/CPU), serverless API (MaaS, per-token), self-hosted on [AKS](/stacks/azure/aks/) / VMs (open-source / weights-available only).
- **Foundry Agents GA 2025** — see [Foundry Agents](/stacks/azure/foundry-agents/).
- **Prompt flow** — visual DAG-based orchestration of LLM calls + tools + Python code.
- **Built-in evaluation** — quality (groundedness, relevance, coherence, similarity) + safety (hate, violence, indirect prompt injection) + custom (LLM-as-judge).

## Patterns + anti-patterns

### Pattern: Eval-driven model selection

Foundry evaluation against representative dataset → pick by data, not vibes. Run before committing to a model in production.

### Pattern: Small + large model routing

GPT-4o-mini classifies intent → routes hard cases to GPT-5.2 / Claude Opus / o3; cached canned responses for trivial. Cost-quality optimization.

### Pattern: Prompt flow for explorable RAG / agent pipelines

Visual DAG. Good for "explorable" pipelines with non-developer collaborators (PMs / SMEs reviewing prompts).

### Pattern: Foundry deployment + Azure SLA

Choose models "sold by Azure" (vs partner/community) when SLA and commercial terms matter.

### Anti-pattern: Defaulting to GPT-4 / GPT-5 for everything

10× cost vs Phi-4 / GPT-4o-mini for simple tasks. Use eval data to pick.

### Anti-pattern: Choosing a model without eval

Without measurement, you're guessing. Run Foundry evaluation first.

### Anti-pattern: Hard-coding examples in code

Externalize prompts to Foundry / Prompt flow / config; version them.

## Gotchas

- **PTU is region-bound** — see [Azure OpenAI](/stacks/azure/azure-openai/).
- **Partner / community models** not covered by Azure SLA — read terms before production.
- **Foundry portal URL** is ai.azure.com; Azure OpenAI Studio URL redirects here.
- **Fine-tuning** options vary per model — Azure OpenAI fine-tuning vs Foundry fine-tuning vs Azure ML for open-weight LoRA / QLoRA.

## Cross-references

- [Azure OpenAI](/stacks/azure/azure-openai/) — OpenAI models with Microsoft commercial terms
- [Foundry Agents](/stacks/azure/foundry-agents/) — managed agent runtime
- [Azure AI Search](/stacks/azure/ai-search/) — RAG retrieval
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — model selection, RAG, evaluation
- [AI Foundry model catalog](https://learn.microsoft.com/azure/ai-foundry/concepts/model-catalog-overview)
- [Foundry evaluation](https://learn.microsoft.com/azure/ai-foundry/concepts/evaluation-approach-gen-ai)
