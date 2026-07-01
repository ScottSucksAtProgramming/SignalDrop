import SwiftUI

struct NetworkDetailsSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    private var isLocked: Bool { !licenseManager.isPaid }

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Network name (SSID)"), isOn: $settingsStore.showNetworkName)
                    .accessibilityLabel(String(localized: "Show network name"))
                Toggle(String(localized: "Signal strength"), isOn: $settingsStore.showSignalStrength)
                    .accessibilityLabel(String(localized: "Show signal strength"))
            } header: {
                Text(String(localized: "Basic Details"))
            }

            Section {
                if isLocked {
                    PaidFeatureNotice(
                        icon: "network",
                        title: String(localized: "Advanced Details"),
                        message: String(localized: "Upgrade to see band, channel, link speed, BSSID, DNS, and more."),
                        color: .green
                    )

                    Group {
                        lockedToggle(String(localized: "Band / Frequency"))
                        lockedToggle(String(localized: "Channel"))
                        lockedToggle(String(localized: "Link speed"))
                        lockedToggle(String(localized: "BSSID"))
                        lockedToggle(String(localized: "DNS servers"))
                        lockedToggle(String(localized: "Gateway"))
                        lockedToggle(String(localized: "Subnet mask"))
                    }
                    .opacity(0.4)
                } else {
                    Toggle(String(localized: "Band / Frequency"), isOn: $settingsStore.showBand)
                        .accessibilityLabel(String(localized: "Show band and frequency"))
                    Toggle(String(localized: "Channel"), isOn: $settingsStore.showChannel)
                        .accessibilityLabel(String(localized: "Show channel number"))
                    Toggle(String(localized: "Link speed"), isOn: $settingsStore.showLinkSpeed)
                        .accessibilityLabel(String(localized: "Show link speed"))
                    Toggle(String(localized: "BSSID"), isOn: $settingsStore.showBSSID)
                        .accessibilityLabel(String(localized: "Show BSSID"))
                    Toggle(String(localized: "DNS servers"), isOn: $settingsStore.showDNS)
                        .accessibilityLabel(String(localized: "Show DNS servers"))
                    Toggle(String(localized: "Gateway"), isOn: $settingsStore.showGateway)
                        .accessibilityLabel(String(localized: "Show gateway address"))
                    Toggle(String(localized: "Subnet mask"), isOn: $settingsStore.showSubnet)
                        .accessibilityLabel(String(localized: "Show subnet mask"))
                }
            } header: {
                HStack {
                    Text(String(localized: "Advanced Details"))
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityLabel(String(localized: "Requires paid upgrade"))
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func lockedToggle(_ label: String) -> some View {
        Toggle(label, isOn: .constant(false))
            .disabled(true)
            .accessibilityLabel(String(localized: "\(label), locked"))
    }
}
