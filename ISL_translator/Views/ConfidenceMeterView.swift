import SwiftUI

// Animated confidence gauge strip shown below the camera feed.
struct ConfidenceMeterView: View {

    let confidence: Float
    let holdProgress: Double
    let gesture: ISLGesture

    private var fillColor: Color {
        switch confidence {
        case 0.85...1.0: return .green
        case 0.70..<0.85: return .yellow
        case 0.55..<0.70: return .orange
        default: return .red.opacity(0.6)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(fillColor)
            }

            // Confidence bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(fillColor.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(confidence))
                        .animation(.spring(response: 0.3), value: confidence)
                }
            }
            .frame(height: 8)

            // Hold-to-accept progress bar
            if holdProgress > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "hand.raised.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Text("Hold to accept…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(holdProgress * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.cyan)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(0.06))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.cyan.opacity(0.75))
                            .frame(width: geo.size.width * holdProgress)
                            .animation(.linear(duration: 0.1), value: holdProgress)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
