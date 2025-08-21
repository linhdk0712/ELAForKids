import SwiftUI

// MARK: - Highlighted Text View
struct HighlightedTextView: View {
    let text: String
    let mistakes: [TextMistake]
    let highlightMode: HighlightMode
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var animationTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text display
            textView
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityManager.getReadingTextAccessibilityLabel(text: text, mistakes: mistakes))
                .accessibilityHint("Văn bản cần đọc. Các từ được tô sáng là những từ cần chú ý.")
            
            // Legend (if showing mistakes)
            if highlightMode == .mistakes && !mistakes.isEmpty {
                legendView
                    .accessibilityLabel("Chú thích: Màu đỏ là từ sai, màu cam là từ thiếu, màu xanh là từ thừa")
            }
        }
    }
    
    // MARK: - Text View
    
    @ViewBuilder
    private var textView: some View {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: getColumnsCount(for: words.count)), spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                wordView(word: word, index: index)
            }
        }
    }
    
    @ViewBuilder
    private func wordView(word: String, index: Int) -> some View {
        let mistake = mistakes.first { $0.position == index }
        let hasError = mistake != nil && highlightMode == .mistakes
        
        Text(word)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(hasError ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColorForWord(mistake: mistake))
                    .scaleEffect(hasError && animationTrigger ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animationTrigger)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColorForWord(mistake: mistake), lineWidth: hasError ? 2 : 0)
            )
            .accessibilityLabel(hasError ? "\(word), có lỗi \(mistake?.mistakeType.localizedName ?? "")" : word)
            .accessibilityAddTraits(hasError ? .isStaticText : .isStaticText)
    }
    
    // MARK: - Legend View
    
    @ViewBuilder
    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: .red, title: "Sai", icon: "xmark.circle.fill")
            legendItem(color: .orange, title: "Thiếu", icon: "minus.circle.fill")
            legendItem(color: .blue, title: "Thừa", icon: "plus.circle.fill")
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func legendItem(color: Color, title: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getColumnsCount(for wordCount: Int) -> Int {
        // Adaptive column count based on word count and screen size
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return min(6, max(3, wordCount / 4))
        } else {
            return min(4, max(2, wordCount / 6))
        }
        #else
        return min(6, max(3, wordCount / 4))
        #endif
    }
    
    private func backgroundColorForWord(mistake: TextMistake?) -> Color {
        guard let mistake = mistake, highlightMode == .mistakes else {
            return Color.clear
        }
        
        switch mistake.mistakeType {
        case .substitution:
            return .red.opacity(0.8)
        case .omission:
            return .orange.opacity(0.8)
        case .insertion:
            return .blue.opacity(0.8)
        case .pronunciation:
            return .purple.opacity(0.8)
        }
    }
    
    private func borderColorForWord(mistake: TextMistake?) -> Color {
        guard let mistake = mistake, highlightMode == .mistakes else {
            return Color.clear
        }
        
        switch mistake.mistakeType {
        case .substitution:
            return .red
        case .omission:
            return .orange
        case .insertion:
            return .blue
        case .pronunciation:
            return .purple
        }
    }
}

// MARK: - Preview
struct HighlightedTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal text
            HighlightedTextView(
                text: "Con mèo nhỏ màu nâu chạy quanh sân",
                mistakes: [],
                highlightMode: .none
            )
            
            // Text with mistakes
            HighlightedTextView(
                text: "Con mèo nhỏ màu nâu chạy quanh sân",
                mistakes: [
                    TextMistake(
                        id: UUID(),
                        expectedWord: "mèo",
                        actualWord: "chó",
                        position: 1,
                        mistakeType: .substitution,
                        severity: .medium
                    ),
                    TextMistake(
                        id: UUID(),
                        expectedWord: "quanh",
                        actualWord: nil,
                        position: 5,
                        mistakeType: .omission,
                        severity: .high
                    )
                ],
                highlightMode: .mistakes
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}