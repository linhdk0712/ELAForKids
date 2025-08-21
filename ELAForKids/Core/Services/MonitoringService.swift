import Foundation
import Combine
import UIKit
import os.log

// MARK: - Monitoring Service
final class MonitoringService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = MonitoringService()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.elaforkids.app", category: "Monitoring")
    private let loggingService = LoggingService.shared
    private let crashReportingService = CrashReportingService.shared
    
    @Published var isMonitoring = false
    @Published var currentHealthScore: Double = 100.0
    @Published var recentIssues: [MonitoringIssue] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var performanceTimer: Timer?
    private var healthCheckTimer: Timer?
    
    // MARK: - Performance Metrics
    private var performanceMetrics = PerformanceMetrics()
    private let performanceQueue = DispatchQueue(label: "com.elaforkids.performance", qos: .utility)
    
    // MARK: - Initialization
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring the application
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Start performance monitoring
        startPerformanceMonitoring()
        
        // Start health checks
        startHealthChecks()
        
        // Monitor app lifecycle
        setupAppLifecycleMonitoring()
        
        // Monitor memory warnings
        setupMemoryWarningMonitoring()
        
        loggingService.logInfo("Monitoring started", category: .general)
        logger.info("Application monitoring started")
    }
    
    /// Stop monitoring the application
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        
        // Stop timers
        performanceTimer?.invalidate()
        healthCheckTimer?.invalidate()
        
        // Cancel subscriptions
        cancellables.removeAll()
        
        loggingService.logInfo("Monitoring stopped", category: .general)
        logger.info("Application monitoring stopped")
    }
    
    /// Record a custom event
    func recordEvent(_ event: String, category: String, parameters: [String: Any]? = nil) {
        loggingService.logAnalyticsEvent(event, parameters: parameters)
        
        // Check if this is a critical event
        if category.lowercased().contains("error") || category.lowercased().contains("crash") {
            let issue = MonitoringIssue(
                type: .error,
                message: event,
                timestamp: Date(),
                severity: .medium,
                context: parameters
            )
            addIssue(issue)
        }
    }
    
    /// Record a performance metric
    func recordPerformance(_ metric: String, value: Double, unit: String) {
        loggingService.logPerformance(metric, value: value, unit: unit)
        
        performanceQueue.async { [weak self] in
            self?.updatePerformanceMetrics(metric: metric, value: value)
        }
    }
    
    /// Record a user interaction
    func recordUserInteraction(_ action: String, screen: String, context: [String: Any]? = nil) {
        loggingService.logUserInteraction(action, screen: screen, context: context)
        
        // Track user engagement
        performanceMetrics.userInteractions += 1
        performanceMetrics.lastInteractionTime = Date()
    }
    
    /// Get current app health status
    func getHealthStatus() -> AppHealthStatus {
        let crashMetrics = crashReportingService.getAppHealthMetrics()
        
        return AppHealthStatus(
            healthScore: crashMetrics.healthScore,
            status: crashMetrics.healthStatus,
            memoryUsage: crashMetrics.memoryUsage,
            cpuUsage: crashMetrics.cpuUsage,
            errorCount: crashMetrics.recentErrors,
            criticalErrorCount: crashMetrics.criticalErrors,
            lastIssueDate: recentIssues.first?.timestamp,
            uptime: getAppUptime()
        )
    }
    
    /// Get performance summary
    func getPerformanceSummary() -> PerformanceSummary {
        return PerformanceSummary(
            averageMemoryUsage: performanceMetrics.averageMemoryUsage,
            peakMemoryUsage: performanceMetrics.peakMemoryUsage,
            averageResponseTime: performanceMetrics.averageResponseTime,
            userInteractions: performanceMetrics.userInteractions,
            sessionDuration: Date().timeIntervalSince(performanceMetrics.sessionStartTime),
            crashCount: crashReportingService.getCrashReports().filter { $0.isFatal }.count,
            errorCount: recentIssues.filter { $0.type == .error }.count
        )
    }
    
    /// Export monitoring data for support
    func exportMonitoringData() -> URL? {
        let exportData = MonitoringExportData(
            healthStatus: getHealthStatus(),
            performanceSummary: getPerformanceSummary(),
            recentIssues: recentIssues,
            crashReports: crashReportingService.getCrashReports(),
            logs: loggingService.getRecentLogs(limit: 500),
            exportDate: Date()
        )
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("monitoring-export-\(Date().timeIntervalSince1970).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(exportData)
            try data.write(to: exportURL)
            
            logger.info("Monitoring data exported to: \(exportURL.path)")
            return exportURL
        } catch {
            logger.error("Failed to export monitoring data: \(error.localizedDescription)")
            crashReportingService.recordError("Failed to export monitoring data", context: ["error": error.localizedDescription])
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMonitoring() {
        // Initialize performance metrics
        performanceMetrics.sessionStartTime = Date()
        
        // Start monitoring automatically
        startMonitoring()
    }
    
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.collectPerformanceMetrics()
        }
    }
    
    private func startHealthChecks() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    private func setupAppLifecycleMonitoring() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.loggingService.logInfo("App became active", category: .general)
                self?.performanceMetrics.activationCount += 1
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.loggingService.logInfo("App entered background", category: .general)
                self?.performanceMetrics.backgroundCount += 1
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.loggingService.logInfo("App will terminate", category: .general)
                self?.stopMonitoring()
            }
            .store(in: &cancellables)
    }
    
    private func setupMemoryWarningMonitoring() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                let memoryUsage = self?.getCurrentMemoryUsage() ?? 0
                self?.loggingService.logWarning("Memory warning received", category: .performance, context: [
                    "memory_usage_mb": memoryUsage
                ])
                
                let issue = MonitoringIssue(
                    type: .performance,
                    message: "Memory warning - usage: \(String(format: "%.1f", memoryUsage))MB",
                    timestamp: Date(),
                    severity: .high,
                    context: ["memory_usage_mb": memoryUsage]
                )
                self?.addIssue(issue)
            }
            .store(in: &cancellables)
    }
    
    private func collectPerformanceMetrics() {
        performanceQueue.async { [weak self] in
            guard let self = self else { return }
            
            let memoryUsage = self.getCurrentMemoryUsage()
            let cpuUsage = self.getCurrentCPUUsage()
            
            // Update metrics
            self.performanceMetrics.memoryReadings.append(memoryUsage)
            self.performanceMetrics.cpuReadings.append(cpuUsage)
            
            // Keep only recent readings (last 100)
            if self.performanceMetrics.memoryReadings.count > 100 {
                self.performanceMetrics.memoryReadings.removeFirst()
            }
            if self.performanceMetrics.cpuReadings.count > 100 {
                self.performanceMetrics.cpuReadings.removeFirst()
            }
            
            // Update calculated metrics
            self.performanceMetrics.averageMemoryUsage = self.performanceMetrics.memoryReadings.reduce(0, +) / Double(self.performanceMetrics.memoryReadings.count)
            self.performanceMetrics.peakMemoryUsage = self.performanceMetrics.memoryReadings.max() ?? 0
            
            // Log performance if concerning
            if memoryUsage > 150 { // Over 150MB
                self.loggingService.logWarning("High memory usage detected", category: .performance, context: [
                    "memory_usage_mb": memoryUsage,
                    "peak_memory_mb": self.performanceMetrics.peakMemoryUsage
                ])
            }
            
            if cpuUsage > 80 { // Over 80% CPU
                self.loggingService.logWarning("High CPU usage detected", category: .performance, context: [
                    "cpu_usage_percent": cpuUsage
                ])
            }
        }
    }
    
    private func performHealthCheck() {
        let healthMetrics = crashReportingService.getAppHealthMetrics()
        
        DispatchQueue.main.async { [weak self] in
            self?.currentHealthScore = healthMetrics.healthScore
            
            // Check for health issues
            if healthMetrics.healthScore < 70 {
                let issue = MonitoringIssue(
                    type: .health,
                    message: "App health score dropped to \(String(format: "%.1f", healthMetrics.healthScore))",
                    timestamp: Date(),
                    severity: healthMetrics.healthScore < 50 ? .high : .medium,
                    context: [
                        "health_score": healthMetrics.healthScore,
                        "recent_errors": healthMetrics.recentErrors,
                        "critical_errors": healthMetrics.criticalErrors
                    ]
                )
                self?.addIssue(issue)
            }
        }
    }
    
    private func addIssue(_ issue: MonitoringIssue) {
        DispatchQueue.main.async { [weak self] in
            self?.recentIssues.insert(issue, at: 0)
            
            // Keep only recent issues (last 50)
            if let issues = self?.recentIssues, issues.count > 50 {
                self?.recentIssues = Array(issues.prefix(50))
            }
            
            // Log the issue
            switch issue.severity {
            case .low:
                self?.loggingService.logInfo("Monitoring issue: \(issue.message)", category: .general, context: issue.context)
            case .medium:
                self?.loggingService.logWarning("Monitoring issue: \(issue.message)", category: .general, context: issue.context)
            case .high:
                self?.loggingService.logError("Monitoring issue: \(issue.message)", category: .general, context: issue.context)
            }
        }
    }
    
    private func updatePerformanceMetrics(metric: String, value: Double) {
        switch metric.lowercased() {
        case "response_time":
            performanceMetrics.responseTimeReadings.append(value)
            if performanceMetrics.responseTimeReadings.count > 100 {
                performanceMetrics.responseTimeReadings.removeFirst()
            }
            performanceMetrics.averageResponseTime = performanceMetrics.responseTimeReadings.reduce(0, +) / Double(performanceMetrics.responseTimeReadings.count)
            
        case "speech_recognition_time":
            if value > 5000 { // Over 5 seconds
                let issue = MonitoringIssue(
                    type: .performance,
                    message: "Slow speech recognition: \(String(format: "%.1f", value))ms",
                    timestamp: Date(),
                    severity: .medium,
                    context: ["recognition_time_ms": value]
                )
                addIssue(issue)
            }
            
        case "handwriting_recognition_time":
            if value > 3000 { // Over 3 seconds
                let issue = MonitoringIssue(
                    type: .performance,
                    message: "Slow handwriting recognition: \(String(format: "%.1f", value))ms",
                    timestamp: Date(),
                    severity: .medium,
                    context: ["recognition_time_ms": value]
                )
                addIssue(issue)
            }
            
        default:
            break
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
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
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        } else {
            return 0.0
        }
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = processor_info_array_t.allocate(capacity: 1)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &info, &numCpuInfo)
        
        if result == KERN_SUCCESS {
            // This is a simplified CPU calculation
            // In a real implementation, you'd want more accurate CPU usage calculation
            return Double.random(in: 0...100) // Placeholder
        }
        
        return 0.0
    }
    
    private func getAppUptime() -> TimeInterval {
        return Date().timeIntervalSince(performanceMetrics.sessionStartTime)
    }
}

// MARK: - Supporting Models

struct MonitoringIssue: Codable, Identifiable {
    let id = UUID()
    let type: IssueType
    let message: String
    let timestamp: Date
    let severity: IssueSeverity
    let context: [String: AnyCodable]?
    
    init(type: IssueType, message: String, timestamp: Date, severity: IssueSeverity, context: [String: Any]? = nil) {
        self.type = type
        self.message = message
        self.timestamp = timestamp
        self.severity = severity
        self.context = context?.mapValues { AnyCodable($0) }
    }
    
    enum IssueType: String, Codable, CaseIterable {
        case error = "error"
        case performance = "performance"
        case health = "health"
        case network = "network"
        case storage = "storage"
        case ui = "ui"
    }
    
    enum IssueSeverity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}

struct AppHealthStatus: Codable {
    let healthScore: Double
    let status: String
    let memoryUsage: Double
    let cpuUsage: Double
    let errorCount: Int
    let criticalErrorCount: Int
    let lastIssueDate: Date?
    let uptime: TimeInterval
}

struct PerformanceSummary: Codable {
    let averageMemoryUsage: Double
    let peakMemoryUsage: Double
    let averageResponseTime: Double
    let userInteractions: Int
    let sessionDuration: TimeInterval
    let crashCount: Int
    let errorCount: Int
}

class PerformanceMetrics {
    var sessionStartTime = Date()
    var memoryReadings: [Double] = []
    var cpuReadings: [Double] = []
    var responseTimeReadings: [Double] = []
    var userInteractions = 0
    var activationCount = 0
    var backgroundCount = 0
    var lastInteractionTime: Date?
    
    var averageMemoryUsage: Double = 0
    var peakMemoryUsage: Double = 0
    var averageResponseTime: Double = 0
}

struct MonitoringExportData: Codable {
    let healthStatus: AppHealthStatus
    let performanceSummary: PerformanceSummary
    let recentIssues: [MonitoringIssue]
    let crashReports: [ErrorReport]
    let logs: [LogEntry]
    let exportDate: Date
}