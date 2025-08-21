import Foundation

// MARK: - User Score Repository Protocol
protocol UserScoreRepositoryProtocol {
    func getUserScore(userId: String) async throws -> UserScore
    func updateScore(userId: String, additionalScore: Int) async throws
    func getTopUsers(limit: Int) async throws -> [UserScore]
    func getUserRanking(userId: String) async throws -> Int
    func createUserScore(userId: String, userName: String) async throws -> UserScore
    func getUserStatistics(userId: String) async throws -> UserStatistics
}

// MARK: - Streak Manager Protocol
protocol StreakManagerProtocol {
    func updateStreak(userId: String, isSuccess: Bool) async throws -> Int
    func getCurrentStreak(userId: String) async throws -> Int
    func resetStreak(userId: String) async throws
    func getStreakStatistics(userId: String) async throws -> StreakStatistics
}

// MARK: - Progress Tracking Protocol
protocol ProgressTrackingProtocol {
    /// Update daily progress for user
    func updateDailyProgress(userId: String, sessionResult: SessionResult) async throws
    
    /// Get user progress for specific period
    func getUserProgress(userId: String, period: ProgressPeriod) async throws -> UserProgress
    
    /// Check if daily goal is met
    func checkDailyGoal(userId: String) async throws -> Bool
    
    /// Get learning streak information
    func getLearningStreak(userId: String) async throws -> LearningStreak
    
    /// Get detailed analytics for user
    func getUserAnalytics(userId: String, period: ProgressPeriod) async throws -> UserAnalytics
    
    /// Update user's learning goals
    func updateLearningGoals(userId: String, goals: LearningGoals) async throws
    
    /// Get user's current learning goals
    func getLearningGoals(userId: String) async throws -> LearningGoals
    
    /// Get progress comparison with peers (anonymous)
    func getProgressComparison(userId: String, period: ProgressPeriod) async throws -> ProgressComparison
    
    /// Get learning insights and recommendations
    func getLearningInsights(userId: String) async throws -> [LearningInsight]
    
    /// Export progress data for sharing or backup
    func exportProgressData(userId: String, format: ExportFormat) async throws -> Data
}

// MARK: - Progress Data Models

/// User progress information for a specific period
struct UserProgress: Codable {
    let userId: String
    let period: ProgressPeriod
    let startDate: Date
    let endDate: Date
    let totalSessions: Int
    let totalTimeSpent: TimeInterval
    let averageAccuracy: Float
    let totalScore: Int
    let streakCount: Int
    let goalsAchieved: Int
    let totalGoals: Int
    let dailyProgress: [DailyProgress]
    let categoryProgress: [CategoryProgress]
    let difficultyProgress: [DifficultyProgress]
    let improvementTrend: ImprovementTrend
    
    /// Progress completion percentage
    var completionPercentage: Float {
        guard totalGoals > 0 else { return 0.0 }
        return Float(goalsAchieved) / Float(totalGoals)
    }
    
    /// Average sessions per day
    var averageSessionsPerDay: Float {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        return Float(totalSessions) / Float(max(1, days))
    }
    
    /// Average time per session
    var averageTimePerSession: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalTimeSpent / TimeInterval(totalSessions)
    }
    
    /// Performance level based on accuracy
    var performanceLevel: PerformanceLevel {
        switch averageAccuracy {
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

/// Daily progress tracking
struct DailyProgress: Codable, Identifiable {
    let id: String
    let date: Date
    let sessionsCompleted: Int
    let timeSpent: TimeInterval
    let averageAccuracy: Float
    let scoreEarned: Int
    let goalsMet: [String] // Goal IDs that were met
    let isGoalAchieved: Bool
    
    init(date: Date, sessionsCompleted: Int = 0, timeSpent: TimeInterval = 0, averageAccuracy: Float = 0, scoreEarned: Int = 0, goalsMet: [String] = [], isGoalAchieved: Bool = false) {
        self.id = UUID().uuidString
        self.date = date
        self.sessionsCompleted = sessionsCompleted
        self.timeSpent = timeSpent
        self.averageAccuracy = averageAccuracy
        self.scoreEarned = scoreEarned
        self.goalsMet = goalsMet
        self.isGoalAchieved = isGoalAchieved
    }
    
    /// Formatted time spent
    var formattedTimeSpent: String {
        let minutes = Int(timeSpent / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    /// Day of week
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

/// Progress by category
struct CategoryProgress: Codable {
    let category: AchievementCategory
    let sessionsCompleted: Int
    let averageAccuracy: Float
    let timeSpent: TimeInterval
    let improvementRate: Float
    let strongestSkills: [String]
    let improvementAreas: [String]
    
    /// Performance level for this category
    var performanceLevel: PerformanceLevel {
        switch averageAccuracy {
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

/// Progress by difficulty level
struct DifficultyProgress: Codable {
    let difficulty: DifficultyLevel
    let sessionsCompleted: Int
    let averageAccuracy: Float
    let timeSpent: TimeInterval
    let masteryLevel: MasteryLevel
    let recommendedNext: DifficultyLevel?
    
    /// Whether user has mastered this difficulty
    var isMastered: Bool {
        return masteryLevel == .mastered
    }
    
    /// Progress percentage toward mastery
    var masteryProgress: Float {
        switch masteryLevel {
        case .beginner:
            return 0.2
        case .developing:
            return 0.4
        case .proficient:
            return 0.7
        case .advanced:
            return 0.9
        case .mastered:
            return 1.0
        }
    }
}

/// Learning streak information
struct LearningStreak: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let streakStartDate: Date?
    let lastActivityDate: Date
    let streakLevel: StreakLevel
    let daysUntilReset: Int
    let milestones: [StreakMilestone]
    let nextMilestone: StreakMilestone?
    
    /// Whether streak is active (within last 24 hours)
    var isActive: Bool {
        let daysSinceLastActivity = Calendar.current.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
        return daysSinceLastActivity <= 1
    }
    
    /// Streak status message
    var statusMessage: String {
        if isActive {
            return "Chuỗi học tập: \(currentStreak) ngày 🔥"
        } else {
            return "Hãy tiếp tục học để duy trì chuỗi! 💪"
        }
    }
}

/// User analytics for detailed insights
struct UserAnalytics: Codable {
    let userId: String
    let period: ProgressPeriod
    let totalLearningTime: TimeInterval
    let averageSessionLength: TimeInterval
    let mostActiveDay: String
    let mostActiveTime: String
    let preferredDifficulty: DifficultyLevel
    let strongestCategory: AchievementCategory
    let improvementAreas: [AchievementCategory]
    let learningVelocity: LearningVelocity
    let consistencyScore: Float
    let engagementScore: Float
    let retentionRate: Float
    let weeklyPattern: [WeeklyActivity]
    let monthlyTrend: [MonthlyTrend]
    
    /// Overall learning health score (0-100)
    var learningHealthScore: Int {
        let consistency = consistencyScore * 30
        let engagement = engagementScore * 30
        let retention = retentionRate * 40
        return Int((consistency + engagement + retention) * 100)
    }
}

/// Learning goals configuration
struct LearningGoals: Codable {
    let userId: String
    let dailySessionGoal: Int
    let dailyTimeGoal: TimeInterval // in minutes
    let weeklySessionGoal: Int
    let accuracyGoal: Float
    let streakGoal: Int
    let customGoals: [CustomGoal]
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    /// Default learning goals for new users
    static func defaultGoals(for userId: String) -> LearningGoals {
        return LearningGoals(
            userId: userId,
            dailySessionGoal: 3,
            dailyTimeGoal: 15 * 60, // 15 minutes
            weeklySessionGoal: 20,
            accuracyGoal: 0.8, // 80%
            streakGoal: 7, // 1 week
            customGoals: [],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Custom user-defined goal
struct CustomGoal: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let targetValue: Int
    let currentValue: Int
    let deadline: Date?
    let category: GoalCategory
    let isCompleted: Bool
    let createdAt: Date
    
    /// Progress percentage toward goal
    var progress: Float {
        guard targetValue > 0 else { return 0 }
        return min(1.0, Float(currentValue) / Float(targetValue))
    }
    
    /// Days remaining until deadline
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }
}

/// Progress comparison with peers
struct ProgressComparison: Codable {
    let userRank: Int
    let totalUsers: Int
    let percentile: Float
    let averageAccuracy: Float
    let userAccuracy: Float
    let averageSessionsPerWeek: Float
    let userSessionsPerWeek: Float
    let averageStreak: Int
    let userStreak: Int
    let comparisonInsights: [ComparisonInsight]
    
    /// User's performance relative to peers
    var relativePerformance: RelativePerformance {
        switch percentile {
        case 0.9...1.0:
            return .topPerformer
        case 0.7..<0.9:
            return .aboveAverage
        case 0.3..<0.7:
            return .average
        case 0.1..<0.3:
            return .belowAverage
        default:
            return .needsSupport
        }
    }
}

/// Learning insight with recommendations
struct LearningInsight: Codable, Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let recommendation: String
    let priority: InsightPriority
    let actionable: Bool
    let relatedData: [String: String]
    let createdAt: Date
    
    /// Icon for the insight type
    var icon: String {
        switch type {
        case .improvement:
            return "chart.line.uptrend.xyaxis"
        case .consistency:
            return "calendar.badge.clock"
        case .difficulty:
            return "slider.horizontal.3"
        case .engagement:
            return "heart.fill"
        case .achievement:
            return "trophy.fill"
        case .streak:
            return "flame.fill"
        case .goal:
            return "target"
        }
    }
    
    /// Color for the insight priority
    var priorityColor: String {
        switch priority {
        case .high:
            return "red"
        case .medium:
            return "orange"
        case .low:
            return "blue"
        }
    }
}

// MARK: - Supporting Enums

/// Progress tracking periods
enum ProgressPeriod: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case allTime = "allTime"
    
    var localizedName: String {
        switch self {
        case .daily:
            return "Hôm nay"
        case .weekly:
            return "Tuần này"
        case .monthly:
            return "Tháng này"
        case .yearly:
            return "Năm này"
        case .allTime:
            return "Tất cả"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return (start, end)
        case .weekly:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
            return (start, end)
        case .monthly:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return (start, end)
        case .yearly:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? now
            return (start, end)
        case .allTime:
            return (Date.distantPast, Date.distantFuture)
        }
    }
}

/// Performance levels
enum PerformanceLevel: String, CaseIterable, Codable {
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
}

/// Mastery levels for difficulty progression
enum MasteryLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case developing = "developing"
    case proficient = "proficient"
    case advanced = "advanced"
    case mastered = "mastered"
    
    var localizedName: String {
        switch self {
        case .beginner:
            return "Mới bắt đầu"
        case .developing:
            return "Đang phát triển"
        case .proficient:
            return "Thành thạo"
        case .advanced:
            return "Nâng cao"
        case .mastered:
            return "Thành thạo hoàn toàn"
        }
    }
    
    var requiredAccuracy: Float {
        switch self {
        case .beginner:
            return 0.5
        case .developing:
            return 0.65
        case .proficient:
            return 0.8
        case .advanced:
            return 0.9
        case .mastered:
            return 0.95
        }
    }
    
    var requiredSessions: Int {
        switch self {
        case .beginner:
            return 5
        case .developing:
            return 15
        case .proficient:
            return 30
        case .advanced:
            return 50
        case .mastered:
            return 100
        }
    }
}

/// Learning velocity tracking
struct LearningVelocity: Codable {
    let sessionsPerWeek: Float
    let accuracyImprovement: Float
    let difficultyProgression: Float
    let overallVelocity: Float
    
    var velocityLevel: VelocityLevel {
        switch overallVelocity {
        case 0.8...1.0:
            return .fast
        case 0.5..<0.8:
            return .moderate
        case 0.2..<0.5:
            return .slow
        default:
            return .stagnant
        }
    }
}

/// Velocity levels
enum VelocityLevel: String, CaseIterable, Codable {
    case fast = "fast"
    case moderate = "moderate"
    case slow = "slow"
    case stagnant = "stagnant"
    
    var localizedName: String {
        switch self {
        case .fast:
            return "Nhanh"
        case .moderate:
            return "Vừa phải"
        case .slow:
            return "Chậm"
        case .stagnant:
            return "Đình trệ"
        }
    }
    
    var color: String {
        switch self {
        case .fast:
            return "green"
        case .moderate:
            return "blue"
        case .slow:
            return "orange"
        case .stagnant:
            return "red"
        }
    }
}

/// Weekly activity pattern
struct WeeklyActivity: Codable {
    let dayOfWeek: Int // 1 = Sunday, 2 = Monday, etc.
    let averageSessions: Float
    let averageAccuracy: Float
    let totalTimeSpent: TimeInterval
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.weekdaySymbols[dayOfWeek - 1]
    }
}

/// Monthly trend data
struct MonthlyTrend: Codable {
    let month: Int
    let year: Int
    let totalSessions: Int
    let averageAccuracy: Float
    let totalScore: Int
    let improvementRate: Float
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.monthSymbols[month - 1]
    }
}

/// Improvement trend analysis
struct ImprovementTrend: Codable {
    let direction: TrendDirection
    let magnitude: Float
    let consistency: Float
    let recentChange: Float
    let projectedImprovement: Float
    
    var trendDescription: String {
        switch direction {
        case .improving:
            return "Đang tiến bộ (+\(Int(magnitude * 100))%)"
        case .declining:
            return "Cần cải thiện (\(Int(magnitude * 100))%)"
        case .stable:
            return "Ổn định"
        }
    }
}

/// Trend directions
enum TrendDirection: String, CaseIterable, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    
    var emoji: String {
        switch self {
        case .improving:
            return "📈"
        case .declining:
            return "📉"
        case .stable:
            return "➡️"
        }
    }
}

/// Goal categories
enum GoalCategory: String, CaseIterable, Codable {
    case sessions = "sessions"
    case accuracy = "accuracy"
    case time = "time"
    case streak = "streak"
    case score = "score"
    case custom = "custom"
    
    var localizedName: String {
        switch self {
        case .sessions:
            return "Số buổi học"
        case .accuracy:
            return "Độ chính xác"
        case .time:
            return "Thời gian học"
        case .streak:
            return "Chuỗi học tập"
        case .score:
            return "Điểm số"
        case .custom:
            return "Tùy chỉnh"
        }
    }
    
    var icon: String {
        switch self {
        case .sessions:
            return "book.fill"
        case .accuracy:
            return "target"
        case .time:
            return "clock.fill"
        case .streak:
            return "flame.fill"
        case .score:
            return "star.fill"
        case .custom:
            return "gear"
        }
    }
}

/// Relative performance compared to peers
enum RelativePerformance: String, CaseIterable, Codable {
    case topPerformer = "topPerformer"
    case aboveAverage = "aboveAverage"
    case average = "average"
    case belowAverage = "belowAverage"
    case needsSupport = "needsSupport"
    
    var localizedName: String {
        switch self {
        case .topPerformer:
            return "Xuất sắc nhất"
        case .aboveAverage:
            return "Trên trung bình"
        case .average:
            return "Trung bình"
        case .belowAverage:
            return "Dưới trung bình"
        case .needsSupport:
            return "Cần hỗ trợ"
        }
    }
    
    var color: String {
        switch self {
        case .topPerformer:
            return "gold"
        case .aboveAverage:
            return "green"
        case .average:
            return "blue"
        case .belowAverage:
            return "orange"
        case .needsSupport:
            return "red"
        }
    }
}

/// Comparison insights
struct ComparisonInsight: Codable {
    let type: ComparisonType
    let message: String
    let recommendation: String
    let isPositive: Bool
}

/// Comparison types
enum ComparisonType: String, CaseIterable, Codable {
    case accuracy = "accuracy"
    case consistency = "consistency"
    case engagement = "engagement"
    case improvement = "improvement"
}

/// Insight types
enum InsightType: String, CaseIterable, Codable {
    case improvement = "improvement"
    case consistency = "consistency"
    case difficulty = "difficulty"
    case engagement = "engagement"
    case achievement = "achievement"
    case streak = "streak"
    case goal = "goal"
}

/// Insight priorities
enum InsightPriority: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

/// Export formats
enum ExportFormat: String, CaseIterable, Codable {
    case json = "json"
    case csv = "csv"
    case pdf = "pdf"
    
    var fileExtension: String {
        return rawValue
    }
    
    var mimeType: String {
        switch self {
        case .json:
            return "application/json"
        case .csv:
            return "text/csv"
        case .pdf:
            return "application/pdf"
        }
    }
}