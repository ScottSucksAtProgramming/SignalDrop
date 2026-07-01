import XCTest
@testable import WireBar

final class SettingsStoreTests: XCTestCase {
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.scottkostolni.WireBar.tests")!
        testDefaults.removePersistentDomain(forName: "com.scottkostolni.WireBar.tests")
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.scottkostolni.WireBar.tests")
        testDefaults = nil
        super.tearDown()
    }

    func testDefaultLaunchAtLoginIsTrue() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store.launchAtLogin)
    }

    func testSetLaunchAtLoginPersists() {
        let store = SettingsStore(defaults: testDefaults)
        store.launchAtLogin = false

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store2.launchAtLogin)
    }

    func testDefaultShowNetworkNameIsTrue() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store.showNetworkName)
    }

    func testSetShowNetworkNamePersists() {
        let store = SettingsStore(defaults: testDefaults)
        store.showNetworkName = false

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store2.showNetworkName)
    }

    func testDefaultShowBandIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showBand)
    }

    func testDefaultShowChannelIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showChannel)
    }

    func testDefaultShowLinkSpeedIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showLinkSpeed)
    }

    func testDefaultShowBSSIDIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showBSSID)
    }

    func testDefaultShowDNSIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showDNS)
    }

    func testDefaultShowGatewayIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showGateway)
    }

    func testDefaultShowSubnetIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.showSubnet)
    }

    func testSetShowBandPersists() {
        let store = SettingsStore(defaults: testDefaults)
        store.showBand = true

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store2.showBand)
    }

    // MARK: - Notification Settings

    func testDefaultNotificationTogglesAreTrue() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store.notifyVPNDrop)
        XCTAssertTrue(store.notifyWiFiDisconnect)
        XCTAssertTrue(store.notifyIPChange)
    }

    func testNotificationTogglesPersist() {
        let store = SettingsStore(defaults: testDefaults)
        store.notifyVPNDrop = false
        store.notifyWiFiDisconnect = false
        store.notifyIPChange = false

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store2.notifyVPNDrop)
        XCTAssertFalse(store2.notifyWiFiDisconnect)
        XCTAssertFalse(store2.notifyIPChange)
    }

    // MARK: - Section Collapse Settings

    func testDefaultSectionCollapseIsFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.connectionInfoCollapsed)
        XCTAssertFalse(store.ipPingCollapsed)
        XCTAssertFalse(store.vpnCollapsed)
        XCTAssertFalse(store.networkListCollapsed)
    }

    func testSectionCollapsePersists() {
        let store = SettingsStore(defaults: testDefaults)
        store.connectionInfoCollapsed = true
        store.vpnCollapsed = true

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store2.connectionInfoCollapsed)
        XCTAssertTrue(store2.vpnCollapsed)
    }

    // MARK: - Menu Bar Display Settings

    func testDefaultMenuBarSettingsAreFalse() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.menuBarShowNetworkName)
        XCTAssertFalse(store.menuBarShowVPNIndicator)
        XCTAssertFalse(store.menuBarShowIP)
    }

    func testMenuBarSettingsPersist() {
        let store = SettingsStore(defaults: testDefaults)
        store.menuBarShowNetworkName = true
        store.menuBarShowIP = true

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store2.menuBarShowNetworkName)
        XCTAssertTrue(store2.menuBarShowIP)
        XCTAssertFalse(store2.menuBarShowVPNIndicator)
    }

    // MARK: - Hotkey Bindings

    func testDefaultHotkeyBindingsSeeded() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyBindings.count, HotkeyAction.defaultBindings.count)
        XCTAssertEqual(store.hotkeyBindings[HotkeyAction.togglePopover.rawValue], HotkeyAction.defaultBindings[HotkeyAction.togglePopover.rawValue])
    }

    func testHotkeyBindingsPersist() {
        let store = SettingsStore(defaults: testDefaults)
        let binding = HotkeyBinding(keyCode: 13, modifierFlags: 0x0900)
        store.hotkeyBindings = [HotkeyAction.togglePopover.rawValue: binding]

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store2.hotkeyBindings[HotkeyAction.togglePopover.rawValue], binding)
    }
}
