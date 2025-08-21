import Foundation
import AVFoundation
import Combine
import SwiftUI

// MARK: - Text-to-Speech Manager
@MainActor
final class TextToSpeechManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var currentProgress: Float = 0.0
    @Published var isAvailable = true
    @Published var errorMessage: String?
    @Published var currentMode: TTSMode = .normal
    
    // MARK: - Private Properties
    private let vietnameseTTS = VietnameseTextToSpeech()
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private var currentActivity: LearningActivity = .readingPractice
    private var isConfiguredForChildren = true
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        configureForChildren()
    }
    
    // MARK: - Public Methods
    
    /// Speak text for reading practice
    func speakForReading(_ text: String, mode: ReadingMode = .normal) async {
        currentMode = .reading
        
        switch mode {
        case .normal:
            vietnameseTTS.speakForReadingPractice(text, emphasis: .normal)
        case .slow:
            vietnameseTTS.speakForReadingPractice(text, emphasis: .wordByWord)
        case .syllable:
            vietnameseTTS.speakForReadingPractice(text, emphasis: .syllableBysyllable)
        case .phonetic:
            vietnameseTTS.speakForReadingPractice(text, emphasis: .phonetic)
        }
    }
    
    /// Speak individual word for practice
    func speakWord(_ word: String, withPause: Bool = true) {
        currentMode = .word
        vietnameseTTS.speakWord(word, withPause: withPause)
    }
    
    /// Speak instruction text
    func speakInstruction(_ instruction: String) {
        currentMode = .instruction
        vietnameseTTS.configureForActivity(.instruction)
        vietnameseTTS.speak(instruction, priority: .high)
    }
    
    /// Speak encouragement based on performance
    func speakEncouragement(for performance: ReadingPerformance) {
        currentMode = .encouragement
        
        let context: EncouragementContext
        switch performance.accuracy {
        case 0.9...1.0:
            context = .achievement
        case 0.7..<0.9:
            context = .progress
        case 0.5..<0.7:
            context = .motivation
        default:
            context = .retry
        }
        
        let message = getEncouragementMessage(for: context)
        vietnameseTTS.speakEncouragement(message)
    }
    
    /// Speak story text with appropriate pacing
    func speakStory(_ text: String) {
        currentMode = .story
        vietnameseTTS.configureForActivity(.storyTelling)
        vietnameseTTS.speak(text, priority: .normal)
    }
    
    /// Speak feedback message
    func speakFeedback(_ feedback: String, type: FeedbackType = .neutral) {
        currentMode = .feedback
        
        let pitch: Float
        let rate: Float
        
        switch type {
        case .positive:
            pitch = 1.2
            rate = 0.5
        case .negative:
            pitch = 1.0
            rate = 0.4
        case .neutral:
            pitch = 1.1
            rate = 0.45
        case .encouraging:
            pitch = 1.3
            rate = 0.5
        }
        
        vietnameseTTS.speak(
            feedback,
            rate: rate,
            pitch: pitch,
            priority: .high
        )
    }
    
    /// Pause current speech
    func pause() {
        vietnameseTTS.pauseSpeech()
    }
    
    /// Resume paused speech
    func resume() {
        vietnameseTTS.resumeSpeech()
    }
    
    /// Stop all speech
    func stop() {
        vietnameseTTS.stopSpeech()
    }
    
    /// Configure TTS for specific learning activity
    func configureForActivity(_ activity: LearningActivity) {
        currentActivity = activity
        vietnameseTTS.configureForActivity(activity)
    }
    
    /// Test current voice configuration
    func testVoice() {
        if let selectedVoice = vietnameseTTS.selectedVoice {
            vietnameseTTS.testVoice(selectedVoice)
        }
    }
    
    /// Get available voices
    func getAvailableVoices() -> [TTSVoice] {
        return vietnameseTTS.availableVoices
    }
    
    /// Select voice by identifier
    func selectVoice(identifier: String) {
        vietnameseTTS.selectVoice(identifier: identifier)
    }
    
    /// Configure voice settings
    func configureVoice(rate: Float? = nil, pitch: Float? = nil, volume: Float? = nil) {
        vietnameseTTS.configureVoice(rate: rate, pitch: pitch, volume: volume)
    }
    
    /// Get TTS capabilities and status
    func getTTSStatus() -> TTSStatus {
        let statistics = vietnameseTTS.getTTSStatistics()
        
        return TTSStatus(
            isAvailable: isAvailable,
            hasVietnameseSupport: statistics.hasVietnameseSupport,
            currentVoice: statistics.currentVoice,
            supportQuality: statistics.supportQuality,
            isConfiguredForChildren: isConfiguredForChildren,
            currentActivity: currentActivity,
            errorMessage: errorMessage
        )
    }
    
    /// Speak reading comparison results
    func speakReadingComparison(_ result: ReadingComparisonResult) {
        let accuracy = result.overallAccuracy
        
        // First speak the performance feedback
        speakEncouragement(for: ReadingPerformance(accuracy: accuracy, wordsRead: result.totalWords))
        
        // Then provide specific feedback if needed
        if accuracy < 0.8 {
            let improvementText = generateImprovementSuggestion(for: result)
            speakFeedback(improvementText, type: .encouraging)
        }
    }
    
    /// Speak word-by-word comparison
    func speakWordComparison(_ word: String, isCorrect: Bool, suggestion: String? = nil) {
        if isCorrect {
            let encouragement = ["Đúng rồi!", "Tuyệt vời!", "Giỏi lắm!"].randomElement() ?? "Đúng rồi!"
            speakFeedback(encouragement, type: .positive)
        } else {
            speakFeedback("Hãy thử lại", type: .encouraging)
            if let suggestion = suggestion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.speakWord(suggestion)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind Vietnamese TTS properties
        vietnameseTTS.$isSpeaking
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)
        
        vietnameseTTS.$isPaused
            .assign(to: \.isPaused, on: self)
            .store(in: &cancellables)
        
        vietnameseTTS.$currentProgress
            .assign(to: \.currentProgress, on: self)
            .store(in: &cancellables)
        
        vietnameseTTS.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    private func configureForChildren() {
        // Select the best voice for children
        if let childVoice = vietnameseTTS.getRecommendedChildVoice() {
            vietnameseTTS.selectVoice(identifier: childVoice.identifier)
        }
        
        // Configure for reading practice by default
        configureForActivity(.readingPractice)
        isConfiguredForChildren = true
    }
    
    private func getEncouragementMessage(for context: EncouragementContext) -> EncouragementMessage {
        switch context {
        case .achievement:
            return EncouragementMessage.excellent.randomElement() ?? EncouragementMessage.excellent[0]
        case .progress:
            return EncouragementMessage.good.randomElement() ?? EncouragementMessage.good[0]
        case .motivation:
            return EncouragementMessage.needsImprovement.randomElement() ?? EncouragementMessage.needsImprovement[0]
        case .retry:
            return EncouragementMessage.tryAgain.randomElement() ?? EncouragementMessage.tryAgain[0]
        case .instruction:
            return EncouragementMessage.needsImprovement.randomElement() ?? EncouragementMessage.needsImprovement[0]
        }
    }
    
    private func generateImprovementSuggestion(for result: ReadingComparisonResult) -> String {
        let suggestions = [
            "Hãy đọc chậm hơn một chút để rõ ràng hơn.",
            "Thử đọc to hơn để bé nghe rõ giọng mình.",
            "Đọc từng từ một cách cẩn thận nhé.",
            "Bé có thể làm tốt hơn! Thử lại lần nữa."
        ]
        
        return suggestions.randomElement() ?? suggestions[0]
    }
}

// MARK: - Extensions for Reading Practice Integration

extension TextToSpeechManager {
    
    /// Speak text with highlighting support
    func speakWithHighlighting(_ text: String, onWordSpoken: @escaping (String, Range<String.Index>) -> Void) {
        // This would integrate with the highlighting system
        // For now, we'll speak normally and simulate word highlighting
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var currentIndex = text.startIndex
        
        for word in words {
            if let wordRange = text.range(of: word, range: currentIndex..<text.endIndex) {
                // Speak the word
                speakWord(word, withPause: true)
                
                // Notify about the word being spoken
                onWordSpoken(word, wordRange)
                
                // Update current index
                currentIndex = wordRange.upperBound
            }
        }
    }
    
    /// Speak with real-time feedback
    func speakForComparison(_ targetText: String, recognizedText: String) {
        // Compare texts and provide feedback
        let similarity = calculateSimilarity(target: targetText, recognized: recognizedText)
        
        if similarity > 0.8 {
            speakFeedback("Tuyệt vời! Bé đọc rất chính xác!", type: .positive)
        } else if similarity > 0.6 {
            speakFeedback("Khá tốt! Hãy thử đọc rõ ràng hơn.", type: .encouraging)
        } else {
            speakFeedback("Hãy nghe và đọc theo:", type: .neutral)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.speakForReading(targetText, mode: .slow)
            }
        }
    }
    
    private func calculateSimilarity(target: String, recognized: String) -> Float {
        // Simple similarity calculation
        let targetWords = target.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let recognizedWords = recognized.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let commonWords = Set(targetWords).intersection(Set(recognizedWords))
        let totalWords = max(targetWords.count, recognizedWords.count)
        
        return totalWords > 0 ? Float(commonWords.count) / Float(totalWords) : 0.0
    }
}

// MARK: - Supporting Types

enum TTSMode {
    case normal
    case reading
    case word
    case instruction
    case encouragement
    case story
    case feedback
    
    var localizedDescription: String {
        switch self {
        case .normal:
            return "Bình thường"
        case .reading:
            return "Luyện đọc"
        case .word:
            return "Từ vựng"
        case .instruction:
            return "Hướng dẫn"
        case .encouragement:
            return "Khuyến khích"
        case .story:
            return "Kể chuyện"
        case .feedback:
            return "Phản hồi"
        }
    }
}

enum ReadingMode {
    case normal
    case slow
    case syllable
    case phonetic
    
    var localizedDescription: String {
        switch self {
        case .normal:
            return "Bình thường"
        case .slow:
            return "Chậm"
        case .syllable:
            return "Từng âm tiết"
        case .phonetic:
            return "Phiên âm"
        }
    }
}

enum FeedbackType {
    case positive
    case negative
    case neutral
    case encouraging
    
    var color: Color {
        switch self {
        case .positive:
            return .green
        case .negative:
            return .red
        case .neutral:
            return .blue
        case .encouraging:
            return .orange
        }
    }
}

enum LearningActivity {
    case readingPractice
    case wordPractice
    case storyTelling
    case instruction
    
    var localizedDescription: String {
        switch self {
        case .readingPractice:
            return "Luyện đọc"
        case .wordPractice:
            return "Luyện từ vựng"
        case .storyTelling:
            return "Kể chuyện"
        case .instruction:
            return "Hướng dẫn"
        }
    }
}

struct ReadingPerformance {
    let accuracy: Float
    let wordsRead: Int
    
    var level: PerformanceLevel {
        switch accuracy {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.6..<0.8:
            return .fair
        default:
            return .needsImprovement
        }
    }
}

enum PerformanceLevel {
    case excellent
    case good
    case fair
    case needsImprovement
    
    var localizedDescription: String {
        switch self {
        case .excellent:
            return "Xuất sắc"
        case .good:
            return "Tốt"
        case .fair:
            return "Khá"
        case .needsImprovement:
            return "Cần cải thiện"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .needsImprovement:
            return .red
        }
    }
}

struct ReadingComparisonResult {
    let targetText: String
    let recognizedText: String
    let overallAccuracy: Float
    let wordAccuracies: [Float]
    let totalWords: Int
    
    var averageWordAccuracy: Float {
        guard !wordAccuracies.isEmpty else { return 0.0 }
        return wordAccuracies.reduce(0, +) / Float(wordAccuracies.count)
    }
    
    var correctWords: Int {
        return wordAccuracies.filter { $0 > 0.8 }.count
    }
    
    var incorrectWords: Int {
        return totalWords - correctWords
    }
}

struct TTSStatus {
    let isAvailable: Bool
    let hasVietnameseSupport: Bool
    let currentVoice: TTSVoice?
    let supportQuality: TTSSupportQuality
    let isConfiguredForChildren: Bool
    let currentActivity: LearningActivity
    let errorMessage: String?
    
    var statusMessage: String {
        if let errorMessage = errorMessage {
            return "Lỗi: \(errorMessage)"
        }
        
        if !isAvailable {
            return "Text-to-Speech không khả dụng"
        }
        
        if !hasVietnameseSupport {
            return "Không hỗ trợ tiếng Việt"
        }
        
        return "Sẵn sàng - \(supportQuality.localizedDescription)"
    }
    
    var isReady: Bool {
        return isAvailable && hasVietnameseSupport && errorMessage == nil
    }
}

enum TTSSupportQuality {
    case excellent
    case good
    case limited
    case unsupported
    
    var localizedDescription: String {
        switch self {
        case .excellent:
            return "Hỗ trợ tuyệt vời"
        case .good:
            return "Hỗ trợ tốt"
        case .limited:
            return "Hỗ trợ hạn chế"
        case .unsupported:
            return "Không hỗ trợ"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .limited:
            return .orange
        case .unsupported:
            return .red
        }
    }
}

// MARK: - TTS Manager Extensions

extension TextToSpeechManager {
    
    /// Get TTS statistics for debugging and monitoring
    func getTTSStatistics() -> TTSStatistics {
        return vietnameseTTS.getTTSStatistics()
    }
    
    /// Export TTS configuration
    func exportConfiguration() -> TTSConfiguration {
        return TTSConfiguration(
            selectedVoiceId: vietnameseTTS.selectedVoice?.identifier,
            speechRate: vietnameseTTS.speechRate,
            pitch: vietnameseTTS.pitch,
            volume: vietnameseTTS.volume,
            isConfiguredForChildren: isConfiguredForChildren,
            currentActivity: currentActivity
        )
    }
    
    /// Import TTS configuration
    func importConfiguration(_ config: TTSConfiguration) {
        if let voiceId = config.selectedVoiceId {
            selectVoice(identifier: voiceId)
        }
        
        configureVoice(
            rate: config.speechRate,
            pitch: config.pitch,
            volume: config.volume
        )
        
        configureForActivity(config.currentActivity)
        isConfiguredForChildren = config.isConfiguredForChildren
    }
}

struct TTSConfiguration: Codable {
    let selectedVoiceId: String?
    let speechRate: Float
    let pitch: Float
    let volume: Float
    let isConfiguredForChildren: Bool
    let currentActivity: LearningActivity
}

extension LearningActivity: Codable {}

// MARK: - Vietnamese TTS Statistics Extension

extension VietnameseTextToSpeech {
    
    func getTTSStatistics() -> TTSStatistics {
        return TTSStatistics(
            availableVoicesCount: availableVoices.count,
            vietnameseVoicesCount: availableVoices.filter { $0.isVietnamese }.count,
            enhancedVoicesCount: availableVoices.filter { $0.quality == .enhanced }.count,
            currentVoice: selectedVoice,
            isConfiguredForChildren: true,
            supportedFeatures: getSupportedFeatures()
        )
    }
    
    private func getSupportedFeatures() -> [TTSFeature] {
        var features: [TTSFeature] = [
            .basicSpeech,
            .rateControl,
            .pitchControl,
            .volumeControl,
            .pauseResume,
            .queueManagement
        ]
        
        if #available(iOS 13.0, *) {
            features.append(.onDeviceProcessing)
        }
        
        if #available(iOS 16.0, *) {
            features.append(.punctuationControl)
        }
        
        return features
    }
}

enum TTSFeature {
    case basicSpeech
    case rateControl
    case pitchControl
    case volumeControl
    case pauseResume
    case queueManagement
    case onDeviceProcessing
    case punctuationControl
    
    var localizedDescription: String {
        switch self {
        case .basicSpeech:
            return "Đọc văn bản cơ bản"
        case .rateControl:
            return "Điều chỉnh tốc độ đọc"
        case .pitchControl:
            return "Điều chỉnh cao độ giọng"
        case .volumeControl:
            return "Điều chỉnh âm lượng"
        case .pauseResume:
            return "Tạm dừng và tiếp tục"
        case .queueManagement:
            return "Quản lý hàng đợi"
        case .onDeviceProcessing:
            return "Xử lý offline"
        case .punctuationControl:
            return "Điều khiển dấu câu"
        }
    }
}

struct TTSStatistics {
    let availableVoicesCount: Int
    let vietnameseVoicesCount: Int
    let enhancedVoicesCount: Int
    let currentVoice: TTSVoice?
    let isConfiguredForChildren: Bool
    let supportedFeatures: [TTSFeature]
    
    var hasVietnameseSupport: Bool {
        return vietnameseVoicesCount > 0
    }
    
    var hasEnhancedVoices: Bool {
        return enhancedVoicesCount > 0
    }
    
    var supportQuality: TTSSupportQuality {
        if hasEnhancedVoices && hasVietnameseSupport {
            return .excellent
        } else if hasVietnameseSupport {
            return .good
        } else {
            return .limited
        }
    }
}