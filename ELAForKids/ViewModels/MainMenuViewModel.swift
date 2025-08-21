import SwiftUI
import Combine

// MARK: - Main Menu View Model
@MainActor
final class MainMenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var userName: String = "Bé Minh"
    @Published var userLevel: Int = 1
    @Published var userScore: Int = 0
    @Published var currentStreak: Int = 0
    @Published var todayProgress: Float = 0.0
    @Published var weeklyProgress: Float = 0.0
    @Published var recentAchievements: [Achievement] = []
    @Published var dailyGoal: DailyGoal = DailyGoal.default
    @Published var isLoading: Bool = false
    @Published var animationTrigger: Bool = false
    
    // MARK: - Computed Properties
    var userAvatarURL: URL? {
        // This would typically come from user profile or be generated
        return URL(string: "https://api.dicebear.com/7.x/avataaars/png?seed=\(userName)")
    }
    
    var levelProgress: Float {
        // Calculate progress to next level based on score
        let currentLevelScore = calculateLevelScore(for: userLevel)
        let nextLevelScore = calculateLevelScore(for: userLevel + 1)
        let progressInLevel = userScore - currentLevelScore
        let totalLevelRange = nextLevelScore - currentLevelScore
        
        return Float(progressInLevel) / Float(totalLevelRange)
    }
    
    var levelTitle: String {
        switch userLevel {
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
    
    var todayGoalStatus: GoalStatus {
        if todayProgress >= 1.0 {
            return .completed
        } else if todayProgress >= 0.7 {
            return .nearCompletion
        } else if todayProgress >= 0.3 {
            return .inProgress
        } else {
            return .notStarted
        }
    }
    
    // MARK: - Private Properties
    private let progressTracker = ProgressTrackingFactory.shared.getProgressTracker()
    private let userScoreRepository = ProgressTrackingFactory.shared.getUserScoreRepository()
    private var cancellables = Set<AnyCancellable>()
    private let userId = "current_user" // This would come from authentication
    
    // MARK: - Initialization
    init() {
        setupAnimationTimer()
    }
    
    // MARK: - Public Methods
    
    func loadUserData() {
        isLoading = true
        
        Task {
            do {
                // Load user profile data
                await loadUserProfile()
                
                // Load progress data
                await loadProgressData()
                
                // Load achievements
                await loadRecentAchievements()
                
                // Load daily goal status
                await loadDailyGoalStatus()
                
                isLoading = false
            } catch {
                print("Error loading user data: \(error)")
                isLoading = false
            }
        }
    }
    
    func refreshData() {
        loadUserData()
    }
    
    func startPracticeSession(difficulty: DifficultyLevel) {
        // This would navigate to practice session
        print("Starting practice session with difficulty: \(difficulty)")
    }
    
    func viewProgress() {
        // This would navigate to detailed progress view
        print("Viewing detailed progress")
    }
    
    func viewAchievements() {
        // This would navigate to achievements view
        print("Viewing achievements")
    }
    
    func playGame(gameType: GameType) {
        // This would navigate to selected game
        print("Playing game: \(gameType)")
    }
    
    // MARK: - Private Methods
    
    private func loadUserProfile() async {
        do {
            let userScore = try await userScoreRepository.getUserScore(userId: userId)
            
            userName = userScore.userName
            userLevel = userScore.level
            userScore = userScore.totalScore
            currentStreak = userScore.streak
            
        } catch {
            print("Error loading user profile: \(error)")
            // Use default values
        }
    }
    
    private func loadProgressData() async {
        do {
            // Load today's progress
            let todayProgress = try await progressTracker.getUserProgress(userId: userId, period: .daily)
            self.todayProgress = todayProgress.completionPercentage
            
            // Load weekly progress
            let weeklyProgress = try await progressTracker.getUserProgress(userId: userId, period: .weekly)
            self.weeklyProgress = weeklyProgress.completionPercentage
            
        } catch {
            print("Error loading progress data: \(error)")
        }
    }
    
    private func loadRecentAchievements() async {
        // This would load recent achievements from the achievement system
        // For now, create some sample achievements
        recentAchievements = [
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
                id: "streak_3",
                title: "Học liên tục 3 ngày",
                description: "Học liên tục trong 3 ngày",
                category: .streak,
                difficulty: .silver,
                requirementType: .consecutiveDays,
                requirementTarget: 3
            )
        ]
    }
    
    private func loadDailyGoalStatus() async {
        do {
            let goals = try await progressTracker.getLearningGoals(userId: userId)
            let isDailyGoalMet = try await progressTracker.checkDailyGoal(userId: userId)
            
            dailyGoal = DailyGoal(
                sessionGoal: goals.dailySessionGoal,
                timeGoal: Int(goals.dailyTimeGoal / 60), // Convert to minutes
                accuracyGoal: Int(goals.accuracyGoal * 100), // Convert to percentage
                isCompleted: isDailyGoalMet
            )
            
        } catch {
            print("Error loading daily goal status: \(error)")
        }
    }
    
    private func calculateLevelScore(for level: Int) -> Int {
        // Level 1: 0-99, Level 2: 100-299, Level 3: 300-599, etc.
        if level <= 1 {
            return 0
        }
        
        var totalScore = 0
        for currentLevel in 2...level {
            totalScore += 100 * currentLevel + 50 * (currentLevel - 1) * currentLevel
        }
        return totalScore
    }
    
    private func setupAnimationTimer() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.easeInOut(duration: 2.0)) {
                    self.animationTrigger.toggle()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Data Models

struct DailyGoal {
    let sessionGoal: Int
    let timeGoal: Int // in minutes
    let accuracyGoal: Int // as percentage
    let isCompleted: Bool
    
    static let `default` = DailyGoal(
        sessionGoal: 3,
        timeGoal: 15,
        accuracyGoal: 80,
        isCompleted: false
    )
    
    var progressMessage: String {
        if isCompleted {
            return "🎉 Hoàn thành mục tiêu hôm nay!"
        } else {
            return "📚 Hãy hoàn thành \(sessionGoal) bài học hôm nay"
        }
    }
}

enum GoalStatus {
    case notStarted
    case inProgress
    case nearCompletion
    case completed
    
    var color: Color {
        switch self {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .nearCompletion:
            return .orange
        case .completed:
            return .green
        }
    }
    
    var message: String {
        switch self {
        case .notStarted:
            return "Bắt đầu học thôi!"
        case .inProgress:
            return "Đang tiến bộ tốt!"
        case .nearCompletion:
            return "Sắp hoàn thành rồi!"
        case .completed:
            return "Hoàn thành xuất sắc!"
        }
    }
}

enum GameType: String, CaseIterable {
    case wordMatch = "word_match"
    case speedReading = "speed_reading"
    case pronunciation = "pronunciation"
    case memory = "memory"
    
    var title: String {
        switch self {
        case .wordMatch:
            return "Ghép từ"
        case .speedReading:
            return "Đọc nhanh"
        case .pronunciation:
            return "Phát âm"
        case .memory:
            return "Trí nhớ"
        }
    }
    
    var icon: String {
        switch self {
        case .wordMatch:
            return "puzzlepiece.fill"
        case .speedReading:
            return "bolt.fill"
        case .pronunciation:
            return "mic.fill"
        case .memory:
            return "brain.head.profile"
        }
    }
    
    var description: String {
        switch self {
        case .wordMatch:
            return "Ghép các từ với hình ảnh tương ứng"
        case .speedReading:
            return "Đọc nhanh và hiểu nội dung"
        case .pronunciation:
            return "Luyện phát âm chuẩn"
        case .memory:
            return "Ghi nhớ từ vựng và câu văn"
        }
    }
}