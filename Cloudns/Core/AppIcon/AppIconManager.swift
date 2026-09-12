import Combine
import SwiftUI

// MARK: - AppIconOption

public enum AppIconOption: String, CaseIterable, Identifiable {
    case primary = "AppIcon-Default"
    case cyber = "AppIcon-Cyber"
    case dark = "AppIcon-Dark"
    case gold = "AppIcon-Gold"
    case purple = "AppIcon-Purple"

    public var id: String {
        rawValue
    }

    public var iconName: String? {
        switch self {
        case .primary:
            nil
        case .cyber:
            "AppIcon-Cyber"
        case .dark:
            "AppIcon-Dark"
        case .gold:
            "AppIcon-Gold"
        case .purple:
            "AppIcon-Purple"
        }
    }

    public var displayName: LocalizedStringKey {
        switch self {
        case .primary:
            "Classic Orange"
        case .cyber:
            "Cyber Cyan"
        case .dark:
            "Stealth Dark"
        case .gold:
            "Golden Amber"
        case .purple:
            "Midnight Violet"
        }
    }

    public var rawDisplayName: String {
        switch self {
        case .primary: "Classic Orange"
        case .cyber: "Cyber Cyan"
        case .dark: "Stealth Dark"
        case .gold: "Golden Amber"
        case .purple: "Midnight Violet"
        }
    }

    public var subtitle: LocalizedStringKey {
        switch self {
        case .primary:
            "Official Cloudflare orange gradient"
        case .cyber:
            "Neon cyan & electric blue glow"
        case .dark:
            "Matte obsidian with brushed titanium"
        case .gold:
            "Champagne gold & luxury amber"
        case .purple:
            "Midnight violet & deep nebula glow"
        }
    }

    public var previewImageName: String {
        rawValue
    }
}

// MARK: - AppIconManager

@MainActor
public final class AppIconManager: ObservableObject {
    public static let shared = AppIconManager()

    @Published public private(set) var currentIcon: AppIconOption = .primary
    @Published public private(set) var isChanging: Bool = false

    private init() {
        syncCurrentIcon()
    }

    public func syncCurrentIcon() {
        guard UIApplication.shared.supportsAlternateIcons else {
            currentIcon = .primary
            return
        }

        let activeName = UIApplication.shared.alternateIconName
        if let activeName, let match = AppIconOption.allCases.first(where: { $0.iconName == activeName }) {
            currentIcon = match
        } else {
            currentIcon = .primary
        }
    }

    public func setIcon(_ icon: AppIconOption) {
        Task {
            await selectIcon(icon)
        }
    }

    public func selectIcon(_ icon: AppIconOption) async {
        guard currentIcon != icon else { return }

        guard UIApplication.shared.supportsAlternateIcons else {
            HapticManager.warning()
            return
        }

        isChanging = true
        defer { isChanging = false }

        do {
            try await UIApplication.shared.setAlternateIconName(icon.iconName)
            currentIcon = icon
            UserDefaults.standard.set(icon.rawValue, forKey: AppStorageKey.appIcon)
            HapticManager.success()
        } catch {
            HapticManager.error()
            syncCurrentIcon()
        }
    }
}
