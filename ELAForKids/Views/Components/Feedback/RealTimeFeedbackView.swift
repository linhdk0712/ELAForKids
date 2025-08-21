import SwiftUI

// MARK: - Real-Time Feedback View
struct RealTimeFeedbackView: View {
    let targetText: String
    let recognizedText: String
    let confidence: Float
    let audioLevel: Float
    let isRecording: Bool
    
    @State private var animateWords = false
    @State private var pulseAnimation = false
    @State private var waveAnimation = false
    
    private let words: [String]
    private let recognizedWords: [String]
    
    init(targetText: String, recognizedText: String, confidence: Float, audioLevel: Float, isRecording: Bool) {
        self.targetText = targetText
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.audioLevel = audioLevel
        self.isRecording = isRecording
        
        self.words = targetText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        self.recognizedWords = recognizedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Recording status indicator
            recordingStatusView
            
            // Target text with real-time highlighting
            targetTextView
            
            // Audio level indicator
            audioLevelView
            
            // Confidence meter
            confidenceMeterView
            
            // Real-time suggestions
            if isRecording && !recognizedText.isEmpty {
                realTimeSuggestionsView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            startAnimations()
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startRecordingAnimations()
            } else {
                stopRecordingAnimations()
            }
        }
    }
    
    // MARK: - Recording Status View
    
    private var recordingStatusView: some View {
        HStack(spacing: 12) {
            // Recording indicator
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseAnimation && isRecording ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
            
            Text(isRecording ? "Đang ghi âm..." : "Sẵn sàng ghi âm")
                .font(.headline)
                .foregroundColor(isRecording ? .red : .gray)
            
            Spacer()
            
            // Confidence indicator
            if isRecording && confidence > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(confidenceColor)
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(confidenceColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(confidenceColor.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Target Text View
    
    private var targetTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Đọc theo:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Word-by-word display with real-time feedback
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    WordHighlightView(
                        word: word,
                        status: getWordStatus(at: index),
                        isAnimated: animateWords
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05), value: animateWords)
                }
            }
        }
    }
    
    // MARK: - Audio Level View
    
    private var audioLevelView: some View {
        VStack(spacing: 8) {
            Text("Âm lượng:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(audioBarColor(for: index))
                        .frame(width: 3, height: audioBarHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)
                }
            }
            .frame(height: 20)
        }
    }
    
    // MARK: - Confidence Meter View
    
    private var confidenceMeterView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Độ chính xác:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(confidenceDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: confidence)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Real-Time Suggestions View
    
    private var realTimeSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gợi ý:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(getRealTimeSuggestions(), id: \.self) { suggestion in
                        SuggestionChip(text: suggestion)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func getWordStatus(at index: Int) -> WordStatus {
        if index < recognizedWords.count {
            let recognizedWord = recognizedWords[index]
            let targetWord = words[index]
            
            let similarity = VietnameseLanguageUtils.phoneticSimilarity(word1: recognizedWord, word2: targetWord)
            
            if similarity >= 0.9 {
                return .correct
            } else if similarity >= 0.7 {
                return .partial
            } else {
                return .incorrect
            }
        } else if index < words.count && isRecording {
            return .pending
        } else {
            return .notStarted
        }
    }
    
    private func audioBarColor(for index: Int) -> Color {
        let threshold = Float(index) / 20.0
        
        if audioLevel > threshold {
            if threshold < 0.3 {
                return .green
            } else if threshold < 0.7 {
                return .yellow
            } else {
                return .red
            }
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func audioBarHeight(for index: Int) -> CGFloat {
        let threshold = Float(index) / 20.0
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 20
        
        if audioLevel > threshold {
            let intensity = min(audioLevel * 2, 1.0) // Amplify for better visualization
            return baseHeight + (maxHeight - baseHeight) * CGFloat(intensity)
        } else {
            return baseHeight
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .blue
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
    
    private var confidenceDescription: String {
        switch confidence {
        case 0.9...1.0:
            return "Xuất sắc"
        case 0.8..<0.9:
            return "Rất tốt"
        case 0.7..<0.8:
            return "Tốt"
        case 0.6..<0.7:
            return "Khá"
        case 0.4..<0.6:
            return "Cần cải thiện"
        default:
            return "Thử lại"
        }
    }
    
    private func getRealTimeSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // Suggest next word if user is progressing well
        if recognizedWords.count < words.count && confidence > 0.7 {
            let nextWordIndex = recognizedWords.count
            if nextWordIndex < words.count {
                suggestions.append("Từ tiếp theo: \(words[nextWordIndex])")
            }
        }
        
        // Suggest speaking louder if audio level is low
        if audioLevel < 0.3 && isRecording {
            suggestions.append("Nói to hơn một chút")
        }
        
        // Suggest slowing down if confidence is low
        if confidence < 0.6 && isRecording {
            suggestions.append("Đọc chậm hơn")
        }
        
        // Encourage if doing well
        if confidence > 0.8 && recognizedWords.count > 0 {
            suggestions.append("Đang làm rất tốt!")
        }
        
        return suggestions
    }
    
    // MARK: - Animation Methods
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animateWords = true
        }
    }
    
    private func startRecordingAnimations() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            waveAnimation = true
        }
    }
    
    private func stopRecordingAnimations() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseAnimation = false
            waveAnimation = false
        }
    }
}

// MARK: - Word Highlight View

struct WordHighlightView: View {
    let word: String
    let status: WordStatus
    let isAnimated: Bool
    
    var body: some View {
        Text(word)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(status.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(status.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(status.borderColor, lineWidth: status.borderWidth)
                    )
            )
            .scaleEffect(isAnimated ? 1.0 : 0.9)
            .opacity(isAnimated ? 1.0 : 0.7)
            .overlay(
                // Shimmer effect for pending words
                status == .pending ? shimmerOverlay : nil
            )
    }
    
    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimated)
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Word Status

enum WordStatus {
    case notStarted
    case pending
    case correct
    case partial
    case incorrect
    
    var textColor: Color {
        switch self {
        case .notStarted:
            return .secondary
        case .pending:
            return .primary
        case .correct:
            return .green
        case .partial:
            return .orange
        case .incorrect:
            return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .notStarted:
            return Color.gray.opacity(0.1)
        case .pending:
            return Color.blue.opacity(0.1)
        case .correct:
            return Color.green.opacity(0.1)
        case .partial:
            return Color.orange.opacity(0.1)
        case .incorrect:
            return Color.red.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .notStarted:
            return Color.gray.opacity(0.3)
        case .pending:
            return Color.blue.opacity(0.5)
        case .correct:
            return Color.green.opacity(0.5)
        case .partial:
            return Color.orange.opacity(0.5)
        case .incorrect:
            return Color.red.opacity(0.5)
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .notStarted:
            return 1
        case .pending:
            return 2
        case .correct, .partial, .incorrect:
            return 2
        }
    }
}

// MARK: - Preview

struct RealTimeFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Not recording state
            RealTimeFeedbackView(
                targetText: "Con mèo nhỏ ngồi trên thảm xanh",
                recognizedText: "",
                confidence: 0.0,
                audioLevel: 0.0,
                isRecording: false
            )
            
            // Recording with partial recognition
            RealTimeFeedbackView(
                targetText: "Con mèo nhỏ ngồi trên thảm xanh",
                recognizedText: "Con mèo ngồi",
                confidence: 0.75,
                audioLevel: 0.6,
                isRecording: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}