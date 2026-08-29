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
