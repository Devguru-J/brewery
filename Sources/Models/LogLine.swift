import Foundation

enum LogStream: Sendable { case stdout, stderr, system }

struct LogLine: Identifiable, Sendable {
    let id: Int
    let text: String
    let stream: LogStream
    let stepID: Step.ID?
}
