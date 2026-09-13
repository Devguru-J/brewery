import Foundation
import Observation

/// 앱 언어. "system"이면 Mac의 언어를 따르고, 아니면 해당 .lproj 번들을 직접 쓴다.
@MainActor
@Observable
final class LanguageSettings {
    static let shared = LanguageSettings()
    static let key = "language"
    static let system = "system"

    struct Option: Identifiable, Hashable {
        let code: String
        let nativeName: String
        var id: String { code }
    }

    static let options: [Option] = [
        Option(code: "ko", nativeName: "한국어"),
        Option(code: "en", nativeName: "English"),
        Option(code: "ja", nativeName: "日本語"),
        Option(code: "zh-Hans", nativeName: "简体中文"),
        Option(code: "es", nativeName: "Español"),
        Option(code: "de", nativeName: "Deutsch"),
        Option(code: "fr", nativeName: "Français"),
    ]

    var language: String {
        didSet { UserDefaults.standard.set(language, forKey: Self.key) }
    }

    private init() {
        language = UserDefaults.standard.string(forKey: Self.key) ?? Self.system
    }

    var bundle: Bundle { Self.bundle(for: language) }
    var locale: Locale { Self.locale(for: language) }

    nonisolated static func bundle(for language: String) -> Bundle {
        guard language != system,
              let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let b = Bundle(path: path) else { return .main }
        return b
    }

    nonisolated static func locale(for language: String) -> Locale {
        language == system ? .autoupdatingCurrent : Locale(identifier: language)
    }

    /// 어느 스레드에서든 읽을 수 있는 현재 언어 코드.
    nonisolated static var currentLanguage: String {
        UserDefaults.standard.string(forKey: key) ?? system
    }
}

/// 현재 언어로 번역. 서식 인자는 String(format:)와 같다.
func L(_ key: String, _ args: CVarArg...) -> String {
    let lang = LanguageSettings.currentLanguage
    let format = LanguageSettings.bundle(for: lang).localizedString(forKey: key, value: nil, table: nil)
    return args.isEmpty ? format : String(format: format, locale: LanguageSettings.locale(for: lang), arguments: args)
}
