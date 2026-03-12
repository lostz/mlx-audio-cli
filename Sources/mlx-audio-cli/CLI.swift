import ArgumentParser
import Foundation

@available(macOS 10.15, *)
@main
struct MLXAudioCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mlx-audio",
        abstract: "Audio processing CLI powered by MLX",
        subcommands: [STTCommand.self, ListCommand.self]
    )
}

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List locally cached models"
    )

    @Option(name: .long, help: "Local models cache directory")
    var modelsDir: String?

    func run() throws {
        let resolvedModelsDir = modelsDir.map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".mlx-audio/models")

        guard FileManager.default.fileExists(atPath: resolvedModelsDir.path) else {
            print("No models cached yet (directory not found: \(resolvedModelsDir.path))")
            return
        }

        let entries = (try? FileManager.default.contentsOfDirectory(atPath: resolvedModelsDir.path)) ?? []
        let models = entries
            .filter { $0.hasPrefix("models--") }
            .map { $0.dropFirst("models--".count).replacingOccurrences(of: "--", with: "/") }
            .sorted()

        if models.isEmpty {
            print("No models cached yet.")
        } else {
            print("Cached models in \(resolvedModelsDir.path):\n")
            for model in models {
                print("  \(model)")
            }
        }
    }
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
