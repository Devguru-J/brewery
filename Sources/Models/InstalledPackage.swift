import Foundation

typealias PackageKind = OutdatedPackage.Kind

struct InstalledPackage: Identifiable, Hashable, Sendable {
    let name: String
    let version: String
    let kind: PackageKind
    var id: String { "\(kind.rawValue):\(name)" }
}

struct SearchResult: Identifiable, Hashable, Sendable {
    let name: String
    let kind: PackageKind
    let isInstalled: Bool
    var id: String { "\(kind.rawValue):\(name)" }
}

struct PackageInfo: Equatable, Sendable {
    let name: String
    let kind: PackageKind
    let description: String
    let homepage: String
    let version: String
    let isInstalled: Bool
    /// cask가 설치하는 .app 이름들 (artifacts의 app 항목). formula는 빈 배열.
    var appNames: [String] = []
}
