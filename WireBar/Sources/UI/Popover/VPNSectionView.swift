import SwiftUI
import AppKit

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
        let visibleStates = vpnManager.vpnStates.filter { !settingsStore.hiddenVPNs.contains($0.id) }

        if vpnManager.vpnStates.isEmpty {
            Text(String(localized: "No VPNs configured"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(localized: "No VPNs configured"))
        } else if visibleStates.isEmpty {
            Text(String(localized: "All VPNs hidden — check Settings to show them"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(localized: "All VPNs are hidden in Settings"))
        } else {
            ForEach(visibleStates) { vpnState in
                vpnRow(for: vpnState)
            }

            if settingsStore.showMultiVPNWarning && vpnManager.hasMultipleConnected {
                multiVPNWarning
            }
        }
    }

    @ViewBuilder
    private func vpnRow(for vpnState: VPNState) -> some View {
        Button {
            handleTap(vpnState)
        } label: {
            HStack {
                Circle()
                    .fill(statusColor(for: vpnState.status))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                Image(systemName: vpnState.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(vpnState.displayName)
                    .font(.caption)

                Spacer()

                Image(systemName: "arrow.up.forward.app")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(vpnAccessibilityLabel(for: vpnState))
        .accessibilityHint(String(localized: "Opens VPN controls"))
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

    private func handleTap(_ vpnState: VPNState) {
        switch settingsStore.vpnTapAction {
        case .openApp:
            if let bundleID = vpnState.providerBundleIdentifier,
               let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
            } else {
                openSystemVPNSettings()
            }
        case .openSystemSettings:
            openSystemVPNSettings()
        }
    }

    private func openSystemVPNSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func statusColor(for status: VPNConnectionStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnecting: return .orange
        case .disconnected: return .red
        case .unknown: return .gray
        }
    }

    private func vpnAccessibilityLabel(for vpnState: VPNState) -> String {
        let statusText: String = switch vpnState.status {
        case .connected: String(localized: "connected")
        case .connecting: String(localized: "connecting")
        case .disconnecting: String(localized: "disconnecting")
        case .disconnected: String(localized: "disconnected")
        case .unknown: String(localized: "unknown status")
        }
        return "\(vpnState.displayName): \(statusText)"
    }
}
