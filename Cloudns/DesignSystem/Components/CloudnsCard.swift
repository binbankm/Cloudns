import SwiftUI

// MARK: - Cloudns Card Style

public enum CloudnsCardStyle {
    /// 现代毛玻璃晶体质感 (Apple ultraThinMaterial + 0.5pt 高光微描边)
    case frosted
    /// Apple 原生分组卡片 (secondarySystemGroupedBackground)
    case grouped
    /// 品牌环境高光卡片 (带微弱渐变光晕底座)
    case brandGlow(accent: Color)
}

// MARK: - Cloudns Card Size

public enum CloudnsCardSize {
    /// 紧凑卡片 (列表子项、迷你指标卡，12pt 圆角)
    case compact
    /// 标准主内容卡片 (16pt 圆角，HIG 推荐标准)
    case standard
    /// 大尺寸卡片 / Hero 容器 (20pt 圆角)
    case hero
    
    public var cornerRadius: CGFloat {
        switch self {
        case .compact: return CloudnsRadius.md
        case .standard: return CloudnsRadius.lg
        case .hero: return CloudnsRadius.xl
        }
    }
    
    public var padding: EdgeInsets {
        switch self {
        case .compact:
            return EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        case .standard:
            return EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        case .hero:
            return EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
        }
    }
}

// MARK: - Cloudns Card ViewModifier

public struct CloudnsCardModifier: ViewModifier {
    let style: CloudnsCardStyle
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let isClickable: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false
    
    public init(
        style: CloudnsCardStyle = .frosted,
        size: CloudnsCardSize = .standard,
        padding: EdgeInsets? = nil,
        isClickable: Bool = false
    ) {
        self.style = style
        self.cornerRadius = size.cornerRadius
        self.padding = padding ?? size.padding
        self.isClickable = isClickable
    }
    
    public init(
        style: CloudnsCardStyle = .frosted,
        cornerRadius: CGFloat = CloudnsRadius.lg,
        padding: EdgeInsets = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
        isClickable: Bool = false
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isClickable = isClickable
    }
    
    public func body(content: Content) -> some View {
        let base = content
            .padding(padding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .shadow(
                color: shadowColor,
                radius: colorScheme == .dark ? 10 : 8,
                x: 0,
                y: colorScheme == .dark ? 3 : 2
            )
            .scaleEffect(isPressed && isClickable ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)

        if isClickable {
            base
                .accessibilityAddTraits(.isButton)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
        } else {
            base
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .frosted:
            CloudnsColor.secondaryGroupedBackground
        case .grouped:
            CloudnsColor.secondaryGroupedBackground
        case .brandGlow(let accent):
            ZStack {
                CloudnsColor.secondaryGroupedBackground
                RadialGradient(
                    gradient: Gradient(colors: [accent.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 180
                )
            }
        }
    }
    
    private var borderColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.12)
        } else {
            return Color.black.opacity(0.06)
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.25)
        } else {
            return Color.black.opacity(0.04)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// 应用 Apple HIG 标准的 Cloudns 现代卡片样式 (语义尺寸版)
    func cloudnsCard(
        style: CloudnsCardStyle = .frosted,
        size: CloudnsCardSize = .standard,
        padding: EdgeInsets? = nil,
        isClickable: Bool = false
    ) -> some View {
        self.modifier(CloudnsCardModifier(
            style: style,
            size: size,
            padding: padding,
            isClickable: isClickable
        ))
    }
    
    /// 应用 Apple HIG 标准的 Cloudns 现代卡片样式 (自定义圆角/间距版)
    func cloudnsCard(
        style: CloudnsCardStyle = .frosted,
        cornerRadius: CGFloat,
        padding: EdgeInsets = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
        isClickable: Bool = false
    ) -> some View {
        self.modifier(CloudnsCardModifier(
            style: style,
            cornerRadius: cornerRadius,
            padding: padding,
            isClickable: isClickable
        ))
    }
}
