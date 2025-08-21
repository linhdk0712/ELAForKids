import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition Utilities
struct SpeechUtilities {
    
    // MARK: - Permission Checking
    static func checkSpeechRecognitionPermission() -> SFSpeechRecognizerAuthorizationStatus {
        return SFSpeechRecognizer.authorizationStatus()
    }
    
    static func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }
    
    static func isFullyAuthorized() -> Bool {
        let speechAuth = checkSpeechRecognitionPermission()
        let micAuth = checkMicrophonePermission()
        
        return speechAuth == .authorized && micAuth == .granted
    }
    
    // MARK: - Locale Management
    static func getSupportedLocales() -> [Locale] {
        return [
            Locale(identifier: "vi-VN"),
            Locale(identifier: "en-US"),
            Locale(identifier: "en-GB")
        ]
    }
    
    static func getPreferredLocale() -> Locale {
        let preferredLanguages = Locale.preferredLanguages
        
        for languageCode in preferredLanguages {
            if languageCode.hasPrefix("vi") {
                return Locale(identifier: "vi-VN")
            }
        }
        
        return Locale(identifier: "vi-VN") // Default to Vietnamese
    }
    
    static func isLocaleSupported(_ locale: Locale) -> Bool {
        return SFSpeechRecognizer(locale: locale) != nil
    }
    
    // MARK: - Audio Quality Assessment
    static func assessAudioEnvironment() -> AudioEnvironmentQuality {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Check if other audio is playing
            if audioSession.isOtherAudioPlaying {
                return .poor
            }
            
            // Check audio route
            let currentRoute = audioSession.currentRoute
            let hasBuiltInMic = currentRoute.inputs.contains { input in
                input.portType == .builtInMic
            }
            
            let hasExternalMic = currentRoute.inputs.contains { input in
                input.portType == .bluetoothHFP || 
                input.portType == .headsetMic ||
                input.portType == .usbAudio
            }
            
            if hasExternalMic {
                return .excellent
            } else if hasBuiltInMic {
                return .good
            } else {
                return .poor
            }
            
        } catch {
            return .fair
        }
    }
    
    // MARK: - Speech Recognition Configuration
    static func createOptimalRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        
        // Configure for optimal speech recognition
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false // Use server-based for better accuracy
        request.taskHint = .dictation // Optimize for dictation
        
        return request
    }
    
    static func configureAudioEngineForSpeech(_ audioEngine: AVAudioEngine) {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Optimal buffer size for speech recognition
        let bufferSize: AVAudioFrameCount = 1024
        
        // Remove any existing taps
        inputNode.removeTap(onBus: 0)
        
        // Install tap with optimal settings
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { buffer, _ in
            // This will be handled by the recognition request
        }
    }
    
    // MARK: - Error Handling
    static func mapSpeechErrorToAppError(_ error: Error) -> AppError {
        if let sfError = error as? SFError {
            switch sfError.code {
            case .speechRecognitionRequestIsCancelled:
                return .speechRecognitionFailed
            case .speechRecognitionRequestTimedOut:
                return .speechRecognitionFailed
            case .speechRecognitionRequestWaitingForSpeech:
                return .noSpeechDetected
            case .speechRecognitionRequestUnsupported:
                return .speechRecognitionUnavailable
            default:
                return .speechRecognitionFailed
            }
        }
        
        return .speechRecognitionFailed
    }
    
    // MARK: - Performance Optimization
    static func optimizeForBatteryLife() -> [String: Any] {
        return [
            "preferOnDeviceRecognition": true,
            "maxRecordingDuration": 30.0, // seconds
            "silenceTimeout": 3.0 // seconds
        ]
    }
    
    static func optimizeForAccuracy() -> [String: Any] {
        return [
            "preferOnDeviceRecognition": false,
            "maxRecordingDuration": 60.0, // seconds
            "silenceTimeout": 5.0 // seconds
        ]
    }
    
    // MARK: - Text Processing for Vietnamese
    static func preprocessVietnameseText(_ text: String) -> String {
        var processed = text
        
        // Normalize Vietnamese diacritics
        processed = processed.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi-VN"))
        
        // Remove extra whitespace
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processed
    }
    
    static func isVietnameseText(_ text: String) -> Bool {
        let vietnameseCharacters = CharacterSet(charactersIn: "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ")
        
        return text.rangeOfCharacter(from: vietnameseCharacters) != nil
    }
    
    // MARK: - Debugging and Diagnostics
    static func generateDiagnosticInfo() -> [String: Any] {
        let speechAuth = checkSpeechRecognitionPermission()
        let micAuth = checkMicrophonePermission()
        let audioEnvironment = assessAudioEnvironment()
        let supportedLocales = getSupportedLocales().map { $0.identifier }
        
        return [
            "speechRecognitionAuth": speechAuth.rawValue,
            "microphoneAuth": micAuth.rawValue,
            "audioEnvironmentQuality": audioEnvironment.rawValue,
            "supportedLocales": supportedLocales,
            "preferredLocale": getPreferredLocale().identifier,
            "isFullyAuthorized": isFullyAuthorized(),
            "systemVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model
        ]
    }
}

// MARK: - Audio Environment Quality
enum AudioEnvironmentQuality: String, CaseIterable {
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
    
    var description: String {
        switch self {
        case .excellent:
            return "Môi trường âm thanh lý tưởng cho ghi âm"
        case .good:
            return "Môi trường âm thanh tốt"
        case .fair:
            return "Môi trường âm thanh ổn, có thể có một ít tiếng ồn"
        case .poor:
            return "Môi trường âm thanh không tốt, có nhiều tiếng ồn"
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .excellent:
            return ["Môi trường ghi âm hoàn hảo!"]
        case .good:
            return ["Chất lượng âm thanh tốt", "Có thể nói bình thường"]
        case .fair:
            return ["Hãy tìm nơi yên tĩnh hơn", "Nói to và rõ ràng"]
        case .poor:
            return ["Tìm nơi yên tĩnh để ghi âm", "Tắt các nguồn âm thanh khác", "Sử dụng tai nghe có mic nếu có thể"]
        }
    }
}