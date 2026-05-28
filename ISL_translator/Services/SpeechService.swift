import AVFoundation

// Wraps AVSpeechSynthesizer for text-to-speech.
// All properties and methods that need to be called from non-MainActor contexts
// are marked nonisolated(unsafe) / nonisolated.
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {

    private let synthesizer = AVSpeechSynthesizer()
    var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    var voice: AVSpeechSynthesisVoice? = AVSpeechSynthesisVoice(language: "en-IN")
        ?? AVSpeechSynthesisVoice(language: "en-US")

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // Speaks the given text.  Safe to call from MainActor.
    func speak(_ text: String) {
        guard !text.isEmpty, text != "—" else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = voice
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }
}
