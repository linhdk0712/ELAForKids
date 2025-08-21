import XCTest
import SwiftUI
@testable import ELAForKids

// MARK: - Accessibility Tests

final class AccessibilityTests: XCTestCase {
    
    var accessibilityManager: AccessibilityManager!
    
    override func setUp() {
        super.setUp()
        accessibilityManager = AccessibilityManager.shared
    }
    
    override func tearDown() {
        accessibilityManager = nil
        super.tearDown()
    }
    
    // MARK: - AccessibilityManager Tests
    
    func testAccessibilityManagerInitialization() {
        XCTAssertNotNil(accessibilityManager)
        XCTAssertFalse(accessibilityManager.isVoiceOverEnabled) // Default in test environment
    }
    
    func testReadingTextAccessibilityLabel() {
        let text = "Con mèo ngồi trên thảm"
        let mistakes: [TextMistake] = []
        
        let label = accessibilityManager.getReadingTextAccessibilityLabel(text: text, mistakes: mistakes)
        
        XCTAssertEqual(label, "Văn bản cần đọc: \(text). Không có lỗi.")
    }
    
    func testReadingTextAccessibilityLabelWithMistakes() {
        let text = "Con mèo ngồi trên thảm"
        let mistakes = [
            createMockTextMistake(expectedWord: "mèo", actualWord: "chó", position: 1),
            createMockTextMistake(expectedWord: "thảm", actualWord: nil, position: 4)
        ]
        
        let label = accessibilityManager.getReadingTextAccessibilityLabel(text: text, mistakes: mistakes)
        
        XCTAssertTrue(label.contains("2 lỗi"))
        XCTAssertTrue(label.contains("Văn bản cần đọc"))
    }
    
    func testScoreAccessibilityLabel() {
        let score = 85
        let accuracy: Float = 0.85
        
        let label = accessibilityManager.getScoreAccessibilityLabel(score: score, accuracy: accuracy)
        
        XCTAssertEqual(label, "Điểm số: 85 điểm. Độ chính xác: 85 phần trăm.")
    }
    
    func testProgressAccessibilityLabel() {
        let current = 3
        let total = 10
        let type = "Bài tập"
        
        let label = accessibilityManager.getProgressAccessibilityLabel(current: current, total: total, type: type)
        
        XCTAssertEqual(label, "Bài tập: 3 trên 10. Hoàn thành 30 phần trăm.")
    }
    
    func testStreakAccessibilityLabel() {
        let currentStreak = 5
        let bestStreak = 12
        
        let label = accessibilityManager.getStreakAccessibilityLabel(currentStreak: currentStreak, bestStreak: bestStreak)
        
        XCTAssertEqual(label, "Chuỗi học tập hiện tại: 5 ngày. Kỷ lục cá nhân: 12 ngày.")
    }
    
    func testAccessibilityHints() {
        let practiceHint = accessibilityManager.getAccessibilityHint(for: .practiceButton)
        let recordHint = accessibilityManager.getAccessibilityHint(for: .recordButton)
        let playHint = accessibilityManager.getAccessibilityHint(for: .playButton)
        
        XCTAssertEqual(practiceHint, "Nhấn đúp để bắt đầu luyện tập đọc")
        XCTAssertEqual(recordHint, "Nhấn đúp để bắt đầu hoặc dừng ghi âm")
        XCTAssertEqual(playHint, "Nhấn đúp để phát âm thanh")
    }
    
    func testAnimationDurationWithReducedMotion() {
        // Test with reduced motion disabled
        accessibilityManager.isReduceMotionEnabled = false
        let normalDuration = accessibilityManager.getAnimationDuration(default: 1.0)
        XCTAssertEqual(normalDuration, 1.0)
        
        // Test with reduced motion enabled
        accessibilityManager.isReduceMotionEnabled = true
        let reducedDuration = accessibilityManager.getAnimationDuration(default: 1.0)
        XCTAssertEqual(reducedDuration, 0.1)
    }
    
    func testHapticIntensityWithAssistiveTouch() {
        // Test with assistive touch disabled
        accessibilityManager.isAssistiveTouchEnabled = false
        let normalIntensity = accessibilityManager.getHapticIntensity(default: 1.0)
        XCTAssertEqual(normalIntensity, 1.0)
        
        // Test with assistive touch enabled
        accessibilityManager.isAssistiveTouchEnabled = true
        let reducedIntensity = accessibilityManager.getHapticIntensity(default: 1.0)
        XCTAssertEqual(reducedIntensity, 0.5)
    }
    
    // MARK: - Content Size Category Tests
    
    func testContentSizeCategoryScaleFactor() {
        let mediumCategory = ContentSizeCategory.medium
        XCTAssertEqual(mediumCategory.scaleFactor, 1.0)
        
        let largeCategory = ContentSizeCategory.large
        XCTAssertEqual(largeCategory.scaleFactor, 1.1)
        
        let accessibilityLargeCategory = ContentSizeCategory.accessibilityLarge
        XCTAssertEqual(accessibilityLargeCategory.scaleFactor, 1.6)
    }
    
    func testContentSizeCategoryIsAccessibilitySize() {
        let mediumCategory = ContentSizeCategory.medium
        XCTAssertFalse(mediumCategory.isAccessibilitySize)
        
        let accessibilityMediumCategory = ContentSizeCategory.accessibilityMedium
        XCTAssertTrue(accessibilityMediumCategory.isAccessibilitySize)
    }
    
    // MARK: - TextMistake Extensions Tests
    
    func testTextMistakeTypeLocalizedNames() {
        XCTAssertEqual(TextMistake.MistakeType.substitution.localizedName, "Thay thế từ")
        XCTAssertEqual(TextMistake.MistakeType.omission.localizedName, "Thiếu từ")
        XCTAssertEqual(TextMistake.MistakeType.insertion.localizedName, "Thừa từ")
        XCTAssertEqual(TextMistake.MistakeType.pronunciation.localizedName, "Phát âm sai")
    }
    
    func testTextMistakeTypeColors() {
        XCTAssertEqual(TextMistake.MistakeType.substitution.color, .red)
        XCTAssertEqual(TextMistake.MistakeType.omission.color, .orange)
        XCTAssertEqual(TextMistake.MistakeType.insertion.color, .blue)
        XCTAssertEqual(TextMistake.MistakeType.pronunciation.color, .purple)
    }
    
    func testTextMistakeSeverityColors() {
        XCTAssertEqual(TextMistake.Severity.low.color, .yellow)
        XCTAssertEqual(TextMistake.Severity.medium.color, .orange)
        XCTAssertEqual(TextMistake.Severity.high.color, .red)
    }
    
    // MARK: - DifficultyLevel Tests
    
    func testDifficultyLevelLocalizedNames() {
        XCTAssertEqual(DifficultyLevel.grade1.localizedName, "Lớp 1")
        XCTAssertEqual(DifficultyLevel.grade2.localizedName, "Lớp 2")
        XCTAssertEqual(DifficultyLevel.grade5.localizedName, "Lớp 5")
    }
    
    func testDifficultyLevelNextLevel() {
        XCTAssertEqual(DifficultyLevel.grade1.nextLevel, .grade2)
        XCTAssertEqual(DifficultyLevel.grade4.nextLevel, .grade5)
        XCTAssertNil(DifficultyLevel.grade5.nextLevel)
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityManagerPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = accessibilityManager.getReadingTextAccessibilityLabel(
                    text: "Con mèo ngồi trên thảm xanh",
                    mistakes: []
                )
            }
        }
    }
    
    func testScoreAccessibilityLabelPerformance() {
        measure {
            for i in 0..<1000 {
                _ = accessibilityManager.getScoreAccessibilityLabel(
                    score: i,
                    accuracy: Float(i) / 1000.0
                )
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testVoiceOverAnnouncement() {
        // This test verifies that announcements don't crash
        // Actual VoiceOver testing would require UI testing
        accessibilityManager.announceToVoiceOver("Test announcement", priority: .medium)
        accessibilityManager.announceToVoiceOver("High priority test", priority: .high)
        accessibilityManager.announceToVoiceOver("Low priority test", priority: .low)
        
        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }
    
    func testAccessibilityValueForProgressChart() {
        let value = accessibilityManager.getAccessibilityValue(for: .progressChart, value: 0.75)
        XCTAssertEqual(value, "75 phần trăm")
    }
    
    func testAccessibilityValueForDifficultySelector() {
        let value = accessibilityManager.getAccessibilityValue(for: .difficultySelector, value: DifficultyLevel.grade3)
        XCTAssertEqual(value, "Lớp 3")
    }
    
    // MARK: - Helper Methods
    
    private func createMockTextMistake(expectedWord: String, actualWord: String?, position: Int) -> TextMistake {
        // This would need to be implemented based on your actual TextMistake structure
        // For now, returning a mock structure
        return TextMistake(
            id: UUID(),
            expectedWord: expectedWord,
            actualWord: actualWord,
            position: position,
            mistakeType: .substitution,
            severity: .medium
        )
    }
}

// MARK: - Mock TextMistake for Testing

extension TextMistake {
    init(id: UUID, expectedWord: String, actualWord: String?, position: Int, mistakeType: MistakeType, severity: Severity) {
        // This initializer would need to match your actual TextMistake structure
        // Implement based on your Core Data model
    }
}

// MARK: - Accessibility UI Tests

final class AccessibilityUITests: XCTestCase {
    
    func testMainMenuAccessibility() {
        // UI tests would go here to test actual VoiceOver navigation
        // These require XCUITest framework and would test:
        // - Tab navigation with VoiceOver
        // - Button accessibility labels and hints
        // - Proper focus management
    }
    
    func testReadingPracticeAccessibility() {
        // UI tests for reading practice view accessibility
        // Would test:
        // - Text input accessibility
        // - Voice recording button accessibility
        // - Progress indicator accessibility
    }
    
    func testResultsViewAccessibility() {
        // UI tests for results view accessibility
        // Would test:
        // - Score display accessibility
        // - Achievement announcements
        // - Navigation button accessibility
    }
}