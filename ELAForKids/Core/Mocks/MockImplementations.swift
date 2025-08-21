import Foundation
import PencilKit
import Combine

// MARK: - Mock Text Input Handler
class MockTextInputHandler: TextInputProtocol {
    var currentText: String = ""
    var isActive: Bool = false
    
    func startTextInput() {
        isActive = true
    }
    
    func processKeyboardInput(_ text: String) {
        currentText = text
    }
    
    func processPencilInput(_ drawing: PKDrawing) {
        // Mock implementation - just set some sample text
        currentText = "Văn bản mẫu từ Apple Pencil"
    }
    
    func finishTextInput() -> String {
        isActive = false
        return currentText
    }
    
    func clearInput() {
        currentText = ""
    }
    
    func validateInput(_ text: String) -> ValidationResult {
        if text.isEmpty {
            return .empty
        } else if text.count < 5 {
            return .tooShort(minLength: 5)
        } else if text.count > 200 {
            return .tooLong(maxLength: 200)
        } else {
            return .valid
        }
    }
}

// MARK: - Mock Handwriting Recognition
class MockHandwritingRecognizer: HandwritingRecognitionProtocol {
    private var confidence: Float = 0.85
    
    func recognizeText(from drawing: PKDrawing) async throws -> RecognitionResult {
        // Simulate processing time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return RecognitionResult(
            recognizedText: "Con mèo ngồi trên thảm",
            confidence: confidence,
            alternativeTexts: ["Con mèo ngồi trên ghế", "Con chó ngồi trên thảm"],
            processingTime: 1.0
        )
    }
    
    func getConfidenceScore() -> Float {
        return confidence
    }
    
    func isRecognitionAvailable() -> Bool {
        return true
    }
}

// MARK: - Mock Speech Recognition
class MockSpeechRecognitionManager: SpeechRecognitionProtocol {
    private var hasPermission = true
    private var isRecording = false
    
    func requestPermissions() async -> Bool {
        // Simulate permission request
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return hasPermission
    }
    
    func startRecording() async throws {
        guard hasPermission else {
            throw AppError.microphonePermissionDenied
        }
        isRecording = true
    }
    
    func stopRecording() async throws {
        isRecording = false
    }
    
    func convertSpeechToText() async throws -> String {
        guard !isRecording else {
            throw AppError.speechRecognitionFailed
        }
        
        // Simulate processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        return "Con mèo ngồi trên thảm xanh"
    }
    
    func isAvailable() -> Bool {
        return true
    }
    
    func getSupportedLocales() -> [Locale] {
        return [Locale(identifier: "vi-VN"), Locale(identifier: "en-US")]
    }
}

// MARK: - Mock Text Comparator
class MockTextComparator: TextComparisonProtocol {
    func compareTexts(original: String, spoken: String) -> ComparisonResult {
        let accuracy = calculateMockAccuracy(original: original, spoken: spoken)
        let mistakes = identifyMistakes(original: original, spoken: spoken)
        
        return ComparisonResult(
            originalText: original,
            spokenText: spoken,
            accuracy: accuracy,
            mistakes: mistakes,
            matchedWords: extractMatchedWords(original: original, spoken: spoken),
            feedback: generateFeedback(comparisonResult: ComparisonResult(
                originalText: original,
                spokenText: spoken,
                accuracy: accuracy,
                mistakes: mistakes,
                matchedWords: [],
                feedback: ""
            ))
        )
    }
    
    func identifyMistakes(original: String, spoken: String) -> [TextMistake] {
        let originalWords = original.components(separatedBy: .whitespaces)
        let spokenWords = spoken.components(separatedBy: .whitespaces)
        
        var mistakes: [TextMistake] = []
        
        // Simple mock implementation
        if originalWords.count != spokenWords.count {
            if originalWords.count > spokenWords.count {
                mistakes.append(TextMistake(
                    position: spokenWords.count,
                    expectedWord: originalWords[spokenWords.count],
                    actualWord: "",
                    mistakeType: .omission,
                    severity: .moderate
                ))
            } else {
                mistakes.append(TextMistake(
                    position: originalWords.count,
                    expectedWord: "",
                    actualWord: spokenWords[originalWords.count],
                    mistakeType: .insertion,
                    severity: .minor
                ))
            }
        }
        
        let minCount = min(originalWords.count, spokenWords.count)
        for i in 0..<minCount {
            if originalWords[i].lowercased() != spokenWords[i].lowercased() {
                mistakes.append(TextMistake(
                    position: i,
                    expectedWord: originalWords[i],
                    actualWord: spokenWords[i],
                    mistakeType: .substitution,
                    severity: .moderate
                ))
            }
        }
        
        return mistakes
    }
    
    func calculateAccuracy(original: String, spoken: String) -> Float {
        return calculateMockAccuracy(original: original, spoken: spoken)
    }
    
    func generateFeedback(comparisonResult: ComparisonResult) -> String {
        switch comparisonResult.scoreCategory {
        case .excellent:
            return "Tuyệt vời! Bé đọc rất hay!"
        case .good:
            return "Tốt lắm! Hãy tiếp tục cố gắng!"
        case .fair:
            return "Khá tốt! Bé có thể làm tốt hơn nữa!"
        case .needsImprovement:
            return "Bé cần luyện tập thêm nhé!"
        }
    }
    
    private func calculateMockAccuracy(original: String, spoken: String) -> Float {
        let originalWords = original.components(separatedBy: .whitespaces)
        let spokenWords = spoken.components(separatedBy: .whitespaces)
        
        let maxCount = max(originalWords.count, spokenWords.count)
        guard maxCount > 0 else { return 1.0 }
        
        let minCount = min(originalWords.count, spokenWords.count)
        var matches = 0
        
        for i in 0..<minCount {
            if originalWords[i].lowercased() == spokenWords[i].lowercased() {
                matches += 1
            }
        }
        
        return Float(matches) / Float(maxCount)
    }
    
    private func extractMatchedWords(original: String, spoken: String) -> [String] {
        let originalWords = original.components(separatedBy: .whitespaces)
        let spokenWords = spoken.components(separatedBy: .whitespaces)
        
        var matchedWords: [String] = []
        let minCount = min(originalWords.count, spokenWords.count)
        
        for i in 0..<minCount {
            if originalWords[i].lowercased() == spokenWords[i].lowercased() {
                matchedWords.append(originalWords[i])
            }
        }
        
        return matchedWords
    }
}

// MARK: - Mock Score Calculator
class MockScoreCalculator: ScoringProtocol {
    func calculateScore(accuracy: Float, attempts: Int, difficulty: DifficultyLevel) -> Int {
        let baseScore = Int(accuracy * 100)
        let difficultyMultiplier = difficulty.scoreMultiplier
        let attemptPenalty = max(0, (attempts - 1) * 5)
        
        let finalScore = Int(Float(baseScore) * difficultyMultiplier) - attemptPenalty
        return max(0, finalScore)
    }
    
    func calculateBonusPoints(streak: Int, perfectScore: Bool) -> Int {
        var bonus = 0
        
        if perfectScore {
            bonus += 20
        }
        
        if streak > 1 {
            bonus += min(streak * 2, 50) // Max 50 bonus points for streak
        }
        
        return bonus
    }
    
    func updateUserScore(userId: String, score: Int) async throws {
        // Mock implementation - just simulate delay
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func getLeaderboard(limit: Int) -> [UserScore] {
        return [
            UserScore(id: "1", userId: "user1", userName: "Minh", score: 1250, accuracy: 0.95, sessionsCompleted: 25, streak: 5, lastUpdated: Date(), rank: 1),
            UserScore(id: "2", userId: "user2", userName: "Lan", score: 1100, accuracy: 0.88, sessionsCompleted: 22, streak: 3, lastUpdated: Date(), rank: 2),
            UserScore(id: "3", userId: "user3", userName: "Hùng", score: 950, accuracy: 0.82, sessionsCompleted: 18, streak: 2, lastUpdated: Date(), rank: 3)
        ]
    }
    
    func getUserRanking(userId: String) -> Int? {
        // Mock implementation
        return 5
    }
}

// MARK: - Mock Achievement Manager
class MockAchievementManager: AchievementProtocol {
    private let sampleAchievements = [
        Achievement(
            id: "first_read",
            title: "Lần đầu đọc",
            description: "Hoàn thành bài đọc đầu tiên",
            icon: "book.fill",
            category: .reading,
            difficulty: .bronze,
            points: 10,
            requirement: AchievementRequirement(type: .readSessions, target: 1, timeframe: nil),
            unlockedAt: Date(),
            progress: 1.0
        ),
        Achievement(
            id: "perfect_score",
            title: "Điểm số hoàn hảo",
            description: "Đạt 100% độ chính xác",
            icon: "star.fill",
            category: .accuracy,
            difficulty: .gold,
            points: 50,
            requirement: AchievementRequirement(type: .perfectScores, target: 1, timeframe: nil),
            unlockedAt: nil,
            progress: 0.0
        )
    ]
    
    func checkForNewAchievements(sessionResult: SessionResult) async -> [Achievement] {
        // Mock logic - return achievement if perfect score
        if sessionResult.isPerfect {
            return [sampleAchievements[1]]
        }
        return []
    }
    
    func unlockAchievement(_ achievement: Achievement, for userId: String) async throws {
        // Mock implementation
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func getUserAchievements(userId: String) async -> [Achievement] {
        return sampleAchievements
    }
    
    func getAvailableAchievements() -> [Achievement] {
        return sampleAchievements
    }
    
    func getAchievementProgress(userId: String, achievementId: String) async -> Float {
        return sampleAchievements.first { $0.id == achievementId }?.progress ?? 0.0
    }
}