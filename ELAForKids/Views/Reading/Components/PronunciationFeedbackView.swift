import SwiftUI

// MARK: - Pronunciation Feedback View
struct PronunciationFeedbackView: View {
    let isRecording: Bool
    let currentWord: String?
    let feedback: PronunciationFeedback?
    let onRetry: (() -> Void)?
    
    @Environment(\.adaptiveLayout) private var layout
    @State private var pulseAnimation: Bool = false
    @State private var feedbackAnimation: Bool = false
    @State private var showFeedback: Bool = false
    
    var body: some View {
        VStack(spacing: layout.sectionSpacing / 2) {
            if isRecording {
                recordingIndicatorView
            } else if let feedback = feedback {
                feedbackResultView(feedback)
            } else {
                readyStateView
            }
        }
        .onChange(of: feedback) { newFeedback in
            if newFeedback != nil {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showFeedback = true
                    feedbackAnimation = true
                }
                
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        feedbackAnimation = false
                    }
                }
            }
        }
        .onChange(of: isRecording) { recording in
            pulseAnimation = recording
        }
    }
    
    // MARK: - Recording Indicator View
    private var recordingIndicatorView: some View {
        VStack(spacing: 16) {
            // Animated microphone icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: microphoneCircleSize, height: microphoneCircleSize)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: microphoneIconSize))
                    .foregroundColor(.red)
            }
            
            // Current word being recorded
            if let currentWord = currentWord {
                VStack(spacing: 8) {
                    Text("Đang đọc:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currentWord)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            
            // Recording instruction
            Text("Đọc rõ ràng và chậm rãi")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(layout.contentPadding)
        .background(Color(.systemBackground))
        .cornerRadius(layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Feedback Result View
    private func feedbackResultView(_ feedback: PronunciationFeedback) -> some View {
        VStack(spacing: 16) {
            // Feedback icon with animation
            ZStack {
                Circle()
                    .fill(feedback.isCorrect ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: feedbackCircleSize, height: feedbackCircleSize)
                    .scaleEffect(feedbackAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: feedbackAnimation)
                
                Image(systemName: feedback.icon)
                    .font(.system(size: feedbackIconSize))
                    .foregroundColor(feedback.isCorrect ? .green : .orange)
                    .scaleEffect(feedbackAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: feedbackAnimation)
            }
            
            // Feedback message
            VStack(spacing: 8) {
                Text(feedback.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(feedback.isCorrect ? .green : .orange)
                
                Text(feedback.message)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Word comparison (if applicable)
            if let expectedWord = feedback.expectedWord, let spokenWord = feedback.spokenWord {
                wordComparisonView(expected: expectedWord, spoken: spokenWord, isCorrect: feedback.isCorrect)
            }
            
            // Retry button (if not correct)
            if !feedback.isCorrect, let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(.body, weight: .medium))
                        Text("Thử lại")
                            .font(.system(.body, design: .rounded, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .scaleEffect(feedbackAnimation ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: feedbackAnimation)
            }
        }
        .padding(layout.contentPadding)
        .background(Color(.systemBackground))
        .cornerRadius(layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .stroke(feedback.isCorrect ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Ready State View
    private var readyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Sẵn sàng ghi âm")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Nhấn nút ghi âm để bắt đầu")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(layout.contentPadding)
        .background(Color(.systemGray6))
        .cornerRadius(layout.cornerRadius)
    }
    
    // MARK: - Word Comparison View
    private func wordComparisonView(expected: String, spoken: String, isCorrect: Bool) -> some View {
        HStack(spacing: 16) {
            // Expected word
            VStack(spacing: 4) {
                Text("Từ đúng")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(expected)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Image(systemName: isCorrect ? "checkmark" : "arrow.right")
                .font(.caption)
                .foregroundColor(isCorrect ? .green : .secondary)
            
            // Spoken word
            VStack(spacing: 4) {
                Text("Bé đọc")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(spoken.isEmpty ? "(không nghe rõ)" : spoken)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(isCorrect ? .green : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((isCorrect ? Color.green : Color.orange).opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    private var microphoneCircleSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 80
        case .regular: return 90
        case .large: return 100
        }
    }
    
    private var microphoneIconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 30
        case .regular: return 35
        case .large: return 40
        }
    }
    
    private var feedbackCircleSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 70
        case .regular: return 80
        case .large: return 90
        }
    }
    
    private var feedbackIconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 25
        case .regular: return 30
        case .large: return 35
        }
    }
}

// MARK: - Pronunciation Feedback Model
struct PronunciationFeedback: Equatable {
    let isCorrect: Bool
    let expectedWord: String?
    let spokenWord: String?
    let confidence: Float
    let title: String
    let message: String
    
    var icon: String {
        if isCorrect {
            return "checkmark.circle.fill"
        } else if confidence > 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    static func == (lhs: PronunciationFeedback, rhs: PronunciationFeedback) -> Bool {
        return lhs.isCorrect == rhs.isCorrect &&
               lhs.expectedWord == rhs.expectedWord &&
               lhs.spokenWord == rhs.spokenWord &&
               lhs.confidence == rhs.confidence
    }
}

// MARK: - Pronunciation Feedback Factory
extension PronunciationFeedback {
    static func correct(expectedWord: String, spokenWord: String) -> PronunciationFeedback {
        PronunciationFeedback(
            isCorrect: true,
            expectedWord: expectedWord,
            spokenWord: spokenWord,
            confidence: 1.0,
            title: "Tuyệt vời! 🎉",
            message: "Bé đã phát âm chính xác!"
        )
    }
    
    static func mispronunciation(expectedWord: String, spokenWord: String, confidence: Float) -> PronunciationFeedback {
        PronunciationFeedback(
            isCorrect: false,
            expectedWord: expectedWord,
            spokenWord: spokenWord,
            confidence: confidence,
            title: "Gần đúng rồi! 😊",
            message: "Hãy thử phát âm rõ ràng hơn nhé!"
        )
    }
    
    static func incorrect(expectedWord: String, spokenWord: String) -> PronunciationFeedback {
        PronunciationFeedback(
            isCorrect: false,
            expectedWord: expectedWord,
            spokenWord: spokenWord,
            confidence: 0.0,
            title: "Chưa đúng 🤔",
            message: "Hãy nghe lại từ đúng và thử lần nữa!"
        )
    }
    
    static func notHeard(expectedWord: String) -> PronunciationFeedback {
        PronunciationFeedback(
            isCorrect: false,
            expectedWord: expectedWord,
            spokenWord: nil,
            confidence: 0.0,
            title: "Không nghe rõ 👂",
            message: "Hãy đọc to và rõ ràng hơn nhé!"
        )
    }
}

// MARK: - Preview
struct PronunciationFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Recording state
            PronunciationFeedbackView(
                isRecording: true,
                currentWord: "mèo",
                feedback: nil,
                onRetry: nil
            )
            
            // Correct feedback
            PronunciationFeedbackView(
                isRecording: false,
                currentWord: nil,
                feedback: .correct(expectedWord: "mèo", spokenWord: "mèo"),
                onRetry: nil
            )
            
            // Incorrect feedback
            PronunciationFeedbackView(
                isRecording: false,
                currentWord: nil,
                feedback: .mispronunciation(expectedWord: "mèo", spokenWord: "meo", confidence: 0.7),
                onRetry: {
                    print("Retry tapped")
                }
            )
            
            // Ready state
            PronunciationFeedbackView(
                isRecording: false,
                currentWord: nil,
                feedback: nil,
                onRetry: nil
            )
        }
        .padding()
        .adaptiveLayout()
    }
}