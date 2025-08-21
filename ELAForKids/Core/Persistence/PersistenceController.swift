import CoreData
import Foundation
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Tạo sample data cho preview
        createSampleData(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // Xử lý lỗi preview data
            let nsError = error as NSError
            print("Preview data creation error: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ELAForKids")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            configureCloudKit()
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Xử lý lỗi Core Data
                print("Core Data error: \(error), \(error.userInfo)")
                // In production, handle this more gracefully
                #if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #endif
            }
        })
        
        // Cấu hình automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Setup notifications for remote changes
        setupRemoteChangeNotifications()
    }
    
    private func configureCloudKit() {
        guard let storeDescription = container.persistentStoreDescriptions.first else { return }
        
        // Enable CloudKit
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Configure CloudKit container
        storeDescription.setOption("iCloud.com.yourname.elaforkids" as NSString, 
                                  forKey: NSPersistentCloudKitContainerOptionsKey)
    }
    
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            // Handle remote changes
            print("Remote changes detected")
        }
    }
}

// MARK: - Core Data Operations
extension PersistenceController {
    func save() async throws {
        let context = container.viewContext
        
        if context.hasChanges {
            try await context.perform {
                try context.save()
            }
        }
    }
    
    func saveContext() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
                // Handle error appropriately
            }
        }
    }
    
    func delete(_ object: NSManagedObject) async throws {
        let context = container.viewContext
        await context.perform {
            context.delete(object)
        }
        try await save()
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        let context = container.viewContext
        return try await context.perform {
            try context.fetch(request)
        }
    }
    
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int {
        let context = container.viewContext
        return try await context.perform {
            try context.count(for: request)
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Data Seeding
extension PersistenceController {
    func seedDefaultData() async throws {
        let context = container.viewContext
        
        // Check if data already exists
        let exerciseCount = try await count(Exercise.fetchRequest())
        if exerciseCount > 0 {
            return // Data already seeded
        }
        
        await context.perform {
            createDefaultExercises(in: context)
            createDefaultAchievements(in: context)
        }
        
        try await save()
    }
    
    private static func createSampleData(in context: NSManagedObjectContext) {
        // Create sample user
        let sampleUser = UserProfile(
            context: context,
            name: "Bé Minh",
            grade: 2,
            parentEmail: "parent@example.com"
        )
        
        // Create sample exercises
        let exercises = [
            ("Bài đọc về con mèo", "Con mèo nhỏ ngồi trên thảm xanh. Nó có bộ lông mềm mại và đôi mắt sáng.", DifficultyLevel.grade1, ExerciseCategory.story),
            ("Bài thơ về mùa xuân", "Mùa xuân đến rồi, hoa nở khắp nơi. Chim hót líu lo, lá xanh tươi mới.", DifficultyLevel.grade2, ExerciseCategory.poem),
            ("Hướng dẫn rửa tay", "Đầu tiên, mở vòi nước. Sau đó, xà phòng vào tay. Cuối cùng, rửa sạch và lau khô.", DifficultyLevel.grade1, ExerciseCategory.instruction)
        ]
        
        for (title, text, difficulty, category) in exercises {
            let exercise = Exercise(
                context: context,
                title: title,
                targetText: text,
                difficulty: difficulty,
                category: category
            )
            
            // Create sample session
            let session = UserSession(
                context: context,
                user: sampleUser,
                exercise: exercise,
                inputText: text,
                spokenText: text,
                accuracy: 0.95,
                score: 85,
                timeSpent: 120,
                inputMethod: .keyboard
            )
        }
        
        // Create sample achievements
        let achievement = Achievement(
            context: context,
            id: "first_read",
            title: "Lần đầu đọc",
            description: "Hoàn thành bài đọc đầu tiên",
            category: .reading,
            difficulty: .bronze,
            requirementType: .readSessions,
            requirementTarget: 1,
            user: sampleUser
        )
        achievement.unlock()
    }
    
    private func createDefaultExercises(in context: NSManagedObjectContext) {
        let defaultExercises = [
            // Grade 1
            ("Con chó nhỏ", "Con chó nhỏ màu nâu chạy quanh sân. Nó vẫy đuôi và sủa vang.", DifficultyLevel.grade1, ExerciseCategory.story),
            ("Gia đình tôi", "Gia đình tôi có bốn người. Bố, mẹ, em và tôi. Chúng tôi yêu thương nhau.", DifficultyLevel.grade1, ExerciseCategory.description),
            
            // Grade 2
            ("Mùa hè vui vẻ", "Mùa hè đến, trời nắng chang chang. Các em được nghỉ học, vui chơi cả ngày.", DifficultyLevel.grade2, ExerciseCategory.story),
            ("Bài thơ về mẹ", "Mẹ ơi, mẹ yêu dấu! Con yêu mẹ nhiều lắm. Mẹ chăm sóc con từng ngày.", DifficultyLevel.grade2, ExerciseCategory.poem),
            
            // Grade 3
            ("Chuyến đi picnic", "Cuối tuần, gia đình tôi đi picnic ở công viên. Chúng tôi mang theo nhiều đồ ăn ngon.", DifficultyLevel.grade3, ExerciseCategory.story),
            ("Bảo vệ môi trường", "Chúng ta cần bảo vệ môi trường. Không xả rác bừa bãi, tiết kiệm nước và điện.", DifficultyLevel.grade3, ExerciseCategory.instruction),
            
            // Grade 4
            ("Truyện cổ tích", "Ngày xưa, có một cô bé tên Tấm sống với mẹ kế và em gái. Cô rất hiền lành và chăm chỉ.", DifficultyLevel.grade4, ExerciseCategory.story),
            ("Khoa học thú vị", "Khoa học giúp chúng ta hiểu về thế giới xung quanh. Từ những ngôi sao xa xôi đến vi khuẩn nhỏ bé.", DifficultyLevel.grade4, ExerciseCategory.description),
            
            // Grade 5
            ("Lịch sử Việt Nam", "Việt Nam có lịch sử hàng nghìn năm. Tổ tiên ta đã dựng nước và giữ nước qua nhiều thế hệ.", DifficultyLevel.grade5, ExerciseCategory.news),
            ("Công nghệ hiện đại", "Công nghệ phát triển nhanh chóng. Smartphone, internet và trí tuệ nhân tạo thay đổi cuộc sống.", DifficultyLevel.grade5, ExerciseCategory.description)
        ]
        
        for (title, text, difficulty, category) in defaultExercises {
            _ = Exercise(
                context: context,
                title: title,
                targetText: text,
                difficulty: difficulty,
                category: category
            )
        }
    }
    
    private func createDefaultAchievements(in context: NSManagedObjectContext) {
        let defaultAchievements = [
            ("first_read", "Lần đầu đọc", "Hoàn thành bài đọc đầu tiên", AchievementCategory.reading, AchievementDifficulty.bronze, RequirementType.readSessions, 1),
            ("perfect_score", "Điểm số hoàn hảo", "Đạt 100% độ chính xác", AchievementCategory.accuracy, AchievementDifficulty.gold, RequirementType.perfectScores, 1),
            ("daily_streak_3", "Học liên tục 3 ngày", "Học liên tục trong 3 ngày", AchievementCategory.streak, AchievementDifficulty.silver, RequirementType.consecutiveDays, 3),
            ("daily_streak_7", "Học liên tục 1 tuần", "Học liên tục trong 7 ngày", AchievementCategory.streak, AchievementDifficulty.gold, RequirementType.consecutiveDays, 7),
            ("score_1000", "Nghìn điểm", "Đạt tổng điểm 1000", AchievementCategory.volume, AchievementDifficulty.silver, RequirementType.totalScore, 1000),
            ("accuracy_master", "Bậc thầy chính xác", "Đạt độ chính xác trung bình 90%", AchievementCategory.accuracy, AchievementDifficulty.platinum, RequirementType.averageAccuracy, 90),
            ("speed_reader", "Đọc nhanh", "Hoàn thành 50 bài đọc", AchievementCategory.volume, AchievementDifficulty.gold, RequirementType.readSessions, 50),
            ("perfect_week", "Tuần hoàn hảo", "Đạt điểm hoàn hảo 7 lần", AchievementCategory.special, AchievementDifficulty.platinum, RequirementType.perfectScores, 7)
        ]
        
        for (id, title, description, category, difficulty, requirementType, target) in defaultAchievements {
            _ = Achievement(
                context: context,
                id: id,
                title: title,
                description: description,
                category: category,
                difficulty: difficulty,
                requirementType: requirementType,
                requirementTarget: target
            )
        }
    }
}

// MARK: - CloudKit Sync Status
extension PersistenceController {
    func getCloudKitSyncStatus() -> SyncStatus {
        // This would need to be implemented based on CloudKit status
        // For now, return a mock status
        return .idle
    }
    
    func forceSync() async throws {
        // Trigger CloudKit sync
        // This would need CloudKit-specific implementation
        print("Force sync requested")
    }
}
// MARK: -
 Sync Status
enum SyncStatus {
    case idle
    case syncing
    case error(Error)
}

// MARK: - Core Data Stack Protocol
protocol CoreDataStack {
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
    var viewContext: NSManagedObjectContext { get }
}

// MARK: - PersistenceController Extension
extension PersistenceController: CoreDataStack {
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}