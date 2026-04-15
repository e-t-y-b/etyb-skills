# Live Streaming Architecture — Deep Reference

**Always use `WebSearch` to verify streaming platform features, codec support, and protocol specifications before giving advice. The live streaming space evolves rapidly with new codecs, protocols, and platforms. Last verified: April 2026.**

## Table of Contents
1. [Streaming Protocol Landscape](#1-streaming-protocol-landscape)
2. [Low-Latency Streaming](#2-low-latency-streaming)
3. [WebRTC Architecture](#3-webrtc-architecture)
4. [Media Server Selection](#4-media-server-selection)
5. [Video and Audio Codecs](#5-video-and-audio-codecs)
6. [Transcoding and Adaptive Bitrate](#6-transcoding-and-adaptive-bitrate)
7. [CDN and Edge Delivery](#7-cdn-and-edge-delivery)
8. [Interactive Live Streaming](#8-interactive-live-streaming)
9. [Video Conferencing Architecture](#9-video-conferencing-architecture)
10. [Recording and Live-to-VOD](#10-recording-and-live-to-vod)
11. [Scaling to Millions of Viewers](#11-scaling-to-millions-of-viewers)
12. [Monitoring and Quality of Experience](#12-monitoring-and-quality-of-experience)

---

## 1. Streaming Protocol Landscape

### Ingest Protocols (Streamer → Server)

**RTMP (Real-Time Messaging Protocol)**
- Adobe-developed, TCP-based, the de facto ingest standard
- Every streaming platform (Twitch, YouTube Live, Facebook Live) accepts RTMP ingest
- Latency: 2-5 seconds (ingest only, before transcoding/distribution)
- Codec support: H.264 + AAC (originally Flash-based, limited to these)
- Status: Legacy but ubiquitous for ingest — not dying because OBS, encoders, and all platforms support it
- Limitation: TCP-based (retransmits lost packets, adds latency), no H.265/AV1 support in standard RTMP
- Enhanced RTMP: Extensions adding H.265, AV1, VP9 support — adopted by YouTube, OBS, some platforms

**SRT (Secure Reliable Transport)**
- Haivision-developed, open-source, UDP-based
- Built for unreliable networks: forward error correction (FEC), packet recovery, encryption (AES-128/256)
- Latency: Sub-second over good networks, degrades gracefully on lossy networks
- Codec-agnostic: Carries any codec (H.264, H.265, AV1)
- Adoption: Growing — OBS supports SRT ingest, some platforms accept SRT
- Best for: Remote contribution over public internet, where network quality varies

**WHIP (WebRTC-HTTP Ingest Protocol)**
- IETF standard for using WebRTC as a streaming ingest protocol
- Sub-second ingest latency (WebRTC's low-latency foundation)
- Works from browsers — no software needed for the streamer
- Codec support: VP8, VP9, H.264, AV1 (via WebRTC's codec negotiation)
- Adoption: Cloudflare Stream, Dolby.io, LiveKit, OvenMediaEngine support WHIP
- Best for: Browser-based streaming, ultra-low-latency ingest

### Distribution Protocols (Server → Viewers)

**HLS (HTTP Live Streaming)**
- Apple-developed, HTTP-based, the dominant distribution protocol
- Segments media into small files (.ts or .fmp4), served via regular HTTP/CDN
- Standard HLS latency: 15-30 seconds (segment duration × 3-6 segments in playlist)
- Universal player support (Safari native, all browsers via hls.js)
- Codec support: H.264, H.265, AAC, AC-3 — and increasingly AV1

**LL-HLS (Low-Latency HLS)**
- Apple's low-latency extension to HLS
- Uses partial segments (HTTP chunked transfer) and preload hints
- Latency: 2-4 seconds (vs 15-30 for standard HLS)
- Requires server support for partial segments and blocking playlist reload
- Adoption: Apple's standard, widely supported in 2026
- Best for: Live events where 2-4 seconds is acceptable, maximum compatibility

**DASH (Dynamic Adaptive Streaming over HTTP)**
- MPEG standard, HTTP-based, similar to HLS but with MPEG-DASH manifest format
- LL-DASH: Low-latency variant using CMAF chunked transfer
- Less adoption than HLS in consumer streaming, more in broadcast/enterprise
- Codec-agnostic by design

**CMAF (Common Media Application Format)**
- Unified segment format for both HLS and DASH
- fMP4 (fragmented MP4) segments work with both manifests
- Low-latency: CMAF chunks (sub-segment fragments) enable low-latency delivery
- Best for: Platforms that need to serve both HLS and DASH from the same segments

**WHEP (WebRTC-HTTP Egress Protocol)**
- IETF standard for WebRTC-based stream playback
- Sub-second viewer-side latency (matching WHIP on ingest)
- No buffering, no segments — real-time delivery
- Limitation: Doesn't scale like HLS/CDN (each viewer needs a WebRTC connection or SFU relay)
- Best for: Ultra-low-latency playback for interactive streaming, small-medium audiences

### MoQ (Media over QUIC) — Emerging

- **Status**: IETF draft (draft-ietf-moq-transport-17 as of 2026), expected RFC finalization in 2026
- **Goal**: Solves the streaming trilemma — low latency (like WebRTC) + massive scale (like HLS/CDN) + architectural simplicity (like RTMP)
- **Architecture**: Publisher → MoQ relay network → Subscribers. Relays cache and distribute over QUIC (HTTP/3)
- **Latency**: ~1 second demonstrated at NAB 2026 without complex WebRTC signaling
- **Implementations**: Cloudflare operates the first MoQ relay network across 330+ cities. nanocosmos was first to add MoQ to a commercial platform.
- **Best for**: Watch this space — MoQ may become the convergence protocol replacing RTMP/HLS/WebRTC for many use cases in 2027+

### Protocol Selection Matrix

| Protocol | Direction | Latency | Scalability | Browser Support | Best For |
|----------|-----------|---------|-------------|-----------------|----------|
| RTMP | Ingest | 2-5s | N/A (ingest) | No (software encoder) | Standard ingest |
| SRT | Ingest | <1s | N/A (ingest) | No (software encoder) | Unreliable network ingest |
| WHIP | Ingest | <1s | N/A (ingest) | Yes (WebRTC) | Browser-based ingest |
| HLS | Distribution | 15-30s | Excellent (CDN) | Universal | VOD, non-critical live |
| LL-HLS | Distribution | 2-4s | Excellent (CDN) | Universal | Live events |
| LL-DASH | Distribution | 2-4s | Excellent (CDN) | Most browsers | Live events (non-Apple) |
| WHEP | Distribution | <1s | Medium (SFU) | Yes (WebRTC) | Interactive streaming |
| WebRTC (SFU) | Both | <500ms | Medium | Yes | Conferencing, interactive |
| MoQ | Both | ~1s | Designed for CDN | Emerging | Next-gen unified protocol |

---

## 2. Low-Latency Streaming

### The Latency Spectrum

| Latency | Method | Use Case |
|---------|--------|----------|
| < 200ms | WebRTC (P2P or SFU) | Video calls, screen sharing, interactive gaming |
| 200ms - 1s | WebRTC (SFU), WHIP/WHEP | Auctions, sports betting, interactive streaming |
| 1 - 4s | LL-HLS, LL-DASH, CMAF chunks | Live events, esports, social streaming |
| 4 - 10s | Standard HLS/DASH (short segments) | General live streaming |
| 10 - 30s | Standard HLS/DASH (long segments) | Traditional broadcast, DVR-enabled |

### Where Latency Comes From

```
Capture → Encode → Ingest → Transcode → Package → CDN → Player Buffer → Decode → Display
  ~1ms     20-100ms  50-500ms  100-500ms  50-200ms  50-200ms  500-3000ms   5-20ms    ~1ms
```

**Biggest contributors:**
1. **Encoder buffer**: Hardware encoders add 1-3 frames of latency; software encoders are tunable
2. **Segment duration (HLS/DASH)**: 6-second segments = 6 seconds of inherent delay minimum
3. **Player buffer**: Players buffer 3-6 segments for smooth playback = 18-36 seconds with standard HLS
4. **CDN propagation**: Edge cache miss → origin fetch adds 100-500ms

**How to reduce each:**
1. **Encoding**: Use low-latency presets (x264 `tune=zerolatency`, NVENC low-latency mode)
2. **Segmenting**: Use CMAF chunks (sub-second fragments) instead of full segments
3. **Player buffering**: Use LL-HLS partial segments, reduce buffer depth
4. **CDN**: Use CDNs with origin shield and edge caching for live (Cloudflare Stream, Amazon IVS)

### Amazon IVS (Interactive Video Service)

- **Model**: Managed low-latency streaming — ingest via RTMP/RTMPS, distribute via Amazon IVS Player
- **Latency**: 2-5 seconds (standard), sub-second with IVS Real-Time (WebRTC-based)
- **IVS Real-Time**: WebRTC-based interactive streaming for up to 10,000 viewers at sub-second latency
- **Features**: Timed metadata (sync events to stream), auto-record to S3, chat integration
- **Best for**: Interactive streaming (auctions, gaming, shopping), when you want managed sub-second latency

### Cloudflare Stream

- **Model**: Video platform on Cloudflare's edge network
- **Features**: Live streaming (RTMP/SRT ingest, HLS/DASH delivery), video storage, encoding, analytics
- **Latency**: Standard LL-HLS (2-5s), Cloudflare Calls for WebRTC (sub-second)
- **WHIP/WHEP**: Native support for WebRTC-based ingest and playback
- **Best for**: Cloudflare-native stacks, edge-delivered streaming

### Mux

- **Model**: Video API platform — ingest, encode, deliver, analytics
- **Products**: Mux Video (live + VOD), Mux Data (video analytics), Mux Player
- **Features**: RTMP/SRT ingest, HLS delivery, real-time analytics, automatic quality selection
- **Latency**: Standard (12-15s), Reduced (4-8s), Low-latency (~3s)
- **Best for**: Developer-focused video API, when you want comprehensive video analytics

---

## 3. WebRTC Architecture

### SFU vs MCU vs Mesh

**Mesh (P2P)**
```
  A ←──→ B
  ↑ ╲   ╱ ↑
  │  ╲ ╱  │
  │   ╳   │
  │  ╱ ╲  │
  ↓ ╱   ╲ ↓
  C ←──→ D
```
- Each participant sends to and receives from every other participant
- Upload: N-1 streams, Download: N-1 streams
- Bandwidth: O(N²) total — only practical for 2-4 participants
- No server cost, lowest latency (direct peer-to-peer)
- Best for: 1-on-1 calls, tiny groups

**SFU (Selective Forwarding Unit)**
```
  A ──→ SFU ──→ B
  B ──→ SFU ──→ A
  C ──→ SFU ──→ A, B
  A, B ──→ received from SFU
```
- Each participant sends ONE stream to the SFU
- SFU forwards the stream to all other participants (no transcoding)
- Upload: 1 stream, Download: N-1 streams
- Bandwidth: O(N) total — scales to 50-100+ participants
- Server does minimal processing (forward, not transcode)
- Best for: 4-50 participants, the standard architecture for video conferencing

**MCU (Multipoint Control Unit)**
```
  A ──→ MCU ──→ composite ──→ A
  B ──→ MCU ──→ composite ──→ B
  C ──→ MCU ──→ composite ──→ C
```
- Each participant sends to MCU, MCU mixes all streams into one composite
- Each participant receives ONE mixed stream
- Upload: 1 stream, Download: 1 stream (mixed)
- Server does heavy processing (decode + composite + re-encode for each participant)
- Best for: Very constrained clients (low bandwidth), large meetings where a gallery view is composited server-side
- Rarely used in modern systems (SFU + simulcast is almost always better)

### Simulcast

Send multiple quality versions of your stream; SFU selects which to forward:

```
Camera → Encode at:
  ├─ 1080p @ 2.5 Mbps  (high quality)
  ├─ 720p  @ 1.0 Mbps  (medium quality)
  └─ 360p  @ 0.3 Mbps  (low quality / thumbnail)

SFU receives all three → forwards appropriate quality to each viewer based on:
  - Viewer's available bandwidth
  - Viewer's display size (spotlight = high, thumbnail = low)
  - Network conditions
```

**Benefits:**
- Viewers with good bandwidth see 1080p; viewers with bad bandwidth see 360p
- Active speaker gets forwarded at high quality; thumbnails at low quality
- No server-side transcoding needed (SFU just forwards selected layer)

### SVC (Scalable Video Coding)

An alternative to simulcast — encode ONE stream with multiple quality layers:

```
Base layer:  360p  (always decodable)
  + Layer 1: 720p  (base + layer 1 = 720p)
  + Layer 2: 1080p (base + layer 1 + layer 2 = 1080p)
```

- SFU can drop higher layers for bandwidth-constrained viewers
- More bandwidth-efficient than simulcast (shared base layer)
- Codec support: VP9 SVC, AV1 SVC, H.264 SVC (limited)
- Growing adoption via WebRTC with VP9/AV1

### TURN Servers

When P2P connection fails (symmetric NAT, strict firewalls), TURN relays traffic:

```
Client A ──→ TURN Server ──→ Client B
```

- All traffic flows through TURN server (higher latency, server bandwidth cost)
- Needed for ~10-20% of WebRTC connections (depending on network environment)
- TURN servers: coturn (open-source), Twilio TURN, Xirsys, Cloudflare TURN
- Cost: TURN bandwidth is expensive — bill per GB transferred

---

## 4. Media Server Selection

### LiveKit

- **Language**: Go (server), SDKs in JavaScript, Swift, Kotlin, Flutter, Rust, Python, Unity
- **Architecture**: SFU with built-in signaling, room management, and WebRTC
- **Features**: Video/audio rooms, screen sharing, simulcast, recording, egress (RTMP/HLS/file), ingress (RTMP/WHIP), data channels, AI integration (real-time voice pipelines)
- **Scaling**: Distributed — multiple nodes with Redis-based coordination
- **Differentiator**: Fastest-growing open-source media server (2026), strong AI/voice integration (LiveKit Agents for real-time AI voice), comprehensive SDK ecosystem
- **Cloud**: LiveKit Cloud (managed hosting)
- **Best for**: Video conferencing, live streaming, real-time AI voice, when you want a modern, well-maintained SFU

### MediaSoup

- **Language**: C++ (core) + Node.js (API layer)
- **Architecture**: SFU library — not a standalone server, you build the signaling on top
- **Features**: WebRTC SFU, simulcast, SVC, data channels, flexible room/routing logic
- **Performance**: Extremely efficient C++ media processing
- **Differentiator**: Most flexible SFU — you control signaling, room logic, everything. MediaSoup handles only the media routing.
- **Limitation**: You must build signaling, room management, recording yourself
- **Best for**: Custom media applications where you need maximum control, large-scale platforms that need to customize everything

### Janus

- **Language**: C
- **Architecture**: General-purpose WebRTC gateway with plugin system
- **Plugins**: Videoroom (SFU), Streaming (live), SIP gateway, record/play, text room, screen sharing
- **Features**: Plugin-based architecture — extend with custom plugins
- **Differentiator**: Gateway concept — connect WebRTC to other protocols (SIP, RTSP, RTP)
- **Best for**: Bridging WebRTC with legacy telephony (SIP), custom protocol gateways

### Pion (Go)

- **Language**: Go
- **Model**: Low-level WebRTC library (not a server framework)
- **Features**: Full WebRTC stack in Go — ICE, DTLS, SRTP, data channels
- **Differentiator**: Build anything WebRTC-related in Go from the ground up
- **Best for**: Custom WebRTC applications in Go, when existing SFU frameworks are too opinionated

### Jitsi Meet

- **Language**: Java (Jitsi Videobridge SFU) + JavaScript (web client)
- **Architecture**: Full video conferencing platform (not just SFU) — Jitsi Meet (UI) + Jitsi Videobridge (SFU) + Oasis (SRTP)
- **Features**: Complete conferencing solution — rooms, screen sharing, chat, recording, live streaming, breakout rooms
- **Differentiator**: Full-featured open-source Zoom alternative, ready to deploy
- **Limitation**: Heavier than a pure SFU — includes the full UI/UX
- **Best for**: Self-hosted video conferencing, white-label meeting solution

### OvenMediaEngine (OME)

- **Language**: C++
- **Architecture**: Full-featured streaming server — ingest, transcode, distribute
- **Ingest**: RTMP, SRT, WHIP, MPEG-TS
- **Output**: WebRTC (WHEP), HLS, LL-HLS, DASH, LL-DASH
- **Features**: Transcoding, ABR, recording, clustering, GPU encoding support
- **Differentiator**: One server handles ingest → transcode → distribute across all protocols
- **Best for**: Self-hosted live streaming platform, when you need a complete streaming server

### Media Server Selection Matrix

| Factor | LiveKit | MediaSoup | Janus | Pion | Jitsi | OME |
|--------|---------|-----------|-------|------|-------|-----|
| Use case | Conferencing + streaming | Custom SFU | Protocol gateway | Custom WebRTC | Conferencing | Live streaming |
| Ready to deploy | Yes | Library only | Plugin-based | Library only | Yes | Yes |
| Signaling included | Yes | No | Yes | No | Yes | Yes |
| Recording | Built-in | Build your own | Plugin | Build your own | Built-in | Built-in |
| AI integration | LiveKit Agents | Build your own | No | Build your own | No | No |
| Cloud option | LiveKit Cloud | No | No | No | 8x8 JaaS | No |
| Flexibility | Medium | Highest | High | Highest | Lower | Medium |
| Best for | Modern default | Custom platforms | SIP bridging | Go custom | Self-host Zoom | Self-host streaming |

---

## 5. Video and Audio Codecs

### Video Codecs

**H.264 (AVC)**
- The universal video codec — supported everywhere (all browsers, all devices, all hardware)
- Encoding: Hardware encoders on every GPU and mobile SoC
- Quality: Good, but not as efficient as newer codecs
- Licensing: Patent pool (MPEG LA), but free for internet streaming
- Use when: Maximum compatibility is required

**H.265 (HEVC)**
- 30-50% better compression than H.264 at same quality
- Hardware encoding on modern GPUs and Apple Silicon
- Browser support: Safari (native), Chrome/Firefox (partial — depends on OS decoder)
- Licensing: Complex patent landscape (multiple patent pools)
- Use when: iOS/Apple ecosystem, premium content, bandwidth-constrained delivery

**AV1**
- 30-50% better compression than H.264, royalty-free
- Encoding: Hardware encoding on newer GPUs (Intel Arc, NVIDIA RTX 40+, AMD RDNA3+)
- Browser support: Chrome, Firefox, Edge, Safari (growing)
- Decoding: Hardware decoding on modern devices, software decoding on older
- Limitation: Encoding is CPU-intensive without hardware support
- Use when: Royalty-free priority, modern audience, bandwidth savings justify encode cost

**VP9**
- Google's royalty-free codec, predecessor to AV1
- 30-40% better than H.264
- Universal browser support (Chrome, Firefox, Edge, Safari)
- Used by: YouTube (primary codec), Google Meet
- Use when: Good balance of quality, compatibility, and royalty-free

### Audio Codecs

**Opus**
- The universal audio codec for real-time — low latency, excellent quality, royalty-free
- Bitrate: 6 kbps (voice) to 510 kbps (high-quality music)
- Latency: 2.5ms minimum algorithmic delay
- Used by: WebRTC (mandatory), Discord, WhatsApp calls
- Best for: All real-time audio (voice, music, streaming)

**AAC (Advanced Audio Coding)**
- Standard for HLS/streaming, wide hardware decoder support
- Higher latency than Opus
- Used by: HLS streams, podcast distribution, Apple ecosystem
- Best for: HLS/DASH distribution, when hardware decode is important

---

## 6. Transcoding and Adaptive Bitrate

### ABR Ladder Design

Adaptive bitrate streaming serves multiple quality levels; the player switches based on bandwidth:

**Standard ABR ladder for live streaming:**

| Rendition | Resolution | Bitrate (H.264) | Bitrate (AV1) | FPS |
|-----------|-----------|-----------------|---------------|-----|
| 1080p60 | 1920×1080 | 6,000 kbps | 3,500 kbps | 60 |
| 1080p | 1920×1080 | 4,500 kbps | 2,500 kbps | 30 |
| 720p | 1280×720 | 2,500 kbps | 1,500 kbps | 30 |
| 480p | 854×480 | 1,200 kbps | 700 kbps | 30 |
| 360p | 640×360 | 600 kbps | 350 kbps | 30 |
| 240p | 426×240 | 300 kbps | 180 kbps | 30 |
| Audio-only | — | 128 kbps (AAC) | 128 kbps (Opus) | — |

### Per-Title Encoding

Netflix pioneered per-title encoding — optimizing the ABR ladder per content:

- Animation (simple scenes) → lower bitrates achieve same quality
- Action movies (complex motion) → need higher bitrates
- Analyze content complexity → generate optimal quality ladder
- VMAF (Video Multimethod Assessment Fusion) score targeting: encode to VMAF 93+ at each rung
- Not practical for live (requires multi-pass encoding) but used for live-to-VOD

### Hardware vs Software Encoding

**Software (CPU-based):**
- FFmpeg + x264 (H.264), x265 (HEVC), SVT-AV1 (AV1), libvpx (VP9)
- Highest quality at any bitrate (more time = better compression)
- Best for: VOD encoding, when quality matters most
- Cost: CPU-intensive, 1-4 real-time encoding per CPU core at 1080p

**Hardware (GPU-based):**
- NVIDIA NVENC, AMD AMF/VCE, Intel QSV, Apple VideoToolbox
- Lower quality than software at same bitrate, but dramatically faster
- Best for: Live encoding (must be real-time), high-volume transcoding
- One GPU can encode 10-30+ simultaneous 1080p streams
- Cost: GPU hardware cost, but much lower CPU usage

### Transcoding Architecture

```
Ingest (RTMP/SRT) → Transcoder → Packager → CDN → Player
                       │             │
                 ┌─────┴─────┐   ┌──┴──┐
                 │ 1080p60   │   │ HLS  │
                 │ 720p      │   │ DASH │
                 │ 480p      │   │ CMAF │
                 │ 360p      │   └─────┘
                 │ Audio     │
                 └───────────┘
```

For self-hosted: FFmpeg is the Swiss Army knife — handles ingest, transcode, and packaging.

---

## 7. CDN and Edge Delivery

### How Live CDN Works

```
Origin Server → Edge PoP 1 → Viewer 1
              → Edge PoP 2 → Viewer 2, 3, 4
              → Edge PoP 3 → Viewer 5, 6
```

1. Origin produces HLS segments / CMAF chunks
2. Viewer requests from nearest edge PoP
3. Edge cache miss → pull from origin (or origin shield)
4. Edge cache hit → serve directly (most requests after first viewer)
5. Segments expire after TTL (segment duration)

### Multi-Region Ingest

For global streaming, ingest at the point closest to the streamer:

```
Streamer (Asia) → Ingest PoP (Tokyo) → Origin (US-West) → CDN Edge (global)
```

- RTMP/SRT to nearest ingest point
- Internal relay to transcoding origin
- CDN serves from edge PoPs worldwide

### CDN Selection for Streaming

| Feature | Cloudflare Stream | AWS CloudFront + MediaLive | Mux | Akamai |
|---------|-------------------|---------------------------|-----|--------|
| Managed transcoding | Yes | MediaLive | Yes | Yes |
| Low-latency | LL-HLS, WHEP (Calls) | MediaLive LL-HLS | LL-HLS | LLDS |
| WebRTC delivery | Cloudflare Calls | Amazon IVS Real-Time | No | No |
| Edge PoPs | 300+ | 600+ | Via CDN partner | 4,000+ |
| Recording/VOD | Yes | MediaLive → S3 | Yes | Via Media Services |
| Analytics | Basic | CloudWatch | Mux Data (detailed) | Media Analytics |
| Best for | Cloudflare stack | AWS stack | Developer-first API | Enterprise/broadcast |

---

## 8. Interactive Live Streaming

### Live Chat Overlay

Architecture for chat alongside a live stream:

```
Viewer → Chat Server (WebSocket) → Chat Storage → Other Viewers
                                                → Chat Overlay Renderer
                                                → Streamer's OBS overlay
```

- Chat runs on separate WebSocket infrastructure (not the video pipeline)
- Chat latency should be lower than video latency (messages arrive before the visual context)
- Rate limiting: Slow mode (1 message per N seconds), subscriber-only mode
- Moderation: AutoMod (ML-based), banned words, moderator tools

### Live Polls and Reactions

```
Viewer taps "reaction" → WebSocket → Server aggregates → 
  Broadcast aggregated reaction count every 500ms →
    Render animated reaction burst on all viewers
```

- Don't broadcast individual reactions at scale (100K viewers × reactions = millions of messages)
- Aggregate on server: Count reactions in 500ms windows, broadcast summary
- Client renders animation from summary (e.g., "42 heart reactions in last 500ms" → render 42 floating hearts)

### Timed Metadata

Sync events to the video stream timeline:

```
Streamer triggers poll → Timed metadata event injected into stream →
  CDN distributes event with video → Player fires callback at correct video timestamp →
    UI shows poll synchronized with video content
```

- HLS: `#EXT-X-DATERANGE` tag in playlist, or ID3 tags in segments
- Amazon IVS: `PutMetadata` API injects metadata into stream
- Use for: Polls, product cards (live shopping), trivia questions, stats overlays

---

## 9. Video Conferencing Architecture

### Small Group (2-8 participants)

```
Participants ←WebRTC→ SFU ←→ Signaling Server
```

- SFU forwards all streams to all participants
- Each participant sends 1 stream (or simulcast 2-3 layers)
- Each participant receives N-1 streams
- Bandwidth per participant: ~2-4 Mbps upload, ~4-8 Mbps download
- Latency: <200ms end-to-end

### Large Meeting (8-50 participants)

```
Participants ←WebRTC→ SFU
                       │
  Active speaker detection → Forward HD for speaker
  Thumbnail quality for others → Forward low-res for gallery
  Screen sharing → Separate high-res stream
```

- SFU intelligently selects which quality layer to forward
- Active speaker: HD (1080p or 720p)
- Gallery view: Low quality (180p-360p thumbnails)
- Screen share: Separate stream with higher resolution, lower framerate
- Bandwidth per participant: ~1-2 Mbps upload, ~3-6 Mbps download

### Webinar (1-few speakers, many viewers)

```
Speakers ←WebRTC→ SFU → WebRTC/HLS/LL-HLS → Viewers (hundreds/thousands)
```

- Speakers: Full WebRTC (bidirectional, interactive)
- Small audience (<500): WebRTC via SFU
- Large audience (500+): Transcode from SFU to HLS/LL-HLS for CDN delivery
- Hybrid: Interactive viewers (raised hand, Q&A) on WebRTC, passive viewers on HLS
- Hand-raise/Q&A: Promote viewer to WebRTC speaker temporarily

### Breakout Rooms

- Create sub-rooms dynamically during a meeting
- Participants moved between rooms (SFU manages room membership)
- Main room persists — moderator can broadcast to all breakout rooms
- Re-join main room: Participants rejoin the main SFU room

---

## 10. Recording and Live-to-VOD

### Recording Architecture

```
Live Stream → Recording Pipeline → Storage → Processing → VOD CDN
                    │                  │          │
              Demux + store       S3/GCS/R2    Transcode to
              raw segments        Blob Store   ABR ladder for VOD
```

**Recording approaches:**
1. **Server-side composite**: Record the mixed/composited output (what viewers see). Simplest.
2. **Individual track recording**: Record each participant's audio/video separately. Enables post-production editing.
3. **Segment capture**: For HLS/DASH, simply save segments as they're produced. Cheapest.

### Live-to-VOD Pipeline

1. During live: HLS segments served from edge, simultaneously written to storage
2. Stream ends: Generate a VOD manifest pointing to all segments
3. Post-processing: Re-transcode at higher quality (multi-pass), generate thumbnails, index for search
4. DVR window: Keep the last N hours accessible as time-shifted HLS (viewer can "rewind" the live stream)

### DVR Functionality

Allow viewers to pause/rewind during live:
- Sliding window: Keep last 2-4 hours of segments available
- Player: Seek within available window, "Go Live" button to jump to live edge
- Storage: Ring buffer of segments (expire oldest as new arrive)
- Manifest: Extended playlist with `#EXT-X-PROGRAM-DATE-TIME` for absolute timestamps

---

## 11. Scaling to Millions of Viewers

### The Scaling Challenge

1 million concurrent viewers watching 1080p at 4.5 Mbps = 4.5 Tbps total bandwidth.

No single server or data center can handle this. CDNs are essential.

### Architecture for Millions

```
Origin (1 server) → CDN Edge PoPs (hundreds of PoPs worldwide)
                          │
                    Cache segments at edge
                          │
                    Serve millions of viewers from edge
```

**Key insight**: The origin produces segments ONCE. CDN edge caches serve those segments to millions. The origin load is constant regardless of viewer count (one set of segments, pulled by edge PoPs).

**Origin scaling:**
- Origin capacity: Needs to handle edge PoP pull requests (hundreds, not millions)
- Origin shield: An intermediate CDN tier that aggregates edge requests (100 edges → 1 origin shield → 1 origin)
- Multi-origin: Active-active origins for redundancy

**CDN edge scaling:**
- Each edge PoP serves its local viewers from cache
- Cache hit ratio for live: Very high (segments change every 2-6 seconds, many viewers request same segment)
- Bandwidth: CDN handles the Tbps — that's what CDNs are built for

### Thundering Herd Problem

When a new live segment becomes available, thousands of viewers request it simultaneously:

- **Origin shield**: Aggregates requests — only one request reaches origin, response fans out to edge PoPs
- **Stale-while-revalidate**: Serve slightly stale segment while fetching new one
- **Predictive pre-push**: Origin pushes new segments to edge PoPs before they're requested

---

## 12. Monitoring and Quality of Experience

### Key Metrics

**Stream health (server-side):**
- Ingest bitrate stability
- Dropped frames during transcoding
- Segment generation latency (time to produce each HLS segment)
- Origin-to-edge propagation time

**Quality of Experience (client-side):**
- **Startup time (TTFF — Time to First Frame)**: How long from play click to first video frame
- **Buffering ratio**: Percentage of playback time spent buffering
- **Rebuffering events**: Number of buffer underruns per hour
- **Bitrate adaptation**: How often and how dramatically does quality switch
- **Latency (live)**: Delay between real-world event and viewer seeing it
- **Video quality (VMAF/SSIM)**: Objective perceptual quality score

**Target QoE benchmarks:**

| Metric | Good | Acceptable | Poor |
|--------|------|------------|------|
| Startup time | <2s | 2-5s | >5s |
| Buffering ratio | <0.5% | 0.5-2% | >2% |
| Rebuffer events | <0.5/hr | 0.5-2/hr | >2/hr |
| Live latency (LL-HLS) | <3s | 3-5s | >5s |
| Live latency (WebRTC) | <500ms | 500ms-1s | >1s |

### Mux Data

The most comprehensive video analytics platform:
- Player-side SDK (video.js, hls.js, native players) collects QoE metrics
- Dashboard: Startup time, rebuffer frequency, playback failure rate, video quality, engagement
- Real-time alerting on quality degradation
- Per-viewer drill-down for debugging
- Best for: When you need serious video analytics beyond basic CDN metrics
