import SwiftUI
import UIKit

// MARK: - Device Detection
struct DeviceInfo {
    static let shared = DeviceInfo()
    
    private init() {}
    
    // MARK: - Device Type Detection
    var deviceType: DeviceType {
        #if os(macOS)
        return .mac
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        case .mac:
            return .mac
        default:
            return .iPhone
        }
        #endif
    }
    
    var isPhone: Bool {
        deviceType == .iPhone
    }
    
    var isPad: Bool {
        deviceType == .iPad
    }
    
    var isMac: Bool {
        deviceType == .mac
    }
    
    // MARK: - Screen Size Categories
    var screenSizeCategory: ScreenSizeCategory {
        #if os(macOS)
        return .large
        #else
        let screenBounds = UIScreen.main.bounds
        let screenWidth = min(screenBounds.width, screenBounds.height)
        let screenHeight = max(screenBounds.width, screenBounds.height)
        
        switch deviceType {
        case .iPhone:
            if screenHeight <= 667 { // iPhone SE, 6, 7, 8
                return .compact
            } else if screenHeight <= 736 { // iPhone 6+, 7+, 8+
                return .regular
            } else { // iPhone X and newer
                return .large
            }
        case .iPad:
            if screenWidth <= 768 { // iPad mini, regular iPad
                return .regular
            } else { // iPad Pro
                return .large
            }
        case .mac:
            return .large
        }
        #endif
    }
    
    // MARK: - Orientation
    var orientation: DeviceOrientation {
        #if os(macOS)
        return .landscape
        #else
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait, .portraitUpsideDown:
            return .portrait
        case .landscapeLeft, .landscapeRight:
            return .landscape
        default:
            // Fallback to interface orientation
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                switch windowScene.interfaceOrientation {
                case .portrait, .portraitUpsideDown:
                    return .portrait
                default:
                    return .landscape
                }
            }
            return .portrait
        }
        #endif
    }
    
    // MARK: - Apple Pencil Support
    var supportsPencil: Bool {
        #if os(iOS)
        return isPad
        #else
        return false
        #endif
    }
    
    // MARK: - Safe Area
    var safeAreaInsets: EdgeInsets {
        #if os(macOS)
        return EdgeInsets()
        #else
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let insets = window.safeAreaInsets
            return EdgeInsets(
                top: insets.top,
                leading: insets.left,
                bottom: insets.bottom,
                trailing: insets.right
            )
        }
        return EdgeInsets()
        #endif
    }
}

// MARK: - Device Type Enum
enum DeviceType: String, CaseIterable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "Mac"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Screen Size Category
enum ScreenSizeCategory: String, CaseIterable {
    case compact = "compact"
    case regular = "regular"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .compact:
            return "Nhỏ"
        case .regular:
            return "Vừa"
        case .large:
            return "Lớn"
        }
    }
}

// MARK: - Device Orientation
enum DeviceOrientation: String, CaseIterable {
    case portrait = "portrait"
    case landscape = "landscape"
    
    var displayName: String {
        switch self {
        case .portrait:
            return "Dọc"
        case .landscape:
            return "Ngang"
        }
    }
}

// MARK: - Adaptive Layout Configuration
struct AdaptiveLayoutConfig {
    let deviceType: DeviceType
    let screenSize: ScreenSizeCategory
    let orientation: DeviceOrientation
    
    init() {
        let deviceInfo = DeviceInfo.shared
        self.deviceType = deviceInfo.deviceType
        self.screenSize = deviceInfo.screenSizeCategory
        self.orientation = deviceInfo.orientation
    }
    
    // MARK: - Layout Metrics
    var contentPadding: CGFloat {
        switch (deviceType, screenSize) {
        case (.iPhone, .compact):
            return 16
        case (.iPhone, .regular):
            return 20
        case (.iPhone, .large):
            return 24
        case (.iPad, _):
            return orientation == .portrait ? 32 : 48
        case (.mac, _):
            return 40
        }
    }
    
    var sectionSpacing: CGFloat {
        switch screenSize {
        case .compact:
            return 16
        case .regular:
            return 20
        case .large:
            return 24
        }
    }
    
    var buttonHeight: CGFloat {
        switch (deviceType, screenSize) {
        case (.iPhone, .compact):
            return 44
        case (.iPhone, .regular):
            return 48
        case (.iPhone, .large):
            return 52
        case (.iPad, _):
            return 56
        case (.mac, _):
            return 48
        }
    }
    
    var cornerRadius: CGFloat {
        switch screenSize {
        case .compact:
            return 8
        case .regular:
            return 12
        case .large:
            return 16
        }
    }
    
    var maxContentWidth: CGFloat {
        switch (deviceType, orientation) {
        case (.iPhone, _):
            return .infinity
        case (.iPad, .portrait):
            return 600
        case (.iPad, .landscape):
            return 800
        case (.mac, _):
            return 900
        }
    }
    
    // MARK: - Typography
    var titleFontSize: CGFloat {
        switch screenSize {
        case .compact:
            return 24
        case .regular:
            return 28
        case .large:
            return 32
        }
    }
    
    var bodyFontSize: CGFloat {
        switch screenSize {
        case .compact:
            return 16
        case .regular:
            return 17
        case .large:
            return 18
        }
    }
    
    var captionFontSize: CGFloat {
        switch screenSize {
        case .compact:
            return 12
        case .regular:
            return 13
        case .large:
            return 14
        }
    }
    
    // MARK: - Grid Layout
    var gridColumns: Int {
        switch (deviceType, orientation) {
        case (.iPhone, .portrait):
            return 1
        case (.iPhone, .landscape):
            return 2
        case (.iPad, .portrait):
            return 2
        case (.iPad, .landscape):
            return 3
        case (.mac, _):
            return 3
        }
    }
    
    var gridSpacing: CGFloat {
        switch screenSize {
        case .compact:
            return 12
        case .regular:
            return 16
        case .large:
            return 20
        }
    }
    
    // MARK: - Drawing Canvas
    var canvasHeight: CGFloat {
        switch (deviceType, orientation) {
        case (.iPhone, .portrait):
            return 200
        case (.iPhone, .landscape):
            return 150
        case (.iPad, .portrait):
            return 300
        case (.iPad, .landscape):
            return 250
        case (.mac, _):
            return 300
        }
    }
    
    // MARK: - Input Method Selection
    var showInputMethodSelection: Bool {
        return deviceType == .iPad
    }
    
    var inputMethodButtonSize: CGFloat {
        switch screenSize {
        case .compact:
            return 60
        case .regular:
            return 70
        case .large:
            return 80
        }
    }
}

// MARK: - Environment Values
struct AdaptiveLayoutConfigKey: EnvironmentKey {
    static let defaultValue = AdaptiveLayoutConfig()
}

extension EnvironmentValues {
    var adaptiveLayout: AdaptiveLayoutConfig {
        get { self[AdaptiveLayoutConfigKey.self] }
        set { self[AdaptiveLayoutConfigKey.self] = newValue }
    }
}

// MARK: - View Modifiers
struct AdaptiveLayoutModifier: ViewModifier {
    @State private var layoutConfig = AdaptiveLayoutConfig()
    
    func body(content: Content) -> some View {
        content
            .environment(\.adaptiveLayout, layoutConfig)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                layoutConfig = AdaptiveLayoutConfig()
            }
    }
}

extension View {
    func adaptiveLayout() -> some View {
        modifier(AdaptiveLayoutModifier())
    }
}