import AppKit
import Observation

/// cask의 .app 아이콘을 찾는다. Caskroom/<name>/<version>/*.app → /Applications/<app> 순.
@MainActor
@Observable
final class AppIconResolver {
    private let caskroom: URL
    private let applications: [URL]
    private let fileManager: FileManager
    @ObservationIgnored private var cache: [String: NSImage?] = [:]

    init(caskroom: URL,
         applications: [URL] = [URL(fileURLWithPath: "/Applications"),
                                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")],
         fileManager: FileManager = .default) {
        self.caskroom = caskroom
        self.applications = applications
        self.fileManager = fileManager
    }

    /// 설치된 cask의 .app 경로. 없으면 nil.
    func appPath(forCask name: String, appNames: [String] = []) -> URL? {
        let dir = caskroom.appendingPathComponent(name)
        if let versions = try? fileManager.contentsOfDirectory(atPath: dir.path) {
            for v in versions.filter({ !$0.hasPrefix(".") }).sorted().reversed() {
                let vdir = dir.appendingPathComponent(v)
                if let entries = try? fileManager.contentsOfDirectory(atPath: vdir.path),
                   let app = entries.first(where: { $0.hasSuffix(".app") }) {
                    return vdir.appendingPathComponent(app)
                }
            }
        }
        for app in appNames {
            for base in applications {
                let url = base.appendingPathComponent(app)
                if fileManager.fileExists(atPath: url.path) { return url }
            }
        }
        return nil
    }

    func icon(forCask name: String, appNames: [String] = []) -> NSImage? {
        if let cached = cache[name] { return cached }
        let image = appPath(forCask: name, appNames: appNames).map { NSWorkspace.shared.icon(forFile: $0.path) }
        cache[name] = image
        return image
    }

    func invalidate() { cache.removeAll() }
}
