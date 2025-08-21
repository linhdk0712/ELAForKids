import XCTest
@testable import ELAForKids

final class UserJourneyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Main User Journey Tests
    
    func testCompleteTextInputToSpeechRecordingFlow() {
        // Given - App is launched and user is on main menu
        
        // When - Navigate to text input
        let textInputButton = app.buttons["Text Input"]
        XCTAssertTrue(textInputButton.exists)
        textInputButton.tap()
        
        // Then - Should be on text input screen
        let textInputTitle = app.navigationBars["Viết văn bản"]
        XCTAssertTrue(textInputTitle.exists)
        
        // When - Enter text
        let textField = app.textFields["Text Input Field"]
        XCTAssertTrue(textField.exists)
        textField.tap()
        textField.typeText("Xin chào các bạn")
        
        // Then - Text should be entered
        XCTAssertEqual(textField.value as? String, "Xin chào các bạn")
        
        // When - Continue to reading practice
        let continueButton = app.buttons["Tiếp tục đọc"]
        XCTAssertTrue(continueButton.exists)
        continueButton.tap()
        
        // Then - Should be on reading practice screen
        let readingTitle = app.navigationBars["Luyện tập đọc"]
        XCTAssertTrue(readingTitle.exists)
        
        // When - Start speech recording
        let recordButton = app.buttons["Record Button"]
        XCTAssertTrue(recordButton.exists)
        recordButton.tap()
        
        // Then - Should show recording state
        let recordingIndicator = app.staticTexts["Recording..."]
        XCTAssertTrue(recordingIndicator.exists)
        
        // When - Stop recording
        let stopButton = app.buttons["Stop Button"]
        XCTAssertTrue(stopButton.exists)
        stopButton.tap()
        
        // Then - Should show processing state
        let processingIndicator = app.staticTexts["Processing..."]
        XCTAssertTrue(processingIndicator.exists)
        
        // When - Results are ready
        let resultsTitle = app.navigationBars["Kết quả"]
        XCTAssertTrue(resultsTitle.exists)
        
        // Then - Should display accuracy and score
        let accuracyLabel = app.staticTexts["Accuracy:"]
        XCTAssertTrue(accuracyLabel.exists)
        
        let scoreLabel = app.staticTexts["Score:"]
        XCTAssertTrue(scoreLabel.exists)
    }
    
    func testHandwritingInputFlow() {
        // Given - User is on text input screen
        
        // Navigate to text input
        let textInputButton = app.buttons["Text Input"]
        textInputButton.tap()
        
        // When - Switch to pencil mode
        let pencilModeButton = app.buttons["Pencil Mode"]
        XCTAssertTrue(pencilModeButton.exists)
        pencilModeButton.tap()
        
        // Then - Should show pencil canvas
        let pencilCanvas = app.otherElements["Pencil Canvas"]
        XCTAssertTrue(pencilCanvas.exists)
        
        // When - Draw some text
        pencilCanvas.tap()
        // Simulate drawing gesture
        let startPoint = pencilCanvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let endPoint = pencilCanvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        
        // Then - Should show recognition result
        let recognitionResult = app.staticTexts["Recognition Result"]
        XCTAssertTrue(recognitionResult.exists)
        
        // When - Accept recognition
        let acceptButton = app.buttons["Accept"]
        XCTAssertTrue(acceptButton.exists)
        acceptButton.tap()
        
        // Then - Should continue to reading practice
        let readingTitle = app.navigationBars["Luyện tập đọc"]
        XCTAssertTrue(readingTitle.exists)
    }
    
    func testAchievementUnlockingFlow() {
        // Given - User completes a perfect reading session
        
        // Complete a session (simplified for UI test)
        completePerfectReadingSession()
        
        // When - Achievement is unlocked
        let achievementPopup = app.otherElements["Achievement Popup"]
        XCTAssertTrue(achievementPopup.exists)
        
        // Then - Should show achievement details
        let achievementTitle = achievementPopup.staticTexts["Achievement Title"]
        XCTAssertTrue(achievementTitle.exists)
        
        let achievementDescription = achievementPopup.staticTexts["Achievement Description"]
        XCTAssertTrue(achievementDescription.exists)
        
        // When - User taps on achievement
        achievementPopup.tap()
        
        // Then - Should navigate to achievements screen
        let achievementsTitle = app.navigationBars["Thành tích"]
        XCTAssertTrue(achievementsTitle.exists)
        
        // Should show the newly unlocked achievement
        let unlockedAchievement = app.staticTexts["Perfect Reader"]
        XCTAssertTrue(unlockedAchievement.exists)
    }
    
    func testProgressTrackingFlow() {
        // Given - User has completed several sessions
        
        // Navigate to profile
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
        // Then - Should show progress statistics
        let progressSection = app.staticTexts["Progress Section"]
        XCTAssertTrue(progressSection.exists)
        
        let totalSessions = app.staticTexts["Total Sessions:"]
        XCTAssertTrue(totalSessions.exists)
        
        let averageAccuracy = app.staticTexts["Average Accuracy:"]
        XCTAssertTrue(averageAccuracy.exists)
        
        let currentStreak = app.staticTexts["Current Streak:"]
        XCTAssertTrue(currentStreak.exists)
        
        // When - Tap on progress details
        let progressDetailsButton = app.buttons["View Progress Details"]
        XCTAssertTrue(progressDetailsButton.exists)
        progressDetailsButton.tap()
        
        // Then - Should show detailed progress
        let progressChart = app.otherElements["Progress Chart"]
        XCTAssertTrue(progressChart.exists)
        
        let weeklyProgress = app.staticTexts["Weekly Progress"]
        XCTAssertTrue(weeklyProgress.exists)
    }
    
    func testErrorHandlingFlow() {
        // Given - User encounters an error (e.g., no microphone permission)
        
        // Try to start speech recognition without permission
        let textInputButton = app.buttons["Text Input"]
        textInputButton.tap()
        
        let textField = app.textFields["Text Input Field"]
        textField.tap()
        textField.typeText("Test text")
        
        let continueButton = app.buttons["Tiếp tục đọc"]
        continueButton.tap()
        
        let recordButton = app.buttons["Record Button"]
        recordButton.tap()
        
        // When - Permission error occurs
        let errorAlert = app.alerts["Permission Required"]
        XCTAssertTrue(errorAlert.exists)
        
        // Then - Should show helpful error message
        let errorMessage = errorAlert.staticTexts["Microphone access is required for speech recognition"]
        XCTAssertTrue(errorMessage.exists)
        
        // When - User taps settings button
        let settingsButton = errorAlert.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()
        
        // Then - Should handle navigation to settings gracefully
        // (In real app, this would open system settings)
    }
    
    func testOfflineModeFlow() {
        // Given - App is in offline mode
        
        // Simulate offline state
        app.launchArguments = ["UI-Testing", "Offline-Mode"]
        app.terminate()
        app.launch()
        
        // When - User tries to use online features
        let textInputButton = app.buttons["Text Input"]
        textInputButton.tap()
        
        // Then - Should show offline indicator
        let offlineIndicator = app.staticTexts["Offline Mode"]
        XCTAssertTrue(offlineIndicator.exists)
        
        // Should still allow basic functionality
        let textField = app.textFields["Text Input Field"]
        XCTAssertTrue(textField.exists)
        textField.tap()
        textField.typeText("Offline test")
        
        // When - Try to continue
        let continueButton = app.buttons["Tiếp tục đọc"]
        continueButton.tap()
        
        // Then - Should show offline message but allow practice
        let offlineMessage = app.staticTexts["Working offline - some features limited"]
        XCTAssertTrue(offlineMessage.exists)
    }
    
    func testAccessibilityFlow() {
        // Given - App is running with VoiceOver enabled
        
        // Enable accessibility testing
        app.launchArguments = ["UI-Testing", "Accessibility-Testing"]
        app.terminate()
        app.launch()
        
        // When - Navigating through the app
        let textInputButton = app.buttons["Text Input"]
        XCTAssertTrue(textInputButton.exists)
        
        // Then - Should have proper accessibility labels
        XCTAssertTrue(textInputButton.hasValidAccessibilityLabel)
        
        // When - Entering text
        let textField = app.textFields["Text Input Field"]
        textField.tap()
        textField.typeText("Accessibility test")
        
        // Then - Should have proper accessibility hints
        XCTAssertTrue(textField.hasValidAccessibilityHint)
        
        // When - Viewing results
        let continueButton = app.buttons["Tiếp tục đọc"]
        continueButton.tap()
        
        // Then - Should have proper accessibility traits
        let recordButton = app.buttons["Record Button"]
        XCTAssertTrue(recordButton.hasValidAccessibilityTraits)
    }
    
    func testResponsiveLayoutFlow() {
        // Given - App is running on different device orientations
        
        // Test portrait orientation
        XCUIDevice.shared.orientation = .portrait
        
        let textInputButton = app.buttons["Text Input"]
        textInputButton.tap()
        
        // Verify portrait layout
        let portraitLayout = app.otherElements["Portrait Layout"]
        XCTAssertTrue(portraitLayout.exists)
        
        // Test landscape orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Verify landscape layout
        let landscapeLayout = app.otherElements["Landscape Layout"]
        XCTAssertTrue(landscapeLayout.exists)
        
        // Test different device sizes (simulated)
        app.launchArguments = ["UI-Testing", "Device-Size-iPad"]
        app.terminate()
        app.launch()
        
        // Verify iPad layout
        let iPadLayout = app.otherElements["iPad Layout"]
        XCTAssertTrue(iPadLayout.exists)
    }
    
    func testPerformanceFlow() {
        // Given - App is running performance tests
        
        // Measure app launch time
        let startTime = Date()
        app.launch()
        let launchTime = Date().timeIntervalSince(startTime)
        
        // Then - Launch should be reasonably fast
        XCTAssertLessThan(launchTime, 3.0, "App should launch in under 3 seconds")
        
        // Measure navigation performance
        let textInputButton = app.buttons["Text Input"]
        let navigationStartTime = Date()
        textInputButton.tap()
        let navigationTime = Date().timeIntervalSince(navigationStartTime)
        
        // Then - Navigation should be smooth
        XCTAssertLessThan(navigationTime, 1.0, "Navigation should be under 1 second")
        
        // Measure text input performance
        let textField = app.textFields["Text Input Field"]
        textField.tap()
        
        let inputStartTime = Date()
        textField.typeText("Performance test text")
        let inputTime = Date().timeIntervalSince(inputStartTime)
        
        // Then - Text input should be responsive
        XCTAssertLessThan(inputTime, 2.0, "Text input should be under 2 seconds")
    }
    
    // MARK: - Helper Methods
    
    private func completePerfectReadingSession() {
        // Navigate to text input
        let textInputButton = app.buttons["Text Input"]
        textInputButton.tap()
        
        // Enter text
        let textField = app.textFields["Text Input Field"]
        textField.tap()
        textField.typeText("Perfect reading test")
        
        // Continue to reading
        let continueButton = app.buttons["Tiếp tục đọc"]
        continueButton.tap()
        
        // Complete recording (simplified)
        let recordButton = app.buttons["Record Button"]
        recordButton.tap()
        
        // Wait for processing
        let processingIndicator = app.staticTexts["Processing..."]
        XCTAssertTrue(processingIndicator.waitForExistence(timeout: 5))
        
        // Simulate perfect result
        // In real app, this would come from the speech recognition system
    }
}

// MARK: - Accessibility Extensions

extension XCUIElement {
    var hasValidAccessibilityLabel: Bool {
        guard let label = accessibilityLabel else { return false }
        return !label.isEmpty && label.count > 2
    }
    
    var hasValidAccessibilityHint: Bool {
        guard let hint = accessibilityHint else { return false }
        return !hint.isEmpty && hint.count > 5
    }
    
    var hasValidAccessibilityTraits: Bool {
        return accessibilityTraits != .none
    }
}

// MARK: - Test Data

struct TestUser {
    let name = "Test User"
    let grade = 1
    let parentEmail = "test@example.com"
}

struct TestExercise {
    let title = "Test Exercise"
    let text = "This is a test exercise for UI testing"
    let category = "story"
    let difficulty = DifficultyLevel.grade1
}

struct TestSessionResult {
    let accuracy: Float = 0.95
    let score: Int = 100
    let timeSpent: TimeInterval = 30.0
    let mistakes: [TextMistake] = []
}
