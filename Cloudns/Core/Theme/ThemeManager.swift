import SwiftUI
import Combine

// MARK: - App Theme Manager

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @AppStorage(AppStorageKey.themeColor)
    private var storedColorKey: String = AppThemeColor.orange.rawValue
    
    @Published public var currentColor: AppThemeColor = .orange
    
    private init() {
        if let theme = AppThemeColor(rawValue: storedColorKey) {
            self.currentColor = theme
        } else {
            self.currentColor = .orange
        }
    }
    
    public func setThemeColor(_ theme: AppThemeColor) {
        guard currentColor != theme else { return }
        HapticManager.selection()
        currentColor = theme
        storedColorKey = theme.rawValue
    }
}
