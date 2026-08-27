import SwiftUI

// MARK: - Adaptive Grid Helpers

public extension GridItem {
    /// 标准响应式卡片网格布局：iPhone 自动 2 列，iPad / 横屏大屏自动 3~4 列
    static var cloudnsAdaptiveMetrics: [GridItem] {
        [GridItem(.adaptive(minimum: 155, maximum: 240), spacing: 12)]
    }
}

// MARK: - Responsive Container ViewModifier

public struct CenterConstrainedWidthModifier: ViewModifier {
    let maxWidth: CGFloat
    
    public init(maxWidth: CGFloat = 840) {
        self.maxWidth = maxWidth
    }
    
    public func body(content: Content) -> some View {
        HStack {
            Spacer(minLength: 0)
            content
                .frame(maxWidth: maxWidth)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Sensory Feedback Compatibility Bridge

public struct CloudnsSensorySelectionModifier<T: Equatable>: ViewModifier {
    let trigger: T
    
    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .sensoryFeedback(.selection, trigger: trigger)
        } else {
            content
                .onChange(of: trigger) { _ in
                    HapticManager.selection()
                }
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// 限制 iPad / 横屏下的最大可视内容宽度，并居中呈现，防止内容横向过度拉伸
    func centerConstrainedWidth(maxWidth: CGFloat = 840) -> some View {
        self.modifier(CenterConstrainedWidthModifier(maxWidth: maxWidth))
    }
    
    /// 声明式选择触觉反馈 (兼容 iOS 16 与 iOS 17+)
    func cloudnsSensorySelection<T: Equatable>(trigger: T) -> some View {
        self.modifier(CloudnsSensorySelectionModifier(trigger: trigger))
    }
}
