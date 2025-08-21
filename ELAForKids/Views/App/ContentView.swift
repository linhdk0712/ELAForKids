import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var rewardSystem = RewardSystem(
        progressTracker: ProgressTrackingFactory.shared.getProgressTracker()
    )
    
    var body: some View {
        ZStack {
            // Main navigation content
            NavigationStack(path: $navigationCoordinator.navigationPath) {
                screenView(for: navigationCoordinator.currentScreen)
                    .navigationDestination(for: AppScreen.self) { screen in
                        screenView(for: screen)
                    }
            }
            .navigationCoordinator(navigationCoordinator)
            
            // Reward overlay
            RewardOverlayView(rewardService: rewardSystem.animationService)
        }
        .environmentObject(navigationCoordinator)
        .environmentObject(rewardSystem)
        .preferredColorScheme(.light) // Child-friendly light theme
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

// MARK: - App Entry Point
@main
struct ELAForKidsApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Configure app appearance for child-friendly design
        configureAppearance()
        
        // Initialize default data if needed
        Task {
            do {
                try await persistenceController.seedDefaultData()
            } catch {
                print("Error seeding default data: \(error)")
            }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure button appearance for child-friendly design
        UIButton.appearance().titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Configure colors for accessibility
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.systemBlue
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}