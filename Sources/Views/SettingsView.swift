import SwiftUI

/// 테마 + 언어 선택. 설정 창, 툴바 팝오버, 사이드바에서 같은 내용을 쓴다.
struct AppearancePanel: View {
    @AppStorage("theme") private var themeID: ThemeID = .native
    @Environment(\.theme) private var theme
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("settings.theme")).font(.headline)
            HStack(spacing: 12) {
                ForEach(ThemeID.allCases) { id in
                    ThemePreviewCard(theme: Theme.named(id), selected: themeID == id, compact: compact)
                        .onTapGesture { withAnimation { themeID = id } }
                }
            }
            Text(L("settings.themeHint"))
                .font(.caption).foregroundStyle(.secondary)

            Divider()

            Text(L("settings.language")).font(.headline)
            LanguagePicker()
            Text(L("settings.languageHint"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct LanguagePicker: View {
    @Environment(\.theme) private var theme
    private var settings: LanguageSettings { LanguageSettings.shared }

    var body: some View {
        @Bindable var settings = settings
        Picker("language", selection: $settings.language) {
            Text(L("settings.languageSystem")).tag(LanguageSettings.system)
            Divider()
            ForEach(LanguageSettings.options) { opt in
                Text(opt.nativeName).tag(opt.code)
            }
        }
        .labelsHidden()
        .frame(maxWidth: 260, alignment: .leading)
    }
}

struct SettingsView: View {
    var body: some View {
        AppearancePanel()
            .padding(24)
            .frame(width: 560)
    }
}

struct ThemePreviewCard: View {
    let theme: Theme
    let selected: Bool
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: theme.cornerRadius / 2, style: .continuous)
                    .fill(theme.windowBackground ?? Color(nsColor: .windowBackgroundColor))
                VStack(alignment: .leading, spacing: 6) {
                    Capsule().fill(theme.accent).frame(width: 60, height: 10)
                    RoundedRectangle(cornerRadius: 4).fill(theme.cardFill).frame(height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.cardStroke))
                    RoundedRectangle(cornerRadius: 4).fill(theme.logBackground).frame(height: 22)
                        .overlay(alignment: .leading) {
                            Text("$ brew upgrade").font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(theme.logStdout).padding(.leading, 6)
                        }
                }
                .padding(10)
            }
            .frame(height: compact ? 90 : 110)
            .environment(\.colorScheme, theme.colorScheme ?? .light)
            Text(L(theme.name)).font(.subheadline.weight(.semibold))
            Text(L(theme.tagline)).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: compact ? 0 : 30, alignment: .topLeading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: selected ? 2 : 1)
        )
        .contentShape(Rectangle())
    }
}
