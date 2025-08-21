import XCTest
@testable import ELAForKids

final class ScoringSystemTests: XCTestCase {
    
    var scoreCalculator: ScoreCalculator!
    var mockUserScoreRepository: MockUserScoreRepository!
    var mockStreakManager: MockStreakManager!
    
    override func setUp() {
        super.setUp()
        mockUserScoreRepository = MockUserScoreRepository()
        mockStreakManager = MockStreakManager()
        scoreCalculator = ScoreCalculator(
            userScoreRepository: mockUserScoreRepository,
            streakManager: mockStreakManager
        )
    }
    
    override func tearDown() {
        scoreCalculator = nil
        mockUserScoreRepository = nil
        mockStreakManager = nil
        super.tearDown()
    }
    
    // MARK: - Basic Score Calculation Tests
    
    func testBasicScoreCalculation() {
        let score = scoreCalculator.calculateScore(
            accuracy: 1.0,
            attempts: 1,
            difficulty: .grade1
        )
        
        XCTAssertEqual(score, 100, "Perfect accuracy on grade 1 should give 100 points")
    }
    
    func testScoreCalculationWithDifferentAccuracy() {
        let testCases: [(Float, DifficultyLevel, Int)] = [
            (1.0, .grade1, 100),
            (0.8, .grade1, 80),
            (0.5, .grade1, 50),
            (0.0, .grade1, 0),
            (1.0, .grade2, 150),
            (0.8, .grade2, 120),
            (1.0, .grade5, 300),
            (0.8, .grade5, 240)
        ]
        
        for (accuracy, difficulty, expectedScore) in testCases {
            let score = scoreCalculator.calculateScore(
                accuracy: accuracy,
                attempts: 1,
                difficulty: difficulty
            )
            
            XCTAssertEqual(score, expectedScore,
                          "Accuracy \(accuracy) on \(difficulty) should give \(expectedScore) points")
        }
    }
    
    func testScoreCalculationWithMultipleAttempts() {
        let baseScore = scoreCalculator.calculateScore(
            accuracy: 1.0,
            attempts: 1,
            difficulty: .grade1
        )
        
        let scoreWithTwoAttempts = scoreCalculator.calculateScore(
            accuracy: 1.0,
            attempts: 2,
            difficulty: .grade1
        )
        
        XCTAssertLessThan(scoreWithTwoAttempts, baseScore,
                         "Multiple attempts should reduce score")
        
        let expectedPenalty = Int(Float(baseScore) * 0.15) // 15% penalty
        let expectedScore = baseScore - expectedPenalty
        XCTAssertEqual(scoreWithTwoAttempts, expectedScore,
                      "Two attempts should apply 15% penalty")
    }
    
    func testDifficultyMultipliers() {
        let difficulties: [DifficultyLevel] = [.grade1, .grade2, .grade3, .grade4, .grade5]
        let expectedMultipliers: [Float] = [1.0, 1.2, 1.4, 1.6, 1.8]
        
        for (difficulty, expectedMultiplier) in zip(difficulties, expectedMultipliers) {
            let multiplier = scoreCalculator.getDifficultyMultiplier(difficulty: difficulty)
            XCTAssertEqual(multiplier, expectedMultiplier, accuracy: 0.01,
                          "\(difficulty) should have multiplier \(expectedMultiplier)")
        }
    }
    
    // MARK: - Bonus Points Tests
    
    func testPerfectScoreBonus() {
        let bonusPoints = scoreCalculator.calculateBonusPoints(
            streak: 1,
            perfectScore: true,
            timeBonus: nil
        )
        
        XCTAssertEqual(bonusPoints, 100, "Perfect score should give 100 bonus points")
    }
    
    func testStreakBonus() {
        let testCases: [(Int, Int)] = [
            (1, 0),   // No streak bonus for 1
            (2, 20),  // 2 * 0.1 * 100 = 20
            (5, 50),  // 5 * 0.1 * 100 = 50
            (10, 100) // 10 * 0.1 * 100 = 100
        ]
        
        for (streak, expectedBonus) in testCases {
            let bonusPoints = scoreCalculator.calculateBonusPoints(
                streak: streak,
                perfectScore: false,
                timeBonus: nil
            )
            
            XCTAssertEqual(bonusPoints, expectedBonus,
                          "Streak \(streak) should give \(expectedBonus) bonus points")
        }
    }
    
    func testTimeBonus() {
        let timeBonus = scoreCalculator.calculateTimeBonus(
            completionTime: 30, // 30 seconds
            targetTime: 60      // 60 seconds target
        )
        
        XCTAssertNotNil(timeBonus, "Completing in half the target time should give time bonus")
        XCTAssertGreaterThan(timeBonus!.bonusPoints, 0, "Time bonus should be positive")
        XCTAssertEqual(timeBonus!.completionTime, 30, "Completion time should be recorded")
        XCTAssertEqual(timeBonus!.targetTime, 60, "Target time should be recorded")
    }
    
    func testNoTimeBonusForSlowCompletion() {
        let timeBonus = scoreCalculator.calculateTimeBonus(
            completionTime: 60, // 60 seconds
            targetTime: 60      // 60 seconds target (no bonus threshold)
        )
        
        XCTAssertNil(timeBonus, "Completing at target time should not give time bonus")
    }
    
    // MARK: - Comprehensive Scoring Tests
    
    func testComprehensiveScoring() {
        let mistakes: [TextMistake] = []
        
        let result = scoreCalculator.calculateComprehensiveScore(
            accuracy: 1.0,
            attempts: 1,
            difficulty: .grade2,
            completionTime: 45, // Fast completion
            streak: 5,
            mistakes: mistakes
        )
        
        XCTAssertEqual(result.baseScore, 150, "Grade 2 base score should be 150")
        XCTAssertEqual(result.accuracyScore, 150, "Perfect accuracy should give full base score")
        XCTAssertGreaterThan(result.difficultyBonus, 0, "Grade 2 should have difficulty bonus")
        XCTAssertNotNil(result.timeBonus, "Fast completion should give time bonus")
        XCTAssertNotNil(result.streakBonus, "Streak of 5 should give streak bonus")
        XCTAssertEqual(result.perfectScoreBonus, 100, "Perfect score should give 100 bonus")
        XCTAssertEqual(result.attemptPenalty, 0, "Single attempt should have no penalty")
        XCTAssertGreaterThan(result.finalScore, result.accuracyScore, "Final score should include bonuses")
        XCTAssertEqual(result.category, .excellent, "Perfect accuracy should be excellent")
    }
    
    func testComprehensiveScoringWithMistakes() {
        let mistakes = [
            TextMistake(
                position: 0,
                expectedWord: "test",
                actualWord: "wrong",
                mistakeType: .substitution,
                severity: .moderate
            )
        ]
        
        let result = scoreCalculator.calculateComprehensiveScore(
            accuracy: 0.8,
            attempts: 2,
            difficulty: .grade1,
            completionTime: 90, // Slow completion
            streak: 1,
            mistakes: mistakes
        )
        
        XCTAssertEqual(result.baseScore, 100, "Grade 1 base score should be 100")
        XCTAssertEqual(result.accuracyScore, 80, "80% accuracy should give 80 points")
        XCTAssertEqual(result.difficultyBonus, 0, "Grade 1 should have no difficulty bonus")
        XCTAssertNil(result.timeBonus, "Slow completion should not give time bonus")
        XCTAssertNil(result.streakBonus, "Streak of 1 should not give bonus")
        XCTAssertEqual(result.perfectScoreBonus, 0, "Imperfect score should not give perfect bonus")
        XCTAssertGreaterThan(result.attemptPenalty, 0, "Multiple attempts should have penalty")
        XCTAssertEqual(result.category, .good, "80% accuracy should be good")
    }
    
    // MARK: - Score with Mistake Severity Tests
    
    func testScoreWithMistakeSeverity() {
        let mistakes = [
            TextMistake(
                position: 0,
                expectedWord: "test1",
                actualWord: "wrong1",
                mistakeType: .substitution,
                severity: .minor
            ),
            TextMistake(
                position: 1,
                expectedWord: "test2",
                actualWord: "wrong2",
                mistakeType: .substitution,
                severity: .moderate
            ),
            TextMistake(
                position: 2,
                expectedWord: "test3",
                actualWord: "wrong3",
                mistakeType: .substitution,
                severity: .major
            )
        ]
        
        let score = scoreCalculator.calculateScoreWithMistakeSeverity(
            accuracy: 0.7,
            mistakes: mistakes,
            difficulty: .grade1,
            attempts: 1
        )
        
        let baseScore = scoreCalculator.calculateScore(accuracy: 0.7, attempts: 1, difficulty: .grade1)
        let expectedPenalty = 5 + 15 + 30 // minor + moderate + major
        let expectedScore = max(0, baseScore - expectedPenalty)
        
        XCTAssertEqual(score, expectedScore, "Score should account for mistake severity")
    }
    
    // MARK: - Adaptive Scoring Tests
    
    func testAdaptiveScoring() {
        let userAverageAccuracy: Float = 0.7
        
        // Test improvement bonus
        let improvedScore = scoreCalculator.calculateAdaptiveScore(
            accuracy: 0.9,
            attempts: 1,
            difficulty: .grade1,
            userAverageAccuracy: userAverageAccuracy
        )
        
        let baseScore = scoreCalculator.calculateScore(accuracy: 0.9, attempts: 1, difficulty: .grade1)
        XCTAssertGreaterThan(improvedScore, baseScore, "Improvement over average should give bonus")
        
        // Test no bonus for performance at average
        let averageScore = scoreCalculator.calculateAdaptiveScore(
            accuracy: 0.7,
            attempts: 1,
            difficulty: .grade1,
            userAverageAccuracy: userAverageAccuracy
        )
        
        let expectedAverageScore = scoreCalculator.calculateScore(accuracy: 0.7, attempts: 1, difficulty: .grade1)
        XCTAssertEqual(averageScore, expectedAverageScore, "Average performance should not get bonus")
    }
    
    // MARK: - Validation Tests
    
    func testScoringParameterValidation() {
        // Test invalid accuracy
        XCTAssertThrowsError(try scoreCalculator.validateScoringParameters(
            accuracy: -0.1,
            attempts: 1,
            difficulty: .grade1,
            completionTime: 60
        )) { error in
            XCTAssertEqual(error as? ScoringError, .invalidAccuracy)
        }
        
        XCTAssertThrowsError(try scoreCalculator.validateScoringParameters(
            accuracy: 1.1,
            attempts: 1,
            difficulty: .grade1,
            completionTime: 60
        )) { error in
            XCTAssertEqual(error as? ScoringError, .invalidAccuracy)
        }
        
        // Test invalid attempts
        XCTAssertThrowsError(try scoreCalculator.validateScoringParameters(
            accuracy: 1.0,
            attempts: 0,
            difficulty: .grade1,
            completionTime: 60
        )) { error in
            XCTAssertEqual(error as? ScoringError, .invalidAttempts)
        }
        
        // Test invalid completion time
        XCTAssertThrowsError(try scoreCalculator.validateScoringParameters(
            accuracy: 1.0,
            attempts: 1,
            difficulty: .grade1,
            completionTime: -1
        )) { error in
            XCTAssertEqual(error as? ScoringError, .invalidCompletionTime)
        }
        
        // Test valid parameters
        XCTAssertNoThrow(try scoreCalculator.validateScoringParameters(
            accuracy: 0.8,
            attempts: 2,
            difficulty: .grade3,
            completionTime: 120
        ))
    }
    
    func testScoreValidation() {
        XCTAssertTrue(scoreCalculator.isValidScore(0), "0 should be valid score")
        XCTAssertTrue(scoreCalculator.isValidScore(500), "500 should be valid score")
        XCTAssertTrue(scoreCalculator.isValidScore(1000), "1000 should be valid score")
        XCTAssertFalse(scoreCalculator.isValidScore(-1), "-1 should be invalid score")
        XCTAssertFalse(scoreCalculator.isValidScore(1001), "1001 should be invalid score")
    }
    
    // MARK: - Performance Trend Tests
    
    func testPerformanceTrendCalculation() {
        let sessions = [
            createSessionResult(accuracy: 0.6, completedAt: Date().addingTimeInterval(-10 * 24 * 3600)),
            createSessionResult(accuracy: 0.7, completedAt: Date().addingTimeInterval(-8 * 24 * 3600)),
            createSessionResult(accuracy: 0.8, completedAt: Date().addingTimeInterval(-6 * 24 * 3600)),
            createSessionResult(accuracy: 0.9, completedAt: Date().addingTimeInterval(-4 * 24 * 3600)),
            createSessionResult(accuracy: 0.95, completedAt: Date().addingTimeInterval(-2 * 24 * 3600))
        ]
        
        let trend = scoreCalculator.calculatePerformanceTrend(recentSessions: sessions)
        
        XCTAssertEqual(trend.trend, .improving, "Increasing accuracy should show improving trend")
        XCTAssertGreaterThan(trend.changePercentage, 0, "Improving trend should have positive change")
    }
    
    func testPerformanceTrendWithDecliningPerformance() {
        let sessions = [
            createSessionResult(accuracy: 0.9, completedAt: Date().addingTimeInterval(-10 * 24 * 3600)),
            createSessionResult(accuracy: 0.8, completedAt: Date().addingTimeInterval(-8 * 24 * 3600)),
            createSessionResult(accuracy: 0.7, completedAt: Date().addingTimeInterval(-6 * 24 * 3600)),
            createSessionResult(accuracy: 0.6, completedAt: Date().addingTimeInterval(-4 * 24 * 3600)),
            createSessionResult(accuracy: 0.5, completedAt: Date().addingTimeInterval(-2 * 24 * 3600))
        ]
        
        let trend = scoreCalculator.calculatePerformanceTrend(recentSessions: sessions)
        
        XCTAssertEqual(trend.trend, .declining, "Decreasing accuracy should show declining trend")
        XCTAssertLessThan(trend.changePercentage, 0, "Declining trend should have negative change")
    }
    
    func testPerformanceTrendWithStablePerformance() {
        let sessions = [
            createSessionResult(accuracy: 0.8, completedAt: Date().addingTimeInterval(-10 * 24 * 3600)),
            createSessionResult(accuracy: 0.82, completedAt: Date().addingTimeInterval(-8 * 24 * 3600)),
            createSessionResult(accuracy: 0.78, completedAt: Date().addingTimeInterval(-6 * 24 * 3600)),
            createSessionResult(accuracy: 0.81, completedAt: Date().addingTimeInterval(-4 * 24 * 3600)),
            createSessionResult(accuracy: 0.79, completedAt: Date().addingTimeInterval(-2 * 24 * 3600))
        ]
        
        let trend = scoreCalculator.calculatePerformanceTrend(recentSessions: sessions)
        
        XCTAssertEqual(trend.trend, .stable, "Small variations should show stable trend")
    }
    
    // MARK: - Integration Tests
    
    func testUserScoreUpdate() async throws {
        let userId = "test_user"
        let additionalScore = 150
        
        try await scoreCalculator.updateUserScore(userId: userId, score: additionalScore)
        
        XCTAssertTrue(mockUserScoreRepository.updateScoreCalled, "updateScore should be called")
        XCTAssertEqual(mockUserScoreRepository.lastUpdatedUserId, userId, "Correct user ID should be used")
        XCTAssertEqual(mockUserScoreRepository.lastAdditionalScore, additionalScore, "Correct score should be added")
    }
    
    func testGetUserScore() async throws {
        let userId = "test_user"
        mockUserScoreRepository.mockUserScore = UserScore(
            id: "1",
            userId: userId,
            userName: "Test User",
            totalScore: 500,
            level: 3,
            experience: 750,
            streak: 5,
            lastUpdated: Date(),
            achievements: ["first_perfect"]
        )
        
        let score = try await scoreCalculator.getUserScore(userId: userId)
        
        XCTAssertEqual(score, 500, "Should return user's total score")
        XCTAssertTrue(mockUserScoreRepository.getUserScoreCalled, "getUserScore should be called")
    }
    
    // MARK: - Helper Methods
    
    private func createSessionResult(accuracy: Float, completedAt: Date) -> SessionResult {
        return SessionResult(
            userId: "test_user",
            exerciseId: UUID(),
            originalText: "Test text",
            spokenText: "Test text",
            accuracy: accuracy,
            score: Int(accuracy * 100),
            timeSpent: 60,
            mistakes: [],
            completedAt: completedAt,
            difficulty: .grade1,
            inputMethod: .voice
        )
    }
}

// MARK: - Mock Implementations

class MockUserScoreRepository: UserScoreRepositoryProtocol {
    var mockUserScore: UserScore?
    var mockLeaderboard: [UserScore] = []
    var mockRanking: Int = 1
    
    var getUserScoreCalled = false
    var updateScoreCalled = false
    var getLeaderboardCalled = false
    var getUserRankingCalled = false
    
    var lastUpdatedUserId: String?
    var lastAdditionalScore: Int?
    
    func getUserScore(userId: String) async throws -> UserScore {
        getUserScoreCalled = true
        return mockUserScore ?? UserScore(
            id: "1",
            userId: userId,
            userName: "Test User",
            totalScore: 0,
            level: 1,
            experience: 0,
            streak: 0,
            lastUpdated: Date(),
            achievements: []
        )
    }
    
    func updateScore(userId: String, additionalScore: Int) async throws {
        updateScoreCalled = true
        lastUpdatedUserId = userId
        lastAdditionalScore = additionalScore
    }
    
    func getTopUsers(limit: Int) async throws -> [UserScore] {
        getLeaderboardCalled = true
        return Array(mockLeaderboard.prefix(limit))
    }
    
    func getUserRanking(userId: String) async throws -> Int {
        getUserRankingCalled = true
        return mockRanking
    }
    
    func createUserScore(userId: String, userName: String) async throws -> UserScore {
        return UserScore(
            id: UUID().uuidString,
            userId: userId,
            userName: userName,
            totalScore: 0,
            level: 1,
            experience: 0,
            streak: 0,
            lastUpdated: Date(),
            achievements: []
        )
    }
}

class MockStreakManager: StreakManagerProtocol {
    var mockCurrentStreak: Int = 0
    
    var updateStreakCalled = false
    var getCurrentStreakCalled = false
    var resetStreakCalled = false
    
    func updateStreak(userId: String, isSuccess: Bool) async throws -> Int {
        updateStreakCalled = true
        if isSuccess {
            mockCurrentStreak += 1
        } else {
            mockCurrentStreak = 0
        }
        return mockCurrentStreak
    }
    
    func getCurrentStreak(userId: String) async throws -> Int {
        getCurrentStreakCalled = true
        return mockCurrentStreak
    }
    
    func resetStreak(userId: String) async throws {
        resetStreakCalled = true
        mockCurrentStreak = 0
    }
}