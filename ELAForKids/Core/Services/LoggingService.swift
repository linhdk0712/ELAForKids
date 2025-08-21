import Foundation
import os.log
import Combine

// MARK: - Logging Service
final class LoggingService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = LoggingService()
    
    // MARK: - Properties
    private let subsystem = "com.elaforkids.app"
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10MB
    private let maxLogFiles = 5
    private let logQueue = DispatchQueue(label: "com.elaforkids.logging", qos: .utility)
    
    // MARK: - Loggers
    private let generalLogger = Logger(subsystem: "com.elaforkids.app", category: "General")
    private let speechLogger = Logger(subsystem: "com.elaforkids.app", category: "Speech")
    private let audioLogger = Logger(subsystem: "com.elaforkids.app", category: "Audio")
    private let networkLogger = Logger(subsystem: "com.elaforkids.app", category: "Network")
    private let storageLogger = Logger(subsystem: "com.elaforkids.app", category: "Storage")
    private let uiLogger = Logger(subsystem: "com.elaforkids.app", category: "UI")
    private let performanceLogger = Logger(subsystem: "com.elaforkids.app", category: "Performance")
    private let analyticsLogger = Logger(subsystem: "com.elaforkids.app", category: "Analytics")
    private let privacyLogger = Logger(subsystem: "com.elaforkids.app", category: "Privacy")
    
    // MARK: - File Logging
    private var logFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Logs")
    }
    
    private var currentLogFile: URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        return logFileURL.appendingPathComponent("ela-\(dateString).log")
    }
    
    // MARK: - Initialization
    private init() {
        setupLogDirectory()
        cleanupOldLogs()
        logAppStart()
    }
    
    // MARK: - Public Logging Methods
    
    /// Log general application events
    func logInfo(_ message: String, category: LogCategory = .general, context: [String: Any]? = nil) {
        log(message, level: .info, category: category, context: context)
    }
    
    /// Log warnings that don't affect functionality
    func logWarning(_ message: String, category: LogCategory = .general, context: [String: Any]? = nil) {
        log(message, level: .warning, category: category, context: context)
    }
    
    /// Log errors that affect functionality
    func logError(_ message: String, category: LogCategory = .general, error: Error? = nil, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        if let error = error {
            fullContext["error"] = error.localizedDescription
            fullContext["error_type"] = String(describing: type(of: error))
        }
        log(message, level: .error, category: category, context: fullContext)
    }
    
    /// Log critical errors that may cause crashes
    func logCritical(_ message: String, category: LogCategory = .general, error: Error? = nil, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        if let error = error {
            fullContext["error"] = error.localizedDescription
            fullContext["error_type"] = String(describing: type(of: error))
        }
        log(message, level: .critical, category: category, context: fullContext)
    }
    
    /// Log user interactions (privacy-safe)
    func logUserInteraction(_ action: String, screen: String, context: [String: Any]? = nil) {
        var safeContext = sanitizeUserContext(context)
        safeContext["screen"] = screen
        safeContext["action"] = action
        safeContext["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        log("User interaction: \(action)", level: .info, category: .ui, context: safeContext)
    }
    
    /// Log performance metrics
    func logPerformance(_ metric: String, value: Double, unit: String, context: [String: Any]? = nil) {
        var perfContext = context ?? [:]
        perfContext["metric"] = metric
        perfContext["value"] = value
        perfContext["unit"] = unit
        perfContext["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        log("Performance: \(metric) = \(value) \(unit)", level: .info, category: .performance, context: perfContext)
    }
    
    /// Log speech recognition events
    func logSpeechEvent(_ event: String, accuracy: Float? = nil, duration: TimeInterval? = nil, context: [String: Any]? = nil) {
        var speechContext = context ?? [:]
        if let accuracy = accuracy {
            speechContext["accuracy"] = accuracy
        }
        if let duration = duration {
            speechContext["duration"] = duration
        }
        speechContext["event"] = event
        
        log("Speech: \(event)", level: .info, category: .speech, context: speechContext)
    }
    
    /// Log audio events
    func logAudioEvent(_ event: String, context: [String: Any]? = nil) {
        var audioContext = context ?? [:]
        audioContext["event"] = event
        
        log("Audio: \(event)", level: .info, category: .audio, context: audioContext)
    }
    
    /// Log network events
    func logNetworkEvent(_ event: String, url: String? = nil, statusCode: Int? = nil, duration: TimeInterval? = nil, context: [String: Any]? = nil) {
        var networkContext = context ?? [:]
        networkContext["event"] = event
        if let url = url {
            networkContext["url"] = sanitizeURL(url)
        }
        if let statusCode = statusCode {
            networkContext["status_code"] = statusCode
        }
        if let duration = duration {
            networkContext["duration"] = duration
        }
        
        log("Network: \(event)", level: .info, category: .network, context: networkContext)
    }
    
    /// Log storage events
    func logStorageEvent(_ event: String, operation: String? = nil, size: Int64? = nil, context: [String: Any]? = nil) {
        var storageContext = context ?? [:]
        storageContext["event"] = event
        if let operation = operation {
            storageContext["operation"] = operation
        }
        if let size = size {
            storageContext["size_bytes"] = size
        }
        
        log("Storage: \(event)", level: .info, category: .storage, context: storageContext)
    }
    
    /// Log analytics events (privacy-safe)
    func logAnalyticsEvent(_ event: String, parameters: [String: Any]? = nil) {
        let safeParameters = sanitizeAnalyticsParameters(parameters)
        log("Analytics: \(event)", level: .info, category: .analytics, context: safeParameters)
    }
    
    // MARK: - Log Retrieval
    
    /// Get recent logs for debugging
    func getRecentLogs(limit: Int = 100) -> [LogEntry] {
        return getLogsFromFile(limit: limit)
    }
    
    /// Get logs for a specific date range
    func getLogs(from startDate: Date, to endDate: Date) -> [LogEntry] {
        return getLogsFromFile(from: startDate, to: endDate)
    }
    
    /// Get logs by category
    func getLogs(category: LogCategory, limit: Int = 100) -> [LogEntry] {
        return getLogsFromFile(limit: limit).filter { $0.category == category }
    }
    
    /// Get logs by level
    func getLogs(level: LogLevel, limit: Int = 100) -> [LogEntry] {
        return getLogsFromFile(limit: limit).filter { $0.level == level }
    }
    
    /// Export logs for support
    func exportLogs() -> URL? {
        let exportURL = logFileURL.appendingPathComponent("export-\(Date().timeIntervalSince1970).log")
        
        do {
            let allLogs = getRecentLogs(limit: 1000)
            let logContent = allLogs.map { $0.formattedString }.joined(separator: "\n")
            try logContent.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            logError("Failed to export logs", error: error)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func log(_ message: String, level: LogLevel, category: LogCategory, context: [String: Any]? = nil) {
        let logEntry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            context: context
        )
        
        // Log to system logger
        logToSystem(logEntry)
        
        // Log to file
        logToFile(logEntry)
        
        // Send to crash reporting if critical
        if level == .critical {
            CrashReportingService.shared.recordError(message, context: context)
        }
    }
    
    private func logToSystem(_ entry: LogEntry) {
        let logger = getSystemLogger(for: entry.category)
        let contextString = entry.contextString
        let fullMessage = contextString.isEmpty ? entry.message : "\(entry.message) | \(contextString)"
        
        switch entry.level {
        case .info:
            logger.info("\(fullMessage)")
        case .warning:
            logger.notice("\(fullMessage)")
        case .error:
            logger.error("\(fullMessage)")
        case .critical:
            logger.fault("\(fullMessage)")
        }
    }
    
    private func logToFile(_ entry: LogEntry) {
        logQueue.async { [weak self] in
            self?.writeToFile(entry)
        }
    }
    
    private func writeToFile(_ entry: LogEntry) {
        do {
            let logString = entry.formattedString + "\n"
            let data = logString.data(using: .utf8) ?? Data()
            
            if FileManager.default.fileExists(atPath: currentLogFile.path) {
                let fileHandle = try FileHandle(forWritingTo: currentLogFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try data.write(to: currentLogFile)
            }
            
            // Check file size and rotate if needed
            rotateLogFileIfNeeded()
        } catch {
            generalLogger.error("Failed to write to log file: \(error.localizedDescription)")
        }
    }
    
    private func getSystemLogger(for category: LogCategory) -> Logger {
        switch category {
        case .general:
            return generalLogger
        case .speech:
            return speechLogger
        case .audio:
            return audioLogger
        case .network:
            return networkLogger
        case .storage:
            return storageLogger
        case .ui:
            return uiLogger
        case .performance:
            return performanceLogger
        case .analytics:
            return analyticsLogger
        case .privacy:
            return privacyLogger
        }
    }
    
    private func setupLogDirectory() {
        do {
            try FileManager.default.createDirectory(at: logFileURL, withIntermediateDirectories: true)
        } catch {
            generalLogger.error("Failed to create log directory: \(error.localizedDescription)")
        }
    }
    
    private func cleanupOldLogs() {
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(at: logFileURL, includingPropertiesForKeys: [.creationDateKey])
            let sortedFiles = logFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // Keep only the most recent files
            if sortedFiles.count > maxLogFiles {
                let filesToDelete = Array(sortedFiles.dropFirst(maxLogFiles))
                for file in filesToDelete {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            generalLogger.error("Failed to cleanup old logs: \(error.localizedDescription)")
        }
    }
    
    private func rotateLogFileIfNeeded() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: currentLogFile.path)
            if let fileSize = attributes[.size] as? Int64, fileSize > maxLogFileSize {
                let rotatedFile = logFileURL.appendingPathComponent("ela-\(Date().timeIntervalSince1970).log")
                try FileManager.default.moveItem(at: currentLogFile, to: rotatedFile)
                cleanupOldLogs()
            }
        } catch {
            generalLogger.error("Failed to rotate log file: \(error.localizedDescription)")
        }
    }
    
    private func getLogsFromFile(limit: Int = 100) -> [LogEntry] {
        do {
            let logContent = try String(contentsOf: currentLogFile, encoding: .utf8)
            let lines = logContent.components(separatedBy: .newlines)
            let recentLines = Array(lines.suffix(limit))
            
            return recentLines.compactMap { line in
                LogEntry.fromString(line)
            }
        } catch {
            return []
        }
    }
    
    private func getLogsFromFile(from startDate: Date, to endDate: Date) -> [LogEntry] {
        let allLogs = getLogsFromFile(limit: 10000)
        return allLogs.filter { log in
            log.timestamp >= startDate && log.timestamp <= endDate
        }
    }
    
    private func logAppStart() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        logInfo("App started", context: [
            "app_version": appVersion,
            "build_number": buildNumber,
            "device_model": deviceModel,
            "system_version": systemVersion,
            "launch_time": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    // MARK: - Privacy Methods
    
    private func sanitizeUserContext(_ context: [String: Any]?) -> [String: Any] {
        guard let context = context else { return [:] }
        
        var sanitized: [String: Any] = [:]
        
        for (key, value) in context {
            // Remove potentially sensitive data
            let lowerKey = key.lowercased()
            if lowerKey.contains("name") || lowerKey.contains("email") || lowerKey.contains("phone") || lowerKey.contains("address") {
                sanitized[key] = "[REDACTED]"
            } else if let stringValue = value as? String, stringValue.count > 100 {
                // Truncate long strings that might contain sensitive data
                sanitized[key] = String(stringValue.prefix(100)) + "..."
            } else {
                sanitized[key] = value
            }
        }
        
        return sanitized
    }
    
    private func sanitizeAnalyticsParameters(_ parameters: [String: Any]?) -> [String: Any] {
        guard let parameters = parameters else { return [:] }
        
        var sanitized: [String: Any] = [:]
        
        for (key, value) in parameters {
            // Only allow specific analytics parameters
            let allowedKeys = ["event_type", "screen_name", "action", "category", "duration", "count", "level", "score"]
            if allowedKeys.contains(key.lowercased()) {
                sanitized[key] = value
            }
        }
        
        return sanitized
    }
    
    private func sanitizeURL(_ url: String) -> String {
        // Remove query parameters and sensitive path components
        guard let urlComponents = URLComponents(string: url) else { return url }
        
        var sanitizedComponents = urlComponents
        sanitizedComponents.query = nil
        sanitizedComponents.fragment = nil
        
        return sanitizedComponents.string ?? url
    }
}

// MARK: - Log Models

enum LogLevel: String, CaseIterable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var emoji: String {
        switch self {
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🔥"
        }
    }
}

enum LogCategory: String, CaseIterable {
    case general = "GENERAL"
    case speech = "SPEECH"
    case audio = "AUDIO"
    case network = "NETWORK"
    case storage = "STORAGE"
    case ui = "UI"
    case performance = "PERFORMANCE"
    case analytics = "ANALYTICS"
    case privacy = "PRIVACY"
}

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let context: [String: Any]?
    
    var contextString: String {
        guard let context = context, !context.isEmpty else { return "" }
        
        let contextPairs = context.map { key, value in
            "\(key)=\(value)"
        }
        
        return contextPairs.joined(separator: ", ")
    }
    
    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestampString = formatter.string(from: timestamp)
        
        let contextPart = contextString.isEmpty ? "" : " | \(contextString)"
        return "[\(timestampString)] \(level.emoji) \(category.rawValue): \(message)\(contextPart)"
    }
    
    static func fromString(_ string: String) -> LogEntry? {
        // Parse log entry from string format
        // This is a simplified parser - in production, you might want a more robust one
        let components = string.components(separatedBy: "] ")
        guard components.count >= 2 else { return nil }
        
        let timestampPart = String(components[0].dropFirst()) // Remove leading [
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        guard let timestamp = formatter.date(from: timestampPart) else { return nil }
        
        let remainingPart = components[1]
        let parts = remainingPart.components(separatedBy: ": ")
        guard parts.count >= 2 else { return nil }
        
        let levelCategoryPart = parts[0]
        let messagePart = parts[1]
        
        // Extract level and category (simplified)
        let levelCategory = levelCategoryPart.components(separatedBy: " ")
        guard levelCategory.count >= 2 else { return nil }
        
        let levelString = String(levelCategory[1])
        let categoryString = String(levelCategory[2])
        
        guard let level = LogLevel(rawValue: levelString),
              let category = LogCategory(rawValue: categoryString) else { return nil }
        
        return LogEntry(
            timestamp: timestamp,
            level: level,
            category: category,
            message: messagePart,
            context: nil
        )
    }
}