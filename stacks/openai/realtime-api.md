---
title: Realtime API
description: GA 2025 speech-to-speech surface. WebRTC for browser, WebSocket for server. Voice agents with sub-second turn-taking; pricing + audio-token model evolving.
product:
  name: Realtime API
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect, security-engineer]
  authoritative_url: https://platform.openai.com/docs/guides/realtime
  notes: "GA 2025; gpt-realtime + gpt-4o-realtime models; WebRTC + WebSocket transports; audio-token pricing is separate from chat tokens and evolving; tier-gated."
---

## What it is

The Realtime API is OpenAI's speech-to-speech surface — bidirectional audio streaming with sub-second turn-taking. The model accepts audio (and text) as input and emits audio (and text transcripts) as output, with low-latency interruption + barge-in.

Two transports:

- **WebRTC** — browser establishes a peer connection to OpenAI directly using a server-minted ephemeral token. Audio bypasses your server. Lowest latency for in-browser voice.
- **WebSocket** — your server holds the long-lived WS connection to OpenAI. You bridge audio to/from the client however you want (mobile native, telephony, RTP).

Models: `gpt-realtime` (the 2026 default), `gpt-4o-realtime-preview` (original), `gpt-4o-mini-realtime` (cost-sensitive). Plus `gpt-4o-audio-preview` for synchronous audio-aware generation without the Realtime streaming session.

Reference: [Realtime guide](https://platform.openai.com/docs/guides/realtime).

## When to use

**Use Realtime API when:**

- The experience demands sub-second turn-taking — phone IVR, voice agents, live tutoring, voice-first accessibility surfaces.
- Speech is the primary modality (not "transcribe → LLM → TTS" but native audio in / audio out).
- You need barge-in (user interrupts the agent mid-sentence and it stops).

**Don't use Realtime API when:**

- You're doing one-shot transcription → text response → TTS — that's [Whisper](/stacks/openai/whisper/) + [Chat Completions](/stacks/openai/chat-completions/) + [TTS](/stacks/openai/tts/), simpler and cheaper.
- You don't need low latency — async audio works with batch transcription + standard model + TTS.
- The product is text-first and audio is an afterthought.

**Use [Realtime Agents](/stacks/openai/realtime-agents/) when:** the voice flow involves more than one logical agent role (triage → specialist, IVR → human handoff).

**Use `gpt-4o-audio-preview` when:** you want audio-aware response generation but not the streaming Realtime session — lower complexity than the full Realtime API.

## 2025-2026 currency anchors

- **GA 2025.** Realtime is no longer "preview" for the core surface.
- **`gpt-realtime` is the 2026 default.** Better turn-taking and lower latency than `gpt-4o-realtime-preview`. New builds should default to `gpt-realtime`.
- **WebRTC is the production transport for browsers.** Audio goes browser ↔ OpenAI directly using ephemeral tokens.
- **Audio tokens are not chat tokens.** Audio input + output have separate per-minute pricing, separate caching rules, separate context limits. Reading "Realtime is the same price as Chat Completions" is wrong.
- **Cached audio input is supported** but cache hit rates are much lower than text — audio frames vary even for the same speech content.
- **[Realtime Agents](/stacks/openai/realtime-agents/)** wraps the Realtime API with handoffs, tools, transcript primitives. Use it when you have more than one agent role.
- **Tool calls mid-conversation** work — the model emits `response.function_call_arguments.done` events; your code runs the tool; you send `conversation.item.create` with the result; trigger `response.create` to continue.
- **Server-side VAD (voice activity detection)** is the default. Switch to client-side VAD with `input_audio_buffer.commit` for tighter control.
- **Tier-gated.** Tier 1 projects often can't access Realtime — confirm before promising.

## Patterns

### Pattern: browser voice agent (WebRTC)

```
1. Client requests session: POST /api/realtime/session on your server.
2. Server calls OpenAI: POST /v1/realtime/sessions with model + voice + tools.
   Returns client_secret.value — an ephemeral token (~60s TTL).
3. Server returns ephemeral token to client.
4. Client establishes WebRTC peer connection to OpenAI using ephemeral token.
5. Audio + events flow browser ↔ OpenAI directly. Your server is not in the audio path.
```

This is the right architecture for browser-based voice. The real API key never leaves your server.

### Pattern: telephony / mobile voice agent (WebSocket)

```
1. Your server connects: wss://api.openai.com/v1/realtime?model=gpt-realtime
   Authenticate with real API key (server-side).
2. Stream audio frames (PCM16 / G.711 / Opus) to OpenAI; receive audio + text events back.
3. Bridge to client (mobile WebSocket, telephony RTP, etc.).
```

Use WebSocket when the client isn't a modern browser, when you need to inject server-side audio (recordings, hold music), or when you want to record / observe centrally.

### Pattern: mid-call tool calls

Tools are defined in the `session.update` event. Tool call events arrive as `response.function_call_arguments.done`. Run the tool. Send back via `conversation.item.create` with the result. Trigger `response.create` to continue.

**Latency budget for tool calls in Realtime is tight** — the user is mid-conversation. Tools called in Realtime should be **sub-200ms**. Long-running work should hand off to a background job and return `{"status": "queued"}` with the agent acknowledging "I'm working on it, give me a sec."

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Bridging WebSocket on your server to a browser client | Use WebRTC instead — lower latency, audio bypasses your server. |
| Putting the real API key in the browser for Realtime | Server-side ephemeral session token (60s TTL). |
| Synthesizing "Realtime is the same price as Chat Completions" | Audio tokens have separate pricing. Verify on the Realtime pricing page. |
| Running long-blocking tool calls in mid-conversation | Async + acknowledgement. <200ms inline; longer = background. |
| Persisting unredacted audio in logs without consent | Transcripts only; or redact + encrypt audio with retention policy. |
| Aggressive server-side VAD that clips speech | Tune threshold or switch to client-side VAD. |
| Putting Realtime through a Chat-Completions-only gateway | Direct OpenAI for Realtime; gateways don't proxy WebRTC cleanly. |

## Gotchas

- **Audio tokens are separate from chat tokens.** Different pricing, different limits, different caching behavior.
- **Tier-gating** — Realtime requires Tier 1+ access for the model variant. Confirm.
- **WebRTC ephemeral token TTL** is short (~60s). Mint right before connection; don't cache.
- **Mid-stream errors** can cut audio mid-sentence. Plan reconnect.
- **Transcripts are emitted alongside audio** — log the transcript (text) to your tracing layer; audio is optional and subject to retention rules.
- **Server-side VAD threshold** is the most common source of "audio cuts off mid-sentence" complaints. Lower it or move VAD client-side.
- **Tool calls during Realtime stream** require careful coordination — don't block the audio path.
- **Concurrency limits.** Each project has a Realtime concurrency cap. Capacity-plan or hit 429.
- **Voice catalog evolves.** Voice IDs and quality have shifted through 2025-2026. Verify current voice availability.

## Cross-references

### Related products in this Stack

- [Realtime Agents](/stacks/openai/realtime-agents/) — orchestration on top of Realtime.
- [Whisper](/stacks/openai/whisper/) — batch / non-streaming transcription alternative.
- [TTS](/stacks/openai/tts/) — non-streaming TTS for non-Realtime flows.
- [Function calling / tool use](/stacks/openai/function-calling/) — tool definitions in Realtime sessions.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — voice agent design.
- [backend-architect](/stacks/openai/backend-architect/) — WebSocket / WebRTC server pieces.
- [system-architect](/stacks/openai/system-architect/) — Realtime in the topology.
- [security-engineer](/stacks/openai/security-engineer/) — ephemeral tokens, transcript redaction.

### Authoritative sources

- [Realtime API guide](https://platform.openai.com/docs/guides/realtime)
- [Realtime API reference](https://platform.openai.com/docs/api-reference/realtime)
- [OpenAI Pricing](https://openai.com/api/pricing/) — Realtime has its own section
