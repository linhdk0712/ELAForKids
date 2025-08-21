import SwiftUI
import Combine

// MARK: - Reward System
@MainActor
final class RewardSystem: ObservableObject {
    
    // MARK: - Properties
    @Published var isShowingReward = false
    @Published var currentReward: RewardEvent?
    @Published var rewardQueue: [RewardEvent] = []
    
    private let animationService: RewardAnimationService
    private let soundManager: SoundEffectManager
    private let hapticManager: HapticFeedbackManager
    private let progressTracker: ProgressTrackingProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var isProcessingReward = false
    
    // MARK: - Initialization
    init(
        animationService: RewardAnimationService = RewardAnimationService(),
        soundManager: SoundEffectManager = SoundEffectManager(),
        hapticManager: HapticFeedbackManager = HapticFeedbackManager(),
        progressTracker: ProgressTrackingProtocol
    ) {
        self.animationService = animationService
        self.soundManager = soundManager
        self.hapticManager = hapticManager
        self.progressTracker = progressTracker
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Process session result and trigger appropriate rewards
    func processSessionResult(_ sessionResult: SessionResult) async {
        var rewards: [RewardEvent] = []
        
        // Check for perfect score
        if sessionResult.isPerfectScore {
            rewards.append(.perfectScore(sessionResult.score))
        }
        
        // Check for high accuracy
        else if sessionResult.accuracy >= 0.9 {
            rewards.append(.highAccuracy(sessionResult.accuracy))
        }
        
        // Check for first attempt success
        if sessionResult.attempts == 1 && sessionResult.accuracy >= 0.8 {
            rewards.append(.firstAttemptSuccess)
        }
        
        // Check for speed bonus
        let expectedTime = calculateExpectedTime(for: sessionResult.difficulty, wordCount: sessionResult.totalWords)
        if sessionResult.timeSpent < expectedTime * 0.8 {
            let bonus = calculateSpeedBonus(sessionResult.timeSpent, expected: expectedTime)
            rewards.append(.speedBonus(bonus))
        }
        
        // Check for streak updates
        do {
            let streakManager = ProgressTrackingFactory.shared.getStreakManager()
            let newStreak = try await streakManager.updateStreak(
                userId: sessionResult.userId,
                isSuccess: sessionResult.qualifiesForStreak
            )
            
            // Check for streak milestones
            if let milestone = getStreakMilestone(for: newStreak) {
                rewards.append(.streakMilestone(newStreak, milestone))
            }
        } catch {
            print("Error updating streak: \(error)")
        }
        
        // Check for achievements
        let newAchievements = await checkForNewAchievements(sessionResult)
        for achievement in newAchievements {
            rewards.append(.achievementUnlocked(achievement))
        }
        
        // Check for level up
        if let levelUp = await checkForLevelUp(sessionResult) {
            rewards.append(.levelUp(levelUp.newLevel, levelUp.title))
        }
        
        // Queue rewards for display
        queueRewards(rewards)
    }
    
    /// Process daily goal completion
    func processDailyGoalCompletion(_ goalType: GoalType) {
        let reward = RewardEvent.goalCompletion(goalType)
        queueRewards([reward])
    }
    
    /// Process improvement milestone
    func processImprovement(improvementPercent: Int) {
        let reward = RewardEvent.improvement(improvementPercent)
        queueRewards([reward])
    }
    
    /// Process consistency milestone
    func processConsistency(days: Int) {
        let reward = RewardEvent.consistency(days)
        queueRewards([reward])
    }
    
    /// Manually trigger a reward (for testing or special events)
    func triggerReward(_ reward: RewardEvent) {
        queueRewards([reward])
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind animation service state
        animationService.$isShowingReward
            .assign(to: \.isShowingReward, on: self)
            .store(in: &cancellables)
        
        animationService.$currentRewardType
            .sink { [weak self] rewardType in
                if rewardType == nil && !self?.rewardQueue.isEmpty == true {
                    Task { @MainActor in
                        await self?.processNextReward()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func queueRewards(_ rewards: [RewardEvent]) {
        rewardQueue.append(contentsOf: rewards)
        
        if !isProcessingReward {
            Task {
                await processNextReward()
            }
        }
    }
    
    private func processNextReward() async {
        guard !rewardQueue.isEmpty, !isProcessingReward else { return }
        
        isProcessingReward = true
        let reward = rewardQueue.removeFirst()
        currentReward = reward
        
        await displayReward(reward)
        
        // Wait for animation to complete before processing next reward
        try? await Task.sleep(nanoseconds: 3_500_000_000) // 3.5 seconds
        
        isProcessingReward = false
        
        // Process next reward if queue is not empty
        if !rewardQueue.isEmpty {
            await processNextReward()
        }
    }
    
    private func displayReward(_ reward: RewardEvent) async {
        switch reward {
        case .perfectScore(let score):
            animationService.showPerfectScoreReward(score: score)
            soundManager.playRewardSound(.epic)
            hapticManager.playRewardHaptic(.perfectScore)
            
        case .highAccuracy(let accuracy):
            animationService.showHighAccuracyReward(accuracy: accuracy)
            soundManager.playRewardSound(.excellent)
            hapticManager.playRewardHaptic(.highAccuracy)
            
        case .firstAttemptSuccess:
            animationService.showFirstAttemptReward()
            soundManager.playRewardSound(.great)
            hapticManager.playRewardHaptic(.firstAttempt)
            
        case .speedBonus(let bonus):
            animationService.showSpeedBonusReward(timeBonus: bonus)
            soundManager.playRewardSound(.bonus)
            hapticManager.playRewardHaptic(.speedBonus)
            
        case .streakMilestone(let streak, let milestone):
            animationService.showStreakReward(streak: streak, milestone: milestone)
            soundManager.playStreakSound(streak: streak)
            hapticManager.playRewardHaptic(.streak(streak))
            
        case .achievementUnlocked(let achievement):
            animationService.showAchievementReward(achievement: achievement)
            soundManager.playRewardSound(getRewardSoundType(for: achievement.difficulty))
            hapticManager.playRewardHaptic(.achievement(achievement.difficulty))
            
        case .levelUp(let level, let title):
            animationService.showLevelUpReward(newLevel: level, levelTitle: title)
            soundManager.playRewardSound(.legendary)
            hapticManager.playRewardHaptic(.levelUp)
            
        case .goalCompletion(let goalType):
            animationService.showGoalCompletionReward(goalType: goalType)
            soundManager.playRewardSound(.good)
            hapticManager.playRewardHaptic(.goalCompletion)
            
        case .improvement(let percent):
            animationService.showImprovementReward(improvementPercent: percent)
            soundManager.playRewardSound(.great)
            hapticManager.playRewardHaptic(.improvement)
            
        case .consistency(let days):
            animationService.showConsistencyReward(days: days)
            soundManager.playRewardSound(.excellent)
            hapticManager.playRewardHaptic(.consistency)
        }
        
        // Play encouragement voice if appropriate
        playEncouragementVoice(for: reward)
    }
    
    private func playEncouragementVoice(for reward: RewardEvent) {
        let encouragementType: EncouragementType
        
        switch reward {
        case .perfectScore, .achievementUnlocked:
            encouragementType = .perfect
        case .highAccuracy, .firstAttemptSuccess:
            encouragementType = .greatJob
        case .speedBonus, .improvement:
            encouragementType = .keepGoing
        case .streakMilestone, .levelUp:
            encouragementType = .almostThere
        case .goalCompletion, .consistency:
            encouragementType = .greatJob
        }
        
        soundManager.playEncouragement(encouragementType)
    }
    
    private func calculateExpectedTime(for difficulty: DifficultyLevel, wordCount: Int) -> TimeInterval {
        let baseTimePerWord: TimeInterval
        
        switch difficulty {
        case .grade1:
            baseTimePerWord = 3.0 // 3 seconds per word
        case .grade2:
            baseTimePerWord = 2.5
        case .grade3:
            baseTimePerWord = 2.0
        case .grade4:
            baseTimePerWord = 1.8
        case .grade5:
            baseTimePerWord = 1.5
        }
        
        return TimeInterval(wordCount) * baseTimePerWord
    }
    
    private func calculateSpeedBonus(_ actualTime: TimeInterval, expected: TimeInterval) -> Int {
        let timeSaved = expected - actualTime
        let bonusMultiplier = timeSaved / expected
        return Int(bonusMultiplier * 50) // Up to 50 bonus points
    }
    
    private func getStreakMilestone(for streak: Int) -> StreakMilestone? {
        let milestones = [3, 5, 7, 10, 15, 20, 25, 30, 50, 100]
        
        guard milestones.contains(streak) else { return nil }
        
        return StreakMilestone(
            streak: streak,
            title: getStreakMilestoneTitle(for: streak),
            description: getStreakMilestoneDescription(for: streak),
            reward: getStreakMilestoneReward(for: streak)
        )
    }
    
    private func getStreakMilestoneTitle(for streak: Int) -> String {
        switch streak {
        case 3:
            return "Khởi đầu tốt!"
        case 5:
            return "Kiên trì!"
        case 7:
            return "Một tuần hoàn hảo!"
        case 10:
            return "Thành thạo!"
        case 15:
            return "Chuyên gia nhỏ!"
        case 20:
            return "Siêu sao đọc!"
        case 25:
            return "Bậc thầy ngôn ngữ!"
        case 30:
            return "Huyền thoại!"
        case 50:
            return "Vô địch toàn quốc!"
        case 100:
            return "Thần đồng tiếng Việt!"
        default:
            return "Thành tích tuyệt vời!"
        }
    }
    
    private func getStreakMilestoneDescription(for streak: Int) -> String {
        return "Bé đã đọc đúng \(streak) lần liên tiếp!"
    }
    
    private func getStreakMilestoneReward(for streak: Int) -> StreakReward {
        let bonusPoints = streak * 10
        let badge = getStreakBadge(for: streak)
        let effect = streak >= 20 ? "fireworks" : "confetti"
        
        return StreakReward(bonusPoints: bonusPoints, badge: badge, specialEffect: effect)
    }
    
    private func getStreakBadge(for streak: Int) -> String {
        switch streak {
        case 3: return "🔥"
        case 5: return "⭐"
        case 7: return "🏆"
        case 10: return "💎"
        case 15: return "👑"
        case 20: return "🌟"
        case 25: return "🎖️"
        case 30: return "🏅"
        case 50: return "🥇"
        case 100: return "🎯"
        default: return "🎉"
        }
    }
    
    private func checkForNewAchievements(_ sessionResult: SessionResult) async -> [Achievement] {
        // This would integrate with the achievement system
        // For now, return empty array
        return []
    }
    
    private func checkForLevelUp(_ sessionResult: SessionResult) async -> (newLevel: Int, title: String)? {
        // This would integrate with the user score system
        // For now, return nil
        return nil
    }
    
    private func getRewardSoundType(for difficulty: AchievementDifficulty) -> RewardSoundType {
        switch difficulty {
        case .bronze:
            return .good
        case .silver:
            return .great
        case .gold:
            return .excellent
        case .platinum:
            return .epic
        case .diamond:
            return .legendary
        }
    }
}

// MARK: - Reward Event Types
enum RewardEvent: Equatable {
    case perfectScore(Int)
    case highAccuracy(Float)
    case firstAttemptSuccess
    case speedBonus(Int)
    case streakMilestone(Int, StreakMilestone)
    case achievementUnlocked(Achievement)
    case levelUp(Int, String)
    case goalCompletion(GoalType)
    case improvement(Int)
    case consistency(Int)
    
    var priority: Int {
        switch self {
        case .levelUp, .achievementUnlocked:
            return 1 // Highest priority
        case .perfectScore, .streakMilestone:
            return 2
        case .goalCompletion, .improvement:
            return 3
        case .highAccuracy, .firstAttemptSuccess:
            return 4
        case .speedBonus, .consistency:
            return 5 // Lowest priority
        }
    }
    
    var displayDuration: TimeInterval {
        switch self {
        case .levelUp, .achievementUnlocked:
            return 4.0
        case .perfectScore, .streakMilestone:
            return 3.5
        case .goalCompletion:
            return 3.0
        default:
            return 2.5
        }
    }
}

// MARK: - Streak Milestone Model
struct StreakMilestone: Equatable {
    let streak: Int
    let title: String
    let description: String
    let reward: StreakReward
}

// MARK: - Streak Reward Model
struct StreakReward: Equatable {
    let bonusPoints: Int
    let badge: String
    let specialEffect: String
}