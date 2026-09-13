import Foundation

enum BrewInfoParser {
    private struct Payload: Decodable {
        struct Formula: Decodable {
            struct Versions: Decodable { let stable: String? }
            struct Installed: Decodable { let version: String }
            let name: String
            let desc: String?
            let homepage: String?
            let versions: Versions
            let installed: [Installed]
        }
        struct Cask: Decodable {
            let token: String
            let desc: String?
            let homepage: String?
            let version: String?
            let installed: String?
        }
        let formulae: [Formula]
        let casks: [Cask]
    }

    static func parse(_ data: Data, kind: PackageKind) throws -> PackageInfo? {
        let p = try JSONDecoder().decode(Payload.self, from: data)
        switch kind {
        case .formula:
            guard let f = p.formulae.first else { return nil }
            return PackageInfo(name: f.name, kind: .formula, description: f.desc ?? "", homepage: f.homepage ?? "",
                               version: f.versions.stable ?? "", isInstalled: !f.installed.isEmpty)
        case .cask:
            guard let c = p.casks.first else { return nil }
            return PackageInfo(name: c.token, kind: .cask, description: c.desc ?? "", homepage: c.homepage ?? "",
                               version: c.version ?? "", isInstalled: c.installed != nil)
        }
    }
}
