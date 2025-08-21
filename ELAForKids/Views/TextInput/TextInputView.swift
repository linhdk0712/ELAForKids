import SwiftUI
import PencilKit

struct TextInputView: View {
    @StateObject private var viewModel = TextInputViewModel()
    @Environment(\.navigationCoordinator) private var navigationCoordinator
    @Environment(\.adaptiveLayout) private var layout
    @FocusState private var isTextFieldFocused: Bool
    @State private var showStatistics = false
    @State private var showTips = false
    @State private var pencilDrawing = PKDrawing()
    @State private var showPencilTips = false
    
    var body: some View {
        ResponsiveLayout {
            AdaptiveContainer {
                AdaptiveStack(spacing: layout.sectionSpacing) {
                // Header
                headerSection
                
                // Input Method Selection
                inputMethodSection
                
                // Text Input Area
                if viewModel.isPencilMode {
                    pencilInputSection
                } else {
                    textInputSection
                }
                
                // Progress Section
                if !viewModel.state.currentText.isEmpty {
                    AdaptiveProgressIndicator(
                        currentCount: viewModel.characterCount,
                        minimumCount: 50,
                        maximumCount: 500
                    )
                }
                
                // Sample Texts
                AdaptiveSampleTextGrid(
                    sampleTexts: viewModel.getSampleTexts(),
                    onTextSelected: { text in
                        viewModel.insertSampleText(text)
                        isTextFieldFocused = true
                    }
                )
                
                // Tips Section
                if showTips {
                    if viewModel.isPencilMode {
                        PencilInputTips()
                    } else {
                        TextInputTips()
                    }
                }
                
                // Recognition Result
                if let result = viewModel.recognitionResult,
                   let qualityAssessment = viewModel.getQualityAssessment() {
                    EnhancedRecognitionResultView(
                        result: result,
                        qualityAssessment: qualityAssessment,
                        onAccept: {
                            viewModel.acceptRecognitionResult()
                        },
                        onReject: {
                            viewModel.rejectRecognitionResult()
                            pencilDrawing = PKDrawing() // Clear drawing
                        },
                        onSelectAlternative: { text in
                            viewModel.selectAlternativeText(text)
                        }
                    )
                }
                
                // Action Buttons
                AdaptiveActionButtons(
                    primaryAction: { viewModel.send(.finishInput) },
                    secondaryAction: { viewModel.send(.clearInput) },
                    primaryTitle: viewModel.state.isProcessing ? "Đang xử lý..." : "Tiếp tục đọc",
                    secondaryTitle: "Xóa hết",
                    primaryEnabled: viewModel.canFinish,
                    secondaryEnabled: !viewModel.state.currentText.isEmpty,
                    isProcessing: viewModel.state.isProcessing
                )
                
                }
            }
        }
        .adaptiveLayout()
        .navigationTitle("Viết văn bản")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Mẹo") {
                    showTips.toggle()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Xóa hết", role: .destructive) {
                        viewModel.send(.clearInput)
                    }
                    .disabled(viewModel.state.currentText.isEmpty)
                    
                    Button("Thống kê") {
                        showStatistics = true
                    }
                    .disabled(viewModel.state.currentText.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.send(.startInput(method: .keyboard))
            isTextFieldFocused = true
        }
        .alert("Lỗi nhập văn bản", isPresented: .constant(viewModel.state.error != nil)) {
            Button("Đóng") {
                viewModel.send(.clearError)
            }
        } message: {
            if let error = viewModel.state.error {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $showStatistics) {
            if !viewModel.state.currentText.isEmpty {
                NavigationStack {
                    TextStatisticsView(statistics: getTextStatistics())
                        .navigationTitle("Thống kê văn bản")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Đóng") {
                                    showStatistics = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 2) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: headerIconSize))
                    .foregroundColor(.blue)
                
                AdaptiveText("Hãy viết một đoạn văn bản", style: .title)
                    .multilineTextAlignment(.center)
                
                AdaptiveText("Viết ít nhất 10 từ để có thể tiếp tục", style: .caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var headerIconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 40
        case .regular: return 50
        case .large: return 60
        }
    }
    
    // MARK: - Input Method Section
    private var inputMethodSection: some View {
        if layout.showInputMethodSelection {
            AdaptiveCard {
                VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                    AdaptiveText("Cách nhập văn bản", style: .headline)
                    
                    AdaptiveGrid {
                        AdaptiveInputMethodButton(
                            title: "Bàn phím",
                            icon: "keyboard",
                            isSelected: viewModel.state.inputMethod == .keyboard
                        ) {
                            viewModel.send(.startInput(method: .keyboard))
                            isTextFieldFocused = true
                        }
                        
                        #if os(iOS)
                        if DeviceInfo.shared.supportsPencil {
                            AdaptiveInputMethodButton(
                                title: "Apple Pencil",
                                icon: "pencil.tip",
                                isSelected: viewModel.state.inputMethod == .pencil
                            ) {
                                viewModel.send(.startInput(method: .pencil))
                                isTextFieldFocused = false
                                pencilDrawing = PKDrawing()
                            }
                        }
                        #endif
                    }
                }
            }
        }
    }
    
    // MARK: - Text Input Section
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Input Label with Character Count
            HStack {
                Text("Văn bản của bạn")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.characterCount)/500")
                    .font(.caption)
                    .foregroundColor(viewModel.characterCount > 450 ? .red : .secondary)
            }
            
            // Text Input Field
            TextEditor(text: Binding(
                get: { viewModel.state.currentText },
                set: { viewModel.send(.updateText($0)) }
            ))
            .focused($isTextFieldFocused)
            .font(.body)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .frame(minHeight: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .overlay(
                // Placeholder
                Group {
                    if viewModel.state.currentText.isEmpty {
                        VStack {
                            HStack {
                                Text("Hãy viết một đoạn văn bản ở đây...")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(16)
                        .allowsHitTesting(false)
                    }
                }
            )
            
            // Progress Bar
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(y: 2)
            
            // Validation Message
            if let validationMessage = viewModel.validationMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Sample Texts Section
    private var sampleTextsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Văn bản mẫu")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Nhấn vào một câu để sử dụng làm mẫu")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.getSampleTexts(), id: \.self) { sampleText in
                    SampleTextCard(text: sampleText) {
                        viewModel.insertSampleText(sampleText)
                        isTextFieldFocused = true
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button(action: {
                viewModel.send(.finishInput)
            }) {
                HStack {
                    if viewModel.state.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(viewModel.state.isProcessing ? "Đang xử lý..." : "Tiếp tục đọc")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.canFinish ? Color.green : Color.gray
                )
                .cornerRadius(12)
            }
            .disabled(!viewModel.canFinish)
            
            // Clear Button
            Button(action: {
                viewModel.send(.clearInput)
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("Xóa hết")
                        .font(.headline)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(viewModel.state.currentText.isEmpty)
        }
    }
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        if let _ = viewModel.validationMessage {
            return .orange
        } else if viewModel.isTextValid && !viewModel.state.currentText.isEmpty {
            return .green
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var progressColor: Color {
        if viewModel.progressPercentage >= 1.0 {
            return .green
        } else if viewModel.progressPercentage >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func getTextStatistics() -> TextStatistics {
        let handler = TextInputHandler()
        return handler.getTextStatistics(viewModel.state.currentText)
    }
    
    // MARK: - Text Input Section
    private var textInputSection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                HStack {
                    AdaptiveText("Văn bản của bạn", style: .headline)
                    Spacer()
                    AdaptiveText("\(viewModel.characterCount)/500", style: .caption)
                        .foregroundColor(viewModel.characterCount > 450 ? .red : .secondary)
                }
                
                AdaptiveTextEditor(
                    text: Binding(
                        get: { viewModel.state.currentText },
                        set: { viewModel.send(.updateText($0)) }
                    ),
                    placeholder: "Hãy viết một đoạn văn bản ở đây...",
                    isFocused: $isTextFieldFocused
                )
                .overlay(
                    RoundedRectangle(cornerRadius: layout.cornerRadius)
                        .stroke(borderColor, lineWidth: 2)
                )
                
                if let validationMessage = viewModel.validationMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        AdaptiveText(validationMessage, style: .caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Pencil Input Section
    private var pencilInputSection: some View {
        AdaptiveCard {
            AdaptiveDrawingCanvas(
                drawing: $pencilDrawing,
                onDrawingChanged: { drawing in
                    if !drawing.strokes.isEmpty {
                        viewModel.send(.processPencilDrawing(drawing))
                    }
                },
                onClear: {
                    pencilDrawing = PKDrawing()
                    viewModel.send(.clearInput)
                },
                onRecognize: {
                    if !pencilDrawing.strokes.isEmpty {
                        viewModel.send(.processPencilDrawing(pencilDrawing))
                    }
                }
            )
        }
    }
}

// MARK: - Input Method Button
struct InputMethodButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sample Text Card
struct SampleTextCard: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct TextInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TextInputView()
                .withNavigationCoordinator(NavigationCoordinator())
                .environmentObject(ErrorHandler())
        }
    }
}