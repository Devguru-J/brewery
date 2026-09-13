import SwiftUI

struct LogConsole: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        Text("로그")
                        Text("\(pipeline.log.count)줄").foregroundStyle(.secondary)
                    }
                    .font(theme.bodyFont.weight(.semibold))
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    let text = pipeline.log.map(\.text).joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: { Image(systemName: "doc.on.doc") }
                .buttonStyle(.borderless).help("로그 복사")
                Button { pipeline.clearLog() } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless).help("로그 지우기")
                    .disabled(pipeline.isRunning)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            if isExpanded {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(pipeline.log) { line in
                                Text(line.text)
                                    .font(theme.logFont)
                                    .foregroundStyle(color(for: line.stream))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(line.id)
                            }
                        }
                        .padding(12)
                        .textSelection(.enabled)
                    }
                    .background(theme.logBackground)
                    .onChange(of: pipeline.log.count) {
                        if let last = pipeline.log.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .frame(minHeight: 160)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.cardFill)
                .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).stroke(theme.cardStroke))
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
    }

    private func color(for stream: LogStream) -> Color {
        switch stream {
        case .stdout: return theme.logStdout
        case .stderr: return theme.logStderr
        case .system: return theme.logSystem
        }
    }
}
