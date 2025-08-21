import Foundation

// MARK: - Progress Tracker
final class ProgressTracker: ProgressTrackingProtocol {
    
    // MARK: - Properties
    private let progressRepository: ProgressRepositoryProtocol
    private let userScoreRepository: UserScoreRepositoryProtocol
    private let streakManager: StreakManagerProtocol
    private let analyticsEngine: AnalyticsEngineProtocol
    
    init(
        progressRepository: ProgressRepositoryProtocol,
        userScoreRepository: UserScoreRepositoryProtocol,
        streakManager: StreakManagerProtocol,
        analyticsEngine: AnalyticsEngineProtocol
    ) {
        self.progressRepository = progressRepository
        self.userScoreRepository = userScoreRepository
        self.streakManager = streakManager
        self.analyticsEngine = analyticsEngine
    }
    
    // MARK: - ProgressTrackingProtocol Implementation
    
    func updateDailyProgress(userId: String, sessionResult: SessionResult) async throws {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get or create today's progress
        var dailyProgress = try await progressRepository.getDailyProgress(
            userId: userId,
            date: today
        ) ?? DailyProgress(date: today)
        
        // Update daily progress with session data
        dailyProgress = DailyProgress(
            date: dailyProgress.date,
            sessionsCompleted: dailyProgress.sessionsCompleted + 1,
            timeSpent: dailyProgress.timeSpent + sessionResult.timeSpent,
            averageAccuracy: calculateNewAverage(
                current: dailyProgress.averageAccuracy,
                newValue: sessionResult.accuracy,
                count: dailyProgress.sessionsCompleted + 1
            ),
            scoreEarned: dailyProgress.scoreEarned + sessionResult.score,
            goalsMet: dailyProgress.goalsMet,
            isGoalAchieved: dailyProgress.isGoalAchieved
        )
        
        // Check if daily goals are met
        let goals = try await getLearningGoals(userId: userId)
        let isGoalAchieved = checkDailyGoalsAchieved(dailyProgress: dailyProgress, goals: goals)
        
        dailyProgress = DailyProgress(
            date: dailyProgress.date,
            sessionsCompleted: dailyProgress.sessionsCompleted,
            timeSpent: dailyProgress.timeSpent,
            averageAccuracy: dailyProgress.averageAccuracy,
            scoreEarned: dailyProgress.scoreEarned,
            goalsMet: dailyProgress.goalsMet,
            isGoalAchieved: isGoalAchieved
        )
        
        // Save updated progress
        try await progressRepository.saveDailyProgress(userId: userId, progress: dailyProgress)
        
        // Update streak if goals are achieved
        if isGoalAchieved {
            _ = try await streakManager.updateStreak(userId: userId, isSuccess: true)
        }
        
        // Update analytics
        try await analyticsEngine.recordSession(userId: userId, sessionResult: sessionResult)
    }
    
    func getUserProgress(userId: String, period: ProgressPeriod) async throws -> UserProgress {
        let dateRange = period.dateRange
        
        // Get daily progress data for the period
        let dailyProgressData = try await progressRepository.getDailyProgressRange(
            userId: userId,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        // Get user statistics
        let userStats = try await userScoreRepository.getUserStatistics(userId: userId)
        
        // Calculate aggregated metrics
        let totalSessions = dailyProgressData.reduce(0) { $0 + $1.sessionsCompleted }
        let totalTimeSpent = dailyProgressData.reduce(0) { $0 + $1.timeSpent }
        let totalScore = dailyProgressData.reduce(0) { $0 + $1.scoreEarned }
        
        let averageAccuracy = dailyProgressData.isEmpty ? 0 :
            dailyProgressData.reduce(0) { $0 + $1.averageAccuracy } / Float(dailyProgressData.count)
        
        let goalsAchieved = dailyProgressData.filter { $0.isGoalAchieved }.count
        let totalGoals = dailyProgressData.count
        
        // Get streak information
        let streak = try await getLearningStreak(userId: userId)
        
        // Get category and difficulty progress
        let categoryProgress = try await getCategoryProgress(userId: userId, period: period)
        let difficultyProgress = try await getDifficultyProgress(userId: userId, period: period)
        
        // Calculate improvement trend
        let improvementTrend = try await calculateImprovementTrend(userId: userId, period: period)
        
        return UserProgress(
            userId: userId,
            period: period,
            startDate: dateRange.start,
            endDate: dateRange.end,
            totalSessions: totalSessions,
            totalTimeSpent: totalTimeSpent,
            averageAccuracy: averageAccuracy,
            totalScore: totalScore,
            streakCount: streak.currentStreak,
            goalsAchieved: goalsAchieved,
            totalGoals: totalGoals,
            dailyProgress: dailyProgressData,
            categoryProgress: categoryProgress,
            difficultyProgress: difficultyProgress,
            improvementTrend: improvementTrend
        )
    }
    
    func checkDailyGoal(userId: String) async throws -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        guard let dailyProgress = try await progressRepository.getDailyProgress(
            userId: userId,
            date: today
        ) else {
            return false
        }
        
        return dailyProgress.isGoalAchieved
    }
    
    func getLearningStreak(userId: String) async throws -> LearningStreak {
        let streakStats = try await streakManager.getStreakStatistics(userId: userId)
        
        // Get streak milestones
        let milestones = generateStreakMilestones(currentStreak: streakStats.currentStreak)
        let nextMilestone = milestones.first { !$0.isReached }
        
        return LearningStreak(
            currentStreak: streakStats.currentStreak,
            longestStreak: streakStats.bestStreak,
            streakStartDate: streakStats.lastStreakDate,
            lastActivityDate: streakStats.lastStreakDate ?? Date(),
            streakLevel: streakStats.streakLevel,
            daysUntilReset: streakStats.daysUntilReset,
            milestones: milestones,
            nextMilestone: nextMilestone
        )
    }
    
    func getUserAnalytics(userId: String, period: ProgressPeriod) async throws -> UserAnalytics {
        return try await analyticsEngine.generateUserAnalytics(userId: userId, period: period)
    }
    
    func updateLearningGoals(userId: String, goals: LearningGoals) async throws {
        var updatedGoals = goals
        updatedGoals = LearningGoals(
            userId: updatedGoals.userId,
            dailySessionGoal: updatedGoals.dailySessionGoal,
            dailyTimeGoal: updatedGoals.dailyTimeGoal,
            weeklySessionGoal: updatedGoals.weeklySessionGoal,
            accuracyGoal: updatedGoals.accuracyGoal,
            streakGoal: updatedGoals.streakGoal,
            customGoals: updatedGoals.customGoals,
            isActive: updatedGoals.isActive,
            createdAt: updatedGoals.createdAt,
            updatedAt: Date()
        )
        
        try await progressRepository.saveLearningGoals(userId: userId, goals: updatedGoals)
    }
    
    func getLearningGoals(userId: String) async throws -> LearningGoals {
        return try await progressRepository.getLearningGoals(userId: userId) ??
            LearningGoals.defaultGoals(for: userId)
    }
    
    func getProgressComparison(userId: String, period: ProgressPeriod) async throws -> ProgressComparison {
        return try await analyticsEngine.generateProgressComparison(userId: userId, period: period)
    }
    
    func getLearningInsights(userId: String) async throws -> [LearningInsight] {
        return try await analyticsEngine.generateLearningInsights(userId: userId)
    }
    
    func exportProgressData(userId: String, format: ExportFormat) async throws -> Data {
        let userProgress = try await getUserProgress(userId: userId, period: .allTime)
        let analytics = try await getUserAnalytics(userId: userId, period: .allTime)
        
        switch format {
        case .json:
            return try exportAsJSON(userProgress: userProgress, analytics: analytics)
        case .csv:
            return try exportAsCSV(userProgress: userProgress, analytics: analytics)
        case .pdf:
            return try exportAsPDF(userProgress: userProgress, analytics: analytics)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateNewAverage(current: Float, newValue: Float, count: Int) -> Float {
        guard count > 0 else { return newValue }
        return ((current * Float(count - 1)) + newValue) / Float(count)
    }
    
    private func checkDailyGoalsAchieved(dailyProgress: DailyProgress, goals: LearningGoals) -> Bool {
        let sessionGoalMet = dailyProgress.sessionsCompleted >= goals.dailySessionGoal
        let timeGoalMet = dailyProgress.timeSpent >= goals.dailyTimeGoal
        let accuracyGoalMet = dailyProgress.averageAccuracy >= goals.accuracyGoal
        
        return sessionGoalMet && timeGoalMet && accuracyGoalMet
    }
    
    private func getCategoryProgress(userId: String, period: ProgressPeriod) async throws -> [CategoryProgress] {
        let sessions = try await progressRepository.getSessionsByCategory(
            userId: userId,
            period: period
        )
        
        return AchievementCategory.allCases.compactMap { category in
            let categorySessions = sessions.filter { $0.category == category }
            guard !categorySessions.isEmpty else { return nil }
            
            let averageAccuracy = categorySessions.reduce(0) { $0 + $1.accuracy } / Float(categorySessions.count)
            let totalTime = categorySessions.reduce(0) { $0 + $1.timeSpent }
            
            return CategoryProgress(
                category: category,
                sessionsCompleted: categorySessions.count,
                averageAccuracy: averageAccuracy,
                timeSpent: totalTime,
                improvementRate: 0.0, // Would be calculated from historical data
                strongestSkills: [], // Would be determined from detailed analysis
                improvementAreas: [] // Would be determined from mistake patterns
            )
        }
    }
    
    private func getDifficultyProgress(userId: String, period: ProgressPeriod) async throws -> [DifficultyProgress] {
        let sessions = try await progressRepository.getSessionsByDifficulty(
            userId: userId,
            period: period
        )
        
        return DifficultyLevel.allCases.compactMap { difficulty in
            let difficultySessions = sessions.filter { $0.difficulty == difficulty }
            guard !difficultySessions.isEmpty else { return nil }
            
            let averageAccuracy = difficultySessions.reduce(0) { $0 + $1.accuracy } / Float(difficultySessions.count)
            let totalTime = difficultySessions.reduce(0) { $0 + $1.timeSpent }
            let masteryLevel = calculateMasteryLevel(
                sessions: difficultySessions.count,
                accuracy: averageAccuracy
            )
            
            let nextDifficulty = getNextDifficulty(current: difficulty, masteryLevel: masteryLevel)
            
            return DifficultyProgress(
                difficulty: difficulty,
                sessionsCompleted: difficultySessions.count,
                averageAccuracy: averageAccuracy,
                timeSpent: totalTime,
                masteryLevel: masteryLevel,
                recommendedNext: nextDifficulty
            )
        }
    }
    
    private func calculateMasteryLevel(sessions: Int, accuracy: Float) -> MasteryLevel {
        for level in MasteryLevel.allCases.reversed() {
            if sessions >= level.requiredSessions && accuracy >= level.requiredAccuracy {
                return level
            }
        }
        return .beginner
    }
    
    private func getNextDifficulty(current: DifficultyLevel, masteryLevel: MasteryLevel) -> DifficultyLevel? {
        guard masteryLevel == .mastered else { return nil }
        
        let allDifficulties = DifficultyLevel.allCases
        guard let currentIndex = allDifficulties.firstIndex(of: current),
              currentIndex < allDifficulties.count - 1 else {
            return nil
        }
        
        return allDifficulties[currentIndex + 1]
    }
    
    private func calculateImprovementTrend(userId: String, period: ProgressPeriod) async throws -> ImprovementTrend {
        let sessions = try await progressRepository.getRecentSessions(userId: userId, limit: 20)
        
        guard sessions.count >= 2 else {
            return ImprovementTrend(
                direction: .stable,
                magnitude: 0.0,
                consistency: 0.0,
                recentChange: 0.0,
                projectedImprovement: 0.0
            )
        }
        
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        let firstHalf = Array(sortedSessions.prefix(sessions.count / 2))
        let secondHalf = Array(sortedSessions.suffix(sessions.count / 2))
        
        let firstHalfAverage = firstHalf.reduce(0) { $0 + $1.accuracy } / Float(firstHalf.count)
        let secondHalfAverage = secondHalf.reduce(0) { $0 + $1.accuracy } / Float(secondHalf.count)
        
        let change = secondHalfAverage - firstHalfAverage
        let magnitude = abs(change)
        
        let direction: TrendDirection
        if change > 0.05 {
            direction = .improving
        } else if change < -0.05 {
            direction = .declining
        } else {
            direction = .stable
        }
        
        // Calculate consistency (how stable the trend is)
        let accuracyVariance = calculateVariance(sessions.map { $0.accuracy })
        let consistency = max(0, 1.0 - accuracyVariance)
        
        // Project future improvement based on current trend
        let projectedImprovement = change * 2.0 // Simple projection
        
        return ImprovementTrend(
            direction: direction,
            magnitude: magnitude,
            consistency: consistency,
            recentChange: change,
            projectedImprovement: projectedImprovement
        )
    }
    
    private func calculateVariance(_ values: [Float]) -> Float {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Float(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Float(values.count - 1)
    }
    
    private func generateStreakMilestones(currentStreak: Int) -> [StreakMilestone] {
        let milestoneValues = [3, 7, 14, 30, 60, 100, 365]
        
        return milestoneValues.map { value in
            StreakMilestone(
                streak: value,
                title: getStreakMilestoneTitle(for: value),
                description: getStreakMilestoneDescription(for: value),
                reward: value * 10, // 10 points per day
                isReached: currentStreak >= value
            )
        }
    }
    
    private func getStreakMilestoneTitle(for streak: Int) -> String {
        switch streak {
        case 3:
            return "Khởi đầu tốt"
        case 7:
            return "Một tuần kiên trì"
        case 14:
            return "Hai tuần xuất sắc"
        case 30:
            return "Một tháng tuyệt vời"
        case 60:
            return "Hai tháng phi thường"
        case 100:
            return "Trăm ngày học tập"
        case 365:
            return "Một năm hoàn hảo"
        default:
            return "Cột mốc \(streak) ngày"
        }
    }
    
    private func getStreakMilestoneDescription(for streak: Int) -> String {
        switch streak {
        case 3:
            return "Học liên tục 3 ngày"
        case 7:
            return "Học liên tục 1 tuần"
        case 14:
            return "Học liên tục 2 tuần"
        case 30:
            return "Học liên tục 1 tháng"
        case 60:
            return "Học liên tục 2 tháng"
        case 100:
            return "Học liên tục 100 ngày"
        case 365:
            return "Học liên tục 1 năm"
        default:
            return "Học liên tục \(streak) ngày"
        }
    }
    
    // MARK: - Export Methods
    
    private func exportAsJSON(userProgress: UserProgress, analytics: UserAnalytics) throws -> Data {
        let exportData = [
            "userProgress": userProgress,
            "analytics": analytics,
            "exportDate": Date(),
            "version": "1.0"
        ] as [String: Any]
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    private func exportAsCSV(userProgress: UserProgress, analytics: UserAnalytics) throws -> Data {
        var csvContent = "Date,Sessions,Time Spent,Accuracy,Score,Goal Achieved\n"
        
        for dailyProgress in userProgress.dailyProgress {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: dailyProgress.date)
            
            csvContent += "\(dateString),\(dailyProgress.sessionsCompleted),\(Int(dailyProgress.timeSpent/60)),\(dailyProgress.averageAccuracy),\(dailyProgress.scoreEarned),\(dailyProgress.isGoalAchieved)\n"
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func exportAsPDF(userProgress: UserProgress, analytics: UserAnalytics) throws -> Data {
        // This would require a PDF generation library
        // For now, return JSON data as placeholder
        return try exportAsJSON(userProgress: userProgress, analytics: analytics)
    }
}

// MARK: - Supporting Protocols

/// Analytics engine protocol
protocol AnalyticsEngineProtocol {
    func recordSession(userId: String, sessionResult: SessionResult) async throws
    func generateUserAnalytics(userId: String, period: ProgressPeriod) async throws -> UserAnalytics
    func generateProgressComparison(userId: String, period: ProgressPeriod) async throws -> ProgressComparison
    func generateLearningInsights(userId: String) async throws -> [LearningInsight]
}

/// Category session data
struct CategorySession: Codable {
    let category: AchievementCategory
    let accuracy: Float
    let timeSpent: TimeInterval
    let completedAt: Date
}

/// Streak milestone
struct StreakMilestone: Codable {
    let streak: Int
    let title: String
    let description: String
    let reward: Int
    let isReached: Bool
}