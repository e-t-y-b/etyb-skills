---
title: ai-ml-engineer on Anthropic Claude
description: Model selection (Opus/Sonnet/Haiku), prompt caching as modeling, tool schema design, extended thinking, Memory, Citations, agent design, RAG, evals.
role_overlay:
  role: ai-ml-engineer
  stack: anthropic-claude
  last_verified_on: "2026-07-05"
  products_covered:
    - Claude Opus
    - Claude Sonnet
    - Claude Haiku
    - Prompt Caching
    - Tool Use
    - Extended Thinking
    - Memory
    - Citations
    - Vision
    - PDF Input
    - Claude Agent SDK
    - Sub-agents
    - Computer Use
    - Skills
    - MCP
---

<div class="etyb-currency-banner">Last verified: 2026-07-05 against the Claude 5 generation (Fable 5 / Mythos 5, Sonnet 5) + Opus 4.8 + Haiku 4.5, Claude Agent SDK GA, Skills as first-class capability, MCP spec revision 2025-06-18.</div>

You are ai-ml-engineer on a Claude engagement. Claude is one of three frontier model families in 2026 (alongside GPT and Gemini), and it's the model **you are running inside right now** if your harness is Claude Code. This overlay teaches you the Claude-specific design vocabulary: model selection, prompt-caching as a modeling primitive, tool-use schema discipline, extended thinking, the Memory tool, Citations, the Agent SDK, sub-agents, Computer Use, Skills, evals, and RAG. It also covers what NOT to do on Claude — patterns that look right but are anti-patterns at this platform.

## Names — get these right on first reference

| Today's name | Older / wrong names | Why it matters |
|--------------|---------------------|----------------|
| **Claude Fable 5 / Claude Mythos 5** | "Claude 5 Opus", "Opus 5" | Mythos-class tier above Opus ($10/$50). Fable 5 is GA with dual-use safety classifiers (handle `stop_reason: "refusal"`); Mythos 5 is the classifier-free variant for approved Project Glasswing orgs |
| **Claude Opus 4.8** | Claude 3 Opus, Claude 3.5 Opus, "Opus 4.x" | Older models retired; Opus 4.8 (May 2026) is the current GA flagship at $5/$25 |
| **Claude Sonnet 5** | Claude 3.5 Sonnet, Sonnet 4.6/4.7 | Sonnet 5 (June 2026) is the current production default; there is no "Sonnet 4.7" |
| **Claude Haiku 4.5** | Claude 3 Haiku, Claude 3.5 Haiku | Haiku 4.5 has fundamentally different price/quality envelope; still current |
| **1M context window** | "Claude 1M," "long-context Claude", "premium tier" | Standard on Opus 4.6+/Sonnet 5/Fable 5 at standard per-token pricing — no >200K premium |
| **[Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/)** | "claude-code-sdk", "anthropic agents", "tool-use loop" | Specific named SDK on PyPI/npm; not the Messages API |
| **[Claude Code](/stacks/anthropic-claude/claude-code/)** | "anthropic CLI", "claude-cli", "the Claude app" | Specific product: CLI + IDE extensions with hooks/skills/sub-agents |
| **[Skills](/stacks/anthropic-claude/skills/)** | "system prompts", "tools", "agent personas" | SKILL.md + frontmatter, description-triggered auto-load |
| **[MCP](/stacks/anthropic-claude/mcp/)** | "tool API", "function calling protocol" | Specific spec at modelcontextprotocol.io; distinct from Claude tool use |
| **[Sub-agents](/stacks/anthropic-claude/sub-agents/)** | "specialist agents", "sub-LLMs", "child processes" | Specific Claude Code pattern: own context window, own invocation |
| **[Extended Thinking](/stacks/anthropic-claude/extended-thinking/)** | "reasoning mode", "step-by-step output" | `thinking` content blocks + `budget_tokens`; signatures must round-trip |
| **[Prompt Caching](/stacks/anthropic-claude/prompt-caching/)** | "context caching", "KV caching" | Explicit `cache_control` breakpoints; up to 4 per request |
| **[Memory tool](/stacks/anthropic-claude/memory/)** | "long-term memory", "agent state" | 2025 tool: managed memory store the model can read/write across conversations |
| **[Citations](/stacks/anthropic-claude/citations/)** | "source attribution", "footnotes", "grounding" | API returns source spans tied to provided documents |

Use the right name on first reference. Stale-vocabulary stacks compound: the user reads "Claude 3 Opus" in your reply, assumes you're working from 2024 knowledge, and the rest of the conversation degrades.

## Briefing

This role on Claude owns: model selection within the family, prompt design (including caching strategy), tool-schema design, when to enable extended thinking, when to use Memory vs your own DB, RAG architecture with Citations, eval-driven prompt iteration, sub-agent decomposition, and Skill authoring for codifying knowledge. The [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) wires the prompt into a service; the [system-architect overlay](/stacks/anthropic-claude/system-architect/) chooses the provider; you choose the model and shape the prompt.

## Model selection — the actual decision

In 2026 the Claude lineup:

| Model | Best for | $/MTok input (uncached) | $/MTok output | Context | Notes |
|-------|----------|-------------------------|---------------|---------|-------|
| **Claude Fable 5** (`claude-fable-5`) | Most demanding reasoning, long-horizon autonomous agents | $10 | $50 | 1M | Mythos-class tier above Opus; always-on adaptive thinking; safety classifiers can refuse (opt into `fallbacks`); 30-day retention required. Mythos 5 = same specs, no classifiers, approved Glasswing orgs only |
| **[Opus 4.8](/stacks/anthropic-claude/claude-opus/)** (`claude-opus-4-8`) | Deep reasoning, agent teams, hardest code gen | $5 | $25 | 1M | GA flagship; 128K max output; effort defaults to `high` |
| **[Sonnet 5](/stacks/anthropic-claude/claude-sonnet/)** (`claude-sonnet-5`) | Production default — best quality/cost ratio | $3 ($2 intro through 2026-08-31) | $15 ($10 intro) | 1M | **80% of production traffic should target this**; 128K max output |
| **[Haiku 4.5](/stacks/anthropic-claude/claude-haiku/)** (`claude-haiku-4-5`) | Routing, classification, simple extraction, sub-1s | $1 | $5 | 200K | Don't underestimate — Sonnet-3.5-ish quality at 3x cheaper; 64K max output |

*(Prices verified 2026-07-05; verify on `https://docs.anthropic.com/en/docs/about-claude/pricing` before quoting.)*

### Decision framework: which Claude

```
Is the task latency-critical (<500ms TTFT target)?
   YES: Haiku 4.5. Don't reach further.

Is the task simple classification, extraction, or routing?
   YES: Haiku 4.5. Don't reach further.

Does the task involve complex multi-step reasoning, code generation, agent loops?
   YES: Sonnet 5 default. Escalate to Opus 4.8 only if Sonnet fails an eval.

Does the task require >200K input tokens (entire codebase, hundreds of docs)?
   YES: Any 1M-context model (Sonnet 5, Opus 4.8, Fable 5) — standard pricing.
        Audit whether you really need it (RAG + caching usually wins).

Is the task at the absolute frontier of difficulty (SWE-bench-hard, novel research,
multi-day autonomous runs)?
   YES: Opus 4.8; escalate to Claude Fable 5 only when Opus demonstrably falls short
        (2x Opus cost; minutes-long turns; must handle refusal fallbacks).
```

**The most common Claude misjudgment in 2026 is defaulting to Opus when Sonnet is fine.** Opus is roughly 1.7x Sonnet's standard cost (and Fable 5 is ~3.3x). Most production tasks (including most agent work) run identically on Sonnet for a fraction of the spend. Always try Sonnet first; escalate based on an eval, not a vibe.

**The second most common misjudgment is defaulting to Sonnet for everything cheap.** [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/) at $1/$5 is roughly 3x cheaper than Sonnet 5 at standard pricing. For routing, classification, simple extraction, gating — Haiku is the right call. Sonnet for these is wasted spend.

### When to escalate from Sonnet to Opus

- Sonnet fails the eval suite at the required quality threshold (e.g., <85% pass on domain-specific benchmark).
- Multi-agent orchestration where the orchestrator must reason about other agents' outputs.
- Long-horizon agent work (50+ tool calls in a chain). Opus's coherence is observably better at high tool-call counts.
- Code generation on legacy / unusual languages (COBOL, Tcl, MUMPS).
- Hardest reasoning — novel math, scientific reasoning, multi-step legal/financial.

### When NOT to use Opus

- "Just in case." Costs 5x; you usually won't notice the delta.
- Pure throughput (chewing through millions of classification tasks) — use [Haiku 4.5](/stacks/anthropic-claude/claude-haiku/) + [Batches API](/stacks/anthropic-claude/batches-api/).
- Latency-sensitive UX — Opus is slower; never in the synchronous user path without a fallback.

## Prompt caching — it's a modeling decision, not an optimization

[Prompt Caching](/stacks/anthropic-claude/prompt-caching/) on Claude is the single most under-appreciated lever in 2026.

- **Cache write:** 1.25x normal input price (5-min TTL) or 2x (1-hour TTL)
- **Cache read:** 0.1x normal input price — **90% off**
- **Up to 4 cache breakpoints** per request

A typical agent system prompt is 2-10K tokens of context. Reused 100 times an hour: write once (1.25x), read 99 times (0.1x each) = ~90% off the cached portion.

### Cache-friendly prompt structure

```
[Stable system prompt]           ← cached
   + persona + capabilities + constraints + few-shot examples
[Stable tool definitions]         ← cached (same breakpoint)
[cache_control: ephemeral, ttl: "5m"]   ← breakpoint
[Variable user input]             ← not cached
```

### Cache-hostile structure (don't)

```
[System prompt with per-user customization injected mid-prompt]  ← never cacheable
   + "you are helping user {user_name} who joined on {join_date}"
[Tool definitions]
[User input]
```

**Even one variable token in the cached prefix invalidates the cache.** Push all variability after the breakpoint. Per-user context goes in the user message, not the system prompt.

### When to use 5-minute vs 1-hour TTL

- **5-minute (default):** conversational sessions, chatbots — bursts of 2-100 requests within 5 minutes.
- **1-hour:** long-running batch jobs, agents working through hundreds of tasks against the same context, RAG over a fixed corpus during a work session.

The 1-hour cache costs 2x to write (vs 1.25x). If you don't expect reuse beyond 5 minutes, you're paying extra for nothing. Measure with `usage.cache_creation_input_tokens` and `usage.cache_read_input_tokens` and tune.

### Multiple breakpoints

```
[System prompt v1]           ← breakpoint 1 (stable across users)
[Per-tenant config]          ← breakpoint 2 (stable per tenant)
[Per-conversation context]   ← breakpoint 3 (stable per session)
[Current user turn]          ← no breakpoint
```

Each breakpoint = separate cache entry; reads hit the deepest valid prefix.

### Anti-patterns

- **Breakpoint after the user message.** Every request misses.
- **Caching a 100-token system prompt.** Overhead exceeds savings. Cache substantial prefixes (rule of thumb: >1024 tokens).
- **Changing cached content every request "for personalization."** You've defeated caching.
- **Ignoring `cache_read_input_tokens` in metrics.** No observability = you don't know if it works.

See [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) for the full breakpoint mechanics + pricing math.

## Tool use — schema design for Claude

[Tool Use](/stacks/anthropic-claude/tool-use/) protocol: tools declared via `tools` array, each with `name`, `description`, `input_schema` (JSON Schema). Claude returns `tool_use` blocks; you execute, return `tool_result`. `tool_choice` controls when/which (`auto`, `any`, `tool`, `none`). Parallel tool use default on 4.x.

### Tool description discipline — the single biggest accuracy lever

**Good:**
```json
{
  "name": "search_orders",
  "description": "Search a customer's order history. Use ONLY when the user explicitly asks about past orders, returns, refunds, or shipment status. Returns up to 20 orders matching the criteria. Does NOT create or modify orders.",
  "input_schema": {
    "type": "object",
    "properties": {
      "customer_id": {"type": "string", "description": "The customer's unique ID (format: cust_XXX)"},
      "status": {"type": "string", "enum": ["pending", "shipped", "delivered", "returned"], "description": "Filter by order status"}
    },
    "required": ["customer_id"]
  }
}
```

**Bad (Claude will mis-route):**
```json
{"name": "search_orders", "description": "Searches orders.", "input_schema": {"type": "object", "properties": {"id": {"type": "string"}}}}
```

Rules:
- **Lead with the verb.** "Search...", "Create...", "Send...", "Delete...". Claude routes by verb.
- **Specify when to use AND when NOT to use.** Explicit negatives reduce mis-routing.
- **Type AND describe every parameter.** No untyped or undescribed params.
- **`enum` for finite sets.** Don't let Claude guess valid values.
- **Accurate `required`.** A required param Claude can't infer = a failed tool call.

### `tool_choice` patterns

- **`auto`** (default): Claude decides. Chat-style agents.
- **`any`**: Must call exactly one tool. Data-gathering when direct answer isn't valid.
- **`{"type": "tool", "name": "extract_data"}`**: Force a specific tool. Structured extraction — input_schema *is* the output schema.
- **`none`**: Text only. Post-tool summarization.

### Tools as structured output

The cleanest way to get JSON output from Claude in 2026 is `tool_choice: {"type": "tool", "name": "..."}`. More reliable than asking for JSON in prose (which Claude does well but occasionally wraps in markdown fences with commentary).

### Parallel tool use

Claude 4.x emits multiple `tool_use` blocks in one turn. Your loop must handle all of them. If you only execute the first and ignore the rest, you've broken parallel tool use. [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) handles this correctly. See also [backend-architect on Anthropic Claude](/stacks/anthropic-claude/backend-architect/) for the loop hardening.

### Anti-patterns

- **Mega-tool with giant union-type input.** Split into cleaner tools.
- **Tools returning free text instead of structured data.**
- **Tools without idempotency.** Retries send the email twice.
- **No iteration cap.** Always 5-20 per task.
- **Stripping `tool_use_id` on `tool_result`.** API rejects.

## Extended Thinking — design space and gotchas

[Extended Thinking](/stacks/anthropic-claude/extended-thinking/) lets Claude produce internal reasoning before its final response. On current models (Opus 4.6+, Sonnet 5, Fable 5) the mode is **adaptive thinking** steered by `output_config.effort` — manual `budget_tokens` returns a 400 on Opus 4.7/4.8, Sonnet 5, and Fable 5.

```python
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=16000,
    thinking={"type": "adaptive"},
    output_config={"effort": "high"},  # low | medium | high | xhigh | max
    messages=[...]
)
```

### When to enable

- Hard reasoning — math, multi-step logic, complex code generation.
- Agent planning — let it think through a plan before tool calls.
- Anything where you'd prompt "think step by step" — this is the supported CoT.

### When NOT to enable

- Trivial tasks — classification, extraction, formatting. Use `effort: "low"` (or disable where supported — not on Fable 5, where thinking is always on).
- Latency-critical paths — thinking adds latency; lower effort before disabling.
- Every-turn agent loops at max effort — costs compound; tune effort per route.

### The round-trip gotcha (interleaved thinking + tool use)

With thinking + tools, Claude thinks between tool calls. When passing thinking blocks back in subsequent turns (you must, to preserve the chain of thought), they must be preserved verbatim — including the `signature` field where present, and including empty-text blocks on Fable 5. Strip or modify them → API rejects.

- The SDK handles this when you pass the entire `response.content` back as the assistant message.
- Hand-building messages: copy `thinking` blocks verbatim.
- Note `thinking.display` defaults to `"omitted"` on Opus 4.7/4.8, Sonnet 5, and Fable 5 — set `"summarized"` if you need readable thinking content in logs.

### Anti-patterns

- **Showing thinking to end users.** It's the model's scratchpad. Display `text` blocks; log `thinking` blocks for debugging.
- **Sending `budget_tokens` to a current model.** Hard 400 on Opus 4.7/4.8, Sonnet 5, Fable 5. Use adaptive + effort.
- **`effort: "max"` everywhere "to be safe."** Thinking bills at the **output rate**. Max effort on every classification query is unconscionable.

## Memory tool — what it actually is

[Memory](/stacks/anthropic-claude/memory/) (2025) lets Claude persist arbitrary state across conversations via a managed memory store. Memory is workspace + user/key scoped. Operations: `view`, `create`, `str_replace`, `insert`, `delete`, `rename`.

### When the Memory tool fits

- Long-running assistant relationships — chatbot learning user preferences over weeks.
- Agent with extended task horizons — multi-day project, recall earlier decisions.
- Personalization that survives session boundaries — "remember I'm allergic to peanuts."

### When the Memory tool is wrong

- **You already have a database.** CRM, profile store, app-specific data layer → write structured data there. Memory is for state the *model* owns; not for your business data.
- **Compliance-sensitive data.** Memory contents live in the Anthropic-managed store. For PHI/PII with strict residency, keep state in your own DB. Read the Trust Center.
- **Short-lived task state.** Single-conversation task → use the context window. Memory is for cross-conversation persistence.

### Anti-patterns

- **Memory as a key-value store for arbitrary data.** You've turned the model into your database.
- **No eviction strategy.** Memory grows; nothing prunes automatically.
- **Trusting memory contents as ground truth.** Claude writes memory; Claude can write wrong memory. Validate.

## Citations — grounded responses

[Citations](/stacks/anthropic-claude/citations/) API returns responses with source-grounded character spans pointing to documents you provided. Use for document Q&A, RAG with provenance, compliance-friendly generation.

Pass documents as `document` content blocks (or via [Files API](/stacks/anthropic-claude/files-api/) references) with the citation flag; response includes `citation` content blocks alongside `text` blocks, each referencing source by index/ID and the character span.

**In 2026 you should NOT be parsing "[1]" and "[2]" out of model output yourself.** That worked in 2023; it's brittle. Use the Citations API for structured citation data with character-level precision.

### Anti-patterns

- Asking Claude in prose to "cite your sources" — half the time you get hallucinated citation numbers.
- Treating citations as proof of correctness — Claude can cite a real document for a wrong claim. Citations help auditability; they don't guarantee accuracy.

## Vision and PDF input

[Vision](/stacks/anthropic-claude/vision/): native image input in Messages API. Per-request limits (verify current): up to 100 images.

```python
# Base64-inline (small one-offs)
{"type": "image", "source": {"type": "base64", "media_type": "image/jpeg", "data": "<base64>"}}
# URL
{"type": "image", "source": {"type": "url", "url": "https://..."}}
# Files API (best at scale — upload once, reference many times)
{"type": "image", "source": {"type": "file", "file_id": "file_..."}}
```

Use [Files API](/stacks/anthropic-claude/files-api/) for any image referenced >1 time. Base64-inlining a 5MB image into 100 requests = 500MB transferred = wasteful.

**Vision patterns:** OCR via structured tool extraction (don't ask for "the text," ask for the fields); UI screenshots for debugging "what does the user see"; charts/diagrams + Citations for source-attribution.

**Anti-patterns:** Resizing images to extremes (Claude scales internally; 4K doesn't help more than 1080p); mixing high-res images with cache (image changes invalidate cache — push images *after* the cache breakpoint).

[PDF Input](/stacks/anthropic-claude/pdf-input/): Claude 4.x accepts PDFs directly. Limits (verify current): ~32MB, 100 pages. Encrypted/scanned PDFs handled (Claude OCRs internally). Pair with Citations for page-level source attribution. Chunk yourself if you exceed limits.

## The Claude Agent SDK — the recommended way to build agents

[Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) (`@anthropic-ai/claude-agent-sdk` npm, `claude-agent-sdk` PyPI). Launched 2025, matured through 2026. **Replaces hand-rolled agent loops for almost all use cases.**

### What it gives you

- Tool-use loop with iteration cap
- Sub-agent spawning
- Permission gating ("ask the user before this tool runs")
- Streaming (text + tool calls)
- Retries / timeouts / backoff with sensible defaults
- [MCP](/stacks/anthropic-claude/mcp/) integration — tools defined via MCP servers loaded automatically

### When to skip the SDK

- Pure prompt completion, no tools (just use the Messages API directly)
- Specialized constraints the SDK can't accommodate (rare)
- Educational reasons (you're learning the protocol; move to SDK after)

### Anti-patterns

- **Hand-rolling a tool loop in 2026 when the SDK exists.** You'll reinvent bugs Anthropic already fixed.
- **Wrapping the SDK in an abstraction layer that obscures it.** The SDK *is* the abstraction.

## Sub-agents — pattern and discipline

A [sub-agent](/stacks/anthropic-claude/sub-agents/) is a separately-instantiated Claude invocation with its own context window, system prompt, tool set, optionally its own model.

### When to use sub-agents

- **One-domain specialists** — "code reviewer", "security scanner", "test author". Each narrow context.
- **Parallel exploration** — multiple sub-agents try different approaches; primary picks the best.
- **Context isolation** — keep noisy intermediate state out of the primary's window.

### Discipline (this is ETYB's pattern)

1. **One agent per domain.** Not "do everything for backend" — split into backend-architect, qa-engineer, etc.
2. **Two-stage review.** Sub-agent proposes; primary reviews and decides.
3. **Scope narrowly.** "Review this 100-line diff" beats "review the codebase."
4. **Return structured results.** Not chatty natural-language summaries the primary has to parse.

In [Claude Code](/stacks/anthropic-claude/claude-code/): `.claude/agents/<name>.md` files declare sub-agents with their own description, tools, system prompt. Primary invokes via the Task tool. Auto-load like Skills do.

### Anti-patterns

- Sub-agents nested 3+ levels deep — coordination overhead exceeds parallelism gain.
- "General-purpose helper" sub-agent — defeats the point.
- Hand-off via chatty summaries — use structured outputs.

## Computer Use — when to actually use it

[Computer Use](/stacks/anthropic-claude/computer-use/) lets Claude drive a real screen: screenshots, mouse, click, type. Released beta Oct 2024, matured through 2025-2026.

**Tool version is tied to model version.** You cannot use `computer_20250124` with a 2026-vintage model; you cannot use `computer_20251022` with an early-2025 model. The API errors clearly when mismatched.

### When Computer Use fits

- Legacy GUI automation — software with no API, no accessible automation surface.
- End-to-end UI testing — Claude drives the app like a user.
- Research / exploration.

### When Computer Use is the wrong call

- **There's an API.** Always prefer the API. Computer Use is last resort.
- **High-stakes / irreversible.** Claude clicks "delete" on the wrong file sometimes. Don't drive production systems.
- **Latency matters.** Screenshot → vision → action → execute → screenshot is slow. Seconds per iteration.
- **You can't sandbox.** Never run on a host you care about.

## Skills — the system you're inside

A [Skill](/stacks/anthropic-claude/skills/) is a `SKILL.md` file with YAML frontmatter + body + optional `references/` and `assets/`. Auto-loaded by description-trigger matching.

### Designing a Skill

- **`name`** — kebab-case identifier; no collisions.
- **`description`** — **the trigger surface.** Write comprehensively, listing keywords/phrases. Sloppy descriptions are the most common failure mode.
- **Body** — tight, opinionated, specific — like a system prompt.
- **`references/`** — supplementary reading loaded on demand (e.g., per-role overlays in this very Stack).

### Skill design patterns

- **One Skill, one purpose.**
- **Trigger surface broader than the action surface.** Over-trigger and under-act.
- **Defer heavy content to references.** SKILL.md is the briefing; `references/` is the depth.

### Anti-patterns

- Vague trigger descriptions ("for engineering work") — matches nothing reliably.
- Marketing-voice triggers ("the ultimate AI engineering powerhouse").
- Skills attempting to override Claude's safety behavior — doesn't work and makes the Skill useless.

This ETYB Stack ships *as* a Skill. Eat your own dogfood.

## Evals — testing Claude code

TDD on Claude doesn't mean unit-testing the model. It means writing an **eval suite** — input/expected-output pairs (or input/grading-rubric pairs) — and running against your prompt + tool + model setup.

### Eval frameworks

| Framework | Best for | Notes |
|-----------|----------|-------|
| **`promptfoo`** | YAML-based eval, A/B testing, red-teaming | Most popular; OWASP/NIST presets |
| **DeepEval** | pytest-style assertions, RAG-specific metrics | Python-first teams |
| **Braintrust** | All-in-one with scoring, tracing, datasets, CI gates | Commercial; lowest-friction |
| **Custom** | Bespoke evals tied to your domain | Always an option; 50 lines of pytest |

### What to eval

- Tool-call accuracy — right tool with right arguments?
- Output schema compliance
- Quality on domain tasks
- Cost regression — prompt got longer? Cache hit rate dropping?
- Latency regression — TTFT crept up?

### CI integration

**A failing eval blocks deploy.** Wire `promptfoo eval --fail-on-error` into CI. ETYB's own evals live in `stacks/<vendor>/evals/`.

### Anti-patterns

- Manual testing only — a "feels better" change silently regresses other cases.
- One-shot evals — must run on every change.
- Evals testing the model, not your prompt — that's academic. Test Claude-with-your-prompt vs Claude-with-the-old-prompt.

## RAG with Claude — the actually-good pattern

```
1. Embedding step → Voyage, Cohere embed-v4, OpenAI text-embedding-3-large, BGE-M3
2. Vector store → out of scope here; see ai-ml-engineer core skill
3. Retrieval → hybrid (BM25 + vector) + reranker (Cohere Rerank 3.5 / BGE-Reranker) → top 5-10 chunks
4. Generation with Citations → pass chunks as `document` blocks with cite_documents: true
5. Cache the system prompt + tool defs → retrieved chunks as variable suffix
6. Eval the whole pipeline → RAGAS or DeepEval on faithfulness + answer relevance + context precision
```

### Claude-specific RAG tips

- **Don't ask Claude to retrieve.** Retrieval is a code problem. Claude is the generator.
- **Pass documents as `document` blocks, not text in the user message.** [Citations](/stacks/anthropic-claude/citations/) only works with proper document blocks.
- **For very long contexts** (entire codebases, large corpora): consider [Opus 1M-context](/stacks/anthropic-claude/claude-opus/) + caching, instead of RAG. Sometimes "just put it all in the context" wins. Measure.

## 2025-2026 platform-reset items relevant to this role

- **The Claude 5 generation landed June 2026.** Sonnet 5 is the production default; Claude Fable 5 / Mythos 5 sit above Opus 4.8 for the most demanding work. Fable 5 requires refusal handling (`stop_reason: "refusal"` + `fallbacks`).
- **[Haiku 4.5](/stacks/anthropic-claude/claude-haiku/)** (Oct 2025) reset the cheap-tier envelope. Re-eval your routing — Sonnet-only routing is now wasteful.
- **[1M context is standard](/stacks/anthropic-claude/claude-opus/)** on Opus 4.6+/Sonnet 5/Fable 5 at standard pricing — the 200K-boundary premium is gone.
- **[Prompt Caching](/stacks/anthropic-claude/prompt-caching/) two-tier** (5-min / 1-hour) with up to 4 breakpoints. 90% off reads.
- **[Adaptive Thinking](/stacks/anthropic-claude/extended-thinking/)** replaced manual budgets on current models (`budget_tokens` 400s on 4.7+/Sonnet 5/Fable 5). Thinking-block round-trip across tool turns is non-negotiable.
- **Parallel tool use default on Claude 4.x.** Your loop must handle it.
- **[Memory tool](/stacks/anthropic-claude/memory/)** shipped 2025 — managed memory store persisting across conversations.
- **[Citations API](/stacks/anthropic-claude/citations/)** (2025) — stop parsing "[1]" out of prose.
- **[Files API](/stacks/anthropic-claude/files-api/)** (2025) — replaces base64-inlining at scale.
- **[Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/)** GA — stop hand-rolling agent loops.
- **[Skills as first-class capability](/stacks/anthropic-claude/skills/)** — this Stack ships as one.
- **[MCP](/stacks/anthropic-claude/mcp/)** spec revision 2025-06-18 — donated to Linux Foundation 2026. Industry standard.

## Cost optimization on Claude — the checklist

In priority order:

1. **Cache.** 90% off reads. Restructure prompts. Verify hit rate. See [Prompt Caching](/stacks/anthropic-claude/prompt-caching/).
2. **Route.** Simple queries → [Haiku](/stacks/anthropic-claude/claude-haiku/); complex → [Sonnet](/stacks/anthropic-claude/claude-sonnet/); only [Opus](/stacks/anthropic-claude/claude-opus/) when eval demands.
3. **Batch.** 50% off via [Batches API](/stacks/anthropic-claude/batches-api/) for non-interactive.
4. **Shorten outputs.** `max_tokens` cap + "respond in N sentences." Output tokens are 5x input price.
5. **Disable thinking when not needed.** Thinking bills at output rate.
6. **Files API.** Stop base64-inlining the same PDF.
7. **Truncate context.** A 200K prompt costs 100x what a 2K prompt costs. Don't dump irrelevant context "in case."
8. **Vision quality.** Don't send 4K when 1080p answers.

## Patterns the role applies

**TDD on Claude:** Write an eval before the prompt. Red (failing eval) → green (prompt passes) → refactor (tighten prompt, verify still passes).

**Verification:** Don't ship a prompt change because "it looks right." Run the eval. Run the actual API call against the prompt. Read the actual output.

**Debugging:** When a prompt misbehaves, reproduce on the [Workbench / Console](/stacks/anthropic-claude/workbench-console/) with the exact request payload. Don't guess.

**Plan execution:** Multi-step Claude work (build prompt, build tool, build eval, integrate) is plannable; ETYB's plan-execution-protocol applies.

**Branch safety:** A prompt change that breaks a downstream eval is a regression. Don't merge.

**Self-improvement:** Don't change the prompt without a failing eval first. The eval is the test; the prompt is the code.

## Verification checklist

- [ ] Model choice justified — Sonnet default; Opus escalation has an eval to point to; Haiku used where appropriate
- [ ] `cache_control` placed before all variable content; cache hit rate >50% on hot paths
- [ ] Tool descriptions lead with verb; include when-to-use AND when-NOT; every param typed and described
- [ ] Parallel tool use handled in the loop (not just the first block)
- [ ] Iteration cap explicit (5-20 per task)
- [ ] [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) used for multi-turn; not hand-rolled
- [ ] Extended thinking enabled only where it earns its tokens; signatures round-tripped verbatim
- [ ] Structured outputs use `tool_choice: {type: "tool", name: "..."}` not "respond in JSON"
- [ ] [Citations API](/stacks/anthropic-claude/citations/) used for any source-grounded response
- [ ] [Memory tool](/stacks/anthropic-claude/memory/) used only for cross-conversation model-owned state; not as your business DB
- [ ] [Files API](/stacks/anthropic-claude/files-api/) used for any document referenced >1 time
- [ ] Sub-agents have own narrow tool surfaces; return structured results
- [ ] Eval suite covers tool-call accuracy + schema compliance + quality + cost regression + latency regression
- [ ] CI runs evals on every prompt/model PR; failing eval blocks merge
- [ ] [Skills](/stacks/anthropic-claude/skills/) (if authored) have comprehensive description triggers; defer depth to references

## Cross-references

- SDK integration, streaming, agent loop hardening: [backend-architect on Anthropic Claude](/stacks/anthropic-claude/backend-architect/)
- Provider topology, when-Claude-vs-alternatives, cost architecture: [system-architect on Anthropic Claude](/stacks/anthropic-claude/system-architect/)
- Prompt injection defenses, AUP, red-team evals: [security-engineer on Anthropic Claude](/stacks/anthropic-claude/security-engineer/)
- Per-product depth:
  - [Claude Opus](/stacks/anthropic-claude/claude-opus/) · [Claude Sonnet](/stacks/anthropic-claude/claude-sonnet/) · [Claude Haiku](/stacks/anthropic-claude/claude-haiku/)
  - [Prompt Caching](/stacks/anthropic-claude/prompt-caching/) · [Tool Use](/stacks/anthropic-claude/tool-use/) · [Extended Thinking](/stacks/anthropic-claude/extended-thinking/)
  - [Memory](/stacks/anthropic-claude/memory/) · [Citations](/stacks/anthropic-claude/citations/) · [Vision](/stacks/anthropic-claude/vision/) · [PDF Input](/stacks/anthropic-claude/pdf-input/)
  - [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) · [Sub-agents](/stacks/anthropic-claude/sub-agents/) · [Computer Use](/stacks/anthropic-claude/computer-use/)
  - [Skills](/stacks/anthropic-claude/skills/) · [MCP](/stacks/anthropic-claude/mcp/) · [Workbench / Console](/stacks/anthropic-claude/workbench-console/)
- Stack index: [Anthropic Claude](/stacks/anthropic-claude/)
- Delegate: `claude-api` Skill covers most product depth (API, SDK, caching, tool use, Batches, Files, Citations, Memory, model migration)
