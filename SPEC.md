# SignalDrop - Product Specification

## Overview

**SignalDrop** is a macOS menu bar utility that provides at-a-glance Wi-Fi and VPN status, network switching, VPN toggling, and detailed network information in a clean popover interface.

## Technology

- **Language/Framework:** Swift + SwiftUI
- **Minimum macOS:** 13 (Ventura)
- **Maximum macOS:** 27 (Golden Gate, currently in beta) and forward
- **Distribution:** Direct distribution (Developer ID signed + notarized), distributed as a .dmg file, not App Store
- **Updates:** Sparkle framework, hosted via GitHub Releases
- **Licensing:** BSL (Business Source License), converts to Apache 2.0 after 3-4 years
- **Storefront:** LemonSqueezy (merchant of record, handles global sales tax)
- **Crash Reporting:** Sentry (opt-in only) — deferred to V1.1; V1 ships without crash reporting

## Pricing Model

### Freemium + One-Time Purchase with Time-Limited Updates

**Free tier:**
- Wi-Fi status and network name in menu bar
- Signal strength and basic connection info
- Available network list and switching (known networks listed first)
- Wi-Fi on/off toggle
- Ethernet detection and display
- Local IP address display

**Paid tier ($12.99 one-time):**
- VPN status monitoring and toggle switches
- External/public IP address
- Configurable menu bar display (choose what's shown)
- Configurable global hotkeys
- Advanced network details (channel, BSSID, DNS, gateway, subnet, link speed)
- Ping/latency indicator
- Notifications (VPN drops, IP changes, Wi-Fi disconnects)
- Collapsible/configurable popover sections

App keeps working forever at the last installed version.

---

## Menu Bar Icon

### Display
- Configurable by the user. Options to show any combination of:
  - Wi-Fi signal strength icon (changes to wired icon on Ethernet, disabled icon when Wi-Fi is off)
  - Network name (SSID)
  - VPN status indicators
  - IP address (local or external)
- Default: Wi-Fi icon + network name

### Interaction
- **Left-click:** Opens popover
- **Global hotkey:** Configurable shortcut to open/close popover

---

## Popover Panel

### Layout (top to bottom)
1. **Current Connection Info** - network name, signal strength, IP addresses, ping latency
2. **VPN Section** - each VPN with name, status indicator, and on/off toggle
3. **Wi-Fi Networks** - known/saved networks first, then available networks sorted by signal strength
4. **Quick Actions** - Wi-Fi on/off, copy network info, settings

### Behavior
- SwiftUI popover (not NSMenu)
- Closes when clicking outside
- Sections are collapsible
- Max height with scrolling for long network lists
- Dynamic resize up to max height based on content

### Multiple Connections
- Supports Wi-Fi + Ethernet active simultaneously
- Shows all active connections with clear labels
- Indicates which interface is the primary route
- Soft warning when multiple VPNs are active (dismissable, can be disabled in settings)

---

## Wi-Fi Management

### Network List
- Shows all available networks
- Known/saved networks pinned to top
- Sorted by signal strength within each group
- Shows signal strength indicator and security type
- Known networks visually distinguished from unknown
- Checkmark on currently connected network

### Network Switching
- One-click join for saved/known networks
- Password input dialog for unknown networks
- Wi-Fi on/off toggle

### Network Details (configurable - user chooses what to display)
- SSID (network name)
- Signal strength (bars + percentage)
- Band/frequency (2.4 GHz / 5 GHz / 6 GHz)
- Channel number
- Link speed
- BSSID (router MAC address)
- DNS servers
- Gateway IP
- Subnet mask
- **Default display:** Network name and signal strength only

---

## Ethernet Support

- Auto-detect wired Ethernet connections
- Show Ethernet connection info (IP, gateway, DNS, etc.) in popover
- Menu bar icon changes to indicate wired connection
- VPN and IP sections work regardless of connection type

---

## VPN Management

### Supported VPNs
- **Any VPN with a system profile** — auto-discovers all VPN configurations visible in System Settings > VPN
- Works with WireGuard, Tailscale, PIA, Mullvad, NordVPN, corporate VPNs, and any other VPN app that registers a Network Extension profile
- No curated list to maintain — if the OS sees it, SignalDrop sees it

### VPN Controls
- Simple on/off toggle for each VPN
- Status indicator (connected/connecting/disconnecting/disconnected)
- Provider-specific icons for recognized VPN apps (e.g., Tailscale, WireGuard), generic shield icon for unrecognized providers
- Connect/disconnect via `NEVPNConnection.startVPNTunnel()` / `.stopVPNTunnel()`

### VPN Implementation
Uses Apple's Network Extension framework (`NEVPNManager` / `NETunnelProviderManager`):
- **Discovery:** `NETunnelProviderManager.loadAllFromPreferences()` returns all system VPN profiles
- **Status monitoring:** Real-time via `NEVPNStatusDidChange` notification (no polling)
- **Configuration changes:** `NEVPNConfigurationChange` notification triggers automatic VPN list reload
- **Provider identification:** `NETunnelProviderProtocol.providerBundleIdentifier` maps to known VPN provider icons
- **No CLI commands, no privileged helper** — the OS handles all privilege escalation natively

### VPN Detection
- Auto-detect all system VPN profiles at launch and when configurations change
- User chooses which to show/hide in settings
- New VPN apps appear automatically after installation — no restart required

---

## IP Address Display

### Local IP
- Displayed for current active interface
- Available in free tier

### External/Public IP (paid tier)
- Fetched via DNS query (privacy-respecting, no personal data collection):
  - Primary: Cloudflare DNS (`whoami.cloudflare` via DNS-over-HTTPS or DNS TXT query)
  - Fallback: OpenDNS (`myip.opendns.com`)
- **Refresh modes (user configurable):**
  - Timed interval (configurable interval)
  - On-demand only (manual refresh button)
- **Auto-refresh on VPN state change** (always, regardless of mode)
- Cached for 30 seconds to avoid excessive DNS queries
- Shows "Unavailable" with retry button on fetch failure
- Click to copy to clipboard

---

## Ping / Latency Indicator (paid tier)

- TCP-based latency measurement via `NWConnection` to configurable target (default: `1.1.1.1:443`)
- Displays latency in milliseconds
- Lightweight, runs fast
- User can toggle on/off
- User can change target host

---

## Notifications (paid tier)

All notifications are individually toggleable in settings:
- Wi-Fi disconnection
- VPN connection drops (especially important for privacy/security)
- IP address changes
- Network changes

---

## Keyboard Shortcuts

All hotkeys are user-configurable:
- Open/close popover (global hotkey)
- Toggle each VPN
- Toggle Wi-Fi on/off
- Copy local IP to clipboard
- Copy external IP to clipboard
- Refresh external IP
- Navigate between popover sections

---

## Settings / Preferences

### General
- Launch at login (on by default)
- Menu bar display configuration (choose visible elements)
- IP refresh mode (timed interval vs. on-demand)
- IP refresh interval (if timed)

### VPN Management
- Enable/disable monitored VPNs (show/hide per VPN in popover)
- Multiple VPN warning toggle
- VPN list auto-populates from system VPN profiles

### Notifications
- Individual toggle for each notification type
- VPN drop notifications
- IP change notifications
- Wi-Fi disconnect notifications

### Network Details
- Configure which details are shown in the popover
- Defaults: network name + signal strength

### Keyboard Shortcuts
- Configure all hotkeys
- Global popover toggle
- Per-VPN toggles
- Utility shortcuts

### Privacy
- Opt-in diagnostic/crash reporting (Sentry) — added in V1.1 alongside a per-crash consent dialog
- Off by default

### Appearance
- Follows system dark/light mode automatically

---

## Security & Privacy

- **VPN management via Network Extension framework** — no privileged helper, no CLI commands. The OS handles all VPN connection management and privilege escalation natively through `NEVPNManager`.
- **No data logging.** All network info is in-memory only, never written to disk.
- **Opt-in crash reporting** via Sentry (V1.1+). Off by default; consent dialog shown per-crash.
- **External IP fetched via DNS query only** (Cloudflare / OpenDNS). No HTTPS API calls for IP lookup.
- **Location Services permission** required for SSID reading (Apple requirement). First-run wizard explains why.

---

## First-Run Experience

1. Welcome screen introducing SignalDrop
2. Permission setup wizard:
   - Location Services (required for Wi-Fi SSID)
3. Auto-detect system VPN profiles, present for user confirmation of which to show
4. Configure menu bar display preferences
5. Done - app is ready

---

## Accessibility

- Full VoiceOver support (all elements properly labeled)
- Complete keyboard navigation (tab through all interactive elements)
- Respects system accessibility settings:
  - Reduced motion
  - High contrast / increased contrast
- Built in from day one using SwiftUI accessibility APIs

---

## Localization

- Localization-ready from v1 (all strings use `String(localized:)`)
- Ships with English only at launch
- Translations can be added later without refactoring

---

## Error Handling

- **No VPNs found:** Helpful message directing users to set up a VPN in System Settings or install a VPN app
- **Network state changes:** Real-time via `NWPathMonitor` (no polling)
- **External IP fetch failure:** Shows "Unavailable" with retry button
- **Principle:** Never silently fail. Always give the user a clear path to fix it.

---

## Utility Features

- **Copy/export network info:** One-click copy of all connection details to clipboard (useful for tech support)
