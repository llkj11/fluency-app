import AVFoundation
import Foundation

class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var levelTimer: Timer?

    var currentLevel: Float = 0

    override init() {
        super.init()
        // Don't request permission in init - check status first
        checkMicrophonePermission()
    }

    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            // Only request if not yet determined
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print(granted ? "🎤 Microphone permission granted" : "🎤 Microphone permission denied")
            }
        case .denied, .restricted:
            print("⚠️ Microphone permission denied. Please enable in System Settings.")
        case .authorized:
            print("✅ Microphone permission already granted")
        @unknown default:
            break
        }
    }

    func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "fluency_recording_\(UUID().uuidString).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)

        guard let url = recordingURL else { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            // Start level metering
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                // Normalize from dB (-160 to 0) to 0-1 range
                self?.currentLevel = max(0, min(1, (level + 50) / 50))
            }

            print("Started recording to: \(url)")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        levelTimer?.invalidate()
        levelTimer = nil
        currentLevel = 0

        audioRecorder?.stop()
        audioRecorder = nil

        let url = recordingURL
        recordingURL = nil
        return url
    }
}
