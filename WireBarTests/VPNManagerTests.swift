import XCTest
import Combine
@testable import WireBar

final class VPNManagerTests: XCTestCase {

    private func makePaidLicense() -> LicenseManager {
        let license = LicenseManager()
        license.isPaid = true
        return license
    }

    private func makeProvider(configs: [VPNConfigurationInfo] = []) -> MockVPNConfigurationProvider {
        let provider = MockVPNConfigurationProvider()
        provider.configurations = configs
        return provider
    }

    private let sampleConfigs: [VPNConfigurationInfo] = [
        VPNConfigurationInfo(
            id: "F5F86763-7D4E-4F9E-8D76-F746957BDCEB",
            displayName: "Rivendell",
            status: .disconnected,
            providerBundleIdentifier: "com.wireguard.macos"
        ),
        VPNConfigurationInfo(
            id: "4D9D5222-38FB-46B5-B61B-09499DBB016B",
            displayName: "Tailscale",
            status: .connected,
            providerBundleIdentifier: "io.tailscale.ipn.macsys"
        ),
    ]

    // MARK: - Discovery

    func testRefreshPopulatesVPNStates() {
        let sut = VPNManager(provider: makeProvider(configs: sampleConfigs), licenseManager: makePaidLicense())

        sut.refresh()

        XCTAssertEqual(sut.vpnStates.count, 2)
        XCTAssertEqual(sut.vpnStates[0].displayName, "Rivendell")
        XCTAssertEqual(sut.vpnStates[0].id, "F5F86763-7D4E-4F9E-8D76-F746957BDCEB")
        XCTAssertEqual(sut.vpnStates[1].displayName, "Tailscale")
    }

    func testRefreshMapsProviderBundleID() {
        let sut = VPNManager(provider: makeProvider(configs: sampleConfigs), licenseManager: makePaidLicense())

        sut.refresh()

        XCTAssertEqual(sut.vpnStates[0].providerBundleIdentifier, "com.wireguard.macos")
        XCTAssertEqual(sut.vpnStates[1].providerBundleIdentifier, "io.tailscale.ipn.macsys")
    }

    // MARK: - Status Mapping

    func testRefreshMapsAllStatusCases() {
        let configs: [VPNConfigurationInfo] = [
            VPNConfigurationInfo(id: "1", displayName: "Connected", status: .connected, providerBundleIdentifier: nil),
            VPNConfigurationInfo(id: "2", displayName: "Connecting", status: .connecting, providerBundleIdentifier: nil),
            VPNConfigurationInfo(id: "3", displayName: "Disconnecting", status: .disconnecting, providerBundleIdentifier: nil),
            VPNConfigurationInfo(id: "4", displayName: "Disconnected", status: .disconnected, providerBundleIdentifier: nil),
            VPNConfigurationInfo(id: "5", displayName: "Unknown", status: .unknown, providerBundleIdentifier: nil),
        ]
        let sut = VPNManager(provider: makeProvider(configs: configs), licenseManager: makePaidLicense())

        sut.refresh()

        XCTAssertEqual(sut.vpnStates[0].status, .connected)
        XCTAssertEqual(sut.vpnStates[1].status, .connecting)
        XCTAssertEqual(sut.vpnStates[2].status, .disconnecting)
        XCTAssertEqual(sut.vpnStates[3].status, .disconnected)
        XCTAssertEqual(sut.vpnStates[4].status, .unknown)
    }

    // MARK: - Multiple Connected Warning

    func testMultipleVPNsConnectedWarning() {
        let configs: [VPNConfigurationInfo] = [
            VPNConfigurationInfo(id: "1", displayName: "VPN A", status: .connected, providerBundleIdentifier: nil),
            VPNConfigurationInfo(id: "2", displayName: "VPN B", status: .connected, providerBundleIdentifier: nil),
        ]
        let sut = VPNManager(provider: makeProvider(configs: configs), licenseManager: makePaidLicense())

        sut.refresh()

        XCTAssertTrue(sut.hasMultipleConnected)
        XCTAssertEqual(sut.connectedCount, 2)
    }

    func testSingleVPNConnectedNoWarning() {
        let sut = VPNManager(provider: makeProvider(configs: sampleConfigs), licenseManager: makePaidLicense())

        sut.refresh()

        XCTAssertFalse(sut.hasMultipleConnected)
        XCTAssertEqual(sut.connectedCount, 1)
    }

    // MARK: - Paid Gate

    func testRefreshReturnsEmptyWhenNotPaid() {
        let license = LicenseManager()
        license.isPaid = false
        let sut = VPNManager(provider: makeProvider(configs: sampleConfigs), licenseManager: license)

        sut.refresh()

        XCTAssertTrue(sut.vpnStates.isEmpty)
    }

    func testRefreshClearsExistingStatesWhenNotPaid() {
        let license = makePaidLicense()
        let sut = VPNManager(provider: makeProvider(configs: sampleConfigs), licenseManager: license)
        sut.refresh()
        XCTAssertEqual(sut.vpnStates.count, 2)

        license.isPaid = false
        sut.refresh()

        XCTAssertTrue(sut.vpnStates.isEmpty)
    }

    // MARK: - Provider Icon

    func testProviderIconMapsKnownBundleIDs() {
        XCTAssertEqual(VPNState.providerIcon(for: "com.wireguard.macos"), "shield.lefthalf.filled")
        XCTAssertEqual(VPNState.providerIcon(for: "io.tailscale.ipn.macsys"), "network.badge.shield.half.filled")
        XCTAssertEqual(VPNState.providerIcon(for: "io.tailscale.ipn.macos"), "network.badge.shield.half.filled")
    }

    func testProviderIconFallsBackForUnknown() {
        XCTAssertEqual(VPNState.providerIcon(for: "com.example.unknown"), "lock.shield")
        XCTAssertEqual(VPNState.providerIcon(for: nil), "lock.shield")
    }

    // MARK: - SystemVPNProvider.parse()

    func testParseRealScutilOutput() {
        let output = """
        Available network connection services in the current set (*=enabled):
        * (Disconnected)   F5F86763-7D4E-4F9E-8D76-F746957BDCEB VPN (com.wireguard.macos) "Rivendell"                      [VPN:com.wireguard.macos]
        * (Disconnected)   4D9D5222-38FB-46B5-B61B-09499DBB016B VPN (io.tailscale.ipn.macsys) "Tailscale"                      [VPN:io.tailscale.ipn.macsys]
        """

        let results = SystemVPNProvider.parse(output)

        XCTAssertEqual(results.count, 2)

        XCTAssertEqual(results[0].id, "F5F86763-7D4E-4F9E-8D76-F746957BDCEB")
        XCTAssertEqual(results[0].displayName, "Rivendell")
        XCTAssertEqual(results[0].status, .disconnected)
        XCTAssertEqual(results[0].providerBundleIdentifier, "com.wireguard.macos")

        XCTAssertEqual(results[1].id, "4D9D5222-38FB-46B5-B61B-09499DBB016B")
        XCTAssertEqual(results[1].displayName, "Tailscale")
        XCTAssertEqual(results[1].status, .disconnected)
        XCTAssertEqual(results[1].providerBundleIdentifier, "io.tailscale.ipn.macsys")
    }

    func testParseConnectedStatus() {
        let output = """
        * (Connected)   AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE VPN (com.example.vpn) "My VPN"  [VPN:com.example.vpn]
        """

        let results = SystemVPNProvider.parse(output)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .connected)
    }

    func testParseSkipsHeaderLine() {
        let output = "Available network connection services in the current set (*=enabled):\n"

        let results = SystemVPNProvider.parse(output)

        XCTAssertTrue(results.isEmpty)
    }

    func testParseHandlesAllStatusStrings() {
        func lineWith(status: String) -> String {
            "* (\(status))   AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE VPN (com.test) \"Test\"  [VPN:com.test]"
        }

        XCTAssertEqual(SystemVPNProvider.parse(lineWith(status: "Connected")).first?.status, .connected)
        XCTAssertEqual(SystemVPNProvider.parse(lineWith(status: "Connecting")).first?.status, .connecting)
        XCTAssertEqual(SystemVPNProvider.parse(lineWith(status: "Disconnecting")).first?.status, .disconnecting)
        XCTAssertEqual(SystemVPNProvider.parse(lineWith(status: "Disconnected")).first?.status, .disconnected)
        XCTAssertEqual(SystemVPNProvider.parse(lineWith(status: "SomethingElse")).first?.status, .unknown)
    }
}
