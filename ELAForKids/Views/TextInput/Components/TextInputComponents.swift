import SwiftUI

// MARK: - Text Statistics View
struct TextStatisticsView: View {
    let statistics: TextStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thống kê văn bản")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatisticCard(
                    title: "Số từ",
                    value: "\(statistics.wordCount)",
                    icon: "textformat",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Số câu",
                    value: "\(statistics.sentenceCount)",
                    icon: "text.quote",
                    color: .green
                )
                
                StatisticCard(
                    title: "Thời gian đọc",
                    value: statistics.formattedReadingTime,
                    icon: "clock",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Độ khó",
                    value: statistics.difficulty.displayName,
                    icon: "chart.bar",
                    color: Color(statistics.difficulty.color)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
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
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Text Input Toolbar
struct TextInputToolbar: View {
    let onClear: () -> Void
    let onFormat: () -> Void
    let onStatistics: () -> Void
    let canClear: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ToolbarButton(
                title: "Xóa hết",
                icon: "trash",
                color: .red,
                action: onClear
            )
            .disabled(!canClear)
            
            ToolbarButton(
                title: "Định dạng",
                icon: "textformat",
                color: .blue,
                action: onFormat
            )
            .disabled(!canClear)
            
            ToolbarButton(
                title: "Thống kê",
                icon: "chart.bar",
                color: .green,
                action: onStatistics
            )
            .disabled(!canClear)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text Input Progress
struct TextInputProgress: View {
    let currentCount: Int
    let minimumCount: Int
    let maximumCount: Int
    
    private var progress: Double {
        Double(currentCount) / Double(minimumCount)
    }
    
    private var isMinimumReached: Bool {
        currentCount >= minimumCount
    }
    
    private var progressColor: Color {
        if currentCount >= maximumCount {
            return .red
        } else if isMinimumReached {
            return .green
        } else if progress >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tiến độ")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(currentCount)/\(maximumCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(y: 2)
            
            HStack {
                if isMinimumReached {
                    Label("Đủ điều kiện tiếp tục", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Cần thêm \(minimumCount - currentCount) từ", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Sample Text Grid
struct SampleTextGrid: View {
    let sampleTexts: [String]
    let onTextSelected: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(sampleTexts, id: \.self) { text in
                SampleTextCard(text: text) {
                    onTextSelected(text)
                }
            }
        }
    }
}

// MARK: - Enhanced Sample Text Card
struct EnhancedSampleTextCard: View {
    let text: String
    let statistics: TextStatistics
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Divider()
                
                HStack {
                    Label("\(statistics.wordCount) từ", systemImage: "textformat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(statistics.difficulty.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(statistics.difficulty.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(statistics.difficulty.color).opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text Input Tips
struct TextInputTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mẹo viết văn bản hay")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(
                    icon: "lightbulb",
                    text: "Viết về những điều bạn thích hoặc trải nghiệm của bạn",
                    color: .yellow
                )
                
                TipRow(
                    icon: "textformat",
                    text: "Sử dụng từ ngữ đơn giản và dễ hiểu",
                    color: .blue
                )
                
                TipRow(
                    icon: "quote.bubble",
                    text: "Chia thành các câu ngắn để dễ đọc",
                    color: .green
                )
                
                TipRow(
                    icon: "checkmark.circle",
                    text: "Kiểm tra lại chính tả trước khi hoàn thành",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct TextInputComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextStatisticsView(statistics: TextStatistics(
                    characterCount: 45,
                    wordCount: 8,
                    sentenceCount: 2,
                    estimatedReadingTime: 3.84,
                    difficulty: .easy
                ))
                
                TextInputProgress(
                    currentCount: 8,
                    minimumCount: 10,
                    maximumCount: 100
                )
                
                TextInputTips()
            }
            .padding()
        }
    }
}