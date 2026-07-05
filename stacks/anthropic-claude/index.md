---
title: Anthropic Claude
description: Anthropic Claude platform knowledge — Claude API, Fable/Mythos/Opus/Sonnet/Haiku models, prompt caching, tool use, Batches, Files, Citations, Memory, Extended/Adaptive Thinking, Computer Use, Agent SDK, Claude Code, MCP, Skills. Current to July 2026.
stack:
  vendor: anthropic-claude
  last_verified_on: "2026-07-05"
  drift_risk_default: high
  applies_to_roles:
    - backend-architect
    - ai-ml-engineer
    - system-architect
    - security-engineer
  authoritative_sources:
    - { name: "Anthropic Docs Home",                url: "https://docs.anthropic.com/",                                              type: official_docs }
    - { name: "Claude API Reference",                url: "https://docs.anthropic.com/en/api/",                                       type: api_reference }
    - { name: "Claude Release Notes",                url: "https://docs.anthropic.com/en/release-notes",                              type: changelog }
    - { name: "Prompt Caching Guide",                url: "https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching",      type: official_docs }
    - { name: "Tool Use Guide",                      url: "https://docs.anthropic.com/en/docs/build-with-claude/tool-use",            type: official_docs }
    - { name: "Extended Thinking Guide",             url: "https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking",   type: official_docs }
    - { name: "Memory Tool Guide",                   url: "https://docs.anthropic.com/en/docs/build-with-claude/memory",              type: official_docs }
    - { name: "Citations Guide",                     url: "https://docs.anthropic.com/en/docs/build-with-claude/citations",           type: official_docs }
    - { name: "Computer Use Guide",                  url: "https://docs.anthropic.com/en/docs/agents-and-tools/computer-use",         type: official_docs }
    - { name: "Batches API",                         url: "https://docs.anthropic.com/en/api/creating-message-batches",               type: api_reference }
    - { name: "Files API",                           url: "https://docs.anthropic.com/en/api/files",                                  type: api_reference }
    - { name: "Claude Agent SDK Docs",               url: "https://docs.anthropic.com/en/api/claude-code-sdk",                        type: official_docs }
    - { name: "Claude Code Docs",                    url: "https://docs.anthropic.com/en/docs/claude-code/overview",                  type: official_docs }
    - { name: "MCP Specification",                   url: "https://modelcontextprotocol.io/",                                         type: official_docs }
    - { name: "Anthropic on Amazon Bedrock",         url: "https://docs.anthropic.com/en/api/claude-on-amazon-bedrock",               type: official_docs }
    - { name: "Anthropic on Vertex AI",              url: "https://docs.anthropic.com/en/api/claude-on-vertex-ai",                    type: official_docs }
    - { name: "Anthropic Acceptable Use Policy",     url: "https://www.anthropic.com/legal/aup",                                      type: official_docs }
    - { name: "Anthropic Trust Center",              url: "https://trust.anthropic.com/",                                             type: official_docs }
    - { name: "Anthropic News",                      url: "https://www.anthropic.com/news",                                           type: changelog }
  delegate_to_skills:
    - { skill: "claude-api", covers: ["Claude API", "Anthropic SDK", "prompt caching", "tool use", "Batches API", "Files API", "Citations", "Memory", "Extended Thinking", "model migration"] }
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip" title="ETYB's own substrate">
This Stack ships in **all tiers** — Lite, Core, and Pro. Claude is the substrate ETYB itself runs on when invoked inside Claude Code. The hooks, settings.json, sub-agent conventions, and Skills mechanisms documented here aren't theoretical — they're the protocol layer ETYB uses. Treat the substrate with care: a sloppy Skill destabilizes ETYB's own routing; a misused `cache_control` block raises ETYB's own context costs.
</Aside>

## Currency

<div class="etyb-currency-banner">Last verified: 2026-07-05 against the Claude 5 generation (Fable 5 / Mythos 5, Sonnet 5) + Opus 4.8 + Haiku 4.5, Claude Agent SDK GA, Claude Code on weekly cadence, MCP spec revision 2025-06-18.</div>

The Anthropic surface drifts fast — model IDs rotate every 2-3 months, beta flags ship to GA on a quarterly cadence, and the MCP spec still evolves. If today's date is more than 90 days past the `last_verified_on` above, treat model IDs, pricing numbers, beta-header flags, and tool versions with extra care — the [drift-check protocol](/conventions/knowledge-currency/) governs how agents handle staleness. The default `drift_risk` for this Stack is **high** for that reason.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get most of these wrong:

- **Model name rotation.** Claude 3 → 3.5 → 3.7 → 4 (May 2025) → 4.1 → 4.5 → 4.6 → 4.7 (Apr 2026) → Opus 4.8 (May 2026) → **the Claude 5 generation** (Fable 5 / Mythos 5, June 2026; Sonnet 5, June 2026). Current production default is **Claude Sonnet 5** (`claude-sonnet-5`); GA flagship is **Claude Opus 4.8** (`claude-opus-4-8`); the Mythos-class tier above Opus is **Claude Fable 5** (`claude-fable-5`, $10/$50 — GA with dual-use safety classifiers) / **Claude Mythos 5** (`claude-mythos-5`, classifier-free, approved Project Glasswing orgs only). `claude-3-opus-20240229` is retired. Dateless IDs (4.6 generation onward) are pinned snapshots — never append a date suffix.
- **1M context at standard pricing.** Opus 4.6+, Sonnet 5/4.6, and Fable 5 include the full 1M-token window with no >200K premium. Still don't reflexively stuff a million tokens into context — input cost scales linearly.
- **Haiku 4.5** (Oct 2025) reset the cheap-tier envelope to ~Sonnet-3.5 quality, opening new routing patterns. Reconsider "Sonnet for everything" defaults.
- **Prompt caching is two-tier.** 5-minute TTL (1.25x write, 0.1x read) is default; 1-hour TTL (2x write, 0.1x read) for stable long contexts. Up to **4 cache breakpoints** per request. Cache reads are **90% off**.
- **Extended Thinking became Adaptive Thinking.** Current models (Opus 4.6+, Sonnet 5, Fable 5) use `thinking: {type: "adaptive"}` + `output_config.effort`; manual `budget_tokens` returns 400 on Opus 4.7/4.8, Sonnet 5, and Fable 5. Thinking blocks must round-trip verbatim across tool-use turns.
- **Computer Use** went from public beta (Oct 2024) to production-grade. Tool versions (`computer_20250124`, `computer_20251022`...) are **tied to model versions** — you cannot mix and match.
- **Memory tool** shipped 2025 as a first-class capability — managed memory store persisting across conversations.
- **Citations API** (2025) returns source-grounded responses with character-level spans. Don't parse "[1]" out of prose anymore.
- **Files API** (2025) replaces base64-inlining for PDFs/images at scale.
- **Batches API** ships a **50% discount** for async work — up to 100K requests, 256MB, 24-hour window.
- **Claude Agent SDK** (`@anthropic-ai/claude-agent-sdk` / PyPI `claude-agent-sdk`) launched 2025. **Don't roll your own agent loop in 2026** unless you have an explicit reason.
- **Claude Code** matured from coding-CLI to a general-purpose agent harness with hooks, slash commands, Skills, sub-agents, plan mode, settings.json. CLI updates weekly.
- **Skills as a first-class capability** (2025-2026). `SKILL.md` + frontmatter, description-triggered auto-load. **This ETYB Stack is itself a Skill.**
- **MCP went from Nov 2024 launch to industry standard.** Spec at 2025-06-18 revision; adopted by OpenAI, Google, Microsoft, JetBrains, Cursor, Zed. **Donated to the Linux Foundation under the Agentic AI Foundation (2026).** If you're building agent tooling in 2026, build it as an MCP server first.
- **Bedrock + Vertex + Anthropic API parity** — Claude available on all three with effectively the same Messages API. Model IDs differ; SDK abstracts most of the rest.
- **Pricing is stratified.** Cache writes cost more; cache reads cost a fraction; Batches cost half; Sonnet 5 has introductory pricing ($2/$10) through 2026-08-31; the old >200K long-context premium is gone. Don't quote a single $/MTok number.

If you find yourself recommending `claude-3-opus-20240229`, hand-rolling a tool loop instead of using the Agent SDK, base64-inlining PDFs into every request, or treating prompt caching as "an optimization to consider later" — you're using stale knowledge.

## Products covered

Per-product pages under `/stacks/anthropic-claude/<product>/`. Drift risk reflects how often each surface changes in the wild.

| Product | Drift risk | Why |
|---|---|---|
| [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Model names rotate every 2-3 months; pricing changes; new beta flags every release |
| [Claude Opus](/stacks/anthropic-claude/claude-opus/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Opus 4.8 current; 1M context standard-priced; Fable 5 / Mythos 5 tier above |
| [Claude Sonnet](/stacks/anthropic-claude/claude-sonnet/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Sonnet 5 (June 2026) current default for production; intro pricing through 2026-08-31 |
| [Claude Haiku](/stacks/anthropic-claude/claude-haiku/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Haiku 4.5 (Oct 2025) reset price/quality envelope; still current |
| [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Two TTLs, pricing 1.25x/2x write, 0.1x read; up to 4 breakpoints |
| [Tool Use](/stacks/anthropic-claude/tool-use/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Schema is stable; parallel tool use + `tool_choice` evolve per model |
| [Batches API](/stacks/anthropic-claude/batches-api/) | <span class="etyb-drift-badge" data-risk="low">low</span> | 50% discount, async; up to 100K requests / 256MB / 24h |
| [Files API](/stacks/anthropic-claude/files-api/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | GA 2025; replaces base64 inlining at scale |
| [Citations](/stacks/anthropic-claude/citations/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Document-grounded responses with source spans; stable surface |
| [Memory](/stacks/anthropic-claude/memory/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Released 2025; surface still evolving |
| [Extended Thinking](/stacks/anthropic-claude/extended-thinking/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Thinking + interleaved thinking; `budget_tokens`; `signature` round-trip required |
| [Computer Use](/stacks/anthropic-claude/computer-use/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Tool versions tied to model versions (`computer_20250124`, `computer_20251022`...) |
| [Vision](/stacks/anthropic-claude/vision/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Native image input in Messages API; size limits documented |
| [PDF Input](/stacks/anthropic-claude/pdf-input/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Native PDF in Messages API; size/page limits documented |
| [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Released 2025; replaces ad-hoc agent loops; harness conventions still settling |
| [Claude Code](/stacks/anthropic-claude/claude-code/) | <span class="etyb-drift-badge" data-risk="high">high</span> | CLI updates weekly; hooks, settings.json, slash commands, plan mode evolve rapidly |
| [MCP](/stacks/anthropic-claude/mcp/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Spec at 2025-06-18 revision; SDKs in 5+ languages; donated to Linux Foundation 2026 |
| [Skills](/stacks/anthropic-claude/skills/) | <span class="etyb-drift-badge" data-risk="high">high</span> | First-class capability 2025-2026; this very ETYB pack ships as a Skill |
| [Sub-agents](/stacks/anthropic-claude/sub-agents/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Pattern formalized in Claude Code; one-domain-per-agent convention |
| [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | First-party Python/TS/Go/Java/Ruby; community SDKs vary in quality |
| [Vertex AI Provider](/stacks/anthropic-claude/vertex-ai-provider/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Claude-on-GCP via Vertex AI; model name prefix differs |
| [Bedrock Provider](/stacks/anthropic-claude/bedrock-provider/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Claude-on-AWS via Bedrock InvokeModel/Converse; regional availability rotates |
| [Workbench / Console](/stacks/anthropic-claude/workbench-console/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Web UI for prompt experimentation, key/usage management; surface stable |
| [Admin API](/stacks/anthropic-claude/admin-api/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Org/workspace/key/spend-limit management programmatically |

## Role overlays

Composed views under `/stacks/anthropic-claude/<role>/`. Each one stitches together the products that role's work touches on this platform.

- [`/stacks/anthropic-claude/ai-ml-engineer/`](/stacks/anthropic-claude/ai-ml-engineer/) — model selection, prompt-caching as modeling, tool-schema design, extended thinking, Memory, Citations, agent design, evals, RAG. **The richest overlay in this Stack.**
- [`/stacks/anthropic-claude/backend-architect/`](/stacks/anthropic-claude/backend-architect/) — SDK integration, streaming, tool-execution loop, Batches, Files, provider routing, MCP authoring.
- [`/stacks/anthropic-claude/system-architect/`](/stacks/anthropic-claude/system-architect/) — when-Claude-vs-alternatives, provider choice (Anthropic / Bedrock / Vertex), failover topology, cost architecture, Skills/sub-agents in SDLC.
- [`/stacks/anthropic-claude/security-engineer/`](/stacks/anthropic-claude/security-engineer/) — OWASP LLM Top 10 mapped to Claude, prompt-injection defense, PII/PHI, AUP compliance, API key management, MCP supply chain, EU AI Act obligations.

## Authoritative sources

For verified-current behavior, consult Anthropic's own surfaces:

- **[Anthropic Docs](https://docs.anthropic.com/)** — canonical reference
- **[Claude API Reference](https://docs.anthropic.com/en/api/)** — full API surface
- **[Release Notes](https://docs.anthropic.com/en/release-notes)** — model & feature changes (read this first when in doubt)
- **[Prompt Caching Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)**
- **[Tool Use Guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)**
- **[Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)**
- **[Memory Tool Guide](https://docs.anthropic.com/en/docs/build-with-claude/memory)**
- **[Citations Guide](https://docs.anthropic.com/en/docs/build-with-claude/citations)**
- **[Computer Use Guide](https://docs.anthropic.com/en/docs/agents-and-tools/computer-use)**
- **[Batches API](https://docs.anthropic.com/en/api/creating-message-batches)**
- **[Files API](https://docs.anthropic.com/en/api/files)**
- **[Claude Agent SDK Docs](https://docs.anthropic.com/en/api/claude-code-sdk)**
- **[Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)**
- **[MCP Specification](https://modelcontextprotocol.io/)**
- **[Anthropic on Bedrock](https://docs.anthropic.com/en/api/claude-on-amazon-bedrock)**
- **[Anthropic on Vertex AI](https://docs.anthropic.com/en/api/claude-on-vertex-ai)**
- **[Acceptable Use Policy](https://www.anthropic.com/legal/aup)** — read in full before shipping customer-facing
- **[Trust Center](https://trust.anthropic.com/)** — compliance posture, data handling, attestations
- **[Anthropic News](https://www.anthropic.com/news)** — major announcements often hit before release notes

## Delegate skills

The `claude-api` Skill is an installable specialist that covers most of the Claude product surface (API, SDK, caching, tool use, Batches, Files, Citations, Memory, model migration). When that Skill is loaded in the agent's environment, ETYB delegates to it for matching products per the [drift-check protocol](/conventions/knowledge-currency/). This Stack remains the opinionated overlay; the delegate is the up-to-the-day surface.

For other Anthropic surfaces (Claude Code, MCP authoring, Skills design, sub-agent patterns), ETYB stays on this Stack — those are areas where the opinionated team view is the value, and no first-party MCP currently delegates the full surface.
