# Settings UI Redesign

**Inspiration:** xIsland app settings (screenshots provided by Scott)
**Goal:** Modernize WireBar's settings window to match the polished sidebar + grouped content pattern.

## Layout

- SwiftUI `TabView` with `.tabViewStyle(.grouped)` (native macOS sidebar style)
- Resizable window, minimum size ~700x450
- Supports both light and dark mode (system adaptive)

## Sidebar Structure

Each item gets a colored SF Symbol icon (distinct color per item, similar to System Settings).

### Top Group (unlabeled)
- General (`gear`, blue)
- Network Details (`network`, green)
- IP & Latency (`globe`, purple)
- VPN (`shield.lefthalf.filled`, orange)

### Preferences
- Notifications (`bell`, red)
- Shortcuts (`keyboard`, gray)

### Other
- License (`key`, yellow) — **NEW**
- About (`info.circle`, blue) — **NEW** (replaces Updates tab)

## Content Panes

Use SwiftUI `Form` with `Section("Header")` for grouped sections. Existing settings content stays but gets:
- Proper section grouping with headers
- Description text in secondary style where helpful
- Consistent control alignment (label left, control right)
- `LabeledContent` for non-toggle rows

## About Pane (New)

Centered layout:
1. App icon (pulled from bundle via `NSImage(named: NSImage.applicationIconName)`)
2. "WireBar" title + version string
3. Row: "Check for Updates..." (triggers Sparkle updater)
4. Row: "Website" → `https://github.com/ScottSucksAtProgramming/WireBar` (external link arrow)
5. Row: "Creator" → "ScottSucksAtProgramming" → `https://github.com/ScottSucksAtProgramming` (external link arrow)
6. Row: "Report Bug" → `https://github.com/ScottSucksAtProgramming/WireBar/issues` (external link arrow)

## License Pane (New)

- License key entry field
- Current tier display (Free / Paid)
- Upgrade button/link
- Paid-feature lock icons in other panes navigate here when clicked

## Assets Needed

None — app icon from bundle at runtime, all sidebar and row icons are SF Symbols.

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Sidebar implementation | `.tabViewStyle(.grouped)` | Native macOS look, free keyboard/accessibility support |
| Content pane styling | SwiftUI `Form` | Standard macOS settings layout, no custom row reimplementation |
| Theme support | Light + dark (system) | macOS user expectation, SwiftUI adaptive colors |
| Updates tab | Merged into About | Follows xIsland pattern, cleaner sidebar |
| Paid feature locks | Navigate to License pane | Single upgrade path, less intrusive than modals |
| Sidebar icons | Colored SF Symbols | Visual scanning, matches System Settings pattern |
| Window sizing | 700x450 min, resizable | Room for sidebar + content, user adjustable |
