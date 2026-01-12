import SwiftUI

struct WordsDetailView: View {
    @State private var wordStats: StatsService.WordStats?
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
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
                    .font(themeManager.fonts.headline())
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Spacer()
                
                if let stats = wordStats {
                    Text("\(stats.uniqueWords) unique")
                        .font(themeManager.fonts.caption())
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.colors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Summary Cards
            if let stats = wordStats {
                HStack(spacing: 12) {
                    SummaryCard(value: "\(stats.totalWords)", label: "Total Words", color: themeManager.colors.iconWords, themeManager: themeManager)
                    SummaryCard(value: "\(stats.uniqueWords)", label: "Unique", color: themeManager.colors.iconTranscriptions, themeManager: themeManager)
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
                    .foregroundColor(themeManager.colors.textSecondary)
                Spacer()
            } else if filteredWords.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.colors.textMuted)
                    Text(searchText.isEmpty ? "No words yet" : "No matches found")
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                Spacer()
            } else {
                List(filteredWords) { entry in
                    WordRowView(entry: entry, maxCount: wordStats?.topWords.first?.count ?? 1, themeManager: themeManager)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(themeManager.colors.fullWindowGradient)
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
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(themeManager.fonts.statValue(size: 24))
                .foregroundColor(color)
            Text(label)
                .font(themeManager.fonts.caption())
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeManager.colors.cardBackground.opacity(themeManager.colors.cardBackgroundOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WordRowView: View {
    let entry: StatsService.WordEntry
    let maxCount: Int
    let themeManager: ThemeManager
    
    var barWidth: CGFloat {
        CGFloat(entry.count) / CGFloat(max(1, maxCount))
    }
    
    var body: some View {
        HStack {
            Text(entry.word)
                .font(themeManager.fonts.body(size: 13))
                .foregroundColor(themeManager.colors.textPrimary)
            
            Spacer()
            
            // Frequency bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [themeManager.colors.gradientStart.opacity(0.6), themeManager.colors.gradientEnd.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * barWidth)
            }
            .frame(width: 100, height: 16)
            
            Text("\(entry.count)")
                .font(themeManager.fonts.caption(size: 12))
                .foregroundColor(themeManager.colors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    WordsDetailView()
}
