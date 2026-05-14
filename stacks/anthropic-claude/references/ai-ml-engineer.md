---
role: ai-ml-engineer
stack: anthropic-claude
last_verified_on: "2026-05-14"
---

# Anthropic Claude Overlay — ai-ml-engineer

You are ai-ml-engineer on a Claude engagement. Claude is one of three frontier model families (alongside GPT and Gemini) in 2026, and it's the model **you are running inside right now** if your harness is Claude Code or another Anthropic surface. This overlay teaches you the Claude-specific design vocabulary: model selection, prompt-caching as a modeling primitive, tool-use schema discipline, extended thinking, the Memory tool, Citations, the Agent SDK, sub-agents, and Computer Use. It also covers what to NOT do on Claude — patterns that look right but are anti-patterns at this platform.

**Currency:** Claude 4.x family (Opus 4.x including 1M-context, Sonnet 4.6/4.7, Haiku 4.5), Claude Agent SDK GA, Skills as first-class capability, MCP at spec revision 2025-06-18. Verified 2026-05-14.

## Names — get these right on first reference

| Today's name | Older / wrong names | Why it matters |
|--------------|---------------------|----------------|
| **Claude Opus 4.x** | Claude 3 Opus, Claude 3.5 Opus | Older models are retired or near-retired; pricing and capability differ |
| **Claude Sonnet 4.6 / 4.7** | Claude 3.5 Sonnet, Claude 3.7 Sonnet | The 3.5 Sonnet was a discrete model; 4.x Sonnet is a different generation |
| **Claude Haiku 4.5** | Claude 3 Haiku, Claude 3.5 Haiku | Haiku 4.5 has fundamentally different price/quality envelope; previous reasoning doesn't transfer |
| **1M-context Opus variant** | "Claude 1M," "long-context Claude" | Pricing is tiered at 200K input boundary; treat as a separate product |
| **Claude Agent SDK** | "claude-code-sdk" (early name), "anthropic agents," "tool-use loop" | Specific named SDK on PyPI/npm; not the same as the Messages API |
| **Claude Code** | "anthropic CLI," "claude-cli," "the Claude app" | Specific product: CLI + IDE extensions with hooks/skills/sub-agents |
| **Skills** | "system prompts," "tools," "agent personas" | Specific Anthropic capability: SKILL.md + frontmatter, description-triggered auto-load |
| **MCP** | "tool API," "function calling protocol," "agent protocol" | Specific spec at modelcontextprotocol.io; distinct from Anthropic's tool use, though related |
| **Sub-agents** | "specialist agents," "sub-LLMs," "child processes" | Specific Claude Code pattern: a sub-agent is its own context window and own model invocation |
| **Extended Thinking** | "reasoning mode," "step-by-step output," "thinking blocks" | Specific Claude capability with `thinking` content blocks and `budget_tokens`; signatures must round-trip |
| **Prompt Caching** | "context caching," "KV caching" (provider-side), "memo" | Specific Claude feature: explicit `cache_control` breakpoints; up to 4 per request |
| **Memory tool** | "long-term memory," "Claude memory," "agent state" | Specific 2025 tool: managed memory store the model can read/write across conversations |
| **Citations** | "source attribution," "footnotes," "grounding" | Specific feature: API returns source spans tied to provided documents |

Use the right name on first reference. Stale-vocabulary stacks compound: the user reads "Claude 3 Opus" in your reply, assumes you're working from 2024 knowledge, and the rest of the conversation degrades from there.

## Model selection — the actual decision

In 2026 the Claude lineup is:

| Model | Best for | $/MTok input (uncached) | $/MTok output | Context | Notes |
|-------|----------|-------------------------|---------------|---------|-------|
| **Opus 4.x** (standard) | Deep reasoning, agent teams, complex multi-step work, hardest code generation | $15 | $75 | 200K | The flagship; the most expensive |
| **Opus 4.x** (1M-context, <=200K input) | Same as above, but with headroom | $15 | $75 | 1M | Same price as standard up to 200K |
| **Opus 4.x** (1M-context, >200K input) | Massive context (entire codebases, hundreds of docs) | premium tier (verify current rate) | premium tier | 1M | Significantly more expensive past 200K |
| **Sonnet 4.6 / 4.7** | Production default — best quality/cost ratio at the frontier | $3 | $15 | 200K (1M variant in some configurations) | This is what 80% of production traffic should target |
| **Haiku 4.5** | Routing, classification, simple extraction, real-time / sub-1s targets | $1 | $5 | 200K | Don't underestimate — at Sonnet-3.5-ish quality, this changes routing math |

*(Prices indicative as of May 2026; verify on `https://docs.anthropic.com/en/docs/about-claude/pricing` before quoting.)*

### Decision framework: which Claude

Default flowchart:

```
Is the task latency-critical (<500ms TTFT target)?
   YES: Haiku 4.5. Don't reach further.
   NO:  continue
   
Is the task simple classification, extraction, or routing?
   YES: Haiku 4.5. Don't reach further.
   NO:  continue

Does the task involve complex multi-step reasoning, code generation, agent loops?
   YES: Sonnet 4.7 default. Escalate to Opus only if Sonnet fails an eval.
   NO:  Sonnet 4.7.

Does the task require >200K input tokens (entire codebase, hundreds of docs)?
   YES: Opus 4.x 1M-context. Audit whether you really need it (RAG + caching usually wins).
   NO:  Sonnet 4.7.

Is the task at the absolute frontier of difficulty (SWE-bench-hard, novel research)?
   YES: Opus 4.x.
   NO:  Sonnet 4.7.
```

The most common Claude misjudgment in 2026 is **defaulting to Opus when Sonnet is fine.** Opus is 5x the input cost and 5x the output cost. Most production tasks (including most agent work) run identically on Sonnet for a fraction of the spend. Always try Sonnet first; escalate based on an eval, not a vibe.

The second most common misjudgment is **defaulting to Sonnet for everything cheap.** Haiku 4.5 at $1/$5 is roughly 3x cheaper than Sonnet 4.7. For routing, classification, retrieval-augmentation-step questions, simple extraction, "is this in scope?" gating — Haiku is the right call. Sonnet for these is wasted spend.

### When to escalate from Sonnet to Opus

Concrete triggers:

- **Sonnet fails the eval suite at the required quality threshold** (e.g., < 85% pass on a domain-specific benchmark). Try Opus, measure delta, decide if the cost is worth it.
- **Multi-agent orchestration where the orchestrator must reason about other agents' outputs.** Opus's depth helps; Sonnet sometimes loses the thread on 5+ agent chains.
- **Long-horizon agent work** (50+ tool calls in a chain). Opus's coherence is observably better at high tool-call counts.
- **Code generation on legacy / unusual languages** (COBOL, Tcl, MUMPS). Sonnet handles modern stacks fine; Opus is more reliable on the long tail.
- **Hardest reasoning** — novel math, scientific reasoning, multi-step legal/financial analysis where each step depends on the last.

### When NOT to use Opus

- "Just in case" — costs 5x; you usually won't notice the quality delta.
- For pure throughput (you want to chew through a million classification tasks) — use Haiku 4.5 + Batches API.
- For latency-sensitive UX — Opus is slower; never put it in the synchronous user path without a fallback.

## Prompt caching — it's a modeling decision, not an optimization

Prompt caching on Claude is the single most under-appreciated lever in 2026. The economics:

- **Cache write:** 1.25x the normal input price (5-min TTL) or 2x (1-hour TTL)
- **Cache read:** 0.1x the normal input price — **90% off**
- **Up to 4 cache breakpoints** per request

A typical agent system prompt is 2-10K tokens of context (persona, tool definitions, examples). If that prompt is reused 100 times an hour, you write the cache once (1.25x cost) and read it 99 times (0.1x cost each). Net: ~90% off the input cost for the cached portion.

This is a *modeling* decision because the prompt structure that maximizes cache hits is different from the prompt structure that minimizes naive token count. Specifically:

### Cache-friendly prompt structure

```
[Stable system prompt] ← cached
   + persona
   + capabilities
   + constraints
   + few-shot examples
[Stable tool definitions] ← cached (in the same breakpoint)
[cache_control: { type: "ephemeral", ttl: "5m" }]  ← breakpoint here
[Variable user input]    ← not cached, re-sent each request
```

### Cache-hostile prompt structure (don't do this)

```
[System prompt with per-user customization injected mid-prompt] ← never cacheable
   + "you are helping user {user_name} who joined on {join_date}"
[Tool definitions]
[User input]
```

Even one variable token in the cached prefix invalidates the cache. **Push all variability after the cache breakpoint.** If you need per-user context, put it in the user message, not the system prompt.

### When to use 5-minute vs 1-hour TTL

- **5-minute (default):** Conversational sessions, chatbots, anything where requests come in bursts and you can expect 2-100 requests within 5 minutes of the prior one.
- **1-hour:** Long-running batch jobs, agents working through hundreds of tasks against the same context, RAG over a fixed corpus where the corpus rarely changes during a work session.

The 1-hour cache costs 2x to write (vs 1.25x for 5-min). If you don't expect cache reuse beyond 5 minutes, you're paying extra for nothing. Measure cache hit rate (the API returns `cache_creation_input_tokens` and `cache_read_input_tokens` in the usage block) and tune from there.

### Multiple breakpoints

You can place up to 4 `cache_control` breakpoints in a single request. Useful for layered prompts:

```
[System prompt v1] ← breakpoint 1 (stable across all users)
[Per-tenant config] ← breakpoint 2 (stable for one tenant)
[Per-conversation context] ← breakpoint 3 (stable for one chat session)
[Current user turn] ← no breakpoint (changes every request)
```

Each breakpoint represents a separate cache entry; reads hit the deepest valid prefix.

### Anti-patterns

- **Cache breakpoint after the user message:** every request is a miss. The breakpoint applies to *up to and including* its position; put it before variable content.
- **Caching a 100-token system prompt:** the overhead of caching exceeds the savings. Caching is for substantial prefixes (rule of thumb: >1024 tokens, the more the better).
- **Changing the cached content every request "for personalization":** you've defeated caching. Find a different layer for personalization (user message, retrieved context, post-processing).
- **Ignoring the `usage.cache_read_input_tokens` field:** without observability you don't know if caching works. Log this; alert when hit rate drops.

## Tool use — schema design for Claude

Claude's tool-use protocol is structurally similar to OpenAI's function calling but with Claude-specific niceties:

- Tools are declared via the `tools` array on the Messages API
- Each tool has `name`, `description`, `input_schema` (JSON Schema)
- Claude returns `tool_use` content blocks; you execute the tool and pass results back as `tool_result` content blocks
- `tool_choice` controls when/which tools are called (`auto`, `any`, `tool`, `none`)
- Parallel tool use is supported by default on 4.x models — Claude can emit multiple `tool_use` blocks in one turn

### Tool description discipline

The single biggest determinant of tool-use accuracy on Claude is the quality of tool descriptions. Claude reads descriptions to decide which tool to call. Sloppy descriptions = mis-routing.

**Good tool description:**
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

**Bad tool description (Claude will mis-route):**
```json
{
  "name": "search_orders",
  "description": "Searches orders.",
  "input_schema": { "type": "object", "properties": { "id": {"type": "string"} } }
}
```

Rules:
- **Lead with the verb.** "Search...", "Create...", "Send...", "Delete...". Claude routes by verb.
- **Specify when to use AND when NOT to use** — explicit negatives reduce mis-routing.
- **Type every parameter, describe every parameter.** No untyped or undescribed params.
- **Use `enum` for finite sets.** Don't leave Claude to guess valid status values.
- **Mark `required` accurately.** A required param Claude can't infer = a failed tool call.

### Parallel tool use

Claude 4.x emits multiple `tool_use` blocks in one turn when the task is parallelizable. Your tool-execution loop must:

1. Receive a response with potentially multiple `tool_use` blocks
2. Execute all of them (ideally in parallel)
3. Collect all `tool_result` blocks
4. Pass them all back in the next user turn

If your loop only handles the first `tool_use` and ignores the rest, you've broken parallel tool use. Use the Claude Agent SDK — it handles this correctly. If rolling your own, write a test for the multi-tool case.

### `tool_choice` patterns

- **`auto`** (default): Claude decides whether and which tool to call. Use for chat-style agents.
- **`any`**: Claude must call exactly one tool. Use when the prompt's purpose is to gather data and a direct answer isn't valid.
- **`{"type": "tool", "name": "extract_data"}`**: Force Claude to call a specific tool. Use for structured extraction — the response is guaranteed to be that tool's input schema, which Claude has to fill out.
- **`none`**: Claude cannot call tools, returns text only. Use for follow-up summarization after tools have already run.

### Tools as structured output

The cleanest way to get JSON-compliant structured output from Claude in 2026 is `tool_choice: {"type": "tool", "name": "..."}`. The tool's `input_schema` is the output schema; Claude fills it out and you parse the `tool_use.input` field.

This is more reliable than asking for JSON in prose ("respond in JSON format..."), which Claude does well but with occasional wrapping in markdown code fences, extra commentary, etc.

### Anti-patterns

- **One mega-tool with a giant union-type input.** Splits into multiple cleaner tools.
- **Tools that return free text instead of structured data.** Claude's tool calls are routinely well-formed; have them return structured data too.
- **Tools without idempotency considerations.** If Claude retries a tool, did you just send the email twice?
- **No iteration cap.** Always cap the agent loop at 5-20 tool calls per task.
- **Stripping `tool_use_id` when returning results.** The Messages API requires `tool_result` blocks to reference the originating `tool_use_id`. The SDK handles this; manual REST users get it wrong.

## Extended Thinking — design space and gotchas

Extended Thinking (sometimes called "thinking mode") lets Claude produce internal reasoning before its final response. You see this as `thinking` content blocks in the response, separate from `text` blocks. Configuration:

```python
response = client.messages.create(
    model="claude-sonnet-4-7-20260301",
    max_tokens=8000,
    thinking={
        "type": "enabled",
        "budget_tokens": 4000  # Claude will think up to 4000 tokens before responding
    },
    messages=[...]
)
```

### When to enable extended thinking

- **Hard reasoning problems** — math, multi-step logic, complex code generation.
- **Agent planning** — let the model think through a plan before executing tool calls.
- **Anything where you'd prompt "think step by step"** — extended thinking is the supported way to do CoT.

### When NOT to enable extended thinking

- **Trivial tasks** — classification, extraction, formatting. The thinking budget is wasted tokens.
- **Latency-critical paths** — thinking adds latency proportional to `budget_tokens`. A 4000-token think-budget adds several seconds.
- **Memory-tool / agent loops where every turn thinks** — costs compound; thinking on every turn often isn't necessary.

### Interleaved thinking with tool use

When extended thinking is enabled AND tools are in use, Claude can think between tool calls — think, call tool, see result, think again, call another tool, respond. This is called **interleaved thinking** and it's transformative for complex agents.

**The signature gotcha:** thinking blocks have a `signature` field. When you pass them back to Claude in a subsequent turn (which you must do to preserve the chain of thought across tool calls), the signature must be preserved. If you strip or modify it, the API rejects the request.

- The Anthropic SDK handles this automatically when you pass the entire `response.content` back as the assistant message.
- If you're hand-building messages, copy `thinking` blocks verbatim including the `signature` field.

### Anti-patterns

- **Showing thinking to end users.** Thinking is the model's scratchpad, not customer-facing copy. Display the `text` blocks; log the `thinking` blocks for debugging.
- **Setting `budget_tokens` too low.** If you give Claude 100 tokens to think with on a hard problem, it'll either truncate mid-thought (bad output) or skip thinking (back to non-thinking quality). Either bump the budget or disable thinking.
- **Setting `budget_tokens` too high "to be safe."** You pay for thinking tokens at the output rate. A 16K-token thinking budget on every classification query is unconscionable.
- **Modifying thinking blocks between turns.** The signature breaks; the API rejects. Pass them through verbatim.

## Memory tool — what it actually is

The Memory tool (released 2025) lets Claude persist arbitrary state across conversations via a managed memory store. Architecture:

- You enable the Memory tool by including it in the `tools` array (it's a named built-in tool, similar to other Anthropic tools)
- Claude can call memory operations: `view`, `create`, `str_replace`, `insert`, `delete`, `rename`
- Memory is scoped to the workspace + user/key combination you configure
- The state persists across requests, sessions, conversations — until you delete it

### When the Memory tool fits

- **Long-running assistant relationships** — a customer-facing assistant that learns user preferences over weeks/months.
- **Agent with extended task horizons** — an agent working on a multi-day project that needs to recall earlier decisions.
- **Personalization that survives session boundaries** — "remember that I'm allergic to peanuts" persists for the user.

### When the Memory tool is wrong

- **You already have a database.** If you have a CRM, profile store, or app-specific data layer, write structured data there, not into model-managed memory. Memory is for state the model itself owns; not for structured business data.
- **Compliance-sensitive data.** Memory contents live in the Anthropic-managed memory store. For PHI/PII subject to data residency, you may need to keep state in your own database. Read the Trust Center on data handling for memory contents.
- **Short-lived task state.** A single-conversation task uses the context window. Memory is for things that need to survive across conversations.

### Anti-patterns

- **Using Memory as a key-value store for arbitrary data.** It works, but you've turned the model into your database. Use a real database.
- **Not having a memory-eviction strategy.** Memory grows; nothing prunes it automatically. Decide what's worth keeping, what's stale, what's PII that must be deleted on a schedule.
- **Trusting memory contents as ground truth.** Claude writes memory; Claude can write wrong memory. Validate memory contents the same way you'd validate any LLM output.

## Citations — grounded responses

The Citations API returns responses with source-grounded character spans pointing back to documents you provided. Use it for:

- **Document Q&A** — "Answer this question based on these PDFs; cite where each claim comes from."
- **RAG with provenance** — your RAG pipeline retrieves chunks, you pass them with citations enabled, the response has spans you can render as footnotes.
- **Compliance-friendly generation** — generated text with sources for audit.

### How it works

You pass documents in the `content` array with `cite_documents: true` (or via Files API references with the citation flag); the response includes `citation` content blocks alongside `text` blocks, each citation referencing the source document by index/ID and the character span it grounds.

Render in your UI by mapping citation spans to numbered footnotes; expose document name + character range to the user; let them click through to the original document.

### Why this matters

In 2026 you should not be parsing "[1]" and "[2]" out of model output yourself. That worked in 2023; it's brittle. The Citations API gives you structured citation data with character-level precision. Use it.

### Anti-patterns

- **Asking Claude in prose to "cite your sources"** — you'll get hallucinated citation numbers half the time. Use the Citations API.
- **Treating citations as proof of correctness** — Claude can cite a real document for a wrong claim if the document's text is misinterpreted. Citations help auditability; they don't guarantee accuracy.

## Vision input

Claude 4.x natively accepts images in the Messages API. Per-request limits (verify current): up to 100 images, with size limits per image. Two input modes:

```python
# Base64-inline (fine for small one-offs, bad at scale)
{"type": "image", "source": {"type": "base64", "media_type": "image/jpeg", "data": "<base64>"}}

# URL (Claude fetches the image)
{"type": "image", "source": {"type": "url", "url": "https://..."}}

# Files API reference (best at scale — upload once, reference many times)
{"type": "image", "source": {"type": "file", "file_id": "file_..."}}
```

Use the Files API for any image you'll reference more than once. Base64-inlining a 5MB image into 100 requests = 500MB transferred = wasteful.

### Vision design patterns

- **OCR / document understanding:** Send the page image, ask for structured extraction via a tool. Don't ask for "the text" — ask for the fields you need.
- **UI screenshots:** Claude handles these well; useful for debugging "what does the user see" questions in agents.
- **Charts / diagrams:** Claude can describe and reason about them; couple with the Citations API if you need source attribution.

### Vision anti-patterns

- **Resizing images to extremes:** Claude scales internally; a 4K screenshot doesn't help more than 1080p. Don't pay for tokens that don't help.
- **Mixing high-res images with cache:** Image content invalidates cache if it changes. Push images after the cache breakpoint.

## PDF input

Claude 4.x accepts PDFs directly (no need to OCR first). Implementation:

```python
{"type": "document", "source": {"type": "base64", "media_type": "application/pdf", "data": "<base64>"}}
# or
{"type": "document", "source": {"type": "url", "url": "https://...pdf"}}
# or
{"type": "document", "source": {"type": "file", "file_id": "file_..."}}
```

Pair with the Citations API for grounded responses with page-level source attribution.

### Limits (verify current)

- Up to ~32MB per PDF
- Up to 100 pages per PDF
- Encrypted/scanned PDFs handled (Claude OCRs internally)

If your PDF exceeds limits, you must chunk it yourself. Standard pattern: split by section, send each section in its own request, aggregate.

## The Claude Agent SDK — the recommended way to build agents

`@anthropic-ai/claude-agent-sdk` (npm) and `claude-agent-sdk` (PyPI). Launched 2025, matured through 2026. Replaces hand-rolled agent loops for almost all use cases.

### What it gives you

- **Tool-use loop** — receives a response, executes any `tool_use` blocks, sends results back, loops until model produces a non-tool-use response or hits iteration cap.
- **Sub-agent spawning** — fork a sub-agent with a scoped task, get its result, continue.
- **Permission gating** — hooks for "ask the user before this tool runs" patterns.
- **Streaming** — text and tool calls stream to the caller.
- **Retries / timeouts / backoff** — sensible defaults.
- **MCP integration** — tools defined via MCP servers are loaded automatically if configured.

### When to use the SDK

- Building any multi-turn agent.
- Building a service that wraps Claude with a fixed tool surface.
- Building anything that needs sub-agents.
- Building anything that integrates MCP servers.

### When to skip the SDK

- Pure prompt completion with no tools (just use the Messages API directly).
- Specialized constraints the SDK can't accommodate (rare; the SDK is flexible).
- Educational reasons (you're learning the protocol; you'll move to the SDK once you understand it).

### Anti-patterns

- **Hand-rolling a tool loop in 2026 when the SDK exists.** You will reinvent bugs Anthropic already fixed.
- **Wrapping the SDK in an abstraction layer that obscures it.** The SDK is the abstraction; another layer on top usually slows iteration without adding value.

## Sub-agents — pattern and discipline

A sub-agent is a separately-instantiated Claude invocation with its own context window, its own system prompt, its own tool set, optionally its own model. The primary agent calls the sub-agent for a focused task and gets a result back; the sub-agent's intermediate context never pollutes the primary.

### When to use sub-agents

- **One-domain specialists** — a "code reviewer" sub-agent reviews a diff; a "security scanner" sub-agent runs a checklist; a "test author" sub-agent writes tests. Each has its own narrow context.
- **Parallel exploration** — multiple sub-agents try different approaches; primary picks the best.
- **Context window isolation** — keeping a sub-task's noisy intermediate state out of the primary's window.

### Discipline (this is ETYB's pattern)

1. **One agent per domain.** Don't have a sub-agent "do everything for backend" — split into backend-architect, qa-engineer, etc.
2. **Two-stage review.** Sub-agent proposes; primary reviews and decides. Sub-agent is not authoritative on its own.
3. **Scope the sub-agent's task narrowly.** "Review this 100-line diff" beats "review the codebase."
4. **Return structured results.** A sub-agent should return JSON-shaped findings, not a chatty summary the primary has to parse.

### How sub-agents work in Claude Code

Claude Code has first-class sub-agent support: `.claude/agents/<name>.md` files declare sub-agents with their own description, tools, system prompt. The primary agent invokes them via the Task tool. Sub-agent prompts auto-load like Skills do.

### Anti-patterns

- **Sub-agents nested 3+ levels deep.** Coordination overhead exceeds the parallelism gain.
- **A "general-purpose helper" sub-agent.** Defeats the point — the value of sub-agents is specialization.
- **Sub-agents that hand off via chatty natural-language summaries.** Use structured outputs (tool-call-shaped JSON).

## Computer Use — design space and when to actually use it

Computer Use lets Claude drive a real screen: take screenshots, move the mouse, click, type. Released as beta Oct 2024, matured through 2025-2026. Implementation:

- Run Claude with the `computer_20251022` tool (or current tool version) enabled.
- Provide a virtualized desktop environment (Anthropic publishes Docker images and a reference VM).
- Claude emits actions: `screenshot`, `key`, `type`, `mouse_move`, `left_click`, `right_click`, etc.
- Your harness executes the action, returns the resulting screenshot, loops.

### Tool version is tied to model version

You cannot use `computer_20250124` with a 2026-vintage model; you cannot use `computer_20251022` with an early-2025 model. Pairing is in the docs; the API errors clearly when you mismatch.

### When Computer Use fits

- **Legacy GUI automation** — interacting with software that has no API and no accessible automation surface.
- **End-to-end UI testing** — Claude drives the app like a user; verifies behaviors.
- **Research / exploration** — letting Claude explore an interface you're studying.

### When Computer Use is the wrong call

- **There's an API.** Always prefer the API. Computer Use is the option of last resort.
- **The task is high-stakes and irreversible.** Claude clicks "delete" on the wrong file sometimes. Don't let it drive production systems.
- **Latency matters.** Screenshots → vision → action → execute → screenshot is slow. Each iteration is seconds.
- **You can't sandbox.** Never run Computer Use on a host you care about. The sandboxing requirement is real.

### Anti-patterns

- **Running Computer Use on a developer laptop without isolation.** One bad action and your filesystem is touched. Use a VM or container.
- **Treating Computer Use as a substitute for missing automation.** It's the bridge; build the automation eventually.
- **Combining Computer Use with high-budget agent loops.** Costs and risk compound; cap iterations aggressively.

## Skills — the system you're inside

A Skill is a `SKILL.md` file with YAML frontmatter (name, description, license, metadata, etc.) + body content + optional `references/` and `assets/` directories. Skills are auto-loaded by description-trigger matching in Claude Code (and increasingly in other harnesses).

### Designing a Skill

- **`name`** — kebab-case identifier; should not collide with other Skills in the user's environment.
- **`description`** — the trigger surface. Write it as comprehensively as possible, listing the keywords and phrases that should activate the Skill. ETYB itself relies on this — sloppy descriptions are the most common Skill failure mode.
- **`license`** — declare it; MIT is common for community Skills.
- **Body** — the actual instructions. Treat it like a system prompt: tight, opinionated, specific.
- **`references/`** — supplementary reading the Skill can load by demand (e.g., per-role overlays in this Stack).
- **`assets/`** — non-instructional files (templates, scripts, data) the Skill references.

### Skill design patterns

- **One Skill, one purpose.** A Skill that "does engineering work" is too broad; a Skill that "reviews Apex code for governor-limit violations" is the right scope.
- **Trigger surface broader than the action surface.** The `description` should list every keyword the user might say; the body should narrow down what the Skill actually does. Over-trigger and under-act, not the reverse.
- **Defer heavy content to references.** A 5,000-line SKILL.md is unwieldy. Put the briefing in SKILL.md; put the deep dives in `references/`.

### Anti-patterns

- **Vague trigger descriptions.** "Use this for engineering work" matches nothing reliably.
- **Trigger descriptions in marketing voice.** "The ultimate AI engineering powerhouse" doesn't help Claude know when to load the Skill.
- **Skills that try to override Claude's safety / system behavior.** Anthropic's safety layers run regardless of Skill content; trying to "jailbreak via Skill" doesn't work and just makes the Skill useless.

## Evals — testing Claude code

TDD on Claude doesn't mean unit-testing the model. It means writing an **eval suite** — a set of input/expected-output pairs (or input/grading-rubric pairs) — and running it against your prompt + tool + model setup.

### Eval frameworks

| Framework | Best for | Notes |
|-----------|----------|-------|
| **`promptfoo`** | YAML-based eval, A/B testing, red-teaming | Most popular for prompt-level testing; OWASP/NIST presets |
| **DeepEval** | pytest-style assertions, RAG-specific metrics | Good if your team is Python-first and uses pytest |
| **Braintrust** | All-in-one with scoring, tracing, datasets, CI gates | Commercial; lowest-friction for production teams |
| **Custom (just the API)** | Bespoke evals tied to your domain | Always an option; don't over-engineer when 50 lines of pytest does the job |

### What to eval

- **Tool-call accuracy** — given a query, does Claude pick the right tool with the right arguments?
- **Output schema compliance** — does the structured output match the schema?
- **Quality on domain tasks** — does the response meet the rubric for your domain?
- **Cost regression** — has the prompt got longer? Are cache hit rates dropping?
- **Latency regression** — has TTFT crept up?

### CI integration

A failing eval should block deploy. Wire `promptfoo eval --output ... --fail-on-error` (or equivalent) into CI; gate prompt changes on a passing run. ETYB's own evals live in `stacks/<vendor>/evals/`; pattern-match that for your project.

### Anti-patterns

- **Manual testing only.** A change that "feels better" silently regresses other cases. You need an eval suite to know.
- **One-shot evals.** Evals must run on every prompt/model change. Make them cheap enough to run continuously.
- **Evals that test the model, not your prompt.** Don't grade Claude vs GPT on your benchmark — that's an academic question. Grade Claude with-your-prompt vs Claude with-the-old-prompt. That's the regression test.

## RAG with Claude — the actually-good pattern

If you're building RAG on Claude in 2026, the recommended pattern is:

1. **Embedding step:** Use any embedding model — Claude doesn't ship one; common pairings are Voyage (formerly Anthropic-recommended; verify current), Cohere embed-v4, OpenAI text-embedding-3-large, or open-source BGE-M3.
2. **Vector store:** Out of scope here; see `ai-ml-engineer` core skill for store selection.
3. **Retrieval:** Hybrid (BM25 + vector) + reranker (Cohere Rerank 3.5 or BGE-Reranker) → top 5-10 chunks.
4. **Generation with Citations:** Pass retrieved chunks as `document` content blocks with `cite_documents: true`. Claude grounds the response in those documents and returns citation spans.
5. **Cache the system prompt + tool definitions:** with retrieved chunks as the variable suffix. The retrieved chunks themselves can be cached (1-hour TTL) if the same chunks come up frequently in a session.
6. **Eval the whole pipeline:** with RAGAS or DeepEval on faithfulness + answer relevance + context precision.

### Claude-specific RAG tips

- **Don't ask Claude to retrieve.** Retrieval is a code problem, not a model problem. Claude is the generator after retrieval.
- **Pass documents as `document` blocks, not as text in the user message.** The Citations API only works with proper `document` blocks.
- **For very long contexts** (entire codebases, large doc corpora): consider the 1M-context Opus variant with prompt caching, instead of RAG with retrieval. Sometimes "just put it all in the context" wins. Measure.

## Cost optimization on Claude — the checklist

In priority order:

1. **Cache.** 90% off cache reads. Restructure prompts to be cacheable. Verify cache hit rate.
2. **Route.** Send simple queries to Haiku; complex to Sonnet; only Opus when needed.
3. **Batch.** 50% off via the Batches API for non-interactive work.
4. **Shorten outputs.** `max_tokens` cap + explicit "respond in N sentences" works. Output tokens are 5x more expensive than input.
5. **Disable thinking when not needed.** Thinking tokens bill at output rate.
6. **Use the Files API.** Re-uploading the same PDF/image base64-inlined into every request is wasteful.
7. **Truncate context.** A 200K prompt costs 100x what a 2K prompt costs. Don't dump irrelevant context "in case Claude needs it."
8. **Vision quality.** Don't send 4K images when 1080p answers the same question.

### Spend monitoring

The Anthropic Admin API exposes per-key, per-workspace usage. Wire it to alerting:

- Daily spend > threshold → page someone.
- Cache hit rate < threshold → investigate (something broke cacheability).
- Token-per-task creep > threshold → prompt grew; re-audit.

## Integration with always-on protocols

- **TDD:** Write an eval before the prompt. Red (failing eval) → green (prompt passes) → refactor (tighten prompt, verify still passes).
- **Verification:** Don't ship a prompt change because "it looks right." Run the eval. Run the actual API call against the prompt. Read the actual output. Verify before claiming.
- **Debugging:** When a prompt misbehaves, start by reproducing on the Workbench with the exact request payload. Don't guess.
- **Plan execution:** Multi-step Claude work (build prompt, build tool, build eval, integrate) is plannable; ETYB's plan-execution-protocol applies.
- **Branch safety:** A prompt change that breaks a downstream eval is a regression. Don't merge.
- **Self-improvement:** Don't change the prompt without a failing eval first. The eval is the test; the prompt is the code.

## Cross-references

- [`backend-architect.md`](backend-architect.md) — SDK integration, streaming, retries, MCP authoring.
- [`system-architect.md`](system-architect.md) — provider routing, when-Claude-vs-alternatives.
- [`security-engineer.md`](security-engineer.md) — prompt injection, AUP, PII handling.
- `skills/etyb/references/specialists/ai-ml-engineer/` — platform-neutral ML/LLM patterns (vector DBs, embedding models, fine-tuning, generic agent frameworks).
- `https://docs.anthropic.com/en/docs/build-with-claude/` — feature-level docs.
- `https://docs.anthropic.com/en/release-notes` — model and feature release log.
- `https://github.com/anthropics/anthropic-cookbook` — pattern examples (note: lags behind release notes; verify against docs before pattern-matching).
