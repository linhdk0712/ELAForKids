import Foundation

// MARK: - Achievement Manager
final class AchievementManager: AchievementProtocol {
    
    // MARK: - Properties
    private let achievementRepository: AchievementRepositoryProtocol
    private let userScoreRepository: UserScoreRepositoryProtocol
    private let notificationCenter: NotificationCenter
    
    // Cache for achievements to avoid repeated database queries
    private var achievementsCache: [Achievement] = []
    private var lastCacheUpdate: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    init(
        achievementRepository: AchievementRepositoryProtocol,
        userScoreRepository: UserScoreRepositoryProtocol,
        notificationCenter: NotificationCenter = .default
    ) {
        self.achievementRepository = achievementRepository
        self.userScoreRepository = userScoreRepository
        self.notificationCenter = notificationCenter
        
        Task {
            await loadDefaultAchievements()
        }
    }
    
    // MARK: - AchievementProtocol Implementation
    
    func checkForNewAchievements(sessionResult: SessionResult) async throws -> [Achievement] {
        let userStats = try await userScoreRepository.getUserStatistics(userId: sessionResult.userId)
        let availableAchievements = try await getAvailableAchievements()
        let userAchievements = try await getUserAchievements(userId: sessionResult.userId)
        
        let unlockedAchievementIds = Set(userAchievements.map { $0.achievementId })
        var newAchievements: [Achievement] = []
        
        for achievement in availableAchievements {
            // Skip if already unlocked and not repeatable
            if unlockedAchievementIds.contains(achievement.id) && !achievement.isRepeatable {
                continue
            }
            
            // Check if requirements are met
            if achievement.requirements.isMet(by: sessionResult, userStats: userStats) {
                // Unlock the achievement
                if let unlockedAchievement = try await unlockAchievement(achievement.id, for: sessionResult.userId) {
                    newAchievements.append(unlockedAchievement)
                    
                    // Post notification for UI
                    postAchievementNotification(achievement: unlockedAchievement, userId: sessionResult.userId)
                }
            }
        }
        
        return newAchievements
    }
    
    func unlockAchievement(_ achievementId: String, for userId: String) async throws -> Achievement? {
        guard let achievement = try await getAchievement(by: achievementId) else {
            return nil
        }
        
        // Check if already unlocked and not repeatable
        let hasAchievement = try await hasAchievement(userId: userId, achievementId: achievementId)
        if hasAchievement && !achievement.isRepeatable {
            return nil
        }
        
        // Create user achievement record
        let userAchievement = UserAchievement(
            id: UUID().uuidString,
            userId: userId,
            achievementId: achievementId,
            unlockedAt: Date(),
            progress: AchievementProgress(
                current: achievement.requirements.target,
                target: achievement.requirements.target,
                percentage: 1.0,
                milestones: []
            ),
            isNew: true
        )
        
        // Save to repository
        try await achievementRepository.saveUserAchievement(userAchievement)
        
        // Award points and experience
        try await userScoreRepository.updateScore(
            userId: userId,
            additionalScore: achievement.rewards.points
        )
        
        // Add achievement to user's collection
        try await userScoreRepository.addAchievement(
            userId: userId,
            achievementId: achievementId
        )
        
        return achievement
    }
    
    func getUserAchievements(userId: String) async throws -> [UserAchievement] {
        return try await achievementRepository.getUserAchievements(userId: userId)
    }
    
    func getAvailableAchievements() async throws -> [Achievement] {
        // Check cache validity
        if let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration,
           !achievementsCache.isEmpty {
            return achievementsCache
        }
        
        // Refresh cache
        achievementsCache = try await achievementRepository.getAllAchievements()
        lastCacheUpdate = Date()
        
        return achievementsCache
    }
    
    func getAchievementProgress(userId: String, achievementId: String) async throws -> AchievementProgress? {
        guard let achievement = try await getAchievement(by: achievementId) else {
            return nil
        }
        
        let userStats = try await userScoreRepository.getUserStatistics(userId: userId)
        let currentValue = getCurrentProgressValue(
            for: achievement.requirements.type,
            userStats: userStats
        )
        
        let progress = AchievementProgress(
            current: currentValue,
            target: achievement.requirements.target,
            percentage: Float(currentValue) / Float(achievement.requirements.target),
            milestones: generateMilestones(for: achievement)
        )
        
        return progress
    }
    
    func getAchievementsByCategory(_ category: AchievementCategory) async throws -> [Achievement] {
        let allAchievements = try await getAvailableAchievements()
        return allAchievements.filter { $0.category == category }
    }
    
    func hasAchievement(userId: String, achievementId: String) async throws -> Bool {
        let userAchievements = try await getUserAchievements(userId: userId)
        return userAchievements.contains { $0.achievementId == achievementId }
    }
    
    func getRecentAchievements(userId: String, limit: Int) async throws -> [UserAchievement] {
        let allUserAchievements = try await getUserAchievements(userId: userId)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        
        let recentAchievements = allUserAchievements
            .filter { $0.unlockedAt >= thirtyDaysAgo }
            .sorted { $0.unlockedAt > $1.unlockedAt }
        
        return Array(recentAchievements.prefix(limit))
    }
    
    // MARK: - Additional Methods
    
    /// Get achievement statistics for user
    func getAchievementStatistics(userId: String) async throws -> AchievementStatistics {
        let userAchievements = try await getUserAchievements(userId: userId)
        let allAchievements = try await getAvailableAchievements()
        
        let totalAchievements = allAchievements.count
        let unlockedAchievements = userAchievements.count
        let completionPercentage = Float(unlockedAchievements) / Float(totalAchievements)
        
        // Calculate points from achievements
        let achievementPoints = userAchievements.compactMap { userAchievement in
            allAchievements.first { $0.id == userAchievement.achievementId }?.rewards.points
        }.reduce(0, +)
        
        // Group by category
        let categoryStats = Dictionary(grouping: userAchievements) { userAchievement in
            allAchievements.first { $0.id == userAchievement.achievementId }?.category ?? .special
        }.mapValues { $0.count }
        
        // Group by difficulty
        let difficultyStats = Dictionary(grouping: userAchievements) { userAchievement in
            allAchievements.first { $0.id == userAchievement.achievementId }?.difficulty ?? .bronze
        }.mapValues { $0.count }
        
        return AchievementStatistics(
            totalAchievements: totalAchievements,
            unlockedAchievements: unlockedAchievements,
            completionPercentage: completionPercentage,
            achievementPoints: achievementPoints,
            categoryStats: categoryStats,
            difficultyStats: difficultyStats,
            recentUnlocks: try await getRecentAchievements(userId: userId, limit: 5)
        )
    }
    
    /// Get next achievable achievements for user
    func getNextAchievableAchievements(userId: String, limit: Int) async throws -> [AchievementWithProgress] {
        let userStats = try await userScoreRepository.getUserStatistics(userId: userId)
        let allAchievements = try await getAvailableAchievements()
        let userAchievements = try await getUserAchievements(userId: userId)
        
        let unlockedIds = Set(userAchievements.map { $0.achievementId })
        
        var achievementsWithProgress: [AchievementWithProgress] = []
        
        for achievement in allAchievements {
            // Skip if already unlocked and not repeatable
            if unlockedIds.contains(achievement.id) && !achievement.isRepeatable {
                continue
            }
            
            // Calculate progress
            let currentValue = getCurrentProgressValue(
                for: achievement.requirements.type,
                userStats: userStats
            )
            
            let progress = AchievementProgress(
                current: currentValue,
                target: achievement.requirements.target,
                percentage: Float(currentValue) / Float(achievement.requirements.target),
                milestones: generateMilestones(for: achievement)
            )
            
            // Only include achievements with some progress or very close to completion
            if progress.percentage > 0.1 || progress.remaining <= 5 {
                achievementsWithProgress.append(
                    AchievementWithProgress(achievement: achievement, progress: progress)
                )
            }
        }
        
        // Sort by progress (closest to completion first)
        achievementsWithProgress.sort { $0.progress.percentage > $1.progress.percentage }
        
        return Array(achievementsWithProgress.prefix(limit))
    }
    
    /// Reset user achievements (for testing or admin purposes)
    func resetUserAchievements(userId: String) async throws {
        try await achievementRepository.deleteUserAchievements(userId: userId)
    }
    
    // MARK: - Private Methods
    
    private func getAchievement(by id: String) async throws -> Achievement? {
        let achievements = try await getAvailableAchievements()
        return achievements.first { $0.id == id }
    }
    
    private func getCurrentProgressValue(for type: RequirementType, userStats: UserStatistics) -> Int {
        switch type {
        case .sessionCount:
            return userStats.totalSessions
        case .accuracy:
            return Int(userStats.averageAccuracy * 100)
        case .streak:
            return userStats.currentStreak
        case .perfectSessions:
            return userStats.totalSessions // This would need more specific tracking
        case .totalScore:
            return userStats.totalScore
        case .timeSpent:
            return Int(userStats.totalTimeSpent / 60) // Convert to minutes
        case .difficulty:
            return 1 // This would need session-specific tracking
        case .improvement:
            return Int(userStats.averageAccuracy * 100)
        case .consecutive:
            return userStats.currentStreak
        }
    }
    
    private func generateMilestones(for achievement: Achievement) -> [ProgressMilestone] {
        let target = achievement.requirements.target
        let milestoneCount = min(5, target / 10) // Up to 5 milestones
        
        guard milestoneCount > 0 else { return [] }
        
        var milestones: [ProgressMilestone] = []
        let step = target / milestoneCount
        
        for i in 1...milestoneCount {
            let value = step * i
            let milestone = ProgressMilestone(
                value: value,
                title: "Mốc \(value)",
                reward: achievement.rewards.points / milestoneCount,
                isReached: false // This would be calculated based on current progress
            )
            milestones.append(milestone)
        }
        
        return milestones
    }
    
    private func postAchievementNotification(achievement: Achievement, userId: String) {
        let notification = AchievementNotification(
            achievement: achievement,
            userAchievement: UserAchievement(
                id: UUID().uuidString,
                userId: userId,
                achievementId: achievement.id,
                unlockedAt: Date(),
                progress: AchievementProgress(
                    current: achievement.requirements.target,
                    target: achievement.requirements.target,
                    percentage: 1.0,
                    milestones: []
                ),
                isNew: true
            ),
            isFirstTime: true,
            celebrationLevel: getCelebrationLevel(for: achievement)
        )
        
        notificationCenter.post(
            name: .achievementUnlocked,
            object: notification
        )
    }
    
    private func getCelebrationLevel(for achievement: Achievement) -> CelebrationLevel {
        switch achievement.difficulty {
        case .bronze:
            return .minimal
        case .silver:
            return .standard
        case .gold:
            return .grand
        case .platinum, .diamond:
            return .epic
        }
    }
    
    private func loadDefaultAchievements() async {
        do {
            let existingAchievements = try await achievementRepository.getAllAchievements()
            if existingAchievements.isEmpty {
                let defaultAchievements = createDefaultAchievements()
                for achievement in defaultAchievements {
                    try await achievementRepository.saveAchievement(achievement)
                }
            }
        } catch {
            print("Failed to load default achievements: \(error)")
        }
    }
}

// MARK: - Default Achievements Factory
extension AchievementManager {
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            // Reading Category
            createFirstStepsAchievement(),
            createBookwormAchievement(),
            createReadingMasterAchievement(),
            
            // Accuracy Category
            createPerfectionistAchievement(),
            createSharpshooterAchievement(),
            createFlawlessAchievement(),
            
            // Streak Category
            createOnFireAchievement(),
            createUnstoppableAchievement(),
            createLegendaryStreakAchievement(),
            
            // Volume Category
            createDedicatedLearnerAchievement(),
            createMarathonReaderAchievement(),
            createBookwormEliteAchievement(),
            
            // Speed Category
            createSpeedReaderAchievement(),
            createLightningFastAchievement(),
            createSonicReaderAchievement(),
            
            // Special Category
            createWelcomeAchievement(),
            createFirstPerfectAchievement(),
            createComebackKidAchievement(),
            
            // Improvement Category
            createRisingStarAchievement(),
            createTransformationAchievement(),
            createMasteryAchievement()
        ]
    }
    
    // MARK: - Reading Achievements
    
    private func createFirstStepsAchievement() -> Achievement {
        return Achievement(
            id: "first_steps",
            title: "Những bước đầu tiên",
            description: "Hoàn thành 5 bài đọc đầu tiên",
            category: .reading,
            difficulty: .bronze,
            requirements: AchievementRequirements(
                type: .sessionCount,
                target: 5,
                conditions: [
                    RequirementCondition(
                        type: .sessionCount,
                        operator: .greaterThanOrEqual,
                        value: 5,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 100,
                experience: 50,
                badge: "first_steps_badge",
                title: "Người mới bắt đầu",
                specialEffect: "confetti",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "first_steps_badge",
                name: "Bước đầu tiên",
                description: "Bắt đầu hành trình học tập",
                imageName: "first_steps",
                emoji: "👶",
                rarity: .common,
                animationType: .pulse
            ),
            isSecret: false,
            sortOrder: 1
        )
    }
    
    private func createBookwormAchievement() -> Achievement {
        return Achievement(
            id: "bookworm",
            title: "Mọt sách nhỏ",
            description: "Hoàn thành 50 bài đọc",
            category: .reading,
            difficulty: .silver,
            requirements: AchievementRequirements(
                type: .sessionCount,
                target: 50,
                conditions: [
                    RequirementCondition(
                        type: .sessionCount,
                        operator: .greaterThanOrEqual,
                        value: 50,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 500,
                experience: 250,
                badge: "bookworm_badge",
                title: "Mọt sách",
                specialEffect: "sparkle",
                unlockContent: ["advanced_exercises"]
            ),
            badge: BadgeInfo(
                id: "bookworm_badge",
                name: "Mọt sách",
                description: "Yêu thích đọc sách",
                imageName: "bookworm",
                emoji: "🐛",
                rarity: .uncommon,
                animationType: .glow
            ),
            isSecret: false,
            sortOrder: 2
        )
    }
    
    private func createReadingMasterAchievement() -> Achievement {
        return Achievement(
            id: "reading_master",
            title: "Bậc thầy đọc sách",
            description: "Hoàn thành 200 bài đọc",
            category: .reading,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .sessionCount,
                target: 200,
                conditions: [
                    RequirementCondition(
                        type: .sessionCount,
                        operator: .greaterThanOrEqual,
                        value: 200,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 2000,
                experience: 1000,
                badge: "reading_master_badge",
                title: "Bậc thầy đọc sách",
                specialEffect: "fireworks",
                unlockContent: ["master_exercises", "special_themes"]
            ),
            badge: BadgeInfo(
                id: "reading_master_badge",
                name: "Bậc thầy",
                description: "Thành thạo nghệ thuật đọc",
                imageName: "reading_master",
                emoji: "👑",
                rarity: .epic,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 3
        )
    }
    
    // MARK: - Accuracy Achievements
    
    private func createPerfectionistAchievement() -> Achievement {
        return Achievement(
            id: "perfectionist",
            title: "Người cầu toàn",
            description: "Đạt 100% độ chính xác trong 10 bài đọc",
            category: .accuracy,
            difficulty: .silver,
            requirements: AchievementRequirements(
                type: .perfectSessions,
                target: 10,
                conditions: [
                    RequirementCondition(
                        type: .accuracy,
                        operator: .equal,
                        value: 1.0,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 750,
                experience: 375,
                badge: "perfectionist_badge",
                title: "Người cầu toàn",
                specialEffect: "golden_glow",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "perfectionist_badge",
                name: "Cầu toàn",
                description: "Không chấp nhận sai sót",
                imageName: "perfectionist",
                emoji: "💯",
                rarity: .rare,
                animationType: .glow
            ),
            isSecret: false,
            sortOrder: 4
        )
    }
    
    private func createSharpshooterAchievement() -> Achievement {
        return Achievement(
            id: "sharpshooter",
            title: "Xạ thủ bắn tỉa",
            description: "Duy trì độ chính xác trên 95% trong 25 bài đọc",
            category: .accuracy,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .accuracy,
                target: 25,
                conditions: [
                    RequirementCondition(
                        type: .accuracy,
                        operator: .greaterThanOrEqual,
                        value: 0.95,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 1250,
                experience: 625,
                badge: "sharpshooter_badge",
                title: "Xạ thủ",
                specialEffect: "target_hit",
                unlockContent: ["precision_exercises"]
            ),
            badge: BadgeInfo(
                id: "sharpshooter_badge",
                name: "Xạ thủ",
                description: "Chính xác tuyệt đối",
                imageName: "sharpshooter",
                emoji: "🎯",
                rarity: .epic,
                animationType: .pulse
            ),
            isSecret: false,
            sortOrder: 5
        )
    }
    
    private func createFlawlessAchievement() -> Achievement {
        return Achievement(
            id: "flawless",
            title: "Hoàn hảo tuyệt đối",
            description: "Đạt 100% độ chính xác trong 50 bài đọc",
            category: .accuracy,
            difficulty: .diamond,
            requirements: AchievementRequirements(
                type: .perfectSessions,
                target: 50,
                conditions: [
                    RequirementCondition(
                        type: .accuracy,
                        operator: .equal,
                        value: 1.0,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 5000,
                experience: 2500,
                badge: "flawless_badge",
                title: "Hoàn hảo tuyệt đối",
                specialEffect: "diamond_sparkle",
                unlockContent: ["legendary_exercises", "diamond_theme"]
            ),
            badge: BadgeInfo(
                id: "flawless_badge",
                name: "Hoàn hảo",
                description: "Không một lỗi sai nào",
                imageName: "flawless",
                emoji: "💎",
                rarity: .legendary,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 6
        )
    }
    
    // MARK: - Additional achievement creation methods would continue here...
    // For brevity, I'll include a few more key ones
    
    private func createWelcomeAchievement() -> Achievement {
        return Achievement(
            id: "welcome",
            title: "Chào mừng!",
            description: "Hoàn thành bài đọc đầu tiên",
            category: .special,
            difficulty: .bronze,
            requirements: AchievementRequirements(
                type: .sessionCount,
                target: 1,
                conditions: [
                    RequirementCondition(
                        type: .sessionCount,
                        operator: .greaterThanOrEqual,
                        value: 1,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 50,
                experience: 25,
                badge: "welcome_badge",
                title: "Người mới",
                specialEffect: "welcome_confetti",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "welcome_badge",
                name: "Chào mừng",
                description: "Bước đầu tiên trong hành trình",
                imageName: "welcome",
                emoji: "🎉",
                rarity: .common,
                animationType: .bounce
            ),
            isSecret: false,
            sortOrder: 0
        )
    }
    
    private func createOnFireAchievement() -> Achievement {
        return Achievement(
            id: "on_fire",
            title: "Đang bùng cháy!",
            description: "Đạt chuỗi 10 lần đọc đúng liên tiếp",
            category: .streak,
            difficulty: .silver,
            requirements: AchievementRequirements(
                type: .streak,
                target: 10,
                conditions: [
                    RequirementCondition(
                        type: .streak,
                        operator: .greaterThanOrEqual,
                        value: 10,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: true
            ),
            rewards: AchievementRewards(
                points: 500,
                experience: 250,
                badge: "on_fire_badge",
                title: "Đang bùng cháy",
                specialEffect: "fire_animation",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "on_fire_badge",
                name: "Bùng cháy",
                description: "Chuỗi thành công ấn tượng",
                imageName: "on_fire",
                emoji: "🔥",
                rarity: .uncommon,
                animationType: .glow
            ),
            isSecret: false,
            sortOrder: 7
        )
    }
    
    private func createUnstoppableAchievement() -> Achievement {
        return Achievement(
            id: "unstoppable",
            title: "Không thể cản được!",
            description: "Đạt chuỗi 25 lần đọc đúng liên tiếp",
            category: .streak,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .streak,
                target: 25,
                conditions: [
                    RequirementCondition(
                        type: .streak,
                        operator: .greaterThanOrEqual,
                        value: 25,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: true
            ),
            rewards: AchievementRewards(
                points: 1500,
                experience: 750,
                badge: "unstoppable_badge",
                title: "Không thể cản",
                specialEffect: "lightning_bolt",
                unlockContent: ["streak_master_exercises"]
            ),
            badge: BadgeInfo(
                id: "unstoppable_badge",
                name: "Không thể cản",
                description: "Sức mạnh không giới hạn",
                imageName: "unstoppable",
                emoji: "⚡",
                rarity: .epic,
                animationType: .pulse
            ),
            isSecret: false,
            sortOrder: 8
        )
    }
    
    private func createLegendaryStreakAchievement() -> Achievement {
        return Achievement(
            id: "legendary_streak",
            title: "Chuỗi huyền thoại",
            description: "Đạt chuỗi 100 lần đọc đúng liên tiếp",
            category: .streak,
            difficulty: .diamond,
            requirements: AchievementRequirements(
                type: .streak,
                target: 100,
                conditions: [
                    RequirementCondition(
                        type: .streak,
                        operator: .greaterThanOrEqual,
                        value: 100,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: true
            ),
            rewards: AchievementRewards(
                points: 10000,
                experience: 5000,
                badge: "legendary_streak_badge",
                title: "Huyền thoại chuỗi",
                specialEffect: "legendary_explosion",
                unlockContent: ["legendary_content", "hall_of_fame"]
            ),
            badge: BadgeInfo(
                id: "legendary_streak_badge",
                name: "Huyền thoại",
                description: "Chuỗi thành công không tưởng",
                imageName: "legendary_streak",
                emoji: "🏆",
                rarity: .legendary,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 9
        )
    }
    
    // Additional achievement creation methods would continue...
    private func createDedicatedLearnerAchievement() -> Achievement {
        return Achievement(
            id: "dedicated_learner",
            title: "Học sinh chăm chỉ",
            description: "Dành 60 phút học tập",
            category: .volume,
            difficulty: .bronze,
            requirements: AchievementRequirements(
                type: .timeSpent,
                target: 60,
                conditions: [
                    RequirementCondition(
                        type: .timeSpent,
                        operator: .greaterThanOrEqual,
                        value: 3600, // 60 minutes in seconds
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 200,
                experience: 100,
                badge: "dedicated_learner_badge",
                title: "Học sinh chăm chỉ",
                specialEffect: "study_glow",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "dedicated_learner_badge",
                name: "Chăm chỉ",
                description: "Kiên trì học tập",
                imageName: "dedicated_learner",
                emoji: "📚",
                rarity: .common,
                animationType: .pulse
            ),
            isSecret: false,
            sortOrder: 10
        )
    }
    
    private func createMarathonReaderAchievement() -> Achievement {
        return Achievement(
            id: "marathon_reader",
            title: "Vận động viên marathon đọc",
            description: "Dành 10 giờ học tập",
            category: .volume,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .timeSpent,
                target: 600,
                conditions: [
                    RequirementCondition(
                        type: .timeSpent,
                        operator: .greaterThanOrEqual,
                        value: 36000, // 10 hours in seconds
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 3000,
                experience: 1500,
                badge: "marathon_reader_badge",
                title: "Vận động viên marathon",
                specialEffect: "marathon_finish",
                unlockContent: ["endurance_exercises"]
            ),
            badge: BadgeInfo(
                id: "marathon_reader_badge",
                name: "Marathon",
                description: "Sức bền phi thường",
                imageName: "marathon_reader",
                emoji: "🏃‍♂️",
                rarity: .epic,
                animationType: .bounce
            ),
            isSecret: false,
            sortOrder: 11
        )
    }
    
    private func createBookwormEliteAchievement() -> Achievement {
        return Achievement(
            id: "bookworm_elite",
            title: "Mọt sách siêu hạng",
            description: "Dành 50 giờ học tập",
            category: .volume,
            difficulty: .diamond,
            requirements: AchievementRequirements(
                type: .timeSpent,
                target: 3000,
                conditions: [
                    RequirementCondition(
                        type: .timeSpent,
                        operator: .greaterThanOrEqual,
                        value: 180000, // 50 hours in seconds
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 15000,
                experience: 7500,
                badge: "bookworm_elite_badge",
                title: "Mọt sách siêu hạng",
                specialEffect: "elite_transformation",
                unlockContent: ["elite_content", "master_library"]
            ),
            badge: BadgeInfo(
                id: "bookworm_elite_badge",
                name: "Siêu hạng",
                description: "Đỉnh cao của việc học",
                imageName: "bookworm_elite",
                emoji: "🎓",
                rarity: .legendary,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 12
        )
    }
    
    private func createSpeedReaderAchievement() -> Achievement {
        return Achievement(
            id: "speed_reader",
            title: "Tốc độ ánh sáng",
            description: "Hoàn thành bài đọc trong 30 giây",
            category: .speed,
            difficulty: .silver,
            requirements: AchievementRequirements(
                type: .timeSpent,
                target: 1,
                conditions: [
                    RequirementCondition(
                        type: .timeSpent,
                        operator: .lessThanOrEqual,
                        value: 30,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: true
            ),
            rewards: AchievementRewards(
                points: 300,
                experience: 150,
                badge: "speed_reader_badge",
                title: "Tốc độ ánh sáng",
                specialEffect: "speed_burst",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "speed_reader_badge",
                name: "Tốc độ",
                description: "Nhanh như chớp",
                imageName: "speed_reader",
                emoji: "💨",
                rarity: .uncommon,
                animationType: .pulse
            ),
            isSecret: false,
            sortOrder: 13
        )
    }
    
    private func createLightningFastAchievement() -> Achievement {
        return Achievement(
            id: "lightning_fast",
            title: "Nhanh như sét",
            description: "Hoàn thành 10 bài đọc trong 20 giây mỗi bài",
            category: .speed,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .timeSpent,
                target: 10,
                conditions: [
                    RequirementCondition(
                        type: .timeSpent,
                        operator: .lessThanOrEqual,
                        value: 20,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 1000,
                experience: 500,
                badge: "lightning_fast_badge",
                title: "Nhanh như sét",
                specialEffect: "lightning_strike",
                unlockContent: ["speed_challenges"]
            ),
            badge: BadgeInfo(
                id: "lightning_fast_badge",
                name: "Như sét",
                description: "Tốc độ siêu phàm",
                imageName: "lightning_fast",
                emoji: "⚡",
                rarity: .epic,
                animationType: .glow
            ),
            isSecret: false,
            sortOrder: 14
        )
    }
    
    private func createSonicReaderAchievement() -> Achievement {
        return Achievement(
            id: "sonic_reader",
            title: "Siêu âm thanh",
            description: "Hoàn thành 25 bài đọc trong 15 giây mỗi bài",
            category: .speed,
            difficulty: .diamond,
            requirements: AchievementRequirements(
                type: .timeSpent,
                target: 25,
                conditions: [
                    RequirementCondition(
                        type: .timeSpent,
                        operator: .lessThanOrEqual,
                        value: 15,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 5000,
                experience: 2500,
                badge: "sonic_reader_badge",
                title: "Siêu âm thanh",
                specialEffect: "sonic_boom",
                unlockContent: ["sonic_exercises", "time_master"]
            ),
            badge: BadgeInfo(
                id: "sonic_reader_badge",
                name: "Siêu âm",
                description: "Vượt qua rào cản âm thanh",
                imageName: "sonic_reader",
                emoji: "🚀",
                rarity: .legendary,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 15
        )
    }
    
    private func createFirstPerfectAchievement() -> Achievement {
        return Achievement(
            id: "first_perfect",
            title: "Lần đầu hoàn hảo",
            description: "Đạt 100% độ chính xác lần đầu tiên",
            category: .special,
            difficulty: .bronze,
            requirements: AchievementRequirements(
                type: .accuracy,
                target: 1,
                conditions: [
                    RequirementCondition(
                        type: .accuracy,
                        operator: .equal,
                        value: 1.0,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 200,
                experience: 100,
                badge: "first_perfect_badge",
                title: "Hoàn hảo đầu tiên",
                specialEffect: "first_perfect_celebration",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "first_perfect_badge",
                name: "Hoàn hảo đầu tiên",
                description: "Khoảnh khắc đặc biệt",
                imageName: "first_perfect",
                emoji: "🌟",
                rarity: .uncommon,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 16
        )
    }
    
    private func createComebackKidAchievement() -> Achievement {
        return Achievement(
            id: "comeback_kid",
            title: "Trở lại mạnh mẽ",
            description: "Cải thiện độ chính xác từ dưới 50% lên trên 90%",
            category: .special,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .improvement,
                target: 1,
                conditions: [
                    RequirementCondition(
                        type: .improvement,
                        operator: .greaterThanOrEqual,
                        value: 0.4, // 40% improvement
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 2000,
                experience: 1000,
                badge: "comeback_kid_badge",
                title: "Trở lại mạnh mẽ",
                specialEffect: "comeback_explosion",
                unlockContent: ["comeback_story"]
            ),
            badge: BadgeInfo(
                id: "comeback_kid_badge",
                name: "Trở lại",
                description: "Không bao giờ từ bỏ",
                imageName: "comeback_kid",
                emoji: "💪",
                rarity: .epic,
                animationType: .bounce
            ),
            isSecret: false,
            sortOrder: 17
        )
    }
    
    private func createRisingStarAchievement() -> Achievement {
        return Achievement(
            id: "rising_star",
            title: "Ngôi sao đang lên",
            description: "Cải thiện độ chính xác trung bình lên 20%",
            category: .improvement,
            difficulty: .silver,
            requirements: AchievementRequirements(
                type: .improvement,
                target: 1,
                conditions: [
                    RequirementCondition(
                        type: .improvement,
                        operator: .greaterThanOrEqual,
                        value: 0.2, // 20% improvement
                        additionalParams: nil
                    )
                ],
                timeframe: .monthly,
                isRepeatable: true
            ),
            rewards: AchievementRewards(
                points: 500,
                experience: 250,
                badge: "rising_star_badge",
                title: "Ngôi sao đang lên",
                specialEffect: "star_rise",
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "rising_star_badge",
                name: "Đang lên",
                description: "Tiến bộ vượt bậc",
                imageName: "rising_star",
                emoji: "⭐",
                rarity: .uncommon,
                animationType: .glow
            ),
            isSecret: false,
            sortOrder: 18
        )
    }
    
    private func createTransformationAchievement() -> Achievement {
        return Achievement(
            id: "transformation",
            title: "Biến đổi kỳ diệu",
            description: "Cải thiện độ chính xác trung bình lên 50%",
            category: .improvement,
            difficulty: .gold,
            requirements: AchievementRequirements(
                type: .improvement,
                target: 1,
                conditions: [
                    RequirementCondition(
                        type: .improvement,
                        operator: .greaterThanOrEqual,
                        value: 0.5, // 50% improvement
                        additionalParams: nil
                    )
                ],
                timeframe: .allTime,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 3000,
                experience: 1500,
                badge: "transformation_badge",
                title: "Biến đổi kỳ diệu",
                specialEffect: "transformation_magic",
                unlockContent: ["transformation_story"]
            ),
            badge: BadgeInfo(
                id: "transformation_badge",
                name: "Biến đổi",
                description: "Thay đổi hoàn toàn",
                imageName: "transformation",
                emoji: "🦋",
                rarity: .epic,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 19
        )
    }
    
    private func createMasteryAchievement() -> Achievement {
        return Achievement(
            id: "mastery",
            title: "Thành thạo tuyệt đối",
            description: "Duy trì độ chính xác trên 95% trong 100 bài đọc",
            category: .improvement,
            difficulty: .diamond,
            requirements: AchievementRequirements(
                type: .accuracy,
                target: 100,
                conditions: [
                    RequirementCondition(
                        type: .accuracy,
                        operator: .greaterThanOrEqual,
                        value: 0.95,
                        additionalParams: nil
                    )
                ],
                timeframe: nil,
                isRepeatable: false
            ),
            rewards: AchievementRewards(
                points: 10000,
                experience: 5000,
                badge: "mastery_badge",
                title: "Thành thạo tuyệt đối",
                specialEffect: "mastery_aura",
                unlockContent: ["mastery_hall", "grandmaster_title"]
            ),
            badge: BadgeInfo(
                id: "mastery_badge",
                name: "Thành thạo",
                description: "Đỉnh cao kỹ năng",
                imageName: "mastery",
                emoji: "🏆",
                rarity: .legendary,
                animationType: .sparkle
            ),
            isSecret: false,
            sortOrder: 20
        )
    }
}

// MARK: - Supporting Data Models

/// Achievement with current progress
struct AchievementWithProgress {
    let achievement: Achievement
    let progress: AchievementProgress
    
    var isNearCompletion: Bool {
        return progress.percentage >= 0.8
    }
    
    var estimatedSessionsToComplete: Int {
        guard progress.remaining > 0 else { return 0 }
        return max(1, progress.remaining)
    }
}

/// Achievement statistics for user profile
struct AchievementStatistics {
    let totalAchievements: Int
    let unlockedAchievements: Int
    let completionPercentage: Float
    let achievementPoints: Int
    let categoryStats: [AchievementCategory: Int]
    let difficultyStats: [AchievementDifficulty: Int]
    let recentUnlocks: [UserAchievement]
    
    /// Next achievement tier
    var nextTier: AchievementDifficulty? {
        let currentHighest = difficultyStats.keys.max { $0.pointMultiplier < $1.pointMultiplier }
        let allDifficulties = AchievementDifficulty.allCases.sorted { $0.pointMultiplier < $1.pointMultiplier }
        
        guard let current = currentHighest,
              let currentIndex = allDifficulties.firstIndex(of: current),
              currentIndex < allDifficulties.count - 1 else {
            return nil
        }
        
        return allDifficulties[currentIndex + 1]
    }
    
    /// Achievements needed for next tier
    var achievementsNeededForNextTier: Int {
        guard let nextTier = nextTier else { return 0 }
        let currentCount = difficultyStats[nextTier] ?? 0
        return max(0, 1 - currentCount)
    }
}

// MARK: - Achievement Repository Protocol
protocol AchievementRepositoryProtocol {
    func getAllAchievements() async throws -> [Achievement]
    func saveAchievement(_ achievement: Achievement) async throws
    func getUserAchievements(userId: String) async throws -> [UserAchievement]
    func saveUserAchievement(_ userAchievement: UserAchievement) async throws
    func deleteUserAchievements(userId: String) async throws
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let achievementProgressUpdated = Notification.Name("achievementProgressUpdated")
}