import Foundation
import PencilKit

// MARK: - Handwriting Analytics
final class HandwritingAnalytics {
    
    // MARK: - Writing Pattern Analysis
    func analyzeWritingPattern(_ drawing: PKDrawing) -> WritingPatternAnalysis {
        let strokes = drawing.strokes
        
        return WritingPatternAnalysis(
            strokeCount: strokes.count,
            averageStrokeLength: calculateAverageStrokeLength(strokes),
            writingSpeed: calculateWritingSpeed(strokes),
            pressure: calculateAveragePressure(strokes),
            consistency: calculateConsistency(strokes),
            direction: analyzeWritingDirection(strokes),
            spacing: analyzeSpacing(strokes)
        )
    }
    
    private func calculateAverageStrokeLength(_ strokes: [PKStroke]) -> Float {
        guard !strokes.isEmpty else { return 0 }
        
        let totalLength = strokes.reduce(0.0) { sum, stroke in
            return sum + calculateStrokeLength(stroke)
        }
        
        return Float(totalLength / Double(strokes.count))
    }
    
    private func calculateStrokeLength(_ stroke: PKStroke) -> Double {
        let path = stroke.path
        guard path.count > 1 else { return 0 }
        
        var length: Double = 0
        for i in 1..<path.count {
            let point1 = path.point(at: i - 1)
            let point2 = path.point(at: i)
            
            let dx = point2.location.x - point1.location.x
            let dy = point2.location.y - point1.location.y
            length += sqrt(Double(dx * dx + dy * dy))
        }
        
        return length
    }
    
    private func calculateWritingSpeed(_ strokes: [PKStroke]) -> Float {
        guard !strokes.isEmpty else { return 0 }
        
        let speeds = strokes.compactMap { stroke -> Float? in
            let path = stroke.path
            guard path.count > 1 else { return nil }
            
            let startTime = path.point(at: 0).timeOffset
            let endTime = path.point(at: path.count - 1).timeOffset
            let duration = endTime - startTime
            
            guard duration > 0 else { return nil }
            
            let length = calculateStrokeLength(stroke)
            return Float(length / duration)
        }
        
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Float(speeds.count)
    }
    
    private func calculateAveragePressure(_ strokes: [PKStroke]) -> Float {
        guard !strokes.isEmpty else { return 0 }
        
        var totalPressure: Float = 0
        var pointCount = 0
        
        for stroke in strokes {
            let path = stroke.path
            for i in 0..<path.count {
                totalPressure += path.point(at: i).force
                pointCount += 1
            }
        }
        
        return pointCount > 0 ? totalPressure / Float(pointCount) : 0
    }
    
    private func calculateConsistency(_ strokes: [PKStroke]) -> Float {
        guard strokes.count > 1 else { return 1.0 }
        
        let strokeLengths = strokes.map { Float(calculateStrokeLength($0)) }
        let averageLength = strokeLengths.reduce(0, +) / Float(strokeLengths.count)
        
        let variance = strokeLengths.reduce(0) { sum, length in
            let diff = length - averageLength
            return sum + (diff * diff)
        } / Float(strokeLengths.count)
        
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = averageLength > 0 ? standardDeviation / averageLength : 0
        
        // Return consistency as 1 - normalized coefficient of variation
        return max(0, 1 - min(1, coefficientOfVariation))
    }
    
    private func analyzeWritingDirection(_ strokes: [PKStroke]) -> WritingDirection {
        guard !strokes.isEmpty else { return .unknown }
        
        var leftToRightCount = 0
        var rightToLeftCount = 0
        var topToBottomCount = 0
        var bottomToTopCount = 0
        
        for stroke in strokes {
            let path = stroke.path
            guard path.count > 1 else { continue }
            
            let startPoint = path.point(at: 0)
            let endPoint = path.point(at: path.count - 1)
            
            let deltaX = endPoint.location.x - startPoint.location.x
            let deltaY = endPoint.location.y - startPoint.location.y
            
            if abs(deltaX) > abs(deltaY) {
                // Horizontal movement is dominant
                if deltaX > 0 {
                    leftToRightCount += 1
                } else {
                    rightToLeftCount += 1
                }
            } else {
                // Vertical movement is dominant
                if deltaY > 0 {
                    topToBottomCount += 1
                } else {
                    bottomToTopCount += 1
                }
            }
        }
        
        let maxCount = max(leftToRightCount, rightToLeftCount, topToBottomCount, bottomToTopCount)
        
        switch maxCount {
        case leftToRightCount:
            return .leftToRight
        case rightToLeftCount:
            return .rightToLeft
        case topToBottomCount:
            return .topToBottom
        case bottomToTopCount:
            return .bottomToTop
        default:
            return .unknown
        }
    }
    
    private func analyzeSpacing(_ strokes: [PKStroke]) -> SpacingAnalysis {
        guard strokes.count > 1 else {
            return SpacingAnalysis(averageSpacing: 0, consistency: 1.0, isEvenlySpaced: true)
        }
        
        var spacings: [Float] = []
        
        for i in 1..<strokes.count {
            let prevStroke = strokes[i - 1]
            let currentStroke = strokes[i]
            
            let prevEnd = getStrokeEndPoint(prevStroke)
            let currentStart = getStrokeStartPoint(currentStroke)
            
            let spacing = distance(from: prevEnd, to: currentStart)
            spacings.append(spacing)
        }
        
        let averageSpacing = spacings.reduce(0, +) / Float(spacings.count)
        let spacingVariance = spacings.reduce(0) { sum, spacing in
            let diff = spacing - averageSpacing
            return sum + (diff * diff)
        } / Float(spacings.count)
        
        let spacingConsistency = max(0, 1 - min(1, sqrt(spacingVariance) / max(1, averageSpacing)))
        let isEvenlySpaced = spacingConsistency > 0.7
        
        return SpacingAnalysis(
            averageSpacing: averageSpacing,
            consistency: spacingConsistency,
            isEvenlySpaced: isEvenlySpaced
        )
    }
    
    private func getStrokeStartPoint(_ stroke: PKStroke) -> CGPoint {
        return stroke.path.point(at: 0).location
    }
    
    private func getStrokeEndPoint(_ stroke: PKStroke) -> CGPoint {
        let path = stroke.path
        return path.point(at: path.count - 1).location
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> Float {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return Float(sqrt(dx * dx + dy * dy))
    }
    
    // MARK: - Recognition Quality Assessment
    func assessRecognitionQuality(_ result: RecognitionResult, drawing: PKDrawing) -> RecognitionQualityAssessment {
        let writingPattern = analyzeWritingPattern(drawing)
        
        return RecognitionQualityAssessment(
            overallQuality: calculateOverallQuality(result, writingPattern: writingPattern),
            confidence: result.confidence,
            textLength: result.recognizedText.count,
            alternativeCount: result.alternativeTexts.count,
            writingPattern: writingPattern,
            suggestions: generateSuggestions(result, writingPattern: writingPattern)
        )
    }
    
    private func calculateOverallQuality(_ result: RecognitionResult, writingPattern: WritingPatternAnalysis) -> RecognitionQuality {
        let confidence = result.confidence
        let textLength = result.recognizedText.count
        let writingConsistency = writingPattern.consistency
        
        let qualityScore = (confidence + writingConsistency) / 2.0
        
        switch (qualityScore, textLength) {
        case (0.8...1.0, 5...):
            return .excellent
        case (0.6..<0.8, 3...):
            return .good
        case (0.4..<0.6, 1...):
            return .fair
        default:
            return .poor
        }
    }
    
    private func generateSuggestions(_ result: RecognitionResult, writingPattern: WritingPatternAnalysis) -> [String] {
        var suggestions: [String] = []
        
        // Confidence-based suggestions
        if result.confidence < 0.5 {
            suggestions.append("Hãy viết chậm và rõ ràng hơn")
        }
        
        if result.confidence < 0.3 {
            suggestions.append("Viết chữ to hơn để dễ nhận dạng")
        }
        
        // Writing pattern suggestions
        if writingPattern.consistency < 0.5 {
            suggestions.append("Cố gắng viết đều tay hơn")
        }
        
        if writingPattern.spacing.consistency < 0.5 {
            suggestions.append("Để khoảng cách đều giữa các từ")
        }
        
        if writingPattern.writingSpeed > 100 {
            suggestions.append("Viết chậm hơn để chính xác hơn")
        }
        
        if writingPattern.pressure < 0.3 {
            suggestions.append("Ấn mạnh hơn khi viết")
        }
        
        // Text length suggestions
        if result.recognizedText.count < 3 {
            suggestions.append("Thử viết nhiều từ hơn")
        }
        
        // Default encouragement
        if suggestions.isEmpty {
            suggestions.append("Tuyệt vời! Tiếp tục cố gắng!")
        }
        
        return suggestions
    }
}

// MARK: - Data Models
struct WritingPatternAnalysis {
    let strokeCount: Int
    let averageStrokeLength: Float
    let writingSpeed: Float
    let pressure: Float
    let consistency: Float
    let direction: WritingDirection
    let spacing: SpacingAnalysis
    
    var qualityScore: Float {
        return (consistency + spacing.consistency + min(1.0, pressure * 2)) / 3.0
    }
}

struct SpacingAnalysis {
    let averageSpacing: Float
    let consistency: Float
    let isEvenlySpaced: Bool
}

enum WritingDirection: String, CaseIterable {
    case leftToRight = "leftToRight"
    case rightToLeft = "rightToLeft"
    case topToBottom = "topToBottom"
    case bottomToTop = "bottomToTop"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .leftToRight:
            return "Trái sang phải"
        case .rightToLeft:
            return "Phải sang trái"
        case .topToBottom:
            return "Trên xuống dưới"
        case .bottomToTop:
            return "Dưới lên trên"
        case .unknown:
            return "Không xác định"
        }
    }
    
    var isCorrect: Bool {
        return self == .leftToRight
    }
}

struct RecognitionQualityAssessment {
    let overallQuality: RecognitionQuality
    let confidence: Float
    let textLength: Int
    let alternativeCount: Int
    let writingPattern: WritingPatternAnalysis
    let suggestions: [String]
    
    var needsImprovement: Bool {
        return overallQuality == .poor || overallQuality == .fair
    }
    
    var isExcellent: Bool {
        return overallQuality == .excellent
    }
}