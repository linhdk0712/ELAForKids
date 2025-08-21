import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - Reading View Model
@MainActor
final class ReadingViewModel: BaseViewModel<ReadingState, ReadingAction> {
    
    @Injected(SpeechRecognitionProtocol.self) private var speechRecognizer: SpeechRecognitionProtocol
    @Injected(AudioRecordingProtocol.self) private var audioRecorder: AudioRecordingProtocol
    @Injected(TextComparisonProtocol.self) private var textComparator: TextComparisonProtocol
    @Injected(NavigationCoordinator.self) private var navigationCoordinator: NavigationCoordinator
    @Injected(ErrorHandler.self) private var errorHandler: ErrorHandler
    
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    override init() {
        super.init(initialState: ReadingState())
        setupSubscriptions()
    }
    
    deinit {
        updateTimer?.invalidate()
        cancellables.removeAll()
    }
    
    override func send(_ action: ReadingAction) {
        switch action {
        case .loadText(let text):
            handleLoadText(text)
            
        case .requestPermissions:
            handleRequestPermissions()
            
        case .startRecording:
            handleStartRecording()
            
        case .stopRecording:
            handleStopRecording()
            
        case .startPlayback:
            handleStartPlayback()
            
        case .stopPlayback:
            handleStopPlayback()
            
        case .processRecording:
            handleProcessRecording()
            
        case .retryRecording:
            handleRetryRecording()
            
        case .updateAudioLevel(let level):
            updateState { state in
                state.audioLevel = level
            }
            
        case .updateDuration(let duration):
            updateState { state in
                state.recordingDuration = duration
            }
            
        case .setError(let error):
            updateState { state in
                state.error = error
                state.isRecording = false
                state.isProcessing = false
                state.isPlaying = false
            }
            
        case .clearError:
            updateState { state in
                state.error = nil
            }
        }
    }
    
    // MARK: - Action Handlers
    private func handleLoadText(_ text: String) {
        updateState { state in
            state.originalText = text
            state.hasPermission = false
            state.error = nil
        }
        
        // Request permissions automatically
        send(.requestPermissions)
    }
    
    private func handleRequestPermissions() {
        updateState { state in
            state.isProcessing = true
        }
        
        Task {
            let hasPermission = await speechRecognizer.requestPermissions()
            
            await MainActor.run {
                updateState { state in
                    state.hasPermission = hasPermission
                    state.isProcessing = false
                }
                
                if !hasPermission {
                    send(.setError(.microphonePermissionDenied))
                }
            }
        }
    }
    
    private func handleStartRecording() {
        guard state.hasPermission else {
            send(.setError(.microphonePermissionDenied))
            return
        }
        
        guard speechRecognizer.isAvailable() else {
            send(.setError(.speechRecognitionUnavailable))
            return
        }
        
        updateState { state in
            state.isProcessing = true
        }
        
        Task {
            do {
                // Start both speech recognition and audio recording
                try await speechRecognizer.startRecording()
                try await audioRecorder.startRecording()
                
                await MainActor.run {
                    updateState { state in
                        state.isRecording = true
                        state.isProcessing = false
                        state.recordingDuration = 0
                    }
                    
                    startUpdateTimer()
                }
            } catch {
                await MainActor.run {
                    send(.setError(.audioRecordingFailed))
                }
            }
        }
    }
    
    private func handleStopRecording() {
        guard state.isRecording else { return }
        
        updateState { state in
            state.isProcessing = true
        }
        
        stopUpdateTimer()
        
        Task {
            do {
                try await speechRecognizer.stopRecording()
                try await audioRecorder.stopRecording()
                
                await MainActor.run {
                    updateState { state in
                        state.isRecording = false
                        state.isProcessing = false
                        state.hasRecording = true
                    }
                }
            } catch {
                await MainActor.run {
                    send(.setError(.audioRecordingFailed))
                }
            }
        }
    }
    
    private func handleStartPlayback() {
        guard state.hasRecording else { return }
        
        Task {
            do {
                try await audioRecorder.playback()
                
                await MainActor.run {
                    updateState { state in
                        state.isPlaying = true
                    }
                }
            } catch {
                await MainActor.run {
                    send(.setError(.audioRecordingFailed))
                }
            }
        }
    }
    
    private func handleStopPlayback() {
        audioRecorder.stopPlayback()
        
        updateState { state in
            state.isPlaying = false
        }
    }
    
    private func handleProcessRecording() {
        guard state.hasRecording else { return }
        
        updateState { state in
            state.isProcessing = true
        }
        
        Task {
            do {
                // Get recognized text from speech recognizer
                let recognizedText = try await speechRecognizer.convertSpeechToText()
                
                // Compare with original text
                let comparisonResult = textComparator.compareTexts(
                    original: state.originalText,
                    spoken: recognizedText
                )
                
                await MainActor.run {
                    updateState { state in
                        state.recognizedText = recognizedText
                        state.comparisonResult = comparisonResult
                        state.isProcessing = false
                    }
                    
                    // Navigate to results
                    let sessionResult = SessionResult(
                        userId: "current_user", // This should come from user management
                        exerciseId: UUID(),
                        originalText: state.originalText,
                        spokenText: recognizedText,
                        accuracy: comparisonResult.accuracy,
                        score: calculateScore(from: comparisonResult),
                        timeSpent: state.recordingDuration,
                        mistakes: comparisonResult.mistakes,
                        completedAt: Date(),
                        difficulty: .grade1, // This should be determined from the text
                        inputMethod: .voice
                    )
                    
                    navigationCoordinator.navigate(to: .results(sessionResult: sessionResult))
                }
            } catch {
                await MainActor.run {
                    send(.setError(.speechRecognitionFailed))
                }
            }
        }
    }
    
    private func handleRetryRecording() {
        // Clear previous recording
        updateState { state in
            state.hasRecording = false
            state.recognizedText = ""
            state.comparisonResult = nil
            state.recordingDuration = 0
            state.audioLevel = 0
        }
        
        // Stop any ongoing playback
        audioRecorder.stopPlayback()
    }
    
    // MARK: - Timer Management
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingMetrics()
            }
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateRecordingMetrics() {
        guard state.isRecording else { return }
        
        let duration = audioRecorder.getRecordingDuration()
        send(.updateDuration(duration))
        
        // Audio level would be updated through the audio recorder's publisher
        // This is handled in setupSubscriptions()
    }
    
    // MARK: - Subscriptions
    private func setupSubscriptions() {
        // Subscribe to audio recorder updates if it supports publishers
        if let audioManager = audioRecorder as? AudioRecordingManager {
            audioManager.audioLevelPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] level in
                    self?.send(.updateAudioLevel(level))
                }
                .store(in: &cancellables)
            
            audioManager.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    self?.send(.setError(error))
                }
                .store(in: &cancellables)
        }
        
        // Subscribe to speech recognizer updates if it supports publishers
        if let speechManager = speechRecognizer as? SpeechRecognitionManager {
            speechManager.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    self?.send(.setError(error))
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Helper Methods
    private func calculateScore(from result: ComparisonResult) -> Int {
        let baseScore = Int(result.accuracy * 100)
        let mistakePenalty = result.mistakes.count * 5
        return max(0, baseScore - mistakePenalty)
    }
    
    // MARK: - Computed Properties
    var hasRecording: Bool {
        state.hasRecording
    }
    
    var canContinue: Bool {
        state.hasRecording && !state.isRecording && !state.isProcessing
    }
    
    var audioQuality: AudioQuality {
        if let audioManager = audioRecorder as? AudioRecordingManager {
            return audioManager.analyzeAudioQuality()
        }
        return .good
    }
}

// MARK: - Reading State
struct ReadingState {
    var originalText: String = ""
    var recognizedText: String = ""
    var hasPermission: Bool = false
    var isRecording: Bool = false
    var isPlaying: Bool = false
    var isProcessing: Bool = false
    var hasRecording: Bool = false
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0
    var comparisonResult: ComparisonResult?
    var error: AppError?
}

// MARK: - Reading Actions
enum ReadingAction {
    case loadText(String)
    case requestPermissions
    case startRecording
    case stopRecording
    case startPlayback
    case stopPlayback
    case processRecording
    case retryRecording
    case updateAudioLevel(Float)
    case updateDuration(TimeInterval)
    case setError(AppError)
    case clearError
}