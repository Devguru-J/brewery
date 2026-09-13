import XCTest
@testable import brewery

@MainActor
final class UpgradePipelineTests: XCTestCase {
    let brew = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
    let outdatedArgs = ["outdated", "--json=v2", "--greedy"]
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "brewery.tests")
        defaults.removePersistentDomain(forName: "brewery.tests")
    }

    func make(_ runner: FakeRunner) -> UpgradePipeline {
        runner.stdout[outdatedArgs] = [#"{"formulae":[],"casks":[]}"#]
        return UpgradePipeline(runner: runner, brewURL: brew, defaults: defaults)
    }

    func testRunAllRunsStepsInOrderThenRefreshes() async {
        let runner = FakeRunner()
        let p = make(runner)
        await p.runAll()
        XCTAssertEqual(runner.calls, [["update"], ["upgrade"], ["upgrade", "--greedy"], outdatedArgs])
        for s in p.steps { XCTAssertEqual(p.state(of: s), .succeeded) }
        XCTAssertTrue(p.allSucceeded)
        XCTAssertNotNil(p.lastRun)
        XCTAssertNotNil(defaults.object(forKey: "lastRun"))
        XCTAssertFalse(p.isRunning)
    }

    func testFailureStopsPipelineAndSkipsRest() async {
        let runner = FakeRunner()
        runner.exitCodes[["upgrade"]] = 1
        let p = make(runner)
        await p.runAll()
        XCTAssertEqual(p.state(of: .update), .succeeded)
        XCTAssertEqual(p.state(of: .upgrade), .failed(exitCode: 1))
        XCTAssertEqual(p.state(of: .upgradeGreedy), .skipped)
        XCTAssertEqual(runner.calls, [["update"], ["upgrade"], outdatedArgs])
        XCTAssertEqual(p.lastError, "Upgrade 실패 (종료 코드 1)")
    }

    func testRunSingleStep() async {
        let runner = FakeRunner()
        let p = make(runner)
        await p.run(.upgradeGreedy)
        XCTAssertEqual(runner.calls, [["upgrade", "--greedy"], outdatedArgs])
        XCTAssertEqual(p.state(of: .upgradeGreedy), .succeeded)
        XCTAssertEqual(p.state(of: .update), .idle)
    }

    func testLogCapturesOutputWithStepAndSudoHint() async {
        let runner = FakeRunner()
        runner.stdout[["update"]] = ["Already up-to-date."]
        runner.stderr[["upgrade"]] = ["sudo: a terminal is required to read the password"]
        let p = make(runner)
        await p.runAll()
        let texts = p.log.map(\.text)
        XCTAssertTrue(texts.contains("$ brew update"))
        XCTAssertTrue(texts.contains("Already up-to-date."))
        XCTAssertTrue(texts.contains { $0.contains("관리자 비밀번호") })
        XCTAssertEqual(p.log.first { $0.text == "Already up-to-date." }?.stepID, "update")
    }

    func testRefreshOutdatedParsesList() async {
        let runner = FakeRunner()
        runner.stdout[outdatedArgs] = [#"{"formulae":[{"name":"git","installed_versions":["1"],"current_version":"2"}],"casks":[]}"#]
        let p = UpgradePipeline(runner: runner, brewURL: brew, defaults: defaults)
        await p.refreshOutdated()
        XCTAssertEqual(p.outdatedCount, 1)
        XCTAssertEqual(p.outdated.first?.name, "git")
    }

    func testNoBrewDoesNothing() async {
        let runner = FakeRunner()
        let p = UpgradePipeline(runner: runner, brewURL: nil, defaults: defaults)
        await p.runAll()
        await p.refreshOutdated()
        XCTAssertTrue(runner.calls.isEmpty)
        XCTAssertFalse(p.brewAvailable)
    }

    func testCancelForwardsToRunner() {
        let runner = FakeRunner()
        let p = make(runner)
        p.cancel()
        XCTAssertTrue(runner.terminated)
    }

    func testEnvironmentContainsBrewBinInPath() {
        let env = UpgradePipeline.environment(for: brew)
        XCTAssertTrue(env["PATH"]!.hasPrefix("/opt/homebrew/bin:"))
        XCTAssertEqual(env["NONINTERACTIVE"], "1")
        XCTAssertEqual(env["HOMEBREW_NO_COLOR"], "1")
    }

    func testLogIsCapped() async {
        let runner = FakeRunner()
        runner.stdout[["update"]] = (0..<6000).map(String.init)
        let p = make(runner)
        await p.run(.update)
        XCTAssertLessThanOrEqual(p.log.count, 5000)
        XCTAssertEqual(p.log.last?.text, "5999")
    }
}
