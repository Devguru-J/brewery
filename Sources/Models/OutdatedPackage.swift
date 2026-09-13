import Foundation

struct OutdatedPackage: Identifiable, Equatable, Sendable {
    enum Kind: String, Sendable { case formula, cask }
    let name: String
    let installedVersion: String
    let currentVersion: String
    let kind: Kind
    var id: String { "\(kind.rawValue):\(name)" }
}
