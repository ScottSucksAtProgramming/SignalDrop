import Foundation
import Combine

final class NotificationService: @unchecked Sendable {
    private let dispatcher: NotificationDispatching
    private let licenseManager: LicenseManager
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    private var previousVPNStates: [String: VPNConnectionStatus] = [:]
    private var previousWiFiConnected: Bool?
    private var previousSSID: String?
    private var previousExternalIP: String?
    private var hasReceivedInitialIP = false
    private var hasAuthorized = false
    private var wifiDisconnectWorkItem: DispatchWorkItem?

    init(
        dispatcher: NotificationDispatching = UNNotificationDispatcher(),
        licenseManager: LicenseManager,
        settingsStore: SettingsStore
    ) {
        self.dispatcher = dispatcher
        self.licenseManager = licenseManager
        self.settingsStore = settingsStore
    }

    func observeVPN(_ vpnManager: VPNManager) {
        vpnManager.$vpnStates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                self?.handleVPNUpdate(states)
            }
            .store(in: &cancellables)
    }

    func observeNetwork(_ networkMonitor: NetworkMonitor) {
        networkMonitor.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                let isWiFiConnected = state.connectionType == .wifi || state.connectionType == .wifiAndEthernet
                self?.handleWiFiUpdate(isWiFiConnected, ssid: state.ssid)
            }
            .store(in: &cancellables)
    }

    func observeIP(_ ipService: IPService) {
        ipService.$externalIPStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleIPUpdate(status)
            }
            .store(in: &cancellables)
    }

    private func handleVPNUpdate(_ states: [VPNState]) {
        guard licenseManager.isPaid, settingsStore.notifyVPNDrop else {
            previousVPNStates = Dictionary(uniqueKeysWithValues: states.map { ($0.id, $0.status) })
            return
        }

        for vpn in states {
            if let previous = previousVPNStates[vpn.id],
               previous == .connected,
               vpn.status == .disconnected {
                let title = String(localized: "VPN Disconnected")
                let body = String(localized: "\(vpn.displayName) has disconnected")
                ensureAuthorizedThenDispatch(title: title, body: body, identifier: "vpn-drop-\(vpn.id)")
            }
        }

        previousVPNStates = Dictionary(uniqueKeysWithValues: states.map { ($0.id, $0.status) })
    }

    private func handleWiFiUpdate(_ isWiFiConnected: Bool, ssid: String? = nil) {
        guard licenseManager.isPaid else {
            previousWiFiConnected = isWiFiConnected
            previousSSID = ssid
            return
        }

        defer {
            previousWiFiConnected = isWiFiConnected
            previousSSID = ssid
        }

        if let wasConnected = previousWiFiConnected, wasConnected, !isWiFiConnected, settingsStore.notifyWiFiDisconnect {
            let workItem = DispatchWorkItem { [weak self] in
                let title = String(localized: "Wi-Fi Disconnected")
                let body = String(localized: "Your Wi-Fi connection has been lost")
                self?.ensureAuthorizedThenDispatch(title: title, body: body, identifier: "wifi-disconnect")
            }
            wifiDisconnectWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
        }

        if isWiFiConnected, let currentSSID = ssid {
            wifiDisconnectWorkItem?.cancel()
            wifiDisconnectWorkItem = nil

            if let prevSSID = previousSSID, prevSSID != currentSSID, settingsStore.notifyNetworkChange {
                let title = String(localized: "Network Changed")
                let body = String(localized: "Switched from \(prevSSID) to \(currentSSID)")
                ensureAuthorizedThenDispatch(title: title, body: body, identifier: "network-change")
            }
        }
    }

    private func handleIPUpdate(_ status: ExternalIPStatus) {
        guard licenseManager.isPaid, settingsStore.notifyIPChange else {
            if case .loaded(let ip) = status {
                if !hasReceivedInitialIP { hasReceivedInitialIP = true }
                previousExternalIP = ip
            }
            return
        }

        guard case .loaded(let ip) = status else { return }

        defer { previousExternalIP = ip }

        guard hasReceivedInitialIP else {
            hasReceivedInitialIP = true
            return
        }

        guard let previous = previousExternalIP, previous != ip else { return }

        let title = String(localized: "External IP Changed")
        let body = String(localized: "Your external IP changed to \(ip)")
        ensureAuthorizedThenDispatch(title: title, body: body, identifier: "ip-change")
    }

    func handleWiFiUpdateForTesting(_ isWiFiConnected: Bool, ssid: String? = nil) {
        handleWiFiUpdate(isWiFiConnected, ssid: ssid)
    }

    func handleIPUpdateForTesting(_ status: ExternalIPStatus) {
        handleIPUpdate(status)
    }

    private func ensureAuthorizedThenDispatch(title: String, body: String, identifier: String) {
        Task {
            if !hasAuthorized {
                hasAuthorized = (try? await dispatcher.requestAuthorization()) ?? false
            }
            await dispatcher.dispatch(title: title, body: body, identifier: identifier)
        }
    }
}
