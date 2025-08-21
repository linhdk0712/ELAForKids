import SwiftUI

// MARK: - Reading Results View
struct ReadingResultsView: View {
    let sessionResult: SessionResult
    @StateObject private var viewModel = ReadingResultsViewModel()
    @Environment(\.navigationCoordinator) private var navigationCoordinator
    @Environment(\.adaptiveLayout) private var layout
    
    var body: some View {
        ResponsiveLayout {
            AdaptiveContainer {
                ScrollView {
                    LazyVStack(spacing: layout.sectionSpacing) {
                        // Header with score and performance
                        headerSection
                        
                        // Text with highlighting
                        textHighlightSection
                        
                        // Detailed mistake feedback
                        mistakeFeedbackSection
                        
                        // Performance insights
                        performanceInsightsSection
                        
                        // Action buttons
                        actionButtonsSection
                    }
                }
            }
        }
        .adaptiveLayout()
        .navigationTitle("Kết quả")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.send(.loadResults(sessionResult))
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
                // Performance icon and category
                VStack(spacing: 8) {
                    Image(systemName: performanceIcon)
                        .font(.system(size: headerIconSize))
                        .foregroundColor(performanceColor)
                        .scaleEffect(viewModel.state.isAnimatingScore ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatCount(3), value: viewModel.state.isAnimatingScore)
                    
                    AdaptiveText(performanceTitle, style: .title)
                        .foregroundColor(performanceColor)
                        .multilineTextAlignment(.center)
                }
                
                // Score and accuracy
                HStack(spacing: layout.sectionSpacing) {
                    scoreCard(
                        title: "Điểm số",
                        value: "\(sessionResult.score)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    scoreCard(
                        title: "Độ chính xác",
                        value: "\(Int(sessionResult.accuracy * 100))%",
                        icon: "target",
                        color: .blue
                    )
                    
                    scoreCard(
                        title: "Thời gian",
                        value: formattedTime,
                        icon: "clock.fill",
                        color: .green
                    )
                }
                
                // Encouraging message
                AdaptiveText(sessionResult.comparisonResult?.feedback ?? "", style: .body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Text Highlight Section
    private var textHighlightSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                HStack {
                    AdaptiveText("Văn bản đã đọc", style: .headline)
                    
                    Spacer()
                    
                    if !sessionResult.mistakes.isEmpty {
                        Button(action: {
                            viewModel.send(.toggleTextHighlight)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.state.showTextHighlight ? "eye.slash" : "eye")
                                    .font(.caption)
                                Text(viewModel.state.showTextHighlight ? "Ẩn lỗi" : "Hiện lỗi")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                if viewModel.state.showTextHighlight {
                    TextHighlightView(
                        text: sessionResult.originalText,
                        mistakes: sessionResult.mistakes,
                        matchedWords: sessionResult.comparisonResult?.matchedWords ?? []
                    ) { word, index in
                        viewModel.send(.selectWord(word, index))
                    }
                } else {
                    Text(sessionResult.originalText)
                        .font(.system(.body, design: .rounded))
                        .padding(layout.contentPadding / 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(layout.cornerRadius)
                }
            }
        }
    }
    
    // MARK: - Mistake Feedback Section
    private var mistakeFeedbackSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                AdaptiveText("Chi tiết lỗi", style: .headline)
                
                MistakeFeedbackView(
                    mistakes: sessionResult.mistakes,
                    onRetryWord: { mistake in
                        viewModel.send(.retryWord(mistake))
                    },
                    onPlayCorrectPronunciation: { word in
                        viewModel.send(.playCorrectPronunciation(word))
                    }
                )
            }
        }
    }
    
    // MARK: - Performance Insights Section
    private var performanceInsightsSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                AdaptiveText("Phân tích kết quả", style: .headline)
                
                LazyVGrid(columns: insightColumns, spacing: layout.sectionSpacing / 2) {
                    insightCard(
                        title: "Tổng số từ",
                        value: "\(sessionResult.comparisonResult?.totalWords ?? 0)",
                        icon: "textformat",
                        color: .blue
                    )
                    
                    insightCard(
                        title: "Từ đúng",
                        value: "\(sessionResult.comparisonResult?.correctWords ?? 0)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    insightCard(
                        title: "Từ sai",
                        value: "\(sessionResult.mistakes.count)",
                        icon: "xmark.circle",
                        color: .red
                    )
                    
                    insightCard(
                        title: "Loại lỗi",
                        value: "\(uniqueMistakeTypes.count)",
                        icon: "exclamationmark.triangle",
                        color: .orange
                    )
                }
                
                // Mistake type breakdown
                if !sessionResult.mistakes.isEmpty {
                    mistakeTypeBreakdownView
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        OrientationLayout {
            // Portrait Layout
            VStack(spacing: layout.sectionSpacing / 2) {
                primaryActionButtons
                secondaryActionButtons
            }
        } landscape: {
            // Landscape Layout
            VStack(spacing: layout.sectionSpacing / 2) {
                HStack(spacing: layout.sectionSpacing) {
                    primaryActionButtons
                }
                HStack(spacing: layout.sectionSpacing) {
                    secondaryActionButtons
                }
            }
        }
    }
    
    private var primaryActionButtons: some View {
        HStack(spacing: layout.sectionSpacing / 2) {
            AdaptiveButton(
                "Đọc lại",
                icon: "arrow.clockwise",
                style: .secondary
            ) {
                viewModel.send(.retryReading)
            }
            
            AdaptiveButton(
                "Tiếp tục",
                icon: "arrow.right.circle.fill",
                style: .primary
            ) {
                viewModel.send(.continueToNext)
            }
        }
    }
    
    private var secondaryActionButtons: some View {
        HStack(spacing: layout.sectionSpacing / 2) {
            AdaptiveButton(
                "Lưu kết quả",
                icon: "square.and.arrow.down",
                style: .tertiary
            ) {
                viewModel.send(.saveResults)
            }
            
            AdaptiveButton(
                "Chia sẻ",
                icon: "square.and.arrow.up",
                style: .tertiary
            ) {
                viewModel.send(.shareResults)
            }
        }
    }
    
    // MARK: - Helper Views
    private func scoreCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, layout.contentPadding / 2)
        .background(color.opacity(0.1))
        .cornerRadius(layout.cornerRadius)
    }
    
    private func insightCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(layout.contentPadding / 3)
        .background(Color(.systemGray6))
        .cornerRadius(layout.cornerRadius / 2)
    }
    
    private var mistakeTypeBreakdownView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phân loại lỗi:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(mistakeTypeBreakdown, id: \.type) { breakdown in
                HStack {
                    Image(systemName: breakdown.icon)
                        .font(.caption)
                        .foregroundColor(breakdown.color)
                        .frame(width: 16)
                    
                    Text(breakdown.type.localizedName)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(breakdown.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(layout.contentPadding / 3)
        .background(Color(.systemBackground))
        .cornerRadius(layout.cornerRadius / 2)
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius / 2)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    private var performanceIcon: String {
        guard let result = sessionResult.comparisonResult else { return "questionmark.circle" }
        return result.performanceCategory.emoji.isEmpty ? "star.circle.fill" : "star.circle.fill"
    }
    
    private var performanceColor: Color {
        guard let result = sessionResult.comparisonResult else { return .gray }
        switch result.performanceCategory {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .needsImprovement:
            return .red
        }
    }
    
    private var performanceTitle: String {
        guard let result = sessionResult.comparisonResult else { return "Kết quả" }
        return result.performanceCategory.localizedName
    }
    
    private var headerIconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 60
        case .regular: return 70
        case .large: return 80
        }
    }
    
    private var formattedTime: String {
        let minutes = Int(sessionResult.timeSpent) / 60
        let seconds = Int(sessionResult.timeSpent) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var insightColumns: [GridItem] {
        let columnCount: Int
        switch layout.deviceType {
        case .iPhone:
            columnCount = layout.orientation == .portrait ? 2 : 4
        case .iPad:
            columnCount = 4
        case .mac:
            columnCount = 4
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
    
    private var uniqueMistakeTypes: Set<MistakeType> {
        Set(sessionResult.mistakes.map { $0.mistakeType })
    }
    
    private var mistakeTypeBreakdown: [(type: MistakeType, count: Int, icon: String, color: Color)] {
        let mistakeGroups = Dictionary(grouping: sessionResult.mistakes) { $0.mistakeType }
        
        return mistakeGroups.map { (type, mistakes) in
            let (icon, color) = iconAndColorForMistakeType(type)
            return (type: type, count: mistakes.count, icon: icon, color: color)
        }.sorted { $0.count > $1.count }
    }
    
    private func iconAndColorForMistakeType(_ mistakeType: MistakeType) -> (String, Color) {
        switch mistakeType {
        case .substitution:
            return ("xmark.circle.fill", .red)
        case .mispronunciation:
            return ("exclamationmark.triangle.fill", .orange)
        case .omission:
            return ("minus.circle.fill", .blue)
        case .insertion:
            return ("plus.circle.fill", .purple)
        }
    }
}

// MARK: - Preview
struct ReadingResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMistakes = [
            TextMistake(
                position: 1,
                expectedWord: "mèo",
                actualWord: "chó",
                mistakeType: .substitution,
                severity: .moderate
            ),
            TextMistake(
                position: 3,
                expectedWord: "trên",
                actualWord: "",
                mistakeType: .omission,
                severity: .moderate
            ),
            TextMistake(
                position: 4,
                expectedWord: "thảm",
                actualWord: "tảm",
                mistakeType: .mispronunciation,
                severity: .minor
            )
        ]
        
        let comparisonResult = ComparisonResult(
            originalText: "Con mèo ngồi trên thảm xanh",
            spokenText: "Con chó ngồi tảm xanh",
            accuracy: 0.67,
            mistakes: sampleMistakes,
            matchedWords: ["Con", "ngồi", "xanh"],
            feedback: "Khá tốt! Hãy cố gắng đọc chậm và rõ hơn nhé! 😊"
        )
        
        let sessionResult = SessionResult(
            userId: "user123",
            exerciseId: UUID(),
            originalText: "Con mèo ngồi trên thảm xanh",
            spokenText: "Con chó ngồi tảm xanh",
            accuracy: 0.67,
            score: 67,
            timeSpent: 45.5,
            mistakes: sampleMistakes,
            completedAt: Date(),
            difficulty: .grade2,
            inputMethod: .voice,
            comparisonResult: comparisonResult
        )
        
        NavigationStack {
            ReadingResultsView(sessionResult: sessionResult)
                .withNavigationCoordinator(NavigationCoordinator())
        }
    }
}