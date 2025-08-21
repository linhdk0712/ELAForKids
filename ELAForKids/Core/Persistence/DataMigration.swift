import Foundation
import CoreData

// MARK: - Data Migration Manager
class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private init() {}
    
    func requiresMigration(at storeURL: URL, toVersion version: String) -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        ) else {
            return false
        }
        
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }
    
    func migrateStore(at storeURL: URL) throws {
        // Perform migration if needed
        // This is a simplified implementation
        print("Performing data migration...")
        
        // In a real implementation, you would:
        // 1. Create mapping models
        // 2. Perform progressive migration
        // 3. Handle data transformation
        // 4. Validate migrated data
        
        print("Data migration completed")
    }
}

// MARK: - Migration Utilities
extension DataMigrationManager {
    func backupStore(at storeURL: URL) throws -> URL {
        let backupURL = storeURL.appendingPathExtension("backup")
        
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        
        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        return backupURL
    }
    
    func restoreStore(from backupURL: URL, to storeURL: URL) throws {
        if FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
        }
        
        try FileManager.default.copyItem(at: backupURL, to: storeURL)
    }
    
    func cleanupBackup(at backupURL: URL) {
        try? FileManager.default.removeItem(at: backupURL)
    }
}

// MARK: - Data Validation
extension DataMigrationManager {
    func validateData(in context: NSManagedObjectContext) throws {
        // Validate exercises
        try validateExercises(in: context)
        
        // Validate user profiles
        try validateUserProfiles(in: context)
        
        // Validate sessions
        try validateUserSessions(in: context)
        
        // Validate achievements
        try validateAchievements(in: context)
    }
    
    private func validateExercises(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        let exercises = try context.fetch(request)
        
        for exercise in exercises {
            // Validate required fields
            guard let id = exercise.id,
                  let title = exercise.title,
                  let targetText = exercise.targetText,
                  let difficulty = exercise.difficulty,
                  let createdAt = exercise.createdAt else {
                throw DataValidationError.invalidExercise("Missing required fields")
            }
            
            // Validate difficulty level
            guard DifficultyLevel(rawValue: difficulty) != nil else {
                throw DataValidationError.invalidExercise("Invalid difficulty level: \(difficulty)")
            }
            
            // Validate text length
            guard !targetText.isEmpty && targetText.count <= 1000 else {
                throw DataValidationError.invalidExercise("Invalid target text length")
            }
        }
    }
    
    private func validateUserProfiles(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        let profiles = try context.fetch(request)
        
        for profile in profiles {
            // Validate required fields
            guard let id = profile.id,
                  let name = profile.name,
                  let createdAt = profile.createdAt else {
                throw DataValidationError.invalidUserProfile("Missing required fields")
            }
            
            // Validate grade
            guard profile.grade >= 1 && profile.grade <= 5 else {
                throw DataValidationError.invalidUserProfile("Invalid grade: \(profile.grade)")
            }
            
            // Validate scores
            guard profile.totalScore >= 0 && profile.averageAccuracy >= 0 && profile.averageAccuracy <= 1 else {
                throw DataValidationError.invalidUserProfile("Invalid score values")
            }
        }
    }
    
    private func validateUserSessions(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        let sessions = try context.fetch(request)
        
        for session in sessions {
            // Validate required fields
            guard let id = session.id,
                  let inputText = session.inputText,
                  let completedAt = session.completedAt,
                  let inputMethod = session.inputMethod else {
                throw DataValidationError.invalidUserSession("Missing required fields")
            }
            
            // Validate accuracy
            guard session.accuracy >= 0 && session.accuracy <= 1 else {
                throw DataValidationError.invalidUserSession("Invalid accuracy: \(session.accuracy)")
            }
            
            // Validate input method
            guard InputMethod(rawValue: inputMethod) != nil else {
                throw DataValidationError.invalidUserSession("Invalid input method: \(inputMethod)")
            }
            
            // Validate relationships
            guard session.user != nil && session.exercise != nil else {
                throw DataValidationError.invalidUserSession("Missing required relationships")
            }
        }
    }
    
    private func validateAchievements(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        let achievements = try context.fetch(request)
        
        for achievement in achievements {
            // Validate required fields
            guard let id = achievement.id,
                  let title = achievement.title,
                  let category = achievement.category,
                  let difficulty = achievement.difficulty,
                  let requirementType = achievement.requirementType else {
                throw DataValidationError.invalidAchievement("Missing required fields")
            }
            
            // Validate enums
            guard AchievementCategory(rawValue: category) != nil else {
                throw DataValidationError.invalidAchievement("Invalid category: \(category)")
            }
            
            guard AchievementDifficulty(rawValue: difficulty) != nil else {
                throw DataValidationError.invalidAchievement("Invalid difficulty: \(difficulty)")
            }
            
            guard RequirementType(rawValue: requirementType) != nil else {
                throw DataValidationError.invalidAchievement("Invalid requirement type: \(requirementType)")
            }
            
            // Validate progress
            guard achievement.progress >= 0 && achievement.progress <= 1 else {
                throw DataValidationError.invalidAchievement("Invalid progress: \(achievement.progress)")
            }
        }
    }
}

// MARK: - Data Validation Errors
enum DataValidationError: LocalizedError {
    case invalidExercise(String)
    case invalidUserProfile(String)
    case invalidUserSession(String)
    case invalidAchievement(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidExercise(let details):
            return "Invalid exercise data: \(details)"
        case .invalidUserProfile(let details):
            return "Invalid user profile data: \(details)"
        case .invalidUserSession(let details):
            return "Invalid user session data: \(details)"
        case .invalidAchievement(let details):
            return "Invalid achievement data: \(details)"
        }
    }
}

// MARK: - Data Cleanup
extension DataMigrationManager {
    func cleanupOrphanedData(in context: NSManagedObjectContext) throws {
        // Remove orphaned text mistakes (sessions without mistakes relationship)
        try cleanupOrphanedTextMistakes(in: context)
        
        // Remove orphaned achievements (achievements without user relationship)
        try cleanupOrphanedAchievements(in: context)
        
        // Save changes
        if context.hasChanges {
            try context.save()
        }
    }
    
    private func cleanupOrphanedTextMistakes(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<TextMistake> = TextMistake.fetchRequest()
        request.predicate = NSPredicate(format: "session == nil")
        
        let orphanedMistakes = try context.fetch(request)
        for mistake in orphanedMistakes {
            context.delete(mistake)
        }
        
        print("Cleaned up \(orphanedMistakes.count) orphaned text mistakes")
    }
    
    private func cleanupOrphanedAchievements(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "user == nil")
        
        let orphanedAchievements = try context.fetch(request)
        for achievement in orphanedAchievements {
            context.delete(achievement)
        }
        
        print("Cleaned up \(orphanedAchievements.count) orphaned achievements")
    }
}