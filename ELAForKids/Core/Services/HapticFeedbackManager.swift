import UIKit
import CoreHaptics

// MARK: - Haptic Feedback Manager
final class HapticFeedbackManager: ObservableObject {
    
    // MARK: - Properties
    private var hapticEngine: CHHapticEngine?
    private var hapticsEnabled = true
    private var hapticIntensity: Float = 1.0
    
    // MARK: - Initialization
    init() {
        loadSettings()
        setupHapticEngine()
    }
    
    // MARK: - Public Methods
    
    /// Play haptic feedback for reward
    func playRewardHaptic(_ type: RewardHapticType) {
        guard hapticsEnabled && supportsHaptics else { return }
        
        switch type {
        case .achievement(.diamond), .perfectScore, .levelUp:
            playComplexPattern(.celebration)
        case .achievement(.platinum), .achievement(.gold):
            playComplexPattern(.success)
        case .streak(let days) where days >= 7:
            playRepeatingHaptic(count: 3, intensity: 0.8, interval: 0.15)
        case .achievement(.silver), .achievement(.bronze):
            playSimpleHaptic(.medium, intensity: 0.7)
        default:
            playSimpleHaptic(.light, intensity: 0.6)
        }
    }
    
    /// Play haptic feedback for UI interactions
    func playUIHaptic(_ type: UIHapticType) {
        guard hapticsEnabled && supportsHaptics else { return }
        
        switch type {
        case .buttonTap:
            playSimpleHaptic(.light, intensity: 0.5)
        case .success:
            playNotificationHaptic(.success)
        case .error:
            playNotificationHaptic(.error)
        case .warning:
            playNotificationHaptic(.warning)
        case .selection:
            playSelectionHaptic()
        case .swipe:
            playSimpleHaptic(.light, intensity: 0.3)
        case .longPress:
            playSimpleHaptic(.medium, intensity: 0.8)
        }
    }
    
    /// Play haptic feedback for reading accuracy
    func playAccuracyHaptic(accuracy: Float) {
        guard hapticsEnabled && supportsHaptics else { return }
        
        switch accuracy {
        case 0.95...1.0:
            playComplexPattern(.excellent)
        case 0.85..<0.95:
            playComplexPattern(.good)
        case 0.70..<0.85:
            playSimpleHaptic(.medium, intensity: 0.6)
        default:
            playComplexPattern(.needsImprovement)
        }
    }
    
    /// Play haptic feedback for progress milestones
    func playProgressHaptic(progress: Float) {
        guard hapticsEnabled && supportsHaptics else { return }
        
        let milestones: [Float] = [0.25, 0.5, 0.75, 1.0]
        
        for milestone in milestones {
            if abs(progress - milestone) < 0.01 {
                let intensity = milestone * hapticIntensity
                playSimpleHaptic(.medium, intensity: intensity)
                break
            }
        }
    }
    
    /// Play custom haptic pattern
    func playCustomPattern(_ pattern: HapticPattern) {
        guard hapticsEnabled && supportsHaptics else { return }
        playComplexPattern(pattern)
    }
    
    // MARK: - Settings
    
    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "HapticFeedbackEnabled")
        
        if enabled {
            setupHapticEngine()
        } else {
            hapticEngine?.stop()
        }
    }
    
    func setHapticIntensity(_ intensity: Float) {
        hapticIntensity = max(0.0, min(1.0, intensity))
        UserDefaults.standard.set(hapticIntensity, forKey: "HapticFeedbackIntensity")
    }
    
    func isHapticsEnabled() -> Bool {
        return hapticsEnabled && supportsHaptics
    }
    
    func getHapticIntensity() -> Float {
        return hapticIntensity
    }
    
    // MARK: - Private Methods
    
    private var supportsHaptics: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    private func setupHapticEngine() {
        guard supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Error restarting haptic engine: \(error)")
                }
            }
            
            // Handle engine stop
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
            
        } catch {
            print("Error setting up haptic engine: \(error)")
        }
    }
    
    private func playSimpleHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: Float) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred(intensity: CGFloat(intensity * hapticIntensity))
    }
    
    private func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    private func playSelectionHaptic() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    private func playRepeatingHaptic(count: Int, intensity: Float, interval: TimeInterval) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                self.playSimpleHaptic(.medium, intensity: intensity)
            }
        }
    }
    
    private func playComplexPattern(_ pattern: HapticPattern) {
        guard let hapticEngine = hapticEngine else {
            // Fallback to simple haptic
            playSimpleHaptic(.medium, intensity: 0.7)
            return
        }
        
        do {
            let hapticPattern = try createHapticPattern(pattern)
            let player = try hapticEngine.makePlayer(with: hapticPattern)
            try player.start(atTime: 0)
        } catch {
            print("Error playing complex haptic pattern: \(error)")
            // Fallback to simple haptic
            playSimpleHaptic(.medium, intensity: 0.7)
        }
    }
    
    private func createHapticPattern(_ pattern: HapticPattern) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        switch pattern {
        case .celebration:
            // Celebration pattern: Strong burst followed by gentle pulses
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0
            ))
            
            for i in 1...3 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: TimeInterval(i) * 0.2
                ))
            }
            
        case .success:
            // Success pattern: Two strong pulses
            for i in 0..<2 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: TimeInterval(i) * 0.15
                ))
            }
            
        case .excellent:
            // Excellent pattern: Rising intensity
            for i in 0..<4 {
                let intensity = (0.4 + Float(i) * 0.2) * hapticIntensity
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: TimeInterval(i) * 0.1
                ))
            }
            
        case .good:
            // Good pattern: Steady rhythm
            for i in 0..<3 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: TimeInterval(i) * 0.12
                ))
            }
            
        case .needsImprovement:
            // Needs improvement pattern: Gentle, encouraging
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: 0.5
            ))
            
        case .heartbeat:
            // Heartbeat pattern: Two quick pulses
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ))
            
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.1
            ))
            
        case .wave:
            // Wave pattern: Continuous wave-like motion
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0,
                duration: 1.0
            ))
            
            // Add intensity curve
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.3),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.5, value: 0.8),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 1.0, value: 0.2)
                ],
                relativeTime: 0
            )
            
            return try CHHapticPattern(events: events, parameterCurves: [curve])
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func loadSettings() {
        hapticsEnabled = UserDefaults.standard.object(forKey: "HapticFeedbackEnabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "HapticFeedbackIntensity") as? Float ?? 1.0
    }
}

// MARK: - Haptic Type Enums

enum RewardHapticType {
    case achievement(AchievementDifficulty)
    case perfectScore
    case streak(Int)
    case levelUp
    case goalCompletion
    case highAccuracy
    case speedBonus
    case firstAttempt
    case improvement
    case consistency
}

enum UIHapticType {
    case buttonTap
    case success
    case error
    case warning
    case selection
    case swipe
    case longPress
}

enum HapticPattern {
    case celebration
    case success
    case excellent
    case good
    case needsImprovement
    case heartbeat
    case wave
}