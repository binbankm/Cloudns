import Foundation
import SwiftUI
import Combine

// MARK: - Bundle Dynamic Localization Extension
// Dynamically routes Bundle.main string lookups to the user's selected in-app language

private nonisolated(unsafe) var bundleKey: UInt8 = 0

final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

public extension Bundle {
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, LocalizedBundle.self)
        }
        
        if language == "system" {
            objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
            ?? Bundle.main.path(forResource: language.replacingOccurrences(of: "-", with: "_"), ofType: "lproj")
        
        guard let path = path, let bundle = Bundle(path: path) else {
            objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - LanguageManager
// Coordinates in-app language switching and SwiftUI locale environment propagation

@MainActor
public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    @Published public var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: AppStorageKey.appLanguage)
            applyLanguage(currentLanguage)
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: AppStorageKey.appLanguage) ?? "system"
        self.currentLanguage = saved
        applyLanguage(saved)
    }
    
    public func setLanguage(_ lang: String) {
        currentLanguage = lang
    }
    
    private func applyLanguage(_ lang: String) {
        Bundle.setLanguage(lang)
        if lang != "system" {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }
    
    public var currentLocale: Locale {
        if currentLanguage == "system" {
            return Locale.autoupdatingCurrent
        }
        return Locale(identifier: currentLanguage)
    }
}
