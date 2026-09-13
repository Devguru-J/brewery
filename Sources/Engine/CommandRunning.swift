import Foundation

protocol CommandRunning: AnyObject {
    /// 실행 파일을 띄우고 stdout/stderr를 줄 단위로 `onLine`에 전달한다. 종료 코드를 반환한다.
    func run(executable: URL,
             arguments: [String],
             environment: [String: String],
             onLine: @escaping @Sendable (String, LogStream) -> Void) async throws -> Int32

    /// 현재 실행 중인 프로세스에 SIGTERM을 보낸다.
    func terminate()
}
