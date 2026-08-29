import SwiftUI
import Combine

// MARK: - AppIconOption

public enum AppIconOption: String, CaseIterable, Identifiable {
    case primary = "AppIcon-Default"
    case cyber = "AppIcon-Cyber"
    case dark = "AppIcon-Dark"
    case gold = "AppIcon-Gold"
    case purple = "AppIcon-Purple"
    
    public var id: String { rawValue }
    
    public var iconName: String? {
        switch self {
        case .primary:
            return nil
        case .cyber:
            return "AppIcon-Cyber"
        case .dark:
            return "AppIcon-Dark"
        case .gold:
            return "AppIcon-Gold"
        case .purple:
            return "AppIcon-Purple"
        }
    }
    
    public var displayName: LocalizedStringKey {
        switch self {
        case .primary:
            return "Classic Orange"
        case .cyber:
            return "Cyber Cyan"
        case .dark:
            return "Stealth Dark"
        case .gold:
            return "Golden Amber"
        case .purple:
            return "Midnight Violet"
        }
    }
    
    public var subtitle: LocalizedStringKey {
        switch self {
        case .primary:
            return "Official Cloudflare orange gradient"
        case .cyber:
            return "Neon cyan & electric blue glow"
        case .dark:
            return "Matte obsidian with brushed titanium"
        case .gold:
            return "Champagne gold & luxury amber"
        case .purple:
            return "Midnight violet & deep nebula glow"
        }
    }
    
    public var previewImageName: String {
        return rawValue
    }
}

// MARK: - AppIconManager

@MainActor
public final class AppIconManager: ObservableObject {
    public static let shared = AppIconManager()
    
    @AppStorage("selected_app_icon_id") private var storedIconId: String = AppIconOption.primary.rawValue
    
    @Published public private(set) var currentIcon: AppIconOption = .primary
    @Published public private(set) var isChanging: Bool = false
    
    private init() {
        self.syncCurrentIcon()
    }
    
    public func syncCurrentIcon() {
        guard UIApplication.shared.supportsAlternateIcons else {
            self.currentIcon = .primary
            return
        }
        
        let activeName = UIApplication.shared.alternateIconName
        if let activeName = activeName, let match = AppIconOption.allCases.first(where: { $0.iconName == activeName }) {
            self.currentIcon = match
        } else {
            self.currentIcon = .primary
        }
    }
    
    public func selectIcon(_ icon: AppIconOption) async {
        guard currentIcon != icon else { return }
        
        guard UIApplication.shared.supportsAlternateIcons else {
            HIGFeedback.warning()
            return
        }
        
        isChanging = true
        defer { isChanging = false }
        
        do {
            try await UIApplication.shared.setAlternateIconName(icon.iconName)
            self.currentIcon = icon
            self.storedIconId = icon.rawValue
            HIGFeedback.success()
        } catch {
            HIGFeedback.error()
            self.syncCurrentIcon()
        }
    }
}
