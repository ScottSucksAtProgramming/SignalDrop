import Foundation
@testable import WireBar

final class MockWiFiScanner: WiFiScanning, @unchecked Sendable {
    var networksToReturn: [ScannedNetwork] = []
    var knownSSIDs: Set<String> = []
    var isPowered: Bool = true
    var currentSSIDValue: String? = "HomeNetwork"
    var associateCalledWith: (bssid: String, password: String?)? = nil
    var setPowerCalledWith: Bool? = nil
    var scanShouldThrow: Bool = false
    var associateShouldThrow: Bool = false

    func scanForNetworks() throws -> [ScannedNetwork] {
        if scanShouldThrow {
            throw NSError(domain: "CoreWLAN", code: -3931, userInfo: [NSLocalizedDescriptionKey: "Scan failed"])
        }
        return networksToReturn
    }

    func knownNetworkSSIDs() -> Set<String> {
        return knownSSIDs
    }

    func associateToNetwork(bssid: String, password: String?) throws {
        if associateShouldThrow {
            throw NSError(domain: "CoreWLAN", code: -3905, userInfo: [NSLocalizedDescriptionKey: "Association failed"])
        }
        associateCalledWith = (bssid, password)
    }

    func setPower(_ on: Bool) throws {
        setPowerCalledWith = on
        isPowered = on
    }

    func isPoweredOn() -> Bool {
        return isPowered
    }

    func currentSSID() -> String? {
        return currentSSIDValue
    }
}
