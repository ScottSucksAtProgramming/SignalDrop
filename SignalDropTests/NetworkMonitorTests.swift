import XCTest
import Network
@testable import SignalDrop

final class MockPathMonitor: NetworkPathProviding {
    var currentPath: NWPath { NWPathMonitor().currentPath }
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)?
    var isStarted = false
    var isCancelled = false

    func start(queue: DispatchQueue) {
        isStarted = true
    }

    func cancel() {
        isCancelled = true
    }
}

final class NetworkMonitorTests: XCTestCase {
    func testStartBeginsMonitoring() {
        let mockMonitor = MockPathMonitor()
        let sut = NetworkMonitor(pathMonitor: mockMonitor)

        sut.start()

        XCTAssertTrue(mockMonitor.isStarted)
        XCTAssertNotNil(mockMonitor.pathUpdateHandler)
    }

    func testStopCancelsMonitoring() {
        let mockMonitor = MockPathMonitor()
        let sut = NetworkMonitor(pathMonitor: mockMonitor)

        sut.start()
        sut.stop()

        XCTAssertTrue(mockMonitor.isCancelled)
    }

    func testInitialStateIsDisconnected() {
        let sut = NetworkMonitor(pathMonitor: MockPathMonitor())

        XCTAssertFalse(sut.state.isConnected)
        XCTAssertNil(sut.state.ssid)
        XCTAssertEqual(sut.state.connectionType, .none)
    }
}
