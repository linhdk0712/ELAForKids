import SwiftUI

// MARK: - Audio Level Indicator
struct AudioLevelIndicator: View {
    let level: Float
    let barCount: Int = 20
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var animationPhase: Double = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                audioBar(for: index)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mức âm thanh")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private func audioBar(for index: Int) -> some View {
        let barLevel = Float(index) / Float(barCount - 1)
        let isActive = level > barLevel
        let height: CGFloat = isActive ? CGFloat.random(in: 4...20) : 4
        
        RoundedRectangle(cornerRadius: 1)
            .fill(colorForBar(index: index, isActive: isActive))
            .frame(width: 3, height: height)
            .animation(.easeInOut(duration: 0.1), value: isActive)
    }
    
    private func colorForBar(index: Int, isActive: Bool) -> Color {
        guard isActive else { return Color.gray.opacity(0.3) }
        
        let normalizedIndex = Float(index) / Float(barCount - 1)
        
        switch normalizedIndex {
        case 0.0..<0.6:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .red
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
            animationPhase += 1
        }
    }
    
    private var accessibilityValue: String {
        let percentage = Int(level * 100)
        switch percentage {
        case 0...20:
            return "Rất nhỏ, \(percentage) phần trăm"
        case 21...40:
            return "Nhỏ, \(percentage) phần trăm"
        case 41...60:
            return "Vừa phải, \(percentage) phần trăm"
        case 61...80:
            return "To, \(percentage) phần trăm"
        default:
            return "Rất to, \(percentage) phần trăm"
        }
    }
}

// MARK: - Instructions View
struct InstructionsView: View {
    let difficulty: DifficultyLevel
    let mode: PracticeMode
    let onStart: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Hướng dẫn luyện tập")
                        .font(.title)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Cấp độ: \(difficulty.localizedName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    instructionItem(
                        icon: "1.circle.fill",
                        title: "Đọc kỹ đoạn văn",
                        description: "Đọc thầm đoạn văn để hiểu nội dung"
                    )
                    
                    instructionItem(
                        icon: "2.circle.fill",
                        title: "Chọn cách nhập",
                        description: "Chọn gõ phím, viết tay hoặc nói"
                    )
                    
                    instructionItem(
                        icon: "3.circle.fill",
                        title: "Nhập lại đoạn văn",
                        description: "Nhập lại đoạn văn theo cách đã chọn"
                    )
                    
                    instructionItem(
                        icon: "4.circle.fill",
                        title: "Xem kết quả",
                        description: "Xem điểm số và những chỗ cần cải thiện"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Tips
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Mẹo nhỏ")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        tipItem("Đọc chậm và rõ ràng")
                        tipItem("Tập trung vào từng từ")
                        tipItem("Không vội vàng, cẩn thận là quan trọng nhất")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                )
                .padding(.horizontal, 20)
                
                // Start button
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Bắt đầu luyện tập")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .accessibilityLabel("Bắt đầu luyện tập")
                .accessibilityHint("Nhấn đúp để bắt đầu bài luyện tập \(difficulty.localizedName)")
                .accessibilityAddTraits(.isButton)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private func instructionItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
    
    @ViewBuilder
    private func tipItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct AudioLevelIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AudioLevelIndicator(level: 0.3)
            AudioLevelIndicator(level: 0.7)
            AudioLevelIndicator(level: 1.0)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsView(
            difficulty: .grade2,
            mode: .normal,
            onStart: {}
        )
    }
}