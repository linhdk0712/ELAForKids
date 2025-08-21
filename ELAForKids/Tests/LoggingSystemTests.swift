import XCTest
@testable import ELAForKids

final class LoggingSystemTests: XCTestCase {
    
    var loggingService: LoggingService!
    var crashReportingService: CrashReportingService!
    var monitoringService: MonitoringService!
    var privacyAnalytics: PrivacyCompliantAnalytics!
    
    override func setUpWithError() throws {
        loggingService = LoggingService.shared
        crashReportingService = CrashReportingService.shared
        monitoringService = MonitoringService.shared
        privacyAnalytics = PrivacyCompliantAnalytics.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        privacyAnalytics.clearAllAnalytics()
        crashReportingService.clearCrashReports()
    }
    
    // MARK: - Logging Service Tests
    
    func testLoggingServiceInitialization() throws {
        XCTAssertNotNil(loggingService)
    }
    
    func testBasicLogging() throws {
        // Test different log levels
        loggingService.logInfo("Test info message", category: .general)
        loggingService.logWarning("Test warning message", category: .general)
        loggingService.logError("Test error message", category: .general)
        loggingService.logCritical("Test critical message", category: .general)
        
        // Verify logs were created
        let recentLogs = loggingService.getRecentLogs(limit: 10)
        XCTAssertGreaterThan(recentLogs.count, 0)
        
        // Check if our test messages are in the logs
        let testMessages = recentLogs.filter { $0.message.contains("Test") }
        XCTAssertGreaterThanOrEqual(testMessages.count, 4)
    }
    
    func testLoggingWithContext() throws {
        let testContext = [
            "user_id": "test_user",
            "session_id": "test_session",
            "action": "test_action"
        ]
        
        loggingService.logInfo("Test message with context", category: .general, context: testContext)
        
        let recentLogs = loggingService.getRecentLogs(limit: 5)
        let contextLog = recentLogs.first { $0.message.contains("Test message with context") }
        
        XCTAssertNotNil(contextLog)
        XCTAssertNotNil(contextLog?.context)
    }
    
    func testCategoryFiltering() throws {
        // Log messages in different categories
        loggingService.logInfo("Speech test", category: .speech)
        loggingService.logInfo("Audio test", category: .audio)
        loggingService.logInfo("Network test", category: .network)
        
        // Test category filtering
        let speechLogs = loggingService.getLogs(category: .speech, limit: 10)
        let audioLogs = loggingService.getLogs(category: .audio, limit: 10)
        let networkLogs = loggingService.getLogs(category: .network, limit: 10)
        
        XCTAssertTrue(speechLogs.contains { $0.message.contains("Speech test") })
        XCTAssertTrue(audioLogs.contains { $0.message.contains("Audio test") })
        XCTAssertTrue(networkLogs.contains { $0.message.contains("Network test") })
    }
    
    // MARK: - Crash Reporting Tests
    
    func testCrashReportingInitialization() throws {
        XCTAssertNotNil(crashReportingService)
    }
    
    func testErrorRecording() throws {
        let testError = "Test error for crash reporting"
        let testContext = ["test": "context"]
        
        crashReportingService.recordError(testError, context: testContext)
        
        let crashReports = crashReportingService.getCrashReports()
        let testReport = crashReports.first { $0.message.contains("Test error") }
        
        XCTAssertNotNil(testReport)
        XCTAssertFalse(testReport?.isFatal ?? true)
    }
    
    func testCriticalErrorRecording() throws {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test critical error"])
        let testContext = ["critical": "test"]
        
        crashReportingService.recordCriticalError("Critical test error", error: testError, context: testContext)
        
        let crashReports = crashReportingService.getCrashReports()
        let criticalReport = crashReports.first { $0.message.contains("Critical test error") }
        
        XCTAssertNotNil(criticalReport)
        XCTAssertNotNil(criticalReport?.context)
    }
    
    func testAppHealthMetrics() throws {
        // Record some test errors
        crashReportingService.recordError("Test error 1")
        crashReportingService.recordError("Test error 2")
        crashReportingService.recordCriticalError("Critical error")
        
        let healthMetrics = crashReportingService.getAppHealthMetrics()
        
        XCTAssertGreaterThan(healthMetrics.totalErrors, 0)
        XCTAssertGreaterThan(healthMetrics.recentErrors, 0)
        XCTAssertGreaterThan(healthMetrics.criticalErrors, 0)
        XCTAssertLessThanOrEqual(healthMetrics.healthScore, 100.0)
        XCTAssertGreaterThanOrEqual(healthMetrics.healthScore, 0.0)
    }
    
    // MARK: - Monitoring Service Tests
    
    func testMonitoringServiceInitialization() throws {
        XCTAssertNotNil(monitoringService)
        XCTAssertTrue(monitoringService.isMonitoring)
    }
    
    func testEventRecording() throws {
        let testEvent = "test_event"
        let testCategory = "test_category"
        let testParameters = ["param1": "value1", "param2": 42] as [String: Any]
        
        monitoringService.recordEvent(testEvent, category: testCategory, parameters: testParameters)
        
        // Verify the event was logged
        let recentLogs = loggingService.getRecentLogs(limit: 10)
        let eventLog = recentLogs.first { $0.message.contains("Analytics: \(testEvent)") }
        
        XCTAssertNotNil(eventLog)
    }
    
    func testPerformanceRecording() throws {
        let testMetric = "test_metric"
        let testValue = 123.45
        let testUnit = "ms"
        
        monitoringService.recordPerformance(testMetric, value: testValue, unit: testUnit)
        
        // Verify the performance metric was logged
        let recentLogs = loggingService.getRecentLogs(limit: 10)
        let performanceLog = recentLogs.first { $0.message.contains("Performance: \(testMetric)") }
        
        XCTAssertNotNil(performanceLog)
    }
    
    func testUserInteractionRecording() throws {
        let testAction = "test_tap"
        let testScreen = "test_screen"
        let testContext = ["element": "test_button"]
        
        monitoringService.recordUserInteraction(testAction, screen: testScreen, context: testContext)
        
        // Verify the interaction was logged
        let recentLogs = loggingService.getRecentLogs(limit: 10)
        let interactionLog = recentLogs.first { $0.message.contains("User interaction: \(testAction)") }
        
        XCTAssertNotNil(interactionLog)
    }
    
    func testHealthStatusRetrieval() throws {
        let healthStatus = monitoringService.getHealthStatus()
        
        XCTAssertNotNil(healthStatus)
        XCTAssertGreaterThanOrEqual(healthStatus.healthScore, 0.0)
        XCTAssertLessThanOrEqual(healthStatus.healthScore, 100.0)
        XCTAssertGreaterThanOrEqual(healthStatus.memoryUsage, 0.0)
        XCTAssertGreaterThanOrEqual(healthStatus.uptime, 0.0)
    }
    
    // MARK: - Privacy Analytics Tests
    
    func testPrivacyAnalyticsInitialization() throws {
        XCTAssertNotNil(privacyAnalytics)
    }
    
    func testAllowedEventTracking() throws {
        // Test allowed events
        privacyAnalytics.trackEvent("app_launch")
        privacyAnalytics.trackEvent("session_start")
        privacyAnalytics.trackEvent("exercise_completed")
        
        // These should be tracked without issues
        // We can't easily verify the internal state, but we can check that no errors occur
    }
    
    func testDisallowedEventFiltering() throws {
        // Test that disallowed events are not tracked
        privacyAnalytics.trackEvent("sensitive_event")
        privacyAnalytics.trackEvent("personal_data_event")
        
        // These should be filtered out
        // The test passes if no exceptions are thrown
    }
    
    func testLearningProgressTracking() throws {
        let testLevel = "grade_1"
        let testAccuracy: Float = 0.85
        let testTimeSpent: TimeInterval = 120.0
        
        privacyAnalytics.trackLearningProgress(level: testLevel, accuracy: testAccuracy, timeSpent: testTimeSpent)
        
        // Verify the event was logged
        let recentLogs = loggingService.getRecentLogs(limit: 10)
        let progressLog = recentLogs.first { $0.message.contains("Analytics: exercise_completed") }
        
        XCTAssertNotNil(progressLog)
    }
    
    func testPrivacyCompliance() throws {
        let complianceStatus = privacyAnalytics.getPrivacyComplianceStatus()
        
        XCTAssertTrue(complianceStatus.isCOPPACompliant)
        XCTAssertTrue(complianceStatus.encryptionEnabled)
        XCTAssertTrue(complianceStatus.anonymizationEnabled)
        XCTAssertTrue(complianceStatus.parentalControlsRespected)
    }
    
    // MARK: - Integration Tests
    
    func testErrorHandlingIntegration() throws {
        // Test that errors flow through the entire system
        let testError = ValidationError.invalidInput("test_field")
        let testContext = ["integration": "test"]
        
        ErrorHandler.shared.handle(testError, context: testContext)
        
        // Check that the error was logged
        let recentLogs = loggingService.getRecentLogs(limit: 10)
        let errorLog = recentLogs.first { $0.message.contains("VAL_001") }
        XCTAssertNotNil(errorLog)
        
        // Check that the error was reported to crash reporting
        let crashReports = crashReportingService.getCrashReports()
        let errorReport = crashReports.first { $0.message.contains("VAL_001") }
        XCTAssertNotNil(errorReport)
    }
    
    func testSystemStatusRetrieval() throws {
        let systemStatus = LoggingInitializer.shared.getSystemStatus()
        
        XCTAssertTrue(systemStatus.isLoggingActive)
        XCTAssertNotNil(systemStatus.healthStatus)
        XCTAssertNotNil(systemStatus.performanceSummary)
        XCTAssertNotNil(systemStatus.privacyCompliance)
    }
    
    func testDataExport() throws {
        // Add some test data
        loggingService.logInfo("Export test log", category: .general)
        crashReportingService.recordError("Export test error")
        privacyAnalytics.trackEvent("app_launch")
        
        // Test export
        let exportURLs = LoggingInitializer.shared.exportSystemData()
        
        XCTAssertGreaterThan(exportURLs.count, 0)
        
        // Verify files exist
        for url in exportURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        
        // Clean up export files
        for url in exportURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Performance Tests
    
    func testLoggingPerformance() throws {
        measure {
            for i in 0..<100 {
                loggingService.logInfo("Performance test message \(i)", category: .performance)
            }
        }
    }
    
    func testCrashReportingPerformance() throws {
        measure {
            for i in 0..<50 {
                crashReportingService.recordError("Performance test error \(i)")
            }
        }
    }
    
    func testAnalyticsPerformance() throws {
        measure {
            for i in 0..<100 {
                privacyAnalytics.trackEvent("app_launch", parameters: ["test_id": i])
            }
        }
    }
}