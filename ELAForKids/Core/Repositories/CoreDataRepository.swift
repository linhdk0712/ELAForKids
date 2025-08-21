import Foundation
import CoreData
import Combine

// MARK: - Base Core Data Repository
class CoreDataRepository: CoreDataRepositoryProtocol {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func save() async throws {
        if context.hasChanges {
            try await context.perform {
                try self.context.save()
            }
        }
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int {
        return try await context.perform {
            try self.context.count(for: request)
        }
    }
    
    func delete(_ object: NSManagedObject) async throws {
        await context.perform {
            self.context.delete(object)
        }
        try await save()
    }
}

// MARK: - Exercise Repository Implementation
class ExerciseRepository: CoreDataRepository, ExerciseRepositoryProtocol {
    
    func create(_ entity: Exercise) async throws -> Exercise {
        // Entity is already created in context, just save
        try await save()
        return entity
    }
    
    func read(id: UUID) async throws -> Exercise? {
        let request = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    func update(_ entity: Exercise) async throws -> Exercise {
        try await save()
        return entity
    }
    
    func delete(id: UUID) async throws {
        guard let exercise = try await read(id: id) else {
            throw RepositoryError.entityNotFound("Exercise with id \(id)")
        }
        try await delete(exercise)
    }
    
    func list(limit: Int? = nil, offset: Int? = nil) async throws -> [Exercise] {
        let request = Exercise.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.createdAt, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        if let offset = offset {
            request.fetchOffset = offset
        }
        
        return try await fetch(request)
    }
    
    func count() async throws -> Int {
        return try await count(Exercise.fetchRequest())
    }
    
    func findByDifficulty(_ difficulty: DifficultyLevel) async throws -> [Exercise] {
        let request = Exercise.fetchByDifficulty(difficulty)
        return try await fetch(request)
    }
    
    func findByTitle(_ title: String) async throws -> [Exercise] {
        let request = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", title)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.title, ascending: true)]
        return try await fetch(request)
    }
    
    func getRandomExercise(difficulty: DifficultyLevel) async throws -> Exercise? {
        let exercises = try await findByDifficulty(difficulty)
        return exercises.randomElement()
    }
    
    func createDefaultExercises() async throws {
        // Check if exercises already exist
        let existingCount = try await count()
        if existingCount > 0 {
            return
        }
        
        // Create default exercises (this would be moved to PersistenceController)
        try await PersistenceController.shared.seedDefaultData()
    }
}

// MARK: - User Session Repository Implementation
class UserSessionRepository: CoreDataRepository, UserSessionRepositoryProtocol {
    
    func create(_ entity: UserSession) async throws -> UserSession {
        try await save()
        return entity
    }
    
    func read(id: UUID) async throws -> UserSession? {
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    func update(_ entity: UserSession) async throws -> UserSession {
        try await save()
        return entity
    }
    
    func delete(id: UUID) async throws {
        guard let session = try await read(id: id) else {
            throw RepositoryError.entityNotFound("UserSession with id \(id)")
        }
        try await delete(session)
    }
    
    func list(limit: Int? = nil, offset: Int? = nil) async throws -> [UserSession] {
        let request = UserSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.completedAt, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        if let offset = offset {
            request.fetchOffset = offset
        }
        
        return try await fetch(request)
    }
    
    func count() async throws -> Int {
        return try await count(UserSession.fetchRequest())
    }
    
    func findByUser(_ userId: String) async throws -> [UserSession] {
        let request = UserSession.fetchByUser(userId)
        return try await fetch(request)
    }
    
    func findByExercise(_ exerciseId: UUID) async throws -> [UserSession] {
        let request = UserSession.fetchByExercise(exerciseId)
        return try await fetch(request)
    }
    
    func findByDateRange(userId: String, from: Date, to: Date) async throws -> [UserSession] {
        let request = UserSession.fetchByDateRange(userId: userId, from: from, to: to)
        return try await fetch(request)
    }
    
    func getLatestSession(userId: String) async throws -> UserSession? {
        let request = UserSession.fetchLatest(userId: userId)
        let results = try await fetch(request)
        return results.first
    }
    
    func getUserStats(userId: String) async throws -> UserSessionStats {
        let sessions = try await findByUser(userId)
        
        let totalSessions = sessions.count
        let totalScore = sessions.reduce(0) { $0 + Int($1.score) }
        let totalAccuracy = sessions.reduce(0) { $0 + $1.accuracy }
        let averageAccuracy = totalSessions > 0 ? totalAccuracy / Float(totalSessions) : 0.0
        let bestScore = sessions.max { $0.score < $1.score }?.score ?? 0
        let totalTimeSpent = sessions.reduce(0) { $0 + $1.timeSpent }
        let lastSessionDate = sessions.first?.completedAt
        
        // Calculate streaks
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        let (currentStreak, bestStreak) = calculateStreaks(from: sortedSessions)
        
        // Calculate improvement rate (simplified)
        let improvementRate = calculateImprovementRate(from: sessions)
        
        return UserSessionStats(
            totalSessions: totalSessions,
            averageAccuracy: averageAccuracy,
            totalScore: totalScore,
            bestScore: Int(bestScore),
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalTimeSpent: totalTimeSpent,
            lastSessionDate: lastSessionDate,
            improvementRate: improvementRate
        )
    }
    
    private func calculateStreaks(from sessions: [UserSession]) -> (current: Int, best: Int) {
        guard !sessions.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 1
        
        for i in 1..<sessions.count {
            let prevDate = calendar.startOfDay(for: sessions[i-1].completedAt)
            let currentDate = calendar.startOfDay(for: sessions[i].completedAt)
            let daysBetween = calendar.dateComponents([.day], from: prevDate, to: currentDate).day ?? 0
            
            if daysBetween == 1 {
                tempStreak += 1
            } else {
                bestStreak = max(bestStreak, tempStreak)
                tempStreak = 1
            }
        }
        
        bestStreak = max(bestStreak, tempStreak)
        
        // Calculate current streak from the end
        let today = calendar.startOfDay(for: Date())
        if let lastSession = sessions.last {
            let lastSessionDate = calendar.startOfDay(for: lastSession.completedAt)
            let daysSinceLastSession = calendar.dateComponents([.day], from: lastSessionDate, to: today).day ?? 0
            
            if daysSinceLastSession <= 1 {
                currentStreak = 1
                for i in stride(from: sessions.count - 2, through: 0, by: -1) {
                    let prevDate = calendar.startOfDay(for: sessions[i].completedAt)
                    let nextDate = calendar.startOfDay(for: sessions[i + 1].completedAt)
                    let daysBetween = calendar.dateComponents([.day], from: prevDate, to: nextDate).day ?? 0
                    
                    if daysBetween == 1 {
                        currentStreak += 1
                    } else {
                        break
                    }
                }
            }
        }
        
        return (currentStreak, bestStreak)
    }
    
    private func calculateImprovementRate(from sessions: [UserSession]) -> Float {
        guard sessions.count >= 2 else { return 0.0 }
        
        let sortedSessions = sessions.sorted { $0.completedAt < $1.completedAt }
        let firstHalf = Array(sortedSessions.prefix(sortedSessions.count / 2))
        let secondHalf = Array(sortedSessions.suffix(sortedSessions.count / 2))
        
        let firstHalfAverage = firstHalf.reduce(0) { $0 + $1.accuracy } / Float(firstHalf.count)
        let secondHalfAverage = secondHalf.reduce(0) { $0 + $1.accuracy } / Float(secondHalf.count)
        
        return secondHalfAverage - firstHalfAverage
    }
}

// MARK: - User Profile Repository Implementation
class UserProfileRepository: CoreDataRepository, UserProfileRepositoryProtocol {
    
    func create(_ entity: UserProfile) async throws -> UserProfile {
        try await save()
        return entity
    }
    
    func read(id: String) async throws -> UserProfile? {
        let request = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    func update(_ entity: UserProfile) async throws -> UserProfile {
        try await save()
        return entity
    }
    
    func delete(id: String) async throws {
        guard let user = try await read(id: id) else {
            throw RepositoryError.entityNotFound("UserProfile with id \(id)")
        }
        try await delete(user)
    }
    
    func list(limit: Int? = nil, offset: Int? = nil) async throws -> [UserProfile] {
        let request = UserProfile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        if let offset = offset {
            request.fetchOffset = offset
        }
        
        return try await fetch(request)
    }
    
    func count() async throws -> Int {
        return try await count(UserProfile.fetchRequest())
    }
    
    func findByName(_ name: String) async throws -> [UserProfile] {
        let request = UserProfile.fetchByName(name)
        return try await fetch(request)
    }
    
    func updateScore(userId: String, score: Int) async throws {
        guard let user = try await read(id: userId) else {
            throw RepositoryError.entityNotFound("UserProfile with id \(userId)")
        }
        
        user.totalScore += Int32(score)
        try await save()
    }
    
    func updateStreak(userId: String, streak: Int) async throws {
        guard let user = try await read(id: userId) else {
            throw RepositoryError.entityNotFound("UserProfile with id \(userId)")
        }
        
        user.currentStreak = Int32(streak)
        if streak > user.bestStreak {
            user.bestStreak = Int32(streak)
        }
        try await save()
    }
    
    func getCurrentUser() async throws -> UserProfile? {
        // For now, return the first user or create a default one
        let users = try await list(limit: 1, offset: nil)
        if let user = users.first {
            return user
        } else {
            return try await createDefaultUser()
        }
    }
    
    func createDefaultUser() async throws -> UserProfile {
        let user = UserProfile(
            context: context,
            name: "Học sinh",
            grade: 1
        )
        return try await create(user)
    }
}

// MARK: - Achievement Repository Implementation
class AchievementRepository: CoreDataRepository, AchievementRepositoryProtocol {
    
    func create(_ entity: Achievement) async throws -> Achievement {
        try await save()
        return entity
    }
    
    func read(id: String) async throws -> Achievement? {
        let request = Achievement.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    func update(_ entity: Achievement) async throws -> Achievement {
        try await save()
        return entity
    }
    
    func delete(id: String) async throws {
        guard let achievement = try await read(id: id) else {
            throw RepositoryError.entityNotFound("Achievement with id \(id)")
        }
        try await delete(achievement)
    }
    
    func list(limit: Int? = nil, offset: Int? = nil) async throws -> [Achievement] {
        let request = Achievement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Achievement.category, ascending: true)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        if let offset = offset {
            request.fetchOffset = offset
        }
        
        return try await fetch(request)
    }
    
    func count() async throws -> Int {
        return try await count(Achievement.fetchRequest())
    }
    
    func findByCategory(_ category: AchievementCategory) async throws -> [Achievement] {
        let request = Achievement.fetchByCategory(category)
        return try await fetch(request)
    }
    
    func findByUser(_ userId: String) async throws -> [Achievement] {
        let request = Achievement.fetchByUser(userId)
        return try await fetch(request)
    }
    
    func findUnlockedByUser(_ userId: String) async throws -> [Achievement] {
        let request = Achievement.fetchUnlockedByUser(userId)
        return try await fetch(request)
    }
    
    func unlockAchievement(achievementId: String, userId: String) async throws {
        guard let achievement = try await read(id: achievementId) else {
            throw RepositoryError.entityNotFound("Achievement with id \(achievementId)")
        }
        
        achievement.unlock()
        try await save()
    }
    
    func updateProgress(achievementId: String, userId: String, progress: Float) async throws {
        guard let achievement = try await read(id: achievementId) else {
            throw RepositoryError.entityNotFound("Achievement with id \(achievementId)")
        }
        
        achievement.updateProgress(progress)
        try await save()
    }
}