import SwiftUI

struct MenuBarPanel: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mug.fill").foregroundStyle(theme.accent)
                Text("brewery").font(theme.bodyFont.weight(.semibold))
                Spacer()
                if pipeline.isBusy { ProgressView().controlSize(.small) }
            }
            Text(statusText)
                .font(theme.captionFont)
                .foregroundStyle(.secondary)

            ForEach(pipeline.steps) { step in
                HStack(spacing: 8) {
                    StepStatusBadge(state: pipeline.state(of: step))
                        .frame(width: 70, alignment: .leading)
                    Text(step.command).font(theme.logFont)
                }
            }

            Divider()

            HStack {
                Button {
                    if pipeline.isRunning { pipeline.cancel() } else { Task { await pipeline.runAll() } }
                } label: {
                    Label(pipeline.isRunning ? "중단" : "전체 실행",
                          systemImage: pipeline.isRunning ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(pipeline.isRunning ? .red : theme.accent)
                .disabled(!pipeline.brewAvailable || pipeline.isRefreshing)

                Button("창 열기") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("종료") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    private var statusText: String {
        if !pipeline.brewAvailable { return "Homebrew를 찾을 수 없습니다" }
        if let step = pipeline.currentStep { return "실행 중 · \(step.command)" }
        if let err = pipeline.lastError { return err }
        return pipeline.outdatedCount == 0 ? "모두 최신입니다" : "업데이트 가능 \(pipeline.outdatedCount)개"
    }
}
