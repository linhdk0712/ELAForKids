import SwiftUI
import PencilKit

// MARK: - Pencil Drawing View
struct PencilDrawingView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var isDrawing: Bool
    let onDrawingChanged: (PKDrawing) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        
        // Configure canvas
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = UIColor.systemBackground
        canvasView.isOpaque = false
        
        // Configure tool picker for iPad
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        #endif
        
        // Set drawing policy
        canvasView.drawingPolicy = .anyInput
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.drawing = drawing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PencilDrawingView
        
        init(_ parent: PencilDrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.isDrawing = !canvasView.drawing.strokes.isEmpty
            parent.onDrawingChanged(canvasView.drawing)
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            parent.isDrawing = true
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // Keep isDrawing true if there are strokes
            parent.isDrawing = !canvasView.drawing.strokes.isEmpty
        }
    }
}

// MARK: - Pencil Drawing Container
struct PencilDrawingContainer: View {
    @Binding var drawing: PKDrawing
    @State private var isDrawing = false
    let onDrawingChanged: (PKDrawing) -> Void
    let onClear: () -> Void
    let onRecognize: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Drawing Area Header
            HStack {
                Text("Viết bằng Apple Pencil")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isDrawing {
                    Text("Đang viết...")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Drawing Canvas
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                PencilDrawingView(
                    drawing: $drawing,
                    isDrawing: $isDrawing,
                    onDrawingChanged: onDrawingChanged
                )
                .cornerRadius(12)
                
                // Placeholder when empty
                if drawing.strokes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "pencil.tip")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Hãy viết văn bản bằng Apple Pencil")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Viết chậm và rõ ràng để nhận dạng tốt hơn")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 200)
            
            // Drawing Controls
            HStack(spacing: 16) {
                // Clear Button
                Button(action: onClear) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Xóa hết")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(drawing.strokes.isEmpty)
                
                Spacer()
                
                // Recognize Button
                Button(action: onRecognize) {
                    HStack {
                        Image(systemName: "textformat")
                        Text("Nhận dạng")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(drawing.strokes.isEmpty)
            }
        }
    }
}

// MARK: - Pencil Input Tips
struct PencilInputTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mẹo viết bằng Apple Pencil")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                PencilTipRow(
                    icon: "hand.draw",
                    text: "Viết chậm và rõ ràng",
                    color: .blue
                )
                
                PencilTipRow(
                    icon: "textformat.size",
                    text: "Viết chữ to và cách đều nhau",
                    color: .green
                )
                
                PencilTipRow(
                    icon: "arrow.right",
                    text: "Viết từ trái sang phải",
                    color: .orange
                )
                
                PencilTipRow(
                    icon: "checkmark.circle",
                    text: "Kiểm tra kết quả nhận dạng",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Pencil Tip Row
struct PencilTipRow: View {
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

// MARK: - Recognition Result View
struct RecognitionResultView: View {
    let result: RecognitionResult
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Kết quả nhận dạng")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                ConfidenceIndicator(confidence: result.confidence)
            }
            
            // Recognized Text
            VStack(alignment: .leading, spacing: 8) {
                Text("Văn bản nhận dạng:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(result.recognizedText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Alternative Texts (if available)
            if !result.alternativeTexts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Các lựa chọn khác:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(result.alternativeTexts.prefix(3), id: \.self) { alternative in
                        Button(action: {
                            // Handle alternative selection
                        }) {
                            Text(alternative)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Viết lại")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Sử dụng")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Confidence Indicator
struct ConfidenceIndicator: View {
    let confidence: Float
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var confidenceText: String {
        switch confidence {
        case 0.8...1.0:
            return "Tốt"
        case 0.5..<0.8:
            return "Trung bình"
        default:
            return "Thấp"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
            
            Text(confidenceText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor)
            
            Text("(\(Int(confidence * 100))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct PencilDrawingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PencilDrawingContainer(
                drawing: .constant(PKDrawing()),
                onDrawingChanged: { _ in },
                onClear: {},
                onRecognize: {}
            )
            
            PencilInputTips()
            
            RecognitionResultView(
                result: RecognitionResult(
                    recognizedText: "Con mèo ngồi trên thảm",
                    confidence: 0.85,
                    alternativeTexts: ["Con mèo ngồi trên ghế", "Con chó ngồi trên thảm"],
                    processingTime: 1.2
                ),
                onAccept: {},
                onReject: {}
            )
        }
        .padding()
    }
}