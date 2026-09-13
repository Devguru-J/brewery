import Foundation

enum BrewLocator {
    static let standardCandidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    static func locate(candidates: [String] = standardCandidates,
                       path: String? = ProcessInfo.processInfo.environment["PATH"],
                       fileManager: FileManager = .default) -> URL? {
        for c in candidates where fileManager.isExecutableFile(atPath: c) {
            return URL(fileURLWithPath: c)
        }
        for dir in (path ?? "").split(separator: ":") {
            let p = "\(dir)/brew"
            if fileManager.isExecutableFile(atPath: p) { return URL(fileURLWithPath: p) }
        }
        return nil
    }
}
