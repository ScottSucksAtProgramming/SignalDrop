import SwiftUI

struct VPNSettingsView: View {
    @ObservedObject var vpnManager: VPNManager
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    var body: some View {
        Form {
            if !licenseManager.isPaid {
                paidOverlay
            } else {
                vpnToggles
                tapActionPicker
                warningToggle
            }
        }
        .padding()
    }

    @ViewBuilder
    private var vpnToggles: some View {
        Section {
            Text(String(localized: "Shown VPNs"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if vpnManager.vpnStates.isEmpty {
                Text(String(localized: "No VPNs configured in System Settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(localized: "No VPNs configured in System Settings"))
            } else {
                ForEach(vpnManager.vpnStates) { vpnState in
                    Toggle(vpnState.displayName, isOn: Binding(
                        get: { !settingsStore.hiddenVPNs.contains(vpnState.id) },
                        set: { shown in
                            if shown {
                                settingsStore.hiddenVPNs.remove(vpnState.id)
                            } else {
                                settingsStore.hiddenVPNs.insert(vpnState.id)
                            }
                        }
                    ))
                    .accessibilityLabel(String(localized: "Show \(vpnState.displayName) in the popover"))
                }
            }
        }
    }

    @ViewBuilder
    private var tapActionPicker: some View {
        Section {
            Picker(String(localized: "When a VPN is tapped"), selection: $settingsStore.vpnTapAction) {
                Text(String(localized: "Open the VPN app")).tag(VPNTapAction.openApp)
                Text(String(localized: "Open System Settings")).tag(VPNTapAction.openSystemSettings)
            }
            .accessibilityLabel(String(localized: "Choose what happens when you tap a VPN"))
        }
    }

    @ViewBuilder
    private var warningToggle: some View {
        Section {
            Toggle(String(localized: "Show multi-VPN warning"), isOn: $settingsStore.showMultiVPNWarning)
                .accessibilityLabel(String(localized: "Show warning when multiple VPNs are active"))
        }
    }

    @ViewBuilder
    private var paidOverlay: some View {
        VStack(spacing: 12) {
            Toggle(String(localized: "Show VPNs in the popover"), isOn: .constant(true))
                .disabled(true)
            Toggle(String(localized: "Show multi-VPN warning"), isOn: .constant(true))
                .disabled(true)
        }
        .opacity(0.5)
        .overlay(alignment: .bottom) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                Text(String(localized: "VPN settings require a paid license"))
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
        .accessibilityLabel(String(localized: "VPN settings are a paid feature"))
    }
}
