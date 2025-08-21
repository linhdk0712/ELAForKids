import SwiftUI
import AVFoundation

struct ReadingView: View {
    let text: String
    @StateObject private var viewModel = ReadingViewModel()
    @Environment(\.navigationCoordinator) private var navigationCoordinator
    @Environment(\.adaptiveLayout) private var layout
    
    var body: some View {
        ResponsiveLayout {
            AdaptiveContainer {
                AdaptiveStack(spacing: layout.sectionSpacing) {
                    // Header Section
                    headerSection
                    
                    // Text Display Section
                    textDisplaySection
                    
                    // Audio Controls Section
                    audioControlsSection
                    
                    // Recording Status Section
                    if viewModel.state.isRecording || viewModel.state.isProcessing {
                        recordingStatusSection
                    }
                    
                    // Audio Quality Indicator
                    if viewModel.state.isRecording {
                        audioQualitySection
                    }
                    
                    // Action Buttons
                    actionButtonsSection
                }
            }
        }
        .adaptiveLayout()
        .navigationTitle("Đọc văn bản")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.send(.loadText(text))
        }
        .alert("Lỗi ghi âm", isPresented: .constant(viewModel.state.error != nil)) {
            Button("Đóng") {
                viewModel.send(.clearError)
            }
            Button("Thử lại") {
                viewModel.send(.retryRecording)
            }
        } message: {
            if let error = viewModel.state.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 2) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: headerIconSize))
                    .foregroundColor(.blue)
                
                AdaptiveText("Hãy đọc to đoạn văn bản", style: .title)
                    .multilineTextAlignment(.center)
                
                AdaptiveText("Đọc chậm và rõ ràng để có kết quả tốt nhất", style: .caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Text Display Section
    private var textDisplaySection: some View {
        AdaptiveCard {
            VStack(alignment: .leading, spacing: layout.sectionSpacing / 2) {
                AdaptiveText("Văn bản cần đọc:", style: .headline)
                
                ScrollView {
                    AdaptiveText(text, style: .body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(layout.contentPadding / 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(layout.cornerRadius)
                }
                .frame(maxHeight: textDisplayHeight)
            }
        }
    }
    
    // MARK: - Audio Controls Section
    private var audioControlsSection: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 2) {
                // Recording Button
                Button(action: {
                    if viewModel.state.isRecording {
                        viewModel.send(.stopRecording)
                    } else {
                        viewModel.send(.startRecording)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: recordingButtonIcon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        AdaptiveText(recordingButtonTitle, style: .headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: layout.buttonHeight)
                    .background(recordingButtonColor)
                    .cornerRadius(layout.cornerRadius)
                }
                .disabled(viewModel.state.isProcessing)
                
                // Playback Button (if recording exists)
                if viewModel.hasRecording {
                    Button(action: {
                        if viewModel.state.isPlaying {
                            viewModel.send(.stopPlayback)
                        } else {
                            viewModel.send(.startPlayback)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: playbackButtonIcon)
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            AdaptiveText(playbackButtonTitle, style: .body)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: layout.buttonHeight * 0.8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(layout.cornerRadius)
                    }
                }
            }
        }
    }
    
    // MARK: - Recording Status Section
    private var recordingStatusSection: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 3) {
                if viewModel.state.isRecording {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(viewModel.state.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(), value: viewModel.state.isRecording)
                        
                        AdaptiveText("Đang ghi âm...", style: .headline)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        AdaptiveText(formattedDuration, style: .body)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.state.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        AdaptiveText("Đang xử lý âm thanh...", style: .headline)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Quality Section
    private var audioQualitySection: some View {
        AdaptiveCard {
            VStack(spacing: layout.sectionSpacing / 3) {
                HStack {
                    AdaptiveText("Chất lượng âm thanh:", style: .headline)
                    Spacer()
                    AudioQualityIndicator(quality: viewModel.audioQuality)
                }
                
                // Audio Level Meter
                AudioLevelMeter(level: viewModel.state.audioLevel)
                
                // Quality Suggestions
                if !viewModel.audioQuality.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.audioQuality.suggestions.prefix(2), id: \.self) { suggestion in
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                AdaptiveText(suggestion, style: .caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        OrientationLayout {
            // Portrait Layout
            VStack(spacing: layout.sectionSpacing / 2) {
                continueButton
                retryButton
            }
        } landscape: {
            // Landscape Layout
            HStack(spacing: layout.sectionSpacing) {
                retryButton
                continueButton
            }
        }
    }
    
    private var continueButton: some View {
        AdaptiveButton(
            "Tiếp tục",
            icon: "arrow.right.circle.fill",
            style: .primary
        ) {
            viewModel.send(.processRecording)
        }
        .disabled(!viewModel.canContinue)
    }
    
    private var retryButton: some View {
        AdaptiveButton(
            "Ghi lại",
            icon: "arrow.clockwise",
            style: .secondary
        ) {
            viewModel.send(.retryRecording)
        }
        .disabled(!viewModel.hasRecording)
    }
    
    // MARK: - Computed Properties
    private var headerIconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 50
        case .regular: return 60
        case .large: return 70
        }
    }
    
    private var textDisplayHeight: CGFloat {
        switch (layout.deviceType, layout.orientation) {
        case (.iPhone, .portrait): return 150
        case (.iPhone, .landscape): return 100
        case (.iPad, .portrait): return 200
        case (.iPad, .landscape): return 150
        case (.mac, _): return 200
        }
    }
    
    private var recordingButtonIcon: String {
        viewModel.state.isRecording ? "stop.circle.fill" : "mic.circle.fill"
    }
    
    private var recordingButtonTitle: String {
        viewModel.state.isRecording ? "Dừng ghi âm" : "Bắt đầu đọc"
    }
    
    private var recordingButtonColor: Color {
        viewModel.state.isRecording ? .red : .green
    }
    
    private var playbackButtonIcon: String {
        viewModel.state.isPlaying ? "pause.circle" : "play.circle"
    }
    
    private var playbackButtonTitle: String {
        viewModel.state.isPlaying ? "Dừng phát" : "Nghe lại"
    }
    
    private var formattedDuration: String {
        let duration = viewModel.state.recordingDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Quality Indicator
struct AudioQualityIndicator: View {
    let quality: AudioQuality
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: quality.icon)
                .font(.caption)
                .foregroundColor(Color(quality.color))
            
            Text(quality.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(quality.color))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(quality.color).opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Audio Level Meter
struct AudioLevelMeter: View {
    let level: Float
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Âm lượng")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(level * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(levelColor)
                        .frame(width: geometry.size.width * CGFloat(level), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.1), value: level)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var levelColor: Color {
        switch level {
        case 0.7...1.0: return .green
        case 0.3..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview
struct ReadingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReadingView(text: "Con mèo nhỏ ngồi trên thảm xanh. Nó có bộ lông mềm mại và đôi mắt sáng.")
                .withNavigationCoordinator(NavigationCoordinator())
        }
    }
}