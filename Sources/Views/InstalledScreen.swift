import SwiftUI

struct InstalledScreen: View {
    @Environment(PackageStore.self) private var store
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme
    @State private var filter = ""
    @State private var selection = Set<InstalledPackage.ID>()
    @State private var confirmingDelete = false

    private var filtered: [InstalledPackage] {
        let q = filter.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? store.installed : store.installed.filter { $0.name.lowercased().contains(q) }
    }
    private var formulae: [InstalledPackage] { filtered.filter { $0.kind == .formula } }
    private var casks: [InstalledPackage] { filtered.filter { $0.kind == .cask } }
    private var selectedPackages: [InstalledPackage] { store.installed.filter { selection.contains($0.id) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                TextField("이름으로 필터", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
                Text("formula \(store.formulae.count) · cask \(store.casks.count)")
                    .font(theme.captionFont)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Task { await store.refreshInstalled() }
                } label: {
                    if store.isLoadingInstalled { ProgressView().controlSize(.small) } else { Image(systemName: "arrow.clockwise") }
                }
                .buttonStyle(.borderless)
                .disabled(store.isLoadingInstalled)
                .help("목록 새로고침")
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("선택 삭제 (\(selection.count))", systemImage: "trash")
                }
                .disabled(selection.isEmpty || pipeline.isBusy)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider()

            if store.installed.isEmpty {
                ContentUnavailableView(
                    store.isLoadingInstalled ? "불러오는 중…" : "설치된 패키지가 없습니다",
                    systemImage: store.isLoadingInstalled ? "hourglass" : "shippingbox",
                    description: Text(store.lastError ?? "")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: filter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    if !formulae.isEmpty {
                        Section("Formulae (\(formulae.count))") {
                            ForEach(formulae) { InstalledRow(package: $0) }
                        }
                    }
                    if !casks.isEmpty {
                        Section("Casks (\(casks.count))") {
                            ForEach(casks) { InstalledRow(package: $0) }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
            .fill(theme.cardFill)
            .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).stroke(theme.cardStroke))
    }
}

struct InstalledRow: View {
    let package: InstalledPackage
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Image(systemName: package.kind == .cask ? "app.fill" : "shippingbox")
                .foregroundStyle(.secondary)
            Text(package.name).font(theme.bodyFont)
            Spacer()
            Text(package.version).font(theme.logFont).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .tag(package.id)
    }
}
