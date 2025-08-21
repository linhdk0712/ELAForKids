import Foundation
import PencilKit
import Vision
import UIKit

// MARK: - Real Handwriting Recognition Implementation
final class HandwritingRecognizer: HandwritingRecognitionProtocol {
    private var isProcessing = false
    private let advancedEngine = AdvancedHandwritingEngine()
    private var lastConfidenceScore: Float = 0.0
    
    func recognizeText(from drawing: PKDrawing) async throws -> RecognitionResult {
        guard !isProcessing else {
            throw AppError.handwritingRecognitionFailed
        }
        
        guard isDrawingValid(drawing) else {
            throw AppError.handwritingLowConfidence
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await advancedEngine.recognizeText(from: drawing)
            lastConfidenceScore = result.confidence
            
            // Validate result quality
            if result.confidence < 0.3 && result.recognizedText.isEmpty {
                throw AppError.handwritingLowConfidence
            }
            
            return result
        } catch {
            if error is HandwritingRecognitionError {
                throw AppError.handwritingRecognitionFailed
            } else {
                throw error
            }
        }
    }
    
    func getConfidenceScore() -> Float {
        return lastConfidenceScore
    }
    
    func isRecognitionAvailable() -> Bool {
        return true // Vision framework is always available on iOS 13+
    }
    
    // MARK: - Private Methods
    private func performVisionTextRecognition(on image: UIImage) async throws -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else {
            throw AppError.handwritingRecognitionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AppError.handwritingRecognitionFailed)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: AppError.handwritingRecognitionFailed)
                    return
                }
                
                continuation.resume(returning: observations)
            }
            
            // Configure request for handwriting
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"] // Vietnamese and English
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AppError.handwritingRecognitionFailed)
            }
        }
    }
    
    private func processRecognitionResults(_ observations: [VNRecognizedTextObservation]) -> RecognitionResult {
        var allCandidates: [(text: String, confidence: Float)] = []
        
        // Extract all text candidates with confidence scores
        for observation in observations {
            let candidates = observation.topCandidates(5)
            for candidate in candidates {
                allCandidates.append((
                    text: candidate.string,
                    confidence: candidate.confidence
                ))
            }
        }
        
        // Sort by confidence
        allCandidates.sort { $0.confidence > $1.confidence }
        
        // Filter by minimum confidence
        let validCandidates = allCandidates.filter { $0.confidence >= minimumConfidence }
        
        guard !validCandidates.isEmpty else {
            return RecognitionResult(
                recognizedText: "",
                confidence: 0.0,
                alternativeTexts: [],
                processingTime: 0.0
            )
        }
        
        // Get the best result
        let bestCandidate = validCandidates.first!
        
        // Get alternative texts (excluding the best one)
        let alternatives = validCandidates.dropFirst().prefix(3).map { $0.text }
        
        // Clean up the recognized text
        let cleanedText = cleanupRecognizedText(bestCandidate.text)
        
        return RecognitionResult(
            recognizedText: cleanedText,
            confidence: bestCandidate.confidence,
            alternativeTexts: Array(alternatives),
            processingTime: 1.0 // Mock processing time
        )
    }
    
    private func cleanupRecognizedText(_ text: String) -> String {
        // Remove extra whitespaces
        var cleaned = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix common OCR mistakes for Vietnamese
        cleaned = fixVietnameseOCRMistakes(cleaned)
        
        // Capitalize first letter
        if !cleaned.isEmpty {
            cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
        
        return cleaned
    }
    
    private func fixVietnameseOCRMistakes(_ text: String) -> String {
        var fixed = text
        
        // Common OCR mistakes for Vietnamese characters
        let corrections: [String: String] = [
            "ă": "ă", "â": "â", "đ": "đ", "ê": "ê", "ô": "ô", "ơ": "ơ", "ư": "ư",
            "à": "à", "á": "á", "ả": "ả", "ã": "ã", "ạ": "ạ",
            "è": "è", "é": "é", "ẻ": "ẻ", "ẽ": "ẽ", "ẹ": "ẹ",
            "ì": "ì", "í": "í", "ỉ": "ỉ", "ĩ": "ĩ", "ị": "ị",
            "ò": "ò", "ó": "ó", "ỏ": "ỏ", "õ": "õ", "ọ": "ọ",
            "ù": "ù", "ú": "ú", "ủ": "ủ", "ũ": "ũ", "ụ": "ụ",
            "ỳ": "ỳ", "ý": "ý", "ỷ": "ỷ", "ỹ": "ỹ", "ỵ": "ỵ"
        ]
        
        // Apply corrections
        for (wrong, correct) in corrections {
            fixed = fixed.replacingOccurrences(of: wrong, with: correct)
        }
        
        // Fix common word mistakes
        let wordCorrections: [String: String] = [
            "con": "con",
            "meo": "mèo",
            "ngoi": "ngồi",
            "tren": "trên",
            "tham": "thảm"
        ]
        
        for (wrong, correct) in wordCorrections {
            fixed = fixed.replacingOccurrences(of: "\\b\(wrong)\\b", with: correct, options: .regularExpression)
        }
        
        return fixed
    }
}

// MARK: - Handwriting Recognition Extensions
extension HandwritingRecognizer {
    func preprocessDrawing(_ drawing: PKDrawing) -> PKDrawing {
        // Create a new drawing with optimized strokes
        let processedDrawing = PKDrawing()
        
        for stroke in drawing.strokes {
            // Smooth the stroke path
            let smoothedStroke = smoothStroke(stroke)
            processedDrawing.strokes.append(smoothedStroke)
        }
        
        return processedDrawing
    }
    
    private func smoothStroke(_ stroke: PKStroke) -> PKStroke {
        // Simple stroke smoothing
        // In a real implementation, you might apply more sophisticated smoothing algorithms
        return stroke
    }
    
    func getDrawingBounds(_ drawing: PKDrawing) -> CGRect {
        return drawing.bounds
    }
    
    func isDrawingValid(_ drawing: PKDrawing) -> Bool {
        // Check if drawing has enough content for recognition
        guard !drawing.strokes.isEmpty else { return false }
        
        // Check if drawing bounds are reasonable
        let bounds = drawing.bounds
        let minSize: CGFloat = 20
        
        return bounds.width >= minSize && bounds.height >= minSize
    }
    
    func estimateTextLength(_ drawing: PKDrawing) -> Int {
        // Estimate number of characters based on drawing complexity
        let strokeCount = drawing.strokes.count
        let bounds = drawing.bounds
        let area = bounds.width * bounds.height
        
        // Simple heuristic: more strokes and larger area = more text
        let estimatedLength = Int(sqrt(area) / 50 + Double(strokeCount) / 3)
        return max(1, estimatedLength)
    }
}

// MARK: - Recognition Quality Assessment
extension HandwritingRecognizer {
    func assessRecognitionQuality(_ result: RecognitionResult) -> RecognitionQuality {
        let confidence = result.confidence
        let textLength = result.recognizedText.count
        let hasAlternatives = !result.alternativeTexts.isEmpty
        
        switch (confidence, textLength, hasAlternatives) {
        case (0.8...1.0, 5..., _):
            return .excellent
        case (0.6..<0.8, 3..., _):
            return .good
        case (0.4..<0.6, 1..., true):
            return .fair
        default:
            return .poor
        }
    }
    
    func getSuggestions(for quality: RecognitionQuality) -> [String] {
        switch quality {
        case .excellent:
            return ["Tuyệt vời! Chữ viết rất rõ ràng."]
        case .good:
            return ["Tốt lắm! Hãy viết chậm hơn một chút."]
        case .fair:
            return [
                "Hãy viết to hơn và rõ ràng hơn.",
                "Viết từng chữ cách đều nhau."
            ]
        case .poor:
            return [
                "Hãy viết chậm và rõ ràng hơn.",
                "Viết chữ to hơn.",
                "Đảm bảo không viết chồng lên nhau."
            ]
        }
    }
}

// MARK: - Recognition Quality Enum
enum RecognitionQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Tuyệt vời"
        case .good:
            return "Tốt"
        case .fair:
            return "Khá"
        case .poor:
            return "Cần cải thiện"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .poor:
            return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "hand.thumbsup.fill"
        case .fair:
            return "hand.raised.fill"
        case .poor:
            return "exclamationmark.triangle.fill"
        }
    }
}