import Foundation

class StatsService {
    static let shared = StatsService()
    
    private let defaults = UserDefaults.standard
    
    private let totalWordsKey = "fluency.stats.totalWords"
    private let totalTranscriptionsKey = "fluency.stats.totalTranscriptions"
    private let totalDurationKey = "fluency.stats.totalDuration"
    private let firstUseDateKey = "fluency.stats.firstUseDate"
    
    private init() {
        // Set first use date if not already set
        if defaults.object(forKey: firstUseDateKey) == nil {
            defaults.set(Date(), forKey: firstUseDateKey)
        }
    }
    
    // MARK: - Recording Stats
    
    func recordTranscription(wordCount: Int, duration: TimeInterval) {
        let currentWords = defaults.integer(forKey: totalWordsKey)
        let currentTranscriptions = defaults.integer(forKey: totalTranscriptionsKey)
        let currentDuration = defaults.double(forKey: totalDurationKey)
        
        defaults.set(currentWords + wordCount, forKey: totalWordsKey)
        defaults.set(currentTranscriptions + 1, forKey: totalTranscriptionsKey)
        defaults.set(currentDuration + duration, forKey: totalDurationKey)
    }
    
    // MARK: - Getters
    
    var totalWords: Int {
        defaults.integer(forKey: totalWordsKey)
    }
    
    var totalTranscriptions: Int {
        defaults.integer(forKey: totalTranscriptionsKey)
    }
    
    var totalDuration: TimeInterval {
        defaults.double(forKey: totalDurationKey)
    }
    
    var firstUseDate: Date? {
        defaults.object(forKey: firstUseDateKey) as? Date
    }
    
    var daysActive: Int {
        guard let firstUse = firstUseDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: firstUse, to: Date()).day ?? 0
        return max(1, days)
    }
    
    // Estimate time saved (assuming typing is 40 WPM, speaking is 150 WPM)
    var estimatedTimeSaved: TimeInterval {
        let typingWPM = 40.0
        let speakingWPM = 150.0
        let wordsPerMinute = Double(totalWords)
        
        let typingTime = wordsPerMinute / typingWPM * 60 // seconds
        let speakingTime = wordsPerMinute / speakingWPM * 60 // seconds
        
        return max(0, typingTime - speakingTime)
    }
    
    // MARK: - Reset
    
    func resetStats() {
        defaults.removeObject(forKey: totalWordsKey)
        defaults.removeObject(forKey: totalTranscriptionsKey)
        defaults.removeObject(forKey: totalDurationKey)
        defaults.set(Date(), forKey: firstUseDateKey)
    }
}
