import XCTest
@testable import brewery

@MainActor
final class AppIconResolverTests: XCTestCase {
    func testFindsAppInCaskroomThenApplications() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("icons-\(UUID().uuidString)")
        let caskroom = root.appendingPathComponent("Caskroom")
        let apps = root.appendingPathComponent("Applications")
        try FileManager.default.createDirectory(at: caskroom.appendingPathComponent("ghostty/1.0/Ghostty.app"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: caskroom.appendingPathComponent("ghostty/.metadata"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: apps.appendingPathComponent("Raycast.app"), withIntermediateDirectories: true)
        let r = AppIconResolver(caskroom: caskroom, applications: [apps])
        XCTAssertEqual(r.appPath(forCask: "ghostty")?.lastPathComponent, "Ghostty.app")
        XCTAssertEqual(r.appPath(forCask: "raycast", appNames: ["Raycast.app"])?.path, apps.appendingPathComponent("Raycast.app").path)
        XCTAssertNil(r.appPath(forCask: "missing"))
        XCTAssertNotNil(r.icon(forCask: "ghostty"))
        XCTAssertNil(r.icon(forCask: "missing"))
    }
}
