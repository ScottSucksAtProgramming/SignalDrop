import XCTest
import Combine
@testable import WireBar

struct MockExternalIPResolver: ExternalIPResolving {
    var result: Result<String, Error>

    func fetchExternalIP() async throws -> String {
        switch result {
        case .success(let ip): return ip
        case .failure(let error): throw error
        }
    }
}

final class IPServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    private func makePaidLicense() -> LicenseManager {
        let license = LicenseManager()
        license.isPaid = true
        return license
    }

    func testLocalIPReturnsValue() {
        let sut = IPService()
        sut.refreshLocalIP()

        let expectation = expectation(description: "localIP published")
        sut.$localIP
            .dropFirst()
            .first()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2)
    }

    func testExternalIPBlockedWhenNotPaid() {
        let license = LicenseManager()
        let resolver = MockExternalIPResolver(result: .success("1.2.3.4"))
        let sut = IPService(resolver: resolver, licenseManager: license)

        sut.refreshExternalIP()

        let expectation = expectation(description: "status stays idle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(sut.externalIPStatus, .idle)
            XCTAssertNil(sut.externalIP)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func testExternalIPSuccessWhenPaid() {
        let license = makePaidLicense()
        let resolver = MockExternalIPResolver(result: .success("203.0.113.1"))
        let sut = IPService(resolver: resolver, licenseManager: license)

        let expectation = expectation(description: "external IP loaded")
        sut.$externalIPStatus
            .dropFirst()
            .sink { status in
                if case .loaded(let ip) = status {
                    XCTAssertEqual(ip, "203.0.113.1")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refreshExternalIP()
        wait(for: [expectation], timeout: 5)
    }

    func testExternalIPFailureSetsUnavailable() {
        let license = makePaidLicense()
        let resolver = MockExternalIPResolver(result: .failure(DNSError.timeout))
        let sut = IPService(resolver: resolver, licenseManager: license)

        let expectation = expectation(description: "external IP unavailable")
        sut.$externalIPStatus
            .dropFirst()
            .sink { status in
                if status == .unavailable {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refreshExternalIP()
        wait(for: [expectation], timeout: 5)
    }

    func testCacheReturnsCachedValue() {
        let license = makePaidLicense()
        let resolver = MockExternalIPResolver(result: .success("10.0.0.1"))
        let sut = IPService(resolver: resolver, licenseManager: license, cacheInterval: 60)

        let loadedExpectation = expectation(description: "first load")
        sut.$externalIPStatus
            .dropFirst()
            .sink { status in
                if case .loaded = status {
                    loadedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refreshExternalIP()
        wait(for: [loadedExpectation], timeout: 5)

        cancellables.removeAll()

        sut.refreshExternalIP()
        XCTAssertEqual(sut.externalIPStatus, .loaded("10.0.0.1"))
    }

    func testClearCacheForcesFreshFetch() {
        let license = makePaidLicense()
        let resolver = MockExternalIPResolver(result: .success("10.0.0.1"))
        let sut = IPService(resolver: resolver, licenseManager: license, cacheInterval: 60)

        let loadedExpectation = expectation(description: "first load")
        sut.$externalIPStatus
            .dropFirst()
            .sink { status in
                if case .loaded = status {
                    loadedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refreshExternalIP()
        wait(for: [loadedExpectation], timeout: 5)

        cancellables.removeAll()

        sut.clearCache()

        let reloadExpectation = expectation(description: "reload after clear")
        sut.$externalIPStatus
            .dropFirst()
            .sink { status in
                if status == .loading {
                    reloadExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refreshExternalIP()
        wait(for: [reloadExpectation], timeout: 5)
    }

    func testExternalIPComputedProperty() {
        let license = makePaidLicense()
        let resolver = MockExternalIPResolver(result: .success("8.8.8.8"))
        let sut = IPService(resolver: resolver, licenseManager: license)

        XCTAssertNil(sut.externalIP)

        let loadedExpectation = expectation(description: "loaded")
        sut.$externalIPStatus
            .dropFirst()
            .sink { status in
                if case .loaded = status {
                    loadedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.refreshExternalIP()
        wait(for: [loadedExpectation], timeout: 5)

        XCTAssertEqual(sut.externalIP, "8.8.8.8")
    }
}
