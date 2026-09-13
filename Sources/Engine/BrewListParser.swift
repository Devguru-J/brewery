import Foundation

enum BrewListParser {
    /// `brew list --formula --versions` 출력. 한 줄에 "name v1 v2 …".
    static func parseFormulaVersions(_ text: String) -> [InstalledPackage] {
        text.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard let name = parts.first else { return nil }
            let version = parts.dropFirst().joined(separator: ", ")
            return InstalledPackage(name: String(name), version: version, kind: .formula)
        }
    }

    /// `brew list --cask` 출력. 한 줄에 이름 하나.
    static func parseCaskNames(_ text: String) -> [String] {
        text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// Caskroom/<name>/ 아래 디렉터리명이 버전. `.metadata` 등 숨김 항목 제외.
    static func caskVersions(names: [String], caskroom: URL, fileManager: FileManager = .default) -> [InstalledPackage] {
        names.map { name in
            let dir = caskroom.appendingPathComponent(name)
            let entries = (try? fileManager.contentsOfDirectory(atPath: dir.path)) ?? []
            let versions = entries.filter { !$0.hasPrefix(".") }.sorted()
            return InstalledPackage(name: name, version: versions.joined(separator: ", "), kind: .cask)
        }
    }
}
