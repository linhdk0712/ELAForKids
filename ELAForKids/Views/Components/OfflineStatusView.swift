import SwiftUI

// MARK: - Offline Status View
struct OfflineStatusView: View {
    @ObservedObject var offlineManager: OfflineManager
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Bar
            statusBar
            
            // Details Panel (expandable)
            if showDetails {
                detailsPanel
                    .transition(.slide)
            }
        }
        .background(statusBackgroundColor)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: offlineManager.status.icon)
                .foregroundColor(statusIconColor)
                .font(.system(size: 16, weight: .medium))
                .symbolRenderingMode(.hierarchical)
            
            // Status Text
            Text(offlineManager.status.displayMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusTextColor)
            
            Spacer()
            
            // Pending Sync Count
            if offlineManager.pendingSyncCount > 0 {
                syncBadge
            }
            
            // Expand/Collapse Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetails.toggle()
                }
            }) {
                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusTextColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Sync Badge
    private var syncBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 10, weight: .medium))
            
            Text("\(offlineManager.pendingSyncCount)")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange)
        .cornerRadius(12)
    }
    
    // MARK: - Details Panel
    private var detailsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 12) {
                // Offline Mode Info
                if offlineManager.isOfflineMode {
                    offlineModeInfo
                } else {
                    onlineModeInfo
                }
                
                // Sync Information
                syncInfo
                
                // Action Buttons
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Offline Mode Info
    private var offlineModeInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Chế độ ngoại tuyến", systemImage: "wifi.slash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
            
            let info = offlineManager.getOfflineModeInfo()
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(
                    icon: "book.closed",
                    title: "Bài tập có sẵn",
                    value: "\(info.cachedExercisesCount)"
                )
                
                InfoRow(
                    icon: "checkmark.circle",
                    title: "Tính năng hoạt động",
                    value: "Nhập văn bản, Đọc, Chấm điểm"
                )
                
                if info.pendingSyncCount > 0 {
                    InfoRow(
                        icon: "clock",
                        title: "Chờ đồng bộ",
                        value: "\(info.pendingSyncCount) phiên học"
                    )
                }
            }
        }
    }
    
    // MARK: - Online Mode Info
    private var onlineModeInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Đã kết nối mạng", systemImage: "wifi")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
            
            Text("Tất cả tính năng đều có sẵn")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Sync Info
    private var syncInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Đồng bộ dữ liệu", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
            
            let info = offlineManager.getOfflineModeInfo()
            
            if let lastSync = info.lastSyncDate {
                Text("Lần cuối: \(lastSync, formatter: dateFormatter)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                Text("Chưa đồng bộ lần nào")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Sync Now Button
            if !offlineManager.isOfflineMode && offlineManager.pendingSyncCount > 0 {
                Button(action: {
                    Task {
                        await offlineManager.forceSyncNow()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .medium))
                        Text("Đồng bộ ngay")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
            
            // Refresh Cache Button
            Button(action: {
                Task {
                    await offlineManager.refreshCache()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                    Text("Làm mới")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    private var statusBackgroundColor: Color {
        switch offlineManager.status {
        case .online:
            return Color.green.opacity(0.1)
        case .offline:
            return Color.orange.opacity(0.1)
        case .syncing:
            return Color.blue.opacity(0.1)
        }
    }
    
    private var statusIconColor: Color {
        switch offlineManager.status {
        case .online:
            return .green
        case .offline:
            return .orange
        case .syncing:
            return .blue
        }
    }
    
    private var statusTextColor: Color {
        switch offlineManager.status {
        case .online:
            return .green
        case .offline:
            return .orange
        case .syncing:
            return .blue
        }
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "vi-VN")
        return formatter
    }
}

// MARK: - Info Row Component
private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Compact Offline Status View
struct CompactOfflineStatusView: View {
    @ObservedObject var offlineManager: OfflineManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: offlineManager.status.icon)
                .foregroundColor(iconColor)
                .font(.system(size: 14, weight: .medium))
            
            if offlineManager.pendingSyncCount > 0 {
                Text("\(offlineManager.pendingSyncCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(12)
    }
    
    private var iconColor: Color {
        switch offlineManager.status {
        case .online:
            return .green
        case .offline:
            return .orange
        case .syncing:
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        switch offlineManager.status {
        case .online:
            return Color.green.opacity(0.1)
        case .offline:
            return Color.orange.opacity(0.1)
        case .syncing:
            return Color.blue.opacity(0.1)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        OfflineStatusView(offlineManager: OfflineManager())
        
        CompactOfflineStatusView(offlineManager: OfflineManager())
    }
    .padding()
}