import UIKit

// MARK: - Global Apple HIG Pure Chevron Navigation Bar
// Implements iOS 14+ native UINavigationItem.backButtonDisplayMode = .minimal
// completely eliminating mixed-language fallback text artifacts while preserving
// native swipe-to-back gestures, RTL auto-flipping, and VoiceOver accessibility.

extension UIViewController {
    private static var hasConfiguredMinimalBack = false
    
    public static func configureGlobalMinimalBackButton() {
        guard !hasConfiguredMinimalBack else { return }
        hasConfiguredMinimalBack = true
        
        let originalSelector = #selector(viewWillAppear(_:))
        let swizzledSelector = #selector(cloudns_minimalBack_viewWillAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc private func cloudns_minimalBack_viewWillAppear(_ animated: Bool) {
        cloudns_minimalBack_viewWillAppear(animated)
        navigationItem.backButtonDisplayMode = .minimal
    }
}
