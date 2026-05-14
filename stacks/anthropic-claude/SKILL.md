---
name: stack-anthropic-claude
description: >
  Anthropic Claude platform knowledge overlay for the ETYB team. Loads when work involves the Anthropic ecosystem — the Claude API (Messages API), Claude Opus / Sonnet / Haiku models, prompt caching, tool use (function calling), extended thinking, the Batches API, Files API, Citations, the Memory tool, Computer Use, vision and PDF input, the Claude Agent SDK, the Claude Code CLI / IDE extensions, Skills, sub-agents, the Anthropic SDK (TS/Python/Go/Java/Ruby), MCP (Model Context Protocol) servers and clients, and provider routing across Anthropic API / Amazon Bedrock / Google Vertex AI. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Claude work as of 2026-Q2.
  Triggers: anthropic, claude, claude-api, anthropic-api, messages-api, opus, claude-opus, claude-opus-4, claude-opus-4.5, claude-opus-4.6, claude-opus-4.7, sonnet, claude-sonnet, claude-sonnet-4, claude-sonnet-4.5, claude-sonnet-4.6, claude-sonnet-4.7, haiku, claude-haiku, claude-haiku-4, claude-haiku-4.5, 1m context, one million context, prompt caching, cache_control, ephemeral cache, 5-minute cache, 1-hour cache, tool use, function calling, claude tools, claude tool_use, batches api, message batches, files api, citations, claude citations, memory tool, claude memory, extended thinking, interleaved thinking, computer use, claude computer use, vision input, pdf input, claude pdf, claude agent sdk, claude-agent-sdk, agent sdk, claude code, claude-code, claude code cli, claude code ide, skills, claude skills, anthropic skills, sub-agents, subagents, claude sub-agents, anthropic sdk, anthropic-typescript, anthropic-python, anthropic-go, anthropic-java, anthropic-ruby, @anthropic-ai/sdk, mcp, model context protocol, mcp server, mcp client, mcp tools, mcp resources, mcp prompts, vertex ai claude, bedrock claude, claude on aws, claude on gcp, anthropic bedrock, anthropic vertex, workbench, anthropic workbench, anthropic console, admin api, anthropic admin api, anthropic budget, anthropic spend limits, claude rate limits, anthropic rate limits, aup, acceptable use policy, anthropic aup, usage policy, prompt injection claude, claude safety, constitutional ai, prefill, response prefill, system prompt, claude system prompt, stop_sequences, claude streaming, sse, server-sent events, anthropic streaming, claude responses.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
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

# Anthropic Claude Stack Pack — Team Briefing

You're working with Anthropic's Claude platform. This is a **knowledge overlay**, not a new specialist. ETYB's existing team does the work — ai-ml-engineer designs the prompts and tool schemas, backend-architect wires the SDK into a service, system-architect picks Claude vs alternatives and the provider, security-engineer enforces the AUP and prompt-injection defenses. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against the Claude 4.x model family in May 2026 (Opus 4.x including the 1M-context variant, Sonnet 4.6/4.7 cadence, Haiku 4.5), Claude Agent SDK as released in 2025 and matured through Q1 2026, Claude Code CLI on its weekly release rhythm, MCP at the 2025-06-18 spec revision. If today's date is more than 6 months past `last_verified_on` above, the pack is stale — warn the user and consult the release notes (`https://docs.anthropic.com/en/release-notes`) before quoting model IDs, pricing, beta flags, or tool versions.

This Stack is special: **Claude is ETYB's own substrate.** When ETYB runs inside Claude Code, the hooks, settings.json, sub-agent conventions, and Skills mechanisms in this pack are not theoretical — they are the protocol layer ETYB itself uses. Treat the substrate with care: if you author a sloppy Skill, you destabilize ETYB's own routing. If you misuse `cache_control`, ETYB's own context costs go up. Eat your own dogfood.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get most of these wrong:

- **Model name rotation.** Claude 3 → Claude 3.5 → Claude 3.7 → Claude 4 (May 2025) → Claude 4.1 → Claude 4.5 → Claude 4.6 → Claude 4.7 across 2025-2026. The current production default is **Claude Sonnet 4.7** (or the latest Sonnet 4.x at read time). Older training data still recommends `claude-3-opus-20240229` — that model is retired. Always look up the current dated alias in the release notes before pinning a model ID.
- **Opus 4.x has a 1M-context variant.** Pricing is tiered: <=200K input tokens at the standard rate, >200K input tokens at a premium rate. Don't blindly stuff a million tokens into context — it's billed differently and most tasks don't need it.
- **Haiku 4.5 (Oct 2025) reset the cheap-tier envelope.** Haiku at ~Sonnet-3.5 quality opens routing patterns that weren't viable before. Reconsider "Sonnet for everything" defaults.
- **Prompt caching is two-tier.** 5-minute TTL (1.25x write cost, 0.1x read) is the default. 1-hour TTL (2x write cost, 0.1x read) is for stable long contexts. Up to **4 cache breakpoints** per request. **Cache reads are 90% off** — architect for cacheability, not just for short prompts.
- **Extended Thinking + Interleaved Thinking** (2025) are first-class. Thinking blocks have signatures that must be preserved across tool-use round-trips, or you get errors. `budget_tokens` controls thinking length. Tool use during extended thinking is interleaved — the model thinks, calls a tool, thinks again, calls another, then responds.
- **Computer Use** went from public beta (Oct 2024) to production-grade capability (2025-2026). Tool versions are dated (`computer_20250124`, `computer_20251022`...) and **tied to model versions** — you cannot mix-and-match. Requires a sandboxed VM; nobody runs this on a production server.
- **Memory tool** shipped in 2025 as a first-class capability — the model can persist state across conversations via a managed memory store. This is distinct from "memory" in the conversational sense (context window). Memory belongs to a workspace/user scope you define.
- **Citations API** (2025) returns source-grounded responses with character-level spans. For RAG over documents, this is the supported path — don't roll your own citation parsing.
- **Files API** (2025) lets you upload PDFs/images once and reference them by ID across requests. Replaces base64-inlining at any non-trivial scale.
- **Batches API** ships a 50% discount for non-real-time work — up to 100K requests, 256MB, 24-hour window.
- **Claude Agent SDK** (`@anthropic-ai/claude-agent-sdk`, `claude-agent-sdk` on PyPI) launched in 2025 as the recommended way to build agentic loops on top of the Messages API. It owns the tool loop, retries, sub-agent spawning, and harness conventions. **Don't roll your own agent loop in 2026** unless you have an explicit reason — use the SDK.
- **Claude Code** matured from coding-CLI to a general-purpose agent harness with hooks, slash commands, Skills, sub-agents, plan mode, and settings.json. CLI updates weekly. `settings.json` hooks are the deterministic layer that fires *outside* the LLM — use them for guarantees, not for vibes.
- **Skills as a first-class capability** (2025-2026). A Skill is a `SKILL.md` (frontmatter + body) plus optional `references/` and `assets/`. Skills auto-load based on description-trigger matching. **This very ETYB pack is a Skill** — you are reading proof that the system works.
- **Sub-agents pattern formalized.** One domain per sub-agent, two-stage review (sub-agent proposes, primary reviews). ETYB's specialists are this pattern applied to engineering disciplines.
- **MCP (Model Context Protocol) went from Nov-2024 launch to industry standard.** Spec at the 2025-06-18 revision. Adopted by OpenAI, Google, Microsoft, JetBrains, Cursor, Zed, every major agent platform. SDKs in TypeScript, Python, Go, Java, Kotlin, Rust, C#. Tens of thousands of public MCP servers. Donated to the Linux Foundation under the Agentic AI Foundation (2026). **If you're building agent tooling in 2026, build it as an MCP server first.**
- **Bedrock + Vertex + Anthropic API parity** — Claude is now available on all three with effectively the same Messages API surface. Model IDs differ (Bedrock uses `anthropic.claude-sonnet-4-7-20260301-v1:0`-style ARNs; Vertex uses `claude-sonnet-4-7@20260301`; Anthropic API uses `claude-sonnet-4-7-20260301`). The SDK abstracts most of this if you use the right client constructor.
- **Pricing is stratified by feature usage.** Cache writes cost more than uncached. Cache reads cost a fraction. Batches cost half. >200K input on the 1M-context Opus variant costs a premium. Don't quote a single $/MTok number — Claude pricing is conditional.

If you find yourself recommending `claude-3-opus-20240229`, hand-rolling a tool loop instead of using the Agent SDK, base64-inlining PDFs into every request, or treating prompt caching as "an optimization to consider later" — you're using stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects Anthropic/Claude signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The Anthropic overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform — e.g., TDD on Claude code = eval suites with `promptfoo` / DeepEval / a custom harness; verification on a Claude integration = running the prompt against the real Messages API in a test workspace, not "I read the docs and it should work."

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **Claude as model platform** — model selection (Opus / Sonnet / Haiku, 1M variant), prompt design idioms specific to Claude, tool-use schema design, extended thinking budgets, the Memory tool, Citations, building RAG with Claude, agent design with the Claude Agent SDK, sub-agents, evals, prompt caching strategy as a *modeling* decision, Computer Use design (when/why/how not to). The richest overlay in this Stack. |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | **SDK integration** — wiring the Anthropic SDK (Python/TypeScript/Go/Java/Ruby) into a service, streaming (SSE), tool definitions and the tool-execution loop, request retries / timeouts / backoff, the Batches API for async workloads, the Files API for documents, prompt-caching breakpoints as a *systems* decision, provider routing (Anthropic API vs Bedrock vs Vertex), authoring an MCP server, MCP client patterns. |
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | **When-and-where decisions** — Claude vs alternatives at the architecture level, provider choice (Anthropic / Bedrock / Vertex) by compliance and data residency, regional availability, multi-provider failover topology, Claude-on-AWS vs Claude-on-GCP cost / latency / governance tradeoffs, where Claude Code / Skills / sub-agents fit in a delivery pipeline, integration boundaries between Claude-based agents and the rest of a system. |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | **Threat model + compliance** — prompt-injection defenses (direct + indirect), PII/PHI handling and the Anthropic Trust Center commitments, AUP compliance (high-risk uses, prohibited categories), content moderation patterns, API key management (workspaces / scopes / rotation), Admin API for governance, budget and spend-limit enforcement, audit logging, output handling (LLM05), supply-chain considerations for MCP servers, jailbreak / red-team approach. |

The four overlays cover the four roles where Claude work has the most depth. **Other roles still apply** when Claude touches their domain — e.g., devops-engineer setting up GitHub Actions to run a Claude eval suite, qa-engineer authoring `promptfoo` test cases against a prompt, technical-writer documenting an MCP server. They use their own discipline + this SKILL.md briefing; they don't need a dedicated overlay because the Claude-specific surface for them is thin.

## Top platform gotchas the team must know

Opinionated, named, with consequences. Skim before any non-trivial Claude work.

1. **Model IDs are dated and they retire.** Pinning `claude-3-opus-20240229` in 2026 doesn't just give worse results — that model may be retired. Track aliases (e.g., `claude-sonnet-4-5` vs `claude-sonnet-4-5-20251001`) and use dated IDs in production with a written upgrade plan. Never use the floating alias in prod without monitoring.
2. **Prompt caching is not optional at scale.** Cache reads are 90% off the input price. A system prompt that's reused 100 times an hour saves 90% of its input cost via caching. Designing the prompt as a *cacheable prefix + variable suffix* is a primary modeling decision, not a late optimization.
3. **The 1M-context Opus variant is two products in one.** <=200K input is standard pricing; >200K input is premium. Don't reflexively dump everything into context — it's billed differently and rarely improves quality past 200K. Use RAG + caching first; reach for 1M only when you have a verified reason.
4. **Extended Thinking signatures must round-trip.** When you pass thinking blocks back to the model in a follow-up tool-use round, the `signature` field must be preserved. Stripping it (e.g., by recreating the message dict without that field) breaks the request. The SDK preserves it for you; manual REST users get this wrong constantly.
5. **Tool-use loops without an iteration cap are how you bankrupt yourself.** An agent that calls a tool, gets bad output, retries forever, will burn through a budget in minutes. Always cap tool-use iterations (5-20 depending on task) and surface the cap to the caller. The Claude Agent SDK enforces this by default.
6. **Computer Use is not a server tool.** It drives a real screen with real keyboard/mouse events. You run it in a sandboxed VM. The tool version is **tied to the model version** — `computer_20250124` does not work with a 2026-vintage model; `computer_20251022` does. Mixing them throws an API error.
7. **`cache_control` placement matters.** A `cache_control` breakpoint applies to *everything up to and including that block*. Put it after your stable system prompt and stable tools, *before* the user message. If you put it after the user message, every request is a cache miss because the user message changes.
8. **Streaming is the default UX, not an upgrade.** A non-streaming response is fine for batch / agent / server-side use, but any user-facing chat / write / generate flow must stream. SSE is the protocol; the SDK exposes `client.messages.stream()` (Python) and `client.messages.stream({...})` (TypeScript). Hand-rolling streaming over fetch in 2026 is a code smell.
9. **MCP servers run with the trust of whoever launched them.** An MCP server you install reads your filesystem and network with your credentials. Treat every MCP server like a piece of software you're installing — read the source, pin the version, sandbox if untrusted. The MCP spec does *not* enforce sandboxing — that's the client's job, and most clients delegate to the user.
10. **Skills auto-load on description match — that's the contract.** Write the `description:` frontmatter as the trigger surface, not as marketing copy. A skill with a vague description doesn't load when needed; a skill with too-broad triggers loads when it shouldn't and pollutes context. ETYB itself depends on this — pay attention to your Skill descriptions.
11. **The Anthropic AUP enforces by use case, not by content.** A request to "write a phishing email for a security training" is legitimate; "write a phishing email to target Bob" is not. The model side enforces some of this; the operator side (you, the developer) is contractually responsible for upstream use. Read the AUP at `https://www.anthropic.com/legal/aup` before shipping a customer-facing product.
12. **Budget caps are the only thing between a bug and a $50K week.** Configure workspace spend limits, per-key rate limits, and webhook alerts on usage anomalies before going to production. The Admin API exposes all of this — automate it as part of provisioning.
13. **Beta flags ship in `anthropic-beta` headers and they expire.** Today's beta header is tomorrow's GA. Track what beta flags your code depends on; revisit on every release-notes cycle. A header that worked last quarter may now be required, deprecated, or renamed.
14. **System prompt vs first user turn matters.** The `system` parameter is treated specially — it's not the same as putting instructions in a user message. For prompt caching, `system` is the most stable prefix candidate. For tool use, `system` is where you put the agent's persona and constraints, not in the user turn.
15. **Bedrock and Vertex are not 1:1 with the Anthropic API.** Most things work. Some don't: prompt caching has lagged on the provider clouds historically (verify current state on release notes); some beta features ship to Anthropic API first; rate limits and regional availability differ. If you're choosing a provider for a real workload, run the actual workload on a candidate before committing.

## Compliance composition

When Claude work touches a vertical, the vertical owns the compliance bar:

- **Healthcare (HIPAA / FHIR):** This Stack tells you how Claude handles PHI at the API level (zero-retention contracts, no training on customer data via API, BAA available for enterprise). The healthcare-architect tells you when a Claude-based feature is appropriate for clinical data, what PHI must be masked vs allowed, what audit trail must be persisted server-side. Defer to healthcare-architect.
- **Fintech (PCI / PSD2 / AML):** Same split. This Stack tells you Claude doesn't see card data because you mask it before the API call (and the API doesn't store it). The fintech-architect tells you when a Claude-based feature is appropriate in a payment flow, where the audit trail lives, and what tooling sits between Claude and a regulated ledger. Defer to fintech-architect. **Claude is not your ledger.**
- **EU AI Act:** This Stack tells you the technical surface (audit logs, output handling). The security-engineer overlay covers operator obligations (transparency, logging retention). High-risk-system classification and conformity assessments are a project-level legal question, not a platform question.
- **AUP:** Anthropic's Acceptable Use Policy applies to *all* uses of Claude regardless of vertical. Some uses are prohibited outright (CSAM, weapons design, election manipulation, etc.); some require special agreement (high-risk consumer-facing uses); some are conditional (deepfakes, biometric identification). The security-engineer overlay enumerates this; check before shipping a customer-facing product.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics for healthcare / fintech / public sector | `healthcare-architect` / `fintech-architect` / vertical specialist |
| Non-Claude LLM choice (OpenAI, Gemini, Mistral, DeepSeek, self-hosted) | Other vendor Stacks; this Stack stays in its lane |
| Generic RAG pipeline patterns (vector DB choice, chunking, reranking) | `ai-ml-engineer` core skill (platform-neutral) |
| Generic agent-loop patterns (LangGraph vs CrewAI vs AutoGen) | `ai-ml-engineer` core skill (platform-neutral) |
| GenAI on AWS topology beyond Bedrock for Claude | `stack-aws` |
| GenAI on GCP topology beyond Vertex for Claude | `stack-gcp` |
| Self-hosted inference / fine-tuning Llama / Mistral / Qwen | `ai-ml-engineer` core skill (Claude is not self-hostable) |

## Stack composition

If the user is using Claude **plus** another stack (AWS for Bedrock-hosted Claude + S3 + Lambda, GCP for Vertex-hosted Claude + GCS, Salesforce with Agentforce on Claude as the backing model, Supabase + Claude for a chatbot), all the relevant overlays load. The Anthropic Stack handles Claude-specific patterns; the other Stack handles its side. Neither pack pretends to know the other's depth.

Common compositions:
- **Anthropic + AWS** — Claude via Bedrock, S3 for Files-API-style document storage, Lambda for serverless tool implementations, EventBridge for orchestration. AWS Stack owns the infra; Anthropic Stack owns the prompt/agent layer.
- **Anthropic + GCP** — Claude via Vertex AI, GCS for documents, Cloud Run for tool implementations, Pub/Sub for orchestration. GCP Stack owns the infra; Anthropic Stack owns the prompt/agent layer.
- **Anthropic + Salesforce** — Salesforce Agentforce drives the user-facing agent; Atlas Reasoning Engine routes to a Claude model under the hood (Sonnet 4.5 is the default for Agentforce Vibes). Salesforce Stack owns Topic/Action/Guardrail design; this Stack owns prompt-caching design and Claude-specific tool patterns when the team is building Atlas-callable Actions.
- **Anthropic + Supabase** — Claude as the model, Supabase as the database with pgvector for RAG, Edge Functions for tool implementations. Supabase Stack owns the data plane; this Stack owns Claude integration.

## Currency

This Stack is verified against the model and feature surface as of **2026-05-14**. If you're reading this more than ~6 months later, refresh:

1. Read `https://docs.anthropic.com/en/release-notes` for any model/feature changes since `last_verified_on`.
2. Cross-check `products_covered` for any product renames, retirements, or new products.
3. Update model IDs in code examples (overlays may show `claude-sonnet-4-7-20260301` — replace with current).
4. Re-verify the MCP spec revision at `https://modelcontextprotocol.io/` — the protocol still evolves.
5. Re-verify beta-header flags — some will have moved to GA, some will have been renamed.

If a user's request hits a surface that's changed since verification, say so explicitly: "This pack was verified May 2026. I'm not certain whether [feature] has changed since then — let me check the release notes before recommending an API shape." Then check.

## Standing instructions for every role on a Claude engagement

1. **Anchor to currency.** Before quoting a model ID, pricing number, beta flag, or tool version, check whether this pack's `last_verified_on` is still recent (within 6 months). If you're past that window or unsure, consult `https://docs.anthropic.com/en/release-notes` before asserting specifics. Stale model IDs are the most common mistake.

2. **Default to Sonnet.** When asked "which model?" the default answer is Claude Sonnet 4.7 (or current 4.x Sonnet). Escalate to Opus only when an eval shows Sonnet fails. Drop to Haiku for routing, classification, and latency-sensitive paths. Never default to Opus because "it's the best" — costs are 5x.

3. **Cache like it matters.** Prompt caching gives 90% off cache reads. Restructure prompts to be cacheable. Stable prefix (system + tools + tenant context), variable suffix (user message). Log `cache_read_input_tokens` vs `cache_creation_input_tokens` and alert when hit rate drops.

4. **Use the Claude Agent SDK for agent loops.** Rolling your own tool-execution loop in 2026 is a code smell unless you have a specific reason. The SDK handles parallel tool use, retries, sub-agents, MCP integration.

5. **Cap iteration on every agent.** No unbounded loops. 5-20 iterations per task; surface the cap to callers; escalate to human when hit.

6. **Wire the Citations API for grounded outputs.** Don't parse "[1]" out of prose. Use `cite_documents: true` for any RAG / document-Q&A flow.

7. **Stream user-facing responses.** Non-streaming is for batch / server-side. Any chat / generate flow that doesn't stream feels broken.

8. **Configure spend caps before launching.** Per-key, per-workspace, organization-wide. The cap is your line of defense against runaway bugs and bad actors. The Admin API exposes this; automate at provisioning time.

9. **Trust boundaries on every input.** User input goes in user messages, not the system prompt. Retrieved documents go in `document` content blocks, not interpolated into prompts. Tool outputs are untrusted until validated.

10. **Read the AUP before shipping customer-facing.** Some use cases are prohibited; some require notification; all require operator-side disclosure to end users. `https://www.anthropic.com/legal/aup`.

## Skill-trigger discipline

Because this is itself a Skill and the whole ETYB system depends on Skill-trigger matching:

- This Stack auto-loads when the user's message or context contains any of the trigger keywords listed in `description.triggers`. The list is intentionally broad — Claude API, every model name, every product surface, common synonyms.
- If you find yourself doing Claude work and this Stack didn't load, the trigger list is missing a keyword. Add it (revisit the Stack manifest in `skills-lock.json` if your version controls it that way).
- If this Stack loads when it shouldn't (e.g., the user mentioned "claude" as a person's name), the triggers are too broad. Tighten.
- The 30 currently-listed triggers (in `description`) reflect the actual Anthropic surface as of May 2026. New surfaces (e.g., a hypothetical Claude Voice product) would extend this list.

## Tier — which deployments include this Stack

- **Lite tier:** Includes this Stack. Claude is ETYB's own substrate; the Lite tier needs it.
- **Core tier:** Includes this Stack.
- **Pro tier:** Includes this Stack.

This Stack is Tier-Universal — wherever ETYB runs on Claude, this pack should load.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- **No fine-tuning coverage.** Anthropic doesn't currently offer fine-tuning on Claude. If/when it ships, this Stack adds it.
- **No detailed coverage of Anthropic's Workbench evaluation features.** Brief mentions only; deep eval design lives in `qa-engineer` core skill + project-specific eval suites.
- **No detailed coverage of MCP authoring SDKs in Go / Java / C# / Rust.** TypeScript and Python SDKs are the primary supported paths; the backend-architect overlay covers those and notes the others.
- **No coverage of the Anthropic-managed model gateway products for non-Claude models** — if Anthropic ever ships a generic model router, that's a separate concern.
- **Sub-agent coordination details live in ETYB core** (`skills/etyb/core/subagent-protocol.md`). This Stack mentions sub-agents as a Claude Code surface; the discipline of using them lives in ETYB's always-on protocols.
- **No detailed coverage of Claude's safety / Constitutional AI internals.** Treated as black-box; security-engineer overlay covers operator-side safety.
- **No coverage of Anthropic's research APIs / experimental features** (RL fine-tuning preview, etc.) — covered only via release notes.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.
