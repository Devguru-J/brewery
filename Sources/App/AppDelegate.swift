import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor static var onTerminate: (() -> Void)?

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { Self.onTerminate?() }
    }
}
