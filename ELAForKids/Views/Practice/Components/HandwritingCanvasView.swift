import SwiftUI
import PencilKit
import Vision

// MARK: - Handwriting Canvas View
struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var recognizedText: String
    let onTextRecognized: (String) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = UIColor.systemBackground
        
        // Configure tool picker for child-friendly use
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 3.0)
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: HandwritingCanvasView
        private let textRecognizer = HandwritingTextRecognizer()
        
        init(_ parent: HandwritingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Debounce text recognition to avoid too frequent calls
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.recognizeText(from: canvasView.drawing)
            }
        }
        
        private func recognizeText(from drawing: PKDrawing) {
            textRecognizer.recognizeText(from: drawing) { [weak self] recognizedText in
                DispatchQueue.main.async {
                    self?.parent.recognizedText = recognizedText
                    self?.parent.onTextRecognized(recognizedText)
                }
            }
        }
    }
}

// MARK: - Handwriting Text Recognizer
class HandwritingTextRecognizer {
    
    func recognizeText(from drawing: PKDrawing, completion: @escaping (String) -> Void) {
        // Convert PKDrawing to image
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        
        // Use Vision framework for text recognition
        recognizeText(from: image, completion: completion)
    }
    
    private func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                completion("")
                return
            }
            
            let recognizedStrings = request.results?.compactMap { result in
                (result as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
            } ?? []
            
            let fullText = recognizedStrings.joined(separator: " ")
            completion(fullText)
        }
        
        // Configure for Vietnamese text recognition
        request.recognitionLanguages = ["vi-VN", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                completion("")
            }
        }
    }
}

// MARK: - Preview
struct HandwritingCanvasView_Previews: PreviewProvider {
    @State static var recognizedText = ""
    
    static var previews: some View {
        VStack {
            Text("Viết vào khung bên dưới:")
                .font(.headline)
                .padding()
            
            HandwritingCanvasView(recognizedText: $recognizedText) { text in
                print("Recognized: \(text)")
            }
            .frame(height: 200)
            .border(Color.gray, width: 1)
            .padding()
            
            Text("Nhận dạng: \(recognizedText)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}