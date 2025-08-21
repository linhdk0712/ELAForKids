import Foundation

// MARK: - Score Calculator
final class ScoreCalculator: ScoringProtocol {
    
    // MARK: - Properties
    private let userScoreRepository: UserScoreRepositoryProtocol
    private let streakManager: StreakManagerProtocol
    
    // Scoring constants
    private let maxScore = 1000
    private let perfectScoreBonusPoints = 100
    private let streakBonusMultiplier: Float = 0.1
    private let attemptPenaltyPercentage: Float = 0.15
    private let timeBonusThreshold: Float = 0.8 // Must complete in 80% of target time
    
    init(
        userScoreRepository: UserScoreRepositoryProtocol,
        streakManager: StreakManagerProtocol
    ) {
        self.userScoreRepository = userScoreRepository
        self.streakManager = streakManager
    }
    
    // MARK: - ScoringProtocol Implementation
    
    func calculateScore(accuracy: Float, attempts: Int, difficulty: DifficultyLevel) -> Int {
        let baseScore = difficulty.baseScore
        let accuracyScore = Int(Float(baseScore) * accuracy)
        let difficultyBonus = Int(Float(baseScore) * (difficulty.multiplier - 1.0))
        
        // Apply attempt penalty
        let attemptPenalty = attempts > 1 ? Int(Float(accuracyScore) * attemptPenaltyPercentage * Float(attempts - 1)) : 0
        
        let finalScore = max(0, accuracyScore + difficultyBonus - attemptPenalty)
        return min(finalScore, maxScore)
    }
    
    func calculateBonusPoints(streak: Int, perfectScore: Bool, timeBonus: TimeBonus?) -> Int {
        var bonusPoints = 0
        
        // Perfect score bonus
        if perfectScore {
            bonusPoints += perfectScoreBonusPoints
        }
        
        // Streak bonus
        if streak > 1 {
            bonusPoints += Int(Float(streak) * streakBonusMultiplier * 100)
        }
        
        // Time bonus
        if let timeBonus = timeBonus {
            bonusPoints += timeBonus.bonusPoints
        }
        
        return bonusPoints
    }
    
    func updateUserScore(userId: String, score: Int) async throws {
        try await userScoreRepository.updateScore(userId: userId, additionalScore: score)
    }
    
    func getUserScore(userId: String) async throws -> Int {
        let userScore = try await userScoreRepository.getUserScore(userId: userId)
        return userScore.totalScore
    }
    
    func getLeaderboard(limit: Int) async throws -> [UserScore] {
        return try await userScoreRepository.getTopUsers(limit: limit)
    }
    
    func getUserRanking(userId: String) async throws -> Int {
        return try await userScoreRepository.getUserRanking(userId: userId)
    }
    
    func getDifficultyMultiplier(difficulty: DifficultyLevel) -> Float {
        return difficulty.multiplier
    }
    
    func calculateTimeBonus(completionTime: TimeInterval, targetTime: TimeInterval) -> TimeBonus? {
        guard completionTime < targetTime * TimeInterval(timeBonusThreshold) else {
            return nil
        }
        
        let timeSaved = targetTime - completionTime
        let bonusPercentage = Float(timeSaved / targetTime)
        let bonusPoints = Int(bonusPercentage * 200) // Max 200 bonus points
        
        return TimeBonus(
            bonusPoints: bonusPoints,
            completionTime: completionTime,
            targetTime: targetTime,
            bonusPercentage: bonusPercentage
        )
    }
    
    // MARK: - Advanced Scoring Methods
    
    /// Calculate comprehensive scoring result with all bonuses and penalties
    func calculateComprehensiveScore(
        accuracy: Float,
        attempts: Int,
        difficulty: DifficultyLevel,
        completionTime: TimeInterval,
        streak: Int,
        mistakes: [TextMistake]
    ) -> ScoringResult {
        
        // Base calculations
        let baseScore = difficulty.baseScore
        let accuracyScore = Int(Float(baseScore) * accuracy)
        let difficultyBonus = Int(Float(baseScore) * (difficulty.multiplier - 1.0))
        
        // Time bonus
        let timeBonus = calculateTimeBonus(
            completionTime: completionTime,
            targetTime: difficulty.targetTimeSeconds
        )
        
        // Perfect score check
        let isPerfectScore = accuracy >= 1.0 && mistakes.isEmpty
        let perfectScoreBonus = isPerfectScore ? perfectScoreBonusPoints : 0
        
        // Streak bonus
        let streakBonus = streak > 1 ? StreakBonus(
            streakCount: streak,
            bonusPoints: Int(Float(streak) * streakBonusMultiplier * 100),
            multiplier: streakBonusMultiplier
        ) : nil
        
        // Attempt penalty
        let attemptPenalty = attempts > 1 ? Int(Float(accuracyScore) * attemptPenaltyPercentage * Float(attempts - 1)) : 0
        
        // Calculate final score
        let totalBonus = difficultyBonus + (timeBonus?.bonusPoints ?? 0) + (streakBonus?.bonusPoints ?? 0) + perfectScoreBonus
        let finalScore = max(0, accuracyScore + totalBonus - attemptPenalty)
        let clampedScore = min(finalScore, maxScore)
        
        // Calculate experience points (same as score but with different scaling)
        let experience = Int(Float(clampedScore) * 1.5)
        
        return ScoringResult(
            baseScore: baseScore,
            accuracyScore: accuracyScore,
            difficultyBonus: difficultyBonus,
            timeBonus: timeBonus,
            streakBonus: streakBonus,
            perfectScoreBonus: perfectScoreBonus,
            attemptPenalty: attemptPenalty,
            finalScore: clampedScore,
            category: ScoreCategory.from(accuracy: accuracy),
            experience: experience
        )
    }
    
    /// Calculate score with mistake severity consideration
    func calculateScoreWithMistakeSeverity(
        accuracy: Float,
        mistakes: [TextMistake],
        difficulty: DifficultyLevel,
        attempts: Int
    ) -> Int {
        let baseScore = calculateScore(accuracy: accuracy, attempts: attempts, difficulty: difficulty)
        
        // Apply mistake severity penalties
        var severityPenalty = 0
        for mistake in mistakes {
            switch mistake.severity {
            case .minor:
                severityPenalty += 5
            case .moderate:
                severityPenalty += 15
            case .major:
                severityPenalty += 30
            }
        }
        
        return max(0, baseScore - severityPenalty)
    }
    
    /// Calculate adaptive score based on user's historical performance
    func calculateAdaptiveScore(
        accuracy: Float,
        attempts: Int,
        difficulty: DifficultyLevel,
        userAverageAccuracy: Float
    ) -> Int {
        let baseScore = calculateScore(accuracy: accuracy, attempts: attempts, difficulty: difficulty)
        
        // Bonus for improvement over personal average
        if accuracy > userAverageAccuracy {
            let improvementBonus = Int((accuracy - userAverageAccuracy) * 200)
            return baseScore + improvementBonus
        }
        
        return baseScore
    }
}

// MARK: - Streak Manager Protocol
protocol StreakManagerProtocol {
    func updateStreak(userId: String, isSuccess: Bool) async throws -> Int
    func getCurrentStreak(userId: String) async throws -> Int
    func resetStreak(userId: String) async throws
}

// MARK: - User Score Repository Protocol
protocol UserScoreRepositoryProtocol {
    func getUserScore(userId: String) async throws -> UserScore
    func updateScore(userId: String, additionalScore: Int) async throws
    func getTopUsers(limit: Int) async throws -> [UserScore]
    func getUserRanking(userId: String) async throws -> Int
    func createUserScore(userId: String, userName: String) async throws -> UserScore
}

// MARK: - Score Validation
extension ScoreCalculator {
    
    /// Validate scoring parameters
    func validateScoringParameters(
        accuracy: Float,
        attempts: Int,
        difficulty: DifficultyLevel,
        completionTime: TimeInterval
    ) throws {
        guard accuracy >= 0.0 && accuracy <= 1.0 else {
            throw ScoringError.invalidAccuracy
        }
        
        guard attempts >= 1 else {
            throw ScoringError.invalidAttempts
        }
        
        guard completionTime > 0 else {
            throw ScoringError.invalidCompletionTime
        }
    }
    
    /// Check if score is within valid range
    func isValidScore(_ score: Int) -> Bool {
        return score >= 0 && score <= maxScore
    }
}

// MARK: - Scoring Errors
enum ScoringError: LocalizedError {
    case invalidAccuracy
    case invalidAttempts
    case invalidCompletionTime
    case userNotFound
    case scoringCalculationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAccuracy:
            return "Độ chính xác phải từ 0.0 đến 1.0"
        case .invalidAttempts:
            return "Số lần thử phải lớn hơn 0"
        case .invalidCompletionTime:
            return "Thời gian hoàn thành phải lớn hơn 0"
        case .userNotFound:
            return "Không tìm thấy người dùng"
        case .scoringCalculationFailed:
            return "Lỗi tính toán điểm số"
        }
    }
}

// MARK: - Score Analytics
extension ScoreCalculator {
    
    /// Calculate performance trends
    func calculatePerformanceTrend(
        recentSessions: [SessionResult]
    ) -> PerformanceTrend {
        guard !recentSessions.isEmpty else {
            return PerformanceTrend(trend: .stable, changePercentage: 0.0)
        }
        
        let sortedSessions = recentSessions.sorted { $0.completedAt < $1.completedAt }
        
        if sortedSessions.count < 2 {
            return PerformanceTrend(trend: .stable, changePercentage: 0.0)
        }
        
        let firstHalf = Array(sortedSessions.prefix(sortedSessions.count / 2))
        let secondHalf = Array(sortedSessions.suffix(sortedSessions.count / 2))
        
        let firstHalfAverage = firstHalf.map { $0.accuracy }.reduce(0, +) / Float(firstHalf.count)
        let secondHalfAverage = secondHalf.map { $0.accuracy }.reduce(0, +) / Float(secondHalf.count)
        
        let changePercentage = (secondHalfAverage - firstHalfAverage) / firstHalfAverage
        
        let trend: TrendDirection
        if changePercentage > 0.05 {
            trend = .improving
        } else if changePercentage < -0.05 {
            trend = .declining
        } else {
            trend = .stable
        }
        
        return PerformanceTrend(trend: trend, changePercentage: changePercentage)
    }
}

// MARK: - Performance Trend
struct PerformanceTrend {
    let trend: TrendDirection
    let changePercentage: Float
    
    var description: String {
        switch trend {
        case .improving:
            return "Đang tiến bộ (+\(Int(changePercentage * 100))%)"
        case .declining:
            return "Cần cải thiện (\(Int(changePercentage * 100))%)"
        case .stable:
            return "Ổn định"
        }
    }
    
    var emoji: String {
        switch trend {
        case .improving:
            return "📈"
        case .declining:
            return "📉"
        case .stable:
            return "➡️"
        }
    }
}

enum TrendDirection {
    case improving
    case declining
    case stable
}