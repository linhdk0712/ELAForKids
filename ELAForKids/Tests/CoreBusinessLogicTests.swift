import XCTest
@testable import ELAForKids

final class CoreBusinessLogicTests: XCTestCase {
    
    var mockTextInputHandler: MockTextInputHandler!
    var mockSpeechRecognitionManager: MockSpeechRecognitionManager!
    var mockTextComparator: MockTextComparator!
    var mockScoreCalculator: MockScoreCalculator!
    var mockUserScoreRepository: MockUserScoreRepository!
    var mockAchievementRepository: MockAchievementRepository!
    var mockProgressRepository: MockProgressRepository!
    var mockUserProfileRepository: MockUserProfileRepository!
    var mockExerciseRepository: MockExerciseRepository!
    
    override func setUp() {
        super.setUp()
        mockTextInputHandler = MockTextInputHandler()
        mockSpeechRecognitionManager = MockSpeechRecognitionManager()
        mockTextComparator = MockTextComparator()
        mockScoreCalculator = MockScoreCalculator()
        mockUserScoreRepository = MockUserScoreRepository()
        mockAchievementRepository = MockAchievementRepository()
        mockProgressRepository = MockProgressRepository()
        mockUserProfileRepository = MockUserProfileRepository()
        mockExerciseRepository = MockExerciseRepository()
    }
    
    override func tearDown() {
        mockTextInputHandler = nil
        mockSpeechRecognitionManager = nil
        mockTextComparator = nil
        mockScoreCalculator = nil
        mockUserScoreRepository = nil
        mockAchievementRepository = nil
        mockProgressRepository = nil
        mockUserProfileRepository = nil
        mockExerciseRepository = nil
        super.tearDown()
    }
    
    // MARK: - Text Input Use Case Tests
    
    func testProcessTextInputUseCase() async throws {
        // Given
        let validationService = TextValidationService()
        let useCase = ProcessTextInputUseCase(
            textInputHandler: mockTextInputHandler,
            validationService: validationService
        )
        
        let request = TextInputRequest(
            text: "Xin chào các bạn",
            inputMethod: .keyboard,
            userId: "test_user"
        )
        
        // When
        let response = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(response.processedText, "Xin chào các bạn")
        XCTAssertTrue(response.validationResult.isValid)
        XCTAssertTrue(response.suggestions.isEmpty)
    }
    
    func testValidateTextUseCase() async throws {
        // Given
        let validationService = TextValidationService()
        let useCase = ValidateTextUseCase(validationService: validationService)
        
        // When
        let result = try await useCase.execute(input: "Văn bản mẫu")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.mistakes.isEmpty)
    }
    
    func testValidateTextUseCaseWithInvalidInput() async throws {
        // Given
        let validationService = TextValidationService()
        let useCase = ValidateTextUseCase(validationService: validationService)
        
        // When
        let result = try await useCase.execute(input: "A")
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.mistakes.isEmpty)
    }
    
    // MARK: - Speech Recognition Use Case Tests
    
    func testStartSpeechRecognitionUseCase() async throws {
        // Given
        let useCase = StartSpeechRecognitionUseCase(
            speechRecognitionManager: mockSpeechRecognitionManager
        )
        
        let request = SpeechRecognitionRequest(
            userId: "test_user",
            originalText: "Xin chào",
            locale: Locale(identifier: "vi_VN")
        )
        
        // When
        try await useCase.execute(input: request)
        
        // Then
        XCTAssertTrue(mockSpeechRecognitionManager.startRecognitionCalled)
    }
    
    func testProcessSpeechUseCase() async throws {
        // Given
        let audioProcessor = AudioProcessingService()
        let useCase = ProcessSpeechUseCase(
            speechRecognitionManager: mockSpeechRecognitionManager,
            audioProcessor: audioProcessor
        )
        
        let request = SpeechProcessingRequest(
            audioData: Data(),
            originalText: "Xin chào",
            userId: "test_user"
        )
        
        // When
        let response = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(response.recognizedText, "Xin chào")
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertGreaterThan(response.processingTime, 0)
    }
    
    func testCompareTextsUseCase() async throws {
        // Given
        let useCase = CompareTextsUseCase(textComparator: mockTextComparator)
        
        let request = TextComparisonRequest(
            originalText: "Xin chào các bạn",
            spokenText: "Xin chào các bạn",
            userId: "test_user"
        )
        
        // When
        let result = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(result.originalText, "Xin chào các bạn")
        XCTAssertEqual(result.spokenText, "Xin chào các bạn")
        XCTAssertEqual(result.accuracy, 1.0)
        XCTAssertTrue(result.mistakes.isEmpty)
    }
    
    // MARK: - Scoring Use Case Tests
    
    func testCalculateScoreUseCase() async throws {
        // Given
        let useCase = CalculateScoreUseCase(
            scoreCalculator: mockScoreCalculator,
            userScoreRepository: mockUserScoreRepository
        )
        
        let request = ScoreCalculationRequest(
            accuracy: 0.95,
            attempts: 1,
            difficulty: .grade1,
            timeSpent: 30.0,
            userId: "test_user"
        )
        
        // When
        let response = try await useCase.execute(input: request)
        
        // Then
        XCTAssertGreaterThan(response.totalScore, 0)
        XCTAssertGreaterThan(response.baseScore, 0)
        XCTAssertGreaterThanOrEqual(response.bonusPoints, 0)
    }
    
    func testUpdateUserScoreUseCase() async throws {
        // Given
        let achievementManager = AchievementManager(
            achievementRepository: mockAchievementRepository,
            userScoreRepository: mockUserScoreRepository,
            notificationCenter: NotificationCenter.default
        )
        
        let useCase = UpdateUserScoreUseCase(
            userScoreRepository: mockUserScoreRepository,
            achievementManager: achievementManager
        )
        
        let request = UserScoreUpdateRequest(
            userId: "test_user",
            sessionScore: 100,
            accuracy: 0.95,
            exerciseId: UUID()
        )
        
        // When
        let result = try await useCase.execute(input: request)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockUserScoreRepository.updateScoreCalled)
    }
    
    func testCheckAchievementsUseCase() async throws {
        // Given
        let achievementManager = AchievementManager(
            achievementRepository: mockAchievementRepository,
            userScoreRepository: mockUserScoreRepository,
            notificationCenter: NotificationCenter.default
        )
        
        let useCase = CheckAchievementsUseCase(achievementManager: achievementManager)
        
        let sessionResult = SessionResult(
            userId: "test_user",
            exerciseId: UUID(),
            originalText: "Xin chào",
            spokenText: "Xin chào",
            accuracy: 1.0,
            score: 100,
            timeSpent: 30.0,
            mistakes: [],
            completedAt: Date(),
            difficulty: .grade1,
            inputMethod: .keyboard
        )
        
        let userStats = UserSessionStats(
            totalSessions: 5,
            totalScore: 500,
            averageAccuracy: 0.95,
            currentStreak: 3,
            bestStreak: 5,
            totalTimeSpent: 150.0
        )
        
        let request = AchievementCheckRequest(
            userId: "test_user",
            sessionResult: sessionResult,
            userStats: userStats
        )
        
        // When
        let achievements = try await useCase.execute(input: request)
        
        // Then
        XCTAssertNotNil(achievements)
    }
    
    // MARK: - User Management Use Case Tests
    
    func testCreateUserUseCase() async throws {
        // Given
        let useCase = CreateUserUseCase(
            userProfileRepository: mockUserProfileRepository
        )
        
        let request = CreateUserRequest(
            name: "Test User",
            grade: 1,
            parentEmail: "test@example.com"
        )
        
        // When
        let userProfile = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(userProfile.name, "Test User")
        XCTAssertEqual(userProfile.grade, 1)
        XCTAssertEqual(userProfile.parentEmail, "test@example.com")
        XCTAssertTrue(mockUserProfileRepository.createUserCalled)
    }
    
    func testGetUserProgressUseCase() async throws {
        // Given
        let useCase = GetUserProgressUseCase(
            progressRepository: mockProgressRepository,
            userScoreRepository: mockUserScoreRepository
        )
        
        let request = UserProgressRequest(
            userId: "test_user",
            date: Date(),
            goals: LearningGoals(
                dailySessionGoal: 3,
                dailyTimeGoal: 900.0,
                accuracyGoal: 0.8,
                streakGoal: 7
            )
        )
        
        // When
        let progress = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(progress.userId, "test_user")
        XCTAssertTrue(mockProgressRepository.getDailyProgressCalled)
        XCTAssertTrue(mockProgressRepository.getWeeklyProgressCalled)
    }
    
    // MARK: - Exercise Management Use Case Tests
    
    func testGetExerciseUseCase() async throws {
        // Given
        let useCase = GetExerciseUseCase(
            exerciseRepository: mockExerciseRepository
        )
        
        let exerciseId = UUID()
        let request = ExerciseRequest(exerciseId: exerciseId)
        
        // When
        let exercise = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(exercise.id, exerciseId)
        XCTAssertTrue(mockExerciseRepository.getExerciseCalled)
    }
    
    func testCreateExerciseUseCase() async throws {
        // Given
        let useCase = CreateExerciseUseCase(
            exerciseRepository: mockExerciseRepository
        )
        
        let request = CreateExerciseRequest(
            title: "Bài tập mẫu",
            targetText: "Đây là văn bản mẫu để luyện tập",
            category: "story",
            difficulty: .grade1,
            tags: ["mẫu", "luyện tập"]
        )
        
        // When
        let exercise = try await useCase.execute(input: request)
        
        // Then
        XCTAssertEqual(exercise.title, "Bài tập mẫu")
        XCTAssertEqual(exercise.targetText, "Đây là văn bản mẫu để luyện tập")
        XCTAssertEqual(exercise.difficulty, .grade1)
        XCTAssertTrue(mockExerciseRepository.createExerciseCalled)
    }
    
    func testGetExerciseListUseCase() async throws {
        // Given
        let useCase = GetExerciseListUseCase(
            exerciseRepository: mockExerciseRepository
        )
        
        let request = ExerciseListRequest(
            category: "story",
            difficulty: .grade1,
            limit: 10
        )
        
        // When
        let exercises = try await useCase.execute(input: request)
        
        // Then
        XCTAssertNotNil(exercises)
        XCTAssertTrue(mockExerciseRepository.getExercisesCalled)
    }
    
    // MARK: - Validation Service Tests
    
    func testTextValidationService() {
        // Given
        let service = TextValidationService()
        
        // When
        let validResult = service.validate("Văn bản hợp lệ")
        let invalidResult = service.validate("A")
        let emptyResult = service.validate("")
        
        // Then
        XCTAssertTrue(validResult.isValid)
        XCTAssertTrue(validResult.mistakes.isEmpty)
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertFalse(invalidResult.mistakes.isEmpty)
        
        XCTAssertFalse(emptyResult.isValid)
        XCTAssertFalse(emptyResult.mistakes.isEmpty)
    }
    
    func testTextValidationServiceSuggestions() {
        // Given
        let service = TextValidationService()
        
        // When
        let emptySuggestions = service.generateSuggestions(for: "", validationResult: ValidationResult(
            isValid: false,
            mistakes: [],
            suggestions: []
        ))
        
        let mistakeSuggestions = service.generateSuggestions(for: "A", validationResult: ValidationResult(
            isValid: false,
            mistakes: [TextMistake(
                id: UUID(),
                expectedWord: "A",
                actualWord: "A",
                mistakeType: .omission,
                position: 0,
                severity: .minor
            )],
            suggestions: []
        ))
        
        // Then
        XCTAssertTrue(emptySuggestions.contains("Hãy nhập văn bản để luyện tập"))
        XCTAssertTrue(mistakeSuggestions.contains("Hãy kiểm tra lại các từ bị thiếu"))
    }
    
    // MARK: - Audio Processing Service Tests
    
    func testAudioProcessingService() async throws {
        // Given
        let service = AudioProcessingService()
        let testData = Data([1, 2, 3, 4, 5])
        
        // When
        let processedData = try await service.processAudio(testData)
        
        // Then
        XCTAssertEqual(processedData, testData)
    }
}

// MARK: - Mock Implementations

class MockTextInputHandler: TextInputProtocol {
    func processText(_ text: String, method: InputMethod) async throws -> String {
        return text
    }
    
    func validateText(_ text: String) -> Bool {
        return text.count >= 2
    }
    
    func getSuggestions(for text: String) -> [String] {
        return []
    }
}

class MockSpeechRecognitionManager: SpeechRecognitionProtocol {
    var currentConfidence: Float = 0.95
    var startRecognitionCalled = false
    
    func startRecognition(for text: String, locale: Locale, userId: String) async throws {
        startRecognitionCalled = true
    }
    
    func recognizeSpeech(from audioData: Data) async throws -> String {
        return "Xin chào"
    }
    
    func stopRecognition() {
        // Mock implementation
    }
    
    func requestPermission() async -> Bool {
        return true
    }
}

class MockTextComparator: TextComparisonProtocol {
    func compareTexts(original: String, spoken: String) -> ComparisonResult {
        let accuracy: Float = original == spoken ? 1.0 : 0.8
        let mistakes: [TextMistake] = original == spoken ? [] : [
            TextMistake(
                id: UUID(),
                expectedWord: original,
                actualWord: spoken,
                mistakeType: .substitution,
                position: 0,
                severity: .minor
            )
        ]
        
        return ComparisonResult(
            originalText: original,
            spokenText: spoken,
            accuracy: accuracy,
            mistakes: mistakes,
            matchedWords: original.components(separatedBy: " "),
            feedback: accuracy == 1.0 ? "Tuyệt vời!" : "Hãy thử lại"
        )
    }
    
    func identifyMistakes(original: String, spoken: String) -> [TextMistake] {
        return []
    }
    
    func calculateAccuracy(original: String, spoken: String) -> Float {
        return original == spoken ? 1.0 : 0.8
    }
    
    func generateFeedback(comparisonResult: ComparisonResult) -> String {
        return comparisonResult.feedback
    }
}

class MockScoreCalculator: ScoringProtocol {
    func calculateScore(accuracy: Float, attempts: Int, difficulty: DifficultyLevel, timeSpent: TimeInterval, userStats: UserSessionStats) -> ScoreResult {
        let baseScore = Int(accuracy * 100)
        let bonusPoints = attempts == 1 ? 20 : 0
        let totalScore = baseScore + bonusPoints
        
        return ScoreResult(
            baseScore: baseScore,
            bonusPoints: bonusPoints,
            totalScore: totalScore,
            multiplier: 1.0,
            breakdown: ScoreBreakdown(
                accuracyPoints: baseScore,
                speedBonus: 0,
                difficultyBonus: 0,
                streakBonus: 0,
                perfectBonus: accuracy == 1.0 ? 50 : 0
            )
        )
    }
    
    func calculateStreakBonus(currentStreak: Int) -> Int {
        return min(currentStreak * 5, 50)
    }
    
    func calculateTimeBonus(timeSpent: TimeInterval, difficulty: DifficultyLevel) -> Int {
        return 0
    }
}

class MockUserScoreRepository: UserScoreRepositoryProtocol {
    var updateScoreCalled = false
    var addAchievementCalled = false
    
    func updateScore(userId: String, sessionScore: Int, accuracy: Float, exerciseId: UUID) async throws -> UserScore {
        updateScoreCalled = true
        return UserScore(
            id: UUID().uuidString,
            userId: userId,
            totalScore: sessionScore,
            level: 1,
            experience: 100,
            rank: "Beginner"
        )
    }
    
    func getUserStats(userId: String) async throws -> UserSessionStats {
        return UserSessionStats(
            totalSessions: 5,
            totalScore: 500,
            averageAccuracy: 0.95,
            currentStreak: 3,
            bestStreak: 5,
            totalTimeSpent: 150.0
        )
    }
    
    func addAchievements(_ achievements: [Achievement], for userId: String) async throws {
        addAchievementCalled = true
    }
}

class MockAchievementRepository: AchievementRepositoryProtocol {
    func getAllAchievements() async throws -> [Achievement] {
        return []
    }
    
    func getUserAchievements(userId: String) async throws -> [Achievement] {
        return []
    }
    
    func saveUserAchievement(_ achievement: Achievement, userId: String) async throws {
        // Mock implementation
    }
}

class MockProgressRepository: ProgressRepositoryProtocol {
    var getDailyProgressCalled = false
    var getWeeklyProgressCalled = false
    
    func getDailyProgress(userId: String, date: Date) async throws -> DailyProgress {
        getDailyProgressCalled = true
        return DailyProgress(
            date: date,
            sessionsCompleted: 3,
            timeSpent: 900.0,
            averageAccuracy: 0.95,
            scoreEarned: 300
        )
    }
    
    func getWeeklyProgress(userId: String, weekOf: Date) async throws -> WeeklyProgress {
        getWeeklyProgressCalled = true
        return WeeklyProgress(
            weekOf: weekOf,
            totalSessions: 15,
            totalTime: 4500.0,
            averageAccuracy: 0.92,
            totalScore: 1500,
            streakDays: 5
        )
    }
    
    func updateProgress(userId: String, sessionResult: SessionResult, goals: LearningGoals) async throws -> UserProgress {
        return UserProgress(
            userId: userId,
            date: Date(),
            dailyProgress: DailyProgress(
                date: Date(),
                sessionsCompleted: 1,
                timeSpent: 300.0,
                averageAccuracy: 0.95,
                scoreEarned: 100
            ),
            weeklyProgress: WeeklyProgress(
                weekOf: Date(),
                totalSessions: 5,
                totalTime: 1500.0,
                averageAccuracy: 0.93,
                totalScore: 500,
                streakDays: 3
            ),
            userStats: UserSessionStats(
                totalSessions: 5,
                totalScore: 500,
                averageAccuracy: 0.93,
                currentStreak: 3,
                bestStreak: 5,
                totalTimeSpent: 1500.0
            ),
            goals: goals
        )
    }
}

class MockUserProfileRepository: UserProfileRepositoryProtocol {
    var createUserCalled = false
    
    func createUser(_ userProfile: UserProfile) async throws -> UserProfile {
        createUserCalled = true
        return userProfile
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile? {
        return nil
    }
    
    func updateUserProfile(_ userProfile: UserProfile) async throws {
        // Mock implementation
    }
    
    func deleteUserProfile(userId: String) async throws {
        // Mock implementation
    }
}

class MockExerciseRepository: ExerciseRepositoryProtocol {
    var getExerciseCalled = false
    var createExerciseCalled = false
    var getExercisesCalled = false
    
    func getExercise(id: UUID) async throws -> Exercise {
        getExerciseCalled = true
        return Exercise(
            id: id,
            title: "Bài tập mẫu",
            targetText: "Đây là văn bản mẫu",
            category: "story",
            difficulty: .grade1,
            tags: ["mẫu"],
            createdAt: Date()
        )
    }
    
    func createExercise(_ exercise: Exercise) async throws -> Exercise {
        createExerciseCalled = true
        return exercise
    }
    
    func getExercises(category: String?, difficulty: DifficultyLevel?, limit: Int?) async throws -> [Exercise] {
        getExercisesCalled = true
        return [
            Exercise(
                id: UUID(),
                title: "Bài tập 1",
                targetText: "Văn bản 1",
                category: category ?? "story",
                difficulty: difficulty ?? .grade1,
                tags: ["bài tập"],
                createdAt: Date()
            )
        ]
    }
    
    func updateExercise(_ exercise: Exercise) async throws {
        // Mock implementation
    }
    
    func deleteExercise(id: UUID) async throws {
        // Mock implementation
    }
}
