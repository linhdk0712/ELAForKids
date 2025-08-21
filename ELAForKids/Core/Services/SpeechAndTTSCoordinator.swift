import Foundation
import Speech
import AVFoundation
import Combine
import SwiftUI

// MARK: - Speech and TTS Coordinator
@MainActor
final class SpeechAndTTSCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var recognizedText = ""
    @Published var confidence: Float = 0.0
    @Published var audioLevel: Float = 0.0
    @Published var currentMode: CoordinatorMode = .idle
    @Published var errorMessage: String?
    @Published var isAvailable = false
    
    // MARK: - Private Properties
    private let speechRecognitionManager = SpeechRecognitionManager()
    private let textToSpeechManager = TextToSpeechManager()
    private var cancellables = Set<AnyCancellable>()
    
    // Session management
    private var currentSession: ReadingSession?
    private var sessionResults: [ReadingAttempt] = []
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        checkAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Start a new reading practice session
    func startReadingSession(targetText: String, mode: ReadingSessionMode = .practice) async throws {
        guard isAvailable else {
            throw CoordinatorError.systemUnavailable
        }
        
        currentSession = ReadingSession(
            targetText: targetText,
            mode: mode,
            startTime: Date()
        )
        
        sessionResults.removeAll()
        currentMode = .readingSession
        
        // Configure TTS for the session
        textToSpeechManager.configureForActivity(.readingPractice)
        
        // Speak instructions
        await speakInstructions(for: mode)
    }
    
    /// Start recording user's speech
    func startRecording() async throws {
        guard let session = currentSession else {
            throw CoordinatorError.noActiveSession
        }
        
        currentMode = .recording
        
        // Stop any current TTS
        textToSpeechManager.stop()
        
        // Start speech recognition
        try await speechRecognitionManager.startReadingPracticeRecognition()
    }
    
    /// Stop recording and process results
    func stopRecording() async -> ReadingAttempt {
        speechRecognitionManager.stopRecognition()
        currentMode = .processing
        
        guard let session = currentSession else {
            return ReadingAttempt(
                recognizedText: recognizedText,
                targetText: "",
                accuracy: 0.0,
                confidence: confidence,
                timestamp: Date(),
                feedback: []
            )
        }
        
        // Create reading attempt
        let attempt = ReadingAttempt(
            recognizedText: recognizedText,
            targetText: session.targetText,
            accuracy: calculateAccuracy(recognized: recognizedText, target: session.targetText),
            confidence: confidence,
            timestamp: Date(),
            feedback: generateFeedback(recognized: recognizedText, target: session.targetText)
        )
        
        sessionResults.append(attempt)
        
        // Provide immediate feedback
        await provideFeedback(for: attempt)
        
        currentMode = .feedback
        return attempt
    }
    
    /// Speak the target text for the user to hear
    func speakTargetText(mode: ReadingMode = .normal) async {
        guard let session = currentSession else { return }
        
        currentMode = .demonstration
        await textToSpeechManager.speakForReading(session.targetText, mode: mode)
        
        // Wait for TTS to complete
        while textToSpeechManager.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        currentMode = .readingSession
    }
    
    /// Speak individual word for practice
    func speakWord(_ word: String) {
        currentMode = .wordPractice
        textToSpeechManager.speakWord(word, withPause: true)
    }
    
    /// Get real-time comparison feedback
    func getRealTimeFeedback() -> ReadingFeedback? {
        guard let session = currentSession else { return nil }
        
        return speechRecognitionManager.getReadingFeedback(targetText: session.targetText)
    }
    
    /// End current session and get results
    func endSession() -> ReadingSessionResult? {
        guard let session = currentSession else { return nil }
        
        let result = ReadingSessionResult(
            session: session,
            attempts: sessionResults,
            endTime: Date()
        )
        
        currentSession = nil
        sessionResults.removeAll()
        currentMode = .idle
        
        return result
    }
    
    /// Pause all audio activities
    func pauseAll() {
        speechRecognitionManager.stopRecognition()
        textToSpeechManager.pause()
        currentMode = .paused
    }
    
    /// Resume activities
    func resumeAll() {
        textToSpeechManager.resume()
        if currentMode == .paused {
            currentMode = .readingSession
        }
    }
    
    /// Stop all activities
    func stopAll() {
        speechRecognitionManager.stopRecognition()
        textToSpeechManager.stop()
        currentMode = .idle
    }
    
    /// Configure system for specific use case
    func configureForUseCase(_ useCase: ReadingUseCase) {
        switch useCase {
        case .beginnerPractice:
            textToSpeechManager.configureVoice(rate: 0.3, pitch: 1.1, volume: 0.8)
            speechRecognitionManager.configureForUseCase(.readingPractice)
            
        case .advancedPractice:
            textToSpeechManager.configureVoice(rate: 0.5, pitch: 1.0, volume: 0.8)
            speechRecognitionManager.configureForUseCase(.readingPractice)
            
        case .wordPractice:
            textToSpeechManager.configureVoice(rate: 0.25, pitch: 1.0, volume: 0.9)
            speechRecognitionManager.configureForUseCase(.quickInput)
            
        case .assessment:
            textToSpeechManager.configureVoice(rate: 0.4, pitch: 1.0, volume: 0.7)
            speechRecognitionManager.configureForUseCase(.dictation)
        }
    }
    
    /// Get system status
    func getSystemStatus() -> SystemStatus {
        let speechStatus = speechRecognitionManager.checkVietnameseSupport()
        let ttsStatus = textToSpeechManager.getTTSStatus()
        
        return SystemStatus(
            speechRecognitionAvailable: speechStatus.isSupported,
            textToSpeechAvailable: ttsStatus.isAvailable,
            vietnameseSupported: speechStatus.isSupported && ttsStatus.hasVietnameseSupport,
            currentMode: currentMode,
            hasActiveSession: currentSession != nil,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind speech recognition properties
        speechRecognitionManager.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        speechRecognitionManager.$recognizedText
            .assign(to: \.recognizedText, on: self)
            .store(in: &cancellables)
        
        speechRecognitionManager.$confidence
            .assign(to: \.confidence, on: self)
            .store(in: &cancellables)
        
        speechRecognitionManager.$audioLevel
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
        
        speechRecognitionManager.$errorMessage
            .compactMap { $0 }
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        // Bind TTS properties
        textToSpeechManager.$isSpeaking
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)
        
        textToSpeechManager.$errorMessage
            .compactMap { $0 }
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        // Update availability when either system changes
        Publishers.CombineLatest(
            speechRecognitionManager.$isAvailable,
            textToSpeechManager.$isAvailable
        )
        .map { speechAvailable, ttsAvailable in
            speechAvailable && ttsAvailable
        }
        .assign(to: \.isAvailable, on: self)
        .store(in: &cancellables)
    }
    
    private func checkAvailability() {
        Task {
            let speechSupport = speechRecognitionManager.checkVietnameseSupport()
            let ttsStatus = textToSpeechManager.getTTSStatus()
            
            isAvailable = speechSupport.isSupported && ttsStatus.isAvailable
            
            if !isAvailable {
                if !speechSupport.isSupported {
                    errorMessage = "Nhận dạng giọng nói tiếng Việt không được hỗ trợ"
                } else if !ttsStatus.isAvailable {
                    errorMessage = "Text-to-Speech không khả dụng"
                }
            }
        }
    }
    
    private func speakInstructions(for mode: ReadingSessionMode) async {
        let instruction: String
        
        switch mode {
        case .practice:
            instruction = "Hãy nghe và đọc theo. Bé có thể nghe lại bất cứ lúc nào."
        case .assessment:
            instruction = "Bây giờ bé hãy đọc văn bản này. Đọc rõ ràng và chậm rãi nhé."
        case .wordByWord:
            instruction = "Chúng ta sẽ luyện từng từ một. Nghe và đọc theo từng từ nhé."
        case .freeReading:
            instruction = "Bé có thể đọc tự do. Hãy đọc theo cách bé thích."
        }
        
        textToSpeechManager.speakInstruction(instruction)
        
        // Wait for instruction to complete
        while textToSpeechManager.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func calculateAccuracy(recognized: String, target: String) -> Float {
        // Use the Vietnamese language utilities for better accuracy
        return VietnameseLanguageUtils.phoneticSimilarity(word1: recognized, word2: target)
    }
    
    private func generateFeedback(recognized: String, target: String) -> [FeedbackItem] {
        var feedback: [FeedbackItem] = []
        
        let recognizedWords = recognized.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let targetWords = target.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let maxCount = max(recognizedWords.count, targetWords.count)
        
        for i in 0..<maxCount {
            let recognizedWord = i < recognizedWords.count ? recognizedWords[i] : ""
            let targetWord = i < targetWords.count ? targetWords[i] : ""
            
            if recognizedWord.isEmpty {
                feedback.append(FeedbackItem(
                    type: .missing,
                    position: i,
                    expectedWord: targetWord,
                    actualWord: "",
                    suggestion: "Thiếu từ: \(targetWord)"
                ))
            } else if targetWord.isEmpty {
                feedback.append(FeedbackItem(
                    type: .extra,
                    position: i,
                    expectedWord: "",
                    actualWord: recognizedWord,
                    suggestion: "Từ thừa: \(recognizedWord)"
                ))
            } else {
                let similarity = VietnameseLanguageUtils.phoneticSimilarity(word1: recognizedWord, word2: targetWord)
                
                if similarity < 0.8 {
                    feedback.append(FeedbackItem(
                        type: .mispronunciation,
                        position: i,
                        expectedWord: targetWord,
                        actualWord: recognizedWord,
                        suggestion: "Thử phát âm: \(targetWord)"
                    ))
                } else {
                    feedback.append(FeedbackItem(
                        type: .correct,
                        position: i,
                        expectedWord: targetWord,
                        actualWord: recognizedWord,
                        suggestion: "Đúng rồi!"
                    ))
                }
            }
        }
        
        return feedback
    }
    
    private func provideFeedback(for attempt: ReadingAttempt) async {
        let accuracy = attempt.accuracy
        
        // Speak encouragement based on performance
        textToSpeechManager.speakEncouragement(for: ReadingPerformance(
            accuracy: accuracy,
            wordsRead: attempt.targetText.components(separatedBy: .whitespacesAndNewlines).count
        ))
        
        // Wait for encouragement to complete
        while textToSpeechManager.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Provide specific feedback for errors
        let errors = attempt.feedback.filter { $0.type != .correct }
        if !errors.isEmpty && errors.count <= 3 { // Only provide feedback for a few errors
            for error in errors.prefix(3) {
                switch error.type {
                case .mispronunciation:
                    textToSpeechManager.speakFeedback("Từ \(error.expectedWord):", type: .neutral)
                    while textToSpeechManager.isSpeaking {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    textToSpeechManager.speakWord(error.expectedWord)
                    while textToSpeechManager.isSpeaking {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    
                case .missing:
                    textToSpeechManager.speakFeedback("Bé quên từ: \(error.expectedWord)", type: .encouraging)
                    while textToSpeechManager.isSpeaking {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    
                case .extra:
                    textToSpeechManager.speakFeedback("Từ \(error.actualWord) không có trong câu", type: .neutral)
                    while textToSpeechManager.isSpeaking {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    
                case .correct:
                    break
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum CoordinatorMode {
    case idle
    case readingSession
    case recording
    case processing
    case demonstration
    case wordPractice
    case feedback
    case paused
    
    var localizedDescription: String {
        switch self {
        case .idle:
            return "Sẵn sàng"
        case .readingSession:
            return "Phiên luyện đọc"
        case .recording:
            return "Đang ghi âm"
        case .processing:
            return "Đang xử lý"
        case .demonstration:
            return "Đang minh họa"
        case .wordPractice:
            return "Luyện từ vựng"
        case .feedback:
            return "Phản hồi"
        case .paused:
            return "Tạm dừng"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .gray
        case .readingSession:
            return .blue
        case .recording:
            return .red
        case .processing:
            return .orange
        case .demonstration:
            return .green
        case .wordPractice:
            return .purple
        case .feedback:
            return .yellow
        case .paused:
            return .gray
        }
    }
}

enum ReadingSessionMode {
    case practice
    case assessment
    case wordByWord
    case freeReading
    
    var localizedDescription: String {
        switch self {
        case .practice:
            return "Luyện tập"
        case .assessment:
            return "Đánh giá"
        case .wordByWord:
            return "Từng từ"
        case .freeReading:
            return "Đọc tự do"
        }
    }
}

enum ReadingUseCase {
    case beginnerPractice
    case advancedPractice
    case wordPractice
    case assessment
    
    var localizedDescription: String {
        switch self {
        case .beginnerPractice:
            return "Luyện tập cơ bản"
        case .advancedPractice:
            return "Luyện tập nâng cao"
        case .wordPractice:
            return "Luyện từ vựng"
        case .assessment:
            return "Đánh giá"
        }
    }
}

struct ReadingSession {
    let id = UUID()
    let targetText: String
    let mode: ReadingSessionMode
    let startTime: Date
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}

struct ReadingAttempt {
    let id = UUID()
    let recognizedText: String
    let targetText: String
    let accuracy: Float
    let confidence: Float
    let timestamp: Date
    let feedback: [FeedbackItem]
    
    var wordCount: Int {
        return targetText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var correctWords: Int {
        return feedback.filter { $0.type == .correct }.count
    }
    
    var errors: [FeedbackItem] {
        return feedback.filter { $0.type != .correct }
    }
}

struct FeedbackItem {
    let type: FeedbackType
    let position: Int
    let expectedWord: String
    let actualWord: String
    let suggestion: String
    
    enum FeedbackType {
        case correct
        case mispronunciation
        case missing
        case extra
        
        var localizedDescription: String {
            switch self {
            case .correct:
                return "Đúng"
            case .mispronunciation:
                return "Phát âm sai"
            case .missing:
                return "Thiếu từ"
            case .extra:
                return "Từ thừa"
            }
        }
        
        var color: Color {
            switch self {
            case .correct:
                return .green
            case .mispronunciation:
                return .orange
            case .missing:
                return .red
            case .extra:
                return .purple
            }
        }
    }
}

struct ReadingSessionResult {
    let session: ReadingSession
    let attempts: [ReadingAttempt]
    let endTime: Date
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(session.startTime)
    }
    
    var averageAccuracy: Float {
        guard !attempts.isEmpty else { return 0.0 }
        return attempts.map { $0.accuracy }.reduce(0, +) / Float(attempts.count)
    }
    
    var bestAttempt: ReadingAttempt? {
        return attempts.max { $0.accuracy < $1.accuracy }
    }
    
    var totalWords: Int {
        return session.targetText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var improvementRate: Float {
        guard attempts.count > 1 else { return 0.0 }
        let first = attempts.first!.accuracy
        let last = attempts.last!.accuracy
        return last - first
    }
}

struct SystemStatus {
    let speechRecognitionAvailable: Bool
    let textToSpeechAvailable: Bool
    let vietnameseSupported: Bool
    let currentMode: CoordinatorMode
    let hasActiveSession: Bool
    let errorMessage: String?
    
    var isFullyOperational: Bool {
        return speechRecognitionAvailable && textToSpeechAvailable && vietnameseSupported && errorMessage == nil
    }
    
    var statusMessage: String {
        if let errorMessage = errorMessage {
            return "Lỗi: \(errorMessage)"
        }
        
        if !speechRecognitionAvailable {
            return "Nhận dạng giọng nói không khả dụng"
        }
        
        if !textToSpeechAvailable {
            return "Text-to-Speech không khả dụng"
        }
        
        if !vietnameseSupported {
            return "Không hỗ trợ tiếng Việt"
        }
        
        return "Hệ thống sẵn sàng - \(currentMode.localizedDescription)"
    }
}

enum CoordinatorError: LocalizedError {
    case systemUnavailable
    case noActiveSession
    case speechRecognitionFailed
    case textToSpeechFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .systemUnavailable:
            return "Hệ thống không khả dụng"
        case .noActiveSession:
            return "Không có phiên luyện tập nào đang hoạt động"
        case .speechRecognitionFailed:
            return "Nhận dạng giọng nói thất bại"
        case .textToSpeechFailed:
            return "Text-to-Speech thất bại"
        case .permissionDenied:
            return "Không có quyền truy cập microphone"
        }
    }
}

// MARK: - Extensions for Integration

extension SpeechAndTTSCoordinator {
    
    /// Quick practice session for a single word
    func practiceWord(_ word: String) async throws {
        try await startReadingSession(targetText: word, mode: .wordByWord)
        await speakTargetText(mode: .slow)
        
        // Wait a moment for user to prepare
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        try await startRecording()
    }
    
    /// Practice session with step-by-step guidance
    func guidedPracticeSession(targetText: String) async throws {
        try await startReadingSession(targetText: targetText, mode: .practice)
        
        // First, speak the entire text
        await speakTargetText(mode: .normal)
        
        // Then break it down word by word
        let words = targetText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        for word in words {
            textToSpeechManager.speakFeedback("Từ tiếp theo:", type: .neutral)
            while textToSpeechManager.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            speakWord(word)
            while textToSpeechManager.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            // Pause for user to repeat
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        // Finally, ask user to read the complete text
        textToSpeechManager.speakInstruction("Bây giờ bé hãy đọc toàn bộ câu:")
        while textToSpeechManager.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        try await startRecording()
    }
    
    /// Assessment session with minimal guidance
    func assessmentSession(targetText: String) async throws -> ReadingSessionResult? {
        try await startReadingSession(targetText: targetText, mode: .assessment)
        
        // Give minimal instruction
        textToSpeechManager.speakInstruction("Hãy đọc văn bản này:")
        while textToSpeechManager.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Start recording immediately
        try await startRecording()
        
        // Wait for user to finish (this would be handled by UI in real implementation)
        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds max
        
        let _ = await stopRecording()
        return endSession()
    }
}