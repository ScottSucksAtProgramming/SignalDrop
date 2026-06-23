import XCTest
import Combine
@testable import SignalDrop

final class VPNManagerTests: XCTestCase {
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

    // MARK: - Detection

    func testDetectInstalledVPNsFindsExistingCLIs() {
        let executor = MockVPNCommandExecutor()
        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: LicenseManager(),
            fileExistsChecker: { path in
                path == "/opt/homebrew/bin/tailscale"
            }
        )

        sut.detectInstalledVPNs()

        XCTAssertEqual(sut.vpnStates.count, 1)
        XCTAssertEqual(sut.vpnStates[0].detectedCLIPath, "/opt/homebrew/bin/tailscale")
        XCTAssertTrue(sut.vpnStates[0].isCLIInstalled)
    }

    func testDetectInstalledVPNsMarksUninstalledCLIs() {
        let executor = MockVPNCommandExecutor()
        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: LicenseManager(),
            fileExistsChecker: { _ in false }
        )

        sut.detectInstalledVPNs()

        XCTAssertEqual(sut.vpnStates.count, 1)
        XCTAssertNil(sut.vpnStates[0].detectedCLIPath)
        XCTAssertFalse(sut.vpnStates[0].isCLIInstalled)
    }

    // MARK: - Status Refresh

    func testRefreshStatusParsesConnected() {
        let executor = MockVPNCommandExecutor()
        executor.results["/opt/homebrew/bin/tailscale"] = ShellResult(
            output: "{\"BackendState\":\"Running\"}",
            exitCode: 0
        )

        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: LicenseManager(),
            fileExistsChecker: { $0 == "/opt/homebrew/bin/tailscale" }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Status updates to connected")
        var cancellable: AnyCancellable?
        cancellable = sut.$vpnStates
            .dropFirst()
            .sink { states in
                if states.first?.status == .connected {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        sut.refreshAllStatuses()
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(sut.vpnStates[0].status, .connected)
    }

    func testRefreshStatusParsesDisconnected() {
        let executor = MockVPNCommandExecutor()
        executor.results["/opt/homebrew/bin/tailscale"] = ShellResult(
            output: "{\"BackendState\":\"Stopped\"}",
            exitCode: 0
        )

        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: LicenseManager(),
            fileExistsChecker: { $0 == "/opt/homebrew/bin/tailscale" }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Status updates to disconnected")
        var cancellable: AnyCancellable?
        cancellable = sut.$vpnStates
            .dropFirst()
            .sink { states in
                if states.first?.status == .disconnected {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        sut.refreshAllStatuses()
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(sut.vpnStates[0].status, .disconnected)
    }

    // MARK: - Connect / Disconnect

    func testConnectExecutesCorrectCommand() {
        let executor = MockVPNCommandExecutor()
        executor.results["/opt/homebrew/bin/tailscale"] = ShellResult(output: "", exitCode: 0)

        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: makePaidLicense(),
            fileExistsChecker: { $0 == "/opt/homebrew/bin/tailscale" }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Connect completes")
        sut.connect(vpnID: "tailscale") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        let connectCalls = executor.executedCommands.filter { $0.args.contains("up") }
        XCTAssertEqual(connectCalls.count, 1)
        XCTAssertEqual(connectCalls[0].path, "/opt/homebrew/bin/tailscale")
        XCTAssertEqual(connectCalls[0].args, ["up"])
    }

    func testDisconnectExecutesCorrectCommand() {
        let executor = MockVPNCommandExecutor()
        executor.results["/opt/homebrew/bin/tailscale"] = ShellResult(output: "", exitCode: 0)

        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: makePaidLicense(),
            fileExistsChecker: { $0 == "/opt/homebrew/bin/tailscale" }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Disconnect completes")
        sut.disconnect(vpnID: "tailscale") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        let disconnectCalls = executor.executedCommands.filter { $0.args.contains("down") }
        XCTAssertEqual(disconnectCalls.count, 1)
        XCTAssertEqual(disconnectCalls[0].path, "/opt/homebrew/bin/tailscale")
        XCTAssertEqual(disconnectCalls[0].args, ["down"])
    }

    // MARK: - Guards

    func testConnectBlockedWhenNotPaid() {
        let executor = MockVPNCommandExecutor()
        executor.results["/opt/homebrew/bin/tailscale"] = ShellResult(output: "", exitCode: 0)

        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: LicenseManager(), // isPaid defaults to false
            fileExistsChecker: { $0 == "/opt/homebrew/bin/tailscale" }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Connect completes (blocked)")
        sut.connect(vpnID: "tailscale") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        let connectCalls = executor.executedCommands.filter { $0.args.contains("up") }
        XCTAssertTrue(connectCalls.isEmpty)
    }

    func testConnectNoopsWhenCLIMissing() {
        let executor = MockVPNCommandExecutor()
        let sut = VPNManager(
            definitions: [.tailscale],
            executor: executor,
            licenseManager: makePaidLicense(),
            fileExistsChecker: { _ in false }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Connect completes (no CLI)")
        sut.connect(vpnID: "tailscale") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(executor.executedCommands.isEmpty)
    }

    // MARK: - Multiple Connected Warning

    func testMultipleVPNsConnectedWarning() {
        let executor = MockVPNCommandExecutor()
        executor.results["/opt/homebrew/bin/tailscale"] = ShellResult(
            output: "{\"BackendState\":\"Running\"}",
            exitCode: 0
        )
        executor.results["/usr/local/bin/piactl"] = ShellResult(
            output: "Connected",
            exitCode: 0
        )

        let sut = VPNManager(
            definitions: [.tailscale, .pia],
            executor: executor,
            licenseManager: LicenseManager(),
            fileExistsChecker: { path in
                path == "/opt/homebrew/bin/tailscale" || path == "/usr/local/bin/piactl"
            }
        )
        sut.detectInstalledVPNs()

        let expectation = XCTestExpectation(description: "Both VPNs report connected")
        var cancellable: AnyCancellable?
        cancellable = sut.$vpnStates
            .dropFirst()
            .sink { states in
                let connectedCount = states.filter { $0.status == .connected }.count
                if connectedCount >= 2 {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        sut.refreshAllStatuses()
        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(sut.hasMultipleConnected)
        XCTAssertEqual(sut.connectedCount, 2)
    }

    // MARK: - setEnabled

    func testSetEnabledUpdatesState() {
        let sut = VPNManager(
            definitions: [.tailscale],
            executor: MockVPNCommandExecutor(),
            licenseManager: LicenseManager(),
            fileExistsChecker: { $0 == "/opt/homebrew/bin/tailscale" }
        )
        sut.detectInstalledVPNs()
        XCTAssertTrue(sut.vpnStates[0].isEnabled)

        sut.setEnabled(vpnID: "tailscale", enabled: false)

        XCTAssertFalse(sut.vpnStates[0].isEnabled)
    }
}
