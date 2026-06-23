import Foundation
import Network
import CoreWLAN
import Combine

final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    @Published private(set) var state = NetworkState()

    private let pathMonitor: NetworkPathProviding
    private let ipService: IPService
    private let monitorQueue = DispatchQueue(label: "com.scottkostolni.SignalDrop.networkMonitor")

    init(pathMonitor: NetworkPathProviding = NWPathMonitor(), ipService: IPService = IPService()) {
        self.pathMonitor = pathMonitor
        self.ipService = ipService
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

        let localIP = IPService.getIPAddress()

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

        let primaryIface: String? = {
            if let first = path.availableInterfaces.first {
                return first.name
            }
            return nil
        }()

        let ethernetIP: String? = hasEthernet ? IPService.getIPAddress(forInterface: "en0") ?? IPService.getIPAddress(forInterface: "en1") : nil

        DispatchQueue.main.async { [weak self] in
            self?.state.isConnected = isConnected
            self?.state.connectionType = connectionType
            self?.state.isEthernetConnected = hasEthernet
            self?.state.primaryInterface = primaryIface
            self?.state.ethernetIPAddress = ethernetIP
        }

        if hasWifi {
            refreshWiFiInfo()
        }
    }

}
