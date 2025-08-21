import SwiftUI
import UIKit

// MARK: - SwiftUI Accessibility Extensions

extension View {
    /// Apply accessibility modifications based on current accessibility settings
    func accessibilityOptimized() -> some View {
        self.modifier(AccessibilityOptimizedModifier())
    }
    
    /// Add child-friendly accessibility labels and hints
    func childFriendlyAccessibility(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Make text dynamically scalable for accessibility
    func dynamicTypeSize() -> some View {
        self.modifier(DynamicTypeSizeModifier())
    }
    
    /// Add high contrast support
    func highContrastSupport() -> some View {
        self.modifier(HighContrastModifier())
    }
    
    /// Add reduced motion support
    func reducedMotionSupport() -> some View {
        self.modifier(ReducedMotionModifier())
    }
    
    /// Announce changes to VoiceOver users
    func announceChanges(_ message: String, priority: AccessibilityNotificationPriority = .medium) -> some View {
        self.onAppear {
            AccessibilityManager.shared.announceToVoiceOver(message, priority: priority)
        }
    }
}

// MARK: - Accessibility Modifiers

struct AccessibilityOptimizedModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize()
            .highContrastSupport()
            .reducedMotionSupport()
    }
}

struct DynamicTypeSizeModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(accessibilityManager.preferredContentSizeCategory.scaleFactor)
            .animation(.easeInOut(duration: 0.3), value: accessibilityManager.preferredContentSizeCategory)
    }
}

struct HighContrastModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .colorScheme(accessibilityManager.isHighContrastEnabled ? .dark : .light)
    }
}

struct ReducedMotionModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .animation(
                accessibilityManager.shouldReduceMotion() ? .none : .default,
                value: accessibilityManager.isReduceMotionEnabled
            )
    }
}

// MARK: - Accessibility-Aware Components

struct AccessibleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        title: String,
        icon: String? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
            .foregroundColor(.white)
        }
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
        .scaleEffect(accessibilityManager.preferredContentSizeCategory.scaleFactor)
        .animation(.easeInOut(duration: 0.3), value: accessibilityManager.preferredContentSizeCategory)
    }
}

struct AccessibleProgressView: View {
    let value: Double
    let total: Double
    let label: String
    let description: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(value: Double, total: Double, label: String, description: String? = nil) {
        self.value = value
        self.total = total
        self.label = label
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(value))/\(Int(total))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: value, total: total)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityManager.getProgressAccessibilityLabel(
            current: Int(value),
            total: Int(total),
            type: label
        ))
        .accessibilityValue("\(Int((value / total) * 100)) phần trăm")
    }
}

struct AccessibleScoreDisplay: View {
    let score: Int
    let accuracy: Float
    let title: String
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(score)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityManager.getScoreAccessibilityLabel(score: score, accuracy: accuracy))
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Accessibility Helpers

struct AccessibilityFocusHelper: View {
    let isActive: Bool
    let announcement: String
    
    var body: some View {
        EmptyView()
            .accessibilityHidden(true)
            .onChange(of: isActive) { active in
                if active {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        AccessibilityManager.shared.announceToVoiceOver(announcement, priority: .high)
                    }
                }
            }
    }
}

// MARK: - Voice Control Support

extension View {
    /// Add voice control support with custom commands
    func voiceControlSupport(commands: [String]) -> some View {
        self.accessibilityInputLabels(commands)
    }
    
    /// Add voice control navigation support
    func voiceNavigationSupport(label: String) -> some View {
        self.accessibilityIdentifier(label)
            .accessibilityInputLabels([label])
    }
}

// MARK: - Switch Control Support

extension View {
    /// Optimize for Switch Control navigation
    func switchControlOptimized() -> some View {
        self.modifier(SwitchControlModifier())
    }
}

struct SwitchControlModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityAction(.default) {
                // Default action for switch control
            }
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
extension View {
    /// Add accessibility testing identifiers
    func accessibilityTestIdentifier(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
    }
    
    /// Log accessibility information for testing
    func logAccessibilityInfo() -> some View {
        self.onAppear {
            print("Accessibility Info: VoiceOver enabled: \(AccessibilityManager.shared.isVoiceOverEnabled)")
            print("Accessibility Info: Reduce Motion enabled: \(AccessibilityManager.shared.isReduceMotionEnabled)")
            print("Accessibility Info: High Contrast enabled: \(AccessibilityManager.shared.isHighContrastEnabled)")
        }
    }
}
#endif

// MARK: - Custom Accessibility Traits

extension AccessibilityTraits {
    static let isLearningContent = AccessibilityTraits.isStaticText
    static let isInteractiveContent = AccessibilityTraits.allowsDirectInteraction
    static let isGameElement = AccessibilityTraits.playsSound
}