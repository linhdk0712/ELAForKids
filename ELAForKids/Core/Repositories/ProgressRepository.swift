import Foundation
import CoreData

// MARK: - Progress Repository Protocol
protocol ProgressRepositoryProtocol {
    func getDailyProgress(userId: String, date: Date) async throws -> DailyProgress?
    func saveDailyProgress(userId: String, progress: DailyProgress) async throws
    func getDailyProgressRange(userId: String, startDate: Date, endDate: Date) async throws -> [DailyProgress]
    func getLearningGoals(userId: String) async throws -> LearningGoals?
    func saveLearningGoals(userId: String, goals: LearningGoals) async throws
    func getSessionsByCategory(userId: String, period: ProgressPeriod) async throws -> [CategorySession]
    func getSessionsByDifficulty(userId: String, period: ProgressPeriod) async throws -> [SessionResult]
    func getRecentSessions(userId: String, limit: Int) async throws -> [SessionResult]
    func getUserProgress(userId: String, period: ProgressPeriod) async throws -> UserProgress
    func saveSessionResult(_ sessionResult: SessionResult) async throws
}

// MARK: - Progress Repository
final class ProgressRepository: ProgressRepositoryProtocol {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let userDefaults: UserDefaults
    
    init(coreDataStack: CoreDataStack, userDefaults: UserDefaults = .standard) {
        self.coreDataStack = coreDataStack
        self.userDefaults = userDefaults
    }
    
    // MARK: - ProgressRepositoryProtocol Implementation
    
    func getDailyProgress(userId: String, date: Date) async throws -> DailyProgress? {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<DailyProgressEntity> = DailyProgressEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND date == %@",
                        userId, date as NSDate
                    )
                    request.fetchLimit = 1
                    
                    if let entity = try context.fetch(request).first {
                        let progress = self.mapToDailyProgress(entity)
                        continuation.resume(returning: progress)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveDailyProgress(userId: String, progress: DailyProgress) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    // Check if progress already exists for this date
                    let request: NSFetchRequest<DailyProgressEntity> = DailyProgressEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND date == %@",
                        userId, progress.date as NSDate
                    )
                    request.fetchLimit = 1
                    
                    let entity = try context.fetch(request).first ?? DailyProgressEntity(context: context)
                    
                    // Map progress to entity
                    self.mapDailyProgressToEntity(progress, entity: entity, userId: userId)
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getDailyProgressRange(userId: String, startDate: Date, endDate: Date) async throws -> [DailyProgress] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<DailyProgressEntity> = DailyProgressEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND date >= %@ AND date <= %@",
                        userId, startDate as NSDate, endDate as NSDate
                    )
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \DailyProgressEntity.date, ascending: true)
                    ]
                    
                    let entities = try context.fetch(request)
                    let progressList = entities.compactMap { self.mapToDailyProgress($0) }
                    
                    continuation.resume(returning: progressList)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getLearningGoals(userId: String) async throws -> LearningGoals? {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<LearningGoalsEntity> = LearningGoalsEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    request.fetchLimit = 1
                    
                    if let entity = try context.fetch(request).first {
                        let goals = self.mapToLearningGoals(entity)
                        continuation.resume(returning: goals)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveLearningGoals(userId: String, goals: LearningGoals) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    // Check if goals already exist
                    let request: NSFetchRequest<LearningGoalsEntity> = LearningGoalsEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    request.fetchLimit = 1
                    
                    let entity = try context.fetch(request).first ?? LearningGoalsEntity(context: context)
                    
                    // Map goals to entity
                    self.mapLearningGoalsToEntity(goals, entity: entity)
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getSessionsByCategory(userId: String, period: ProgressPeriod) async throws -> [CategorySession] {
        let dateRange = period.dateRange
        
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<SessionResultEntity> = SessionResultEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND completedAt >= %@ AND completedAt <= %@",
                        userId, dateRange.start as NSDate, dateRange.end as NSDate
                    )
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \SessionResultEntity.completedAt, ascending: true)
                    ]
                    
                    let entities = try context.fetch(request)
                    let categorySessions = entities.compactMap { entity -> CategorySession? in
                        guard let categoryString = entity.category,
                              let category = AchievementCategory(rawValue: categoryString),
                              let completedAt = entity.completedAt else {
                            return nil
                        }
                        
                        return CategorySession(
                            category: category,
                            accuracy: entity.accuracy,
                            timeSpent: entity.timeSpent,
                            completedAt: completedAt
                        )
                    }
                    
                    continuation.resume(returning: categorySessions)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getSessionsByDifficulty(userId: String, period: ProgressPeriod) async throws -> [SessionResult] {
        let dateRange = period.dateRange
        
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<SessionResultEntity> = SessionResultEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND completedAt >= %@ AND completedAt <= %@",
                        userId, dateRange.start as NSDate, dateRange.end as NSDate
                    )
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \SessionResultEntity.completedAt, ascending: true)
                    ]
                    
                    let entities = try context.fetch(request)
                    let sessionResults = entities.compactMap { self.mapToSessionResult($0) }
                    
                    continuation.resume(returning: sessionResults)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getRecentSessions(userId: String, limit: Int) async throws -> [SessionResult] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<SessionResultEntity> = SessionResultEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \SessionResultEntity.completedAt, ascending: false)
                    ]
                    request.fetchLimit = limit
                    
                    let entities = try context.fetch(request)
                    let sessionResults = entities.compactMap { self.mapToSessionResult($0) }
                    
                    continuation.resume(returning: sessionResults)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Additional Repository Methods
    
    /// Get weekly progress summary
    func getWeeklyProgress(userId: String, weekStartDate: Date) async throws -> [DailyProgress] {
        let weekEndDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
        return try await getDailyProgressRange(userId: userId, startDate: weekStartDate, endDate: weekEndDate)
    }
    
    /// Get monthly progress summary
    func getMonthlyProgress(userId: String, month: Int, year: Int) async throws -> [DailyProgress] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        
        return try await getDailyProgressRange(userId: userId, startDate: startDate, endDate: endDate)
    }
    
    /// Save session result for progress tracking
    func saveSessionResult(_ sessionResult: SessionResult) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let entity = SessionResultEntity(context: context)
                    self.mapSessionResultToEntity(sessionResult, entity: entity)
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getUserProgress(userId: String, period: ProgressPeriod) async throws -> UserProgress {
        let dateRange = period.dateRange
        
        // Get daily progress data for the period
        let dailyProgressData = try await getDailyProgressRange(
            userId: userId,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        // Calculate aggregated metrics
        let totalSessions = dailyProgressData.reduce(0) { $0 + $1.sessionsCompleted }
        let totalTimeSpent = dailyProgressData.reduce(0) { $0 + $1.timeSpent }
        let totalScore = dailyProgressData.reduce(0) { $0 + $1.scoreEarned }
        
        let averageAccuracy = dailyProgressData.isEmpty ? 0 :
            dailyProgressData.reduce(0) { $0 + $1.averageAccuracy } / Float(dailyProgressData.count)
        
        let goalsAchieved = dailyProgressData.filter { $0.isGoalAchieved }.count
        let totalGoals = dailyProgressData.count
        
        // Get category and difficulty progress (simplified implementation)
        let categoryProgress: [CategoryProgress] = []
        let difficultyProgress: [DifficultyProgress] = []
        
        // Calculate improvement trend (simplified)
        let improvementTrend = ImprovementTrend(
            direction: .stable,
            magnitude: 0.0,
            consistency: 0.0,
            recentChange: 0.0,
            projectedImprovement: 0.0
        )
        
        return UserProgress(
            userId: userId,
            period: period,
            startDate: dateRange.start,
            endDate: dateRange.end,
            totalSessions: totalSessions,
            totalTimeSpent: totalTimeSpent,
            averageAccuracy: averageAccuracy,
            totalScore: totalScore,
            streakCount: 0, // Would be fetched from streak manager
            goalsAchieved: goalsAchieved,
            totalGoals: totalGoals,
            dailyProgress: dailyProgressData,
            categoryProgress: categoryProgress,
            difficultyProgress: difficultyProgress,
            improvementTrend: improvementTrend
        )
    }

    /// Get user's learning statistics
    func getUserLearningStatistics(userId: String) async throws -> LearningStatistics {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    // Get all sessions for user
                    let sessionRequest: NSFetchRequest<SessionResultEntity> = SessionResultEntity.fetchRequest()
                    sessionRequest.predicate = NSPredicate(format: "userId == %@", userId)
                    let sessions = try context.fetch(sessionRequest)
                    
                    // Get all daily progress for user
                    let progressRequest: NSFetchRequest<DailyProgressEntity> = DailyProgressEntity.fetchRequest()
                    progressRequest.predicate = NSPredicate(format: "userId == %@", userId)
                    let dailyProgress = try context.fetch(progressRequest)
                    
                    let statistics = self.calculateLearningStatistics(
                        sessions: sessions,
                        dailyProgress: dailyProgress
                    )
                    
                    continuation.resume(returning: statistics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Mapping Methods
    
    private func mapToDailyProgress(_ entity: DailyProgressEntity) -> DailyProgress? {
        guard let date = entity.date else { return nil }
        
        let goalsMet = entity.goalsMet?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        
        return DailyProgress(
            date: date,
            sessionsCompleted: Int(entity.sessionsCompleted),
            timeSpent: entity.timeSpent,
            averageAccuracy: entity.averageAccuracy,
            scoreEarned: Int(entity.scoreEarned),
            goalsMet: goalsMet,
            isGoalAchieved: entity.isGoalAchieved
        )
    }
    
    private func mapDailyProgressToEntity(_ progress: DailyProgress, entity: DailyProgressEntity, userId: String) {
        entity.userId = userId
        entity.date = progress.date
        entity.sessionsCompleted = Int32(progress.sessionsCompleted)
        entity.timeSpent = progress.timeSpent
        entity.averageAccuracy = progress.averageAccuracy
        entity.scoreEarned = Int32(progress.scoreEarned)
        entity.goalsMet = progress.goalsMet.joined(separator: ",")
        entity.isGoalAchieved = progress.isGoalAchieved
    }
    
    private func mapToLearningGoals(_ entity: LearningGoalsEntity) -> LearningGoals? {
        guard let userId = entity.userId,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }
        
        // Decode custom goals from JSON
        let customGoals = decodeCustomGoals(from: entity.customGoalsData) ?? []
        
        return LearningGoals(
            userId: userId,
            dailySessionGoal: Int(entity.dailySessionGoal),
            dailyTimeGoal: entity.dailyTimeGoal,
            weeklySessionGoal: Int(entity.weeklySessionGoal),
            accuracyGoal: entity.accuracyGoal,
            streakGoal: Int(entity.streakGoal),
            customGoals: customGoals,
            isActive: entity.isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func mapLearningGoalsToEntity(_ goals: LearningGoals, entity: LearningGoalsEntity) {
        entity.userId = goals.userId
        entity.dailySessionGoal = Int32(goals.dailySessionGoal)
        entity.dailyTimeGoal = goals.dailyTimeGoal
        entity.weeklySessionGoal = Int32(goals.weeklySessionGoal)
        entity.accuracyGoal = goals.accuracyGoal
        entity.streakGoal = Int32(goals.streakGoal)
        entity.customGoalsData = encodeCustomGoals(goals.customGoals)
        entity.isActive = goals.isActive
        entity.createdAt = goals.createdAt
        entity.updatedAt = goals.updatedAt
    }
    
    private func mapToSessionResult(_ entity: SessionResultEntity) -> SessionResult? {
        guard let userId = entity.userId,
              let exerciseIdString = entity.exerciseId,
              let exerciseId = UUID(uuidString: exerciseIdString),
              let originalText = entity.originalText,
              let spokenText = entity.spokenText,
              let completedAt = entity.completedAt,
              let difficultyString = entity.difficulty,
              let difficulty = DifficultyLevel(rawValue: difficultyString),
              let inputMethodString = entity.inputMethod,
              let inputMethod = InputMethod(rawValue: inputMethodString) else {
            return nil
        }
        
        // Decode mistakes from JSON
        let mistakes = decodeMistakes(from: entity.mistakesData) ?? []
        
        return SessionResult(
            userId: userId,
            exerciseId: exerciseId,
            originalText: originalText,
            spokenText: spokenText,
            accuracy: entity.accuracy,
            score: Int(entity.score),
            timeSpent: entity.timeSpent,
            mistakes: mistakes,
            completedAt: completedAt,
            difficulty: difficulty,
            inputMethod: inputMethod,
            attempts: Int(entity.attempts)
        )
    }
    
    private func mapSessionResultToEntity(_ sessionResult: SessionResult, entity: SessionResultEntity) {
        entity.id = sessionResult.id.uuidString
        entity.userId = sessionResult.userId
        entity.exerciseId = sessionResult.exerciseId.uuidString
        entity.originalText = sessionResult.originalText
        entity.spokenText = sessionResult.spokenText
        entity.accuracy = sessionResult.accuracy
        entity.score = Int32(sessionResult.score)
        entity.timeSpent = sessionResult.timeSpent
        entity.mistakesData = encodeMistakes(sessionResult.mistakes)
        entity.completedAt = sessionResult.completedAt
        entity.difficulty = sessionResult.difficulty.rawValue
        entity.inputMethod = sessionResult.inputMethod.rawValue
        entity.attempts = Int32(sessionResult.attempts)
    }
    
    private func calculateLearningStatistics(
        sessions: [SessionResultEntity],
        dailyProgress: [DailyProgressEntity]
    ) -> LearningStatistics {
        let totalSessions = sessions.count
        let totalTimeSpent = sessions.reduce(0) { $0 + $1.timeSpent }
        let averageAccuracy = sessions.isEmpty ? 0 :
            sessions.reduce(0) { $0 + $1.accuracy } / Float(sessions.count)
        
        let goalsAchieved = dailyProgress.filter { $0.isGoalAchieved }.count
        let totalDays = dailyProgress.count
        
        return LearningStatistics(
            totalSessions: totalSessions,
            totalTimeSpent: totalTimeSpent,
            averageAccuracy: averageAccuracy,
            goalsAchievedCount: goalsAchieved,
            totalDaysTracked: totalDays,
            consistencyRate: totalDays > 0 ? Float(goalsAchieved) / Float(totalDays) : 0
        )
    }
    
    // MARK: - JSON Encoding/Decoding Helpers
    
    private func encodeCustomGoals(_ goals: [CustomGoal]) -> Data? {
        return try? JSONEncoder().encode(goals)
    }
    
    private func decodeCustomGoals(from data: Data?) -> [CustomGoal]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([CustomGoal].self, from: data)
    }
    
    private func encodeMistakes(_ mistakes: [TextMistake]) -> Data? {
        return try? JSONEncoder().encode(mistakes)
    }
    
    private func decodeMistakes(from data: Data?) -> [TextMistake]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([TextMistake].self, from: data)
    }
}

// MARK: - Core Data Entities

/// Core Data entity for daily progress
@objc(DailyProgressEntity)
class DailyProgressEntity: NSManagedObject {
    @NSManaged var userId: String?
    @NSManaged var date: Date?
    @NSManaged var sessionsCompleted: Int32
    @NSManaged var timeSpent: TimeInterval
    @NSManaged var averageAccuracy: Float
    @NSManaged var scoreEarned: Int32
    @NSManaged var goalsMet: String?
    @NSManaged var isGoalAchieved: Bool
}

/// Core Data entity for learning goals
@objc(LearningGoalsEntity)
class LearningGoalsEntity: NSManagedObject {
    @NSManaged var userId: String?
    @NSManaged var dailySessionGoal: Int32
    @NSManaged var dailyTimeGoal: TimeInterval
    @NSManaged var weeklySessionGoal: Int32
    @NSManaged var accuracyGoal: Float
    @NSManaged var streakGoal: Int32
    @NSManaged var customGoalsData: Data?
    @NSManaged var isActive: Bool
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
}

// MARK: - Fetch Request Extensions
extension DailyProgressEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyProgressEntity> {
        return NSFetchRequest<DailyProgressEntity>(entityName: "DailyProgressEntity")
    }
}

extension LearningGoalsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningGoalsEntity> {
        return NSFetchRequest<LearningGoalsEntity>(entityName: "LearningGoalsEntity")
    }
}

// MARK: - Supporting Data Models

/// Learning statistics summary
struct LearningStatistics: Codable {
    let totalSessions: Int
    let totalTimeSpent: TimeInterval
    let averageAccuracy: Float
    let goalsAchievedCount: Int
    let totalDaysTracked: Int
    let consistencyRate: Float
    
    /// Formatted total time spent
    var formattedTimeSpent: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Average session length
    var averageSessionLength: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalTimeSpent / TimeInterval(totalSessions)
    }
}