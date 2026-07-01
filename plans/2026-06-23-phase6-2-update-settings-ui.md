# Plan: Phase 6.2 — Update Settings UI

> Source PRD: PRD.md, user story 61
> Depends on: Phase 6.1 (Sparkle integration)

## Architectural decisions

- **Settings tab**: Add an "Updates" tab to the existing `SettingsView` TabView.
- **Sparkle binding**: Use `SPUStandardUpdaterController.updater` properties to read/write automatic check preferences. Sparkle owns this state — don't duplicate it in `SettingsStore`.
- **No license gate**: Update settings are available to all users (free and paid), per Q38.

---

## What to build

Add an "Updates" tab to Settings that lets users control automatic update checking and manually trigger a check. Display the current app version so users know what they're running.

### Steps

1. **Create `UpdateSettingsView`** in `WireBar/Sources/UI/Settings/`.
   - Toggle: "Automatically check for updates" — bound to `SPUUpdater.automaticallyChecksForUpdates`
   - Button: "Check for Updates Now" — calls `SPUStandardUpdaterController.checkForUpdates(_:)`
   - Display: "Version X.Y.Z (build N)" — read from `Bundle.main`
   - All strings use `String(localized:)`
   - All elements have VoiceOver accessibility labels

2. **Add the tab to `SettingsView`** — new tab with a `arrow.triangle.2.circlepath` SF Symbol icon, labeled "Updates". Place it after the existing tabs (after Shortcuts).

3. **Pass the updater controller** from `AppDelegate` through to `SettingsView` so `UpdateSettingsView` can access it. The updater controller is created in Phase 6.1 — this phase wires it to the UI.

4. **Manual test**: Open Settings → Updates tab, toggle automatic checks, click "Check Now", verify version string is correct.

### Acceptance criteria

- [ ] "Updates" tab appears in Settings window
- [ ] "Automatically check for updates" toggle reads and writes Sparkle's preference
- [ ] "Check for Updates Now" button triggers Sparkle's update check (standard dialog appears)
- [ ] Current version and build number are displayed correctly
- [ ] All strings use `String(localized:)`
- [ ] All UI elements have VoiceOver accessibility labels
- [ ] Tab works correctly in both light and dark mode
- [ ] All existing tests continue to pass
- [ ] Settings window resizes appropriately with the new tab
