import Foundation
import Combine
import Network

enum PingStatus: Sendable, Equatable {
    case idle
    case measuring
    case result(latencyMs: Double)
    case error
}

final class PingService: ObservableObject, @unchecked Sendable {
    @Published private(set) var status: PingStatus = .idle
    @Published private(set) var isRunning: Bool = false

    private let licenseManager: LicenseManager
    private var timer: Timer?
    private var currentConnection: NWConnection?
    private let pingQueue = DispatchQueue(label: "com.scottkostolni.SignalDrop.ping")

    var target: String = "1.1.1.1"
    var port: UInt16 = 443

    init(licenseManager: LicenseManager = LicenseManager()) {
        self.licenseManager = licenseManager
    }

    func start() {
        guard licenseManager.isPaid else { return }
        guard !isRunning else { return }

        isRunning = true
        measureOnce()

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.measureOnce()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        currentConnection?.cancel()
        currentConnection = nil
        isRunning = false
        status = .idle
    }

    func measureOnce() {
        guard licenseManager.isPaid else {
            status = .idle
            return
        }

        status = .measuring

        let host = NWEndpoint.Host(target)
        let nwPort = NWEndpoint.Port(rawValue: port) ?? .https
        let connection = NWConnection(host: host, port: nwPort, using: .tcp)

        currentConnection?.cancel()
        currentConnection = connection

        let startTime = CFAbsoluteTimeGetCurrent()

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                let latency = (elapsed * 10).rounded() / 10
                connection.cancel()
                DispatchQueue.main.async {
                    self?.status = .result(latencyMs: latency)
                }
            case .failed:
                connection.cancel()
                DispatchQueue.main.async {
                    self?.status = .error
                }
            case .cancelled:
                break
            default:
                break
            }
        }

        connection.start(queue: pingQueue)

        pingQueue.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard case .measuring = self?.status else { return }
            connection.cancel()
            DispatchQueue.main.async {
                self?.status = .error
            }
        }
    }
}
