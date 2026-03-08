import Foundation
import HuggingFace
import MLXAudioCore
import MLXAudioSTT

struct Transcriber {
    let modelsDir: URL

    init(modelsDir: URL) {
        self.modelsDir = modelsDir
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
    }

    func transcribe(audioURL: URL, modelID: String, language: String) async throws -> String {
        fputs("Loading model: \(modelID)\n", stderr)

        let cache = HubCache(cacheDirectory: modelsDir)
        let model = try await Qwen3ASRModel.fromPretrained(modelID, cache: cache)

        fputs("Transcribing \(audioURL.lastPathComponent)...\n", stderr)
        let (_, audioData) = try loadAudioArray(from: audioURL)

        let params = STTGenerateParameters(language: language)
        let output = model.generate(audio: audioData, generationParameters: params)
        return output.text
    }
}
