import Foundation
import SwiftUI
import Combine

// MARK: - Animation Manager

final class AnimationManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isAnimating = false
    @Published var currentAnimation: AnimationType?
    
    private var animationQueue: [AnimationTask] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Animation Types
    
    enum AnimationType: String, CaseIterable {
        case success = "success"
        case error = "error"
        case loading = "loading"
        case transition = "transition"
        case reward = "reward"
        case achievement = "achievement"
        case progress = "progress"
        case feedback = "feedback"
    }
    
    // MARK: - Animation Presets
    
    struct AnimationPreset {
        let type: AnimationType
        let duration: Double
        let curve: Animation.TimingCurve
        let delay: Double
        let repeatCount: Int?
        let autoReverse: Bool
        
        static let success = AnimationPreset(
            type: .success,
            duration: 0.6,
            curve: .spring(response: 0.6, dampingFraction: 0.8),
            delay: 0,
            repeatCount: nil,
            autoReverse: false
        )
        
        static let error = AnimationPreset(
            type: .error,
            duration: 0.4,
            curve: .easeInOut(duration: 0.4),
            delay: 0,
            repeatCount: 2,
            autoReverse: true
        )
        
        static let loading = AnimationPreset(
            type: .loading,
            duration: 1.0,
            curve: .linear(duration: 1.0),
            delay: 0,
            repeatCount: nil,
            autoReverse: false
        )
        
        static let reward = AnimationPreset(
            type: .reward,
            duration: 0.8,
            curve: .spring(response: 0.8, dampingFraction: 0.6),
            delay: 0.1,
            repeatCount: 1,
            autoReverse: false
        )
        
        static let achievement = AnimationPreset(
            type: .achievement,
            duration: 1.2,
            curve: .spring(response: 1.0, dampingFraction: 0.7),
            delay: 0.2,
            repeatCount: 1,
            autoReverse: false
        )
        
        static let progress = AnimationPreset(
            type: .progress,
            duration: 0.5,
            curve: .easeInOut(duration: 0.5),
            delay: 0,
            repeatCount: nil,
            autoReverse: false
        )
        
        static let feedback = AnimationPreset(
            type: .feedback,
            duration: 0.3,
            curve: .easeInOut(duration: 0.3),
            delay: 0,
            repeatCount: 1,
            autoReverse: true
        )
    }
    
    // MARK: - Animation Task
    
    struct AnimationTask {
        let id = UUID()
        let preset: AnimationPreset
        let completion: (() -> Void)?
        let priority: Int
        
        init(preset: AnimationPreset, completion: (() -> Void)? = nil, priority: Int = 0) {
            self.preset = preset
            self.completion = completion
            self.priority = priority
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupAnimationQueue()
    }
    
    // MARK: - Public Methods
    
    func playAnimation(_ type: AnimationType, completion: (() -> Void)? = nil) {
        let preset = getPreset(for: type)
        let task = AnimationTask(preset: preset, completion: completion)
        
        addToQueue(task)
    }
    
    func playCustomAnimation(
        type: AnimationType,
        duration: Double,
        curve: Animation.TimingCurve = .easeInOut(duration: 0.3),
        delay: Double = 0,
        repeatCount: Int? = nil,
        autoReverse: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        let preset = AnimationPreset(
            type: type,
            duration: duration,
            curve: curve,
            delay: delay,
            repeatCount: repeatCount,
            autoReverse: autoReverse
        )
        
        let task = AnimationTask(preset: preset, completion: completion)
        addToQueue(task)
    }
    
    func stopAllAnimations() {
        animationQueue.removeAll()
        isAnimating = false
        currentAnimation = nil
    }
    
    func pauseAnimations() {
        isAnimating = false
    }
    
    func resumeAnimations() {
        isAnimating = true
        processQueue()
    }
    
    // MARK: - Private Methods
    
    private func setupAnimationQueue() {
        // Process animation queue when animations complete
        $isAnimating
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.processQueue()
            }
            .store(in: &cancellables)
    }
    
    private func addToQueue(_ task: AnimationTask) {
        animationQueue.append(task)
        animationQueue.sort { $0.priority > $1.priority }
        
        if !isAnimating {
            processQueue()
        }
    }
    
    private func processQueue() {
        guard !isAnimating, let task = animationQueue.first else { return }
        
        animationQueue.removeFirst()
        executeAnimation(task)
    }
    
    private func executeAnimation(_ task: AnimationTask) {
        isAnimating = true
        currentAnimation = task.preset.type
        
        let animation = Animation(
            task.preset.curve,
            duration: task.preset.duration
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + task.preset.delay) {
            withAnimation(animation) {
                // Animation execution
                if let repeatCount = task.preset.repeatCount {
                    self.executeRepeatedAnimation(task, repeatCount: repeatCount)
                } else {
                    self.completeAnimation(task)
                }
            }
        }
    }
    
    private func executeRepeatedAnimation(_ task: AnimationTask, repeatCount: Int) {
        var remainingCount = repeatCount
        
        func execute() {
            guard remainingCount > 0 else {
                completeAnimation(task)
                return
            }
            
            remainingCount -= 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + task.preset.duration) {
                if task.preset.autoReverse {
                    // Execute reverse animation
                    withAnimation(Animation(task.preset.curve, duration: task.preset.duration)) {
                        // Reverse animation logic
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + task.preset.duration) {
                        execute()
                    }
                } else {
                    execute()
                }
            }
        }
        
        execute()
    }
    
    private func completeAnimation(_ task: AnimationTask) {
        DispatchQueue.main.async {
            self.isAnimating = false
            self.currentAnimation = nil
            
            task.completion?()
        }
    }
    
    private func getPreset(for type: AnimationType) -> AnimationPreset {
        switch type {
        case .success:
            return .success
        case .error:
            return .error
        case .loading:
            return .loading
        case .reward:
            return .reward
        case .achievement:
            return .achievement
        case .progress:
            return .progress
        case .feedback:
            return .feedback
        case .transition:
            return AnimationPreset(
                type: .transition,
                duration: 0.4,
                curve: .easeInOut(duration: 0.4),
                delay: 0,
                repeatCount: nil,
                autoReverse: false
            )
        }
    }
}

// MARK: - Animation Extensions

extension Animation {
    static func customSpring(response: Double = 0.6, dampingFraction: Double = 0.8, blendDuration: Double = 0) -> Animation {
        return .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
    }
    
    static func customEaseInOut(duration: Double) -> Animation {
        return .easeInOut(duration: duration)
    }
    
    static func customLinear(duration: Double) -> Animation {
        return .linear(duration: duration)
    }
}

// MARK: - View Modifiers

struct AnimatedScale: ViewModifier {
    let scale: CGFloat
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(animation, value: scale)
    }
}

struct AnimatedOpacity: ViewModifier {
    let opacity: Double
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(animation, value: opacity)
    }
}

struct AnimatedRotation: ViewModifier {
    let rotation: Angle
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(rotation)
            .animation(animation, value: rotation)
    }
}

struct AnimatedOffset: ViewModifier {
    let offset: CGSize
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .animation(animation, value: offset)
    }
}

// MARK: - Custom Animations

struct SuccessAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Angle = .degrees(0)
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                    rotation = .degrees(360)
                }
            }
    }
}

struct ErrorAnimation: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(.red)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    scale = 1.2
                }
                
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    opacity = 0.7
                }
            }
    }
}

struct LoadingAnimation: View {
    @State private var rotation: Angle = .degrees(0)
    
    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 40))
            .foregroundColor(.blue)
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatCount(0, autoreverses: false)) {
                    rotation = .degrees(360)
                }
            }
    }
}

struct RewardAnimation: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var offset: CGSize = CGSize(width: 0, height: 50)
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 80))
            .foregroundColor(.yellow)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                    opacity = 1.0
                    offset = CGSize(width: 0, height: 0)
                }
                
                withAnimation(.easeInOut(duration: 0.3).delay(0.9)) {
                    scale = 0.8
                    opacity = 0.8
                }
            }
    }
}

struct AchievementAnimation: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var rotation: Angle = .degrees(-180)
    
    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: 100))
            .foregroundColor(.orange)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                    scale = 1.0
                    opacity = 1.0
                    rotation = .degrees(0)
                }
                
                withAnimation(.easeInOut(duration: 0.2).delay(1.0)) {
                    scale = 0.9
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func animatedScale(_ scale: CGFloat, animation: Animation = .easeInOut(duration: 0.3)) -> some View {
        modifier(AnimatedScale(scale: scale, animation: animation))
    }
    
    func animatedOpacity(_ opacity: Double, animation: Animation = .easeInOut(duration: 0.3)) -> some View {
        modifier(AnimatedOpacity(opacity: opacity, animation: animation))
    }
    
    func animatedRotation(_ rotation: Angle, animation: Animation = .easeInOut(duration: 0.3)) -> some View {
        modifier(AnimatedRotation(rotation: rotation, animation: animation))
    }
    
    func animatedOffset(_ offset: CGSize, animation: Animation = .easeInOut(duration: 0.3)) -> some View {
        modifier(AnimatedOffset(offset: offset, animation: animation))
    }
    
    func successAnimation() -> some View {
        SuccessAnimation()
    }
    
    func errorAnimation() -> some View {
        ErrorAnimation()
    }
    
    func loadingAnimation() -> some View {
        LoadingAnimation()
    }
    
    func rewardAnimation() -> some View {
        RewardAnimation()
    }
    
    func achievementAnimation() -> some View {
        AchievementAnimation()
    }
}
