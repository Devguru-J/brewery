import Foundation

enum BrewOutdatedParser {
    private struct Payload: Decodable {
        struct Entry: Decodable {
            let name: String
            let installedVersions: [String]
            let currentVersion: String

            enum CodingKeys: String, CodingKey {
                case name, installedVersions = "installed_versions", currentVersion = "current_version"
            }

            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                name = try c.decode(String.self, forKey: .name)
                currentVersion = try c.decode(String.self, forKey: .currentVersion)
                if let list = try? c.decode([String].self, forKey: .installedVersions) {
                    installedVersions = list
                } else if let single = try? c.decode(String.self, forKey: .installedVersions) {
                    installedVersions = [single]
                } else {
                    installedVersions = []
                }
            }
        }
        let formulae: [Entry]
        let casks: [Entry]
    }

    static func parse(_ data: Data) throws -> [OutdatedPackage] {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        func convert(_ e: Payload.Entry, _ kind: OutdatedPackage.Kind) -> OutdatedPackage {
            OutdatedPackage(name: e.name, installedVersion: e.installedVersions.joined(separator: ", "),
                            currentVersion: e.currentVersion, kind: kind)
        }
        return payload.formulae.map { convert($0, .formula) } + payload.casks.map { convert($0, .cask) }
    }
}
