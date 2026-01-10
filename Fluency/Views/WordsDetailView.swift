import SwiftUI

struct WordsDetailView: View {
    @State private var wordStats: StatsService.WordStats?
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var filteredWords: [StatsService.WordEntry] {
        guard let words = wordStats?.allWords else { return [] }
        if searchText.isEmpty {
            return words
        }
        return words.filter { $0.word.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Word Breakdown")
                    .font(.headline)
                
                Spacer()
                
                if let stats = wordStats {
                    Text("\(stats.uniqueWords) unique")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Summary Cards
            if let stats = wordStats {
                HStack(spacing: 12) {
                    SummaryCard(value: "\(stats.totalWords)", label: "Total Words", color: .blue)
                    SummaryCard(value: "\(stats.uniqueWords)", label: "Unique", color: .purple)
                }
                .padding(.horizontal)
            }
            
            // Search
            TextField("Search words...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
            
            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if filteredWords.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No words yet" : "No matches found")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(filteredWords) { entry in
                    WordRowView(entry: entry, maxCount: wordStats?.topWords.first?.count ?? 1)
                }
            }
        }
        .frame(width: 400, height: 500)
        .task {
            await loadWordStats()
        }
    }
    
    private func loadWordStats() async {
        isLoading = true
        wordStats = await StatsService.shared.fetchWordStats()
        isLoading = false
    }
}

struct SummaryCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

struct WordRowView: View {
    let entry: StatsService.WordEntry
    let maxCount: Int
    
    var barWidth: CGFloat {
        CGFloat(entry.count) / CGFloat(max(1, maxCount))
    }
    
    var body: some View {
        HStack {
            Text(entry.word)
                .font(.system(size: 13, design: .monospaced))
            
            Spacer()
            
            // Frequency bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * barWidth)
            }
            .frame(width: 100, height: 16)
            
            Text("\(entry.count)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WordsDetailView()
}
