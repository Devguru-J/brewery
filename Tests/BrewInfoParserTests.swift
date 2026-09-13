import XCTest
@testable import brewery

final class BrewInfoParserTests: XCTestCase {
    func testFormula() throws {
        let json = #"{"formulae":[{"name":"ripgrep","desc":"Search tool","homepage":"https://x","versions":{"stable":"15.2.0"},"installed":[{"version":"15.2.0"}]}],"casks":[]}"#
        let i = try XCTUnwrap(try BrewInfoParser.parse(Data(json.utf8), kind: .formula))
        XCTAssertEqual(i, PackageInfo(name: "ripgrep", kind: .formula, description: "Search tool", homepage: "https://x", version: "15.2.0", isInstalled: true))
    }

    func testCaskNotInstalled() throws {
        let json = #"{"formulae":[],"casks":[{"token":"iterm2","desc":"Terminal","homepage":"https://iterm2.com/","version":"3.7.1","installed":null}]}"#
        let i = try XCTUnwrap(try BrewInfoParser.parse(Data(json.utf8), kind: .cask))
        XCTAssertEqual(i.name, "iterm2")
        XCTAssertFalse(i.isInstalled)
        XCTAssertEqual(i.version, "3.7.1")
    }

    func testMissingReturnsNil() throws {
        XCTAssertNil(try BrewInfoParser.parse(Data(#"{"formulae":[],"casks":[]}"#.utf8), kind: .formula))
    }
}

final class BrewInfoArtifactsTests: XCTestCase {
    func testCaskAppNamesFromArtifacts() throws {
        let json = #"{"formulae":[],"casks":[{"token":"android-studio","desc":"IDE","homepage":"h","version":"1","installed":"1","artifacts":[{"uninstall":[{"quit":"x"}]},{"app":["Android Studio.app"],"target":"/Applications/Android Studio.app"},{"zap":[{"trash":["a"]}]}]}]}"#
        let i = try XCTUnwrap(try BrewInfoParser.parse(Data(json.utf8), kind: .cask))
        XCTAssertEqual(i.appNames, ["Android Studio.app"])
        XCTAssertTrue(i.isInstalled)
    }
}
