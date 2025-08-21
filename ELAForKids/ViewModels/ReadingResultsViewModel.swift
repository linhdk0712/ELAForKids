import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - Reading Results View Model
@MainActor
final class ReadingResultsViewModel: BaseViewModel<ReadingResultsState, ReadingResultsAction> {
    
    @Injected(SpeechRecognitionProtocol.self) private var speechRecognizer: SpeechRecognitionProtocol
    @Injected(AudioRecordingProtocol.self) private var audioRecorder: AudioRecordingProtocol
    @Injected(TextComparisonProtocol.self) private var textComparator: TextComparisonProtocol
    @Injected(NavigationCoordinator.self) private var navigationCoordinator: NavigationCoordinator
    @Injected(ErrorHandler.self) private var errorHandler: ErrorHandler
    
    private var cancellables = Set<AnyCancellable>()
    private var textToSpeech: AVSpeechSynthesizer?
    
    override init() {
        super.init(initialState: ReadingResultsState())
        setupTextToSpeech()
    }
    
    deinit {
        cancellables.removeAll()
        textToSpeech?.stopSpeaking(at: .immediate)
    }
    
    override func send(_ action: ReadingResultsAction) {
        switch action {
        case .loadResults(let sessionResult):
            handleLoadResults(sessionResult)
            
        case .toggleTextHighlight:
            handleToggleTextHighlight()
            
        case .selectWord(let word, let index):
            handleSelectWord(word, index)
            
        case .retryWord(let mistake):
            handleRetryWord(mistake)
            
        case .playCorrectPronunciation(let word):
            handlePlayCorrectPronunciation(word)
            
        case .retryReading:
            handleRetryReading()
            
        case .continueToNext:
            handleContinueToNext()
            
        case .saveResults:
            handleSaveResults()
            
        case .shareResults:
            handleShareResults()
            
        case .setError(let error):
            updateState { state in
                state.error = error
                state.isProcessing = false
            }
            
        case .clearError:
            updateState { state in
                state.error = nil
            }
        }
    }
    
    // MARK: - Action Handlers
    private func handleLoadResults(_ sessionResult: SessionResult) {
        updateState { state in
            state.sessionResult = sessionResult
            state.showTextHighlight = !sessionResult.mistakes.isEmpty
            state.isAnimatingScore = true
        }
        
        // Stop score animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateState { state in
                state.isAnimatingScore = false
            }
        }
    }
    
    private func handleToggleTextHighlight() {
        updateState { state in
            state.showTextHighlight.toggle()
        }
    }
    
    private func handleSelectWord(_ word: String, _ index: Int) {
        updateState { state in
            state.selectedWord = word
            state.selectedWordIndex = index
        }
        
        // Find mistake for this word and provide feedback
        if let mistake = state.sessionResult?.mistakes.first(where: { 
            $0.position == index || $0.expectedWord.lowercased() == word.lowercased() 
        }) {
            // Play correct pronunciation automatically when word is selected
            handlePlayCorrectPronunciation(mistake.expectedWord)
        }
    }
    
    private func handleRetryWord(_ mistake: TextMistake) {
        guard !mistake.expectedWord.isEmpty else { return }
        
        updateState { state in
            state.isProcessing = true
            state.retryingWord = mistake.expectedWord
        }
        
        Task {
            do {
                // Start recording for just this word
                try await speechRecognizer.startRecording()
                
                // Give user time to speak the word (3 seconds)
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                try await speechRecognizer.stopRecording()
                let recognizedText = try await speechRecognizer.convertSpeechToText()
                
                await MainActor.run {
                    // Compare the retry with the expected word
                    let comparisonResult = textComparator.compareTexts(
                        original: mistake.expectedWord,
                        spoken: recognizedText
                    )
                    
                    updateState { state in
                        state.isProcessing = false
                        state.retryingWord = nil
                        
                        if comparisonResult.accuracy >= 0.8 {
                            state.retryResults[mistake.expectedWord] = .success
                        } else {
                            state.retryResults[mistake.expectedWord] = .failed
                        }
                    }
                    
                    // Provide feedback
                    if comparisonResult.accuracy >= 0.8 {
                        // Success feedback
                        playSuccessSound()
                    } else {
                        // Encourage to try again
                        playCorrectPronunciation(mistake.expectedWord)
                    }
                }
            } catch {
                await MainActor.run {
                    send(.setError(.speechRecognitionFailed))
                }
            }
        }
    }
    
    private func handlePlayCorrectPronunciation(_ word: String) {
        guard let textToSpeech = textToSpeech else { return }
        
        // Stop any current speech
        textToSpeech.stopSpeaking(at: .immediate)
        
        // Create utterance for the word
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN") // Vietnamese voice
        utterance.rate = 0.4 // Slower rate for learning
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for clarity
        utterance.volume = 1.0
        
        // Speak the word
        textToSpeech.speak(utterance)
        
        updateState { state in
            state.playingPronunciation = word
        }
    }
    
    private func handleRetryReading() {
        guard let sessionResult = state.sessionResult else { return }
        
        // Navigate back to reading view with the same text
        navigationCoordinator.navigate(to: .reading(text: sessionResult.originalText))
    }
    
    private func handleContinueToNext() {
        // Navigate to next exercise or main menu
        navigationCoordinator.navigate(to: .mainMenu)
    }
    
    private func handleSaveResults() {
        guard let sessionResult = state.sessionResult else { return }
        
        updateState { state in
            state.isProcessing = true
        }
        
        Task {
            do {
                // Save results to local storage
                // This would typically involve a repository
                try await saveSessionResult(sessionResult)
                
                await MainActor.run {
                    updateState { state in
                        state.isProcessing = false
                        state.resultsSaved = true
                    }
                }
            } catch {
                await MainActor.run {
                    send(.setError(.dataStorageError))
                }
            }
        }
    }
    
    private func handleShareResults() {
        guard let sessionResult = state.sessionResult else { return }
        
        // Create shareable content
        let shareText = createShareableText(from: sessionResult)
        
        updateState { state in
            state.shareContent = shareText
        }
        
        // This would trigger the share sheet in the view
    }
    
    // MARK: - Helper Methods
    private func setupTextToSpeech() {
        textToSpeech = AVSpeechSynthesizer()
        textToSpeech?.delegate = self
    }
    
    private func playSuccessSound() {
        // Play a success sound effect
        // This would typically use AVAudioPlayer or system sounds
        AudioServicesPlaySystemSound(1016) // Success sound
    }
    
    private func saveSessionResult(_ sessionResult: SessionResult) async throws {
        // This would save to Core Data or other persistence layer
        // For now, just simulate the operation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
    }
    
    private func createShareableText(from sessionResult: SessionResult) -> String {
        let accuracy = Int(sessionResult.accuracy * 100)
        let performance = sessionResult.comparisonResult?.performanceCategory.localizedName ?? "Tốt"
        
        return """
        🎯 Kết quả học tiếng Việt
        
        📝 Văn bản: "\(sessionResult.originalText)"
        ⭐ Điểm số: \(sessionResult.score)
        🎯 Độ chính xác: \(accuracy)%
        📊 Đánh giá: \(performance)
        ⏱️ Thời gian: \(formatTime(sessionResult.timeSpent))
        
        #HọcTiếngViệt #ELAForKids
        """
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ReadingResultsViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        updateState { state in
            state.playingPronunciation = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        updateState { state in
            state.playingPronunciation = nil
        }
    }
}

// MARK: - Reading Results State
struct ReadingResultsState {
    var sessionResult: SessionResult?
    var showTextHighlight: Bool = true
    var selectedWord: String?
    var selectedWordIndex: Int?
    var isAnimatingScore: Bool = false
    var isProcessing: Bool = false
    var retryingWord: String?
    var playingPronunciation: String?
    var retryResults: [String: RetryResult] = [:]
    var resultsSaved: Bool = false
    var shareContent: String?
    var error: AppError?
}

// MARK: - Reading Results Actions
enum ReadingResultsAction {
    case loadResults(SessionResult)
    case toggleTextHighlight
    case selectWord(String, Int)
    case retryWord(TextMistake)
    case playCorrectPronunciation(String)
    case retryReading
    case continueToNext
    case saveResults
    case shareResults
    case setError(AppError)
    case clearError
}

// MARK: - Retry Result
enum RetryResult {
    case success
    case failed
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}