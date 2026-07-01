import Foundation
@testable import WireBar

final class MockNotificationDispatcher: NotificationDispatching, @unchecked Sendable {
    var authorizationResult: Bool = true
    var authorizationError: Error?
    var authorizationCallCount = 0
    private(set) var dispatched: [(title: String, body: String, identifier: String)] = []

    func requestAuthorization() async throws -> Bool {
        authorizationCallCount += 1
        if let error = authorizationError { throw error }
        return authorizationResult
    }

    func dispatch(title: String, body: String, identifier: String) async {
        dispatched.append((title: title, body: body, identifier: identifier))
    }
}
