import SwiftUI
import UIKit

// MARK: - Apple HIG Feedback & Haptics

/// 统一遵循 Apple HIG 规范的触感与反馈管理器
@MainActor
public enum HIGFeedback {
    
    /// 检查用户在设置中是否开启了触感反馈（默认 true）
    public static var isHapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: AppStorageKey.hapticsEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppStorageKey.hapticsEnabled)
    }
    
    /// 触发轻微点按触感（用于切换、选择、轻量交互）
    public static func selection() {
        guard isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// 触发撞击触感
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 触发成功通知触感
    public static func success() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// 触发警告通知触感
    public static func warning() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// 触发错误通知触感
    public static func error() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// 触发通知触感快捷通道
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Legacy Compatibility

@MainActor
public enum HapticManager {
    public static func selection() {
        HIGFeedback.selection()
    }
    
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        HIGFeedback.impact(style)
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        HIGFeedback.notification(type)
    }
}

// MARK: - HIG Touch Target Standard (44x44pt)

public struct HIGTouchTargetModifier: ViewModifier {
    public let minSize: CGFloat
    
    public init(minSize: CGFloat = 44) {
        self.minSize = minSize
    }
    
    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

public extension View {
    func higTouchTarget(_ minSize: CGFloat = 44) -> some View {
        self.modifier(HIGTouchTargetModifier(minSize: minSize))
    }
}
