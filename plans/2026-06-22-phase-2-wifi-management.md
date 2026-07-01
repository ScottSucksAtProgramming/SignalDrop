# Phase 2 — Wi-Fi Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Wi-Fi scanning, network list UI, one-click join, password input for unknown networks, Wi-Fi power toggle, Ethernet display, multi-connection support, dynamic menu bar icon, and a Settings tab for network detail visibility.

**Architecture:** WiFiManager is a new module that wraps CoreWLAN scanning/joining/power operations behind a protocol (`WiFiScanning`) for testability. It publishes a `@Published` list of `ScannedNetwork` value types. NetworkMonitor is extended with Ethernet IP and gateway info. The popover gets a network list section. AppDelegate observes NetworkMonitor state to update the menu bar icon dynamically. A new Settings tab controls which network details are visible, with advanced details gated behind `LicenseManager.isPaid`.

**Tech Stack:** Swift 6, SwiftUI, CoreWLAN (`CWWiFiClient`, `CWNetwork`, `CWNetworkProfile`), NWPathMonitor, Combine, XCTest

**Branch:** `phase/2-wifi-management` (create from `main` before any commits)

---

## File Structure

### New Files

| File | Responsibility |
|------|----------------|
| `WireBar/Sources/Protocols/WiFiScanning.swift` | Protocol abstracting CoreWLAN scan/join/power/known-networks for testability |
| `WireBar/Sources/Models/ScannedNetwork.swift` | Value type representing a discovered Wi-Fi network (ssid, rssi, security, isKnown, isCurrent) |
| `WireBar/Sources/Services/WiFiManager/WiFiManager.swift` | Scans for networks, sorts them, joins networks, toggles Wi-Fi power |
| `WireBar/Sources/UI/Popover/NetworkListView.swift` | Network list section: signal bars, security badges, checkmark on current, tap to join |
| `WireBar/Sources/UI/Popover/PasswordInputView.swift` | Inline password field shown when joining an unknown network |
| `WireBar/Sources/UI/Popover/ConnectionInfoView.swift` | Extracted connection header + detail rows (from current PopoverView) |
| `WireBar/Sources/UI/Popover/EthernetInfoView.swift` | Ethernet connection details (IP, gateway) shown when wired connection active |
| `WireBar/Sources/UI/Settings/NetworkDetailsSettingsView.swift` | Settings tab: toggles for which network details appear in popover |
| `WireBarTests/WiFiManagerTests.swift` | Unit tests for WiFiManager |
| `WireBarTests/Mocks/MockWiFiScanner.swift` | Mock implementation of WiFiScanning protocol |

### Modified Files

| File | Changes |
|------|---------|
| `WireBar/Sources/Models/NetworkState.swift` | Add `ethernetIPAddress`, `gatewayAddress`, `dnsServers`, `subnetMask`, `primaryInterface` fields |
| `WireBar/Sources/Services/NetworkMonitor/NetworkMonitor.swift` | Extract Ethernet IP + gateway + DNS + subnet; track primary interface |
| `WireBar/Sources/UI/Popover/PopoverView.swift` | Integrate NetworkListView, ConnectionInfoView, EthernetInfoView; add Wi-Fi toggle |
| `WireBar/Sources/App/AppDelegate.swift` | Observe NetworkMonitor state to update menu bar icon dynamically; create and inject WiFiManager |
| `WireBar/Sources/Services/SettingsStore/SettingsStore.swift` | Add detail visibility settings (showBand, showChannel, showLinkSpeed, showBSSID, showDNS, showGateway, showSubnet) |
| `WireBar/Sources/UI/Settings/SettingsView.swift` | Add "Network Details" tab |
| `WireBarTests/NetworkMonitorTests.swift` | Add tests for Ethernet state handling |
| `project.yml` | No changes needed (sources are auto-discovered from WireBar/Sources) |

---

## Task 1: Create Branch and ScannedNetwork Model

**Files:**
- Create: `WireBar/Sources/Models/ScannedNetwork.swift`

- [ ] **Step 1: Create the phase branch**

```bash
git checkout -b phase/2-wifi-management main
```

- [ ] **Step 2: Create ScannedNetwork model**

Create `WireBar/Sources/Models/ScannedNetwork.swift`:

```swift
import Foundation

struct ScannedNetwork: Identifiable, Sendable {
    let id: String
    let ssid: String
    let bssid: String?
    let rssi: Int
    let channelNumber: Int?
    let securityType: NetworkSecurityType
    let isKnown: Bool
    var isCurrent: Bool

    var signalQuality: SignalQuality {
        switch rssi {
        case -50...0: return .excellent
        case -60...(-51): return .good
        case -70...(-61): return .fair
        default: return .poor
        }
    }
}

enum NetworkSecurityType: Sendable {
    case open
    case wpa
    case wpa2
    case wpa3
    case wpaEnterprise
    case wpa2Enterprise
    case wpa3Enterprise
    case unknown

    var displayName: String {
        switch self {
        case .open: return String(localized: "Open")
        case .wpa: return String(localized: "WPA")
        case .wpa2: return String(localized: "WPA2")
        case .wpa3: return String(localized: "WPA3")
        case .wpaEnterprise: return String(localized: "WPA Enterprise")
        case .wpa2Enterprise: return String(localized: "WPA2 Enterprise")
        case .wpa3Enterprise: return String(localized: "WPA3 Enterprise")
        case .unknown: return String(localized: "Secured")
        }
    }

    var isSecured: Bool {
        self != .open
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add WireBar/Sources/Models/ScannedNetwork.swift
git commit -m "feat: add ScannedNetwork model and NetworkSecurityType enum"
```

---

## Task 2: Create WiFiScanning Protocol

**Files:**
- Create: `WireBar/Sources/Protocols/WiFiScanning.swift`

- [ ] **Step 1: Create WiFiScanning protocol**

Create `WireBar/Sources/Protocols/WiFiScanning.swift`:

```swift
import Foundation

protocol WiFiScanning {
    func scanForNetworks() throws -> [ScannedNetwork]
    func knownNetworkSSIDs() -> Set<String>
    func associateToNetwork(bssid: String, password: String?) throws
    func setPower(_ on: Bool) throws
    func isPoweredOn() -> Bool
    func currentSSID() -> String?
}
```

- [ ] **Step 2: Build to verify it compiles**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add WireBar/Sources/Protocols/WiFiScanning.swift
git commit -m "feat: add WiFiScanning protocol for CoreWLAN abstraction"
```

---

## Task 3: Create Mock and WiFiManager Tests

**Files:**
- Create: `WireBarTests/Mocks/MockWiFiScanner.swift`
- Create: `WireBarTests/WiFiManagerTests.swift`

- [ ] **Step 1: Create MockWiFiScanner**

Create `WireBarTests/Mocks/MockWiFiScanner.swift`:

```swift
import Foundation
@testable import WireBar

final class MockWiFiScanner: WiFiScanning {
    var networksToReturn: [ScannedNetwork] = []
    var knownSSIDs: Set<String> = []
    var isPowered: Bool = true
    var currentSSIDValue: String? = "HomeNetwork"
    var associateCalledWith: (bssid: String, password: String?)? = nil
    var setPowerCalledWith: Bool? = nil
    var scanShouldThrow: Bool = false
    var associateShouldThrow: Bool = false

    func scanForNetworks() throws -> [ScannedNetwork] {
        if scanShouldThrow {
            throw NSError(domain: "CoreWLAN", code: -3931, userInfo: [NSLocalizedDescriptionKey: "Scan failed"])
        }
        return networksToReturn
    }

    func knownNetworkSSIDs() -> Set<String> {
        return knownSSIDs
    }

    func associateToNetwork(bssid: String, password: String?) throws {
        if associateShouldThrow {
            throw NSError(domain: "CoreWLAN", code: -3905, userInfo: [NSLocalizedDescriptionKey: "Association failed"])
        }
        associateCalledWith = (bssid, password)
    }

    func setPower(_ on: Bool) throws {
        setPowerCalledWith = on
        isPowered = on
    }

    func isPoweredOn() -> Bool {
        return isPowered
    }

    func currentSSID() -> String? {
        return currentSSIDValue
    }
}
```

- [ ] **Step 2: Write failing WiFiManager tests**

Create `WireBarTests/WiFiManagerTests.swift`:

```swift
import XCTest
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

        XCTAssertTrue(sut.networks.first { $0.ssid == "HomeNetwork" }!.isCurrent)
        XCTAssertFalse(sut.networks.first { $0.ssid == "Other" }!.isCurrent)
    }

    func testScanFiltersOutNilSSIDNetworks() {
        mockScanner.networksToReturn = [
            makeNetwork(ssid: "Visible", rssi: -50, isKnown: false),
        ]

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()

        XCTAssertEqual(sut.networks.count, 1)
        XCTAssertEqual(sut.networks[0].ssid, "Visible")
    }

    func testScanFailureSetsErrorState() {
        mockScanner.scanShouldThrow = true

        let sut = WiFiManager(scanner: mockScanner)
        sut.scan()

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
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(Test Case|BUILD|error:)" | head -20
```

Expected: FAIL — `WiFiManager` type does not exist

- [ ] **Step 4: Commit failing tests**

```bash
git add WireBarTests/Mocks/MockWiFiScanner.swift WireBarTests/WiFiManagerTests.swift
git commit -m "test: add failing WiFiManager tests with MockWiFiScanner"
```

---

## Task 4: Implement WiFiManager

**Files:**
- Create: `WireBar/Sources/Services/WiFiManager/WiFiManager.swift`

- [ ] **Step 1: Implement WiFiManager**

Create `WireBar/Sources/Services/WiFiManager/WiFiManager.swift`:

```swift
import Foundation
import CoreWLAN
import Combine

final class WiFiManager: ObservableObject {
    @Published private(set) var networks: [ScannedNetwork] = []
    @Published private(set) var isWiFiPoweredOn: Bool = true
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var scanError: Error?
    @Published private(set) var joinError: Error?

    private let scanner: WiFiScanning

    init(scanner: WiFiScanning = CoreWLANScanner()) {
        self.scanner = scanner
        self.isWiFiPoweredOn = scanner.isPoweredOn()
    }

    func scan() {
        isScanning = true
        scanError = nil

        do {
            var scanned = try scanner.scanForNetworks()
            let currentSSID = scanner.currentSSID()

            scanned = scanned.map { network in
                var n = network
                n.isCurrent = (network.ssid == currentSSID)
                return n
            }

            let known = scanned.filter(\.isKnown).sorted { $0.rssi > $1.rssi }
            let other = scanned.filter { !$0.isKnown }.sorted { $0.rssi > $1.rssi }
            networks = known + other
        } catch {
            scanError = error
            networks = []
        }

        isScanning = false
    }

    func joinNetwork(_ network: ScannedNetwork, password: String?) {
        joinError = nil
        guard let bssid = network.bssid else { return }

        do {
            try scanner.associateToNetwork(bssid: bssid, password: password)
        } catch {
            joinError = error
        }
    }

    func togglePower() {
        let newState = !isWiFiPoweredOn
        do {
            try scanner.setPower(newState)
            isWiFiPoweredOn = newState
        } catch {
            // Power toggle failed — state unchanged
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(Test Case|BUILD|Executed)" | head -20
```

Expected: All WiFiManagerTests pass, BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add WireBar/Sources/Services/WiFiManager/WiFiManager.swift
git commit -m "feat: implement WiFiManager with scan, join, and power toggle"
```

---

## Task 5: Implement CoreWLANScanner (Real CoreWLAN Adapter)

**Files:**
- Create: `WireBar/Sources/Services/WiFiManager/CoreWLANScanner.swift`

- [ ] **Step 1: Implement CoreWLANScanner**

Create `WireBar/Sources/Services/WiFiManager/CoreWLANScanner.swift`:

```swift
import Foundation
import CoreWLAN

final class CoreWLANScanner: WiFiScanning {
    private let client: CWWiFiClient
    private var interface: CWInterface? { client.interface() }

    init(client: CWWiFiClient = .shared()) {
        self.client = client
    }

    func scanForNetworks() throws -> [ScannedNetwork] {
        guard let iface = interface else { return [] }
        let cwNetworks = try iface.scanForNetworks(withName: nil)
        let known = knownNetworkSSIDs()

        return cwNetworks.compactMap { network -> ScannedNetwork? in
            guard let ssid = network.ssid, !ssid.isEmpty else { return nil }
            return ScannedNetwork(
                id: network.bssid ?? ssid,
                ssid: ssid,
                bssid: network.bssid,
                rssi: network.rssiValue,
                channelNumber: network.wlanChannel?.channelNumber,
                securityType: securityType(for: network),
                isKnown: known.contains(ssid),
                isCurrent: false
            )
        }
    }

    func knownNetworkSSIDs() -> Set<String> {
        guard let config = interface?.configuration(),
              let profiles = config.networkProfiles else {
            return []
        }
        var ssids = Set<String>()
        for case let profile as CWNetworkProfile in profiles {
            if let ssid = profile.ssid {
                ssids.insert(ssid)
            }
        }
        return ssids
    }

    func associateToNetwork(bssid: String, password: String?) throws {
        guard let iface = interface else { return }
        let networks = try iface.scanForNetworks(withName: nil)
        guard let target = networks.first(where: { $0.bssid == bssid }) else {
            throw NSError(
                domain: "WiFiManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Network not found"]
            )
        }
        try iface.associate(to: target, password: password)
    }

    func setPower(_ on: Bool) throws {
        guard let iface = interface else { return }
        try iface.setPower(on)
    }

    func isPoweredOn() -> Bool {
        interface?.powerOn() ?? false
    }

    func currentSSID() -> String? {
        interface?.ssid()
    }

    private func securityType(for network: CWNetwork) -> NetworkSecurityType {
        if network.supportsSecurity(.wpa3Personal) { return .wpa3 }
        if network.supportsSecurity(.wpa3Enterprise) { return .wpa3Enterprise }
        if network.supportsSecurity(.wpa2Personal) { return .wpa2 }
        if network.supportsSecurity(.wpa2Enterprise) { return .wpa2Enterprise }
        if network.supportsSecurity(.wpaPersonal) { return .wpa }
        if network.supportsSecurity(.wpaEnterprise) { return .wpaEnterprise }
        if network.supportsSecurity(.none) { return .open }
        return .unknown
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests to check nothing broke**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(Executed|BUILD)" | tail -3
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add WireBar/Sources/Services/WiFiManager/CoreWLANScanner.swift
git commit -m "feat: implement CoreWLANScanner wrapping real CoreWLAN APIs"
```

---

## Task 6: Extend NetworkState for Ethernet and Multi-Connection Details

**Files:**
- Modify: `WireBar/Sources/Models/NetworkState.swift`
- Modify: `WireBar/Sources/Services/NetworkMonitor/NetworkMonitor.swift`
- Modify: `WireBarTests/NetworkMonitorTests.swift`

- [ ] **Step 1: Write tests for new Ethernet state fields**

Add to `WireBarTests/NetworkMonitorTests.swift`:

```swift
func testInitialEthernetFieldsAreNil() {
    let sut = NetworkMonitor(pathMonitor: MockPathMonitor())
    XCTAssertNil(sut.state.ethernetIPAddress)
    XCTAssertNil(sut.state.gatewayAddress)
    XCTAssertNil(sut.state.subnetMask)
    XCTAssertTrue(sut.state.dnsServers.isEmpty)
    XCTAssertNil(sut.state.primaryInterface)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(error:|FAIL)" | head -10
```

Expected: FAIL — `ethernetIPAddress`, `gatewayAddress`, etc. do not exist on NetworkState

- [ ] **Step 3: Extend NetworkState**

Edit `WireBar/Sources/Models/NetworkState.swift` — add new fields after `isWiFiPoweredOn`:

```swift
var ethernetIPAddress: String?
var gatewayAddress: String?
var subnetMask: String?
var dnsServers: [String] = []
var primaryInterface: String?
var linkSpeed: Double = 0
```

- [ ] **Step 4: Extend NetworkMonitor to populate new fields**

In `WireBar/Sources/Services/NetworkMonitor/NetworkMonitor.swift`, update `handlePathUpdate` to track the primary interface and extract Ethernet IP. Replace `handlePathUpdate` with:

```swift
private func handlePathUpdate(_ path: NWPath) {
    let isConnected = path.status == .satisfied
    let hasWifi = path.usesInterfaceType(.wifi)
    let hasEthernet = path.usesInterfaceType(.wiredEthernet)

    let connectionType: ConnectionType = {
        switch (hasWifi, hasEthernet) {
        case (true, true): return .wifiAndEthernet
        case (true, false): return .wifi
        case (false, true): return .ethernet
        case (false, false): return .none
        }
    }()

    let primaryIface: String? = {
        if let first = path.availableInterfaces.first {
            return first.name
        }
        return nil
    }()

    let ethernetIP: String? = hasEthernet ? Self.getIPAddress(forInterface: "en0") ?? Self.getIPAddress(forInterface: "en1") : nil

    DispatchQueue.main.async { [weak self] in
        self?.state.isConnected = isConnected
        self?.state.connectionType = connectionType
        self?.state.isEthernetConnected = hasEthernet
        self?.state.primaryInterface = primaryIface
        self?.state.ethernetIPAddress = ethernetIP
    }

    if hasWifi {
        refreshWiFiInfo()
    }
}
```

Also refactor `getLocalIPAddress` to accept an interface name parameter. Replace the existing static method with:

```swift
static func getIPAddress(forInterface targetName: String? = nil) -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
    defer { freeifaddrs(ifaddr) }

    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let iface = ptr.pointee
        let addrFamily = iface.ifa_addr.pointee.sa_family
        guard addrFamily == UInt8(AF_INET) else { continue }

        let name = String(cString: iface.ifa_name)
        if let target = targetName {
            guard name == target else { continue }
        } else {
            guard name == "en0" || name == "en1" else { continue }
        }

        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(
            iface.ifa_addr, socklen_t(iface.ifa_addr.pointee.sa_len),
            &hostname, socklen_t(hostname.count),
            nil, 0, NI_NUMERICHOST
        ) == 0 {
            address = String(cString: hostname)
            break
        }
    }
    return address
}
```

Update `refreshWiFiInfo()` to call `Self.getIPAddress()` (no change to the call site since the parameter is optional).

- [ ] **Step 5: Run tests to verify they pass**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(Executed|BUILD)" | tail -3
```

Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add WireBar/Sources/Models/NetworkState.swift WireBar/Sources/Services/NetworkMonitor/NetworkMonitor.swift WireBarTests/NetworkMonitorTests.swift
git commit -m "feat: extend NetworkState with Ethernet IP, gateway, DNS, primary interface"
```

---

## Task 7: Add Network Detail Visibility Settings

**Files:**
- Modify: `WireBar/Sources/Services/SettingsStore/SettingsStore.swift`
- Modify: `WireBarTests/SettingsStoreTests.swift`

- [ ] **Step 1: Write failing tests for new settings**

Add to `WireBarTests/SettingsStoreTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(error:|FAIL)" | head -10
```

Expected: FAIL — properties don't exist

- [ ] **Step 3: Add settings to SettingsStore**

Edit `WireBar/Sources/Services/SettingsStore/SettingsStore.swift`. Add the new properties after `showSignalStrength`, following the same pattern:

```swift
@Published var showBand: Bool = false {
    didSet { defaults.set(showBand, forKey: Keys.showBand) }
}

@Published var showChannel: Bool = false {
    didSet { defaults.set(showChannel, forKey: Keys.showChannel) }
}

@Published var showLinkSpeed: Bool = false {
    didSet { defaults.set(showLinkSpeed, forKey: Keys.showLinkSpeed) }
}

@Published var showBSSID: Bool = false {
    didSet { defaults.set(showBSSID, forKey: Keys.showBSSID) }
}

@Published var showDNS: Bool = false {
    didSet { defaults.set(showDNS, forKey: Keys.showDNS) }
}

@Published var showGateway: Bool = false {
    didSet { defaults.set(showGateway, forKey: Keys.showGateway) }
}

@Published var showSubnet: Bool = false {
    didSet { defaults.set(showSubnet, forKey: Keys.showSubnet) }
}
```

Add to `loadSettings()`:

```swift
if defaults.object(forKey: Keys.showBand) != nil {
    showBand = defaults.bool(forKey: Keys.showBand)
}
if defaults.object(forKey: Keys.showChannel) != nil {
    showChannel = defaults.bool(forKey: Keys.showChannel)
}
if defaults.object(forKey: Keys.showLinkSpeed) != nil {
    showLinkSpeed = defaults.bool(forKey: Keys.showLinkSpeed)
}
if defaults.object(forKey: Keys.showBSSID) != nil {
    showBSSID = defaults.bool(forKey: Keys.showBSSID)
}
if defaults.object(forKey: Keys.showDNS) != nil {
    showDNS = defaults.bool(forKey: Keys.showDNS)
}
if defaults.object(forKey: Keys.showGateway) != nil {
    showGateway = defaults.bool(forKey: Keys.showGateway)
}
if defaults.object(forKey: Keys.showSubnet) != nil {
    showSubnet = defaults.bool(forKey: Keys.showSubnet)
}
```

Add to `Keys` enum:

```swift
static let showBand = "showBand"
static let showChannel = "showChannel"
static let showLinkSpeed = "showLinkSpeed"
static let showBSSID = "showBSSID"
static let showDNS = "showDNS"
static let showGateway = "showGateway"
static let showSubnet = "showSubnet"
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(Executed|BUILD)" | tail -3
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add WireBar/Sources/Services/SettingsStore/SettingsStore.swift WireBarTests/SettingsStoreTests.swift
git commit -m "feat: add network detail visibility settings to SettingsStore"
```

---

## Task 8: Create Network Details Settings Tab (UI)

**Files:**
- Create: `WireBar/Sources/UI/Settings/NetworkDetailsSettingsView.swift`
- Modify: `WireBar/Sources/UI/Settings/SettingsView.swift`
- Modify: `WireBar/Sources/App/WireBarApp.swift`

- [ ] **Step 1: Create NetworkDetailsSettingsView**

Create `WireBar/Sources/UI/Settings/NetworkDetailsSettingsView.swift`:

```swift
import SwiftUI

struct NetworkDetailsSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    private var isLocked: Bool { !licenseManager.isPaid }

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Network name (SSID)"), isOn: $settingsStore.showNetworkName)
                    .accessibilityLabel(String(localized: "Show network name"))
                Toggle(String(localized: "Signal strength"), isOn: $settingsStore.showSignalStrength)
                    .accessibilityLabel(String(localized: "Show signal strength"))
            } header: {
                Text(String(localized: "Basic Details"))
            }

            Section {
                advancedToggle(String(localized: "Band / Frequency"), isOn: $settingsStore.showBand)
                    .accessibilityLabel(String(localized: "Show band and frequency"))
                advancedToggle(String(localized: "Channel"), isOn: $settingsStore.showChannel)
                    .accessibilityLabel(String(localized: "Show channel number"))
                advancedToggle(String(localized: "Link speed"), isOn: $settingsStore.showLinkSpeed)
                    .accessibilityLabel(String(localized: "Show link speed"))
                advancedToggle(String(localized: "BSSID"), isOn: $settingsStore.showBSSID)
                    .accessibilityLabel(String(localized: "Show BSSID"))
                advancedToggle(String(localized: "DNS servers"), isOn: $settingsStore.showDNS)
                    .accessibilityLabel(String(localized: "Show DNS servers"))
                advancedToggle(String(localized: "Gateway"), isOn: $settingsStore.showGateway)
                    .accessibilityLabel(String(localized: "Show gateway address"))
                advancedToggle(String(localized: "Subnet mask"), isOn: $settingsStore.showSubnet)
                    .accessibilityLabel(String(localized: "Show subnet mask"))
            } header: {
                HStack {
                    Text(String(localized: "Advanced Details"))
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(String(localized: "Requires paid upgrade"))
                    }
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func advancedToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .disabled(isLocked)
    }
}
```

- [ ] **Step 2: Update SettingsView to add Network Details tab**

Replace the contents of `WireBar/Sources/UI/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    var body: some View {
        TabView {
            GeneralSettingsView(settingsStore: settingsStore)
                .tabItem {
                    Label(String(localized: "General"), systemImage: "gear")
                }
            NetworkDetailsSettingsView(settingsStore: settingsStore, licenseManager: licenseManager)
                .tabItem {
                    Label(String(localized: "Network Details"), systemImage: "network")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        Form {
            Toggle(String(localized: "Launch at login"), isOn: $settingsStore.launchAtLogin)
                .accessibilityLabel(String(localized: "Launch WireBar when you log in"))
        }
        .padding()
    }
}
```

- [ ] **Step 3: Update WireBarApp to pass dependencies to SettingsView**

Replace the contents of `WireBar/Sources/App/WireBarApp.swift`:

```swift
import SwiftUI

@main
struct WireBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settingsStore: appDelegate.settingsStore,
                licenseManager: appDelegate.licenseManager
            )
        }
    }
}
```

Note: This requires `settingsStore` and `licenseManager` to be accessible on AppDelegate. We'll update AppDelegate in Task 12 when wiring everything together.

- [ ] **Step 4: Build to verify (may have build errors until Task 12 wires AppDelegate — that's expected)**

If the build fails because AppDelegate properties are private, temporarily change `settingsStore` and `licenseManager` from `private let` to `let` in AppDelegate. We'll do the full AppDelegate update in Task 12.

- [ ] **Step 5: Commit**

```bash
git add WireBar/Sources/UI/Settings/NetworkDetailsSettingsView.swift WireBar/Sources/UI/Settings/SettingsView.swift WireBar/Sources/App/WireBarApp.swift
git commit -m "feat: add Network Details settings tab with paid-tier gating"
```

---

## Task 9: Extract ConnectionInfoView from PopoverView

**Files:**
- Create: `WireBar/Sources/UI/Popover/ConnectionInfoView.swift`

- [ ] **Step 1: Create ConnectionInfoView**

This extracts the connection header and network details from PopoverView into its own view, now respecting SettingsStore visibility toggles.

Create `WireBar/Sources/UI/Popover/ConnectionInfoView.swift`:

```swift
import SwiftUI

struct ConnectionInfoView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            connectionHeader
            Divider()
            networkDetails
        }
    }

    @ViewBuilder
    private var connectionHeader: some View {
        HStack {
            Image(systemName: statusIconName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                if settingsStore.showNetworkName {
                    Text(networkName)
                        .font(.headline)
                        .accessibilityLabel(networkNameAccessibilityLabel)
                }

                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if networkMonitor.state.connectionType == .wifi || networkMonitor.state.connectionType == .wifiAndEthernet {
                signalBars
            }
        }
    }

    @ViewBuilder
    private var networkDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ip = networkMonitor.state.localIPAddress {
                DetailRow(
                    label: String(localized: "Local IP"),
                    value: ip
                )
            }

            if settingsStore.showSignalStrength && networkMonitor.state.signalStrength != 0 {
                DetailRow(
                    label: String(localized: "Signal"),
                    value: "\(networkMonitor.state.signalStrength) dBm (\(signalPercentage)%)"
                )
            }

            if settingsStore.showChannel, let channel = networkMonitor.state.channelNumber {
                DetailRow(
                    label: String(localized: "Channel"),
                    value: "\(channel)"
                )
            }

            if settingsStore.showBand, let band = networkMonitor.state.channelBand, band != .unknown {
                DetailRow(
                    label: String(localized: "Band"),
                    value: bandDisplayName(band)
                )
            }

            if settingsStore.showLinkSpeed && networkMonitor.state.transmitRate > 0 {
                DetailRow(
                    label: String(localized: "Link Speed"),
                    value: String(localized: "\(Int(networkMonitor.state.transmitRate)) Mbps")
                )
            }

            if settingsStore.showBSSID, let bssid = networkMonitor.state.bssid {
                DetailRow(
                    label: String(localized: "BSSID"),
                    value: bssid
                )
            }

            if settingsStore.showGateway, let gateway = networkMonitor.state.gatewayAddress {
                DetailRow(
                    label: String(localized: "Gateway"),
                    value: gateway
                )
            }

            if settingsStore.showSubnet, let subnet = networkMonitor.state.subnetMask {
                DetailRow(
                    label: String(localized: "Subnet"),
                    value: subnet
                )
            }

            if settingsStore.showDNS && !networkMonitor.state.dnsServers.isEmpty {
                DetailRow(
                    label: String(localized: "DNS"),
                    value: networkMonitor.state.dnsServers.joined(separator: ", ")
                )
            }
        }
    }

    @ViewBuilder
    private var signalBars: some View {
        let quality = networkMonitor.state.signalQuality
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: index, quality: quality))
                    .frame(width: 4, height: CGFloat(6 + index * 4))
            }
        }
        .accessibilityLabel(signalAccessibilityLabel)
    }

    private var signalPercentage: Int {
        let clamped = min(max(networkMonitor.state.signalStrength, -100), -20)
        return Int(Double(clamped + 100) / 80.0 * 100.0)
    }

    private var networkName: String {
        if let ssid = networkMonitor.state.ssid {
            return ssid
        }
        if networkMonitor.state.isConnected {
            return switch networkMonitor.state.connectionType {
            case .ethernet, .wifiAndEthernet: String(localized: "Ethernet")
            case .wifi: String(localized: "Wi-Fi Connected")
            case .none: String(localized: "Not Connected")
            }
        }
        return String(localized: "Not Connected")
    }

    private var networkNameAccessibilityLabel: String {
        if let ssid = networkMonitor.state.ssid {
            return String(localized: "Connected to \(ssid)")
        }
        if networkMonitor.state.isConnected {
            return String(localized: "Connected via \(connectionStatusText)")
        }
        return String(localized: "Not connected to any network")
    }

    private var statusIconName: String {
        if !networkMonitor.state.isWiFiPoweredOn && networkMonitor.state.connectionType != .ethernet {
            return "wifi.slash"
        }
        switch networkMonitor.state.connectionType {
        case .none: return "wifi.slash"
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector.horizontal"
        case .wifiAndEthernet: return "wifi"
        }
    }

    private var statusColor: Color {
        networkMonitor.state.isConnected ? .green : .secondary
    }

    private var connectionStatusText: String {
        if !networkMonitor.state.isWiFiPoweredOn && networkMonitor.state.connectionType == .none {
            return String(localized: "Wi-Fi Off")
        }
        switch networkMonitor.state.connectionType {
        case .none: return String(localized: "Disconnected")
        case .wifi: return String(localized: "Wi-Fi")
        case .ethernet: return String(localized: "Ethernet")
        case .wifiAndEthernet: return String(localized: "Wi-Fi + Ethernet")
        }
    }

    private var signalAccessibilityLabel: String {
        switch networkMonitor.state.signalQuality {
        case .excellent: return String(localized: "Signal strength: excellent")
        case .good: return String(localized: "Signal strength: good")
        case .fair: return String(localized: "Signal strength: fair")
        case .poor: return String(localized: "Signal strength: poor")
        }
    }

    private func barColor(for index: Int, quality: SignalQuality) -> Color {
        let filledBars: Int = {
            switch quality {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .poor: return 1
            }
        }()
        return index < filledBars ? .primary : .secondary.opacity(0.3)
    }

    private func bandDisplayName(_ band: WLANChannelBand) -> String {
        switch band {
        case .band2GHz: return String(localized: "2.4 GHz")
        case .band5GHz: return String(localized: "5 GHz")
        case .band6GHz: return String(localized: "6 GHz")
        case .unknown: return String(localized: "Unknown")
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add WireBar/Sources/UI/Popover/ConnectionInfoView.swift
git commit -m "feat: extract ConnectionInfoView with configurable detail visibility"
```

---

## Task 10: Create EthernetInfoView

**Files:**
- Create: `WireBar/Sources/UI/Popover/EthernetInfoView.swift`

- [ ] **Step 1: Create EthernetInfoView**

Create `WireBar/Sources/UI/Popover/EthernetInfoView.swift`:

```swift
import SwiftUI

struct EthernetInfoView: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "cable.connector.horizontal")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text(String(localized: "Ethernet"))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if networkMonitor.state.primaryInterface?.hasPrefix("en") == true &&
                   networkMonitor.state.connectionType == .ethernet {
                    Text(String(localized: "Primary"))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .clipShape(Capsule())
                        .accessibilityLabel(String(localized: "Primary network route"))
                }
            }

            if let ip = networkMonitor.state.ethernetIPAddress {
                DetailRow(
                    label: String(localized: "IP Address"),
                    value: ip
                )
            }

            if let gateway = networkMonitor.state.gatewayAddress {
                DetailRow(
                    label: String(localized: "Gateway"),
                    value: gateway
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Ethernet connection details"))
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add WireBar/Sources/UI/Popover/EthernetInfoView.swift
git commit -m "feat: add EthernetInfoView for wired connection details"
```

---

## Task 11: Create NetworkListView and PasswordInputView

**Files:**
- Create: `WireBar/Sources/UI/Popover/NetworkListView.swift`
- Create: `WireBar/Sources/UI/Popover/PasswordInputView.swift`

- [ ] **Step 1: Create PasswordInputView**

Create `WireBar/Sources/UI/Popover/PasswordInputView.swift`:

```swift
import SwiftUI

struct PasswordInputView: View {
    let networkName: String
    let onJoin: (String) -> Void
    let onCancel: () -> Void

    @State private var password: String = ""
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Enter password for \"\(networkName)\""))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                SecureField(String(localized: "Password"), text: $password)
                    .textFieldStyle(.roundedBorder)
                    .focused($isPasswordFocused)
                    .onSubmit {
                        if !password.isEmpty {
                            onJoin(password)
                        }
                    }
                    .accessibilityLabel(String(localized: "Wi-Fi password for \(networkName)"))

                Button(String(localized: "Join")) {
                    onJoin(password)
                }
                .disabled(password.isEmpty)
                .accessibilityLabel(String(localized: "Join \(networkName)"))

                Button(String(localized: "Cancel")) {
                    onCancel()
                }
                .accessibilityLabel(String(localized: "Cancel joining network"))
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            isPasswordFocused = true
        }
    }
}
```

- [ ] **Step 2: Create NetworkListView**

Create `WireBar/Sources/UI/Popover/NetworkListView.swift`:

```swift
import SwiftUI

struct NetworkListView: View {
    @ObservedObject var wifiManager: WiFiManager
    @State private var networkAwaitingPassword: ScannedNetwork?
    @State private var showJoinError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(localized: "Wi-Fi Networks"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if wifiManager.isScanning {
                    ProgressView()
                        .scaleEffect(0.6)
                        .accessibilityLabel(String(localized: "Scanning for networks"))
                } else {
                    Button {
                        wifiManager.scan()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(String(localized: "Refresh network list"))
                }
            }

            if let error = wifiManager.scanError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel(String(localized: "Scan error: \(error.localizedDescription)"))
            }

            if wifiManager.networks.isEmpty && !wifiManager.isScanning {
                Text(String(localized: "No networks found"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(wifiManager.networks) { network in
                        networkRow(network)
                        if network.id != wifiManager.networks.last?.id {
                            Divider().padding(.leading, 24)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            if let network = networkAwaitingPassword {
                PasswordInputView(
                    networkName: network.ssid,
                    onJoin: { password in
                        wifiManager.joinNetwork(network, password: password)
                        networkAwaitingPassword = nil
                        if wifiManager.joinError != nil {
                            showJoinError = true
                        }
                    },
                    onCancel: {
                        networkAwaitingPassword = nil
                    }
                )
            }

            if showJoinError, let error = wifiManager.joinError {
                Text(String(localized: "Failed to join: \(error.localizedDescription)"))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showJoinError = false
                        }
                    }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Available Wi-Fi networks"))
    }

    @ViewBuilder
    private func networkRow(_ network: ScannedNetwork) -> some View {
        Button {
            handleNetworkTap(network)
        } label: {
            HStack(spacing: 8) {
                signalIcon(for: network)
                    .frame(width: 16)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(network.ssid)
                        .font(.caption)
                        .fontWeight(network.isCurrent ? .semibold : .regular)
                        .lineLimit(1)

                    if network.isKnown {
                        Text(String(localized: "Known Network"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if network.securityType.isSecured {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(network.securityType.displayName)
                }

                Text(network.securityType.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if network.isCurrent {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .accessibilityLabel(String(localized: "Currently connected"))
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(networkAccessibilityLabel(for: network))
        .accessibilityHint(network.isCurrent ? "" : String(localized: "Double-tap to join"))
    }

    @ViewBuilder
    private func signalIcon(for network: ScannedNetwork) -> some View {
        let quality = network.signalQuality
        HStack(spacing: 1) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(miniBarColor(for: index, quality: quality))
                    .frame(width: 2, height: CGFloat(3 + index * 2))
            }
        }
    }

    private func miniBarColor(for index: Int, quality: SignalQuality) -> Color {
        let filledBars: Int = switch quality {
        case .excellent: 4
        case .good: 3
        case .fair: 2
        case .poor: 1
        }
        return index < filledBars ? .primary : .secondary.opacity(0.3)
    }

    private func networkAccessibilityLabel(for network: ScannedNetwork) -> String {
        var parts = [network.ssid]
        parts.append(String(localized: "Signal \(network.signalQuality.accessibilityName)"))
        parts.append(network.securityType.displayName)
        if network.isKnown { parts.append(String(localized: "Known network")) }
        if network.isCurrent { parts.append(String(localized: "Currently connected")) }
        return parts.joined(separator: ", ")
    }

    private func handleNetworkTap(_ network: ScannedNetwork) {
        guard !network.isCurrent else { return }

        if network.isKnown || !network.securityType.isSecured {
            wifiManager.joinNetwork(network, password: nil)
            if wifiManager.joinError != nil {
                showJoinError = true
            }
        } else {
            networkAwaitingPassword = network
        }
    }
}

extension SignalQuality {
    var accessibilityName: String {
        switch self {
        case .excellent: return String(localized: "excellent")
        case .good: return String(localized: "good")
        case .fair: return String(localized: "fair")
        case .poor: return String(localized: "poor")
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add WireBar/Sources/UI/Popover/NetworkListView.swift WireBar/Sources/UI/Popover/PasswordInputView.swift
git commit -m "feat: add NetworkListView with signal indicators, security badges, and password input"
```

---

## Task 12: Rewrite PopoverView and Update AppDelegate

**Files:**
- Modify: `WireBar/Sources/UI/Popover/PopoverView.swift`
- Modify: `WireBar/Sources/App/AppDelegate.swift`

- [ ] **Step 1: Rewrite PopoverView to integrate all new views**

Replace the contents of `WireBar/Sources/UI/Popover/PopoverView.swift`:

```swift
import SwiftUI

struct PopoverView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var wifiManager: WiFiManager
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConnectionInfoView(
                networkMonitor: networkMonitor,
                settingsStore: settingsStore
            )

            if networkMonitor.state.isEthernetConnected {
                Divider()
                EthernetInfoView(networkMonitor: networkMonitor)
            }

            if networkMonitor.state.isWiFiPoweredOn {
                Divider()
                NetworkListView(wifiManager: wifiManager)
            }

            Divider()
            quickActions
        }
        .padding()
        .frame(width: 320)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Network status popover"))
    }

    @ViewBuilder
    private var quickActions: some View {
        HStack {
            wifiToggle

            Spacer()

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gear")
                Text(String(localized: "Settings"))
            }
            .accessibilityLabel(String(localized: "Open settings"))
        }
    }

    @ViewBuilder
    private var wifiToggle: some View {
        Toggle(isOn: Binding(
            get: { wifiManager.isWiFiPoweredOn },
            set: { _ in wifiManager.togglePower() }
        )) {
            Label(String(localized: "Wi-Fi"), systemImage: "wifi")
                .font(.caption)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .accessibilityLabel(String(localized: "Wi-Fi power"))
        .accessibilityValue(wifiManager.isWiFiPoweredOn ? String(localized: "On") : String(localized: "Off"))
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontDesign(.monospaced)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
```

- [ ] **Step 2: Update AppDelegate**

Replace the contents of `WireBar/Sources/App/AppDelegate.swift`:

```swift
import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let settingsStore = SettingsStore()
    let licenseManager = LicenseManager()
    private let networkMonitor = NetworkMonitor()
    private lazy var wifiManager = WiFiManager()
    private let locationManager = LocationPermissionManager()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        locationManager.requestPermissionIfNeeded()
        setupStatusItem()
        setupPopover()
        observeNetworkState()
        networkMonitor.start()
        wifiManager.scan()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wifi", accessibilityDescription: String(localized: "WireBar network status"))
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                networkMonitor: networkMonitor,
                wifiManager: wifiManager,
                settingsStore: settingsStore
            )
        )
    }

    private func observeNetworkState() {
        networkMonitor.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenuBarIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon(for state: NetworkState) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        if !state.isWiFiPoweredOn && state.connectionType != .ethernet && state.connectionType != .wifiAndEthernet {
            symbolName = "wifi.slash"
        } else {
            symbolName = switch state.connectionType {
            case .none: "wifi.slash"
            case .wifi: "wifi"
            case .ethernet: "cable.connector.horizontal"
            case .wifiAndEthernet: "wifi"
            }
        }

        button.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: String(localized: "WireBar network status")
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            wifiManager.scan()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run all tests**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -project WireBar.xcodeproj -scheme WireBar -configuration Debug 2>&1 | grep -E "(Executed|BUILD)" | tail -3
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add WireBar/Sources/UI/Popover/PopoverView.swift WireBar/Sources/App/AppDelegate.swift
git commit -m "feat: integrate WiFiManager, dynamic menu bar icon, and Wi-Fi toggle into popover"
```

---

## Task 13: Update CLAUDE.md Tree and Taskpaper

**Files:**
- Modify: `CLAUDE.md`
- Modify: `.taskpaper`

- [ ] **Step 1: Update the Tree section in CLAUDE.md**

Add the new files to the tree:

```
WireBar/
  Sources/
    ...
    Models/
      NetworkState.swift
      ScannedNetwork.swift
    Protocols/
      NetworkPathProviding.swift
      WLANInterface.swift
      ShellExecuting.swift
      WiFiScanning.swift
    Services/
      NetworkMonitor/
        NetworkMonitor.swift
      WiFiManager/
        WiFiManager.swift
        CoreWLANScanner.swift
      SettingsStore/
        SettingsStore.swift
      LicenseManager/
        LicenseManager.swift
    UI/
      MenuBar/
      Popover/
        PopoverView.swift
        ConnectionInfoView.swift
        EthernetInfoView.swift
        NetworkListView.swift
        PasswordInputView.swift
      Settings/
        SettingsView.swift
        NetworkDetailsSettingsView.swift
      Onboarding/
  ...
WireBarTests/
  NetworkMonitorTests.swift
  SettingsStoreTests.swift
  WiFiManagerTests.swift
  Mocks/
    MockWiFiScanner.swift
```

- [ ] **Step 2: Mark Phase 2 tasks as done in .taskpaper and log discoveries**

Mark each completed task with `@done(2026-06-22)`. Add a Discoveries section under Phase 2 similar to Phase 1.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md .taskpaper
git commit -m "docs: update tree and mark Phase 2 tasks complete"
```

---

## Task 14: Manual Testing

> **Note:** Manual testing requires the Claude Code desktop app (not CLI) for computer-use screen interaction. Many Wi-Fi management features (scanning, joining networks) also require Location Services permission which may not work for debug builds. The agent should build, launch the app, and visually verify what it can. For operations requiring real network switching, flag for Scott to test manually.

**PRD User Stories to verify:**

- [ ] **Stories 21-28 (Wi-Fi network switching):** Open popover, verify network list appears, check sorting (known first, then by signal), verify signal indicators and security badges, verify checkmark on current network. Tap a known network to join. Tap an unknown secured network to see password prompt.

- [ ] **Stories 4, 5, 13-15 (Ethernet, multiple connections):** If Ethernet is available, verify Ethernet section appears with IP. Verify primary route indicator. Verify menu bar icon changes for Ethernet-only vs Wi-Fi vs both. Toggle Wi-Fi off and verify disabled icon + minimal popover.

- [ ] **Regression — Stories 1-2, 8-9 (Phase 1):** Menu bar icon appears. Popover opens on click. SSID and signal strength display. Settings window opens.

- [ ] **Step 1: Build and launch**

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project WireBar.xcodeproj -scheme WireBar -configuration Debug build 2>&1 | tail -3
open DerivedData/Build/Products/Debug/WireBar.app
```

- [ ] **Step 2: Visual verification via computer-use**

Use computer-use to take screenshots and verify the popover layout, network list, icons, and settings tab.

- [ ] **Step 3: Log any issues found**

Add issues to `.taskpaper` under Phase 2 or fix inline.

---

## Task 15: Log Lessons and Final Commit

**Files:**
- Modify: `context/lessons.md`

- [ ] **Step 1: Log lessons learned**

Append any new discoveries to `context/lessons.md`. Expected lessons might include:
- CoreWLAN `scanForNetworks(withName: nil)` blocks for 1-3 seconds — always call off-main-thread
- `CWSecurity` cases in Swift 6: `.dynamicWEP` not `.DynamicWEP`, no `.wep` case
- `CWNetworkProfile` is accessed via `CWConfiguration.networkProfiles` (NSOrderedSet) — cast elements to `CWNetworkProfile`
- `associate(to:password:)` accepts `nil` password for open/known networks

- [ ] **Step 2: Commit**

```bash
git add context/lessons.md
git commit -m "docs: log Phase 2 lessons learned"
```

---

## Design Decisions Made in This Plan

1. **Scan trigger:** WiFiManager scans on popover open + manual refresh button. No background polling. This keeps battery impact minimal.
2. **Password input:** Inline in the popover (not a modal window). LSUIElement apps have trouble with modal windows; inline fields are more reliable and feel more integrated.
3. **Primary route detection:** Uses `NWPath.availableInterfaces.first` — NWPathMonitor lists the primary interface first.
4. **Menu bar icon:** Changed from distinctive antenna icon (used during Phase 1 for testing) to standard `wifi`/`wifi.slash`/`cable.connector.horizontal` icons that match the connection state. This aligns with user stories 4 and 5.
5. **Network detail gating:** Advanced detail toggles (band, channel, BSSID, etc.) are wired through `LicenseManager.isPaid` now. They'll be locked until Phase 6 makes LicenseManager real.
6. **PRD contradiction (Stories 12 vs 50):** Story 12 ("paid user") is treated as correct for advanced details. Story 50 likely refers to the general ability to see basic details which remains free.
