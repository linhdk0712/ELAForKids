import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Speech Recognition Manager
@MainActor
final class SpeechRecognitionManager: SpeechRecognitionProtocol {
    
    // MARK: - Properties
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var hasPermission = false
    private var isRecording = false
    private var currentLocale: Locale = Locale(identifier: "vi-VN")
    
    // Publishers for reactive updates
    private let permissionSubject = PassthroughSubject<Bool, Never>()
    private let recordingStateSubject = PassthroughSubject<Bool, Never>()
    private let recognitionResultSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<AppError, Never>()
    
    // MARK: - Initialization
    init() {
        setupSpeechRecognizer()
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Speech Recognition Protocol Implementation
    func requestPermissions() async -> Bool {
        // Request Speech Recognition permission
        let speechAuthStatus = await requestSpeechRecognitionPermission()
        
        // Request Microphone permission
        let microphoneAuthStatus = await requestMicrophonePermission()
        
        hasPermission = speechAuthStatus && microphoneAuthStatus
        permissionSubject.send(hasPermission)
        
        return hasPermission
    }
    
    func startRecording() async throws {
        guard hasPermission else {
            throw AppError.microphonePermissionDenied
        }
        
        guard !isRecording else {
            throw AppError.speechRecognitionFailed
        }
        
        try await setupRecording()
        isRecording = true
        recordingStateSubject.send(true)
    }
    
    func stopRecording() async throws {
        guard isRecording else { return }
        
        await stopRecordingInternal()
        isRecording = false
        recordingStateSubject.send(false)
    }
    
    func convertSpeechToText() async throws -> String {
        // This method returns the final recognized text
        // The actual recognition happens in real-time during recording
        return ""
    }
    
    func isAvailable() -> Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    func getSupportedLocales() -> [Locale] {
        return [
            Locale(identifier: "vi-VN"),
            Locale(identifier: "en-US")
        ]
    }
    
    // MARK: - Setup Methods
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: currentLocale)
        speechRecognizer?.delegate = self
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Permission Requests
    private func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        continuation.resume(returning: true)
                    case .denied, .restricted, .notDetermined:
                        continuation.resume(returning: false)
                    @unknown default:
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Recording Setup
    private func setupRecording() async throws {
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw AppError.audioRecordingFailed
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw AppError.speechRecognitionFailed
        }
        
        // Configure recognition request based on performance conditions
        let performanceLevel = PerformanceOptimizer.shared.getCurrentPerformanceLevel()
        recognitionRequest.shouldReportPartialResults = performanceLevel == .normal
        recognitionRequest.requiresOnDeviceRecognition = performanceLevel == .optimized
        
        // Apply Vietnamese-specific optimizations
        if currentLocale.identifier.hasPrefix("vi") {
            VietnameseSpeechOptimizer.shared.optimizeRecognitionRequest(recognitionRequest)
        }
        
        // Get input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Prepare and start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        guard let speechRecognizer = speechRecognizer else {
            throw AppError.speechRecognitionUnavailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }
    }
    
    private func stopRecordingInternal() async {
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Finish recognition request
        recognitionRequest?.endAudio()
        
        // Cancel recognition task after a delay to get final results
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.recognitionRequest = nil
        }
    }
    
    // MARK: - Recognition Result Handling
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            handleRecognitionError(error)
            return
        }
        
        guard let result = result else { return }
        
        let recognizedText = result.bestTranscription.formattedString
        recognitionResultSubject.send(recognizedText)
        
        // If result is final, we can process it with Vietnamese optimization
        if result.isFinal {
            print("Final recognition result: \(recognizedText)")
            
            // Apply Vietnamese speech optimization if available
            if currentLocale.identifier.hasPrefix("vi") {
                NotificationCenter.default.post(
                    name: .vietnameseRecognitionCompleted,
                    object: recognizedText
                )
            }
        }
    }
    
    private func handleRecognitionError(_ error: Error) {
        print("Speech recognition error: \(error)")
        
        let appError: AppError
        if let speechError = error as? SFError {
            switch speechError.code {
            case .speechRecognitionRequestIsCancelled:
                return // Normal cancellation, don't treat as error
            default:
                appError = .speechRecognitionFailed
            }
        } else {
            appError = .speechRecognitionFailed
        }
        
        errorSubject.send(appError)
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine?.stop()
        audioEngine = nil
    }
    
    // MARK: - Locale Management
    func setLocale(_ locale: Locale) {
        currentLocale = locale
        setupSpeechRecognizer()
    }
    
    func getCurrentLocale() -> Locale {
        return currentLocale
    }
    
    // MARK: - Publishers
    var permissionPublisher: AnyPublisher<Bool, Never> {
        permissionSubject.eraseToAnyPublisher()
    }
    
    var recordingStatePublisher: AnyPublisher<Bool, Never> {
        recordingStateSubject.eraseToAnyPublisher()
    }
    
    var recognitionResultPublisher: AnyPublisher<String, Never> {
        recognitionResultSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            print("Speech recognizer availability changed: \(available)")
            if !available {
                errorSubject.send(.speechRecognitionUnavailable)
            }
        }
    }
}

// MARK: - Audio Session Management
extension SpeechRecognitionManager {
    func configureAudioSession(for recording: Bool) throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        if recording {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } else {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session was interrupted (e.g., phone call)
            if isRecording {
                Task {
                    try? await stopRecording()
                }
            }
        case .ended:
            // Audio session interruption ended
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // We could potentially resume recording here
                    // But for safety, we'll let the user manually restart
                }
            }
        @unknown default:
            break
        }
    }
}