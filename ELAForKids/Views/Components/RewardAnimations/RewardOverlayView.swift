import SwiftUI

// MARK: - Reward Overlay View
struct RewardOverlayView: View {
    @ObservedObject var rewardService: RewardAnimationService
    
    var body: some View {
        ZStack {
            if rewardService.isShowingReward {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                // Reward content
                VStack(spacing: 20) {
                    // Main reward animation
                    rewardAnimationView
                    
                    // Reward message
                    Text(rewardService.rewardMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: rewardService.isShowingReward)
    }
    
    @ViewBuilder
    private var rewardAnimationView: some View {
        ZStack {
            // Background animations
            backgroundAnimations
            
            // Main reward icon
            mainRewardIcon
                .scaleEffect(rewardService.isShowingReward ? 1.0 : 0.1)
                .rotationEffect(.degrees(rewardService.isShowingReward ? 0 : -180))
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: rewardService.isShowingReward)
        }
        .frame(width: 200, height: 200)
    }
    
    @ViewBuilder
    private var backgroundAnimations: some View {
        // Confetti animation
        ConfettiView(trigger: rewardService.confettiTrigger)
            .opacity(shouldShowConfetti ? 1 : 0)
        
        // Star burst animation
        StarBurstView(trigger: rewardService.starBurstTrigger)
            .opacity(shouldShowStarBurst ? 1 : 0)
        
        // Fireworks animation
        FireworksView(trigger: rewardService.fireworksTrigger)
            .opacity(shouldShowFireworks ? 1 : 0)
    }
    
    @ViewBuilder
    private var mainRewardIcon: some View {
        if let rewardType = rewardService.currentRewardType {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [rewardType.primaryColor.opacity(0.8), rewardType.primaryColor.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(rewardService.isShowingReward ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: rewardService.isShowingReward)
                
                // Main icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [rewardType.primaryColor, rewardType.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: rewardType.primaryColor.opacity(0.5), radius: 10, x: 0, y: 5)
                
                // Icon content
                rewardIconContent(for: rewardType)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    @ViewBuilder
    private func rewardIconContent(for type: RewardType) -> some View {
        switch type {
        case .achievement:
            Image(systemName: "trophy.fill")
        case .perfectScore:
            Image(systemName: "star.fill")
        case .streak:
            Image(systemName: "flame.fill")
        case .levelUp:
            Image(systemName: "arrow.up.circle.fill")
        case .goalCompletion:
            Image(systemName: "checkmark.circle.fill")
        case .highAccuracy:
            Image(systemName: "target")
        case .speedBonus:
            Image(systemName: "bolt.fill")
        case .firstAttempt:
            Image(systemName: "hand.thumbsup.fill")
        case .improvement:
            Image(systemName: "chart.line.uptrend.xyaxis")
        case .consistency:
            Image(systemName: "calendar.badge.checkmark")
        }
    }
    
    // MARK: - Animation Conditions
    
    private var shouldShowConfetti: Bool {
        guard let rewardType = rewardService.currentRewardType else { return false }
        return rewardType.animationType == .confetti
    }
    
    private var shouldShowStarBurst: Bool {
        guard let rewardType = rewardService.currentRewardType else { return false }
        return rewardType.animationType == .starBurst
    }
    
    private var shouldShowFireworks: Bool {
        guard let rewardType = rewardService.currentRewardType else { return false }
        return rewardType.animationType == .fireworks
    }
}

// MARK: - Confetti Animation View
struct ConfettiView: View {
    let trigger: Int
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Rectangle()
                    .fill(particle.color)
                    .frame(width: particle.size.width, height: particle.size.height)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: trigger) { _ in
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        particles.removeAll()
        
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                id: UUID(),
                position: CGPoint(x: Double.random(in: 50...350), y: -20),
                color: colors.randomElement() ?? .blue,
                size: CGSize(
                    width: Double.random(in: 4...12),
                    height: Double.random(in: 4...12)
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        withAnimation(.easeOut(duration: 3.0)) {
            for i in particles.indices {
                particles[i].position.y += Double.random(in: 400...600)
                particles[i].rotation += Double.random(in: 180...720)
                particles[i].opacity = 0.0
            }
        }
        
        // Clean up particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            particles.removeAll()
        }
    }
}

// MARK: - Star Burst Animation View
struct StarBurstView: View {
    let trigger: Int
    @State private var stars: [StarParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(stars, id: \.id) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: star.size))
                    .foregroundColor(star.color)
                    .position(star.position)
                    .opacity(star.opacity)
                    .scaleEffect(star.scale)
            }
        }
        .onChange(of: trigger) { _ in
            generateStarBurst()
        }
    }
    
    private func generateStarBurst() {
        stars.removeAll()
        
        let colors: [Color] = [.yellow, .orange, .white, .cyan]
        let center = CGPoint(x: 200, y: 200)
        
        for i in 0..<12 {
            let angle = Double(i) * 30.0 * .pi / 180.0
            let star = StarParticle(
                id: UUID(),
                position: center,
                color: colors.randomElement() ?? .yellow,
                size: Double.random(in: 15...25),
                opacity: 1.0,
                scale: 0.1
            )
            stars.append(star)
        }
        
        // Animate star burst
        withAnimation(.easeOut(duration: 1.5)) {
            for i in stars.indices {
                let angle = Double(i) * 30.0 * .pi / 180.0
                let distance = Double.random(in: 80...120)
                
                stars[i].position.x += cos(angle) * distance
                stars[i].position.y += sin(angle) * distance
                stars[i].scale = 1.0
            }
        }
        
        // Fade out stars
        withAnimation(.easeOut(duration: 1.0).delay(1.0)) {
            for i in stars.indices {
                stars[i].opacity = 0.0
                stars[i].scale = 0.1
            }
        }
        
        // Clean up stars
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            stars.removeAll()
        }
    }
}

// MARK: - Fireworks Animation View
struct FireworksView: View {
    let trigger: Int
    @State private var fireworks: [FireworkParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(fireworks, id: \.id) { firework in
                Circle()
                    .fill(firework.color)
                    .frame(width: firework.size, height: firework.size)
                    .position(firework.position)
                    .opacity(firework.opacity)
                    .scaleEffect(firework.scale)
            }
        }
        .onChange(of: trigger) { _ in
            generateFireworks()
        }
    }
    
    private func generateFireworks() {
        fireworks.removeAll()
        
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan]
        
        // Create multiple firework bursts
        for burstIndex in 0..<3 {
            let center = CGPoint(
                x: Double.random(in: 100...300),
                y: Double.random(in: 100...300)
            )
            
            // Create particles for each burst
            for i in 0..<20 {
                let firework = FireworkParticle(
                    id: UUID(),
                    position: center,
                    color: colors.randomElement() ?? .red,
                    size: Double.random(in: 3...8),
                    opacity: 1.0,
                    scale: 0.1
                )
                fireworks.append(firework)
            }
        }
        
        // Animate firework explosion
        withAnimation(.easeOut(duration: 2.0)) {
            var particleIndex = 0
            for burstIndex in 0..<3 {
                for i in 0..<20 {
                    let angle = Double(i) * 18.0 * .pi / 180.0
                    let distance = Double.random(in: 50...100)
                    
                    fireworks[particleIndex].position.x += cos(angle) * distance
                    fireworks[particleIndex].position.y += sin(angle) * distance
                    fireworks[particleIndex].scale = 1.0
                    
                    particleIndex += 1
                }
            }
        }
        
        // Fade out fireworks
        withAnimation(.easeOut(duration: 1.5).delay(1.0)) {
            for i in fireworks.indices {
                fireworks[i].opacity = 0.0
                fireworks[i].scale = 0.1
            }
        }
        
        // Clean up fireworks
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            fireworks.removeAll()
        }
    }
}

// MARK: - Particle Data Models

struct ConfettiParticle {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGSize
    var rotation: Double
    var opacity: Double
}

struct StarParticle {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
}

struct FireworkParticle {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
}

// MARK: - Preview
struct RewardOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            RewardOverlayView(rewardService: {
                let service = RewardAnimationService()
                service.showPerfectScoreReward(score: 100)
                return service
            }())
        }
    }
}