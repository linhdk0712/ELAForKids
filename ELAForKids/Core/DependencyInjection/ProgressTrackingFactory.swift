import Foundation

// MARK: - Progress Tracking Factory
final class ProgressTrackingFactory {
    
    // MARK: - Shared Instance
    static let shared = ProgressTrackingFactory()
    
    // MARK: - Properties
    private let persistenceController: PersistenceController
    private lazy var progressRepository: ProgressRepositoryProtocol = {
        return ProgressRepository(coreDataStack: persistenceController)
    }()
    
    private lazy var userScoreRepository: UserScoreRepositoryProtocol = {
        return UserScoreRepository(coreDataStack: persistenceController)
    }()
    
    private lazy var streakManager: StreakManagerProtocol = {
        return StreakManager()
    }()
    
    private lazy var analyticsEngine: AnalyticsEngineProtocol = {
        return AnalyticsEngine(
            progressRepository: progressRepository,
            userScoreRepository: userScoreRepository
        )
    }()
    
    private lazy var progressTracker: ProgressTrackingProtocol = {
        return ProgressTracker(
            progressRepository: progressRepository,
            userScoreRepository: userScoreRepository,
            streakManager: streakManager,
            analyticsEngine: analyticsEngine
        )
    }()
    
    // MARK: - Initialization
    private init() {
        self.persistenceController = PersistenceController.shared
    }
    
    // MARK: - Factory Methods
    
    /// Get the main progress tracker instance
    func getProgressTracker() -> ProgressTrackingProtocol {
        return progressTracker
    }
    
    /// Get progress repository instance
    func getProgressRepository() -> ProgressRepositoryProtocol {
        return progressRepository
    }
    
    /// Get user score repository instance
    func getUserScoreRepository() -> UserScoreRepositoryProtocol {
        return userScoreRepository
    }
    
    /// Get streak manager instance
    func getStreakManager() -> StreakManagerProtocol {
        return streakManager
    }
    
    /// Get analytics engine instance
    func getAnalyticsEngine() -> AnalyticsEngineProtocol {
        return analyticsEngine
    }
    
    // MARK: - Convenience Methods
    
    /// Create a new session result and update progress
    func recordSession(
        userId: String,
        exerciseId: UUID,
        originalText: String,
        spokenText: String,
        accuracy: Float,
        score: Int,
        timeSpent: TimeInterval,
        mistakes: [TextMistake] = [],
        difficulty: DifficultyLevel,
        inputMethod: InputMethod,
        attempts: Int = 1,
        category: AchievementCategory? = nil
    ) async throws {
        let sessionResult = SessionResult(
            userId: userId,
            exerciseId: exerciseId,
            originalText: originalText,
            spokenText: spokenText,
            accuracy: accuracy,
            score: score,
            timeSpent: timeSpent,
            mistakes: mistakes,
            difficulty: difficulty,
            inputMethod: inputMethod,
            attempts: attempts,
            category: category
        )
        
        try await progressTracker.updateDailyProgress(userId: userId, sessionResult: sessionResult)
    }
    
    /// Get comprehensive user progress for a period
    func getUserProgressSummary(userId: String, period: ProgressPeriod) async throws -> ProgressSummary {
        let userProgress = try await progressTracker.getUserProgress(userId: userId, period: period)
        let userAnalytics = try await progressTracker.getUserAnalytics(userId: userId, period: period)
        let learningStreak = try await progressTracker.getLearningStreak(userId: userId)
        let learningGoals = try await progressTracker.getLearningGoals(userId: userId)
        
        return ProgressSummary(
            userProgress: userProgress,
            analytics: userAnalytics,
            streak: learningStreak,
            goals: learningGoals
        )
    }
    
    /// Check if user has met their daily goals
    func checkDailyGoalCompletion(userId: String) async throws -> DailyGoalStatus {
        let isDailyGoalMet = try await progressTracker.checkDailyGoal(userId: userId)
        let goals = try await progressTracker.getLearningGoals(userId: userId)
        let todayProgress = try await progressRepository.getDailyProgress(userId: userId, date: Date())
        
        return DailyGoalStatus(
            isGoalMet: isDailyGoalMet,
            goals: goals,
            currentProgress: todayProgress,
            progressPercentage: calculateDailyGoalProgress(progress: todayProgress, goals: goals)
        )
    }
    
    /// Update user's learning goals
    func updateUserGoals(
        userId: String,
        dailySessionGoal: Int? = nil,
        dailyTimeGoal: TimeInterval? = nil,
        weeklySessionGoal: Int? = nil,
        accuracyGoal: Float? = nil,
        streakGoal: Int? = nil
    ) async throws {
        var currentGoals = try await progressTracker.getLearningGoals(userId: userId)
        
        if let dailySessionGoal = dailySessionGoal {
            currentGoals = LearningGoals(
                userId: currentGoals.userId,
                dailySessionGoal: dailySessionGoal,
                dailyTimeGoal: currentGoals.dailyTimeGoal,
                weeklySessionGoal: currentGoals.weeklySessionGoal,
                accuracyGoal: currentGoals.accuracyGoal,
                streakGoal: currentGoals.streakGoal,
                customGoals: currentGoals.customGoals,
                isActive: currentGoals.isActive,
                createdAt: currentGoals.createdAt,
                updatedAt: Date()
            )
        }
        
        if let dailyTimeGoal = dailyTimeGoal {
            currentGoals = LearningGoals(
                userId: currentGoals.userId,
                dailySessionGoal: currentGoals.dailySessionGoal,
                dailyTimeGoal: dailyTimeGoal,
                weeklySessionGoal: currentGoals.weeklySessionGoal,
                accuracyGoal: currentGoals.accuracyGoal,
                streakGoal: currentGoals.streakGoal,
                customGoals: currentGoals.customGoals,
                isActive: currentGoals.isActive,
                createdAt: currentGoals.createdAt,
                updatedAt: Date()
            )
        }
        
        if let weeklySessionGoal = weeklySessionGoal {
            currentGoals = LearningGoals(
                userId: currentGoals.userId,
                dailySessionGoal: currentGoals.dailySessionGoal,
                dailyTimeGoal: currentGoals.dailyTimeGoal,
                weeklySessionGoal: weeklySessionGoal,
                accuracyGoal: currentGoals.accuracyGoal,
                streakGoal: currentGoals.streakGoal,
                customGoals: currentGoals.customGoals,
                isActive: currentGoals.isActive,
                createdAt: currentGoals.createdAt,
                updatedAt: Date()
            )
        }
        
        if let accuracyGoal = accuracyGoal {
            currentGoals = LearningGoals(
                userId: currentGoals.userId,
                dailySessionGoal: currentGoals.dailySessionGoal,
                dailyTimeGoal: currentGoals.dailyTimeGoal,
                weeklySessionGoal: currentGoals.weeklySessionGoal,
                accuracyGoal: accuracyGoal,
                streakGoal: currentGoals.streakGoal,
                customGoals: currentGoals.customGoals,
                isActive: currentGoals.isActive,
                createdAt: currentGoals.createdAt,
                updatedAt: Date()
            )
        }
        
        if let streakGoal = streakGoal {
            currentGoals = LearningGoals(
                userId: currentGoals.userId,
                dailySessionGoal: currentGoals.dailySessionGoal,
                dailyTimeGoal: currentGoals.dailyTimeGoal,
                weeklySessionGoal: currentGoals.weeklySessionGoal,
                accuracyGoal: currentGoals.accuracyGoal,
                streakGoal: streakGoal,
                customGoals: currentGoals.customGoals,
                isActive: currentGoals.isActive,
                createdAt: currentGoals.createdAt,
                updatedAt: Date()
            )
        }
        
        try await progressTracker.updateLearningGoals(userId: userId, goals: currentGoals)
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateDailyGoalProgress(progress: DailyProgress?, goals: LearningGoals) -> Float {
        guard let progress = progress else { return 0.0 }
        
        let sessionProgress = Float(progress.sessionsCompleted) / Float(goals.dailySessionGoal)
        let timeProgress = Float(progress.timeSpent) / Float(goals.dailyTimeGoal)
        let accuracyProgress = progress.averageAccuracy / goals.accuracyGoal
        
        return min(1.0, (sessionProgress + timeProgress + accuracyProgress) / 3.0)
    }
}

// MARK: - Supporting Data Models

/// Comprehensive progress summary
struct ProgressSummary {
    let userProgress: UserProgress
    let analytics: UserAnalytics
    let streak: LearningStreak
    let goals: LearningGoals
    
    /// Overall learning health score
    var healthScore: Int {
        return analytics.learningHealthScore
    }
    
    /// Whether user is on track with their goals
    var isOnTrack: Bool {
        return userProgress.completionPercentage >= 0.7
    }
    
    /// Key insights for the user
    var keyInsights: [String] {
        var insights: [String] = []
        
        if userProgress.averageAccuracy >= 0.9 {
            insights.append("Độ chính xác xuất sắc!")
        }
        
        if streak.currentStreak >= 7 {
            insights.append("Chuỗi học tập ấn tượng!")
        }
        
        if userProgress.averageSessionsPerDay >= Float(goals.dailySessionGoal) {
            insights.append("Đạt mục tiêu hàng ngày!")
        }
        
        return insights
    }
}

/// Daily goal completion status
struct DailyGoalStatus {
    let isGoalMet: Bool
    let goals: LearningGoals
    let currentProgress: DailyProgress?
    let progressPercentage: Float
    
    /// Remaining sessions to complete daily goal
    var remainingSessions: Int {
        guard let progress = currentProgress else { return goals.dailySessionGoal }
        return max(0, goals.dailySessionGoal - progress.sessionsCompleted)
    }
    
    /// Remaining time to complete daily goal
    var remainingTime: TimeInterval {
        guard let progress = currentProgress else { return goals.dailyTimeGoal }
        return max(0, goals.dailyTimeGoal - progress.timeSpent)
    }
    
    /// Formatted remaining time
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime / 60)
        return "\(minutes) phút"
    }
    
    /// Motivational message based on progress
    var motivationalMessage: String {
        switch progressPercentage {
        case 0.0..<0.3:
            return "Hãy bắt đầu học thôi! 🌟"
        case 0.3..<0.7:
            return "Đang tiến bộ tốt! Tiếp tục nào! 💪"
        case 0.7..<1.0:
            return "Sắp hoàn thành mục tiêu rồi! 🎯"
        default:
            return "Tuyệt vời! Đã hoàn thành mục tiêu hôm nay! 🎉"
        }
    }
}