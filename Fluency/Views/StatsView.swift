import SwiftUI

struct StatsView: View {
    @State private var stats: StatsService.ServerStats?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 20) {
                    StatCard(
                        title: "Words Dictated",
                        value: "\(stats?.totalWords ?? 0)",
                        icon: "text.word.spacing",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Transcriptions",
                        value: "\(stats?.totalTranscriptions ?? 0)",
                        icon: "waveform",
                        color: .purple
                    )
                }
                
                HStack(spacing: 20) {
                    StatCard(
                        title: "Time Recorded",
                        value: formatDuration(stats?.totalDuration ?? 0),
                        icon: "clock",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Time Saved",
                        value: formatDuration(StatsService.shared.estimatedTimeSaved),
                        icon: "bolt.fill",
                        color: .green
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .task {
            stats = await StatsService.shared.fetchStats()
            isLoading = false
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins)m \(secs)s"
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return "\(hours)h \(mins)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    StatsView()
        .padding()
        .frame(width: 350)
}
