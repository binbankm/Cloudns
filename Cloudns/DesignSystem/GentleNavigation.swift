import SwiftUI
import UIKit

// MARK: - Gentle Navigation Bar Theme & Configuration

/// Configures iOS UINavigationBarAppearance to eliminate harsh border lines
/// and align with the ultra-gentle oat-milk canvas theme.
public enum GentleNavigation {
    @MainActor
    public static func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        // Background color adapting to light (oat milk) and dark (graphite)
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
                : UIColor(red: 247 / 255, green: 244 / 255, blue: 238 / 255, alpha: 1.0)
        }

        // Eliminate harsh separator line
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        // SF Pro Rounded Large Title
        if let roundedDescriptor = UIFont.systemFont(ofSize: 32, weight: .bold)
            .fontDescriptor.withDesign(.rounded) {
            appearance.largeTitleTextAttributes = [
                .font: UIFont(descriptor: roundedDescriptor, size: 32),
                .foregroundColor: UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1.0)
                        : UIColor(red: 46 / 255, green: 42 / 255, blue: 39 / 255, alpha: 1.0)
                }
            ]
        }

        // SF Pro Rounded Inline Title
        if let roundedInlineDescriptor = UIFont.systemFont(ofSize: 17, weight: .semibold)
            .fontDescriptor.withDesign(.rounded) {
            appearance.titleTextAttributes = [
                .font: UIFont(descriptor: roundedInlineDescriptor, size: 17),
                .foregroundColor: UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1.0)
                        : UIColor(red: 46 / 255, green: 42 / 255, blue: 39 / 255, alpha: 1.0)
                }
            ]
        }

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 232 / 255, green: 122 / 255, blue: 30 / 255, alpha: 1.0)
    }
}
