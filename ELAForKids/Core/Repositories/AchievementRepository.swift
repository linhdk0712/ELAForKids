import Foundation
import CoreData

// MARK: - Achievement Repository
final class AchievementRepository: AchievementRepositoryProtocol {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let userDefaults: UserDefaults
    
    init(coreDataStack: CoreDataStack, userDefaults: UserDefaults = .standard) {
        self.coreDataStack = coreDataStack
        self.userDefaults = userDefaults
    }
    
    // MARK: - AchievementRepositoryProtocol Implementation
    
    func getAllAchievements() async throws -> [Achievement] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \AchievementEntity.sortOrder, ascending: true),
                        NSSortDescriptor(keyPath: \AchievementEntity.title, ascending: true)
                    ]
                    
                    let entities = try context.fetch(request)
                    let achievements = entities.compactMap { self.mapToAchievement($0) }
                    
                    continuation.resume(returning: achievements)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveAchievement(_ achievement: Achievement) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    // Check if achievement already exists
                    let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", achievement.id)
                    request.fetchLimit = 1
                    
                    let existingEntity = try context.fetch(request).first
                    let entity = existingEntity ?? AchievementEntity(context: context)
                    
                    // Map achievement to entity
                    self.mapAchievementToEntity(achievement, entity: entity)
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getUserAchievements(userId: String) async throws -> [UserAchievement] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<UserAchievementEntity> = UserAchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \UserAchievementEntity.unlockedAt, ascending: false)
                    ]
                    
                    let entities = try context.fetch(request)
                    let userAchievements = entities.compactMap { self.mapToUserAchievement($0) }
                    
                    continuation.resume(returning: userAchievements)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveUserAchievement(_ userAchievement: UserAchievement) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    // Check if user achievement already exists
                    let request: NSFetchRequest<UserAchievementEntity> = UserAchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND achievementId == %@",
                        userAchievement.userId,
                        userAchievement.achievementId
                    )
                    request.fetchLimit = 1
                    
                    let existingEntity = try context.fetch(request).first
                    let entity = existingEntity ?? UserAchievementEntity(context: context)
                    
                    // Map user achievement to entity
                    self.mapUserAchievementToEntity(userAchievement, entity: entity)
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteUserAchievements(userId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<UserAchievementEntity> = UserAchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    
                    let entities = try context.fetch(request)
                    for entity in entities {
                        context.delete(entity)
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Additional Repository Methods
    
    /// Get achievements by category
    func getAchievementsByCategory(_ category: AchievementCategory) async throws -> [Achievement] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "category == %@", category.rawValue)
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \AchievementEntity.sortOrder, ascending: true)
                    ]
                    
                    let entities = try context.fetch(request)
                    let achievements = entities.compactMap { self.mapToAchievement($0) }
                    
                    continuation.resume(returning: achievements)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get achievements by difficulty
    func getAchievementsByDifficulty(_ difficulty: AchievementDifficulty) async throws -> [Achievement] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "difficulty == %@", difficulty.rawValue)
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \AchievementEntity.sortOrder, ascending: true)
                    ]
                    
                    let entities = try context.fetch(request)
                    let achievements = entities.compactMap { self.mapToAchievement($0) }
                    
                    continuation.resume(returning: achievements)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get user achievements by date range
    func getUserAchievements(
        userId: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [UserAchievement] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<UserAchievementEntity> = UserAchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND unlockedAt >= %@ AND unlockedAt <= %@",
                        userId, startDate as NSDate, endDate as NSDate
                    )
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \UserAchievementEntity.unlockedAt, ascending: false)
                    ]
                    
                    let entities = try context.fetch(request)
                    let userAchievements = entities.compactMap { self.mapToUserAchievement($0) }
                    
                    continuation.resume(returning: userAchievements)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get achievement by ID
    func getAchievement(by id: String) async throws -> Achievement? {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id)
                    request.fetchLimit = 1
                    
                    if let entity = try context.fetch(request).first {
                        let achievement = self.mapToAchievement(entity)
                        continuation.resume(returning: achievement)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update user achievement progress
    func updateUserAchievementProgress(
        userId: String,
        achievementId: String,
        progress: AchievementProgress
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<UserAchievementEntity> = UserAchievementEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "userId == %@ AND achievementId == %@",
                        userId, achievementId
                    )
                    request.fetchLimit = 1
                    
                    if let entity = try context.fetch(request).first {
                        entity.progressCurrent = Int32(progress.current)
                        entity.progressTarget = Int32(progress.target)
                        entity.progressPercentage = progress.percentage
                        
                        try context.save()
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get user achievement statistics
    func getUserAchievementStatistics(userId: String) async throws -> AchievementStatistics {
        let userAchievements = try await getUserAchievements(userId: userId)
        let allAchievements = try await getAllAchievements()
        
        let totalAchievements = allAchievements.count
        let unlockedAchievements = userAchievements.count
        let completionPercentage = Float(unlockedAchievements) / Float(totalAchievements)
        
        // Calculate points from achievements
        let achievementPoints = userAchievements.compactMap { userAchievement in
            allAchievements.first { $0.id == userAchievement.achievementId }?.rewards.points
        }.reduce(0, +)
        
        // Group by category
        let categoryStats = Dictionary(grouping: userAchievements) { userAchievement in
            allAchievements.first { $0.id == userAchievement.achievementId }?.category ?? .special
        }.mapValues { $0.count }
        
        // Group by difficulty
        let difficultyStats = Dictionary(grouping: userAchievements) { userAchievement in
            allAchievements.first { $0.id == userAchievement.achievementId }?.difficulty ?? .bronze
        }.mapValues { $0.count }
        
        // Get recent unlocks (last 5)
        let recentUnlocks = Array(userAchievements.prefix(5))
        
        return AchievementStatistics(
            totalAchievements: totalAchievements,
            unlockedAchievements: unlockedAchievements,
            completionPercentage: completionPercentage,
            achievementPoints: achievementPoints,
            categoryStats: categoryStats,
            difficultyStats: difficultyStats,
            recentUnlocks: recentUnlocks
        )
    }
    
    // MARK: - Private Mapping Methods
    
    private func mapToAchievement(_ entity: AchievementEntity) -> Achievement? {
        guard let id = entity.id,
              let title = entity.title,
              let description = entity.achievementDescription,
              let categoryRaw = entity.category,
              let category = AchievementCategory(rawValue: categoryRaw),
              let difficultyRaw = entity.difficulty,
              let difficulty = AchievementDifficulty(rawValue: difficultyRaw) else {
            return nil
        }
        
        // Decode requirements
        let requirements = decodeRequirements(from: entity.requirementsData)
        
        // Decode rewards
        let rewards = decodeRewards(from: entity.rewardsData)
        
        // Decode badge info
        let badge = decodeBadgeInfo(from: entity.badgeData)
        
        return Achievement(
            id: id,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            requirements: requirements,
            rewards: rewards,
            badge: badge,
            isSecret: entity.isSecret,
            sortOrder: Int(entity.sortOrder)
        )
    }
    
    private func mapAchievementToEntity(_ achievement: Achievement, entity: AchievementEntity) {
        entity.id = achievement.id
        entity.title = achievement.title
        entity.achievementDescription = achievement.description
        entity.category = achievement.category.rawValue
        entity.difficulty = achievement.difficulty.rawValue
        entity.isSecret = achievement.isSecret
        entity.sortOrder = Int32(achievement.sortOrder)
        
        // Encode complex data as JSON
        entity.requirementsData = encodeRequirements(achievement.requirements)
        entity.rewardsData = encodeRewards(achievement.rewards)
        entity.badgeData = encodeBadgeInfo(achievement.badge)
    }
    
    private func mapToUserAchievement(_ entity: UserAchievementEntity) -> UserAchievement? {
        guard let id = entity.id,
              let userId = entity.userId,
              let achievementId = entity.achievementId,
              let unlockedAt = entity.unlockedAt else {
            return nil
        }
        
        let progress = AchievementProgress(
            current: Int(entity.progressCurrent),
            target: Int(entity.progressTarget),
            percentage: entity.progressPercentage,
            milestones: [] // Milestones would be calculated dynamically
        )
        
        return UserAchievement(
            id: id,
            userId: userId,
            achievementId: achievementId,
            unlockedAt: unlockedAt,
            progress: progress,
            isNew: entity.isNew
        )
    }
    
    private func mapUserAchievementToEntity(_ userAchievement: UserAchievement, entity: UserAchievementEntity) {
        entity.id = userAchievement.id
        entity.userId = userAchievement.userId
        entity.achievementId = userAchievement.achievementId
        entity.unlockedAt = userAchievement.unlockedAt
        entity.progressCurrent = Int32(userAchievement.progress.current)
        entity.progressTarget = Int32(userAchievement.progress.target)
        entity.progressPercentage = userAchievement.progress.percentage
        entity.isNew = userAchievement.isNew
    }
    
    // MARK: - JSON Encoding/Decoding Helpers
    
    private func encodeRequirements(_ requirements: AchievementRequirements) -> Data? {
        return try? JSONEncoder().encode(requirements)
    }
    
    private func decodeRequirements(from data: Data?) -> AchievementRequirements {
        guard let data = data,
              let requirements = try? JSONDecoder().decode(AchievementRequirements.self, from: data) else {
            // Return default requirements if decoding fails
            return AchievementRequirements(
                type: .sessionCount,
                target: 1,
                conditions: [],
                timeframe: nil,
                isRepeatable: false
            )
        }
        return requirements
    }
    
    private func encodeRewards(_ rewards: AchievementRewards) -> Data? {
        return try? JSONEncoder().encode(rewards)
    }
    
    private func decodeRewards(from data: Data?) -> AchievementRewards {
        guard let data = data,
              let rewards = try? JSONDecoder().decode(AchievementRewards.self, from: data) else {
            // Return default rewards if decoding fails
            return AchievementRewards(
                points: 0,
                experience: 0,
                badge: "",
                title: nil,
                specialEffect: nil,
                unlockContent: nil
            )
        }
        return rewards
    }
    
    private func encodeBadgeInfo(_ badge: BadgeInfo) -> Data? {
        return try? JSONEncoder().encode(badge)
    }
    
    private func decodeBadgeInfo(from data: Data?) -> BadgeInfo {
        guard let data = data,
              let badge = try? JSONDecoder().decode(BadgeInfo.self, from: data) else {
            // Return default badge if decoding fails
            return BadgeInfo(
                id: "default",
                name: "Default Badge",
                description: "Default badge",
                imageName: "default_badge",
                emoji: "🏆",
                rarity: .common,
                animationType: .none
            )
        }
        return badge
    }
}

// MARK: - Core Data Entities

/// Core Data entity for achievements
@objc(AchievementEntity)
class AchievementEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var achievementDescription: String?
    @NSManaged var category: String?
    @NSManaged var difficulty: String?
    @NSManaged var requirementsData: Data?
    @NSManaged var rewardsData: Data?
    @NSManaged var badgeData: Data?
    @NSManaged var isSecret: Bool
    @NSManaged var sortOrder: Int32
}

/// Core Data entity for user achievements
@objc(UserAchievementEntity)
class UserAchievementEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var userId: String?
    @NSManaged var achievementId: String?
    @NSManaged var unlockedAt: Date?
    @NSManaged var progressCurrent: Int32
    @NSManaged var progressTarget: Int32
    @NSManaged var progressPercentage: Float
    @NSManaged var isNew: Bool
}

// MARK: - Fetch Request Extensions
extension AchievementEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AchievementEntity> {
        return NSFetchRequest<AchievementEntity>(entityName: "AchievementEntity")
    }
}

extension UserAchievementEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserAchievementEntity> {
        return NSFetchRequest<UserAchievementEntity>(entityName: "UserAchievementEntity")
    }
}