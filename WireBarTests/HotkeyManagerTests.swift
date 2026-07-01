import XCTest
import Combine
import Carbon.HIToolbox
@testable import WireBar

@MainActor
final class MockHotkeyActionHandler: HotkeyActionHandler {
    var receivedActions: [HotkeyAction] = []

    func performHotkeyAction(_ action: HotkeyAction) {
        receivedActions.append(action)
    }
}

@MainActor
final class HotkeyManagerTests: XCTestCase {

    private func makePaidLicense() -> LicenseManager {
        let license = LicenseManager()
        license.isPaid = true
        return license
    }

    private func makeSettings() -> SettingsStore {
        SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    // MARK: - Dispatch

    func testDispatchCallsHandler() {
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = HotkeyManager(licenseManager: license, settingsStore: settings)
        let handler = MockHotkeyActionHandler()
        sut.actionHandler = handler

        sut.dispatchAction(.togglePopover)

        XCTAssertEqual(handler.receivedActions, [.togglePopover])
    }

    func testDispatchBlockedForFreeUsers() {
        let license = LicenseManager()
        let settings = makeSettings()
        let sut = HotkeyManager(licenseManager: license, settingsStore: settings)
        let handler = MockHotkeyActionHandler()
        sut.actionHandler = handler

        sut.dispatchAction(.togglePopover)

        XCTAssertTrue(handler.receivedActions.isEmpty)
    }

    func testDispatchMultipleActions() {
        let license = makePaidLicense()
        let settings = makeSettings()
        let sut = HotkeyManager(licenseManager: license, settingsStore: settings)
        let handler = MockHotkeyActionHandler()
        sut.actionHandler = handler

        sut.dispatchAction(.toggleWiFi)
        sut.dispatchAction(.refreshIP)
        sut.dispatchAction(.copyLocalIP)

        XCTAssertEqual(handler.receivedActions, [.toggleWiFi, .refreshIP, .copyLocalIP])
    }

    // MARK: - Conflict Detection

    func testConflictDetection() {
        let license = makePaidLicense()
        let settings = makeSettings()
        let binding = HotkeyBinding(keyCode: 13, modifierFlags: 0x0900) // ⌥⇧W
        settings.hotkeyBindings = [HotkeyAction.togglePopover.rawValue: binding]
        let sut = HotkeyManager(licenseManager: license, settingsStore: settings)

        let conflict = sut.conflictingAction(for: binding)

        XCTAssertEqual(conflict, .togglePopover)
    }

    func testNoConflictWhenExcluded() {
        let license = makePaidLicense()
        let settings = makeSettings()
        let binding = HotkeyBinding(keyCode: 13, modifierFlags: 0x0900)
        settings.hotkeyBindings = [HotkeyAction.togglePopover.rawValue: binding]
        let sut = HotkeyManager(licenseManager: license, settingsStore: settings)

        let conflict = sut.conflictingAction(for: binding, excluding: .togglePopover)

        XCTAssertNil(conflict)
    }

    func testNoConflictForDifferentBinding() {
        let license = makePaidLicense()
        let settings = makeSettings()
        let binding = HotkeyBinding(keyCode: 13, modifierFlags: 0x0900)
        settings.hotkeyBindings = [HotkeyAction.togglePopover.rawValue: binding]
        let sut = HotkeyManager(licenseManager: license, settingsStore: settings)

        let different = HotkeyBinding(keyCode: 14, modifierFlags: 0x0900)
        let conflict = sut.conflictingAction(for: different)

        XCTAssertNil(conflict)
    }

    // MARK: - HotkeyBinding Display

    func testHotkeyBindingDisplayString() {
        let binding = HotkeyBinding(keyCode: 13, modifierFlags: UInt32(optionKey) | UInt32(shiftKey))
        XCTAssertTrue(binding.displayString.contains("⌥"))
        XCTAssertTrue(binding.displayString.contains("⇧"))
        XCTAssertTrue(binding.displayString.contains("W"))
    }
}
