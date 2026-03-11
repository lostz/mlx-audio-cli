import ArgumentParser
import Foundation

@available(macOS 10.15, *)
@main
struct MLXAudioCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mlx-audio",
        abstract: "Audio processing CLI powered by MLX",
        subcommands: [STTCommand.self]
    )
}

struct STTCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stt",
        abstract: "Transcribe audio file to text"
    )

    @Argument(help: "Path to the audio file")
    var audioFile: String

    @Option(name: .long, help: "HuggingFace model ID")
    var model: String = "mlx-community/Qwen3-ASR-0.6B-4bit"

    @Option(name: .long, help: "Language hint for transcription")
    var language: String = "English"

    @Option(name: .long, help: "Local models cache directory")
    var modelsDir: String?

    @Option(name: .long, help: "Maximum number of tokens to generate")
    var maxTokens: Int = 81920

    @Option(name: [.short, .long], help: "Output file path (default: stdout)")
    var output: String?

    func run() async throws {
        let audioURL = URL(fileURLWithPath: audioFile)
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw ValidationError("Audio file not found: \(audioFile)")
        }

        let resolvedModelsDir = modelsDir.map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".mlx-audio/models")

        let transcriber = Transcriber(modelsDir: resolvedModelsDir)
        let text = try await transcriber.transcribe(
            audioURL: audioURL,
            modelID: model,
            language: language,
            maxTokens: maxTokens
        )

        if let outputPath = output {
            try text.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            fputs("Saved to \(outputPath)\n", stderr)
        } else {
            print(text)
        }
    }
}
