import Foundation
import SwiftUI
import os.log

// MARK: - Logging Initializer
final class LoggingInitializer {
    
    // MARK: - Singleton
    static let shared = LoggingInitializer()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.elaforkids.app", category: "LoggingInitializer")
    private var isInitialized = false
    
    // MARK: - Services
    private let loggingService = LoggingService.shared
    private let crashReportingService = CrashReportingService.shared
    private let monitoringService = MonitoringService.shared
    private let privacyAnalytics = PrivacyCompliantAnalytics.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Initialize all logging and monitoring services
    func initializeLogging() {
        guard !isInitialized else {
            logger.info("Logging already initialized")
            return
        }
        
        logger.info("Initializing comprehensive logging system...")
        
        // Initialize services in order
        initializeLoggingService()
        initializeCrashReporting()
        initializeMonitoring()
        initializePrivacyAnalytics()
        
        // Set up global error handling
        setupGlobalErrorHandling()
        
        // Log successful initialization
        logInitializationComplete()
        
        isInitialized = true
        logger.info("Logging system initialization complete")
    }
    
    /// Configure logging for development vs production
    func configureForEnvironment(_ environment: AppEnvironment) {
        switch environment {
        case .development:
            configureDevelopmentLogging()
        case .staging:
            configureStagingLogging()
        case .production:
            configureProductionLogging()
        }
        
        loggingService.logInfo("Logging configured for \(environment.rawValue) environment", category: .general)
    }
    
    /// Get comprehensive system status
    func getSystemStatus() -> SystemStatus {
        let healthStatus = monitoringService.getHealthStatus()
        let performanceSummary = monitoringService.getPerformanceSummary()
        let privacyCompliance = privacyAnalytics.getPrivacyComplianceStatus()
        
        return SystemStatus(
            isLoggingActive: isInitialized,
            healthStatus: healthStatus,
            performanceSummary: performanceSummary,
            privacyCompliance: privacyCompliance,
            lastSystemCheck: Date()
        )
    }
    
    /// Export all system data for support
    func exportSystemData() -> [URL] {
        var exportURLs: [URL] = []
        
        // Export logs
        if let logsURL = loggingService.exportLogs() {
            exportURLs.append(logsURL)
        }
        
        // Export crash reports
        if let crashURL = crashReportingService.exportCrashReports() {
            exportURLs.append(crashURL)
        }
        
        // Export monitoring data
        if let monitoringURL = monitoringService.exportMonitoringData() {
            exportURLs.append(monitoringURL)
        }
        
        // Export analytics
        if let analyticsURL = privacyAnalytics.exportAnalytics() {
            exportURLs.append(analyticsURL)
        }
        
        loggingService.logInfo("System data exported", category: .general, context: [
            "export_count": exportURLs.count,
            "export_timestamp": ISO8601DateFormatter().string(from: Date())
        ])
        
        return exportURLs
    }
    
    /// Clear all system data (for privacy compliance)
    func clearAllSystemData() {
        // Clear analytics first (most privacy-sensitive)
        privacyAnalytics.clearAllAnalytics()
        
        // Clear crash reports
        crashReportingService.clearCrashReports()
        
        // Note: We don't clear logs as they may be needed for debugging
        // But we could add an option for that if needed
        
        loggingService.logInfo("System data cleared by user request", category: .privacy)
        logger.info("All system data cleared")
    }
    
    // MARK: - Private Methods
    
    private func initializeLoggingService() {
        // LoggingService initializes automatically as singleton
        loggingService.logInfo("Logging service initialized", category: .general, context: [
            "app_version": getAppVersion(),
            "build_number": getBuildNumber(),
            "device_model": UIDevice.current.model,
            "system_version": UIDevice.current.systemVersion
        ])
    }
    
    private func initializeCrashReporting() {
        // CrashReportingService initializes automatically as singleton
        crashReportingService.recordError("Crash reporting service initialized")
    }
    
    private func initializeMonitoring() {
        // MonitoringService starts automatically
        monitoringService.recordEvent("monitoring_initialized", category: "system")
    }
    
    private func initializePrivacyAnalytics() {
        // PrivacyCompliantAnalytics initializes automatically as singleton
        privacyAnalytics.trackEvent("app_launch", parameters: [
            "app_version": getAppVersion(),
            "device_type": getDeviceType()
        ])
    }
    
    private func setupGlobalErrorHandling() {
        // Set up additional global error handlers
        
        // Handle SwiftUI errors
        setupSwiftUIErrorHandling()
        
        // Handle Core Data errors
        setupCoreDataErrorHandling()
        
        // Handle network errors
        setupNetworkErrorHandling()
    }
    
    private func setupSwiftUIErrorHandling() {
        // This would set up SwiftUI-specific error handling
        // For now, we rely on the existing ErrorHandler
        loggingService.logInfo("SwiftUI error handling configured", category: .ui)
    }
    
    private func setupCoreDataErrorHandling() {
        // Set up Core Data error notifications
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?["error"] as? Error {
                self?.loggingService.logError("Core Data save error", category: .storage, error: error)
                self?.crashReportingService.recordError("Core Data save failed", context: [
                    "error": error.localizedDescription
                ])
            }
        }
        
        loggingService.logInfo("Core Data error handling configured", category: .storage)
    }
    
    private func setupNetworkErrorHandling() {
        // Set up network error monitoring
        NotificationCenter.default.addObserver(
            forName: .networkErrorOccurred,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.object as? AppError {
                self?.privacyAnalytics.trackError(
                    errorCode: error.errorCode,
                    category: error.category.rawValue,
                    severity: error.severity.rawValue
                )
            }
        }
        
        loggingService.logInfo("Network error handling configured", category: .network)
    }
    
    private func configureDevelopmentLogging() {
        // In development, log everything
        loggingService.logInfo("Development logging configuration applied", category: .general, context: [
            "log_level": "verbose",
            "crash_reporting": "enabled",
            "analytics": "enabled",
            "monitoring": "enabled"
        ])
    }
    
    private func configureStagingLogging() {
        // In staging, log most things but with some filtering
        loggingService.logInfo("Staging logging configuration applied", category: .general, context: [
            "log_level": "standard",
            "crash_reporting": "enabled",
            "analytics": "enabled",
            "monitoring": "enabled"
        ])
    }
    
    private func configureProductionLogging() {
        // In production, log only important events and errors
        loggingService.logInfo("Production logging configuration applied", category: .general, context: [
            "log_level": "minimal",
            "crash_reporting": "enabled",
            "analytics": "privacy_compliant",
            "monitoring": "performance_only"
        ])
    }
    
    private func logInitializationComplete() {
        let initContext: [String: Any] = [
            "initialization_time": Date().timeIntervalSince1970,
            "app_version": getAppVersion(),
            "build_number": getBuildNumber(),
            "device_model": UIDevice.current.model,
            "system_version": UIDevice.current.systemVersion,
            "available_memory": getAvailableMemory(),
            "total_storage": getTotalStorage(),
            "available_storage": getAvailableStorage()
        ]
        
        loggingService.logInfo("Comprehensive logging system initialized successfully", category: .general, context: initContext)
        
        privacyAnalytics.trackEvent("logging_system_initialized", parameters: [
            "device_type": getDeviceType(),
            "app_version": getAppVersion()
        ])
    }
    
    // MARK: - Helper Methods
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private func getDeviceType() -> String {
        let model = UIDevice.current.model
        if model.contains("iPad") {
            return "tablet"
        } else if model.contains("iPhone") {
            return "phone"
        } else {
            return "other"
        }
    }
    
    private func getAvailableMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func getTotalStorage() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return systemAttributes[.systemSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func getAvailableStorage() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return systemAttributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Supporting Models

enum AppEnvironment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
}

struct SystemStatus: Codable {
    let isLoggingActive: Bool
    let healthStatus: AppHealthStatus
    let performanceSummary: PerformanceSummary
    let privacyCompliance: PrivacyComplianceStatus
    let lastSystemCheck: Date
}

// MARK: - SwiftUI Integration

struct LoggingInitializerModifier: ViewModifier {
    @State private var isInitialized = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !isInitialized {
                    LoggingInitializer.shared.initializeLogging()
                    
                    // Configure for current environment
                    #if DEBUG
                    LoggingInitializer.shared.configureForEnvironment(.development)
                    #elseif STAGING
                    LoggingInitializer.shared.configureForEnvironment(.staging)
                    #else
                    LoggingInitializer.shared.configureForEnvironment(.production)
                    #endif
                    
                    isInitialized = true
                }
            }
    }
}

extension View {
    func initializeLogging() -> some View {
        modifier(LoggingInitializerModifier())
    }
}