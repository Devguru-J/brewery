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
        .confirmationDialog(L("installed.confirmDelete", selection.count), isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button(L("btn.delete"), role: .destructive) {
                let items = selectedPackages
                selection.removeAll()
                Task { await pipeline.uninstall(items) }
            }
            Button(L("btn.cancel"), role: .cancel) {}
        } message: {
            Text(selectedPackages.map(\.name).joined(separator: ", "))
        }
    }

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Picker("kind", selection: $kindTab) {
                    Text("Formulae \(store.formulae.count)").tag(PackageKind.formula)
                    Text("Casks \(store.casks.count)").tag(PackageKind.cask)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 240)
                Toggle(isOn: $onlyOutdated) {
                    Text(L("installed.onlyOutdated"))
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
                .help(L("outdated.refresh"))
            }
            HStack(spacing: 12) {
                TextField(L("installed.filter"), text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Spacer()
                Button {
                    let items = selectedOutdated
                    Task { await pipeline.upgrade(items) }
                } label: {
                    Label(L("installed.upgradeSelected", selectedOutdated.count), systemImage: "arrow.up.circle")
                        .fixedSize()
                }
                .buttonStyle(.borderedProminent).tint(theme.accent)
                .disabled(selectedOutdated.isEmpty || pipeline.isBusy)
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label(L("installed.deleteSelected", selection.count), systemImage: "trash")
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
                store.isLoadingInstalled ? L("installed.loading") : L("installed.empty"),
                systemImage: store.isLoadingInstalled ? "hourglass" : "shippingbox",
                description: Text(store.lastError ?? "")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            ContentUnavailableView(onlyOutdated && filter.isEmpty ? L("hero.upToDate") : L("installed.noResults"),
                                   systemImage: onlyOutdated ? "checkmark.seal.fill" : "magnifyingglass")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selection) {
                Section {
                    ForEach(filtered) { InstalledRow(package: $0, outdated: outdatedByID[$0.id]) }
                } header: {
                    HStack {
                        Text(kindTab == .cask ? "Casks" : "Formulae")
                        Text(L("installed.count", filtered.count)).foregroundStyle(.secondary)
                        if outdatedCount(kindTab) > 0 {
                            Text(L("installed.updatesBadge", outdatedCount(kindTab)))
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
            ContentUnavailableView(L("installed.selected", selection.count), systemImage: "checklist",
                                   description: Text(L("installed.selectedHint")))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(L("installed.pick"), systemImage: "info.circle",
                                   description: Text(L("installed.pickHint")))
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
                Text(L("badge.update"))
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
