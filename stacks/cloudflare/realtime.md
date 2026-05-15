---
title: Realtime
description: Cloudflare's WebRTC infrastructure — TURN + SFU + Realtime API for real-time audio, video, and data. GA 2025, replacing the older "Cloudflare Calls" naming.
product:
  name: Realtime
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, ai-ml-engineer]
  authoritative_url: https://developers.cloudflare.com/realtime/
  notes: "Cloudflare Realtime (TURN + SFU + Realtime API) GA 2025; replaces the older Calls naming."
---

## What it is

Cloudflare Realtime is the managed WebRTC stack — TURN servers (NAT traversal), SFU (Selective Forwarding Unit for many-to-many audio/video), and the Realtime API for programmatic session control. Real-time audio/video apps on Workers without managing your own SFU.

Authoritative reference: [developers.cloudflare.com/realtime](https://developers.cloudflare.com/realtime/).

## When to use

- **Real-time audio/video** — calls, conferencing, live streaming with low latency.
- **Voice agents** — pair with [Workers AI](/stacks/cloudflare/workers-ai/) Whisper + LLM + external TTS for end-to-end voice AI.
- **Many-to-many sessions** — Realtime SFU handles fan-out cheaply.
- **Replacing external SFU services** (LiveKit, Daily, Twilio) when Cloudflare-native fits.

Don't use Realtime when:

- **Plain WebSocket fanout** — [Durable Objects](/stacks/cloudflare/durable-objects/) with WebSockets + Hibernation handle that for free.
- **Pre-recorded video playback** — use [Stream](/stacks/cloudflare/stream/) instead.
- **One-to-one only with no fan-out** — direct WebRTC may be simpler.

## 2025-2026 currency anchors

- **GA in 2025.** Replaced the "Cloudflare Calls" naming.
- **TURN + SFU + Realtime API** is the canonical surface as of 2026-Q2.
- **Pair with [Durable Objects](/stacks/cloudflare/durable-objects/)** for signaling/session state — DO holds room state, Realtime handles the media.

## Patterns

### Real-time voice agent

```
[Browser/App]
   ↓ (WebRTC audio)
[Cloudflare Realtime: TURN + SFU]
   ↓ (audio samples)
[Worker: voice-agent]
   ├── Workers AI Whisper (STT)
   ├── DO: ConversationState
   ├── AI Gateway → LLM (streaming)
   └── External TTS (ElevenLabs / OpenAI) via AI Gateway
   ↓ (audio back through SFU)
[Browser/App]
```

DO holds conversation history + barge-in state. LLM streams tokens; TTS pipelines them. Total target latency from user-stop-talking → user-hears-response: 500-800ms.

### Signaling via DO

```ts
const signalRoom = env.SIGNAL_ROOM.get(env.SIGNAL_ROOM.idFromName(`room-${roomId}`));
const ws = await signalRoom.fetch(req);   // upgrades to WebSocket inside the DO
```

DO is the signaling primitive — holds room state, broadcasts offers/answers/ICE candidates. Realtime handles the actual media.

## Anti-patterns

- **Calling it "Cloudflare Calls" in new docs** — the canonical name is Realtime.
- **DIY SFU on Workers** — Workers can't run a custom SFU efficiently. Use Realtime.
- **Putting media bytes through a Worker** — Worker proxies the signaling, not the media. The SFU is the data plane.

## Gotchas

1. **Realtime API is newer surface area** — verify bindings and config syntax against current docs.
2. **TURN credentials need rotation** — manage as secrets.
3. **Latency depends on SFU placement** — verify against current docs for cross-region scenarios.
4. **Browser WebRTC support matters** — Realtime is a server; the client still uses standard WebRTC APIs.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — signaling and orchestration runtime
- [Durable Objects](/stacks/cloudflare/durable-objects/) — signaling state + Hibernation for many idle WebSockets
- [Workers AI](/stacks/cloudflare/workers-ai/) — Whisper for STT in voice agents
- [AI Gateway](/stacks/cloudflare/ai-gateway/) — LLM and TTS calls in voice agents
- [Stream](/stacks/cloudflare/stream/) — for pre-recorded video, not real-time
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/realtime](https://developers.cloudflare.com/realtime/)
