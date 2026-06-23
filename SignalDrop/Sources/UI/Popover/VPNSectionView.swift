import SwiftUI

struct VPNSectionView: View {
    @ObservedObject var vpnManager: VPNManager
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "VPN"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            if !licenseManager.isPaid {
                paidFeatureHint
            } else {
                vpnList
            }
        }
    }

    @ViewBuilder
    private var vpnList: some View {
        let enabledStates = vpnManager.vpnStates.filter { settingsStore.enabledVPNs.contains($0.id) }

        if enabledStates.isEmpty {
            Text(String(localized: "No VPNs configured"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(localized: "No VPNs configured"))
        } else {
            ForEach(enabledStates) { vpnState in
                vpnRow(for: vpnState)
            }

            if settingsStore.showMultiVPNWarning && vpnManager.hasMultipleConnected {
                multiVPNWarning
            }
        }
    }

    @ViewBuilder
    private func vpnRow(for vpnState: VPNState) -> some View {
        HStack {
            Circle()
                .fill(statusColor(for: vpnState.status))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(vpnState.definition.displayName)
                    .font(.caption)

                if !vpnState.isCLIInstalled {
                    Text(String(localized: "CLI not found"))
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            if vpnState.isCLIInstalled {
                if vpnState.status == .connecting {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(String(localized: "\(vpnState.definition.displayName) connecting"))
                } else {
                    Toggle("", isOn: Binding(
                        get: { vpnState.status == .connected },
                        set: { newValue in
                            if newValue {
                                vpnManager.connect(vpnID: vpnState.id)
                            } else {
                                vpnManager.disconnect(vpnID: vpnState.id)
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .disabled(vpnState.definition.executionTier == .elevated)
                    .accessibilityLabel(String(localized: "\(vpnState.definition.displayName) VPN toggle"))
                    .accessibilityValue(vpnState.status == .connected ? String(localized: "Connected") : String(localized: "Disconnected"))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(vpnAccessibilityLabel(for: vpnState))
    }

    @ViewBuilder
    private var multiVPNWarning: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.caption2)
            Text(String(localized: "Multiple VPNs active — possible routing conflicts"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Warning: multiple VPNs are active, which may cause routing conflicts"))
    }

    @ViewBuilder
    private var paidFeatureHint: some View {
        HStack {
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(localized: "VPN management requires a paid license"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "VPN management is a paid feature"))
    }

    private func statusColor(for status: VPNConnectionStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        case .unknown: return .gray
        }
    }

    private func vpnAccessibilityLabel(for vpnState: VPNState) -> String {
        if !vpnState.isCLIInstalled {
            return String(localized: "\(vpnState.definition.displayName): CLI not found")
        }
        let statusText: String = switch vpnState.status {
        case .connected: String(localized: "connected")
        case .disconnected: String(localized: "disconnected")
        case .connecting: String(localized: "connecting")
        case .unknown: String(localized: "unknown status")
        }
        return "\(vpnState.definition.displayName): \(statusText)"
    }
}
