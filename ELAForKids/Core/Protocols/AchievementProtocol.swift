import Foundation

// MARK: - Achievement Protocol
protocol AchievementProtocol {
    /// Check for new achievements based on session result
    func checkForNewAchievements(sessionResult: SessionResult) async throws -> [Achievement]
    
    /// Unlock specific achievement for user
    func unlockAchievement(_ achievementId: String, for userId: String) async throws -> Achievement?
    
    /// Get all achievements for user
    func getUserAchievements(userId: String) async throws -> [UserAchievement]
    
    /// Get all available achievements
    func getAvailableAchievements() async throws -> [Achievement]
    
    /// Get achievement progress for user
    func getAchievementProgress(userId: String, achievementId: String) async throws -> AchievementProgress?
    
    /// Get achievements by category
    func getAchievementsByCategory(_ category: AchievementCategory) async throws -> [Achievement]
    
    /// Check if user has specific achievement
    func hasAchievement(userId: String, achievementId: String) async throws -> Bool
    
    /// Get recent achievements for user (last 30 days)
    func getRecentAchievements(userId: String, limit: Int) async throws -> [UserAchievement]
}

// MARK: - Achievement Data Models

/// Achievement definition
struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let difficulty: AchievementDifficulty
    let requirements: AchievementRequirements
    let rewards: AchievementRewards
    let badge: BadgeInfo
    let isSecret: Bool
    let sortOrder: Int
    
    /// Localized title for display
    var localizedTitle: String {
        return title
    }
    
    /// Localized description for display
    var localizedDescription: String {
        return description
    }
    
    /// Points value for this achievement
    var pointValue: Int {
        return rewards.points
    }
    
    /// Whether this achievement can be earned multiple times
    var isRepeatable: Bool {
        return requirements.isRepeatable
    }
}

/// User's achievement with unlock information
struct UserAchievement: Codable, Identifiable {
    let id: String
    let userId: String
    let achievementId: String
    let unlockedAt: Date
    let progress: AchievementProgress
    let isNew: Bool // For UI highlighting
    
    /// The achievement definition
    var achievement: Achievement? {
        // This would be populated by the service
        return nil
    }
}

/// Achievement progress tracking
struct AchievementProgress: Codable {
    let current: Int
    let target: Int
    let percentage: Float
    let milestones: [ProgressMilestone]
    
    /// Whether the achievement is completed
    var isCompleted: Bool {
        return current >= target
    }
    
    /// Progress as a value between 0.0 and 1.0
    var normalizedProgress: Float {
        return min(1.0, Float(current) / Float(target))
    }
    
    /// Remaining progress needed
    var remaining: Int {
        return max(0, target - current)
    }
}

/// Progress milestone for incremental achievements
struct ProgressMilestone: Codable {
    let value: Int
    let title: String
    let reward: Int // Bonus points for reaching milestone
    let isReached: Bool
}

/// Achievement categories
enum AchievementCategory: String, CaseIterable, Codable {
    case reading = "reading"
    case accuracy = "accuracy"
    case streak = "streak"
    case volume = "volume"
    case speed = "speed"
    case special = "special"
    case social = "social"
    case improvement = "improvement"
    
    var localizedName: String {
        switch self {
        case .reading:
            return "Đọc sách"
        case .accuracy:
            return "Độ chính xác"
        case .streak:
            return "Chuỗi thành công"
        case .volume:
            return "Số lượng"
        case .speed:
            return "Tốc độ"
        case .special:
            return "Đặc biệt"
        case .social:
            return "Xã hội"
        case .improvement:
            return "Tiến bộ"
        }
    }
    
    var icon: String {
        switch self {
        case .reading:
            return "book.fill"
        case .accuracy:
            return "target"
        case .streak:
            return "flame.fill"
        case .volume:
            return "chart.bar.fill"
        case .speed:
            return "speedometer"
        case .special:
            return "star.fill"
        case .social:
            return "person.2.fill"
        case .improvement:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: String {
        switch self {
        case .reading:
            return "blue"
        case .accuracy:
            return "green"
        case .streak:
            return "orange"
        case .volume:
            return "purple"
        case .speed:
            return "red"
        case .special:
            return "gold"
        case .social:
            return "pink"
        case .improvement:
            return "teal"
        }
    }
}

/// Achievement difficulty levels
enum AchievementDifficulty: String, CaseIterable, Codable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var localizedName: String {
        switch self {
        case .bronze:
            return "Đồng"
        case .silver:
            return "Bạc"
        case .gold:
            return "Vàng"
        case .platinum:
            return "Bạch kim"
        case .diamond:
            return "Kim cương"
        }
    }
    
    var pointMultiplier: Float {
        switch self {
        case .bronze:
            return 1.0
        case .silver:
            return 1.5
        case .gold:
            return 2.0
        case .platinum:
            return 3.0
        case .diamond:
            return 5.0
        }
    }
    
    var color: String {
        switch self {
        case .bronze:
            return "brown"
        case .silver:
            return "gray"
        case .gold:
            return "yellow"
        case .platinum:
            return "cyan"
        case .diamond:
            return "purple"
        }
    }
    
    var emoji: String {
        switch self {
        case .bronze:
            return "🥉"
        case .silver:
            return "🥈"
        case .gold:
            return "🥇"
        case .platinum:
            return "💎"
        case .diamond:
            return "💠"
        }
    }
}

/// Achievement requirements
struct AchievementRequirements: Codable {
    let type: RequirementType
    let target: Int
    let conditions: [RequirementCondition]
    let timeframe: TimeFrame?
    let isRepeatable: Bool
    
    /// Check if requirements are met by session result
    func isMet(by sessionResult: SessionResult, userStats: UserStatistics) -> Bool {
        // Implementation would check all conditions
        return checkConditions(sessionResult: sessionResult, userStats: userStats)
    }
    
    private func checkConditions(sessionResult: SessionResult, userStats: UserStatistics) -> Bool {
        for condition in conditions {
            if !condition.isMet(by: sessionResult, userStats: userStats) {
                return false
            }
        }
        return true
    }
}

/// Requirement types
enum RequirementType: String, Codable {
    case sessionCount = "sessionCount"
    case accuracy = "accuracy"
    case streak = "streak"
    case perfectSessions = "perfectSessions"
    case totalScore = "totalScore"
    case timeSpent = "timeSpent"
    case difficulty = "difficulty"
    case improvement = "improvement"
    case consecutive = "consecutive"
}

/// Individual requirement condition
struct RequirementCondition: Codable {
    let type: RequirementType
    let operator: ComparisonOperator
    let value: Float
    let additionalParams: [String: String]?
    
    func isMet(by sessionResult: SessionResult, userStats: UserStatistics) -> Bool {
        let actualValue = extractValue(from: sessionResult, userStats: userStats)
        
        switch `operator` {
        case .equal:
            return actualValue == value
        case .greaterThan:
            return actualValue > value
        case .greaterThanOrEqual:
            return actualValue >= value
        case .lessThan:
            return actualValue < value
        case .lessThanOrEqual:
            return actualValue <= value
        }
    }
    
    private func extractValue(from sessionResult: SessionResult, userStats: UserStatistics) -> Float {
        switch type {
        case .accuracy:
            return sessionResult.accuracy
        case .totalScore:
            return Float(userStats.totalScore)
        case .streak:
            return Float(userStats.currentStreak)
        case .sessionCount:
            return Float(userStats.totalSessions)
        case .timeSpent:
            return Float(sessionResult.timeSpent)
        case .difficulty:
            return Float(sessionResult.difficulty.rawValue.suffix(1)) ?? 1.0
        case .perfectSessions:
            return sessionResult.accuracy >= 1.0 ? 1.0 : 0.0
        case .improvement:
            return userStats.averageAccuracy
        case .consecutive:
            return Float(userStats.currentStreak)
        }
    }
}

/// Comparison operators for requirements
enum ComparisonOperator: String, Codable {
    case equal = "=="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    case lessThan = "<"
    case lessThanOrEqual = "<="
}

/// Time frame for achievements
enum TimeFrame: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "allTime"
    
    var localizedName: String {
        switch self {
        case .daily:
            return "Hàng ngày"
        case .weekly:
            return "Hàng tuần"
        case .monthly:
            return "Hàng tháng"
        case .allTime:
            return "Tất cả thời gian"
        }
    }
}

/// Achievement rewards
struct AchievementRewards: Codable {
    let points: Int
    let experience: Int
    let badge: String
    let title: String?
    let specialEffect: String?
    let unlockContent: [String]? // IDs of content unlocked
    
    /// Total reward value
    var totalValue: Int {
        return points + experience
    }
}

/// Badge information
struct BadgeInfo: Codable {
    let id: String
    let name: String
    let description: String
    let imageName: String
    let emoji: String
    let rarity: BadgeRarity
    let animationType: BadgeAnimation
    
    /// Display name for the badge
    var displayName: String {
        return name
    }
}

/// Badge rarity levels
enum BadgeRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var localizedName: String {
        switch self {
        case .common:
            return "Thông thường"
        case .uncommon:
            return "Không phổ biến"
        case .rare:
            return "Hiếm"
        case .epic:
            return "Sử thi"
        case .legendary:
            return "Huyền thoại"
        }
    }
    
    var color: String {
        switch self {
        case .common:
            return "gray"
        case .uncommon:
            return "green"
        case .rare:
            return "blue"
        case .epic:
            return "purple"
        case .legendary:
            return "orange"
        }
    }
}

/// Badge animation types
enum BadgeAnimation: String, CaseIterable, Codable {
    case none = "none"
    case pulse = "pulse"
    case glow = "glow"
    case sparkle = "sparkle"
    case bounce = "bounce"
    case rotate = "rotate"
    
    var duration: TimeInterval {
        switch self {
        case .none:
            return 0
        case .pulse:
            return 1.0
        case .glow:
            return 2.0
        case .sparkle:
            return 1.5
        case .bounce:
            return 0.8
        case .rotate:
            return 3.0
        }
    }
}

/// Achievement notification for UI
struct AchievementNotification {
    let achievement: Achievement
    let userAchievement: UserAchievement
    let isFirstTime: Bool
    let celebrationLevel: CelebrationLevel
    
    var title: String {
        return achievement.title
    }
    
    var message: String {
        if isFirstTime {
            return "Chúc mừng! Bạn đã mở khóa thành tích mới!"
        } else {
            return "Bạn đã đạt được thành tích này lần nữa!"
        }
    }
}

/// Celebration levels for achievements
enum CelebrationLevel: String, CaseIterable {
    case minimal = "minimal"
    case standard = "standard"
    case grand = "grand"
    case epic = "epic"
    
    var duration: TimeInterval {
        switch self {
        case .minimal:
            return 2.0
        case .standard:
            return 3.0
        case .grand:
            return 5.0
        case .epic:
            return 8.0
        }
    }
    
    var effectIntensity: Float {
        switch self {
        case .minimal:
            return 0.3
        case .standard:
            return 0.6
        case .grand:
            return 0.8
        case .epic:
            return 1.0
        }
    }
}