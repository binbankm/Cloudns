import SwiftUI
import UIKit

/// 集中管理的触觉反馈工具类，统一封装 UIKit 的 UIImpactFeedbackGenerator / UINotificationFeedbackGenerator，
/// 并支持根据全局设置开关自动判断是否触发。
@MainActor
public enum HapticManager {
    
    private static var isHapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: AppStorageKey.hapticsEnabled) as? Bool ?? true
    }
    
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notificationGen = UINotificationFeedbackGenerator()
    private static let selectionGen = UISelectionFeedbackGenerator()

    /// 触发轻/中/重度触觉敲击反馈
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticsEnabled else { return }
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = lightImpact
        case .medium: generator = mediumImpact
        case .heavy: generator = heavyImpact
        case .soft: generator = softImpact
        case .rigid: generator = rigidImpact
        @unknown default: generator = mediumImpact
        }
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 触发通知型反馈（成功、警告、错误）
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        notificationGen.prepare()
        notificationGen.notificationOccurred(type)
    }
    
    /// 触发选择器切换反馈
    public static func selection() {
        guard isHapticsEnabled else { return }
        selectionGen.prepare()
        selectionGen.selectionChanged()
    }
}
