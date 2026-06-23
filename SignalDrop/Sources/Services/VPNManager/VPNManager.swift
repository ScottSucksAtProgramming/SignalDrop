import Foundation
import Combine

final class VPNManager: ObservableObject, @unchecked Sendable {
    @Published private(set) var vpnStates: [VPNState] = []

    var hasMultipleConnected: Bool { connectedCount >= 2 }
    var connectedCount: Int { vpnStates.filter { $0.status == .connected }.count }

    private let definitions: [VPNDefinition]
    private let executor: VPNCommandExecuting
    private let licenseManager: LicenseManager
    private let fileExistsChecker: @Sendable (String) -> Bool
    private var pollingTimer: Timer?

    init(
        definitions: [VPNDefinition] = VPNDefinition.allCurated,
        executor: VPNCommandExecuting = ProcessCommandExecutor(),
        licenseManager: LicenseManager = LicenseManager(),
        fileExistsChecker: @escaping @Sendable (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) {
        self.definitions = definitions
        self.executor = executor
        self.licenseManager = licenseManager
        self.fileExistsChecker = fileExistsChecker
    }

    func detectInstalledVPNs() {
        vpnStates = definitions.map { definition in
            let detectedPath = definition.cliPaths.first(where: { fileExistsChecker($0) })
            return VPNState(
                id: definition.id,
                definition: definition,
                status: .unknown,
                detectedCLIPath: detectedPath,
                isEnabled: true
            )
        }
    }

    func refreshAllStatuses() {
        for index in vpnStates.indices {
            let state = vpnStates[index]
            guard let cliPath = state.detectedCLIPath,
                  !state.definition.statusArgv.isEmpty else { continue }

            let definition = state.definition
            let executor = self.executor
            Task {
                do {
                    let result = try await executor.execute(
                        executablePath: cliPath,
                        arguments: definition.statusArgv
                    )
                    let newStatus = definition.parseStatus(result.output, result.exitCode)
                    DispatchQueue.main.async {
                        self.vpnStates[index].status = newStatus
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.vpnStates[index].status = .unknown
                    }
                }
            }
        }
    }

    func startStatusPolling(interval: TimeInterval = 10) {
        stopStatusPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshAllStatuses()
        }
    }

    func stopStatusPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func connect(vpnID: String, completion: @escaping @Sendable () -> Void = {}) {
        guard licenseManager.isPaid else {
            completion()
            return
        }
        guard let index = vpnStates.firstIndex(where: { $0.id == vpnID }),
              let cliPath = vpnStates[index].detectedCLIPath else {
            completion()
            return
        }
        guard vpnStates[index].definition.executionTier == .nonElevated else {
            completion()
            return
        }

        let argv = vpnStates[index].definition.connectArgv
        let executor = self.executor
        Task { @Sendable in
            _ = try? await executor.execute(
                executablePath: cliPath,
                arguments: argv
            )
            DispatchQueue.main.async {
                self.refreshAllStatuses()
                completion()
            }
        }
    }

    func disconnect(vpnID: String, completion: @escaping @Sendable () -> Void = {}) {
        guard licenseManager.isPaid else {
            completion()
            return
        }
        guard let index = vpnStates.firstIndex(where: { $0.id == vpnID }),
              let cliPath = vpnStates[index].detectedCLIPath else {
            completion()
            return
        }
        guard vpnStates[index].definition.executionTier == .nonElevated else {
            completion()
            return
        }

        let argv = vpnStates[index].definition.disconnectArgv
        let executor = self.executor
        Task { @Sendable in
            _ = try? await executor.execute(
                executablePath: cliPath,
                arguments: argv
            )
            DispatchQueue.main.async {
                self.refreshAllStatuses()
                completion()
            }
        }
    }

    func setEnabled(vpnID: String, enabled: Bool) {
        guard let index = vpnStates.firstIndex(where: { $0.id == vpnID }) else { return }
        vpnStates[index].isEnabled = enabled
    }
}
