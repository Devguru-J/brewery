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
                TextField("brew search — 이름을 입력하고 Enter", text: $query)
                    .textFieldStyle(.plain)
                    .font(theme.bodyFont)
                    .onSubmit { Task { await store.search(query) } }
                if store.isSearching { ProgressView().controlSize(.small) }
                else if !store.lastQuery.isEmpty {
                    Text("\(store.searchResults.count)개").font(theme.captionFont).foregroundStyle(.secondary)
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
        .onChange(of: selected) { _, id in
            guard let r = store.searchResults.first(where: { $0.id == id }) else { store.clearInfo(); return }
            Task { await store.loadInfo(name: r.name, kind: r.kind) }
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        if store.searchResults.isEmpty {
            ContentUnavailableView(
                store.lastQuery.isEmpty ? "검색어를 입력하세요" : (store.isSearching ? "검색 중…" : "결과 없음"),
                systemImage: "magnifyingglass",
                description: Text(store.lastQuery.isEmpty ? "formula와 cask를 함께 찾습니다" : "“\(store.lastQuery)”에 해당하는 패키지가 없습니다")
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: r.kind == .cask ? "app.fill" : "shippingbox")
                        .font(.title2).foregroundStyle(theme.accent)
                    Text(r.name).font(theme.titleFont)
                    Spacer()
                }
                if store.isLoadingInfo {
                    ProgressView().controlSize(.small)
                } else if let info = store.selectedInfo {
                    Text(info.description.isEmpty ? "설명 없음" : info.description)
                        .font(theme.bodyFont)
                    LabeledContent("종류") { Text(r.kind == .cask ? "Cask" : "Formula") }
                    LabeledContent("버전") { Text(info.version).font(theme.logFont) }
                    if let url = URL(string: info.homepage), !info.homepage.isEmpty {
                        LabeledContent("홈페이지") { Link(info.homepage, destination: url) }
                    }
                }
                Spacer()
                let installed = store.installed.contains { $0.id == r.id }
                Button {
                    Task { await pipeline.install(name: r.name, kind: r.kind) }
                } label: {
                    Label(installed ? "이미 설치됨" : "설치", systemImage: installed ? "checkmark.circle" : "arrow.down.circle.fill")
                        .padding(.horizontal, 12).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .controlSize(.large)
                .disabled(installed || pipeline.isBusy || store.isLoadingInfo)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            ContentUnavailableView("패키지를 선택하세요", systemImage: "info.circle")
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
                Label("설치됨", systemImage: "checkmark.circle.fill")
                    .font(theme.captionFont).foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
        .tag(result.id)
    }
}
