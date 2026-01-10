import AVFoundation
import AppKit

class AudioFeedbackService {
    static let shared = AudioFeedbackService()
    
    private var startSound: NSSound?
    private var stopSound: NSSound?
    
    private init() {
        // Use system sounds for feedback
        // These are subtle and professional
        startSound = NSSound(named: "Tink")
        stopSound = NSSound(named: "Pop")
    }
    
    func playStartSound() {
        startSound?.play()
    }
    
    func playStopSound() {
        stopSound?.play()
    }
    
    func playSuccessSound() {
        NSSound(named: "Glass")?.play()
    }
    
    func playErrorSound() {
        NSSound(named: "Basso")?.play()
    }
}
