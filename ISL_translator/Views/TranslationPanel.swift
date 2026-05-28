import SwiftUI

// Right-hand panel: sentence output + history.
struct TranslationPanel: View {

    @ObservedObject var viewModel: CameraViewModel
    @State private var showCopied = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Sentence output area ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                Label("Translation", systemImage: "text.bubble.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ScrollView {
                    Text(viewModel.sentence.isEmpty ? "Hold a gesture to translate…" : viewModel.sentence)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(viewModel.sentence.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .animation(.spring(response: 0.3), value: viewModel.sentence)
                }
                .frame(minHeight: 90, maxHeight: 140)

                // Action row
                HStack(spacing: 8) {
                    Button {
                        viewModel.speakCurrentSentence()
                    } label: {
                        Label("Speak", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.sentence.isEmpty)

                    Button {
                        copyToClipboard(viewModel.sentence)
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopied = false
                        }
                    } label: {
                        Label(showCopied ? "Copied!" : "Copy",
                              systemImage: showCopied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.sentence.isEmpty)

                    Button(role: .destructive) {
                        viewModel.deleteLastWord()
                    } label: {
                        Image(systemName: "delete.left")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.sentence.isEmpty)
                    .keyboardShortcut(.delete, modifiers: [])

                    Button(role: .destructive) {
                        viewModel.clearSentence()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.sentence.isEmpty)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)

            Divider()

            // ── History list ─────────────────────────────────────────────────
            HistoryPanel(viewModel: viewModel)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
