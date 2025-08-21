import SwiftUI
import Charts

// MARK: - Session Results View
struct SessionResultsView: View {
    let sessionResult: SessionResult
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var rewardSystem: RewardSystem
    @StateObject private var viewModel = SessionResultsViewModel()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    @State private var showingDetailedFeedback = false
    @State private var showingShareSheet = false
    @State private var animationPhase = 0
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Main content
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header with celebration
                    headerView
                    
                    // Score overview
                    scoreOverviewView
                    
                    // Performance breakdown
                    performanceBreakdownView
                    
                    // Mistakes analysis
                    if !sessionResult.mistakes.isEmpty {
                        mistakesAnalysisView
                    }
                    
                    // Achievements earned
                    if !viewModel.newAchievements.isEmpty {
                        achievementsView
                    }
                    
                    // Progress comparison
                    progressComparisonView
                    
                    // Recommendations
                    recommendationsView
                    
                    // Action buttons
                    actionButtonsView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.processResults(sessionResult)
            startCelebrationAnimation()
        }
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                sessionResult.performanceLevel.backgroundColor,
                sessionResult.performanceLevel.backgroundColor.opacity(0.7),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Celebration particles
        if sessionResult.accuracy >= 0.8 {
            ForEach(0..<20, id: \.self) { index in
                celebrationParticle(index: index)
            }
        }
    }
    
    @ViewBuilder
    private func celebrationParticle(index: Int) -> some View {
        Image(systemName: ["star.fill", "heart.fill", "sparkles"].randomElement() ?? "star.fill")
            .font(.system(size: CGFloat.random(in: 12...24)))
            .foregroundColor([Color.yellow, Color.pink, Color.cyan, Color.green].randomElement() ?? .yellow)
            .offset(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -300...300)
            )
            .opacity(0.7)
            .scaleEffect(animationPhase % 2 == 0 ? 1.0 : 1.2)
            .animation(
                .easeInOut(duration: Double.random(in: 1...3))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2)),
                value: animationPhase
            )
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                
                Button(action: {
                    navigationCoordinator.returnToMainMenu()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                        )
                }
                .accessibilityLabel("Đóng kết quả")
                .accessibilityHint("Nhấn đúp để quay về trang chủ")
                .accessibilityAddTraits(.isButton)
            }
            
            // Celebration icon
            VStack(spacing: 12) {
                Image(systemName: sessionResult.performanceLevel.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(animationPhase % 2 == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)
                
                Text(sessionResult.performanceLevel.celebrationMessage)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(sessionResult.performanceLevel.encouragementMessage)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Score Overview View
    
    @ViewBuilder
    private var scoreOverviewView: some View {
        VStack(spacing: 20) {
            // Main score display
            VStack(spacing: 8) {
                Text("\(sessionResult.score)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("điểm")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityManager.getScoreAccessibilityLabel(
                score: sessionResult.score,
                accuracy: sessionResult.accuracy
            ))
            
            // Score breakdown
            HStack(spacing: 20) {
                scoreMetric(
                    title: "Độ chính xác",
                    value: "\(Int(sessionResult.accuracy * 100))%",
                    color: sessionResult.performanceLevel.color,
                    icon: "target"
                )
                
                scoreMetric(
                    title: "Thời gian",
                    value: sessionResult.formattedTimeSpent,
                    color: .blue,
                    icon: "clock.fill"
                )
                
                scoreMetric(
                    title: "Từ đúng",
                    value: "\(sessionResult.correctWords)/\(sessionResult.totalWords)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    @ViewBuilder
    private func scoreMetric(title: String, value: String, color: Color, icon: String) -> some View {
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
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Performance Breakdown View
    
    @ViewBuilder
    private var performanceBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Phân tích chi tiết")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Accuracy chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Độ chính xác theo từng phần")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Chart(viewModel.accuracyBreakdown) { dataPoint in
                    BarMark(
                        x: .value("Phần", dataPoint.section),
                        y: .value("Độ chính xác", dataPoint.accuracy)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [sessionResult.performanceLevel.color, sessionResult.performanceLevel.color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 120)
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
            
            // Reading speed
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tốc độ đọc")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(sessionResult.wordsPerMinute)) từ/phút")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                speedIndicator
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
    private var speedIndicator: some View {
        let speedLevel = getSpeedLevel(wpm: sessionResult.wordsPerMinute)
        
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < speedLevel ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 6, height: CGFloat(12 + index * 4))
            }
        }
    }
    
    // MARK: - Mistakes Analysis View
    
    @ViewBuilder
    private var mistakesAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Phân tích lỗi")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Chi tiết") {
                    showingDetailedFeedback = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Mistake types chart
            Chart(viewModel.mistakeTypeBreakdown) { dataPoint in
                SectorMark(
                    angle: .value("Số lượng", dataPoint.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(dataPoint.mistakeType.color)
                .opacity(0.8)
            }
            .frame(height: 150)
            
            // Mistake legend
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.mistakeTypeBreakdown, id: \.mistakeType) { dataPoint in
                    mistakeLegendItem(dataPoint)
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
    private func mistakeLegendItem(_ dataPoint: MistakeTypeData) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dataPoint.mistakeType.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(dataPoint.mistakeType.localizedName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(dataPoint.count) lỗi")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Achievements View
    
    @ViewBuilder
    private var achievementsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thành tích mới! 🎉")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.newAchievements, id: \.id) { achievement in
                        achievementCard(achievement)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 32))
                .foregroundColor(achievement.difficulty.color)
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Progress Comparison View
    
    @ViewBuilder
    private var progressComparisonView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("So với lần trước")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                comparisonMetric(
                    title: "Độ chính xác",
                    current: sessionResult.accuracy,
                    previous: viewModel.previousAccuracy,
                    format: .percentage
                )
                
                comparisonMetric(
                    title: "Điểm số",
                    current: Float(sessionResult.score),
                    previous: Float(viewModel.previousScore),
                    format: .number
                )
                
                comparisonMetric(
                    title: "Tốc độ",
                    current: sessionResult.wordsPerMinute,
                    previous: viewModel.previousSpeed,
                    format: .speed
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
    private func comparisonMetric(
        title: String,
        current: Float,
        previous: Float,
        format: MetricFormat
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(formatMetric(current, format: format))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if previous > 0 {
                    let change = current - previous
                    let changePercent = (change / previous) * 100
                    
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundColor(change >= 0 ? .green : .red)
                        
                        Text("\(abs(Int(changePercent)))%")
                            .font(.caption2)
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Recommendations View
    
    @ViewBuilder
    private var recommendationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gợi ý cải thiện")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.recommendations, id: \.id) { recommendation in
                    recommendationCard(recommendation)
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
    private func recommendationCard(_ recommendation: Recommendation) -> some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.icon)
                .font(.title3)
                .foregroundColor(recommendation.priority.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(recommendation.priority.color.opacity(0.1))
        )
    }
    
    // MARK: - Action Buttons View
    
    @ViewBuilder
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Primary actions
            HStack(spacing: 16) {
                Button(action: {
                    navigationCoordinator.startPracticeSession(
                        difficulty: sessionResult.difficulty,
                        category: sessionResult.category
                    )
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Luyện lại")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    let nextDifficulty = sessionResult.difficulty.nextLevel ?? sessionResult.difficulty
                    navigationCoordinator.startPracticeSession(
                        difficulty: nextDifficulty,
                        category: sessionResult.category
                    )
                }) {
                    HStack {
                        Image(systemName: "arrow.up")
                        Text("Thử thách")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .disabled(sessionResult.difficulty.nextLevel == nil)
            }
            
            // Secondary actions
            HStack(spacing: 16) {
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Chia sẻ")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    navigationCoordinator.returnToMainMenu()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Trang chủ")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startCelebrationAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase += 1
            }
        }
    }
    
    private func getSpeedLevel(wpm: Float) -> Int {
        switch wpm {
        case 0..<30:
            return 1
        case 30..<60:
            return 2
        case 60..<90:
            return 3
        case 90..<120:
            return 4
        default:
            return 5
        }
    }
    
    private func formatMetric(_ value: Float, format: MetricFormat) -> String {
        switch format {
        case .percentage:
            return "\(Int(value * 100))%"
        case .number:
            return "\(Int(value))"
        case .speed:
            return "\(Int(value)) từ/phút"
        }
    }
}

// MARK: - Supporting Enums and Extensions

enum MetricFormat {
    case percentage
    case number
    case speed
}

extension PerformanceLevel {
    var backgroundColor: Color {
        switch self {
        case .excellent:
            return Color.green
        case .good:
            return Color.blue
        case .fair:
            return Color.orange
        case .needsImprovement:
            return Color.red
        }
    }
    
    var color: Color {
        return backgroundColor
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "hand.thumbsup.fill"
        case .fair:
            return "face.smiling"
        case .needsImprovement:
            return "heart.fill"
        }
    }
    
    var celebrationMessage: String {
        switch self {
        case .excellent:
            return "Xuất sắc! 🌟"
        case .good:
            return "Làm tốt lắm! 👏"
        case .fair:
            return "Khá tốt! 😊"
        case .needsImprovement:
            return "Cố gắng lên! 💪"
        }
    }
    
    var encouragementMessage: String {
        switch self {
        case .excellent:
            return "Bé đọc rất chính xác và tự tin!"
        case .good:
            return "Bé đang tiến bộ rất tốt!"
        case .fair:
            return "Bé đã cố gắng rất nhiều!"
        case .needsImprovement:
            return "Lần sau sẽ tốt hơn nữa!"
        }
    }
}

// MARK: - Preview
struct SessionResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SessionResultsView(
            sessionResult: SessionResult(
                userId: "test_user",
                exerciseId: UUID(),
                originalText: "Con mèo nhỏ ngồi trên thảm xanh",
                spokenText: "Con mèo nhỏ ngồi trên thảm xanh",
                accuracy: 0.95,
                score: 95,
                timeSpent: 120,
                difficulty: .grade2,
                inputMethod: .voice
            )
        )
        .environmentObject(NavigationCoordinator())
        .environmentObject(RewardSystem(progressTracker: ProgressTrackingFactory.shared.getProgressTracker()))
    }
}