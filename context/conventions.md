---
title: "WireBar Conventions"
summary: "Swift/SwiftUI coding conventions, module structure, and naming standards for WireBar"
created: 2026-06-22
updated: 2026-06-22
---

# WireBar Conventions

## What Belongs Here

Swift/SwiftUI source code for the WireBar macOS menu bar app, Xcode project files, tests, and build configuration. Project planning documents (SPEC, PRD, roadmap) also live at the project root.

## What Does NOT Belong Here

- Planning notes and non-code documentation belong in `~/Documents/1_projects/` per the parent workspace rules.
- General-purpose utilities or libraries that aren't WireBar-specific should be separate packages.
- Credentials, API keys, or license keys must never be committed. Use environment variables or Xcode build settings.

## Module Structure

The app follows the module architecture defined in `PRD.md`. Each module should:

- Live in its own directory/group within the Xcode project
- Expose a clean public interface (protocol + concrete implementation)
- Accept dependencies via protocol injection (for testability)
- Not import or depend on other modules' internals

Core modules: NetworkMonitor, WiFiManager, VPNManager, PrivilegedHelper, IPService, PingService, LicenseManager, HotkeyManager, NotificationService, SettingsStore, UI Layer.

## Naming Conventions

- **Files:** PascalCase matching the primary type they contain (e.g., `NetworkMonitor.swift`, `VPNManager.swift`)
- **Protocols:** Descriptive name without `Protocol` suffix (e.g., `NetworkMonitoring`, `VPNManaging`)
- **Views:** Suffix with `View` (e.g., `PopoverView`, `SettingsView`, `VPNToggleView`)
- **View Models:** Suffix with `ViewModel` if used (e.g., `PopoverViewModel`)
- **Tests:** Mirror source file name with `Tests` suffix (e.g., `NetworkMonitorTests.swift`)

## Localization

All user-facing strings must use `String(localized:)`. No hardcoded English strings in views or notifications. This is enforced from day one even though we ship English-only.

## Accessibility

Every interactive element needs an `.accessibilityLabel()`. Every toggle needs `.accessibilityValue()` reflecting its state. Navigation must work via keyboard Tab. Test with VoiceOver periodically during manual testing rounds.
