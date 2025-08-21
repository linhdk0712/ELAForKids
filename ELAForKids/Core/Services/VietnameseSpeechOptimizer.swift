import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Vietnamese Speech Optimizer
@MainActor
final class VietnameseSpeechOptimizer: ObservableObject {
    
    // MARK: - Properties
    static let shared = VietnameseSpeechOptimizer()
    
    // Vietnamese language specific settings
    private let vietnameseLocales = [
        Locale(identifier: "vi-VN"),
        Locale(identifier: "vi-US") // Vietnamese in US
    ]
    
    // Pronunciation patterns for Vietnamese
    private let vietnamesePronunciationPatterns: [String: [String]] = [
        // Common mispronunciations and their corrections
        "ch": ["tr", "c"],
        "tr": ["ch", "t"],
        "gi": ["d", "z"],
        "r": ["g", "gh"],
        "x": ["s", "th"],
        "d": ["gi", "z"],
        "đ": ["d"],
        "th": ["t", "f"],
        "ph": ["f", "p"],
        "kh": ["k", "h"],
        "gh": ["g", "r"],
        "ng": ["n"],
        "nh": ["n", "ni"],
        "qu": ["kw", "k"]
    ]
    
    // Vietnamese tone markers
    private let vietnameseTones: [Character: [Character]] = [
        "a": ["à", "á", "ả", "ã", "ạ", "ă", "ằ", "ắ", "ẳ", "ẵ", "ặ", "â", "ầ", "ấ", "ẩ", "ẫ", "ậ"],
        "e": ["è", "é", "ẻ", "ẽ", "ẹ", "ê", "ề", "ế", "ể", "ễ", "ệ"],
        "i": ["ì", "í", "ỉ", "ĩ", "ị"],
        "o": ["ò", "ó", "ỏ", "õ", "ọ", "ô", "ồ", "ố", "ổ", "ỗ", "ộ", "ơ", "ờ", "ớ", "ở", "ỡ", "ợ"],
        "u": ["ù", "ú", "ủ", "ũ", "ụ", "ư", "ừ", "ứ", "ử", "ữ", "ự"],
        "y": ["ỳ", "ý", "ỷ", "ỹ", "ỵ"]
    ]
    
    // Common Vietnamese words for children
    private let commonChildrenWords = [
        "con", "mèo", "chó", "gà", "vịt", "heo", "bò", "ngựa", "cá", "chim",
        "mẹ", "bố", "anh", "chị", "em", "ông", "bà", "cô", "chú", "dì",
        "nhà", "trường", "lớp", "bàn", "ghế", "sách", "vở", "bút", "thước", "cặp",
        "ăn", "uống", "ngủ", "chơi", "học", "đọc", "viết", "vẽ", "hát", "nhảy",
        "đỏ", "xanh", "vàng", "tím", "hồng", "trắng", "đen", "nâu", "cam", "xám",
        "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín", "mười"
    ]
    
    // Recognition accuracy metrics
    @Published var recognitionAccuracy: Float = 0.0
    @Published var vietnameseSpecificAccuracy: Float = 0.0
    @Published var toneAccuracy: Float = 0.0
    
    private var recognitionHistory: [RecognitionAttempt] = []
    private let maxHistoryCount = 100
    
    // MARK: - Initialization
    private init() {
        setupVietnameseOptimizations()
    }
    
    // MARK: - Setup
    private func setupVietnameseOptimizations() {
        // Configure speech recognizer for Vietnamese
        configureSpeechRecognizer()
        
        // Load Vietnamese language models
        loadVietnameseLanguageModels()
        
        // Setup pronunciation correction
        setupPronunciationCorrection()
    }
    
    private func configureSpeechRecognizer() {
        // This would be called by SpeechRecognitionManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(optimizeSpeechRecognition),
            name: .optimizeVietnameseSpeech,
            object: nil
        )
    }
    
    @objc private func optimizeSpeechRecognition(_ notification: Notification) {
        guard let recognizer = notification.object as? SFSpeechRecognizer else { return }
        
        // Apply Vietnamese-specific optimizations
        // This would be implemented in the actual speech recognition setup
    }
    
    private func loadVietnameseLanguageModels() {
        // Load custom Vietnamese language models for better accuracy
        // This would involve loading pre-trained models or dictionaries
    }
    
    private func setupPronunciationCorrection() {
        // Setup pronunciation correction patterns
        // This helps correct common mispronunciations in Vietnamese
    }
    
    // MARK: - Speech Recognition Optimization
    func optimizeRecognitionRequest(_ request: SFSpeechAudioBufferRecognitionRequest) {
        // Set Vietnamese as primary language
        request.recognitionLanguages = ["vi-VN", "vi-US"]
        
        // Enable language correction for Vietnamese
        request.usesLanguageCorrection = true
        
        // Configure for children's speech patterns
        configureForChildrenSpeech(request)
    }
    
    private func configureForChildrenSpeech(_ request: SFSpeechAudioBufferRecognitionRequest) {
        // Children often speak slower and with different intonation
        // Configure recognition to be more tolerant of these patterns
        
        // Enable partial results for better feedback
        request.shouldReportPartialResults = true
        
        // Use on-device recognition when possible for privacy
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = true
        }
    }
    
    // MARK: - Text Processing and Correction
    func processRecognizedText(_ text: String, originalText: String) -> ProcessedRecognitionResult {
        let startTime = Date()
        
        // Clean up the recognized text
        let cleanedText = cleanupVietnameseText(text)
        
        // Apply pronunciation corrections
        let correctedText = applyPronunciationCorrections(cleanedText)
        
        // Apply tone corrections
        let toneCorrectedText = applyToneCorrections(correctedText, original: originalText)
        
        // Calculate accuracy metrics
        let accuracy = calculateAccuracy(recognized: toneCorrectedText, original: originalText)
        let vietnameseAccuracy = calculateVietnameseSpecificAccuracy(recognized: toneCorrectedText, original: originalText)
        let toneAccuracy = calculateToneAccuracy(recognized: toneCorrectedText, original: originalText)
        
        // Update metrics
        updateAccuracyMetrics(accuracy: accuracy, vietnameseAccuracy: vietnameseAccuracy, toneAccuracy: toneAccuracy)
        
        // Record attempt for learning
        recordRecognitionAttempt(
            original: originalText,
            recognized: text,
            processed: toneCorrectedText,
            accuracy: accuracy
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return ProcessedRecognitionResult(
            originalRecognized: text,
            cleanedText: cleanedText,
            correctedText: correctedText,
            finalText: toneCorrectedText,
            accuracy: accuracy,
            vietnameseAccuracy: vietnameseAccuracy,
            toneAccuracy: toneAccuracy,
            processingTime: processingTime,
            suggestions: generateImprovementSuggestions(accuracy: accuracy, toneAccuracy: toneAccuracy)
        )
    }
    
    private func cleanupVietnameseText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove extra spaces
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Fix common OCR/ASR mistakes
        cleaned = fixCommonVietnameseMistakes(cleaned)
        
        // Normalize Vietnamese characters
        cleaned = normalizeVietnameseCharacters(cleaned)
        
        return cleaned
    }
    
    private func fixCommonVietnameseMistakes(_ text: String) -> String {
        var fixed = text
        
        // Common speech recognition mistakes for Vietnamese
        let corrections: [String: String] = [
            // Consonant confusions
            "tr": "tr", "ch": "ch", // Keep these as reference
            "gi": "gi", "d": "d",
            "x": "x", "s": "s",
            "th": "th", "t": "t",
            "ph": "ph", "f": "f",
            "kh": "kh", "k": "k",
            "gh": "gh", "g": "g",
            "ng": "ng", "n": "n",
            "nh": "nh", "ni": "ni",
            "qu": "qu", "kw": "kw"
        ]
        
        // Apply word-level corrections
        let words = fixed.components(separatedBy: " ")
        let correctedWords = words.map { word in
            return correctVietnameseWord(word)
        }
        
        return correctedWords.joined(separator: " ")
    }
    
    private func correctVietnameseWord(_ word: String) -> String {
        let lowercased = word.lowercased()
        
        // Check if it's a common children's word
        if commonChildrenWords.contains(lowercased) {
            return lowercased
        }
        
        // Apply pronunciation pattern corrections
        var corrected = word
        for (pattern, alternatives) in vietnamesePronunciationPatterns {
            if corrected.contains(pattern) {
                // Try to find the best alternative based on context
                corrected = applyBestAlternative(corrected, pattern: pattern, alternatives: alternatives)
            }
        }
        
        return corrected
    }
    
    private func applyBestAlternative(_ word: String, pattern: String, alternatives: [String]) -> String {
        // This is a simplified implementation
        // In a real system, you would use context and frequency analysis
        return word // Return original for now
    }
    
    private func normalizeVietnameseCharacters(_ text: String) -> String {
        // Normalize Vietnamese diacritics
        return text.precomposedStringWithCanonicalMapping
    }
    
    private func applyPronunciationCorrections(_ text: String) -> String {
        var corrected = text
        
        // Apply pronunciation corrections based on common mistakes
        for (correct, mistakes) in vietnamesePronunciationPatterns {
            for mistake in mistakes {
                corrected = corrected.replacingOccurrences(of: mistake, with: correct)
            }
        }
        
        return corrected
    }
    
    private func applyToneCorrections(_ text: String, original: String) -> String {
        // This is a complex task that would require sophisticated NLP
        // For now, we'll do basic tone matching
        
        let textWords = text.components(separatedBy: " ")
        let originalWords = original.components(separatedBy: " ")
        
        guard textWords.count == originalWords.count else { return text }
        
        var correctedWords: [String] = []
        
        for (index, textWord) in textWords.enumerated() {
            if index < originalWords.count {
                let originalWord = originalWords[index]
                let correctedWord = correctWordTones(recognized: textWord, original: originalWord)
                correctedWords.append(correctedWord)
            } else {
                correctedWords.append(textWord)
            }
        }
        
        return correctedWords.joined(separator: " ")
    }
    
    private func correctWordTones(recognized: String, original: String) -> String {
        // Simple tone correction based on character similarity
        if recognized.count != original.count {
            return recognized
        }
        
        var corrected = ""
        
        for (index, char) in recognized.enumerated() {
            let originalIndex = original.index(original.startIndex, offsetBy: index)
            let originalChar = original[originalIndex]
            
            // If the base character matches but tone is different, use original tone
            if areBasicCharactersSame(char, originalChar) {
                corrected.append(originalChar)
            } else {
                corrected.append(char)
            }
        }
        
        return corrected
    }
    
    private func areBasicCharactersSame(_ char1: Character, _ char2: Character) -> Bool {
        // Remove tones and compare base characters
        let base1 = removeVietnameseTones(String(char1))
        let base2 = removeVietnameseTones(String(char2))
        return base1.lowercased() == base2.lowercased()
    }
    
    private func removeVietnameseTones(_ text: String) -> String {
        var result = text
        
        // Remove Vietnamese tones
        let toneMap: [String: String] = [
            "àáảãạăằắẳẵặâầấẩẫậ": "a",
            "èéẻẽẹêềếểễệ": "e",
            "ìíỉĩị": "i",
            "òóỏõọôồốổỗộơờớởỡợ": "o",
            "ùúủũụưừứửữự": "u",
            "ỳýỷỹỵ": "y",
            "đ": "d"
        ]
        
        for (accented, base) in toneMap {
            for accentedChar in accented {
                result = result.replacingOccurrences(of: String(accentedChar), with: base)
                result = result.replacingOccurrences(of: String(accentedChar).uppercased(), with: base.uppercased())
            }
        }
        
        return result
    }
    
    // MARK: - Accuracy Calculation
    private func calculateAccuracy(recognized: String, original: String) -> Float {
        let recognizedWords = recognized.components(separatedBy: " ")
        let originalWords = original.components(separatedBy: " ")
        
        let maxCount = max(recognizedWords.count, originalWords.count)
        guard maxCount > 0 else { return 1.0 }
        
        var correctCount = 0
        let minCount = min(recognizedWords.count, originalWords.count)
        
        for i in 0..<minCount {
            if recognizedWords[i].lowercased() == originalWords[i].lowercased() {
                correctCount += 1
            }
        }
        
        return Float(correctCount) / Float(maxCount)
    }
    
    private func calculateVietnameseSpecificAccuracy(recognized: String, original: String) -> Float {
        // Calculate accuracy for Vietnamese-specific features
        let recognizedWords = recognized.components(separatedBy: " ")
        let originalWords = original.components(separatedBy: " ")
        
        var vietnameseCorrect = 0
        var vietnameseTotal = 0
        
        let minCount = min(recognizedWords.count, originalWords.count)
        
        for i in 0..<minCount {
            let recognizedWord = recognizedWords[i]
            let originalWord = originalWords[i]
            
            if containsVietnameseCharacters(originalWord) {
                vietnameseTotal += 1
                if recognizedWord == originalWord {
                    vietnameseCorrect += 1
                }
            }
        }
        
        guard vietnameseTotal > 0 else { return 1.0 }
        return Float(vietnameseCorrect) / Float(vietnameseTotal)
    }
    
    private func calculateToneAccuracy(recognized: String, original: String) -> Float {
        let recognizedChars = Array(recognized)
        let originalChars = Array(original)
        
        let minCount = min(recognizedChars.count, originalChars.count)
        guard minCount > 0 else { return 1.0 }
        
        var toneCorrect = 0
        var toneTotal = 0
        
        for i in 0..<minCount {
            let originalChar = originalChars[i]
            if hasVietnameseTone(originalChar) {
                toneTotal += 1
                if i < recognizedChars.count && recognizedChars[i] == originalChar {
                    toneCorrect += 1
                }
            }
        }
        
        guard toneTotal > 0 else { return 1.0 }
        return Float(toneCorrect) / Float(toneTotal)
    }
    
    private func containsVietnameseCharacters(_ text: String) -> Bool {
        let vietnameseChars = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ"
        return text.lowercased().rangeOfCharacter(from: CharacterSet(charactersIn: vietnameseChars)) != nil
    }
    
    private func hasVietnameseTone(_ char: Character) -> Bool {
        let tonedChars = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ"
        return tonedChars.contains(char)
    }
    
    // MARK: - Metrics and Learning
    private func updateAccuracyMetrics(accuracy: Float, vietnameseAccuracy: Float, toneAccuracy: Float) {
        // Update running averages
        self.recognitionAccuracy = (self.recognitionAccuracy * 0.9) + (accuracy * 0.1)
        self.vietnameseSpecificAccuracy = (self.vietnameseSpecificAccuracy * 0.9) + (vietnameseAccuracy * 0.1)
        self.toneAccuracy = (self.toneAccuracy * 0.9) + (toneAccuracy * 0.1)
    }
    
    private func recordRecognitionAttempt(original: String, recognized: String, processed: String, accuracy: Float) {
        let attempt = RecognitionAttempt(
            timestamp: Date(),
            originalText: original,
            recognizedText: recognized,
            processedText: processed,
            accuracy: accuracy
        )
        
        recognitionHistory.append(attempt)
        
        // Keep only recent history
        if recognitionHistory.count > maxHistoryCount {
            recognitionHistory.removeFirst()
        }
    }
    
    private func generateImprovementSuggestions(accuracy: Float, toneAccuracy: Float) -> [String] {
        var suggestions: [String] = []
        
        if accuracy < 0.7 {
            suggestions.append("Hãy nói chậm và rõ ràng hơn")
            suggestions.append("Đảm bảo phát âm đúng từng từ")
        }
        
        if toneAccuracy < 0.6 {
            suggestions.append("Chú ý đến thanh điệu của từng từ")
            suggestions.append("Luyện tập phát âm các thanh trong tiếng Việt")
        }
        
        if accuracy >= 0.9 && toneAccuracy >= 0.8 {
            suggestions.append("Tuyệt vời! Phát âm rất chuẩn!")
        }
        
        return suggestions
    }
    
    // MARK: - Public Interface
    func getRecognitionStatistics() -> RecognitionStatistics {
        return RecognitionStatistics(
            overallAccuracy: recognitionAccuracy,
            vietnameseAccuracy: vietnameseSpecificAccuracy,
            toneAccuracy: toneAccuracy,
            totalAttempts: recognitionHistory.count,
            recentAttempts: Array(recognitionHistory.suffix(10))
        )
    }
    
    func resetStatistics() {
        recognitionAccuracy = 0.0
        vietnameseSpecificAccuracy = 0.0
        toneAccuracy = 0.0
        recognitionHistory.removeAll()
    }
}

// MARK: - Supporting Types
struct ProcessedRecognitionResult {
    let originalRecognized: String
    let cleanedText: String
    let correctedText: String
    let finalText: String
    let accuracy: Float
    let vietnameseAccuracy: Float
    let toneAccuracy: Float
    let processingTime: TimeInterval
    let suggestions: [String]
}

struct RecognitionAttempt {
    let timestamp: Date
    let originalText: String
    let recognizedText: String
    let processedText: String
    let accuracy: Float
}

struct RecognitionStatistics {
    let overallAccuracy: Float
    let vietnameseAccuracy: Float
    let toneAccuracy: Float
    let totalAttempts: Int
    let recentAttempts: [RecognitionAttempt]
    
    var formattedOverallAccuracy: String {
        return String(format: "%.1f%%", overallAccuracy * 100)
    }
    
    var formattedVietnameseAccuracy: String {
        return String(format: "%.1f%%", vietnameseAccuracy * 100)
    }
    
    var formattedToneAccuracy: String {
        return String(format: "%.1f%%", toneAccuracy * 100)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let optimizeVietnameseSpeech = Notification.Name("optimizeVietnameseSpeech")
}