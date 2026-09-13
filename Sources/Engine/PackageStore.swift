import Foundation
import Observation

/// 설치 목록·검색·정보 조회. 읽기 전용이라 업그레이드와 동시에 돌아도 된다.
@MainActor
@Observable
final class PackageStore {
    private(set) var installed: [InstalledPackage] = []
    private(set) var isLoadingInstalled = false
    private(set) var searchResults: [SearchResult] = []
    private(set) var isSearching = false
    private(set) var lastQuery = ""
    private(set) var selectedInfo: PackageInfo?
    private(set) var isLoadingInfo = false
    private(set) var lastError: String?

    var formulae: [InstalledPackage] { installed.filter { $0.kind == .formula } }
    var casks: [InstalledPackage] { installed.filter { $0.kind == .cask } }

    private let runner: CommandRunning
    private let brewURL: URL?
    private let caskroom: URL
    private let fileManager: FileManager

    init(runner: CommandRunning, brewURL: URL?, caskroom: URL? = nil, fileManager: FileManager = .default) {
        self.runner = runner
        self.brewURL = brewURL
        self.fileManager = fileManager
        // /opt/homebrew/bin/brew → /opt/homebrew/Caskroom
        self.caskroom = caskroom
            ?? brewURL?.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Caskroom")
            ?? URL(fileURLWithPath: "/opt/homebrew/Caskroom")
    }

    func refreshInstalled() async {
        guard !isLoadingInstalled else { return }
        isLoadingInstalled = true
        defer { isLoadingInstalled = false }
        do {
            let formulaText = try await capture(["list", "--formula", "--versions"])
            let caskText = try await capture(["list", "--cask"])
            let formulae = BrewListParser.parseFormulaVersions(formulaText)
            let casks = BrewListParser.caskVersions(names: BrewListParser.parseCaskNames(caskText),
                                                    caskroom: caskroom, fileManager: fileManager)
            installed = formulae + casks
            let ids = Set(installed.map(\.id))
            searchResults = searchResults.map { SearchResult(name: $0.name, kind: $0.kind, isInstalled: ids.contains($0.id)) }
            lastError = nil
        } catch {
            lastError = "설치 목록을 읽지 못했습니다: \(error.localizedDescription)"
        }
    }

    func search(_ query: String) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !isSearching else { return }
        isSearching = true
        lastQuery = q
        defer { isSearching = false }
        do {
            let f = BrewSearchParser.parse(try await capture(["search", "--formula", q]))
            let c = BrewSearchParser.parse(try await capture(["search", "--cask", q]))
            let installedIDs = Set(installed.map(\.id))
            searchResults = f.map { SearchResult(name: $0, kind: .formula, isInstalled: installedIDs.contains("formula:\($0)")) }
                + c.map { SearchResult(name: $0, kind: .cask, isInstalled: installedIDs.contains("cask:\($0)")) }
            lastError = nil
        } catch {
            lastError = "검색 실패: \(error.localizedDescription)"
        }
    }

    func loadInfo(name: String, kind: PackageKind) async {
        isLoadingInfo = true
        selectedInfo = nil
        defer { isLoadingInfo = false }
        var args = ["info", "--json=v2"]
        if kind == .cask { args.append("--cask") }
        args.append(name)
        do {
            let text = try await capture(args)
            selectedInfo = try BrewInfoParser.parse(Data(text.utf8), kind: kind)
        } catch {
            lastError = "정보를 읽지 못했습니다: \(error.localizedDescription)"
        }
    }

    func clearInfo() { selectedInfo = nil }

    // MARK: - Private

    struct CommandFailed: LocalizedError {
        let arguments: [String]
        let code: Int32
        var errorDescription: String? { "brew \(arguments.joined(separator: " ")) (종료 코드 \(code))" }
    }

    private func capture(_ arguments: [String]) async throws -> String {
        guard let brewURL else { throw CommandFailed(arguments: arguments, code: -1) }
        let buffer = LineBuffer()
        let code = try await runner.run(executable: brewURL, arguments: arguments,
                                        environment: UpgradePipeline.environment(for: brewURL)) { line, stream in
            if stream == .stdout { buffer.append(line) }
        }
        // brew search는 결과가 없으면 1을 돌려준다. 그 경우 빈 결과로 처리.
        guard code == 0 || arguments.first == "search" else { throw CommandFailed(arguments: arguments, code: code) }
        return buffer.joined()
    }
}
