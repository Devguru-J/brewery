import XCTest
@testable import brewery

@MainActor
final class PackageActionsTests: XCTestCase {
    let brew = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
    let outdatedArgs = ["outdated", "--json=v2", "--greedy"]

    func make(_ runner: FakeRunner) -> UpgradePipeline {
        runner.stdout[outdatedArgs] = [#"{"formulae":[],"casks":[]}"#]
        let d = UserDefaults(suiteName: "brewery.actions.tests")!
        d.removePersistentDomain(forName: "brewery.actions.tests")
        return UpgradePipeline(runner: runner, brewURL: brew, defaults: d)
    }

    func testInstallFormulaAndCask() async {
        let runner = FakeRunner()
        let p = make(runner)
        var changed = 0
        p.onPackagesChanged = { changed += 1 }
        await p.install(name: "ripgrep", kind: .formula)
        await p.install(name: "iterm2", kind: .cask)
        XCTAssertEqual(runner.calls, [["install", "ripgrep"], outdatedArgs, ["install", "--cask", "iterm2"], outdatedArgs])
        XCTAssertEqual(changed, 2)
        XCTAssertFalse(p.isRunning)
        XCTAssertNil(p.lastError)
        XCTAssertTrue(p.log.map(\.text).contains("$ brew install --cask iterm2"))
    }

    func testUninstallGroupsByKindAndStopsOnFailure() async {
        let runner = FakeRunner()
        runner.exitCodes[["uninstall", "a", "b"]] = 1
        let p = make(runner)
        await p.uninstall([
            InstalledPackage(name: "a", version: "1", kind: .formula),
            InstalledPackage(name: "c", version: "1", kind: .cask),
            InstalledPackage(name: "b", version: "1", kind: .formula),
        ])
        XCTAssertEqual(runner.calls, [["uninstall", "a", "b"], outdatedArgs])
        XCTAssertTrue(p.lastError?.contains("1") == true, p.lastError ?? "nil")
    }

    func testUninstallSucceedsRunsBoth() async {
        let runner = FakeRunner()
        let p = make(runner)
        await p.uninstall([
            InstalledPackage(name: "a", version: "1", kind: .formula),
            InstalledPackage(name: "c", version: "1", kind: .cask),
        ])
        XCTAssertEqual(runner.calls, [["uninstall", "a"], ["uninstall", "--cask", "c"], outdatedArgs])
    }

    func testDoesNothingWhileBusy() async {
        let runner = FakeRunner()
        let p = make(runner)
        p.beginAction()
        await p.install(name: "x", kind: .formula)
        XCTAssertTrue(runner.calls.isEmpty)
        p.endAction()
    }

    func testStepStatesUntouched() async {
        let runner = FakeRunner()
        let p = make(runner)
        await p.runAll()
        await p.install(name: "x", kind: .formula)
        XCTAssertTrue(p.allSucceeded)
    }
}

@MainActor
final class PackageUpgradeTests: XCTestCase {
    func testUpgradeSelectedGroupsByKind() async {
        let runner = FakeRunner()
        let outdatedArgs = ["outdated", "--json=v2", "--greedy"]
        runner.stdout[outdatedArgs] = [#"{"formulae":[],"casks":[]}"#]
        let d = UserDefaults(suiteName: "brewery.upgrade.tests")!
        d.removePersistentDomain(forName: "brewery.upgrade.tests")
        let p = UpgradePipeline(runner: runner, brewURL: URL(fileURLWithPath: "/opt/homebrew/bin/brew"), defaults: d)
        await p.upgrade([
            InstalledPackage(name: "git", version: "1", kind: .formula),
            InstalledPackage(name: "ghostty", version: "1", kind: .cask),
            InstalledPackage(name: "bat", version: "1", kind: .formula),
        ])
        XCTAssertEqual(runner.calls, [["upgrade", "git", "bat"], ["upgrade", "--cask", "ghostty"], outdatedArgs])
        XCTAssertNil(p.lastError)
    }
}
