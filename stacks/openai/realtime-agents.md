---
title: Realtime Agents
description: Voice agent orchestration on top of the Realtime API. Handoffs, function tools, transcript + turn tracking, moderation guardrails — for voice flows with more than one agent role.
product:
  name: Realtime Agents
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://github.com/openai/openai-agents-python
  notes: "Voice-agent layer on Realtime; experimental → production maturity through 2025-2026. Track Agents SDK changelog."
---

## What it is

Realtime Agents is the voice-side companion to the [Agents SDK](/stacks/openai/agents-sdk/) — orchestration primitives layered on the [Realtime API](/stacks/openai/realtime-api/). It gives you:

- **Handoffs** between agents during a live voice call (e.g., triage agent → billing specialist).
- **Function tools** invoked mid-call.
- **Transcript + turn tracking** for forensics and audit.
- **Moderation guardrails** running alongside the live stream.

Use Realtime Agents when the voice flow has **more than one logical agent role**. For a single-agent voice loop, raw [Realtime API](/stacks/openai/realtime-api/) is enough.

## When to use

**Use Realtime Agents when:**

- The call flow involves handoff — triage → specialist, IVR → human.
- You want function tools mid-call with the Agents SDK ergonomics (`@function_tool` decorator + guardrails).
- You need consolidated transcript + turn telemetry for the entire multi-agent flow.
- You want moderation rails running against the live audio stream.

**Use raw [Realtime API](/stacks/openai/realtime-api/) when:**

- The voice loop is single-agent.
- You're integrating with non-Agents-SDK orchestration (custom state machine, LangGraph).

**Use [Agents SDK](/stacks/openai/agents-sdk/) (text) when:** the multi-agent flow doesn't need voice; text handoffs are simpler and cheaper.

## 2025-2026 currency anchors

- **Maturity ramped 2025-2026** — experimental in early 2025, production-grade by late 2025 / early 2026.
- **Tied to the [Agents SDK](/stacks/openai/agents-sdk/) Python + TypeScript libraries.** Versioning tracks the SDK.
- **Built-in tracing** surfaces in OpenAI Platform Logs by default; can also be wired to OpenTelemetry.
- **Moderation guardrails** run on transcripts; configurable per-agent.
- **Audio + transcripts are emitted in parallel.** Always log the transcript; treat audio as optional + retention-controlled.

## Patterns

### Pattern: triage handoff flow

```
TriageAgent (greeting, intent detection)
   ↓ handoff (if intent == "billing")
BillingAgent (account lookup, charge dispute resolution)
   ↓ handoff (if escalation needed)
HumanAgent (queued via your CRM, ringing the human's softphone)
```

Each agent has its own system prompt + tool set + moderation rails. Handoff is explicit and traced.

### Pattern: mid-call tool with acknowledgment

```python
@function_tool
async def lookup_order(order_id: str) -> dict:
    # If lookup takes >200ms, queue + return acknowledgment
    if estimated_duration > 200:
        job_id = await queue_lookup(order_id)
        return {"status": "queued", "job_id": job_id}
    return await lookup_order_sync(order_id)
```

Voice flows can't block — long tools must hand off async and the agent acknowledges in real time.

### Pattern: guarded transcript moderation

Configure a [Moderation](/stacks/openai/moderation-api/) guardrail at the input boundary of the Realtime Agent. The guardrail runs on the audio transcript per turn; if flagged, the agent intervenes or escalates.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Multi-agent voice flow built on raw Realtime API with custom state machine | Use Realtime Agents — handoff + tracing are first-class. |
| Single-agent voice flow built on Realtime Agents | Overkill. Use raw [Realtime API](/stacks/openai/realtime-api/). |
| Mid-call tools that block for seconds | Async + acknowledgment; don't stall the voice channel. |
| No transcript logging | Always log transcripts; that's your forensic trail. |
| Sharing audio across user sessions | Per-session isolation. Voice agents must be tenant + session-scoped. |
| Building handoff logic outside the SDK's primitives | Use Agents SDK handoffs; tracing won't capture custom flows cleanly. |

## Gotchas

- **Latency budget is brutal.** Each handoff has a per-second perception cost. Optimize handoff timing; pre-warm the destination agent if possible.
- **Tool latency** of >200ms is noticeable in voice. Async acknowledgment is mandatory for anything slower.
- **Transcripts lag audio** by ms-to-seconds. Don't gate audio playback on transcript completeness.
- **Tier-gating** inherits from [Realtime API](/stacks/openai/realtime-api/) — confirm before deploy.
- **Cost composes** — you're paying Realtime audio tokens + Agents SDK tracing overhead + tool execution. Budget per-call.
- **PII in transcripts.** Treat as sensitive — redact for logging where appropriate.

## Cross-references

### Related products in this Stack

- [Realtime API](/stacks/openai/realtime-api/) — the underlying surface.
- [Agents SDK](/stacks/openai/agents-sdk/) — text-side orchestration; same patterns.
- [Function calling / tool use](/stacks/openai/function-calling/) — tool definitions for voice.
- [Moderation API](/stacks/openai/moderation-api/) — guardrail content.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — multi-agent voice design.
- [backend-architect](/stacks/openai/backend-architect/) — server pieces, async tool handling.
- [security-engineer](/stacks/openai/security-engineer/) — voice-side prompt-injection, transcript redaction.

### Authoritative sources

- [Agents SDK GitHub (Python)](https://github.com/openai/openai-agents-python)
- [Realtime API guide](https://platform.openai.com/docs/guides/realtime)
- [OpenAI Cookbook (Realtime examples)](https://cookbook.openai.com/)
