import SwiftUI
import AVFoundation

@MainActor
final class CameraViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentResult: GestureResult = .empty
    @Published var currentLandmarks: [HandLandmarks] = []
    @Published var sentence: String = ""
    @Published var translationHistory: [TranslationEntry] = []
    @Published var isRunning = false
    @Published var permissionDenied = false
    @Published var errorMessage: String?
    @Published var holdProgress: Double = 0
    @Published var speakEnabled = true
    @Published var speechRate: Float = 0.5
    @Published var showOverlay = true
    @Published var activeMode: FilterMode = .all

    // MARK: - Services (private)

    private let camera = CameraService()
    private let sentenceBuilder = SentenceBuilder()
    private let speech = SpeechService()

    // Expose the AVCaptureSession for the preview view
    var captureSession: AVCaptureSession { camera.session }

    // MARK: - Lifecycle

    func start() async {
        await camera.requestPermission()
        guard camera.permissionGranted else {
            permissionDenied = true
            errorMessage = camera.error ?? "Camera permission required."
            return
        }

        await camera.configure()

        camera.coordinator.onFrame = { [weak self] result, landmarks in
            self?.handleFrame(result: result, landmarks: landmarks)
        }

        camera.start()
        isRunning = true
    }

    func stop() {
        camera.stop()
        isRunning = false
    }

    func toggleCamera() {
        if isRunning {
            stop()
        } else {
            Task { await start() }
        }
    }

    // MARK: - Frame Handling (called on main thread by coordinator)

    private func handleFrame(result: GestureResult, landmarks: [HandLandmarks]) {
        currentResult = result
        currentLandmarks = landmarks

        // Update hold progress for the pending gesture
        holdProgress = sentenceBuilder.holdProgress(for: result.gesture)

        // Try to commit a new token
        if let newToken = sentenceBuilder.update(with: result) {
            sentence = sentenceBuilder.currentSentence

            let entry = TranslationEntry(
                text: newToken,
                confidence: result.confidence,
                category: result.gesture.category
            )
            translationHistory.insert(entry, at: 0)
            if translationHistory.count > 200 { translationHistory.removeLast() }

            if speakEnabled { speech.speak(newToken) }
        }
    }

    // MARK: - Controls

    func clearSentence() {
        sentenceBuilder.clearSentence()
        sentence = ""
    }

    func deleteLastWord() {
        sentenceBuilder.removeLastToken()
        sentence = sentenceBuilder.currentSentence
    }

    func speakCurrentSentence() {
        guard !sentence.isEmpty else { return }
        speech.rate = speechRate
        speech.speak(sentence)
    }

    func updateSpeechRate(_ rate: Float) {
        speechRate = rate
        speech.rate = rate
    }

    func clearHistory() {
        translationHistory.removeAll()
    }

    func exportHistory() -> String {
        translationHistory.map { "[\($0.timeString)] \($0.text)" }.joined(separator: "\n")
    }
}

// MARK: - Filter Mode

enum FilterMode: String, CaseIterable {
    case all = "All"
    case letters = "Letters"
    case numbers = "Numbers"
    case words = "Words"
}
