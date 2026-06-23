import SwiftUI

struct IPPingView: View {
    @ObservedObject var ipService: IPService
    @ObservedObject var pingService: PingService
    @ObservedObject var licenseManager: LicenseManager
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text(String(localized: "IP & Latency"))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            if let localIP = ipService.localIP {
                DetailRow(
                    label: String(localized: "Local IP"),
                    value: localIP,
                    copyable: true
                )
            }

            if licenseManager.isPaid {
                externalIPRow
                pingRow
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "IP address and latency details"))
    }

    @ViewBuilder
    private var externalIPRow: some View {
        switch ipService.externalIPStatus {
        case .idle:
            EmptyView()
        case .loading:
            HStack {
                Text(String(localized: "External IP"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(String(localized: "Loading external IP"))
            }
        case .loaded(let ip):
            DetailRow(
                label: String(localized: "External IP"),
                value: ip,
                copyable: true
            )
        case .unavailable:
            HStack {
                Text(String(localized: "External IP"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(localized: "Unavailable"))
                    .font(.caption)
                    .foregroundStyle(.red)
                Button {
                    ipService.clearCache()
                    ipService.refreshExternalIP()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Retry fetching external IP"))
            }
        }
    }

    @ViewBuilder
    private var pingRow: some View {
        if settingsStore.showPing {
            HStack {
                Text(String(localized: "Latency"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                switch pingService.status {
                case .idle:
                    Text(String(localized: "—"))
                        .font(.caption)
                        .fontDesign(.monospaced)
                case .measuring:
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(String(localized: "Measuring latency"))
                case .result(let ms):
                    Text(String(localized: "\(String(format: "%.1f", ms)) ms"))
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(latencyColor(ms))
                case .error:
                    Text(String(localized: "Timeout"))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(pingAccessibilityLabel)
        }
    }

    private func latencyColor(_ ms: Double) -> Color {
        switch ms {
        case 0..<50: return .green
        case 50..<100: return .yellow
        default: return .red
        }
    }

    private var pingAccessibilityLabel: String {
        switch pingService.status {
        case .idle: return String(localized: "Latency: not measured")
        case .measuring: return String(localized: "Measuring latency")
        case .result(let ms): return String(localized: "Latency: \(String(format: "%.1f", ms)) milliseconds")
        case .error: return String(localized: "Latency: timed out")
        }
    }
}
