import Foundation
import SwiftUI
import Combine
import PencilKit

// MARK: - Text Input View Model
@MainActor
final class TextInputViewModel: BaseViewModel<TextInputState, TextInputAction> {
    
    @Injected(TextInputProtocol.self) private var textInputHandler: TextInputProtocol
    @Injected(HandwritingRecognitionProtocol.self) private var handwritingRecognizer: HandwritingRecognitionProtocol
    @Injected(NavigationCoordinator.self) private var navigationCoordinator: NavigationCoordinator
    @Injected(ErrorHandler.self) private var errorHandler: ErrorHandler
    
    private let handwritingAnalytics = HandwritingAnalytics()
    private var currentDrawing: PKDrawing?
    
    private let maxTextLength = 500
    private let minTextLength = 10
    
    override init() {
        super.init(initialState: TextInputState())
    }
    
    override func send(_ action: TextInputAction) {
        switch action {
        case .startInput(let method):
            handleStartInput(method: method)
            
        case .updateText(let text):
            handleUpdateText(text)
            
        case .validateInput:
            handleValidateInput()
            
        case .clearInput:
            handleClearInput()
            
        case .finishInput:
            handleFinishInput()
            
        case .setError(let error):
            updateState { state in
                state.error = error
                state.isProcessing = false
            }
            
        case .clearError:
            updateState { state in
                state.error = nil
            }
            
        case .processPencilDrawing(let drawing):
            handleProcessPencilDrawing(drawing)
        }
    }
    
    // MARK: - Action Handlers
    private func handleStartInput(method: InputMethod) {
        updateState { state in
            state.inputMethod = method
            state.isInputActive = true
            state.error = nil
        }
        
        textInputHandler.startTextInput()
    }
    
    private func handleUpdateText(_ text: String) {
        // Limit text length
        let limitedText = String(text.prefix(maxTextLength))
        
        updateState { state in
            state.currentText = limitedText
            state.error = nil
        }
        
        textInputHandler.processKeyboardInput(limitedText)
        
        // Auto-validate as user types
        handleValidateInput()
    }
    
    private func handleValidateInput() {
        let validation = textInputHandler.validateInput(state.currentText)
        
        updateState { state in
            state.validationResult = validation
        }
    }
    
    private func handleClearInput() {
        updateState { state in
            state.currentText = ""
            state.validationResult = .valid
            state.error = nil
        }
        
        textInputHandler.clearInput()
    }
    
    private func handleFinishInput() {
        guard state.validationResult.isValid else {
            if let errorMessage = state.validationResult.errorMessage {
                send(.setError(.textInputEmpty)) // Will be mapped properly
            }
            return
        }
        
        updateState { state in
            state.isProcessing = true
            state.isInputActive = false
        }
        
        let finalText = textInputHandler.finishTextInput()
        
        // Navigate to reading view
        navigationCoordinator.navigate(to: .reading(text: finalText))
        
        updateState { state in
            state.isProcessing = false
        }
    }
    
    // MARK: - Computed Properties
    var isTextValid: Bool {
        state.validationResult.isValid
    }
    
    var canFinish: Bool {
        !state.currentText.isEmpty && 
        state.currentText.count >= minTextLength && 
        isTextValid && 
        !state.isProcessing
    }
    
    var characterCount: Int {
        state.currentText.count
    }
    
    var remainingCharacters: Int {
        maxTextLength - characterCount
    }
    
    var validationMessage: String? {
        state.validationResult.errorMessage
    }
    
    var progressPercentage: Double {
        min(Double(characterCount) / Double(minTextLength), 1.0)
    }
    
    // MARK: - Apple Pencil Support
    private func handleProcessPencilDrawing(_ drawing: PKDrawing) {
        guard handwritingRecognizer.isRecognitionAvailable() else {
            send(.setError(.handwritingRecognitionFailed))
            return
        }
        
        currentDrawing = drawing
        
        updateState { state in
            state.isProcessing = true
            state.error = nil
        }
        
        Task {
            do {
                let result = try await handwritingRecognizer.recognizeText(from: drawing)
                
                await MainActor.run {
                    updateState { state in
                        state.recognitionResult = result
                        state.isProcessing = false
                    }
                    
                    // Auto-accept if confidence is very high
                    if result.confidence >= 0.9 && !result.recognizedText.isEmpty {
                        handleUpdateText(result.recognizedText)
                        clearRecognitionResult()
                    }
                }
            } catch {
                await MainActor.run {
                    send(.setError(.handwritingRecognitionFailed))
                }
            }
        }
    }
    
    func acceptRecognitionResult() {
        guard let result = state.recognitionResult else { return }
        handleUpdateText(result.recognizedText)
        clearRecognitionResult()
    }
    
    func rejectRecognitionResult() {
        clearRecognitionResult()
    }
    
    func selectAlternativeText(_ text: String) {
        handleUpdateText(text)
        clearRecognitionResult()
    }
    
    private func clearRecognitionResult() {
        updateState { state in
            state.recognitionResult = nil
        }
    }
    
    // MARK: - Pencil Drawing State
    var hasRecognitionResult: Bool {
        state.recognitionResult != nil
    }
    
    var recognitionResult: RecognitionResult? {
        state.recognitionResult
    }
    
    var isPencilMode: Bool {
        state.inputMethod == .pencil
    }
    
    // MARK: - Analytics Support
    func getQualityAssessment() -> RecognitionQualityAssessment? {
        guard let result = state.recognitionResult,
              let drawing = currentDrawing else { return nil }
        
        return handwritingAnalytics.assessRecognitionQuality(result, drawing: drawing)
    }
    
    func getWritingPatternAnalysis() -> WritingPatternAnalysis? {
        guard let drawing = currentDrawing else { return nil }
        return handwritingAnalytics.analyzeWritingPattern(drawing)
    }

// MARK: - Text Input Validation
extension TextInputViewModel {
    private func validateTextInput(_ text: String) -> ValidationResult {
        if text.isEmpty {
            return .empty
        }
        
        if text.count < minTextLength {
            return .tooShort(minLength: minTextLength)
        }
        
        if text.count > maxTextLength {
            return .tooLong(maxLength: maxTextLength)
        }
        
        // Check for invalid characters (basic validation)
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(.punctuationCharacters)
            .union(.decimalDigits)
        
        let textCharacterSet = CharacterSet(charactersIn: text)
        if !allowedCharacterSet.isSuperset(of: textCharacterSet) {
            let invalidChars = text.compactMap { char in
                String(char).rangeOfCharacter(from: allowedCharacterSet) == nil ? char : nil
            }
            return .invalidCharacters(Array(Set(invalidChars)))
        }
        
        return .valid
    }
}

// MARK: - Helper Methods
extension TextInputViewModel {
    func getSampleTexts() -> [String] {
        return [
            "Con mèo nhỏ ngồi trên thảm xanh.",
            "Hôm nay trời đẹp, em đi học vui vẻ.",
            "Mẹ nấu cơm ngon, cả nhà ăn no.",
            "Cây xanh trong vườn, chim hót líu lo.",
            "Bé học bài chăm chỉ, cô giáo khen ngoan."
        ]
    }
    
    func insertSampleText(_ text: String) {
        send(.updateText(text))
    }
    
    func getInputMethodIcon() -> String {
        switch state.inputMethod {
        case .keyboard:
            return "keyboard"
        case .pencil:
            return "pencil.tip"
        case .voice:
            return "mic"
        }
    }
    
    func getInputMethodTitle() -> String {
        switch state.inputMethod {
        case .keyboard:
            return "Bàn phím"
        case .pencil:
            return "Apple Pencil"
        case .voice:
            return "Giọng nói"
        }
    }
}