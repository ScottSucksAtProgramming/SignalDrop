---
title: "SignalDrop Lessons Learned"
summary: "Running log of corrections, preferences, and discoveries during SignalDrop development"
created: 2026-06-22
updated: 2026-06-22
---

# SignalDrop Lessons Learned

<!-- Append dated one-liners below. When 3+ related lessons accumulate on a topic, extract into a dedicated context file. -->

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
- 2026-06-22: Computer-use screenshot filtering hides menu bar status items from apps not in the installed app registry. Debug builds from DerivedData and even copies in /Applications are not recognized by the computer-use tool's app detection. Manual testing of SignalDrop's menu bar UI requires user confirmation until the app is properly distributed.
- 2026-06-22: SignalDrop's menu bar icon IS visible in screenshots and clickable, but the popover window is hidden by screenshot filtering for unrecognized apps. The icon is a `(( ))` antenna shape (antenna.radiowaves.left.and.right), located between battery % and memory readout in the menu bar — NOT near the left-side system icons.
- 2026-06-22: Computer-use app detection requires the app to be in /Applications BEFORE session start. Copying mid-session doesn't register. SignalDrop.app is now in /Applications — new sessions should see it. Use bundle ID `com.scottkostolni.SignalDrop` if name lookup fails.
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
