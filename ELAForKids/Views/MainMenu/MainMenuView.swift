import SwiftUI

// MARK: - Main Menu View
struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()
    @StateObject private var rewardSystem = ProgressTrackingFactory.shared.getProgressTracker()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @EnvironmentObject private var offlineManager: OfflineManager
    @State private var selectedTab: MainMenuTab = .home
    @State private var showingProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tab content
                    tabContentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom navigation
                    bottomNavigationView
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.loadUserData()
        }
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.8, blue: 1.0),
                Color(red: 0.6, green: 0.9, blue: 1.0),
                Color(red: 0.8, green: 0.95, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Decorative clouds
        ForEach(0..<3, id: \.self) { index in
            Image(systemName: "cloud.fill")
                .font(.system(size: 40 + CGFloat(index * 10)))
                .foregroundColor(.white.opacity(0.3))
                .offset(
                    x: CGFloat(index * 120 - 100),
                    y: CGFloat(index * 80 - 200)
                )
                .animation(
                    .easeInOut(duration: 3 + Double(index))
                    .repeatForever(autoreverses: true),
                    value: viewModel.animationTrigger
                )
        }
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Welcome message
            VStack(alignment: .leading, spacing: 4) {
                Text("Xin chào!")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(viewModel.userName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // User avatar and settings
            HStack(spacing: 12) {
                // Offline status indicator
                CompactOfflineStatusView(offlineManager: offlineManager)
                
                // Streak indicator
                if viewModel.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.currentStreak)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityManager.getStreakAccessibilityLabel(
                        currentStreak: viewModel.currentStreak,
                        bestStreak: viewModel.bestStreak
                    ))
                }
                
                // Profile button
                Button(action: {
                    showingProfile = true
                }) {
                    AsyncImage(url: viewModel.userAvatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                }
                .accessibilityLabel("Hồ sơ cá nhân của \(viewModel.userName)")
                .accessibilityHint(accessibilityManager.getAccessibilityHint(for: .profileButton))
                .accessibilityAddTraits(.isButton)
                
                // Settings button
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Cài đặt")
                .accessibilityHint(accessibilityManager.getAccessibilityHint(for: .settingsButton))
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Tab Content View
    
    @ViewBuilder
    private var tabContentView: some View {
        TabView(selection: $selectedTab) {
            // Home tab
            HomeTabView(viewModel: viewModel)
                .tag(MainMenuTab.home)
            
            // Practice tab
            PracticeTabView(viewModel: viewModel)
                .tag(MainMenuTab.practice)
            
            // Progress tab
            ProgressTabView(viewModel: viewModel)
                .tag(MainMenuTab.progress)
            
            // Games tab
            GamesTabView(viewModel: viewModel)
                .tag(MainMenuTab.games)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    // MARK: - Bottom Navigation View
    
    @ViewBuilder
    private var bottomNavigationView: some View {
        HStack(spacing: 0) {
            ForEach(MainMenuTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                            .scaleEffect(selectedTab == tab ? 1.2 : 1.0)
                        
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel(tab.title)
                .accessibilityHint("Nhấn đúp để chuyển đến tab \(tab.title)")
                .accessibilityAddTraits(.isButton)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Main Menu Tabs
enum MainMenuTab: String, CaseIterable {
    case home = "home"
    case practice = "practice"
    case progress = "progress"
    case games = "games"
    
    var title: String {
        switch self {
        case .home:
            return "Trang chủ"
        case .practice:
            return "Luyện tập"
        case .progress:
            return "Tiến độ"
        case .games:
            return "Trò chơi"
        }
    }
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .practice:
            return "book.fill"
        case .progress:
            return "chart.bar.fill"
        case .games:
            return "gamecontroller.fill"
        }
    }
}

// MARK: - Preview
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .previewDevice("iPhone 14")
        
        MainMenuView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}