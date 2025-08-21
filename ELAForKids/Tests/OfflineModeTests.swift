import XCTest
import CoreData
@testable import ELAForKids

// MARK: - Offline Mode Tests
final class OfflineModeTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var networkMonitor: NetworkMonitor!
    var offlineManager: OfflineManager!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        networkMonitor = NetworkMonitor()
        offlineManager = OfflineManager(
            networkMonitor: networkMonitor,
            persistenceController: persistenceController
        )
    }
    
    override func tearDown() {
        offlineManager = nil
        networkMonitor = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Network Monitor Tests
    
    func testNetworkMonitorInitialization() {
        XCTAssertNotNil(networkMonitor)
        XCTAssertEqual(networkMonitor.status, .unknown)
    }
    
    // MARK: - Offline Manager Tests
    
    func testOfflineManagerInitialization() {
        XCTAssertNotNil(offlineManager)
        XCTAssertFalse(offlineManager.isOfflineMode)
        XCTAssertEqual(offlineManager.pendingSyncCount, 0)
    }
    
    func testOfflineCapabilities() {
        // Test that essential capabilities are available offline
        XCTAssertTrue(offlineManager.isCapabilityAvailable(.textInput))
        XCTAssertTrue(offlineManager.isCapabilityAvailable(.scoring))
        XCTAssertTrue(offlineManager.isCapabilityAvailable(.progress))
        XCTAssertTrue(offlineManager.isCapabilityAvailable(.achievements))
        XCTAssertTrue(offlineManager.isCapabilityAvailable(.speechRecognition))
    }
    
    func testOfflineExerciseRetrieval() {
        // Test getting offline exercises
        let exercises = offlineManager.getOfflineExercises()
        XCTAssertNotNil(exercises)
        
        // Test getting random offline exercise
        let randomExercise = offlineManager.getRandomOfflineExercise()
        // May be nil if no exercises are cached, which is expected in test environment
    }
    
    func testOfflineModeInfo() {
        let info = offlineManager.getOfflineModeInfo()
        XCTAssertNotNil(info)
        XCTAssertFalse(info.isOffline) // Should be false initially
        XCTAssertEqual(info.pendingSyncCount, 0)
    }
    
    // MARK: - Offline Session Tests
    
    func testOfflineSessionSaving() async throws {
        // Create a test user session
        let context = persistenceController.container.viewContext
        let userSession = UserSession(context: context)
        
        userSession.id = UUID()
        userSession.inputText = "Test input"
        userSession.spokenText = "Test spoken"
        userSession.accuracy = 0.95
        userSession.score = 100
        userSession.timeSpent = 120.0
        userSession.completedAt = Date()
        userSession.inputMethod = "keyboard"
        userSession.difficulty = "grade1"
        userSession.attempts = 1
        
        // Save as offline session
        try await offlineManager.saveOfflineSession(userSession)
        
        // Verify session was marked for sync
        XCTAssertTrue(userSession.needsSync)
        XCTAssertEqual(userSession.syncStatus, "pending")
        XCTAssertNotNil(userSession.offlineCreatedAt)
        
        // Verify pending sync count increased
        XCTAssertEqual(offlineManager.pendingSyncCount, 1)
    }
    
    // MARK: - Core Data Extensions Tests
    
    func testUserSessionOfflineExtensions() {
        let context = persistenceController.container.viewContext
        let userSession = UserSession(context: context)
        
        // Test marking for sync
        userSession.markForSync()
        XCTAssertTrue(userSession.needsSync)
        XCTAssertEqual(userSession.syncStatus, "pending")
        XCTAssertNotNil(userSession.offlineCreatedAt)
        XCTAssertEqual(userSession.syncRetryCount, 0)
        
        // Test marking sync completed
        userSession.markSyncCompleted()
        XCTAssertFalse(userSession.needsSync)
        XCTAssertEqual(userSession.syncStatus, "synced")
        XCTAssertNotNil(userSession.syncedAt)
        
        // Test marking sync failed
        userSession.markForSync() // Reset to pending
        userSession.markSyncFailed(error: "Test error")
        XCTAssertEqual(userSession.syncStatus, "failed")
        XCTAssertEqual(userSession.syncRetryCount, 1)
        XCTAssertEqual(userSession.lastSyncError, "Test error")
        XCTAssertTrue(userSession.canRetrySync)
        
        // Test retry limit
        userSession.markSyncFailed(error: "Test error 2")
        userSession.markSyncFailed(error: "Test error 3")
        XCTAssertFalse(userSession.needsSync)
        XCTAssertEqual(userSession.syncStatus, "failed_permanent")
        XCTAssertFalse(userSession.canRetrySync)
    }
    
    func testExerciseOfflineExtensions() {
        let context = persistenceController.container.viewContext
        let exercise = Exercise(
            context: context,
            title: "Test Exercise",
            targetText: "Test text",
            difficulty: .grade1,
            category: .story
        )
        
        // Test marking as cached
        exercise.markAsCached(priority: 5, expiryDays: 30)
        XCTAssertTrue(exercise.isCached)
        XCTAssertNotNil(exercise.cachedAt)
        XCTAssertNotNil(exercise.cacheExpiry)
        XCTAssertEqual(exercise.offlinePriority, 5)
        XCTAssertFalse(exercise.isCacheExpired)
        XCTAssertFalse(exercise.shouldRefreshCache)
        
        // Test clearing cache
        exercise.clearCache()
        XCTAssertFalse(exercise.isCached)
        XCTAssertNil(exercise.cachedAt)
        XCTAssertNil(exercise.cacheExpiry)
        XCTAssertEqual(exercise.offlinePriority, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testOfflineErrorHandling() {
        let networkError = NetworkError.noConnection
        let offlineErrorMessage = offlineManager.handleOfflineError(networkError)
        
        XCTAssertFalse(offlineErrorMessage.isEmpty)
        XCTAssertTrue(offlineErrorMessage.contains("ngoại tuyến") || offlineErrorMessage.contains("offline"))
    }
    
    // MARK: - Performance Tests
    
    func testOfflineManagerPerformance() {
        measure {
            // Test performance of getting offline exercises
            _ = offlineManager.getOfflineExercises()
            
            // Test performance of getting offline mode info
            _ = offlineManager.getOfflineModeInfo()
            
            // Test performance of checking capabilities
            for capability in [OfflineCapability.textInput, .speechRecognition, .scoring, .progress, .achievements] {
                _ = offlineManager.isCapabilityAvailable(capability)
            }
        }
    }
}

// MARK: - Mock Network Monitor for Testing
class MockNetworkMonitor: NetworkMonitor {
    private var mockStatus: NetworkStatus = .connected
    
    override var status: NetworkStatus {
        get { mockStatus }
        set { mockStatus = newValue }
    }
    
    override var isConnected: Bool {
        return mockStatus.isConnected
    }
    
    func simulateNetworkChange(to status: NetworkStatus) {
        mockStatus = status
        // Trigger status update
        updateStatus(status)
    }
    
    private func updateStatus(_ newStatus: NetworkStatus) {
        // This would normally be called by the parent class
        // but we need to simulate it for testing
    }
}