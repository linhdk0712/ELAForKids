import SwiftUI

// MARK: - Achievements View
struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @Environment(\.adaptiveLayout) private var layout
    @State private var selectedCategory: AchievementCategory = .reading
    @State private var selectedBadge: BadgeInfo?
    @State private var showBadgeDetail = false
    
    var body: some View {
        ResponsiveLayout {
            AdaptiveContainer {
                ScrollView {
                    LazyVStack(spacing: layout.sectionSpacing) {
                        // Header with statistics
                        headerSection
                        
                        // Category filter
                        categoryFilterSection
                        
                        // Achievement grid
                        achievementGridSection
                        
                        // Recent achievements
                        if !viewModel.state.recentAchievements.isEmpty {
                            recentAchievementsSection
                        }
                        
                        // Next achievable
                        if !viewModel.state.nextAchievable.isEmpty {
                            nextAchievableSection
                        }
                    }
                }
            }
        }
        .adaptiveLayout()
        .navigationTitle("Thành tích")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.send(.loadAchievements)
        }
        .sheet(isPresented: $showBadgeDetail) {
            if let badge = selectedBadge {
                BadgeDetailView(
                    badge: badge,
                    isUnlocked: viewModel.isBadgeUnlocked(badge.id),
                    unlockedAt: viewModel.getBadgeUnlockDate(badge.id),
                    onClose: {
                        showBadgeDetail = false
                        selectedBadge = nil
                    }
                )
            }
        }
        .alert("Lỗi", isPresented: .constant(viewModel.state.error != nil)) {
            Button("Đóng") {
                viewModel.send(.clearError)
            }
        } message: {
            if let error = viewModel.state.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 2) {
                // Title and completion percentage
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        AdaptiveText("Bộ sưu tập thành tích", style: .title2)
                            .fontWeight(.bold)
                        
                        AdaptiveText(
                            "\(viewModel.state.statistics.unlockedAchievements)/\(viewModel.state.statistics.totalAchievements) thành tích",
                            style: .caption
                        )
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Completion circle
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.state.statistics.completionPercentage))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: viewModel.state.statistics.completionPercentage)
                        
                        Text("\(Int(viewModel.state.statistics.completionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Statistics row
                HStack(spacing: layout.sectionSpacing) {
                    statisticItem(
                        title: "Điểm thành tích",
                        value: "\(viewModel.state.statistics.achievementPoints)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    statisticItem(
                        title: "Mới mở khóa",
                        value: "\(viewModel.state.statistics.recentUnlocks.count)",
                        icon: "sparkles",
                        color: .orange
                    )
                    
                    statisticItem(
                        title: "Hiếm nhất",
                        value: viewModel.state.statistics.nextTier?.localizedName ?? "Hoàn thành",
                        icon: "crown.fill",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private func statisticItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Filter Section
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: layout.sectionSpacing / 2) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    categoryFilterButton(category)
                }
            }
            .padding(.horizontal, layout.contentPadding)
        }
    }
    
    private func categoryFilterButton(_ category: AchievementCategory) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedCategory = category
                viewModel.send(.filterByCategory(category))
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.localizedName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedCategory == category ?
                Color(category.color) :
                Color(.systemGray6)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Achievement Grid Section
    private var achievementGridSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                HStack {
                    AdaptiveText("Thành tích \(selectedCategory.localizedName)", style: .headline)
                    
                    Spacer()
                    
                    Text("\(viewModel.filteredAchievements.count) thành tích")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.state.isLoading {
                    loadingView
                } else if viewModel.filteredAchievements.isEmpty {
                    emptyStateView
                } else {
                    achievementGrid
                }
            }
        }
    }
    
    private var achievementGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: layout.sectionSpacing / 2) {
            ForEach(viewModel.filteredAchievements, id: \.id) { achievement in
                AchievementCardView(
                    achievement: achievement,
                    isUnlocked: viewModel.isAchievementUnlocked(achievement.id),
                    progress: viewModel.getAchievementProgress(achievement.id),
                    onTap: {
                        selectedBadge = achievement.badge
                        showBadgeDetail = true
                    }
                )
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        let columnCount: Int
        switch layout.deviceType {
        case .iPhone:
            columnCount = layout.orientation == .portrait ? 2 : 3
        case .iPad:
            columnCount = layout.orientation == .portrait ? 3 : 4
        case .mac:
            columnCount = 4
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: layout.sectionSpacing / 2), count: columnCount)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Đang tải thành tích...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Chưa có thành tích nào")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Hãy hoàn thành các bài đọc để mở khóa thành tích!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Recent Achievements Section
    private var recentAchievementsSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                HStack {
                    AdaptiveText("Mới mở khóa", style: .headline)
                    
                    Spacer()
                    
                    Button("Xem tất cả") {
                        // Navigate to all recent achievements
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: layout.sectionSpacing / 2) {
                        ForEach(viewModel.state.recentAchievements.prefix(5), id: \.id) { userAchievement in
                            if let achievement = viewModel.getAchievement(by: userAchievement.achievementId) {
                                RecentAchievementCard(
                                    achievement: achievement,
                                    unlockedAt: userAchievement.unlockedAt,
                                    onTap: {
                                        selectedBadge = achievement.badge
                                        showBadgeDetail = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, layout.contentPadding)
                }
            }
        }
    }
    
    // MARK: - Next Achievable Section
    private var nextAchievableSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                AdaptiveText("Sắp đạt được", style: .headline)
                
                ForEach(viewModel.state.nextAchievable.prefix(3), id: \.achievement.id) { achievementWithProgress in
                    BadgeProgressView(
                        badge: achievementWithProgress.achievement.badge,
                        progress: achievementWithProgress.progress
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Card View
struct AchievementCardView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: AchievementProgress?
    let onTap: () -> Void
    
    @Environment(\.adaptiveLayout) private var layout
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Badge
                BadgeView(
                    badge: achievement.badge,
                    isUnlocked: isUnlocked,
                    size: .medium,
                    showAnimation: isUnlocked
                )
                
                // Title and description
                VStack(spacing: 4) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // Progress or completion indicator
                if let progress = progress, !isUnlocked {
                    VStack(spacing: 4) {
                        ProgressView(value: progress.normalizedProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        Text("\(progress.current)/\(progress.target)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("Đã mở khóa")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                // Difficulty indicator
                HStack(spacing: 4) {
                    Text(achievement.difficulty.emoji)
                        .font(.caption2)
                    
                    Text(achievement.difficulty.localizedName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(layout.contentPadding / 2)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: layout.cornerRadius)
                    .stroke(isUnlocked ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Achievement Card
struct RecentAchievementCard: View {
    let achievement: Achievement
    let unlockedAt: Date
    let onTap: () -> Void
    
    @Environment(\.adaptiveLayout) private var layout
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                BadgeView(
                    badge: achievement.badge,
                    isUnlocked: true,
                    size: .small,
                    showAnimation: true
                )
                
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(timeAgoString(from: unlockedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(width: 100)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes) phút trước"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours) giờ trước"
        } else { // More than 1 day
            let days = Int(timeInterval / 86400)
            return "\(days) ngày trước"
        }
    }
}

// MARK: - Preview
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AchievementsView()
                .adaptiveLayout()
        }
    }
}