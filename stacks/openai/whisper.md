---
title: Whisper
description: Audio-to-text transcription. Stable batch transcription via whisper-1. Competing with gpt-4o-transcribe for streaming workloads.
product:
  name: Whisper
  stack: openai
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/speech-to-text
  notes: "whisper-1 endpoint stable; gpt-4o-transcribe and gpt-4o-mini-transcribe added for streaming/lower-latency use cases."
---

## What it is

The Whisper API (`/v1/audio/transcriptions` with `model: "whisper-1"`) provides batch audio-to-text transcription. Submit an audio file; receive a transcript. Supports many languages, optional translation to English, optional timestamp + word-level granularity.

For **streaming transcription**, newer models exist:

- **gpt-4o-transcribe** — streaming STT; lower latency than Whisper.
- **gpt-4o-mini-transcribe** — cheaper streaming STT.

For **synchronous audio-aware generation** (audio in → text + audio out without the full Realtime session), see `gpt-4o-audio-preview` discussed under [Realtime API](/stacks/openai/realtime-api/).

For **bidirectional speech-to-speech**, see [Realtime API](/stacks/openai/realtime-api/).

Reference: [Speech-to-Text guide](https://platform.openai.com/docs/guides/speech-to-text).

## When to use

**Use whisper-1 when:**

- Workload is batch transcription of audio files (interviews, podcasts, voicemails).
- Latency is not critical (file-based, async processing).
- Cost matters — whisper-1 is the cheapest STT option.

**Use gpt-4o-transcribe / gpt-4o-mini-transcribe when:**

- Workload is streaming (live captions, real-time transcription).
- Lower latency than Whisper is required.
- Quality bar is higher than whisper-1 delivers.

**Use [Realtime API](/stacks/openai/realtime-api/) instead when:**

- The flow is speech-to-speech (not just transcribing — generating responses too).
- Sub-second turn-taking matters.

## 2025-2026 currency anchors

- **whisper-1 is stable.** No major churn.
- **gpt-4o-transcribe + gpt-4o-mini-transcribe** are the newer streaming-friendly alternatives. Higher quality + lower latency than whisper-1 in many cases.
- **Many languages supported.** Translation to English is built-in.
- **Word-level timestamps** are available via `timestamp_granularities=["word"]`.
- **Max file size** ~25 MB; chunk longer audio.

## Patterns

### Pattern: batch transcription

```python
audio = open("interview.mp3", "rb")
transcript = client.audio.transcriptions.create(
    model="whisper-1",
    file=audio,
    response_format="verbose_json",
    timestamp_granularities=["word"],
)
```

### Pattern: streaming transcription via gpt-4o-transcribe

```python
# Use OpenAI's streaming transcribe surface for lower-latency live use cases
# (specific API shape: verify against current SDK / API reference)
```

### Pattern: chunking long audio

For audio >25 MB, split into chunks with overlap, transcribe each chunk, stitch:

```python
chunks = split_audio(long_audio, max_size_mb=24, overlap_seconds=2)
for chunk in chunks:
    transcript = client.audio.transcriptions.create(model="whisper-1", file=chunk)
    # stitch transcripts; use overlap to dedupe
```

### Pattern: transcribe + downstream LLM

```
audio → whisper-1 → transcript → GPT-5 → analysis / extraction
```

For workflows where the audio is just an input to text processing. If the flow is interactive, see [Realtime API](/stacks/openai/realtime-api/) for speech-native.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Using whisper-1 for live captions | Use gpt-4o-transcribe (streaming). |
| Using whisper-1 for full conversation flows | Use [Realtime API](/stacks/openai/realtime-api/) — speech-to-speech. |
| Audio >25 MB single request | Chunk + overlap. |
| Persisting unredacted audio in logs | Treat as PII; transcripts only or redact audio. |
| Skipping language hint when known | Pass `language` for faster + more accurate transcription. |

## Gotchas

- **25 MB file size limit** for whisper-1. Chunk longer audio.
- **Audio formats** — mp3, mp4, mpeg, mpga, m4a, wav, webm. Convert before upload if needed.
- **Word-level timestamps** add latency + cost; only enable if needed.
- **Language detection** is automatic but slower; hint via `language` parameter if known.
- **Translation** is to English only via `/v1/audio/translations`. For other target languages, transcribe + then translate via a chat model.
- **Cost differs** between whisper-1 (cheapest) and gpt-4o-transcribe variants. Verify on [pricing](https://openai.com/api/pricing/).
- **Privacy** — audio is sensitive. Retention policy + ZDR considerations apply.

## Cross-references

### Related products in this Stack

- [TTS](/stacks/openai/tts/) — the inverse direction.
- [Realtime API](/stacks/openai/realtime-api/) — speech-to-speech, includes streaming STT.
- [Files API](/stacks/openai/files-api/) — for batch audio workflows.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — model selection (whisper-1 vs gpt-4o-transcribe).
- [backend-architect](/stacks/openai/backend-architect/) — chunking + streaming plumbing.

### Authoritative sources

- [Speech-to-Text guide](https://platform.openai.com/docs/guides/speech-to-text)
- [Audio API reference](https://platform.openai.com/docs/api-reference/audio)
