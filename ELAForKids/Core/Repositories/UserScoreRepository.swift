import Foundation
import CoreData

// MARK: - User Score Repository
final class UserScoreRepository: UserScoreRepositoryProtocol {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let userDefaults: UserDefaults
    
    init(coreDataStack: CoreDataStack, userDefaults: UserDefaults = .standard) {
        self.coreDataStack = coreDataStack
        self.userDefaults = userDefaults
    }
    
    // MARK: - UserScoreRepositoryProtocol Implementation
    
    func getUserScore(userId: String) async throws -> UserScore {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let userScore = try self.fetchOrCreateUserScore(userId: userId, context: context)
                    let score = self.mapToUserScore(userScore)
                    continuation.resume(returning: score)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateScore(userId: String, additionalScore: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let userScore = try self.fetchOrCreateUserScore(userId: userId, context: context)
                    
                    // Update total score
                    userScore.totalScore += Int32(additionalScore)
                    
                    // Update experience
                    let experienceGain = Int32(Float(additionalScore) * 1.5)
                    userScore.experience += experienceGain
                    
                    // Check for level up
                    let newLevel = self.calculateLevel(experience: Int(userScore.experience))
                    if newLevel > userScore.level {
                        userScore.level = Int32(newLevel)
                    }
                    
                    // Update last updated timestamp
                    userScore.lastUpdated = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getTopUsers(limit: Int) async throws -> [UserScore] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<UserScoreEntity> = UserScoreEntity.fetchRequest()
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \UserScoreEntity.totalScore, ascending: false),
                        NSSortDescriptor(keyPath: \UserScoreEntity.lastUpdated, ascending: false)
                    ]
                    request.fetchLimit = limit
                    
                    let entities = try context.fetch(request)
                    let userScores = entities.map { self.mapToUserScore($0) }
                    
                    continuation.resume(returning: userScores)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getUserRanking(userId: String) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    // Get user's score
                    let userScore = try self.fetchOrCreateUserScore(userId: userId, context: context)
                    let userTotalScore = userScore.totalScore
                    
                    // Count users with higher scores
                    let request: NSFetchRequest<UserScoreEntity> = UserScoreEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "totalScore > %d", userTotalScore)
                    
                    let higherScoreCount = try context.count(for: request)
                    let ranking = higherScoreCount + 1
                    
                    continuation.resume(returning: ranking)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func createUserScore(userId: String, userName: String) async throws -> UserScore {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let userScore = UserScoreEntity(context: context)
                    userScore.id = UUID().uuidString
                    userScore.userId = userId
                    userScore.userName = userName
                    userScore.totalScore = 0
                    userScore.level = 1
                    userScore.experience = 0
                    userScore.streak = 0
                    userScore.lastUpdated = Date()
                    userScore.achievements = []
                    
                    try context.save()
                    
                    let score = self.mapToUserScore(userScore)
                    continuation.resume(returning: score)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Additional Repository Methods
    
    /// Update user's streak
    func updateStreak(userId: String, newStreak: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let userScore = try self.fetchOrCreateUserScore(userId: userId, context: context)
                    userScore.streak = Int32(newStreak)
                    userScore.lastUpdated = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Add achievement to user
    func addAchievement(userId: String, achievementId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let userScore = try self.fetchOrCreateUserScore(userId: userId, context: context)
                    
                    var achievements = userScore.achievements ?? []
                    if !achievements.contains(achievementId) {
                        achievements.append(achievementId)
                        userScore.achievements = achievements
                        userScore.lastUpdated = Date()
                        
                        try context.save()
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get user statistics
    func getUserStatistics(userId: String) async throws -> UserStatistics {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let userScore = try self.fetchOrCreateUserScore(userId: userId, context: context)
                    
                    // Get session statistics
                    let sessionStats = try self.getSessionStatistics(userId: userId, context: context)
                    
                    let statistics = UserStatistics(
                        totalScore: Int(userScore.totalScore),
                        level: Int(userScore.level),
                        experience: Int(userScore.experience),
                        currentStreak: Int(userScore.streak),
                        totalSessions: sessionStats.totalSessions,
                        averageAccuracy: sessionStats.averageAccuracy,
                        totalTimeSpent: sessionStats.totalTimeSpent,
                        favoriteInputMethod: sessionStats.favoriteInputMethod,
                        strongestDifficulty: sessionStats.strongestDifficulty,
                        improvementAreas: sessionStats.improvementAreas
                    )
                    
                    continuation.resume(returning: statistics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get users by level range
    func getUsersByLevel(minLevel: Int, maxLevel: Int) async throws -> [UserScore] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<UserScoreEntity> = UserScoreEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "level >= %d AND level <= %d", minLevel, maxLevel)
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \UserScoreEntity.totalScore, ascending: false)
                    ]
                    
                    let entities = try context.fetch(request)
                    let userScores = entities.map { self.mapToUserScore($0) }
                    
                    continuation.resume(returning: userScores)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchOrCreateUserScore(userId: String, context: NSManagedObjectContext) throws -> UserScoreEntity {
        let request: NSFetchRequest<UserScoreEntity> = UserScoreEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1
        
        if let existingScore = try context.fetch(request).first {
            return existingScore
        } else {
            // Create new user score
            let userScore = UserScoreEntity(context: context)
            userScore.id = UUID().uuidString
            userScore.userId = userId
            userScore.userName = "User \(userId.prefix(8))" // Default name
            userScore.totalScore = 0
            userScore.level = 1
            userScore.experience = 0
            userScore.streak = 0
            userScore.lastUpdated = Date()
            userScore.achievements = []
            
            return userScore
        }
    }
    
    private func mapToUserScore(_ entity: UserScoreEntity) -> UserScore {
        return UserScore(
            id: entity.id ?? UUID().uuidString,
            userId: entity.userId ?? "",
            userName: entity.userName ?? "",
            totalScore: Int(entity.totalScore),
            level: Int(entity.level),
            experience: Int(entity.experience),
            streak: Int(entity.streak),
            lastUpdated: entity.lastUpdated ?? Date(),
            achievements: entity.achievements ?? []
        )
    }
    
    private func calculateLevel(experience: Int) -> Int {
        // Level calculation: level 1 = 0-99, level 2 = 100-299, level 3 = 300-599, etc.
        var level = 1
        var requiredExp = 100
        var totalExp = 0
        
        while experience >= totalExp + requiredExp {
            totalExp += requiredExp
            level += 1
            requiredExp = 100 * level + 50 * (level - 1) * level
        }
        
        return level
    }
    
    private func getSessionStatistics(userId: String, context: NSManagedObjectContext) throws -> SessionStatistics {
        let request: NSFetchRequest<SessionResultEntity> = SessionResultEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        let sessions = try context.fetch(request)
        
        guard !sessions.isEmpty else {
            return SessionStatistics(
                totalSessions: 0,
                averageAccuracy: 0.0,
                totalTimeSpent: 0.0,
                favoriteInputMethod: .voice,
                strongestDifficulty: .grade1,
                improvementAreas: []
            )
        }
        
        let totalSessions = sessions.count
        let averageAccuracy = sessions.map { $0.accuracy }.reduce(0, +) / Float(sessions.count)
        let totalTimeSpent = sessions.map { $0.timeSpent }.reduce(0, +)
        
        // Find favorite input method
        let inputMethodCounts = Dictionary(grouping: sessions) { $0.inputMethod }
            .mapValues { $0.count }
        let favoriteInputMethod = inputMethodCounts.max { $0.value < $1.value }?.key ?? "voice"
        
        // Find strongest difficulty
        let difficultyAccuracy = Dictionary(grouping: sessions) { $0.difficulty }
            .mapValues { sessions in
                sessions.map { $0.accuracy }.reduce(0, +) / Float(sessions.count)
            }
        let strongestDifficulty = difficultyAccuracy.max { $0.value < $1.value }?.key ?? "grade1"
        
        // Identify improvement areas (difficulties with low accuracy)
        let improvementAreas = difficultyAccuracy.compactMap { (difficulty, accuracy) in
            accuracy < 0.7 ? difficulty : nil
        }
        
        return SessionStatistics(
            totalSessions: totalSessions,
            averageAccuracy: averageAccuracy,
            totalTimeSpent: totalTimeSpent,
            favoriteInputMethod: InputMethod(rawValue: favoriteInputMethod) ?? .voice,
            strongestDifficulty: DifficultyLevel(rawValue: strongestDifficulty) ?? .grade1,
            improvementAreas: improvementAreas.compactMap { DifficultyLevel(rawValue: $0) }
        )
    }
}

// MARK: - Supporting Data Models

/// User statistics for profile and analytics
struct UserStatistics {
    let totalScore: Int
    let level: Int
    let experience: Int
    let currentStreak: Int
    let totalSessions: Int
    let averageAccuracy: Float
    let totalTimeSpent: TimeInterval
    let favoriteInputMethod: InputMethod
    let strongestDifficulty: DifficultyLevel
    let improvementAreas: [DifficultyLevel]
    
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
    
    /// Performance level description
    var performanceLevel: String {
        switch averageAccuracy {
        case 0.95...1.0:
            return "Xuất sắc"
        case 0.85..<0.95:
            return "Tốt"
        case 0.70..<0.85:
            return "Khá"
        default:
            return "Cần cải thiện"
        }
    }
    
    /// Sessions per day average (assuming 30 days)
    var sessionsPerDay: Float {
        return Float(totalSessions) / 30.0
    }
}

/// Internal session statistics
private struct SessionStatistics {
    let totalSessions: Int
    let averageAccuracy: Float
    let totalTimeSpent: TimeInterval
    let favoriteInputMethod: InputMethod
    let strongestDifficulty: DifficultyLevel
    let improvementAreas: [DifficultyLevel]
}

// MARK: - Core Data Entities (Mock definitions for compilation)

/// Core Data entity for user scores
@objc(UserScoreEntity)
class UserScoreEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var userId: String?
    @NSManaged var userName: String?
    @NSManaged var totalScore: Int32
    @NSManaged var level: Int32
    @NSManaged var experience: Int32
    @NSManaged var streak: Int32
    @NSManaged var lastUpdated: Date?
    @NSManaged var achievements: [String]?
}

/// Core Data entity for session results
@objc(SessionResultEntity)
class SessionResultEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var userId: String?
    @NSManaged var exerciseId: String?
    @NSManaged var originalText: String?
    @NSManaged var spokenText: String?
    @NSManaged var accuracy: Float
    @NSManaged var score: Int32
    @NSManaged var timeSpent: TimeInterval
    @NSManaged var completedAt: Date?
    @NSManaged var difficulty: String?
    @NSManaged var inputMethod: String?
    @NSManaged var attempts: Int32
}

// MARK: - Core Data Stack Protocol
protocol CoreDataStack {
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
    var viewContext: NSManagedObjectContext { get }
}