import Foundation
import Network
import CoreWLAN
import Combine

final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    @Published private(set) var state = NetworkState()

    private let pathMonitor: NetworkPathProviding
    private let monitorQueue = DispatchQueue(label: "com.scottkostolni.SignalDrop.networkMonitor")

    init(pathMonitor: NetworkPathProviding = NWPathMonitor()) {
        self.pathMonitor = pathMonitor
    }

    func start() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        pathMonitor.start(queue: monitorQueue)
        handlePathUpdate(pathMonitor.currentPath)
        refreshWiFiInfo()
    }

    func stop() {
        pathMonitor.cancel()
    }

    func refreshWiFiInfo() {
        let wifiClient = CWWiFiClient.shared()
        guard let iface = wifiClient.interface() else {
            DispatchQueue.main.async { [weak self] in
                self?.state.ssid = nil
                self?.state.isWiFiPoweredOn = false
            }
            return
        }

        let ssid = iface.ssid()
        let rssi = iface.rssiValue()
        let noise = iface.noiseMeasurement()
        let bssid = iface.bssid()
        let rate = iface.transmitRate()
        let powerOn = iface.powerOn()

        let channelNum = iface.wlanChannel()?.channelNumber
        let band: WLANChannelBand? = {
            guard let cwBand = iface.wlanChannel()?.channelBand else { return nil }
            return switch cwBand {
            case .band2GHz: .band2GHz
            case .band5GHz: .band5GHz
            case .band6GHz: .band6GHz
            case .bandUnknown: .unknown
            @unknown default: .unknown
            }
        }()

        let localIP = Self.getLocalIPAddress()

        DispatchQueue.main.async { [weak self] in
            self?.state.ssid = ssid
            self?.state.signalStrength = rssi
            self?.state.noiseLevel = noise
            self?.state.bssid = bssid
            self?.state.transmitRate = rate
            self?.state.isWiFiPoweredOn = powerOn
            self?.state.channelNumber = channelNum
            self?.state.channelBand = band
            self?.state.localIPAddress = localIP
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        let isConnected = path.status == .satisfied
        let hasWifi = path.usesInterfaceType(.wifi)
        let hasEthernet = path.usesInterfaceType(.wiredEthernet)

        let connectionType: ConnectionType = {
            switch (hasWifi, hasEthernet) {
            case (true, true): return .wifiAndEthernet
            case (true, false): return .wifi
            case (false, true): return .ethernet
            case (false, false): return .none
            }
        }()

        DispatchQueue.main.async { [weak self] in
            self?.state.isConnected = isConnected
            self?.state.connectionType = connectionType
            self?.state.isEthernetConnected = hasEthernet
        }

        if hasWifi {
            refreshWiFiInfo()
        }
    }

    private static func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let iface = ptr.pointee
            let addrFamily = iface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }

            let name = String(cString: iface.ifa_name)
            guard name == "en0" || name == "en1" else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                iface.ifa_addr, socklen_t(iface.ifa_addr.pointee.sa_len),
                &hostname, socklen_t(hostname.count),
                nil, 0, NI_NUMERICHOST
            ) == 0 {
                address = String(cString: hostname)
                break
            }
        }
        return address
    }
}
