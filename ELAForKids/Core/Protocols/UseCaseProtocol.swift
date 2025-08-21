import Foundation
import Combine

// MARK: - Base Use Case Protocol
protocol UseCaseProtocol {
    associatedtype Input
    associatedtype Output
    
    func execute(input: Input) async throws -> Output
}

// MARK: - Text Input Use Cases
protocol ProcessTextInputUseCaseProtocol: UseCaseProtocol where Input == TextInputRequest, Output == TextInputResponse {
}

protocol ValidateTextUseCaseProtocol: UseCaseProtocol where Input == String, Output == ValidationResult {
}

protocol RecognizeHandwritingUseCaseProtocol: UseCaseProtocol where Input == HandwritingRequest, Output == RecognitionResult {
}

// MARK: - Speech Recognition Use Cases
protocol StartSpeechRecognitionUseCaseProtocol: UseCaseProtocol where Input == SpeechRecognitionRequest, Output == Void {
}

protocol ProcessSpeechUseCaseProtocol: UseCaseProtocol where Input == SpeechProcessingRequest, Output == SpeechProcessingResponse {
}

protocol CompareTextsUseCaseProtocol: UseCaseProtocol where Input == TextComparisonRequest, Output == ComparisonResult {
}

// MARK: - Scoring Use Cases
protocol CalculateScoreUseCaseProtocol: UseCaseProtocol where Input == ScoreCalculationRequest, Output == ScoreCalculationResponse {
}

protocol UpdateUserScoreUseCaseProtocol: UseCaseProtocol where Input == UserScoreUpdateRequest, Output == UserScore {
}

protocol CheckAchievementsUseCaseProtocol: UseCaseProtocol where Input == AchievementCheckRequest, Output == [Achievement] {
}

// MARK: - User Management Use Cases
protocol CreateUserUseCaseProtocol: UseCaseProtocol where Input == CreateUserRequest, Output == UserProfile {
}

protocol GetUserProgressUseCaseProtocol: UseCaseProtocol where Input == UserProgressRequest, Output == UserProgress {
}

protocol UpdateUserProgressUseCaseProtocol: UseCaseProtocol where Input == ProgressUpdateRequest, Output == UserProgress {
}

// MARK: - Exercise Management Use Cases
protocol GetExerciseUseCaseProtocol: UseCaseProtocol where Input == ExerciseRequest, Output == Exercise {
}

protocol CreateExerciseUseCaseProtocol: UseCaseProtocol where Input == CreateExerciseRequest, Output == Exercise {
}

protocol GetExerciseListUseCaseProtocol: UseCaseProtocol where Input == ExerciseListRequest, Output == [Exercise] {
}

// MARK: - Request/Response Models

// Text Input
struct TextInputRequest {
    let text: String
    let inputMethod: InputMethod
    let userId: String
}

struct TextInputResponse {
    let processedText: String
    let validationResult: ValidationResult
    let suggestions: [String]
}

struct HandwritingRequest {
    let drawingData: Data
    let userId: String
}

// Speech Recognition
struct SpeechRecognitionRequest {
    let userId: String
    let originalText: String
    let locale: Locale
}

struct SpeechProcessingRequest {
    let audioData: Data
    let originalText: String
    let userId: String
}

struct SpeechProcessingResponse {
    let recognizedText: String
    let confidence: Float
    let processingTime: TimeInterval
}

struct TextComparisonRequest {
    let originalText: String
    let spokenText: String
    let userId: String
}

// Scoring
struct ScoreCalculationRequest {
    let accuracy: Float
    let attempts: Int
    let difficulty: DifficultyLevel
    let timeSpent: TimeInterval
    let userId: String
}

struct ScoreCalculationResponse {
    let baseScore: Int
    let bonusPoints: Int
    let totalScore: Int
    let multiplier: Float
    let breakdown: ScoreBreakdown
}

struct ScoreBreakdown {
    let accuracyPoints: Int
    let speedBonus: Int
    let difficultyBonus: Int
    let streakBonus: Int
    let perfectBonus: Int
}

struct UserScoreUpdateRequest {
    let userId: String
    let sessionScore: Int
    let accuracy: Float
    let exerciseId: UUID
}

struct AchievementCheckRequest {
    let userId: String
    let sessionResult: SessionResult
    let userStats: UserSessionStats
}

// User Management
struct CreateUserRequest {
    let name: String
    let grade: Int
    let parentEmail: String?
}

struct UserProgressRequest {
    let userId: String
    let period: ProgressPeriod
}

struct ProgressUpdateRequest {
    let userId: String
    let sessionResult: SessionResult
}

// Exercise Management
struct ExerciseRequest {
    let difficulty: DifficultyLevel?
    let category: ExerciseCategory?
    let random: Bool
}

struct CreateExerciseRequest {
    let title: String
    let targetText: String
    let difficulty: DifficultyLevel
    let category: ExerciseCategory
    let tags: [String]
}

struct ExerciseListRequest {
    let difficulty: DifficultyLevel?
    let category: ExerciseCategory?
    let limit: Int?
    let offset: Int?
}

// MARK: - Exercise Category
enum ExerciseCategory: String, CaseIterable, Codable {
    case story = "story"
    case poem = "poem"
    case dialogue = "dialogue"
    case description = "description"
    case instruction = "instruction"
    case news = "news"
    
    var displayName: String {
        switch self {
        case .story:
            return "Truyện"
        case .poem:
            return "Thơ"
        case .dialogue:
            return "Hội thoại"
        case .description:
            return "Mô tả"
        case .instruction:
            return "Hướng dẫn"
        case .news:
            return "Tin tức"
        }
    }
    
    var icon: String {
        switch self {
        case .story:
            return "book.closed"
        case .poem:
            return "quote.bubble"
        case .dialogue:
            return "bubble.left.and.bubble.right"
        case .description:
            return "text.alignleft"
        case .instruction:
            return "list.bullet"
        case .news:
            return "newspaper"
        }
    }
}

// MARK: - Session Result
struct SessionResult: Codable, Hashable {
    let id = UUID()
    let userId: String
    let exerciseId: UUID
    let originalText: String
    let spokenText: String
    let accuracy: Float
    let score: Int
    let timeSpent: TimeInterval
    let mistakes: [TextMistake]
    let completedAt: Date
    let difficulty: DifficultyLevel
    let inputMethod: InputMethod
    
    var isExcellent: Bool { accuracy >= 0.9 }
    var isGood: Bool { accuracy >= 0.7 }
    var isPerfect: Bool { accuracy == 1.0 }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SessionResult, rhs: SessionResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Use Case Error
enum UseCaseError: LocalizedError {
    case invalidInput(String)
    case processingFailed(String)
    case permissionDenied(String)
    case resourceUnavailable(String)
    case networkError(String)
    case dataCorrupted(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let details):
            return "Dữ liệu đầu vào không hợp lệ: \(details)"
        case .processingFailed(let details):
            return "Xử lý thất bại: \(details)"
        case .permissionDenied(let details):
            return "Không có quyền: \(details)"
        case .resourceUnavailable(let details):
            return "Tài nguyên không khả dụng: \(details)"
        case .networkError(let details):
            return "Lỗi mạng: \(details)"
        case .dataCorrupted(let details):
            return "Dữ liệu bị hỏng: \(details)"
        }
    }
}

// MARK: - Use Case Result
enum UseCaseResult<T> {
    case success(T)
    case failure(UseCaseError)
    
    var value: T? {
        if case .success(let value) = self { return value }
        return nil
    }
    
    var error: UseCaseError? {
        if case .failure(let error) = self { return error }
        return nil
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}