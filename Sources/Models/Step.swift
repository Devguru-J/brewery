import Foundation

struct Step: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let arguments: [String]
    let symbol: String
    let summary: String

    var command: String { (["brew"] + arguments).joined(separator: " ") }

    static let update = Step(id: "update", title: "Update", arguments: ["update"],
                             symbol: "arrow.triangle.2.circlepath", summary: "패키지 목록을 최신으로 받아옵니다")
    static let upgrade = Step(id: "upgrade", title: "Upgrade", arguments: ["upgrade"],
                              symbol: "shippingbox.fill", summary: "설치된 formula와 cask를 업그레이드합니다")
    static let upgradeGreedy = Step(id: "upgrade-greedy", title: "Upgrade Greedy", arguments: ["upgrade", "--greedy"],
                                    symbol: "sparkles", summary: "자동 업데이트 cask까지 모두 업그레이드합니다")
    static let all: [Step] = [.update, .upgrade, .upgradeGreedy]
}

enum StepState: Equatable, Sendable {
    case idle
    case running
    case succeeded
    case skipped
    case failed(exitCode: Int32)
}
