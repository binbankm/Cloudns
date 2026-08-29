import SwiftUI

// MARK: - ListRowIcon

/// Apple HIG 规范列表行首图标容器组件
/// 提供统一的 30×30 pt 连续曲率圆角容器与语义颜色渲染，解决行首图标参差不齐、文字不对齐的问题
struct ListRowIcon: View {
    let icon: String
    let color: Color
    var size: CGFloat = 30
    var cornerRadius: CGFloat = 7
    
    init(icon: String, color: Color, size: CGFloat = 30, cornerRadius: CGFloat = 7) {
        self.icon = icon
        self.color = color
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - AccountAvatarView

/// Apple HIG 规范全局统一的动态账号头像组件
/// 根据用户邮箱或标识符自动生成确定性的彩虹微渐变圆形头像，附带精致的高级光晕投影
public struct AccountAvatarView: View {
    public let identifier: String
    public let size: CGFloat
    public let showShadow: Bool
    
    private static let avatarColors: [Color] = [
        .orange, .blue, .purple, .teal, .indigo, .pink, .green
    ]
    
    public init(identifier: String, size: CGFloat = 34, showShadow: Bool = true) {
        self.identifier = identifier
        self.size = size
        self.showShadow = showShadow
    }
    
    public var body: some View {
        let initial = String(identifier.prefix(1)).uppercased()
        let color = AccountAvatarView.color(for: identifier)
        
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: showShadow ? color.opacity(0.28) : .clear, radius: size > 40 ? 6 : 3, x: 0, y: 2)
            
            Text(initial.isEmpty ? "?" : initial)
                .font(fontSize.weight(.bold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
    
    private var fontSize: Font {
        if size >= 50 {
            return .title2
        } else if size >= 40 {
            return .headline
        } else if size >= 30 {
            return .subheadline
        } else {
            return .caption
        }
    }
    
    public static func color(for string: String) -> Color {
        guard !string.isEmpty else { return .orange }
        let hash = abs(string.hashValue)
        return avatarColors[hash % avatarColors.count]
    }
}
