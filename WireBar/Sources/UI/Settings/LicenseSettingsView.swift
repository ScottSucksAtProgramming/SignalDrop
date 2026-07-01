import SwiftUI

struct LicenseSettingsView: View {
    @ObservedObject var licenseManager: LicenseManager
    @State private var licenseKeyInput: String = ""
    @State private var isActivating: Bool = false
    @State private var activationFailed: Bool = false

    private func activateLicense() {
        nonisolated(unsafe) let manager = licenseManager
        let key = licenseKeyInput
        isActivating = true
        activationFailed = false
        Task {
            let success = await manager.activateLicense(key: key)
            await MainActor.run {
                if !success {
                    activationFailed = true
                }
                isActivating = false
            }
        }
    }

    var body: some View {
        Form {
            Section(String(localized: "Current Plan")) {
                LabeledContent(String(localized: "Plan")) {
                    Text(licenseManager.isPaid ? String(localized: "Paid") : String(localized: "Free"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(licenseManager.isPaid ? .green : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            (licenseManager.isPaid ? Color.green : Color.secondary).opacity(0.15),
                            in: Capsule()
                        )
                        .accessibilityLabel(String(localized: "Current plan: \(licenseManager.isPaid ? "Paid" : "Free")"))
                }
                if licenseManager.isPaid, let key = licenseManager.licenseKey {
                    LabeledContent(String(localized: "License Key")) {
                        Text("\(key.prefix(4))••••••••")
                            .accessibilityLabel(String(localized: "License key starting with \(key.prefix(4))"))
                    }
                }
            }

            Section(String(localized: "Activate License")) {
                if !licenseManager.isPaid {
                    TextField(String(localized: "Enter license key"), text: $licenseKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(String(localized: "License key input"))

                    Button {
                        activateLicense()
                    } label: {
                        Text(isActivating ? String(localized: "Activating…") : String(localized: "Activate"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(licenseKeyInput.isEmpty || isActivating)
                    .accessibilityLabel(String(localized: "Activate license"))

                    if activationFailed {
                        Text(String(localized: "Invalid license key. Please try again."))
                            .foregroundStyle(.red)
                            .accessibilityLabel(String(localized: "Activation failed: Invalid license key. Please try again."))
                    }
                } else {
                    Text(String(localized: "Your license is active"))
                        .foregroundStyle(.green)
                        .accessibilityLabel(String(localized: "License is active"))

                    Button(String(localized: "Deactivate License")) {
                        licenseManager.deactivateLicense()
                    }
                    .accessibilityLabel(String(localized: "Deactivate license"))
                }
            }

            Section {
                Link(destination: URL(string: "https://wirebar.app")!) {
                    Label(String(localized: "Get a License"), systemImage: "arrow.up.forward")
                }
                .accessibilityLabel(String(localized: "Get a license at wirebar.app"))
            }
        }
        .formStyle(.grouped)
    }
}
