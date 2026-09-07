import SwiftUI
import Combine

// MARK: - App Theme Manager

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @AppStorage(AppStorageKey.themeColor)
    private var storedColorKey: String = AppThemeColor.orange.rawValue
    
    @AppStorage("custom_theme_color_hex")
    private var storedCustomHex: String = "#F38020"
    
    @Published public var currentColor: AppThemeColor = .orange
    @Published public var customColor: Color = .orange
    
    private init() {
        let hexColor = Color(hex: storedCustomHex)
        self.customColor = hexColor
        
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
    
    public func setCustomColor(_ color: Color) {
        customColor = color
        if let hex = color.toHex() {
            storedCustomHex = hex
        }
        currentColor = .custom
        storedColorKey = AppThemeColor.custom.rawValue
    }
}

// MARK: - Color Hex Conversion
public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (243, 128, 32)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }
    
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
        }
        guard let components = uiColor.cgColor.components else { return nil }
        if components.count >= 3 {
            return String(
                format: "#%02X%02X%02X",
                Int(round(components[0] * 255)),
                Int(round(components[1] * 255)),
                Int(round(components[2] * 255))
            )
        } else if components.count >= 1 {
            let gray = Int(round(components[0] * 255))
            return String(format: "#%02X%02X%02X", gray, gray, gray)
        }
        return nil
    }
}
