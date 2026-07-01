# WireBar - Design Decision Log

Record of all decisions made during the initial product design session (2026-06-22).

---

## Q1: Technology Stack

**Decision:** Swift + SwiftUI

**Why:** Native macOS choice. Direct access to CoreWLAN (Wi-Fi APIs), NetworkExtension (VPN APIs), and system-level integrations without bridging layers. Lightweight — important for an always-running menu bar app. Alternatives like Electron or Tauri would add unnecessary bloat.

---

## Q2: App Store vs. Direct Distribution

**Decision:** Direct distribution (Developer ID signed + notarized)

**Why:** Several core features are impossible or severely restricted under App Store sandboxing:
- Switching Wi-Fi networks (CoreWLAN restricted in sandbox)
- Toggling VPNs (NetworkExtension requires Apple approval + limited to Apple VPN frameworks)
- Reading Wi-Fi details (gated entitlements)

Features are more important than App Store presence. Many successful Mac utilities (Bartender, iStat Menus, Little Snitch) use direct distribution for the same reasons. App Store version with reduced features is a future roadmap item.

---

## Q3: Menu Bar Icon

**Decision:** Configurable display. User chooses what to show from: Wi-Fi signal strength icon, network name, VPN status indicators, IP address.

**Default:** Wi-Fi icon + network name.

**Why:** Scott wants to see network name by default, but also sometimes wants VPN status or IP visible. Making it configurable satisfies all use cases without cluttering the menu bar.

---

## Q4: VPN Protocols/Clients

**Decision (updated 2026-06-23):** Auto-discover all system VPN profiles via Apple's Network Extension framework. No curated list — any VPN visible in System Settings > VPN is supported.

**Scott's setup:** Uses WireGuard (config named "Rivendell") and Tailscale regularly.

**Original decision:** Curated list of WireGuard, Tailscale, PIA with CLI commands. **Replaced** because CLI toggling didn't work — users manage VPNs through their apps, which register system profiles, not through CLI tools.

---

## Q5: VPN Toggle Behavior

**Decision (updated 2026-06-23):** Simple on/off toggles for all VPNs via Network Extension framework (`NEVPNConnection.startVPNTunnel()` / `.stopVPNTunnel()`). No CLI commands.

**Why:** The original CLI-based approach (wg-quick, tailscale, piactl) didn't work in practice — VPN apps manage connections through system profiles, not CLI tools. Network Extension is the OS-native way to interact with VPN configurations. It's simpler, works with any VPN app, and eliminates the privileged helper entirely.

---

## Q6: Wi-Fi Network Switching

**Decision:** Full list of available networks sorted by signal strength. Known/saved networks pinned to the top. Signal quality indicator and security type shown. Saved networks visually distinguished. Unknown networks prompt a password dialog.

---

## Q7: Dropdown Layout

**Decision:** SwiftUI popover (not NSMenu) with sections:
1. Current connection info (network name, signal strength, IPs)
2. VPN section (name, status, toggle per VPN)
3. Wi-Fi networks (known first, then available)
4. Quick actions (disconnect, settings)

**Why:** Popover allows proper toggle switches, signal strength bars, and rich UI. Traditional NSMenu is too limiting for VPN toggles and detailed info.

---

## Q8: IP Address Display

**Decision:** Both local and external IP. External IP fetched via DNS query — Cloudflare `whoami.cloudflare` (primary), OpenDNS `myip.opendns.com` (fallback). Not an HTTPS API.

**Refresh modes (user configurable):**
- Timed interval (configurable)
- On-demand only (manual refresh button)

Auto-refresh on VPN state change regardless of mode. 30-second cache to avoid lookup spam. "Unavailable" with retry on failure.

**Why:** External IP is especially useful with VPNs — confirms traffic is actually routing through the VPN. DNS queries are faster (milliseconds vs HTTP round trip), more private (no cookies, headers, or user agent string — just a raw DNS packet), and more reliable (DNS infrastructure uptime > web API uptime). Natural fit for a networking utility.

---

## Q9: Settings Scope

**Decision:** Extensive settings including:
- Menu bar display configuration
- IP refresh mode and interval
- VPN list management
- Launch at login (on by default)
- Granular notification toggles per event type
- Network detail display configuration
- Hotkey configuration
- Opt-in diagnostics

**Appearance:** Follows system dark/light mode. No manual override needed.

---

## Q10: Network Details

**Decision:** All network details built in and configurable by user:
- SSID, signal strength (bars + percentage), band/frequency, channel, link speed, BSSID, DNS servers, gateway IP, subnet mask

**Default display:** Network name + signal strength only. User configures what else to show.

**Why:** Power users want deep info, general users want simplicity. Configurable defaults solve both.

---

## Q11: Wi-Fi On/Off Control

**Decision:** Include Wi-Fi on/off toggle. When off, menu bar icon changes to disabled state, popover shows minimal UI with toggle to re-enable. VPN section still visible (relevant for Ethernet).

---

## Q12: Ethernet Awareness

**Decision:** Full Ethernet support. Auto-detect wired connections, show connection info, indicate wired connection on menu bar icon. VPN and IP features work regardless of connection type.

**Why:** Low implementation effort since we're already reading network interfaces. Would be weird if the app went blank on Ethernet.

---

## Q13: Multiple Active Connections

**Decision:** Handle Wi-Fi + Ethernet simultaneously. Show all active connections with clear labels. Indicate primary route. Soft warning when multiple VPNs active (dismissable, can be disabled in settings).

**Why:** Users running Tailscale + WireGuard simultaneously usually know what they're doing. Warn but don't block.

---

## Q14: Keyboard Shortcuts

**Decision:** Extensive configurable hotkeys:
- Global hotkey to open/close popover
- Toggle each VPN
- Toggle Wi-Fi
- Copy local/external IP to clipboard
- Refresh external IP
- Navigate between popover sections

**Why:** Scott specifically said extensive hotkeys are important.

---

## Q15: Data Persistence and First Run

**Decision (updated 2026-06-23):**
- Settings stored in UserDefaults (standard macOS approach)
- Auto-discover all system VPN profiles via Network Extension, user chooses which to show
- New VPN apps appear automatically after installation — no manual add needed
- First-run setup wizard walks through Location Services permission (no privileged helper step — eliminated with Network Extension)

---

## Q16: Custom VPN Support

**Decision (updated 2026-06-23):** No curated list or custom VPN support needed for V1. The Network Extension framework auto-discovers all system VPN profiles. Any VPN app that registers a system profile (which is all major VPN apps) works automatically.

Custom VPN configurations (user-defined profiles) may be revisited in a future version if there's demand.

**Original decision:** Curated CLI list + custom CLI commands. **Replaced** by auto-discovery via Network Extension — the entire problem of "which VPNs to support" is solved by the OS.

---

## Q17: Auto-Updates

**Decision:** Sparkle framework integrated from v1. Releases hosted on GitHub Releases. `generate_appcast` builds update feed XML from releases.

**Why:** Direct distribution means no App Store auto-updates. Sparkle is free (MIT), safe, and used by thousands of Mac apps (Firefox, VLC, Sketch).

---

## Q18: App Name

**Decision:** WireBar

---

## Q19: Minimum macOS Version

**Decision:** macOS 13 (Ventura) through macOS 27 (Golden Gate, currently in beta). Must work on Tahoe (macOS 26) as well.

**Why:** macOS 13 covers the vast majority of active Macs and provides modern SwiftUI + full CoreWLAN access. Scott is running Golden Gate beta.

---

## Q20: Security and Privacy

**Decision:**
- Privileged helper via `SMAppService` (user authorizes once during setup)
- No data logging — all network info in-memory only, never written to disk
- External IP fetch via HTTPS only
- Opt-in diagnostic logging for error reports (off by default, user must enable)

**Why:** Trust is paramount for a networking utility. "I want this app to be trusted." — Scott

---

## Q21: Error Handling

**Decision:**
- Missing VPN CLI: grayed out entry with warning icon and tooltip
- Network state: real-time via `NWPathMonitor` (no polling)
- IP fetch failure: "Unavailable" with retry button
- Helper failure: "Reinstall Helper" option in settings
- Principle: never silently fail, always give clear path to fix

---

## Q22: Speed Test

**Decision:** Skip full speed test for v1. Future roadmap item.

---

## Q23: Ping/Latency Indicator

**Decision:** Include lightweight ping indicator. Configurable target (default `1.1.1.1`). User can toggle on/off. Implementation uses TCP-based latency measurement via `NWConnection` to `1.1.1.1:443` — not ICMP ping. UI still labels it "Ping" since users understand the term.

**Why:** ICMP ping requires raw sockets, which need either root access or a special entitlement that Apple doesn't easily grant for Developer ID apps. TCP connection latency gives an accurate, practical measurement without special permissions.

---

## Q24: Popover Interaction

**Decision:**
- Left-click menu bar icon to open popover
- Close on click outside
- Sections collapsible
- Section reordering deferred to v2
- Max height with scrolling, dynamic resize up to max

---

## Q25: Accessibility

**Decision:** Full accessibility from day one:
- VoiceOver support (all elements labeled)
- Keyboard navigation (tab through all elements)
- Respect system settings (reduced motion, high contrast, increased contrast)

**Why:** Much harder to bolt on later. Nearly free with SwiftUI if built from the start.

---

## Q26: Open Source / License

**Decision:** BSL (Business Source License), converts to Apache 2.0 after 3-4 years.

**Why:** Scott wants to sell the app but also wants code transparency for trust. BSL allows full source visibility, personal/non-commercial use for free, but protects commercial rights. Conversion to Apache 2.0 ensures older versions eventually become fully open source.

---

## Q27: Licensing and Payment

**Decision:** Freemium model with LemonSqueezy as storefront.
- Free tier: core Wi-Fi features
- Paid tier: $12.99 one-time purchase (no renewal in V1)

When V2 ships with major new features, it will be a separate product with a loyalty discount for V1 buyers. All V1.x updates are included with a V1 purchase.

LemonSqueezy chosen for: simplest onboarding experience, merchant of record (handles global sales tax), Swift SDK for license validation, 5% + $0.50 per transaction.

**Why:** Scott has never sold an app before — LemonSqueezy is the easiest path. Freemium builds adoption, paid tier converts power users. One-time pricing avoids subscription stigma and matches market preference.

---

## Q28: Free vs. Paid Feature Split

**Decision:**

Free: Wi-Fi status/name in menu bar, signal strength, network list + switching, Wi-Fi on/off, Ethernet detection, local IP.

Paid: VPN monitoring/toggles, external IP, custom VPNs, configurable menu bar display, configurable hotkeys, advanced network details, ping indicator, notifications, collapsible sections.

**Why:** Free tier is genuinely useful (not crippled). VPN management is the clear premium value.

---

## Q29: Pricing Research

**Decision:** $12.99 one-time based on competitive analysis.

**Market context:** Consumer Mac networking utilities cluster $9-$30 one-time. One-time purchase dominates (subscriptions deeply unpopular). Comparable apps: Radio Silence ($9), iStat Menus ($11.99), WiFi Explorer ($19.99). WireBar is unique in combining Wi-Fi + VPN + network info.

---

## Q30: Analytics/Telemetry

**Decision:** Opt-in only. No behavioral analytics. LemonSqueezy provides basic business metrics via license activations. Sentry crash reporting is deferred to V1.1 — V1 ships without crash reporting. When Sentry is added in V1.1, non-opted-in users will see a per-crash consent dialog before any data is sent.

**Why:** "I want this app to be trusted." — Scott

---

## Q31: Localization

**Decision:** Localization-ready but English-only at launch. All strings use `String(localized:)` from the start. Translations added later without refactoring.

---

## Q32: Setapp Distribution

**Decision:** Not for v1. Architect licensing to support Setapp SDK integration later. Good future growth channel once app is stable.

---

## Q33: Additional Features Triage

**Deferred to v2+:**
- Personal Hotspot management
- Network connection history/log
- Menu bar icon customization
- macOS Widget (desktop/Notification Center)
- Section reordering in popover
- Tailscale exit node selection
- PIA server selection
- Speed test
- Setapp integration
- App Store reduced-feature version
- Shortcuts/Automator integration
- AppleScript support

**Included in v1:**
- Copy/export all network info to clipboard (useful for tech support)

---

## Q34: VPN Execution Model

**Decision (updated 2026-06-23):** Network Extension framework handles all VPN operations. No CLI commands, no privileged helper. `NEVPNConnection.startVPNTunnel()` and `.stopVPNTunnel()` manage connections; the OS handles privilege escalation natively.

**Original decision:** Two-tier CLI execution (non-elevated + PrivilegedHelper for wg-quick). **Replaced** because CLI toggling didn't work with app-managed VPN configurations, and the privileged helper added significant complexity for a problem the OS already solves.

---

## Q35: Privileged Helper Security

**Decision (updated 2026-06-23):** ~~Privileged helper with audit token verification and command whitelist.~~ **Eliminated.** Network Extension framework removes the need for a privileged helper entirely. No elevated CLI commands, no XPC service, no daemon process.

---

## Q36: Helper Uninstall Flow

**Decision (updated 2026-06-23):** ~~In-app uninstall button for SMAppService helper.~~ **Eliminated.** No helper to install or uninstall.

---

## Q37: Offline License Validation

**Decision:** LicenseManager caches license validation locally with a grace period. Paid features remain accessible when the network is down.

**Why:** A network utility that locks features when the network is down defeats its own purpose. Users need VPN management most when troubleshooting connectivity.

---

## Q38: Update Entitlement

**Decision:** Sparkle updates are public — anyone with the app gets updates. The license gates features, not updates. Appcast XML is hosted on public GitHub Releases with no per-license gating.

**Why:** Gating updates requires a backend server or private appcast endpoint. Unnecessary complexity for V1 with no renewal model. All V1 buyers get all V1.x updates.

---

## Q39: Distribution Format

**Decision:** `.dmg` (drag to Applications). No `.pkg` installer for V1.

**Why:** Simplest distribution for a menu bar utility. No installer needed — VPN management uses the Network Extension framework, which requires no privileged helper or daemon registration. Standard for indie Mac apps.

---

## Q40: External IP — DNS vs HTTP

**Decision:** DNS-based lookup instead of HTTPS API. Cloudflare DNS (`whoami.cloudflare`) primary, OpenDNS (`myip.opendns.com`) fallback.

**Why:** DNS queries are faster (milliseconds vs HTTP round trip), more private (no cookies, headers, or user agent string — just a raw DNS packet), and more reliable (DNS infrastructure uptime > web API uptime). Natural fit for a networking utility.

---

## Q41: Ping — TCP vs ICMP

**Decision:** TCP-based latency measurement via `NWConnection` to `1.1.1.1:443` instead of ICMP ping.

**Why:** ICMP ping requires raw sockets, which need either root access or a special entitlement that Apple doesn't easily grant for Developer ID apps. TCP connection latency gives an accurate, practical measurement without special permissions. UI still labels it "Ping."

---

## Q42: VPN Architecture — Read-Only Status + Deep-Link (2026-06-23, revised)

> Replaces original Q42 (Network Extension rework), Q43 (NE notifications), Q44 (NE-based icons).

**Decision:** VPN feature is **read-only status display with deep-link**. WireBar discovers system VPN profiles via `scutil --nc list` (SystemConfiguration), shows their name/status/provider icon, and deep-links to the owning app or System Settings on click. No toggling, no Network Extension, no CLI control.

**What changed:**
- **Deleted:** VPNDefinition, ProcessCommandExecutor, VPNCommandExecuting, ShellExecuting, HelperConstants, PrivilegedHelperManager, PrivilegedHelper target, MockVPNCommandExecutor
- **New:** VPNState (model), VPNConfigurationProviding (protocol seam), SystemVPNProvider (scutil parser), MockVPNConfigurationProvider
- **Rewritten:** VPNManager (refresh-only, no connect/disconnect), VPNSectionView (deep-link rows), VPNSettingsView (show/hide + tap-action picker), SettingsStore (hiddenVPNs + vpnTapAction)

**Why:** Two discovery/control approaches failed:
1. CLI-based (original Phase 4) — VPN apps register system profiles via Network Extension, not CLI tools; CLI toggling was unreliable.
2. Network Extension (`NETunnelProviderManager.loadAllFromPreferences()`) — returns only configs the calling app created. WireBar creates none, so the result is empty. No entitlement grants cross-app visibility. This is macOS sandboxing by design.

`scutil --nc list` reads SystemConfiguration, which does see all system VPN profiles (confirmed on real hardware: "Rivendell" WireGuard + Tailscale both visible with UUID, status, and provider bundle ID). Read-only is the honest scope; deep-linking to the owning app gives users one-click access to toggle.

**Tradeoffs:**
- Cannot toggle VPNs — users must click through to the app or System Settings
- Status refresh is on-demand (popover open / app launch), not real-time push. Live updates (SCDynamicStore) deferred as a future nicety.
- VPN identifier uses SCNetworkService UUID (survives config renames, unlike localizedDescription)
- Tap-action is user-configurable: "open the VPN app" (default, falls back to System Settings if unknown) or "open System Settings"
