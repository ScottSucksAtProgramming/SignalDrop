import CoreLocation

final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    var isAuthorized: Bool {
        let status = authorizationStatus
        return status == .authorizedAlways || status == .authorized
    }

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermissionIfNeeded() {
        guard !isAuthorized else { return }
        locationManager.requestWhenInUseAuthorization()
    }
}
