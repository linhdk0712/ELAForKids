import Foundation
import AVFoundation
import Speech
import Combine

// MARK: - Speech Recognition Protocol
protocol SpeechRecognitionProtocol {
    func requestPermissions() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws
    func convertSpeechToText() async throws -> String
    func isAvailable() -> Bool
    func getSupportedLocales() -> [Locale]
}

// MARK: - Audio Recording Protocol
protocol AudioRecordingProtocol {
    func startRecording() async throws
    func stopRecording() async throws
    func pauseRecording() throws
    func resumeRecording() throws
    func getRecordingDuration() -> TimeInterval
    func getAudioData() -> Data?
    func playback() async throws
    func stopPlayback()
}

// MARK: - Text Comparison Protocol
protocol TextComparisonProtocol {
    func compareTexts(original: String, spoken: String) -> ComparisonResult
    func identifyMistakes(original: String, spoken: String) -> [TextMistake]
    func calculateAccuracy(original: String, spoken: String) -> Float
    func generateFeedback(comparisonResult: ComparisonResult) -> String
}

// MARK: - Speech Recognition State
struct SpeechRecognitionState {
    var isRecording: Bool = false
    var isProcessing: Bool = false
    var hasPermission: Bool = false
    var recognizedText: String = ""
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0
    var error: AppError?
    var comparisonResult: ComparisonResult?
}

// MARK: - Speech Recognition Actions
enum SpeechRecognitionAction {
    case requestPermissions
    case startRecording
    case stopRecording
    case updateRecognizedText(String)
    case updateAudioLevel(Float)
    case updateDuration(TimeInterval)
    case processComparison(original: String, spoken: String)
    case setError(AppError)
    case clearError
    case reset
}

// MARK: - Comparison Result
struct ComparisonResult {
    let originalText: String
    let spokenText: String
    let accuracy: Float
    let mistakes: [TextMistake]
    let matchedWords: [String]
    let feedback: String
    
    var isExcellent: Bool { accuracy >= 0.9 }
    var isGood: Bool { accuracy >= 0.7 }
    var needsImprovement: Bool { accuracy < 0.7 }
    
    var scoreCategory: ScoreCategory {
        switch accuracy {
        case 0.9...1.0:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.5..<0.7:
            return .fair
        default:
            return .needsImprovement
        }
    }
}

// MARK: - Text Mistake
struct TextMistake {
    let id = UUID()
    let position: Int
    let expectedWord: String
    let actualWord: String
    let mistakeType: MistakeType
    let severity: MistakeSeverity
    
    var description: String {
        switch mistakeType {
        case .mispronunciation:
            return "Phát âm sai: '\(expectedWord)' thành '\(actualWord)'"
        case .omission:
            return "Bỏ sót từ: '\(expectedWord)'"
        case .insertion:
            return "Thêm từ: '\(actualWord)'"
        case .substitution:
            return "Thay thế từ: '\(expectedWord)' thành '\(actualWord)'"
        }
    }
}

// MARK: - Mistake Type
enum MistakeType: String, CaseIterable {
    case mispronunciation = "mispronunciation"
    case omission = "omission"
    case insertion = "insertion"
    case substitution = "substitution"
    
    var displayName: String {
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
    
    var icon: String {
        switch self {
        case .mispronunciation:
            return "speaker.wave.2.circle"
        case .omission:
            return "minus.circle"
        case .insertion:
            return "plus.circle"
        case .substitution:
            return "arrow.triangle.2.circlepath.circle"
        }
    }
}

// MARK: - Mistake Severity
enum MistakeSeverity: String, CaseIterable {
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
    
    var color: String {
        switch self {
        case .minor:
            return "yellow"
        case .moderate:
            return "orange"
        case .major:
            return "red"
        }
    }
    
    var weight: Float {
        switch self {
        case .minor:
            return 0.1
        case .moderate:
            return 0.3
        case .major:
            return 0.5
        }
    }
}

// MARK: - Score Category
enum ScoreCategory: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case needsImprovement = "needsImprovement"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Tuyệt vời!"
        case .good:
            return "Tốt lắm!"
        case .fair:
            return "Khá tốt"
        case .needsImprovement:
            return "Cần cải thiện"
        }
    }
    
    var message: String {
        switch self {
        case .excellent:
            return "Bé đọc rất hay! Tiếp tục phát huy nhé!"
        case .good:
            return "Bé đọc tốt lắm! Hãy tiếp tục cố gắng!"
        case .fair:
            return "Bé đã cố gắng rồi! Hãy luyện tập thêm nhé!"
        case .needsImprovement:
            return "Bé cần luyện tập thêm. Đừng nản chí nhé!"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "hand.thumbsup.fill"
        case .fair:
            return "face.smiling"
        case .needsImprovement:
            return "heart.fill"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .needsImprovement:
            return "red"
        }
    }
}