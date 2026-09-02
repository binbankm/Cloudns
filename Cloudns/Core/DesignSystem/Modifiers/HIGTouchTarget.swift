import SwiftUI

// MARK: - Apple HIG Standard Touch Target (≥ 44×44 pt)
// Strict adherence to Apple Human Interface Guidelines for touch target size

public struct HIGTouchTargetModifier: ViewModifier {
    public let minSize: CGFloat
    
    public init(minSize: CGFloat = HIGTokens.Size.minTouchTarget) {
        self.minSize = minSize
    }
    
    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

public extension View {
    /// Ensures interactive controls meet the canonical Apple HIG ≥ 44×44 pt touch target size
    func higTouchTarget(_ minSize: CGFloat = HIGTokens.Size.minTouchTarget) -> some View {
        self.modifier(HIGTouchTargetModifier(minSize: minSize))
    }
}
