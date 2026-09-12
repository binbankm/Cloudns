import Combine
import SwiftUI

// MARK: - App Theme Manager (SwiftUI Native)

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var currentColor: AppThemeColor = .orange {
        didSet {
            UserDefaults.standard.set(currentColor.rawValue, forKey: AppStorageKey.themeColor)
        }
    }

    @Published public var customColor: Color = .orange {
        didSet {
            if let hex = customColor.toHex() {
                UserDefaults.standard.set(hex, forKey: "custom_theme_color_hex")
            }
        }
    }

    public var accentColor: Color {
        currentColor == .custom ? customColor : currentColor.presetColor
    }

    public var accentUIColor: UIColor {
        UIColor(accentColor)
    }

    private init() {
        let storedCustomHex = UserDefaults.standard.string(forKey: "custom_theme_color_hex") ?? "#F38020"
        customColor = Color(hex: storedCustomHex)

        let storedColorKey = UserDefaults.standard.string(forKey: AppStorageKey.themeColor) ?? AppThemeColor.orange.rawValue
        currentColor = AppThemeColor(rawValue: storedColorKey) ?? .orange
    }

    public func setThemeColor(_ theme: AppThemeColor) {
        guard currentColor != theme else { return }
        HapticManager.selection()
        currentColor = theme
    }

    public func setCustomColor(_ color: Color) {
        customColor = color
        if currentColor != .custom {
            currentColor = .custom
        }
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
