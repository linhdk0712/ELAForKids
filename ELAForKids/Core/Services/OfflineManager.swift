import Foundation
import CoreData
import Combine

// MARK: - Offline Capability
enum OfflineCapability {
    case textInput
    case speechRecognition
    case scoring
    case progress
    case achievements
    
    var isAvailableOffline: Bool {
        switch self {
        case .textInput, .scoring, .progress, .achievements:
            return true
        case .speechRecognition:
            return true // On-device speech recognition available
        }
    }
}

// MARK: - Offline Mode Status
enum OfflineModeStatus {
    case online
    case offline
    case syncing
    
    var displayMessage: String {
        switch self {
        case .online:
            return "Đã kết nối mạng"
        case .offline:
            return "Chế độ ngoại tuyến"
        case .syncing:
            return "Đang đồng bộ dữ liệu..."
        }
    }
    
    var icon: String {
        switch self {
        case .online:
            return "wifi"
        case .offline:
            return "wifi.slash"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Offline Manager
@MainActor
final class OfflineManager: ObservableObject {
    
    // MARK: - Properties
    @Published var status: OfflineModeStatus = .online
    @Published var isOfflineMode: Bool = false
    @Published var pendingSyncCount: Int = 0
    
    private let networkMonitor: NetworkMonitor
    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()
    
    // Offline data cache
    private var cachedExercises: [Exercise] = []
    private var pendingSessionsToSync: [UserSession] = []
    private var offlineCapabilities: Set<OfflineCapability> = []
    
    // MARK: - Initialization
    init(
        networkMonitor: NetworkMonitor = NetworkMonitor.shared,
        persistenceController: PersistenceController = PersistenceController.shared
    ) {
        self.networkMonitor = networkMonitor
        self.persistenceController = persistenceController
        
        setupOfflineCapabilities()
        observeNetworkChanges()
        loadCachedData()
    }
    
    // MARK: - Setup
    private func setupOfflineCapabilities() {
        offlineCapabilities = [
            .textInput,
            .speechRecognition,
            .scoring,
            .progress,
            .achievements
        ]
    }
    
    private func observeNetworkChanges() {
        networkMonitor.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] networkStatus in
                self?.handleNetworkStatusChange(networkStatus)
            }
            .store(in: &cancellables)
    }
    
    private func handleNetworkStatusChange(_ networkStatus: NetworkStatus) {
        switch networkStatus {
        case .connected:
            if isOfflineMode {
                // Coming back online
                status = .syncing
                Task {
                    await syncPendingData()
                    status = .online
                    isOfflineMode = false
                }
            } else {
                status = .online
                isOfflineMode = false
            }
            
        case .disconnected:
            status = .offline
            isOfflineMode = true
            
        case .unknown:
            // Keep current state
            break
        }
    }
    
    // MARK: - Data Caching
    private func loadCachedData() {
        Task {
            do {
                // Load essential exercises for offline use
                cachedExercises = try await loadEssentialExercises()
                
                // Load pending sessions that need sync
                pendingSessionsToSync = try await loadPendingSessions()
                pendingSyncCount = pendingSessionsToSync.count
                
                print("Loaded \(cachedExercises.count) cached exercises")
                print("Found \(pendingSessionsToSync.count) pending sessions to sync")
                
            } catch {
                print("Failed to load cached data: \(error)")
            }
        }
    }
    
    private func loadEssentialExercises() async throws -> [Exercise] {
        let request = Exercise.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.createdAt, ascending: false)]
        request.fetchLimit = 50 // Cache top 50 exercises
        
        return try await persistenceController.fetch(request)
    }
    
    private func loadPendingSessions() async throws -> [UserSession] {
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.completedAt, ascending: false)]
        
        return try await persistenceController.fetch(request)
    }
    
    // MARK: - Offline Capabilities
    func isCapabilityAvailable(_ capability: OfflineCapability) -> Bool {
        if networkMonitor.isConnected {
            return true // All capabilities available online
        }
        
        return offlineCapabilities.contains(capability) && capability.isAvailableOffline
    }
    
    func getOfflineExercises() -> [Exercise] {
        return cachedExercises
    }
    
    func getRandomOfflineExercise(difficulty: DifficultyLevel? = nil) -> Exercise? {
        let filteredExercises: [Exercise]
        
        if let difficulty = difficulty {
            filteredExercises = cachedExercises.filter { $0.difficulty == difficulty }
        } else {
            filteredExercises = cachedExercises
        }
        
        return filteredExercises.randomElement()
    }
    
    // MARK: - Offline Session Management
    func saveOfflineSession(_ session: UserSession) async throws {
        // Mark session as needing sync
        session.needsSync = true
        session.syncStatus = "pending"
        
        // Save to Core Data
        try await persistenceController.save()
        
        // Add to pending sync list
        pendingSessionsToSync.append(session)
        pendingSyncCount = pendingSessionsToSync.count
        
        print("Saved offline session: \(session.id)")
    }
    
    func getPendingSyncSessions() -> [UserSession] {
        return pendingSessionsToSync
    }
    
    // MARK: - Data Synchronization
    func syncPendingData() async {
        guard networkMonitor.isConnected else {
            print("Cannot sync: No network connection")
            return
        }
        
        print("Starting data synchronization...")
        
        do {
            // Sync pending sessions
            await syncPendingSessions()
            
            // Refresh cached data
            await refreshCachedData()
            
            print("Data synchronization completed successfully")
            
        } catch {
            print("Data synchronization failed: \(error)")
            // Handle sync errors gracefully
        }
    }
    
    private func syncPendingSessions() async {
        for session in pendingSessionsToSync {
            do {
                // In a real app, this would sync with a remote server
                // For now, we'll just mark as synced
                session.needsSync = false
                session.syncStatus = "synced"
                session.syncedAt = Date()
                
                try await persistenceController.save()
                print("Synced session: \(session.id)")
                
            } catch {
                print("Failed to sync session \(session.id): \(error)")
                session.syncStatus = "failed"
            }
        }
        
        // Update pending list
        pendingSessionsToSync = pendingSessionsToSync.filter { $0.needsSync }
        pendingSyncCount = pendingSessionsToSync.count
    }
    
    private func refreshCachedData() async {
        do {
            cachedExercises = try await loadEssentialExercises()
            print("Refreshed cached exercises: \(cachedExercises.count)")
        } catch {
            print("Failed to refresh cached data: \(error)")
        }
    }
    
    // MARK: - Manual Sync
    func forceSyncNow() async -> Bool {
        guard networkMonitor.isConnected else {
            return false
        }
        
        status = .syncing
        await syncPendingData()
        status = .online
        
        return true
    }
    
    // MARK: - Offline Mode Info
    func getOfflineModeInfo() -> OfflineModeInfo {
        return OfflineModeInfo(
            isOffline: isOfflineMode,
            availableCapabilities: Array(offlineCapabilities),
            cachedExercisesCount: cachedExercises.count,
            pendingSyncCount: pendingSyncCount,
            lastSyncDate: getLastSyncDate()
        )
    }
    
    private func getLastSyncDate() -> Date? {
        // Get the most recent sync date from synced sessions
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "syncedAt != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSession.syncedAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let sessions = try persistenceController.container.viewContext.fetch(request)
            return sessions.first?.syncedAt
        } catch {
            return nil
        }
    }
    
    // MARK: - Error Handling
    func handleOfflineError(_ error: Error) -> String {
        if isOfflineMode {
            return "Chế độ ngoại tuyến: Một số tính năng có thể bị hạn chế. Dữ liệu sẽ được đồng bộ khi có kết nối mạng."
        } else {
            return error.localizedDescription
        }
    }
    
    // MARK: - Cache Management
    func clearCache() async {
        cachedExercises.removeAll()
        pendingSessionsToSync.removeAll()
        pendingSyncCount = 0
        
        print("Cache cleared")
    }
    
    func refreshCache() async {
        await loadCachedData()
        print("Cache refreshed")
    }
}

// MARK: - Offline Mode Info
struct OfflineModeInfo {
    let isOffline: Bool
    let availableCapabilities: [OfflineCapability]
    let cachedExercisesCount: Int
    let pendingSyncCount: Int
    let lastSyncDate: Date?
    
    var statusMessage: String {
        if isOffline {
            return "Chế độ ngoại tuyến - \(cachedExercisesCount) bài tập có sẵn"
        } else {
            return "Đã kết nối - Tất cả tính năng có sẵn"
        }
    }
}

// MARK: - Core Data Extensions for Offline Support
extension UserSession {
    @NSManaged var needsSync: Bool
    @NSManaged var syncStatus: String?
    @NSManaged var syncedAt: Date?
}