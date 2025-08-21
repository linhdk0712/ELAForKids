import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - UX Enhancement Service
@MainActor
final class UXEnhancementService: ObservableObject {
    
    // MARK: - Properties
    static let shared = UXEnhancementService()
    
    @Published var hapticFeedbackEnabled = true
    @Published var soundEffectsEnabled = true
    @Published var visualFeedbackEnabled = true
    @Published var encouragementLevel: EncouragementLevel = .balanced
    
    private var cancellables = Set<AnyCancellable>()
    private let hapticManager = HapticFeedbackManager.shared
    private let soundManager = SoundEffectManager.shared
    
    // User interaction tracking
    private var interactionHistory: [UserInteraction] = []
    private var sessionStartTime = Date()
    private var consecutiveSuccesses = 0
    private var consecutiveErrors = 0
    
    // Adaptive feedback system
    private var adaptiveFeedbackEnabled = true
    private var userPreferences = UserPreferences()
    
    // MARK: - Initialization
    private init() {
        setupUserPreferences()
        setupAdaptiveFeedback()
    }
    
    // MARK: - Setup
    private func setupUserPreferences() {
        // Load user preferences from UserDefaults
        loadUserPreferences()
        
        // Setup preference observers
        setupPreferenceObservers()
    }
    
    private func setupAdaptiveFeedback() {
        // Monitor user interactions to adapt feedback
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.analyzeUserBehavior()
        }
    }
    
    private func setupPreferenceObservers() {
        // Monitor accessibility settings
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.adaptToAccessibilityChanges()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.adaptToAccessibilityChanges()
            }
            .store(in: &cancellables)
    }
    
    private func loadUserPreferences() {
        let defaults = UserDefaults.standard
        hapticFeedbackEnabled = defaults.bool(forKey: "hapticFeedbackEnabled")
        soundEffectsEnabled = defaults.bool(forKey: "soundEffectsEnabled")
        visualFeedbackEnabled = defaults.bool(forKey: "visualFeedbackEnabled")
        
        if let encouragementRaw = defaults.object(forKey: "encouragementLevel") as? String,
           let encouragement = EncouragementLevel(rawValue: encouragementRaw) {
            encouragementLevel = encouragement
        }
    }
    
    private func saveUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        defaults.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        defaults.set(visualFeedbackEnabled, forKey: "visualFeedbackEnabled")
        defaults.set(encouragementLevel.rawValue, forKey: "encouragementLevel")
    }
    
    private func adaptToAccessibilityChanges() {
        if UIAccessibility.isVoiceOverRunning {
            // Enhance audio feedback for VoiceOver users
            soundEffectsEnabled = true
            hapticFeedbackEnabled = true
        }
        
        if UIAccessibility.isReduceMotionEnabled {
            // Reduce visual effects
            visualFeedbackEnabled = false
        }
    }
    
    // MARK: - Feedback Methods
    func provideFeedback(for result: FeedbackResult) {
        recordInteraction(result)
        
        switch result.type {
        case .success:
            provideSuccessFeedback(result)
        case .error:
            provideErrorFeedback(result)
        case .encouragement:
            provideEncouragementFeedback(result)
        case .achievement:
            provideAchievementFeedback(result)
        }
        
        updateConsecutiveCounters(result.type)
        adaptFeedbackBasedOnHistory()
    }
    
    private func provideSuccessFeedback(_ result: FeedbackResult) {
        // Haptic feedback
        if hapticFeedbackEnabled {
            hapticManager.playSuccessHaptic()
        }
        
        // Sound feedback
        if soundEffectsEnabled {
            soundManager.playSuccessSound()
        }
        
        // Visual feedback
        if visualFeedbackEnabled {
            showVisualFeedback(.success, message: result.message)
        }
        
        // Adaptive encouragement
        if shouldShowEncouragement(.success) {
            showEncouragementMessage(getSuccessEncouragement())
        }
    }
    
    private func provideErrorFeedback(_ result: FeedbackResult) {
        // Gentle haptic feedback for errors
        if hapticFeedbackEnabled {
            hapticManager.playErrorHaptic()
        }
        
        // Gentle sound feedback
        if soundEffectsEnabled {
            soundManager.playErrorSound()
        }
        
        // Visual feedback with helpful hints
        if visualFeedbackEnabled {
            showVisualFeedback(.error, message: result.message, hints: result.hints)
        }
        
        // Adaptive encouragement for errors
        if shouldShowEncouragement(.error) {
            showEncouragementMessage(getErrorEncouragement())
        }
    }
    
    private func provideEncouragementFeedback(_ result: FeedbackResult) {
        // Light haptic feedback
        if hapticFeedbackEnabled {
            hapticManager.playEncouragementHaptic()
        }
        
        // Encouraging sound
        if soundEffectsEnabled {
            soundManager.playEncouragementSound()
        }
        
        // Visual encouragement
        if visualFeedbackEnabled {
            showVisualFeedback(.encouragement, message: result.message)
        }
    }
    
    private func provideAchievementFeedback(_ result: FeedbackResult) {
        // Strong haptic feedback for achievements
        if hapticFeedbackEnabled {
            hapticManager.playAchievementHaptic()
        }
        
        // Celebration sound
        if soundEffectsEnabled {
            soundManager.playAchievementSound()
        }
        
        // Visual celebration
        if visualFeedbackEnabled {
            showVisualFeedback(.achievement, message: result.message)
        }
        
        // Always show encouragement for achievements
        showEncouragementMessage(getAchievementEncouragement())
    }
    
    // MARK: - Visual Feedback
    private func showVisualFeedback(_ type: FeedbackType, message: String, hints: [String] = []) {
        let feedback = VisualFeedback(
            type: type,
            message: message,
            hints: hints,
            timestamp: Date()
        )
        
        NotificationCenter.default.post(
            name: .showVisualFeedback,
            object: feedback
        )
    }
    
    // MARK: - Encouragement System
    private func shouldShowEncouragement(_ type: FeedbackType) -> Bool {
        switch encouragementLevel {
        case .minimal:
            return type == .achievement
        case .balanced:
            return type == .achievement || (type == .error && consecutiveErrors >= 2)
        case .maximum:
            return true
        }
    }
    
    private func getSuccessEncouragement() -> String {
        let messages = [
            "Tuyệt vời! 🌟",
            "Giỏi lắm! 👏",
            "Chính xác! ✨",
            "Xuất sắc! 🎉",
            "Làm tốt lắm! 💫"
        ]
        return messages.randomElement() ?? "Tuyệt vời!"
    }
    
    private func getErrorEncouragement() -> String {
        let messages = [
            "Không sao, hãy thử lại nhé! 💪",
            "Gần đúng rồi, cố gắng thêm! 🌈",
            "Học hỏi từ sai lầm là tuyệt vời! 📚",
            "Hãy thử một lần nữa! 🚀",
            "Bạn đang tiến bộ! ⭐"
        ]
        return messages.randomElement() ?? "Hãy thử lại nhé!"
    }
    
    private func getAchievementEncouragement() -> String {
        let messages = [
            "Chúc mừng! Bạn đã đạt được thành tích mới! 🏆",
            "Tuyệt vời! Bạn đang học rất giỏi! 🎊",
            "Xuất sắc! Tiếp tục cố gắng nhé! 🌟",
            "Thật tuyệt! Bạn đã vượt qua thử thách! 🎯",
            "Tài giỏi quá! Bạn là nhà vô địch! 👑"
        ]
        return messages.randomElement() ?? "Chúc mừng!"
    }
    
    private func showEncouragementMessage(_ message: String) {
        NotificationCenter.default.post(
            name: .showEncouragementMessage,
            object: message
        )
    }
    
    // MARK: - Adaptive Feedback
    private func recordInteraction(_ result: FeedbackResult) {
        let interaction = UserInteraction(
            timestamp: Date(),
            type: result.type,
            context: result.context,
            userResponse: result.userResponse
        )
        
        interactionHistory.append(interaction)
        
        // Keep only recent history
        if interactionHistory.count > 100 {
            interactionHistory.removeFirst()
        }
    }
    
    private func updateConsecutiveCounters(_ type: FeedbackType) {
        switch type {
        case .success:
            consecutiveSuccesses += 1
            consecutiveErrors = 0
        case .error:
            consecutiveErrors += 1
            consecutiveSuccesses = 0
        case .encouragement, .achievement:
            break
        }
    }
    
    private func adaptFeedbackBasedOnHistory() {
        guard adaptiveFeedbackEnabled else { return }
        
        let recentInteractions = interactionHistory.suffix(10)
        let errorRate = Double(recentInteractions.filter { $0.type == .error }.count) / Double(recentInteractions.count)
        
        // Adapt encouragement level based on error rate
        if errorRate > 0.7 {
            encouragementLevel = .maximum
        } else if errorRate < 0.2 {
            encouragementLevel = .minimal
        } else {
            encouragementLevel = .balanced
        }
        
        // Adapt feedback intensity
        if consecutiveErrors >= 3 {
            // Increase encouragement and reduce negative feedback
            hapticFeedbackEnabled = true
            soundEffectsEnabled = true
        }
        
        if consecutiveSuccesses >= 5 {
            // User is doing well, can reduce feedback intensity
            encouragementLevel = .minimal
        }
    }
    
    private func analyzeUserBehavior() {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let totalInteractions = interactionHistory.count
        
        // Analyze interaction patterns
        if sessionDuration > 300 && totalInteractions < 5 {
            // User seems disengaged, increase encouragement
            encouragementLevel = .maximum
        }
        
        // Analyze success patterns
        let recentSuccesses = interactionHistory.suffix(20).filter { $0.type == .success }
        if recentSuccesses.count >= 15 {
            // User is very successful, can reduce feedback
            encouragementLevel = .minimal
        }
    }
    
    // MARK: - Micro-interactions
    func enhanceButtonInteraction() -> some ViewModifier {
        return ButtonEnhancementModifier(
            hapticEnabled: hapticFeedbackEnabled,
            soundEnabled: soundEffectsEnabled,
            visualEnabled: visualFeedbackEnabled
        )
    }
    
    func enhanceTextInput() -> some ViewModifier {
        return TextInputEnhancementModifier(
            hapticEnabled: hapticFeedbackEnabled,
            soundEnabled: soundEffectsEnabled
        )
    }
    
    func enhanceNavigation() -> some ViewModifier {
        return NavigationEnhancementModifier(
            hapticEnabled: hapticFeedbackEnabled,
            soundEnabled: soundEffectsEnabled
        )
    }
    
    // MARK: - Public Interface
    func setHapticFeedback(_ enabled: Bool) {
        hapticFeedbackEnabled = enabled
        saveUserPreferences()
    }
    
    func setSoundEffects(_ enabled: Bool) {
        soundEffectsEnabled = enabled
        saveUserPreferences()
    }
    
    func setVisualFeedback(_ enabled: Bool) {
        visualFeedbackEnabled = enabled
        saveUserPreferences()
    }
    
    func setEncouragementLevel(_ level: EncouragementLevel) {
        encouragementLevel = level
        saveUserPreferences()
    }
    
    func resetSession() {
        sessionStartTime = Date()
        consecutiveSuccesses = 0
        consecutiveErrors = 0
        interactionHistory.removeAll()
    }
    
    func getSessionStatistics() -> SessionStatistics {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let totalInteractions = interactionHistory.count
        let successCount = interactionHistory.filter { $0.type == .success }.count
        let errorCount = interactionHistory.filter { $0.type == .error }.count
        
        return SessionStatistics(
            duration: sessionDuration,
            totalInteractions: totalInteractions,
            successCount: successCount,
            errorCount: errorCount,
            consecutiveSuccesses: consecutiveSuccesses,
            consecutiveErrors: consecutiveErrors
        )
    }
}

// MARK: - Supporting Types
enum FeedbackType {
    case success
    case error
    case encouragement
    case achievement
}

enum EncouragementLevel: String, CaseIterable {
    case minimal = "minimal"
    case balanced = "balanced"
    case maximum = "maximum"
    
    var displayName: String {
        switch self {
        case .minimal:
            return "Tối thiểu"
        case .balanced:
            return "Cân bằng"
        case .maximum:
            return "Tối đa"
        }
    }
    
    var description: String {
        switch self {
        case .minimal:
            return "Ít khuyến khích, tập trung vào kết quả"
        case .balanced:
            return "Khuyến khích vừa phải"
        case .maximum:
            return "Khuyến khích nhiều, động viên tích cực"
        }
    }
}

struct FeedbackResult {
    let type: FeedbackType
    let message: String
    let context: String
    let hints: [String]
    let userResponse: String?
    
    init(type: FeedbackType, message: String, context: String = "", hints: [String] = [], userResponse: String? = nil) {
        self.type = type
        self.message = message
        self.context = context
        self.hints = hints
        self.userResponse = userResponse
    }
}

struct UserInteraction {
    let timestamp: Date
    let type: FeedbackType
    let context: String
    let userResponse: String?
}

struct VisualFeedback {
    let type: FeedbackType
    let message: String
    let hints: [String]
    let timestamp: Date
}

struct UserPreferences {
    var hapticFeedbackEnabled = true
    var soundEffectsEnabled = true
    var visualFeedbackEnabled = true
    var encouragementLevel = EncouragementLevel.balanced
}

struct SessionStatistics {
    let duration: TimeInterval
    let totalInteractions: Int
    let successCount: Int
    let errorCount: Int
    let consecutiveSuccesses: Int
    let consecutiveErrors: Int
    
    var successRate: Double {
        guard totalInteractions > 0 else { return 0 }
        return Double(successCount) / Double(totalInteractions)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    var formattedSuccessRate: String {
        return String(format: "%.1f%%", successRate * 100)
    }
}

// MARK: - View Modifiers
struct ButtonEnhancementModifier: ViewModifier {
    let hapticEnabled: Bool
    let soundEnabled: Bool
    let visualEnabled: Bool
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
                if pressing && hapticEnabled {
                    HapticFeedbackManager.shared.playButtonTapHaptic()
                }
                if pressing && soundEnabled {
                    SoundEffectManager.shared.playButtonTapSound()
                }
            }, perform: {})
    }
}

struct TextInputEnhancementModifier: ViewModifier {
    let hapticEnabled: Bool
    let soundEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if hapticEnabled {
                    HapticFeedbackManager.shared.playSelectionHaptic()
                }
                if soundEnabled {
                    SoundEffectManager.shared.playTextInputSound()
                }
            }
    }
}

struct NavigationEnhancementModifier: ViewModifier {
    let hapticEnabled: Bool
    let soundEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if hapticEnabled {
                    HapticFeedbackManager.shared.playNavigationHaptic()
                }
                if soundEnabled {
                    SoundEffectManager.shared.playNavigationSound()
                }
            }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let showVisualFeedback = Notification.Name("showVisualFeedback")
    static let showEncouragementMessage = Notification.Name("showEncouragementMessage")
}

// MARK: - View Extensions
extension View {
    func enhancedButton() -> some View {
        modifier(UXEnhancementService.shared.enhanceButtonInteraction())
    }
    
    func enhancedTextInput() -> some View {
        modifier(UXEnhancementService.shared.enhanceTextInput())
    }
    
    func enhancedNavigation() -> some View {
        modifier(UXEnhancementService.shared.enhanceNavigation())
    }
}