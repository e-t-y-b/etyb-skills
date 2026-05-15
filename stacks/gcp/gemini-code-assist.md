---
title: Gemini Code Assist
description: AI coding assistant for IDEs (VS Code, IntelliJ) — Gemini 2.5 backend, Code Assist Agents for agentic workflows. Formerly Duet AI for Developers.
product:
  name: Gemini Code Assist
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, devops-engineer]
  authoritative_url: https://cloud.google.com/gemini/docs/codeassist
  notes: "Cloud Code is the IDE plugin; Gemini Code Assist is its AI brain — both rebranded and feature-extended in 2025-2026. Code Assist Agents added 2025-2026 for agentic IDE workflows."
---

## What it is

Gemini Code Assist is GCP's AI coding assistant for IDEs. **Cloud Code** is the VS Code / IntelliJ plugin that provides GCP-native dev loops (local Cloud Run, GKE manifests, gcloud integration); **Gemini Code Assist** is the AI brain inside it — code completion, code generation, chat, refactoring, and **Code Assist Agents** (agentic, multi-step workflows that drive GCP changes from inside the IDE).

The product was **Duet AI for Developers** until Feb 2024. Backend swapped to Gemini 2.5 across 2025. Agentic mode shipped in 2025-2026.

Authoritative reference: [cloud.google.com/gemini/docs/codeassist](https://cloud.google.com/gemini/docs/codeassist).

## When to use

Pick Gemini Code Assist when:
- Your team works on GCP code and you want IDE-integrated AI with GCP context
- You want agentic IDE workflows (Code Assist Agents) that can plan + execute multi-file changes
- Compliance posture matters — Gemini Code Assist Standard/Enterprise has explicit data controls

Don't pick Gemini Code Assist when:
- Your team has a Copilot / Cursor / Claude Code workflow they prefer — those are also strong choices
- You're not on GCP — the GCP-context value-add is the differentiator

## 2025-2026 currency anchors

- **Was Duet AI for Developers** until Feb 2024.
- **Backend on Gemini 2.5** as of 2025.
- **Code Assist Agents** (agentic mode) shipped 2025-2026 — multi-step plans, file edits, tool calls.
- **Gemini Code Assist Standard / Enterprise** tiers — Enterprise has on-cloud customization (private code indexing).
- **Cloud Code** plugin available for VS Code and IntelliJ.

## Patterns

### Install in VS Code

1. Install the **Cloud Code** extension
2. Sign in with Google Cloud account
3. Enable Gemini Code Assist
4. Code completions appear inline; chat panel for explanations + refactoring

### Code Assist Agents

In the chat panel, ask for a multi-step change:
```
Add a Cloud Run service with Pub/Sub trigger, write the handler in Python, create the Terraform module, and add unit tests.
```

The agent plans, drafts files, asks for confirmation, applies edits.

## Anti-patterns

- **Duet AI** in any new doc / training material — it's Gemini Code Assist now.
- **Code Assist Agents without code review** — agentic edits need the same review discipline as human PRs.
- **No private code indexing setup** on Enterprise — you're not using the differentiator.

## Gotchas

- **Tier differences** (Standard vs Enterprise) matter for data residency and code privacy commitments.
- **License**: per-user pricing; verify against your team size.
- **IDE integration quality** differs by language — Python / Go / Java strongest; less common languages weaker.

## Cross-references

- Related: [Gemini](/stacks/gcp/gemini/), [Vertex AI](/stacks/gcp/vertex-ai/)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/gemini/docs/codeassist](https://cloud.google.com/gemini/docs/codeassist)
