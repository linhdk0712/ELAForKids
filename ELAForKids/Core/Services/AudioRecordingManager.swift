import Foundation
import AVFoundation
import Combine

// MARK: - Audio Recording Manager
@MainActor
final class AudioRecordingManager: AudioRecordingProtocol {
    
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    private var isCurrentlyRecording = false
    private var isPaused = false
    private var recordingStartTime: Date?
    private var recordingURL: URL?
    
    // Publishers for reactive updates
    private let recordingStateSubject = PassthroughSubject<Bool, Never>()
    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    private let durationSubject = PassthroughSubject<TimeInterval, Never>()
    private let errorSubject = PassthroughSubject<AppError, Never>()
    
    // Timer for updating duration and audio levels
    private var updateTimer: Timer?
    
    // MARK: - Audio Recording Protocol Implementation
    func startRecording() async throws {
        guard !isCurrentlyRecording else {
            throw AppError.audioRecordingFailed
        }
        
        try await setupRecordingSession()
        try await createAudioRecorder()
        
        guard let recorder = audioRecorder else {
            throw AppError.audioRecordingFailed
        }
        
        recorder.record()
        isCurrentlyRecording = true
        isPaused = false
        recordingStartTime = Date()
        
        startUpdateTimer()
        recordingStateSubject.send(true)
    }
    
    func stopRecording() async throws {
        guard isCurrentlyRecording else { return }
        
        audioRecorder?.stop()
        isCurrentlyRecording = false
        isPaused = false
        recordingStartTime = nil
        
        stopUpdateTimer()
        recordingStateSubject.send(false)
    }
    
    func pauseRecording() throws {
        guard isCurrentlyRecording && !isPaused else {
            throw AppError.audioRecordingFailed
        }
        
        audioRecorder?.pause()
        isPaused = true
        stopUpdateTimer()
    }
    
    func resumeRecording() throws {
        guard isCurrentlyRecording && isPaused else {
            throw AppError.audioRecordingFailed
        }
        
        audioRecorder?.record()
        isPaused = false
        startUpdateTimer()
    }
    
    func getRecordingDuration() -> TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func getAudioData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
    
    func playback() async throws {
        guard let url = recordingURL else {
            throw AppError.audioRecordingFailed
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            throw AppError.audioRecordingFailed
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Setup Methods
    private func setupRecordingSession() async throws {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            // Request permission if needed
            let permission = await requestRecordingPermission()
            if !permission {
                throw AppError.microphonePermissionDenied
            }
        } catch {
            throw AppError.audioRecordingFailed
        }
    }
    
    private func requestRecordingPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            recordingSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private func createAudioRecorder() async throws {
        // Create unique recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        recordingURL = audioFilename
        
        // Audio recording settings optimized for speech and performance
        let performanceLevel = PerformanceOptimizer.shared.getCurrentPerformanceLevel()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: performanceLevel == .optimized ? 22050.0 : 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: performanceLevel == .optimized ? AVAudioQuality.medium.rawValue : AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: performanceLevel == .optimized ? 64000 : 128000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            throw AppError.audioRecordingFailed
        }
    }
    
    // MARK: - Timer Management
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateMetrics() {
        guard let recorder = audioRecorder, isCurrentlyRecording && !isPaused else { return }
        
        // Update audio level
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, averagePower / 20) // Convert dB to linear scale
        audioLevelSubject.send(normalizedLevel)
        
        // Update duration
        let duration = getRecordingDuration()
        durationSubject.send(duration)
    }
    
    // MARK: - Audio Quality Analysis
    func analyzeAudioQuality() -> AudioQuality {
        guard let recorder = audioRecorder else { return .poor }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)
        
        // Analyze audio quality based on power levels
        switch averagePower {
        case -20...0:
            return .excellent
        case -40..<(-20):
            return .good
        case -60..<(-40):
            return .fair
        default:
            return .poor
        }
    }
    
    // MARK: - File Management
    func deleteRecording() {
        guard let url = recordingURL else { return }
        
        try? FileManager.default.removeItem(at: url)
        recordingURL = nil
    }
    
    func saveRecording(to destinationURL: URL) throws {
        guard let sourceURL = recordingURL else {
            throw AppError.audioRecordingFailed
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }
    
    // MARK: - Publishers
    var recordingStatePublisher: AnyPublisher<Bool, Never> {
        recordingStateSubject.eraseToAnyPublisher()
    }
    
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }
    
    var durationPublisher: AnyPublisher<TimeInterval, Never> {
        durationSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Cleanup
    deinit {
        stopUpdateTimer()
        audioRecorder?.stop()
        audioPlayer?.stop()
        deleteRecording()
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                errorSubject.send(.audioRecordingFailed)
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            errorSubject.send(.audioRecordingFailed)
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioRecordingManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            audioPlayer = nil
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            audioPlayer = nil
            errorSubject.send(.audioRecordingFailed)
        }
    }
}

// MARK: - Audio Quality Enum
enum AudioQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Tuyệt vời"
        case .good:
            return "Tốt"
        case .fair:
            return "Khá"
        case .poor:
            return "Cần cải thiện"
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
        case .poor:
            return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "mic.fill"
        case .good:
            return "mic"
        case .fair:
            return "mic.slash"
        case .poor:
            return "mic.slash.fill"
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .excellent:
            return ["Chất lượng âm thanh tuyệt vời!"]
        case .good:
            return ["Chất lượng âm thanh tốt!", "Hãy nói gần microphone hơn."]
        case .fair:
            return ["Hãy nói to hơn.", "Kiểm tra microphone."]
        case .poor:
            return ["Nói to và rõ ràng hơn.", "Kiểm tra kết nối microphone.", "Tránh tiếng ồn xung quanh."]
        }
    }
}