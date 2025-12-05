import Foundation
import SwiftUI

public let AppLanguageKey = "AtomicXLanguageKey"
public let AppLanguageChangedNotification = "AtomicXLanguageChangedKey"
@inline(__always)
public func LocalizedRTCString(_ key: String) -> String {
    LanguageHelper.localizedRTCString(key)
}

@inline(__always)
public func LocalizedChatString(_ key: String) -> String {
    LanguageHelper.localizedChatString(key)
}

public class LanguageState: ObservableObject {
    @Published public var currentLanguage: String = "en"
    public init() {
        currentLanguage = LanguageHelper.getCurrentLanguage()
    }

    public func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        LanguageHelper.saveLanguage(languageCode)
    }

    public func getCurrentLanguageName() -> String {
        if let language = supportedLanguages.first(where: { $0.code == currentLanguage }) {
            return language.nativeName
        }
        return "English"
    }

    public let supportedLanguages = [
        LanguageOption(code: "en", name: "English", nativeName: "English"),
        LanguageOption(code: "zh-Hans", name: "Simplified Chinese", nativeName: "简体中文"),
        LanguageOption(code: "zh-Hant", name: "Traditional Chinese", nativeName: "繁體中文"),
        LanguageOption(code: "ar", name: "Arabic", nativeName: "العربية")
    ]
}

public class LanguageHelper {
    public class func getLocalizedString(forKey key: String, bundle bundleName: String, classType: AnyClass, frameworkName: String) -> String {
        let currentLanguage = getCurrentLanguage()
        if let bundle = BundleHelper.findLocalizableBundle(
            bundleName: bundleName,
            classType: classType,
            language: currentLanguage,
            frameworkName: frameworkName
        ) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return key
    }

    public class func localizedChatString(_ key: String) -> String {
        return getLocalizedString(forKey: key, bundle: "ChatLocalizable", classType: LanguageHelper.self, frameworkName: "AtomicXBundle")
    }

    public class func localizedRTCString(_ key: String) -> String {
        return getLocalizedString(forKey: key, bundle: "RTCLocalizable", classType: LanguageHelper.self, frameworkName: "AtomicXBundle")
    }

    public static func getCurrentLanguage() -> String {
        if let savedLanguage = UserDefaults.standard.string(forKey: AppLanguageKey), !savedLanguage.isEmpty {
            return savedLanguage
        }
        return getSystemLanguage()
    }

    static func saveLanguage(_ languageCode: String) {
        UserDefaults.standard.set(languageCode, forKey: AppLanguageKey)
        UserDefaults.standard.synchronize()
    }

    private static func getSystemLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if preferredLanguage.hasPrefix("en") {
            return "en"
        } else if preferredLanguage.hasPrefix("zh") {
            if preferredLanguage.contains("Hans") {
                return "zh-Hans"
            } else {
                return "zh-Hant"
            }
        } else if preferredLanguage.hasPrefix("ar") {
            return "ar"
        } else {
            return "en"
        }
    }
}

public struct LanguageOption: Identifiable {
    public let id = UUID()
    public let code: String
    public let name: String
    public let nativeName: String
    public init(code: String, name: String, nativeName: String) {
        self.code = code
        self.name = name
        self.nativeName = nativeName
    }
}
