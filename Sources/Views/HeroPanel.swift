import SwiftUI

struct HeroPanel: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("brewery")
                    .font(theme.titleFont)
                Text(statusText)
                    .font(theme.bodyFont)
                    .foregroundStyle(statusColor)
                    .contentTransition(.numericText())
                    .animation(.default, value: statusText)
                Text(lastRunText)
                    .font(theme.captionFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            RunButton()
        }
        .padding(24)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
            .fill(theme.cardFill)
            .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).stroke(theme.cardStroke))
    }

    private var statusText: String {
        if !pipeline.brewAvailable { return L("hero.noBrew") }
        if let step = pipeline.currentStep { return L("hero.running", step.command) }
        if let err = pipeline.lastError { return err }
        if pipeline.isRefreshing { return L("hero.checking") }
        if pipeline.allSucceeded && pipeline.lastRun != nil { return L("hero.allDone") }
        return pipeline.outdatedCount == 0 ? L("hero.upToDate") : L("hero.outdatedCount", pipeline.outdatedCount)
    }

    private var statusColor: Color {
        if pipeline.lastError != nil || !pipeline.brewAvailable { return .red }
        if pipeline.isRunning { return theme.accent }
        return .primary
    }

    private var lastRunText: String {
        guard let d = pipeline.lastRun else { return L("hero.neverRun") }
        let f = RelativeDateTimeFormatter()
        f.locale = LanguageSettings.shared.locale
        f.dateTimeStyle = .named
        return L("hero.lastRun", f.localizedString(for: d, relativeTo: Date()))
    }
}

struct RunButton: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            if pipeline.isRunning {
                pipeline.cancel()
            } else {
                Task { await pipeline.runAll() }
            }
        } label: {
            Label(pipeline.isRunning ? L("btn.stop") : L("btn.runAll"),
                  systemImage: pipeline.isRunning ? "stop.fill" : "mug.fill")
                .font(theme.bodyFont.weight(.semibold))
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(pipeline.isRunning ? .red : theme.accent)
        .controlSize(.large)
        .disabled(!pipeline.brewAvailable || pipeline.isRefreshing)
        .keyboardShortcut(.defaultAction)
        .shadow(color: theme.glow ? theme.accent.opacity(0.6) : .clear, radius: 12)
    }
}
