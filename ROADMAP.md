# WireBar - Roadmap

## v1.0 - Initial Release

Everything defined in [SPEC.md](SPEC.md). Development tracked in [.taskpaper](.taskpaper).

### Development Phases

1. **Walking Skeleton** — Xcode project, menu bar icon, popover, NetworkMonitor, SettingsStore, protocol-based DI, first tests
2. **Wi-Fi Management** — WiFiManager, network list, switching, Wi-Fi toggle, Ethernet detection
3. **IP + Ping** — IPService (DNS-based lookup), PingService (TCP-based latency), configurable refresh
4. **VPN** — Read-only VPN status via SystemConfiguration (`scutil --nc list`), auto-discovery of system VPN profiles, provider icons, deep-link to owning app or System Settings
5. **Notifications + Hotkeys + Polish** — NotificationService, HotkeyManager, collapsible sections, configurable menu bar
6. **Licensing + Updates** — LemonSqueezy SDK, Sparkle auto-updates, free/paid feature gating
7. **Onboarding + Accessibility** — First-run wizard, accessibility audit, edge case polish
8. **Release Prep** — Release script, notarization, .dmg, docs, privacy policy, beta testing, launch

### Core Features

- Menu bar icon with configurable display
- SwiftUI popover with connection info, VPN toggles, network list
- Wi-Fi network switching (known networks prioritized)
- VPN status monitoring with deep-link (auto-discovers system VPN profiles via SystemConfiguration)
- Local and external IP display (DNS-based lookup) with configurable refresh
- Ethernet detection and display
- Ping/latency indicator (TCP-based)
- Configurable notifications
- Extensive configurable hotkeys
- Freemium licensing via LemonSqueezy ($12.99 one-time purchase)
- Auto-updates via Sparkle + GitHub Releases
- First-run setup wizard
- Full accessibility support
- Localization-ready (English only)
- Provider-specific VPN icons for recognized VPN apps
- Copy/export network info to clipboard

---

## v1.1 - Crash Reporting

- Sentry SDK integration (opt-in only, off by default)
- Per-crash consent dialog for non-opted-in users
- Sentry only initializes after explicit user opt-in

---

## v1.x - Post-Launch Improvements

### Custom VPN Configurations
- Allow users to create custom VPN profiles from within WireBar (if demand exists)

### VPN Enhancements
- Expand provider icon library for more VPN apps
- VPN leak detection (DNS leaks, IPv6 leaks, packet-level inspection) — far-future

### Polish
- Bug fixes and performance improvements based on user feedback
- Refine first-run experience based on user friction points
- Expand notification options based on user requests
- Move release pipeline to GitHub Actions CI

---

## v2.0 - Future Features

Sold as a separate product with loyalty discount for V1 buyers.

### Popover Enhancements
- **Section reordering** - drag and drop to rearrange popover sections
- **Tailscale exit node selection** - submenu to pick exit nodes
- **PIA server selection** - choose VPN server location

### Network Features
- **Speed test** - integrated upload/download speed test
- **Network history** - log of connected networks, VPN state changes, connection events
- **Personal Hotspot** - show and manage macOS Personal Hotspot sharing

### Visual
- **Menu bar icon customization** - choose your own icon or color scheme
- **macOS Widget** - desktop or Notification Center widget showing network status

### Distribution
- **Setapp integration** - second revenue channel via Setapp subscription platform
- **App Store version** - reduced feature set (no network switching) for App Store presence and discoverability

### Localization
- Community-sourced translations
- Priority languages based on user base geography

### Platform
- **Shortcuts/Automator integration** - expose actions for macOS Shortcuts app
- **AppleScript support** - scriptable network info queries and VPN status
