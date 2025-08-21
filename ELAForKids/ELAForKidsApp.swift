import SwiftUI
import CoreData

@main
struct ELAForKidsApp: App {
    let persistenceController = PersistenceController.shared
    let navigationCoordinator = NavigationCoordinator()
    let errorHandler = ErrorHandler()
    let networkMonitor = NetworkMonitor.shared
    let offlineManager: OfflineManager
    
    init() {
        // Initialize logging system first
        LoggingInitializer.shared.initializeLogging()
        
        // Configure for current environment
        #if DEBUG
        LoggingInitializer.shared.configureForEnvironment(.development)
        #elseif STAGING
        LoggingInitializer.shared.configureForEnvironment(.staging)
        #else
        LoggingInitializer.shared.configureForEnvironment(.production)
        #endif
        
        // Initialize offline manager with dependencies
        offlineManager = OfflineManager(
            networkMonitor: networkMonitor,
            persistenceController: persistenceController
        )
        
        setupDependencyInjection()
        setupOfflineCapabilities()
        
        // Log app initialization
        LoggingService.shared.logInfo("ELA for Kids app initialized", category: .general, context: [
            "app_version": Self.appVersion,
            "build_number": Self.buildNumber,
            "device_model": UIDevice.current.model,
            "system_version": UIDevice.current.systemVersion
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .withNavigationCoordinator(navigationCoordinator)
                .environmentObject(errorHandler)
                .environmentObject(networkMonitor)
                .environmentObject(offlineManager)
                .environmentObject(MonitoringService.shared)
                .preferredColorScheme(.light) // Luôn sử dụng light mode cho trẻ em
                .errorHandling() // Add comprehensive error handling
                .initializeLogging() // Ensure logging is initialized for views
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
    
    // MARK: - Dependency Injection Setup
    private func setupDependencyInjection() {
        DIContainer.shared.registerServices()
        
        // Register app-level dependencies
        DIContainer.shared.register(NavigationCoordinator.self, instance: navigationCoordinator)
        DIContainer.shared.register(ErrorHandler.self, instance: errorHandler)
        DIContainer.shared.register(NetworkMonitor.self, instance: networkMonitor)
        DIContainer.shared.register(OfflineManager.self, instance: offlineManager)
    }
    
    // MARK: - Offline Capabilities Setup
    private func setupOfflineCapabilities() {
        // Start network monitoring
        networkMonitor.startMonitoring()
        
        // Setup periodic cache cleanup
        Task {
            await setupPeriodicMaintenance()
        }
    }
    
    private func setupPeriodicMaintenance() async {
        // Clean up expired cache every day
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            Task {
                try? await persistenceController.cleanupExpiredCache()
                try? await persistenceController.cleanupSyncedData()
            }
        }
    }
}

// MARK: - App Configuration
extension ELAForKidsApp {
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
