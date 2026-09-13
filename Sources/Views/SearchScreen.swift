import SwiftUI

struct SearchScreen: View {
    @Environment(PackageStore.self) private var store
    @Environment(UpgradePipeline.self) private var pipeline
    @Environment(\.theme) private var theme
    @State private var query = ""
    @State private var selected: SearchResult.ID?

    private var formulae: [SearchResult] { store.searchResults.filter { $0.kind == .formula } }
    private var casks: [SearchResult] { store.searchResults.filter { $0.kind == .cask } }
    private var selectedResult: SearchResult? { store.searchResults.first { $0.id == selected } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(L("search.placeholder"), text: $query)
                    .textFieldStyle(.plain)
                    .font(theme.bodyFont)
                    .onSubmit { Task { await store.search(query) } }
                if store.isSearching { ProgressView().controlSize(.small) }
                else if !store.lastQuery.isEmpty {
                    Text(L("search.count", store.searchResults.count)).font(theme.captionFont).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider()

            HSplitView {
                resultsList
                    .frame(minWidth: 260)
                detailPane
                    .frame(minWidth: 260)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var resultsList: some View {
        if store.searchResults.isEmpty {
            ContentUnavailableView(
                store.lastQuery.isEmpty ? L("search.prompt") : (store.isSearching ? L("search.searching") : L("installed.noResults")),
                systemImage: "magnifyingglass",
                description: Text(store.lastQuery.isEmpty ? L("search.hintEmpty") : L("search.hintNone", store.lastQuery))
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selected) {
                if !formulae.isEmpty {
                    Section("Formulae (\(formulae.count))") { ForEach(formulae) { SearchRow(result: $0) } }
                }
                if !casks.isEmpty {
                    Section("Casks (\(casks.count))") { ForEach(casks) { SearchRow(result: $0) } }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let r = selectedResult {
            let installed = store.installed.first { $0.id == r.id }
            let outdated = pipeline.outdated.first { $0.id == r.id }
            PackageDetailView(name: r.name, kind: r.kind, installedVersion: installed?.version, outdated: outdated)
        } else {
            ContentUnavailableView(L("installed.pick"), systemImage: "info.circle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
            .fill(theme.cardFill)
            .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).stroke(theme.cardStroke))
    }
}

struct SearchRow: View {
    let result: SearchResult
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Text(result.name).font(theme.bodyFont)
            Spacer()
            if result.isInstalled {
                Label(L("badge.installed"), systemImage: "checkmark.circle.fill")
                    .font(theme.captionFont).foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
        .tag(result.id)
    }
}
