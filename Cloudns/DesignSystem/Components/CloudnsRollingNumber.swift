import SwiftUI

/// Cloudns 高性能数字翻牌滚动动画组件 (支持 iOS 17+ 原生硬件加速)
public struct CloudnsRollingNumber: View {
    let value: String
    let font: Font
    let weight: Font.Weight
    let color: Color
    
    public init(
        value: String,
        font: Font = CloudnsTypography.title2,
        weight: Font.Weight = .bold,
        color: Color = CloudnsColor.textPrimary
    ) {
        self.value = value
        self.font = font
        self.weight = weight
        self.color = color
    }
    
    public var body: some View {
        if #available(iOS 17.0, *) {
            Text(value)
                .font(font.monospacedDigit().weight(weight))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: 1.0))
                .animation(CloudnsAnimation.snappy, value: value)
        } else {
            Text(value)
                .font(font.monospacedDigit().weight(weight))
                .foregroundStyle(color)
                .animation(CloudnsAnimation.snappy, value: value)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// 在数据发生变化时自动应用数字翻牌器滚动微动效 (iOS 17+ 硬件加速)
    @ViewBuilder
    func cloudnsRollingTransition() -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.numericText(value: 1.0))
        } else {
            self
        }
    }
}
