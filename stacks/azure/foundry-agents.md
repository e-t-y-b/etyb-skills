---
title: Foundry Agents
description: Managed agent runtime in AI Foundry (GA 2025). Declarative agents — tools, threads, structured outputs, evaluation hooks. Different surface from raw Azure OpenAI Assistants API.
product:
  name: Foundry Agents
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/ai-foundry/concepts/agents
  notes: "GA 2025; managed runtime with thread state + tool dispatch + structured output + eval hooks; Entra Agent ID compatible."
---

## What it is

Foundry Agents is Microsoft's managed agent runtime in [AI Foundry](/stacks/azure/ai-foundry/) — declarative agent definition (system prompt + tools + output schema), managed thread state, tool calling with auto-loop until response, structured output (JSON schema-enforced), built-in evaluation hooks, Content Safety integrated, [Entra Agent ID](/stacks/azure/entra-id/) compatible. Canonical reference: [Foundry Agents docs](https://learn.microsoft.com/azure/ai-foundry/concepts/agents).

## When to use

Pick Foundry Agents when:

- **Single-agent with tools and threaded state** — managed runtime handles state, tool dispatch, structured output.
- **You want evaluation hooks** built in.
- **You want Content Safety** integrated.
- **You want [Entra Agent ID](/stacks/azure/entra-id/)** identity for production.

Don't pick Foundry Agents for:

- **Multi-agent orchestration with custom topology** — use **AutoGen** (with Foundry Agents as the underlying agent runtime).
- **Lowest-level control** — use [Azure OpenAI SDK](/stacks/azure/azure-openai/) directly.
- **Low-code for business users** — use **Copilot Studio**.
- **Cross-language Microsoft SDK pattern** — use **Semantic Kernel**.

## 2025-2026 currency anchors

- **GA 2025.**
- **Declarative agent definition** — system prompt, tools, output schema, evaluation config.
- **Managed thread state** — no DB plumbing for conversation state.
- **Tool calling auto-loop** — dispatches tools, feeds results, continues until model returns final response.
- **Structured output** with JSON schema enforcement.
- **Built-in evaluation** — quality + safety + custom metrics in the same surface.
- **Content Safety integrated** — Prompt Shields + groundedness + protected material.
- **Entra Agent ID compatible** — agents authenticate with first-class identity.
- **AutoGen 0.4+** — Microsoft-supported multi-agent SDK; can compose Foundry Agents as underlying runtime.
- **Copilot Studio** — low-code agent builder for business users; multi-agent orchestration GA 2025.

## Patterns + anti-patterns

### Pattern: Foundry Agents as the unit of agent; AutoGen for multi-agent topology

Single agents → Foundry Agents (managed). Multi-agent → AutoGen with Foundry Agents as the underlying agent runtime.

### Pattern: Entra Agent ID for production

Every production agent gets an Entra Agent ID. Conditional Access scopes when/where it operates; PIM gates sensitive ops; audit attributes actions to the agent. See [Security Engineer on Azure](/stacks/azure/security-engineer/).

### Pattern: Structured output for downstream automation

Define JSON schema for response → model output conforms → downstream code parses without prompt-injection risk.

### Pattern: Tool definition as the integration surface

Tools are typed functions with descriptions; agent runtime dispatches; you implement deterministically. Unit-test tools like any function.

### Pattern: Foundry evaluation in CI

Eval dataset (50-500 cases) in repo. CI runs evaluation on PR; blocks merge if metrics regress.

### Anti-pattern: Custom orchestration on Cosmos + raw Azure OpenAI for a use case Foundry Agents covers

You're rebuilding what Microsoft maintains.

### Anti-pattern: Agent running with developer's user credentials in production

Use Entra Agent ID. Audit log otherwise misattributes.

### Anti-pattern: Long unstructured system prompt

4000-token system prompts increase cost + latency + reduce edge-case quality. Iterate to the shortest prompt that achieves the metric.

### Anti-pattern: Shipping agent changes without eval

Eval dataset is the test suite. Every prompt / model / tool change runs against it.

## Gotchas

- **Thread state retention** is Foundry-managed; verify retention policy + data residency for your compliance scope.
- **Tool latency budget** — each tool call adds to overall latency; design tools for sub-second response.
- **Evaluation cost** — running eval datasets uses model calls; budget accordingly.
- **Foundry vs Azure OpenAI Assistants API** — Foundry Agents is the higher-level surface; Assistants API is lower-level with more control.

## Cross-references

- [AI Foundry](/stacks/azure/ai-foundry/) — host platform
- [Azure OpenAI](/stacks/azure/azure-openai/) — underlying models
- [Entra ID](/stacks/azure/entra-id/) — Agent ID
- [Azure AI Search](/stacks/azure/ai-search/) — RAG retrieval for agent tools
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — agent design, evaluation
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Entra Agent ID governance
- [Foundry Agents docs](https://learn.microsoft.com/azure/ai-foundry/concepts/agents)
- [AutoGen](https://microsoft.github.io/autogen/)
- [Semantic Kernel](https://learn.microsoft.com/semantic-kernel/)
- [Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/)
