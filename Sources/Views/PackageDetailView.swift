import SwiftUI

/// 설치 목록과 검색 화면이 공유하는 상세 패널.
struct PackageDetailView: View {
    let name: String
    let kind: PackageKind
    let installedVersion: String?          // nil이면 미설치
    let outdated: OutdatedPackage?         // 업데이트 가능하면 값 있음

    @Environment(PackageStore.self) private var store
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(AppIconResolver.self) private var icons
    @Environment(\.theme) private var theme
    @State private var confirmingDelete = false

    private var info: PackageInfo? { store.selectedInfo?.name == name ? store.selectedInfo : nil }
    private var isInstalled: Bool { installedVersion != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                PackageIcon(name: name, kind: kind, appNames: info?.appNames ?? [], size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(theme.titleFont)
                    HStack(spacing: 8) {
                        Text(kind == .cask ? "Cask" : "Formula")
                            .font(theme.captionFont).foregroundStyle(.secondary)
                        if isInstalled {
                            Label("설치됨", systemImage: "checkmark.circle.fill")
                                .font(theme.captionFont).foregroundStyle(.green)
                        }
                        if outdated != nil {
                            Label("업데이트 있음", systemImage: "arrow.up.circle.fill")
                                .font(theme.captionFont).foregroundStyle(theme.accent)
                        }
                    }
                }
                Spacer()
            }

            if store.isLoadingInfo && info == nil {
                ProgressView().controlSize(.small)
            } else if let info {
                Text(info.description.isEmpty ? "설명 없음" : info.description)
                    .font(theme.bodyFont)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                if let installedVersion {
                    GridRow {
                        Text("설치 버전").foregroundStyle(.secondary)
                        Text(installedVersion).font(theme.logFont)
                    }
                }
                if let outdated {
                    GridRow {
                        Text("새 버전").foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Text(outdated.installedVersion).font(theme.logFont).foregroundStyle(.secondary)
                            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                            Text(outdated.currentVersion).font(theme.logFont).foregroundStyle(theme.accent).bold()
                        }
                    }
                } else if let info, !isInstalled {
                    GridRow {
                        Text("최신 버전").foregroundStyle(.secondary)
                        Text(info.version).font(theme.logFont)
                    }
                }
                if let info, let url = URL(string: info.homepage), !info.homepage.isEmpty {
                    GridRow {
                        Text("홈페이지").foregroundStyle(.secondary)
                        Link(info.homepage, destination: url).lineLimit(1)
                    }
                }
            }
            .font(theme.bodyFont)

            if outdated != nil {
                Text("변경 내역은 brew가 제공하지 않습니다. 홈페이지의 릴리스 노트를 확인하세요.")
                    .font(theme.captionFont).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                if !isInstalled {
                    Button {
                        Task { await pipeline.install(name: name, kind: kind) }
                    } label: {
                        Label("설치", systemImage: "arrow.down.circle.fill")
                            .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent).tint(theme.accent).controlSize(.large)
                    .disabled(pipeline.isBusy)
                }
                if let installedVersion, outdated != nil {
                    Button {
                        Task { await pipeline.upgrade([InstalledPackage(name: name, version: installedVersion, kind: kind)]) }
                    } label: {
                        Label("업그레이드", systemImage: "arrow.up.circle.fill")
                            .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent).tint(theme.accent).controlSize(.large)
                    .disabled(pipeline.isBusy)
                }
                if let installedVersion {
                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                            .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                    .controlSize(.large)
                    .disabled(pipeline.isBusy)
                    .confirmationDialog("\(name)을(를) 삭제할까요?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                        Button("삭제", role: .destructive) {
                            Task { await pipeline.uninstall([InstalledPackage(name: name, version: installedVersion, kind: kind)]) }
                        }
                        Button("취소", role: .cancel) {}
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: "\(kind.rawValue):\(name)") {
            await store.loadInfo(name: name, kind: kind)
        }
    }
}

/// cask는 실제 앱 아이콘, formula는 심볼.
struct PackageIcon: View {
    let name: String
    let kind: PackageKind
    var appNames: [String] = []
    var size: CGFloat = 20

    @Environment(AppIconResolver.self) private var icons
    @Environment(\.theme) private var theme

    var body: some View {
        if kind == .cask, let image = icons.icon(forCask: name, appNames: appNames) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(theme.accent.opacity(0.14))
                Image(systemName: kind == .cask ? "app.fill" : "shippingbox.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: size, height: size)
        }
    }
}
