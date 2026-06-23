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
    }
}
