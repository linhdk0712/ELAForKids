import Foundation
import UIKit
import Combine

// MARK: - Cache Manager
final class CacheManager: ObservableObject {
    
    // MARK: - Properties
    static let shared = CacheManager()
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let audioCache = NSCache<NSString, NSData>()
    private let textCache = NSCache<NSString, NSString>()
    private let recognitionCache = NSCache<NSString, RecognitionResult>()
    
    private var cancellables = Set<AnyCancellable>()
    private let cacheQueue = DispatchQueue(label: "com.elaforKids.cache", qos: .utility)
    
    // Cache configuration
    private let maxImageCacheSize = 50 * 1024 * 1024 // 50MB
    private let maxAudioCacheSize = 100 * 1024 * 1024 // 100MB
    private let maxTextCacheSize = 10 * 1024 * 1024 // 10MB
    private let maxRecognitionCacheSize = 20 * 1024 * 1024 // 20MB
    
    // Cache statistics
    @Published var cacheStatistics = CacheStatistics()
    
    // MARK: - Initialization
    private init() {
        setupCaches()
        setupNotifications()
        startCacheMonitoring()
    }
    
    // MARK: - Cache Setup
    private func setupCaches() {
        // Configure image cache
        imageCache.totalCostLimit = maxImageCacheSize
        imageCache.countLimit = 100
        imageCache.name = "ImageCache"
        
        // Configure audio cache
        audioCache.totalCostLimit = maxAudioCacheSize
        audioCache.countLimit = 50
        audioCache.name = "AudioCache"
        
        // Configure text cache
        textCache.totalCostLimit = maxTextCacheSize
        textCache.countLimit = 1000
        textCache.name = "TextCache"
        
        // Configure recognition cache
        recognitionCache.totalCostLimit = maxRecognitionCacheSize
        recognitionCache.countLimit = 200
        recognitionCache.name = "RecognitionCache"
    }
    
    private func setupNotifications() {
        // Listen for memory warnings
        NotificationCenter.default.publisher(for: .memoryWarning)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
        
        // Listen for cache clear requests
        NotificationCenter.default.publisher(for: .clearCaches)
            .sink { [weak self] _ in
                self?.clearAllCaches()
            }
            .store(in: &cancellables)
        
        // Listen for app background/foreground
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.optimizeForBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.optimizeForForeground()
            }
            .store(in: &cancellables)
    }
    
    private func startCacheMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateCacheStatistics()
        }
    }
    
    // MARK: - Image Caching
    func cacheImage(_ image: UIImage, forKey key: String) {
        cacheQueue.async { [weak self] in
            let cost = self?.calculateImageCost(image) ?? 0
            self?.imageCache.setObject(image, forKey: key as NSString, cost: cost)
            
            DispatchQueue.main.async {
                self?.updateCacheStatistics()
            }
        }
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func removeCachedImage(forKey key: String) {
        imageCache.removeObject(forKey: key as NSString)
        updateCacheStatistics()
    }
    
    private func calculateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
    
    // MARK: - Audio Caching
    func cacheAudioData(_ data: Data, forKey key: String) {
        cacheQueue.async { [weak self] in
            let nsData = NSData(data: data)
            self?.audioCache.setObject(nsData, forKey: key as NSString, cost: data.count)
            
            DispatchQueue.main.async {
                self?.updateCacheStatistics()
            }
        }
    }
    
    func getCachedAudioData(forKey key: String) -> Data? {
        guard let nsData = audioCache.object(forKey: key as NSString) else { return nil }
        return Data(referencing: nsData)
    }
    
    func removeCachedAudioData(forKey key: String) {
        audioCache.removeObject(forKey: key as NSString)
        updateCacheStatistics()
    }
    
    // MARK: - Text Caching
    func cacheText(_ text: String, forKey key: String) {
        cacheQueue.async { [weak self] in
            let cost = text.utf8.count
            self?.textCache.setObject(text as NSString, forKey: key as NSString, cost: cost)
            
            DispatchQueue.main.async {
                self?.updateCacheStatistics()
            }
        }
    }
    
    func getCachedText(forKey key: String) -> String? {
        return textCache.object(forKey: key as NSString) as String?
    }
    
    func removeCachedText(forKey key: String) {
        textCache.removeObject(forKey: key as NSString)
        updateCacheStatistics()
    }
    
    // MARK: - Recognition Result Caching
    func cacheRecognitionResult(_ result: RecognitionResult, forKey key: String) {
        cacheQueue.async { [weak self] in
            let cost = result.recognizedText.utf8.count + 
                      result.alternativeTexts.reduce(0) { $0 + $1.utf8.count }
            self?.recognitionCache.setObject(result, forKey: key as NSString, cost: cost)
            
            DispatchQueue.main.async {
                self?.updateCacheStatistics()
            }
        }
    }
    
    func getCachedRecognitionResult(forKey key: String) -> RecognitionResult? {
        return recognitionCache.object(forKey: key as NSString)
    }
    
    func removeCachedRecognitionResult(forKey key: String) {
        recognitionCache.removeObject(forKey: key as NSString)
        updateCacheStatistics()
    }
    
    // MARK: - Cache Management
    func clearAllCaches() {
        cacheQueue.async { [weak self] in
            self?.imageCache.removeAllObjects()
            self?.audioCache.removeAllObjects()
            self?.textCache.removeAllObjects()
            self?.recognitionCache.removeAllObjects()
            
            DispatchQueue.main.async {
                self?.updateCacheStatistics()
            }
        }
    }
    
    func clearImageCache() {
        imageCache.removeAllObjects()
        updateCacheStatistics()
    }
    
    func clearAudioCache() {
        audioCache.removeAllObjects()
        updateCacheStatistics()
    }
    
    func clearTextCache() {
        textCache.removeAllObjects()
        updateCacheStatistics()
    }
    
    func clearRecognitionCache() {
        recognitionCache.removeAllObjects()
        updateCacheStatistics()
    }
    
    // MARK: - Memory Management
    private func handleMemoryWarning() {
        // Clear least important caches first
        clearRecognitionCache()
        clearTextCache()
        
        // If still under memory pressure, clear more
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if PerformanceOptimizer.shared.memoryPressure == .critical {
                self?.clearImageCache()
                self?.clearAudioCache()
            }
        }
    }
    
    private func optimizeForBackground() {
        // Reduce cache sizes when app goes to background
        imageCache.totalCostLimit = maxImageCacheSize / 2
        audioCache.totalCostLimit = maxAudioCacheSize / 2
        textCache.totalCostLimit = maxTextCacheSize / 2
        recognitionCache.totalCostLimit = maxRecognitionCacheSize / 2
        
        // Clear some caches
        clearRecognitionCache()
    }
    
    private func optimizeForForeground() {
        // Restore full cache sizes when app comes to foreground
        imageCache.totalCostLimit = maxImageCacheSize
        audioCache.totalCostLimit = maxAudioCacheSize
        textCache.totalCostLimit = maxTextCacheSize
        recognitionCache.totalCostLimit = maxRecognitionCacheSize
    }
    
    // MARK: - Cache Statistics
    private func updateCacheStatistics() {
        let stats = CacheStatistics(
            imageCacheCount: imageCache.countLimit,
            audioCacheCount: audioCache.countLimit,
            textCacheCount: textCache.countLimit,
            recognitionCacheCount: recognitionCache.countLimit,
            totalMemoryUsage: getTotalCacheMemoryUsage(),
            hitRate: calculateHitRate()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.cacheStatistics = stats
        }
    }
    
    private func getTotalCacheMemoryUsage() -> Int {
        return imageCache.totalCostLimit + 
               audioCache.totalCostLimit + 
               textCache.totalCostLimit + 
               recognitionCache.totalCostLimit
    }
    
    private func calculateHitRate() -> Double {
        // This is a simplified hit rate calculation
        // In a real implementation, you would track hits and misses
        return 0.75 // Mock 75% hit rate
    }
    
    // MARK: - Preloading
    func preloadCommonAssets() {
        cacheQueue.async { [weak self] in
            // Preload common images
            self?.preloadCommonImages()
            
            // Preload common audio files
            self?.preloadCommonAudioFiles()
            
            // Preload common text templates
            self?.preloadCommonTextTemplates()
        }
    }
    
    private func preloadCommonImages() {
        let commonImageNames = [
            "star_filled",
            "star_empty",
            "trophy",
            "medal",
            "microphone",
            "pencil",
            "checkmark",
            "xmark"
        ]
        
        for imageName in commonImageNames {
            if let image = UIImage(named: imageName) {
                cacheImage(image, forKey: imageName)
            }
        }
    }
    
    private func preloadCommonAudioFiles() {
        let commonAudioFiles = [
            "success_sound",
            "error_sound",
            "button_tap",
            "achievement_unlock"
        ]
        
        for audioFileName in commonAudioFiles {
            if let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3"),
               let data = try? Data(contentsOf: url) {
                cacheAudioData(data, forKey: audioFileName)
            }
        }
    }
    
    private func preloadCommonTextTemplates() {
        let commonTexts = [
            "Tuyệt vời!",
            "Giỏi lắm!",
            "Hãy thử lại nhé!",
            "Chúc mừng!",
            "Tiếp tục cố gắng!"
        ]
        
        for (index, text) in commonTexts.enumerated() {
            cacheText(text, forKey: "common_text_\(index)")
        }
    }
    
    // MARK: - Cache Key Generation
    func generateCacheKey(for components: [String]) -> String {
        return components.joined(separator: "_").replacingOccurrences(of: " ", with: "_")
    }
    
    func generateImageCacheKey(for imageName: String, size: CGSize) -> String {
        return "\(imageName)_\(Int(size.width))x\(Int(size.height))"
    }
    
    func generateAudioCacheKey(for audioName: String, quality: AudioQuality) -> String {
        return "\(audioName)_\(quality.rawValue)"
    }
    
    func generateRecognitionCacheKey(for drawingHash: String, locale: String) -> String {
        return "recognition_\(drawingHash)_\(locale)"
    }
}

// MARK: - Cache Statistics
struct CacheStatistics {
    let imageCacheCount: Int
    let audioCacheCount: Int
    let textCacheCount: Int
    let recognitionCacheCount: Int
    let totalMemoryUsage: Int
    let hitRate: Double
    
    init() {
        self.imageCacheCount = 0
        self.audioCacheCount = 0
        self.textCacheCount = 0
        self.recognitionCacheCount = 0
        self.totalMemoryUsage = 0
        self.hitRate = 0.0
    }
    
    init(imageCacheCount: Int, audioCacheCount: Int, textCacheCount: Int, 
         recognitionCacheCount: Int, totalMemoryUsage: Int, hitRate: Double) {
        self.imageCacheCount = imageCacheCount
        self.audioCacheCount = audioCacheCount
        self.textCacheCount = textCacheCount
        self.recognitionCacheCount = recognitionCacheCount
        self.totalMemoryUsage = totalMemoryUsage
        self.hitRate = hitRate
    }
    
    var totalCacheCount: Int {
        return imageCacheCount + audioCacheCount + textCacheCount + recognitionCacheCount
    }
    
    var formattedMemoryUsage: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(totalMemoryUsage))
    }
    
    var formattedHitRate: String {
        return String(format: "%.1f%%", hitRate * 100)
    }
}

// MARK: - Cache Extensions for RecognitionResult
extension RecognitionResult: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return RecognitionResult(
            recognizedText: self.recognizedText,
            confidence: self.confidence,
            alternativeTexts: self.alternativeTexts,
            processingTime: self.processingTime
        )
    }
}