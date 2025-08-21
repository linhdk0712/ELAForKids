import Foundation

// MARK: - Streak Manager
final class StreakManager: StreakManagerProtocol {
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let streakThreshold: Float = 0.8 // 80% accuracy required to maintain streak
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - StreakManagerProtocol Implementation
    
    func updateStreak(userId: String, isSuccess: Bool) async throws -> Int {
        let currentStreak = try await getCurrentStreak(userId: userId)
        let newStreak: Int
        
        if isSuccess {
            newStreak = currentStreak + 1
        } else {
            newStreak = 0
        }
        
        // Update streak in storage
        userDefaults.set(newStreak, forKey: streakKey(for: userId))
        
        // Update last streak date
        userDefaults.set(Date(), forKey: lastStreakDateKey(for: userId))
        
        // Update best streak if necessary
        let bestStreak = getBestStreak(userId: userId)
        if newStreak > bestStreak {
            userDefaults.set(newStreak, forKey: bestStreakKey(for: userId))
        }
        
        return newStreak
    }
    
    func getCurrentStreak(userId: String) async throws -> Int {
        // Check if streak should be reset due to inactivity
        if shouldResetStreakDueToInactivity(userId: userId) {
            try await resetStreak(userId: userId)
            return 0
        }
        
        return userDefaults.integer(forKey: streakKey(for: userId))
    }
    
    func resetStreak(userId: String) async throws {
        userDefaults.set(0, forKey: streakKey(for: userId))
        userDefaults.set(Date(), forKey: lastStreakDateKey(for: userId))
    }
    
    // MARK: - Additional Streak Methods
    
    /// Update streak based on session result
    func updateStreakFromSession(userId: String, sessionResult: SessionResult) async throws -> StreakResult {
        let isSuccess = sessionResult.accuracy >= streakThreshold
        let newStreak = try await updateStreak(userId: userId, isSuccess: isSuccess)
        
        let streakResult = StreakResult(
            currentStreak: newStreak,
            isSuccess: isSuccess,
            previousStreak: isSuccess ? newStreak - 1 : newStreak + 1,
            bestStreak: getBestStreak(userId: userId),
            streakBonus: calculateStreakBonus(streak: newStreak),
            milestone: getStreakMilestone(streak: newStreak)
        )
        
        return streakResult
    }
    
    /// Get best streak for user
    func getBestStreak(userId: String) -> Int {
        return userDefaults.integer(forKey: bestStreakKey(for: userId))
    }
    
    /// Get streak statistics
    func getStreakStatistics(userId: String) async throws -> StreakStatistics {
        let currentStreak = try await getCurrentStreak(userId: userId)
        let bestStreak = getBestStreak(userId: userId)
        let lastStreakDate = userDefaults.object(forKey: lastStreakDateKey(for: userId)) as? Date
        
        return StreakStatistics(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            lastStreakDate: lastStreakDate,
            streakLevel: getStreakLevel(streak: currentStreak),
            daysUntilReset: getDaysUntilStreakReset(userId: userId)
        )
    }
    
    /// Check if user qualifies for streak bonus
    func qualifiesForStreakBonus(accuracy: Float) -> Bool {
        return accuracy >= streakThreshold
    }
    
    // MARK: - Private Methods
    
    private func streakKey(for userId: String) -> String {
        return "streak_\(userId)"
    }
    
    private func bestStreakKey(for userId: String) -> String {
        return "best_streak_\(userId)"
    }
    
    private func lastStreakDateKey(for userId: String) -> String {
        return "last_streak_date_\(userId)"
    }
    
    private func shouldResetStreakDueToInactivity(userId: String) -> Bool {
        guard let lastDate = userDefaults.object(forKey: lastStreakDateKey(for: userId)) as? Date else {
            return false
        }
        
        let daysSinceLastActivity = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastActivity > 7 // Reset after 7 days of inactivity
    }
    
    private func getDaysUntilStreakReset(userId: String) -> Int {
        guard let lastDate = userDefaults.object(forKey: lastStreakDateKey(for: userId)) as? Date else {
            return 7
        }
        
        let daysSinceLastActivity = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return max(0, 7 - daysSinceLastActivity)
    }
    
    private func calculateStreakBonus(streak: Int) -> Int {
        switch streak {
        case 0...2:
            return 0
        case 3...5:
            return 25
        case 6...10:
            return 50
        case 11...20:
            return 100
        case 21...50:
            return 200
        default:
            return 300
        }
    }
    
    private func getStreakLevel(streak: Int) -> StreakLevel {
        switch streak {
        case 0...2:
            return .beginner
        case 3...7:
            return .bronze
        case 8...15:
            return .silver
        case 16...30:
            return .gold
        case 31...50:
            return .platinum
        default:
            return .diamond
        }
    }
    
    private func getStreakMilestone(streak: Int) -> StreakMilestone? {
        let milestones = [3, 5, 7, 10, 15, 20, 25, 30, 50, 100]
        
        if milestones.contains(streak) {
            return StreakMilestone(
                streak: streak,
                title: getMilestoneTitle(for: streak),
                description: getMilestoneDescription(for: streak),
                reward: getMilestoneReward(for: streak)
            )
        }
        
        return nil
    }
    
    private func getMilestoneTitle(for streak: Int) -> String {
        switch streak {
        case 3:
            return "Khởi đầu tốt!"
        case 5:
            return "Kiên trì!"
        case 7:
            return "Một tuần hoàn hảo!"
        case 10:
            return "Thành thạo!"
        case 15:
            return "Chuyên gia nhỏ!"
        case 20:
            return "Siêu sao đọc!"
        case 25:
            return "Bậc thầy ngôn ngữ!"
        case 30:
            return "Huyền thoại!"
        case 50:
            return "Vô địch toàn quốc!"
        case 100:
            return "Thần đồng tiếng Việt!"
        default:
            return "Thành tích tuyệt vời!"
        }
    }
    
    private func getMilestoneDescription(for streak: Int) -> String {
        switch streak {
        case 3:
            return "Bé đã đọc đúng 3 lần liên tiếp!"
        case 5:
            return "Bé đã đọc đúng 5 lần liên tiếp!"
        case 7:
            return "Bé đã đọc đúng cả tuần!"
        case 10:
            return "Bé đã đọc đúng 10 lần liên tiếp!"
        case 15:
            return "Bé đã đọc đúng 15 lần liên tiếp!"
        case 20:
            return "Bé đã đọc đúng 20 lần liên tiếp!"
        case 25:
            return "Bé đã đọc đúng 25 lần liên tiếp!"
        case 30:
            return "Bé đã đọc đúng 30 lần liên tiếp!"
        case 50:
            return "Bé đã đọc đúng 50 lần liên tiếp!"
        case 100:
            return "Bé đã đọc đúng 100 lần liên tiếp!"
        default:
            return "Bé đã đạt được thành tích tuyệt vời!"
        }
    }
    
    private func getMilestoneReward(for streak: Int) -> StreakReward {
        let bonusPoints = calculateStreakBonus(streak: streak)
        let badge = getStreakBadge(for: streak)
        
        return StreakReward(
            bonusPoints: bonusPoints,
            badge: badge,
            specialEffect: streak >= 20 ? "fireworks" : "confetti"
        )
    }
    
    private func getStreakBadge(for streak: Int) -> String {
        switch streak {
        case 3:
            return "🔥"
        case 5:
            return "⭐"
        case 7:
            return "🏆"
        case 10:
            return "💎"
        case 15:
            return "👑"
        case 20:
            return "🌟"
        case 25:
            return "🎖️"
        case 30:
            return "🏅"
        case 50:
            return "🥇"
        case 100:
            return "🎯"
        default:
            return "🎉"
        }
    }
}

// MARK: - Streak Data Models

/// Complete streak result information
struct StreakResult {
    let currentStreak: Int
    let isSuccess: Bool
    let previousStreak: Int
    let bestStreak: Int
    let streakBonus: Int
    let milestone: StreakMilestone?
    
    var isNewBest: Bool {
        return currentStreak > bestStreak
    }
    
    var streakChange: Int {
        return currentStreak - previousStreak
    }
}

/// Streak statistics for user profile
struct StreakStatistics {
    let currentStreak: Int
    let bestStreak: Int
    let lastStreakDate: Date?
    let streakLevel: StreakLevel
    let daysUntilReset: Int
    
    var isActive: Bool {
        return daysUntilReset > 0
    }
    
    var progressToNextLevel: Float {
        let currentLevelRange = streakLevel.range
        let progress = Float(currentStreak - currentLevelRange.lowerBound) / Float(currentLevelRange.upperBound - currentLevelRange.lowerBound)
        return min(1.0, max(0.0, progress))
    }
}

/// Streak milestone achievement
struct StreakMilestone {
    let streak: Int
    let title: String
    let description: String
    let reward: StreakReward
}

/// Streak reward information
struct StreakReward {
    let bonusPoints: Int
    let badge: String
    let specialEffect: String
}

/// Streak level categories
enum StreakLevel: String, CaseIterable {
    case beginner = "beginner"
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var localizedName: String {
        switch self {
        case .beginner:
            return "Người mới"
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
    
    var color: String {
        switch self {
        case .beginner:
            return "gray"
        case .bronze:
            return "brown"
        case .silver:
            return "silver"
        case .gold:
            return "gold"
        case .platinum:
            return "platinum"
        case .diamond:
            return "diamond"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner:
            return "🌱"
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
    
    var range: ClosedRange<Int> {
        switch self {
        case .beginner:
            return 0...2
        case .bronze:
            return 3...7
        case .silver:
            return 8...15
        case .gold:
            return 16...30
        case .platinum:
            return 31...50
        case .diamond:
            return 51...Int.max
        }
    }
}