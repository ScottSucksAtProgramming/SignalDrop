import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadSettings()
    }

    @Published var launchAtLogin: Bool = true {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showNetworkName: Bool = true {
        didSet { defaults.set(showNetworkName, forKey: Keys.showNetworkName) }
    }

    @Published var showSignalStrength: Bool = true {
        didSet { defaults.set(showSignalStrength, forKey: Keys.showSignalStrength) }
    }

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

    @Published var ipRefreshMode: IPRefreshMode = .onDemand {
        didSet { defaults.set(ipRefreshMode.rawValue, forKey: Keys.ipRefreshMode) }
    }

    @Published var ipRefreshInterval: TimeInterval = 60 {
        didSet { defaults.set(ipRefreshInterval, forKey: Keys.ipRefreshInterval) }
    }

    @Published var showPing: Bool = false {
        didSet { defaults.set(showPing, forKey: Keys.showPing) }
    }

    @Published var pingTarget: String = "1.1.1.1" {
        didSet { defaults.set(pingTarget, forKey: Keys.pingTarget) }
    }

    @Published var pingPort: UInt16 = 443 {
        didSet { defaults.set(Int(pingPort), forKey: Keys.pingPort) }
    }

    /// VPNs the user has hidden from the popover, keyed by SCNetworkService UUID.
    /// Opt-out: newly discovered VPNs are shown by default.
    @Published var hiddenVPNs: Set<String> = [] {
        didSet { defaults.set(Array(hiddenVPNs), forKey: Keys.hiddenVPNs) }
    }

    @Published var vpnTapAction: VPNTapAction = .openApp {
        didSet { defaults.set(vpnTapAction.rawValue, forKey: Keys.vpnTapAction) }
    }

    @Published var showMultiVPNWarning: Bool = true {
        didSet { defaults.set(showMultiVPNWarning, forKey: Keys.showMultiVPNWarning) }
    }

    @Published var notifyVPNDrop: Bool = true {
        didSet { defaults.set(notifyVPNDrop, forKey: Keys.notifyVPNDrop) }
    }

    @Published var notifyWiFiDisconnect: Bool = true {
        didSet { defaults.set(notifyWiFiDisconnect, forKey: Keys.notifyWiFiDisconnect) }
    }

    @Published var notifyIPChange: Bool = true {
        didSet { defaults.set(notifyIPChange, forKey: Keys.notifyIPChange) }
    }

    @Published var notifyNetworkChange: Bool = true {
        didSet { defaults.set(notifyNetworkChange, forKey: Keys.notifyNetworkChange) }
    }

    @Published var connectionInfoCollapsed: Bool = false {
        didSet { defaults.set(connectionInfoCollapsed, forKey: Keys.connectionInfoCollapsed) }
    }

    @Published var ipPingCollapsed: Bool = false {
        didSet { defaults.set(ipPingCollapsed, forKey: Keys.ipPingCollapsed) }
    }

    @Published var vpnCollapsed: Bool = false {
        didSet { defaults.set(vpnCollapsed, forKey: Keys.vpnCollapsed) }
    }

    @Published var networkListCollapsed: Bool = false {
        didSet { defaults.set(networkListCollapsed, forKey: Keys.networkListCollapsed) }
    }

    @Published var menuBarShowNetworkName: Bool = false {
        didSet { defaults.set(menuBarShowNetworkName, forKey: Keys.menuBarShowNetworkName) }
    }

    @Published var menuBarShowVPNIndicator: Bool = false {
        didSet { defaults.set(menuBarShowVPNIndicator, forKey: Keys.menuBarShowVPNIndicator) }
    }

    @Published var menuBarShowIP: Bool = false {
        didSet { defaults.set(menuBarShowIP, forKey: Keys.menuBarShowIP) }
    }

    @Published var hotkeyBindings: [String: HotkeyBinding] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(hotkeyBindings) {
                defaults.set(data, forKey: Keys.hotkeyBindings)
            }
        }
    }

    private func loadSettings() {
        if defaults.object(forKey: Keys.launchAtLogin) != nil {
            launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        }
        if defaults.object(forKey: Keys.showNetworkName) != nil {
            showNetworkName = defaults.bool(forKey: Keys.showNetworkName)
        }
        if defaults.object(forKey: Keys.showSignalStrength) != nil {
            showSignalStrength = defaults.bool(forKey: Keys.showSignalStrength)
        }
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
        if defaults.object(forKey: Keys.ipRefreshMode) != nil {
            ipRefreshMode = IPRefreshMode(rawValue: defaults.integer(forKey: Keys.ipRefreshMode)) ?? .onDemand
        }
        if defaults.object(forKey: Keys.ipRefreshInterval) != nil {
            ipRefreshInterval = defaults.double(forKey: Keys.ipRefreshInterval)
        }
        if defaults.object(forKey: Keys.showPing) != nil {
            showPing = defaults.bool(forKey: Keys.showPing)
        }
        if defaults.object(forKey: Keys.pingTarget) != nil {
            pingTarget = defaults.string(forKey: Keys.pingTarget) ?? "1.1.1.1"
        }
        if defaults.object(forKey: Keys.pingPort) != nil {
            pingPort = UInt16(defaults.integer(forKey: Keys.pingPort))
        }
        if let vpnArray = defaults.array(forKey: Keys.hiddenVPNs) as? [String] {
            hiddenVPNs = Set(vpnArray)
        }
        if defaults.object(forKey: Keys.vpnTapAction) != nil {
            vpnTapAction = VPNTapAction(rawValue: defaults.integer(forKey: Keys.vpnTapAction)) ?? .openApp
        }
        if defaults.object(forKey: Keys.showMultiVPNWarning) != nil {
            showMultiVPNWarning = defaults.bool(forKey: Keys.showMultiVPNWarning)
        }
        if defaults.object(forKey: Keys.notifyVPNDrop) != nil {
            notifyVPNDrop = defaults.bool(forKey: Keys.notifyVPNDrop)
        }
        if defaults.object(forKey: Keys.notifyWiFiDisconnect) != nil {
            notifyWiFiDisconnect = defaults.bool(forKey: Keys.notifyWiFiDisconnect)
        }
        if defaults.object(forKey: Keys.notifyIPChange) != nil {
            notifyIPChange = defaults.bool(forKey: Keys.notifyIPChange)
        }
        if defaults.object(forKey: Keys.notifyNetworkChange) != nil {
            notifyNetworkChange = defaults.bool(forKey: Keys.notifyNetworkChange)
        }
        if defaults.object(forKey: Keys.connectionInfoCollapsed) != nil {
            connectionInfoCollapsed = defaults.bool(forKey: Keys.connectionInfoCollapsed)
        }
        if defaults.object(forKey: Keys.ipPingCollapsed) != nil {
            ipPingCollapsed = defaults.bool(forKey: Keys.ipPingCollapsed)
        }
        if defaults.object(forKey: Keys.vpnCollapsed) != nil {
            vpnCollapsed = defaults.bool(forKey: Keys.vpnCollapsed)
        }
        if defaults.object(forKey: Keys.networkListCollapsed) != nil {
            networkListCollapsed = defaults.bool(forKey: Keys.networkListCollapsed)
        }
        if defaults.object(forKey: Keys.menuBarShowNetworkName) != nil {
            menuBarShowNetworkName = defaults.bool(forKey: Keys.menuBarShowNetworkName)
        }
        if defaults.object(forKey: Keys.menuBarShowVPNIndicator) != nil {
            menuBarShowVPNIndicator = defaults.bool(forKey: Keys.menuBarShowVPNIndicator)
        }
        if defaults.object(forKey: Keys.menuBarShowIP) != nil {
            menuBarShowIP = defaults.bool(forKey: Keys.menuBarShowIP)
        }
        if let data = defaults.data(forKey: Keys.hotkeyBindings),
           let bindings = try? JSONDecoder().decode([String: HotkeyBinding].self, from: data) {
            hotkeyBindings = bindings
        } else {
            hotkeyBindings = HotkeyAction.defaultBindings
        }
    }

    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showNetworkName = "showNetworkName"
        static let showSignalStrength = "showSignalStrength"
        static let showBand = "showBand"
        static let showChannel = "showChannel"
        static let showLinkSpeed = "showLinkSpeed"
        static let showBSSID = "showBSSID"
        static let showDNS = "showDNS"
        static let showGateway = "showGateway"
        static let showSubnet = "showSubnet"
        static let ipRefreshMode = "ipRefreshMode"
        static let ipRefreshInterval = "ipRefreshInterval"
        static let showPing = "showPing"
        static let pingTarget = "pingTarget"
        static let pingPort = "pingPort"
        static let hiddenVPNs = "hiddenVPNs"
        static let vpnTapAction = "vpnTapAction"
        static let showMultiVPNWarning = "showMultiVPNWarning"
        static let notifyVPNDrop = "notifyVPNDrop"
        static let notifyWiFiDisconnect = "notifyWiFiDisconnect"
        static let notifyIPChange = "notifyIPChange"
        static let notifyNetworkChange = "notifyNetworkChange"
        static let hotkeyBindings = "hotkeyBindings"
        static let connectionInfoCollapsed = "connectionInfoCollapsed"
        static let ipPingCollapsed = "ipPingCollapsed"
        static let vpnCollapsed = "vpnCollapsed"
        static let networkListCollapsed = "networkListCollapsed"
        static let menuBarShowNetworkName = "menuBarShowNetworkName"
        static let menuBarShowVPNIndicator = "menuBarShowVPNIndicator"
        static let menuBarShowIP = "menuBarShowIP"
    }
}

enum VPNTapAction: Int {
    case openApp
    case openSystemSettings
}
