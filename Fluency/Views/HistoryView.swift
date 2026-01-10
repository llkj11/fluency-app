import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcription.createdAt, order: .reverse) private var transcriptions: [Transcription]

    @State private var searchText = ""
    @State private var selectedTranscription: Transcription?

    var filteredTranscriptions: [Transcription] {
        if searchText.isEmpty {
            return transcriptions
        }
        return transcriptions.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTranscription) {
                ForEach(filteredTranscriptions) { transcription in
                    HistoryRow(transcription: transcription)
                        .tag(transcription)
                        .contextMenu {
                            Button("Copy") {
                                copyToClipboard(transcription.text)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteTranscription(transcription)
                            }
                        }
                }
                .onDelete(perform: deleteTranscriptions)
            }
            .searchable(text: $searchText, prompt: "Search transcriptions")
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    if !transcriptions.isEmpty {
                        Button(role: .destructive) {
                            deleteAllTranscriptions()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                }
            }
        } detail: {
            if let transcription = selectedTranscription {
                TranscriptionDetailView(transcription: transcription)
            } else {
                ContentUnavailableView(
                    "Select a Transcription",
                    systemImage: "text.bubble",
                    description: Text("Choose a transcription from the list to view details")
                )
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func deleteTranscription(_ transcription: Transcription) {
        modelContext.delete(transcription)
        if selectedTranscription == transcription {
            selectedTranscription = nil
        }
    }

    private func deleteTranscriptions(at offsets: IndexSet) {
        for index in offsets {
            let transcription = filteredTranscriptions[index]
            modelContext.delete(transcription)
            if selectedTranscription == transcription {
                selectedTranscription = nil
            }
        }
    }

    private func deleteAllTranscriptions() {
        for transcription in transcriptions {
            modelContext.delete(transcription)
        }
        selectedTranscription = nil
    }
}

struct HistoryRow: View {
    let transcription: Transcription

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transcription.text)
                .font(.system(size: 13))
                .lineLimit(2)
                .truncationMode(.tail)

            HStack(spacing: 8) {
                Label(transcription.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                Label("\(transcription.wordCount) words", systemImage: "text.word.spacing")
                Label(formatDuration(transcription.duration), systemImage: "waveform")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }
}

struct TranscriptionDetailView: View {
    let transcription: Transcription

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Metadata
                HStack(spacing: 16) {
                    MetadataItem(
                        icon: "clock",
                        title: "Created",
                        value: transcription.createdAt.formatted(date: .long, time: .shortened)
                    )

                    MetadataItem(
                        icon: "text.word.spacing",
                        title: "Words",
                        value: "\(transcription.wordCount)"
                    )

                    MetadataItem(
                        icon: "waveform",
                        title: "Duration",
                        value: formatDuration(transcription.duration)
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )

                // Text content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription")
                        .font(.headline)

                    Text(transcription.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.03))
                        )
                }

                // Actions
                HStack {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcription.text, forType: .string)
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Details")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds) seconds"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }
}

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 13, weight: .medium))
        }
    }
}

#Preview {
    HistoryView()
}
