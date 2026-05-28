import Foundation

// Accumulates gestures into words / sentences with debounce logic.
// All state is accessed from the MainActor (the ViewModel is @MainActor).
final class SentenceBuilder {

    // How long the same gesture must be held before it's accepted
    private let holdDuration: TimeInterval = 0.8
    // Minimum time before the same gesture is accepted again
    private let repeatCooldown: TimeInterval = 1.4
    // Maximum pause before the sentence is considered complete
    private let sentenceTimeout: TimeInterval = 4.0

    private var pendingGesture: ISLGesture?
    private var pendingStart: Date?
    private var lastAccepted: ISLGesture?
    private var lastAcceptedTime: Date?
    private var lastActivityTime: Date = .now

    private(set) var tokens: [String] = []       // accumulated words/letters
    private(set) var currentSentence: String = ""

    // Called every frame with the latest detection result.
    // Returns a newly accepted token if one was just confirmed, else nil.
    func update(with result: GestureResult) -> String? {
        let now = Date()
        let gesture = result.gesture

        // Auto-clear stale sentence
        if now.timeIntervalSince(lastActivityTime) > sentenceTimeout, !tokens.isEmpty {
            clearSentence()
        }

        guard result.isValid else {
            pendingGesture = nil
            pendingStart = nil
            return nil
        }

        lastActivityTime = now

        // Track hold
        if gesture != pendingGesture {
            pendingGesture = gesture
            pendingStart = now
            return nil
        }

        guard let start = pendingStart,
              now.timeIntervalSince(start) >= holdDuration
        else { return nil }

        // Check cooldown (avoid repeating the same sign too fast)
        if let last = lastAccepted, last == gesture,
           let lastTime = lastAcceptedTime,
           now.timeIntervalSince(lastTime) < repeatCooldown {
            return nil
        }

        // Accept the gesture
        let token = gesture.displayText
        tokens.append(token)
        currentSentence = tokens.joined(separator: " ")

        lastAccepted = gesture
        lastAcceptedTime = now
        pendingGesture = nil
        pendingStart = nil

        return token
    }

    func removeLastToken() {
        guard !tokens.isEmpty else { return }
        tokens.removeLast()
        currentSentence = tokens.joined(separator: " ")
    }

    func clearSentence() {
        tokens.removeAll()
        currentSentence = ""
        pendingGesture = nil
        pendingStart = nil
        lastAccepted = nil
    }

    // Time remaining before the pending gesture is accepted (0-1 progress)
    func holdProgress(for gesture: ISLGesture, at now: Date = .now) -> Double {
        guard pendingGesture == gesture, let start = pendingStart else { return 0 }
        return min(1, now.timeIntervalSince(start) / holdDuration)
    }
}
