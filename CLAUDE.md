# SignalDrop

## Purpose

macOS menu bar utility built with Swift/SwiftUI that provides Wi-Fi status, VPN management, network switching, and detailed network information in a single popover interface. Distributed directly (not App Store), freemium model via LemonSqueezy. See `SPEC.md` for the full product specification and `PRD.md` for the formal requirements.

## Tree

```
wifi-menubar/
  AGENTS.md
  CLAUDE.md
  INDEX.md
  .taskpaper
  project.yml
  SPEC.md
  PRD.md
  ROADMAP.md
  DESIGN_DECISIONS.md
  SignalDrop/
    Sources/
      App/
        SignalDropApp.swift
        AppDelegate.swift
      Models/
        NetworkState.swift
        ScannedNetwork.swift
      Protocols/
        NetworkPathProviding.swift
        WLANInterface.swift
        ShellExecuting.swift
        WiFiScanning.swift
      Services/
        NetworkMonitor/
          NetworkMonitor.swift
        WiFiManager/
          WiFiManager.swift
          CoreWLANScanner.swift
        IPService/
          IPService.swift
          DNSExternalIPResolver.swift
        PingService/
          PingService.swift
        SettingsStore/
          SettingsStore.swift
        LicenseManager/
          LicenseManager.swift
      UI/
        MenuBar/
        Popover/
          PopoverView.swift
          ConnectionInfoView.swift
          EthernetInfoView.swift
          NetworkListView.swift
          PasswordInputView.swift
          IPPingView.swift
        Settings/
          SettingsView.swift
          NetworkDetailsSettingsView.swift
          IPPingSettingsView.swift
        Onboarding/
    Resources/
      Info.plist
      SignalDrop.entitlements
  SignalDropTests/
    NetworkMonitorTests.swift
    SettingsStoreTests.swift
    WiFiManagerTests.swift
    IPServiceTests.swift
    PingServiceTests.swift
    Mocks/
      MockWiFiScanner.swift
  handoffs/          (local only, .gitignored — session handoff docs)
  context/
    conventions.md
    lessons.md
```

## Rules

1. On session start within `wifi-menubar/`, read this file, then `INDEX.md`.
2. Read `SPEC.md` and `PRD.md` before implementing any feature — they are the source of truth for product decisions.
3. When creating, renaming, or deleting files, update the Tree section above.
4. Follow the Note-Taking protocol: log lessons to `context/lessons.md` after completing tasks.
5. Use `na next` to see pending tasks. Add tasks with `na add "Task text"`.

## Git Workflow

- Development uses **feature branches per phase**: `phase/1-walking-skeleton`, `phase/2-wifi-management`, etc.
- Always create the phase branch before starting work. Never commit directly to `main` during development.
- Merge to `main` only after the phase is complete and all manual testing passes.
- Check `.taskpaper` for the current phase and branch name.
- At the end of each session, run `/mattpocock-handoff` and save the handoff doc to `handoffs/` in the repo.

## Agent Guidelines

### Think Before Coding

- State assumptions explicitly before implementing. If uncertain, ask rather than guess.
- If multiple interpretations exist, present them all — don't pick one silently.
- If a simpler approach exists, say so. Push back when warranted.
- Surface inconsistencies and tradeoffs rather than resolving them unilaterally.
- **When asking the user for input:** Scott is product and UX focused. Do not ask technical implementation questions that the agent should be able to resolve independently. If a technical decision genuinely requires user input, provide a plain-language explanation of each option with clear tradeoffs — no jargon without explanation.

### Simplicity First

- No features beyond exactly what was asked.
- No abstractions for single-use code. No speculative "flexibility" or "configurability."
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Add complexity only when the requirement actually emerges — not in anticipation of it.

### Surgical Changes

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd personally do it differently.
- Remove imports, variables, and functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless explicitly asked — mention it instead.
- Every changed line should trace directly to the request.

### Goal-Driven Execution

- Transform tasks into verifiable goals before starting:
  - "Add validation" → "Write tests for invalid inputs, then make them pass"
  - "Fix the bug" → "Write a test that reproduces it, then make it pass"
- For multi-step tasks, state a brief plan upfront: `[Step] → verify: [check]`
- Write a failing test to reproduce a bug before fixing it, not after.

## Swift / macOS Rules

1. Use SwiftUI idioms (environment values, `@Observable`, state management) — don't fight the framework.
2. All user-facing strings must use `String(localized:)` for localization readiness.
3. All UI elements must have VoiceOver accessibility labels.
4. Target macOS 13+ (Ventura). Use `@available` checks for any API not available in Ventura.
5. Follow Apple's Human Interface Guidelines for menu bar apps and popovers.

## SignalDrop-Specific Rules

1. **No data logging to disk.** All network info stays in-memory only. This is a core trust promise.
2. **Crash reporting (Sentry) must never initialize unless the user has explicitly opted in.** No silent telemetry.
3. **All external network calls must use HTTPS only.**
4. **VPN CLI commands must only execute through the PrivilegedHelper** — never shell out directly from the main app process.
5. **Paid features must be gated through LicenseManager** — never hardcode tier checks or scatter `if paid` logic through the codebase.
6. **Follow the module boundaries in PRD.md.** Modules communicate through their public interfaces. Don't reach into another module's internals.

## Testing Rules

### Unit / Integration Tests

1. Test external behavior through each module's public interface, not implementation details.
2. Use protocol-based dependency injection to mock system APIs (CoreWLAN, NWPathMonitor, shell execution).
3. No real network calls or VPN toggling in tests. All tests must be deterministic.
4. Modules under test: NetworkMonitor, WiFiManager, VPNManager, PrivilegedHelper, IPService, PingService, HotkeyManager, NotificationService.

### Manual Testing (AI Agent)

1. **When to run:** After major updates, when features are completed or added, and periodically during active development. Not required for every small change.
2. **How:** The AI agent builds and launches the app, then uses computer-use to interact with it as a real user would — clicking the menu bar icon, navigating the popover, toggling VPNs, switching networks, opening settings, etc.
3. **Environment requirement:** Manual testing requires the **Claude Code desktop app** (not the terminal CLI) because it uses computer-use to see and interact with the screen. If running in the terminal, remind the user: *"I need to do manual testing but I'm in the terminal. Please open this session in the Claude Code desktop app so I can see and interact with the screen."*
4. **What to verify:**
   - **Functionality:** Does each feature work correctly? Do toggles toggle, do networks switch, do IPs refresh?
   - **User experience:** Is the popover layout correct? Are sections collapsible? Is text readable? Do animations feel right? Does it follow system dark/light mode?
   - **Error states:** What happens when Wi-Fi is off? When a VPN CLI is missing? When the IP fetch fails?
   - **Edge cases:** Multiple VPNs active, Wi-Fi + Ethernet simultaneous, long network names, empty network list.
   - **Accessibility:** Can the popover be navigated with keyboard? Are VoiceOver labels present and meaningful?
5. **Reporting:** After manual testing, log any issues found as tasks. Log UX observations and fixes to `context/lessons.md`.

## Note-Taking

After completing a task, log any corrections, preferences, patterns, or discoveries.

**Protocol:**

1. Write a dated one-liner to the appropriate location:
   - General lessons → `context/lessons.md`
   - Topic-specific lessons → the relevant context file's Lessons Learned section
2. If 3+ related lessons accumulate in `context/lessons.md`, extract them into a new context file in `context/`, add a Lessons Learned section to that file, and update both `INDEX.md` and the Tree above.
3. Do not ask permission to log lessons. Just log them.

### Recent Lessons (last 5)

<!-- Claude maintains this as a quick-reference mirror of the most recent entries from context/lessons.md. -->
