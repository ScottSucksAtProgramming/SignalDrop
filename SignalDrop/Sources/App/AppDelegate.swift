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
    private lazy var ipService = IPService(licenseManager: licenseManager)
    private lazy var pingService = PingService(licenseManager: licenseManager)
    lazy var vpnManager = VPNManager(licenseManager: licenseManager)
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?

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
        vpnManager.detectInstalledVPNs()
        vpnManager.startStatusPolling()
        observeVPNStateChanges()
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
            .sink { [weak self] state in
                self?.updateMenuBarIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon(for state: NetworkState) {
        guard let button = statusItem.button else { return }

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
            vpnManager: vpnManager
        )
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "SignalDrop Settings")
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 450, height: 300))
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

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            wifiManager.scan()
            ipService.refreshLocalIP()
            ipService.refreshExternalIP()
            vpnManager.refreshAllStatuses()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
