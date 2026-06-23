import SwiftUI

struct VPNSettingsView: View {
    @ObservedObject var vpnManager: VPNManager
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    private var isLocked: Bool { !licenseManager.isPaid }

    var body: some View {
        Form {
            if isLocked {
                PaidFeatureNotice(
                    icon: "shield.lefthalf.filled",
                    title: String(localized: "VPN Management"),
                    message: String(localized: "Upgrade to customize VPN visibility, tap actions, and multi-VPN warnings."),
                    color: .orange
                )
            }

            if isLocked {
                Section(String(localized: "Shown VPNs")) {
                    Group {
                        if vpnManager.vpnStates.isEmpty {
                            Text(String(localized: "No VPNs configured in System Settings"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(vpnManager.vpnStates) { vpnState in
                                Toggle(vpnState.displayName, isOn: .constant(false))
                                    .disabled(true)
                            }
                        }
                    }
                    .opacity(0.4)
                }

                Section {
                    Group {
                        LabeledContent(String(localized: "When a VPN is tapped")) {
                            Text(String(localized: "Open the VPN app"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .opacity(0.4)
                }

                Section {
                    Group {
                        Toggle(String(localized: "Show multi-VPN warning"), isOn: .constant(false))
                            .disabled(true)
                    }
                    .opacity(0.4)
                }
            } else {
                vpnToggles
                tapActionPicker
                warningToggle
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var vpnToggles: some View {
        Section(String(localized: "Shown VPNs")) {
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
}
