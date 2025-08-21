import Foundation

// MARK: - App Error Protocol
protocol AppError: LocalizedError {
    var errorCode: String { get }
    var userFriendlyMessage: String { get }
    var severity: ErrorSeverity { get }
    var category: ErrorCategory { get }
    var underlyingError: Error? { get }
    var context: [String: Any]? { get }
}

// MARK: - Error Severity
enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var localizedName: String {
        switch self {
        case .low:
            return "Thấp"
        case .medium:
            return "Trung bình"
        case .high:
            return "Cao"
        case .critical:
            return "Nghiêm trọng"
        }
    }
    
    var shouldShowToUser: Bool {
        switch self {
        case .low:
            return false
        case .medium, .high, .critical:
            return true
        }
    }
    
    var shouldReportToCrashlytics: Bool {
        switch self {
        case .low, .medium:
            return false
        case .high, .critical:
            return true
        }
    }
}

// MARK: - Error Category
enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case storage = "storage"
    case speech = "speech"
    case audio = "audio"
    case permissions = "permissions"
    case validation = "validation"
    case authentication = "authentication"
    case parsing = "parsing"
    case ui = "ui"
    case unknown = "unknown"
    
    var localizedName: String {
        switch self {
        case .network:
            return "Mạng"
        case .storage:
            return "Lưu trữ"
        case .speech:
            return "Nhận dạng giọng nói"
        case .audio:
            return "Âm thanh"
        case .permissions:
            return "Quyền truy cập"
        case .validation:
            return "Xác thực"
        case .authentication:
            return "Đăng nhập"
        case .parsing:
            return "Xử lý dữ liệu"
        case .ui:
            return "Giao diện"
        case .unknown:
            return "Không xác định"
        }
    }
    
    var icon: String {
        switch self {
        case .network:
            return "wifi.exclamationmark"
        case .storage:
            return "externaldrive.badge.exclamationmark"
        case .speech:
            return "mic.slash"
        case .audio:
            return "speaker.slash"
        case .permissions:
            return "lock.shield"
        case .validation:
            return "exclamationmark.triangle"
        case .authentication:
            return "person.badge.key"
        case .parsing:
            return "doc.badge.exclamationmark"
        case .ui:
            return "display.trianglebadge.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

// MARK: - Specific Error Types

// MARK: Network Errors
enum NetworkError: AppError {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case rateLimited
    
    var errorCode: String {
        switch self {
        case .noConnection:
            return "NET_001"
        case .timeout:
            return "NET_002"
        case .serverError(let code):
            return "NET_003_\(code)"
        case .invalidResponse:
            return "NET_004"
        case .rateLimited:
            return "NET_005"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .noConnection:
            return "Không có kết nối mạng. Hãy kiểm tra kết nối internet của bé."
        case .timeout:
            return "Kết nối mạng chậm. Hãy thử lại sau."
        case .serverError:
            return "Có lỗi từ máy chủ. Hãy thử lại sau."
        case .invalidResponse:
            return "Dữ liệu nhận được không hợp lệ."
        case .rateLimited:
            return "Quá nhiều yêu cầu. Hãy đợi một chút rồi thử lại."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout:
            return .medium
        case .serverError, .invalidResponse:
            return .high
        case .rateLimited:
            return .low
        }
    }
    
    var category: ErrorCategory { return .network }
    var underlyingError: Error? { return nil }
    var context: [String: Any]? { return nil }
    
    var errorDescription: String? { return userFriendlyMessage }
}

// MARK: Speech Recognition Errors
enum SpeechError: AppError {
    case permissionDenied
    case notAvailable
    case recognitionFailed
    case audioEngineError
    case languageNotSupported
    
    var errorCode: String {
        switch self {
        case .permissionDenied:
            return "SPE_001"
        case .notAvailable:
            return "SPE_002"
        case .recognitionFailed:
            return "SPE_003"
        case .audioEngineError:
            return "SPE_004"
        case .languageNotSupported:
            return "SPE_005"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .permissionDenied:
            return "Cần quyền truy cập microphone để nhận dạng giọng nói. Hãy vào Cài đặt để bật quyền này."
        case .notAvailable:
            return "Tính năng nhận dạng giọng nói không khả dụng trên thiết bị này."
        case .recognitionFailed:
            return "Không thể nhận dạng giọng nói. Hãy nói rõ hơn và thử lại."
        case .audioEngineError:
            return "Có lỗi với microphone. Hãy kiểm tra và thử lại."
        case .languageNotSupported:
            return "Ngôn ngữ này chưa được hỗ trợ cho nhận dạng giọng nói."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .permissionDenied, .notAvailable:
            return .high
        case .recognitionFailed, .audioEngineError:
            return .medium
        case .languageNotSupported:
            return .low
        }
    }
    
    var category: ErrorCategory { return .speech }
    var underlyingError: Error? { return nil }
    var context: [String: Any]? { return nil }
    
    var errorDescription: String? { return userFriendlyMessage }
}

// MARK: Storage Errors
enum StorageError: AppError {
    case diskFull
    case permissionDenied
    case corruptedData
    case fileNotFound
    case saveFailed
    case loadFailed
    
    var errorCode: String {
        switch self {
        case .diskFull:
            return "STO_001"
        case .permissionDenied:
            return "STO_002"
        case .corruptedData:
            return "STO_003"
        case .fileNotFound:
            return "STO_004"
        case .saveFailed:
            return "STO_005"
        case .loadFailed:
            return "STO_006"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .diskFull:
            return "Thiết bị đã hết dung lượng. Hãy xóa bớt dữ liệu để tiếp tục."
        case .permissionDenied:
            return "Không có quyền truy cập vào bộ nhớ thiết bị."
        case .corruptedData:
            return "Dữ liệu bị hỏng. Ứng dụng sẽ tự động khôi phục."
        case .fileNotFound:
            return "Không tìm thấy tệp dữ liệu cần thiết."
        case .saveFailed:
            return "Không thể lưu dữ liệu. Hãy thử lại."
        case .loadFailed:
            return "Không thể tải dữ liệu. Hãy khởi động lại ứng dụng."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .diskFull, .permissionDenied:
            return .high
        case .corruptedData, .fileNotFound:
            return .medium
        case .saveFailed, .loadFailed:
            return .medium
        }
    }
    
    var category: ErrorCategory { return .storage }
    var underlyingError: Error? { return nil }
    var context: [String: Any]? { return nil }
    
    var errorDescription: String? { return userFriendlyMessage }
}

// MARK: Audio Errors
enum AudioError: AppError {
    case permissionDenied
    case deviceNotAvailable
    case playbackFailed
    case recordingFailed
    case formatNotSupported
    
    var errorCode: String {
        switch self {
        case .permissionDenied:
            return "AUD_001"
        case .deviceNotAvailable:
            return "AUD_002"
        case .playbackFailed:
            return "AUD_003"
        case .recordingFailed:
            return "AUD_004"
        case .formatNotSupported:
            return "AUD_005"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .permissionDenied:
            return "Cần quyền truy cập microphone để ghi âm. Hãy vào Cài đặt để bật quyền này."
        case .deviceNotAvailable:
            return "Không tìm thấy thiết bị âm thanh. Hãy kiểm tra tai nghe hoặc loa."
        case .playbackFailed:
            return "Không thể phát âm thanh. Hãy kiểm tra âm lượng và thử lại."
        case .recordingFailed:
            return "Không thể ghi âm. Hãy kiểm tra microphone và thử lại."
        case .formatNotSupported:
            return "Định dạng âm thanh không được hỗ trợ."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .permissionDenied:
            return .high
        case .deviceNotAvailable, .playbackFailed, .recordingFailed:
            return .medium
        case .formatNotSupported:
            return .low
        }
    }
    
    var category: ErrorCategory { return .audio }
    var underlyingError: Error? { return nil }
    var context: [String: Any]? { return nil }
    
    var errorDescription: String? { return userFriendlyMessage }
}

// MARK: Validation Errors
enum ValidationError: AppError {
    case invalidInput(String)
    case missingRequiredField(String)
    case formatMismatch(String)
    case outOfRange(String, min: Any?, max: Any?)
    
    var errorCode: String {
        switch self {
        case .invalidInput:
            return "VAL_001"
        case .missingRequiredField:
            return "VAL_002"
        case .formatMismatch:
            return "VAL_003"
        case .outOfRange:
            return "VAL_004"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .invalidInput(let field):
            return "Dữ liệu nhập vào không hợp lệ: \(field)"
        case .missingRequiredField(let field):
            return "Thiếu thông tin bắt buộc: \(field)"
        case .formatMismatch(let field):
            return "Định dạng không đúng: \(field)"
        case .outOfRange(let field, let min, let max):
            var message = "Giá trị nằm ngoài phạm vi cho phép: \(field)"
            if let min = min, let max = max {
                message += " (từ \(min) đến \(max))"
            }
            return message
        }
    }
    
    var severity: ErrorSeverity { return .medium }
    var category: ErrorCategory { return .validation }
    var underlyingError: Error? { return nil }
    var context: [String: Any]? { return nil }
    
    var errorDescription: String? { return userFriendlyMessage }
}

// MARK: - Generic App Error
struct GenericAppError: AppError {
    let errorCode: String
    let userFriendlyMessage: String
    let severity: ErrorSeverity
    let category: ErrorCategory
    let underlyingError: Error?
    let context: [String: Any]?
    
    var errorDescription: String? { return userFriendlyMessage }
    
    init(
        code: String,
        message: String,
        severity: ErrorSeverity = .medium,
        category: ErrorCategory = .unknown,
        underlyingError: Error? = nil,
        context: [String: Any]? = nil
    ) {
        self.errorCode = code
        self.userFriendlyMessage = message
        self.severity = severity
        self.category = category
        self.underlyingError = underlyingError
        self.context = context
    }
}

// MARK: - Error Extensions
extension Error {
    var asAppError: AppError {
        if let appError = self as? AppError {
            return appError
        }
        
        // Convert common system errors to app errors
        if let urlError = self as? URLError {
            return urlError.asAppError
        }
        
        if let nsError = self as? NSError {
            return nsError.asAppError
        }
        
        // Generic fallback
        return GenericAppError(
            code: "GEN_001",
            message: "Đã xảy ra lỗi không xác định. Hãy thử lại sau.",
            severity: .medium,
            category: .unknown,
            underlyingError: self
        )
    }
}

extension URLError {
    var asAppError: AppError {
        switch self.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return NetworkError.noConnection
        case .timedOut:
            return NetworkError.timeout
        case .badServerResponse:
            return NetworkError.invalidResponse
        default:
            return GenericAppError(
                code: "NET_999",
                message: "Lỗi kết nối mạng: \(self.localizedDescription)",
                severity: .medium,
                category: .network,
                underlyingError: self
            )
        }
    }
}

extension NSError {
    var asAppError: AppError {
        switch self.domain {
        case "AVAudioSessionErrorDomain":
            return AudioError.deviceNotAvailable
        case "NSSpeechRecognizerErrorDomain":
            return SpeechError.recognitionFailed
        case "NSCocoaErrorDomain":
            if self.code == NSFileReadNoSuchFileError {
                return StorageError.fileNotFound
            } else if self.code == NSFileWriteFileExistsError {
                return StorageError.saveFailed
            }
            fallthrough
        default:
            return GenericAppError(
                code: "SYS_\(self.code)",
                message: self.localizedDescription,
                severity: .medium,
                category: .unknown,
                underlyingError: self
            )
        }
    }
}