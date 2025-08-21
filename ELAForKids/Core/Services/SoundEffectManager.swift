import AVFoundation
import AudioToolbox

// MARK: - Sound Effect Manager
final class SoundEffectManager: ObservableObject {
    
    // MARK: - Properties
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var soundEnabled = true
    private var volume: Float = 0.7
    
    // MARK: - Initialization
    init() {
        loadSettings()
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Public Methods
    
    /// Play reward sound effect
    func playRewardSound(_ type: RewardSoundType) {
        guard soundEnabled else { return }
        playSound(named: type.fileName)
    }
    
    /// Play UI interaction sound
    func playUISound(_ type: UISoundType) {
        guard soundEnabled else { return }
        
        switch type {
        case .buttonTap:
            playSystemSound(1104) // Keyboard tap
        case .success:
            playSystemSound(1016) // Success
        case .error:
            playSystemSound(1053) // Error
        case .notification:
            playSystemSound(1315) // Notification
        case .swipe:
            playSystemSound(1519) // Swipe
        case .pop:
            playSystemSound(1306) // Pop
        }
    }
    
    /// Play feedback sound for reading accuracy
    func playAccuracyFeedback(accuracy: Float) {
        guard soundEnabled else { return }
        
        switch accuracy {
        case 0.95...1.0:
            playSound(named: "feedback_excellent")
        case 0.85..<0.95:
            playSound(named: "feedback_good")
        case 0.70..<0.85:
            playSound(named: "feedback_okay")
        default:
            playSound(named: "feedback_needs_improvement")
        }
    }
    
    /// Play sound for streak milestone
    func playStreakSound(streak: Int) {
        guard soundEnabled else { return }
        
        switch streak {
        case 1...3:
            playSound(named: "streak_start")
        case 4...7:
            playSound(named: "streak_week")
        case 8...14:
            playSound(named: "streak_strong")
        case 15...30:
            playSound(named: "streak_amazing")
        default:
            playSound(named: "streak_legendary")
        }
    }
    
    /// Play ambient background music
    func playBackgroundMusic(_ type: BackgroundMusicType, loop: Bool = true) {
        guard soundEnabled else { return }
        
        let fileName = type.fileName
        playSound(named: fileName, volume: 0.3, loop: loop)
    }
    
    /// Stop background music
    func stopBackgroundMusic() {
        stopSound(named: "background_music")
    }
    
    /// Play voice encouragement
    func playEncouragement(_ type: EncouragementType) {
        guard soundEnabled else { return }
        playSound(named: type.fileName)
    }
    
    // MARK: - Settings
    
    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "SoundEffectsEnabled")
        
        if !enabled {
            stopAllSounds()
        }
    }
    
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        UserDefaults.standard.set(self.volume, forKey: "SoundEffectsVolume")
        
        // Update volume for all active players
        for player in audioPlayers.values {
            player.volume = self.volume
        }
    }
    
    func isSoundEnabled() -> Bool {
        return soundEnabled
    }
    
    func getVolume() -> Float {
        return volume
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        let soundFiles = [
            "reward_success", "reward_good", "reward_great", "reward_excellent",
            "reward_epic", "reward_legendary", "reward_bonus",
            "feedback_excellent", "feedback_good", "feedback_okay", "feedback_needs_improvement",
            "streak_start", "streak_week", "streak_strong", "streak_amazing", "streak_legendary",
            "encouragement_great_job", "encouragement_keep_going", "encouragement_almost_there",
            "encouragement_perfect", "encouragement_try_again"
        ]
        
        for soundFile in soundFiles {
            preloadSound(named: soundFile)
        }
    }
    
    private func preloadSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = volume
            audioPlayers[soundName] = player
        } catch {
            print("Error preloading sound \(soundName): \(error)")
        }
    }
    
    private func playSound(named soundName: String, volume: Float? = nil, loop: Bool = false) {
        // Try to use preloaded player first
        if let player = audioPlayers[soundName] {
            player.volume = volume ?? self.volume
            player.numberOfLoops = loop ? -1 : 0
            player.play()
            return
        }
        
        // Fallback to creating new player
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Sound file not found: \(soundName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume ?? self.volume
            player.numberOfLoops = loop ? -1 : 0
            player.play()
            
            // Store player for potential reuse
            audioPlayers[soundName] = player
        } catch {
            print("Error playing sound \(soundName): \(error)")
        }
    }
    
    private func stopSound(named soundName: String) {
        audioPlayers[soundName]?.stop()
    }
    
    private func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
    }
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    private func loadSettings() {
        soundEnabled = UserDefaults.standard.object(forKey: "SoundEffectsEnabled") as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: "SoundEffectsVolume") as? Float ?? 0.7
    }
}

// MARK: - Sound Type Enums

enum RewardSoundType {
    case success
    case good
    case great
    case excellent
    case epic
    case legendary
    case bonus
    
    var fileName: String {
        switch self {
        case .success:
            return "reward_success"
        case .good:
            return "reward_good"
        case .great:
            return "reward_great"
        case .excellent:
            return "reward_excellent"
        case .epic:
            return "reward_epic"
        case .legendary:
            return "reward_legendary"
        case .bonus:
            return "reward_bonus"
        }
    }
}

enum UISoundType {
    case buttonTap
    case success
    case error
    case notification
    case swipe
    case pop
}

enum BackgroundMusicType {
    case learning
    case celebration
    case calm
    
    var fileName: String {
        switch self {
        case .learning:
            return "background_learning"
        case .celebration:
            return "background_celebration"
        case .calm:
            return "background_calm"
        }
    }
}

enum EncouragementType {
    case greatJob
    case keepGoing
    case almostThere
    case perfect
    case tryAgain
    
    var fileName: String {
        switch self {
        case .greatJob:
            return "encouragement_great_job"
        case .keepGoing:
            return "encouragement_keep_going"
        case .almostThere:
            return "encouragement_almost_there"
        case .perfect:
            return "encouragement_perfect"
        case .tryAgain:
            return "encouragement_try_again"
        }
    }
    
    var message: String {
        switch self {
        case .greatJob:
            return "Làm tốt lắm!"
        case .keepGoing:
            return "Tiếp tục nào!"
        case .almostThere:
            return "Sắp xong rồi!"
        case .perfect:
            return "Hoàn hảo!"
        case .tryAgain:
            return "Thử lại nào!"
        }
    }
}