---
title: "WireBar Lessons Learned"
summary: "Running log of corrections, preferences, and discoveries during WireBar development"
created: 2026-06-22
updated: 2026-06-22
---

# WireBar Lessons Learned

<!-- Append dated one-liners below. When 3+ related lessons accumulate on a topic, extract into a dedicated context file. -->

- 2026-06-23: `SPUStandardUpdaterController` is a plain reference type (not ObservableObject); bind its `automaticallyChecksForUpdates` property via an explicit `Binding(get:set:)` rather than `@ObservedObject` — no Sparkle state mirroring needed in SettingsStore.
- 2026-06-23: When adding a required parameter to a SwiftUI view, search all call sites — `SettingsView` was instantiated in both `AppDelegate.openSettings()` and `WireBarApp.body`; both needed updating.

- 2026-06-22: DNS-based IP lookup (Cloudflare/OpenDNS) is faster, more private, and more reliable than HTTPS APIs for external IP detection.
- 2026-06-22: ICMP ping requires raw sockets and special entitlements on macOS — use TCP-based latency via NWConnection instead.
- 2026-06-22: SMAppService privileged helpers must verify caller code signatures via audit token, or any local process can invoke them.
- 2026-06-22: SMAppService daemons survive app deletion — always provide an uninstall flow.
- 2026-06-22: Location Services authorization is required in Phase 1, not just onboarding — CWInterface.ssid() returns nil without it.
- 2026-06-22: Most VPN CLIs (tailscale, piactl, mullvad) don't need sudo — only wg-quick does. Two-tier execution avoids unnecessary privileged helper usage.
- 2026-06-22: Sparkle EdDSA private key loss is catastrophic — existing installs will never accept updates again. Back up immediately upon generation.
- 2026-06-22: @Observable macro requires macOS 14+ — use ObservableObject/@Published for macOS 13 (Ventura) compatibility.
- 2026-06-22: Swift 6 strict concurrency requires @unchecked Sendable on classes captured in @Sendable closures (e.g. NWPathMonitor.pathUpdateHandler). AppDelegate needs @MainActor annotation.
- 2026-06-22: When xcode-select points to CommandLine Tools, use DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer to target full Xcode without sudo.
- 2026-06-22: XcodeGen regenerates entitlements files — define entitlements via project.yml entitlements.properties to keep them in sync.
- 2026-06-22: CWInterface signal method is rssiValue() not rssi(). Returns dBm as Int.
- 2026-06-22: NWPathMonitor.pathUpdateHandler fires asynchronously — read currentPath on start() to avoid stale initial UI state.
- 2026-06-22: CLLocationManager.requestWhenInUseAuthorization() silently does nothing for debug builds outside /Applications. Users must grant Location Services manually in System Settings during development. Onboarding wizard will handle this for release builds.
- 2026-06-22: CWInterface.ssid() returns nil without Location Services, but channel, signal, and transmitRate still work. Show "Wi-Fi Connected" as fallback instead of "Not Connected" to avoid misleading the user.
- 2026-06-22: Computer-use screenshot filtering hides menu bar status items from apps not in the installed app registry. Debug builds from DerivedData and even copies in /Applications are not recognized by the computer-use tool's app detection. Manual testing of WireBar's menu bar UI requires user confirmation until the app is properly distributed.
- 2026-06-22: WireBar's menu bar icon IS visible in screenshots and clickable, but the popover window is hidden by screenshot filtering for unrecognized apps. The icon is a `(( ))` antenna shape (antenna.radiowaves.left.and.right), located between battery % and memory readout in the menu bar — NOT near the left-side system icons.
- 2026-06-22: Computer-use app detection requires the app to be in /Applications BEFORE session start. Copying mid-session doesn't register. WireBar.app is now in /Applications — new sessions should see it. Use bundle ID `com.scottkostolni.WireBar` if name lookup fails.
- 2026-06-22: CWSecurity in Swift 6 SDK has no .wep case — use .dynamicWEP (lowercase). Case names follow Swift 3+ naming (.dynamicWEP not .DynamicWEP).
- 2026-06-22: CWConfiguration.networkProfiles returns non-optional NSOrderedSet — cast elements to CWNetworkProfile directly, no optional binding needed.
- 2026-06-22: CWInterface.scanForNetworks(withName: nil) blocks for 1-3 seconds — always call off main thread in production.
- 2026-06-22: Computer-use popover visibility — even with Bartender disabled, the popover window from a debug-built app is hidden by screenshot filtering. The icon is visible and clickable, but popover contents require user visual confirmation.
- 2026-06-22: SourceKit false positives are persistent with XcodeGen projects — "Cannot find type X in scope" appears for every new file added, but builds always succeed. Do not treat these as real errors.
- 2026-06-22: NSApp.sendAction(Selector(("showSettingsWindow:"))) does NOT work in menu bar-only apps — there's no app menu responder chain. Use a programmatic NSWindow with NSHostingController instead.
- 2026-06-22: WiFiManager.scan() must run CoreWLAN's scanForNetworks off the main thread — it blocks for 1-3 seconds. Use DispatchQueue.global + main.async callback pattern.
- 2026-06-22: Swift 6 strict concurrency: to send a non-Sendable protocol across isolation boundaries, mark the protocol Sendable and concrete types @unchecked Sendable. Use nonisolated(unsafe) for stored properties captured in async work.
- 2026-06-22: Raw DNS queries via NWConnection UDP work well on macOS — build the packet manually (header + question section), send to port 53, parse response. No need for libresolv or shell commands.
- 2026-06-22: Swift 6 + NWConnection callbacks: closures capturing a CheckedContinuation need thread-safe one-shot handling. Use an NSLock-guarded wrapper class marked @unchecked Sendable (ContinuationGate pattern) to avoid double-resume and satisfy Sendable requirements.
- 2026-06-22: LicenseManager needs internal(set) on isPaid (not private(set)) and must be non-final class so tests can set isPaid=true via @testable import. Phase 6 will replace the stub with real LemonSqueezy SDK.
- 2026-06-22: UX rule for paid-gated settings: show all controls greyed out/disabled so users can see what they'd get with the paid version. Never hide controls completely behind a full overlay — that tells users nothing about the features they're missing.
- 2026-06-23: PrivilegedHelper is a separate build target (tool type in XcodeGen), not just another Swift file in the app. It needs its own Info.plist (SMAuthorizedClients), launchd.plist (MachServices + AssociatedBundleIdentifiers), and must duplicate the XPC protocol locally since it can't import from the main app target.
- 2026-06-23: Two-tier VPN execution: most VPN CLIs (tailscale, piactl) don't need sudo and run from the main app via Process. Only wg-quick needs elevated privileges via the PrivilegedHelper. Keep CLAUDE.md and DESIGN_DECISIONS.md in sync on this — contradictions cause confusion.
- 2026-06-23: VPN CLI auto-detection: check multiple candidate paths (/Applications/X.app/Contents/MacOS/..., /usr/local/bin/..., /opt/homebrew/bin/...) via FileManager.isExecutableFile(atPath:). Inject the file-exists check as a closure for testability.
- 2026-06-23: VPN status parsing differs per CLI: Tailscale uses JSON (BackendState field), PIA uses plain text (connectionstate output), WireGuard has no simple status command. Design VPNDefinition with a parseStatus closure per VPN rather than a universal parser.
- 2026-06-23: CLI-based VPN toggling doesn't work when users manage VPNs through their apps — the apps register system VPN profiles via Network Extension, and CLI commands conflict with app-managed state. Use NEVPNManager/NETunnelProviderManager instead.
- 2026-06-23: NEVPNStatusDidChange notification provides real-time VPN status updates — no polling needed. NEVPNConfigurationChange fires when VPN profiles are added/removed.
- 2026-06-23: NETunnelProviderProtocol.providerBundleIdentifier identifies which VPN app owns a profile — useful for showing provider-specific icons next to user-defined VPN config names.
- 2026-06-23: NETunnelProviderManager.loadAllFromPreferences() only returns VPN configs the calling app created — macOS sandboxes NE per-app. A third-party menu bar app cannot discover or toggle other apps' VPNs via Network Extension. Use `scutil --nc list` (SystemConfiguration) for read-only cross-app VPN discovery.
- 2026-06-23: macOS System Settings deep-link for VPN & Filters page: `x-apple.systempreferences:com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension`. The generic Network page is `com.apple.Network-Settings.extension`.
- 2026-06-23: When filtering items by user preferences (e.g. hidden VPNs), distinguish "none exist" from "all hidden" in the empty state — users need different guidance for each case.
- 2026-06-23: Carbon RegisterEventHotKey requires no Accessibility permission (unlike CGEvent tap and NSEvent.addGlobalMonitorForEvents). Best choice for global hotkeys when consuming keystrokes isn't needed.
- 2026-06-23: Swift 6 strict concurrency: a protocol with @MainActor methods must be marked @MainActor itself, not just the conforming class. Otherwise conformance across actor boundaries causes a build error.
- 2026-06-23: NotificationService must track previous state keyed by VPN id (not just connected count) to detect which specific VPN dropped. Use pairwise/skip-initial for IP change detection.
- 2026-06-23: Hotkey bindings stored in UserDefaults must be seeded with defaults on first run, not left empty — otherwise hotkeys ship dead until the user manually records each one. "Reset to Defaults" must restore to the seeded defaults, not clear to empty.
- 2026-06-23: NSStatusBarButton needs `.imagePosition = .imageLeading` when setting both `.image` and `.title` — without it the title won't render next to the icon.
- 2026-06-23: Sparkle 2.x SPM integration via XcodeGen: add top-level `packages:` block + `dependencies: [package: Sparkle]` on the app target. `SPUStandardUpdaterController(startingUpdater: true, ...)` on `@MainActor AppDelegate` has no Swift 6 concurrency issues. Empty `SUPublicEDKey` does NOT cause test-host abort — tests pass cleanly.
- 2026-06-23: `.tabViewStyle(.grouped)` does NOT exist in SwiftUI for macOS. For System Settings-style sidebar navigation, use `NavigationSplitView` with a `List(selection:)` sidebar. Available macOS 13+.
- 2026-06-23: System Settings-style colored sidebar icons need a white SF Symbol on a colored `RoundedRectangle` background — plain `foregroundStyle(color)` on the icon looks flat and unprofessional.
- 2026-06-23: `.formStyle(.grouped)` on macOS gives the inset rounded-card section appearance (like System Settings). Without it, Forms render flat. Apply to every detail pane in a sidebar settings layout.
- 2026-06-23: Swift 6 region isolation: capturing a non-Sendable `@ObservedObject` in a `Task {}` inside a SwiftUI view triggers "sending risks data races." Fix with `nonisolated(unsafe) let` capture before the Task.
