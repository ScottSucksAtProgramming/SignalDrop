import XCTest
import Combine
@testable import WireBar

final class WiFiManagerTests: XCTestCase {
    private var mockScanner: MockWiFiScanner!

    override func setUp() {
        super.setUp()
        mockScanner = MockWiFiScanner()
    }

    // MARK: - Scanning

    func testScanReturnsNetworksSortedKnownFirst() {
        mockScanner.knownSSIDs = ["HomeNetwork"]
        mockScanner.networksToReturn = [
            makeNetwork(ssid: "CoffeeShop", rssi: -40, isKnown: false),
            makeNetwork(ssid: "HomeNetwork", rssi: -60, isKnown: true),
        ]

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()
        waitForScanToFinish(sut)

        XCTAssertEqual(sut.networks.count, 2)
        XCTAssertEqual(sut.networks[0].ssid, "HomeNetwork")
        XCTAssertEqual(sut.networks[1].ssid, "CoffeeShop")
    }

    func testScanSortsWithinGroupBySignalStrength() {
        mockScanner.networksToReturn = [
            makeNetwork(ssid: "Weak", rssi: -80, isKnown: false),
            makeNetwork(ssid: "Strong", rssi: -30, isKnown: false),
            makeNetwork(ssid: "Medium", rssi: -55, isKnown: false),
        ]

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()
        waitForScanToFinish(sut)

        XCTAssertEqual(sut.networks.map(\.ssid), ["Strong", "Medium", "Weak"])
    }

    func testScanMarksCurrentNetwork() {
        mockScanner.currentSSIDValue = "HomeNetwork"
        mockScanner.networksToReturn = [
            makeNetwork(ssid: "HomeNetwork", rssi: -50, isKnown: false),
            makeNetwork(ssid: "Other", rssi: -60, isKnown: false),
        ]

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()
        waitForScanToFinish(sut)

        XCTAssertTrue(sut.networks.first { $0.ssid == "HomeNetwork" }!.isCurrent)
        XCTAssertFalse(sut.networks.first { $0.ssid == "Other" }!.isCurrent)
    }

    func testScanFiltersOutNilSSIDNetworks() {
        mockScanner.networksToReturn = [
            makeNetwork(ssid: "Visible", rssi: -50, isKnown: false),
        ]

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()
        waitForScanToFinish(sut)

        XCTAssertEqual(sut.networks.count, 1)
        XCTAssertEqual(sut.networks[0].ssid, "Visible")
    }

    func testScanFailureSetsErrorState() {
        mockScanner.scanShouldThrow = true

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()
        waitForScanToFinish(sut)

        XCTAssertTrue(sut.networks.isEmpty)
        XCTAssertNotNil(sut.scanError)
    }

    // MARK: - Join Network

    func testJoinKnownNetworkCallsAssociateWithNilPassword() {
        let network = makeNetwork(ssid: "Home", rssi: -50, isKnown: true, bssid: "AA:BB:CC:DD:EE:FF")
        let sut = WiFiManager(scanner: mockScanner)

        sut.joinNetwork(network, password: nil)

        XCTAssertEqual(mockScanner.associateCalledWith?.bssid, "AA:BB:CC:DD:EE:FF")
        XCTAssertNil(mockScanner.associateCalledWith?.password)
    }

    func testJoinUnknownNetworkCallsAssociateWithPassword() {
        let network = makeNetwork(ssid: "Cafe", rssi: -50, isKnown: false, bssid: "11:22:33:44:55:66")
        let sut = WiFiManager(scanner: mockScanner)

        sut.joinNetwork(network, password: "secret123")

        XCTAssertEqual(mockScanner.associateCalledWith?.bssid, "11:22:33:44:55:66")
        XCTAssertEqual(mockScanner.associateCalledWith?.password, "secret123")
    }

    func testJoinFailureSetsJoinError() {
        mockScanner.associateShouldThrow = true
        let network = makeNetwork(ssid: "Bad", rssi: -50, isKnown: false, bssid: "FF:FF:FF:FF:FF:FF")
        let sut = WiFiManager(scanner: mockScanner)

        sut.joinNetwork(network, password: "pw")

        XCTAssertNotNil(sut.joinError)
    }

    // MARK: - Power Toggle

    func testTogglePowerOff() {
        mockScanner.isPowered = true
        let sut = WiFiManager(scanner: mockScanner)

        sut.togglePower()

        XCTAssertEqual(mockScanner.setPowerCalledWith, false)
        XCTAssertFalse(sut.isWiFiPoweredOn)
    }

    func testTogglePowerOn() {
        mockScanner.isPowered = false
        let sut = WiFiManager(scanner: mockScanner)

        sut.togglePower()

        XCTAssertEqual(mockScanner.setPowerCalledWith, true)
        XCTAssertTrue(sut.isWiFiPoweredOn)
    }

    // MARK: - Helpers

    private func waitForScanToFinish(_ manager: WiFiManager, timeout: TimeInterval = 2) {
        let expectation = XCTestExpectation(description: "Scan completes")
        var cancellable: AnyCancellable?
        cancellable = manager.$isScanning
            .dropFirst()
            .filter { !$0 }
            .sink { _ in
                expectation.fulfill()
                cancellable?.cancel()
            }
        wait(for: [expectation], timeout: timeout)
    }

    private func makeNetwork(
        ssid: String,
        rssi: Int,
        isKnown: Bool,
        bssid: String = "00:00:00:00:00:00"
    ) -> ScannedNetwork {
        ScannedNetwork(
            id: bssid,
            ssid: ssid,
            bssid: bssid,
            rssi: rssi,
            channelNumber: 6,
            securityType: .wpa2,
            isKnown: isKnown,
            isCurrent: false
        )
    }
}
