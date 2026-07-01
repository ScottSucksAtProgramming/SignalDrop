import Foundation
import Network
import CoreWLAN
import Combine

final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    @Published private(set) var state = NetworkState()

    private let pathMonitor: NetworkPathProviding
    private let ipService: IPService
    private let monitorQueue = DispatchQueue(label: "com.scottkostolni.WireBar.networkMonitor")

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
        let ifaceName = iface.interfaceName ?? "en0"
        let subnet = Self.getSubnetMask(forInterface: ifaceName)
        let gateway = Self.getDefaultGateway()
        let dns = Self.getDNSServers()

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
            self?.state.subnetMask = subnet
            self?.state.gatewayAddress = gateway
            self?.state.dnsServers = dns
        }
    }

    private static func getSubnetMask(forInterface targetName: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let iface = ptr.pointee
            guard iface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            guard String(cString: iface.ifa_name) == targetName else { continue }
            guard let netmask = iface.ifa_netmask else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                netmask, socklen_t(netmask.pointee.sa_len),
                &hostname, socklen_t(hostname.count),
                nil, 0, NI_NUMERICHOST
            ) == 0 {
                return String(cString: hostname)
            }
        }
        return nil
    }

    private static func getDefaultGateway() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        task.arguments = ["-rn", "-f", "inet"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
        } catch { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        for line in output.components(separatedBy: "\n") {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            guard cols.count >= 2 else { continue }
            if cols[0] == "default" {
                return String(cols[1])
            }
        }
        return nil
    }

    private static func getDNSServers() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        task.arguments = ["--dns"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
        } catch { return [] }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var servers: [String] = []
        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("nameserver[") {
                let parts = trimmed.split(separator: ":")
                if parts.count >= 2 {
                    let ip = parts[1].trimmingCharacters(in: .whitespaces)
                    if !servers.contains(ip) {
                        servers.append(ip)
                    }
                }
            }
        }
        return servers
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
