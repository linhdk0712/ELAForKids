import Foundation
import PencilKit
import Combine

// MARK: - Real Text Input Handler Implementation
final class TextInputHandler: TextInputProtocol {
    private var currentText: String = ""
    private var isActive: Bool = false
    private var inputMethod: InputMethod = .keyboard
    
    // MARK: - Text Input Protocol Implementation
    func startTextInput() {
        isActive = true
        currentText = ""
    }
    
    func processKeyboardInput(_ text: String) {
        guard isActive else { return }
        currentText = text
    }
    
    func processPencilInput(_ drawing: PKDrawing) {
        guard isActive else { return }
        // The actual recognition will be handled by HandwritingRecognizer
        // This method is called after recognition is complete
        // currentText will be set by processKeyboardInput when recognition result is accepted
    }
    
    func finishTextInput() -> String {
        isActive = false
        return currentText
    }
    
    func clearInput() {
        currentText = ""
    }
    
    func validateInput(_ text: String) -> ValidationResult {
        return validateTextContent(text)
    }
    
    // MARK: - Private Validation Methods
    private func validateTextContent(_ text: String) -> ValidationResult {
        // Check if empty
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .empty
        }
        
        // Check minimum length (word count)
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count < 3 {
            return .tooShort(minLength: 3)
        }
        
        // Check maximum length (character count)
        if text.count > 500 {
            return .tooLong(maxLength: 500)
        }
        
        // Check for invalid characters
        let invalidChars = findInvalidCharacters(in: text)
        if !invalidChars.isEmpty {
            return .invalidCharacters(invalidChars)
        }
        
        return .valid
    }
    
    private func findInvalidCharacters(in text: String) -> [Character] {
        // Define allowed character sets for Vietnamese text
        let vietnameseLetters = CharacterSet(charactersIn: "aăâbcdđeêfghijklmnoôơpqrstuưvwxyàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ")
        let basicLetters = CharacterSet.letters
        let numbers = CharacterSet.decimalDigits
        let punctuation = CharacterSet.punctuationCharacters
        let whitespace = CharacterSet.whitespacesAndNewlines
        
        let allowedCharacters = vietnameseLetters
            .union(basicLetters)
            .union(numbers)
            .union(punctuation)
            .union(whitespace)
        
        var invalidChars: [Character] = []
        
        for char in text {
            let charString = String(char)
            if charString.rangeOfCharacter(from: allowedCharacters) == nil {
                if !invalidChars.contains(char) {
                    invalidChars.append(char)
                }
            }
        }
        
        return invalidChars
    }
}

// MARK: - Text Processing Utilities
extension TextInputHandler {
    func getWordCount(_ text: String) -> Int {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    func getSentenceCount(_ text: String) -> Int {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return sentences.count
    }
    
    func getReadingTime(_ text: String) -> TimeInterval {
        let wordCount = getWordCount(text)
        // Average reading speed for children: 100-150 words per minute
        let wordsPerMinute: Double = 125
        return Double(wordCount) / wordsPerMinute * 60 // in seconds
    }
    
    func cleanupText(_ text: String) -> String {
        // Remove extra whitespaces and newlines
        let cleaned = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    func formatText(_ text: String) -> String {
        let cleaned = cleanupText(text)
        
        // Capitalize first letter of sentences
        let sentences = cleaned.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let formattedSentences = sentences.map { sentence in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return trimmed }
            return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        }
        
        return formattedSentences.joined(separator: ". ")
    }
}

// MARK: - Text Statistics
struct TextStatistics {
    let characterCount: Int
    let wordCount: Int
    let sentenceCount: Int
    let estimatedReadingTime: TimeInterval
    let difficulty: TextDifficulty
    
    var formattedReadingTime: String {
        let minutes = Int(estimatedReadingTime) / 60
        let seconds = Int(estimatedReadingTime) % 60
        
        if minutes > 0 {
            return "\(minutes) phút \(seconds) giây"
        } else {
            return "\(seconds) giây"
        }
    }
}

enum TextDifficulty: String, CaseIterable {
    case veryEasy = "very_easy"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case veryHard = "very_hard"
    
    var displayName: String {
        switch self {
        case .veryEasy:
            return "Rất dễ"
        case .easy:
            return "Dễ"
        case .medium:
            return "Trung bình"
        case .hard:
            return "Khó"
        case .veryHard:
            return "Rất khó"
        }
    }
    
    var color: String {
        switch self {
        case .veryEasy:
            return "green"
        case .easy:
            return "blue"
        case .medium:
            return "orange"
        case .hard:
            return "red"
        case .veryHard:
            return "purple"
        }
    }
}

extension TextInputHandler {
    func getTextStatistics(_ text: String) -> TextStatistics {
        let characterCount = text.count
        let wordCount = getWordCount(text)
        let sentenceCount = getSentenceCount(text)
        let readingTime = getReadingTime(text)
        let difficulty = calculateTextDifficulty(text)
        
        return TextStatistics(
            characterCount: characterCount,
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            estimatedReadingTime: readingTime,
            difficulty: difficulty
        )
    }
    
    private func calculateTextDifficulty(_ text: String) -> TextDifficulty {
        let wordCount = getWordCount(text)
        let sentenceCount = getSentenceCount(text)
        let averageWordsPerSentence = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0
        
        // Simple difficulty calculation based on text length and sentence complexity
        switch (wordCount, averageWordsPerSentence) {
        case (0..<10, _):
            return .veryEasy
        case (10..<25, 0..<8):
            return .easy
        case (10..<25, 8...):
            return .medium
        case (25..<50, 0..<10):
            return .medium
        case (25..<50, 10...):
            return .hard
        case (50..., _):
            return .veryHard
        default:
            return .easy
        }
    }
}