import SwiftUI

// MARK: - Mistake Feedback View
struct MistakeFeedbackView: View {
    let mistakes: [TextMistake]
    let onRetryWord: ((TextMistake) -> Void)?
    let onPlayCorrectPronunciation: ((String) -> Void)?
    
    @Environment(\.adaptiveLayout) private var layout
    @State private var expandedMistakes: Set<Int> = []
    @State private var animatingMistakes: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
            if mistakes.isEmpty {
                emptyStateView
            } else {
                headerView
                mistakeListView
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                AdaptiveText("Tuyệt vời!", style: .title)
                    .foregroundColor(.green)
                
                AdaptiveText("Bé đã đọc hoàn hảo! Không có lỗi nào cả.", style: .body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                AdaptiveText("Cần cải thiện", style: .headline)
                AdaptiveText("\(mistakes.count) từ cần luyện tập thêm", style: .caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedMistakes.count == mistakes.count {
                        expandedMistakes.removeAll()
                    } else {
                        expandedMistakes = Set(0..<mistakes.count)
                    }
                }
            }) {
                Image(systemName: expandedMistakes.count == mistakes.count ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Mistake List View
    private var mistakeListView: some View {
        LazyVStack(spacing: layout.sectionSpacing / 3) {
            ForEach(Array(mistakes.enumerated()), id: \.offset) { index, mistake in
                mistakeCardView(mistake: mistake, index: index)
            }
        }
    }
    
    // MARK: - Mistake Card View
    private func mistakeCardView(mistake: TextMistake, index: Int) -> some View {
        let isExpanded = expandedMistakes.contains(index)
        let isAnimating = animatingMistakes.contains(index)
        
        return VStack(spacing: 0) {
            // Main mistake info
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isExpanded {
                        expandedMistakes.remove(index)
                    } else {
                        expandedMistakes.insert(index)
                    }
                }
            }) {
                HStack(spacing: 12) {
                    // Mistake type icon
                    mistakeTypeIcon(mistake.mistakeType)
                    
                    // Mistake info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(mistake.mistakeType.localizedName)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            severityBadge(mistake.severity)
                        }
                        
                        Text(mistake.description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(layout.contentPadding / 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: layout.sectionSpacing / 3) {
                    Divider()
                    
                    // Detailed explanation
                    detailedExplanationView(mistake: mistake)
                    
                    // Action buttons
                    actionButtonsView(mistake: mistake, index: index)
                }
                .padding(.horizontal, layout.contentPadding / 2)
                .padding(.bottom, layout.contentPadding / 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(mistakeBackgroundColor(mistake.mistakeType))
        .cornerRadius(layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .stroke(mistakeBorderColor(mistake.mistakeType), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isAnimating)
    }
    
    // MARK: - Detailed Explanation View
    private func detailedExplanationView(mistake: TextMistake) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Word comparison
            if !mistake.expectedWord.isEmpty && !mistake.actualWord.isEmpty {
                wordComparisonView(expected: mistake.expectedWord, actual: mistake.actualWord)
            }
            
            // Suggestion
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 2)
                
                Text(mistake.suggestion)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - Word Comparison View
    private func wordComparisonView(expected: String, actual: String) -> some View {
        HStack(spacing: 16) {
            // Expected word
            VStack(alignment: .leading, spacing: 4) {
                Text("Từ đúng:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(expected)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Actual word
            VStack(alignment: .leading, spacing: 4) {
                Text("Bé đọc:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(actual.isEmpty ? "(bỏ sót)" : actual)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons View
    private func actionButtonsView(mistake: TextMistake, index: Int) -> some View {
        HStack(spacing: 12) {
            // Retry button
            if let onRetryWord = onRetryWord {
                Button(action: {
                    animateMistake(at: index)
                    onRetryWord(mistake)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.circle.fill")
                            .font(.caption)
                        Text("Đọc lại")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            
            // Play correct pronunciation button
            if let onPlayCorrectPronunciation = onPlayCorrectPronunciation, !mistake.expectedWord.isEmpty {
                Button(action: {
                    animateMistake(at: index)
                    onPlayCorrectPronunciation(mistake.expectedWord)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                        Text("Nghe mẫu")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Views
    private func mistakeTypeIcon(_ mistakeType: MistakeType) -> some View {
        let (icon, color) = iconAndColorForMistakeType(mistakeType)
        
        return Image(systemName: icon)
            .font(.title3)
            .foregroundColor(color)
            .frame(width: 24, height: 24)
    }
    
    private func severityBadge(_ severity: MistakeSeverity) -> some View {
        Text(severity.localizedName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForSeverity(severity))
            .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
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
    
    private func mistakeBackgroundColor(_ mistakeType: MistakeType) -> Color {
        switch mistakeType {
        case .substitution:
            return Color.red.opacity(0.05)
        case .mispronunciation:
            return Color.orange.opacity(0.05)
        case .omission:
            return Color.blue.opacity(0.05)
        case .insertion:
            return Color.purple.opacity(0.05)
        }
    }
    
    private func mistakeBorderColor(_ mistakeType: MistakeType) -> Color {
        switch mistakeType {
        case .substitution:
            return Color.red.opacity(0.3)
        case .mispronunciation:
            return Color.orange.opacity(0.3)
        case .omission:
            return Color.blue.opacity(0.3)
        case .insertion:
            return Color.purple.opacity(0.3)
        }
    }
    
    private func colorForSeverity(_ severity: MistakeSeverity) -> Color {
        switch severity {
        case .minor:
            return .yellow
        case .moderate:
            return .orange
        case .major:
            return .red
        }
    }
    
    private func animateMistake(at index: Int) {
        animatingMistakes.insert(index)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animatingMistakes.remove(index)
        }
    }
}

// MARK: - Preview
struct MistakeFeedbackView_Previews: PreviewProvider {
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
            ),
            TextMistake(
                position: 5,
                expectedWord: "",
                actualWord: "nhỏ",
                mistakeType: .insertion,
                severity: .minor
            )
        ]
        
        ScrollView {
            VStack(spacing: 20) {
                // With mistakes
                MistakeFeedbackView(
                    mistakes: sampleMistakes,
                    onRetryWord: { mistake in
                        print("Retry word: \(mistake.expectedWord)")
                    },
                    onPlayCorrectPronunciation: { word in
                        print("Play pronunciation for: \(word)")
                    }
                )
                
                // No mistakes
                MistakeFeedbackView(
                    mistakes: [],
                    onRetryWord: nil,
                    onPlayCorrectPronunciation: nil
                )
            }
            .padding()
        }
        .adaptiveLayout()
    }
}