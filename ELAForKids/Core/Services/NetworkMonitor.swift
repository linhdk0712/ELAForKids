import Foundation
import Network
import Combine

// MARK: - Network Status
enum NetworkStatus {
    case connected
    case disconnected
    case unknown
    
    var isConnected: Bool {
        return self == .connected
    }
}

// MARK: - Network Monitor
@MainActor
final class NetworkMonitor: ObservableObject {
    
    // MARK: - Properties
    @Published var status: NetworkStatus = .unknown
    @Published var isConnected: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // Publishers
    private let statusSubject = PassthroughSubject<NetworkStatus, Never>()
    
    // MARK: - Initialization
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let newStatus: NetworkStatus = path.status == .satisfied ? .connected : .disconnected
                self?.updateStatus(newStatus)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateStatus(_ newStatus: NetworkStatus) {
        guard status != newStatus else { return }
        
        status = newStatus
        isConnected = newStatus.isConnected
        statusSubject.send(newStatus)
        
        // Log status changes
        print("Network status changed to: \(newStatus)")
        
        // Post notification for other components
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: ["status": newStatus]
        )
    }
    
    // MARK: - Publishers
    var statusPublisher: AnyPublisher<NetworkStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Utility Methods
    func checkConnectivity() async -> Bool {
        return await withCheckedContinuation { continuation in
            let testMonitor = NWPathMonitor()
            testMonitor.pathUpdateHandler = { path in
                testMonitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            testMonitor.start(queue: queue)
        }
    }
    
    func waitForConnection(timeout: TimeInterval = 10.0) async -> Bool {
        if isConnected {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            // Set up timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: false)
                }
            }
            
            // Wait for connection
            let cancellable = statusPublisher
                .first { $0.isConnected }
                .sink { _ in
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: true)
                    }
                }
            
            // Store cancellable to prevent deallocation
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout + 1) {
                cancellable.cancel()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - Singleton Access
extension NetworkMonitor {
    static let shared = NetworkMonitor()
}