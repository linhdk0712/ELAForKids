import Foundation

// MARK: - Analytics Engine
final class AnalyticsEngine: AnalyticsEngineProtocol {
    
    // MARK: - Properties
    private let progressRepository: ProgressRepositoryProtocol
    private let userScoreRepository: UserScoreRepositoryProtocol
    
    init(
        progressRepository: ProgressRepositoryProtocol,
        userScoreRepository: UserScoreRepositoryProtocol
    ) {
        self.progressRepository = progressRepository
        self.userScoreRepository = userScoreRepository
    }
    
    // MARK: - AnalyticsEngineProtocol Implementation
    
    func recordSession(userId: String, sessionResult: SessionResult) async throws {
        // Save session result to repository
        try await progressRepository.saveSessionResult(sessionResult)
        
        // Update user score
        try await userScoreRepository.updateScore(userId: userId, additionalScore: sessionResult.score)
        
        // Record analytics data
        await recordAnalyticsData(sessionResult: sessionResult)
    }
    
    func generateUserAnalytics(userId: String, period: ProgressPeriod) async throws -> UserAnalytics {
        let dateRange = period.dateRange
        let sessions = try await progressRepository.getSessionsByDifficulty(userId: userId, period: period)
        let userStats = try await userScoreRepository.getUserStatistics(userId: userId)
        
        // Calculate analytics metrics
        let totalLearningTime = sessions.reduce(0) { $0 + $1.timeSpent }
        let averageSessionLength = sessions.isEmpty ? 0 : totalLearningTime / TimeInterval(sessions.count)
        
        // Find most active patterns
        let mostActiveDay = findMostActiveDay(sessions: sessions)
        let mostActiveTime = findMostActiveTime(sessions: sessions)
        
        // Determine preferences
        let preferredDifficulty = findPreferredDifficulty(sessions: sessions)
        let strongestCategory = findStrongestCategory(userId: userId, period: period)
        let improvementAreas = findImprovementAreas(userId: userId, period: period)
        
        // Calculate learning velocity
        let learningVelocity = calculateLearningVelocity(sessions: sessions, period: period)
        
        // Calculate scores
        let consistencyScore = calculateConsistencyScore(userId: userId, period: period)
        let engagementScore = calculateEngagementScore(sessions: sessions)
        let retentionRate = calculateRetentionRate(sessions: sessions)
        
        // Generate patterns
        let weeklyPattern = generateWeeklyPattern(sessions: sessions)
        let monthlyTrend = generateMonthlyTrend(userId: userId, period: period)
        
        return UserAnalytics(
            userId: userId,
            period: period,
            totalLearningTime: totalLearningTime,
            averageSessionLength: averageSessionLength,
            mostActiveDay: mostActiveDay,
            mostActiveTime: mostActiveTime,
            preferredDifficulty: preferredDifficulty,
            strongestCategory: strongestCategory,
            improvementAreas: improvementAreas,
            learningVelocity: learningVelocity,
            consistencyScore: consistencyScore,
            engagementScore: engagementScore,
            retentionRate: retentionRate,
            weeklyPattern: weeklyPattern,
            monthlyTrend: monthlyTrend
        )
    }
    
    func generateProgressComparison(userId: String, period: ProgressPeriod) async throws -> ProgressComparison {
        let userProgress = try await progressRepository.getUserProgress(userId: userId, period: period)
        
        // Get anonymous peer data (mock implementation)
        let peerData = await generatePeerComparisonData(period: period)
        
        // Calculate user's rank and percentile
        let userRank = calculateUserRank(userScore: userProgress.totalScore, peerScores: peerData.scores)
        let percentile = Float(peerData.scores.count - userRank + 1) / Float(peerData.scores.count)
        
        // Generate comparison insights
        let insights = generateComparisonInsights(
            userProgress: userProgress,
            peerData: peerData
        )
        
        return ProgressComparison(
            userRank: userRank,
            totalUsers: peerData.scores.count,
            percentile: percentile,
            averageAccuracy: peerData.averageAccuracy,
            userAccuracy: userProgress.averageAccuracy,
            averageSessionsPerWeek: peerData.averageSessionsPerWeek,
            userSessionsPerWeek: userProgress.averageSessionsPerDay * 7,
            averageStreak: peerData.averageStreak,
            userStreak: userProgress.streakCount,
            comparisonInsights: insights
        )
    }
    
    func generateLearningInsights(userId: String) async throws -> [LearningInsight] {
        var insights: [LearningInsight] = []
        
        // Get recent progress data
        let recentProgress = try await progressRepository.getUserProgress(userId: userId, period: .weekly)
        let monthlyProgress = try await progressRepository.getUserProgress(userId: userId, period: .monthly)
        
        // Accuracy insights
        if let accuracyInsight = generateAccuracyInsight(recentProgress: recentProgress, monthlyProgress: monthlyProgress) {
            insights.append(accuracyInsight)
        }
        
        // Consistency insights
        if let consistencyInsight = generateConsistencyInsight(recentProgress: recentProgress) {
            insights.append(consistencyInsight)
        }
        
        // Difficulty progression insights
        if let difficultyInsight = generateDifficultyInsight(monthlyProgress: monthlyProgress) {
            insights.append(difficultyInsight)
        }
        
        // Engagement insights
        if let engagementInsight = generateEngagementInsight(recentProgress: recentProgress) {
            insights.append(engagementInsight)
        }
        
        // Achievement insights
        if let achievementInsight = generateAchievementInsight(userId: userId, recentProgress: recentProgress) {
            insights.append(achievementInsight)
        }
        
        // Streak insights
        if let streakInsight = generateStreakInsight(recentProgress: recentProgress) {
            insights.append(streakInsight)
        }
        
        // Goal insights
        if let goalInsight = await generateGoalInsight(userId: userId, recentProgress: recentProgress) {
            insights.append(goalInsight)
        }
        
        // Sort by priority
        return insights.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    // MARK: - Private Analytics Methods
    
    private func recordAnalyticsData(sessionResult: SessionResult) async {
        // Record session data for analytics
        // This could be sent to analytics service or stored locally
        print("Recording analytics for session: \(sessionResult.id)")
    }
    
    private func findMostActiveDay(sessions: [SessionResult]) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "vi_VN")
        dayFormatter.dateFormat = "EEEE"
        
        let dayCounts = Dictionary(grouping: sessions) { session in
            dayFormatter.string(from: session.completedAt)
        }.mapValues { $0.count }
        
        return dayCounts.max { $0.value < $1.value }?.key ?? "Thứ Hai"
    }
    
    private func findMostActiveTime(sessions: [SessionResult]) -> String {
        let hourCounts = Dictionary(grouping: sessions) { session in
            Calendar.current.component(.hour, from: session.completedAt)
        }.mapValues { $0.count }
        
        guard let mostActiveHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return "Buổi sáng"
        }
        
        switch mostActiveHour {
        case 6..<12:
            return "Buổi sáng"
        case 12..<18:
            return "Buổi chiều"
        case 18..<22:
            return "Buổi tối"
        default:
            return "Buổi tối muộn"
        }
    }
    
    private func findPreferredDifficulty(sessions: [SessionResult]) -> DifficultyLevel {
        let difficultyCounts = Dictionary(grouping: sessions) { $0.difficulty }
            .mapValues { $0.count }
        
        return difficultyCounts.max { $0.value < $1.value }?.key ?? .grade1
    }
    
    private func findStrongestCategory(userId: String, period: ProgressPeriod) async -> AchievementCategory {
        do {
            let categorySessions = try await progressRepository.getSessionsByCategory(userId: userId, period: period)
            let categoryAccuracy = Dictionary(grouping: categorySessions) { $0.category }
                .mapValues { sessions in
                    sessions.reduce(0) { $0 + $1.accuracy } / Float(sessions.count)
                }
            
            return categoryAccuracy.max { $0.value < $1.value }?.key ?? .reading
        } catch {
            return .reading
        }
    }
    
    private func findImprovementAreas(userId: String, period: ProgressPeriod) async -> [AchievementCategory] {
        do {
            let categorySessions = try await progressRepository.getSessionsByCategory(userId: userId, period: period)
            let categoryAccuracy = Dictionary(grouping: categorySessions) { $0.category }
                .mapValues { sessions in
                    sessions.reduce(0) { $0 + $1.accuracy } / Float(sessions.count)
                }
            
            return categoryAccuracy.compactMap { (category, accuracy) in
                accuracy < 0.75 ? category : nil
            }
        } catch {
            return []
        }
    }
    
    private func calculateLearningVelocity(sessions: [SessionResult], period: ProgressPeriod) -> LearningVelocity {
        let dateRange = period.dateRange
        let days = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
        let weeks = Float(days) / 7.0
        
        let sessionsPerWeek = Float(sessions.count) / max(1, weeks)
        
        // Calculate accuracy improvement
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        let firstHalf = Array(sortedSessions.prefix(sessions.count / 2))
        let secondHalf = Array(sortedSessions.suffix(sessions.count / 2))
        
        let firstHalfAccuracy = firstHalf.isEmpty ? 0 : firstHalf.reduce(0) { $0 + $1.accuracy } / Float(firstHalf.count)
        let secondHalfAccuracy = secondHalf.isEmpty ? 0 : secondHalf.reduce(0) { $0 + $1.accuracy } / Float(secondHalf.count)
        let accuracyImprovement = secondHalfAccuracy - firstHalfAccuracy
        
        // Calculate difficulty progression
        let difficultyProgression = calculateDifficultyProgression(sessions: sessions)
        
        // Overall velocity
        let overallVelocity = (sessionsPerWeek / 10.0 + max(0, accuracyImprovement) + difficultyProgression) / 3.0
        
        return LearningVelocity(
            sessionsPerWeek: sessionsPerWeek,
            accuracyImprovement: accuracyImprovement,
            difficultyProgression: difficultyProgression,
            overallVelocity: overallVelocity
        )
    }
    
    private func calculateDifficultyProgression(sessions: [SessionResult]) -> Float {
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        guard let firstSession = sortedSessions.first,
              let lastSession = sortedSessions.last else {
            return 0
        }
        
        let firstDifficultyValue = getDifficultyValue(firstSession.difficulty)
        let lastDifficultyValue = getDifficultyValue(lastSession.difficulty)
        
        return Float(lastDifficultyValue - firstDifficultyValue) / 4.0 // Max progression is 4 levels
    }
    
    private func getDifficultyValue(_ difficulty: DifficultyLevel) -> Int {
        switch difficulty {
        case .grade1: return 1
        case .grade2: return 2
        case .grade3: return 3
        case .grade4: return 4
        case .grade5: return 5
        }
    }
    
    private func calculateConsistencyScore(userId: String, period: ProgressPeriod) async -> Float {
        do {
            let dateRange = period.dateRange
            let dailyProgress = try await progressRepository.getDailyProgressRange(
                userId: userId,
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            
            let totalDays = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
            let activeDays = dailyProgress.filter { $0.sessionsCompleted > 0 }.count
            
            return Float(activeDays) / Float(totalDays)
        } catch {
            return 0
        }
    }
    
    private func calculateEngagementScore(sessions: [SessionResult]) -> Float {
        guard !sessions.isEmpty else { return 0 }
        
        let averageTimePerSession = sessions.reduce(0) { $0 + $1.timeSpent } / TimeInterval(sessions.count)
        let averageAccuracy = sessions.reduce(0) { $0 + $1.accuracy } / Float(sessions.count)
        let averageAttempts = sessions.reduce(0) { $0 + $1.attempts } / sessions.count
        
        // Normalize scores
        let timeScore = min(1.0, Float(averageTimePerSession) / 300.0) // 5 minutes = 1.0
        let accuracyScore = averageAccuracy
        let attemptsScore = max(0, 1.0 - Float(averageAttempts - 1) / 3.0) // 1 attempt = 1.0, 4+ attempts = 0
        
        return (timeScore + accuracyScore + attemptsScore) / 3.0
    }
    
    private func calculateRetentionRate(sessions: [SessionResult]) -> Float {
        guard sessions.count >= 2 else { return 0 }
        
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        let firstSession = sortedSessions.first!
        let lastSession = sortedSessions.last!
        
        let daysBetween = Calendar.current.dateComponents([.day], from: firstSession.completedAt, to: lastSession.completedAt).day ?? 1
        let expectedSessions = max(1, daysBetween / 2) // Expect session every 2 days
        
        return min(1.0, Float(sessions.count) / Float(expectedSessions))
    }
    
    private func generateWeeklyPattern(sessions: [SessionResult]) -> [WeeklyActivity] {
        var weeklyPattern: [WeeklyActivity] = []
        
        for dayOfWeek in 1...7 { // 1 = Sunday, 7 = Saturday
            let daySessions = sessions.filter { session in
                Calendar.current.component(.weekday, from: session.completedAt) == dayOfWeek
            }
            
            let averageSessions = Float(daySessions.count) / max(1, Float(getWeeksInPeriod(sessions: sessions)))
            let averageAccuracy = daySessions.isEmpty ? 0 : daySessions.reduce(0) { $0 + $1.accuracy } / Float(daySessions.count)
            let totalTimeSpent = daySessions.reduce(0) { $0 + $1.timeSpent }
            
            weeklyPattern.append(WeeklyActivity(
                dayOfWeek: dayOfWeek,
                averageSessions: averageSessions,
                averageAccuracy: averageAccuracy,
                totalTimeSpent: totalTimeSpent
            ))
        }
        
        return weeklyPattern
    }
    
    private func generateMonthlyTrend(userId: String, period: ProgressPeriod) async -> [MonthlyTrend] {
        // This would generate monthly trend data
        // For now, return empty array as it requires more complex date calculations
        return []
    }
    
    private func getWeeksInPeriod(sessions: [SessionResult]) -> Int {
        guard let firstSession = sessions.min(by: { $0.completedAt < $1.completedAt }),
              let lastSession = sessions.max(by: { $0.completedAt < $1.completedAt }) else {
            return 1
        }
        
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: firstSession.completedAt, to: lastSession.completedAt).weekOfYear ?? 1
        return max(1, weeks)
    }
    
    // MARK: - Peer Comparison Methods
    
    private func generatePeerComparisonData(period: ProgressPeriod) async -> PeerComparisonData {
        // Mock peer data - in real implementation, this would come from anonymized user data
        let mockScores = Array(1...100).map { _ in Int.random(in: 50...500) }.sorted(by: >)
        let mockAccuracy = Float.random(in: 0.6...0.95)
        let mockSessionsPerWeek = Float.random(in: 2...15)
        let mockStreak = Int.random(in: 0...30)
        
        return PeerComparisonData(
            scores: mockScores,
            averageAccuracy: mockAccuracy,
            averageSessionsPerWeek: mockSessionsPerWeek,
            averageStreak: mockStreak
        )
    }
    
    private func calculateUserRank(userScore: Int, peerScores: [Int]) -> Int {
        let higherScores = peerScores.filter { $0 > userScore }
        return higherScores.count + 1
    }
    
    private func generateComparisonInsights(userProgress: UserProgress, peerData: PeerComparisonData) -> [ComparisonInsight] {
        var insights: [ComparisonInsight] = []
        
        // Accuracy comparison
        if userProgress.averageAccuracy > peerData.averageAccuracy {
            insights.append(ComparisonInsight(
                type: .accuracy,
                message: "Độ chính xác của bé cao hơn trung bình \(Int((userProgress.averageAccuracy - peerData.averageAccuracy) * 100))%",
                recommendation: "Tiếp tục duy trì độ chính xác tuyệt vời này!",
                isPositive: true
            ))
        } else {
            insights.append(ComparisonInsight(
                type: .accuracy,
                message: "Độ chính xác của bé thấp hơn trung bình \(Int((peerData.averageAccuracy - userProgress.averageAccuracy) * 100))%",
                recommendation: "Hãy đọc chậm hơn và tập trung vào từng từ để cải thiện độ chính xác.",
                isPositive: false
            ))
        }
        
        // Consistency comparison
        let userSessionsPerWeek = userProgress.averageSessionsPerDay * 7
        if userSessionsPerWeek > peerData.averageSessionsPerWeek {
            insights.append(ComparisonInsight(
                type: .consistency,
                message: "Bé học nhiều hơn bạn bè \(Int(userSessionsPerWeek - peerData.averageSessionsPerWeek)) buổi/tuần",
                recommendation: "Tuyệt vời! Sự kiên trì sẽ giúp bé tiến bộ nhanh chóng.",
                isPositive: true
            ))
        }
        
        return insights
    }
    
    // MARK: - Learning Insights Generation
    
    private func generateAccuracyInsight(recentProgress: UserProgress, monthlyProgress: UserProgress) -> LearningInsight? {
        let accuracyChange = recentProgress.averageAccuracy - monthlyProgress.averageAccuracy
        
        if accuracyChange > 0.05 {
            return LearningInsight(
                id: UUID().uuidString,
                type: .improvement,
                title: "Độ chính xác đang cải thiện!",
                description: "Độ chính xác của bé đã tăng \(Int(accuracyChange * 100))% trong tuần qua.",
                recommendation: "Tiếp tục duy trì phong độ tốt này bằng cách đọc đều đặn mỗi ngày.",
                priority: .medium,
                actionable: true,
                relatedData: ["accuracy_change": String(format: "%.2f", accuracyChange)],
                createdAt: Date()
            )
        } else if accuracyChange < -0.05 {
            return LearningInsight(
                id: UUID().uuidString,
                type: .improvement,
                title: "Cần cải thiện độ chính xác",
                description: "Độ chính xác của bé đã giảm \(Int(abs(accuracyChange) * 100))% trong tuần qua.",
                recommendation: "Hãy đọc chậm hơn và tập trung vào từng từ. Thực hành với các bài dễ hơn trước.",
                priority: .high,
                actionable: true,
                relatedData: ["accuracy_change": String(format: "%.2f", accuracyChange)],
                createdAt: Date()
            )
        }
        
        return nil
    }
    
    private func generateConsistencyInsight(recentProgress: UserProgress) -> LearningInsight? {
        let activeDays = recentProgress.dailyProgress.filter { $0.sessionsCompleted > 0 }.count
        let totalDays = recentProgress.dailyProgress.count
        let consistencyRate = Float(activeDays) / Float(totalDays)
        
        if consistencyRate < 0.5 {
            return LearningInsight(
                id: UUID().uuidString,
                type: .consistency,
                title: "Cần học đều đặn hơn",
                description: "Bé chỉ học \(activeDays)/\(totalDays) ngày trong tuần qua.",
                recommendation: "Hãy đặt mục tiêu học ít nhất 15 phút mỗi ngày để duy trì tiến độ.",
                priority: .high,
                actionable: true,
                relatedData: ["consistency_rate": String(format: "%.2f", consistencyRate)],
                createdAt: Date()
            )
        }
        
        return nil
    }
    
    private func generateDifficultyInsight(monthlyProgress: UserProgress) -> LearningInsight? {
        let difficultyProgress = monthlyProgress.difficultyProgress
        let masteredLevels = difficultyProgress.filter { $0.isMastered }
        
        if let nextLevel = masteredLevels.last?.difficulty.nextLevel {
            return LearningInsight(
                id: UUID().uuidString,
                type: .difficulty,
                title: "Sẵn sàng thử thách mới!",
                description: "Bé đã thành thạo \(masteredLevels.last?.difficulty.localizedName ?? ""). Đã đến lúc thử \(nextLevel.localizedName)!",
                recommendation: "Hãy thử các bài tập \(nextLevel.localizedName) để tiếp tục phát triển kỹ năng.",
                priority: .medium,
                actionable: true,
                relatedData: ["next_level": nextLevel.rawValue],
                createdAt: Date()
            )
        }
        
        return nil
    }
    
    private func generateEngagementInsight(recentProgress: UserProgress) -> LearningInsight? {
        let averageTimePerSession = recentProgress.averageTimePerSession
        
        if averageTimePerSession < 60 { // Less than 1 minute
            return LearningInsight(
                id: UUID().uuidString,
                type: .engagement,
                title: "Thời gian học ngắn",
                description: "Bé chỉ học trung bình \(Int(averageTimePerSession)) giây mỗi buổi.",
                recommendation: "Hãy dành thêm thời gian để đọc kỹ và hiểu rõ nội dung.",
                priority: .medium,
                actionable: true,
                relatedData: ["average_time": String(Int(averageTimePerSession))],
                createdAt: Date()
            )
        }
        
        return nil
    }
    
    private func generateAchievementInsight(userId: String, recentProgress: UserProgress) -> LearningInsight? {
        // This would check for near achievements
        return LearningInsight(
            id: UUID().uuidString,
            type: .achievement,
            title: "Gần đạt thành tích mới!",
            description: "Bé chỉ cần thêm 2 buổi học nữa để đạt thành tích 'Học sinh chăm chỉ'.",
            recommendation: "Tiếp tục học để mở khóa thành tích mới và nhận điểm thưởng!",
            priority: .low,
            actionable: true,
            relatedData: ["achievement_id": "diligent_student"],
            createdAt: Date()
        )
    }
    
    private func generateStreakInsight(recentProgress: UserProgress) -> LearningInsight? {
        if recentProgress.streakCount >= 7 {
            return LearningInsight(
                id: UUID().uuidString,
                type: .streak,
                title: "Chuỗi học tập tuyệt vời!",
                description: "Bé đã học liên tục \(recentProgress.streakCount) ngày!",
                recommendation: "Tiếp tục duy trì để đạt cột mốc 30 ngày và nhận phần thưởng đặc biệt.",
                priority: .low,
                actionable: false,
                relatedData: ["streak_count": String(recentProgress.streakCount)],
                createdAt: Date()
            )
        } else if recentProgress.streakCount == 0 {
            return LearningInsight(
                id: UUID().uuidString,
                type: .streak,
                title: "Bắt đầu chuỗi học tập mới",
                description: "Hãy bắt đầu xây dựng chuỗi học tập mới!",
                recommendation: "Học liên tục 3 ngày để nhận thành tích đầu tiên.",
                priority: .medium,
                actionable: true,
                relatedData: ["streak_count": "0"],
                createdAt: Date()
            )
        }
        
        return nil
    }
    
    private func generateGoalInsight(userId: String, recentProgress: UserProgress) async -> LearningInsight? {
        do {
            let goals = try await progressRepository.getLearningGoals(userId: userId)
            let dailyGoalsMet = recentProgress.dailyProgress.filter { $0.isGoalAchieved }.count
            let totalDays = recentProgress.dailyProgress.count
            
            if totalDays > 0 && Float(dailyGoalsMet) / Float(totalDays) < 0.5 {
                return LearningInsight(
                    id: UUID().uuidString,
                    type: .goal,
                    title: "Mục tiêu cần điều chỉnh",
                    description: "Bé chỉ đạt mục tiêu \(dailyGoalsMet)/\(totalDays) ngày trong tuần qua.",
                    recommendation: "Có thể mục tiêu hiện tại hơi cao. Hãy điều chỉnh để phù hợp hơn.",
                    priority: .medium,
                    actionable: true,
                    relatedData: ["goals_met": String(dailyGoalsMet), "total_days": String(totalDays)],
                    createdAt: Date()
                )
            }
        } catch {
            // Handle error silently
        }
        
        return nil
    }
}

// MARK: - Supporting Data Models

/// Peer comparison data for analytics
private struct PeerComparisonData {
    let scores: [Int]
    let averageAccuracy: Float
    let averageSessionsPerWeek: Float
    let averageStreak: Int
}