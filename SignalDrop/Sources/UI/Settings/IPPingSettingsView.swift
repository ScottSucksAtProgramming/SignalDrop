import SwiftUI

struct IPPingSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    private let intervalOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
    ]

    var body: some View {
        Form {
            if !licenseManager.isPaid {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text(String(localized: "Upgrade to unlock IP & Latency features"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(String(localized: "Paid feature. Upgrade to access IP and latency settings."))
            }

            Section {
                ipRefreshSettings
            } header: {
                Text(String(localized: "External IP"))
            }

            Section {
                pingSettings
            } header: {
                Text(String(localized: "Latency"))
            }
        }
        .padding()
        .disabled(!licenseManager.isPaid)
    }

    @ViewBuilder
    private var ipRefreshSettings: some View {
        Picker(String(localized: "Refresh mode"), selection: $settingsStore.ipRefreshMode) {
            Text(String(localized: "On demand")).tag(IPRefreshMode.onDemand)
            Text(String(localized: "Automatic")).tag(IPRefreshMode.timed)
        }
        .accessibilityLabel(String(localized: "External IP refresh mode"))

        Picker(String(localized: "Refresh interval"), selection: $settingsStore.ipRefreshInterval) {
            ForEach(intervalOptions, id: \.1) { option in
                Text(String(localized: "\(option.0)")).tag(option.1)
            }
        }
        .accessibilityLabel(String(localized: "External IP refresh interval"))
    }

    @ViewBuilder
    private var pingSettings: some View {
        Toggle(String(localized: "Show ping latency"), isOn: $settingsStore.showPing)
            .accessibilityLabel(String(localized: "Show ping latency indicator"))

        TextField(String(localized: "Ping target"), text: $settingsStore.pingTarget)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(String(localized: "Ping target host"))
            .accessibilityHint(String(localized: "IP address or hostname to measure latency to"))
    }
}
