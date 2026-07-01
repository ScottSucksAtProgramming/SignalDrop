import Foundation

protocol NotificationDispatching: Sendable {
    func requestAuthorization() async throws -> Bool
    func dispatch(title: String, body: String, identifier: String) async
}
