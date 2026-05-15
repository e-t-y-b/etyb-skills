---
title: Stream
description: Cloudflare's video platform — ingest, transcode, HLS/DASH playback, Live Input for streaming, Stream Connect for restreaming. Per-minute pricing.
product:
  name: Stream
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://developers.cloudflare.com/stream/
  notes: "Video ingest/playback; Live Input + Stream Connect stable; pricing per-minute."
---

## What it is

Stream is Cloudflare's managed video platform — upload, transcode, and serve video on demand or live, with HLS/DASH playback, Live Input for RTMP/SRT ingest, and Stream Connect for restreaming to other platforms (YouTube, Twitch).

Authoritative reference: [developers.cloudflare.com/stream](https://developers.cloudflare.com/stream/).

## When to use

- **Video-on-demand serving** — uploaded video, transcoded, delivered globally.
- **Live streaming** — RTMP/SRT ingest, HLS/DASH playback.
- **Restreaming** to YouTube/Twitch — Stream Connect.
- **You want a managed video pipeline** without spinning up MediaConvert/MediaLive/CloudFront equivalent.

Don't use Stream when:

- **Real-time/low-latency video (WebRTC)** — use [Realtime](/stacks/cloudflare/realtime/).
- **Just want to store video bytes** — use [R2](/stacks/cloudflare/r2/) if you don't need transcode/playback.
- **Image-only** — use [Images](/stacks/cloudflare/images/).

## 2025-2026 currency anchors

- **Live Input and Stream Connect are stable** through 2025-26.
- **Pricing is per-minute** of ingest/playback — model around session length.

## Patterns

### Direct creator upload

```ts
// Generate one-time upload URL for browser direct-upload
const r = await fetch("https://api.cloudflare.com/client/v4/accounts/.../stream/direct_upload", {
  method: "POST",
  headers: { Authorization: `Bearer ${env.CF_API_TOKEN}` },
  body: JSON.stringify({ maxDurationSeconds: 3600 })
});
const { uploadURL } = (await r.json()).result;
return Response.json({ uploadURL });
```

### Live streaming

Create a Live Input via API/dashboard; configure RTMPS/SRT push URLs in OBS/encoder; consumers play via HLS URL.

### Stream Connect — restream to YouTube/Twitch

Configure Stream Connect outputs on a Live Input; Cloudflare handles the relay.

## Anti-patterns

- **Storing raw video in R2 and rolling your own transcode/playback** when Stream is the managed path. Use Stream for "I want a video to be playable" workloads.
- **Using Stream for real-time low-latency video** — that's WebRTC / Realtime territory.

## Gotchas

1. **Per-minute pricing** — long live streams add up; model around session length.
2. **HLS/DASH playback is global edge** — leverage Cloudflare CDN.
3. **Stream content URLs are signed** when access control is needed — use signed URLs.
4. **Restreaming destinations require auth keys** managed in the dashboard.

## Cross-references

- [R2](/stacks/cloudflare/r2/) — for raw video storage without transcode/playback
- [Realtime](/stacks/cloudflare/realtime/) — for real-time WebRTC video
- [Images](/stacks/cloudflare/images/) — for static image delivery
- [Workers](/stacks/cloudflare/workers/) — orchestration via the Stream API
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/stream](https://developers.cloudflare.com/stream/)
