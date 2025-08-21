import SwiftUI
import Combine

// MARK: - Session Results View Model
@MainActor
final class SessionResultsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var accuracyBreakdown: [AccuracyBreakdownData] = []
    @Published var mistakeTypeBreakdown: [MistakeTypeData] = []
    @Published var newAchievements: [Achievement] = []
    @Published var recommendations: [Recommendation] = []
    @Published var previousAccuracy: Float = 0.0
    @Published var previousScore: Int = 0
    @Published var previousSpeed: Float = 0.0
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let progressTracker = ProgressTrackingFactory.shared.getProgressTracker()
    private let achievementService = AchievementService()
    private let recommendationEngine = RecommendationEngine()
    
    // MARK: - Public Methods
    
    func processResults(_ sessionResult: SessionResult) {
        isLoading = true
        
        Task {
            do {
                // Generate accuracy breakdown
                generateAccuracyBreakdown(from: sessionResult)
                
                // Analyze mistake types
                analyzeMistakeTypes(from: sessionResult.mistakes)
                
                // Load previous performance data
                await loadPreviousPerformance(userId: sessionResult.userId)
                
                // Check for new achievements
                await checkForNewAchievements(sessionResult)
                
                // Generate recommendations
                generateRecommendations(from: sessionResult)
                
                isLoading = false
            } catch {
                print("Error processing results: \(error)")
                isLoading = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generateAccuracyBreakdown(from sessionResult: SessionResult) {
        // Simulate breaking down the text into sections for analysis
        let words = sessionResult.originalText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sectionSize = max(1, words.count / 4) // Divide into 4 sections
        
        var breakdown: [AccuracyBreakdownData] = []
        
        for i in 0..<4 {
            let startIndex = i * sectionSize
            let endIndex = min((i + 1) * sectionSize, words.count)
            
            if startIndex < words.count {
                let sectionWords = Array(words[startIndex..<endIndex])
                let sectionMistakes = sessionResult.mistakes.filter { mistake in
                    mistake.position >= startIndex && mistake.position < endIndex
                }
                
                let sectionAccuracy = sectionWords.isEmpty ? 1.0 : 
                    Float(sectionWords.count - sectionMistakes.count) / Float(sectionWords.count)
                
                breakdown.append(AccuracyBreakdownData(
                    section: "Phần \(i + 1)",
                    accuracy: max(0, sectionAccuracy)
                ))
            }
        }
        
        accuracyBreakdown = breakdown
    }
    
    private func analyzeMistakeTypes(from mistakes: [TextMistake]) {
        let mistakeGroups = Dictionary(grouping: mistakes) { $0.mistakeType }
        
        mistakeTypeBreakdown = mistakeGroups.map { (type, mistakes) in
            MistakeTypeData(mistakeType: type, count: mistakes.count)
        }.sorted { $0.count > $1.count }
    }
    
    private func loadPreviousPerformance(userId: String) async {
        do {
            // Get recent progress to compare with
            let recentProgress = try await progressTracker.getUserProgress(userId: userId, period: .weekly)
            
            // Calculate previous averages (simplified)
            previousAccuracy = recentProgress.averageAccuracy
            previousScore = recentProgress.totalScore / max(1, recentProgress.totalSessions)
            previousSpeed = 60.0 // Mock previous speed - would come from actual data
            
        } catch {
            print("Error loading previous performance: \(error)")
            // Use default values
            previousAccuracy = 0.75
            previousScore = 70
            previousSpeed = 50.0
        }
    }
    
    private func checkForNewAchievements(_ sessionResult: SessionResult) async {
        // This would integrate with the actual achievement system
        // For now, simulate some achievements based on performance
        
        var achievements: [Achievement] = []
        
        // Perfect score achievement
        if sessionResult.isPerfectScore {
            achievements.append(Achievement(
                id: "perfect_score",
                title: "Điểm số hoàn hảo",
                description: "Đạt 100% độ chính xác",
                category: .accuracy,
                difficulty: .gold,
                requirementType: .perfectScores,
                requirementTarget: 1
            ))
        }
        
        // High accuracy achievement
        if sessionResult.accuracy >= 0.9 {
            achievements.append(Achievement(
                id: "high_accuracy",
                title: "Độ chính xác cao",
                description: "Đạt trên 90% độ chính xác",
                category: .accuracy,
                difficulty: .silver,
                requirementType: .averageAccuracy,
                requirementTarget: 90
            ))
        }
        
        // Speed achievement
        if sessionResult.wordsPerMinute >= 80 {
            achievements.append(Achievement(
                id: "speed_reader",
                title: "Đọc nhanh",
                description: "Đọc trên 80 từ/phút",
                category: .speed,
                difficulty: .bronze,
                requirementType: .readingSpeed,
                requirementTarget: 80
            ))
        }
        
        newAchievements = achievements
    }
    
    private func generateRecommendations(from sessionResult: SessionResult) {
        var recs: [Recommendation] = []
        
        // Accuracy-based recommendations
        if sessionResult.accuracy < 0.7 {
            recs.append(Recommendation(
                id: "slow_down",
                title: "Đọc chậm hơn",
                description: "Hãy đọc chậm và rõ ràng từng từ để cải thiện độ chính xác",
                icon: "tortoise.fill",
                priority: .high,
                category: .accuracy
            ))
        }
        
        // Speed-based recommendations
        if sessionResult.wordsPerMinute < 40 {
            recs.append(Recommendation(
                id: "practice_more",
                title: "Luyện tập thêm",
                description: "Luyện tập đều đặn sẽ giúp bé đọc nhanh và chính xác hơn",
                icon: "book.fill",
                priority: .medium,
                category: .practice
            ))
        }
        
        // Mistake-based recommendations
        let substitutionMistakes = sessionResult.mistakes.filter { $0.mistakeType == .substitution }
        if substitutionMistakes.count > 2 {
            recs.append(Recommendation(
                id: "focus_pronunciation",
                title: "Chú ý phát âm",
                description: "Hãy nghe kỹ và phát âm rõ ràng từng từ",
                icon: "speaker.wave.2.fill",
                priority: .medium,
                category: .pronunciation
            ))
        }
        
        // Positive reinforcement
        if sessionResult.accuracy >= 0.85 {
            recs.append(Recommendation(
                id: "keep_going",
                title: "Tiếp tục cố gắng",
                description: "Bé đang làm rất tốt! Hãy tiếp tục luyện tập để tiến bộ hơn nữa",
                icon: "star.fill",
                priority: .low,
                category: .encouragement
            ))
        }
        
        // Difficulty progression
        if sessionResult.accuracy >= 0.9 && sessionResult.difficulty.nextLevel != nil {
            recs.append(Recommendation(
                id: "try_harder",
                title: "Thử cấp độ cao hơn",
                description: "Bé đã thành thạo cấp độ này, hãy thử thách bản thân với cấp độ cao hơn",
                icon: "arrow.up.circle.fill",
                priority: .medium,
                category: .progression
            ))
        }
        
        recommendations = recs
    }
}

// MARK: - Data Models

struct AccuracyBreakdownData {
    let section: String
    let accuracy: Float
}

struct MistakeTypeData {
    let mistakeType: MistakeType
    let count: Int
}

struct Recommendation {
    let id: String
    let title: String
    let description: String
    let icon: String
    let priority: RecommendationPriority
    let category: RecommendationCategory
}

enum RecommendationPriority {
    case high
    case medium
    case low
    
    var color: Color {
        switch self {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

enum RecommendationCategory {
    case accuracy
    case speed
    case pronunciation
    case practice
    case progression
    case encouragement
}

// MARK: - MistakeType Extension

extension MistakeType {
    var color: Color {
        switch self {
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
    
    var localizedName: String {
        switch self {
        case .substitution:
            return "Thay thế sai"
        case .omission:
            return "Bỏ sót"
        case .insertion:
            return "Thêm từ"
        case .pronunciation:
            return "Phát âm"
        }
    }
}

// MARK: - Mock Services

class AchievementService {
    func checkAchievements(for sessionResult: SessionResult) async -> [Achievement] {
        // Mock implementation
        return []
    }
}

class RecommendationEngine {
    func generateRecommendations(for sessionResult: SessionResult) -> [Recommendation] {
        // Mock implementation
        return []
    }
}