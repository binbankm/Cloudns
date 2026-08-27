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
        cornerRadius: CGFloat = 16,
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
    /// 应用 Apple HIG 标准的 Cloudns 现代卡片样式
    func cloudnsCard(
        style: CloudnsCardStyle = .frosted,
        cornerRadius: CGFloat = 16,
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
