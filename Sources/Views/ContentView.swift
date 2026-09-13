import SwiftUI

struct ContentView: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme
    @State private var logExpanded = true

    var body: some View {
        VStack(spacing: 16) {
            HeroPanel()
            StepCards()
                .frame(height: 180)
            VSplitView {
                OutdatedList()
                    .frame(minHeight: 160)
                    .padding(.bottom, 8)
                LogConsole(isExpanded: $logExpanded)
                    .frame(minHeight: logExpanded ? 140 : 44)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 740)
        .background(background)
        .task { await pipeline.refreshOutdated() }
        .onChange(of: pipeline.lastError) { _, err in
            if err != nil { withAnimation { logExpanded = true } }
        }
    }

    @ViewBuilder
    private var background: some View {
        if let bg = theme.windowBackground {
            bg
        } else {
            Rectangle().fill(.regularMaterial)
        }
    }
}
