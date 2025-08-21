import Foundation
import CoreData
import Combine

// MARK: - Base Repository Protocol
protocol RepositoryProtocol {
    associatedtype Entity
    associatedtype ID: Hashable
    
    func create(_ entity: Entity) async throws -> Entity
    func read(id: ID) async throws -> Entity?
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: ID) async throws
    func list(limit: Int?, offset: Int?) async throws -> [Entity]
    func count() async throws -> Int
}

// MARK: - Exercise Repository Protocol
protocol ExerciseRepositoryProtocol: RepositoryProtocol where Entity == Exercise, ID == UUID {
    func findByDifficulty(_ difficulty: DifficultyLevel) async throws -> [Exercise]
    func findByTitle(_ title: String) async throws -> [Exercise]
    func getRandomExercise(difficulty: DifficultyLevel) async throws -> Exercise?
    func createDefaultExercises() async throws
}

// MARK: - User Session Repository Protocol
protocol UserSessionRepositoryProtocol: RepositoryProtocol where Entity == UserSession, ID == UUID {
    func findByUser(_ userId: String) async throws -> [UserSession]
    func findByExercise(_ exerciseId: UUID) async throws -> [UserSession]
    func findByDateRange(userId: String, from: Date, to: Date) async throws -> [UserSession]
    func getLatestSession(userId: String) async throws -> UserSession?
    func getUserStats(userId: String) async throws -> UserSessionStats
}

// MARK: - User Profile Repository Protocol
protocol UserProfileRepositoryProtocol: RepositoryProtocol where Entity == UserProfile, ID == String {
    func findByName(_ name: String) async throws -> [UserProfile]
    func updateScore(userId: String, score: Int) async throws
    func updateStreak(userId: String, streak: Int) async throws
    func getCurrentUser() async throws -> UserProfile?
    func createDefaultUser() async throws -> UserProfile
}

// MARK: - Achievement Repository Protocol
protocol AchievementRepositoryProtocol: RepositoryProtocol where Entity == Achievement, ID == String {
    func findByCategory(_ category: AchievementCategory) async throws -> [Achievement]
    func findByUser(_ userId: String) async throws -> [Achievement]
    func findUnlockedByUser(_ userId: String) async throws -> [Achievement]
    func unlockAchievement(achievementId: String, userId: String) async throws
    func updateProgress(achievementId: String, userId: String, progress: Float) async throws
}

// MARK: - Core Data Repository Protocol
protocol CoreDataRepositoryProtocol {
    var context: NSManagedObjectContext { get }
    func save() async throws
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T]
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int
    func delete(_ object: NSManagedObject) async throws
}

// MARK: - Sync Repository Protocol
protocol SyncRepositoryProtocol {
    func syncToCloud() async throws
    func syncFromCloud() async throws
    func resolveConflicts() async throws
    func getLastSyncDate() -> Date?
    func setLastSyncDate(_ date: Date)
}

// MARK: - User Session Stats
struct UserSessionStats: Codable {
    let totalSessions: Int
    let averageAccuracy: Float
    let totalScore: Int
    let bestScore: Int
    let currentStreak: Int
    let bestStreak: Int
    let totalTimeSpent: TimeInterval
    let lastSessionDate: Date?
    let improvementRate: Float
    
    var formattedTotalTime: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = Int(totalTimeSpent) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Repository Error
enum RepositoryError: LocalizedError {
    case entityNotFound(String)
    case invalidData(String)
    case saveError(String)
    case fetchError(String)
    case deleteError(String)
    case syncError(String)
    case contextError(String)
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound(let entity):
            return "Không tìm thấy \(entity)"
        case .invalidData(let details):
            return "Dữ liệu không hợp lệ: \(details)"
        case .saveError(let details):
            return "Lỗi khi lưu: \(details)"
        case .fetchError(let details):
            return "Lỗi khi tải: \(details)"
        case .deleteError(let details):
            return "Lỗi khi xóa: \(details)"
        case .syncError(let details):
            return "Lỗi đồng bộ: \(details)"
        case .contextError(let details):
            return "Lỗi context: \(details)"
        }
    }
}

// MARK: - Query Options
struct QueryOptions {
    let limit: Int?
    let offset: Int?
    let sortBy: String?
    let sortAscending: Bool
    let filters: [String: Any]
    
    init(limit: Int? = nil, 
         offset: Int? = nil, 
         sortBy: String? = nil, 
         sortAscending: Bool = true, 
         filters: [String: Any] = [:]) {
        self.limit = limit
        self.offset = offset
        self.sortBy = sortBy
        self.sortAscending = sortAscending
        self.filters = filters
    }
}

// MARK: - Pagination Result
struct PaginationResult<T> {
    let items: [T]
    let totalCount: Int
    let hasMore: Bool
    let currentPage: Int
    let pageSize: Int
    
    var totalPages: Int {
        (totalCount + pageSize - 1) / pageSize
    }
}

// MARK: - Sync Status
enum SyncStatus {
    case idle
    case syncing
    case success(Date)
    case failed(Error)
    
    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }
    
    var lastSyncDate: Date? {
        if case .success(let date) = self { return date }
        return nil
    }
    
    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}