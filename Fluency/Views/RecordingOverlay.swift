import SwiftUI

struct RecordingOverlay: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack(spacing: 0) {
            if appState.isTranscribing {
                // Transcribing state - show spinner
                TranscribingView()
            } else {
                // Recording state - show waveform
                ModernWaveformView(level: appState.audioLevel, isRecording: appState.isRecording, themeManager: themeManager)
            }
        }
        .frame(width: 180, height: 50)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
    }
}

struct TranscribingView: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Processing...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ModernWaveformView: View {
    let level: Float
    let isRecording: Bool
    let themeManager: ThemeManager
    let barCount = 12
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                ModernWaveformBar(
                    level: level,
                    index: index,
                    isRecording: isRecording,
                    themeManager: themeManager
                )
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModernWaveformBar: View {
    let level: Float
    let index: Int
    let isRecording: Bool
    let themeManager: ThemeManager
    
    @State private var animatedHeight: CGFloat = 0.15
    
    // Create a smooth wave pattern
    private var baseOffset: Double {
        Double(index) * 0.5
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        themeManager.colors.gradientMiddle,
                        themeManager.colors.gradientEnd
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: animatedHeight * 35)
            .animation(.easeInOut(duration: 0.08), value: animatedHeight)
            .onAppear {
                startIdleAnimation()
            }
            .onChange(of: level) { _, newLevel in
                updateHeight(for: newLevel)
            }
            .onChange(of: isRecording) { _, recording in
                if !recording {
                    startIdleAnimation()
                }
            }
    }
    
    private func startIdleAnimation() {
        // Gentle idle animation when not actively receiving audio
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.05)) {
            animatedHeight = 0.15 + sin(baseOffset) * 0.1
        }
    }
    
    private func updateHeight(for newLevel: Float) {
        let variation = sin(baseOffset + Double(Date().timeIntervalSince1970 * 8))
        let levelContribution = CGFloat(newLevel) * 0.7
        let variationContribution = CGFloat(variation) * 0.15
        animatedHeight = max(0.1, min(1.0, 0.15 + levelContribution + variationContribution))
    }
}

#Preview("Recording") {
    RecordingOverlay()
        .environmentObject({
            let state = AppState()
            state.isRecording = true
            state.statusMessage = "Listening..."
            state.audioLevel = 0.5
            return state
        }())
        .padding(40)
        .background(Color.gray.opacity(0.5))
}

#Preview("Transcribing") {
    RecordingOverlay()
        .environmentObject({
            let state = AppState()
            state.isTranscribing = true
            state.statusMessage = "Transcribing..."
            return state
        }())
        .padding(40)
        .background(Color.gray.opacity(0.5))
}
