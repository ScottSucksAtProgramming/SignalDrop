import SwiftUI
import Sparkle

struct AboutView: View {
    let updaterController: SPUStandardUpdaterController

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    if let icon = NSImage(named: NSImage.applicationIconName) {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .accessibilityLabel(String(localized: "WireBar app icon"))
                    }
                    Text(String(localized: "WireBar"))
                        .font(.title2.bold())
                    Text(versionString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
            }

            Section {
                Toggle(
                    String(localized: "Automatically check for updates"),
                    isOn: Binding(
                        get: { updaterController.updater.automaticallyChecksForUpdates },
                        set: { updaterController.updater.automaticallyChecksForUpdates = $0 }
                    )
                )
                .accessibilityLabel(String(localized: "Automatically check for updates"))

                Button(String(localized: "Check for Updates…")) {
                    updaterController.checkForUpdates(nil)
                }
                .accessibilityLabel(String(localized: "Check for updates now"))
            }

            Section {
                AboutLinkRow(
                    icon: "globe",
                    iconColor: .blue,
                    label: String(localized: "Website"),
                    detail: "github.com",
                    url: "https://github.com/ScottSucksAtProgramming/WireBar"
                )
                AboutLinkRow(
                    icon: "person",
                    iconColor: .purple,
                    label: String(localized: "Creator"),
                    detail: "ScottSucksAtProgramming",
                    url: "https://github.com/ScottSucksAtProgramming"
                )
                AboutLinkRow(
                    icon: "ladybug",
                    iconColor: .red,
                    label: String(localized: "Report Bug"),
                    detail: "GitHub",
                    url: "https://github.com/ScottSucksAtProgramming/WireBar/issues"
                )
            }
        }
        .formStyle(.grouped)
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version)"
    }
}

private struct AboutLinkRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let detail: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Label {
                    Text(label)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                Spacer()
                Text(detail)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.up.forward")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityLabel(String(localized: "\(label), opens \(detail)"))
    }
}
