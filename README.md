# mlx-audio-cli

A command-line tool for audio processing on Apple Silicon, powered by [mlx-audio-swift](https://github.com/Blaizzy/mlx-audio-swift).

## Requirements

- macOS 14+
- Apple Silicon (M1+)
- Xcode 15+

## Build

```bash
bash build.sh
```

This compiles the Swift binary and the Metal shader library. Both files are required to run:

```
.build/release/mlx-audio-cli
.build/release/mlx.metallib
```

> **Note:** Keep `mlx.metallib` in the same directory as the binary when distributing.

## Usage

### Speech-to-Text (STT)

```bash
# Basic transcription (outputs to stdout)
mlx-audio stt audio.wav

# Specify language
mlx-audio stt audio.wav --language Chinese

# Specify model
mlx-audio stt audio.wav --model mlx-community/Qwen3-ASR-0.6B-4bit

# Save output to file
mlx-audio stt audio.wav -o transcript.txt

# Custom models cache directory
mlx-audio stt audio.wav --models-dir /path/to/models
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--model` | `mlx-community/Qwen3-ASR-0.6B-4bit` | HuggingFace model ID |
| `--language` | `English` | Language hint for transcription |
| `--models-dir` | `~/.mlx-audio/models` | Local models cache directory |
| `-o, --output` | stdout | Output file path |

## Models

Models are downloaded automatically from HuggingFace on first use and cached locally under `~/.mlx-audio/models`.

| Model | Description |
|-------|-------------|
| `mlx-community/Qwen3-ASR-0.6B-4bit` | Default STT model, fast and lightweight |
| `mlx-community/Qwen3-ASR-1.7B-bf16` | Higher accuracy STT |
| `mlx-community/parakeet-tdt-0.6b-v3` | Parakeet STT |

## License

MIT
