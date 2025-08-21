import SwiftUI
import Combine

// MARK: - User Profile View Model
@MainActor
final class UserProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfileData = UserProfileData.default
    @Published var topAchievements: [Achievement] = []
    @Published var recentAchievements: [Achievement] = []
    @Published var weeklyProgress: [WeeklyProgressData] = []
    @Published var accuracyHistory: [AccuracyHistoryData] = []
    @Published var categoryProgress: [CategoryProgressData] = []
    @Published var nextStreakMilestone: StreakMilestone?
    @Published var dailySessionsCompleted: Int = 0
    @Published var dailyTimeSpent: Int = 0
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let progressTracker = ProgressTrackingFactory.shared.getProgressTracker()
    private let userScoreRepository = ProgressTrackingFactory.shared.getUserScoreRepository()
    private let userId = "current_user" // This would come from authentication
    
    // MARK: - Public Methods
    
    func loadUserProfile() {
        isLoading = true
        
        Task {
            do {
                // Load user basic data
                await loadUserBasicData()
                
                // Load achievements
                await loadAchievements()
                
                // Load progress data
                await loadProgressData()
                
                // Load performance history
                await loadPerformanceHistory()
                
                // Load daily progress
                await loadDailyProgress()
                
                isLoading = false
            } catch {
                print("Error loading user profile: \(error)")
                isLoading = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUserBasicData() async {
        do {
            let userScore = try await userScoreRepository.getUserScore(userId: userId)
            let userStats = try await userScoreRepository.getUserStatistics(userId: userId)
            let learningGoals = try await progressTracker.getLearningGoals(userId: userId)
            let streak = try await progressTracker.getLearningStreak(userId: userId)
            
            userProfile = UserProfileData(
                id: userScore.id,
                name: userScore.userName,
                grade: 2, // This would come from user settings
                level: userScore.level,
                totalScore: userScore.totalScore,
                experience: userScore.experience,
                experienceToNextLevel: userScore.experienceToNextLevel,
                levelProgress: userScore.levelProgress,
                currentStreak: streak.currentStreak,
                bestStreak: streak.longestStreak,
                averageAccuracy: Float(userStats.averageAccuracy),
                completedExercises: userStats.totalSessions,
                totalTimeSpent: userStats.totalTimeSpent,
                dailySessionGoal: learningGoals.dailySessionGoal,
                dailyTimeGoal: Int(learningGoals.dailyTimeGoal / 60), // Convert to minutes
                accuracyGoal: Int(learningGoals.accuracyGoal * 100), // Convert to percentage
                avatarURL: generateAvatarURL(for: userScore.userName),
                joinedDate: Date(), // This would come from user data
                lastActiveDate: Date()
            )
            
        } catch {
            print("Error loading user basic data: \(error)")
            // Use default data
        }
    }
    
    private func loadAchievements() async {
        // This would load actual achievements from the achievement system
        // For now, create sample achievements
        let sampleAchievements = [
            Achievement(
                id: "first_read",
                title: "Lần đầu đọc",
                description: "Hoàn thành bài đọc đầu tiên",
                category: .reading,
                difficulty: .bronze,
                requirementType: .readSessions,
                requirementTarget: 1
            ),
            Achievement(
                id: "perfect_score",
                title: "Điểm số hoàn hảo",
                description: "Đạt 100% độ chính xác",
                category: .accuracy,
                difficulty: .gold,
                requirementType: .perfectScores,
                requirementTarget: 1
            ),
            Achievement(
                id: "streak_7",
                title: "Học liên tục 7 ngày",
                description: "Học liên tục trong 1 tuần",
                category: .streak,
                difficulty: .silver,
                requirementType: .consecutiveDays,
                requirementTarget: 7
            ),
            Achievement(
                id: "speed_reader",
                title: "Đọc nhanh",
                description: "Đọc trên 80 từ/phút",
                category: .speed,
                difficulty: .bronze,
                requirementType: .readingSpeed,
                requirementTarget: 80
            ),
            Achievement(
                id: "accuracy_master",
                title: "Bậc thầy chính xác",
                description: "Đạt độ chính xác trung bình 90%",
                category: .accuracy,
                difficulty: .platinum,
                requirementType: .averageAccuracy,
                requirementTarget: 90
            )
        ]
        
        // Simulate some achievements as unlocked
        for (index, achievement) in sampleAchievements.enumerated() {
            if index < 3 {
                achievement.unlock()
            }
        }
        
        topAchievements = sampleAchievements.filter { $0.isUnlocked }
        recentAchievements = Array(topAchievements.prefix(3))
        
        // Set next streak milestone
        nextStreakMilestone = getNextStreakMilestone(currentStreak: userProfile.currentStreak)
    }
    
    private func loadProgressData() async {
        do {
            let weeklyProgress = try await progressTracker.getUserProgress(userId: userId, period: .weekly)
            
            // Generate weekly progress data
            let calendar = Calendar.current
            let today = Date()
            
            self.weeklyProgress = (0..<7).compactMap { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
                
                // Find daily progress for this date
                let dailyProgress = weeklyProgress.dailyProgress.first { progress in
                    calendar.isDate(progress.date, inSameDayAs: date)
                }
                
                return WeeklyProgressData(
                    date: date,
                    score: dailyProgress?.scoreEarned ?? 0
                )
            }.reversed()
            
            // Generate category progress
            categoryProgress = ExerciseCategory.allCases.map { category in
                CategoryProgressData(
                    category: category,
                    accuracy: Float.random(in: 0.7...0.95) // Mock data
                )
            }
            
        } catch {
            print("Error loading progress data: \(error)")
            generateMockProgressData()
        }
    }
    
    private func loadPerformanceHistory() async {
        // Generate accuracy history for the past 30 days
        let calendar = Calendar.current
        let today = Date()
        
        accuracyHistory = (0..<30).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            
            return AccuracyHistoryData(
                date: date,
                accuracy: Double.random(in: 0.6...0.95) // Mock data - would come from actual sessions
            )
        }.reversed()
    }
    
    private func loadDailyProgress() async {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let dailyProgress = try await progressTracker.getUserProgress(userId: userId, period: .daily)
            
            // Calculate today's completed sessions and time
            let todayProgress = dailyProgress.dailyProgress.first { progress in
                Calendar.current.isDate(progress.date, inSameDayAs: today)
            }
            
            dailySessionsCompleted = todayProgress?.sessionsCompleted ?? 0
            dailyTimeSpent = Int((todayProgress?.timeSpent ?? 0) / 60) // Convert to minutes
            
        } catch {
            print("Error loading daily progress: \(error)")
            // Use mock data
            dailySessionsCompleted = 2
            dailyTimeSpent = 18
        }
    }
    
    private func generateMockProgressData() {
        // Generate mock weekly progress
        let calendar = Calendar.current
        let today = Date()
        
        weeklyProgress = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            return WeeklyProgressData(
                date: date,
                score: Int.random(in: 50...100)
            )
        }.reversed()
        
        // Generate mock category progress
        categoryProgress = ExerciseCategory.allCases.map { category in
            CategoryProgressData(
                category: category,
                accuracy: Float.random(in: 0.7...0.95)
            )
        }
    }
    
    private func generateAvatarURL(for name: String) -> URL? {
        // Generate a consistent avatar URL based on the user's name
        let seed = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "default"
        return URL(string: "https://api.dicebear.com/7.x/avataaars/png?seed=\(seed)")
    }
    
    private func getNextStreakMilestone(currentStreak: Int) -> StreakMilestone? {
        let milestones = [3, 7, 14, 30, 50, 100]
        
        for milestone in milestones {
            if currentStreak < milestone {
                return StreakMilestone(
                    streak: milestone,
                    title: getStreakMilestoneTitle(for: milestone),
                    description: getStreakMilestoneDescription(for: milestone),
                    reward: StreakReward(
                        bonusPoints: milestone * 10,
                        badge: getStreakBadge(for: milestone),
                        specialEffect: milestone >= 30 ? "fireworks" : "confetti"
                    )
                )
            }
        }
        
        return nil
    }
    
    private func getStreakMilestoneTitle(for streak: Int) -> String {
        switch streak {
        case 3:
            return "Khởi đầu tốt"
        case 7:
            return "Một tuần hoàn hảo"
        case 14:
            return "Hai tuần xuất sắc"
        case 30:
            return "Một tháng tuyệt vời"
        case 50:
            return "Năm mươi ngày phi thường"
        case 100:
            return "Trăm ngày học tập"
        default:
            return "Cột mốc \(streak) ngày"
        }
    }
    
    private func getStreakMilestoneDescription(for streak: Int) -> String {
        return "Học liên tục \(streak) ngày"
    }
    
    private func getStreakBadge(for streak: Int) -> String {
        switch streak {
        case 3: return "🔥"
        case 7: return "🏆"
        case 14: return "⭐"
        case 30: return "💎"
        case 50: return "👑"
        case 100: return "🎯"
        default: return "🎉"
        }
    }
}

// MARK: - Data Models

struct UserProfileData {
    let id: String
    let name: String
    let grade: Int
    let level: Int
    let totalScore: Int
    let experience: Int
    let experienceToNextLevel: Int
    let levelProgress: Float
    let currentStreak: Int
    let bestStreak: Int
    let averageAccuracy: Float
    let completedExercises: Int
    let totalTimeSpent: TimeInterval
    let dailySessionGoal: Int
    let dailyTimeGoal: Int // in minutes
    let accuracyGoal: Int // as percentage
    let avatarURL: URL?
    let joinedDate: Date
    let lastActiveDate: Date
    
    static let `default` = UserProfileData(
        id: "default",
        name: "Bé Minh",
        grade: 2,
        level: 1,
        totalScore: 0,
        experience: 0,
        experienceToNextLevel: 100,
        levelProgress: 0.0,
        currentStreak: 0,
        bestStreak: 0,
        averageAccuracy: 0.0,
        completedExercises: 0,
        totalTimeSpent: 0,
        dailySessionGoal: 3,
        dailyTimeGoal: 15,
        accuracyGoal: 80,
        avatarURL: nil,
        joinedDate: Date(),
        lastActiveDate: Date()
    )
    
    var levelTitle: String {
        switch level {
        case 1...5:
            return "Người mới bắt đầu"
        case 6...10:
            return "Học sinh chăm chỉ"
        case 11...20:
            return "Đọc giả nhỏ"
        case 21...35:
            return "Chuyên gia đọc"
        case 36...50:
            return "Bậc thầy ngôn ngữ"
        default:
            return "Huyền thoại"
        }
    }
    
    var formattedTotalTime: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var joinedDaysAgo: Int {
        return Calendar.current.dateComponents([.day], from: joinedDate, to: Date()).day ?? 0
    }
}

struct WeeklyProgressData {
    let date: Date
    let score: Int
}

struct AccuracyHistoryData {
    let date: Date
    let accuracy: Double
}

struct CategoryProgressData {
    let category: ExerciseCategory
    let accuracy: Float
}

// MARK: - Edit Profile View (Placeholder)
struct EditProfileView: View {
    let userProfile: UserProfileData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Chỉnh sửa hồ sơ")
                Text("Tính năng này sẽ được phát triển sau")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Chỉnh sửa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Achievements Detail View (Placeholder)
struct AchievementsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Tất cả thành tích")
                Text("Tính năng này sẽ được phát triển sau")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Thành tích")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detailed Statistics View (Placeholder)
struct DetailedStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Thống kê chi tiết")
                Text("Tính năng này sẽ được phát triển sau")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Thống kê")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}