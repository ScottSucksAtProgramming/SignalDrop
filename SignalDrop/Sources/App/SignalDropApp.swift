import SwiftUI

@main
struct SignalDropApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settingsStore: appDelegate.settingsStore,
                licenseManager: appDelegate.licenseManager,
                vpnManager: appDelegate.vpnManager
            )
        }
    }
}
