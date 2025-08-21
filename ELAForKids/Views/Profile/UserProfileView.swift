import SwiftUI
import Charts

// MARK: - User Profile View
struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var showingEditProfile = false
    @State private var showingAchievements = false
    @State private var showingDetailedStats = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Profile header
                    profileHeaderView
                    
                    // Quick stats
                    quickStatsView
                    
                    // Progress overview
                    progressOverviewView
                    
                    // Recent achievements
                    recentAchievementsView
                    
                    // Learning streak
                    learningStreakView
                    
                    // Performance charts
                    performanceChartsView
                    
                    // Goals and targets
                    goalsView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("Hồ sơ của bé")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chỉnh sửa") {
                        showingEditProfile = true
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadUserProfile()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userProfile: viewModel.userProfile)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsDetailView()
        }
        .sheet(isPresented: $showingDetailedStats) {
            DetailedStatisticsView()
        }
    }
    
    // MARK: - Profile Header View
    
    @ViewBuilder
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Avatar and basic info
            HStack(spacing: 16) {
                // Avatar
                AsyncImage(url: viewModel.userProfile.avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                
                // User info
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.userProfile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("Lớp \(viewModel.userProfile.grade)", systemImage: "graduationcap.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Label("Cấp \(viewModel.userProfile.level)", systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    // Level progress
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Tiến độ cấp độ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(viewModel.userProfile.experienceToNextLevel) XP nữa")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: viewModel.userProfile.levelProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                }
                
                Spacer()
            }
            
            // Achievement badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.topAchievements.prefix(5), id: \.id) { achievement in
                        achievementBadge(achievement)
                    }
                    
                    if viewModel.topAchievements.count > 5 {
                        Button(action: {
                            showingAchievements = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                
                                Text("Xem thêm")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    @ViewBuilder
    private func achievementBadge(_ achievement: Achievement) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(achievement.difficulty.color)
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 60, height: 60)
        .background(
            Circle()
                .fill(achievement.difficulty.color.opacity(0.1))
                .overlay(
                    Circle()
                        .stroke(achievement.difficulty.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Stats View
    
    @ViewBuilder
    private var quickStatsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statCard(
                title: "Tổng điểm",
                value: "\(viewModel.userProfile.totalScore)",
                icon: "star.fill",
                color: .yellow
            )
            
            statCard(
                title: "Chuỗi học tập",
                value: "\(viewModel.userProfile.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            statCard(
                title: "Độ chính xác",
                value: "\(Int(viewModel.userProfile.averageAccuracy * 100))%",
                icon: "target",
                color: .green
            )
            
            statCard(
                title: "Bài hoàn thành",
                value: "\(viewModel.userProfile.completedExercises)",
                icon: "checkmark.circle.fill",
                color: .blue
            )
        }
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Progress Overview View
    
    @ViewBuilder
    private var progressOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tổng quan tiến độ")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Chi tiết") {
                    showingDetailedStats = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Weekly progress chart
            Chart(viewModel.weeklyProgress) { dataPoint in
                LineMark(
                    x: .value("Ngày", dataPoint.date),
                    y: .value("Điểm", dataPoint.score)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Ngày", dataPoint.date),
                    y: .value("Điểm", dataPoint.score)
                )
                .foregroundStyle(.blue)
                .symbolSize(50)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(formatChartDate(dateValue))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Category breakdown
            HStack(spacing: 16) {
                ForEach(viewModel.categoryProgress, id: \.category) { progress in
                    categoryProgressItem(progress)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func categoryProgressItem(_ progress: CategoryProgressData) -> some View {
        VStack(spacing: 8) {
            Image(systemName: progress.category.icon)
                .font(.title3)
                .foregroundColor(progress.category.color)
            
            Text("\(Int(progress.accuracy * 100))%")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(progress.category.localizedName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Recent Achievements View
    
    @ViewBuilder
    private var recentAchievementsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Thành tích gần đây")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Xem tất cả") {
                    showingAchievements = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.recentAchievements.prefix(3), id: \.id) { achievement in
                    achievementRow(achievement)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(achievement.difficulty.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let achievedAt = achievement.achievedAt {
                Text(formatAchievementDate(achievedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(achievement.difficulty.color.opacity(0.1))
        )
    }
    
    // MARK: - Learning Streak View
    
    @ViewBuilder
    private var learningStreakView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chuỗi học tập")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Current streak
                VStack(spacing: 8) {
                    Text("\(viewModel.userProfile.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("ngày liên tiếp")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak visualization
                VStack(spacing: 4) {
                    Text("7 ngày gần đây")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { index in
                            streakDayIndicator(
                                isActive: index < viewModel.userProfile.currentStreak,
                                dayIndex: index
                            )
                        }
                    }
                }
            }
            
            // Next milestone
            if let nextMilestone = viewModel.nextStreakMilestone {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                    
                    Text("Mục tiêu tiếp theo: \(nextMilestone.title)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(nextMilestone.streak - viewModel.userProfile.currentStreak) ngày nữa")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func streakDayIndicator(isActive: Bool, dayIndex: Int) -> some View {
        Circle()
            .fill(isActive ? Color.orange : Color(.systemGray5))
            .frame(width: 20, height: 20)
            .overlay(
                Text("\(dayIndex + 1)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? .white : .secondary)
            )
    }
    
    // MARK: - Performance Charts View
    
    @ViewBuilder
    private var performanceChartsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biểu đồ hiệu suất")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Accuracy over time
            VStack(alignment: .leading, spacing: 8) {
                Text("Độ chính xác theo thời gian")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Chart(viewModel.accuracyHistory) { dataPoint in
                    LineMark(
                        x: .value("Ngày", dataPoint.date),
                        y: .value("Độ chính xác", dataPoint.accuracy)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 100)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue * 100))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Goals View
    
    @ViewBuilder
    private var goalsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mục tiêu học tập")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                goalProgressRow(
                    title: "Bài học hàng ngày",
                    current: viewModel.dailySessionsCompleted,
                    target: viewModel.userProfile.dailySessionGoal,
                    unit: "bài",
                    color: .blue
                )
                
                goalProgressRow(
                    title: "Thời gian học hàng ngày",
                    current: viewModel.dailyTimeSpent,
                    target: viewModel.userProfile.dailyTimeGoal,
                    unit: "phút",
                    color: .green
                )
                
                goalProgressRow(
                    title: "Độ chính xác mục tiêu",
                    current: Int(viewModel.userProfile.averageAccuracy * 100),
                    target: viewModel.userProfile.accuracyGoal,
                    unit: "%",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func goalProgressRow(
        title: String,
        current: Int,
        target: Int,
        unit: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current)/\(target) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: Float(current), total: Float(target))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func formatAchievementDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
            .environmentObject(NavigationCoordinator())
    }
}