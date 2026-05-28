import SwiftUI

struct SidebarView: View {

    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        List {

            // ── App Identity ───────────────────────────────────────────────
            Section {
                VStack(spacing: 6) {
                    Image(systemName: "hand.raised.fingers.spread.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue.gradient)
                    Text("ISL Translator")
                        .font(.headline.bold())
                    Text("Indian Sign Language → Text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // ── Camera Controls ────────────────────────────────────────────
            Section("Camera") {
                HStack {
                    Circle()
                        .fill(viewModel.isRunning ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isRunning ? "Camera active" : "Camera stopped")
                        .font(.callout)
                    Spacer()
                }

                Button {
                    viewModel.toggleCamera()
                } label: {
                    Label(viewModel.isRunning ? "Stop Camera" : "Start Camera",
                          systemImage: viewModel.isRunning ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isRunning ? .red : .green)
                .controlSize(.regular)
            }

            // ── Speech ─────────────────────────────────────────────────────
            Section("Speech") {
                Toggle(isOn: $viewModel.speakEnabled) {
                    Label("Auto-Speak", systemImage: "speaker.wave.2")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label("Speed: \(speechRateLabel)", systemImage: "gauge.medium")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $viewModel.speechRate, in: 0.1...0.7, step: 0.05) {
                        Text("Speech Rate")
                    } minimumValueLabel: {
                        Text("Slow").font(.caption2)
                    } maximumValueLabel: {
                        Text("Fast").font(.caption2)
                    }
                    .onChange(of: viewModel.speechRate) { _, rate in
                        viewModel.updateSpeechRate(rate)
                    }
                }

                Button {
                    viewModel.speakCurrentSentence()
                } label: {
                    Label("Speak Sentence", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.sentence.isEmpty)
            }

            // ── Sentence Tools ─────────────────────────────────────────────
            Section("Sentence") {
                Button {
                    viewModel.deleteLastWord()
                } label: {
                    Label("Delete Last Word", systemImage: "delete.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.sentence.isEmpty)
                .keyboardShortcut(.delete, modifiers: [.command])

                Button(role: .destructive) {
                    viewModel.clearSentence()
                } label: {
                    Label("Clear Sentence", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.sentence.isEmpty)
                .keyboardShortcut("k", modifiers: [.command])
            }

            // ── Gesture Legend ────────────────────────────────────────────
            Section("ISL Reference") {
                GestureLegendView()
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("ISL Translator")
    }

    private var speechRateLabel: String {
        switch viewModel.speechRate {
        case ..<0.25: return "Very Slow"
        case 0.25..<0.4: return "Slow"
        case 0.4..<0.55: return "Normal"
        case 0.55..<0.65: return "Fast"
        default: return "Very Fast"
        }
    }
}

// MARK: - Gesture Legend

struct GestureLegendView: View {

    private let categories: [(String, [String])] = [
        ("Alphabet", ["A", "B", "C", "D", "E", "F", "G", "H", "I", "K",
                      "L", "M", "N", "O", "R", "S", "T", "U", "V", "W", "X", "Y"]),
        ("Numbers",  ["0","1","2","3","4","5","6","7","8","9"]),
        ("Words",    ["Hello","Thank You","Yes","No","Help","Water","Food","Sorry","I Love You"])
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(categories, id: \.0) { title, items in
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 4) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > maxWidth, x > 0 {
                y += rowHeight + spacing; x = 0; rowHeight = 0
            }
            x += sz.width + spacing
            rowHeight = max(rowHeight, sz.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowHeight = max(rowHeight, sz.height)
        }
    }
}
