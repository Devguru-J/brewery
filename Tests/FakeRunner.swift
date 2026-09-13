import Foundation
@testable import brewery

final class FakeRunner: CommandRunning, @unchecked Sendable {
    var exitCodes: [[String]: Int32] = [:]
    var stdout: [[String]: [String]] = [:]
    var stderr: [[String]: [String]] = [:]
    private(set) var calls: [[String]] = []
    private(set) var environments: [[String: String]] = []
    private(set) var terminated = false

    func run(executable: URL, arguments: [String], environment: [String: String],
             onLine: @escaping @Sendable (String, LogStream) -> Void) async throws -> Int32 {
        calls.append(arguments)
        environments.append(environment)
        for l in stdout[arguments] ?? [] { onLine(l, .stdout) }
        for l in stderr[arguments] ?? [] { onLine(l, .stderr) }
        await Task.yield()
        return exitCodes[arguments] ?? 0
    }

    func terminate() { terminated = true }
}
