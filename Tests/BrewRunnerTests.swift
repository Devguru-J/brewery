import XCTest
@testable import brewery

final class BrewRunnerTests: XCTestCase {
    final class Collector: @unchecked Sendable {
        private let lock = NSLock()
        private var lines: [(String, LogStream)] = []
        func add(_ l: String, _ s: LogStream) { lock.withLock { lines.append((l, s)) } }
        var stdout: [String] { lock.withLock { lines.filter { $0.1 == .stdout }.map(\.0) } }
        var stderr: [String] { lock.withLock { lines.filter { $0.1 == .stderr }.map(\.0) } }
    }

    func testStreamsStdoutAndStderrAndReturnsExitCode() async throws {
        let runner = BrewRunner()
        let c = Collector()
        let code = try await runner.run(executable: URL(fileURLWithPath: "/bin/sh"),
                                        arguments: ["-c", "echo one; echo two; echo oops 1>&2; exit 3"],
                                        environment: [:]) { c.add($0, $1) }
        XCTAssertEqual(code, 3)
        XCTAssertEqual(c.stdout, ["one", "two"])
        XCTAssertEqual(c.stderr, ["oops"])
    }

    func testEnvironmentIsPassed() async throws {
        let runner = BrewRunner()
        let c = Collector()
        _ = try await runner.run(executable: URL(fileURLWithPath: "/bin/sh"),
                                 arguments: ["-c", "echo $BREWERY_TEST"],
                                 environment: ["BREWERY_TEST": "hello"]) { c.add($0, $1) }
        XCTAssertEqual(c.stdout, ["hello"])
    }

    func testTerminateStopsProcess() async throws {
        let runner = BrewRunner()
        let c = Collector()
        async let code = runner.run(executable: URL(fileURLWithPath: "/bin/sh"),
                                    arguments: ["-c", "sleep 30"], environment: [:]) { c.add($0, $1) }
        try await Task.sleep(for: .milliseconds(300))
        runner.terminate()
        let result = try await code
        XCTAssertNotEqual(result, 0)
    }

    func testMissingExecutableThrows() async {
        let runner = BrewRunner()
        do {
            _ = try await runner.run(executable: URL(fileURLWithPath: "/nonexistent/brew"), arguments: [], environment: [:]) { _, _ in }
            XCTFail("expected throw")
        } catch { }
    }
}
