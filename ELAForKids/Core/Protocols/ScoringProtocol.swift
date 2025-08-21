import Foundation

// MARK: - Scoring Protocol
protocol ScoringProtocol {
    /// Calculate score based on accuracy, attempts, and difficulty
    func calculateScore(accuracy: Float, attempts: Int, difficulty: DifficultyLevel) -> Int
    
    /// Calculate bonus points for streaks and perfect scores
    func calculateBonusPoints(streak: Int, perfectScore: Bool, timeBonus: TimeBonus?) -> Int
    
    /// Update user's total score
    func updateUserScore(userId: String, score: Int) async throws
    
    /// Get user's current total score
    func getUserScore(userId: String) async throws -> Int
    
    /// Get leaderboard with top users
    func getLeaderboard(limit: Int) async throws -> [UserScore]
    
    /// Get user's ranking position
    func getUserRanking(userId: String) async throws -> Int
    
    /// Calculate score multiplier based on difficulty
    func getDifficultyMultiplier(difficulty: DifficultyLevel) -> Float
    
    /// Calculate time bonus based on completion time
    func calculateTimeBonus(completionTime: TimeInterval, targetTime: TimeInterval) -> TimeBonus?
}

// MARK: - Data Models

/// User score information
struct UserScore: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let totalScore: Int
    let level: Int
    let experience: Int
    let streak: Int
    let lastUpdated: Date
    let achievements: [String] // Achievement IDs
    
    /// Current level progress (0.0 to 1.0)
    var levelProgress: Float {
        let experienceForCurrentLevel = experienceRequiredForLevel(level)
        let experienceForNextLevel = experienceRequiredForLevel(level + 1)
        let currentLevelExperience = experience - experienceForCurrentLevel
        let experienceNeeded = experienceForNextLevel - experienceForCurrentLevel
        
        return Float(currentLevelExperience) / Float(experienceNeeded)
    }
    
    /// Experience required for a specific level
    private func experienceRequiredForLevel(_ level: Int) -> Int {
        // Exponential growth: level 1 = 100, level 2 = 250, level 3 = 450, etc.
        return level == 0 ? 0 : 100 * level + 50 * (level - 1) * level
    }
}

/// Difficulty levels for exercises
enum DifficultyLevel: String, CaseIterable, Codable {
    case grade1 = "grade1"
    case grade2 = "grade2"
    case grade3 = "grade3"
    case grade4 = "grade4"
    case grade5 = "grade5"
    
    var localizedName: String {
        switch self {
        case .grade1:
            return "Lớp 1"
        case .grade2:
            return "Lớp 2"
        case .grade3:
            return "Lớp 3"
        case .grade4:
            return "Lớp 4"
        case .grade5:
            return "Lớp 5"
        }
    }
    
    var baseScore: Int {
        switch self {
        case .grade1:
            return 100
        case .grade2:
            return 150
        case .grade3:
            return 200
        case .grade4:
            return 250
        case .grade5:
            return 300
        }
    }
    
    var multiplier: Float {
        switch self {
        case .grade1:
            return 1.0
        case .grade2:
            return 1.2
        case .grade3:
            return 1.4
        case .grade4:
            return 1.6
        case .grade5:
            return 1.8
        }
    }
    
    var targetTimeSeconds: TimeInterval {
        switch self {
        case .grade1:
            return 60  // 1 minute
        case .grade2:
            return 90  // 1.5 minutes
        case .grade3:
            return 120 // 2 minutes
        case .grade4:
            return 150 // 2.5 minutes
        case .grade5:
            return 180 // 3 minutes
        }
    }
}

/// Score category based on performance
enum ScoreCategory: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case needsImprovement = "needsImprovement"
    
    var localizedName: String {
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
    
    var emoji: String {
        switch self {
        case .excellent:
            return "🌟"
        case .good:
            return "👏"
        case .fair:
            return "😊"
        case .needsImprovement:
            return "💪"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .needsImprovement:
            return "red"
        }
    }
    
    static func from(accuracy: Float) -> ScoreCategory {
        switch accuracy {
        case 0.95...1.0:
            return .excellent
        case 0.85..<0.95:
            return .good
        case 0.70..<0.85:
            return .fair
        default:
            return .needsImprovement
        }
    }
}

/// Time bonus information
struct TimeBonus: Codable {
    let bonusPoints: Int
    let completionTime: TimeInterval
    let targetTime: TimeInterval
    let bonusPercentage: Float
    
    var description: String {
        let timeSaved = targetTime - completionTime
        return "Hoàn thành nhanh hơn \(Int(timeSaved))s: +\(bonusPoints) điểm"
    }
}

/// Streak bonus information
struct StreakBonus: Codable {
    let streakCount: Int
    let bonusPoints: Int
    let multiplier: Float
    
    var description: String {
        return "Chuỗi \(streakCount) lần đúng: +\(bonusPoints) điểm"
    }
}

/// Complete scoring result
struct ScoringResult: Codable {
    let baseScore: Int
    let accuracyScore: Int
    let difficultyBonus: Int
    let timeBonus: TimeBonus?
    let streakBonus: StreakBonus?
    let perfectScoreBonus: Int
    let attemptPenalty: Int
    let finalScore: Int
    let category: ScoreCategory
    let experience: Int
    
    /// Total bonus points
    var totalBonus: Int {
        let timeBonusPoints = timeBonus?.bonusPoints ?? 0
        let streakBonusPoints = streakBonus?.bonusPoints ?? 0
        return difficultyBonus + timeBonusPoints + streakBonusPoints + perfectScoreBonus
    }
    
    /// Breakdown description for UI
    var breakdown: [String] {
        var items: [String] = []
        
        items.append("Điểm cơ bản: \(baseScore)")
        items.append("Độ chính xác: \(accuracyScore)")
        
        if difficultyBonus > 0 {
            items.append("Độ khó: +\(difficultyBonus)")
        }
        
        if let timeBonus = timeBonus {
            items.append(timeBonus.description)
        }
        
        if let streakBonus = streakBonus {
            items.append(streakBonus.description)
        }
        
        if perfectScoreBonus > 0 {
            items.append("Hoàn hảo: +\(perfectScoreBonus)")
        }
        
        if attemptPenalty > 0 {
            items.append("Thử lại: -\(attemptPenalty)")
        }
        
        return items
    }
}

/// Session result with scoring information
struct SessionResult: Codable, Identifiable {
    let id: UUID
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
    let attempts: Int
    let scoringResult: ScoringResult?
    let comparisonResult: ComparisonResult?
    
    init(
        userId: String,
        exerciseId: UUID,
        originalText: String,
        spokenText: String,
        accuracy: Float,
        score: Int,
        timeSpent: TimeInterval,
        mistakes: [TextMistake],
        completedAt: Date,
        difficulty: DifficultyLevel,
        inputMethod: InputMethod,
        attempts: Int = 1,
        scoringResult: ScoringResult? = nil,
        comparisonResult: ComparisonResult? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.exerciseId = exerciseId
        self.originalText = originalText
        self.spokenText = spokenText
        self.accuracy = accuracy
        self.score = score
        self.timeSpent = timeSpent
        self.mistakes = mistakes
        self.completedAt = completedAt
        self.difficulty = difficulty
        self.inputMethod = inputMethod
        self.attempts = attempts
        self.scoringResult = scoringResult
        self.comparisonResult = comparisonResult
    }
}

/// Input method used for the exercise
enum InputMethod: String, CaseIterable, Codable {
    case keyboard = "keyboard"
    case pencil = "pencil"
    case voice = "voice"
    
    var localizedName: String {
        switch self {
        case .keyboard:
            return "Bàn phím"
        case .pencil:
            return "Apple Pencil"
        case .voice:
            return "Giọng nói"
        }
    }
    
    var icon: String {
        switch self {
        case .keyboard:
            return "keyboard"
        case .pencil:
            return "pencil.tip"
        case .voice:
            return "mic.fill"
        }
    }
}