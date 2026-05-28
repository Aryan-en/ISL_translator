import Foundation

struct TranslationEntry: Identifiable, Sendable {
    let id: UUID
    let text: String
    let timestamp: Date
    let confidence: Float
    let category: GestureCategory

    init(text: String, confidence: Float, category: GestureCategory) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.confidence = confidence
        self.category = category
    }

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .medium
        return f.string(from: timestamp)
    }
}
