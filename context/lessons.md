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
