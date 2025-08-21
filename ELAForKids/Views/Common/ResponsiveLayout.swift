import SwiftUI

// MARK: - Responsive Layout Container
struct ResponsiveLayout<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: layout.sectionSpacing) {
                    content
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding(for: geometry.size))
                .padding(.vertical, layout.contentPadding)
            }
        }
    }
    
    private func horizontalPadding(for size: CGSize) -> CGFloat {
        let deviceInfo = DeviceInfo.shared
        
        switch deviceInfo.deviceType {
        case .iPhone:
            return layout.contentPadding
        case .iPad:
            let availableWidth = size.width
            let contentWidth = min(availableWidth, layout.maxContentWidth)
            return max(layout.contentPadding, (availableWidth - contentWidth) / 2)
        case .mac:
            let availableWidth = size.width
            let contentWidth = min(availableWidth, layout.maxContentWidth)
            return max(layout.contentPadding, (availableWidth - contentWidth) / 2)
        }
    }
}

// MARK: - Adaptive Stack
struct AdaptiveStack<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let content: Content
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    
    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        let deviceInfo = DeviceInfo.shared
        
        if deviceInfo.orientation == .landscape && deviceInfo.deviceType == .iPad {
            HStack(alignment: .top, spacing: effectiveSpacing) {
                content
            }
        } else {
            VStack(alignment: alignment, spacing: effectiveSpacing) {
                content
            }
        }
    }
    
    private var effectiveSpacing: CGFloat {
        spacing ?? layout.sectionSpacing
    }
}

// MARK: - Breakpoint-based Layout
struct BreakpointLayout<CompactContent: View, RegularContent: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let compactContent: CompactContent
    let regularContent: RegularContent
    
    init(
        @ViewBuilder compact: () -> CompactContent,
        @ViewBuilder regular: () -> RegularContent
    ) {
        self.compactContent = compact()
        self.regularContent = regular()
    }
    
    var body: some View {
        if layout.screenSize == .compact {
            compactContent
        } else {
            regularContent
        }
    }
}

// MARK: - Orientation-based Layout
struct OrientationLayout<PortraitContent: View, LandscapeContent: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let portraitContent: PortraitContent
    let landscapeContent: LandscapeContent
    
    init(
        @ViewBuilder portrait: () -> PortraitContent,
        @ViewBuilder landscape: () -> LandscapeContent
    ) {
        self.portraitContent = portrait()
        self.landscapeContent = landscape()
    }
    
    var body: some View {
        if layout.orientation == .portrait {
            portraitContent
        } else {
            landscapeContent
        }
    }
}

// MARK: - Device-specific Layout
struct DeviceLayout<PhoneContent: View, PadContent: View, MacContent: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let phoneContent: PhoneContent?
    let padContent: PadContent?
    let macContent: MacContent?
    
    init(
        @ViewBuilder phone: (() -> PhoneContent)? = nil,
        @ViewBuilder pad: (() -> PadContent)? = nil,
        @ViewBuilder mac: (() -> MacContent)? = nil
    ) {
        self.phoneContent = phone?()
        self.padContent = pad?()
        self.macContent = mac?()
    }
    
    var body: some View {
        switch layout.deviceType {
        case .iPhone:
            if let phoneContent = phoneContent {
                phoneContent
            } else if let padContent = padContent {
                padContent
            } else {
                macContent
            }
        case .iPad:
            if let padContent = padContent {
                padContent
            } else if let phoneContent = phoneContent {
                phoneContent
            } else {
                macContent
            }
        case .mac:
            if let macContent = macContent {
                macContent
            } else if let padContent = padContent {
                padContent
            } else {
                phoneContent
            }
        }
    }
}

// MARK: - Adaptive Spacing
struct AdaptiveSpacing: View {
    @Environment(\.adaptiveLayout) private var layout
    let multiplier: CGFloat
    
    init(_ multiplier: CGFloat = 1.0) {
        self.multiplier = multiplier
    }
    
    var body: some View {
        Spacer()
            .frame(height: layout.sectionSpacing * multiplier)
    }
}

// MARK: - Safe Area Adaptive View
struct SafeAreaAdaptive<Content: View>: View {
    let content: Content
    let edges: Edge.Set
    
    init(edges: Edge.Set = .all, @ViewBuilder content: () -> Content) {
        self.edges = edges
        self.content = content()
    }
    
    var body: some View {
        let deviceInfo = DeviceInfo.shared
        
        if deviceInfo.deviceType == .iPhone {
            content
                .safeAreaInset(edge: .top) {
                    if edges.contains(.top) {
                        Color.clear.frame(height: 0)
                    }
                }
        } else {
            content
        }
    }
}