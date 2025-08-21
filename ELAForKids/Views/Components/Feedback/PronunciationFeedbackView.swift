import SwiftUI

// MARK: - Pronunciation Feedback View
struct PronunciationFeedbackView: View {
    let attempt: ReadingAttempt
    let onWordTap: (String) -> Void
    let onRetry: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var animateCorrectWords = false
    @State private var animateErrors = false
    @State private var showDetailedFeedback = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with overall score
            feedbackHeader
            
            // Word-by-word feedback
            wordFeedbackSection
            
            // Detailed feedback (expandable)
            if showDetailedFeedback {
                detailedFeedbackSection
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Action buttons
            actionButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            animateFeedback()
        }
    }
    
    // MARK: - Header Section
    
    private var feedbackHeader: some View {
        VStack(spacing: 12) {
            // Accuracy circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(attempt.accuracy))
                    .stroke(
                        accuracyColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animateCorrectWords)
                
                Text("\(Int(attempt.accuracy * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(accuracyColor)
                    .accessibilityLabel("Độ chính xác: \(Int(attempt.accuracy * 100)) phần trăm")
            }
            
            // Encouragement message
            Text(encouragementMessage)
                .font(.headline)
                .foregroundColor(accuracyColor)
                .multilineTextAlignment(.center)
                .scaleEffect(animateCorrectWords ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateCorrectWords)
        }
    }
    
    // MARK: - Word Feedback Section
    
    private var wordFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Kết quả từng từ:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        showDetailedFeedback.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Chi tiết")
                            .font(.caption)
                        Image(systemName: showDetailedFeedback ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Word grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(attempt.feedback.enumerated()), id: \.offset) { index, feedback in
                    WordFeedbackCard(
                        feedback: feedback,
                        isAnimated: animateErrors,
                        onTap: {
                            onWordTap(feedback.expectedWord)
                        }
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateErrors)
                }
            }
        }
    }
    
    // MARK: - Detailed Feedback Section
    
    private var detailedFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phân tích chi tiết:")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Statistics
            HStack(spacing: 20) {
                StatisticCard(
                    title: "Từ đúng",
                    value: "\(attempt.correctWords)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatisticCard(
                    title: "Lỗi",
                    value: "\(attempt.errors.count)",
                    color: .red,
                    icon: "xmark.circle.fill"
                )
                
                StatisticCard(
                    title: "Độ tin cậy",
                    value: "\(Int(attempt.confidence * 100))%",
                    color: .blue,
                    icon: "waveform"
                )
            }
            
            // Error breakdown
            if !attempt.errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Các lỗi cần cải thiện:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(attempt.errors, id: \.position) { error in
                        ErrorDetailRow(error: error) {
                            onWordTap(error.expectedWord)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Retry button
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Thử lại")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue)
                )
            }
            .scaleEffect(animateCorrectWords ? 1.0 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateCorrectWords)
            .accessibilityLabel("Thử lại")
            .accessibilityHint("Nhấn đúp để đọc lại đoạn văn")
            .accessibilityAddTraits(.isButton)
            
            // Practice difficult words button
            if !attempt.errors.isEmpty {
                Button(action: {
                    // Practice the first error word
                    if let firstError = attempt.errors.first {
                        onWordTap(firstError.expectedWord)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "book")
                        Text("Luyện từ khó")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                }
                .scaleEffect(animateErrors ? 1.0 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: animateErrors)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var accuracyColor: Color {
        switch attempt.accuracy {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return .blue
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
    
    private var encouragementMessage: String {
        switch attempt.accuracy {
        case 0.9...1.0:
            return "Tuyệt vời! Bé đọc rất hay! 🌟"
        case 0.8..<0.9:
            return "Rất tốt! Bé đang tiến bộ! 👏"
        case 0.6..<0.8:
            return "Khá tốt! Cố gắng thêm nhé! 📚"
        case 0.4..<0.6:
            return "Bé có thể làm tốt hơn! 💪"
        default:
            return "Đừng lo! Hãy thử lại nhé! 🤗"
        }
    }
    
    // MARK: - Animation
    
    private func animateFeedback() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animateCorrectWords = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateErrors = true
            }
        }
    }
}

// MARK: - Word Feedback Card

struct WordFeedbackCard: View {
    let feedback: FeedbackItem
    let isAnimated: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Word text
                Text(feedback.expectedWord.isEmpty ? feedback.actualWord : feedback.expectedWord)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(feedback.type.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Status indicator
                Image(systemName: feedback.type.iconName)
                    .font(.caption)
                    .foregroundColor(feedback.type.color)
                    .scaleEffect(isAnimated ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimated)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(feedback.type.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(feedback.type.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .opacity(isAnimated ? 1.0 : 0.6)
    }
}

// MARK: - Statistic Card

struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Error Detail Row

struct ErrorDetailRow: View {
    let error: FeedbackItem
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Error type icon
            Image(systemName: error.type.iconName)
                .font(.title3)
                .foregroundColor(error.type.color)
                .frame(width: 24)
            
            // Error description
            VStack(alignment: .leading, spacing: 2) {
                Text(error.type.localizedDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if !error.expectedWord.isEmpty && !error.actualWord.isEmpty {
                    HStack(spacing: 8) {
                        Text("Mong đợi:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(error.expectedWord)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("→")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Nhận được:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(error.actualWord)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                
                Text(error.suggestion)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Practice button
            Button(action: onTap) {
                Image(systemName: "speaker.wave.2")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension FeedbackItem.FeedbackType {
    var iconName: String {
        switch self {
        case .correct:
            return "checkmark.circle.fill"
        case .mispronunciation:
            return "waveform.badge.exclamationmark"
        case .missing:
            return "minus.circle.fill"
        case .extra:
            return "plus.circle.fill"
        }
    }
}

// MARK: - Preview

struct PronunciationFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAttempt = ReadingAttempt(
            recognizedText: "Con mèo ngồi trên thảm",
            targetText: "Con mèo nhỏ ngồi trên thảm xanh",
            accuracy: 0.75,
            confidence: 0.85,
            timestamp: Date(),
            feedback: [
                FeedbackItem(
                    type: .correct,
                    position: 0,
                    expectedWord: "Con",
                    actualWord: "Con",
                    suggestion: "Đúng rồi!"
                ),
                FeedbackItem(
                    type: .correct,
                    position: 1,
                    expectedWord: "mèo",
                    actualWord: "mèo",
                    suggestion: "Đúng rồi!"
                ),
                FeedbackItem(
                    type: .missing,
                    position: 2,
                    expectedWord: "nhỏ",
                    actualWord: "",
                    suggestion: "Thiếu từ: nhỏ"
                ),
                FeedbackItem(
                    type: .correct,
                    position: 3,
                    expectedWord: "ngồi",
                    actualWord: "ngồi",
                    suggestion: "Đúng rồi!"
                ),
                FeedbackItem(
                    type: .correct,
                    position: 4,
                    expectedWord: "trên",
                    actualWord: "trên",
                    suggestion: "Đúng rồi!"
                ),
                FeedbackItem(
                    type: .correct,
                    position: 5,
                    expectedWord: "thảm",
                    actualWord: "thảm",
                    suggestion: "Đúng rồi!"
                ),
                FeedbackItem(
                    type: .missing,
                    position: 6,
                    expectedWord: "xanh",
                    actualWord: "",
                    suggestion: "Thiếu từ: xanh"
                )
            ]
        )
        
        PronunciationFeedbackView(
            attempt: sampleAttempt,
            onWordTap: { word in
                print("Tapped word: \(word)")
            },
            onRetry: {
                print("Retry tapped")
            }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}