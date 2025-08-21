import XCTest
@testable import ELAForKids

final class RewardSystemTests: XCTestCase {
    
    var rewardSystem: RewardSystem!
    var mockProgressTracker: MockProgressTracker!
    var animationService: RewardAnimationService!
    var soundManager: SoundEffectManager!
    var hapticManager: HapticFeedbackManager!
    
    override func setUpWithError() throws {
        mockProgressTracker = MockProgressTracker()
        animationService = RewardAnimationService()
        soundManager = SoundEffectManager()
        hapticManager = HapticFeedbackManager()
        
        rewardSystem = RewardSystem(
            animationService: animationService,
            soundManager: soundManager,
            hapticManager: hapticManager,
            progressTracker: mockProgressTracker
        )
    }
    
    override func tearDownWithError() throws {
        rewardSystem = nil
        mockProgressTracker = nil
        animationService = nil
        soundManager = nil
        hapticManager = nil
    }
    
    // MARK: - Reward Animation Service Tests
    
    func testRewardAnimationService() async throws {
        // Test perfect score reward
        await animationService.showPerfectScoreReward(score: 100)
        XCTAssertEqual(animationService.rewardMessage, "🌟 Hoàn hảo!\nĐiểm số: 100")
        XCTAssertTrue(animationService.isShowingReward)
        
        // Wait for animation to complete
        try await Task.sleep(nanoseconds: 3_000_000_000)
        XCTAssertFalse(animationService.isShowingReward)
    }
    
    func testAchievementReward() async throws {
        let achievement = Achievement(
            id: "test_achievement",
            title: "Thành tích Test",
            description: "Mô tả thành tích test",
            category: .reading,
            difficulty: .gold,
            requirementType: .readSessions,
            requirementTarget: 10
        )
        
        await animationService.showAchievementReward(achievement: achievement)
        XCTAssertTrue(animationService.rewardMessage.contains("Thành tích Test"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testStreakReward() async throws {
        let milestone = StreakMilestone(
            streak: 7,
            title: "Một tuần hoàn hảo!",
            description: "Bé đã đọc đúng 7 lần liên tiếp!",
            reward: StreakReward(bonusPoints: 70, badge: "🏆", specialEffect: "confetti")
        )
        
        await animationService.showStreakReward(streak: 7, milestone: milestone)
        XCTAssertTrue(animationService.rewardMessage.contains("Một tuần hoàn hảo!"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testLevelUpReward() async throws {
        await animationService.showLevelUpReward(newLevel: 5, levelTitle: "Chuyên gia đọc")
        XCTAssertTrue(animationService.rewardMessage.contains("Lên cấp 5"))
        XCTAssertTrue(animationService.rewardMessage.contains("Chuyên gia đọc"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testHighAccuracyReward() async throws {
        await animationService.showHighAccuracyReward(accuracy: 0.95)
        XCTAssertTrue(animationService.rewardMessage.contains("95%"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testSpeedBonusReward() async throws {
        await animationService.showSpeedBonusReward(timeBonus: 25)
        XCTAssertTrue(animationService.rewardMessage.contains("+25 điểm"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testFirstAttemptReward() async throws {
        await animationService.showFirstAttemptReward()
        XCTAssertTrue(animationService.rewardMessage.contains("Lần đầu đã đúng"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testImprovementReward() async throws {
        await animationService.showImprovementReward(improvementPercent: 15)
        XCTAssertTrue(animationService.rewardMessage.contains("+15%"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    func testConsistencyReward() async throws {
        await animationService.showConsistencyReward(days: 5)
        XCTAssertTrue(animationService.rewardMessage.contains("5 ngày"))
        XCTAssertTrue(animationService.isShowingReward)
    }
    
    // MARK: - Sound Manager Tests
    
    func testSoundManagerSettings() {
        // Test initial state
        XCTAssertTrue(soundManager.isSoundEnabled())
        XCTAssertEqual(soundManager.getVolume(), 0.7, accuracy: 0.01)
        
        // Test sound toggle
        soundManager.setSoundEnabled(false)
        XCTAssertFalse(soundManager.isSoundEnabled())
        
        soundManager.setSoundEnabled(true)
        XCTAssertTrue(soundManager.isSoundEnabled())
        
        // Test volume setting
        soundManager.setVolume(0.5)
        XCTAssertEqual(soundManager.getVolume(), 0.5, accuracy: 0.01)
        
        // Test volume bounds
        soundManager.setVolume(-0.1)
        XCTAssertEqual(soundManager.getVolume(), 0.0, accuracy: 0.01)
        
        soundManager.setVolume(1.1)
        XCTAssertEqual(soundManager.getVolume(), 1.0, accuracy: 0.01)
    }
    
    func testRewardSoundTypes() {
        let soundTypes: [RewardSoundType] = [.success, .good, .great, .excellent, .epic, .legendary, .bonus]
        
        for soundType in soundTypes {
            XCTAssertFalse(soundType.fileName.isEmpty)
            XCTAssertTrue(soundType.fileName.hasPrefix("reward_"))
        }
    }
    
    func testEncouragementTypes() {
        let encouragementTypes: [EncouragementType] = [.greatJob, .keepGoing, .almostThere, .perfect, .tryAgain]
        
        for type in encouragementTypes {
            XCTAssertFalse(type.fileName.isEmpty)
            XCTAssertFalse(type.message.isEmpty)
            XCTAssertTrue(type.fileName.hasPrefix("encouragement_"))
        }
    }
    
    // MARK: - Haptic Manager Tests
    
    func testHapticManagerSettings() {
        // Test initial state
        XCTAssertTrue(hapticManager.getHapticIntensity() > 0)
        
        // Test haptic toggle
        hapticManager.setHapticsEnabled(false)
        // Note: isHapticsEnabled() also checks hardware support
        
        hapticManager.setHapticsEnabled(true)
        
        // Test intensity setting
        hapticManager.setHapticIntensity(0.5)
        XCTAssertEqual(hapticManager.getHapticIntensity(), 0.5, accuracy: 0.01)
        
        // Test intensity bounds
        hapticManager.setHapticIntensity(-0.1)
        XCTAssertEqual(hapticManager.getHapticIntensity(), 0.0, accuracy: 0.01)
        
        hapticManager.setHapticIntensity(1.1)
        XCTAssertEqual(hapticManager.getHapticIntensity(), 1.0, accuracy: 0.01)
    }
    
    // MARK: - Reward System Integration Tests
    
    func testSessionResultProcessing() async throws {
        let sessionResult = SessionResult(
            userId: "test_user",
            exerciseId: UUID(),
            originalText: "Con mèo ngồi trên thảm",
            spokenText: "Con mèo ngồi trên thảm",
            accuracy: 1.0, // Perfect score
            score: 100,
            timeSpent: 60, // Fast completion
            difficulty: .grade2,
            inputMethod: .voice,
            attempts: 1 // First attempt
        )
        
        await rewardSystem.processSessionResult(sessionResult)
        
        // Should have queued multiple rewards
        XCTAssertFalse(rewardSystem.rewardQueue.isEmpty)
        
        // Check for expected reward types
        let rewardTypes = rewardSystem.rewardQueue.map { reward in
            switch reward {
            case .perfectScore: return "perfectScore"
            case .firstAttemptSuccess: return "firstAttempt"
            case .speedBonus: return "speedBonus"
            default: return "other"
            }
        }
        
        XCTAssertTrue(rewardTypes.contains("perfectScore"))
        XCTAssertTrue(rewardTypes.contains("firstAttempt"))
    }
    
    func testRewardPriority() {
        let rewards: [RewardEvent] = [
            .speedBonus(10),
            .levelUp(5, "Expert"),
            .highAccuracy(0.9),
            .perfectScore(100)
        ]
        
        let sortedRewards = rewards.sorted { $0.priority < $1.priority }
        
        // Level up should have highest priority (lowest number)
        if case .levelUp = sortedRewards.first! {
            // Test passes
        } else {
            XCTFail("Level up should have highest priority")
        }
        
        // Speed bonus should have lowest priority (highest number)
        if case .speedBonus = sortedRewards.last! {
            // Test passes
        } else {
            XCTFail("Speed bonus should have lowest priority")
        }
    }
    
    func testRewardDisplayDuration() {
        let levelUpReward = RewardEvent.levelUp(5, "Expert")
        let speedBonusReward = RewardEvent.speedBonus(10)
        
        XCTAssertGreaterThan(levelUpReward.displayDuration, speedBonusReward.displayDuration)
        XCTAssertEqual(levelUpReward.displayDuration, 4.0)
        XCTAssertEqual(speedBonusReward.displayDuration, 2.5)
    }
    
    func testGoalCompletionReward() {
        let dailyGoal = GoalType.dailySessions
        rewardSystem.processDailyGoalCompletion(dailyGoal)
        
        XCTAssertEqual(rewardSystem.rewardQueue.count, 1)
        
        if case .goalCompletion(let goalType) = rewardSystem.rewardQueue.first! {
            XCTAssertEqual(goalType, dailyGoal)
        } else {
            XCTFail("Should have queued goal completion reward")
        }
    }
    
    func testImprovementReward() {
        rewardSystem.processImprovement(improvementPercent: 20)
        
        XCTAssertEqual(rewardSystem.rewardQueue.count, 1)
        
        if case .improvement(let percent) = rewardSystem.rewardQueue.first! {
            XCTAssertEqual(percent, 20)
        } else {
            XCTFail("Should have queued improvement reward")
        }
    }
    
    func testConsistencyReward() {
        rewardSystem.processConsistency(days: 7)
        
        XCTAssertEqual(rewardSystem.rewardQueue.count, 1)
        
        if case .consistency(let days) = rewardSystem.rewardQueue.first! {
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Should have queued consistency reward")
        }
    }
    
    // MARK: - Reward Type Tests
    
    func testRewardTypeAnimations() {
        let rewardTypes: [RewardType] = [
            .achievement(.diamond),
            .perfectScore,
            .streak(10),
            .levelUp,
            .goalCompletion(.dailySessions),
            .highAccuracy,
            .speedBonus,
            .firstAttempt,
            .improvement,
            .consistency
        ]
        
        for rewardType in rewardTypes {
            XCTAssertNotNil(rewardType.animationType)
            XCTAssertNotNil(rewardType.primaryColor)
            XCTAssertNotNil(rewardType.secondaryColor)
        }
    }
    
    func testAchievementDifficultyColors() {
        let difficulties: [AchievementDifficulty] = [.bronze, .silver, .gold, .platinum, .diamond]
        
        for difficulty in difficulties {
            XCTAssertNotNil(difficulty.color)
        }
        
        // Test that different difficulties have different colors
        XCTAssertNotEqual(AchievementDifficulty.bronze.color, AchievementDifficulty.gold.color)
        XCTAssertNotEqual(AchievementDifficulty.silver.color, AchievementDifficulty.diamond.color)
    }
    
    // MARK: - Performance Tests
    
    func testRewardSystemPerformance() {
        measure {
            let sessionResult = SessionResult(
                userId: "test_user",
                exerciseId: UUID(),
                originalText: "Test text",
                spokenText: "Test text",
                accuracy: 0.95,
                score: 95,
                timeSpent: 120,
                difficulty: .grade2,
                inputMethod: .voice
            )
            
            Task {
                await rewardSystem.processSessionResult(sessionResult)
            }
        }
    }
    
    func testSoundPreloadingPerformance() {
        measure {
            let soundManager = SoundEffectManager()
            // Sound preloading happens in init
            XCTAssertTrue(soundManager.isSoundEnabled())
        }
    }
}

// MARK: - Mock Progress Tracker

class MockProgressTracker: ProgressTrackingProtocol {
    func updateDailyProgress(userId: String, sessionResult: SessionResult) async throws {
        // Mock implementation
    }
    
    func getUserProgress(userId: String, period: ProgressPeriod) async throws -> UserProgress {
        return UserProgress(
            userId: userId,
            period: period,
            startDate: Date(),
            endDate: Date(),
            totalSessions: 10,
            totalTimeSpent: 600,
            averageAccuracy: 0.85,
            totalScore: 850,
            streakCount: 5,
            goalsAchieved: 8,
            totalGoals: 10,
            dailyProgress: [],
            categoryProgress: [],
            difficultyProgress: [],
            improvementTrend: ImprovementTrend(
                direction: .improving,
                magnitude: 0.1,
                consistency: 0.8,
                recentChange: 0.05,
                projectedImprovement: 0.15
            )
        )
    }
    
    func checkDailyGoal(userId: String) async throws -> Bool {
        return true
    }
    
    func getLearningStreak(userId: String) async throws -> LearningStreak {
        return LearningStreak(
            currentStreak: 5,
            longestStreak: 10,
            streakStartDate: Date(),
            lastActivityDate: Date(),
            streakLevel: .bronze,
            daysUntilReset: 2,
            milestones: [],
            nextMilestone: nil
        )
    }
    
    func getUserAnalytics(userId: String, period: ProgressPeriod) async throws -> UserAnalytics {
        return UserAnalytics(
            userId: userId,
            period: period,
            totalLearningTime: 600,
            averageSessionLength: 60,
            mostActiveDay: "Monday",
            mostActiveTime: "Morning",
            preferredDifficulty: .grade2,
            strongestCategory: .reading,
            improvementAreas: [],
            learningVelocity: LearningVelocity(
                sessionsPerWeek: 7,
                accuracyImprovement: 0.1,
                difficultyProgression: 0.2,
                overallVelocity: 0.8
            ),
            consistencyScore: 0.8,
            engagementScore: 0.9,
            retentionRate: 0.85,
            weeklyPattern: [],
            monthlyTrend: []
        )
    }
    
    func updateLearningGoals(userId: String, goals: LearningGoals) async throws {
        // Mock implementation
    }
    
    func getLearningGoals(userId: String) async throws -> LearningGoals {
        return LearningGoals.defaultGoals(for: userId)
    }
    
    func getProgressComparison(userId: String, period: ProgressPeriod) async throws -> ProgressComparison {
        return ProgressComparison(
            userRank: 25,
            totalUsers: 100,
            percentile: 0.75,
            averageAccuracy: 0.8,
            userAccuracy: 0.85,
            averageSessionsPerWeek: 5,
            userSessionsPerWeek: 7,
            averageStreak: 3,
            userStreak: 5,
            comparisonInsights: []
        )
    }
    
    func getLearningInsights(userId: String) async throws -> [LearningInsight] {
        return []
    }
    
    func exportProgressData(userId: String, format: ExportFormat) async throws -> Data {
        return Data()
    }
}