import XCTest
import SwiftUI
@testable import ELAForKids

final class VisualFeedbackTests: XCTestCase {
    
    // MARK: - Text Highlight View Tests
    
    func testTextHighlightViewWithNoMistakes() {
        let text = "Con mèo ngồi trên thảm"
        let mistakes: [TextMistake] = []
        let matchedWords = ["Con", "mèo", "ngồi", "trên", "thảm"]
        
        // Test that all words are highlighted as correct
        let view = TextHighlightView(
            text: text,
            mistakes: mistakes,
            matchedWords: matchedWords
        )
        
        // Verify view can be created without errors
        XCTAssertNotNil(view)
    }
    
    func testTextHighlightViewWithMistakes() {
        let text = "Con mèo ngồi trên thảm"
        let mistakes = [
            TextMistake(
                position: 1,
                expectedWord: "mèo",
                actualWord: "chó",
                mistakeType: .substitution,
                severity: .moderate
            ),
            TextMistake(
                position: 3,
                expectedWord: "trên",
                actualWord: "",
                mistakeType: .omission,
                severity: .moderate
            )
        ]
        let matchedWords = ["Con", "ngồi", "thảm"]
        
        let view = TextHighlightView(
            text: text,
            mistakes: mistakes,
            matchedWords: matchedWords
        ) { word, index in
            // Test word tap callback
            XCTAssertTrue(!word.isEmpty)
            XCTAssertGreaterThanOrEqual(index, 0)
        }
        
        XCTAssertNotNil(view)
    }
    
    func testTextHighlightViewWordParsing() {
        let text = "Con mèo ngồi trên thảm"
        let expectedWords = ["Con", "mèo", "ngồi", "trên", "thảm"]
        let actualWords = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        XCTAssertEqual(actualWords, expectedWords)
    }
    
    func testTextHighlightViewWithPunctuation() {
        let text = "Con mèo, ngồi trên thảm!"
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Should include punctuation in words
        XCTAssertEqual(words.count, 5)
        XCTAssertEqual(words[1], "mèo,")
        XCTAssertEqual(words[4], "thảm!")
    }
    
    // MARK: - Mistake Feedback View Tests
    
    func testMistakeFeedbackViewWithNoMistakes() {
        let mistakes: [TextMistake] = []
        
        let view = MistakeFeedbackView(
            mistakes: mistakes,
            onRetryWord: nil,
            onPlayCorrectPronunciation: nil
        )
        
        XCTAssertNotNil(view)
    }
    
    func testMistakeFeedbackViewWithMistakes() {
        let mistakes = [
            TextMistake(
                position: 0,
                expectedWord: "mèo",
                actualWord: "chó",
                mistakeType: .substitution,
                severity: .moderate
            ),
            TextMistake(
                position: 1,
                expectedWord: "thảm",
                actualWord: "tảm",
                mistakeType: .mispronunciation,
                severity: .minor
            )
        ]
        
        var retryWordCalled = false
        var playPronunciationCalled = false
        
        let view = MistakeFeedbackView(
            mistakes: mistakes,
            onRetryWord: { mistake in
                retryWordCalled = true
                XCTAssertEqual(mistake.expectedWord, "mèo")
            },
            onPlayCorrectPronunciation: { word in
                playPronunciationCalled = true
                XCTAssertEqual(word, "mèo")
            }
        )
        
        XCTAssertNotNil(view)
    }
    
    // MARK: - Pronunciation Feedback Tests
    
    func testPronunciationFeedbackCorrect() {
        let feedback = PronunciationFeedback.correct(
            expectedWord: "mèo",
            spokenWord: "mèo"
        )
        
        XCTAssertTrue(feedback.isCorrect)
        XCTAssertEqual(feedback.expectedWord, "mèo")
        XCTAssertEqual(feedback.spokenWord, "mèo")
        XCTAssertEqual(feedback.confidence, 1.0)
        XCTAssertEqual(feedback.icon, "checkmark.circle.fill")
        XCTAssertTrue(feedback.title.contains("Tuyệt vời"))
    }
    
    func testPronunciationFeedbackMispronunciation() {
        let feedback = PronunciationFeedback.mispronunciation(
            expectedWord: "mèo",
            spokenWord: "meo",
            confidence: 0.7
        )
        
        XCTAssertFalse(feedback.isCorrect)
        XCTAssertEqual(feedback.expectedWord, "mèo")
        XCTAssertEqual(feedback.spokenWord, "meo")
        XCTAssertEqual(feedback.confidence, 0.7)
        XCTAssertEqual(feedback.icon, "exclamationmark.triangle.fill")
        XCTAssertTrue(feedback.title.contains("Gần đúng"))
    }
    
    func testPronunciationFeedbackIncorrect() {
        let feedback = PronunciationFeedback.incorrect(
            expectedWord: "mèo",
            spokenWord: "chó"
        )
        
        XCTAssertFalse(feedback.isCorrect)
        XCTAssertEqual(feedback.expectedWord, "mèo")
        XCTAssertEqual(feedback.spokenWord, "chó")
        XCTAssertEqual(feedback.confidence, 0.0)
        XCTAssertEqual(feedback.icon, "xmark.circle.fill")
        XCTAssertTrue(feedback.title.contains("Chưa đúng"))
    }
    
    func testPronunciationFeedbackNotHeard() {
        let feedback = PronunciationFeedback.notHeard(expectedWord: "mèo")
        
        XCTAssertFalse(feedback.isCorrect)
        XCTAssertEqual(feedback.expectedWord, "mèo")
        XCTAssertNil(feedback.spokenWord)
        XCTAssertEqual(feedback.confidence, 0.0)
        XCTAssertEqual(feedback.icon, "xmark.circle.fill")
        XCTAssertTrue(feedback.title.contains("Không nghe rõ"))
    }
    
    func testPronunciationFeedbackEquality() {
        let feedback1 = PronunciationFeedback.correct(expectedWord: "mèo", spokenWord: "mèo")
        let feedback2 = PronunciationFeedback.correct(expectedWord: "mèo", spokenWord: "mèo")
        let feedback3 = PronunciationFeedback.incorrect(expectedWord: "mèo", spokenWord: "chó")
        
        XCTAssertEqual(feedback1, feedback2)
        XCTAssertNotEqual(feedback1, feedback3)
    }
    
    // MARK: - Reading Results View Model Tests
    
    func testReadingResultsViewModelInitialization() {
        let viewModel = ReadingResultsViewModel()
        
        XCTAssertNotNil(viewModel.state)
        XCTAssertNil(viewModel.state.sessionResult)
        XCTAssertTrue(viewModel.state.showTextHighlight)
        XCTAssertFalse(viewModel.state.isAnimatingScore)
        XCTAssertFalse(viewModel.state.isProcessing)
    }
    
    func testReadingResultsViewModelLoadResults() {
        let viewModel = ReadingResultsViewModel()
        let sessionResult = createSampleSessionResult()
        
        viewModel.send(.loadResults(sessionResult))
        
        XCTAssertEqual(viewModel.state.sessionResult?.originalText, sessionResult.originalText)
        XCTAssertTrue(viewModel.state.showTextHighlight)
        XCTAssertTrue(viewModel.state.isAnimatingScore)
    }
    
    func testReadingResultsViewModelToggleTextHighlight() {
        let viewModel = ReadingResultsViewModel()
        let initialState = viewModel.state.showTextHighlight
        
        viewModel.send(.toggleTextHighlight)
        
        XCTAssertNotEqual(viewModel.state.showTextHighlight, initialState)
    }
    
    func testReadingResultsViewModelSelectWord() {
        let viewModel = ReadingResultsViewModel()
        let word = "mèo"
        let index = 1
        
        viewModel.send(.selectWord(word, index))
        
        XCTAssertEqual(viewModel.state.selectedWord, word)
        XCTAssertEqual(viewModel.state.selectedWordIndex, index)
    }
    
    // MARK: - Integration Tests
    
    func testVisualFeedbackIntegration() {
        // Test the integration between text comparison and visual feedback
        let textComparator = TextComparisonEngine()
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con chó ngồi trên ghế"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        // Verify that mistakes can be used for visual feedback
        XCTAssertFalse(result.mistakes.isEmpty)
        
        // Test that each mistake has the required properties for visual feedback
        for mistake in result.mistakes {
            XCTAssertFalse(mistake.expectedWord.isEmpty)
            XCTAssertNotNil(mistake.mistakeType)
            XCTAssertNotNil(mistake.severity)
            XCTAssertFalse(mistake.description.isEmpty)
            XCTAssertFalse(mistake.suggestion.isEmpty)
        }
    }
    
    func testMistakeTypeVisualization() {
        let mistakeTypes: [MistakeType] = [.substitution, .mispronunciation, .omission, .insertion]
        
        for mistakeType in mistakeTypes {
            // Test that each mistake type has appropriate visual representation
            XCTAssertFalse(mistakeType.localizedName.isEmpty)
            
            // Test color mapping exists for each type
            let mistake = TextMistake(
                position: 0,
                expectedWord: "test",
                actualWord: "test2",
                mistakeType: mistakeType,
                severity: .moderate
            )
            
            XCTAssertNotNil(mistake.mistakeType)
        }
    }
    
    func testSeverityVisualization() {
        let severities: [MistakeSeverity] = [.minor, .moderate, .major]
        
        for severity in severities {
            XCTAssertFalse(severity.localizedName.isEmpty)
            XCTAssertGreaterThan(severity.scoreImpact, 0)
            XCTAssertLessThanOrEqual(severity.scoreImpact, 1.0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testTextHighlightPerformanceWithLongText() {
        let longText = String(repeating: "Con mèo ngồi trên thảm xanh. ", count: 100)
        let mistakes: [TextMistake] = []
        let matchedWords = Array(repeating: ["Con", "mèo", "ngồi", "trên", "thảm", "xanh"], count: 100).flatMap { $0 }
        
        measure {
            let view = TextHighlightView(
                text: longText,
                mistakes: mistakes,
                matchedWords: matchedWords
            )
            _ = view.body // Force view evaluation
        }
    }
    
    func testMistakeFeedbackPerformanceWithManyMistakes() {
        let mistakes = (0..<50).map { index in
            TextMistake(
                position: index,
                expectedWord: "word\(index)",
                actualWord: "wrong\(index)",
                mistakeType: .substitution,
                severity: .moderate
            )
        }
        
        measure {
            let view = MistakeFeedbackView(
                mistakes: mistakes,
                onRetryWord: nil,
                onPlayCorrectPronunciation: nil
            )
            _ = view.body // Force view evaluation
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleSessionResult() -> SessionResult {
        let mistakes = [
            TextMistake(
                position: 1,
                expectedWord: "mèo",
                actualWord: "chó",
                mistakeType: .substitution,
                severity: .moderate
            )
        ]
        
        let comparisonResult = ComparisonResult(
            originalText: "Con mèo ngồi trên thảm",
            spokenText: "Con chó ngồi trên thảm",
            accuracy: 0.8,
            mistakes: mistakes,
            matchedWords: ["Con", "ngồi", "trên", "thảm"],
            feedback: "Khá tốt! Hãy cố gắng đọc chậm và rõ hơn nhé! 😊"
        )
        
        return SessionResult(
            userId: "test_user",
            exerciseId: UUID(),
            originalText: "Con mèo ngồi trên thảm",
            spokenText: "Con chó ngồi trên thảm",
            accuracy: 0.8,
            score: 80,
            timeSpent: 30.0,
            mistakes: mistakes,
            completedAt: Date(),
            difficulty: .grade2,
            inputMethod: .voice,
            comparisonResult: comparisonResult
        )
    }
}