import Foundation

final class BrewRunner: CommandRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Process?

    func run(executable: URL,
             arguments: [String],
             environment: [String: String],
             onLine: @escaping @Sendable (String, LogStream) -> Void) async throws -> Int32 {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        var env = ProcessInfo.processInfo.environment
        env.merge(environment) { _, new in new }
        process.environment = env

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = FileHandle.nullDevice

        try process.run()
        lock.withLock { current = process }
        defer { lock.withLock { current = nil } }

        async let outDone: Void = Self.pump(stdout.fileHandleForReading, .stdout, onLine)
        async let errDone: Void = Self.pump(stderr.fileHandleForReading, .stderr, onLine)
        _ = await (outDone, errDone)

        await Task.detached { process.waitUntilExit() }.value
        return process.terminationStatus
    }

    func terminate() {
        lock.withLock { current }?.terminate()
    }

    private static func pump(_ handle: FileHandle, _ stream: LogStream,
                             _ onLine: @escaping @Sendable (String, LogStream) -> Void) async {
        do {
            for try await line in handle.bytes.lines {
                onLine(line, stream)
            }
        } catch {
            onLine("[brewery] output read error: \(error.localizedDescription)", .system)
        }
    }
}
