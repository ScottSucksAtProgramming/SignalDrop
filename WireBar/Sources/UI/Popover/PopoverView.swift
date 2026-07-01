import SwiftUI

struct PopoverView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var wifiManager: WiFiManager
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var ipService: IPService
    @ObservedObject var pingService: PingService
    @ObservedObject var vpnManager: VPNManager
    @ObservedObject var licenseManager: LicenseManager
    var onOpenSettings: () -> Void = {}

    private var isWiFiOff: Bool {
        !networkMonitor.state.isWiFiPoweredOn
            && networkMonitor.state.connectionType != .ethernet
            && networkMonitor.state.connectionType != .wifiAndEthernet
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isWiFiOff {
                    wifiOffContent
                } else {
                    normalContent
                }

                Divider()
                quickActions
            }
            .padding()
        }
        .frame(width: 320)
        .frame(maxHeight: 500)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Network status popover"))
    }

    @ViewBuilder
    private var wifiOffContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(String(localized: "Wi-Fi is off"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)

        Divider()
        VPNSectionView(
            vpnManager: vpnManager,
            settingsStore: settingsStore,
            licenseManager: licenseManager
        )
    }

    @ViewBuilder
    private var normalContent: some View {
        CollapsibleSectionView(
            title: String(localized: "Connection"),
            isCollapsed: $settingsStore.connectionInfoCollapsed,
            isPaid: licenseManager.isPaid
        ) {
            ConnectionInfoView(
                networkMonitor: networkMonitor,
                settingsStore: settingsStore
            )
        }

        if networkMonitor.state.isEthernetConnected {
            Divider()
            EthernetInfoView(networkMonitor: networkMonitor)
        }

        Divider()
        CollapsibleSectionView(
            title: String(localized: "IP & Latency"),
            isCollapsed: $settingsStore.ipPingCollapsed,
            isPaid: licenseManager.isPaid
        ) {
            IPPingView(
                ipService: ipService,
                pingService: pingService,
                licenseManager: licenseManager,
                settingsStore: settingsStore
            )
        }

        Divider()
        CollapsibleSectionView(
            title: String(localized: "VPN"),
            isCollapsed: $settingsStore.vpnCollapsed,
            isPaid: licenseManager.isPaid
        ) {
            VPNSectionView(
                vpnManager: vpnManager,
                settingsStore: settingsStore,
                licenseManager: licenseManager
            )
        }

        if networkMonitor.state.isWiFiPoweredOn {
            Divider()
            CollapsibleSectionView(
                title: String(localized: "Networks"),
                isCollapsed: $settingsStore.networkListCollapsed,
                isPaid: licenseManager.isPaid
            ) {
                NetworkListView(wifiManager: wifiManager)
            }
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        HStack {
            wifiToggle

            Spacer()

            copyAllButton

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gear")
                Text(String(localized: "Settings"))
            }
            .accessibilityLabel(String(localized: "Open settings"))
        }
    }

    @ViewBuilder
    private var wifiToggle: some View {
        Toggle(isOn: Binding(
            get: { wifiManager.isWiFiPoweredOn },
            set: { _ in wifiManager.togglePower() }
        )) {
            Label(String(localized: "Wi-Fi"), systemImage: "wifi")
                .font(.caption)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .accessibilityLabel(String(localized: "Wi-Fi power"))
        .accessibilityValue(wifiManager.isWiFiPoweredOn ? String(localized: "On") : String(localized: "Off"))
    }

    @ViewBuilder
    private var copyAllButton: some View {
        Button {
            copyAllNetworkInfo()
        } label: {
            Image(systemName: "doc.on.doc")
            Text(String(localized: "Copy All"))
        }
        .font(.caption)
        .accessibilityLabel(String(localized: "Copy all network information to clipboard"))
    }

    private func copyAllNetworkInfo() {
        var lines: [String] = []

        if let ssid = networkMonitor.state.ssid {
            lines.append("SSID: \(ssid)")
        }
        lines.append("Signal: \(networkMonitor.state.signalStrength) dBm (\(networkMonitor.state.signalQuality.label))")

        if let localIP = ipService.localIP {
            lines.append("Local IP: \(localIP)")
        }
        if let externalIP = ipService.externalIP {
            lines.append("External IP: \(externalIP)")
        }

        if networkMonitor.state.isEthernetConnected, let ethIP = networkMonitor.state.ethernetIPAddress {
            lines.append("Ethernet IP: \(ethIP)")
        }

        for vpn in vpnManager.vpnStates {
            lines.append("VPN: \(vpn.displayName) (\(vpn.status.label))")
        }

        let text = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var copyable: Bool = false

    @State private var showCopied = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            if copyable {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showCopied ? String(localized: "Copied!") : value)
                            .font(.caption)
                            .fontDesign(.monospaced)
                        if !showCopied {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "\(label): \(value). Click to copy."))
                .accessibilityHint(String(localized: "Copies \(value) to clipboard"))
            } else {
                Text(value)
                    .font(.caption)
                    .fontDesign(.monospaced)
            }
        }
        .accessibilityElement(children: copyable ? .contain : .combine)
        .accessibilityLabel(copyable ? "" : "\(label): \(value)")
    }
}

extension SignalQuality {
    var label: String {
        switch self {
        case .excellent: return String(localized: "Excellent")
        case .good: return String(localized: "Good")
        case .fair: return String(localized: "Fair")
        case .poor: return String(localized: "Poor")
        }
    }
}

extension VPNConnectionStatus {
    var label: String {
        switch self {
        case .connected: return String(localized: "Connected")
        case .connecting: return String(localized: "Connecting")
        case .disconnecting: return String(localized: "Disconnecting")
        case .disconnected: return String(localized: "Disconnected")
        case .unknown: return String(localized: "Unknown")
        }
    }
}
