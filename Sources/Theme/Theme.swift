import SwiftUI

enum ThemeID: String, CaseIterable, Identifiable {
    case native, terminal, taproom
    var id: String { rawValue }
}

enum ProgressStyle { case ring, cursor, foam }

struct Theme {
    let id: ThemeID
    let name: String
    let tagline: String
    let colorScheme: ColorScheme?
    let accent: Color
    let windowBackground: Color?      // nil이면 시스템 창 배경 + 재질
    let cardFill: Color
    let cardStroke: Color
    let cornerRadius: CGFloat
    let titleFont: Font
    let bodyFont: Font
    let captionFont: Font
    let logFont: Font
    let logBackground: Color
    let logStdout: Color
    let logStderr: Color
    let logSystem: Color
    let progress: ProgressStyle
    let glow: Bool

    static let native = Theme(
        id: .native, name: "macOS 순정", tagline: "시스템 재질과 SF Symbols",
        colorScheme: nil,
        accent: .accentColor,
        windowBackground: nil,
        cardFill: Color(nsColor: .controlBackgroundColor).opacity(0.7),
        cardStroke: Color.primary.opacity(0.08),
        cornerRadius: 14,
        titleFont: .system(.title, design: .default, weight: .semibold),
        bodyFont: .system(.body),
        captionFont: .system(.caption),
        logFont: .system(.callout, design: .monospaced),
        logBackground: Color(nsColor: .textBackgroundColor),
        logStdout: .primary,
        logStderr: .orange,
        logSystem: .secondary,
        progress: .ring, glow: false)

    static let terminal = Theme(
        id: .terminal, name: "다크 터미널", tagline: "검정 바탕, 초록 글씨, 글로우",
        colorScheme: .dark,
        accent: Color(red: 0.35, green: 1.0, blue: 0.55),
        windowBackground: Color(red: 0.04, green: 0.05, blue: 0.05),
        cardFill: Color(white: 0.09),
        cardStroke: Color(red: 0.35, green: 1.0, blue: 0.55).opacity(0.25),
        cornerRadius: 6,
        titleFont: .system(.title, design: .monospaced, weight: .bold),
        bodyFont: .system(.body, design: .monospaced),
        captionFont: .system(.caption, design: .monospaced),
        logFont: .system(.callout, design: .monospaced),
        logBackground: .black,
        logStdout: Color(red: 0.75, green: 0.95, blue: 0.80),
        logStderr: Color(red: 1.0, green: 0.70, blue: 0.30),
        logSystem: Color(white: 0.55),
        progress: .cursor, glow: true)

    static let taproom = Theme(
        id: .taproom, name: "맥주집", tagline: "호박색 팔레트와 거품",
        colorScheme: .light,
        accent: Color(red: 0.85, green: 0.52, blue: 0.12),
        windowBackground: Color(red: 0.98, green: 0.95, blue: 0.89),
        cardFill: Color(red: 1.0, green: 0.99, blue: 0.96),
        cardStroke: Color(red: 0.85, green: 0.52, blue: 0.12).opacity(0.25),
        cornerRadius: 22,
        titleFont: .system(.title, design: .rounded, weight: .bold),
        bodyFont: .system(.body, design: .rounded),
        captionFont: .system(.caption, design: .rounded),
        logFont: .system(.callout, design: .monospaced),
        logBackground: Color(red: 0.25, green: 0.16, blue: 0.08),
        logStdout: Color(red: 0.98, green: 0.93, blue: 0.82),
        logStderr: Color(red: 1.0, green: 0.62, blue: 0.40),
        logSystem: Color(red: 0.85, green: 0.70, blue: 0.50),
        progress: .foam, glow: false)

    static func named(_ id: ThemeID) -> Theme {
        switch id {
        case .native: return .native
        case .terminal: return .terminal
        case .taproom: return .taproom
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.native
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
