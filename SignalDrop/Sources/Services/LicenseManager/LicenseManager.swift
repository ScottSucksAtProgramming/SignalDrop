import Foundation
import Combine

class LicenseManager: ObservableObject {
    @Published internal(set) var isPaid: Bool = false
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
