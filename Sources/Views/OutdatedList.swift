import SwiftUI

struct OutdatedList: View {
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme

    private var formulae: [OutdatedPackage] { pipeline.outdated.filter { $0.kind == .formula } }
    private var casks: [OutdatedPackage] { pipeline.outdated.filter { $0.kind == .cask } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("업데이트 가능")
                    .font(theme.bodyFont.weight(.semibold))
                if pipeline.outdatedCount > 0 {
                    Text("\(pipeline.outdatedCount)")
                        .font(theme.captionFont.weight(.bold))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(theme.accent.opacity(0.18)))
                        .foregroundStyle(theme.accent)
                }
                Spacer()
                Button {
                    Task { await pipeline.refreshOutdated() }
                } label: {
                    if pipeline.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(pipeline.isBusy || !pipeline.brewAvailable)
                .help("목록 새로고침")
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider()

            if pipeline.outdated.isEmpty {
                ContentUnavailableView(
                    pipeline.isRefreshing ? "확인 중…" : "모두 최신입니다",
                    systemImage: pipeline.isRefreshing ? "hourglass" : "checkmark.seal.fill",
                    description: Text(pipeline.brewAvailable ? "brew upgrade --greedy 기준으로 확인했습니다" : "Homebrew가 설치되어 있지 않습니다")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !formulae.isEmpty {
                        Section("Formulae") { ForEach(formulae) { PackageRow(package: $0) } }
                    }
                    if !casks.isEmpty {
                        Section("Casks") { ForEach(casks) { PackageRow(package: $0) } }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.cardFill)
                .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).stroke(theme.cardStroke))
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
    }
}

struct PackageRow: View {
    let package: OutdatedPackage
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Image(systemName: package.kind == .cask ? "app.fill" : "shippingbox")
                .foregroundStyle(.secondary)
            Text(package.name).font(theme.bodyFont)
            Spacer()
            HStack(spacing: 6) {
                Text(package.installedVersion).foregroundStyle(.secondary)
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                Text(package.currentVersion).foregroundStyle(theme.accent)
            }
            .font(theme.logFont)
        }
        .padding(.vertical, 2)
    }
}
