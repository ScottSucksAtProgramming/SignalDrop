import Foundation
import CoreWLAN
import Combine

final class WiFiManager: ObservableObject, @unchecked Sendable {
    @Published private(set) var networks: [ScannedNetwork] = []
    @Published private(set) var isWiFiPoweredOn: Bool = true
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var scanError: Error?
    @Published private(set) var joinError: Error?

    private nonisolated(unsafe) let scanner: WiFiScanning

    init(scanner: WiFiScanning = CoreWLANScanner()) {
        self.scanner = scanner
        self.isWiFiPoweredOn = scanner.isPoweredOn()
    }

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        scanError = nil

        let scanner = self.scanner
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.performScan(scanner: scanner)
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let sorted):
                    self?.networks = sorted
                case .failure(let error):
                    self?.scanError = error
                    self?.networks = []
                }
                self?.isScanning = false
            }
        }
    }

    private static func performScan(scanner: WiFiScanning) -> Result<[ScannedNetwork], Error> {
        do {
            var scanned = try scanner.scanForNetworks()
            let currentSSID = scanner.currentSSID()

            scanned = scanned.map { network in
                var n = network
                n.isCurrent = (network.ssid == currentSSID)
                return n
            }

            let known = scanned.filter(\.isKnown).sorted { $0.rssi > $1.rssi }
            let other = scanned.filter { !$0.isKnown }.sorted { $0.rssi > $1.rssi }
            return .success(known + other)
        } catch {
            return .failure(error)
        }
    }

    func joinNetwork(_ network: ScannedNetwork, password: String?) {
        joinError = nil
        guard let bssid = network.bssid else { return }

        do {
            try scanner.associateToNetwork(bssid: bssid, password: password)
        } catch {
            joinError = error
        }
    }

    func togglePower() {
        let newState = !isWiFiPoweredOn
        do {
            try scanner.setPower(newState)
            isWiFiPoweredOn = newState
        } catch {
            // Power toggle failed — state unchanged
        }
    }
}
