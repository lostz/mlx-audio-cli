---
name: local-asr-mlx
description: >
  Transcribe audio files to text using the local mlx-audio CLI on Apple Silicon.
  Use this skill whenever the user wants to transcribe audio, do speech-to-text,
  convert audio to transcript, or mentions audio files (.wav, .mp3, .m4a, .flac, etc.).
  Trigger even if the user just drops an audio file path and says "transcribe" or
  "转录" or "转文字" or similar — the skill handles format conversion, model
  download warnings, and token-limit guidance automatically.
---

# Local ASR with mlx-audio

Transcribe audio files to text using the local `mlx-audio-cli` binary powered by MLX on Apple Silicon.

## Binary location

The CLI binary lives next to this SKILL.md:

```
skills/local-asr-mlx/bin/mlx-audio-cli
```

Use an absolute path when calling it. The `mlx.metallib` file must be in the same directory as the binary — it is already bundled there.

## Prerequisites check

Before running transcription, verify:

1. **ffmpeg** — required for any non-WAV file. Check with `which ffmpeg`. If missing, tell the user:
   > ffmpeg is required to convert audio formats. Install it with: `brew install ffmpeg`
   > (Requires Homebrew — https://brew.sh if not installed.)
   Do not proceed until ffmpeg is available.

2. **Input file exists** — confirm the path is valid before doing anything else.

## Known models

| Model ID | Size | Best for |
|---|---|---|
| `mlx-community/Qwen3-ASR-0.6B-4bit` | Small | Fast, everyday use |
| `mlx-community/Qwen3-ASR-0.6B-8bit` | Small | Fast with slightly better quality |
| `mlx-community/Qwen3-ASR-1.7B-bf16` | Large | High accuracy, noisy/technical audio |
| `mlx-community/parakeet-tdt-0.6b-v3` | Small | English-only, very fast |

## Workflow

### Step 0 — Select model

Always run this first to see what's already cached locally:

```bash
<skill-dir>/bin/mlx-audio-cli list
```

Then apply this decision logic:

1. **User specifies a model explicitly** → use it as-is, skip the rest of this logic.

2. **User asks for high quality / accuracy** → prefer the largest cached model from the known list above (currently `Qwen3-ASR-1.7B-bf16`). If it's not cached, ask the user whether to download it (~1.7GB) or fall back to the best available cached model.

3. **User asks for fast / quick** → prefer the smallest cached model (`Qwen3-ASR-0.6B-4bit` or `0.6B-8bit`).

4. **No preference stated** → pick the best cached model that appears in the known list. Prefer a cached model over downloading, so the user doesn't wait unexpectedly.

5. **Nothing cached at all** → download the default model (`mlx-community/Qwen3-ASR-0.6B-4bit`) and warn:
   > **Note:** No local models found. Downloading `Qwen3-ASR-0.6B-4bit` (~500MB) from HuggingFace. This may take a few minutes. Subsequent runs will be much faster.
   Set `timeout_ms = 600000` for this run.

Tell the user which model you're using before starting transcription.

### Step 1 — Convert to WAV if needed

If the input file is not `.wav`, convert it first:

```bash
ffmpeg -i "<input>" -ar 16000 -ac 1 -c:a pcm_s16le "/tmp/<basename>.wav" -y
```

Use 16 kHz mono PCM — this is the optimal format for the ASR models. Keep the temp file in `/tmp/` and clean it up after transcription.

### Step 2 — Run transcription

```bash
<skill-dir>/bin/mlx-audio-cli stt "<wav-file>" \
  [--model <model>] \
  [--language <language>] \
  [--models-dir <models-dir>] \
  [--max-tokens <max-tokens>]
```

**Timeout guidance** — the Bash tool default is 120s which is too short for this use case. Always set an explicit timeout:

- **First run** (model not cached): set `timeout_ms = 600000` (10 minutes) to allow for model download
- **Subsequent runs**: estimate from audio duration — get it with `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "<file>"`, then use `timeout_ms = max(120000, duration_seconds * 15 * 1000)`. For example, a 10-minute audio → ~150s → use 180000ms. A 60-minute audio → use 600000ms.

If the command times out, tell the user the process was still running and suggest re-running with `--max-tokens` reduced or splitting the audio.

**Defaults:**
| Option | Default |
|---|---|
| `--model` | selected via Step 0 logic above |
| `--language` | `English` |
| `--models-dir` | `~/.mlx-audio/models` |
| `--max-tokens` | `81920` |

If the user specifies a language (e.g. "转录成中文", "in Chinese"), pass `--language Chinese` etc.

### Step 3 — Output

By default, print the transcript to the conversation. If the user asks to save to a file, add `-o <path>`.

## Important warnings to surface

### Incomplete transcription / large files
After transcription completes, check whether the output looks truncated (ends abruptly mid-sentence, or the audio is long but the transcript is short). If so, tell the user:
> The transcription may be incomplete. The audio file is long and the default token limit (81920) may have been reached. Try increasing it:
> ```
> --max-tokens 163840
> ```
> or even higher for very long recordings.

As a rough guide: ~1 token ≈ 0.5–1 word; a 30-minute recording at average speaking pace is ~4500 words, well within default limits. Files over ~60 minutes or very dense speech may need a higher limit.

## Cleanup

Remove any temp WAV file created during conversion:
```bash
rm -f "/tmp/<basename>.wav"
```
