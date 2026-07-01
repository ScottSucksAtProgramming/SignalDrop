import XCTest
import Combine
@testable import WireBar

@MainActor
final class NotificationServiceTests: XCTestCase {

    private func makePaidLicense() -> LicenseManager {
        let license = LicenseManager()
        license.isPaid = true
        return license
    }

    private func makeSettings() -> SettingsStore {
        SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    // MARK: - VPN Drop Notifications

    func testVPNDropNotificationFires() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let vpnManager = VPNManager(provider: MockVPNConfigurationProvider(), licenseManager: license)
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)
        sut.observeVPN(vpnManager)

        let connectedProvider = MockVPNConfigurationProvider()
        connectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .connected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = connectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))

        let disconnectedProvider = MockVPNConfigurationProvider()
        disconnectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .disconnected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = disconnectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(dispatcher.dispatched.count, 1)
        XCTAssertTrue(dispatcher.dispatched[0].identifier.contains("vpn-drop"))
    }

    func testVPNDropNotificationBlockedForFreeUsers() async {
        let dispatcher = MockNotificationDispatcher()
        let license = LicenseManager()
        let settings = makeSettings()
        let vpnManager = VPNManager(provider: MockVPNConfigurationProvider(), licenseManager: makePaidLicense())
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)
        sut.observeVPN(vpnManager)

        let connectedProvider = MockVPNConfigurationProvider()
        connectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .connected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = connectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))

        let disconnectedProvider = MockVPNConfigurationProvider()
        disconnectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .disconnected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = disconnectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    func testVPNDropNotificationSuppressedByToggle() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        settings.notifyVPNDrop = false
        let vpnManager = VPNManager(provider: MockVPNConfigurationProvider(), licenseManager: license)
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)
        sut.observeVPN(vpnManager)

        let connectedProvider = MockVPNConfigurationProvider()
        connectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .connected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = connectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))

        let disconnectedProvider = MockVPNConfigurationProvider()
        disconnectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .disconnected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = disconnectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    func testNoNotificationForNonDropTransition() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let vpnManager = VPNManager(provider: MockVPNConfigurationProvider(), licenseManager: license)
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)
        sut.observeVPN(vpnManager)

        let disconnectedProvider = MockVPNConfigurationProvider()
        disconnectedProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .disconnected, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = disconnectedProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))

        let connectingProvider = MockVPNConfigurationProvider()
        connectingProvider.configurations = [
            VPNConfigurationInfo(id: "vpn-1", displayName: "TestVPN", status: .connecting, providerBundleIdentifier: nil)
        ]
        vpnManager.provider = connectingProvider
        vpnManager.refresh()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    // MARK: - Wi-Fi Disconnect Notifications

    func testWiFiDisconnectNotificationFires() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleWiFiUpdateForTesting(true)

        try? await Task.sleep(for: .milliseconds(50))

        sut.handleWiFiUpdateForTesting(false)

        try? await Task.sleep(for: .milliseconds(2200))

        XCTAssertEqual(dispatcher.dispatched.count, 1)
        XCTAssertEqual(dispatcher.dispatched[0].identifier, "wifi-disconnect")
    }

    func testWiFiDisconnectBlockedForFreeUsers() async {
        let dispatcher = MockNotificationDispatcher()
        let license = LicenseManager()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleWiFiUpdateForTesting(true)
        try? await Task.sleep(for: .milliseconds(50))
        sut.handleWiFiUpdateForTesting(false)
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    func testWiFiDisconnectSuppressedByToggle() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        settings.notifyWiFiDisconnect = false
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleWiFiUpdateForTesting(true)
        try? await Task.sleep(for: .milliseconds(50))
        sut.handleWiFiUpdateForTesting(false)
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    func testNoWiFiNotificationOnInitialState() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleWiFiUpdateForTesting(false)
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    // MARK: - IP Change Notifications

    func testIPChangeNotificationFires() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleIPUpdateForTesting(.loaded("1.2.3.4"))
        try? await Task.sleep(for: .milliseconds(50))

        sut.handleIPUpdateForTesting(.loaded("5.6.7.8"))
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(dispatcher.dispatched.count, 1)
        XCTAssertEqual(dispatcher.dispatched[0].identifier, "ip-change")
    }

    func testNoIPNotificationOnInitialFetch() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleIPUpdateForTesting(.loaded("1.2.3.4"))
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    func testIPChangeBlockedForFreeUsers() async {
        let dispatcher = MockNotificationDispatcher()
        let license = LicenseManager()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleIPUpdateForTesting(.loaded("1.2.3.4"))
        try? await Task.sleep(for: .milliseconds(50))
        sut.handleIPUpdateForTesting(.loaded("5.6.7.8"))
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    func testIPChangeSuppressedByToggle() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        settings.notifyIPChange = false
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleIPUpdateForTesting(.loaded("1.2.3.4"))
        try? await Task.sleep(for: .milliseconds(50))
        sut.handleIPUpdateForTesting(.loaded("5.6.7.8"))
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(dispatcher.dispatched.isEmpty)
    }

    // MARK: - Authorization

    func testAuthorizationRequestedOnFirstDispatch() async {
        let dispatcher = MockNotificationDispatcher()
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = NotificationService(dispatcher: dispatcher, licenseManager: license, settingsStore: settings)

        sut.handleWiFiUpdateForTesting(true)
        try? await Task.sleep(for: .milliseconds(50))
        sut.handleWiFiUpdateForTesting(false)
        try? await Task.sleep(for: .milliseconds(2200))

        XCTAssertEqual(dispatcher.authorizationCallCount, 1)

        sut.handleWiFiUpdateForTesting(true)
        try? await Task.sleep(for: .milliseconds(50))
        sut.handleWiFiUpdateForTesting(false)
        try? await Task.sleep(for: .milliseconds(2200))

        XCTAssertEqual(dispatcher.authorizationCallCount, 1)
    }
}
