import Foundation

enum BrewSearchParser {
    /// `brew search --formula|--cask <q>` 출력. 빈 줄과 `==>` 헤더, 안내 문장은 버린다.
    static func parse(_ text: String) -> [String] {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("==>") && !$0.contains(" ") }
    }
}
