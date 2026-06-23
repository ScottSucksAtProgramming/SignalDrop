# SignalDrop Index

Quick-reference for finding content in this directory. For conventions, see `context/conventions.md`.

## Project Documents

| File | Purpose | When to Use |
|------|---------|-------------|
| `SPEC.md` | Full product specification — features, pricing, tech stack, UX | Before implementing any feature. Source of truth for what to build. |
| `PRD.md` | Formal PRD with user stories, module architecture, testing plan | For user stories, module interfaces, and testing decisions. |
| `ROADMAP.md` | v1 feature list + deferred future features | To check if something is in scope for v1 or deferred. |
| `DESIGN_DECISIONS.md` | Log of all 33 design decisions with reasoning | To understand WHY a decision was made, not just what it is. |

## Source Code

| Path | Purpose |
|------|---------|
| `SignalDrop/Sources/App/` | App entry point, AppDelegate (menu bar setup, popover, settings window) |
| `SignalDrop/Sources/Models/` | Data models — NetworkState, ScannedNetwork |
| `SignalDrop/Sources/Protocols/` | Abstraction protocols — NetworkPathProviding, WLANInterface, ShellExecuting, WiFiScanning |
| `SignalDrop/Sources/Services/NetworkMonitor/` | NWPathMonitor wrapper — connection state, IP address, Ethernet detection |
| `SignalDrop/Sources/Services/WiFiManager/` | Wi-Fi management — scanning, joining, power toggle (WiFiManager + CoreWLANScanner) |
| `SignalDrop/Sources/Services/IPService/` | IP address resolution — local IP from interfaces, external IP via DNS (Cloudflare/OpenDNS), 30s cache, refresh modes |
| `SignalDrop/Sources/Services/PingService/` | TCP-based latency measurement via NWConnection, configurable target/port |
| `SignalDrop/Sources/Services/SettingsStore/` | UserDefaults persistence for all settings (launch at login, detail visibility, IP refresh, ping) |
| `SignalDrop/Sources/Services/LicenseManager/` | License/paid-tier gating (stub — returns false) |
| `SignalDrop/Sources/UI/Popover/` | Popover views — PopoverView, ConnectionInfoView, EthernetInfoView, NetworkListView, PasswordInputView, IPPingView |
| `SignalDrop/Sources/UI/Settings/` | Settings window — SettingsView (tabbed), NetworkDetailsSettingsView, IPPingSettingsView |
| `SignalDropTests/` | Unit tests — NetworkMonitor, WiFiManager, SettingsStore, IPService, PingService + mocks |

## context/

| File | Purpose |
|------|---------|
| `conventions.md` | Swift/SwiftUI coding conventions, naming rules, project structure standards |
| `lessons.md` | Running log of lessons learned during development |

## handoffs/ (local only, .gitignored)

Session handoff documents created by `/mattpocock-handoff` at the end of each development session. Used to resume work in the next session.

## Task Tracking

`.taskpaper` — Comprehensive development plan organized by phase. Single source of truth for all task tracking. Run `na next` to see pending tasks.
