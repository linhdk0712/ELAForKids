import SwiftUI
import PencilKit

// MARK: - Enhanced Recognition Result View
struct EnhancedRecognitionResultView: View {
    let result: RecognitionResult
    let qualityAssessment: RecognitionQualityAssessment
    let onAccept: () -> Void
    let onReject: () -> Void
    let onSelectAlternative: (String) -> Void
    
    @State private var showDetails = false
    @State private var selectedAlternative: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Quality Indicator
            headerSection
            
            // Main Recognition Result
            mainResultSection
            
            // Alternative Texts
            if !result.alternativeTexts.isEmpty {
                alternativeTextsSection
            }
            
            // Quality Details (expandable)
            qualityDetailsSection
            
            // Suggestions
            if !qualityAssessment.suggestions.isEmpty {
                suggestionsSection
            }
            
            // Action Buttons
            actionButtonsSection
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kết quả nhận dạng")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Thời gian xử lý: \(String(format: "%.1f", result.processingTime))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            QualityBadge(quality: qualityAssessment.overallQuality)
        }
    }
    
    // MARK: - Main Result Section
    private var mainResultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Văn bản nhận dạng:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ConfidenceIndicator(confidence: result.confidence)
            }
            
            Text(result.recognizedText.isEmpty ? "Không nhận dạng được văn bản" : result.recognizedText)
                .font(.body)
                .foregroundColor(result.recognizedText.isEmpty ? .secondary : .primary)
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(confidenceColor, lineWidth: 2)
                )
        }
    }
    
    // MARK: - Alternative Texts Section
    private var alternativeTextsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Các lựa chọn khác:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(result.alternativeTexts.prefix(4), id: \.self) { alternative in
                    AlternativeTextButton(
                        text: alternative,
                        isSelected: selectedAlternative == alternative
                    ) {
                        selectedAlternative = alternative
                        onSelectAlternative(alternative)
                    }
                }
            }
        }
    }
    
    // MARK: - Quality Details Section
    private var qualityDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetails.toggle()
                }
            }) {
                HStack {
                    Text("Chi tiết chất lượng")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showDetails {
                QualityDetailsView(assessment: qualityAssessment)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Suggestions Section
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gợi ý cải thiện:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(qualityAssessment.suggestions.prefix(3), id: \.self) { suggestion in
                    SuggestionRow(text: suggestion)
                }
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // Reject Button
            Button(action: onReject) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Viết lại")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Accept Button
            Button(action: {
                if let selected = selectedAlternative {
                    onSelectAlternative(selected)
                } else {
                    onAccept()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text(selectedAlternative != nil ? "Dùng lựa chọn" : "Sử dụng")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(acceptButtonColor)
                .cornerRadius(12)
            }
            .disabled(result.recognizedText.isEmpty && selectedAlternative == nil)
        }
    }
    
    // MARK: - Computed Properties
    private var confidenceColor: Color {
        switch result.confidence {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var acceptButtonColor: Color {
        if result.recognizedText.isEmpty && selectedAlternative == nil {
            return .gray
        } else if selectedAlternative != nil {
            return .blue
        } else {
            return .green
        }
    }
}

// MARK: - Quality Badge
struct QualityBadge: View {
    let quality: RecognitionQuality
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: quality.icon)
                .font(.caption)
                .foregroundColor(.white)
            
            Text(quality.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(quality.color))
        .cornerRadius(16)
    }
}

// MARK: - Alternative Text Button
struct AlternativeTextButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .blue)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quality Details View
struct QualityDetailsView: View {
    let assessment: RecognitionQualityAssessment
    
    var body: some View {
        VStack(spacing: 12) {
            // Confidence Details
            QualityMetricRow(
                title: "Độ tin cậy",
                value: "\(Int(assessment.confidence * 100))%",
                color: confidenceColor
            )
            
            // Writing Pattern Details
            QualityMetricRow(
                title: "Tính nhất quán",
                value: "\(Int(assessment.writingPattern.consistency * 100))%",
                color: consistencyColor
            )
            
            QualityMetricRow(
                title: "Khoảng cách",
                value: assessment.writingPattern.spacing.isEvenlySpaced ? "Đều" : "Không đều",
                color: assessment.writingPattern.spacing.isEvenlySpaced ? .green : .orange
            )
            
            QualityMetricRow(
                title: "Hướng viết",
                value: assessment.writingPattern.direction.displayName,
                color: assessment.writingPattern.direction.isCorrect ? .green : .orange
            )
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        switch assessment.confidence {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
    
    private var consistencyColor: Color {
        switch assessment.writingPattern.consistency {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Quality Metric Row
struct QualityMetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Suggestion Row
struct SuggestionRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct EnhancedRecognitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedRecognitionResultView(
            result: RecognitionResult(
                recognizedText: "Con mèo ngồi trên thảm",
                confidence: 0.85,
                alternativeTexts: ["Con mèo ngồi trên ghế", "Con chó ngồi trên thảm"],
                processingTime: 1.2
            ),
            qualityAssessment: RecognitionQualityAssessment(
                overallQuality: .good,
                confidence: 0.85,
                textLength: 24,
                alternativeCount: 2,
                writingPattern: WritingPatternAnalysis(
                    strokeCount: 15,
                    averageStrokeLength: 25.5,
                    writingSpeed: 45.2,
                    pressure: 0.7,
                    consistency: 0.8,
                    direction: .leftToRight,
                    spacing: SpacingAnalysis(
                        averageSpacing: 12.5,
                        consistency: 0.75,
                        isEvenlySpaced: true
                    )
                ),
                suggestions: ["Tuyệt vời! Tiếp tục cố gắng!", "Viết chậm hơn để chính xác hơn"]
            ),
            onAccept: {},
            onReject: {},
            onSelectAlternative: { _ in }
        )
        .padding()
    }
}