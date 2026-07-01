import Foundation
import Carbon.HIToolbox
import Combine

@MainActor
protocol HotkeyActionHandler: AnyObject {
    func performHotkeyAction(_ action: HotkeyAction)
}

final class HotkeyManager: @unchecked Sendable {
    private let licenseManager: LicenseManager
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    private var registeredHotkeys: [UInt32: (ref: EventHotKeyRef?, action: HotkeyAction)] = [:]
    private var nextHotkeyID: UInt32 = 1
    weak var actionHandler: HotkeyActionHandler?

    nonisolated(unsafe) private static var shared: HotkeyManager?
    private var eventHandler: EventHandlerRef?

    init(licenseManager: LicenseManager, settingsStore: SettingsStore) {
        self.licenseManager = licenseManager
        self.settingsStore = settingsStore
        HotkeyManager.shared = self
    }

    func start() {
        observeSettings()
    }

    func stop() {
        unregisterAll()
        cancellables.removeAll()
    }

    private func observeSettings() {
        settingsStore.$hotkeyBindings
            .combineLatest(licenseManager.$isPaid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bindings, isPaid in
                self?.rebuildRegistrations(bindings: bindings, isPaid: isPaid)
            }
            .store(in: &cancellables)
    }

    private func rebuildRegistrations(bindings: [String: HotkeyBinding], isPaid: Bool) {
        unregisterAll()
        guard isPaid else { return }

        installEventHandlerIfNeeded()

        for (actionKey, binding) in bindings {
            guard let action = HotkeyAction(rawValue: actionKey) else { continue }
            registerHotkey(binding: binding, action: action)
        }
    }

    private func registerHotkey(binding: HotkeyBinding, action: HotkeyAction) {
        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1

        var eventHotKeyID = EventHotKeyID()
        eventHotKeyID.signature = OSType(0x5344_484B) // "SDHK"
        eventHotKeyID.id = hotkeyID

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.modifierFlags,
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            registeredHotkeys[hotkeyID] = (ref: hotKeyRef, action: action)
        }
    }

    private func unregisterAll() {
        for (_, entry) in registeredHotkeys {
            if let ref = entry.ref {
                UnregisterEventHotKey(ref)
            }
        }
        registeredHotkeys.removeAll()
        nextHotkeyID = 1
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.handleCarbonEvent(event)
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    private static func handleCarbonEvent(_ event: EventRef?) -> OSStatus {
        guard let event else { return OSStatus(eventNotHandledErr) }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else { return status }
        guard let manager = HotkeyManager.shared else { return OSStatus(eventNotHandledErr) }

        if let entry = manager.registeredHotkeys[hotkeyID.id] {
            let action = entry.action
            DispatchQueue.main.async { @MainActor in
                manager.actionHandler?.performHotkeyAction(action)
            }
        }

        return noErr
    }

    @MainActor
    func dispatchAction(_ action: HotkeyAction) {
        guard licenseManager.isPaid else { return }
        actionHandler?.performHotkeyAction(action)
    }

    func conflictingAction(for binding: HotkeyBinding, excluding: HotkeyAction? = nil) -> HotkeyAction? {
        for (actionKey, existingBinding) in settingsStore.hotkeyBindings {
            guard let action = HotkeyAction(rawValue: actionKey) else { continue }
            if action == excluding { continue }
            if existingBinding == binding { return action }
        }
        return nil
    }
}
