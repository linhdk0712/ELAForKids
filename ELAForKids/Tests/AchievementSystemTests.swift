import XCTest
@testable import ELAForKids

final class AchievementSystemTests: XCTestCase {
    
    var achievementManager: AchievementManager!
    var mockAchievementRepository: MockAchievementRepository!
    var mockUserScoreRepository: MockUserScoreRepository!
    var notificationCenter: NotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockAchievementRepository = MockAchievementRepository()
        mockUserScoreRepository = MockUserScoreRepository()
        notificationCenter = NotificationCenter()
        
        achievementManager = AchievementManager(
            achievementRepository: mockAchievementRepository,
            userScoreRepository: mockUserScoreRepository,
            notificationCenter: notificationCenter
        )
    }
    
    override func tearDown() {
        achievementManager = nil
        mockAchievementRepository = nil
        mockUserScoreRepository = nil
        notificationCenter = nil
        super.tearDown()
    }
    
    // MARK: - Achievement Creation Tests
    
    func testCreateBasicAchievement() {
        let achievement = Achievement(
            id: "test_achievement",
            title: "Test Achievement",
            description: "A test achievement",
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
                badge: "test_badge",
                title: "Test Title",
                specialEffect: nil,
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "test_badge",
                name: "Test Badge",
                description: "A test badge",
                imageName: "test_image",
                emoji: "🏆",
                rarity: .common,
                animationType: .none
            ),
            isSecret: false,
            sortOrder: 1
        )
        
        XCTAssertEqual(achievement.id, "test_achievement")
        XCTAssertEqual(achievement.title, "Test Achievement")
        XCTAssertEqual(achievement.category, .reading)
        XCTAssertEqual(achievement.difficulty, .bronze)
        XCTAssertEqual(achievement.requirements.target, 5)
        XCTAssertEqual(achievement.rewards.points, 100)
        XCTAssertEqual(achievement.badge.emoji, "🏆")
    }
    
    // MARK: - Achievement Unlocking Tests
    
    func testUnlockAchievement() async throws {
        let achievement = createTestAchievement()
        mockAchievementRepository.mockAchievements = [achievement]
        
        let unlockedAchievement = try await achievementManager.unlockAchievement(
            achievement.id,
            for: "test_user"
        )
        
        XCTAssertNotNil(unlockedAchievement)
        XCTAssertEqual(unlockedAchievement?.id, achievement.id)
        XCTAssertTrue(mockAchievementRepository.saveUserAchievementCalled)
        XCTAssertTrue(mockUserScoreRepository.updateScoreCalled)
        XCTAssertTrue(mockUserScoreRepository.addAchievementCalled)
    }
    
    func testUnlockNonRepeatableAchievementTwice() async throws {
        let achievement = createTestAchievement()
        mockAchievementRepository.mockAchievements = [achievement]
        mockAchievementRepository.mockUserAchievements = [
            UserAchievement(
                id: "existing",
                userId: "test_user",
                achievementId: achievement.id,
                unlockedAt: Date(),
                progress: AchievementProgress(current: 5, target: 5, percentage: 1.0, milestones: []),
                isNew: false
            )
        ]
        
        let result = try await achievementManager.unlockAchievement(
            achievement.id,
            for: "test_user"
        )
        
        XCTAssertNil(result, "Non-repeatable achievement should not be unlocked twice")
    }
    
    func testUnlockRepeatableAchievement() async throws {
        var achievement = createTestAchievement()
        achievement = Achievement(
            id: achievement.id,
            title: achievement.title,
            description: achievement.description,
            category: achievement.category,
            difficulty: achievement.difficulty,
            requirements: AchievementRequirements(
                type: achievement.requirements.type,
                target: achievement.requirements.target,
                conditions: achievement.requirements.conditions,
                timeframe: achievement.requirements.timeframe,
                isRepeatable: true // Make it repeatable
            ),
            rewards: achievement.rewards,
            badge: achievement.badge,
            isSecret: achievement.isSecret,
            sortOrder: achievement.sortOrder
        )
        
        mockAchievementRepository.mockAchievements = [achievement]
        mockAchievementRepository.mockUserAchievements = [
            UserAchievement(
                id: "existing",
                userId: "test_user",
                achievementId: achievement.id,
                unlockedAt: Date(),
                progress: AchievementProgress(current: 5, target: 5, percentage: 1.0, milestones: []),
                isNew: false
            )
        ]
        
        let result = try await achievementManager.unlockAchievement(
            achievement.id,
            for: "test_user"
        )
        
        XCTAssertNotNil(result, "Repeatable achievement should be unlocked multiple times")
    }
    
    // MARK: - Achievement Checking Tests
    
    func testCheckForNewAchievements() async throws {
        let achievement = createTestAchievement()
        mockAchievementRepository.mockAchievements = [achievement]
        mockUserScoreRepository.mockUserStats = UserStatistics(
            totalScore: 500,
            level: 2,
            experience: 300,
            currentStreak: 3,
            totalSessions: 10, // Meets the requirement
            averageAccuracy: 0.85,
            totalTimeSpent: 1800,
            favoriteInputMethod: .voice,
            strongestDifficulty: .grade2,
            improvementAreas: []
        )
        
        let sessionResult = createTestSessionResult()
        
        let newAchievements = try await achievementManager.checkForNewAchievements(
            sessionResult: sessionResult
        )
        
        XCTAssertEqual(newAchievements.count, 1)
        XCTAssertEqual(newAchievements.first?.id, achievement.id)
    }
    
    func testCheckForNewAchievementsNotMet() async throws {
        let achievement = createTestAchievement()
        mockAchievementRepository.mockAchievements = [achievement]
        mockUserScoreRepository.mockUserStats = UserStatistics(
            totalScore: 100,
            level: 1,
            experience: 50,
            currentStreak: 1,
            totalSessions: 2, // Does not meet the requirement (needs 5)
            averageAccuracy: 0.75,
            totalTimeSpent: 600,
            favoriteInputMethod: .voice,
            strongestDifficulty: .grade1,
            improvementAreas: []
        )
        
        let sessionResult = createTestSessionResult()
        
        let newAchievements = try await achievementManager.checkForNewAchievements(
            sessionResult: sessionResult
        )
        
        XCTAssertEqual(newAchievements.count, 0)
    }
    
    // MARK: - Achievement Progress Tests
    
    func testGetAchievementProgress() async throws {
        let achievement = createTestAchievement()
        mockAchievementRepository.mockAchievements = [achievement]
        mockUserScoreRepository.mockUserStats = UserStatistics(
            totalScore: 200,
            level: 1,
            experience: 100,
            currentStreak: 2,
            totalSessions: 3, // 3 out of 5 required
            averageAccuracy: 0.8,
            totalTimeSpent: 900,
            favoriteInputMethod: .voice,
            strongestDifficulty: .grade1,
            improvementAreas: []
        )
        
        let progress = try await achievementManager.getAchievementProgress(
            userId: "test_user",
            achievementId: achievement.id
        )
        
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.current, 3)
        XCTAssertEqual(progress?.target, 5)
        XCTAssertEqual(progress?.percentage, 0.6, accuracy: 0.01)
        XCTAssertFalse(progress?.isCompleted ?? true)
    }
    
    // MARK: - Achievement Statistics Tests
    
    func testGetAchievementStatistics() async throws {
        let achievements = [
            createTestAchievement(),
            createTestAchievement(id: "test2", category: .accuracy, difficulty: .silver)
        ]
        mockAchievementRepository.mockAchievements = achievements
        mockAchievementRepository.mockUserAchievements = [
            UserAchievement(
                id: "user1",
                userId: "test_user",
                achievementId: "test_achievement",
                unlockedAt: Date(),
                progress: AchievementProgress(current: 5, target: 5, percentage: 1.0, milestones: []),
                isNew: false
            )
        ]
        
        let statistics = try await achievementManager.getAchievementStatistics(userId: "test_user")
        
        XCTAssertEqual(statistics.totalAchievements, 2)
        XCTAssertEqual(statistics.unlockedAchievements, 1)
        XCTAssertEqual(statistics.completionPercentage, 0.5, accuracy: 0.01)
        XCTAssertEqual(statistics.achievementPoints, 100)
        XCTAssertEqual(statistics.categoryStats[.reading], 1)
        XCTAssertEqual(statistics.difficultyStats[.bronze], 1)
    }
    
    // MARK: - Requirement Condition Tests
    
    func testRequirementConditionAccuracy() {
        let condition = RequirementCondition(
            type: .accuracy,
            operator: .greaterThanOrEqual,
            value: 0.8,
            additionalParams: nil
        )
        
        let sessionResult = createTestSessionResult(accuracy: 0.85)
        let userStats = createTestUserStats()
        
        XCTAssertTrue(condition.isMet(by: sessionResult, userStats: userStats))
        
        let sessionResult2 = createTestSessionResult(accuracy: 0.75)
        XCTAssertFalse(condition.isMet(by: sessionResult2, userStats: userStats))
    }
    
    func testRequirementConditionSessionCount() {
        let condition = RequirementCondition(
            type: .sessionCount,
            operator: .greaterThanOrEqual,
            value: 10,
            additionalParams: nil
        )
        
        let sessionResult = createTestSessionResult()
        let userStats = createTestUserStats(totalSessions: 15)
        
        XCTAssertTrue(condition.isMet(by: sessionResult, userStats: userStats))
        
        let userStats2 = createTestUserStats(totalSessions: 5)
        XCTAssertFalse(condition.isMet(by: sessionResult, userStats: userStats2))
    }
    
    func testRequirementConditionStreak() {
        let condition = RequirementCondition(
            type: .streak,
            operator: .greaterThan,
            value: 5,
            additionalParams: nil
        )
        
        let sessionResult = createTestSessionResult()
        let userStats = createTestUserStats(currentStreak: 7)
        
        XCTAssertTrue(condition.isMet(by: sessionResult, userStats: userStats))
        
        let userStats2 = createTestUserStats(currentStreak: 3)
        XCTAssertFalse(condition.isMet(by: sessionResult, userStats: userStats2))
    }
    
    // MARK: - Badge Tests
    
    func testBadgeRarityPointMultiplier() {
        XCTAssertEqual(BadgeRarity.bronze.pointMultiplier, 1.0)
        XCTAssertEqual(BadgeRarity.silver.pointMultiplier, 1.5)
        XCTAssertEqual(BadgeRarity.gold.pointMultiplier, 2.0)
        XCTAssertEqual(BadgeRarity.platinum.pointMultiplier, 3.0)
        XCTAssertEqual(BadgeRarity.diamond.pointMultiplier, 5.0)
    }
    
    func testBadgeAnimationDuration() {
        XCTAssertEqual(BadgeAnimation.none.duration, 0)
        XCTAssertEqual(BadgeAnimation.pulse.duration, 1.0)
        XCTAssertEqual(BadgeAnimation.glow.duration, 2.0)
        XCTAssertEqual(BadgeAnimation.sparkle.duration, 1.5)
        XCTAssertEqual(BadgeAnimation.bounce.duration, 0.8)
        XCTAssertEqual(BadgeAnimation.rotate.duration, 3.0)
    }
    
    // MARK: - Achievement Categories Tests
    
    func testGetAchievementsByCategory() async throws {
        let readingAchievement = createTestAchievement(id: "reading1", category: .reading)
        let accuracyAchievement = createTestAchievement(id: "accuracy1", category: .accuracy)
        let streakAchievement = createTestAchievement(id: "streak1", category: .streak)
        
        mockAchievementRepository.mockAchievements = [
            readingAchievement, accuracyAchievement, streakAchievement
        ]
        
        let readingAchievements = try await achievementManager.getAchievementsByCategory(.reading)
        let accuracyAchievements = try await achievementManager.getAchievementsByCategory(.accuracy)
        
        XCTAssertEqual(readingAchievements.count, 1)
        XCTAssertEqual(readingAchievements.first?.id, "reading1")
        
        XCTAssertEqual(accuracyAchievements.count, 1)
        XCTAssertEqual(accuracyAchievements.first?.id, "accuracy1")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithManyAchievements() {
        let achievements = (0..<1000).map { index in
            createTestAchievement(id: "achievement_\(index)")
        }
        mockAchievementRepository.mockAchievements = achievements
        
        measure {
            Task {
                _ = try? await achievementManager.getAvailableAchievements()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAchievement(
        id: String = "test_achievement",
        category: AchievementCategory = .reading,
        difficulty: AchievementDifficulty = .bronze
    ) -> Achievement {
        return Achievement(
            id: id,
            title: "Test Achievement",
            description: "A test achievement",
            category: category,
            difficulty: difficulty,
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
                badge: "test_badge",
                title: "Test Title",
                specialEffect: nil,
                unlockContent: nil
            ),
            badge: BadgeInfo(
                id: "test_badge",
                name: "Test Badge",
                description: "A test badge",
                imageName: "test_image",
                emoji: "🏆",
                rarity: .common,
                animationType: .none
            ),
            isSecret: false,
            sortOrder: 1
        )
    }
    
    private func createTestSessionResult(accuracy: Float = 0.8) -> SessionResult {
        return SessionResult(
            userId: "test_user",
            exerciseId: UUID(),
            originalText: "Test text",
            spokenText: "Test text",
            accuracy: accuracy,
            score: Int(accuracy * 100),
            timeSpent: 60,
            mistakes: [],
            completedAt: Date(),
            difficulty: .grade1,
            inputMethod: .voice
        )
    }
    
    private func createTestUserStats(
        totalSessions: Int = 10,
        currentStreak: Int = 5
    ) -> UserStatistics {
        return UserStatistics(
            totalScore: 500,
            level: 2,
            experience: 300,
            currentStreak: currentStreak,
            totalSessions: totalSessions,
            averageAccuracy: 0.85,
            totalTimeSpent: 1800,
            favoriteInputMethod: .voice,
            strongestDifficulty: .grade2,
            improvementAreas: []
        )
    }
}

// MARK: - Mock Implementations

class MockAchievementRepository: AchievementRepositoryProtocol {
    var mockAchievements: [Achievement] = []
    var mockUserAchievements: [UserAchievement] = []
    
    var saveAchievementCalled = false
    var saveUserAchievementCalled = false
    var deleteUserAchievementsCalled = false
    
    func getAllAchievements() async throws -> [Achievement] {
        return mockAchievements
    }
    
    func saveAchievement(_ achievement: Achievement) async throws {
        saveAchievementCalled = true
        if !mockAchievements.contains(where: { $0.id == achievement.id }) {
            mockAchievements.append(achievement)
        }
    }
    
    func getUserAchievements(userId: String) async throws -> [UserAchievement] {
        return mockUserAchievements.filter { $0.userId == userId }
    }
    
    func saveUserAchievement(_ userAchievement: UserAchievement) async throws {
        saveUserAchievementCalled = true
        mockUserAchievements.append(userAchievement)
    }
    
    func deleteUserAchievements(userId: String) async throws {
        deleteUserAchievementsCalled = true
        mockUserAchievements.removeAll { $0.userId == userId }
    }
}

extension MockUserScoreRepository {
    var mockUserStats: UserStatistics?
    var addAchievementCalled = false
    
    func getUserStatistics(userId: String) async throws -> UserStatistics {
        return mockUserStats ?? UserStatistics(
            totalScore: 0,
            level: 1,
            experience: 0,
            currentStreak: 0,
            totalSessions: 0,
            averageAccuracy: 0.0,
            totalTimeSpent: 0,
            favoriteInputMethod: .voice,
            strongestDifficulty: .grade1,
            improvementAreas: []
        )
    }
    
    func addAchievement(userId: String, achievementId: String) async throws {
        addAchievementCalled = true
    }
}