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
        if !pipeline.brewAvailable { return "Homebrew를 찾을 수 없습니다. https://brew.sh 에서 설치하세요." }
        if let step = pipeline.currentStep { return "실행 중 · \(step.command)" }
        if let err = pipeline.lastError { return err }
        if pipeline.isRefreshing { return "업데이트 확인 중…" }
        if pipeline.allSucceeded && pipeline.lastRun != nil { return "모든 단계를 완료했습니다" }
        return pipeline.outdatedCount == 0 ? "모두 최신입니다" : "업데이트 가능한 패키지 \(pipeline.outdatedCount)개"
    }

    private var statusColor: Color {
        if pipeline.lastError != nil || !pipeline.brewAvailable { return .red }
        if pipeline.isRunning { return theme.accent }
        return .primary
    }

    private var lastRunText: String {
        guard let d = pipeline.lastRun else { return "아직 실행한 적 없음" }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateTimeStyle = .named
        return "마지막 실행 \(f.localizedString(for: d, relativeTo: Date()))"
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
            Label(pipeline.isRunning ? "중단" : "전체 실행",
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
