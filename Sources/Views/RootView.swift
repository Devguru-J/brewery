import SwiftUI

enum Screen: String, CaseIterable, Identifiable {
    case upgrade, installed, search
    var id: String { rawValue }
    var title: String {
        switch self {
        case .upgrade: return "업그레이드"
        case .installed: return "설치된 패키지"
        case .search: return "검색"
        }
    }
    var symbol: String {
        switch self {
        case .upgrade: return "arrow.up.circle.fill"
        case .installed: return "shippingbox.fill"
        case .search: return "magnifyingglass"
        }
    }
}

struct RootView: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(PackageStore.self) private var store
    @Environment(\.theme) private var theme
    @State private var screen: Screen? = .upgrade
    @State private var logExpanded = true

    var body: some View {
        NavigationSplitView {
            List(Screen.allCases, selection: $screen) { s in
                Label {
                    HStack {
                        Text(s.title)
                        Spacer()
                        badge(for: s)
                    }
                } icon: {
                    Image(systemName: s.symbol).foregroundStyle(theme.accent)
                }
                .font(theme.bodyFont)
                .tag(s)
            }
            .scrollContentBackground(.hidden)
            .background(sidebarBackground)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            VStack(spacing: 16) {
                switch screen ?? .upgrade {
                case .upgrade: UpgradeScreen()
                case .installed: InstalledScreen()
                case .search: SearchScreen()
                }
                LogConsole(isExpanded: $logExpanded)
                    .frame(height: logExpanded ? 220 : 44)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background)
        }
        .frame(minWidth: 900, minHeight: 720)
        .task {
            await pipeline.refreshOutdated()
            await store.refreshInstalled()
        }
        .onChange(of: pipeline.lastError) { _, err in
            if err != nil { withAnimation { logExpanded = true } }
        }
    }

    @ViewBuilder
    private func badge(for s: Screen) -> some View {
        let n: Int = switch s {
        case .upgrade: pipeline.outdatedCount
        case .installed: store.installed.count
        case .search: 0
        }
        if n > 0 {
            Text("\(n)")
                .font(theme.captionFont.weight(.semibold))
                .padding(.horizontal, 6).padding(.vertical, 1)
                .background(Capsule().fill(theme.accent.opacity(0.18)))
                .foregroundStyle(theme.accent)
        }
    }

    @ViewBuilder
    private var background: some View {
        if let bg = theme.windowBackground { bg } else { Rectangle().fill(.regularMaterial) }
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if let bg = theme.windowBackground { bg.opacity(0.85) } else { Color.clear }
    }
}
