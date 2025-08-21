import SwiftUI
import PencilKit

// MARK: - Pencil Toolbar
struct PencilToolbar: View {
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onRecognize: () -> Void
    let canUndo: Bool
    let canRedo: Bool
    let canClear: Bool
    let canRecognize: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Undo Button
            ToolbarActionButton(
                icon: "arrow.uturn.backward",
                title: "Hoàn tác",
                color: .blue,
                action: onUndo
            )
            .disabled(!canUndo)
            
            // Redo Button
            ToolbarActionButton(
                icon: "arrow.uturn.forward",
                title: "Làm lại",
                color: .blue,
                action: onRedo
            )
            .disabled(!canRedo)
            
            Spacer()
            
            // Clear Button
            ToolbarActionButton(
                icon: "trash",
                title: "Xóa hết",
                color: .red,
                action: onClear
            )
            .disabled(!canClear)
            
            // Recognize Button
            ToolbarActionButton(
                icon: "textformat",
                title: "Nhận dạng",
                color: .green,
                action: onRecognize
            )
            .disabled(!canRecognize)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Toolbar Action Button
struct ToolbarActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pencil Settings Panel
struct PencilSettingsPanel: View {
    @Binding var strokeWidth: CGFloat
    @Binding var opacity: Double
    @Binding var showRuler: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cài đặt Apple Pencil")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Stroke Width
            VStack(alignment: .leading, spacing: 8) {
                Text("Độ dày nét vẽ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Mỏng")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $strokeWidth, in: 1...10, step: 1)
                    
                    Text("Dày")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Opacity
            VStack(alignment: .leading, spacing: 8) {
                Text("Độ trong suốt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Mờ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.1)
                    
                    Text("Đậm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Show Ruler Toggle
            Toggle("Hiển thị thước kẻ", isOn: $showRuler)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Drawing Quality Indicator
struct DrawingQualityIndicator: View {
    let quality: RecognitionQuality
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: quality.icon)
                .font(.title3)
                .foregroundColor(Color(quality.color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Chất lượng viết")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(quality.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(quality.color))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(quality.color).opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Pencil Status View
struct PencilStatusView: View {
    let isConnected: Bool
    let batteryLevel: Float?
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection Status
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(isConnected ? "Đã kết nối" : "Chưa kết nối")
                    .font(.caption)
                    .foregroundColor(isConnected ? .green : .red)
            }
            
            // Battery Level (if available)
            if let batteryLevel = batteryLevel, isConnected {
                HStack(spacing: 4) {
                    Image(systemName: batteryIcon(for: batteryLevel))
                        .font(.caption)
                        .foregroundColor(batteryColor(for: batteryLevel))
                    
                    Text("\(Int(batteryLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func batteryIcon(for level: Float) -> String {
        switch level {
        case 0.75...1.0:
            return "battery.100"
        case 0.5..<0.75:
            return "battery.75"
        case 0.25..<0.5:
            return "battery.50"
        case 0.1..<0.25:
            return "battery.25"
        default:
            return "battery.0"
        }
    }
    
    private func batteryColor(for level: Float) -> Color {
        switch level {
        case 0.3...1.0:
            return .green
        case 0.15..<0.3:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Handwriting Practice Guide
struct HandwritingPracticeGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hướng dẫn viết chữ đẹp")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                GuideStep(
                    number: 1,
                    title: "Cầm bút đúng cách",
                    description: "Cầm Apple Pencil như cầm bút chì thông thường"
                )
                
                GuideStep(
                    number: 2,
                    title: "Tư thế ngồi thẳng",
                    description: "Ngồi thẳng lưng, iPad đặt nghiêng vừa phải"
                )
                
                GuideStep(
                    number: 3,
                    title: "Viết chậm và đều",
                    description: "Viết từng chữ một cách chậm rãi và rõ ràng"
                )
                
                GuideStep(
                    number: 4,
                    title: "Khoảng cách đều",
                    description: "Để khoảng cách đều giữa các từ"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Guide Step
struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step Number
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            // Step Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct PencilToolbar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PencilToolbar(
                onUndo: {},
                onRedo: {},
                onClear: {},
                onRecognize: {},
                canUndo: true,
                canRedo: false,
                canClear: true,
                canRecognize: true
            )
            
            DrawingQualityIndicator(quality: .good)
            
            PencilStatusView(isConnected: true, batteryLevel: 0.75)
            
            HandwritingPracticeGuide()
        }
        .padding()
    }
}