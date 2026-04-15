# ADK Integration — Elevating ETYB To A Live Agent Skill

Antigravity supports two kinds of skills:

1. **Markdown-only skills** — SKILL.md + references. Agent reads instructions, acts. This is ETYB's default form and works on every platform.
2. **ADK-backed skills** — include live agent logic (Python via Google's Agent Development Kit) with tool definitions, sub-agent calls, and multi-turn reasoning. Antigravity boots a lightweight ADK agent process when the skill activates.

Both are valid. ADK is strictly optional and only makes sense when ETYB's coordination patterns benefit from live sub-agent dispatch.

## When To Elevate ETYB To ADK

Good reasons:
- Tier 4 projects with genuine parallel tracks are common in your workflow
- You want sub-agents to access platform-specific tools (Vertex AI endpoints, Google Cloud APIs, bespoke MCP servers)
- You want stateful multi-turn reasoning scoped to a single track without polluting the main conversation
- You want to measure or audit what each track did (ADK agents produce clean trace data)

Bad reasons:
- "ADK sounds cool" — stick with markdown if the pain isn't real
- "I want hooks" — ADK doesn't give you hooks. It gives you sub-agents with tool access.
- Tier 0–2 work — ADK is overhead for simple routing and triage

## What An ADK-Elevated ETYB Looks Like

```
.agent/skills/etyb/
├── SKILL.md                    # unchanged — the portable entry point
├── core/                       # unchanged — portable core
├── adapters/antigravity/       # this adapter
├── references/                 # unchanged
├── adk/                        # new — ADK agent code
│   ├── agent.py                # root ADK agent for ETYB
│   ├── sub_agents/
│   │   ├── backend_track.py    # per-track sub-agent templates
│   │   ├── frontend_track.py
│   │   └── review.py           # independent-review sub-agent
│   └── tools/                  # tool definitions ETYB's sub-agents can use
└── scripts/                    # optional bash helpers
```

The markdown layer is unchanged. The `adk/` directory is additive.

## Wiring Up Parallel Tracks With ADK

ETYB's `core/coordination-patterns.md` → Parallel Tracks pattern maps cleanly to ADK sub-agents:

1. **Design gate** — produced as markdown in the plan artifact (unchanged)
2. **Plan gate** — ETYB writes the track assignments to the plan artifact
3. **Implement gate** — ETYB's ADK root agent dispatches one sub-agent per track:
   - Each sub-agent gets: the track's specialist SKILL.md, the API contract from Design, the acceptance criteria
   - Each runs in its own context with its own tools
   - Each reports back to the ETYB root agent
4. **Verify gate** — ETYB dispatches a fresh `review` sub-agent per track (two-stage review, independent context)
5. **Ship gate** — ETYB root agent synthesizes

The gate rule from `core/gates.md` (Implement blocks until all tracks complete) becomes a natural join point in the ADK agent flow — root agent awaits all sub-agent completions before advancing.

## Tool Integration

ADK lets sub-agents declare their own tool dependencies. This is where MCP integration shines — a sub-agent handling the database track can bind to a Postgres MCP server without ETYB's root agent needing to know about it.

Use `allowed-tools` in SKILL.md frontmatter (per the agentskills.io spec) to pre-approve tools globally, or declare per-sub-agent tools in the ADK agent code.

## Backward Compatibility

An ADK-elevated ETYB still works as a markdown-only skill on:
- Claude Code (ignores `adk/` directory)
- Codex (ignores `adk/` directory)
- Any agentskills.io-compliant agent that doesn't support ADK

The core modules are the source of truth. ADK is an Antigravity-specific execution layer on top.

## What To Do Right Now

For this repo, ADK elevation is a **future enhancement**, not a requirement of Plan 3. This file documents the approach so that when the decision is made to elevate, the design is already clear. Today:

- Ship ETYB as markdown-only across all three platforms
- Let real parallel-track demand drive whether to invest in ADK

If and when ADK elevation happens, it can be a separate plan (Plan 4 or later) with its own branch and its own workstreams.

## References

- Antigravity ADK skills docs: <https://antigravity.google/docs/skills>
- Creating an ADK Agent Skill in Antigravity (Medium, Mar 2026): <https://medium.com/google-cloud/creating-an-adk-agent-skill-in-antigravity-0031f5f82ccb>
- Google ADK tutorials: <https://google.github.io/adk-docs/tutorials/coding-with-ai/>
