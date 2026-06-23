# Plan: Phase 4 VPN — Network Extension Rework

> Source: PRD.md (VPNManager module), DESIGN_DECISIONS.md Q34–Q36 & Q42–Q44, `.taskpaper` Phase 4 rework task list, handoff `handoffs/2026-06-23-phase4-vpn-netext-rework.md`

## Context

Phase 4's CLI-based VPN management didn't work in manual testing — VPNs appear but won't toggle. Root cause: users manage VPNs through their apps (Tailscale, WireGuard config "Rivendell", PIA), which register **system VPN profiles** via Network Extension, not CLI tools. The docs have already been reworked to describe the Network Extension target state; **this plan covers the code rework to match.** The current working tree still contains the old CLI + PrivilegedHelper implementation.

## Architectural decisions

Durable decisions that apply across all slices (from the locked grilling session, DESIGN_DECISIONS Q42–Q44):

- **VPN API**: Apple Network Extension framework only. `NETunnelProviderManager.loadAllFromPreferences()` to discover; `NEVPNConnection.startVPNTunnel()` / `.stopVPNTunnel()` to toggle. No CLI, no shell, no privileged helper — the OS handles privilege escalation.
- **Discovery**: auto-discover ALL system VPN profiles (anything in System Settings > VPN). No curated list. Custom VPN configs deferred to a future version.
- **Status**: real-time via `NEVPNStatusDidChange` notification. Reload the list on `NEVPNConfigurationChange`. Load list at launch AND on config change. No polling timer is ever authored.
- **Testability seam**: a new `VPNConfigurationProviding` protocol wraps Network Extension (consistent with the existing `NetworkPathProviding` / `WLANInterface` pattern). The seam must cover: enumerate configs, per-config status, start/stop, and an injectable status-event stream for tests. New `MockVPNConfigurationProvider`. *(Exact protocol signature intentionally not pinned here — settle it during slice 1.)*
- **VPNState**: simplified wrapper — `displayName`, mapped status enum, `isEnabled` preference, provider icon. No CLI paths, parse closures, or execution tier.
- **Status enum**: keep our own `VPNConnectionStatus`, add `disconnecting`. Map all six `NEVPNStatus` cases → our five: `connected`→connected, `connecting`/`reasserting`→connecting, `disconnecting`→disconnecting, `disconnected`→disconnected, `invalid`→unknown.
- **Settings identifier**: use `localizedDescription` as the per-VPN key in `SettingsStore.enabledVPNs`. Renaming a config resets its show/hide pref (accepted).
- **Provider icons**: map `NETunnelProviderProtocol.providerBundleIdentifier` → SF Symbol. Known providers (Tailscale, WireGuard, PIA…) get their own; unknown → generic `lock.shield`. Cosmetic lookup table, easy to extend.
- **Entitlements**: try WITHOUT `com.apple.developer.networking.vpn.api` first (app is unsandboxed). Add only if real-hardware toggling fails. Add the `NetworkExtension` framework dependency in `project.yml`.
- **Paid gate stays** on all VPN features (LicenseManager). Real gating lands in Phase 6.

### Files to delete (verified against current tree)

Confirmed by grep that all of these are consumed only by the CLI/VPN/helper path:

- `SignalDrop/Sources/Models/VPNDefinition.swift` (also holds the old `VPNState` — replaced in-place)
- `SignalDrop/Sources/Services/VPNManager/ProcessCommandExecutor.swift`
- `SignalDrop/Sources/Protocols/VPNCommandExecuting.swift`
- `SignalDrop/Sources/Protocols/ShellExecuting.swift` — **addition not in the handoff list.** Defines `ShellExecuting` *and* `ShellResult`; both are CLI-only (grep shows no non-VPN consumers).
- `SignalDrop/Sources/Services/PrivilegedHelper/HelperConstants.swift`
- `SignalDrop/Sources/Services/PrivilegedHelper/PrivilegedHelperManager.swift`
- `PrivilegedHelper/` (top-level target sources: `main.swift`, `Info.plist`, `launchd.plist`)
- `SignalDropTests/Mocks/MockVPNCommandExecutor.swift`
- Remove the `PrivilegedHelper` target + its `dependencies` entry from `project.yml`.

### Don't forget (carry to the final slice)

- **Revert `LicenseManager.isPaid` to `false`** — currently `true` with a `TODO` for manual testing. Keep it `true` *through* manual testing, flip it back as the last code change of the rework.
- The `enabledVPNs` default (`SettingsStore.swift:72`) is currently `Set(VPNDefinition.allCurated.map(\.id))` — a compile-time constant that dies with `VPNDefinition`. New semantics: discovered VPNs default to enabled (resolved at runtime, not a static default).

---

## Slice 1 — Core swap: NEVPNManager-backed discovery, status & toggling

**User stories**: 16–19 (VPN management); story 20 obsolete.

**This is one atomic slice.** Swift won't compile a half-deletion — the moment `VPNManager` / `VPNState` change, the views, `AppDelegate`, `SettingsStore`, and tests all break together. So the whole structural swap lands at once, including real toggling (it's a few lines once you hold the manager, and it's the riskiest unknown — surface it early).

### What to build

Rip out the entire CLI + PrivilegedHelper implementation and replace `VPNManager` with a Network Extension implementation behind a new `VPNConfigurationProviding` seam. Discover all system VPN profiles, map their live status, and wire real connect/disconnect through the popover toggle. Update every downstream consumer (`VPNState`, `VPNSectionView`, `VPNSettingsView`, `SettingsStore`, `AppDelegate`, `project.yml`) only as much as needed to compile and display real VPNs. Replace `MockVPNCommandExecutor` with `MockVPNConfigurationProvider` and rewrite the discovery/status/toggle tests against it.

Status reading in this slice can happen on popover-open / initial load; the live `NEVPNStatusDidChange` observer is slice 2.

### Acceptance criteria

- [ ] All deletion-set files removed; `PrivilegedHelper` target gone from `project.yml`; `NetworkExtension` framework added; `xcodegen generate` + build succeed.
- [ ] New `VPNConfigurationProviding` protocol + `MockVPNConfigurationProvider`; `VPNManager` depends only on the protocol (no Network Extension types leak into tests).
- [ ] `VPNState` simplified (displayName, mapped status, isEnabled, provider icon) — no CLI fields.
- [ ] All six `NEVPNStatus` cases map correctly to the five `VPNConnectionStatus` cases (`disconnecting` added).
- [ ] `enabledVPNs` no longer references `VPNDefinition`; discovered VPNs default to enabled.
- [ ] `VPNManagerTests` rewritten for discovery, status mapping, connect/disconnect dispatch, and the paid gate — all green via the mock.
- [ ] App launches and the popover lists the user's **real** system VPN profiles (e.g. "Rivendell", Tailscale) with correct names and current status dots.
- [ ] **Hardware gate (separate from unit tests):** Scott / desktop-app manual test confirms a real VPN actually toggles on/off from the popover. If it fails, add `com.apple.developer.networking.vpn.api` to entitlements, `xcodegen generate`, and retest. *(Cannot be verified in the terminal CLI — requires the Claude Code desktop app or Scott.)*

---

## Slice 2 — Live status + external-IP auto-refresh

**User stories**: 16–19 (real-time status); auto-refresh tie-in to IPService.

### What to build

Make status live. The new `VPNManager` observes `NEVPNStatusDidChange` and republishes per-VPN state in real time, and reloads the VPN list on `NEVPNConfigurationChange` (VPN app installed/removed). `AppDelegate` drops the old popover-open status refresh in favor of the observer, and triggers an external-IP refresh (clear cache + refetch) when any VPN's connection state changes. Add a test for config-reload handling via the mock's injectable event stream.

### Acceptance criteria

- [ ] Connecting/disconnecting a VPN from System Settings updates the SignalDrop popover within ~1s with no popover reopen.
- [ ] Installing/removing a VPN app reloads the list automatically (`NEVPNConfigurationChange`).
- [ ] A VPN state change clears the IP cache and refreshes the external IP (confirms traffic re-routing).
- [ ] No polling timer remains anywhere in the codebase.
- [ ] Test covers config-reload + status-event handling through the mock.

---

## Slice 3 — Provider icons + Settings polish

**User stories**: 45, 48 (VPN configuration); stories 46, 47, 47a obsolete.

### What to build

Add the cosmetic provider-icon mapping (`providerBundleIdentifier` → SF Symbol, unknown → `lock.shield`) and show icons next to each VPN in the popover. Rework `VPNSettingsView`: keep show/hide toggles + the multi-VPN warning toggle, **drop the "Request a VPN" button**, and add a "No VPNs configured…" empty state. Ensure `SettingsStore` persists show/hide by `localizedDescription`. Sweep all Phase 4 UI for VoiceOver labels and `String(localized:)`.

### Acceptance criteria

- [ ] Each VPN row shows a provider-appropriate icon; unknown providers show the generic shield.
- [ ] Settings show/hide toggles filter which VPNs appear in the popover; persistence keyed by `localizedDescription` survives relaunch.
- [ ] Multi-VPN warning still toggles and fires when ≥2 VPNs are connected; "Request a VPN" button is gone.
- [ ] Empty state message shows when no system VPN profiles exist.
- [ ] Every Phase 4 UI element has a VoiceOver label; every user-facing string uses `String(localized:)`.

---

## Slice 4 — Test hardening, cleanup & manual test

**User stories**: regression across 16–19, 45, 48; VPN→IP refresh tie-in.

### What to build

Finalize the test suite, do the loose-ends cleanup, and run the full manual pass. Add any missing `VPNManagerTests` coverage (enabled/disabled filtering, multi-VPN warning logic). Update the CLAUDE.md Tree to match the real file set. **Revert `LicenseManager.isPaid` to `false`** as the final code change. Run the manual test battery and a Phase 1–3 regression.

### Acceptance criteria

- [ ] `VPNManagerTests` covers discovery, status mapping (all six cases), connect/disconnect, paid gate, enabled filtering, multi-VPN warning, and config reload — all green.
- [ ] CLAUDE.md Tree reflects deleted/added files (no stale `VPNDefinition`, `PrivilegedHelper`, `ShellExecuting`, `VPNCommandExecuting` entries; `VPNConfigurationProviding` + `MockVPNConfigurationProvider` present).
- [ ] `LicenseManager.isPaid` reverted to `false`; TODO comment removed.
- [ ] Manual test passes against PRD stories 16–19 and 45, 48 (desktop app / Scott): real WireGuard + Tailscale toggle, live status, VPN→external-IP refresh.
- [ ] Phase 1–3 regression: Wi-Fi, IP, ping all still work.
- [ ] Entitlement decision documented in the handoff (whether `com.apple.developer.networking.vpn.api` was needed).
