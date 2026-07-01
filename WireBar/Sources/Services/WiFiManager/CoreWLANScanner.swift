import Foundation
import CoreWLAN

final class CoreWLANScanner: WiFiScanning, @unchecked Sendable {
    private let client: CWWiFiClient
    private var interface: CWInterface? { client.interface() }

    init(client: CWWiFiClient = .shared()) {
        self.client = client
    }

    func scanForNetworks() throws -> [ScannedNetwork] {
        guard let iface = interface else { return [] }
        let cwNetworks = try iface.scanForNetworks(withName: nil)
        let known = knownNetworkSSIDs()

        return cwNetworks.compactMap { network -> ScannedNetwork? in
            guard let ssid = network.ssid, !ssid.isEmpty else { return nil }
            return ScannedNetwork(
                id: network.bssid ?? ssid,
                ssid: ssid,
                bssid: network.bssid,
                rssi: network.rssiValue,
                channelNumber: network.wlanChannel?.channelNumber,
                securityType: securityType(for: network),
                isKnown: known.contains(ssid),
                isCurrent: false
            )
        }
    }

    func knownNetworkSSIDs() -> Set<String> {
        guard let config = interface?.configuration() else { return [] }
        var ssids = Set<String>()
        for case let profile as CWNetworkProfile in config.networkProfiles {
            if let ssid = profile.ssid {
                ssids.insert(ssid)
            }
        }
        return ssids
    }

    func associateToNetwork(bssid: String, password: String?) throws {
        guard let iface = interface else { return }
        let networks = try iface.scanForNetworks(withName: nil)
        guard let target = networks.first(where: { $0.bssid == bssid }) else {
            throw NSError(
                domain: "WiFiManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Network not found"]
            )
        }
        try iface.associate(to: target, password: password)
    }

    func setPower(_ on: Bool) throws {
        guard let iface = interface else { return }
        try iface.setPower(on)
    }

    func isPoweredOn() -> Bool {
        interface?.powerOn() ?? false
    }

    func currentSSID() -> String? {
        interface?.ssid()
    }

    private func securityType(for network: CWNetwork) -> NetworkSecurityType {
        if network.supportsSecurity(.wpa3Personal) { return .wpa3 }
        if network.supportsSecurity(.wpa3Enterprise) { return .wpa3Enterprise }
        if network.supportsSecurity(.wpa2Personal) { return .wpa2 }
        if network.supportsSecurity(.wpa2Enterprise) { return .wpa2Enterprise }
        if network.supportsSecurity(.wpaPersonal) { return .wpa }
        if network.supportsSecurity(.wpaEnterprise) { return .wpaEnterprise }
        if network.supportsSecurity(.none) { return .open }
        return .unknown
    }
}
