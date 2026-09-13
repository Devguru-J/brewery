import XCTest
@testable import brewery

final class BrewLocatorTests: XCTestCase {
    func testFindsInPathWhenStandardLocationsMissing() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("brewery-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fake = dir.appendingPathComponent("brew")
        try "#!/bin/sh\n".write(to: fake, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fake.path)
        let found = BrewLocator.locate(candidates: [], path: dir.path)
        XCTAssertEqual(found?.path, fake.path)
    }

    func testReturnsNilWhenNothingFound() {
        XCTAssertNil(BrewLocator.locate(candidates: ["/nonexistent/brew"], path: "/nonexistent"))
    }

    func testRealMachineHasBrewOrNil() {
        _ = BrewLocator.locate()
    }
}
