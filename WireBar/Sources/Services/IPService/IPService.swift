import Foundation
import Combine
import Network

enum IPRefreshMode: Int, Sendable {
    case timed = 0
    case onDemand = 1
}

enum ExternalIPStatus: Sendable, Equatable {
    case idle
    case loading
    case loaded(String)
    case unavailable
}

protocol ExternalIPResolving: Sendable {
    func fetchExternalIP() async throws -> String
}

final class IPService: ObservableObject, @unchecked Sendable {
    @Published private(set) var localIP: String?
    @Published private(set) var externalIPStatus: ExternalIPStatus = .idle

    private let resolver: ExternalIPResolving
    private let licenseManager: LicenseManager
    private let cacheInterval: TimeInterval
    private var cachedIP: String?
    private var cacheTimestamp: Date?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var externalIP: String? {
        if case .loaded(let ip) = externalIPStatus { return ip }
        return nil
    }

    init(resolver: ExternalIPResolving = DNSExternalIPResolver(), licenseManager: LicenseManager = LicenseManager(), cacheInterval: TimeInterval = 30) {
        self.resolver = resolver
        self.licenseManager = licenseManager
        self.cacheInterval = cacheInterval
    }

    func observeSettings(_ settingsStore: SettingsStore) {
        settingsStore.$ipRefreshMode
            .combineLatest(settingsStore.$ipRefreshInterval)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode, interval in
                self?.configureRefreshTimer(mode: mode, interval: interval)
            }
            .store(in: &cancellables)
    }

    private func configureRefreshTimer(mode: IPRefreshMode, interval: TimeInterval) {
        refreshTimer?.invalidate()
        refreshTimer = nil

        guard mode == .timed, licenseManager.isPaid else { return }

        let clampedInterval = max(interval, 10)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: clampedInterval, repeats: true) { [weak self] _ in
            self?.clearCache()
            self?.refreshExternalIP()
        }
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
    }

    func refreshLocalIP() {
        let ip = Self.getIPAddress()
        DispatchQueue.main.async { [weak self] in
            self?.localIP = ip
        }
    }

    func refreshExternalIP() {
        guard licenseManager.isPaid else {
            DispatchQueue.main.async { [weak self] in
                self?.externalIPStatus = .idle
            }
            return
        }

        if let cached = cachedIP,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheInterval {
            DispatchQueue.main.async { [weak self] in
                self?.externalIPStatus = .loaded(cached)
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.externalIPStatus = .loading
        }

        Task {
            do {
                let ip = try await resolver.fetchExternalIP()
                self.cachedIP = ip
                self.cacheTimestamp = Date()
                await MainActor.run {
                    self.externalIPStatus = .loaded(ip)
                }
            } catch {
                await MainActor.run {
                    self.externalIPStatus = .unavailable
                }
            }
        }
    }

    func clearCache() {
        cachedIP = nil
        cacheTimestamp = nil
    }

    func localIP(forInterface name: String) -> String? {
        Self.getIPAddress(forInterface: name)
    }

    static func getIPAddress(forInterface targetName: String? = nil) -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let iface = ptr.pointee
            let addrFamily = iface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }

            let name = String(cString: iface.ifa_name)
            if let target = targetName {
                guard name == target else { continue }
            } else {
                guard name == "en0" || name == "en1" else { continue }
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                iface.ifa_addr, socklen_t(iface.ifa_addr.pointee.sa_len),
                &hostname, socklen_t(hostname.count),
                nil, 0, NI_NUMERICHOST
            ) == 0 {
                address = String(cString: hostname)
                break
            }
        }
        return address
    }
}
