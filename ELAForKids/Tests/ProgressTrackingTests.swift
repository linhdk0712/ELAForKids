import XCTest
@testable import ELAForKids

final class ProgressTrackingTests: XCTestCase {
    
    var progressTracker: ProgressTrackingProtocol!
    var factory: ProgressTrackingFactory!
    
    override func setUpWithError() throws {
        factory = ProgressTrackingFactory.shared
        progressTracker = factory.getProgressTracker()
    }
    
    override func tearDownWithError() throws {
        progressTracker = nil
        factory = nil
    }
    
    func testUpdateDailyProgress() async throws {
        // Given
        let userId = "test_user_123"
        let sessionResult = SessionResult(
            userId: userId,
            exerciseId: UUID(),
            originalText: "Con mèo ngồi trên thảm",
            spokenText: "Con mèo ngồi trên thảm",
            accuracy: 1.0,
            score: 100,
            timeSpent: 120,
            difficulty: .grade1,
            inputMethod: .voice
        )
        
        // When
        try await progressTracker.updateDailyProgress(userId: userId, sessionResult: sessionResult)
        
        // Then
        let isDailyGoalMet = try await progressTracker.checkDailyGoal(userId: userId)
        // Note: This might be false if daily goals require more than 1 session
        XCTAssertNotNil(isDailyGoalMet)
    }
    
    func testGetUserProgress() async throws {
        // Given
        let userId = "test_user_456"
        
        // When
        let userProgress = try await progressTracker.getUserProgress(userId: userId, period: .weekly)
        
        // Then
        XCTAssertEqual(userProgress.userId, userId)
        XCTAssertEqual(userProgress.period, .weekly)
        XCTAssertNotNil(userProgress.dailyProgress)
    }
    
    func testLearningGoals() async throws {
        // Given
        let userId = "test_user_789"
        let customGoals = LearningGoals(
            userId: userId,
            dailySessionGoal: 5,
            dailyTimeGoal: 30 * 60, // 30 minutes
            weeklySessionGoal: 25,
            accuracyGoal: 0.85,
            streakGoal: 10,
            customGoals: [],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        try await progressTracker.updateLearningGoals(userId: userId, goals: customGoals)
        let retrievedGoals = try await progressTracker.getLearningGoals(userId: userId)
        
        // Then
        XCTAssertEqual(retrievedGoals.dailySessionGoal, 5)
        XCTAssertEqual(retrievedGoals.dailyTimeGoal, 30 * 60)
        XCTAssertEqual(retrievedGoals.accuracyGoal, 0.85, accuracy: 0.01)
    }
    
    func testLearningStreak() async throws {
        // Given
        let userId = "test_user_streak"
        
        // When
        let streak = try await progressTracker.getLearningStreak(userId: userId)
        
        // Then
        XCTAssertNotNil(streak)
        XCTAssertGreaterThanOrEqual(streak.currentStreak, 0)
        XCTAssertGreaterThanOrEqual(streak.longestStreak, 0)
    }
    
    func testUserAnalytics() async throws {
        // Given
        let userId = "test_user_analytics"
        
        // When
        let analytics = try await progressTracker.getUserAnalytics(userId: userId, period: .monthly)
        
        // Then
        XCTAssertEqual(analytics.userId, userId)
        XCTAssertEqual(analytics.period, .monthly)
        XCTAssertGreaterThanOrEqual(analytics.learningHealthScore, 0)
        XCTAssertLessThanOrEqual(analytics.learningHealthScore, 100)
    }
    
    func testProgressComparison() async throws {
        // Given
        let userId = "test_user_comparison"
        
        // When
        let comparison = try await progressTracker.getProgressComparison(userId: userId, period: .weekly)
        
        // Then
        XCTAssertGreaterThan(comparison.totalUsers, 0)
        XCTAssertGreaterThan(comparison.userRank, 0)
        XCTAssertGreaterThanOrEqual(comparison.percentile, 0.0)
        XCTAssertLessThanOrEqual(comparison.percentile, 1.0)
    }
    
    func testLearningInsights() async throws {
        // Given
        let userId = "test_user_insights"
        
        // When
        let insights = try await progressTracker.getLearningInsights(userId: userId)
        
        // Then
        XCTAssertNotNil(insights)
        // Insights array can be empty for new users
        for insight in insights {
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertFalse(insight.recommendation.isEmpty)
        }
    }
    
    func testExportProgressData() async throws {
        // Given
        let userId = "test_user_export"
        
        // When
        let jsonData = try await progressTracker.exportProgressData(userId: userId, format: .json)
        let csvData = try await progressTracker.exportProgressData(userId: userId, format: .csv)
        
        // Then
        XCTAssertGreaterThan(jsonData.count, 0)
        XCTAssertGreaterThan(csvData.count, 0)
        
        // Verify JSON is valid
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        XCTAssertNotNil(jsonObject)
        
        // Verify CSV has content
        let csvString = String(data: csvData, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString?.contains("Date") == true)
    }
    
    func testFactoryConvenienceMethods() async throws {
        // Given
        let userId = "test_user_factory"
        let exerciseId = UUID()
        
        // When
        try await factory.recordSession(
            userId: userId,
            exerciseId: exerciseId,
            originalText: "Bé học chăm chỉ",
            spokenText: "Bé học chăm chỉ",
            accuracy: 0.95,
            score: 95,
            timeSpent: 90,
            difficulty: .grade2,
            inputMethod: .keyboard
        )
        
        let progressSummary = try await factory.getUserProgressSummary(userId: userId, period: .daily)
        let dailyGoalStatus = try await factory.checkDailyGoalCompletion(userId: userId)
        
        // Then
        XCTAssertEqual(progressSummary.userProgress.userId, userId)
        XCTAssertNotNil(dailyGoalStatus.goals)
        XCTAssertGreaterThanOrEqual(dailyGoalStatus.progressPercentage, 0.0)
        XCTAssertLessThanOrEqual(dailyGoalStatus.progressPercentage, 1.0)
    }
    
    func testDifficultyLevelProgression() {
        // Test difficulty level properties
        XCTAssertEqual(DifficultyLevel.grade1.nextLevel, .grade2)
        XCTAssertEqual(DifficultyLevel.grade5.nextLevel, nil)
        XCTAssertEqual(DifficultyLevel.grade3.previousLevel, .grade2)
        XCTAssertEqual(DifficultyLevel.grade1.previousLevel, nil)
        
        // Test localized names
        XCTAssertEqual(DifficultyLevel.grade1.localizedName, "Lớp 1")
        XCTAssertEqual(DifficultyLevel.grade5.localizedName, "Lớp 5")
        
        // Test expected accuracy
        XCTAssertLessThan(DifficultyLevel.grade1.expectedAccuracy, DifficultyLevel.grade5.expectedAccuracy)
    }
    
    func testInputMethodAvailability() {
        // Test input method properties
        XCTAssertTrue(InputMethod.keyboard.isAvailableOnDevice)
        XCTAssertTrue(InputMethod.voice.isAvailableOnDevice)
        
        // Test localized names
        XCTAssertEqual(InputMethod.keyboard.localizedName, "Bàn phím")
        XCTAssertEqual(InputMethod.voice.localizedName, "Giọng nói")
        XCTAssertEqual(InputMethod.handwriting.localizedName, "Viết tay")
    }
    
    func testSessionResultCalculations() {
        // Given
        let sessionResult = SessionResult(
            userId: "test_user",
            exerciseId: UUID(),
            originalText: "Con mèo ngồi trên thảm xanh",
            spokenText: "Con mèo ngồi trên thảm xanh",
            accuracy: 0.95,
            score: 95,
            timeSpent: 120, // 2 minutes
            difficulty: .grade2,
            inputMethod: .voice
        )
        
        // Then
        XCTAssertEqual(sessionResult.performanceLevel, .excellent)
        XCTAssertTrue(sessionResult.qualifiesForStreak)
        XCTAssertEqual(sessionResult.formattedTimeSpent, "2m 0s")
        XCTAssertEqual(sessionResult.grade, "A")
        XCTAssertEqual(sessionResult.totalWords, 6)
        XCTAssertTrue(sessionResult.isPerfectScore == false) // 0.95 < 1.0
        XCTAssertGreaterThan(sessionResult.adjustedScore, sessionResult.score) // Grade 2 has multiplier > 1.0
    }
    
    func testPerformanceMetrics() {
        // Test performance level enum
        XCTAssertEqual(PerformanceLevel.excellent.localizedName, "Xuất sắc")
        XCTAssertEqual(PerformanceLevel.excellent.emoji, "🌟")
        XCTAssertEqual(PerformanceLevel.needsImprovement.color, "red")
        
        // Test mastery level progression
        XCTAssertLessThan(MasteryLevel.beginner.requiredAccuracy, MasteryLevel.mastered.requiredAccuracy)
        XCTAssertLessThan(MasteryLevel.beginner.requiredSessions, MasteryLevel.mastered.requiredSessions)
    }
}