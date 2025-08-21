import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Offline Speech Recognizer
@MainActor
final class OfflineSpeechRecognizer: SpeechRecognitionProtocol {
    
    // MARK: - Properties
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let networkMonitor: NetworkMonitor
    private let offlineManager: OfflineManager
    
    private var hasPermission = false
    private var isRecording = false
    private var currentLocale: Locale = Locale(identifier: "vi-VN")
    private var preferOnDeviceRecognition = true
    
    // Publishers for reactive updates
    private let permissionSubject = PassthroughSubject<Bool, Never>()
    private let recordingStateSubject = PassthroughSubject<Bool, Never>()
    private let recognitionResultSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<AppError, Never>()
    private let offlineModeSubject = PassthroughSubject<Bool, Never>()
    
    // MARK: - Initialization
    init(
        networkMonitor: NetworkMonitor = NetworkMonitor.shared,
        offlineManager: OfflineManager
    ) {
        self.networkMonitor = networkMonitor
        self.offlineManager = offlineManager
        
        setupSpeechRecognizer()
        setupAudioSession()
        observeNetworkChanges()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Network Observation
    private func observeNetworkChanges() {
        networkMonitor.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleNetworkStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func handleNetworkStatusChange(_ status: NetworkStatus) {
        let isOffline = !status.isConnected
        offlineModeSubject.send(isOffline)
        
        // Adjust recognition settings based on network status
        if isOffline {
            preferOnDeviceRecognition = true
            print("Switched to offline speech recognition mode")
        } else {
            // Online mode can use both on-device and server-based recognition
            preferOnDeviceRecognition = false
            print("Online speech recognition mode available")
        }
        
        // Recreate speech recognizer with new settings
        setupSpeechRecognizer()
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
            throw SpeechError.permissionDenied
        }
        
        guard !isRecording else {
            throw SpeechError.recognitionFailed
        }
        
        // Check if speech recognition is available in current mode
        guard isAvailable() else {
            if offlineManager.isOfflineMode {
                throw SpeechError.notAvailable
            } else {
                throw SpeechError.recognitionFailed
            }
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
        guard let recognizer = speechRecognizer else { return false }
        
        if offlineManager.isOfflineMode {
            // In offline mode, check if on-device recognition is available
            return recognizer.isAvailable && recognizer.supportsOnDeviceRecognition
        } else {
            // In online mode, any recognition is fine
            return recognizer.isAvailable
        }
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
        
        // Log recognition capabilities
        if let recognizer = speechRecognizer {
            print("Speech recognizer available: \(recognizer.isAvailable)")
            print("On-device recognition supported: \(recognizer.supportsOnDeviceRecognition)")
            print("Current locale: \(currentLocale.identifier)")
        }
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
            throw AudioError.deviceNotAvailable
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionFailed
        }
        
        // Configure recognition request based on network status
        recognitionRequest.shouldReportPartialResults = true
        
        if offlineManager.isOfflineMode || preferOnDeviceRecognition {
            // Force on-device recognition when offline or preferred
            recognitionRequest.requiresOnDeviceRecognition = true
            print("Using on-device speech recognition")
        } else {
            // Allow server-based recognition when online
            recognitionRequest.requiresOnDeviceRecognition = false
            print("Using server-based speech recognition")
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
            throw SpeechError.notAvailable
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
        
        // If result is final, we can process it
        if result.isFinal {
            print("Final recognition result: \(recognizedText)")
            
            // In offline mode, save the recognition result locally
            if offlineManager.isOfflineMode {
                Task {
                    await saveOfflineRecognitionResult(recognizedText)
                }
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
        
        // Provide offline-specific error handling
        if offlineManager.isOfflineMode {
            let offlineError = GenericAppError(
                code: "OFF_001",
                message: "Nhận dạng giọng nói ngoại tuyến gặp lỗi. Hãy thử lại hoặc kiểm tra kết nối mạng.",
                severity: .medium,
                category: .speech,
                underlyingError: error
            )
            errorSubject.send(offlineError)
        } else {
            errorSubject.send(appError)
        }
    }
    
    private func saveOfflineRecognitionResult(_ text: String) async {
        // Save recognition result for later sync when online
        // This could be expanded to store more detailed recognition data
        print("Saved offline recognition result: \(text)")
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
    
    // MARK: - Offline Mode Utilities
    func getOfflineCapabilities() -> [String] {
        var capabilities: [String] = []
        
        if let recognizer = speechRecognizer {
            if recognizer.supportsOnDeviceRecognition {
                capabilities.append("Nhận dạng giọng nói ngoại tuyến")
            }
            if recognizer.isAvailable {
                capabilities.append("Nhận dạng giọng nói cơ bản")
            }
        }
        
        return capabilities
    }
    
    func isOnDeviceRecognitionAvailable() -> Bool {
        return speechRecognizer?.supportsOnDeviceRecognition ?? false
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
    
    var offlineModePublisher: AnyPublisher<Bool, Never> {
        offlineModeSubject.eraseToAnyPublisher()
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension OfflineSpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            print("Speech recognizer availability changed: \(available)")
            if !available {
                let error = GenericAppError(
                    code: "SPE_006",
                    message: offlineManager.isOfflineMode ? 
                        "Nhận dạng giọng nói ngoại tuyến không khả dụng trên thiết bị này." :
                        "Nhận dạng giọng nói tạm thời không khả dụng.",
                    severity: .medium,
                    category: .speech
                )
                errorSubject.send(error)
            }
        }
    }
}

// MARK: - Audio Session Management
extension OfflineSpeechRecognizer {
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