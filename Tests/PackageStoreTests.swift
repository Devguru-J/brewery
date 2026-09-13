import XCTest
@testable import brewery

@MainActor
final class PackageStoreTests: XCTestCase {
    let brew = URL(fileURLWithPath: "/opt/homebrew/bin/brew")

    func makeCaskroom() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("caskroom-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("iterm2/3.5.1"), withIntermediateDirectories: true)
        return root
    }

    func testRefreshInstalled() async throws {
        let runner = FakeRunner()
        runner.stdout[["list", "--formula", "--versions"]] = ["git 2.50.0"]
        runner.stdout[["list", "--cask"]] = ["iterm2"]
        let store = PackageStore(runner: runner, brewURL: brew, caskroom: try makeCaskroom())
        await store.refreshInstalled()
        XCTAssertEqual(store.installed, [
            InstalledPackage(name: "git", version: "2.50.0", kind: .formula),
            InstalledPackage(name: "iterm2", version: "3.5.1", kind: .cask),
        ])
        XCTAssertNil(store.lastError)
    }

    func testSearchMarksInstalled() async throws {
        let runner = FakeRunner()
        runner.stdout[["list", "--formula", "--versions"]] = ["ripgrep 15.2.0"]
        runner.stdout[["list", "--cask"]] = []
        runner.stdout[["search", "--formula", "rip"]] = ["ripgrep", "ripgrep-all"]
        runner.stdout[["search", "--cask", "rip"]] = ["ripcord"]
        let store = PackageStore(runner: runner, brewURL: brew, caskroom: try makeCaskroom())
        await store.refreshInstalled()
        await store.search("  rip ")
        XCTAssertEqual(store.lastQuery, "rip")
        XCTAssertEqual(store.searchResults, [
            SearchResult(name: "ripgrep", kind: .formula, isInstalled: true),
            SearchResult(name: "ripgrep-all", kind: .formula, isInstalled: false),
            SearchResult(name: "ripcord", kind: .cask, isInstalled: false),
        ])
    }

    func testSearchNoResultsExitCode1IsNotError() async throws {
        let runner = FakeRunner()
        runner.exitCodes[["search", "--formula", "zzz"]] = 1
        runner.exitCodes[["search", "--cask", "zzz"]] = 1
        let store = PackageStore(runner: runner, brewURL: brew, caskroom: try makeCaskroom())
        await store.search("zzz")
        XCTAssertEqual(store.searchResults, [])
        XCTAssertNil(store.lastError)
    }

    func testLoadInfoCask() async throws {
        let runner = FakeRunner()
        runner.stdout[["info", "--json=v2", "--cask", "iterm2"]] = [#"{"formulae":[],"casks":[{"token":"iterm2","desc":"T","homepage":"h","version":"1","installed":null}]}"#]
        let store = PackageStore(runner: runner, brewURL: brew, caskroom: try makeCaskroom())
        await store.loadInfo(name: "iterm2", kind: .cask)
        XCTAssertEqual(store.selectedInfo?.name, "iterm2")
        XCTAssertEqual(runner.calls, [["info", "--json=v2", "--cask", "iterm2"]])
    }

    func testListFailureSetsError() async throws {
        let runner = FakeRunner()
        runner.exitCodes[["list", "--formula", "--versions"]] = 1
        let store = PackageStore(runner: runner, brewURL: brew, caskroom: try makeCaskroom())
        await store.refreshInstalled()
        XCTAssertNotNil(store.lastError)
        XCTAssertEqual(store.installed, [])
    }
}
