import SwiftUI

// MARK: - Adaptive Container
struct AdaptiveContainer<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: layout.maxContentWidth)
            .padding(.horizontal, layout.contentPadding)
    }
}

// MARK: - Adaptive Grid
struct AdaptiveGrid<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: layout.gridColumns),
            spacing: layout.gridSpacing
        ) {
            content
        }
    }
}

// MARK: - Adaptive Button
struct AdaptiveButton: View {
    @Environment(\.adaptiveLayout) private var layout
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize))
                }
                
                Text(title)
                    .font(.system(size: layout.bodyFontSize, weight: .medium))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: layout.buttonHeight)
            .background(backgroundColor)
            .cornerRadius(layout.cornerRadius)
        }
        .buttonStyle(.plain)
    }
} 
   // MARK: - Button Style Properties
    private var iconSize: CGFloat {
        switch layout.screenSize {
        case .compact: return 16
        case .regular: return 18
        case .large: return 20
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .blue
        case .destructive: return .red
        case .ghost: return .primary
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .blue
        case .secondary: return .blue.opacity(0.1)
        case .destructive: return .red.opacity(0.1)
        case .ghost: return .clear
        }
    }
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
    }
}

// MARK: - Adaptive Text
struct AdaptiveText: View {
    @Environment(\.adaptiveLayout) private var layout
    let text: String
    let style: TextStyle
    
    init(_ text: String, style: TextStyle = .body) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
    }
    
    private var fontSize: CGFloat {
        switch style {
        case .title: return layout.titleFontSize
        case .headline: return layout.bodyFontSize + 2
        case .body: return layout.bodyFontSize
        case .caption: return layout.captionFontSize
        }
    }
    
    private var fontWeight: Font.Weight {
        switch style {
        case .title: return .bold
        case .headline: return .semibold
        case .body: return .regular
        case .caption: return .regular
        }
    }
    
    private var textColor: Color {
        switch style {
        case .title, .headline: return .primary
        case .body: return .primary
        case .caption: return .secondary
        }
    }
    
    enum TextStyle {
        case title
        case headline
        case body
        case caption
    }
}

// MARK: - Adaptive Card
struct AdaptiveCard<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(layout.contentPadding)
            .background(Color(.systemBackground))
            .cornerRadius(layout.cornerRadius)
            .shadow(
                color: .black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
    }
    
    private var shadowRadius: CGFloat {
        switch layout.screenSize {
        case .compact: return 2
        case .regular: return 4
        case .large: return 6
        }
    }
    
    private var shadowOffset: CGFloat {
        switch layout.screenSize {
        case .compact: return 1
        case .regular: return 2
        case .large: return 3
        }
    }
}