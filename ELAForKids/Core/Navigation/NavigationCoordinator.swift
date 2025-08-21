import SwiftUI
import Combine

// MARK: - Navigation Coordinator
@MainActor
final class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentScreen: AppScreen = .mainMenu
    @Published var navigationPath = NavigationPath()
    @Published var showingModal = false
    @Published var modalScreen: AppScreen?
    @Published var showingAlert = false
    @Published var alertConfig: AlertConfig?
    
    // MARK: - Navigation Methods
    
    /// Navigate to a new screen
    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }
    
    /// Push a screen onto the navigation stack
    func push(_ screen: AppScreen) {
        navigationPath.append(screen)
    }
    
    /// Pop the current screen from navigation stack
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// Pop to root screen
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    /// Present a modal screen
    func presentModal(_ screen: AppScreen) {
        modalScreen = screen
        showingModal = true
    }
    
    /// Dismiss the current modal
    func dismissModal() {
        showingModal = false
        modalScreen = nil
    }
    
    /// Show an alert
    func showAlert(_ config: AlertConfig) {
        alertConfig = config
        showingAlert = true
    }
    
    /// Dismiss the current alert
    func dismissAlert() {
        showingAlert = false
        alertConfig = nil
    }
    
    // MARK: - Specific Navigation Methods
    
    func startPracticeSession(difficulty: DifficultyLevel, category: ExerciseCategory? = nil) {
        let practiceScreen = AppScreen.practiceSession(
            PracticeSessionConfig(
                difficulty: difficulty,
                category: category,
                mode: .normal
            )
        )
        navigate(to: practiceScreen)
    }
    
    func startQuickPractice() {
        let quickPracticeScreen = AppScreen.practiceSession(
            PracticeSessionConfig(
                difficulty: .grade2,
                category: nil,
                mode: .quick
            )
        )
        navigate(to: quickPracticeScreen)
    }
    
    func showResults(_ results: SessionResult) {
        let resultsScreen = AppScreen.results(results)
        navigate(to: resultsScreen)
    }
    
    func showUserProfile() {
        presentModal(.userProfile)
    }
    
    func showSettings() {
        presentModal(.settings)
    }
    
    func showAchievements() {
        push(.achievements)
    }
    
    func showDetailedProgress() {
        push(.detailedProgress)
    }
    
    func playGame(_ gameType: GameType) {
        let gameScreen = AppScreen.game(gameType)
        navigate(to: gameScreen)
    }
    
    func showGameDetail(_ game: GameInfo) {
        presentModal(.gameDetail(game))
    }
    
    func returnToMainMenu() {
        popToRoot()
        navigate(to: .mainMenu)
    }
    
    // MARK: - Alert Helpers
    
    func showErrorAlert(title: String, message: String) {
        showAlert(AlertConfig(
            title: title,
            message: message,
            primaryButton: AlertButton(title: "OK", action: {}),
            secondaryButton: nil
        ))
    }
    
    func showConfirmationAlert(
        title: String,
        message: String,
        confirmTitle: String = "Xác nhận",
        cancelTitle: String = "Hủy",
        onConfirm: @escaping () -> Void
    ) {
        showAlert(AlertConfig(
            title: title,
            message: message,
            primaryButton: AlertButton(title: confirmTitle, action: onConfirm),
            secondaryButton: AlertButton(title: cancelTitle, action: {})
        ))
    }
}

// MARK: - App Screen Enum

enum AppScreen: Hashable {
    case mainMenu
    case practiceSession(PracticeSessionConfig)
    case results(SessionResult)
    case userProfile
    case settings
    case achievements
    case detailedProgress
    case game(GameType)
    case gameDetail(GameInfo)
    
    var title: String {
        switch self {
        case .mainMenu:
            return "Trang chủ"
        case .practiceSession:
            return "Luyện tập"
        case .results:
            return "Kết quả"
        case .userProfile:
            return "Hồ sơ"
        case .settings:
            return "Cài đặt"
        case .achievements:
            return "Thành tích"
        case .detailedProgress:
            return "Tiến độ chi tiết"
        case .game:
            return "Trò chơi"
        case .gameDetail:
            return "Chi tiết trò chơi"
        }
    }
    
    var showsBackButton: Bool {
        switch self {
        case .mainMenu:
            return false
        default:
            return true
        }
    }
    
    var isModal: Bool {
        switch self {
        case .userProfile, .settings, .gameDetail:
            return true
        default:
            return false
        }
    }
}

// MARK: - Practice Session Config

struct PracticeSessionConfig: Hashable {
    let difficulty: DifficultyLevel
    let category: ExerciseCategory?
    let mode: PracticeMode
    
    static func == (lhs: PracticeSessionConfig, rhs: PracticeSessionConfig) -> Bool {
        return lhs.difficulty == rhs.difficulty &&
               lhs.category == rhs.category &&
               lhs.mode == rhs.mode
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(difficulty)
        hasher.combine(category)
        hasher.combine(mode)
    }
}

enum PracticeMode: Hashable {
    case normal
    case quick
    case review
    case challenge
    
    var title: String {
        switch self {
        case .normal:
            return "Bình thường"
        case .quick:
            return "Nhanh"
        case .review:
            return "Ôn tập"
        case .challenge:
            return "Thử thách"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .normal:
            return 600 // 10 minutes
        case .quick:
            return 300 // 5 minutes
        case .review:
            return 480 // 8 minutes
        case .challenge:
            return 900 // 15 minutes
        }
    }
}

// MARK: - Alert Configuration

struct AlertConfig {
    let title: String
    let message: String
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
}

struct AlertButton {
    let title: String
    let action: () -> Void
}

// MARK: - Navigation View Modifier

struct NavigationCoordinatorModifier: ViewModifier {
    @ObservedObject var coordinator: NavigationCoordinator
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $coordinator.showingModal) {
                if let modalScreen = coordinator.modalScreen {
                    NavigationView {
                        screenView(for: modalScreen)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Đóng") {
                                        coordinator.dismissModal()
                                    }
                                }
                            }
                    }
                }
            }
            .alert(
                coordinator.alertConfig?.title ?? "",
                isPresented: $coordinator.showingAlert
            ) {
                if let config = coordinator.alertConfig {
                    Button(config.primaryButton.title) {
                        config.primaryButton.action()
                        coordinator.dismissAlert()
                    }
                    
                    if let secondaryButton = config.secondaryButton {
                        Button(secondaryButton.title, role: .cancel) {
                            secondaryButton.action()
                            coordinator.dismissAlert()
                        }
                    }
                }
            } message: {
                if let message = coordinator.alertConfig?.message {
                    Text(message)
                }
            }
    }
    
    @ViewBuilder
    private func screenView(for screen: AppScreen) -> some View {
        switch screen {
        case .mainMenu:
            MainMenuView()
        case .practiceSession(let config):
            ReadingPracticeView(config: config)
        case .results(let sessionResult):
            SessionResultsView(sessionResult: sessionResult)
        case .userProfile:
            UserProfileView()
        case .settings:
            SettingsView()
        case .achievements:
            AchievementsView()
        case .detailedProgress:
            DetailedProgressView()
        case .game(let gameType):
            GameView(gameType: gameType)
        case .gameDetail(let game):
            GameDetailView(game: game)
        }
    }
}

// MARK: - View Extension

extension View {
    func navigationCoordinator(_ coordinator: NavigationCoordinator) -> some View {
        modifier(NavigationCoordinatorModifier(coordinator: coordinator))
    }
}

// MARK: - Placeholder Views (to be implemented in other tasks)

// PracticeSessionView is now implemented as ReadingPracticeView

// ResultsView is now implemented as SessionResultsView

// UserProfileView is now implemented in Views/Profile/UserProfileView.swift

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
        }
        .navigationTitle("Cài đặt")
    }
}

struct AchievementsView: View {
    var body: some View {
        VStack {
            Text("Achievements")
        }
        .navigationTitle("Thành tích")
    }
}

struct DetailedProgressView: View {
    var body: some View {
        VStack {
            Text("Detailed Progress")
        }
        .navigationTitle("Tiến độ chi tiết")
    }
}

struct GameView: View {
    let gameType: GameType
    
    var body: some View {
        VStack {
            Text("Game: \(gameType.title)")
        }
        .navigationTitle(gameType.title)
    }
}

struct GameDetailView: View {
    let game: GameInfo
    
    var body: some View {
        VStack {
            Text("Game Detail: \(game.title)")
        }
        .navigationTitle(game.title)
    }
}