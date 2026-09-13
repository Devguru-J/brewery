import SwiftUI

@main
struct breweryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pipeline = UpgradePipeline(runner: BrewRunner(), brewURL: BrewLocator.locate())
    @AppStorage("theme") private var themeID: ThemeID = .native

    private var theme: Theme { Theme.named(themeID) }

    var body: some Scene {
        Window("brewery", id: "main") {
            ContentView()
                .environment(pipeline)
                .environment(\.theme, theme)
                .preferredColorScheme(theme.colorScheme)
                .onAppear { AppDelegate.onTerminate = { [pipeline] in pipeline.cancel() } }
        }
        .defaultSize(width: 900, height: 800)

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
