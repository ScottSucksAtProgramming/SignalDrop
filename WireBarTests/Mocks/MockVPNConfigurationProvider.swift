import Foundation
@testable import WireBar

final class MockVPNConfigurationProvider: VPNConfigurationProviding {
    var configurations: [VPNConfigurationInfo] = []

    func loadConfigurations() -> [VPNConfigurationInfo] {
        configurations
    }
}
