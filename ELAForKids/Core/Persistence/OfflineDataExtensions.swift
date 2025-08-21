import Foundation
import CoreData

// MARK: - Core Data Extensions for Offline Support

// MARK: - UserSession Offline Extensions
extension UserSession {
    
    // MARK: - Offline Sync Properties
    @NSManaged public var needsSync: Bool
    @NSManaged public var syncStatus: String?
    @NSManaged public var syncedAt: Date?
    @NSManaged public var offlineCreatedAt: Date?
    @NSManaged public var syncRetryCount: Int32
    @NSManaged public var lastSyncError: String?
    
    // MARK: - Offline Sync Methods
    func markForSync() {
        needsSync = true
        syncStatus = "pending"
        offlineCreatedAt = Date()
        syncRetryCount = 0
        lastSyncError = nil
    }
    
    func markSyncCompleted() {
        needsSync = false
        syncStatus = "synced"
        syncedAt = Date()
        lastSyncError = nil
    }
    
    func markSyncFailed(error: String) {
        syncStatus = "failed"
        syncRetryCount += 1
        lastSyncError = error
        
        // Don't retry more than 3 times
        if syncRetryCount >= 3 {
            needsSync = false
            syncStatus = "failed_permanent"
        }
    }
    
    var canRetrySync: Bool {
        return needsSync && syncRetryCount < 3
    }
    
    var isOfflineSession: Bool {
        return offlineCreatedAt != nil
    }
    
    // MARK: - Fetch Requests for Offline Data
    @nonobjc public class func fetchPendingSync() -> NSFetchRequest<UserSession> {
        let request: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.offlineCreatedAt, ascending: true)]
        return request
    }
    
    @nonobjc public class func fetchFailedSync() -> NSFetchRequest<UserSession> {
        let request: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "failed")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.offlineCreatedAt, ascending: true)]
        return request
    }
    
    @nonobjc public class func fetchOfflineSessions() -> NSFetchRequest<UserSession> {
        let request: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "offlineCreatedAt != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.offlineCreatedAt, ascending: false)]
        return request
    }
}

// MARK: - Exercise Offline Extensions
extension Exercise {
    
    // MARK: - Offline Cache Properties
    @NSManaged public var isCached: Bool
    @NSManaged public var cachedAt: Date?
    @NSManaged public var cacheExpiry: Date?
    @NSManaged public var offlinePriority: Int32
    
    // MARK: - Cache Management
    func markAsCached(priority: Int32 = 0, expiryDays: Int = 30) {
        isCached = true
        cachedAt = Date()
        offlinePriority = priority
        
        let calendar = Calendar.current
        cacheExpiry = calendar.date(byAdding: .day, value: expiryDays, to: Date())
    }
    
    func clearCache() {
        isCached = false
        cachedAt = nil
        cacheExpiry = nil
        offlinePriority = 0
    }
    
    var isCacheExpired: Bool {
        guard let expiry = cacheExpiry else { return true }
        return Date() > expiry
    }
    
    var shouldRefreshCache: Bool {
        return !isCached || isCacheExpired
    }
    
    // MARK: - Fetch Requests for Cached Data
    @nonobjc public class func fetchCached() -> NSFetchRequest<Exercise> {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "isCached == YES AND cacheExpiry > %@", Date() as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Exercise.offlinePriority, ascending: false),
            NSSortDescriptor(keyPath: \Exercise.cachedAt, ascending: false)
        ]
        return request
    }
    
    @nonobjc public class func fetchExpiredCache() -> NSFetchRequest<Exercise> {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "isCached == YES AND cacheExpiry <= %@", Date() as NSDate)
        return request
    }
    
    @nonobjc public class func fetchHighPriorityCache() -> NSFetchRequest<Exercise> {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "isCached == YES AND offlinePriority > 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.offlinePriority, ascending: false)]
        return request
    }
}

// MARK: - UserProfile Offline Extensions
extension UserProfile {
    
    // MARK: - Offline Sync Properties
    @NSManaged public var lastOfflineSync: Date?
    @NSManaged public var offlineDataVersion: Int32
    @NSManaged public var pendingAchievements: String? // JSON string of pending achievements
    
    // MARK: - Offline Data Management
    func updateOfflineDataVersion() {
        offlineDataVersion += 1
    }
    
    func markOfflineSync() {
        lastOfflineSync = Date()
    }
    
    func addPendingAchievement(_ achievementId: String) {
        var pending: [String] = []
        
        if let existingData = pendingAchievements,
           let data = existingData.data(using: .utf8),
           let existingPending = try? JSONDecoder().decode([String].self, from: data) {
            pending = existingPending
        }
        
        if !pending.contains(achievementId) {
            pending.append(achievementId)
            
            if let data = try? JSONEncoder().encode(pending),
               let jsonString = String(data: data, encoding: .utf8) {
                pendingAchievements = jsonString
            }
        }
    }
    
    func getPendingAchievements() -> [String] {
        guard let data = pendingAchievements?.data(using: .utf8),
              let pending = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return pending
    }
    
    func clearPendingAchievements() {
        pendingAchievements = nil
    }
}

// MARK: - Achievement Offline Extensions
extension Achievement {
    
    // MARK: - Offline Properties
    @NSManaged public var isOfflineUnlocked: Bool
    @NSManaged public var offlineUnlockedAt: Date?
    @NSManaged public var needsSyncUnlock: Bool
    
    // MARK: - Offline Achievement Management
    func unlockOffline() {
        isOfflineUnlocked = true
        offlineUnlockedAt = Date()
        needsSyncUnlock = true
        
        // Also set the regular unlock properties
        unlock()
    }
    
    func syncUnlockCompleted() {
        needsSyncUnlock = false
    }
    
    // MARK: - Fetch Requests for Offline Achievements
    @nonobjc public class func fetchPendingSyncUnlocks() -> NSFetchRequest<Achievement> {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "needsSyncUnlock == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Achievement.offlineUnlockedAt, ascending: true)]
        return request
    }
    
    @nonobjc public class func fetchOfflineUnlocked() -> NSFetchRequest<Achievement> {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "isOfflineUnlocked == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Achievement.offlineUnlockedAt, ascending: false)]
        return request
    }
}

// MARK: - Offline Data Cleanup Utilities
extension PersistenceController {
    
    // MARK: - Cache Cleanup
    func cleanupExpiredCache() async throws {
        let context = container.viewContext
        
        await context.perform {
            // Clean up expired exercise cache
            let expiredExercisesRequest = Exercise.fetchExpiredCache()
            do {
                let expiredExercises = try context.fetch(expiredExercisesRequest)
                for exercise in expiredExercises {
                    exercise.clearCache()
                }
                print("Cleaned up \(expiredExercises.count) expired exercise cache entries")
            } catch {
                print("Failed to cleanup expired exercise cache: \(error)")
            }
        }
        
        try await save()
    }
    
    // MARK: - Sync Data Cleanup
    func cleanupSyncedData(olderThan days: Int = 30) async throws {
        let context = container.viewContext
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        await context.perform {
            // Clean up old synced sessions
            let request: NSFetchRequest<UserSession> = UserSession.fetchRequest()
            request.predicate = NSPredicate(format: "syncStatus == %@ AND syncedAt < %@", "synced", cutoffDate as NSDate)
            
            do {
                let oldSessions = try context.fetch(request)
                for session in oldSessions {
                    // Reset sync fields but keep the session data
                    session.needsSync = false
                    session.syncStatus = nil
                    session.syncedAt = nil
                    session.offlineCreatedAt = nil
                    session.syncRetryCount = 0
                    session.lastSyncError = nil
                }
                print("Cleaned up sync data for \(oldSessions.count) old sessions")
            } catch {
                print("Failed to cleanup old sync data: \(error)")
            }
        }
        
        try await save()
    }
    
    // MARK: - Failed Sync Cleanup
    func retryFailedSyncs() async throws -> [UserSession] {
        let context = container.viewContext
        
        return try await context.perform {
            let request = UserSession.fetchFailedSync()
            let failedSessions = try context.fetch(request)
            
            // Reset failed sessions that can be retried
            let retryableSessions = failedSessions.filter { $0.canRetrySync }
            for session in retryableSessions {
                session.syncStatus = "pending"
                session.lastSyncError = nil
            }
            
            return retryableSessions
        }
    }
    
    // MARK: - Offline Statistics
    func getOfflineStatistics() async throws -> OfflineStatistics {
        let context = container.viewContext
        
        return try await context.perform {
            // Count cached exercises
            let cachedExercisesCount = try context.count(for: Exercise.fetchCached())
            
            // Count pending sync sessions
            let pendingSyncCount = try context.count(for: UserSession.fetchPendingSync())
            
            // Count failed sync sessions
            let failedSyncCount = try context.count(for: UserSession.fetchFailedSync())
            
            // Count offline sessions
            let offlineSessionsCount = try context.count(for: UserSession.fetchOfflineSessions())
            
            // Count pending achievement unlocks
            let pendingAchievementsCount = try context.count(for: Achievement.fetchPendingSyncUnlocks())
            
            return OfflineStatistics(
                cachedExercisesCount: cachedExercisesCount,
                pendingSyncCount: pendingSyncCount,
                failedSyncCount: failedSyncCount,
                offlineSessionsCount: offlineSessionsCount,
                pendingAchievementsCount: pendingAchievementsCount
            )
        }
    }
}

// MARK: - Offline Statistics
struct OfflineStatistics {
    let cachedExercisesCount: Int
    let pendingSyncCount: Int
    let failedSyncCount: Int
    let offlineSessionsCount: Int
    let pendingAchievementsCount: Int
    
    var totalPendingItems: Int {
        return pendingSyncCount + pendingAchievementsCount
    }
    
    var hasFailedItems: Bool {
        return failedSyncCount > 0
    }
}