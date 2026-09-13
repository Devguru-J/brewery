import XCTest
@testable import brewery

final class BrewOutdatedParserTests: XCTestCase {
    func testParsesFormulaeAndCasks() throws {
        let json = """
        {"formulae":[{"name":"git","installed_versions":["2.50.0"],"current_version":"2.51.0","pinned":false,"pinned_version":null}],
         "casks":[{"name":"iterm2","installed_versions":["3.5.0"],"current_version":"3.5.1"}]}
        """
        let result = try BrewOutdatedParser.parse(Data(json.utf8))
        XCTAssertEqual(result, [
            OutdatedPackage(name: "git", installedVersion: "2.50.0", currentVersion: "2.51.0", kind: .formula),
            OutdatedPackage(name: "iterm2", installedVersion: "3.5.0", currentVersion: "3.5.1", kind: .cask),
        ])
    }

    func testCaskInstalledVersionAsString() throws {
        let json = #"{"formulae":[],"casks":[{"name":"x","installed_versions":"1.0","current_version":"1.1"}]}"#
        let result = try BrewOutdatedParser.parse(Data(json.utf8))
        XCTAssertEqual(result.first?.installedVersion, "1.0")
    }

    func testEmpty() throws {
        XCTAssertEqual(try BrewOutdatedParser.parse(Data(#"{"formulae":[],"casks":[]}"#.utf8)), [])
    }

    func testMalformedThrows() {
        XCTAssertThrowsError(try BrewOutdatedParser.parse(Data("not json".utf8)))
    }
}
