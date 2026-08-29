import SwiftUI
import UIKit

// MARK: - Apple HIG Feedback & Haptics

/// 统一遵循 Apple HIG 规范的触感与反馈管理器
@MainActor
public enum HIGFeedback {
    
    /// 触发轻微点按触感（用于切换、选择、轻量交互）
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// 触发撞击触感
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 触发成功通知触感
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// 触发警告通知触感
    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// 触发错误通知触感
    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// 触发通知触感快捷通道
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
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

