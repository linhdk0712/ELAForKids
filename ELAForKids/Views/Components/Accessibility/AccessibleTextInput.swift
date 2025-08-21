import SwiftUI
import UIKit

// MARK: - Accessible Text Input Component

struct AccessibleTextInput: View {
    @Binding var text: String
    let placeholder: String
    let title: String
    let isMultiline: Bool
    let maxLength: Int?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @FocusState private var isFocused: Bool
    @State private var characterCount: Int = 0
    
    init(
        text: Binding<String>,
        placeholder: String,
        title: String,
        isMultiline: Bool = false,
        maxLength: Int? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.title = title
        self.isMultiline = isMultiline
        self.maxLength = maxLength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Text input
            Group {
                if isMultiline {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .focused($isFocused)
            .font(.body)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.blue : Color(.systemGray4),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .accessibilityLabel("\(title). \(placeholder)")
            .accessibilityHint(isMultiline ? "Vùng nhập văn bản nhiều dòng" : "Vùng nhập văn bản một dòng")
            .accessibilityValue(text.isEmpty ? "Trống" : text)
            .onChange(of: text) { newValue in
                characterCount = newValue.count
                
                // Limit text length if specified
                if let maxLength = maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                    
                    // Announce character limit reached
                    if accessibilityManager.isVoiceOverEnabled {
                        accessibilityManager.announceToVoiceOver(
                            "Đã đạt giới hạn \(maxLength) ký tự",
                            priority: .medium
                        )
                    }
                }
            }
            
            // Character count and status
            HStack {
                if !text.isEmpty {
                    Text("\(characterCount) ký tự")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Đã nhập \(characterCount) ký tự")
                }
                
                Spacer()
                
                if let maxLength = maxLength {
                    Text("\(maxLength - characterCount) còn lại")
                        .font(.caption)
                        .foregroundColor(characterCount >= maxLength ? .red : .secondary)
                        .accessibilityLabel("Còn lại \(maxLength - characterCount) ký tự")
                }
            }
            .accessibilityElement(children: .combine)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            characterCount = text.count
        }
    }
}

// MARK: - Accessible Handwriting Canvas

struct AccessibleHandwritingCanvas: View {
    @Binding var recognizedText: String
    let onTextRecognized: (String) -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var isDrawing = false
    @State private var lastRecognitionTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Instructions
            Text("Viết chữ bằng tay")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Canvas area
            HandwritingCanvasView(
                recognizedText: $recognizedText,
                onTextRecognized: { text in
                    onTextRecognized(text)
                    lastRecognitionTime = Date()
                    
                    // Announce recognition result
                    if accessibilityManager.isVoiceOverEnabled && !text.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            accessibilityManager.announceToVoiceOver(
                                "Nhận dạng được: \(text)",
                                priority: .medium
                            )
                        }
                    }
                }
            )
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .accessibilityLabel("Vùng viết chữ tay")
            .accessibilityHint("Sử dụng Apple Pencil hoặc ngón tay để viết chữ")
            .accessibilityValue(recognizedText.isEmpty ? "Chưa có chữ nào được nhận dạng" : "Nhận dạng được: \(recognizedText)")
            .accessibilityAddTraits(.allowsDirectInteraction)
            
            // Recognition result
            if !recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kết quả nhận dạng:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(recognizedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Kết quả nhận dạng chữ viết tay: \(recognizedText)")
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Xóa") {
                    recognizedText = ""
                    // Clear canvas would be handled by the HandwritingCanvasView
                    
                    if accessibilityManager.isVoiceOverEnabled {
                        accessibilityManager.announceToVoiceOver(
                            "Đã xóa chữ viết",
                            priority: .medium
                        )
                    }
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .accessibilityLabel("Xóa chữ viết")
                .accessibilityHint("Nhấn đúp để xóa tất cả chữ viết trên canvas")
                .accessibilityAddTraits(.isButton)
                
                Spacer()
                
                if !recognizedText.isEmpty {
                    Button("Sử dụng") {
                        onTextRecognized(recognizedText)
                        
                        if accessibilityManager.isVoiceOverEnabled {
                            accessibilityManager.announceToVoiceOver(
                                "Đã sử dụng văn bản: \(recognizedText)",
                                priority: .medium
                            )
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .accessibilityLabel("Sử dụng văn bản đã nhận dạng")
                    .accessibilityHint("Nhấn đúp để sử dụng văn bản đã nhận dạng")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Accessible Voice Input

struct AccessibleVoiceInput: View {
    let isRecording: Bool
    let isAvailable: Bool
    let audioLevel: Float
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Instructions
            Text("Đọc to và rõ ràng")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Recording button
            Button(action: {
                if isRecording {
                    onStopRecording()
                } else {
                    onStartRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.green)
                        .frame(width: 80, height: 80)
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(
                            isRecording ? 
                                .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : 
                                .default,
                            value: isRecording
                        )
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .disabled(!isAvailable)
            .accessibilityLabel(isRecording ? "Đang ghi âm" : "Bắt đầu ghi âm")
            .accessibilityHint(isRecording ? "Nhấn đúp để dừng ghi âm" : "Nhấn đúp để bắt đầu ghi âm giọng nói")
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isRecording ? "Đang hoạt động" : "Sẵn sàng")
            
            // Audio level indicator
            if isRecording {
                VStack(spacing: 8) {
                    Text("Mức âm thanh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: audioLevel, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(height: 8)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Mức âm thanh: \(Int(audioLevel * 100)) phần trăm")
                .accessibilityAddTraits(.updatesFrequently)
            }
            
            // Status message
            Text(statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(statusMessage)
        }
        .accessibilityElement(children: .contain)
        .onChange(of: isRecording) { recording in
            let message = recording ? "Bắt đầu ghi âm" : "Dừng ghi âm"
            accessibilityManager.announceToVoiceOver(message, priority: .high)
        }
    }
    
    private var statusMessage: String {
        if !isAvailable {
            return "Microphone không khả dụng"
        } else if isRecording {
            return "Đang ghi âm... Hãy đọc to và rõ ràng"
        } else {
            return "Nhấn nút để bắt đầu ghi âm"
        }
    }
}

// MARK: - Preview

struct AccessibleTextInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AccessibleTextInput(
                text: .constant(""),
                placeholder: "Nhập văn bản ở đây",
                title: "Văn bản cần đọc",
                isMultiline: true,
                maxLength: 200
            )
            
            AccessibleVoiceInput(
                isRecording: false,
                isAvailable: true,
                audioLevel: 0.5,
                onStartRecording: {},
                onStopRecording: {}
            )
        }
        .padding()
    }
}