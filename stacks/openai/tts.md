---
title: TTS
description: Text-to-speech via tts-1 / tts-1-hd plus gpt-4o-audio-preview voices. Non-streaming TTS; quality + voice catalog expanded through 2025-2026.
product:
  name: TTS
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/text-to-speech
  notes: "tts-1 / tts-1-hd stable; voice catalog expanded; gpt-4o-audio-preview adds higher-quality voices; for streaming voice flows, use Realtime API."
---

## What it is

Endpoint `/v1/audio/speech` generates synthesized speech from text input. Two primary model classes:

- **tts-1** — general-purpose; faster + cheaper.
- **tts-1-hd** — higher quality; slightly higher cost + latency.
- **gpt-4o-audio-preview voices** — newer, higher-quality voices.

Output formats: `mp3`, `opus`, `aac`, `flac`, `wav`, `pcm`. Multiple built-in voices (alloy, echo, fable, onyx, nova, shimmer, etc.).

For **streaming / low-latency voice generation in a live conversation**, use [Realtime API](/stacks/openai/realtime-api/) instead. TTS endpoint is for non-streaming / file-based use cases.

Reference: [Text-to-Speech guide](https://platform.openai.com/docs/guides/text-to-speech).

## When to use

**Use TTS endpoint when:**

- You need a pre-generated audio file (podcast generation, audiobooks, voicemail messages, IVR prompts).
- The output is consumed asynchronously (download → play later, attach to email, etc.).
- You don't need bidirectional voice or sub-second latency.

**Use tts-1-hd when:**

- Quality matters (customer-facing voice, brand presence).

**Use tts-1 when:**

- Cost matters (high-volume notifications, automated voicemail).

**Use [Realtime API](/stacks/openai/realtime-api/) instead when:**

- The voice is in a live conversation with the user.
- Latency matters (sub-second).
- You need barge-in / interruption.

## 2025-2026 currency anchors

- **Voice catalog expanded** 2025-2026. New voices via gpt-4o-audio-preview.
- **tts-1 + tts-1-hd remain available** for non-streaming use cases.
- **Output formats** — multiple codecs; pcm useful for telephony.
- **No streaming** on the TTS endpoint; output is delivered as a complete audio file.
- **Speed parameter** — `speed` (0.25 to 4.0) for playback rate adjustment.

## Patterns

### Pattern: generate audio file

```python
response = client.audio.speech.create(
    model="tts-1-hd",
    voice="nova",
    input="Welcome to our service. How can I help you today?",
)
response.stream_to_file("greeting.mp3")
```

### Pattern: telephony pcm output

```python
response = client.audio.speech.create(
    model="tts-1",
    voice="alloy",
    input=text,
    response_format="pcm",
)
# Send pcm to telephony gateway
```

### Pattern: pre-generate IVR prompts

For IVR systems, pre-generate common prompts (greetings, menu options) once → cache the audio files → serve from your CDN. Don't generate on every call.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Calling TTS on every IVR request | Pre-generate + cache common prompts. |
| Using tts-1-hd for low-stakes notifications | tts-1 is cheaper. |
| Streaming TTS for live conversations | Use [Realtime API](/stacks/openai/realtime-api/). |
| Persisting user-input text used for TTS without retention review | Treat as user content; standard retention applies. |
| Brand voice required + using default voices | OpenAI offers fixed voices; for custom brand voice, consider voice-cloning providers (with consent + licensing). |

## Gotchas

- **No streaming output.** TTS endpoint returns complete audio. For streaming, use Realtime.
- **Voice catalog is fixed.** No custom voice cloning. For brand-custom voices, use specialized providers.
- **Cost differs by model.** Verify on [pricing](https://openai.com/api/pricing/).
- **Output format** — pcm for telephony / low-level audio; mp3/aac/opus for web; flac/wav for quality archival.
- **Speech length limits** — long input may need chunking + concatenation.
- **Content policy** — generated speech goes through OpenAI's policy pipeline.

## Cross-references

### Related products in this Stack

- [Whisper](/stacks/openai/whisper/) — the inverse direction.
- [Realtime API](/stacks/openai/realtime-api/) — speech-to-speech with streaming TTS-quality audio.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — voice + model selection.
- [backend-architect](/stacks/openai/backend-architect/) — audio file delivery + caching.

### Authoritative sources

- [Text-to-Speech guide](https://platform.openai.com/docs/guides/text-to-speech)
- [Audio API reference](https://platform.openai.com/docs/api-reference/audio)
