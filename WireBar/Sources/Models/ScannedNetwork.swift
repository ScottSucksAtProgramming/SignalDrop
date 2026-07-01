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
