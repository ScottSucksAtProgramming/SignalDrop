import SwiftUI

struct IPPingSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    private var isLocked: Bool { !licenseManager.isPaid }

    private let intervalOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
    ]

    var body: some View {
        Form {
            if isLocked {
                PaidFeatureNotice(
                    icon: "globe",
                    title: String(localized: "IP & Latency"),
                    message: String(localized: "Upgrade to track your external IP and monitor network latency."),
                    color: .purple
                )
            }

            Section {
                if isLocked {
                    Group {
                        lockedPicker(String(localized: "Refresh mode"), value: String(localized: "On demand"))
                        lockedPicker(String(localized: "Refresh interval"), value: String(localized: "1 minute"))
                    }
                    .opacity(0.4)
                } else {
                    ipRefreshSettings
                }
            } header: {
                Text(String(localized: "External IP"))
            }

            Section {
                if isLocked {
                    Group {
                        Toggle(String(localized: "Show ping latency"), isOn: .constant(false))
                            .disabled(true)
                        LabeledContent(String(localized: "Ping target")) {
                            Text("1.1.1.1")
                        }
                    }
                    .opacity(0.4)
                } else {
                    pingSettings
                }
            } header: {
                Text(String(localized: "Latency"))
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func lockedPicker(_ label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .foregroundStyle(.secondary)
        }
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
