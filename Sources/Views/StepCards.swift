import SwiftUI

struct StepCards: View {
    @Environment(UpgradePipeline.self) private var pipeline

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(pipeline.steps.enumerated()), id: \.element.id) { index, step in
                StepCard(index: index + 1, step: step)
            }
        }
    }
}

struct StepCard: View {
    let index: Int
    let step: Step
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme

    private var state: StepState { pipeline.state(of: step) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: step.symbol)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .symbolEffect(.pulse, isActive: state == .running)
                Spacer()
                StepStatusBadge(state: state)
            }
            Text("\(index). \(step.title)")
                .font(theme.bodyFont.weight(.semibold))
            Text(step.command)
                .font(theme.logFont)
                .foregroundStyle(.secondary)
            Text(L(step.summary))
                .font(theme.captionFont)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
            Spacer(minLength: 0)
            Button(L("btn.runStep")) {
                Task { await pipeline.run(step) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(pipeline.isBusy || !pipeline.brewAvailable)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: state == .running ? 2 : 1)
                )
        )
        .shadow(color: theme.glow && state == .running ? theme.accent.opacity(0.5) : .clear, radius: 10)
        .animation(.easeInOut(duration: 0.25), value: state)
    }

    private var iconColor: Color {
        switch state {
        case .succeeded: return .green
        case .failed: return .red
        case .running: return theme.accent
        default: return .secondary
        }
    }

    private var borderColor: Color {
        switch state {
        case .running: return theme.accent
        case .failed: return .red.opacity(0.6)
        default: return theme.cardStroke
        }
    }
}

struct StepStatusBadge: View {
    let state: StepState
    @Environment(\.theme) private var theme

    var body: some View {
        switch state {
        case .idle:
            Text(L("state.idle")).font(theme.captionFont).foregroundStyle(.secondary)
        case .running:
            ProgressIndicator()
        case .succeeded:
            Label(L("state.done"), systemImage: "checkmark.circle.fill")
                .font(theme.captionFont).foregroundStyle(.green)
        case .skipped:
            Label(L("state.skipped"), systemImage: "minus.circle")
                .font(theme.captionFont).foregroundStyle(.secondary)
        case .failed(let code):
            Label(L("state.failed", code), systemImage: "xmark.octagon.fill")
                .font(theme.captionFont).foregroundStyle(.red)
        }
    }
}

/// 테마별 진행 표시: 순정=링, 터미널=깜빡이는 커서, 맥주집=거품.
struct ProgressIndicator: View {
    @Environment(\.theme) private var theme

    var body: some View {
        switch theme.progress {
        case .ring:
            ProgressView().controlSize(.small)
        case .cursor:
            TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                let on = Int(ctx.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                Text("▮")
                    .font(theme.logFont)
                    .foregroundStyle(theme.accent.opacity(on ? 1 : 0.15))
            }
        case .foam:
            FoamView()
        }
    }
}

struct FoamView: View {
    @Environment(\.theme) private var theme
    @State private var rise = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(theme.accent.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .offset(y: rise ? -6 : 2)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: rise)
            }
        }
        .frame(width: 30, height: 16)
        .onAppear { rise = true }
    }
}
