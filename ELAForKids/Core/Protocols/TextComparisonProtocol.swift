import Foundation

// MARK: - Text Comparison Protocol
protocol TextComparisonProtocol {
    /// Compare original text with spoken text and return detailed results
    func compareTexts(original: String, spoken: String) -> ComparisonResult
    
    /// Identify specific mistakes between original and spoken text
    func identifyMistakes(original: String, spoken: String) -> [TextMistake]
    
    /// Calculate accuracy percentage between original and spoken text
    func calculateAccuracy(original: String, spoken: String) -> Float
    
    /// Generate user-friendly feedback based on comparison results
    func generateFeedback(comparisonResult: ComparisonResult) -> String
}

// MARK: - Data Models

/// Result of text comparison containing all analysis data
struct ComparisonResult {
    let originalText: String
    let spokenText: String
    let accuracy: Float
    let mistakes: [TextMistake]
    let matchedWords: [String]
    let feedback: String
    
    /// Total number of words in original text
    var totalWords: Int {
        originalText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    /// Number of correctly spoken words
    var correctWords: Int {
        totalWords - mistakes.count
    }
    
    /// Whether the reading was perfect (100% accuracy)
    var isPerfect: Bool {
        accuracy >= 1.0
    }
    
    /// Whether the reading was excellent (95%+ accuracy)
    var isExcellent: Bool {
        accuracy >= 0.95
    }
    
    /// Performance category based on accuracy
    var performanceCategory: PerformanceCategory {
        switch accuracy {
        case 0.95...1.0:
            return .excellent
        case 0.85..<0.95:
            return .good
        case 0.70..<0.85:
            return .fair
        default:
            return .needsImprovement
        }
    }
    
    /// Score category (alias for performanceCategory for backward compatibility)
    var scoreCategory: PerformanceCategory {
        return performanceCategory
    }
}

/// Individual mistake information
struct TextMistake {
    let position: Int
    let expectedWord: String
    let actualWord: String
    let mistakeType: MistakeType
    let severity: MistakeSeverity
    
    /// User-friendly description of the mistake
    var description: String {
        switch mistakeType {
        case .mispronunciation:
            return "Phát âm '\(expectedWord)' thành '\(actualWord)'"
        case .omission:
            return "Bỏ sót từ '\(expectedWord)'"
        case .insertion:
            return "Thêm từ '\(actualWord)'"
        case .substitution:
            return "Đọc '\(expectedWord)' thành '\(actualWord)'"
        }
    }
    
    /// Suggestion for improvement
    var suggestion: String {
        switch mistakeType {
        case .mispronunciation:
            return "Hãy phát âm rõ ràng từ '\(expectedWord)'"
        case .omission:
            return "Đừng quên đọc từ '\(expectedWord)'"
        case .insertion:
            return "Không cần đọc thêm từ '\(actualWord)'"
        case .substitution:
            return "Từ đúng là '\(expectedWord)', không phải '\(actualWord)'"
        }
    }
}

/// Types of mistakes that can occur during reading
enum MistakeType: String, CaseIterable {
    case mispronunciation = "mispronunciation"  // Phát âm sai
    case omission = "omission"                  // Bỏ sót từ
    case insertion = "insertion"                // Thêm từ
    case substitution = "substitution"          // Thay thế từ
    
    var localizedName: String {
        switch self {
        case .mispronunciation:
            return "Phát âm sai"
        case .omission:
            return "Bỏ sót"
        case .insertion:
            return "Thêm từ"
        case .substitution:
            return "Thay thế"
        }
    }
}

/// Severity levels for mistakes
enum MistakeSeverity: String, CaseIterable {
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
    
    var localizedName: String {
        switch self {
        case .minor:
            return "Nhẹ"
        case .moderate:
            return "Vừa"
        case .major:
            return "Nặng"
        }
    }
    
    var scoreImpact: Float {
        switch self {
        case .minor:
            return 0.05  // 5% impact
        case .moderate:
            return 0.10  // 10% impact
        case .major:
            return 0.20  // 20% impact
        }
    }
}

/// Performance categories based on accuracy
enum PerformanceCategory: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case needsImprovement = "needsImprovement"
    
    var localizedName: String {
        switch self {
        case .excellent:
            return "Xuất sắc"
        case .good:
            return "Tốt"
        case .fair:
            return "Khá"
        case .needsImprovement:
            return "Cần cải thiện"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent:
            return "🌟"
        case .good:
            return "👏"
        case .fair:
            return "😊"
        case .needsImprovement:
            return "💪"
        }
    }
    
    var encouragementMessage: String {
        switch self {
        case .excellent:
            return "Tuyệt vời! Bé đọc hoàn hảo!"
        case .good:
            return "Rất tốt! Chỉ có vài lỗi nhỏ thôi!"
        case .fair:
            return "Khá tốt! Hãy cố gắng đọc chậm và rõ hơn nhé!"
        case .needsImprovement:
            return "Hãy thử đọc lại nhé! Đọc chậm và rõ ràng sẽ giúp bé đọc tốt hơn!"
        }
    }
}