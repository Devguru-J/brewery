import XCTest
@testable import brewery

final class BrewListParserTests: XCTestCase {
    func testFormulaVersions() {
        let r = BrewListParser.parseFormulaVersions("ada-url 4.0.0\nopenssl@3 3.4.0 3.5.1\n\n")
        XCTAssertEqual(r, [
            InstalledPackage(name: "ada-url", version: "4.0.0", kind: .formula),
            InstalledPackage(name: "openssl@3", version: "3.4.0, 3.5.1", kind: .formula),
        ])
    }

    func testCaskNames() {
        XCTAssertEqual(BrewListParser.parseCaskNames("aerospace\n\nandroid-studio \n"), ["aerospace", "android-studio"])
    }

    func testCaskVersionsFromCaskroom() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("caskroom-\(UUID().uuidString)")
        for dir in ["iterm2/3.5.1", "iterm2/.metadata", "android-studio/2026.1.4.7,quail4"] {
            try FileManager.default.createDirectory(at: root.appendingPathComponent(dir), withIntermediateDirectories: true)
        }
        let r = BrewListParser.caskVersions(names: ["iterm2", "android-studio", "missing"], caskroom: root)
        XCTAssertEqual(r, [
            InstalledPackage(name: "iterm2", version: "3.5.1", kind: .cask),
            InstalledPackage(name: "android-studio", version: "2026.1.4.7,quail4", kind: .cask),
            InstalledPackage(name: "missing", version: "", kind: .cask),
        ])
    }
}
