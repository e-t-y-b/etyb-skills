---
name: stack-anthropic-claude
description: >
  Anthropic Claude platform knowledge overlay for the ETYB team. Loads when work involves the Anthropic ecosystem — the Claude API (Messages API), Claude Opus / Sonnet / Haiku models, prompt caching, tool use (function calling), extended thinking, the Batches API, Files API, Citations, the Memory tool, Computer Use, vision and PDF input, the Claude Agent SDK, the Claude Code CLI / IDE extensions, Skills, sub-agents, the Anthropic SDK (TS/Python/Go/Java/Ruby), MCP (Model Context Protocol) servers and clients, and provider routing across Anthropic API / Amazon Bedrock / Google Vertex AI. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Claude work as of 2026-Q2.
  Triggers: anthropic, claude, claude-api, anthropic-api, messages-api, opus, claude-opus, claude-opus-4, claude-opus-4.5, claude-opus-4.6, claude-opus-4.7, sonnet, claude-sonnet, claude-sonnet-4, claude-sonnet-4.5, claude-sonnet-4.6, claude-sonnet-4.7, haiku, claude-haiku, claude-haiku-4, claude-haiku-4.5, 1m context, one million context, prompt caching, cache_control, ephemeral cache, 5-minute cache, 1-hour cache, tool use, function calling, claude tools, claude tool_use, batches api, message batches, files api, citations, claude citations, memory tool, claude memory, extended thinking, interleaved thinking, computer use, claude computer use, vision input, pdf input, claude pdf, claude agent sdk, claude-agent-sdk, agent sdk, claude code, claude-code, claude code cli, claude code ide, skills, claude skills, anthropic skills, sub-agents, subagents, claude sub-agents, anthropic sdk, anthropic-typescript, anthropic-python, anthropic-go, anthropic-java, anthropic-ruby, @anthropic-ai/sdk, mcp, model context protocol, mcp server, mcp client, mcp tools, mcp resources, mcp prompts, vertex ai claude, bedrock claude, claude on aws, claude on gcp, anthropic bedrock, anthropic vertex, workbench, anthropic workbench, anthropic console, admin api, anthropic admin api, anthropic budget, anthropic spend limits, claude rate limits, anthropic rate limits, aup, acceptable use policy, anthropic aup, usage policy, prompt injection claude, claude safety, constitutional ai, prefill, response prefill, system prompt, claude system prompt, stop_sequences, claude streaming, sse, server-sent events, anthropic streaming, claude responses.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "5.0.0-dev"
  category: stack-pack
  last_verified_release: "Claude 4.x family, May 2026"
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - backend-architect
    - ai-ml-engineer
    - system-architect
    - security-engineer
authoritative_sources:
  primary:
    - { name: "Anthropic Docs Home",              url: "https://docs.anthropic.com/",                                               type: official_docs }
    - { name: "Claude API Reference",              url: "https://docs.anthropic.com/en/api/",                                       type: api_reference }
    - { name: "Claude API Release Notes",          url: "https://docs.anthropic.com/en/release-notes",                              type: changelog }
    - { name: "Prompt Caching Guide",              url: "https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching",      type: official_docs }
    - { name: "Tool Use Guide",                    url: "https://docs.anthropic.com/en/docs/build-with-claude/tool-use",            type: official_docs }
    - { name: "Computer Use Guide",                url: "https://docs.anthropic.com/en/docs/agents-and-tools/computer-use",         type: official_docs }
    - { name: "Extended Thinking Guide",           url: "https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking",   type: official_docs }
    - { name: "Memory Tool Guide",                 url: "https://docs.anthropic.com/en/docs/build-with-claude/memory",              type: official_docs }
    - { name: "Citations Guide",                   url: "https://docs.anthropic.com/en/docs/build-with-claude/citations",           type: official_docs }
    - { name: "Batches API",                       url: "https://docs.anthropic.com/en/api/creating-message-batches",               type: api_reference }
    - { name: "Files API",                         url: "https://docs.anthropic.com/en/api/files",                                  type: api_reference }
    - { name: "Claude Agent SDK Docs",             url: "https://docs.anthropic.com/en/api/claude-code-sdk",                        type: official_docs }
    - { name: "Claude Code Docs",                  url: "https://docs.anthropic.com/en/docs/claude-code/overview",                  type: official_docs }
    - { name: "MCP Specification",                 url: "https://modelcontextprotocol.io/",                                         type: official_docs }
    - { name: "MCP TypeScript SDK",                url: "https://github.com/modelcontextprotocol/typescript-sdk",                   type: api_reference }
    - { name: "MCP Python SDK",                    url: "https://github.com/modelcontextprotocol/python-sdk",                       type: api_reference }
    - { name: "Anthropic on Amazon Bedrock",        url: "https://docs.anthropic.com/en/api/claude-on-amazon-bedrock",              type: official_docs }
    - { name: "Anthropic on Vertex AI",             url: "https://docs.anthropic.com/en/api/claude-on-vertex-ai",                   type: official_docs }
    - { name: "Anthropic Acceptable Use Policy",   url: "https://www.anthropic.com/legal/aup",                                      type: official_docs }
    - { name: "Anthropic Trust Center / Privacy",  url: "https://trust.anthropic.com/",                                             type: official_docs }
    - { name: "Anthropic News",                    url: "https://www.anthropic.com/news",                                           type: announcements }
    - { name: "Anthropic GitHub",                  url: "https://github.com/anthropics",                                            type: source_code }
    - { name: "Anthropic Cookbook",                url: "https://github.com/anthropics/anthropic-cookbook",                         type: source_code }
delegate_to_skills:
  - { skill: "claude-api", covers: [Claude API, Anthropic SDK, prompt caching, tool use, batch API, files, citations, memory, model migration] }
products_covered:
  - { name: "Claude API (Messages)",        drift_risk: high,   notes: "Model names rotate every 2-3 months; pricing changes; new beta flags every release" }
  - { name: "Claude Opus 4.x (1M context)", drift_risk: high,   notes: "1M-context variant priced separately (>200K input premium); model IDs versioned by date" }
  - { name: "Claude Sonnet 4.x",            drift_risk: high,   notes: "Current default for most production work; 4.6/4.7 cadence" }
  - { name: "Claude Haiku 4.x",             drift_risk: medium, notes: "Cheapest tier; Haiku 4.5 (Oct 2025) reset price/quality envelope" }
  - { name: "Prompt Caching",               drift_risk: medium, notes: "Two TTLs (5-min, 1-hour); pricing 1.25x / 2x write, 0.1x read; up to 4 cache breakpoints" }
  - { name: "Tool Use",                     drift_risk: medium, notes: "Schema is stable; parallel tool use + tool_choice behaviors evolve with each model" }
  - { name: "Batches API",                  drift_risk: low,    notes: "50% discount, async; up to 100K requests / 256MB / 24h window" }
  - { name: "Files API",                    drift_risk: medium, notes: "GA 2025; replaces base64 inlining for PDFs/images at scale" }
  - { name: "Citations",                    drift_risk: low,    notes: "Document-grounded responses with source spans; stable surface" }
  - { name: "Memory tool",                  drift_risk: high,   notes: "Released 2025; surface still evolving — read release notes before claiming behavior" }
  - { name: "Extended Thinking",            drift_risk: high,   notes: "Thinking + interleaved thinking; budget_tokens semantics; signature_delta required for tool-use round-trips" }
  - { name: "Computer Use",                 drift_risk: high,   notes: "Beta → production trajectory; tool versions tied to model (computer_20250124, computer_20251022...)" }
  - { name: "Vision + PDF input",           drift_risk: low,    notes: "Native image/PDF in Messages API; size and page limits documented" }
  - { name: "Claude Agent SDK",             drift_risk: high,   notes: "Released 2025; replaces ad-hoc agent loops; harness conventions still settling" }
  - { name: "Claude Code (CLI + IDE)",      drift_risk: high,   notes: "CLI updates weekly; hooks, settings.json, slash commands, plan mode evolve rapidly" }
  - { name: "Skills",                       drift_risk: high,   notes: "First-class capability 2025-2026; this very ETYB pack ships as a Skill" }
  - { name: "Sub-agents",                   drift_risk: medium, notes: "Pattern formalized in Claude Code; one-domain-per-agent convention" }
  - { name: "MCP servers + clients",        drift_risk: high,   notes: "Industry-wide MCP boom in 2025-2026; spec at 2025-06-18 revision, SDKs in 5+ languages" }
  - { name: "Anthropic SDK (multi-lang)",   drift_risk: medium, notes: "Python + TypeScript first-party; Go/Java/Ruby/PHP first-party; community SDKs everywhere else" }
  - { name: "Bedrock provider",             drift_risk: medium, notes: "Claude-on-AWS via Bedrock InvokeModel/Converse; regional availability rotates" }
  - { name: "Vertex provider",              drift_risk: medium, notes: "Claude-on-GCP via Vertex AI; model name prefix differs; GCP-resident customers only" }
  - { name: "Workbench / Console",          drift_risk: low,    notes: "Web UI for prompt experimentation, key/usage management; surface stable" }
  - { name: "Admin API",                    drift_risk: medium, notes: "Org/workspace/key/spend-limit management programmatically" }
  - { name: "Cost limits + budgets",        drift_risk: medium, notes: "Workspace-level spend caps; per-key limits; org-wide alerts" }
  - { name: "Acceptable Use Policy",        drift_risk: medium, notes: "Updated periodically; usage policy enforcement attaches to keys + workspaces" }
---

# Anthropic Claude Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Anthropic Claude knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/anthropic-claude/index.md`](index.md)
- **Per-product pages:** `stacks/anthropic-claude/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/anthropic-claude/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/anthropic-claude/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Model name rotation.** Claude 3 → Claude 3.5 → Claude 3.7 → Claude 4 (May 2025) → Claude 4.1 → Claude 4.5 → Claude 4.6 → Claude 4.7 across 2025-2026. The current production default is **Claude Sonnet 4.7** (or the latest Sonnet 4.x at read time). Older training data still recommends `claude-3-opus-20240229` — that model is retired. Always look up the current dated alias in the release notes before pinning a model ID.
- **Opus 4.x has a 1M-context variant.** Pricing is tiered: <=200K input tokens at the standard rate, >200K input tokens at a premium rate. Don't blindly stuff a million tokens into context — it's billed differently and most tasks don't need it.
- **Haiku 4.5 (Oct 2025) reset the cheap-tier envelope.** Haiku at ~Sonnet-3.5 quality opens routing patterns that weren't viable before. Reconsider "Sonnet for everything" defaults.
- **Prompt caching is two-tier.** 5-minute TTL (1.25x write cost, 0.1x read) is the default. 1-hour TTL (2x write cost, 0.1x read) is for stable long contexts. Up to **4 cache breakpoints** per request. **Cache reads are 90% off** — architect for cacheability, not just for short prompts.
- **Extended Thinking + Interleaved Thinking** (2025) are first-class. Thinking blocks have signatures that must be preserved across tool-use round-trips, or you get errors. `budget_tokens` controls thinking length. Tool use during extended thinking is interleaved — the model thinks, calls a tool, thinks again, calls another, then responds.
- **Computer Use** went from public beta (Oct 2024) to production-grade capability (2025-2026). Tool versions are dated (`computer_20250124`, `computer_20251022`...) and **tied to model versions** — you cannot mix-and-match. Requires a sandboxed VM; nobody runs this on a production server.
- **Memory tool** shipped in 2025 as a first-class capability — the model can persist state across conversations via a managed memory store. This is distinct from "memory" in the conversational sense (context window). Memory belongs to a workspace/user scope you define.
- **Claude Agent SDK** (`@anthropic-ai/claude-agent-sdk`, `claude-agent-sdk` on PyPI) launched in 2025 as the recommended way to build agentic loops on top of the Messages API. It owns the tool loop, retries, sub-agent spawning, and harness conventions. **Don't roll your own agent loop in 2026** unless you have an explicit reason — use the SDK.
- **Skills as a first-class capability** (2025-2026). A Skill is a `SKILL.md` (frontmatter + body) plus optional `references/` and `assets/`. Skills auto-load based on description-trigger matching. **This very ETYB pack is a Skill** — you are reading proof that the system works.
- **MCP (Model Context Protocol) went from Nov-2024 launch to industry standard.** Spec at the 2025-06-18 revision. Adopted by OpenAI, Google, Microsoft, JetBrains, Cursor, Zed, every major agent platform. SDKs in TypeScript, Python, Go, Java, Kotlin, Rust, C#. Tens of thousands of public MCP servers. **If you're building agent tooling in 2026, build it as an MCP server first.**

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on an Anthropic Claude engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Cache like it matters.** Prompt caching gives 90% off cache reads. Restructure prompts as stable prefix (system + tools + tenant context) + variable suffix (user message). Log `cache_read_input_tokens` vs `cache_creation_input_tokens` and alert when hit rate drops.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Anthropic Claude | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Anthropic Claude alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
