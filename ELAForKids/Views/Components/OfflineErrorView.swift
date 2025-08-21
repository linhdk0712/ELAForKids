import SwiftUI

// MARK: - Offline Error View
struct OfflineErrorView: View {
    let error: Error
    let offlineManager: OfflineManager
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(
        error: Error,
        offlineManager: OfflineManager,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.offlineManager = offlineManager
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundColor(errorColor)
            
            // Error Title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Error Message
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Offline Mode Info
            if offlineManager.isOfflineMode {
                offlineModeInfo
            }
            
            // Action Buttons
            actionButtons
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Offline Mode Info
    private var offlineModeInfo: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chế độ ngoại tuyến")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Một số tính năng có thể bị hạn chế khi không có kết nối mạng")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Dismiss Button
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Đóng")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(25)
                }
            }
            
            // Retry Button
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        if offlineManager.isOfflineMode {
                            Image(systemName: "arrow.clockwise")
                        } else {
                            Image(systemName: "wifi")
                        }
                        
                        Text(retryButtonText)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(retryButtonColor)
                    .cornerRadius(25)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var errorIcon: String {
        if offlineManager.isOfflineMode {
            return "wifi.slash"
        } else if error is NetworkError {
            return "wifi.exclamationmark"
        } else if error is SpeechError {
            return "mic.slash"
        } else if error is AudioError {
            return "speaker.slash"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        if offlineManager.isOfflineMode {
            return .orange
        } else if error is NetworkError {
            return .red
        } else {
            return .orange
        }
    }
    
    private var errorTitle: String {
        if offlineManager.isOfflineMode {
            return "Chế độ ngoại tuyến"
        } else if let appError = error as? AppError {
            return "Có lỗi xảy ra"
        } else {
            return "Lỗi không xác định"
        }
    }
    
    private var errorMessage: String {
        if offlineManager.isOfflineMode {
            return offlineManager.handleOfflineError(error)
        } else if let appError = error as? AppError {
            return appError.userFriendlyMessage
        } else {
            return "Đã xảy ra lỗi không mong muốn. Hãy thử lại sau."
        }
    }
    
    private var retryButtonText: String {
        if offlineManager.isOfflineMode {
            return "Thử lại"
        } else {
            return "Kết nối lại"
        }
    }
    
    private var retryButtonColor: Color {
        if offlineManager.isOfflineMode {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Offline Error Alert Modifier
struct OfflineErrorAlert: ViewModifier {
    @Binding var error: Error?
    let offlineManager: OfflineManager
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let error = error {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.error = nil
                            }
                        
                        OfflineErrorView(
                            error: error,
                            offlineManager: offlineManager,
                            onRetry: {
                                onRetry?()
                                self.error = nil
                            },
                            onDismiss: {
                                self.error = nil
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: error != nil)
            )
    }
}

// MARK: - View Extension
extension View {
    func offlineErrorAlert(
        error: Binding<Error?>,
        offlineManager: OfflineManager,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(OfflineErrorAlert(
            error: error,
            offlineManager: offlineManager,
            onRetry: onRetry
        ))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        OfflineErrorView(
            error: NetworkError.noConnection,
            offlineManager: OfflineManager()
        )
        
        OfflineErrorView(
            error: SpeechError.permissionDenied,
            offlineManager: OfflineManager(),
            onRetry: {},
            onDismiss: {}
        )
    }
    .padding()
}