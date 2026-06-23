import XCTest
import Combine
@testable import SignalDrop

final class PingServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    private func makePaidLicense() -> LicenseManager {
        let license = LicenseManager()
        license.isPaid = true
        return license
    }

    func testInitialStatusIsIdle() {
        let sut = PingService()
        XCTAssertEqual(sut.status, .idle)
        XCTAssertFalse(sut.isRunning)
    }

    func testStartBlockedWhenNotPaid() {
        let license = LicenseManager()
        let sut = PingService(licenseManager: license)

        sut.start()

        XCTAssertFalse(sut.isRunning)
        XCTAssertEqual(sut.status, .idle)
    }

    func testStartSetsIsRunningWhenPaid() {
        let license = makePaidLicense()
        let sut = PingService(licenseManager: license)

        sut.start()

        XCTAssertTrue(sut.isRunning)

        sut.stop()
    }

    func testStopResetsState() {
        let license = makePaidLicense()
        let sut = PingService(licenseManager: license)

        sut.start()
        XCTAssertTrue(sut.isRunning)

        sut.stop()
        XCTAssertFalse(sut.isRunning)
        XCTAssertEqual(sut.status, .idle)
    }

    func testMeasureOnceBlockedWhenNotPaid() {
        let license = LicenseManager()
        let sut = PingService(licenseManager: license)

        sut.measureOnce()

        XCTAssertEqual(sut.status, .idle)
    }

    func testMeasureOnceSetsMeasuringWhenPaid() {
        let license = makePaidLicense()
        let sut = PingService(licenseManager: license)

        sut.measureOnce()

        XCTAssertEqual(sut.status, .measuring)

        sut.stop()
    }

    func testDefaultTargetAndPort() {
        let sut = PingService()
        XCTAssertEqual(sut.target, "1.1.1.1")
        XCTAssertEqual(sut.port, 443)
    }

    func testTargetIsConfigurable() {
        let sut = PingService()
        sut.target = "8.8.8.8"
        sut.port = 53

        XCTAssertEqual(sut.target, "8.8.8.8")
        XCTAssertEqual(sut.port, 53)
    }

    func testDoubleStartDoesNotDuplicate() {
        let license = makePaidLicense()
        let sut = PingService(licenseManager: license)

        sut.start()
        sut.start()

        XCTAssertTrue(sut.isRunning)

        sut.stop()
    }
}
