import Foundation
import UIKit
import AVFoundation
import Combine

// MARK: - Performance Optimizer
@MainActor
final class PerformanceOptimizer: ObservableObject {
    
    // MARK: - Properties
    static let shared = PerformanceOptimizer()
    
    @Published var isLowPowerModeEnabled = false
    @Published var batteryLevel: Float = 1.0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var memoryPressure: MemoryPressureLevel = .normal
    
    private var cancellables = Set<AnyCancellable>()
    private var performanceTimer: Timer?
    private var memoryWarningObserver: NSObjectProtocol?
    
    // Performance metrics
    private var cpuUsageHistory: [Double] = []
    private var memoryUsageHistory: [Double] = []
    private let maxHistoryCount = 60 // Keep 1 minute of history at 1-second intervals
    
    // Optimization settings
    private var isOptimizationEnabled = true
    private var adaptiveQualityEnabled = true
    
    // MARK: - Initialization
    private init() {
        setupSystemMonitoring()
        startPerformanceMonitoring()
    }
    
    deinit {
        stopPerformanceMonitoring()
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - System Monitoring Setup
    private func setupSystemMonitoring() {
        // Monitor battery level
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        
        // Monitor low power mode
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // Monitor thermal state
        thermalState = ProcessInfo.processInfo.thermalState
        
        // Setup notifications
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.batteryLevel = UIDevice.current.batteryLevel
                self?.adaptToSystemConditions()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                self?.adaptToSystemConditions()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.thermalState = ProcessInfo.processInfo.thermalState
                self?.adaptToSystemConditions()
            }
            .store(in: &cancellables)
        
        // Monitor memory warnings
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    // MARK: - Performance Monitoring
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func stopPerformanceMonitoring() {
        performanceTimer?.invalidate()
        performanceTimer = nil
    }
    
    private func updatePerformanceMetrics() {
        // Update CPU usage
        let cpuUsage = getCurrentCPUUsage()
        cpuUsageHistory.append(cpuUsage)
        if cpuUsageHistory.count > maxHistoryCount {
            cpuUsageHistory.removeFirst()
        }
        
        // Update memory usage
        let memoryUsage = getCurrentMemoryUsage()
        memoryUsageHistory.append(memoryUsage)
        if memoryUsageHistory.count > maxHistoryCount {
            memoryUsageHistory.removeFirst()
        }
        
        // Update memory pressure level
        memoryPressure = calculateMemoryPressure(memoryUsage)
        
        // Adapt to current conditions
        adaptToSystemConditions()
    }
    
    // MARK: - System Metrics
    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        
        return 0.0
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        
        return 0.0
    }
    
    private func calculateMemoryPressure(_ currentUsage: Double) -> MemoryPressureLevel {
        let averageUsage = memoryUsageHistory.isEmpty ? currentUsage : 
            memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
        
        switch averageUsage {
        case 0..<100:
            return .normal
        case 100..<200:
            return .moderate
        case 200..<300:
            return .high
        default:
            return .critical
        }
    }
    
    // MARK: - Adaptive Optimization
    private func adaptToSystemConditions() {
        guard isOptimizationEnabled else { return }
        
        let shouldOptimize = shouldEnableOptimizations()
        
        if shouldOptimize {
            enablePerformanceOptimizations()
        } else {
            disablePerformanceOptimizations()
        }
    }
    
    private func shouldEnableOptimizations() -> Bool {
        return isLowPowerModeEnabled ||
               batteryLevel < 0.2 ||
               thermalState == .serious ||
               thermalState == .critical ||
               memoryPressure == .high ||
               memoryPressure == .critical
    }
    
    private func enablePerformanceOptimizations() {
        // Reduce animation quality
        UIView.setAnimationsEnabled(false)
        
        // Reduce audio quality for speech recognition
        optimizeAudioSettings(highQuality: false)
        
        // Reduce handwriting recognition frequency
        optimizeHandwritingRecognition(highQuality: false)
        
        // Reduce UI update frequency
        optimizeUIUpdates(highFrequency: false)
        
        // Enable aggressive memory management
        enableAggressiveMemoryManagement()
    }
    
    private func disablePerformanceOptimizations() {
        // Restore normal animation quality
        UIView.setAnimationsEnabled(true)
        
        // Restore normal audio quality
        optimizeAudioSettings(highQuality: true)
        
        // Restore normal handwriting recognition
        optimizeHandwritingRecognition(highQuality: true)
        
        // Restore normal UI update frequency
        optimizeUIUpdates(highFrequency: true)
        
        // Disable aggressive memory management
        disableAggressiveMemoryManagement()
    }
    
    // MARK: - Specific Optimizations
    private func optimizeAudioSettings(highQuality: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            if highQuality {
                // High quality settings
                try audioSession.setPreferredSampleRate(44100.0)
                try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer
            } else {
                // Optimized settings for battery life
                try audioSession.setPreferredSampleRate(22050.0)
                try audioSession.setPreferredIOBufferDuration(0.02) // 20ms buffer
            }
        } catch {
            print("Failed to optimize audio settings: \(error)")
        }
    }
    
    private func optimizeHandwritingRecognition(highQuality: Bool) {
        // This would be implemented in the HandwritingRecognizer
        NotificationCenter.default.post(
            name: .handwritingQualityChanged,
            object: nil,
            userInfo: ["highQuality": highQuality]
        )
    }
    
    private func optimizeUIUpdates(highFrequency: Bool) {
        // This would be implemented in UI components
        NotificationCenter.default.post(
            name: .uiUpdateFrequencyChanged,
            object: nil,
            userInfo: ["highFrequency": highFrequency]
        )
    }
    
    private func enableAggressiveMemoryManagement() {
        // Clear caches
        URLCache.shared.removeAllCachedResponses()
        
        // Notify components to clear their caches
        NotificationCenter.default.post(name: .clearCaches, object: nil)
    }
    
    private func disableAggressiveMemoryManagement() {
        // Restore normal caching behavior
        NotificationCenter.default.post(name: .restoreCaches, object: nil)
    }
    
    // MARK: - Memory Warning Handling
    private func handleMemoryWarning() {
        memoryPressure = .critical
        
        // Immediate memory cleanup
        enableAggressiveMemoryManagement()
        
        // Notify all components to free memory
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
        
        // Force garbage collection
        autoreleasepool {
            // This block will be cleaned up immediately
        }
    }
    
    // MARK: - Public Interface
    func enableOptimization(_ enabled: Bool) {
        isOptimizationEnabled = enabled
        adaptToSystemConditions()
    }
    
    func enableAdaptiveQuality(_ enabled: Bool) {
        adaptiveQualityEnabled = enabled
    }
    
    func getCurrentPerformanceLevel() -> PerformanceLevel {
        if shouldEnableOptimizations() {
            return .optimized
        } else {
            return .normal
        }
    }
    
    func getPerformanceMetrics() -> PerformanceMetrics {
        let avgCPU = cpuUsageHistory.isEmpty ? 0 : cpuUsageHistory.reduce(0, +) / Double(cpuUsageHistory.count)
        let avgMemory = memoryUsageHistory.isEmpty ? 0 : memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
        
        return PerformanceMetrics(
            averageCPUUsage: avgCPU,
            averageMemoryUsage: avgMemory,
            batteryLevel: batteryLevel,
            thermalState: thermalState,
            memoryPressure: memoryPressure,
            isLowPowerMode: isLowPowerModeEnabled
        )
    }
    
    // MARK: - Battery Optimization Recommendations
    func getBatteryOptimizationRecommendations() -> [BatteryOptimizationTip] {
        var tips: [BatteryOptimizationTip] = []
        
        if batteryLevel < 0.2 {
            tips.append(.enableLowPowerMode)
        }
        
        if thermalState == .serious || thermalState == .critical {
            tips.append(.reduceThermalLoad)
        }
        
        if memoryPressure == .high || memoryPressure == .critical {
            tips.append(.freeMemory)
        }
        
        if !isLowPowerModeEnabled && batteryLevel < 0.5 {
            tips.append(.considerLowPowerMode)
        }
        
        return tips
    }
}

// MARK: - Supporting Types
enum MemoryPressureLevel: String, CaseIterable {
    case normal = "normal"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .normal:
            return "Bình thường"
        case .moderate:
            return "Vừa phải"
        case .high:
            return "Cao"
        case .critical:
            return "Nguy hiểm"
        }
    }
    
    var color: String {
        switch self {
        case .normal:
            return "green"
        case .moderate:
            return "yellow"
        case .high:
            return "orange"
        case .critical:
            return "red"
        }
    }
}

enum PerformanceLevel: String, CaseIterable {
    case normal = "normal"
    case optimized = "optimized"
    
    var displayName: String {
        switch self {
        case .normal:
            return "Bình thường"
        case .optimized:
            return "Tối ưu hóa"
        }
    }
}

struct PerformanceMetrics {
    let averageCPUUsage: Double
    let averageMemoryUsage: Double
    let batteryLevel: Float
    let thermalState: ProcessInfo.ThermalState
    let memoryPressure: MemoryPressureLevel
    let isLowPowerMode: Bool
}

enum BatteryOptimizationTip: String, CaseIterable {
    case enableLowPowerMode = "enableLowPowerMode"
    case reduceThermalLoad = "reduceThermalLoad"
    case freeMemory = "freeMemory"
    case considerLowPowerMode = "considerLowPowerMode"
    
    var title: String {
        switch self {
        case .enableLowPowerMode:
            return "Bật chế độ tiết kiệm pin"
        case .reduceThermalLoad:
            return "Giảm tải nhiệt"
        case .freeMemory:
            return "Giải phóng bộ nhớ"
        case .considerLowPowerMode:
            return "Cân nhắc chế độ tiết kiệm pin"
        }
    }
    
    var description: String {
        switch self {
        case .enableLowPowerMode:
            return "Pin yếu. Hãy bật chế độ tiết kiệm pin để sử dụng lâu hơn."
        case .reduceThermalLoad:
            return "Thiết bị đang nóng. Hãy tạm dừng và để thiết bị nguội đi."
        case .freeMemory:
            return "Bộ nhớ đầy. Hãy đóng các ứng dụng khác."
        case .considerLowPowerMode:
            return "Pin còn ít. Cân nhắc bật chế độ tiết kiệm pin."
        }
    }
    
    var icon: String {
        switch self {
        case .enableLowPowerMode:
            return "battery.25"
        case .reduceThermalLoad:
            return "thermometer"
        case .freeMemory:
            return "memorychip"
        case .considerLowPowerMode:
            return "battery.50"
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let handwritingQualityChanged = Notification.Name("handwritingQualityChanged")
    static let uiUpdateFrequencyChanged = Notification.Name("uiUpdateFrequencyChanged")
    static let clearCaches = Notification.Name("clearCaches")
    static let restoreCaches = Notification.Name("restoreCaches")
    static let memoryWarning = Notification.Name("memoryWarning")
    static let vietnameseRecognitionCompleted = Notification.Name("vietnameseRecognitionCompleted")
}