import SwiftUI

// MARK: - Badge View
struct BadgeView: View {
    let badge: BadgeInfo
    let isUnlocked: Bool
    let size: BadgeSize
    let showAnimation: Bool
    
    @Environment(\.adaptiveLayout) private var layout
    @State private var isAnimating: Bool = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    
    init(
        badge: BadgeInfo,
        isUnlocked: Bool = true,
        size: BadgeSize = .medium,
        showAnimation: Bool = true
    ) {
        self.badge = badge
        self.isUnlocked = isUnlocked
        self.size = size
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundGradient)
                .frame(width: badgeSize, height: badgeSize)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            
            // Badge content
            badgeContent
                .frame(width: contentSize, height: contentSize)
                .scaleEffect(isUnlocked ? 1.0 : 0.7)
                .opacity(isUnlocked ? 1.0 : 0.4)
            
            // Glow effect for rare badges
            if badge.rarity != .common && isUnlocked {
                Circle()
                    .fill(glowColor)
                    .frame(width: badgeSize * 1.2, height: badgeSize * 1.2)
                    .opacity(glowOpacity)
                    .blur(radius: 10)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowOpacity)
            }
            
            // Lock overlay for locked badges
            if !isUnlocked {
                lockOverlay
            }
        }
        .scaleEffect(pulseScale)
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            if showAnimation && isUnlocked {
                startAnimation()
            }
        }
        .onChange(of: isUnlocked) { unlocked in
            if unlocked && showAnimation {
                startUnlockAnimation()
            }
        }
    }
    
    // MARK: - Badge Content
    private var badgeContent: some View {
        Group {
            if badge.imageName.isEmpty {
                // Use emoji if no image
                Text(badge.emoji)
                    .font(.system(size: emojiSize))
            } else {
                // Use image if available
                Image(badge.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(contentColor)
            }
        }
    }
    
    // MARK: - Lock Overlay
    private var lockOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: badgeSize, height: badgeSize)
            
            Image(systemName: "lock.fill")
                .font(.system(size: lockIconSize))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Computed Properties
    private var badgeSize: CGFloat {
        switch size {
        case .small:
            return 40
        case .medium:
            return 60
        case .large:
            return 80
        case .extraLarge:
            return 100
        }
    }
    
    private var contentSize: CGFloat {
        badgeSize * 0.6
    }
    
    private var emojiSize: CGFloat {
        badgeSize * 0.4
    }
    
    private var lockIconSize: CGFloat {
        badgeSize * 0.3
    }
    
    private var borderWidth: CGFloat {
        switch badge.rarity {
        case .common:
            return 2
        case .uncommon:
            return 3
        case .rare:
            return 4
        case .epic:
            return 5
        case .legendary:
            return 6
        }
    }
    
    private var shadowRadius: CGFloat {
        switch badge.rarity {
        case .common:
            return 2
        case .uncommon:
            return 4
        case .rare:
            return 6
        case .epic:
            return 8
        case .legendary:
            return 10
        }
    }
    
    private var shadowOffset: CGFloat {
        shadowRadius / 2
    }
    
    private var backgroundGradient: LinearGradient {
        let colors = rarityColors(for: badge.rarity)
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderColor: Color {
        if !isUnlocked {
            return Color.gray
        }
        
        switch badge.rarity {
        case .common:
            return Color.gray
        case .uncommon:
            return Color.green
        case .rare:
            return Color.blue
        case .epic:
            return Color.purple
        case .legendary:
            return Color.orange
        }
    }
    
    private var contentColor: Color {
        isUnlocked ? .primary : .secondary
    }
    
    private var shadowColor: Color {
        if !isUnlocked {
            return Color.clear
        }
        
        return borderColor.opacity(0.3)
    }
    
    private var glowColor: Color {
        borderColor.opacity(0.3)
    }
    
    private func rarityColors(for rarity: BadgeRarity) -> [Color] {
        if !isUnlocked {
            return [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]
        }
        
        switch rarity {
        case .common:
            return [Color.gray.opacity(0.8), Color.gray.opacity(0.4)]
        case .uncommon:
            return [Color.green.opacity(0.8), Color.green.opacity(0.4)]
        case .rare:
            return [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]
        case .epic:
            return [Color.purple.opacity(0.8), Color.purple.opacity(0.4)]
        case .legendary:
            return [Color.orange.opacity(0.8), Color.yellow.opacity(0.6)]
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimation() {
        guard showAnimation else { return }
        
        switch badge.animationType {
        case .none:
            break
        case .pulse:
            startPulseAnimation()
        case .glow:
            startGlowAnimation()
        case .sparkle:
            startSparkleAnimation()
        case .bounce:
            startBounceAnimation()
        case .rotate:
            startRotateAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: badge.animationType.duration).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: badge.animationType.duration).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
    
    private func startSparkleAnimation() {
        // Combine pulse and glow for sparkle effect
        startPulseAnimation()
        startGlowAnimation()
    }
    
    private func startBounceAnimation() {
        withAnimation(.easeInOut(duration: badge.animationType.duration).repeatForever()) {
            pulseScale = 1.0
        }
        
        Timer.scheduledTimer(withTimeInterval: badge.animationType.duration, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.2)) {
                    pulseScale = 1.0
                }
            }
        }
    }
    
    private func startRotateAnimation() {
        withAnimation(.linear(duration: badge.animationType.duration).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func startUnlockAnimation() {
        // Special animation when badge is unlocked
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            pulseScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                pulseScale = 1.0
            }
        }
        
        // Start regular animation after unlock animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startAnimation()
        }
    }
}

// MARK: - Badge Size Enum
enum BadgeSize: CaseIterable {
    case small
    case medium
    case large
    case extraLarge
    
    var displayName: String {
        switch self {
        case .small:
            return "Nhỏ"
        case .medium:
            return "Vừa"
        case .large:
            return "Lớn"
        case .extraLarge:
            return "Rất lớn"
        }
    }
}

// MARK: - Badge Collection View
struct BadgeCollectionView: View {
    let badges: [BadgeInfo]
    let unlockedBadgeIds: Set<String>
    let columns: Int
    let onBadgeTap: ((BadgeInfo) -> Void)?
    
    @Environment(\.adaptiveLayout) private var layout
    
    init(
        badges: [BadgeInfo],
        unlockedBadgeIds: Set<String> = [],
        columns: Int = 3,
        onBadgeTap: ((BadgeInfo) -> Void)? = nil
    ) {
        self.badges = badges
        self.unlockedBadgeIds = unlockedBadgeIds
        self.columns = columns
        self.onBadgeTap = onBadgeTap
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: layout.sectionSpacing / 2) {
            ForEach(badges, id: \.id) { badge in
                Button(action: {
                    onBadgeTap?(badge)
                }) {
                    VStack(spacing: 8) {
                        BadgeView(
                            badge: badge,
                            isUnlocked: unlockedBadgeIds.contains(badge.id),
                            size: .medium,
                            showAnimation: true
                        )
                        
                        Text(badge.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onBadgeTap == nil)
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: layout.sectionSpacing / 2), count: columns)
    }
}

// MARK: - Badge Detail View
struct BadgeDetailView: View {
    let badge: BadgeInfo
    let isUnlocked: Bool
    let unlockedAt: Date?
    let onClose: () -> Void
    
    @Environment(\.adaptiveLayout) private var layout
    
    var body: some View {
        VStack(spacing: layout.sectionSpacing) {
            // Header
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Badge display
            BadgeView(
                badge: badge,
                isUnlocked: isUnlocked,
                size: .extraLarge,
                showAnimation: true
            )
            
            // Badge info
            VStack(spacing: layout.sectionSpacing / 2) {
                Text(badge.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(badge.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Rarity indicator
                HStack {
                    Text("Độ hiếm:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(badge.rarity.localizedName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(rarityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(rarityColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Unlock date
                if let unlockedAt = unlockedAt {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Mở khóa: \(formattedDate(unlockedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(layout.contentPadding)
        .background(Color(.systemBackground))
        .cornerRadius(layout.cornerRadius)
        .shadow(radius: 10)
    }
    
    private var rarityColor: Color {
        switch badge.rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return .orange
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

// MARK: - Badge Progress View
struct BadgeProgressView: View {
    let badge: BadgeInfo
    let progress: AchievementProgress
    
    @Environment(\.adaptiveLayout) private var layout
    
    var body: some View {
        VStack(spacing: layout.sectionSpacing / 2) {
            HStack {
                BadgeView(
                    badge: badge,
                    isUnlocked: progress.isCompleted,
                    size: .small,
                    showAnimation: false
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(badge.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(badge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(progress.current)/\(progress.target)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(progress.percentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(progress.normalizedProgress), height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.5), value: progress.normalizedProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(layout.contentPadding / 2)
        .background(Color(.systemGray6))
        .cornerRadius(layout.cornerRadius / 2)
    }
    
    private var progressColor: Color {
        if progress.isCompleted {
            return .green
        } else if progress.percentage >= 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Preview
struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBadge = BadgeInfo(
            id: "sample",
            name: "Người mới bắt đầu",
            description: "Hoàn thành bài đọc đầu tiên",
            imageName: "",
            emoji: "🎉",
            rarity: .uncommon,
            animationType: .pulse
        )
        
        VStack(spacing: 20) {
            // Single badge
            BadgeView(
                badge: sampleBadge,
                isUnlocked: true,
                size: .large,
                showAnimation: true
            )
            
            // Locked badge
            BadgeView(
                badge: sampleBadge,
                isUnlocked: false,
                size: .large,
                showAnimation: false
            )
            
            // Badge collection
            BadgeCollectionView(
                badges: [sampleBadge, sampleBadge, sampleBadge],
                unlockedBadgeIds: [sampleBadge.id],
                columns: 3
            )
        }
        .padding()
        .adaptiveLayout()
    }
}