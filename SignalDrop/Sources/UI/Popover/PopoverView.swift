import SwiftUI

struct PopoverView: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            connectionHeader
            Divider()
            networkDetails
            Divider()
            quickActions
        }
        .padding()
        .frame(width: 300)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Network status popover"))
    }

    @ViewBuilder
    private var connectionHeader: some View {
        HStack {
            Image(systemName: statusIconName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(networkName)
                    .font(.headline)
                    .accessibilityLabel(networkNameAccessibilityLabel)

                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            signalBars
        }
    }

    @ViewBuilder
    private var networkDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ip = networkMonitor.state.localIPAddress {
                DetailRow(
                    label: String(localized: "Local IP"),
                    value: ip
                )
            }

            if let channel = networkMonitor.state.channelNumber {
                DetailRow(
                    label: String(localized: "Channel"),
                    value: "\(channel)"
                )
            }

            if networkMonitor.state.signalStrength != 0 {
                DetailRow(
                    label: String(localized: "Signal"),
                    value: "\(networkMonitor.state.signalStrength) dBm"
                )
            }
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        HStack {
            Spacer()
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gear")
                Text(String(localized: "Settings"))
            }
            .accessibilityLabel(String(localized: "Open settings"))
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
        switch networkMonitor.state.connectionType {
        case .none:
            return "wifi.slash"
        case .wifi:
            return "wifi"
        case .ethernet:
            return "cable.connector.horizontal"
        case .wifiAndEthernet:
            return "wifi"
        }
    }

    private var statusColor: Color {
        networkMonitor.state.isConnected ? .green : .secondary
    }

    private var connectionStatusText: String {
        switch networkMonitor.state.connectionType {
        case .none:
            return String(localized: "Disconnected")
        case .wifi:
            return String(localized: "Wi-Fi")
        case .ethernet:
            return String(localized: "Ethernet")
        case .wifiAndEthernet:
            return String(localized: "Wi-Fi + Ethernet")
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
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontDesign(.monospaced)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
