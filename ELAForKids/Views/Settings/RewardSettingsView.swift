import SwiftUI

// MARK: - Reward Settings View
struct RewardSettingsView: View {
    @StateObject private var soundManager = SoundEffectManager()
    @StateObject private var hapticManager = HapticFeedbackManager()
    @StateObject private var animationService = RewardAnimationService()
    
    @State private var showingTestReward = false
    @State private var selectedTestReward: TestRewardType = .perfectScore
    
    var body: some View {
        NavigationView {
            Form {
                // Sound Settings Section
                soundSettingsSection
                
                // Haptic Settings Section
                hapticSettingsSection
                
                // Animation Settings Section
                animationSettingsSection
                
                // Test Rewards Section
                testRewardsSection
            }
            .navigationTitle("Cài đặt Phần thưởng")
            .navigationBarTitleDisplayMode(.large)
        }
        .overlay {
            if showingTestReward {
                RewardOverlayView(rewardService: animationService)
            }
        }
    }
    
    // MARK: - Sound Settings Section
    
    @ViewBuilder
    private var soundSettingsSection: some View {
        Section {
            // Sound Toggle
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Âm thanh phần thưởng")
                        .font(.body)
                    Text("Phát âm thanh khi đạt thành tích")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { soundManager.isSoundEnabled() },
                    set: { soundManager.setSoundEnabled($0) }
                ))
            }
            
            // Volume Slider
            if soundManager.isSoundEnabled() {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    
                    Text("Âm lượng")
                    
                    Spacer()
                    
                    Slider(
                        value: Binding(
                            get: { soundManager.getVolume() },
                            set: { soundManager.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 120)
                    
                    Button(action: {
                        soundManager.playRewardSound(.great)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Voice Encouragement
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lời động viên bằng giọng nói")
                        .font(.body)
                    Text("Phát lời động viên khi hoàn thành")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(true)) // Would be connected to actual setting
            }
            
        } header: {
            Label("Âm thanh", systemImage: "speaker.wave.2")
        } footer: {
            Text("Âm thanh giúp tạo cảm giác thành tựu khi bé hoàn thành bài học.")
        }
    }
    
    // MARK: - Haptic Settings Section
    
    @ViewBuilder
    private var hapticSettingsSection: some View {
        Section {
            // Haptic Toggle
            HStack {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rung phản hồi")
                        .font(.body)
                    Text("Rung khi đạt thành tích")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { hapticManager.isHapticsEnabled() },
                    set: { hapticManager.setHapticsEnabled($0) }
                ))
            }
            
            // Haptic Intensity
            if hapticManager.isHapticsEnabled() {
                HStack {
                    Image(systemName: "hand.point.up.braille.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    
                    Text("Cường độ rung")
                    
                    Spacer()
                    
                    Slider(
                        value: Binding(
                            get: { hapticManager.getHapticIntensity() },
                            set: { hapticManager.setHapticIntensity($0) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 120)
                    
                    Button(action: {
                        hapticManager.playRewardHaptic(.perfectScore)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
        } header: {
            Label("Rung phản hồi", systemImage: "iphone.radiowaves.left.and.right")
        } footer: {
            Text("Rung phản hồi giúp bé cảm nhận được thành tựu qua xúc giác.")
        }
    }
    
    // MARK: - Animation Settings Section
    
    @ViewBuilder
    private var animationSettingsSection: some View {
        Section {
            // Animation Toggle
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hiệu ứng hoạt hình")
                        .font(.body)
                    Text("Hiển thị hoạt hình khi đạt thành tích")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(true)) // Would be connected to actual setting
            }
            
            // Animation Style Picker
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Text("Kiểu hoạt hình")
                
                Spacer()
                
                Picker("Animation Style", selection: .constant("full")) {
                    Text("Đầy đủ").tag("full")
                    Text("Đơn giản").tag("simple")
                    Text("Tối thiểu").tag("minimal")
                }
                .pickerStyle(.menu)
            }
            
            // Confetti Toggle
            HStack {
                Image(systemName: "party.popper.fill")
                    .foregroundColor(.pink)
                    .frame(width: 24)
                
                Text("Hiệu ứng pháo giấy")
                
                Spacer()
                
                Toggle("", isOn: .constant(true))
            }
            
        } header: {
            Label("Hoạt hình", systemImage: "sparkles")
        } footer: {
            Text("Hoạt hình tạo cảm giác vui vẻ và động lực cho bé.")
        }
    }
    
    // MARK: - Test Rewards Section
    
    @ViewBuilder
    private var testRewardsSection: some View {
        Section {
            // Test Reward Picker
            HStack {
                Image(systemName: "testtube.2")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Loại phần thưởng")
                
                Spacer()
                
                Picker("Test Reward", selection: $selectedTestReward) {
                    ForEach(TestRewardType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Test Button
            Button(action: {
                testReward(selectedTestReward)
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                    
                    Text("Thử nghiệm phần thưởng")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
        } header: {
            Label("Thử nghiệm", systemImage: "testtube.2")
        } footer: {
            Text("Thử nghiệm các loại phần thưởng để xem hiệu ứng.")
        }
    }
    
    // MARK: - Test Methods
    
    private func testReward(_ type: TestRewardType) {
        showingTestReward = true
        
        switch type {
        case .perfectScore:
            animationService.showPerfectScoreReward(score: 100)
            soundManager.playRewardSound(.epic)
            hapticManager.playRewardHaptic(.perfectScore)
            
        case .achievement:
            let testAchievement = Achievement(
                id: "test_achievement",
                title: "Thành tích thử nghiệm",
                description: "Đây là thành tích để thử nghiệm",
                category: .reading,
                difficulty: .gold,
                requirementType: .readSessions,
                requirementTarget: 10
            )
            animationService.showAchievementReward(achievement: testAchievement)
            soundManager.playRewardSound(.excellent)
            hapticManager.playRewardHaptic(.achievement(.gold))
            
        case .streak:
            let testMilestone = StreakMilestone(
                streak: 7,
                title: "Một tuần hoàn hảo!",
                description: "Bé đã đọc đúng 7 lần liên tiếp!",
                reward: StreakReward(bonusPoints: 70, badge: "🏆", specialEffect: "confetti")
            )
            animationService.showStreakReward(streak: 7, milestone: testMilestone)
            soundManager.playStreakSound(streak: 7)
            hapticManager.playRewardHaptic(.streak(7))
            
        case .levelUp:
            animationService.showLevelUpReward(newLevel: 5, levelTitle: "Chuyên gia đọc")
            soundManager.playRewardSound(.legendary)
            hapticManager.playRewardHaptic(.levelUp)
            
        case .highAccuracy:
            animationService.showHighAccuracyReward(accuracy: 0.95)
            soundManager.playRewardSound(.excellent)
            hapticManager.playRewardHaptic(.highAccuracy)
            
        case .speedBonus:
            animationService.showSpeedBonusReward(timeBonus: 25)
            soundManager.playRewardSound(.bonus)
            hapticManager.playRewardHaptic(.speedBonus)
        }
        
        // Hide test reward after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            showingTestReward = false
        }
    }
}

// MARK: - Test Reward Types
enum TestRewardType: CaseIterable {
    case perfectScore
    case achievement
    case streak
    case levelUp
    case highAccuracy
    case speedBonus
    
    var displayName: String {
        switch self {
        case .perfectScore:
            return "Điểm hoàn hảo"
        case .achievement:
            return "Thành tích"
        case .streak:
            return "Chuỗi học tập"
        case .levelUp:
            return "Lên cấp"
        case .highAccuracy:
            return "Độ chính xác cao"
        case .speedBonus:
            return "Thưởng tốc độ"
        }
    }
}

// MARK: - Preview
struct RewardSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RewardSettingsView()
    }
}