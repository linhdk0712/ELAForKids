import Foundation
import CoreData

// MARK: - Exercise Extensions
extension Exercise {
    
    // MARK: - Convenience Initializers
    convenience init(context: NSManagedObjectContext, 
                    title: String, 
                    targetText: String, 
                    difficulty: DifficultyLevel, 
                    category: ExerciseCategory? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.targetText = targetText
        self.difficulty = difficulty.rawValue
        self.category = category?.rawValue
        self.createdAt = Date()
        self.tags = ""
    }
    
    // MARK: - Computed Properties
    var difficultyLevel: DifficultyLevel {
        get { DifficultyLevel(rawValue: difficulty ?? "grade1") ?? .grade1 }
        set { difficulty = newValue.rawValue }
    }
    
    var exerciseCategory: ExerciseCategory? {
        get { 
            guard let category = category else { return nil }
            return ExerciseCategory(rawValue: category) 
        }
        set { category = newValue?.rawValue }
    }
    
    var tagList: [String] {
        get { 
            guard let tags = tags, !tags.isEmpty else { return [] }
            return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set { tags = newValue.joined(separator: ", ") }
    }
    
    var wordCount: Int {
        targetText?.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count ?? 0
    }
    
    var estimatedReadingTime: TimeInterval {
        // Average reading speed for children: 100-200 words per minute
        let wordsPerMinute: Double = 150
        return Double(wordCount) / wordsPerMinute * 60 // in seconds
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }
    
    static func fetchByDifficulty(_ difficulty: DifficultyLevel) -> NSFetchRequest<Exercise> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "difficulty == %@", difficulty.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.createdAt, ascending: true)]
        return request
    }
    
    static func fetchByCategory(_ category: ExerciseCategory) -> NSFetchRequest<Exercise> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.title, ascending: true)]
        return request
    }
    
    static func fetchRandom(difficulty: DifficultyLevel? = nil) -> NSFetchRequest<Exercise> {
        let request = fetchRequest()
        if let difficulty = difficulty {
            request.predicate = NSPredicate(format: "difficulty == %@", difficulty.rawValue)
        }
        request.fetchLimit = 1
        // Note: For true randomness, we'd need to implement this in the repository layer
        return request
    }
}

// MARK: - UserProfile Extensions
extension UserProfile {
    
    // MARK: - Convenience Initializers
    convenience init(context: NSManagedObjectContext, 
                    name: String, 
                    grade: Int, 
                    parentEmail: String? = nil) {
        self.init(context: context)
        self.id = UUID().uuidString
        self.name = name
        self.grade = Int16(grade)
        self.parentEmail = parentEmail
        self.createdAt = Date()
        self.totalScore = 0
        self.completedExercises = 0
        self.averageAccuracy = 0.0
        self.currentStreak = 0
        self.bestStreak = 0
        self.totalTimeSpent = 0.0
    }
    
    // MARK: - Computed Properties
    var gradeLevel: DifficultyLevel {
        get {
            switch grade {
            case 1: return .grade1
            case 2: return .grade2
            case 3: return .grade3
            case 4: return .grade4
            case 5: return .grade5
            default: return .grade1
            }
        }
        set {
            switch newValue {
            case .grade1: grade = 1
            case .grade2: grade = 2
            case .grade3: grade = 3
            case .grade4: grade = 4
            case .grade5: grade = 5
            }
        }
    }
    
    var formattedTotalTime: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = Int(totalTimeSpent) % 3600 / 60
        
        if hours > 0 {
            return "\(hours) giờ \(minutes) phút"
        } else {
            return "\(minutes) phút"
        }
    }
    
    var unlockedAchievements: [Achievement] {
        return (achievements?.allObjects as? [Achievement])?.filter { $0.achievedAt != nil } ?? []
    }
    
    var totalAchievementPoints: Int {
        return unlockedAchievements.reduce(0) { $0 + Int($1.points) }
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }
    
    static func fetchByName(_ name: String) -> NSFetchRequest<UserProfile> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.name, ascending: true)]
        return request
    }
    
    static func fetchByGrade(_ grade: Int) -> NSFetchRequest<UserProfile> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "grade == %d", grade)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.totalScore, ascending: false)]
        return request
    }
    
    static func fetchTopScorers(limit: Int = 10) -> NSFetchRequest<UserProfile> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.totalScore, ascending: false)]
        request.fetchLimit = limit
        return request
    }
    
    // MARK: - Helper Methods
    func updateStats(from session: UserSession) {
        // Update total score
        totalScore += session.score
        
        // Update completed exercises count
        completedExercises += 1
        
        // Update total time spent
        totalTimeSpent += session.timeSpent
        
        // Update average accuracy
        let sessions = self.sessions?.allObjects as? [UserSession] ?? []
        let totalAccuracy = sessions.reduce(0) { $0 + $1.accuracy }
        averageAccuracy = totalAccuracy / Float(sessions.count)
        
        // Update last session date
        lastSessionDate = session.completedAt
        
        // Update streak
        updateStreak(sessionDate: session.completedAt)
    }
    
    private func updateStreak(sessionDate: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionDay = calendar.startOfDay(for: sessionDate)
        
        if let lastSession = lastSessionDate {
            let lastSessionDay = calendar.startOfDay(for: lastSession)
            let daysBetween = calendar.dateComponents([.day], from: lastSessionDay, to: sessionDay).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                currentStreak = 1
            }
            // If daysBetween == 0, it's the same day, don't change streak
        } else {
            // First session
            currentStreak = 1
        }
        
        // Update best streak
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
    }
}

// MARK: - UserSession Extensions
extension UserSession {
    
    // MARK: - Convenience Initializers
    convenience init(context: NSManagedObjectContext,
                    user: UserProfile,
                    exercise: Exercise,
                    inputText: String,
                    spokenText: String?,
                    accuracy: Float,
                    score: Int,
                    timeSpent: TimeInterval,
                    inputMethod: InputMethod) {
        self.init(context: context)
        self.id = UUID()
        self.user = user
        self.exercise = exercise
        self.inputText = inputText
        self.spokenText = spokenText
        self.accuracy = accuracy
        self.score = Int32(score)
        self.timeSpent = timeSpent
        self.inputMethod = inputMethod.rawValue
        self.completedAt = Date()
    }
    
    // MARK: - Computed Properties
    var inputMethodType: InputMethod {
        get { InputMethod(rawValue: inputMethod ?? "keyboard") ?? .keyboard }
        set { inputMethod = newValue.rawValue }
    }
    
    var scoreCategory: ScoreCategory {
        switch accuracy {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        default: return .needsImprovement
        }
    }
    
    var mistakeList: [TextMistake] {
        return (mistakes?.allObjects as? [TextMistake])?.sorted { $0.position < $1.position } ?? []
    }
    
    var formattedTimeSpent: String {
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var isPerfect: Bool {
        return accuracy >= 1.0
    }
    
    var isExcellent: Bool {
        return accuracy >= 0.9
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSession> {
        return NSFetchRequest<UserSession>(entityName: "UserSession")
    }
    
    static func fetchByUser(_ userId: String) -> NSFetchRequest<UserSession> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "user.id == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.completedAt, ascending: false)]
        return request
    }
    
    static func fetchByDateRange(userId: String, from: Date, to: Date) -> NSFetchRequest<UserSession> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "user.id == %@ AND completedAt >= %@ AND completedAt <= %@", 
                                       userId, from as NSDate, to as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.completedAt, ascending: false)]
        return request
    }
    
    static func fetchLatest(userId: String) -> NSFetchRequest<UserSession> {
        let request = fetchByUser(userId)
        request.fetchLimit = 1
        return request
    }
    
    static func fetchByExercise(_ exerciseId: UUID) -> NSFetchRequest<UserSession> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "exercise.id == %@", exerciseId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.completedAt, ascending: false)]
        return request
    }
}

// MARK: - TextMistake Extensions
extension TextMistake {
    
    // MARK: - Convenience Initializers
    convenience init(context: NSManagedObjectContext,
                    session: UserSession,
                    position: Int,
                    expectedWord: String,
                    actualWord: String?,
                    mistakeType: MistakeType,
                    severity: MistakeSeverity) {
        self.init(context: context)
        self.id = UUID()
        self.session = session
        self.position = Int32(position)
        self.expectedWord = expectedWord
        self.actualWord = actualWord
        self.mistakeType = mistakeType.rawValue
        self.severity = severity.rawValue
    }
    
    // MARK: - Computed Properties
    var mistakeTypeEnum: MistakeType {
        get { MistakeType(rawValue: mistakeType ?? "substitution") ?? .substitution }
        set { mistakeType = newValue.rawValue }
    }
    
    var severityEnum: MistakeSeverity {
        get { MistakeSeverity(rawValue: severity ?? "moderate") ?? .moderate }
        set { severity = newValue.rawValue }
    }
    
    var description: String {
        switch mistakeTypeEnum {
        case .mispronunciation:
            return "Phát âm sai: '\(expectedWord)' thành '\(actualWord ?? "")'"
        case .omission:
            return "Bỏ sót từ: '\(expectedWord)'"
        case .insertion:
            return "Thêm từ: '\(actualWord ?? "")'"
        case .substitution:
            return "Thay thế từ: '\(expectedWord)' thành '\(actualWord ?? "")'"
        }
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextMistake> {
        return NSFetchRequest<TextMistake>(entityName: "TextMistake")
    }
    
    static func fetchBySession(_ sessionId: UUID) -> NSFetchRequest<TextMistake> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "session.id == %@", sessionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TextMistake.position, ascending: true)]
        return request
    }
    
    static func fetchByType(_ type: MistakeType) -> NSFetchRequest<TextMistake> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "mistakeType == %@", type.rawValue)
        return request
    }
}

// MARK: - Achievement Extensions
extension Achievement {
    
    // MARK: - Convenience Initializers
    convenience init(context: NSManagedObjectContext,
                    id: String,
                    title: String,
                    description: String,
                    category: AchievementCategory,
                    difficulty: AchievementDifficulty,
                    requirementType: RequirementType,
                    requirementTarget: Int,
                    user: UserProfile? = nil) {
        self.init(context: context)
        self.id = id
        self.title = title
        self.descriptionText = description
        self.category = category.rawValue
        self.difficulty = difficulty.rawValue
        self.requirementType = requirementType.rawValue
        self.requirementTarget = Int32(requirementTarget)
        self.points = Int32(difficulty.points)
        self.progress = 0.0
        self.icon = category.icon
        self.user = user
    }
    
    // MARK: - Computed Properties
    var categoryEnum: AchievementCategory {
        get { AchievementCategory(rawValue: category ?? "reading") ?? .reading }
        set { category = newValue.rawValue }
    }
    
    var difficultyEnum: AchievementDifficulty {
        get { AchievementDifficulty(rawValue: difficulty ?? "bronze") ?? .bronze }
        set { difficulty = newValue.rawValue }
    }
    
    var requirementTypeEnum: RequirementType {
        get { RequirementType(rawValue: requirementType ?? "readSessions") ?? .readSessions }
        set { requirementType = newValue.rawValue }
    }
    
    var isUnlocked: Bool {
        return achievedAt != nil
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var requirementDescription: String {
        switch requirementTypeEnum {
        case .readSessions:
            return "Hoàn thành \(requirementTarget) bài đọc"
        case .perfectScores:
            return "Đạt điểm hoàn hảo \(requirementTarget) lần"
        case .consecutiveDays:
            return "Học liên tục \(requirementTarget) ngày"
        case .totalScore:
            return "Đạt tổng điểm \(requirementTarget)"
        case .averageAccuracy:
            return "Đạt độ chính xác trung bình \(requirementTarget)%"
        }
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Achievement> {
        return NSFetchRequest<Achievement>(entityName: "Achievement")
    }
    
    static func fetchByUser(_ userId: String) -> NSFetchRequest<Achievement> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "user.id == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Achievement.achievedAt, ascending: false)]
        return request
    }
    
    static func fetchUnlockedByUser(_ userId: String) -> NSFetchRequest<Achievement> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "user.id == %@ AND achievedAt != nil", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Achievement.achievedAt, ascending: false)]
        return request
    }
    
    static func fetchByCategory(_ category: AchievementCategory) -> NSFetchRequest<Achievement> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Achievement.difficulty, ascending: true)]
        return request
    }
    
    // MARK: - Helper Methods
    func unlock() {
        achievedAt = Date()
        progress = 1.0
    }
    
    func updateProgress(_ newProgress: Float) {
        progress = min(1.0, max(0.0, newProgress))
        
        if progress >= 1.0 && achievedAt == nil {
            unlock()
        }
    }
}