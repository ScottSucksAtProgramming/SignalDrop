import SwiftUI

@main
struct WireBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settingsStore: appDelegate.settingsStore,
                licenseManager: appDelegate.licenseManager,
                vpnManager: appDelegate.vpnManager,
                updaterController: appDelegate.updaterController
            )
        }
    }
}
