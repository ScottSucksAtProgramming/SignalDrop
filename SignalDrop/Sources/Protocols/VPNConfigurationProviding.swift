import Foundation

/// A read-only snapshot of one system VPN configuration, as surfaced by
/// SystemConfiguration (`scutil --nc list`). SignalDrop cannot toggle other
/// apps' VPNs, so this is display-only.
struct VPNConfigurationInfo: Sendable, Equatable, Identifiable {
    let id: String                          // SCNetworkService UUID (stable across renames)
    let displayName: String
    let status: VPNConnectionStatus
    let providerBundleIdentifier: String?
}

/// Seam over system VPN discovery, mirroring `NetworkPathProviding` / `WLANInterface`.
/// Keeps SystemConfiguration / Process details out of `VPNManager` and tests.
protocol VPNConfigurationProviding {
    func loadConfigurations() -> [VPNConfigurationInfo]
}
