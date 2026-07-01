import Foundation

/// Reads system VPN configurations via `scutil --nc list`. This is read-only —
/// WireBar discovers and shows the status of VPNs owned by other apps
/// (WireGuard, Tailscale, …) but never toggles them (macOS sandboxes that).
struct SystemVPNProvider: VPNConfigurationProviding {
    func loadConfigurations() -> [VPNConfigurationInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "list"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return SystemVPNProvider.parse(output)
    }

    /// Pure parser for `scutil --nc list` output. Each VPN line looks like:
    /// `* (Disconnected)  F5F86763-…  VPN (com.wireguard.macos) "Rivendell" [VPN:com.wireguard.macos]`
    /// Lines without a service UUID (e.g. the header) are skipped.
    static func parse(_ output: String) -> [VPNConfigurationInfo] {
        output.split(separator: "\n").compactMap { line -> VPNConfigurationInfo? in
            let line = String(line)

            guard let uuid = firstMatch(in: line, pattern: "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}", group: 0),
                  let statusText = firstMatch(in: line, pattern: "\\(([^)]+)\\)", group: 1),
                  let name = firstMatch(in: line, pattern: "\"([^\"]+)\"", group: 1) else {
                return nil
            }

            // Provider bundle id from the trailing bracket, e.g. [VPN:com.wireguard.macos].
            let bundleID = firstMatch(in: line, pattern: "\\[[^:\\]]+:([^\\]]+)\\]", group: 1)

            return VPNConfigurationInfo(
                id: uuid,
                displayName: name,
                status: status(from: statusText),
                providerBundleIdentifier: bundleID
            )
        }
    }

    private static func status(from text: String) -> VPNConnectionStatus {
        switch text.trimmingCharacters(in: .whitespaces).lowercased() {
        case "connected": return .connected
        case "connecting": return .connecting
        case "disconnecting": return .disconnecting
        case "disconnected": return .disconnected
        default: return .unknown
        }
    }

    private static func firstMatch(in string: String, pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: group), in: string) else {
            return nil
        }
        return String(string[range])
    }
}
