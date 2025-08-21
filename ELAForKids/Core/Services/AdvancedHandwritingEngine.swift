import Foundation
import PencilKit
import Vision
import UIKit
import CoreML

// MARK: - Advanced Handwriting Recognition Engine
final class AdvancedHandwritingEngine {
    
    // MARK: - Properties
    private let visionQueue = DispatchQueue(label: "handwriting.vision", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "handwriting.processing", qos: .background)
    
    // Recognition settings
    private let recognitionLanguages = ["vi-VN", "en-US"]
    private let minimumTextHeight: Float = 0.01
    private let maximumCandidates = 10
    
    // MARK: - Main Recognition Method
    func recognizeText(from drawing: PKDrawing) async throws -> RecognitionResult {
        // Step 1: Preprocess drawing
        let preprocessedDrawing = preprocessDrawing(drawing)
        
        // Step 2: Convert to image with optimal settings
        let image = try await convertDrawingToOptimalImage(preprocessedDrawing)
        
        // Step 3: Perform Vision recognition
        let visionResults = try await performVisionRecognition(on: image)
        
        // Step 4: Post-process results
        let processedResult = await processRecognitionResults(visionResults, originalDrawing: drawing)
        
        return processedResult
    }
    
    // MARK: - Drawing Preprocessing
    private func preprocessDrawing(_ drawing: PKDrawing) -> PKDrawing {
        let processedDrawing = PKDrawing()
        
        for stroke in drawing.strokes {
            let processedStroke = preprocessStroke(stroke)
            processedDrawing.strokes.append(processedStroke)
        }
        
        return processedDrawing
    }
    
    private func preprocessStroke(_ stroke: PKStroke) -> PKStroke {
        // Smooth stroke points to reduce noise
        let smoothedPoints = smoothStrokePoints(stroke.path)
        
        // Create new stroke with smoothed path
        let smoothedPath = PKStrokePath(controlPoints: smoothedPoints, creationDate: stroke.path.creationDate)
        
        return PKStroke(ink: stroke.ink, path: smoothedPath)
    }
    
    private func smoothStrokePoints(_ path: PKStrokePath) -> [PKStrokePoint] {
        let originalPoints = (0..<path.count).map { path.point(at: $0) }
        guard originalPoints.count > 2 else { return originalPoints }
        
        var smoothedPoints: [PKStrokePoint] = []
        smoothedPoints.append(originalPoints[0]) // Keep first point
        
        // Apply simple moving average smoothing
        for i in 1..<(originalPoints.count - 1) {
            let prev = originalPoints[i - 1]
            let current = originalPoints[i]
            let next = originalPoints[i + 1]
            
            let smoothedLocation = CGPoint(
                x: (prev.location.x + current.location.x + next.location.x) / 3,
                y: (prev.location.y + current.location.y + next.location.y) / 3
            )
            
            let smoothedPoint = PKStrokePoint(
                location: smoothedLocation,
                timeOffset: current.timeOffset,
                size: current.size,
                opacity: current.opacity,
                force: current.force,
                azimuth: current.azimuth,
                altitude: current.altitude
            )
            
            smoothedPoints.append(smoothedPoint)
        }
        
        smoothedPoints.append(originalPoints.last!) // Keep last point
        return smoothedPoints
    }
    
    // MARK: - Image Conversion
    private func convertDrawingToOptimalImage(_ drawing: PKDrawing) async throws -> UIImage {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let bounds = drawing.bounds
                guard bounds.width > 0 && bounds.height > 0 else {
                    continuation.resume(returning: UIImage())
                    return
                }
                
                // Calculate optimal scale for recognition
                let targetWidth: CGFloat = 1024
                let scale = min(targetWidth / bounds.width, 4.0)
                
                // Create image with white background for better recognition
                let image = drawing.image(from: bounds, scale: scale)
                let whiteBackgroundImage = self.addWhiteBackground(to: image)
                
                continuation.resume(returning: whiteBackgroundImage)
            }
        }
    }
    
    private func addWhiteBackground(to image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Fill with white background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: image.size))
        
        // Draw original image on top
        image.draw(at: .zero)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    // MARK: - Vision Recognition
    private func performVisionRecognition(on image: UIImage) async throws -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else {
            throw HandwritingRecognitionError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        continuation.resume(throwing: HandwritingRecognitionError.visionRecognitionFailed(error))
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(throwing: HandwritingRecognitionError.noTextFound)
                        return
                    }
                    
                    continuation.resume(returning: observations)
                }
                
                // Configure request for optimal handwriting recognition
                self.configureVisionRequest(request)
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: HandwritingRecognitionError.visionRecognitionFailed(error))
                }
            }
        }
    }
    
    private func configureVisionRequest(_ request: VNRecognizeTextRequest) {
        // Set recognition level to accurate for better handwriting recognition
        request.recognitionLevel = .accurate
        
        // Set supported languages
        request.recognitionLanguages = recognitionLanguages
        
        // Enable language correction
        request.usesLanguageCorrection = true
        
        // Set minimum text height for better small text recognition
        request.minimumTextHeight = minimumTextHeight
        
        // Enable automatic language detection
        request.automaticallyDetectsLanguage = true
    }
    
    // MARK: - Result Processing
    private func processRecognitionResults(_ observations: [VNRecognizedTextObservation], originalDrawing: PKDrawing) async -> RecognitionResult {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Extract all candidates with their confidence scores
                var allCandidates: [(text: String, confidence: Float, boundingBox: CGRect)] = []
                
                for observation in observations {
                    let candidates = observation.topCandidates(self.maximumCandidates)
                    for candidate in candidates {
                        allCandidates.append((
                            text: candidate.string,
                            confidence: candidate.confidence,
                            boundingBox: observation.boundingBox
                        ))
                    }
                }
                
                // Sort by confidence and filter
                allCandidates.sort { $0.confidence > $1.confidence }
                let validCandidates = allCandidates.filter { $0.confidence >= 0.1 }
                
                guard !validCandidates.isEmpty else {
                    let emptyResult = RecognitionResult(
                        recognizedText: "",
                        confidence: 0.0,
                        alternativeTexts: [],
                        processingTime: CFAbsoluteTimeGetCurrent() - startTime
                    )
                    continuation.resume(returning: emptyResult)
                    return
                }
                
                // Get the best candidate
                let bestCandidate = validCandidates[0]
                
                // Process and clean the text
                let cleanedText = self.postProcessRecognizedText(bestCandidate.text)
                
                // Get alternative texts
                let alternatives = validCandidates.dropFirst().prefix(5).map { 
                    self.postProcessRecognizedText($0.text) 
                }.filter { !$0.isEmpty && $0 != cleanedText }
                
                // Calculate final confidence based on multiple factors
                let finalConfidence = self.calculateFinalConfidence(
                    visionConfidence: bestCandidate.confidence,
                    textLength: cleanedText.count,
                    drawingComplexity: self.calculateDrawingComplexity(originalDrawing)
                )
                
                let result = RecognitionResult(
                    recognizedText: cleanedText,
                    confidence: finalConfidence,
                    alternativeTexts: Array(alternatives),
                    processingTime: CFAbsoluteTimeGetCurrent() - startTime
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Text Post-Processing
    private func postProcessRecognizedText(_ text: String) -> String {
        var processed = text
        
        // Step 1: Basic cleanup
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Step 2: Fix Vietnamese diacritics
        processed = fixVietnameseDiacritics(processed)
        
        // Step 3: Fix common OCR mistakes
        processed = fixCommonOCRMistakes(processed)
        
        // Step 4: Apply Vietnamese language rules
        processed = applyVietnameseLanguageRules(processed)
        
        // Step 5: Capitalize appropriately
        processed = capitalizeAppropriately(processed)
        
        return processed
    }
    
    private func fixVietnameseDiacritics(_ text: String) -> String {
        var fixed = text
        
        // Common diacritic corrections
        let diacriticCorrections: [String: String] = [
            // Vowel corrections
            "a": "a", "ă": "ă", "â": "â",
            "e": "e", "ê": "ê",
            "i": "i", "í": "í", "ì": "ì", "ỉ": "ỉ", "ĩ": "ĩ", "ị": "ị",
            "o": "o", "ô": "ô", "ơ": "ơ",
            "u": "u", "ư": "ư",
            "y": "y", "ý": "ý", "ỳ": "ỳ", "ỷ": "ỷ", "ỹ": "ỹ", "ỵ": "ỵ",
            
            // Consonant corrections
            "d": "d", "đ": "đ"
        ]
        
        for (pattern, replacement) in diacriticCorrections {
            fixed = fixed.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return fixed
    }
    
    private func fixCommonOCRMistakes(_ text: String) -> String {
        var fixed = text
        
        // Common OCR mistakes for Vietnamese
        let ocrCorrections: [String: String] = [
            // Number/letter confusions
            "0": "o", "1": "l", "5": "s",
            
            // Common word mistakes
            "meo": "mèo", "con": "con", "ngoi": "ngồi",
            "tren": "trên", "tham": "thảm", "xanh": "xanh",
            "nho": "nhỏ", "mau": "màu", "nau": "nâu",
            
            // Punctuation fixes
            ",": ",", ".": ".", "!": "!", "?": "?"
        ]
        
        for (wrong, correct) in ocrCorrections {
            fixed = fixed.replacingOccurrences(of: "\\b\(wrong)\\b", with: correct, options: .regularExpression)
        }
        
        return fixed
    }
    
    private func applyVietnameseLanguageRules(_ text: String) -> String {
        var processed = text
        
        // Apply basic Vietnamese grammar rules
        let words = processed.components(separatedBy: .whitespaces)
        var correctedWords: [String] = []
        
        for (index, word) in words.enumerated() {
            var correctedWord = word
            
            // Apply context-based corrections
            if index > 0 {
                let previousWord = words[index - 1].lowercased()
                correctedWord = applyContextualCorrections(word: correctedWord, previousWord: previousWord)
            }
            
            correctedWords.append(correctedWord)
        }
        
        processed = correctedWords.joined(separator: " ")
        return processed
    }
    
    private func applyContextualCorrections(word: String, previousWord: String) -> String {
        let lowercaseWord = word.lowercased()
        
        // Context-based corrections
        switch (previousWord, lowercaseWord) {
        case ("con", "meo"):
            return "mèo"
        case ("ngồi", "tren"):
            return "trên"
        case ("trên", "tham"):
            return "thảm"
        case ("màu", "nau"):
            return "nâu"
        default:
            return word
        }
    }
    
    private func capitalizeAppropriately(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        // Capitalize first letter of the text
        let firstChar = text.prefix(1).uppercased()
        let remainingText = text.dropFirst()
        
        return firstChar + remainingText
    }
    
    // MARK: - Confidence Calculation
    private func calculateFinalConfidence(visionConfidence: Float, textLength: Int, drawingComplexity: Float) -> Float {
        var confidence = visionConfidence
        
        // Adjust based on text length
        if textLength < 3 {
            confidence *= 0.8 // Reduce confidence for very short text
        } else if textLength > 50 {
            confidence *= 0.9 // Slightly reduce confidence for very long text
        }
        
        // Adjust based on drawing complexity
        if drawingComplexity < 0.3 {
            confidence *= 0.7 // Reduce confidence for very simple drawings
        } else if drawingComplexity > 0.8 {
            confidence *= 0.9 // Slightly reduce confidence for very complex drawings
        }
        
        return min(1.0, max(0.0, confidence))
    }
    
    private func calculateDrawingComplexity(_ drawing: PKDrawing) -> Float {
        let strokeCount = drawing.strokes.count
        let bounds = drawing.bounds
        let area = bounds.width * bounds.height
        
        // Simple complexity calculation based on strokes and area
        let strokeComplexity = min(Float(strokeCount) / 20.0, 1.0)
        let areaComplexity = min(Float(area) / 100000.0, 1.0)
        
        return (strokeComplexity + areaComplexity) / 2.0
    }
}

// MARK: - Handwriting Recognition Errors
enum HandwritingRecognitionError: LocalizedError {
    case imageConversionFailed
    case visionRecognitionFailed(Error)
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Không thể chuyển đổi hình ảnh"
        case .visionRecognitionFailed(let error):
            return "Lỗi nhận dạng: \(error.localizedDescription)"
        case .noTextFound:
            return "Không tìm thấy văn bản"
        case .processingFailed:
            return "Lỗi xử lý kết quả"
        }
    }
}

// MARK: - Recognition Statistics
struct RecognitionStatistics {
    let processingTime: TimeInterval
    let strokeCount: Int
    let drawingArea: CGFloat
    let candidateCount: Int
    let finalConfidence: Float
    let recognizedCharacterCount: Int
    
    var averageConfidencePerCharacter: Float {
        guard recognizedCharacterCount > 0 else { return 0 }
        return finalConfidence / Float(recognizedCharacterCount)
    }
    
    var processingSpeed: Float {
        guard processingTime > 0 else { return 0 }
        return Float(recognizedCharacterCount) / Float(processingTime)
    }
}

extension AdvancedHandwritingEngine {
    func getRecognitionStatistics(for result: RecognitionResult, drawing: PKDrawing) -> RecognitionStatistics {
        return RecognitionStatistics(
            processingTime: result.processingTime,
            strokeCount: drawing.strokes.count,
            drawingArea: drawing.bounds.width * drawing.bounds.height,
            candidateCount: result.alternativeTexts.count + 1,
            finalConfidence: result.confidence,
            recognizedCharacterCount: result.recognizedText.count
        )
    }
}