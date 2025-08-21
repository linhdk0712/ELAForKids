import XCTest
@testable import ELAForKids

final class TextComparisonEngineTests: XCTestCase {
    
    var textComparator: TextComparisonEngine!
    
    override func setUp() {
        super.setUp()
        textComparator = TextComparisonEngine()
    }
    
    override func tearDown() {
        textComparator = nil
        super.tearDown()
    }
    
    // MARK: - Perfect Match Tests
    
    func testExactMatch() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con mèo ngồi trên thảm"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertEqual(result.accuracy, 1.0, "Perfect match should have 100% accuracy")
        XCTAssertTrue(result.mistakes.isEmpty, "Perfect match should have no mistakes")
        XCTAssertTrue(result.isPerfect, "Should be marked as perfect")
        XCTAssertEqual(result.performanceCategory, .excellent, "Should be excellent performance")
        XCTAssertEqual(result.totalWords, 5, "Should count 5 words")
        XCTAssertEqual(result.correctWords, 5, "All words should be correct")
    }
    
    func testCaseInsensitiveMatch() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "CON MÈO NGỒI TRÊN THẢM"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertEqual(result.accuracy, 1.0, "Case insensitive match should have 100% accuracy")
        XCTAssertTrue(result.mistakes.isEmpty, "Case insensitive match should have no mistakes")
    }
    
    func testPunctuationIgnored() {
        let original = "Con mèo ngồi trên thảm."
        let spoken = "Con mèo ngồi trên thảm"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertEqual(result.accuracy, 1.0, "Punctuation should be ignored")
        XCTAssertTrue(result.mistakes.isEmpty, "Punctuation differences should not create mistakes")
    }
    
    // MARK: - Substitution Tests
    
    func testSingleWordSubstitution() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con mèo ngồi trên ghế"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertLessThan(result.accuracy, 1.0, "Substitution should reduce accuracy")
        XCTAssertEqual(result.mistakes.count, 1, "Should have one mistake")
        
        let mistake = result.mistakes.first!
        XCTAssertEqual(mistake.expectedWord, "thảm", "Expected word should be 'thảm'")
        XCTAssertEqual(mistake.actualWord, "ghế", "Actual word should be 'ghế'")
        XCTAssertEqual(mistake.mistakeType, .substitution, "Should be substitution mistake")
    }
    
    func testMultipleSubstitutions() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con chó đứng trên ghế"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertLessThan(result.accuracy, 0.5, "Multiple substitutions should significantly reduce accuracy")
        XCTAssertEqual(result.mistakes.count, 3, "Should have three mistakes")
        
        let expectedMistakes = [
            ("mèo", "chó"),
            ("ngồi", "đứng"),
            ("thảm", "ghế")
        ]
        
        for (index, (expected, actual)) in expectedMistakes.enumerated() {
            XCTAssertEqual(result.mistakes[index].expectedWord, expected)
            XCTAssertEqual(result.mistakes[index].actualWord, actual)
            XCTAssertEqual(result.mistakes[index].mistakeType, .substitution)
        }
    }
    
    // MARK: - Omission Tests
    
    func testWordOmission() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con mèo trên thảm"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertLessThan(result.accuracy, 1.0, "Omission should reduce accuracy")
        XCTAssertEqual(result.mistakes.count, 1, "Should have one mistake")
        
        let mistake = result.mistakes.first!
        XCTAssertEqual(mistake.expectedWord, "ngồi", "Expected word should be 'ngồi'")
        XCTAssertEqual(mistake.actualWord, "", "Actual word should be empty for omission")
        XCTAssertEqual(mistake.mistakeType, .omission, "Should be omission mistake")
        XCTAssertEqual(mistake.severity, .moderate, "Omission should be moderate severity")
    }
    
    func testMultipleOmissions() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con mèo thảm"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertLessThan(result.accuracy, 0.7, "Multiple omissions should significantly reduce accuracy")
        XCTAssertEqual(result.mistakes.count, 2, "Should have two mistakes")
        
        let omittedWords = result.mistakes.compactMap { mistake in
            mistake.mistakeType == .omission ? mistake.expectedWord : nil
        }
        XCTAssertTrue(omittedWords.contains("ngồi"), "Should identify 'ngồi' as omitted")
        XCTAssertTrue(omittedWords.contains("trên"), "Should identify 'trên' as omitted")
    }
    
    // MARK: - Insertion Tests
    
    func testWordInsertion() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con mèo nhỏ ngồi trên thảm"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertLessThan(result.accuracy, 1.0, "Insertion should reduce accuracy")
        XCTAssertEqual(result.mistakes.count, 1, "Should have one mistake")
        
        let mistake = result.mistakes.first!
        XCTAssertEqual(mistake.expectedWord, "", "Expected word should be empty for insertion")
        XCTAssertEqual(mistake.actualWord, "nhỏ", "Actual word should be 'nhỏ'")
        XCTAssertEqual(mistake.mistakeType, .insertion, "Should be insertion mistake")
        XCTAssertEqual(mistake.severity, .minor, "Insertion should be minor severity")
    }
    
    // MARK: - Mispronunciation Tests
    
    func testPhoneticSimilarity() {
        let original = "Con mèo ngồi trên thảm"
        let spoken = "Con mèo ngồi trên tảm" // 'th' vs 't' - common Vietnamese pronunciation issue
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        // Should be treated as mispronunciation, not substitution
        if !result.mistakes.isEmpty {
            let mistake = result.mistakes.first { $0.expectedWord == "thảm" }
            XCTAssertNotNil(mistake, "Should identify mispronunciation of 'thảm'")
            if let mistake = mistake {
                XCTAssertEqual(mistake.mistakeType, .mispronunciation, "Should be mispronunciation mistake")
            }
        }
    }
    
    func testVietnamesePhoneticPairs() {
        let phoneticPairs = [
            ("d", "gi"),
            ("tr", "ch"),
            ("s", "x"),
            ("c", "k")
        ]
        
        for (sound1, sound2) in phoneticPairs {
            let original = "Con \(sound1)ây là gì"
            let spoken = "Con \(sound2)ây là gì"
            
            let result = textComparator.compareTexts(original: original, spoken: spoken)
            
            // Should recognize phonetic similarity
            XCTAssertGreaterThan(result.accuracy, 0.8, "Phonetic similarity should maintain high accuracy for \(sound1)/\(sound2)")
        }
    }
    
    // MARK: - Accuracy Calculation Tests
    
    func testAccuracyCalculation() {
        let testCases: [(String, String, Float)] = [
            ("Con mèo", "Con mèo", 1.0),                    // Perfect match
            ("Con mèo", "Con chó", 0.5),                    // 50% accuracy
            ("Con mèo ngồi", "Con chó ngồi", 0.67),         // 2/3 accuracy
            ("Con mèo ngồi trên", "Con chó", 0.25),         // 1/4 accuracy
            ("", "", 1.0),                                   // Empty strings
            ("Con", "", 0.0)                                // Complete omission
        ]
        
        for (original, spoken, expectedAccuracy) in testCases {
            let accuracy = textComparator.calculateAccuracy(original: original, spoken: spoken)
            XCTAssertEqual(accuracy, expectedAccuracy, accuracy: 0.01, 
                          "Accuracy for '\(original)' vs '\(spoken)' should be \(expectedAccuracy)")
        }
    }
    
    // MARK: - Performance Category Tests
    
    func testPerformanceCategories() {
        let testCases: [(Float, PerformanceCategory)] = [
            (1.0, .excellent),
            (0.95, .excellent),
            (0.90, .good),
            (0.85, .good),
            (0.80, .fair),
            (0.70, .fair),
            (0.60, .needsImprovement),
            (0.30, .needsImprovement)
        ]
        
        for (accuracy, expectedCategory) in testCases {
            let result = ComparisonResult(
                originalText: "Test",
                spokenText: "Test",
                accuracy: accuracy,
                mistakes: [],
                matchedWords: [],
                feedback: ""
            )
            
            XCTAssertEqual(result.performanceCategory, expectedCategory,
                          "Accuracy \(accuracy) should be \(expectedCategory)")
        }
    }
    
    // MARK: - Feedback Generation Tests
    
    func testFeedbackGeneration() {
        let testCases: [(Float, String)] = [
            (1.0, "Tuyệt vời! Bé đọc hoàn hảo!"),
            (0.90, "Rất tốt! Chỉ có vài lỗi nhỏ thôi!"),
            (0.75, "Khá tốt! Hãy cố gắng đọc chậm và rõ hơn nhé!"),
            (0.50, "Hãy thử đọc lại nhé! Đọc chậm và rõ ràng sẽ giúp bé đọc tốt hơn!")
        ]
        
        for (accuracy, expectedMessage) in testCases {
            let result = ComparisonResult(
                originalText: "Test",
                spokenText: "Test",
                accuracy: accuracy,
                mistakes: [],
                matchedWords: [],
                feedback: ""
            )
            
            let feedback = textComparator.generateFeedback(comparisonResult: result)
            XCTAssertTrue(feedback.contains(expectedMessage.components(separatedBy: "!").first ?? ""),
                         "Feedback should contain appropriate message for accuracy \(accuracy)")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyStrings() {
        let result = textComparator.compareTexts(original: "", spoken: "")
        
        XCTAssertEqual(result.accuracy, 1.0, "Empty strings should have perfect accuracy")
        XCTAssertTrue(result.mistakes.isEmpty, "Empty strings should have no mistakes")
        XCTAssertEqual(result.totalWords, 0, "Empty strings should have 0 words")
    }
    
    func testWhitespaceHandling() {
        let original = "  Con   mèo   ngồi  "
        let spoken = "Con mèo ngồi"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertEqual(result.accuracy, 1.0, "Extra whitespace should be normalized")
        XCTAssertTrue(result.mistakes.isEmpty, "Whitespace differences should not create mistakes")
    }
    
    func testSpecialCharacters() {
        let original = "Con mèo ngồi trên thảm!"
        let spoken = "Con mèo ngồi trên thảm?"
        
        let result = textComparator.compareTexts(original: original, spoken: spoken)
        
        XCTAssertEqual(result.accuracy, 1.0, "Punctuation differences should be ignored")
        XCTAssertTrue(result.mistakes.isEmpty, "Punctuation should not affect comparison")
    }
    
    // MARK: - Mistake Description Tests
    
    func testMistakeDescriptions() {
        let mistakes = [
            TextMistake(position: 0, expectedWord: "mèo", actualWord: "chó", mistakeType: .substitution, severity: .moderate),
            TextMistake(position: 1, expectedWord: "ngồi", actualWord: "", mistakeType: .omission, severity: .moderate),
            TextMistake(position: 2, expectedWord: "", actualWord: "nhỏ", mistakeType: .insertion, severity: .minor),
            TextMistake(position: 3, expectedWord: "thảm", actualWord: "tảm", mistakeType: .mispronunciation, severity: .minor)
        ]
        
        let expectedDescriptions = [
            "Đọc 'mèo' thành 'chó'",
            "Bỏ sót từ 'ngồi'",
            "Thêm từ 'nhỏ'",
            "Phát âm 'thảm' thành 'tảm'"
        ]
        
        for (mistake, expectedDescription) in zip(mistakes, expectedDescriptions) {
            XCTAssertEqual(mistake.description, expectedDescription,
                          "Mistake description should be correct")
        }
    }
    
    func testMistakeSuggestions() {
        let mistakes = [
            TextMistake(position: 0, expectedWord: "mèo", actualWord: "chó", mistakeType: .substitution, severity: .moderate),
            TextMistake(position: 1, expectedWord: "ngồi", actualWord: "", mistakeType: .omission, severity: .moderate),
            TextMistake(position: 2, expectedWord: "", actualWord: "nhỏ", mistakeType: .insertion, severity: .minor),
            TextMistake(position: 3, expectedWord: "thảm", actualWord: "tảm", mistakeType: .mispronunciation, severity: .minor)
        ]
        
        let expectedSuggestions = [
            "Từ đúng là 'mèo', không phải 'chó'",
            "Đừng quên đọc từ 'ngồi'",
            "Không cần đọc thêm từ 'nhỏ'",
            "Hãy phát âm rõ ràng từ 'thảm'"
        ]
        
        for (mistake, expectedSuggestion) in zip(mistakes, expectedSuggestions) {
            XCTAssertEqual(mistake.suggestion, expectedSuggestion,
                          "Mistake suggestion should be correct")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLongText() {
        let longOriginal = String(repeating: "Con mèo ngồi trên thảm. ", count: 100)
        let longSpoken = String(repeating: "Con mèo ngồi trên ghế. ", count: 100)
        
        measure {
            _ = textComparator.compareTexts(original: longOriginal, spoken: longSpoken)
        }
    }
    
    func testPerformanceWithManyMistakes() {
        let original = "Con mèo ngồi trên thảm xanh trong phòng khách"
        let spoken = "Con chó đứng dưới ghế đỏ ngoài sân vườn"
        
        measure {
            _ = textComparator.compareTexts(original: original, spoken: spoken)
        }
    }
}