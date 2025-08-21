import SwiftUI
import AVFoundation
import CoreHaptics

// MARK: - Reward Animation Service
@MainActor
final class RewardAnimationService: ObservableObject {
    
    // MARK: - Properties
    @Published var isShowingReward = false
    @Published var currentRewardType: RewardType?
    @Published var rewardMessage = ""
    @Published var confettiTrigger = 0
    @Published var starBurstTrigger = 0
    @Published var fireworksTrigger = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var hapticEngine: CHHapticEngine?
    private var soundEnabled = true
    private var hapticsEnabled = true
    
    // MARK: - Initialization
    init() {
        setupHapticEngine()
        loadSoundSettings()
    }
    
    // MARK: - Public Methods
    
    /// Show reward animation for achievement unlock
    func showAchievementReward(achievement: Achievement) {
        let rewardType = RewardType.achievement(achievement.difficulty)
        showReward(
            type: rewardType,
            message: "🎉 \(achievement.title)!\n\(achievement.description)",
            duration: 3.0
        )
    }
    
    /// Show reward animation for perfect score
    func showPerfectScoreReward(score: Int) {
        showReward(
            type: .perfectScore,
            message: "🌟 Hoàn hảo!\nĐiểm số: \(score)",
            duration: 2.5
        )
    }
    
    /// Show reward animation for streak milestone
    func showStreakReward(streak: Int, milestone: StreakMilestone) {
        let rewardType = RewardType.streak(streak)
        showReward(
            type: rewardType,
            message: "🔥 \(milestone.title)!\n\(milestone.description)",
            duration: 3.0
        )
    }
    
    /// Show reward animation for level up
    func showLevelUpReward(newLevel: Int, levelTitle: String) {
        showReward(
            type: .levelUp,
            message: "⬆️ Lên cấp \(newLevel)!\n\(levelTitle)",
            duration: 2.5
        )
    }
    
    /// Show reward animation for goal completion
    func showGoalCompletionReward(goalType: GoalType) {
        let rewardType = RewardType.goalCompletion(goalType)
        let message = getGoalCompletionMessage(goalType: goalType)
        showReward(
            type: rewardType,
            message: message,
            duration: 2.0
        )
    }
    
    /// Show reward animation for high accuracy
    func showHighAccuracyReward(accuracy: Float) {
        let accuracyPercent = Int(accuracy * 100)
        showReward(
            type: .highAccuracy,
            message: "🎯 Độ chính xác cao!\n\(accuracyPercent)%",
            duration: 2.0
        )
    }
    
    /// Show reward animation for speed bonus
    func showSpeedBonusReward(timeBonus: Int) {
        showReward(
            type: .speedBonus,
            message: "⚡ Thưởng tốc độ!\n+\(timeBonus) điểm",
            duration: 1.5
        )
    }
    
    /// Show reward animation for first attempt success
    func showFirstAttemptReward() {
        showReward(
            type: .firstAttempt,
            message: "👏 Lần đầu đã đúng!\nTuyệt vời!",
            duration: 2.0
        )
    }
    
    /// Show reward animation for improvement
    func showImprovementReward(improvementPercent: Int) {
        showReward(
            type: .improvement,
            message: "📈 Tiến bộ rõ rệt!\n+\(improvementPercent)% so với trước",
            duration: 2.0
        )
    }
    
    /// Show reward animation for consistency
    func showConsistencyReward(days: Int) {
        showReward(
            type: .consistency,
            message: "📅 Học đều đặn!\n\(days) ngày liên tiếp",
            duration: 2.0
        )
    }
    
    // MARK: - Settings
    
    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "RewardSoundEnabled")
    }
    
    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "RewardHapticsEnabled")
    }
    
    // MARK: - Private Methods
    
    private func showReward(type: RewardType, message: String, duration: TimeInterval) {
        // Set reward properties
        currentRewardType = type
        rewardMessage = message
        
        // Trigger appropriate animation
        triggerAnimation(for: type)
        
        // Play sound effect
        playRewardSound(for: type)
        
        // Trigger haptic feedback
        triggerHapticFeedback(for: type)
        
        // Show reward overlay
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isShowingReward = true
        }
        
        // Hide reward after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.isShowingReward = false
            }
            
            // Clear reward data after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentRewardType = nil
                self.rewardMessage = ""
            }
        }
    }
    
    private func triggerAnimation(for type: RewardType) {
        switch type {
        case .achievement(.platinum), .achievement(.diamond), .perfectScore, .levelUp:
            fireworksTrigger += 1
        case .achievement(.gold), .streak(let days) where days >= 7:
            starBurstTrigger += 1
        default:
            confettiTrigger += 1
        }
    }
    
    private func playRewardSound(for type: RewardType) {
        guard soundEnabled else { return }
        
        let soundName = getSoundName(for: type)
        playSound(named: soundName)
    }
    
    private func getSoundName(for type: RewardType) -> String {
        switch type {
        case .achievement(.diamond), .perfectScore:
            return "reward_epic"
        case .achievement(.platinum), .levelUp:
            return "reward_legendary"
        case .achievement(.gold), .streak(let days) where days >= 7:
            return "reward_excellent"
        case .achievement(.silver), .highAccuracy:
            return "reward_great"
        case .achievement(.bronze), .goalCompletion, .firstAttempt:
            return "reward_good"
        case .speedBonus, .improvement, .consistency:
            return "reward_bonus"
        default:
            return "reward_success"
        }
    }
    
    private func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            // Fallback to system sound if custom sound not found
            playSystemSound()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.7
            audioPlayer?.play()
        } catch {
            print("Error playing reward sound: \(error)")
            playSystemSound()
        }
    }
    
    private func playSystemSound() {
        // Use system sound as fallback
        AudioServicesPlaySystemSound(1016) // Success sound
    }
    
    private func triggerHapticFeedback(for type: RewardType) {
        guard hapticsEnabled else { return }
        
        switch type {
        case .achievement(.diamond), .perfectScore, .levelUp:
            playComplexHaptic(intensity: 1.0, sharpness: 1.0, duration: 0.8)
        case .achievement(.platinum), .achievement(.gold):
            playComplexHaptic(intensity: 0.8, sharpness: 0.8, duration: 0.6)
        case .streak(let days) where days >= 7:
            playRepeatingHaptic(count: 3, intensity: 0.7)
        default:
            playSimpleHaptic(intensity: 0.6)
        }
    }
    
    private func playSimpleHaptic(intensity: Float) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred(intensity: CGFloat(intensity))
    }
    
    private func playRepeatingHaptic(count: Int, intensity: Float) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred(intensity: CGFloat(intensity))
            }
        }
    }
    
    private func playComplexHaptic(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard let hapticEngine = hapticEngine else {
            playSimpleHaptic(intensity: intensity)
            return
        }
        
        do {
            let hapticEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0,
                duration: duration
            )
            
            let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
        } catch {
            print("Error playing complex haptic: \(error)")
            playSimpleHaptic(intensity: intensity)
        }
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Error setting up haptic engine: \(error)")
        }
    }
    
    private func loadSoundSettings() {
        soundEnabled = UserDefaults.standard.bool(forKey: "RewardSoundEnabled")
        hapticsEnabled = UserDefaults.standard.bool(forKey: "RewardHapticsEnabled")
        
        // Default to enabled if not set
        if !UserDefaults.standard.object(forKey: "RewardSoundEnabled") != nil {
            soundEnabled = true
        }
        if !UserDefaults.standard.object(forKey: "RewardHapticsEnabled") != nil {
            hapticsEnabled = true
        }
    }
    
    private func getGoalCompletionMessage(goalType: GoalType) -> String {
        switch goalType {
        case .dailySessions:
            return "✅ Hoàn thành mục tiêu!\nĐủ số buổi học hôm nay"
        case .dailyTime:
            return "⏰ Hoàn thành mục tiêu!\nĐủ thời gian học hôm nay"
        case .weeklyGoal:
            return "📅 Hoàn thành mục tiêu!\nĐủ số buổi học tuần này"
        case .accuracyGoal:
            return "🎯 Hoàn thành mục tiêu!\nĐạt độ chính xác mong muốn"
        case .streakGoal:
            return "🔥 Hoàn thành mục tiêu!\nDuy trì chuỗi học tập"
        case .custom(let title):
            return "🌟 Hoàn thành mục tiêu!\n\(title)"
        }
    }
}

// MARK: - Reward Types
enum RewardType: Equatable {
    case achievement(AchievementDifficulty)
    case perfectScore
    case streak(Int)
    case levelUp
    case goalCompletion(GoalType)
    case highAccuracy
    case speedBonus
    case firstAttempt
    case improvement
    case consistency
    
    var animationType: AnimationType {
        switch self {
        case .achievement(.diamond), .perfectScore, .levelUp:
            return .fireworks
        case .achievement(.platinum), .achievement(.gold), .streak(let days) where days >= 7:
            return .starBurst
        default:
            return .confetti
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .achievement(let difficulty):
            return difficulty.color
        case .perfectScore:
            return .yellow
        case .streak:
            return .orange
        case .levelUp:
            return .purple
        case .goalCompletion:
            return .green
        case .highAccuracy:
            return .blue
        case .speedBonus:
            return .red
        case .firstAttempt:
            return .mint
        case .improvement:
            return .indigo
        case .consistency:
            return .teal
        }
    }
    
    var secondaryColor: Color {
        return primaryColor.opacity(0.6)
    }
}

// MARK: - Goal Types
enum GoalType: Equatable {
    case dailySessions
    case dailyTime
    case weeklyGoal
    case accuracyGoal
    case streakGoal
    case custom(String)
}

// MARK: - Animation Types
enum AnimationType {
    case confetti
    case starBurst
    case fireworks
}

// MARK: - Achievement Difficulty Extension
extension AchievementDifficulty {
    var color: Color {
        switch self {
        case .bronze:
            return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum:
            return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .diamond:
            return Color(red: 0.7, green: 0.9, blue: 1.0)
        }
    }
}