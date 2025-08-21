import SwiftUI

// MARK: - Text Highlight View
struct TextHighlightView: View {
    let text: String
    let mistakes: [TextMistake]
    let matchedWords: [String]
    let onWordTap: ((String, Int) -> Void)?
    
    @Environment(\.adaptiveLayout) private var layout
    @State private var animatingMistakes: Set<Int> = []
    
    init(
        text: String,
        mistakes: [TextMistake] = [],
        matchedWords: [String] = [],
        onWordTap: ((String, Int) -> Void)? = nil
    ) {
        self.text = text
        self.mistakes = mistakes
        self.matchedWords = matchedWords
        self.onWordTap = onWordTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
            // Text with highlighting
            highlightedTextView
            
            // Mistake legend (if there are mistakes)
            if !mistakes.isEmpty {
                mistakeLegendView
            }
        }
    }
    
    // MARK: - Highlighted Text View
    private var highlightedTextView: some View {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return LazyVGrid(columns: adaptiveColumns, alignment: .leading, spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                wordView(word: word, index: index)
            }
        }
        .padding(layout.contentPadding / 2)
        .background(Color(.systemGray6))
        .cornerRadius(layout.cornerRadius)
    }
    
    // MARK: - Word View
    private func wordView(word: String, index: Int) -> some View {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
        let wordState = getWordState(word: cleanWord, index: index)
        
        return Button(action: {
            onWordTap?(cleanWord, index)
            if wordState.hasMistake {
                animateMistake(at: index)
            }
        }) {
            Text(word)
                .font(.system(size: wordFontSize, weight: .medium, design: .rounded))
                .foregroundColor(wordState.textColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(wordState.backgroundColor)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(wordState.borderColor, lineWidth: wordState.borderWidth)
                )
                .scaleEffect(animatingMistakes.contains(index) ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: animatingMistakes.contains(index))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onWordTap == nil)
    }
    
    // MARK: - Mistake Legend
    private var mistakeLegendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            AdaptiveText("Chú thích:", style: .headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: legendColumns, alignment: .leading, spacing: 8) {
                legendItem(
                    color: .green,
                    icon: "checkmark.circle.fill",
                    title: "Đúng",
                    description: "Từ đọc chính xác"
                )
                
                legendItem(
                    color: .red,
                    icon: "xmark.circle.fill",
                    title: "Sai",
                    description: "Từ đọc không chính xác"
                )
                
                legendItem(
                    color: .orange,
                    icon: "exclamationmark.triangle.fill",
                    title: "Phát âm",
                    description: "Phát âm không rõ"
                )
                
                legendItem(
                    color: .blue,
                    icon: "minus.circle.fill",
                    title: "Bỏ sót",
                    description: "Từ bị bỏ qua"
                )
            }
        }
        .padding(layout.contentPadding / 2)
        .background(Color(.systemBackground))
        .cornerRadius(layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func legendItem(color: Color, icon: String, title: String, description: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getWordState(word: String, index: Int) -> WordState {
        // Check if word has a mistake
        if let mistake = mistakes.first(where: { $0.position == index || $0.expectedWord.lowercased() == word.lowercased() }) {
            return WordState(
                textColor: .white,
                backgroundColor: backgroundColorForMistake(mistake.mistakeType),
                borderColor: borderColorForMistake(mistake.mistakeType),
                borderWidth: 2,
                hasMistake: true,
                mistake: mistake
            )
        }
        
        // Check if word is correctly matched
        if matchedWords.contains(where: { $0.lowercased() == word.lowercased() }) {
            return WordState(
                textColor: .primary,
                backgroundColor: Color.green.opacity(0.2),
                borderColor: .green,
                borderWidth: 1,
                hasMistake: false
            )
        }
        
        // Default state (neutral)
        return WordState(
            textColor: .primary,
            backgroundColor: Color.clear,
            borderColor: Color.clear,
            borderWidth: 0,
            hasMistake: false
        )
    }
    
    private func backgroundColorForMistake(_ mistakeType: MistakeType) -> Color {
        switch mistakeType {
        case .substitution:
            return .red
        case .mispronunciation:
            return .orange
        case .omission:
            return .blue
        case .insertion:
            return .purple
        }
    }
    
    private func borderColorForMistake(_ mistakeType: MistakeType) -> Color {
        switch mistakeType {
        case .substitution:
            return .red
        case .mispronunciation:
            return .orange
        case .omission:
            return .blue
        case .insertion:
            return .purple
        }
    }
    
    private func animateMistake(at index: Int) {
        animatingMistakes.insert(index)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingMistakes.remove(index)
        }
    }
    
    // MARK: - Computed Properties
    private var adaptiveColumns: [GridItem] {
        let columnCount: Int
        switch layout.deviceType {
        case .iPhone:
            columnCount = layout.orientation == .portrait ? 3 : 5
        case .iPad:
            columnCount = layout.orientation == .portrait ? 4 : 6
        case .mac:
            columnCount = 6
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
    
    private var legendColumns: [GridItem] {
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
    
    private var wordFontSize: CGFloat {
        switch layout.screenSize {
        case .compact:
            return 16
        case .regular:
            return 18
        case .large:
            return 20
        }
    }
}

// MARK: - Word State
private struct WordState {
    let textColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let hasMistake: Bool
    let mistake: TextMistake?
    
    init(
        textColor: Color,
        backgroundColor: Color,
        borderColor: Color,
        borderWidth: CGFloat,
        hasMistake: Bool,
        mistake: TextMistake? = nil
    ) {
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.hasMistake = hasMistake
        self.mistake = mistake
    }
}

// MARK: - Preview
struct TextHighlightView_Previews: PreviewProvider {
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
        
        let matchedWords = ["Con", "ngồi"]
        
        ScrollView {
            VStack(spacing: 20) {
                TextHighlightView(
                    text: "Con mèo ngồi trên thảm xanh",
                    mistakes: sampleMistakes,
                    matchedWords: matchedWords
                ) { word, index in
                    print("Tapped word: \(word) at index: \(index)")
                }
                
                TextHighlightView(
                    text: "Đây là văn bản không có lỗi",
                    mistakes: [],
                    matchedWords: ["Đây", "là", "văn", "bản", "không", "có", "lỗi"]
                )
            }
            .padding()
        }
        .adaptiveLayout()
    }
}