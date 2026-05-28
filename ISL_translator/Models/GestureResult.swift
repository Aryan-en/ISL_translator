import Foundation

// MARK: - ISL Gesture Enum

enum ISLGesture: String, CaseIterable, Sendable {
    // Letters
    case A, B, C, D, E, F, G, H, I, K, L, M, N, O, R, S, T, U, V, W, X, Y
    // Numbers
    case zero = "0", one = "1", two = "2", three = "3", four = "4", five = "5"
    case six = "6", seven = "7", eight = "8", nine = "9"
    // Common words
    case hello = "Hello"
    case thankYou = "Thank You"
    case yes = "Yes"
    case no = "No"
    case help = "Help"
    case water = "Water"
    case food = "Food"
    case sorry = "Sorry"
    case iLoveYou = "I Love You"
    // Fallback
    case unknown = "—"

    var displayText: String { rawValue }

    var category: GestureCategory {
        switch self {
        case .A, .B, .C, .D, .E, .F, .G, .H, .I, .K, .L, .M, .N, .O, .R, .S, .T, .U, .V, .W, .X, .Y:
            return .letter
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            return .number
        default:
            return .word
        }
    }

    var symbolName: String {
        switch self {
        case .hello: return "hand.wave"
        case .thankYou: return "hands.clap"
        case .yes: return "checkmark.circle"
        case .no: return "xmark.circle"
        case .help: return "sos.circle"
        case .water: return "drop"
        case .food: return "fork.knife"
        case .sorry: return "arrow.counterclockwise"
        case .iLoveYou: return "heart"
        case .unknown: return "questionmark.circle"
        default: return "hand.raised"
        }
    }
}

enum GestureCategory: String, Sendable {
    case letter = "Letter"
    case number = "Number"
    case word = "Word"
}

// MARK: - Gesture Result

struct GestureResult: Sendable {
    let gesture: ISLGesture
    let confidence: Float
    let timestamp: Date

    static let empty = GestureResult(gesture: .unknown, confidence: 0, timestamp: .now)

    var isValid: Bool { confidence >= 0.60 && gesture != .unknown }
    var confidencePercent: Int { Int(confidence * 100) }
}
