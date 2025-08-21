import Foundation
import Combine

// MARK: - Text Input Use Cases

final class ProcessTextInputUseCase: ProcessTextInputUseCaseProtocol {
    private let textInputHandler: TextInputProtocol
    private let validationService: TextValidationService
    
    init(textInputHandler: TextInputProtocol, validationService: TextValidationService) {
        self.textInputHandler = textInputHandler
        self.validationService = validationService
    }
    
    func execute(input: TextInputRequest) async throws -> TextInputResponse {
        // Process the input text
        let processedText = try await textInputHandler.processText(input.text, method: input.inputMethod)
        
        // Validate the processed text
        let validationResult = validationService.validate(processedText)
        
        // Generate suggestions based on validation
        let suggestions = validationService.generateSuggestions(for: processedText, validationResult: validationResult)
        
        return TextInputResponse(
            processedText: processedText,
            validationResult: validationResult,
            suggestions: suggestions
        )
    }
}

final class ValidateTextUseCase: ValidateTextUseCaseProtocol {
    private let validationService: TextValidationService
    
    init(validationService: TextValidationService) {
        self.validationService = validationService
    }
    
    func execute(input: String) async throws -> ValidationResult {
        return validationService.validate(input)
    }
}

final class RecognizeHandwritingUseCase: RecognizeHandwritingUseCaseProtocol {
    private let handwritingRecognizer: HandwritingRecognizer
    
    init(handwritingRecognizer: HandwritingRecognizer) {
        self.handwritingRecognizer = handwritingRecognizer
    }
    
    func execute(input: HandwritingRequest) async throws -> RecognitionResult {
        return try await handwritingRecognizer.recognize(drawingData: input.drawingData)
    }
}

// MARK: - Speech Recognition Use Cases

final class StartSpeechRecognitionUseCase: StartSpeechRecognitionUseCaseProtocol {
    private let speechRecognitionManager: SpeechRecognitionProtocol
    
    init(speechRecognitionManager: SpeechRecognitionProtocol) {
        self.speechRecognitionManager = speechRecognitionManager
    }
    
    func execute(input: SpeechRecognitionRequest) async throws -> Void {
        try await speechRecognitionManager.startRecognition(
            for: input.originalText,
            locale: input.locale,
            userId: input.userId
        )
    }
}

final class ProcessSpeechUseCase: ProcessSpeechUseCaseProtocol {
    private let speechRecognitionManager: SpeechRecognitionProtocol
    private let audioProcessor: AudioProcessingService
    
    init(speechRecognitionManager: SpeechRecognitionProtocol, audioProcessor: AudioProcessingService) {
        self.speechRecognitionManager = speechRecognitionManager
        self.audioProcessor = audioProcessor
    }
    
    func execute(input: SpeechProcessingRequest) async throws -> SpeechProcessingResponse {
        let startTime = Date()
        
        // Process audio data
        let processedAudio = try await audioProcessor.processAudio(input.audioData)
        
        // Recognize speech
        let recognizedText = try await speechRecognitionManager.recognizeSpeech(from: processedAudio)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return SpeechProcessingResponse(
            recognizedText: recognizedText,
            confidence: speechRecognitionManager.currentConfidence,
            processingTime: processingTime
        )
    }
}

final class CompareTextsUseCase: CompareTextsUseCaseProtocol {
    private let textComparator: TextComparisonProtocol
    
    init(textComparator: TextComparisonProtocol) {
        self.textComparator = textComparator
    }
    
    func execute(input: TextComparisonRequest) async throws -> ComparisonResult {
        return textComparator.compareTexts(original: input.originalText, spoken: input.spokenText)
    }
}

// MARK: - Scoring Use Cases

final class CalculateScoreUseCase: CalculateScoreUseCaseProtocol {
    private let scoreCalculator: ScoringProtocol
    private let userScoreRepository: UserScoreRepositoryProtocol
    
    init(scoreCalculator: ScoringProtocol, userScoreRepository: UserScoreRepositoryProtocol) {
        self.scoreCalculator = scoreCalculator
        self.userScoreRepository = userScoreRepository
    }
    
    func execute(input: ScoreCalculationRequest) async throws -> ScoreCalculationResponse {
        // Get user's current streak and stats
        let userStats = try await userScoreRepository.getUserStats(userId: input.userId)
        
        // Calculate score using the scoring protocol
        let scoreResult = scoreCalculator.calculateScore(
            accuracy: input.accuracy,
            attempts: input.attempts,
            difficulty: input.difficulty,
            timeSpent: input.timeSpent,
            userStats: userStats
        )
        
        return ScoreCalculationResponse(
            baseScore: scoreResult.baseScore,
            bonusPoints: scoreResult.bonusPoints,
            totalScore: scoreResult.totalScore,
            multiplier: scoreResult.multiplier,
            breakdown: scoreResult.breakdown
        )
    }
}

final class UpdateUserScoreUseCase: UpdateUserScoreUseCaseProtocol {
    private let userScoreRepository: UserScoreRepositoryProtocol
    private let achievementManager: AchievementManager
    
    init(userScoreRepository: UserScoreRepositoryProtocol, achievementManager: AchievementManager) {
        self.userScoreRepository = userScoreRepository
        self.achievementManager = achievementManager
    }
    
    func execute(input: UserScoreUpdateRequest) async throws -> UserScore {
        // Update user score
        let updatedScore = try await userScoreRepository.updateScore(
            userId: input.userId,
            sessionScore: input.sessionScore,
            accuracy: input.accuracy,
            exerciseId: input.exerciseId
        )
        
        // Check for achievements
        let sessionResult = SessionResult(
            userId: input.userId,
            exerciseId: input.exerciseId,
            originalText: "", // This would come from the exercise
            spokenText: "", // This would come from speech recognition
            accuracy: input.accuracy,
            score: input.sessionScore,
            timeSpent: 0, // This would come from the session
            mistakes: [], // This would come from text comparison
            completedAt: Date(),
            difficulty: .grade1, // This would come from the exercise
            inputMethod: .keyboard // This would come from the session
        )
        
        let userStats = try await userScoreRepository.getUserStats(userId: input.userId)
        let achievements = await achievementManager.checkAchievements(
            for: sessionResult,
            userStats: userStats
        )
        
        // Update achievements if any were unlocked
        if !achievements.isEmpty {
            try await userScoreRepository.addAchievements(achievements, for: input.userId)
        }
        
        return updatedScore
    }
}

final class CheckAchievementsUseCase: CheckAchievementsUseCaseProtocol {
    private let achievementManager: AchievementManager
    
    init(achievementManager: AchievementManager) {
        self.achievementManager = achievementManager
    }
    
    func execute(input: AchievementCheckRequest) async throws -> [Achievement] {
        return await achievementManager.checkAchievements(
            for: input.sessionResult,
            userStats: input.userStats
        )
    }
}

// MARK: - User Management Use Cases

final class CreateUserUseCase: CreateUserUseCaseProtocol {
    private let userProfileRepository: UserProfileRepositoryProtocol
    
    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository
    }
    
    func execute(input: CreateUserRequest) async throws -> UserProfile {
        let userProfile = UserProfile(
            id: UUID().uuidString,
            name: input.name,
            grade: Int16(input.grade),
            parentEmail: input.parentEmail,
            createdAt: Date(),
            lastSessionDate: nil,
            totalScore: 0,
            completedExercises: 0,
            totalTimeSpent: 0,
            averageAccuracy: 0,
            currentStreak: 0,
            bestStreak: 0
        )
        
        return try await userProfileRepository.createUser(userProfile)
    }
}

final class GetUserProgressUseCase: GetUserProgressUseCaseProtocol {
    private let progressRepository: ProgressRepositoryProtocol
    private let userScoreRepository: UserScoreRepositoryProtocol
    
    init(progressRepository: ProgressRepositoryProtocol, userScoreRepository: UserScoreRepositoryProtocol) {
        self.progressRepository = progressRepository
        self.userScoreRepository = userScoreRepository
    }
    
    func execute(input: UserProgressRequest) async throws -> UserProgress {
        let userStats = try await userScoreRepository.getUserStats(userId: input.userId)
        let dailyProgress = try await progressRepository.getDailyProgress(userId: input.userId, date: input.date)
        let weeklyProgress = try await progressRepository.getWeeklyProgress(userId: input.userId, weekOf: input.date)
        
        return UserProgress(
            userId: input.userId,
            date: input.date,
            dailyProgress: dailyProgress,
            weeklyProgress: weeklyProgress,
            userStats: userStats,
            goals: input.goals
        )
    }
}

final class UpdateUserProgressUseCase: UpdateUserProgressUseCaseProtocol {
    private let progressRepository: ProgressRepositoryProtocol
    
    init(progressRepository: ProgressRepositoryProtocol) {
        self.progressRepository = progressRepository
    }
    
    func execute(input: ProgressUpdateRequest) async throws -> UserProgress {
        return try await progressRepository.updateProgress(
            userId: input.userId,
            sessionResult: input.sessionResult,
            goals: input.goals
        )
    }
}

// MARK: - Exercise Management Use Cases

final class GetExerciseUseCase: GetExerciseUseCaseProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }
    
    func execute(input: ExerciseRequest) async throws -> Exercise {
        return try await exerciseRepository.getExercise(id: input.exerciseId)
    }
}

final class CreateExerciseUseCase: CreateExerciseUseCaseProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }
    
    func execute(input: CreateExerciseRequest) async throws -> Exercise {
        let exercise = Exercise(
            id: UUID(),
            title: input.title,
            targetText: input.targetText,
            category: input.category,
            difficulty: input.difficulty,
            tags: input.tags,
            createdAt: Date()
        )
        
        return try await exerciseRepository.createExercise(exercise)
    }
}

final class GetExerciseListUseCase: GetExerciseListUseCaseProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }
    
    func execute(input: ExerciseListRequest) async throws -> [Exercise] {
        return try await exerciseRepository.getExercises(
            category: input.category,
            difficulty: input.difficulty,
            limit: input.limit
        )
    }
}

// MARK: - Supporting Services

final class TextValidationService {
    func validate(_ text: String) -> ValidationResult {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let isValid = !words.isEmpty && words.allSatisfy { $0.count >= 2 }
        
        let mistakes = words.enumerated().compactMap { index, word in
            word.count < 2 ? TextMistake(
                id: UUID(),
                expectedWord: word,
                actualWord: word,
                mistakeType: .omission,
                position: Int32(index),
                severity: .minor
            ) : nil
        }
        
        return ValidationResult(
            isValid: isValid,
            mistakes: mistakes,
            suggestions: generateSuggestions(for: text, mistakes: mistakes)
        )
    }
    
    func generateSuggestions(for text: String, validationResult: ValidationResult) -> [String] {
        // Generate suggestions based on validation results
        var suggestions: [String] = []
        
        if text.isEmpty {
            suggestions.append("Hãy nhập văn bản để luyện tập")
        }
        
        if validationResult.mistakes.contains(where: { $0.mistakeType == .omission }) {
            suggestions.append("Hãy kiểm tra lại các từ bị thiếu")
        }
        
        return suggestions
    }
    
    private func generateSuggestions(for text: String, mistakes: [TextMistake]) -> [String] {
        // Implementation for generating suggestions based on mistakes
        return []
    }
}

final class AudioProcessingService {
    func processAudio(_ audioData: Data) async throws -> Data {
        // Process audio data for better speech recognition
        // This is a simplified implementation
        return audioData
    }
}

// MARK: - Supporting Models

struct TextMistake: Codable, Hashable {
    let id: UUID
    let expectedWord: String
    let actualWord: String
    let mistakeType: MistakeType
    let position: Int32
    let severity: MistakeSeverity
}

enum MistakeType: String, Codable, CaseIterable {
    case substitution = "substitution"
    case omission = "omission"
    case insertion = "insertion"
    case pronunciation = "pronunciation"
}

enum MistakeSeverity: String, Codable, CaseIterable {
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
}

struct ValidationResult: Codable {
    let isValid: Bool
    let mistakes: [TextMistake]
    let suggestions: [String]
}

struct RecognitionResult: Codable {
    let recognizedText: String
    let confidence: Float
    let processingTime: TimeInterval
}

struct UserProgress: Codable {
    let userId: String
    let date: Date
    let dailyProgress: DailyProgress
    let weeklyProgress: WeeklyProgress
    let userStats: UserSessionStats
    let goals: LearningGoals
}

struct DailyProgress: Codable {
    let date: Date
    let sessionsCompleted: Int
    let timeSpent: TimeInterval
    let averageAccuracy: Float
    let scoreEarned: Int
}

struct WeeklyProgress: Codable {
    let weekOf: Date
    let totalSessions: Int
    let totalTime: TimeInterval
    let averageAccuracy: Float
    let totalScore: Int
    let streakDays: Int
}

struct LearningGoals: Codable {
    let dailySessionGoal: Int
    let dailyTimeGoal: TimeInterval
    let accuracyGoal: Float
    let streakGoal: Int
}

struct UserSessionStats: Codable {
    let totalSessions: Int
    let totalScore: Int
    let averageAccuracy: Float
    let currentStreak: Int
    let bestStreak: Int
    let totalTimeSpent: TimeInterval
}
