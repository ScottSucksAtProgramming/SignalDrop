import Foundation
@testable import SignalDrop

final class MockVPNConfigurationProvider: VPNConfigurationProviding {
    var configurations: [VPNConfigurationInfo] = []

    func loadConfigurations() -> [VPNConfigurationInfo] {
        configurations
    }
}
