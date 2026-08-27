import SwiftUI

/// Cloudns 全局动态与过场动画 Token (严格遵循 Apple HIG 物理动效与手势回弹规范)
public enum CloudnsAnimation {
    // MARK: - Spring Motion Tokens
    
    /// 灵动交互弹性动画 (用于按钮按压缩放、Chip 选中、快速响应手势)
    public static let interactiveSpring: Animation = .spring(response: 0.28, dampingFraction: 0.76)
    
    /// 敏捷过渡动画 (用于 Toast 弹出提示、展开折叠栏、Segment 切换)
    public static let snappy: Animation = .spring(response: 0.22, dampingFraction: 0.85)
    
    /// 平滑柔和动画 (用于页面卡片大尺寸重排、图表数据切换、模态转场)
    public static let smooth: Animation = .spring(response: 0.40, dampingFraction: 0.88)
    
    /// 极速微动效 (用于颜色微调、透明度渐变、骨架屏微弱呼吸)
    public static let subtle: Animation = .easeInOut(duration: 0.15)
    
    /// 标准过渡 (用于列表行插入/删除)
    public static let standard: Animation = .easeInOut(duration: 0.25)
}
