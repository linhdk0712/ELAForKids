import SwiftUI
import Combine
import os.log

// MARK: - Error Handler
@MainActor
final class ErrorHandler: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ErrorHandler()
    
    // MARK: - Published Properties
    @Published var currentError: AppError?
    @Published var isShowingError = false
    @Published var errorQueue: [AppError] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.elaforkids.app", category: "ErrorHandler")
    private let loggingService = LoggingService.shared
    private let crashReportingService = CrashReportingService.shared
    private let monitoringService = MonitoringService.shared
    private var cancellables = Set<AnyCancellable>()
    private let maxQueueSize = 5
    private var isProcessingError = false
    
    // MARK: - Initialization
    private init() {
        setupErrorProcessing()
    }
    
    // MARK: - Public Methods
    
    /// Handle an error with automatic severity-based processing
    func handle(_ error: Error, context: [String: Any]? = nil) {
        let appError = error.asAppError
        handle(appError, context: context)
    }
    
    /// Handle an app error with optional context
    func handle(_ error: AppError, context: [String: Any]? = nil) {
        // Log the error
        logError(error, context: context)
        
        // Report to crash reporting if needed
        if error.severity.shouldReportToCrashlytics {
            reportToCrashlytics(error, context: context)
        }
        
        // Show to user if needed
        if error.severity.shouldShowToUser {
            queueErrorForDisplay(error)
        }
        
        // Handle specific error types
        handleSpecificError(error)
    }
    
    /// Handle an error silently (log only, don't show to user)
    func handleSilently(_ error: Error, context: [String: Any]? = nil) {
        let appError = error.asAppError
        logError(appError, context: context)
        
        if appError.severity.shouldReportToCrashlytics {
            reportToCrashlytics(appError, context: context)
        }
    }
    
    /// Clear current error
    func clearCurrentError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Clear all queued errors
    func clearAllErrors() {
        errorQueue.removeAll()
        clearCurrentError()
    }
    
    /// Get error recovery suggestions
    func getRecoverySuggestions(for error: AppError) -> [ErrorRecoveryAction] {
        switch error.category {
        case .network:
            return [
                ErrorRecoveryAction(
                    title: "Kiểm tra kết nối",
                    description: "Kiểm tra kết nối Wi-Fi hoặc dữ liệu di động",
                    action: { [weak self] in
                        self?.checkNetworkConnection()
                    }
                ),
                ErrorRecoveryAction(
                    title: "Thử lại",
                    description: "Thử kết nối lại",
                    action: { [weak self] in
                        self?.retryLastOperation()
                    }
                )
            ]
            
        case .speech:
            return [
                ErrorRecoveryAction(
                    title: "Kiểm tra microphone",
                    description: "Đảm bảo microphone hoạt động bình thường",
                    action: { [weak self] in
                        self?.checkMicrophonePermission()
                    }
                ),
                ErrorRecoveryAction(
                    title: "Thử phương pháp khác",
                    description: "Sử dụng bàn phím hoặc viết tay thay thế",
                    action: { [weak self] in
                        self?.suggestAlternativeInputMethod()
                    }
                )
            ]
            
        case .storage:
            return [
                ErrorRecoveryAction(
                    title: "Kiểm tra dung lượng",
                    description: "Xóa bớt dữ liệu để giải phóng dung lượng",
                    action: { [weak self] in
                        self?.checkStorageSpace()
                    }
                ),
                ErrorRecoveryAction(
                    title: "Khởi động lại",
                    description: "Khởi động lại ứng dụng",
                    action: { [weak self] in
                        self?.restartApp()
                    }
                )
            ]
            
        case .audio:
            return [
                ErrorRecoveryAction(
                    title: "Kiểm tra âm lượng",
                    description: "Đảm bảo âm lượng được bật",
                    action: { [weak self] in
                        self?.checkAudioSettings()
                    }
                ),
                ErrorRecoveryAction(
                    title: "Kiểm tra tai nghe",
                    description: "Thử rút tai nghe và cắm lại",
                    action: { [weak self] in
                        self?.checkAudioDevices()
                    }
                )
            ]
            
        case .permissions:
            return [
                ErrorRecoveryAction(
                    title: "Mở Cài đặt",
                    description: "Vào Cài đặt để cấp quyền cho ứng dụng",
                    action: { [weak self] in
                        self?.openAppSettings()
                    }
                )
            ]
            
        default:
            return [
                ErrorRecoveryAction(
                    title: "Thử lại",
                    description: "Thử thực hiện lại thao tác",
                    action: { [weak self] in
                        self?.retryLastOperation()
                    }
                ),
                ErrorRecoveryAction(
                    title: "Khởi động lại",
                    description: "Khởi động lại ứng dụng",
                    action: { [weak self] in
                        self?.restartApp()
                    }
                )
            ]
        }
    }
    
    // MARK: - Private Methods
    
    private func setupErrorProcessing() {
        // Process error queue automatically
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.processErrorQueue()
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ error: AppError, context: [String: Any]?) {
        var logMessage = "Error [\(error.errorCode)]: \(error.userFriendlyMessage)"
        var fullContext = context ?? [:]
        
        if let underlyingError = error.underlyingError {
            logMessage += " | Underlying: \(underlyingError.localizedDescription)"
            fullContext["underlying_error"] = underlyingError.localizedDescription
        }
        
        fullContext["error_code"] = error.errorCode
        fullContext["error_category"] = error.category.rawValue
        fullContext["error_severity"] = error.severity.rawValue
        
        // Log to our comprehensive logging service
        switch error.severity {
        case .low:
            loggingService.logInfo(logMessage, category: .general, context: fullContext)
            logger.info("\(logMessage)")
        case .medium:
            loggingService.logWarning(logMessage, category: .general, context: fullContext)
            logger.notice("\(logMessage)")
        case .high:
            loggingService.logError(logMessage, category: .general, error: error.underlyingError, context: fullContext)
            logger.error("\(logMessage)")
        case .critical:
            loggingService.logCritical(logMessage, category: .general, error: error.underlyingError, context: fullContext)
            logger.fault("\(logMessage)")
        }
    }
    
    private func reportToCrashlytics(_ error: AppError, context: [String: Any]?) {
        // Report to our privacy-compliant crash reporting service
        if error.severity == .critical {
            crashReportingService.recordCriticalError(
                "[\(error.errorCode)] \(error.userFriendlyMessage)",
                error: error.underlyingError,
                context: context
            )
        } else {
            crashReportingService.recordError(
                "[\(error.errorCode)] \(error.userFriendlyMessage)",
                context: context
            )
        }
        
        // Also record in monitoring service
        monitoringService.recordEvent(
            "error_handled",
            category: error.category.rawValue,
            parameters: [
                "error_code": error.errorCode,
                "severity": error.severity.rawValue,
                "category": error.category.rawValue
            ]
        )
    }
    
    private func queueErrorForDisplay(_ error: AppError) {
        // Avoid duplicate errors
        if errorQueue.contains(where: { $0.errorCode == error.errorCode }) {
            return
        }
        
        // Maintain queue size
        if errorQueue.count >= maxQueueSize {
            errorQueue.removeFirst()
        }
        
        errorQueue.append(error)
    }
    
    private func processErrorQueue() {
        guard !isProcessingError, !errorQueue.isEmpty, !isShowingError else { return }
        
        isProcessingError = true
        let error = errorQueue.removeFirst()
        
        currentError = error
        isShowingError = true
        
        // Auto-dismiss after delay for low severity errors
        if error.severity == .low || error.severity == .medium {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.currentError?.errorCode == error.errorCode {
                    self.clearCurrentError()
                }
                self.isProcessingError = false
            }
        } else {
            isProcessingError = false
        }
    }
    
    private func handleSpecificError(_ error: AppError) {
        switch error.category {
        case .speech:
            handleSpeechError(error)
        case .network:
            handleNetworkError(error)
        case .storage:
            handleStorageError(error)
        case .audio:
            handleAudioError(error)
        case .permissions:
            handlePermissionError(error)
        default:
            break
        }
    }
    
    private func handleSpeechError(_ error: AppError) {
        // Could automatically switch to alternative input method
        NotificationCenter.default.post(
            name: .speechErrorOccurred,
            object: error
        )
    }
    
    private func handleNetworkError(_ error: AppError) {
        // Could enable offline mode
        NotificationCenter.default.post(
            name: .networkErrorOccurred,
            object: error
        )
    }
    
    private func handleStorageError(_ error: AppError) {
        // Could trigger cleanup or data migration
        NotificationCenter.default.post(
            name: .storageErrorOccurred,
            object: error
        )
    }
    
    private func handleAudioError(_ error: AppError) {
        // Could disable audio features temporarily
        NotificationCenter.default.post(
            name: .audioErrorOccurred,
            object: error
        )
    }
    
    private func handlePermissionError(_ error: AppError) {
        // Could show permission request UI
        NotificationCenter.default.post(
            name: .permissionErrorOccurred,
            object: error
        )
    }
    
    // MARK: - Recovery Actions
    
    private func checkNetworkConnection() {
        // Implementation would check network status
        print("Checking network connection...")
    }
    
    private func retryLastOperation() {
        // Implementation would retry the last failed operation
        print("Retrying last operation...")
    }
    
    private func checkMicrophonePermission() {
        // Implementation would check and request microphone permission
        print("Checking microphone permission...")
    }
    
    private func suggestAlternativeInputMethod() {
        // Implementation would suggest keyboard or handwriting input
        print("Suggesting alternative input method...")
    }
    
    private func checkStorageSpace() {
        // Implementation would check available storage
        print("Checking storage space...")
    }
    
    private func restartApp() {
        // Implementation would restart the app
        print("Restarting app...")
    }
    
    private func checkAudioSettings() {
        // Implementation would check audio settings
        print("Checking audio settings...")
    }
    
    private func checkAudioDevices() {
        // Implementation would check audio devices
        print("Checking audio devices...")
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Error Recovery Action
struct ErrorRecoveryAction {
    let title: String
    let description: String
    let action: () -> Void
}

// MARK: - Notification Names
extension Notification.Name {
    static let speechErrorOccurred = Notification.Name("speechErrorOccurred")
    static let networkErrorOccurred = Notification.Name("networkErrorOccurred")
    static let storageErrorOccurred = Notification.Name("storageErrorOccurred")
    static let audioErrorOccurred = Notification.Name("audioErrorOccurred")
    static let permissionErrorOccurred = Notification.Name("permissionErrorOccurred")
}

// MARK: - Error Handling View Modifier
struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.category.localizedName ?? "Lỗi",
                isPresented: $errorHandler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                // Recovery actions
                let recoveryActions = errorHandler.getRecoverySuggestions(for: error)
                
                ForEach(Array(recoveryActions.enumerated()), id: \.offset) { index, action in
                    Button(action.title) {
                        action.action()
                        errorHandler.clearCurrentError()
                    }
                }
                
                // Cancel button
                Button("Đóng", role: .cancel) {
                    errorHandler.clearCurrentError()
                }
                
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.userFriendlyMessage)
                    
                    if error.severity == .critical {
                        Text("Đây là lỗi nghiêm trọng. Hãy liên hệ hỗ trợ nếu vấn đề tiếp tục xảy ra.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func errorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

// MARK: - Result Extension for Error Handling
extension Result {
    func handleError(with errorHandler: ErrorHandler = ErrorHandler.shared) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            errorHandler.handle(error)
            return nil
        }
    }
    
    func handleErrorSilently(with errorHandler: ErrorHandler = ErrorHandler.shared) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            errorHandler.handleSilently(error)
            return nil
        }
    }
}