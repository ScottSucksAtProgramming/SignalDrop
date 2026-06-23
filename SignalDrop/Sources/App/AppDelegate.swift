import AppKit
import SwiftUI
import Combine
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let settingsStore = SettingsStore()
    let licenseManager = LicenseManager()
    private let networkMonitor = NetworkMonitor()
    private lazy var wifiManager = WiFiManager()
    private let locationManager = LocationPermissionManager()
    private lazy var ipService = IPService(licenseManager: licenseManager)
    private lazy var pingService = PingService(licenseManager: licenseManager)
    lazy var vpnManager = VPNManager(licenseManager: licenseManager)
    private lazy var notificationService = NotificationService(licenseManager: licenseManager, settingsStore: settingsStore)
    private lazy var hotkeyManager = HotkeyManager(licenseManager: licenseManager, settingsStore: settingsStore)
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        locationManager.requestPermissionIfNeeded()
        setupStatusItem()
        setupPopover()
        observeNetworkState()
        networkMonitor.start()
        wifiManager.scan()
        ipService.refreshLocalIP()
        ipService.observeSettings(settingsStore)
        observePingSettings()
        vpnManager.refresh()
        observeVPNStateChanges()
        setupNotificationService()
        setupHotkeyManager()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: String(localized: "SignalDrop network status"))
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
                settingsStore: settingsStore,
                ipService: ipService,
                pingService: pingService,
                vpnManager: vpnManager,
                licenseManager: licenseManager,
                onOpenSettings: { [weak self] in
                    self?.openSettings()
                }
            )
        )
    }

    private func observeNetworkState() {
        networkMonitor.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        settingsStore.$menuBarShowNetworkName
            .combineLatest(settingsStore.$menuBarShowVPNIndicator, settingsStore.$menuBarShowIP)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        vpnManager.$vpnStates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        ipService.$localIP
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBar() {
        guard let button = statusItem.button else { return }
        let state = networkMonitor.state

        let symbolName: String
        if !state.isWiFiPoweredOn && state.connectionType != .ethernet && state.connectionType != .wifiAndEthernet {
            symbolName = "antenna.radiowaves.left.and.right.slash"
        } else {
            symbolName = switch state.connectionType {
            case .none: "antenna.radiowaves.left.and.right.slash"
            case .wifi: "antenna.radiowaves.left.and.right"
            case .ethernet: "cable.connector.horizontal"
            case .wifiAndEthernet: "antenna.radiowaves.left.and.right"
            }
        }

        button.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: String(localized: "SignalDrop network status")
        )

        var textParts: [String] = []
        let isPaid = licenseManager.isPaid

        if settingsStore.menuBarShowNetworkName, isPaid, let ssid = state.ssid {
            let maxLen = 15
            textParts.append(ssid.count > maxLen ? String(ssid.prefix(maxLen)) + "…" : ssid)
        }

        if settingsStore.menuBarShowVPNIndicator, isPaid {
            let connectedCount = vpnManager.connectedCount
            if connectedCount > 0 {
                textParts.append("🔒\(connectedCount)")
            }
        }

        if settingsStore.menuBarShowIP, isPaid, let ip = ipService.localIP {
            textParts.append(ip)
        }

        button.title = textParts.isEmpty ? "" : " " + textParts.joined(separator: " · ")
        button.imagePosition = textParts.isEmpty ? .imageOnly : .imageLeading

        var accessibilityParts = [String(localized: "SignalDrop")]
        if let ssid = state.ssid { accessibilityParts.append(ssid) }
        let vpnCount = vpnManager.connectedCount
        if vpnCount > 0 { accessibilityParts.append(String(localized: "\(vpnCount) VPN connected")) }
        button.setAccessibilityLabel(accessibilityParts.joined(separator: ", "))
    }

    private func openSettings() {
        popover.performClose(nil)

        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(
            settingsStore: settingsStore,
            licenseManager: licenseManager,
            vpnManager: vpnManager,
            updaterController: updaterController
        )
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "SignalDrop Settings")
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 700, height: 450))
        window.minSize = NSSize(width: 700, height: 450)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    private func observePingSettings() {
        settingsStore.$showPing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showPing in
                guard let self else { return }
                if showPing && licenseManager.isPaid {
                    pingService.target = settingsStore.pingTarget
                    pingService.port = settingsStore.pingPort
                    pingService.start()
                } else {
                    pingService.stop()
                }
            }
            .store(in: &cancellables)

        settingsStore.$pingTarget
            .combineLatest(settingsStore.$pingPort)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] target, port in
                guard let self, pingService.isRunning else { return }
                pingService.target = target
                pingService.port = port
                pingService.measureOnce()
            }
            .store(in: &cancellables)
    }

    private func observeVPNStateChanges() {
        vpnManager.$vpnStates
            .map { states in states.filter { $0.status == .connected }.count }
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, licenseManager.isPaid else { return }
                ipService.clearCache()
                ipService.refreshExternalIP()
            }
            .store(in: &cancellables)
    }

    private func setupHotkeyManager() {
        hotkeyManager.actionHandler = self
        hotkeyManager.start()
    }

    private func setupNotificationService() {
        notificationService.observeVPN(vpnManager)
        notificationService.observeNetwork(networkMonitor)
        notificationService.observeIP(ipService)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            wifiManager.scan()
            ipService.refreshLocalIP()
            ipService.refreshExternalIP()
            vpnManager.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

extension AppDelegate: HotkeyActionHandler {
    func performHotkeyAction(_ action: HotkeyAction) {
        switch action {
        case .togglePopover:
            togglePopover()
        case .toggleWiFi:
            wifiManager.togglePower()
        case .refreshIP:
            ipService.clearCache()
            ipService.refreshExternalIP()
        case .copyLocalIP:
            if let ip = ipService.localIP {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ip, forType: .string)
            }
        case .copyExternalIP:
            if let ip = ipService.externalIP {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ip, forType: .string)
            }
        }
    }
}
