import SwiftUI
import os.log

// MARK: - Logging Debug View
struct LoggingDebugView: View {
    @StateObject private var monitoringService = MonitoringService.shared
    @State private var systemStatus: SystemStatus?
    @State private var recentLogs: [LogEntry] = []
    @State private var crashReports: [ErrorReport] = []
    @State private var isExporting = false
    @State private var exportURLs: [URL] = []
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // System Health Section
                Section("System Health") {
                    if let status = systemStatus {
                        HealthStatusRow(status: status.healthStatus)
                        PerformanceRow(performance: status.performanceSummary)
                        PrivacyComplianceRow(compliance: status.privacyCompliance)
                    } else {
                        ProgressView("Loading system status...")
                    }
                }
                
                // Recent Issues Section
                Section("Recent Issues") {
                    if monitoringService.recentIssues.isEmpty {
                        Text("No recent issues")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(monitoringService.recentIssues.prefix(5)) { issue in
                            IssueRow(issue: issue)
                        }
                    }
                }
                
                // Recent Logs Section
                Section("Recent Logs") {
                    if recentLogs.isEmpty {
                        Text("No recent logs")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(recentLogs.prefix(10), id: \.timestamp) { log in
                            LogRow(log: log)
                        }
                    }
                }
                
                // Crash Reports Section
                Section("Crash Reports") {
                    if crashReports.isEmpty {
                        Text("No crash reports")
                            .foregroundColor(.green)
                    } else {
                        ForEach(crashReports.prefix(5), id: \.id) { report in
                            CrashReportRow(report: report)
                        }
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button("Test Error Logging") {
                        testErrorLogging()
                    }
                    
                    Button("Test Performance Logging") {
                        testPerformanceLogging()
                    }
                    
                    Button("Test Analytics") {
                        testAnalytics()
                    }
                    
                    Button("Export All Data") {
                        exportAllData()
                    }
                    .disabled(isExporting)
                    
                    Button("Clear All Data", role: .destructive) {
                        clearAllData()
                    }
                }
            }
            .navigationTitle("Logging Debug")
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheet(urls: exportURLs)
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadInitialData() async {
        systemStatus = LoggingInitializer.shared.getSystemStatus()
        recentLogs = LoggingService.shared.getRecentLogs(limit: 20)
        crashReports = CrashReportingService.shared.getCrashReports()
    }
    
    @MainActor
    private func refreshData() async {
        await loadInitialData()
    }
    
    // MARK: - Test Methods
    
    private func testErrorLogging() {
        // Test different error levels
        LoggingService.shared.logInfo("Test info message", category: .general)
        LoggingService.shared.logWarning("Test warning message", category: .general)
        LoggingService.shared.logError("Test error message", category: .general)
        
        // Test error handling
        let testError = ValidationError.invalidInput("test_field")
        ErrorHandler.shared.handle(testError, context: ["test": "debug"])
        
        Task {
            await refreshData()
        }
    }
    
    private func testPerformanceLogging() {
        // Test performance metrics
        MonitoringService.shared.recordPerformance("test_metric", value: 123.45, unit: "ms")
        MonitoringService.shared.recordUserInteraction("test_tap", screen: "debug_view")
        
        // Test speech recognition timing
        LoggingService.shared.logSpeechEvent("recognition_test", accuracy: 0.85, duration: 2.5)
        
        Task {
            await refreshData()
        }
    }
    
    private func testAnalytics() {
        // Test privacy-compliant analytics
        PrivacyCompliantAnalytics.shared.trackEvent("app_launch")
        PrivacyCompliantAnalytics.shared.trackLearningProgress(level: "grade_1", accuracy: 0.92, timeSpent: 180)
        PrivacyCompliantAnalytics.shared.trackPerformance(metric: "memory_usage", value: 85.5, category: "performance")
        
        Task {
            await refreshData()
        }
    }
    
    private func exportAllData() {
        isExporting = true
        
        Task {
            let urls = LoggingInitializer.shared.exportSystemData()
            
            await MainActor.run {
                exportURLs = urls
                isExporting = false
                showingExportSheet = true
            }
        }
    }
    
    private func clearAllData() {
        LoggingInitializer.shared.clearAllSystemData()
        
        Task {
            await refreshData()
        }
    }
}

// MARK: - Supporting Views

struct HealthStatusRow: View {
    let status: AppHealthStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Health Score")
                Spacer()
                Text("\(Int(status.healthScore))/100")
                    .foregroundColor(healthColor)
            }
            
            HStack {
                Text("Status")
                Spacer()
                Text(status.status)
                    .foregroundColor(healthColor)
            }
            
            HStack {
                Text("Memory Usage")
                Spacer()
                Text("\(String(format: "%.1f", status.memoryUsage)) MB")
            }
            
            HStack {
                Text("Errors")
                Spacer()
                Text("\(status.errorCount)")
                    .foregroundColor(status.errorCount > 0 ? .orange : .green)
            }
        }
        .font(.caption)
    }
    
    private var healthColor: Color {
        switch status.healthScore {
        case 90...100:
            return .green
        case 70..<90:
            return .yellow
        case 50..<70:
            return .orange
        default:
            return .red
        }
    }
}

struct PerformanceRow: View {
    let performance: PerformanceSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Avg Memory")
                Spacer()
                Text("\(String(format: "%.1f", performance.averageMemoryUsage)) MB")
            }
            
            HStack {
                Text("Peak Memory")
                Spacer()
                Text("\(String(format: "%.1f", performance.peakMemoryUsage)) MB")
            }
            
            HStack {
                Text("User Interactions")
                Spacer()
                Text("\(performance.userInteractions)")
            }
            
            HStack {
                Text("Session Duration")
                Spacer()
                Text("\(String(format: "%.1f", performance.sessionDuration / 60)) min")
            }
        }
        .font(.caption)
    }
}

struct PrivacyComplianceRow: View {
    let compliance: PrivacyComplianceStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("COPPA Compliant")
                Spacer()
                Image(systemName: compliance.isCOPPACompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(compliance.isCOPPACompliant ? .green : .red)
            }
            
            HStack {
                Text("Data Retention")
                Spacer()
                Image(systemName: compliance.dataRetentionCompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(compliance.dataRetentionCompliant ? .green : .red)
            }
            
            HStack {
                Text("Events Stored")
                Spacer()
                Text("\(compliance.totalEventsStored)")
            }
        }
        .font(.caption)
    }
}

struct IssueRow: View {
    let issue: MonitoringIssue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: issue.type.icon)
                    .foregroundColor(issue.severity.color)
                Text(issue.message)
                    .font(.caption)
                Spacer()
                Text(issue.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LogRow: View {
    let log: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(log.level.emoji)
                Text(log.message)
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                Text(log.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !log.contextString.isEmpty {
                Text(log.contextString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct CrashReportRow: View {
    let report: ErrorReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: report.isFatal ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                    .foregroundColor(report.isFatal ? .red : .orange)
                Text(report.message)
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                Text(report.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExportSheet: View {
    let urls: [URL]
    
    var body: some View {
        NavigationView {
            List {
                Section("Exported Files") {
                    ForEach(urls, id: \.self) { url in
                        HStack {
                            Image(systemName: "doc.text")
                            Text(url.lastPathComponent)
                            Spacer()
                            Button("Share") {
                                shareFile(url)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Extensions

extension MonitoringIssue.IssueType {
    var icon: String {
        switch self {
        case .error:
            return "exclamationmark.triangle"
        case .performance:
            return "speedometer"
        case .health:
            return "heart.text.square"
        case .network:
            return "wifi.exclamationmark"
        case .storage:
            return "externaldrive.badge.exclamationmark"
        case .ui:
            return "display.trianglebadge.exclamationmark"
        }
    }
}

extension MonitoringIssue.IssueSeverity {
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LoggingDebugView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingDebugView()
    }
}
#endif