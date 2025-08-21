import SwiftUI

// MARK: - Adaptive Input Method Button
struct AdaptiveInputMethodButton: View {
    @Environment(\.adaptiveLayout) private var layout
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: layout.sectionSpacing / 3) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(isSelected ? .white : .blue)
                
                AdaptiveText(title, style: .caption)
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(layout.cornerRadius)
        }
        .buttonStyle(.plain)
    }
    
    private var buttonSize: CGFloat {
        layout.inputMethodButtonSize
    }
    
    private var iconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 20
        case .regular: return 24
        case .large: return 28
        }
    }
}

// MARK: - Adaptive Text Editor
struct AdaptiveTextEditor: View {
    @Environment(\.adaptiveLayout) private var layout
    @Binding var text: String
    let placeholder: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.system(size: layout.bodyFontSize))
                .padding(layout.contentPadding / 2)
                .background(Color(.systemGray6))
                .cornerRadius(layout.cornerRadius)
                .frame(minHeight: textEditorHeight)
            
            if text.isEmpty {
                VStack {
                    HStack {
                        AdaptiveText(placeholder, style: .body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(layout.contentPadding)
                .allowsHitTesting(false)
            }
        }
    }
    
    private var textEditorHeight: CGFloat {
        switch (layout.deviceType, layout.orientation) {
        case (.iPhone, .portrait): return 120
        case (.iPhone, .landscape): return 100
        case (.iPad, .portrait): return 150
        case (.iPad, .landscape): return 120
        case (.mac, _): return 150
        }
    }
}

// MARK: - Adaptive Drawing Canvas
struct AdaptiveDrawingCanvas: View {
    @Environment(\.adaptiveLayout) private var layout
    @Binding var drawing: PKDrawing
    let onDrawingChanged: (PKDrawing) -> Void
    let onClear: () -> Void
    let onRecognize: () -> Void
    
    var body: some View {
        VStack(spacing: layout.sectionSpacing / 2) {
            // Canvas Header
            HStack {
                AdaptiveText("Viết bằng Apple Pencil", style: .headline)
                Spacer()
            }
            
            // Drawing Area
            PencilDrawingContainer(
                drawing: $drawing,
                onDrawingChanged: onDrawingChanged,
                onClear: onClear,
                onRecognize: onRecognize
            )
            .frame(height: layout.canvasHeight)
        }
    }
}

// MARK: - Adaptive Action Buttons
struct AdaptiveActionButtons: View {
    @Environment(\.adaptiveLayout) private var layout
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let primaryTitle: String
    let secondaryTitle: String
    let primaryEnabled: Bool
    let secondaryEnabled: Bool
    let isProcessing: Bool
    
    var body: some View {
        OrientationLayout {
            // Portrait Layout
            VStack(spacing: layout.sectionSpacing / 2) {
                primaryButton
                secondaryButton
            }
        } landscape: {
            // Landscape Layout
            HStack(spacing: layout.sectionSpacing) {
                secondaryButton
                primaryButton
            }
        }
    }
    
    private var primaryButton: some View {
        AdaptiveButton(
            primaryTitle,
            icon: isProcessing ? nil : "arrow.right.circle.fill",
            style: .primary,
            action: primaryAction
        )
        .disabled(!primaryEnabled)
        .overlay(
            Group {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        AdaptiveText("Đang xử lý...", style: .body)
                            .foregroundColor(.white)
                    }
                }
            }
        )
    }
    
    private var secondaryButton: some View {
        AdaptiveButton(
            secondaryTitle,
            icon: "trash",
            style: .destructive,
            action: secondaryAction
        )
        .disabled(!secondaryEnabled)
    }
}

// MARK: - Adaptive Sample Text Grid
struct AdaptiveSampleTextGrid: View {
    @Environment(\.adaptiveLayout) private var layout
    let sampleTexts: [String]
    let onTextSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
            AdaptiveText("Văn bản mẫu", style: .headline)
            AdaptiveText("Nhấn vào một câu để sử dụng làm mẫu", style: .caption)
            
            AdaptiveGrid {
                ForEach(sampleTexts, id: \.self) { sampleText in
                    AdaptiveSampleTextCard(text: sampleText) {
                        onTextSelected(sampleText)
                    }
                }
            }
        }
    }
}

// MARK: - Adaptive Sample Text Card
struct AdaptiveSampleTextCard: View {
    @Environment(\.adaptiveLayout) private var layout
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AdaptiveText(text, style: .body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(layout.contentPadding / 2)
                .background(Color(.systemGray6))
                .cornerRadius(layout.cornerRadius / 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Adaptive Progress Indicator
struct AdaptiveProgressIndicator: View {
    @Environment(\.adaptiveLayout) private var layout
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
        VStack(alignment: .leading, spacing: layout.sectionSpacing / 3) {
            HStack {
                AdaptiveText("Tiến độ", style: .headline)
                Spacer()
                AdaptiveText("\(currentCount)/\(maximumCount)", style: .caption)
            }
            
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(y: progressBarHeight)
            
            HStack {
                if isMinimumReached {
                    Label("Đủ điều kiện tiếp tục", systemImage: "checkmark.circle.fill")
                        .font(.system(size: layout.captionFontSize))
                        .foregroundColor(.green)
                } else {
                    Label("Cần thêm \(minimumCount - currentCount) từ", systemImage: "info.circle")
                        .font(.system(size: layout.captionFontSize))
                        .foregroundColor(.orange)
                }
                Spacer()
            }
        }
    }
    
    private var progressBarHeight: CGFloat {
        switch layout.screenSize {
        case .compact: return 1.5
        case .regular: return 2.0
        case .large: return 2.5
        }
    }
}