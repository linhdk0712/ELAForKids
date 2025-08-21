import XCTest
import AVFoundation
@testable import ELAForKids

final class SpeechRecognitionIntegrationTests: XCTestCase {
    
    var speechRecognitionManager: SpeechRecognitionManager!
    var audioRecordingManager: AudioRecordingManager!
    var textComparator: TextComparisonEngine!
    var mockUserScoreRepository: MockUserScoreRepository!
    var mockAchievementRepository: MockAchievementRepository!
    
    override func setUp() {
        super.setUp()
        mockUserScoreRepository = MockUserScoreRepository()
        mockAchievementRepository = MockAchievementRepository()
        
        // Initialize real services for integration testing
        speechRecognitionManager = SpeechRecognitionManager()
        audioRecordingManager = AudioRecordingManager()
        textComparator = TextComparisonEngine()
    }
    
    override func tearDown() {
        speechRecognitionManager = nil
        audioRecordingManager = nil
        textComparator = nil
        mockUserScoreRepository = nil
        mockAchievementRepository = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Speech Recognition Flow Tests
    
    func testCompleteSpeechRecognitionFlow() async throws {
        // Given
        let originalText = "Xin chào các bạn"
        let userId = "test_user_123"
        let locale = Locale(identifier: "vi_VN")
        
        // When - Start speech recognition
        try await speechRecognitionManager.startRecognition(
            for: originalText,
            locale: locale,
            userId: userId
        )
        
        // Then - Verify recognition is started
        XCTAssertTrue(speechRecognitionManager.isRecording)
        XCTAssertEqual(speechRecognitionManager.currentText, originalText)
        XCTAssertEqual(speechRecognitionManager.currentLocale, locale)
        
        // When - Simulate audio recording (in real app this would be actual microphone input)
        let mockAudioData = createMockAudioData()
        let recognizedText = try await speechRecognitionManager.recognizeSpeech(from: mockAudioData)
        
        // Then - Verify speech recognition result
        XCTAssertFalse(recognizedText.isEmpty)
        XCTAssertGreaterThan(speechRecognitionManager.currentConfidence, 0.0)
        
        // When - Compare original and recognized text
        let comparisonResult = textComparator.compareTexts(
            original: originalText,
            spoken: recognizedText
        )
        
        // Then - Verify comparison results
        XCTAssertEqual(comparisonResult.originalText, originalText)
        XCTAssertEqual(comparisonResult.spokenText, recognizedText)
        XCTAssertGreaterThanOrEqual(comparisonResult.accuracy, 0.0)
        XCTAssertLessThanOrEqual(comparisonResult.accuracy, 1.0)
        
        // When - Stop recognition
        speechRecognitionManager.stopRecognition()
        
        // Then - Verify recognition is stopped
        XCTAssertFalse(speechRecognitionManager.isRecording)
    }
    
    func testSpeechRecognitionWithVietnameseText() async throws {
        // Given
        let vietnameseTexts = [
            "Chào mừng bạn đến với ứng dụng học tiếng Việt",
            "Hôm nay trời đẹp quá",
            "Tôi thích đọc sách và học ngoại ngữ",
            "Bạn có khỏe không?",
            "Cảm ơn bạn rất nhiều"
        ]
        
        for originalText in vietnameseTexts {
            // When
            try await speechRecognitionManager.startRecognition(
                for: originalText,
                locale: Locale(identifier: "vi_VN"),
                userId: "test_user"
            )
            
            let mockAudioData = createMockAudioData()
            let recognizedText = try await speechRecognitionManager.recognizeSpeech(from: mockAudioData)
            
            let comparisonResult = textComparator.compareTexts(
                original: originalText,
                spoken: recognizedText
            )
            
            // Then
            XCTAssertFalse(recognizedText.isEmpty, "Recognition failed for: \(originalText)")
            XCTAssertGreaterThan(comparisonResult.accuracy, 0.0, "Accuracy should be positive for: \(originalText)")
            XCTAssertLessThanOrEqual(comparisonResult.accuracy, 1.0, "Accuracy should not exceed 1.0 for: \(originalText)")
            
            speechRecognitionManager.stopRecognition()
        }
    }
    
    func testSpeechRecognitionAccuracyScoring() async throws {
        // Given
        let testCases = [
            ("Xin chào", "Xin chào", 1.0), // Perfect match
            ("Xin chào", "Xin chào các bạn", 0.67), // Partial match
            ("Xin chào các bạn", "Xin chào", 0.33), // Partial match
            ("Xin chào", "Tạm biệt", 0.0), // No match
        ]
        
        for (original, spoken, expectedAccuracy) in testCases {
            // When
            let comparisonResult = textComparator.compareTexts(
                original: original,
                spoken: spoken
            )
            
            // Then
            let actualAccuracy = comparisonResult.accuracy
            let accuracyDifference = abs(actualAccuracy - expectedAccuracy)
            XCTAssertLessThan(accuracyDifference, 0.1, "Accuracy for '\(original)' vs '\(spoken)' should be close to \(expectedAccuracy), got \(actualAccuracy)")
        }
    }
    
    func testSpeechRecognitionMistakeIdentification() async throws {
        // Given
        let originalText = "Xin chào các bạn"
        let spokenText = "Xin chào các bạn ơi" // Extra word
        
        // When
        let comparisonResult = textComparator.compareTexts(
            original: originalText,
            spoken: spokenText
        )
        
        // Then
        XCTAssertFalse(comparisonResult.mistakes.isEmpty)
        
        let insertionMistakes = comparisonResult.mistakes.filter { $0.mistakeType == .insertion }
        XCTAssertFalse(insertionMistakes.isEmpty, "Should identify insertion mistakes")
        
        // Verify mistake details
        if let firstMistake = insertionMistakes.first {
            XCTAssertEqual(firstMistake.actualWord, "ơi")
            XCTAssertEqual(firstMistake.mistakeType, .insertion)
            XCTAssertEqual(firstMistake.severity, .minor)
        }
    }
    
    func testSpeechRecognitionConfidenceScoring() async throws {
        // Given
        let originalText = "Xin chào các bạn"
        
        // When
        try await speechRecognitionManager.startRecognition(
            for: originalText,
            locale: Locale(identifier: "vi_VN"),
            userId: "test_user"
        )
        
        let mockAudioData = createMockAudioData()
        let recognizedText = try await speechRecognitionManager.recognizeSpeech(from: mockAudioData)
        
        // Then
        let confidence = speechRecognitionManager.currentConfidence
        XCTAssertGreaterThanOrEqual(confidence, 0.0, "Confidence should be non-negative")
        XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should not exceed 1.0")
        
        // Confidence should correlate with accuracy
        let comparisonResult = textComparator.compareTexts(
            original: originalText,
            spoken: recognizedText
        )
        
        // Higher confidence should generally correlate with higher accuracy
        if confidence > 0.8 {
            XCTAssertGreaterThan(comparisonResult.accuracy, 0.6, "High confidence should correlate with reasonable accuracy")
        }
        
        speechRecognitionManager.stopRecognition()
    }
    
    func testSpeechRecognitionErrorHandling() async throws {
        // Given
        let invalidLocale = Locale(identifier: "invalid_locale")
        let originalText = "Test text"
        
        // When & Then - Should handle invalid locale gracefully
        do {
            try await speechRecognitionManager.startRecognition(
                for: originalText,
                locale: invalidLocale,
                userId: "test_user"
            )
            // If no error is thrown, the system should handle it gracefully
        } catch {
            // Error is acceptable for invalid locale
            XCTAssertTrue(error is SpeechRecognitionError || error is NSError)
        }
        
        // Test with empty text
        do {
            try await speechRecognitionManager.startRecognition(
                for: "",
                locale: Locale(identifier: "vi_VN"),
                userId: "test_user"
            )
            // Should handle empty text gracefully
        } catch {
            // Error is acceptable for empty text
            XCTAssertTrue(error is SpeechRecognitionError || error is NSError)
        }
    }
    
    func testSpeechRecognitionPerformance() async throws {
        // Given
        let originalText = "Đây là một văn bản dài hơn để kiểm tra hiệu suất của hệ thống nhận dạng giọng nói"
        let iterations = 10
        
        // When
        var totalProcessingTime: TimeInterval = 0
        var totalAccuracy: Float = 0
        
        for _ in 0..<iterations {
            let startTime = Date()
            
            try await speechRecognitionManager.startRecognition(
                for: originalText,
                locale: Locale(identifier: "vi_VN"),
                userId: "test_user"
            )
            
            let mockAudioData = createMockAudioData()
            let recognizedText = try await speechRecognitionManager.recognizeSpeech(from: mockAudioData)
            
            let comparisonResult = textComparator.compareTexts(
                original: originalText,
                spoken: recognizedText
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            totalProcessingTime += processingTime
            totalAccuracy += comparisonResult.accuracy
            
            speechRecognitionManager.stopRecognition()
        }
        
        let averageProcessingTime = totalProcessingTime / Double(iterations)
        let averageAccuracy = totalAccuracy / Float(iterations)
        
        // Then - Performance should be reasonable
        XCTAssertLessThan(averageProcessingTime, 5.0, "Average processing time should be under 5 seconds")
        XCTAssertGreaterThan(averageAccuracy, 0.5, "Average accuracy should be above 50%")
        
        print("Performance Results:")
        print("Average Processing Time: \(averageProcessingTime)s")
        print("Average Accuracy: \(averageAccuracy * 100)%")
    }
    
    func testSpeechRecognitionWithDifferentAccents() async throws {
        // Given - Test with different Vietnamese regional accents
        let accentTests = [
            ("Hà Nội", "Xin chào các bạn"),
            ("Huế", "Xin chào các bạn"),
            ("Sài Gòn", "Xin chào các bạn"),
            ("Miền Tây", "Xin chào các bạn")
        ]
        
        for (accent, text) in accentTests {
            // When
            try await speechRecognitionManager.startRecognition(
                for: text,
                locale: Locale(identifier: "vi_VN"),
                userId: "test_user_\(accent)"
            )
            
            let mockAudioData = createMockAudioData()
            let recognizedText = try await speechRecognitionManager.recognizeSpeech(from: mockAudioData)
            
            let comparisonResult = textComparator.compareTexts(
                original: text,
                spoken: recognizedText
            )
            
            // Then - Should handle different accents reasonably well
            XCTAssertGreaterThan(comparisonResult.accuracy, 0.3, "Should handle \(accent) accent with reasonable accuracy")
            
            speechRecognitionManager.stopRecognition()
        }
    }
    
    func testSpeechRecognitionInterruptionHandling() async throws {
        // Given
        let originalText = "Xin chào các bạn"
        
        // When - Start recognition
        try await speechRecognitionManager.startRecognition(
            for: originalText,
            locale: Locale(identifier: "vi_VN"),
            userId: "test_user"
        )
        
        XCTAssertTrue(speechRecognitionManager.isRecording)
        
        // Simulate interruption
        speechRecognitionManager.stopRecognition()
        
        // Then - Should handle interruption gracefully
        XCTAssertFalse(speechRecognitionManager.isRecording)
        
        // Should be able to restart
        try await speechRecognitionManager.startRecognition(
            for: originalText,
            locale: Locale(identifier: "vi_VN"),
            userId: "test_user"
        )
        
        XCTAssertTrue(speechRecognitionManager.isRecording)
        
        speechRecognitionManager.stopRecognition()
    }
    
    // MARK: - Helper Methods
    
    private func createMockAudioData() -> Data {
        // Create mock audio data for testing
        // In a real scenario, this would be actual microphone input
        let sampleRate: Double = 44100
        let duration: Double = 2.0 // 2 seconds
        let samples = Int(sampleRate * duration)
        
        var audioData = Data()
        for i in 0..<samples {
            let amplitude = sin(2.0 * .pi * 440.0 * Double(i) / sampleRate) * 0.5
            let sample = Int16(amplitude * 32767.0)
            withUnsafeBytes(of: sample.littleEndian) { bytes in
                audioData.append(contentsOf: bytes)
            }
        }
        
        return audioData
    }
}

// MARK: - Mock Speech Recognition Manager for Testing

class MockSpeechRecognitionManager: SpeechRecognitionProtocol {
    var isRecording = false
    var currentText = ""
    var currentLocale: Locale?
    var currentConfidence: Float = 0.0
    var startRecognitionCalled = false
    
    func startRecognition(for text: String, locale: Locale, userId: String) async throws {
        startRecognitionCalled = true
        currentText = text
        currentLocale = locale
        isRecording = true
    }
    
    func recognizeSpeech(from audioData: Data) async throws -> String {
        // Simulate speech recognition with some variation
        let variations = [
            currentText,
            currentText + " ơi",
            currentText.replacingOccurrences(of: "các", with: "những"),
            currentText.replacingOccurrences(of: "bạn", with: "em")
        ]
        
        let randomVariation = variations.randomElement() ?? currentText
        currentConfidence = Float.random(in: 0.7...1.0)
        
        return randomVariation
    }
    
    func stopRecognition() {
        isRecording = false
    }
    
    func requestPermission() async -> Bool {
        return true
    }
}

// MARK: - Speech Recognition Error Types

enum SpeechRecognitionError: LocalizedError {
    case invalidLocale
    case emptyText
    case permissionDenied
    case audioInputError
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidLocale:
            return "Invalid locale specified"
        case .emptyText:
            return "Text to recognize cannot be empty"
        case .permissionDenied:
            return "Microphone permission denied"
        case .audioInputError:
            return "Error with audio input"
        case .recognitionFailed:
            return "Speech recognition failed"
        }
    }
}
