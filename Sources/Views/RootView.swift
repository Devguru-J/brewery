import SwiftUI

enum Screen: String, CaseIterable, Identifiable {
    case upgrade, installed, search
    var id: String { rawValue }
    var title: String {
        switch self {
        case .upgrade: return L("sidebar.upgrade")
        case .installed: return L("sidebar.installed")
        case .search: return L("sidebar.search")
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
    @State private var showAppearance = false
    @State private var showAppearanceFromSidebar = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
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
                Divider()
                Button {
                    showAppearanceFromSidebar.toggle()
                } label: {
                    Label(L("sidebar.appearance"), systemImage: "paintpalette")
                        .font(theme.bodyFont)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .popover(isPresented: $showAppearanceFromSidebar, arrowEdge: .trailing) {
                    AppearancePanel(compact: true).padding(20).frame(width: 520)
                }
            }
            .background(sidebarBackground)
            .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAppearance.toggle()
                } label: {
                    Label(L("appearance.title"), systemImage: "paintpalette")
                }
                .help(L("appearance.help"))
                .popover(isPresented: $showAppearance, arrowEdge: .bottom) {
                    AppearancePanel(compact: true).padding(20).frame(width: 520)
                }
            }
        }
        .frame(minWidth: 960, minHeight: 840)
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
