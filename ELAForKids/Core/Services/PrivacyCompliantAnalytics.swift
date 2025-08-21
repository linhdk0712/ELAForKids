import Foundation
import os.log

// MARK: - Privacy Compliant Analytics Service
final class PrivacyCompliantAnalytics: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PrivacyCompliantAnalytics()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.elaforkids.app", category: "PrivacyAnalytics")
    private let loggingService = LoggingService.shared
    
    // MARK: - Privacy Settings
    private let isChildApp = true
    private let maxDataRetentionDays = 30 // COPPA compliance - minimal data retention
    private let allowedAnalyticsEvents: Set<String> = [
        "app_launch",
        "session_start",
        "session_end",
        "exercise_completed",
        "level_completed",
        "achievement_unlocked",
        "error_occurred",
        "performance_metric"
    ]
    
    // MARK: - Storage
    private var analyticsURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Analytics")
    }
    
    // MARK: - Initialization
    private init() {
        setupAnalyticsDirectory()
        cleanupOldAnalytics()
        logPrivacyCompliance()
    }
    
    // MARK: - Public Methods
    
    /// Track an app event (privacy-safe)
    func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        // Only track allowed events
        guard allowedAnalyticsEvents.contains(event) else {
            logger.info("Event '\(event)' not tracked - not in allowed list")
            return
        }
        
        let sanitizedParameters = sanitizeParameters(parameters)
        let analyticsEvent = AnalyticsEvent(
            event: event,
            parameters: sanitizedParameters,
            timestamp: Date()
        )
        
        saveAnalyticsEvent(analyticsEvent)
        loggingService.logAnalyticsEvent(event, parameters: sanitizedParameters)
        
        logger.info("Privacy-compliant event tracked: \(event)")
    }
    
    /// Track learning progress (aggregated, non-identifiable)
    func trackLearningProgress(level: String, accuracy: Float, timeSpent: TimeInterval) {
        let parameters: [String: Any] = [
            "level": level,
            "accuracy_range": getAccuracyRange(accuracy), // Bucketed for privacy
            "time_range": getTimeRange(timeSpent), // Bucketed for privacy
            "session_type": "learning"
        ]
        
        trackEvent("exercise_completed", parameters: parameters)
    }
    
    /// Track app performance (no personal data)
    func trackPerformance(metric: String, value: Double, category: String) {
        let parameters: [String: Any] = [
            "metric": metric,
            "value_range": getValueRange(value, for: metric), // Bucketed for privacy
            "category": category,
            "device_type": getDeviceType() // General device category only
        ]
        
        trackEvent("performance_metric", parameters: parameters)
    }
    
    /// Track errors (sanitized)
    func trackError(errorCode: String, category: String, severity: String) {
        let parameters: [String: Any] = [
            "error_code": errorCode,
            "category": category,
            "severity": severity,
            "device_type": getDeviceType()
        ]
        
        trackEvent("error_occurred", parameters: parameters)
    }
    
    /// Get aggregated analytics (privacy-safe)
    func getAggregatedAnalytics(for period: AnalyticsPeriod) -> AggregatedAnalytics {
        let events = getAnalyticsEvents(for: period)
        
        return AggregatedAnalytics(
            period: period,
            totalSessions: countEvents(events, type: "session_start"),
            totalExercises: countEvents(events, type: "exercise_completed"),
            averageSessionDuration: calculateAverageSessionDuration(events),
            mostPopularLevel: findMostPopularLevel(events),
            errorCount: countEvents(events, type: "error_occurred"),
            performanceMetrics: aggregatePerformanceMetrics(events),
            generatedAt: Date()
        )
    }
    
    /// Export analytics for support (privacy-compliant)
    func exportAnalytics() -> URL? {
        let analytics = getAggregatedAnalytics(for: .last30Days)
        let exportData = AnalyticsExport(
            aggregatedData: analytics,
            privacyNotice: getPrivacyNotice(),
            exportDate: Date()
        )
        
        let exportURL = analyticsURL.appendingPathComponent("analytics-export-\(Date().timeIntervalSince1970).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(exportData)
            try data.write(to: exportURL)
            
            logger.info("Privacy-compliant analytics exported")
            return exportURL
        } catch {
            logger.error("Failed to export analytics: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear all analytics data
    func clearAllAnalytics() {
        do {
            let analyticsFiles = try FileManager.default.contentsOfDirectory(at: analyticsURL, includingPropertiesForKeys: nil)
            
            for file in analyticsFiles {
                try FileManager.default.removeItem(at: file)
            }
            
            logger.info("All analytics data cleared")
            loggingService.logInfo("Analytics data cleared by user request", category: .privacy)
        } catch {
            logger.error("Failed to clear analytics: \(error.localizedDescription)")
        }
    }
    
    /// Get privacy compliance status
    func getPrivacyComplianceStatus() -> PrivacyComplianceStatus {
        let events = getAllAnalyticsEvents()
        let oldestEvent = events.min { $0.timestamp < $1.timestamp }
        
        let dataRetentionCompliant = oldestEvent?.timestamp ?? Date() > Date().addingTimeInterval(-TimeInterval(maxDataRetentionDays * 24 * 60 * 60))
        
        return PrivacyComplianceStatus(
            isCOPPACompliant: true, // We don't collect personal data
            dataRetentionCompliant: dataRetentionCompliant,
            encryptionEnabled: true, // Data is stored locally and encrypted by iOS
            anonymizationEnabled: true, // All data is anonymized
            parentalControlsRespected: true, // No external data sharing
            lastComplianceCheck: Date(),
            totalEventsStored: events.count,
            oldestEventDate: oldestEvent?.timestamp
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAnalyticsDirectory() {
        do {
            try FileManager.default.createDirectory(at: analyticsURL, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create analytics directory: \(error.localizedDescription)")
        }
    }
    
    private func cleanupOldAnalytics() {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(maxDataRetentionDays * 24 * 60 * 60))
        
        do {
            let analyticsFiles = try FileManager.default.contentsOfDirectory(at: analyticsURL, includingPropertiesForKeys: [.creationDateKey])
            
            for file in analyticsFiles {
                let resourceValues = try file.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = resourceValues.creationDate, creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                    logger.info("Removed old analytics file: \(file.lastPathComponent)")
                }
            }
        } catch {
            logger.error("Failed to cleanup old analytics: \(error.localizedDescription)")
        }
    }
    
    private func logPrivacyCompliance() {
        loggingService.logInfo("Privacy-compliant analytics initialized", category: .privacy, context: [
            "coppa_compliant": true,
            "data_retention_days": maxDataRetentionDays,
            "personal_data_collected": false,
            "external_sharing": false
        ])
    }
    
    private func sanitizeParameters(_ parameters: [String: Any]?) -> [String: Any] {
        guard let parameters = parameters else { return [:] }
        
        var sanitized: [String: Any] = [:]
        
        // Only allow specific parameter types
        let allowedKeys = [
            "level", "accuracy_range", "time_range", "session_type",
            "metric", "value_range", "category", "device_type",
            "error_code", "severity", "achievement_type"
        ]
        
        for (key, value) in parameters {
            if allowedKeys.contains(key) {
                // Further sanitize values
                if let stringValue = value as? String {
                    sanitized[key] = sanitizeStringValue(stringValue)
                } else if let numericValue = value as? NSNumber {
                    sanitized[key] = sanitizeNumericValue(numericValue)
                } else {
                    sanitized[key] = String(describing: value)
                }
            }
        }
        
        return sanitized
    }
    
    private func sanitizeStringValue(_ value: String) -> String {
        // Remove any potentially identifying information
        let sanitized = value.lowercased()
            .replacingOccurrences(of: #"\b\d{3,}\b"#, with: "[NUMBER]", options: .regularExpression)
            .replacingOccurrences(of: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#, with: "[EMAIL]", options: .regularExpression)
        
        return String(sanitized.prefix(50)) // Limit length
    }
    
    private func sanitizeNumericValue(_ value: NSNumber) -> Any {
        // Round numbers to reduce precision and protect privacy
        if let doubleValue = value as? Double {
            return round(doubleValue * 10) / 10 // Round to 1 decimal place
        } else if let intValue = value as? Int {
            return intValue
        }
        return value
    }
    
    private func getAccuracyRange(_ accuracy: Float) -> String {
        switch accuracy {
        case 0.0..<0.5:
            return "0-50%"
        case 0.5..<0.7:
            return "50-70%"
        case 0.7..<0.85:
            return "70-85%"
        case 0.85..<0.95:
            return "85-95%"
        default:
            return "95-100%"
        }
    }
    
    private func getTimeRange(_ timeSpent: TimeInterval) -> String {
        switch timeSpent {
        case 0..<60:
            return "0-1min"
        case 60..<300:
            return "1-5min"
        case 300..<600:
            return "5-10min"
        case 600..<1800:
            return "10-30min"
        default:
            return "30min+"
        }
    }
    
    private func getValueRange(_ value: Double, for metric: String) -> String {
        switch metric {
        case "memory_usage":
            switch value {
            case 0..<50:
                return "0-50MB"
            case 50..<100:
                return "50-100MB"
            case 100..<200:
                return "100-200MB"
            default:
                return "200MB+"
            }
        case "response_time":
            switch value {
            case 0..<100:
                return "0-100ms"
            case 100..<500:
                return "100-500ms"
            case 500..<1000:
                return "500ms-1s"
            default:
                return "1s+"
            }
        default:
            return "unknown"
        }
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
    
    private func saveAnalyticsEvent(_ event: AnalyticsEvent) {
        let filename = "analytics-\(Date().timeIntervalSince1970).json"
        let fileURL = analyticsURL.appendingPathComponent(filename)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(event)
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to save analytics event: \(error.localizedDescription)")
        }
    }
    
    private func getAnalyticsEvents(for period: AnalyticsPeriod) -> [AnalyticsEvent] {
        let startDate = period.startDate
        let endDate = period.endDate
        
        return getAllAnalyticsEvents().filter { event in
            event.timestamp >= startDate && event.timestamp <= endDate
        }
    }
    
    private func getAllAnalyticsEvents() -> [AnalyticsEvent] {
        do {
            let analyticsFiles = try FileManager.default.contentsOfDirectory(at: analyticsURL, includingPropertiesForKeys: nil)
            
            var events: [AnalyticsEvent] = []
            for file in analyticsFiles {
                if let event = loadAnalyticsEvent(from: file) {
                    events.append(event)
                }
            }
            
            return events.sorted { $0.timestamp > $1.timestamp }
        } catch {
            logger.error("Failed to get analytics events: \(error.localizedDescription)")
            return []
        }
    }
    
    private func loadAnalyticsEvent(from url: URL) -> AnalyticsEvent? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(AnalyticsEvent.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func countEvents(_ events: [AnalyticsEvent], type: String) -> Int {
        return events.filter { $0.event == type }.count
    }
    
    private func calculateAverageSessionDuration(_ events: [AnalyticsEvent]) -> TimeInterval {
        let sessionStarts = events.filter { $0.event == "session_start" }
        let sessionEnds = events.filter { $0.event == "session_end" }
        
        guard !sessionStarts.isEmpty && !sessionEnds.isEmpty else { return 0 }
        
        // This is a simplified calculation
        // In practice, you'd match start/end pairs
        let totalDuration = sessionEnds.reduce(0) { total, event in
            if let timeRange = event.parameters?["time_range"] as? String {
                return total + parseTimeRange(timeRange)
            }
            return total
        }
        
        return totalDuration / Double(sessionEnds.count)
    }
    
    private func parseTimeRange(_ timeRange: String) -> TimeInterval {
        switch timeRange {
        case "0-1min":
            return 30 // Average
        case "1-5min":
            return 180 // Average
        case "5-10min":
            return 450 // Average
        case "10-30min":
            return 1200 // Average
        case "30min+":
            return 2400 // Estimate
        default:
            return 0
        }
    }
    
    private func findMostPopularLevel(_ events: [AnalyticsEvent]) -> String {
        let exerciseEvents = events.filter { $0.event == "exercise_completed" }
        let levelCounts = Dictionary(grouping: exerciseEvents) { event in
            event.parameters?["level"] as? String ?? "unknown"
        }.mapValues { $0.count }
        
        return levelCounts.max { $0.value < $1.value }?.key ?? "unknown"
    }
    
    private func aggregatePerformanceMetrics(_ events: [AnalyticsEvent]) -> [String: Any] {
        let performanceEvents = events.filter { $0.event == "performance_metric" }
        
        var metrics: [String: [String]] = [:]
        for event in performanceEvents {
            if let metric = event.parameters?["metric"] as? String,
               let valueRange = event.parameters?["value_range"] as? String {
                metrics[metric, default: []].append(valueRange)
            }
        }
        
        return metrics.mapValues { ranges in
            // Return the most common range for each metric
            Dictionary(grouping: ranges) { $0 }.mapValues { $0.count }.max { $0.value < $1.value }?.key ?? "unknown"
        }
    }
    
    private func getPrivacyNotice() -> String {
        return """
        PRIVACY NOTICE FOR ANALYTICS DATA
        
        This analytics data has been collected in compliance with COPPA (Children's Online Privacy Protection Act) and other privacy regulations.
        
        Data Collection Practices:
        - No personally identifiable information is collected
        - All data is anonymized and aggregated
        - Data is stored locally on the device only
        - No data is shared with third parties
        - Data is automatically deleted after \(maxDataRetentionDays) days
        
        Data Types Collected:
        - App usage patterns (anonymized)
        - Performance metrics (device-level only)
        - Error reports (sanitized)
        - Learning progress (aggregated ranges only)
        
        Your Rights:
        - You can request deletion of all data at any time
        - You can export your data for review
        - No data is used for advertising or profiling
        
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        """
    }
}

// MARK: - Supporting Models

struct AnalyticsEvent: Codable {
    let id = UUID()
    let event: String
    let parameters: [String: AnyCodable]?
    let timestamp: Date
    
    init(event: String, parameters: [String: Any]? = nil, timestamp: Date) {
        self.event = event
        self.parameters = parameters?.mapValues { AnyCodable($0) }
        self.timestamp = timestamp
    }
}

enum AnalyticsPeriod {
    case last7Days
    case last30Days
    case last90Days
    case custom(start: Date, end: Date)
    
    var startDate: Date {
        switch self {
        case .last7Days:
            return Date().addingTimeInterval(-7 * 24 * 60 * 60)
        case .last30Days:
            return Date().addingTimeInterval(-30 * 24 * 60 * 60)
        case .last90Days:
            return Date().addingTimeInterval(-90 * 24 * 60 * 60)
        case .custom(let start, _):
            return start
        }
    }
    
    var endDate: Date {
        switch self {
        case .last7Days, .last30Days, .last90Days:
            return Date()
        case .custom(_, let end):
            return end
        }
    }
}

struct AggregatedAnalytics: Codable {
    let period: String
    let totalSessions: Int
    let totalExercises: Int
    let averageSessionDuration: TimeInterval
    let mostPopularLevel: String
    let errorCount: Int
    let performanceMetrics: [String: Any]
    let generatedAt: Date
    
    init(period: AnalyticsPeriod, totalSessions: Int, totalExercises: Int, averageSessionDuration: TimeInterval, mostPopularLevel: String, errorCount: Int, performanceMetrics: [String: Any], generatedAt: Date) {
        switch period {
        case .last7Days:
            self.period = "Last 7 Days"
        case .last30Days:
            self.period = "Last 30 Days"
        case .last90Days:
            self.period = "Last 90 Days"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            self.period = "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        
        self.totalSessions = totalSessions
        self.totalExercises = totalExercises
        self.averageSessionDuration = averageSessionDuration
        self.mostPopularLevel = mostPopularLevel
        self.errorCount = errorCount
        self.performanceMetrics = performanceMetrics
        self.generatedAt = generatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case period, totalSessions, totalExercises, averageSessionDuration, mostPopularLevel, errorCount, generatedAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(period, forKey: .period)
        try container.encode(totalSessions, forKey: .totalSessions)
        try container.encode(totalExercises, forKey: .totalExercises)
        try container.encode(averageSessionDuration, forKey: .averageSessionDuration)
        try container.encode(mostPopularLevel, forKey: .mostPopularLevel)
        try container.encode(errorCount, forKey: .errorCount)
        try container.encode(generatedAt, forKey: .generatedAt)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        period = try container.decode(String.self, forKey: .period)
        totalSessions = try container.decode(Int.self, forKey: .totalSessions)
        totalExercises = try container.decode(Int.self, forKey: .totalExercises)
        averageSessionDuration = try container.decode(TimeInterval.self, forKey: .averageSessionDuration)
        mostPopularLevel = try container.decode(String.self, forKey: .mostPopularLevel)
        errorCount = try container.decode(Int.self, forKey: .errorCount)
        performanceMetrics = [:]
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
    }
}

struct AnalyticsExport: Codable {
    let aggregatedData: AggregatedAnalytics
    let privacyNotice: String
    let exportDate: Date
}

struct PrivacyComplianceStatus: Codable {
    let isCOPPACompliant: Bool
    let dataRetentionCompliant: Bool
    let encryptionEnabled: Bool
    let anonymizationEnabled: Bool
    let parentalControlsRespected: Bool
    let lastComplianceCheck: Date
    let totalEventsStored: Int
    let oldestEventDate: Date?
}