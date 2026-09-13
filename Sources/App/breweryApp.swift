import SwiftUI

@main
struct breweryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pipeline: UpgradePipeline
    @State private var store: PackageStore
    @State private var icons: AppIconResolver
    @AppStorage("theme") private var themeID: ThemeID = .native

    private var theme: Theme { Theme.named(themeID) }

    init() {
        let brew = BrewLocator.locate()
        let pipeline = UpgradePipeline(runner: BrewRunner(), brewURL: brew)
        let store = PackageStore(runner: BrewRunner(), brewURL: brew)
        let icons = AppIconResolver(caskroom: store.caskroom)
        pipeline.onPackagesChanged = { [store, icons] in
            icons.invalidate()
            Task { await store.refreshInstalled() }
        }
        _pipeline = State(initialValue: pipeline)
        _store = State(initialValue: store)
        _icons = State(initialValue: icons)
    }

    var body: some Scene {
        Window("brewery", id: "main") {
            RootView()
                .environment(pipeline)
                .environment(store)
                .environment(icons)
                .environment(\.theme, theme)
                .preferredColorScheme(theme.colorScheme)
                .onAppear { AppDelegate.onTerminate = { [pipeline] in pipeline.cancel() } }
        }
        .defaultSize(width: 1100, height: 900)
        .defaultPosition(.center)

        MenuBarExtra {
            MenuBarPanel()
                .environment(pipeline)
                .environment(\.theme, theme)
        } label: {
            Image(systemName: pipeline.isRunning ? "mug" : "mug.fill")
            if pipeline.outdatedCount > 0 {
                Text("\(pipeline.outdatedCount)")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(\.theme, theme)
        }
    }
}
