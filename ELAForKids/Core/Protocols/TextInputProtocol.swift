import Foundation
import PencilKit
import Combine

// MARK: - Text Input Protocol
protocol TextInputProtocol {
    func startTextInput()
    func processKeyboardInput(_ text: String)
    func processPencilInput(_ drawing: PKDrawing)
    func finishTextInput() -> String
    func clearInput()
    func validateInput(_ text: String) -> ValidationResult
}

// MARK: - Handwriting Recognition Protocol
protocol HandwritingRecognitionProtocol {
    func recognizeText(from drawing: PKDrawing) async throws -> RecognitionResult
    func getConfidenceScore() -> Float
    func isRecognitionAvailable() -> Bool
}

// MARK: - Text Input State
struct TextInputState {
    var currentText: String = ""
    var isInputActive: Bool = false
    var inputMethod: InputMethod = .keyboard
    var validationResult: ValidationResult = .valid
    var recognitionResult: RecognitionResult?
    var isProcessing: Bool = false
    var error: AppError?
}

// MARK: - Text Input Actions
enum TextInputAction {
    case startInput(method: InputMethod)
    case updateText(String)
    case processPencilDrawing(PKDrawing)
    case validateInput
    case clearInput
    case finishInput
    case setError(AppError)
    case clearError
}

// MARK: - Input Method
enum InputMethod {
    case keyboard
    case pencil
    case voice // For future use
    
    var displayName: String {
        switch self {
        case .keyboard:
            return "Bàn phím"
        case .pencil:
            return "Apple Pencil"
        case .voice:
            return "Giọng nói"
        }
    }
    
    var icon: String {
        switch self {
        case .keyboard:
            return "keyboard"
        case .pencil:
            return "pencil.tip"
        case .voice:
            return "mic"
        }
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case empty
    case tooShort(minLength: Int)
    case tooLong(maxLength: Int)
    case invalidCharacters([Character])
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .empty:
            return "Hãy viết một đoạn văn bản trước nhé!"
        case .tooShort(let minLength):
            return "Văn bản quá ngắn. Cần ít nhất \(minLength) ký tự."
        case .tooLong(let maxLength):
            return "Văn bản quá dài. Tối đa \(maxLength) ký tự."
        case .invalidCharacters(let chars):
            return "Có ký tự không hợp lệ: \(chars.map(String.init).joined(separator: ", "))"
        }
    }
}

// MARK: - Recognition Result
struct RecognitionResult {
    let recognizedText: String
    let confidence: Float
    let alternativeTexts: [String]
    let processingTime: TimeInterval
    
    var isHighConfidence: Bool {
        confidence >= 0.8
    }
    
    var isLowConfidence: Bool {
        confidence < 0.5
    }
}