# SignalDrop Index

Quick-reference for finding content in this directory. For conventions, see `context/conventions.md`.

## Project Documents

| File | Purpose | When to Use |
|------|---------|-------------|
| `SPEC.md` | Full product specification — features, pricing, tech stack, UX | Before implementing any feature. Source of truth for what to build. |
| `PRD.md` | Formal PRD with user stories, module architecture, testing plan | For user stories, module interfaces, and testing decisions. |
| `ROADMAP.md` | v1 feature list + deferred future features | To check if something is in scope for v1 or deferred. |
| `DESIGN_DECISIONS.md` | Log of all design decisions with reasoning | To understand WHY a decision was made, not just what it is. |

## Source Code

| Path | Purpose |
|------|---------|
| `SignalDrop/Sources/App/` | App entry point, AppDelegate (menu bar setup, popover, settings window) |
| `SignalDrop/Sources/Models/` | Data models — NetworkState, ScannedNetwork |
| `SignalDrop/Sources/Protocols/` | Abstraction protocols — NetworkPathProviding, WLANInterface, ShellExecuting, WiFiScanning, VPNConfigurationProviding |
| `SignalDrop/Sources/Services/NetworkMonitor/` | NWPathMonitor wrapper — connection state, IP address, Ethernet detection |
| `SignalDrop/Sources/Services/WiFiManager/` | Wi-Fi management — scanning, joining, power toggle (WiFiManager + CoreWLANScanner) |
| `SignalDrop/Sources/Services/IPService/` | IP address resolution — local IP from interfaces, external IP via DNS (Cloudflare/OpenDNS), 30s cache, refresh modes |
| `SignalDrop/Sources/Services/PingService/` | TCP-based latency measurement via NWConnection, configurable target/port |
| `SignalDrop/Sources/Services/VPNManager/` | VPN management via Network Extension framework — auto-discovery of system VPN profiles, real-time status monitoring, connect/disconnect (VPNManager) |
| `SignalDrop/Sources/Services/SettingsStore/` | UserDefaults persistence for all settings (launch at login, detail visibility, IP refresh, ping, VPN) |
| `SignalDrop/Sources/Services/LicenseManager/` | License/paid-tier gating (stub — returns false) |
| `SignalDrop/Sources/UI/Popover/` | Popover views — PopoverView, ConnectionInfoView, EthernetInfoView, NetworkListView, PasswordInputView, IPPingView, VPNSectionView |
| `SignalDrop/Sources/UI/Settings/` | Settings window — SettingsView (tabbed), NetworkDetailsSettingsView, IPPingSettingsView, VPNSettingsView |
| ~~`PrivilegedHelper/`~~ | *(Removed — Network Extension framework eliminates the need for a privileged helper)* |
| `SignalDropTests/` | Unit tests — NetworkMonitor, WiFiManager, SettingsStore, IPService, PingService, VPNManager + mocks |

## context/

| File | Purpose |
|------|---------|
| `conventions.md` | Swift/SwiftUI coding conventions, naming rules, project structure standards |
| `session-workflow.md` | Phase workflow — how to plan, execute, review, and finish a development phase |
| `lessons.md` | Running log of lessons learned during development |

## handoffs/ (local only, .gitignored)

Session handoff documents created by `/mattpocock-handoff` at the end of each development session. Used to resume work in the next session.

## Task Tracking

`.taskpaper` — Development plan for active and future phases. Run `na next` to see pending tasks.

`archive/completed-phases.taskpaper` — Completed phases moved here after merging to `main`. Contains tasks and Discoveries from Phases 1-3. Reference if you need context on what was built or lessons from earlier phases.
