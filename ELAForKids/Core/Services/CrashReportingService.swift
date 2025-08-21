import Foundation
import os.log
import UIKit

// MARK: - Crash Reporting Service
final class CrashReportingService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CrashReportingService()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.elaforkids.app", category: "CrashReporting")
    private let crashQueue = DispatchQueue(label: "com.elaforkids.crashreporting", qos: .utility)
    private let maxCrashReports = 10
    private let isChildApp = true // This is a children's app, so we need extra privacy protection
    
    // MARK: - File URLs
    private var crashReportsURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("CrashReports")
    }
    
    // MARK: - Initialization
    private init() {
        setupCrashReporting()
        setupCrashReportsDirectory()
        cleanupOldCrashReports()
    }
    
    // MARK: - Public Methods
    
    /// Record a non-fatal error
    func recordError(_ message: String, context: [String: Any]? = nil) {
        let errorReport = ErrorReport(
            message: message,
            context: sanitizeContext(context),
            timestamp: Date(),
            isFatal: false
        )
        
        saveCrashReport(errorReport)
        logger.error("Non-fatal error recorded: \(message)")
    }
    
    /// Record a critical error that might lead to a crash
    func recordCriticalError(_ message: String, error: Error? = nil, context: [String: Any]? = nil) {
        var fullContext = sanitizeContext(context) ?? [:]
        
        if let error = error {
            fullContext["error_description"] = error.localizedDescription
            fullContext["error_type"] = String(describing: type(of: error))
            
            if let nsError = error as? NSError {
                fullContext["error_domain"] = nsError.domain
                fullContext["error_code"] = nsError.code
            }
        }
        
        let errorReport = ErrorReport(
            message: message,
            context: fullContext,
            timestamp: Date(),
            isFatal: false
        )
        
        saveCrashReport(errorReport)
        logger.fault("Critical error recorded: \(message)")
        
        // Also log to system for immediate visibility
        LoggingService.shared.logCritical(message, error: error, context: context)
    }
    
    /// Record app performance issues
    func recordPerformanceIssue(_ issue: String, metrics: [String: Any]? = nil) {
        var context = sanitizeContext(metrics) ?? [:]
        context["issue_type"] = "performance"
        context["memory_usage"] = getMemoryUsage()
        context["cpu_usage"] = getCPUUsage()
        
        let performanceReport = ErrorReport(
            message: "Performance issue: \(issue)",
            context: context,
            timestamp: Date(),
            isFatal: false
        )
        
        saveCrashReport(performanceReport)
        logger.notice("Performance issue recorded: \(issue)")
    }
    
    /// Record user experience issues
    func recordUXIssue(_ issue: String, screen: String, context: [String: Any]? = nil) {
        var uxContext = sanitizeContext(context) ?? [:]
        uxContext["issue_type"] = "user_experience"
        uxContext["screen"] = screen
        uxContext["device_model"] = UIDevice.current.model
        uxContext["system_version"] = UIDevice.current.systemVersion
        
        let uxReport = ErrorReport(
            message: "UX issue: \(issue)",
            context: uxContext,
            timestamp: Date(),
            isFatal: false
        )
        
        saveCrashReport(uxReport)
        logger.info("UX issue recorded: \(issue)")
    }
    
    /// Get crash reports for debugging
    func getCrashReports() -> [ErrorReport] {
        do {
            let reportFiles = try FileManager.default.contentsOfDirectory(at: crashReportsURL, includingPropertiesForKeys: [.creationDateKey])
            
            var reports: [ErrorReport] = []
            for file in reportFiles {
                if let report = loadCrashReport(from: file) {
                    reports.append(report)
                }
            }
            
            return reports.sorted { $0.timestamp > $1.timestamp }
        } catch {
            logger.error("Failed to get crash reports: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Export crash reports for support
    func exportCrashReports() -> URL? {
        let reports = getCrashReports()
        guard !reports.isEmpty else { return nil }
        
        let exportURL = crashReportsURL.appendingPathComponent("crash-export-\(Date().timeIntervalSince1970).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(reports)
            try data.write(to: exportURL)
            
            logger.info("Crash reports exported to: \(exportURL.path)")
            return exportURL
        } catch {
            logger.error("Failed to export crash reports: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear all crash reports
    func clearCrashReports() {
        do {
            let reportFiles = try FileManager.default.contentsOfDirectory(at: crashReportsURL, includingPropertiesForKeys: nil)
            
            for file in reportFiles {
                try FileManager.default.removeItem(at: file)
            }
            
            logger.info("All crash reports cleared")
        } catch {
            logger.error("Failed to clear crash reports: \(error.localizedDescription)")
        }
    }
    
    /// Get app health metrics
    func getAppHealthMetrics() -> AppHealthMetrics {
        let reports = getCrashReports()
        let recentReports = reports.filter { $0.timestamp > Date().addingTimeInterval(-7 * 24 * 60 * 60) } // Last 7 days
        
        let errorsByCategory = Dictionary(grouping: recentReports) { report in
            report.context?["category"] as? String ?? "unknown"
        }
        
        let criticalErrors = recentReports.filter { report in
            report.message.lowercased().contains("critical") || report.isFatal
        }
        
        return AppHealthMetrics(
            totalErrors: reports.count,
            recentErrors: recentReports.count,
            criticalErrors: criticalErrors.count,
            errorsByCategory: errorsByCategory.mapValues { $0.count },
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage(),
            lastCrashDate: reports.first?.timestamp
        )
    }
    
    // MARK: - Private Methods
    
    private func setupCrashReporting() {
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingService.shared.handleUncaughtException(exception)
        }
        
        // Set up signal handler for crashes
        signal(SIGABRT) { signal in
            CrashReportingService.shared.handleSignal(signal, name: "SIGABRT")
        }
        
        signal(SIGILL) { signal in
            CrashReportingService.shared.handleSignal(signal, name: "SIGILL")
        }
        
        signal(SIGSEGV) { signal in
            CrashReportingService.shared.handleSignal(signal, name: "SIGSEGV")
        }
        
        signal(SIGFPE) { signal in
            CrashReportingService.shared.handleSignal(signal, name: "SIGFPE")
        }
        
        signal(SIGBUS) { signal in
            CrashReportingService.shared.handleSignal(signal, name: "SIGBUS")
        }
        
        signal(SIGPIPE) { signal in
            CrashReportingService.shared.handleSignal(signal, name: "SIGPIPE")
        }
    }
    
    private func handleUncaughtException(_ exception: NSException) {
        let crashReport = ErrorReport(
            message: "Uncaught exception: \(exception.name.rawValue) - \(exception.reason ?? "No reason")",
            context: [
                "exception_name": exception.name.rawValue,
                "exception_reason": exception.reason ?? "No reason",
                "call_stack": exception.callStackSymbols,
                "crash_type": "uncaught_exception"
            ],
            timestamp: Date(),
            isFatal: true
        )
        
        saveCrashReportSync(crashReport)
        
        // Log to system immediately
        logger.fault("CRASH: Uncaught exception - \(exception.name.rawValue)")
    }
    
    private func handleSignal(_ signal: Int32, name: String) {
        let crashReport = ErrorReport(
            message: "Signal crash: \(name) (\(signal))",
            context: [
                "signal_name": name,
                "signal_number": signal,
                "crash_type": "signal"
            ],
            timestamp: Date(),
            isFatal: true
        )
        
        saveCrashReportSync(crashReport)
        
        // Log to system immediately
        logger.fault("CRASH: Signal \(name) (\(signal))")
        
        // Re-raise the signal to allow system to handle it
        signal(signal, SIG_DFL)
        raise(signal)
    }
    
    private func setupCrashReportsDirectory() {
        do {
            try FileManager.default.createDirectory(at: crashReportsURL, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create crash reports directory: \(error.localizedDescription)")
        }
    }
    
    private func cleanupOldCrashReports() {
        do {
            let reportFiles = try FileManager.default.contentsOfDirectory(at: crashReportsURL, includingPropertiesForKeys: [.creationDateKey])
            
            let sortedFiles = reportFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // Keep only the most recent crash reports
            if sortedFiles.count > maxCrashReports {
                let filesToDelete = Array(sortedFiles.dropFirst(maxCrashReports))
                for file in filesToDelete {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            logger.error("Failed to cleanup old crash reports: \(error.localizedDescription)")
        }
    }
    
    private func saveCrashReport(_ report: ErrorReport) {
        crashQueue.async { [weak self] in
            self?.saveCrashReportSync(report)
        }
    }
    
    private func saveCrashReportSync(_ report: ErrorReport) {
        let filename = "crash-\(report.timestamp.timeIntervalSince1970).json"
        let fileURL = crashReportsURL.appendingPathComponent(filename)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(report)
            try data.write(to: fileURL)
            
            logger.info("Crash report saved: \(filename)")
        } catch {
            logger.error("Failed to save crash report: \(error.localizedDescription)")
        }
    }
    
    private func loadCrashReport(from url: URL) -> ErrorReport? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(ErrorReport.self, from: data)
        } catch {
            logger.error("Failed to load crash report from \(url.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func sanitizeContext(_ context: [String: Any]?) -> [String: Any]? {
        guard let context = context else { return nil }
        
        var sanitized: [String: Any] = [:]
        
        for (key, value) in context {
            let lowerKey = key.lowercased()
            
            // Remove potentially sensitive data for children's privacy
            if lowerKey.contains("name") || 
               lowerKey.contains("email") || 
               lowerKey.contains("phone") || 
               lowerKey.contains("address") ||
               lowerKey.contains("user") ||
               lowerKey.contains("child") ||
               lowerKey.contains("student") {
                sanitized[key] = "[REDACTED_FOR_PRIVACY]"
            } else if let stringValue = value as? String {
                // Truncate long strings that might contain sensitive data
                if stringValue.count > 200 {
                    sanitized[key] = String(stringValue.prefix(200)) + "...[TRUNCATED]"
                } else {
                    sanitized[key] = stringValue
                }
            } else {
                sanitized[key] = value
            }
        }
        
        // Add device info (non-sensitive)
        sanitized["device_model"] = UIDevice.current.model
        sanitized["system_version"] = UIDevice.current.systemVersion
        sanitized["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        sanitized["build_number"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        return sanitized
    }
    
    private func getMemoryUsage() -> Double {
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
    
    private func getCPUUsage() -> Double {
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
            return Double(info.virtual_size) / 1024.0 / 1024.0 // MB
        } else {
            return 0.0
        }
    }
}

// MARK: - Error Report Model
struct ErrorReport: Codable {
    let id: String
    let message: String
    let context: [String: AnyCodable]?
    let timestamp: Date
    let isFatal: Bool
    
    init(message: String, context: [String: Any]? = nil, timestamp: Date, isFatal: Bool) {
        self.id = UUID().uuidString
        self.message = message
        self.context = context?.mapValues { AnyCodable($0) }
        self.timestamp = timestamp
        self.isFatal = isFatal
    }
}

// MARK: - App Health Metrics
struct AppHealthMetrics {
    let totalErrors: Int
    let recentErrors: Int
    let criticalErrors: Int
    let errorsByCategory: [String: Int]
    let memoryUsage: Double
    let cpuUsage: Double
    let lastCrashDate: Date?
    
    var healthScore: Double {
        // Calculate a health score from 0-100
        var score = 100.0
        
        // Deduct points for recent errors
        score -= Double(recentErrors) * 2.0
        
        // Deduct more points for critical errors
        score -= Double(criticalErrors) * 5.0
        
        // Deduct points for high memory usage (over 100MB)
        if memoryUsage > 100 {
            score -= (memoryUsage - 100) * 0.1
        }
        
        // Deduct points for recent crashes
        if let lastCrash = lastCrashDate, lastCrash > Date().addingTimeInterval(-24 * 60 * 60) {
            score -= 20.0
        }
        
        return max(0, min(100, score))
    }
    
    var healthStatus: String {
        switch healthScore {
        case 90...100:
            return "Excellent"
        case 70..<90:
            return "Good"
        case 50..<70:
            return "Fair"
        case 30..<50:
            return "Poor"
        default:
            return "Critical"
        }
    }
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}