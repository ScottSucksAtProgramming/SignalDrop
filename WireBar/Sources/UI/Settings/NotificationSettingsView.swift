import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    private var isLocked: Bool { !licenseManager.isPaid }

    var body: some View {
        Form {
            if isLocked {
                PaidFeatureNotice(
                    icon: "bell.badge",
                    title: String(localized: "Notifications"),
                    message: String(localized: "Upgrade to get alerts for VPN drops, Wi-Fi disconnections, and IP changes."),
                    color: .red
                )
            }

            Section(String(localized: "Alerts")) {
                if isLocked {
                    Group {
                        Toggle(String(localized: "VPN disconnection alerts"), isOn: .constant(false))
                        Toggle(String(localized: "Wi-Fi disconnection alerts"), isOn: .constant(false))
                        Toggle(String(localized: "External IP change alerts"), isOn: .constant(false))
                        Toggle(String(localized: "Network change alerts"), isOn: .constant(false))
                    }
                    .disabled(true)
                    .opacity(0.4)
                } else {
                    Toggle(String(localized: "VPN disconnection alerts"), isOn: $settingsStore.notifyVPNDrop)
                        .accessibilityLabel(String(localized: "Notify when a VPN disconnects"))
                    Toggle(String(localized: "Wi-Fi disconnection alerts"), isOn: $settingsStore.notifyWiFiDisconnect)
                        .accessibilityLabel(String(localized: "Notify when Wi-Fi disconnects"))
                    Toggle(String(localized: "External IP change alerts"), isOn: $settingsStore.notifyIPChange)
                        .accessibilityLabel(String(localized: "Notify when your external IP address changes"))
                    Toggle(String(localized: "Network change alerts"), isOn: $settingsStore.notifyNetworkChange)
                        .accessibilityLabel(String(localized: "Notify when you switch to a different Wi-Fi network"))
                }
            }
        }
        .formStyle(.grouped)
    }
}
