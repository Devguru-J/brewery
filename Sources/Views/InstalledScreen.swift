import SwiftUI

struct InstalledScreen: View {
    @Environment(PackageStore.self) private var store
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme
    @State private var filter = ""
    @State private var onlyOutdated = false
    @State private var kindTab: PackageKind = .formula
    @State private var selection = Set<InstalledPackage.ID>()
    @State private var confirmingDelete = false

    private var outdatedByID: [String: OutdatedPackage] {
        Dictionary(pipeline.outdated.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }
    private var filtered: [InstalledPackage] {
        let q = filter.trimmingCharacters(in: .whitespaces).lowercased()
        let outdated = outdatedByID
        return store.installed.filter {
            $0.kind == kindTab
                && (q.isEmpty || $0.name.lowercased().contains(q))
                && (!onlyOutdated || outdated[$0.id] != nil)
        }
    }
    private func outdatedCount(_ kind: PackageKind) -> Int {
        let o = outdatedByID
        return store.installed.filter { $0.kind == kind && o[$0.id] != nil }.count
    }
    private var selectedPackages: [InstalledPackage] { store.installed.filter { selection.contains($0.id) } }
    private var selectedOutdated: [InstalledPackage] { selectedPackages.filter { outdatedByID[$0.id] != nil } }
    private var focused: InstalledPackage? { selection.count == 1 ? selectedPackages.first : nil }
    private var outdatedInstalledCount: Int { store.installed.filter { outdatedByID[$0.id] != nil }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                list.frame(minWidth: 320)
                detail.frame(minWidth: 300)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        .task { if store.installed.isEmpty { await store.refreshInstalled() } }
        .confirmationDialog("선택한 \(selection.count)개를 삭제할까요?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                let items = selectedPackages
                selection.removeAll()
                Task { await pipeline.uninstall(items) }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text(selectedPackages.map(\.name).joined(separator: ", "))
        }
    }

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Picker("종류", selection: $kindTab) {
                    Text("Formulae \(store.formulae.count)").tag(PackageKind.formula)
                    Text("Casks \(store.casks.count)").tag(PackageKind.cask)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 240)
                Toggle(isOn: $onlyOutdated) {
                    Text("업데이트만")
                    if outdatedInstalledCount > 0 {
                        Text("\(outdatedInstalledCount)")
                            .font(theme.captionFont.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(theme.accent.opacity(0.18)))
                            .foregroundStyle(theme.accent)
                    }
                }
                .toggleStyle(.button)
                Spacer()
                Button {
                    Task {
                        await store.refreshInstalled()
                        await pipeline.refreshOutdated()
                    }
                } label: {
                    if store.isLoadingInstalled || pipeline.isRefreshing { ProgressView().controlSize(.small) } else { Image(systemName: "arrow.clockwise") }
                }
                .buttonStyle(.borderless)
                .disabled(store.isLoadingInstalled || pipeline.isBusy)
                .help("목록 새로고침")
            }
            HStack(spacing: 12) {
                TextField("이름으로 필터", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Spacer()
                Button {
                    let items = selectedOutdated
                    Task { await pipeline.upgrade(items) }
                } label: {
                    Label("선택 업그레이드 (\(selectedOutdated.count))", systemImage: "arrow.up.circle")
                        .fixedSize()
                }
                .buttonStyle(.borderedProminent).tint(theme.accent)
                .disabled(selectedOutdated.isEmpty || pipeline.isBusy)
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("선택 삭제 (\(selection.count))", systemImage: "trash")
                        .fixedSize()
                }
                .disabled(selection.isEmpty || pipeline.isBusy)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    @ViewBuilder
    private var list: some View {
        if store.installed.isEmpty {
            ContentUnavailableView(
                store.isLoadingInstalled ? "불러오는 중…" : "설치된 패키지가 없습니다",
                systemImage: store.isLoadingInstalled ? "hourglass" : "shippingbox",
                description: Text(store.lastError ?? "")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            ContentUnavailableView(onlyOutdated && filter.isEmpty ? "모두 최신입니다" : "결과 없음",
                                   systemImage: onlyOutdated ? "checkmark.seal.fill" : "magnifyingglass")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selection) {
                Section {
                    ForEach(filtered) { InstalledRow(package: $0, outdated: outdatedByID[$0.id]) }
                } header: {
                    HStack {
                        Text(kindTab == .cask ? "Casks" : "Formulae")
                        Text("\(filtered.count)개").foregroundStyle(.secondary)
                        if outdatedCount(kindTab) > 0 {
                            Text("업데이트 \(outdatedCount(kindTab))")
                                .font(theme.captionFont.weight(.semibold))
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(Capsule().fill(theme.accent.opacity(0.18)))
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let p = focused {
            PackageDetailView(name: p.name, kind: p.kind, installedVersion: p.version, outdated: outdatedByID[p.id])
        } else if selection.count > 1 {
            ContentUnavailableView("\(selection.count)개 선택됨", systemImage: "checklist",
                                   description: Text("위 버튼으로 선택한 항목을 업그레이드하거나 삭제합니다"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView("패키지를 선택하세요", systemImage: "info.circle",
                                   description: Text("설명, 버전, 업데이트 여부를 보여줍니다"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
            .fill(theme.cardFill)
            .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).stroke(theme.cardStroke))
    }
}

struct InstalledRow: View {
    let package: InstalledPackage
    let outdated: OutdatedPackage?
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            PackageIcon(name: package.name, kind: package.kind, size: 22)
            Text(package.name).font(theme.bodyFont).lineLimit(1)
            if let outdated {
                Text("업데이트")
                    .font(theme.captionFont.weight(.semibold))
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(Capsule().fill(theme.accent.opacity(0.18)))
                    .foregroundStyle(theme.accent)
                Spacer()
                HStack(spacing: 5) {
                    Text(package.version).foregroundStyle(.secondary)
                    Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                    Text(outdated.currentVersion).foregroundStyle(theme.accent)
                }
                .font(theme.logFont)
            } else {
                Spacer()
                Text(package.version).font(theme.logFont).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
                    .frame(maxWidth: 200, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
        .tag(package.id)
    }
}
