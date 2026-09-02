import SwiftUI

// MARK: - Apple HIG Canonical Design Tokens
// Strict adherence to Apple Human Interface Guidelines (iOS 16.0+)

public enum HIGTokens {
    
    // MARK: - 1. Spacing Tokens (4pt / 8pt Grid System)
    public enum Spacing {
        /// 2 pt — Minimal spacing (micro badges, compact elements)
        public static let xxs: CGFloat = 2
        
        /// 4 pt — Extra small spacing (inline badges, compact padding)
        public static let xs: CGFloat = 4
        
        /// 8 pt — Small spacing (icon-to-text, secondary elements)
        public static let sm: CGFloat = 8
        
        /// 12 pt — Medium spacing (compact card interior, row spacing)
        public static let md: CGFloat = 12
        
        /// 16 pt — Standard spacing (Apple canonical screen margins and card padding)
        public static let lg: CGFloat = 16
        
        /// 20 pt — Large spacing (section gaps, emphasized groups)
        public static let xl: CGFloat = 20
        
        /// 24 pt — Extra large spacing (module separation, title gutters)
        public static let xxl: CGFloat = 24
        
        /// 32 pt — Huge spacing (empty state offsets, modal headers)
        public static let huge: CGFloat = 32
    }
    
    // MARK: - 2. Continuous Corner Radius Tokens (Smooth Apple Curves)
    public enum Radius {
        /// 4 pt — Extra small continuous radius (micro indicators)
        public static let xs: CGFloat = 4
        
        /// 6 pt — Small continuous radius (DNS type pills, compact tags)
        public static let sm: CGFloat = 6
        
        /// 7 pt — Standard list row icon corner radius (30×30 pt container)
        public static let listIcon: CGFloat = 7
        
        /// 10 pt — Medium continuous radius (text fields, standard action buttons)
        public static let md: CGFloat = 10
        
        /// 12 pt — Standard card continuous radius (Inset Grouped and Bento cards)
        public static let card: CGFloat = 12
        
        /// 16 pt — Large container continuous radius (modals, prominent cards)
        public static let lg: CGFloat = 16
        
        /// 999 pt — Full capsule radius (status badges, pill buttons)
        public static let pill: CGFloat = 999
    }
    
    // MARK: - 3. Size & Touch Target Standards
    public enum Size {
        /// 44 pt — Apple HIG canonical minimum interactive touch target size
        public static let minTouchTarget: CGFloat = 44
        
        /// 30 pt — Standard list row leading icon container dimension
        public static let listRowIcon: CGFloat = 30
        
        /// 34 pt — Compact avatar diameter
        public static let avatarSmall: CGFloat = 34
        
        /// 44 pt — Standard avatar diameter
        public static let avatarMedium: CGFloat = 44
        
        /// 20 pt — Compact badge height
        public static let badgeHeightCompact: CGFloat = 20
        
        /// 24 pt — Standard badge height
        public static let badgeHeightStandard: CGFloat = 24
    }
    
    // MARK: - 4. Elevation & Shadow Tokens
    public enum Elevation {
        /// 0.5 pt — Apple standard hairline stroke width
        public static let hairlineStroke: CGFloat = 0.5
        
        /// 0.8 pt — Overlay and floating HUD border stroke width
        public static let overlayStroke: CGFloat = 0.8
        
        /// Standard card shadow radius
        public static let cardShadowRadius: CGFloat = 8
        public static let cardShadowY: CGFloat = 2
        
        /// Overlay HUD and modal shadow radius
        public static let overlayShadowRadius: CGFloat = 16
        public static let overlayShadowY: CGFloat = 6
    }
}
