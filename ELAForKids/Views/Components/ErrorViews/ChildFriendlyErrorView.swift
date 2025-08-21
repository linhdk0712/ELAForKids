import SwiftUI

// MARK: - Child Friendly Error View
struct ChildFriendlyErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Error illustration
            errorIllustration
            
            // Error message
            errorMessage
            
            // Action buttons
            actionButtons
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Error Illustration
    
    @ViewBuilder
    private var errorIllustration: some View {
        VStack(spacing: 16) {
            // Main error icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                error.severity.color.opacity(0.2),
                                error.severity.color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animationPhase % 2 == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationPhase)
                
                Image(systemName: error.category.icon)
                    .font(.system(size: 48))
                    .foregroundColor(error.severity.color)
            }
            
            // Friendly character
            Text(error.severity.emoji)
                .font(.system(size: 40))
                .scaleEffect(animationPhase % 2 == 0 ? 1.0 : 1.2)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)
        }
    }
    
    // MARK: - Error Message
    
    @ViewBuilder
    private var errorMessage: some View {
        VStack(spacing: 12) {
            // Title
            Text(error.severity.friendlyTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(error.userFriendlyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // Additional help for children
            if error.severity == .high || error.severity == .critical {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Gợi ý cho bé:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text(error.childFriendlyAdvice)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action (retry if available)
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Thử lại")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Secondary actions
            HStack(spacing: 12) {
                // Help button
                Button(action: {
                    showHelp()
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Trợ giúp")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Dismiss button
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Đóng")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase += 1
            }
        }
    }
    
    private func showHelp() {
        // This would show context-sensitive help
        print("Showing help for error: \(error.errorCode)")
    }
}

// MARK: - Error Severity Extensions

extension ErrorSeverity {
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
    
    var emoji: String {
        switch self {
        case .low:
            return "😊"
        case .medium:
            return "😐"
        case .high:
            return "😟"
        case .critical:
            return "😰"
        }
    }
    
    var friendlyTitle: String {
        switch self {
        case .low:
            return "Có chút vấn đề nhỏ"
        case .medium:
            return "Ôi không! Có lỗi rồi"
        case .high:
            return "Có lỗi nghiêm trọng"
        case .critical:
            return "Lỗi rất nghiêm trọng"
        }
    }
}

extension AppError {
    var childFriendlyAdvice: String {
        switch self.category {
        case .network:
            return "Hãy nhờ bố mẹ kiểm tra kết nối Wi-Fi hoặc dữ liệu di động nhé!"
        case .speech:
            return "Bé có thể thử nói to hơn, rõ hơn, hoặc sử dụng bàn phím để gõ."
        case .audio:
            return "Hãy kiểm tra âm lượng và tai nghe. Nhờ bố mẹ giúp nếu cần!"
        case .storage:
            return "Thiết bị có thể đã hết dung lượng. Hãy nhờ bố mẹ xóa bớt ảnh hoặc ứng dụng."
        case .permissions:
            return "Ứng dụng cần quyền truy cập. Hãy nhờ bố mẹ vào Cài đặt để bật quyền này."
        default:
            return "Đừng lo lắng! Hãy thử khởi động lại ứng dụng hoặc nhờ bố mẹ giúp."
        }
    }
}

// MARK: - Error Toast View
struct ErrorToastView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.category.icon)
                .font(.title3)
                .foregroundColor(error.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.category.localizedName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(error.userFriendlyMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Auto dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

// MARK: - Network Error View
struct NetworkErrorView: View {
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Offline illustration
            VStack(spacing: 16) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("📡")
                    .font(.system(size: 40))
            }
            
            VStack(spacing: 8) {
                Text("Không có kết nối mạng")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Hãy kiểm tra kết nối Wi-Fi hoặc dữ liệu di động")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Thử kết nối lại")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                
                Button("Tiếp tục offline", action: onDismiss)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
struct ChildFriendlyErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChildFriendlyErrorView(
                error: NetworkError.noConnection,
                onRetry: {},
                onDismiss: {}
            )
            
            ErrorToastView(
                error: SpeechError.permissionDenied,
                onDismiss: {}
            )
        }
        .background(Color(.systemGroupedBackground))
    }
}