import SwiftUI

// MARK: - Home Tab View
struct HomeTabView: View {
    @ObservedObject var viewModel: MainMenuViewModel
    @State private var showingQuickPractice = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Welcome section
                welcomeSection
                
                // Daily goal section
                dailyGoalSection
                
                // Quick actions section
                quickActionsSection
                
                // Recent achievements section
                if !viewModel.recentAchievements.isEmpty {
                    recentAchievementsSection
                }
                
                // Progress overview section
                progressOverviewSection
                
                // Motivational section
                motivationalSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .refreshable {
            viewModel.refreshData()
        }
    }
    
    // MARK: - Welcome Section
    
    @ViewBuilder
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cấp độ \(viewModel.userLevel)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.levelTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.userScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("điểm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Level progress bar
            ProgressView(value: viewModel.levelProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Daily Goal Section
    
    @ViewBuilder
    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Mục tiêu hôm nay")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(viewModel.todayProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.todayGoalStatus.color)
            }
            
            // Progress bar
            ProgressView(value: viewModel.todayProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.todayGoalStatus.color))
                .scaleEffect(x: 1, y: 3, anchor: .center)
            
            // Goal details
            HStack(spacing: 20) {
                goalDetailItem(
                    icon: "book.fill",
                    title: "\(viewModel.dailyGoal.sessionGoal) bài",
                    subtitle: "Bài học"
                )
                
                goalDetailItem(
                    icon: "clock.fill",
                    title: "\(viewModel.dailyGoal.timeGoal) phút",
                    subtitle: "Thời gian"
                )
                
                goalDetailItem(
                    icon: "target",
                    title: "\(viewModel.dailyGoal.accuracyGoal)%",
                    subtitle: "Độ chính xác"
                )
            }
            
            // Status message
            Text(viewModel.todayGoalStatus.message)
                .font(.subheadline)
                .foregroundColor(viewModel.todayGoalStatus.color)
                .fontWeight(.medium)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func goalDetailItem(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quick Actions Section
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bắt đầu học")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickActionButton(
                    title: "Luyện tập nhanh",
                    subtitle: "5 phút",
                    icon: "bolt.fill",
                    color: .orange,
                    action: {
                        showingQuickPractice = true
                    }
                )
                
                quickActionButton(
                    title: "Bài học mới",
                    subtitle: "Cấp độ phù hợp",
                    icon: "book.fill",
                    color: .blue,
                    action: {
                        viewModel.startPracticeSession(difficulty: .grade2)
                    }
                )
                
                quickActionButton(
                    title: "Ôn tập",
                    subtitle: "Bài đã học",
                    icon: "arrow.clockwise",
                    color: .green,
                    action: {
                        viewModel.startPracticeSession(difficulty: .grade1)
                    }
                )
                
                quickActionButton(
                    title: "Thử thách",
                    subtitle: "Khó hơn",
                    icon: "star.fill",
                    color: .purple,
                    action: {
                        viewModel.startPracticeSession(difficulty: .grade3)
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private func quickActionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Recent Achievements Section
    
    @ViewBuilder
    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Thành tích gần đây")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Xem tất cả") {
                    viewModel.viewAchievements()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentAchievements, id: \.id) { achievement in
                        achievementCard(achievement)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 24))
                .foregroundColor(achievement.difficulty.color)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Progress Overview Section
    
    @ViewBuilder
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tiến độ tuần này")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Chi tiết") {
                    viewModel.viewProgress()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 20) {
                progressItem(
                    title: "Hoàn thành",
                    value: "\(Int(viewModel.weeklyProgress * 100))%",
                    color: .green
                )
                
                progressItem(
                    title: "Chuỗi học tập",
                    value: "\(viewModel.currentStreak) ngày",
                    color: .orange
                )
                
                progressItem(
                    title: "Cấp độ",
                    value: "\(viewModel.userLevel)",
                    color: .purple
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
    private func progressItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Motivational Section
    
    @ViewBuilder
    private var motivationalSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 32))
                .foregroundColor(.yellow)
            
            Text(getMotivationalMessage())
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    private func getMotivationalMessage() -> String {
        let messages = [
            "Mỗi ngày học một chút, tiến bộ từng ngày! 📚",
            "Bé đang làm rất tốt! Tiếp tục cố gắng nhé! 💪",
            "Đọc sách là chìa khóa mở ra thế giới tri thức! 🗝️",
            "Hôm nay bé đã học gì mới? Hãy chia sẻ nhé! 🌟",
            "Kiên trì luyện tập sẽ giúp bé đọc giỏi hơn! 🎯"
        ]
        
        return messages.randomElement() ?? messages[0]
    }
}

// MARK: - Preview
struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTabView(viewModel: MainMenuViewModel())
            .background(Color(.systemGroupedBackground))
    }
}