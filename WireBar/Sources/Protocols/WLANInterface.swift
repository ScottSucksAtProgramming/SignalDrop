import Foundation

protocol WLANInterface {
    func ssid() -> String?
    func rssiValue() -> Int
    func noiseMeasurement() -> Int
    func channel() -> WLANChannel?
    func bssid() -> String?
    func hardwareAddress() -> String?
    func transmitRate() -> Double
    func wlanServiceName() -> String?
    func powerOn() -> Bool
}

protocol WLANChannel {
    var channelNumber: Int { get }
    var channelBand: WLANChannelBand { get }
}

enum WLANChannelBand: Int {
    case unknown = 0
    case band2GHz = 1
    case band5GHz = 2
    case band6GHz = 3
}
