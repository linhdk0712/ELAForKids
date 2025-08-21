import SwiftUI
import Charts

// MARK: - Progress Tab View
struct ProgressTabView: View {
    @ObservedObject var viewModel: MainMenuViewModel
    @State private var selectedPeriod: ProgressPeriod = .weekly
    @State private var showingDetailedStats = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header section
                headerSection
                
                // Period selector
                periodSelectorSection
                
                // Progress overview
                progressOverviewSection
                
                // Charts section
                chartsSection
                
                // Achievements section
                achievementsSection
                
                // Goals section
                goalsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tiến độ học tập")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Theo dõi quá trình học của bé")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Chi tiết") {
                    showingDetailedStats = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Period Selector Section
    
    @ViewBuilder
    private var periodSelectorSection: some View {
        Picker("Thời gian", selection: $selectedPeriod) {
            ForEach([ProgressPeriod.daily, .weekly, .monthly], id: \.self) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 4)
    }
    
    // MARK: - Progress Overview Section
    
    @ViewBuilder
    private var progressOverviewSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            progressStatCard(
                title: "Hoàn thành",
                value: "\(Int(getCurrentProgress() * 100))%",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            progressStatCard(
                title: "Chuỗi học tập",
                value: "\(viewModel.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            progressStatCard(
                title: "Điểm trung bình",
                value: "\(getAverageScore())",
                icon: "star.fill",
                color: .yellow
            )
        }
    }
    
    @ViewBuilder
    private func progressStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Charts Section
    
    @ViewBuilder
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biểu đồ tiến độ")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            // Accuracy chart
            accuracyChartView
            
            // Sessions chart
            sessionsChartView
        }
    }
    
    @ViewBuilder
    private var accuracyChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Độ chính xác")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Chart(getAccuracyData()) { dataPoint in
                LineMark(
                    x: .value("Ngày", dataPoint.date),
                    y: .value("Độ chính xác", dataPoint.accuracy)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Ngày", dataPoint.date),
                    y: .value("Độ chính xác", dataPoint.accuracy)
                )
                .foregroundStyle(.blue)
                .symbolSize(50)
            }
            .frame(height: 150)
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var sessionsChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Số buổi học")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Chart(getSessionsData()) { dataPoint in
                BarMark(
                    x: .value("Ngày", dataPoint.date),
                    y: .value("Số buổi", dataPoint.sessions)
                )
                .foregroundStyle(.green)
                .cornerRadius(4)
            }
            .frame(height: 150)
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Achievements Section
    
    @ViewBuilder
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Thành tích")
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.recentAchievements.prefix(4), id: \.id) { achievement in
                    achievementBadge(achievement)
                }
            }
        }
    }
    
    @ViewBuilder
    private func achievementBadge(_ achievement: Achievement) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(achievement.difficulty.color)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(achievement.difficulty.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(achievement.difficulty.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Goals Section
    
    @ViewBuilder
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mục tiêu")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                goalProgressItem(
                    title: "Bài học hôm nay",
                    current: getCurrentDailySessions(),
                    target: viewModel.dailyGoal.sessionGoal,
                    unit: "bài",
                    color: .blue
                )
                
                goalProgressItem(
                    title: "Thời gian học",
                    current: getCurrentDailyTime(),
                    target: viewModel.dailyGoal.timeGoal,
                    unit: "phút",
                    color: .green
                )
                
                goalProgressItem(
                    title: "Độ chính xác",
                    current: getCurrentAccuracy(),
                    target: viewModel.dailyGoal.accuracyGoal,
                    unit: "%",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func goalProgressItem(
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
    
    private func getCurrentProgress() -> Float {
        switch selectedPeriod {
        case .daily:
            return viewModel.todayProgress
        case .weekly:
            return viewModel.weeklyProgress
        default:
            return 0.5 // Mock data
        }
    }
    
    private func getAverageScore() -> Int {
        // Mock data - would come from actual progress tracking
        return 85
    }
    
    private func getCurrentDailySessions() -> Int {
        // Mock data - would come from actual progress tracking
        return 2
    }
    
    private func getCurrentDailyTime() -> Int {
        // Mock data - would come from actual progress tracking
        return 12
    }
    
    private func getCurrentAccuracy() -> Int {
        // Mock data - would come from actual progress tracking
        return 88
    }
    
    private func getAccuracyData() -> [AccuracyDataPoint] {
        // Mock data - would come from actual progress tracking
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            return AccuracyDataPoint(
                date: date,
                accuracy: Double.random(in: 0.7...0.95)
            )
        }.reversed()
    }
    
    private func getSessionsData() -> [SessionsDataPoint] {
        // Mock data - would come from actual progress tracking
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            return SessionsDataPoint(
                date: date,
                sessions: Int.random(in: 0...5)
            )
        }.reversed()
    }
    
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        
        switch selectedPeriod {
        case .daily, .weekly:
            formatter.dateFormat = "E" // Mon, Tue, etc.
        case .monthly:
            formatter.dateFormat = "d" // 1, 2, 3, etc.
        default:
            formatter.dateFormat = "MMM" // Jan, Feb, etc.
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Chart Data Models

struct AccuracyDataPoint {
    let date: Date
    let accuracy: Double
}

struct SessionsDataPoint {
    let date: Date
    let sessions: Int
}

// MARK: - Achievement Difficulty Extension

extension AchievementDifficulty {
    var color: Color {
        switch self {
        case .bronze:
            return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum:
            return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .diamond:
            return Color(red: 0.7, green: 0.9, blue: 1.0)
        }
    }
}

// MARK: - Preview
struct ProgressTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressTabView(viewModel: MainMenuViewModel())
            .background(Color(.systemGroupedBackground))
    }
}