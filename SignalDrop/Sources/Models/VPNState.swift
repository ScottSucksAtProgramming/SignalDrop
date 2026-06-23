import Foundation

enum VPNConnectionStatus: Sendable, Equatable {
    case connected
    case connecting
    case disconnecting
    case disconnected
    case unknown
}

struct VPNState: Sendable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let status: VPNConnectionStatus
    let providerBundleIdentifier: String?

    var iconName: String { VPNState.providerIcon(for: providerBundleIdentifier) }

    /// Maps a VPN's provider bundle identifier to an SF Symbol. Cosmetic lookup —
    /// unknown providers fall back to a generic shield. Easy to extend.
    static func providerIcon(for bundleIdentifier: String?) -> String {
        switch bundleIdentifier {
        case "com.wireguard.macos": return "shield.lefthalf.filled"
        case "io.tailscale.ipn.macsys", "io.tailscale.ipn.macos": return "network.badge.shield.half.filled"
        case "com.privateinternetaccess.vpn", "com.privateinternetaccess.app": return "lock.shield"
        default: return "lock.shield"
        }
    }
}
