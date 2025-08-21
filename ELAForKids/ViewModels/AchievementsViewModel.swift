import Foundation
import SwiftUI
import Combine

// MARK: - Achievements View Model
@MainActor
final class AchievementsViewModel: BaseViewModel<AchievementsState, AchievementsAction> {
    
    @Injected(AchievementProtocol.self) private var achievementManager: AchievementProtocol
    @Injected(UserScoreRepositoryProtocol.self) private var userScoreRepository: UserScoreRepositoryProtocol
    @Injected(ErrorHandler.self) private var errorHandler: ErrorHandler
    
    private var cancellables = Set<AnyCancellable>()
    private let currentUserId = "current_user" // This should come from user management
    
    override init() {
        super.init(initialState: AchievementsState())
        setupNotificationObservers()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    override func send(_ action: AchievementsAction) {
        switch action {
        case .loadAchievements:
            handleLoadAchievements()
            
        case .filterByCategory(let category):
            handleFilterByCategory(category)
            
        case .refreshAchievements:
            handleRefreshAchievements()
            
        case .setError(let error):
            updateState { state in
                state.error = error
                state.isLoading = false
            }
            
        case .clearError:
            updateState { state in
                state.error = nil
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleLoadAchievements() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }
        
        Task {
            do {
                async let allAchievements = achievementManager.getAvailableAchievements()
                async let userAchievements = achievementManager.getUserAchievements(userId: currentUserId)
                async let recentAchievements = achievementManager.getRecentAchievements(userId: currentUserId, limit: 10)
                async let nextAchievable = achievementManager.getNextAchievableAchievements(userId: currentUserId, limit: 5)
                async let statistics = achievementManager.getAchievementStatistics(userId: currentUserId)
                
                let (achievements, userAchs, recent, next, stats) = try await (
                    allAchievements, userAchievements, recentAchievements, nextAchievable, statistics
                )
                
                await MainActor.run {
                    updateState { state in
                        state.allAchievements = achievements
                        state.userAchievements = userAchs
                        state.recentAchievements = recent
                        state.nextAchievable = next
                        state.statistics = stats
                        state.filteredAchievements = achievements.filter { $0.category == state.selectedCategory }
                        state.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    send(.setError(error as? AppError ?? .unknown))
                }
            }
        }
    }
}   
 
    private func handleFilterByCategory(_ category: AchievementCategory) {
        updateState { state in
            state.selectedCategory = category
            state.filteredAchievements = state.allAchievements.filter { $0.category == category }
        }
    }
    
    private func handleRefreshAchievements() {
        handleLoadAchievements()
    }
    
    // MARK: - Helper Methods
    
    /// Check if achievement is unlocked
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        return state.userAchievements.contains { $0.achievementId == achievementId }
    }
    
    /// Check if badge is unlocked
    func isBadgeUnlocked(_ badgeId: String) -> Bool {
        return state.userAchievements.contains { userAchievement in
            if let achievement = state.allAchievements.first(where: { $0.id == userAchievement.achievementId }) {
                return achievement.badge.id == badgeId
            }
            return false
        }
    }
    
    /// Get badge unlock date
    func getBadgeUnlockDate(_ badgeId: String) -> Date? {
        return state.userAchievements.first { userAchievement in
            if let achievement = state.allAchievements.first(where: { $0.id == userAchievement.achievementId }) {
                return achievement.badge.id == badgeId
            }
            return false
        }?.unlockedAt
    }
    
    /// Get achievement progress
    func getAchievementProgress(_ achievementId: String) -> AchievementProgress? {
        // This would typically fetch from the achievement manager
        // For now, return a mock progress
        guard let achievement = state.allAchievements.first(where: { $0.id == achievementId }),
              !isAchievementUnlocked(achievementId) else {
            return nil
        }
        
        // Mock progress calculation
        let mockCurrent = Int.random(in: 0..<achievement.requirements.target)
        return AchievementProgress(
            current: mockCurrent,
            target: achievement.requirements.target,
            percentage: Float(mockCurrent) / Float(achievement.requirements.target),
            milestones: []
        )
    }
    
    /// Get achievement by ID
    func getAchievement(by id: String) -> Achievement? {
        return state.allAchievements.first { $0.id == id }
    }
    
    /// Get filtered achievements for current category
    var filteredAchievements: [Achievement] {
        return state.filteredAchievements
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .sink { [weak self] notification in
                if let achievementNotification = notification.object as? AchievementNotification {
                    Task { @MainActor in
                        self?.handleNewAchievementUnlocked(achievementNotification)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleNewAchievementUnlocked(_ notification: AchievementNotification) {
        // Refresh achievements to show the newly unlocked one
        send(.refreshAchievements)
        
        // Show celebration UI (this could trigger a separate notification for the UI)
        showAchievementCelebration(notification)
    }
    
    private func showAchievementCelebration(_ notification: AchievementNotification) {
        // This would trigger UI celebration effects
        // For now, just post another notification that the UI can observe
        NotificationCenter.default.post(
            name: .showAchievementCelebration,
            object: notification
        )
    }
}

// MARK: - Achievements State
struct AchievementsState {
    var allAchievements: [Achievement] = []
    var userAchievements: [UserAchievement] = []
    var filteredAchievements: [Achievement] = []
    var recentAchievements: [UserAchievement] = []
    var nextAchievable: [AchievementWithProgress] = []
    var statistics: AchievementStatistics = AchievementStatistics(
        totalAchievements: 0,
        unlockedAchievements: 0,
        completionPercentage: 0.0,
        achievementPoints: 0,
        categoryStats: [:],
        difficultyStats: [:],
        recentUnlocks: []
    )
    var selectedCategory: AchievementCategory = .reading
    var isLoading: Bool = false
    var error: AppError?
}

// MARK: - Achievements Actions
enum AchievementsAction {
    case loadAchievements
    case filterByCategory(AchievementCategory)
    case refreshAchievements
    case setError(AppError)
    case clearError
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let showAchievementCelebration = Notification.Name("showAchievementCelebration")
}