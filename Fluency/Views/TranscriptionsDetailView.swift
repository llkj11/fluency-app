import SwiftUI

struct TranscriptionsDetailView: View {
    @State private var transcriptions: [StatsService.ServerTranscription] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var filteredTranscriptions: [StatsService.ServerTranscription] {
        if searchText.isEmpty {
            return transcriptions
        }
        return transcriptions.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Transcriptions")
                    .font(.headline)
                
                Spacer()
                
                Text("\(transcriptions.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Search
            TextField("Search transcriptions...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Divider()
                .padding(.top, 8)
            
            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if filteredTranscriptions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No transcriptions yet" : "No matches found")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(filteredTranscriptions) { transcription in
                    TranscriptionRowView(transcription: transcription)
                }
            }
        }
        .frame(width: 400, height: 500)
        .task {
            await loadTranscriptions()
        }
    }
    
    private func loadTranscriptions() async {
        isLoading = true
        transcriptions = await StatsService.shared.fetchTranscriptions()
        isLoading = false
    }
}

struct TranscriptionRowView: View {
    let transcription: StatsService.ServerTranscription
    @State private var isHovering = false
    @State private var copied = false
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: transcription.createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return transcription.createdAt
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(transcription.text)
                .font(.system(size: 12))
                .lineLimit(3)
            
            HStack {
                Label("\(transcription.wordCount) words", systemImage: "text.word.spacing")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let device = transcription.device {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label(device, systemImage: device == "mac" ? "desktopcomputer" : "iphone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isHovering {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(copied ? .green : .accentColor)
                }
            }
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcription.text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }
}

#Preview {
    TranscriptionsDetailView()
}
