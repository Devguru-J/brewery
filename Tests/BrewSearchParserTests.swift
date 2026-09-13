import XCTest
@testable import brewery

final class BrewSearchParserTests: XCTestCase {
    func testDropsHeadersAndBlankLines() {
        let text = "==> Formulae\nripgrep\nripgrep-all\n\nIf you meant \"rg\" specifically:\n"
        XCTAssertEqual(BrewSearchParser.parse(text), ["ripgrep", "ripgrep-all"])
    }

    func testEmpty() {
        XCTAssertEqual(BrewSearchParser.parse(""), [])
    }
}
