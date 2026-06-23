import SwiftUI
import Sparkle

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case networkDetails
    case ipLatency
    case vpn
    case notifications
    case shortcuts
    case license
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .networkDetails: String(localized: "Network Details")
        case .ipLatency: String(localized: "IP & Latency")
        case .vpn: String(localized: "VPN")
        case .notifications: String(localized: "Notifications")
        case .shortcuts: String(localized: "Shortcuts")
        case .license: String(localized: "License")
        case .about: String(localized: "About")
        }
    }

    var icon: String {
        switch self {
        case .general: "gear"
        case .networkDetails: "network"
        case .ipLatency: "globe"
        case .vpn: "shield.lefthalf.filled"
        case .notifications: "bell"
        case .shortcuts: "keyboard"
        case .license: "key"
        case .about: "info.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .general: .blue
        case .networkDetails: .green
        case .ipLatency: .purple
        case .vpn: .orange
        case .notifications: .red
        case .shortcuts: .gray
        case .license: .yellow
        case .about: .blue
        }
    }

    var group: Int {
        switch self {
        case .general, .networkDetails, .ipLatency, .vpn: 0
        case .notifications, .shortcuts: 1
        case .license, .about: 2
        }
    }
}

struct SettingsIconLabel: View {
    let tab: SettingsTab

    var body: some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.icon)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(tab.iconColor, in: RoundedRectangle(cornerRadius: 6))
        }
        .tag(tab)
        .accessibilityLabel(tab.title)
    }
}

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager
    @ObservedObject var vpnManager: VPNManager
    let updaterController: SPUStandardUpdaterController

    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section {
                    ForEach(SettingsTab.allCases.filter { $0.group == 0 }) { tab in
                        SettingsIconLabel(tab: tab)
                    }
                }
                Section(String(localized: "Preferences")) {
                    ForEach(SettingsTab.allCases.filter { $0.group == 1 }) { tab in
                        SettingsIconLabel(tab: tab)
                    }
                }
                Section(String(localized: "Other")) {
                    ForEach(SettingsTab.allCases.filter { $0.group == 2 }) { tab in
                        SettingsIconLabel(tab: tab)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            switch selectedTab {
            case .general:
                GeneralSettingsView(settingsStore: settingsStore, licenseManager: licenseManager)
            case .networkDetails:
                NetworkDetailsSettingsView(settingsStore: settingsStore, licenseManager: licenseManager)
            case .ipLatency:
                IPPingSettingsView(settingsStore: settingsStore, licenseManager: licenseManager)
            case .vpn:
                VPNSettingsView(vpnManager: vpnManager, settingsStore: settingsStore, licenseManager: licenseManager)
            case .notifications:
                NotificationSettingsView(settingsStore: settingsStore, licenseManager: licenseManager)
            case .shortcuts:
                KeyboardShortcutsSettingsView(settingsStore: settingsStore, licenseManager: licenseManager)
            case .license:
                LicenseSettingsView(licenseManager: licenseManager)
            case .about:
                AboutView(updaterController: updaterController)
            }
        }
    }
}

struct PaidFeatureNotice: View {
    let icon: String
    let title: String
    let message: String
    var color: Color = .orange

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    var body: some View {
        Form {
            Section(String(localized: "Startup")) {
                Toggle(String(localized: "Launch at login"), isOn: $settingsStore.launchAtLogin)
                    .accessibilityLabel(String(localized: "Launch SignalDrop when you log in"))
            }

            Section(String(localized: "Menu Bar Display")) {
                if licenseManager.isPaid {
                    Toggle(String(localized: "Show network name"), isOn: $settingsStore.menuBarShowNetworkName)
                        .accessibilityLabel(String(localized: "Show Wi-Fi network name in menu bar"))
                    Toggle(String(localized: "Show VPN indicator"), isOn: $settingsStore.menuBarShowVPNIndicator)
                        .accessibilityLabel(String(localized: "Show VPN connection indicator in menu bar"))
                    Toggle(String(localized: "Show IP address"), isOn: $settingsStore.menuBarShowIP)
                        .accessibilityLabel(String(localized: "Show local IP address in menu bar"))
                } else {
                    PaidFeatureNotice(
                        icon: "menubar.rectangle",
                        title: String(localized: "Menu Bar Customization"),
                        message: String(localized: "Upgrade to show network name, VPN status, and IP address in the menu bar."),
                        color: .blue
                    )
                }
            }
        }
        .formStyle(.grouped)
    }
}
