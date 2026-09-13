import Foundation
import Observation

@MainActor
@Observable
final class UpgradePipeline {
    let steps = Step.all
    let brewURL: URL?

    private(set) var states: [Step.ID: StepState] = [:]
    private(set) var log: [LogLine] = []
    private(set) var outdated: [OutdatedPackage] = []
    private(set) var isRunning = false
    private(set) var isRefreshing = false
    private(set) var lastRun: Date?
    private(set) var lastError: String?
    private(set) var currentStep: Step?

    var brewAvailable: Bool { brewURL != nil }
    var isBusy: Bool { isRunning || isRefreshing }
    var outdatedCount: Int { outdated.count }
    var allSucceeded: Bool { steps.allSatisfy { state(of: $0) == .succeeded } }

    private let runner: CommandRunning
    private let defaults: UserDefaults
    private var nextLineID = 0
    private let maxLogLines = 5000
    private static let lastRunKey = "lastRun"

    init(runner: CommandRunning, brewURL: URL?, defaults: UserDefaults = .standard) {
        self.runner = runner
        self.brewURL = brewURL
        self.defaults = defaults
        for s in steps { states[s.id] = .idle }
        lastRun = defaults.object(forKey: Self.lastRunKey) as? Date
    }

    func state(of step: Step) -> StepState { states[step.id] ?? .idle }

    func runAll() async { await execute(steps) }
    func run(_ step: Step) async { await execute([step]) }

    func cancel() {
        runner.terminate()
        append("[brewery] 중단을 요청했습니다.", .system, currentStep?.id)
    }

    func clearLog() { log.removeAll() }

    func refreshOutdated() async {
        guard let brewURL, !isBusy else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        let buffer = LineBuffer()
        do {
            let code = try await runner.run(executable: brewURL,
                                            arguments: ["outdated", "--json=v2", "--greedy"],
                                            environment: Self.environment(for: brewURL)) { line, stream in
                if stream == .stdout { buffer.append(line) }
            }
            guard code == 0 else {
                append("[brewery] brew outdated 실패 (종료 코드 \(code))", .system, nil)
                return
            }
            outdated = try BrewOutdatedParser.parse(Data(buffer.joined().utf8))
        } catch {
            append("[brewery] 목록 갱신 실패: \(error.localizedDescription)", .system, nil)
        }
    }

    static func environment(for brew: URL) -> [String: String] {
        let bin = brew.deletingLastPathComponent().path
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        return [
            "HOMEBREW_NO_AUTO_UPDATE": "1",
            "HOMEBREW_NO_ENV_HINTS": "1",
            "HOMEBREW_NO_COLOR": "1",
            "NO_COLOR": "1",
            "NONINTERACTIVE": "1",
            "PATH": "\(bin):\(path)",
        ]
    }

    // MARK: - Private

    private func execute(_ sequence: [Step]) async {
        guard let brewURL, !isBusy else { return }
        isRunning = true
        lastError = nil
        for s in steps { states[s.id] = .idle }

        var failed = false
        for step in sequence {
            if failed { states[step.id] = .skipped; continue }
            states[step.id] = .running
            currentStep = step
            append("$ \(step.command)", .system, step.id)
            do {
                let code = try await runner.run(executable: brewURL,
                                                arguments: step.arguments,
                                                environment: Self.environment(for: brewURL)) { [weak self] line, stream in
                    Task { @MainActor in self?.ingest(line, stream, step.id) }
                }
                for _ in 0..<3 { await Task.yield() }
                if code == 0 {
                    states[step.id] = .succeeded
                } else {
                    states[step.id] = .failed(exitCode: code)
                    lastError = "\(step.title) 실패 (종료 코드 \(code))"
                    failed = true
                }
            } catch {
                states[step.id] = .failed(exitCode: -1)
                lastError = error.localizedDescription
                append("[brewery] \(error.localizedDescription)", .system, step.id)
                failed = true
            }
        }
        lastRun = Date()
        defaults.set(lastRun, forKey: Self.lastRunKey)
        isRunning = false
        currentStep = nil
        await refreshOutdated()
    }

    private func ingest(_ line: String, _ stream: LogStream, _ stepID: Step.ID?) {
        append(line, stream, stepID)
        let lower = line.lowercased()
        if lower.contains("sudo"),
           lower.contains("password") || lower.contains("terminal is required") || lower.contains("askpass") {
            append("[brewery] 이 항목은 관리자 비밀번호가 필요합니다. 터미널에서 직접 실행하세요.", .system, stepID)
        }
    }

    private func append(_ text: String, _ stream: LogStream, _ stepID: Step.ID?) {
        nextLineID += 1
        log.append(LogLine(id: nextLineID, text: text, stream: stream, stepID: stepID))
        if log.count > maxLogLines {
            log.removeFirst(log.count - maxLogLines)
        }
    }
}

/// 여러 스레드에서 오는 stdout 줄을 모으는 잠금 버퍼.
final class LineBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []
    func append(_ l: String) { lock.withLock { lines.append(l) } }
    func joined() -> String { lock.withLock { lines.joined(separator: "\n") } }
}
