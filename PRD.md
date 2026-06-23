# PRD: SignalDrop - macOS Menu Bar Network Utility

## Problem Statement

macOS provides basic Wi-Fi status in the menu bar, but it lacks integrated VPN visibility, quick VPN toggling, and detailed network information in a single, always-accessible interface. Users who manage multiple VPN connections (WireGuard, Tailscale, PIA, etc.) must switch between separate apps to check status and toggle connections. There is no unified way to see Wi-Fi status, VPN states, local/external IP addresses, and network details at a glance — or to act on them without opening System Settings or multiple VPN clients.

## Solution

SignalDrop is a lightweight macOS menu bar utility that consolidates Wi-Fi management, VPN monitoring and control, and network information into a single SwiftUI popover. Users see their network status at a glance in the menu bar (configurable: Wi-Fi icon, network name, VPN indicators, IP address) and click to open a rich popover with full connection details, VPN toggle switches, available Wi-Fi networks, and quick actions. The app supports a freemium model — core Wi-Fi features are free, while VPN management and advanced features require a one-time paid license.

## User Stories

### Menu Bar Status
1. As a user, I want to see my Wi-Fi network name in the menu bar, so that I always know which network I'm connected to.
2. As a user, I want to see my Wi-Fi signal strength icon in the menu bar, so that I can gauge connection quality at a glance.
3. As a user, I want to configure what information appears in the menu bar, so that I can prioritize what matters to me (network name, VPN indicators, IP address).
4. As a user, I want to see a wired connection icon when I'm on Ethernet, so that I know my connection type without opening the popover.
5. As a user, I want to see a disabled Wi-Fi icon when Wi-Fi is turned off, so that I have a clear visual indicator.
6. As a paid user, I want to see VPN status indicators in the menu bar, so that I know at a glance whether my VPNs are active.
7. As a paid user, I want to see my IP address in the menu bar, so that I can monitor it without opening the popover.

### Popover - Connection Info
8. As a user, I want to see my current network name and signal strength in the popover, so that I have detailed connection info.
9. As a user, I want to see my local IP address, so that I can use it for local network tasks.
10. As a paid user, I want to see my external/public IP address, so that I can verify my internet-facing identity.
11. As a paid user, I want to see advanced network details (band, channel, link speed, BSSID, DNS, gateway, subnet), so that I can troubleshoot network issues.
12. As a paid user, I want to configure which network details are shown, so that I only see what's relevant to me.
13. As a user, I want to see Ethernet connection info when plugged in, so that I have full visibility regardless of connection type.
14. As a user, I want to see all active connections when Wi-Fi and Ethernet are both active, so that I understand my full network state.
15. As a user, I want to see which interface is the primary route, so that I know where my traffic is actually going.

### Popover - VPN Management
16. As a paid user, I want to see the status of each configured VPN in the popover, so that I know which are connected.
17. As a paid user, I want to toggle VPNs on and off with a single click, so that I don't have to open separate VPN apps.
18. As a paid user, I want to see a warning when multiple VPNs are active simultaneously, so that I'm aware of potential routing conflicts.
19. As a paid user, I want to disable the multiple-VPN warning, so that it doesn't bother me if I intentionally run multiple VPNs.
20. ~~As a paid user, I want to see a clear error state when a VPN CLI is not found, so that I know to reinstall or reconfigure.~~ *(Obsolete — VPNs are now discovered via macOS Network Extension framework, not CLI detection.)*

### Wi-Fi Network Switching
21. As a user, I want to see a list of available Wi-Fi networks, so that I can choose which to connect to.
22. As a user, I want known/saved networks listed at the top, so that my frequently-used networks are easy to find.
23. As a user, I want networks sorted by signal strength, so that I can pick the strongest connection.
24. As a user, I want to see signal strength and security type for each network, so that I can make informed choices.
25. As a user, I want to join a saved network with one click, so that switching is fast.
26. As a user, I want to enter a password for unknown networks, so that I can join new networks from the app.
27. As a user, I want to see a checkmark on my currently connected network, so that I can identify it in the list.
28. As a user, I want to toggle Wi-Fi on and off, so that I can disable wireless when not needed.

### IP Address Features
29. As a paid user, I want to choose between timed refresh and on-demand refresh for my external IP, so that I control network usage.
30. As a paid user, I want my external IP to auto-refresh when a VPN connects or disconnects, so that I can verify my traffic is routing correctly.
31. As a user, I want to click an IP address to copy it to clipboard, so that I can quickly paste it elsewhere.
32. As a paid user, I want to see "Unavailable" with a retry button if the IP fetch fails, so that I have a clear path to recover.

### Ping / Latency
33. As a paid user, I want to see my ping latency to a DNS server, so that I can quickly assess connection health.
34. As a paid user, I want to configure the ping target, so that I can measure latency to a server I care about.
35. As a paid user, I want to toggle the ping indicator on and off, so that I can hide it if I don't need it.

### Notifications
36. As a paid user, I want to be notified when a VPN connection drops, so that I'm aware of potential privacy/security exposure.
37. As a paid user, I want to be notified when my IP address changes, so that I can verify expected behavior.
38. As a paid user, I want to be notified when Wi-Fi disconnects, so that I know I've lost connectivity.
39. As a paid user, I want to individually toggle each notification type, so that I only get alerts I care about.

### Keyboard Shortcuts
40. As a paid user, I want a global hotkey to open/close the popover, so that I can access it without finding the menu bar icon.
41. As a paid user, I want keyboard shortcuts to toggle specific VPNs, so that I can manage VPNs without the mouse.
42. As a paid user, I want keyboard shortcuts to copy IP addresses, so that I can grab network info quickly.
43. As a paid user, I want keyboard shortcuts to toggle Wi-Fi and refresh the external IP, so that common actions are fast.
44. As a paid user, I want to customize all keyboard shortcuts, so that they don't conflict with my other apps.

### VPN Configuration
45. As a paid user, I want the app to auto-detect all VPN configurations on my Mac, so that setup is effortless. *(Uses macOS Network Extension framework — discovers all system VPN profiles automatically.)*
46. ~~As a paid user, I want to add VPNs from a curated list of popular providers, so that I don't have to figure out CLI commands myself.~~ *(Obsolete — all system VPN profiles are auto-discovered.)*
47. ~~As a paid user, I want to add custom VPNs by specifying CLI commands for status/connect/disconnect, so that I can use any VPN tool.~~ *(Obsolete — replaced by auto-discovery. Custom VPN configurations may be revisited in a future version.)*
47a. ~~As a user who needs a VPN not on the curated list, I want to request support via a GitHub issue template, so that popular VPNs get added in a future update.~~ *(Obsolete — auto-discovery supports any VPN that registers a system profile.)*
48. As a paid user, I want to enable and disable which VPNs are monitored, so that I can hide ones I don't use.

### Settings
49. As a user, I want the app to launch at login automatically, so that it's always available.
50. As a user, I want to configure which network details are visible, so that the popover isn't cluttered.
51. As a user, I want to collapse sections in the popover, so that I can focus on what matters.
52. As a user, I want the app to follow my system dark/light mode, so that it matches my desktop.
53. As a user, I want to opt in to crash reporting, so that I can help improve the app if I choose.
54. As a user, I want crash reporting to be off by default, so that my privacy is respected.

### First-Run Experience
55. As a new user, I want a setup wizard that explains why Location Services is needed, so that I understand the permission prompt.
56. ~~As a new user, I want the app to walk me through installing the privileged helper, so that VPN toggling works from the start.~~ *(Obsolete — Network Extension framework eliminates the need for a privileged helper.)*
57. As a new user, I want the app to detect my installed VPNs and let me confirm which to monitor, so that setup is fast.
58. As a new user, I want to configure my menu bar display preferences during setup, so that the app looks right immediately.

### Licensing and Updates
59. As a free user, I want full Wi-Fi management features without paying, so that the app is useful even before upgrading.
60. As a user, I want to purchase a license from within the app, so that upgrading is frictionless.
61. As a paid user, I want the app to auto-check for updates, so that I always have the latest version.
62. As a user, I want updates to be publicly available to anyone, so that I can stay current without any license gate on the download. *(V1 is a one-time purchase — the license gates features, not updates.)*
63. As a paid user, I want the app to keep working at its last version indefinitely, so that I don't lose functionality I already paid for. *(V1 is a one-time purchase with no renewal. If a V2 upgrade model is introduced, this story covers the V1→V2 transition: V1 licensees stay on the last V1 release.)*

### Utility
64. As a user, I want to copy all network info to clipboard with one click, so that I can share it for tech support.

### Accessibility
65. As a VoiceOver user, I want all elements properly labeled, so that I can use the app with a screen reader.
66. As a user, I want to navigate the entire popover with the keyboard, so that I don't need a mouse.
67. As a user with accessibility needs, I want the app to respect reduced motion and high contrast settings, so that it's comfortable to use.

## Implementation Decisions

### Module Architecture

The app is structured around deep, independently testable modules with clean interfaces:

1. **NetworkMonitor** — Core engine wrapping `NWPathMonitor` and `CoreWLAN`. Publishes a single observable `NetworkState` struct containing all interface info (active interfaces, SSID, signal strength, band, channel, IPs, gateway, DNS, Ethernet status). All other modules consume this rather than querying the system directly. This is the single source of truth for network state.

2. **WiFiManager** — Handles Wi-Fi scanning and network switching via `CoreWLAN`. Scans for available networks, sorts them (known first, then by signal strength), joins known networks with one click, prompts for passwords on unknown networks, toggles Wi-Fi power on/off.

3. **VPNManager** — Manages VPN discovery, real-time status monitoring, and connect/disconnect toggling via Apple's Network Extension framework (`NEVPNManager` / `NETunnelProviderManager`). Auto-discovers all system VPN profiles (any VPN visible in System Settings > VPN). Monitors status changes in real-time via `NEVPNStatusDidChange` notifications and reloads the VPN list on `NEVPNConfigurationChange`. Identifies known VPN providers by `NETunnelProviderProtocol.providerBundleIdentifier` for provider-specific icons. Publishes observable per-VPN connection state. No CLI commands, no privileged helper — the OS handles all privilege escalation natively.

5. **IPService** — Resolves local IP from network interfaces and fetches external IP via DNS-based lookup (Cloudflare DNS as primary, OpenDNS as fallback — no HTTPS API dependency). Supports two user-configurable refresh modes (timed interval, on-demand). Auto-refreshes when VPN state changes. Caches external IP for 30 seconds. Handles fetch failures gracefully.

6. **PingService** — Measures TCP-based latency via `NWConnection` to a user-configurable target (default `1.1.1.1`). Publishes latency in milliseconds. Can be started/stopped independently. (TCP-based rather than ICMP avoids the need for raw socket entitlements.)

7. **LicenseManager** — Integrates LemonSqueezy SDK for license key validation, activation, and expiration checks. Gates paid features with a simple `isPaid` check. Supports offline/cached license validation with a grace period so brief network outages don't lock users out. Handles the purchase-to-activation flow via URL scheme (deep link from LemonSqueezy receipt) or manual license key entry. V1 is a one-time purchase — no renewal model, no update entitlement gate.

8. **HotkeyManager** — Global keyboard shortcut registration and dispatch. Registers user-configured key combinations, maps them to app actions, and persists configuration. Handles conflicts and provides a configuration UI.

9. **NotificationService** — Observes state changes from NetworkMonitor, VPNManager, and IPService. Dispatches macOS user notifications based on per-type user preferences. Each notification type (VPN drop, IP change, Wi-Fi disconnect, network change) is individually toggleable.

10. **SettingsStore** — Centralized `UserDefaults`-backed preferences. Single source of truth for all user configuration: menu bar display options, IP refresh settings, VPN list, notification preferences, hotkey mappings, network detail visibility, diagnostic opt-in.

11. **UI Layer** — SwiftUI views consuming the above modules:
    - **MenuBarController** — `NSStatusItem` rendering with configurable content
    - **PopoverView** — Main popover with collapsible sections, max height scrolling
    - **SettingsView** — Preferences window with tabbed sections
    - **OnboardingView** — First-run wizard flow

### Key Technical Decisions

- **Real-time state via `NWPathMonitor`** — no polling for network changes. System notifications are instant and efficient.
- **CoreWLAN for Wi-Fi operations** — direct API access for scanning, joining, and reading Wi-Fi details. Requires Location Services permission for SSID (Apple requirement on modern macOS).
- **Network Extension framework for VPN management** — uses `NEVPNManager` / `NETunnelProviderManager` to discover, monitor, and toggle all system VPN profiles. Real-time status via `NEVPNStatusDidChange` notifications. No CLI commands, no privileged helper — the OS handles privilege escalation natively. Works with any VPN app that registers a system profile (WireGuard, Tailscale, PIA, Mullvad, NordVPN, corporate VPNs, etc.).
- **Sparkle for auto-updates** — standard macOS update framework. Update feed hosted as XML on GitHub Releases.
- **LemonSqueezy for licensing** — merchant of record handles payment processing and global sales tax. Swift SDK for license validation.
- **Sentry for crash reporting** — deferred to V1.1. When introduced, it will be opt-in only with a per-crash consent dialog; Sentry never initializes unless the user explicitly approves.
- **`String(localized:)` for all user-facing strings** — localization-ready from day one without shipping translations.
- **macOS 13 (Ventura) deployment target** — enables modern SwiftUI features while supporting the vast majority of active Macs through Golden Gate.
- **BSL license** — source visible for trust and auditability, commercial rights protected, converts to Apache 2.0 after 3-4 years.

## Testing Decisions

### Testing Philosophy

Tests should verify external behavior through each module's public interface, not implementation details. A good test for SignalDrop:
- Calls a module's public API and asserts on the observable output
- Does not depend on internal state or private methods
- Uses protocol-based dependency injection to mock system APIs (CoreWLAN, NWPathMonitor, shell execution)
- Is deterministic — no real network calls, no real VPN toggling in tests

### Modules Under Test

1. **NetworkMonitor** — Test that network state updates are correctly published when interfaces change. Mock `NWPathMonitor` and `CWInterface` to simulate Wi-Fi connect/disconnect, Ethernet plug/unplug, and property changes (SSID, signal, band).

2. **WiFiManager** — Test network list sorting (known first, then by signal strength), join flow (known vs. unknown), and Wi-Fi power toggle. Mock `CoreWLAN` interfaces.

3. **VPNManager** — Test VPN discovery, status mapping from `NEVPNStatus`, connect/disconnect dispatch, enabled/disabled filtering, multi-VPN warning logic, and configuration reload handling. Mock the Network Extension framework via a `VPNConfigurationProviding` protocol.

5. **IPService** — Test local IP resolution, external IP fetch with mock DNS responses (Cloudflare primary, OpenDNS fallback), caching behavior (30-second TTL), refresh mode switching, auto-refresh on VPN state change, and failure/retry handling.

6. **PingService** — Test latency reporting with mock `NWConnection` responses (TCP-based), configurable target changes, and start/stop lifecycle.

7. **HotkeyManager** — Test shortcut registration, unregistration, conflict detection, and action dispatch. Mock the global hotkey system API.

8. **NotificationService** — Test that correct notifications fire for VPN drops, IP changes, and Wi-Fi disconnects. Test that per-type toggles suppress notifications when disabled. Mock `UNUserNotificationCenter`.

### Not Tested (verified manually)

- **LicenseManager** — Gate logic tested, but LemonSqueezy SDK integration verified through manual testing and LemonSqueezy's own test mode.
- **SettingsStore** — Thin `UserDefaults` wrapper, verified through UI testing.
- **UI Layer** — SwiftUI views verified through manual testing and accessibility audit.

## Out of Scope

The following are explicitly deferred to future versions (see ROADMAP.md):

- Custom VPN configurations (user-defined VPN profiles) — deferred to a future version; V1 auto-discovers all existing system VPN profiles
- VPN leak detection (DNS leaks, IPv6 leaks, packet-level inspection) — far-future roadmap item

- Speed test (upload/download bandwidth measurement)
- Network connection history / logging
- Personal Hotspot management
- Menu bar icon customization (custom icons/colors)
- macOS desktop or Notification Center widgets
- Popover section reordering (drag and drop)
- Tailscale exit node selection
- PIA server selection
- Setapp distribution channel
- App Store version (reduced feature set)
- macOS Shortcuts / Automator integration
- AppleScript support
- Multi-language translations (app is localization-ready but ships English only)
- Behavioral analytics or usage tracking

## Further Notes

- **Privacy is a core value.** No data is logged to disk. No telemetry unless the user opts in. External IP is resolved via DNS lookup (Cloudflare/OpenDNS) — no third-party HTTPS API involved. This must be maintained in all future development.
- **The free tier must be genuinely useful**, not crippled. It should be a good Wi-Fi utility on its own that people recommend, driving organic adoption and paid conversions.
- **VPN support is universal.** Any VPN that registers a system profile (visible in System Settings > VPN) is automatically discovered and controllable. No curated list to maintain.
- **First-time app seller.** Build and release processes should be well-documented and straightforward. LemonSqueezy was chosen for simplicity of onboarding.
- **Golden Gate compatibility.** The app must be tested on macOS 27 (Golden Gate) beta since that is the developer's primary machine. Monitor Apple beta release notes for API changes affecting CoreWLAN, NWPathMonitor, and SMAppService.
