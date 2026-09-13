import Foundation

/// 설치·삭제. 업그레이드와 같은 러너·로그·잠금을 공유한다.
extension UpgradePipeline {
    func install(name: String, kind: PackageKind) async {
        var args = ["install"]
        if kind == .cask { args.append("--cask") }
        args.append(name)
        await runPackageCommands([args], failureLabel: "설치")
    }

    func uninstall(_ items: [InstalledPackage]) async {
        let formulae = items.filter { $0.kind == .formula }.map(\.name)
        let casks = items.filter { $0.kind == .cask }.map(\.name)
        var commands: [[String]] = []
        if !formulae.isEmpty { commands.append(["uninstall"] + formulae) }
        if !casks.isEmpty { commands.append(["uninstall", "--cask"] + casks) }
        await runPackageCommands(commands, failureLabel: "삭제")
    }

    private func runPackageCommands(_ commands: [[String]], failureLabel: String) async {
        guard let brewURL, !isBusy, !commands.isEmpty else { return }
        beginAction()
        defer { endAction() }
        for args in commands {
            append("$ " + (["brew"] + args).joined(separator: " "), .system, nil)
            do {
                let code = try await runner.run(executable: brewURL, arguments: args,
                                                environment: Self.environment(for: brewURL)) { [weak self] line, stream in
                    Task { @MainActor in self?.ingest(line, stream, nil) }
                }
                for _ in 0..<3 { await Task.yield() }
                if code != 0 {
                    setError("\(failureLabel) 실패 (종료 코드 \(code))")
                    break
                }
            } catch {
                setError("\(failureLabel) 실패: \(error.localizedDescription)")
                append("[brewery] \(error.localizedDescription)", .system, nil)
                break
            }
        }
        endAction()
        onPackagesChanged?()
        await refreshOutdated()
    }
}
