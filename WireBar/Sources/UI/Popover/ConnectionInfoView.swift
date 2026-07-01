import SwiftUI

struct ConnectionInfoView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            connectionHeader
            Divider()
            networkDetails
        }
    }

    @ViewBuilder
    private var connectionHeader: some View {
        HStack {
            Image(systemName: statusIconName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                if settingsStore.showNetworkName {
                    Text(networkName)
                        .font(.headline)
                        .accessibilityLabel(networkNameAccessibilityLabel)
                }

                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if networkMonitor.state.connectionType == .wifi || networkMonitor.state.connectionType == .wifiAndEthernet {
                signalBars
            }
        }
    }

    @ViewBuilder
    private var networkDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ip = networkMonitor.state.localIPAddress {
                DetailRow(
                    label: String(localized: "Local IP"),
                    value: ip,
                    copyable: true
                )
            }

            if settingsStore.showSignalStrength && networkMonitor.state.signalStrength != 0 {
                DetailRow(
                    label: String(localized: "Signal"),
                    value: "\(networkMonitor.state.signalStrength) dBm (\(signalPercentage)%)"
                )
            }

            if settingsStore.showChannel, let channel = networkMonitor.state.channelNumber {
                DetailRow(
                    label: String(localized: "Channel"),
                    value: "\(channel)"
                )
            }

            if settingsStore.showBand, let band = networkMonitor.state.channelBand, band != .unknown {
                DetailRow(
                    label: String(localized: "Band"),
                    value: bandDisplayName(band)
                )
            }

            if settingsStore.showLinkSpeed && networkMonitor.state.transmitRate > 0 {
                DetailRow(
                    label: String(localized: "Link Speed"),
                    value: String(localized: "\(Int(networkMonitor.state.transmitRate)) Mbps")
                )
            }

            if settingsStore.showBSSID, let bssid = networkMonitor.state.bssid {
                DetailRow(
                    label: String(localized: "BSSID"),
                    value: bssid
                )
            }

            if settingsStore.showGateway, let gateway = networkMonitor.state.gatewayAddress {
                DetailRow(
                    label: String(localized: "Gateway"),
                    value: gateway
                )
            }

            if settingsStore.showSubnet, let subnet = networkMonitor.state.subnetMask {
                DetailRow(
                    label: String(localized: "Subnet"),
                    value: subnet
                )
            }

            if settingsStore.showDNS && !networkMonitor.state.dnsServers.isEmpty {
                DetailRow(
                    label: String(localized: "DNS"),
                    value: networkMonitor.state.dnsServers.joined(separator: ", ")
                )
            }
        }
    }

    @ViewBuilder
    private var signalBars: some View {
        let quality = networkMonitor.state.signalQuality
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: index, quality: quality))
                    .frame(width: 4, height: CGFloat(6 + index * 4))
            }
        }
        .accessibilityLabel(signalAccessibilityLabel)
    }

    private var signalPercentage: Int {
        let clamped = min(max(networkMonitor.state.signalStrength, -100), -20)
        return Int(Double(clamped + 100) / 80.0 * 100.0)
    }

    private var networkName: String {
        if let ssid = networkMonitor.state.ssid {
            return ssid
        }
        if networkMonitor.state.isConnected {
            return switch networkMonitor.state.connectionType {
            case .ethernet, .wifiAndEthernet: String(localized: "Ethernet")
            case .wifi: String(localized: "Wi-Fi Connected")
            case .none: String(localized: "Not Connected")
            }
        }
        return String(localized: "Not Connected")
    }

    private var networkNameAccessibilityLabel: String {
        if let ssid = networkMonitor.state.ssid {
            return String(localized: "Connected to \(ssid)")
        }
        if networkMonitor.state.isConnected {
            return String(localized: "Connected via \(connectionStatusText)")
        }
        return String(localized: "Not connected to any network")
    }

    private var statusIconName: String {
        if !networkMonitor.state.isWiFiPoweredOn && networkMonitor.state.connectionType != .ethernet {
            return "wifi.slash"
        }
        switch networkMonitor.state.connectionType {
        case .none: return "wifi.slash"
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector.horizontal"
        case .wifiAndEthernet: return "wifi"
        }
    }

    private var statusColor: Color {
        networkMonitor.state.isConnected ? .green : .secondary
    }

    private var connectionStatusText: String {
        if !networkMonitor.state.isWiFiPoweredOn && networkMonitor.state.connectionType == .none {
            return String(localized: "Wi-Fi Off")
        }
        switch networkMonitor.state.connectionType {
        case .none: return String(localized: "Disconnected")
        case .wifi: return String(localized: "Wi-Fi")
        case .ethernet: return String(localized: "Ethernet")
        case .wifiAndEthernet: return String(localized: "Wi-Fi + Ethernet")
        }
    }

    private var signalAccessibilityLabel: String {
        switch networkMonitor.state.signalQuality {
        case .excellent: return String(localized: "Signal strength: excellent")
        case .good: return String(localized: "Signal strength: good")
        case .fair: return String(localized: "Signal strength: fair")
        case .poor: return String(localized: "Signal strength: poor")
        }
    }

    private func barColor(for index: Int, quality: SignalQuality) -> Color {
        let filledBars: Int = {
            switch quality {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .poor: return 1
            }
        }()
        return index < filledBars ? .primary : .secondary.opacity(0.3)
    }

    private func bandDisplayName(_ band: WLANChannelBand) -> String {
        switch band {
        case .band2GHz: return String(localized: "2.4 GHz")
        case .band5GHz: return String(localized: "5 GHz")
        case .band6GHz: return String(localized: "6 GHz")
        case .unknown: return String(localized: "Unknown")
        }
    }
}
