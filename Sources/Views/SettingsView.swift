import SwiftUI

struct SettingsView: View {
    @AppStorage("theme") private var themeID: ThemeID = .native

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("테마").font(.headline)
            HStack(spacing: 14) {
                ForEach(ThemeID.allCases) { id in
                    ThemePreviewCard(theme: Theme.named(id), selected: themeID == id)
                        .onTapGesture { withAnimation { themeID = id } }
                }
            }
            Text("기본값은 macOS 순정입니다. 선택은 즉시 적용됩니다.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 560)
    }
}

struct ThemePreviewCard: View {
    let theme: Theme
    let selected: Bool

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
            .frame(height: 110)
            .environment(\.colorScheme, theme.colorScheme ?? .light)
            Text(theme.name).font(.subheadline.weight(.semibold))
            Text(theme.tagline).font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: selected ? 2 : 1)
        )
        .contentShape(Rectangle())
    }
}
