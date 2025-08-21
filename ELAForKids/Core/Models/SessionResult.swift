import Foundation

// MARK: - Session Result Model
struct SessionResult: Codable, Identifiable {
    let id: UUID
    let userId: String
    let exerciseId: UUID
    let originalText: String
    let spokenText: String
    let accuracy: Float
    let score: Int
    let timeSpent: TimeInterval
    let mistakes: [TextMistake]
    let completedAt: Date
    let difficulty: DifficultyLevel
    let inputMethod: InputMethod
    let attempts: Int
    let category: AchievementCategory?
    
    init(
        id: UUID = UUID(),
        userId: String,
        exerciseId: UUID,
        originalText: String,
        spokenText: String,
        accuracy: Float,
        score: Int,
        timeSpent: TimeInterval,
        mistakes: [TextMistake] = [],
        completedAt: Date = Date(),
        difficulty: DifficultyLevel,
        inputMethod: InputMethod,
        attempts: Int = 1,
        category: AchievementCategory? = nil
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.originalText = originalText
        self.spokenText = spokenText
        self.accuracy = accuracy
        self.score = score
        self.timeSpent = timeSpent
        self.mistakes = mistakes
        self.completedAt = completedAt
        self.difficulty = difficulty
        self.inputMethod = inputMethod
        self.attempts = attempts
        self.category = category
    }
    
    /// Performance level based on accuracy
    var performanceLevel: PerformanceLevel {
        switch accuracy {
        case 0.95...1.0:
            return .excellent
        case 0.85..<0.95:
            return .good
        case 0.70..<0.85:
            return .fair
        default:
            return .needsImprovement
        }
    }
    
    /// Whether this session qualifies for streak bonus
    var qualifiesForStreak: Bool {
        return accuracy >= 0.8
    }
    
    /// Formatted time spent
    var formattedTimeSpent: String {
        let minutes = Int(timeSpent / 60)
        let seconds = Int(timeSpent.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Grade based on accuracy
    var grade: String {
        switch accuracy {
        case 0.95...1.0:
            return "A+"
        case 0.90..<0.95:
            return "A"
        case 0.85..<0.90:
            return "B+"
        case 0.80..<0.85:
            return "B"
        case 0.75..<0.80:
            return "C+"
        case 0.70..<0.75:
            return "C"
        case 0.60..<0.70:
            return "D"
        default:
            return "F"
        }
    }
    
    /// Number of words read correctly
    var correctWords: Int {
        let totalWords = originalText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let incorrectWords = mistakes.count
        return max(0, totalWords - incorrectWords)
    }
    
    /// Total number of words in the text
    var totalWords: Int {
        return originalText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    /// Words per minute reading speed
    var wordsPerMinute: Float {
        guard timeSpent > 0 else { return 0 }
        let minutes = Float(timeSpent / 60)
        return Float(totalWords) / minutes
    }
    
    /// Whether this is a perfect score
    var isPerfectScore: Bool {
        return accuracy >= 1.0
    }
    
    /// Difficulty-adjusted score
    var adjustedScore: Int {
        let multiplier: Float
        switch difficulty {
        case .grade1:
            multiplier = 1.0
        case .grade2:
            multiplier = 1.2
        case .grade3:
            multiplier = 1.4
        case .grade4:
            multiplier = 1.6
        case .grade5:
            multiplier = 1.8
        }
        return Int(Float(score) * multiplier)
    }
}

// MARK: - Input Method Enum
enum InputMethod: String, CaseIterable, Codable {
    case keyboard = "keyboard"
    case handwriting = "handwriting"
    case voice = "voice"
    
    var localizedName: String {
        switch self {
        case .keyboard:
            return "Bàn phím"
        case .handwriting:
            return "Viết tay"
        case .voice:
            return "Giọng nói"
        }
    }
    
    var icon: String {
        switch self {
        case .keyboard:
            return "keyboard"
        case .handwriting:
            return "pencil.tip"
        case .voice:
            return "mic.fill"
        }
    }
    
    var isAvailableOnDevice: Bool {
        switch self {
        case .keyboard:
            return true
        case .handwriting:
            #if os(iOS)
            return UIDevice.current.userInterfaceIdiom == .pad
            #else
            return false
            #endif
        case .voice:
            return true
        }
    }
}

// MARK: - Difficulty Level Enum
enum DifficultyLevel: String, CaseIterable, Codable {
    case grade1 = "grade1"
    case grade2 = "grade2"
    case grade3 = "grade3"
    case grade4 = "grade4"
    case grade5 = "grade5"
    
    var localizedName: String {
        switch self {
        case .grade1:
            return "Lớp 1"
        case .grade2:
            return "Lớp 2"
        case .grade3:
            return "Lớp 3"
        case .grade4:
            return "Lớp 4"
        case .grade5:
            return "Lớp 5"
        }
    }
    
    var color: String {
        switch self {
        case .grade1:
            return "green"
        case .grade2:
            return "blue"
        case .grade3:
            return "orange"
        case .grade4:
            return "purple"
        case .grade5:
            return "red"
        }
    }
    
    var emoji: String {
        switch self {
        case .grade1:
            return "🌱"
        case .grade2:
            return "🌿"
        case .grade3:
            return "🌳"
        case .grade4:
            return "🏆"
        case .grade5:
            return "👑"
        }
    }
    
    var expectedAccuracy: Float {
        switch self {
        case .grade1:
            return 0.7
        case .grade2:
            return 0.75
        case .grade3:
            return 0.8
        case .grade4:
            return 0.85
        case .grade5:
            return 0.9
        }
    }
    
    var scoreMultiplier: Float {
        switch self {
        case .grade1:
            return 1.0
        case .grade2:
            return 1.2
        case .grade3:
            return 1.4
        case .grade4:
            return 1.6
        case .grade5:
            return 1.8
        }
    }
    
    var nextLevel: DifficultyLevel? {
        switch self {
        case .grade1:
            return .grade2
        case .grade2:
            return .grade3
        case .grade3:
            return .grade4
        case .grade4:
            return .grade5
        case .grade5:
            return nil
        }
    }
    
    var previousLevel: DifficultyLevel? {
        switch self {
        case .grade1:
            return nil
        case .grade2:
            return .grade1
        case .grade3:
            return .grade2
        case .grade4:
            return .grade3
        case .grade5:
            return .grade4
        }
    }
}

// MARK: - Achievement Category Enum
enum AchievementCategory: String, CaseIterable, Codable {
    case reading = "reading"
    case accuracy = "accuracy"
    case streak = "streak"
    case volume = "volume"
    case speed = "speed"
    case special = "special"
    
    var localizedName: String {
        switch self {
        case .reading:
            return "Đọc"
        case .accuracy:
            return "Độ chính xác"
        case .streak:
            return "Chuỗi học tập"
        case .volume:
            return "Số lượng"
        case .speed:
            return "Tốc độ"
        case .special:
            return "Đặc biệt"
        }
    }
    
    var icon: String {
        switch self {
        case .reading:
            return "book.fill"
        case .accuracy:
            return "target"
        case .streak:
            return "flame.fill"
        case .volume:
            return "chart.bar.fill"
        case .speed:
            return "speedometer"
        case .special:
            return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .reading:
            return "blue"
        case .accuracy:
            return "green"
        case .streak:
            return "orange"
        case .volume:
            return "purple"
        case .speed:
            return "red"
        case .special:
            return "gold"
        }
    }
    
    var description: String {
        switch self {
        case .reading:
            return "Thành tích liên quan đến việc đọc"
        case .accuracy:
            return "Thành tích về độ chính xác"
        case .streak:
            return "Thành tích học liên tục"
        case .volume:
            return "Thành tích về số lượng bài học"
        case .speed:
            return "Thành tích về tốc độ đọc"
        case .special:
            return "Thành tích đặc biệt"
        }
    }
}

// MARK: - User Score Model
struct UserScore: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let totalScore: Int
    let level: Int
    let experience: Int
    let streak: Int
    let lastUpdated: Date
    let achievements: [String]
    
    /// Experience needed for next level
    var experienceToNextLevel: Int {
        let nextLevelExp = calculateRequiredExperience(for: level + 1)
        let currentLevelExp = calculateRequiredExperience(for: level)
        return nextLevelExp - experience
    }
    
    /// Progress to next level (0.0 to 1.0)
    var levelProgress: Float {
        let currentLevelExp = calculateRequiredExperience(for: level)
        let nextLevelExp = calculateRequiredExperience(for: level + 1)
        let progressExp = experience - currentLevelExp
        let totalExpNeeded = nextLevelExp - currentLevelExp
        
        guard totalExpNeeded > 0 else { return 1.0 }
        return Float(progressExp) / Float(totalExpNeeded)
    }
    
    /// Level title
    var levelTitle: String {
        switch level {
        case 1...5:
            return "Người mới bắt đầu"
        case 6...10:
            return "Học sinh chăm chỉ"
        case 11...20:
            return "Đọc giả nhỏ"
        case 21...35:
            return "Chuyên gia đọc"
        case 36...50:
            return "Bậc thầy ngôn ngữ"
        default:
            return "Huyền thoại"
        }
    }
    
    /// Level color
    var levelColor: String {
        switch level {
        case 1...5:
            return "gray"
        case 6...10:
            return "green"
        case 11...20:
            return "blue"
        case 21...35:
            return "purple"
        case 36...50:
            return "gold"
        default:
            return "rainbow"
        }
    }
    
    private func calculateRequiredExperience(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        
        var totalExp = 0
        for currentLevel in 2...level {
            totalExp += 100 * currentLevel + 50 * (currentLevel - 1) * currentLevel
        }
        return totalExp
    }
}