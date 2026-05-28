import SwiftUI

struct HistoryPanel: View {

    @ObservedObject var viewModel: CameraViewModel

    var filteredHistory: [TranslationEntry] {
        switch viewModel.activeMode {
        case .all:     return viewModel.translationHistory
        case .letters: return viewModel.translationHistory.filter { $0.category == .letter }
        case .numbers: return viewModel.translationHistory.filter { $0.category == .number }
        case .words:   return viewModel.translationHistory.filter { $0.category == .word }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("History", systemImage: "clock.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("", selection: $viewModel.activeMode) {
                    ForEach(FilterMode.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .controlSize(.mini)

                Button {
                    viewModel.clearHistory()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(viewModel.translationHistory.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            if filteredHistory.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "hand.raised.slash",
                    description: Text("Detected signs will appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredHistory) { entry in
                    HistoryRowView(entry: entry)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - History Row

struct HistoryRowView: View {
    let entry: TranslationEntry

    private var categoryColor: Color {
        switch entry.category {
        case .letter: return .blue
        case .number: return .orange
        case .word:   return .purple
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Category badge
            Text(entry.category.rawValue.prefix(1))
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(categoryColor, in: RoundedRectangle(cornerRadius: 4))

            // Text
            Text(entry.text)
                .font(.body.weight(.medium))
                .lineLimit(1)

            Spacer()

            // Confidence + time
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(entry.confidencePercent)%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(confidenceColor(entry.confidence))
                Text(entry.timeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func confidenceColor(_ c: Float) -> Color {
        c >= 0.85 ? .green : c >= 0.70 ? .yellow : .orange
    }
}

extension TranslationEntry {
    var confidencePercent: Int { Int(confidence * 100) }
}
