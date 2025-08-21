import SwiftUI
import Speech
import AVFoundation
import Combine

// MARK: - Reading Practice View Model
@MainActor
final class ReadingPracticeViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentExercise: Exercise?
    @Published var currentExerciseIndex: Int = 0
    @Published var totalExercises: Int = 5
    @Published var sessionProgress: Float = 0.0
    @Published var currentScore: Int = 0
    @Published var remainingTime: TimeInterval = 600 // 10 minutes
    @Published var sessionCompleted: Bool = false
    @Published var sessionResult: SessionResult?
    
    // Input method properties
    @Published var selectedInputMethod: InputMethod = .voice
    @Published var typedText: String = ""
    @Published var handwrittenText: String = ""
    @Published var recognizedText: String = ""
    
    // Recording properties
    @Published var isRecording: Bool = false
    @Published var isPlayingAudio: Bool = false
    @Published var audioLevel: Float = 0.0
    
    // Feedback properties
    @Published var showingFeedback: Bool = false
    @Published var currentAccuracy: Float = 0.0
    @Published var currentMistakes: [TextMistake] = []
    @Published var lastEarnedScore: Int = 0
    @Published var encouragementMessage: String = ""
    @Published var highlightMode: HighlightMode = .none
    
    // MARK: - Computed Properties
    
    var remainingTimeFormatted: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var accuracyColor: Color {
        switch currentAccuracy {
        case 0.95...1.0:
            return .green
        case 0.85..<0.95:
            return .blue
        case 0.70..<0.85:
            return .orange
        default:
            return .red
        }
    }
    
    var canSubmit: Bool {
        switch selectedInputMethod {
        case .keyboard:
            return !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .handwriting:
            return !handwrittenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .voice:
            return !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // MARK: - Private Properties
    
    private var sessionConfig: PracticeSessionConfig?
    private var exercises: [Exercise] = []
    private var sessionStartTime: Date = Date()
    private var exerciseStartTime: Date = Date()
    private var sessionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Speech recognition
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    // Audio playback
    private var audioPlayer: AVAudioPlayer?
    
    // Text comparison
    private let textComparator = TextComparisonService()
    
    // Offline support
    private var offlineManager: OfflineManager?
    private var networkMonitor: NetworkMonitor?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupSpeechRecognition()
        setupAudioSession()
    }
    
    convenience init(offlineManager: OfflineManager, networkMonitor: NetworkMonitor) {
        self.init()
        self.offlineManager = offlineManager
        self.networkMonitor = networkMonitor
        setupOfflineSupport()
    }
    
    // MARK: - Offline Support Setup
    
    private func setupOfflineSupport() {
        guard let offlineManager = offlineManager,
              let networkMonitor = networkMonitor else { return }
        
        // Observe network status changes
        networkMonitor.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleNetworkStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Observe offline mode changes
        offlineManager.$isOfflineMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOffline in
                self?.handleOfflineModeChange(isOffline)
            }
            .store(in: &cancellables)
    }
    
    private func handleNetworkStatusChange(_ status: NetworkStatus) {
        switch status {
        case .connected:
            print("Network connected - online features available")
        case .disconnected:
            print("Network disconnected - switching to offline mode")
        case .unknown:
            break
        }
    }
    
    private func handleOfflineModeChange(_ isOffline: Bool) {
        if isOffline {
            // Switch to offline-capable speech recognition if needed
            setupOfflineSpeechRecognition()
        } else {
            // Can use full speech recognition features
            setupSpeechRecognition()
        }
    }
    
    private func setupOfflineSpeechRecognition() {
        // Configure speech recognition for offline use
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
        
        // Check if on-device recognition is available
        if let recognizer = speechRecognizer, recognizer.supportsOnDeviceRecognition {
            print("On-device speech recognition available for offline mode")
        } else {
            print("On-device speech recognition not available - limited offline functionality")
        }
    }
    
    deinit {
        endSession()
    }
    
    // MARK: - Public Methods
    
    func startSession(config: PracticeSessionConfig) {
        sessionConfig = config
        sessionStartTime = Date()
        remainingTime = config.mode.duration
        
        loadExercises(for: config)
        startSessionTimer()
        
        if !exercises.isEmpty {
            loadCurrentExercise()
        }
    }
    
    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopRecording()
        audioPlayer?.stop()
    }
    
    func beginReading() {
        exerciseStartTime = Date()
        highlightMode = .none
    }
    
    func selectInputMethod(_ method: InputMethod) {
        selectedInputMethod = method
        clearCurrentInput()
        showingFeedback = false
    }
    
    func submitAnswer() {
        let userInput = getCurrentUserInput()
        guard !userInput.isEmpty else { return }
        
        processUserInput(userInput)
        showingFeedback = true
    }
    
    func nextExercise() {
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            loadCurrentExercise()
            clearCurrentInput()
            showingFeedback = false
            exerciseStartTime = Date()
        } else {
            completeSession()
        }
    }
    
    func skipCurrentExercise() {
        // Record as skipped with 0 accuracy
        if let exercise = currentExercise {
            let timeSpent = Date().timeIntervalSince(exerciseStartTime)
            recordExerciseResult(
                exercise: exercise,
                userInput: "",
                accuracy: 0.0,
                score: 0,
                timeSpent: timeSpent,
                mistakes: [],
                attempts: 1
            )
        }
        
        nextExercise()
    }
    
    // MARK: - Input Processing Methods
    
    func processTypedText() {
        // Real-time feedback could be implemented here
        // For now, we'll process on submit
    }
    
    func processHandwrittenText(_ text: String) {
        handwrittenText = text
    }
    
    func clearHandwriting() {
        handwrittenText = ""
    }
    
    // MARK: - Audio Methods
    
    func playExerciseAudio() {
        guard let exercise = currentExercise else { return }
        
        // This would play the audio for the exercise text
        // For now, we'll use text-to-speech
        playTextToSpeech(text: exercise.targetText)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        requestSpeechRecognitionPermission { [weak self] granted in
            if granted {
                Task { @MainActor in
                    self?.beginSpeechRecognition()
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    // MARK: - Private Methods
    
    private func loadExercises(for config: PracticeSessionConfig) {
        // Check if we're in offline mode and load accordingly
        if let offlineManager = offlineManager, offlineManager.isOfflineMode {
            loadOfflineExercises(for: config)
        } else {
            loadOnlineExercises(for: config)
        }
        totalExercises = exercises.count
    }
    
    private func loadOfflineExercises(for config: PracticeSessionConfig) {
        guard let offlineManager = offlineManager else {
            exercises = createSampleExercises(for: config)
            return
        }
        
        // Get cached exercises from offline manager
        let cachedExercises = offlineManager.getOfflineExercises()
        
        // Filter by difficulty if specified
        let filteredExercises = cachedExercises.filter { exercise in
            exercise.difficulty == config.difficulty
        }
        
        if filteredExercises.isEmpty {
            // Fallback to sample exercises if no cached exercises available
            exercises = createSampleExercises(for: config)
        } else {
            // Use cached exercises, limiting to session size
            exercises = Array(filteredExercises.prefix(config.sessionSize ?? 5))
        }
        
        print("Loaded \(exercises.count) offline exercises for difficulty: \(config.difficulty)")
    }
    
    private func loadOnlineExercises(for config: PracticeSessionConfig) {
        // This would load exercises from the database/server based on config
        // For now, we'll create sample exercises
        exercises = createSampleExercises(for: config)
    }
    
    private func createSampleExercises(for config: PracticeSessionConfig) -> [Exercise] {
        let sampleTexts: [(String, String)] = [
            ("Con mèo nhỏ", "Con mèo nhỏ màu nâu chạy quanh sân. Nó vẫy đuôi và sủa vang."),
            ("Gia đình tôi", "Gia đình tôi có bốn người. Bố, mẹ, em và tôi. Chúng tôi yêu thương nhau."),
            ("Mùa xuân", "Mùa xuân đến rồi, hoa nở khắp nơi. Chim hót líu lo, lá xanh tươi mới."),
            ("Trường học", "Trường học của em rất đẹp. Có nhiều cây xanh và sân chơi rộng."),
            ("Bạn bè", "Em có nhiều bạn bè thân thiết. Chúng em cùng chơi và học bài.")
        ]
        
        return sampleTexts.enumerated().map { index, (title, text) in
            Exercise(
                context: PersistenceController.shared.container.viewContext,
                title: title,
                targetText: text,
                difficulty: config.difficulty,
                category: config.category ?? .story
            )
        }
    }
    
    private func loadCurrentExercise() {
        guard currentExerciseIndex < exercises.count else { return }
        
        currentExercise = exercises[currentExerciseIndex]
        sessionProgress = Float(currentExerciseIndex) / Float(totalExercises)
        highlightMode = .none
    }
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private func updateTimer() {
        remainingTime -= 1
        
        if remainingTime <= 0 {
            completeSession()
        }
    }
    
    private func getCurrentUserInput() -> String {
        switch selectedInputMethod {
        case .keyboard:
            return typedText
        case .handwriting:
            return handwrittenText
        case .voice:
            return recognizedText
        }
    }
    
    private func clearCurrentInput() {
        typedText = ""
        handwrittenText = ""
        recognizedText = ""
        currentMistakes = []
        highlightMode = .none
    }
    
    private func processUserInput(_ userInput: String) {
        guard let exercise = currentExercise else { return }
        
        let timeSpent = Date().timeIntervalSince(exerciseStartTime)
        let comparisonResult = textComparator.compareTexts(
            original: exercise.targetText,
            spoken: userInput
        )
        
        currentAccuracy = comparisonResult.accuracy
        currentMistakes = comparisonResult.mistakes
        
        // Calculate score
        let baseScore = Int(comparisonResult.accuracy * 100)
        let timeBonus = calculateTimeBonus(timeSpent: timeSpent, difficulty: sessionConfig?.difficulty ?? .grade1)
        let difficultyMultiplier = sessionConfig?.difficulty.scoreMultiplier ?? 1.0
        
        lastEarnedScore = Int(Float(baseScore + timeBonus) * difficultyMultiplier)
        currentScore += lastEarnedScore
        
        // Generate encouragement message
        encouragementMessage = generateEncouragementMessage(accuracy: comparisonResult.accuracy)
        
        // Update highlight mode
        highlightMode = .mistakes
        
        // Record the result
        recordExerciseResult(
            exercise: exercise,
            userInput: userInput,
            accuracy: comparisonResult.accuracy,
            score: lastEarnedScore,
            timeSpent: timeSpent,
            mistakes: comparisonResult.mistakes,
            attempts: 1
        )
    }
    
    private func calculateTimeBonus(timeSpent: TimeInterval, difficulty: DifficultyLevel) -> Int {
        let expectedTime: TimeInterval
        
        switch difficulty {
        case .grade1:
            expectedTime = 60 // 1 minute
        case .grade2:
            expectedTime = 90 // 1.5 minutes
        case .grade3:
            expectedTime = 120 // 2 minutes
        case .grade4:
            expectedTime = 150 // 2.5 minutes
        case .grade5:
            expectedTime = 180 // 3 minutes
        }
        
        if timeSpent < expectedTime * 0.8 {
            return Int((expectedTime - timeSpent) / expectedTime * 20) // Up to 20 bonus points
        }
        
        return 0
    }
    
    private func generateEncouragementMessage(accuracy: Float) -> String {
        switch accuracy {
        case 0.95...1.0:
            return ["Tuyệt vời! Bé đọc rất chính xác! 🌟", "Hoàn hảo! Bé làm rất tốt! 👏", "Xuất sắc! Tiếp tục như vậy nhé! ⭐"].randomElement() ?? ""
        case 0.85..<0.95:
            return ["Rất tốt! Bé đang tiến bộ! 👍", "Làm tốt lắm! Cố gắng thêm một chút nữa! 💪", "Giỏi quá! Bé đọc rất hay! 😊"].randomElement() ?? ""
        case 0.70..<0.85:
            return ["Khá tốt! Hãy đọc chậm hơn một chút! 📚", "Cố gắng lên! Bé sắp thành công rồi! 🎯", "Tốt! Lần sau sẽ hay hơn nữa! 🌈"].randomElement() ?? ""
        default:
            return ["Không sao! Hãy thử lại nhé! 💪", "Cố gắng lên! Bé làm được mà! 🌟", "Đọc chậm thôi, bé nhé! 📖"].randomElement() ?? ""
        }
    }
    
    private func recordExerciseResult(
        exercise: Exercise,
        userInput: String,
        accuracy: Float,
        score: Int,
        timeSpent: TimeInterval,
        mistakes: [TextMistake],
        attempts: Int
    ) {
        // This would record the result for analytics and progress tracking
        print("Exercise completed: \(exercise.title), Accuracy: \(accuracy), Score: \(score)")
    }
    
    private func completeSession() {
        sessionCompleted = true
        
        // Create session result
        let totalTimeSpent = Date().timeIntervalSince(sessionStartTime)
        let averageAccuracy = calculateAverageAccuracy()
        
        sessionResult = SessionResult(
            userId: "current_user", // This would come from authentication
            exerciseId: currentExercise?.id ?? UUID(),
            originalText: exercises.map { $0.targetText }.joined(separator: " "),
            spokenText: getCurrentUserInput(),
            accuracy: averageAccuracy,
            score: currentScore,
            timeSpent: totalTimeSpent,
            mistakes: currentMistakes,
            difficulty: sessionConfig?.difficulty ?? .grade1,
            inputMethod: selectedInputMethod,
            attempts: 1,
            category: sessionConfig?.category
        )
        
        // Save session with offline support
        Task {
            await saveSessionResult()
        }
        
        endSession()
    }
    
    private func saveSessionResult() async {
        guard let sessionResult = sessionResult else { return }
        
        do {
            // Create UserSession entity
            let context = PersistenceController.shared.container.viewContext
            let userSession = UserSession(context: context)
            
            // Populate session data
            userSession.id = UUID()
            userSession.inputText = sessionResult.originalText
            userSession.spokenText = sessionResult.spokenText
            userSession.accuracy = sessionResult.accuracy
            userSession.score = Int32(sessionResult.score)
            userSession.timeSpent = sessionResult.timeSpent
            userSession.completedAt = Date()
            userSession.inputMethod = sessionResult.inputMethod.rawValue
            userSession.difficulty = sessionResult.difficulty.rawValue
            userSession.attempts = Int32(sessionResult.attempts)
            
            // Handle offline mode
            if let offlineManager = offlineManager, offlineManager.isOfflineMode {
                // Save as offline session
                userSession.markForSync()
                try await offlineManager.saveOfflineSession(userSession)
                print("Session saved offline - will sync when online")
            } else {
                // Save normally
                try await PersistenceController.shared.save()
                print("Session saved online")
            }
            
        } catch {
            print("Failed to save session: \(error)")
            // Handle error gracefully - maybe show user notification
        }
    }
    
    private func calculateAverageAccuracy() -> Float {
        // This would calculate the average accuracy across all exercises
        // For now, return the current accuracy
        return currentAccuracy
    }
    
    // MARK: - Speech Recognition Methods
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
        speechRecognizer?.delegate = self
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    private func beginSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
                
                // Update audio level
                let level = self.calculateAudioLevel(from: buffer)
                DispatchQueue.main.async {
                    self.audioLevel = level
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            recognizedText = ""
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    DispatchQueue.main.async {
                        self?.recognizedText = result.bestTranscription.formattedString
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    DispatchQueue.main.async {
                        self?.stopRecording()
                    }
                }
            }
        } catch {
            print("Speech recognition failed: \(error)")
            isRecording = false
        }
    }
    
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        
        return min(rms * 10, 1.0) // Normalize to 0-1 range
    }
    
    private func playTextToSpeech(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN")
        utterance.rate = 0.4 // Slower for children
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch
        
        let synthesizer = AVSpeechSynthesizer()
        
        isPlayingAudio = true
        synthesizer.speak(utterance)
        
        // Reset playing state after estimated duration
        let estimatedDuration = Double(text.count) * 0.1 // Rough estimate
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            self.isPlayingAudio = false
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension ReadingPracticeViewModel: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle availability changes
    }
}

// MARK: - Highlight Mode Enum

enum HighlightMode {
    case none
    case mistakes
    case corrections
}

// MARK: - Text Comparison Service

class TextComparisonService {
    func compareTexts(original: String, spoken: String) -> TextComparisonResult {
        let originalWords = original.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let spokenWords = spoken.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        var mistakes: [TextMistake] = []
        var correctWords = 0
        
        let maxLength = max(originalWords.count, spokenWords.count)
        
        for i in 0..<maxLength {
            let originalWord = i < originalWords.count ? originalWords[i] : ""
            let spokenWord = i < spokenWords.count ? spokenWords[i] : ""
            
            if originalWord.lowercased() == spokenWord.lowercased() {
                correctWords += 1
            } else if !originalWord.isEmpty {
                let mistake = TextMistake(
                    id: UUID(),
                    expectedWord: originalWord,
                    actualWord: spokenWord.isEmpty ? nil : spokenWord,
                    position: i,
                    mistakeType: determineMistakeType(expected: originalWord, actual: spokenWord),
                    severity: .medium
                )
                mistakes.append(mistake)
            }
        }
        
        let accuracy = originalWords.isEmpty ? 0.0 : Float(correctWords) / Float(originalWords.count)
        
        return TextComparisonResult(
            accuracy: accuracy,
            mistakes: mistakes,
            correctWords: correctWords,
            totalWords: originalWords.count
        )
    }
    
    private func determineMistakeType(expected: String, actual: String) -> MistakeType {
        if actual.isEmpty {
            return .omission
        } else if expected.isEmpty {
            return .insertion
        } else {
            return .substitution
        }
    }
}

// MARK: - Text Comparison Result

struct TextComparisonResult {
    let accuracy: Float
    let mistakes: [TextMistake]
    let correctWords: Int
    let totalWords: Int
}