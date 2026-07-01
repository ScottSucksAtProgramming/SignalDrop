import Foundation
import Combine

final class VPNManager: ObservableObject, @unchecked Sendable {
    @Published private(set) var vpnStates: [VPNState] = []

    var hasMultipleConnected: Bool { connectedCount >= 2 }
    var connectedCount: Int { vpnStates.filter { $0.status == .connected }.count }

    var provider: VPNConfigurationProviding
    private let licenseManager: LicenseManager

    init(
        provider: VPNConfigurationProviding = SystemVPNProvider(),
        licenseManager: LicenseManager = LicenseManager()
    ) {
        self.provider = provider
        self.licenseManager = licenseManager
    }

    /// Re-reads system VPN configurations and republishes display state.
    /// No-ops when unpaid so no VPN data surfaces behind the paid gate.
    func refresh() {
        guard licenseManager.isPaid else {
            if !vpnStates.isEmpty { vpnStates = [] }
            return
        }

        let infos = provider.loadConfigurations()
        let states = infos.map { info in
            VPNState(
                id: info.id,
                displayName: info.displayName,
                status: info.status,
                providerBundleIdentifier: info.providerBundleIdentifier
            )
        }

        if Thread.isMainThread {
            vpnStates = states
        } else {
            DispatchQueue.main.async { self.vpnStates = states }
        }
    }
}
