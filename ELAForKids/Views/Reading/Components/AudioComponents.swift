import SwiftUI
import AVFoundation

// MARK: - Audio Waveform Visualizer
struct AudioWaveformView: View {
    let audioLevels: [Float]
    let isRecording: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<audioLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: audioLevels[index]))
                    .frame(width: 3, height: barHeight(for: audioLevels[index]))
                    .animation(.easeInOut(duration: 0.1), value: audioLevels[index])
            }
        }
        .frame(height: 60)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func barHeight(for level: Float) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 60
        return minHeight + (maxHeight - minHeight) * CGFloat(level)
    }
    
    private func barColor(for level: Float) -> Color {
        if !isRecording {
            return .gray
        }
        
        switch level {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Recording Timer
struct RecordingTimer: View {
    let duration: TimeInterval
    let isRecording: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if isRecording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: isRecording)
            }
            
            Text(formattedTime)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(isRecording ? .red : .primary)
        }
    }
    
    private var formattedTime: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Permission View
struct AudioPermissionView: View {
    let onRequestPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Cần quyền microphone")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Ứng dụng cần quyền sử dụng microphone để ghi âm giọng đọc của bé.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRequestPermission) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                    Text("Cấp quyền microphone")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Audio Environment Indicator
struct AudioEnvironmentIndicator: View {
    let quality: AudioEnvironmentQuality
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: environmentIcon)
                .font(.title3)
                .foregroundColor(environmentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Môi trường âm thanh")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(quality.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(environmentColor)
            }
            
            Spacer()
            
            Button(action: {
                // Show environment tips
            }) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(environmentColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var environmentIcon: String {
        switch quality {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .fair: return "exclamationmark.triangle"
        case .poor: return "xmark.circle.fill"
        }
    }
    
    private var environmentColor: Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - Playback Controls
struct PlaybackControls: View {
    let isPlaying: Bool
    let duration: TimeInterval
    let currentTime: TimeInterval
    let onPlay: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let onSeek: (TimeInterval) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: duration > 0 ? currentTime / duration : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
            }
            
            // Control Buttons
            HStack(spacing: 30) {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .disabled(duration == 0)
                
                Button(action: isPlaying ? onPause : onPlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                .disabled(duration == 0)
                
                Button(action: {
                    // Skip forward 5 seconds
                    let newTime = min(currentTime + 5, duration)
                    onSeek(newTime)
                }) {
                    Image(systemName: "goforward.5")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .disabled(duration == 0)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recording Instructions
struct RecordingInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hướng dẫn ghi âm")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(
                    icon: "1.circle.fill",
                    text: "Đọc chậm và rõ ràng",
                    color: .blue
                )
                
                InstructionRow(
                    icon: "2.circle.fill",
                    text: "Giữ khoảng cách 20-30cm với microphone",
                    color: .green
                )
                
                InstructionRow(
                    icon: "3.circle.fill",
                    text: "Tránh tiếng ồn xung quanh",
                    color: .orange
                )
                
                InstructionRow(
                    icon: "4.circle.fill",
                    text: "Nhấn 'Dừng' khi đọc xong",
                    color: .purple
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Audio Feedback View
struct AudioFeedbackView: View {
    let feedback: String
    let accuracy: Float
    
    var body: some View {
        VStack(spacing: 12) {
            // Accuracy Circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(accuracy))
                    .stroke(accuracyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: accuracy)
                
                Text("\(Int(accuracy * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(accuracyColor)
            }
            
            // Feedback Text
            Text(feedback)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var accuracyColor: Color {
        switch accuracy {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview
struct AudioComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AudioWaveformView(
                audioLevels: [0.3, 0.7, 0.5, 0.9, 0.4, 0.6, 0.8, 0.2],
                isRecording: true
            )
            
            RecordingTimer(duration: 125, isRecording: true)
            
            AudioEnvironmentIndicator(quality: .good)
            
            RecordingInstructions()
            
            AudioFeedbackView(feedback: "Tuyệt vời! Bé đọc rất hay!", accuracy: 0.85)
        }
        .padding()
    }
}