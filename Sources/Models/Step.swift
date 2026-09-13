import Foundation

struct Step: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let arguments: [String]
    let symbol: String
    /// 로컬라이즈 키
    let summary: String

    var command: String { (["brew"] + arguments).joined(separator: " ") }

    static let update = Step(id: "update", title: "Update", arguments: ["update"],
                             symbol: "arrow.triangle.2.circlepath", summary: "step.update.summary")
    static let upgrade = Step(id: "upgrade", title: "Upgrade", arguments: ["upgrade"],
                              symbol: "shippingbox.fill", summary: "step.upgrade.summary")
    static let upgradeGreedy = Step(id: "upgrade-greedy", title: "Upgrade Greedy", arguments: ["upgrade", "--greedy"],
                                    symbol: "sparkles", summary: "step.greedy.summary")
    static let all: [Step] = [.update, .upgrade, .upgradeGreedy]
}

enum StepState: Equatable, Sendable {
    case idle
    case running
    case succeeded
    case skipped
    case failed(exitCode: Int32)
}
