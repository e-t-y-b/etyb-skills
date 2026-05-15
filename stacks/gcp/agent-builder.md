---
title: Vertex AI Agent Builder
description: Build LLM agents on GCP — Agents, Tools, Data Stores, Conversational Agents. Formerly Generative AI App Builder. Includes Vertex AI Search for RAG.
product:
  name: Vertex AI Agent Builder
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://cloud.google.com/agent-builder/docs
  notes: "Was Generative AI App Builder → Vertex AI Agent Builder → now layered with Conversational Agents + Agentspace; framework boundaries shifted in 2025-2026."
---

## What it is

Vertex AI Agent Builder is GCP's framework for building LLM agents. The stack:

- **Agents** — top-level units with goals, tools, instructions
- **Tools** — function-call surfaces (Cloud Function, Cloud Run endpoint, BigQuery query, external API)
- **Data Stores** — for grounding (Cloud Storage docs, BigQuery, Firestore, websites)
- **Conversational Agents** — chat / voice front-ends powered by agents (was Dialogflow CX, now generative-grounded)
- **Vertex AI Search** — RAG out of the box (ingest, chunk, embed, retrieve, re-rank)

This was **Generative AI App Builder** until 2024, then **Vertex AI Agent Builder**. Now augmented by **[Agentspace](/stacks/gcp/agentspace/)** (enterprise agent application surface) and **Conversational Agents** (dialog subset). If your training data says "Generative AI App Builder" or "Vertex AI Search and Conversation" — those names are wrong.

Authoritative reference: [cloud.google.com/agent-builder/docs](https://cloud.google.com/agent-builder/docs).

## When to use

| When | Use |
|------|-----|
| Standard chat agent, dialog flow, tool calling, grounded on internal docs | **Agent Builder + Conversational Agents** |
| Highly custom orchestration, complex multi-agent coordination, code-heavy control flow | **Custom orchestration** (LangChain / LangGraph / your own framework) on Cloud Run + Vertex AI Gemini API |
| Enterprise-wide AI assistant across Workspace + M365 + Salesforce + Confluence | **[Agentspace](/stacks/gcp/agentspace/)** — don't build |

The 2026 pattern: **buy Agentspace for the enterprise-wide assistant; build with Agent Builder for product-specific agents; custom orchestration only when neither fits.**

## 2025-2026 currency anchors

- **Renamed from Generative AI App Builder to Vertex AI Agent Builder** in 2024.
- **Conversational Agents** is the dialog subset (was Dialogflow CX); now generative-AI-grounded.
- **Vertex AI Search** is RAG out of the box — ingest from Cloud Storage / BigQuery / Drive / web crawl; auto-chunking + embedding; hybrid retrieval (dense + sparse); re-ranking; citations.
- **Agentspace** added 2025 as the enterprise agent application layer (consumes agents built in Agent Builder).
- **Agent Builder SDK** for custom agents in code; deployable to GCP.

## Patterns

### Vertex AI Search for RAG

Use when you have a corpus and want RAG without authoring chunking / embedding / retrieval yourself:

```python
from google.cloud import discoveryengine_v1 as discoveryengine

client = discoveryengine.DataStoreServiceClient()
parent = "projects/my-project/locations/global/collections/default_collection"

data_store = discoveryengine.DataStore(
    display_name="Support Knowledge Base",
    industry_vertical=discoveryengine.IndustryVertical.GENERIC,
    content_config=discoveryengine.DataStore.ContentConfig.CONTENT_REQUIRED,
)

operation = client.create_data_store(
    parent=parent,
    data_store=data_store,
    data_store_id="support-kb",
)
data_store = operation.result()
```

Then ingest documents, create an engine (agent + retrieval config), and call via the Discovery Engine API or expose through Conversational Agents.

**Don't reach for LangChain RAG when Vertex AI Search covers the use case** — extra ops without value.

### Custom orchestration

For multi-agent, code-heavy flows, build on Cloud Run + the Gemini API directly. Use LangGraph or your own framework for state management. Use Agent Builder for individual tools/agents inside the orchestration if it simplifies things.

## Anti-patterns

- **"Generative AI App Builder"** — renamed; the term is stale.
- **Custom RAG (LangChain)** when Vertex AI Search covers — extra ops without value.
- **Building enterprise-wide assistant from scratch** when Agentspace exists — buy, don't build.
- **No grounding** for an agent — hallucinations on production data are an incident, not a quirk.

## Gotchas

- **Agent Builder + Agentspace boundaries shift quarterly** — verify against current docs.
- **Connector availability** for Vertex AI Search varies; verify your data source is supported.
- **Citation quality** depends on chunking strategy — tune for your corpus.

## Cross-references

- Related: [Vertex AI](/stacks/gcp/vertex-ai/), [Gemini](/stacks/gcp/gemini/), [Agentspace](/stacks/gcp/agentspace/)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/)
- Authoritative: [cloud.google.com/agent-builder/docs](https://cloud.google.com/agent-builder/docs)
