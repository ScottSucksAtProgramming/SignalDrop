import Foundation
import Combine

class LicenseManager: ObservableObject {
    // TODO: Revert to false before release — true for beta testing
    @Published internal(set) var isPaid: Bool = true
    @Published private(set) var licenseKey: String?

    func validateLicense() async {
        isPaid = false
    }

    func activateLicense(key: String) async -> Bool {
        return false
    }

    func deactivateLicense() {
        isPaid = false
        licenseKey = nil
    }
}
