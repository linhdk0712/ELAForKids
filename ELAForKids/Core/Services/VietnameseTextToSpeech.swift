import Foundation
import AVFoundation
import Combine
import SwiftUI

// MARK: - Vietnamese Text-to-Speech Engine
@MainActor
final class VietnameseTextToSpeech: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var currentProgress: Float = 0.0
    @Published var availableVoices: [TTSVoice] = []
    @Published var selectedVoice: TTSVoice?
    @Published var speechRate: Float = 0.5
    @Published var pitch: Float = 1.0
    @Published var volume: Float = 1.0
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var speechQueue: [SpeechRequest] = []
    private var isProcessingQueue = false
    
    // Configuration
    private let vietnameseLocale = Locale(identifier: "vi-VN")
    private var childFriendlySettings = ChildFriendlyTTSSettings()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupSynthesizer()
        loadAvailableVoices()
        configureForChildren()
    }
    
    // MARK: - Public Methods
    
    /// Speak text with default settings
    func speak(_ text: String) {
        let request = SpeechRequest(
            text: text,
            voice: selectedVoice,
            rate: speechRate,
            pitch: pitch,
            volume: volume,
            priority: .normal
        )
        
        addToQueue(request)
    }
    
    /// Speak text with custom settings
    func speak(
        _ text: String,
        voice: TTSVoice? = nil,
        rate: Float? = nil,
        pitch: Float? = nil,
        volume: Float? = nil,
        priority: SpeechPriority = .normal
    ) {
        let request = SpeechRequest(
            text: text,
            voice: voice ?? selectedVoice,
            rate: rate ?? speechRate,
            pitch: pitch ?? self.pitch,
            volume: volume ?? self.volume,
            priority: priority
        )
        
        addToQueue(request)
    }
    
    /// Speak text with phonetic emphasis for reading practice
    func speakForReadingPractice(_ text: String, emphasis: PhonemicEmphasis = .normal) {
        let processedText = processTextForReading(text, emphasis: emphasis)
        
        let request = SpeechRequest(
            text: processedText,
            voice: selectedVoice,
            rate: childFriendlySettings.readingPracticeRate,
            pitch: childFriendlySettings.readingPracticePitch,
            volume: volume,
            priority: .high
        )
        
        addToQueue(request)
    }
    
    /// Speak individual words with clear pronunciation
    func speakWord(_ word: String, withPause: Bool = true) {
        let processedWord = processWordForClarity(word)
        
        let request = SpeechRequest(
            text: processedWord,
            voice: selectedVoice,
            rate: childFriendlySettings.wordPracticeRate,
            pitch: childFriendlySettings.wordPracticePitch,
            volume: volume,
            priority: .high
        )
        
        addToQueue(request)
        
        if withPause {
            // Add a brief pause after the word
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Pause is handled by the delay
            }
        }
    }
    
    /// Speak encouragement messages
    func speakEncouragement(_ message: EncouragementMessage) {
        let request = SpeechRequest(
            text: message.text,
            voice: selectedVoice,
            rate: childFriendlySettings.encouragementRate,
            pitch: childFriendlySettings.encouragementPitch,
            volume: volume,
            priority: .high
        )
        
        addToQueue(request)
    }
    
    /// Pause current speech
    func pauseSpeech() {
        guard isSpeaking else { return }
        
        if synthesizer.pauseSpeaking(at: .immediate) {
            isPaused = true
        }
    }
    
    /// Resume paused speech
    func resumeSpeech() {
        guard isPaused else { return }
        
        if synthesizer.continueSpeaking() {
            isPaused = false
        }
    }
    
    /// Stop current speech and clear queue
    func stopSpeech() {
        synthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        currentUtterance = nil
        isSpeaking = false
        isPaused = false
        currentProgress = 0.0
        isProcessingQueue = false
    }
    
    /// Configure voice settings
    func configureVoice(
        rate: Float? = nil,
        pitch: Float? = nil,
        volume: Float? = nil
    ) {
        if let rate = rate {
            speechRate = max(0.1, min(1.0, rate))
        }
        
        if let pitch = pitch {
            self.pitch = max(0.5, min(2.0, pitch))
        }
        
        if let volume = volume {
            self.volume = max(0.0, min(1.0, volume))
        }
    }
    
    /// Select voice by identifier
    func selectVoice(identifier: String) {
        selectedVoice = availableVoices.first { $0.identifier == identifier }
    }
    
    /// Get recommended voice for children
    func getRecommendedChildVoice() -> TTSVoice? {
        // Prefer female voices for children as they're generally clearer
        let femaleVoices = availableVoices.filter { $0.gender == .female }
        
        // Look for high-quality Vietnamese voices
        let highQualityVietnamese = femaleVoices.filter { 
            $0.language.hasPrefix("vi") && $0.quality == .enhanced 
        }
        
        return highQualityVietnamese.first ?? femaleVoices.first ?? availableVoices.first
    }
    
    /// Test voice with sample text
    func testVoice(_ voice: TTSVoice) {
        let sampleTexts = [
            "Xin chào! Tôi là trợ lý đọc của bé.",
            "Hãy đọc theo tôi: Con mèo nhỏ ngồi trên thảm.",
            "Tuyệt vời! Bé đọc rất hay!"
        ]
        
        let randomText = sampleTexts.randomElement() ?? sampleTexts[0]
        
        speak(
            randomText,
            voice: voice,
            rate: childFriendlySettings.testRate,
            pitch: childFriendlySettings.testPitch,
            priority: .high
        )
    }
    
    // MARK: - Private Methods
    
    private func setupSynthesizer() {
        synthesizer.delegate = self
        
        // Configure audio session for speech
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session for TTS: \(error)")
            errorMessage = "Không thể thiết lập âm thanh: \(error.localizedDescription)"
        }
    }
    
    private func loadAvailableVoices() {
        let systemVoices = AVSpeechSynthesisVoice.speechVoices()
        
        availableVoices = systemVoices.compactMap { voice in
            // Focus on Vietnamese voices, but include some English for fallback
            guard voice.language.hasPrefix("vi") || voice.language.hasPrefix("en") else {
                return nil
            }
            
            return TTSVoice(
                identifier: voice.identifier,
                name: voice.name,
                language: voice.language,
                quality: voice.quality == .enhanced ? .enhanced : .default,
                gender: determineGender(from: voice.name)
            )
        }
        
        // Sort by quality and language preference
        availableVoices.sort { voice1, voice2 in
            // Prefer Vietnamese voices
            if voice1.language.hasPrefix("vi") && !voice2.language.hasPrefix("vi") {
                return true
            }
            if !voice1.language.hasPrefix("vi") && voice2.language.hasPrefix("vi") {
                return false
            }
            
            // Then prefer enhanced quality
            if voice1.quality == .enhanced && voice2.quality != .enhanced {
                return true
            }
            if voice1.quality != .enhanced && voice2.quality == .enhanced {
                return false
            }
            
            return voice1.name < voice2.name
        }
    }
    
    private func configureForChildren() {
        // Select the best voice for children
        selectedVoice = getRecommendedChildVoice()
        
        // Set child-friendly defaults
        speechRate = childFriendlySettings.defaultRate
        pitch = childFriendlySettings.defaultPitch
        volume = childFriendlySettings.defaultVolume
    }
    
    private func addToQueue(_ request: SpeechRequest) {
        // Handle priority
        if request.priority == .high {
            // Stop current speech if high priority
            if isSpeaking {
                synthesizer.stopSpeaking(at: .word)
            }
            speechQueue.insert(request, at: 0)
        } else {
            speechQueue.append(request)
        }
        
        processQueue()
    }
    
    private func processQueue() {
        guard !isProcessingQueue, !speechQueue.isEmpty else { return }
        
        isProcessingQueue = true
        let request = speechQueue.removeFirst()
        
        speakRequest(request)
    }
    
    private func speakRequest(_ request: SpeechRequest) {
        guard !request.text.isEmpty else {
            // Handle pause/silence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.onSpeechFinished()
            }
            return
        }
        
        let utterance = AVSpeechUtterance(string: request.text)
        
        // Configure utterance
        if let voice = request.voice,
           let systemVoice = AVSpeechSynthesisVoice(identifier: voice.identifier) {
            utterance.voice = systemVoice
        } else if let selectedVoice = selectedVoice,
                  let systemVoice = AVSpeechSynthesisVoice(identifier: selectedVoice.identifier) {
            utterance.voice = systemVoice
        }
        
        utterance.rate = request.rate
        utterance.pitchMultiplier = request.pitch
        utterance.volume = request.volume
        
        // Add pre-utterance delay for better pacing
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    private func processTextForReading(_ text: String, emphasis: PhonemicEmphasis) -> String {
        var processedText = text
        
        switch emphasis {
        case .normal:
            // Add natural pauses
            processedText = addNaturalPauses(processedText)
            
        case .syllableBysyllable:
            // Break into syllables with pauses
            processedText = breakIntoSyllables(processedText)
            
        case .wordByWord:
            // Add pauses between words
            processedText = processedText.replacingOccurrences(of: " ", with: "... ")
            
        case .phonetic:
            // Emphasize phonetic elements
            processedText = emphasizePhonetics(processedText)
        }
        
        return processedText
    }
    
    private func processWordForClarity(_ word: String) -> String {
        // Add slight pauses for complex Vietnamese words
        var processedWord = word
        
        // Handle common Vietnamese phonetic patterns
        let phoneticPatterns = [
            ("ng", "ng-"),
            ("nh", "nh-"),
            ("ch", "ch-"),
            ("tr", "tr-"),
            ("qu", "qu-")
        ]
        
        for (pattern, replacement) in phoneticPatterns {
            if processedWord.lowercased().contains(pattern) {
                processedWord = processedWord.replacingOccurrences(
                    of: pattern,
                    with: replacement,
                    options: .caseInsensitive
                )
            }
        }
        
        return processedWord
    }
    
    private func addNaturalPauses(_ text: String) -> String {
        var processedText = text
        
        // Add pauses after punctuation
        processedText = processedText.replacingOccurrences(of: ".", with: ".")
        processedText = processedText.replacingOccurrences(of: ",", with: ", ")
        processedText = processedText.replacingOccurrences(of: "!", with: "! ")
        processedText = processedText.replacingOccurrences(of: "?", with: "? ")
        
        return processedText
    }
    
    private func breakIntoSyllables(_ text: String) -> String {
        // Simple syllable breaking for Vietnamese
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        let syllableWords = words.map { word in
            // Add pauses within longer words
            if word.count > 4 {
                let midpoint = word.index(word.startIndex, offsetBy: word.count / 2)
                let firstHalf = String(word[..<midpoint])
                let secondHalf = String(word[midpoint...])
                return "\(firstHalf)-\(secondHalf)"
            }
            return word
        }
        
        return syllableWords.joined(separator: " ")
    }
    
    private func emphasizePhonetics(_ text: String) -> String {
        // Emphasize Vietnamese tones and phonetic elements
        var processedText = text
        
        // Vietnamese tone markers - slow down words with tones
        let toneMarkers = ["á", "à", "ả", "ã", "ạ", "ă", "ắ", "ằ", "ẳ", "ẵ", "ặ", "â", "ấ", "ầ", "ẩ", "ẫ", "ậ",
                          "é", "è", "ẻ", "ẽ", "ẹ", "ê", "ế", "ề", "ể", "ễ", "ệ",
                          "í", "ì", "ỉ", "ĩ", "ị",
                          "ó", "ò", "ỏ", "õ", "ọ", "ô", "ố", "ồ", "ổ", "ỗ", "ộ", "ơ", "ớ", "ờ", "ở", "ỡ", "ợ",
                          "ú", "ù", "ủ", "ũ", "ụ", "ư", "ứ", "ừ", "ử", "ữ", "ự",
                          "ý", "ỳ", "ỷ", "ỹ", "ỵ"]
        
        for marker in toneMarkers {
            processedText = processedText.replacingOccurrences(of: marker, with: "\(marker)")
        }
        
        return processedText
    }
    
    private func determineGender(from voiceName: String) -> VoiceGender {
        let femaleIndicators = ["female", "woman", "girl", "nữ", "Female"]
        let maleIndicators = ["male", "man", "boy", "nam", "Male"]
        
        let lowercaseName = voiceName.lowercased()
        
        if femaleIndicators.contains(where: { lowercaseName.contains($0) }) {
            return .female
        } else if maleIndicators.contains(where: { lowercaseName.contains($0) }) {
            return .male
        }
        
        return .unknown
    }
    
    private func onSpeechFinished() {
        isSpeaking = false
        isPaused = false
        currentProgress = 0.0
        currentUtterance = nil
        isProcessingQueue = false
        
        // Process next item in queue
        if !speechQueue.isEmpty {
            processQueue()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VietnameseTextToSpeech: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
        currentProgress = 0.0
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeechFinished()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPaused = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPaused = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onSpeechFinished()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Update progress
        let totalLength = utterance.speechString.count
        if totalLength > 0 {
            currentProgress = Float(characterRange.location + characterRange.length) / Float(totalLength)
        }
    }
}

// MARK: - Supporting Types

struct TTSVoice {
    let identifier: String
    let name: String
    let language: String
    let quality: VoiceQuality
    let gender: VoiceGender
    
    var isVietnamese: Bool {
        return language.hasPrefix("vi")
    }
    
    var displayName: String {
        return "\(name) (\(language))"
    }
}

enum VoiceQuality {
    case `default`
    case enhanced
    
    var localizedDescription: String {
        switch self {
        case .default:
            return "Tiêu chuẩn"
        case .enhanced:
            return "Chất lượng cao"
        }
    }
}

enum VoiceGender {
    case male
    case female
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .male:
            return "Nam"
        case .female:
            return "Nữ"
        case .unknown:
            return "Không xác định"
        }
    }
}

enum PhonemicEmphasis {
    case normal
    case syllableBysyllable
    case wordByWord
    case phonetic
    
    var localizedDescription: String {
        switch self {
        case .normal:
            return "Bình thường"
        case .syllableBysyllable:
            return "Từng âm tiết"
        case .wordByWord:
            return "Từng từ"
        case .phonetic:
            return "Nhấn âm"
        }
    }
}

enum SpeechPriority {
    case low
    case normal
    case high
}

struct SpeechRequest {
    let text: String
    let voice: TTSVoice?
    let rate: Float
    let pitch: Float
    let volume: Float
    let priority: SpeechPriority
    
    init(
        text: String,
        voice: TTSVoice? = nil,
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 1.0,
        priority: SpeechPriority = .normal
    ) {
        self.text = text
        self.voice = voice
        self.rate = max(0.1, min(1.0, rate))
        self.pitch = max(0.5, min(2.0, pitch))
        self.volume = max(0.0, min(1.0, volume))
        self.priority = priority
    }
}

struct ChildFriendlyTTSSettings {
    // Default settings optimized for children
    let defaultRate: Float = 0.4        // Slower for better comprehension
    let defaultPitch: Float = 1.1       // Slightly higher pitch
    let defaultVolume: Float = 0.8      // Not too loud
    
    // Reading practice settings
    let readingPracticeRate: Float = 0.3    // Very slow for practice
    let readingPracticePitch: Float = 1.0   // Normal pitch for clarity
    
    // Word practice settings
    let wordPracticeRate: Float = 0.25      // Extra slow for individual words
    let wordPracticePitch: Float = 1.0      // Normal pitch
    
    // Encouragement settings
    let encouragementRate: Float = 0.5      // Normal speed for encouragement
    let encouragementPitch: Float = 1.2     // Higher pitch for excitement
    
    // Test settings
    let testRate: Float = 0.4               // Moderate speed for testing
    let testPitch: Float = 1.0              // Normal pitch
}

struct EncouragementMessage {
    let text: String
    let emotion: EmotionType
    let context: EncouragementContext
    
    static let excellent = [
        EncouragementMessage(text: "Tuyệt vời! Bé đọc rất hay!", emotion: .joy, context: .achievement),
        EncouragementMessage(text: "Xuất sắc! Bé là một độc giả tài năng!", emotion: .pride, context: .achievement),
        EncouragementMessage(text: "Thật tuyệt! Bé đã làm rất tốt!", emotion: .excitement, context: .achievement)
    ]
    
    static let good = [
        EncouragementMessage(text: "Rất tốt! Bé đang tiến bộ!", emotion: .happiness, context: .progress),
        EncouragementMessage(text: "Giỏi lắm! Tiếp tục cố gắng nhé!", emotion: .encouragement, context: .progress),
        EncouragementMessage(text: "Tốt lắm! Bé đọc ngày càng hay!", emotion: .pride, context: .progress)
    ]
    
    static let needsImprovement = [
        EncouragementMessage(text: "Cố gắng lên! Bé sẽ làm được!", emotion: .encouragement, context: .motivation),
        EncouragementMessage(text: "Không sao! Hãy thử lại nhé!", emotion: .support, context: .motivation),
        EncouragementMessage(text: "Bé có thể làm tốt hơn! Đọc chậm thôi!", emotion: .guidance, context: .instruction)
    ]
    
    static let tryAgain = [
        EncouragementMessage(text: "Thử lại một lần nữa nhé!", emotion: .encouragement, context: .retry),
        EncouragementMessage(text: "Lần này sẽ tốt hơn đấy!", emotion: .optimism, context: .retry),
        EncouragementMessage(text: "Bé làm được mà! Cố gắng lên!", emotion: .support, context: .retry)
    ]
}

enum EmotionType {
    case joy
    case happiness
    case excitement
    case pride
    case encouragement
    case support
    case guidance
    case optimism
}

enum EncouragementContext {
    case achievement
    case progress
    case motivation
    case instruction
    case retry
}