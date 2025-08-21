import SwiftUI
import UIKit

// MARK: - Accessibility Manager
@MainActor
final class AccessibilityManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AccessibilityManager()
    
    // MARK: - Published Properties
    @Published var isVoiceOverEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var isHighContrastEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    @Published var isAssistiveTouchEnabled = false
    @Published var isSwitchControlEnabled = false
    
    // MARK: - Private Properties
    private var accessibilityObservers: [NSObjectProtocol] = []
    
    // MARK: - Initialization
    private init() {
        updateAccessibilityStatus()
        setupAccessibilityObservers()
    }
    
    deinit {
        removeAccessibilityObservers()
    }
    
    // MARK: - Public Methods
    
    /// Get accessibility label for reading practice text
    func getReadingTextAccessibilityLabel(text: String, mistakes: [TextMistake]) -> String {
        if mistakes.isEmpty {
            return "Văn bản cần đọc: \(text). Không có lỗi."
        } else {
            let mistakeCount = mistakes.count
            let mistakeDescription = mistakeCount == 1 ? "1 lỗi" : "\(mistakeCount) lỗi"
            return "Văn bản cần đọc: \(text). Có \(mistakeDescription) cần sửa."
        }
    }
    
    /// Get accessibility label for score display
    func getScoreAccessibilityLabel(score: Int, accuracy: Float) -> String {
        let accuracyPercent = Int(accuracy * 100)
        return "Điểm số: \(score) điểm. Độ chính xác: \(accuracyPercent) phần trăm."
    }
    
    /// Get accessibility label for progress bar
    func getProgressAccessibilityLabel(current: Int, total: Int, type: String) -> String {
        let percentage = total > 0 ? Int(Float(current) / Float(total) * 100) : 0
        return "\(type): \(current) trên \(total). Hoàn thành \(percentage) phần trăm."
    }
    
    /// Get accessibility label for streak display
    func getStreakAccessibilityLabel(currentStreak: Int, bestStreak: Int) -> String {
        return "Chuỗi học tập hiện tại: \(currentStreak) ngày. Kỷ lục cá nhân: \(bestStreak) ngày."
    }
    
    /// Get accessibility hint for interactive elements
    func getAccessibilityHint(for element: AccessibleElement) -> String {
        switch element {
        case .practiceButton:
            return "Nhấn đúp để bắt đầu luyện tập đọc"
        case .recordButton:
            return "Nhấn đúp để bắt đầu hoặc dừng ghi âm"
        case .playButton:
            return "Nhấn đúp để phát âm thanh"
        case .submitButton:
            return "Nhấn đúp để nộp bài và xem kết quả"
        case .menuButton:
            return "Nhấn đúp để mở menu"
        case .settingsButton:
            return "Nhấn đúp để mở cài đặt"
        case .profileButton:
            return "Nhấn đúp để xem hồ sơ cá nhân"
        case .achievementBadge:
            return "Nhấn đúp để xem chi tiết thành tích"
        case .progressChart:
            return "Biểu đồ tiến độ học tập"
        case .difficultySelector:
            return "Nhấn đúp để chọn cấp độ khó"
        }
    }
    
    /// Get accessibility value for progress elements
    func getAccessibilityValue(for element: AccessibleElement, value: Any) -> String {
        switch element {
        case .progressChart:
            if let progress = value as? Float {
                return "\(Int(progress * 100)) phần trăm"
            }
        case .difficultySelector:
            if let difficulty = value as? DifficultyLevel {
                return difficulty.localizedName
            }
        default:
            break
        }
        
        return "\(value)"
    }
    
    /// Check if reduced motion is preferred
    func shouldReduceMotion() -> Bool {
        return isReduceMotionEnabled
    }
    
    /// Get appropriate animation duration based on accessibility settings
    func getAnimationDuration(default defaultDuration: TimeInterval) -> TimeInterval {
        return isReduceMotionEnabled ? 0.1 : defaultDuration
    }
    
    /// Get appropriate haptic feedback intensity
    func getHapticIntensity(default defaultIntensity: Float) -> Float {
        // Reduce haptic intensity for users with motor impairments
        return isAssistiveTouchEnabled ? defaultIntensity * 0.5 : defaultIntensity
    }
    
    /// Announce important events to VoiceOver users
    func announceToVoiceOver(_ message: String, priority: AccessibilityNotificationPriority = .medium) {
        guard isVoiceOverEnabled else { return }
        
        let notification: UIAccessibility.Notification
        switch priority {
        case .low:
            notification = .announcement
        case .medium:
            notification = .layoutChanged
        case .high:
            notification = .screenChanged
        }
        
        UIAccessibility.post(notification: notification, argument: message)
    }
    
    // MARK: - Private Methods
    
    private func updateAccessibilityStatus() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
        isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
        
        // Get preferred content size
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
    }
    
    private func setupAccessibilityObservers() {
        // VoiceOver status changes
        let voiceOverObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
        accessibilityObservers.append(voiceOverObserver)
        
        // Reduce motion changes
        let reduceMotionObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
        accessibilityObservers.append(reduceMotionObserver)
        
        // High contrast changes
        let contrastObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        accessibilityObservers.append(contrastObserver)
        
        // Content size changes
        let contentSizeObserver = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        }
        accessibilityObservers.append(contentSizeObserver)
        
        // Assistive Touch changes
        let assistiveTouchObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.assistiveTouchStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
        }
        accessibilityObservers.append(assistiveTouchObserver)
    }
    
    private func removeAccessibilityObservers() {
        for observer in accessibilityObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        accessibilityObservers.removeAll()
    }
}

// MARK: - Accessible Element Types
enum AccessibleElement {
    case practiceButton
    case recordButton
    case playButton
    case submitButton
    case menuButton
    case settingsButton
    case profileButton
    case achievementBadge
    case progressChart
    case difficultySelector
}

// MARK: - Accessibility Notification Priority
enum AccessibilityNotificationPriority {
    case low
    case medium
    case high
}

// MARK: - Content Size Category Extension
extension ContentSizeCategory {
    init(_ uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall:
            self = .extraSmall
        case .small:
            self = .small
        case .medium:
            self = .medium
        case .large:
            self = .large
        case .extraLarge:
            self = .extraLarge
        case .extraExtraLarge:
            self = .extraExtraLarge
        case .extraExtraExtraLarge:
            self = .extraExtraExtraLarge
        case .accessibilityMedium:
            self = .accessibilityMedium
        case .accessibilityLarge:
            self = .accessibilityLarge
        case .accessibilityExtraLarge:
            self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            self = .accessibilityExtraExtraExtraLarge
        default:
            self = .medium
        }
    }
    
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.1
        case .extraLarge:
            return 1.2
        case .extraExtraLarge:
            return 1.3
        case .extraExtraExtraLarge:
            return 1.4
        case .accessibilityMedium:
            return 1.5
        case .accessibilityLarge:
            return 1.6
        case .accessibilityExtraLarge:
            return 1.8
        case .accessibilityExtraExtraLarge:
            return 2.0
        case .accessibilityExtraExtraExtraLarge:
            return 2.2
        @unknown default:
            return 1.0
        }
    }
}

// MARK: - Missing Type Extensions

// DifficultyLevel extension for accessibility
extension DifficultyLevel {
    var localizedName: String {
        return self.rawValue
    }
}

// TextMistake extensions for accessibility
extension TextMistake {
    enum MistakeType: String, CaseIterable {
        case substitution = "substitution"
        case omission = "omission"
        case insertion = "insertion"
        case pronunciation = "pronunciation"
        
        var localizedName: String {
            switch self {
            case .substitution:
                return "Thay thế từ"
            case .omission:
                return "Thiếu từ"
            case .insertion:
                return "Thừa từ"
            case .pronunciation:
                return "Phát âm sai"
            }
        }
        
        var icon: String {
            switch self {
            case .substitution:
                return "arrow.left.arrow.right"
            case .omission:
                return "minus.circle"
            case .insertion:
                return "plus.circle"
            case .pronunciation:
                return "waveform.badge.exclamationmark"
            }
        }
        
        var color: Color {
            switch self {
            case .substitution:
                return .red
            case .omission:
                return .orange
            case .insertion:
                return .blue
            case .pronunciation:
                return .purple
            }
        }
    }
    
    enum Severity: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var color: Color {
            switch self {
            case .low:
                return .yellow
            case .medium:
                return .orange
            case .high:
                return .red
            }
        }
    }
}

// HighlightMode enum
enum HighlightMode {
    case none
    case mistakes
    case correct
}

// DifficultyLevel enum
enum DifficultyLevel: String, CaseIterable {
    case grade1 = "Lớp 1"
    case grade2 = "Lớp 2"
    case grade3 = "Lớp 3"
    case grade4 = "Lớp 4"
    case grade5 = "Lớp 5"
    
    var nextLevel: DifficultyLevel? {
        switch self {
        case .grade1:
            return .grade2
        case .grade2:
            return .grade3
        case .grade3:
            return .grade4
        case .grade4:
            return .grade5
        case .grade5:
            return nil
        }
    }
}