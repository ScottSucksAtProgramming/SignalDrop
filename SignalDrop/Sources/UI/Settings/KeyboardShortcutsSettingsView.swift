import SwiftUI
import Carbon.HIToolbox

struct KeyboardShortcutsSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var licenseManager: LicenseManager

    var body: some View {
        Form {
            if !licenseManager.isPaid {
                PaidFeatureNotice(
                    icon: "keyboard",
                    title: String(localized: "Keyboard Shortcuts"),
                    message: String(localized: "Upgrade to control SignalDrop with global keyboard shortcuts."),
                    color: .gray
                )
            }

            Section(String(localized: "Shortcuts")) {
                if licenseManager.isPaid {
                    ForEach(HotkeyAction.allCases, id: \.rawValue) { action in
                        HotkeyRow(
                            action: action,
                            binding: settingsStore.hotkeyBindings[action.rawValue],
                            onSet: { binding in
                                settingsStore.hotkeyBindings[action.rawValue] = binding
                            },
                            onClear: {
                                settingsStore.hotkeyBindings.removeValue(forKey: action.rawValue)
                            },
                            conflictCheck: { binding in
                                for (key, existing) in settingsStore.hotkeyBindings {
                                    guard let other = HotkeyAction(rawValue: key), other != action else { continue }
                                    if existing == binding { return other }
                                }
                                return nil
                            }
                        )
                    }

                    Button(String(localized: "Reset to Defaults")) {
                        settingsStore.hotkeyBindings = HotkeyAction.defaultBindings
                    }
                    .accessibilityLabel(String(localized: "Reset all keyboard shortcuts to defaults"))
                } else {
                    Group {
                        ForEach(HotkeyAction.allCases, id: \.rawValue) { action in
                            LabeledContent(action.displayName) {
                                Text(String(localized: "Not set"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .opacity(0.4)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct HotkeyRow: View {
    let action: HotkeyAction
    let binding: HotkeyBinding?
    let onSet: (HotkeyBinding) -> Void
    let onClear: () -> Void
    let conflictCheck: (HotkeyBinding) -> HotkeyAction?

    @State private var isRecording = false
    @State private var conflictWarning: HotkeyAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(action.displayName)
                    .frame(width: 150, alignment: .leading)

                if isRecording {
                    Text(String(localized: "Press keys…"))
                        .foregroundStyle(.secondary)
                        .frame(width: 120)
                        .background(
                            KeyCaptureView { keyCode, modifiers in
                                let newBinding = HotkeyBinding(keyCode: keyCode, modifierFlags: modifiers)
                                if let conflict = conflictCheck(newBinding) {
                                    conflictWarning = conflict
                                } else {
                                    onSet(newBinding)
                                    conflictWarning = nil
                                }
                                isRecording = false
                            }
                        )
                } else {
                    Text(binding?.displayString ?? String(localized: "Not set"))
                        .foregroundStyle(binding == nil ? .secondary : .primary)
                        .frame(width: 120)
                }

                Button(isRecording ? String(localized: "Cancel") : String(localized: "Record")) {
                    isRecording.toggle()
                    if !isRecording { conflictWarning = nil }
                }
                .accessibilityLabel(isRecording
                    ? String(localized: "Cancel recording shortcut for \(action.displayName)")
                    : String(localized: "Record shortcut for \(action.displayName)"))

                if binding != nil && !isRecording {
                    Button(String(localized: "Clear")) {
                        onClear()
                    }
                    .accessibilityLabel(String(localized: "Clear shortcut for \(action.displayName)"))
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "\(action.displayName) shortcut"))

            if let conflict = conflictWarning {
                Text(String(localized: "Conflicts with \(conflict.displayName)"))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct KeyCaptureView: NSViewRepresentable {
    let onCapture: (UInt32, UInt32) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onCapture = onCapture
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {}
}

class KeyCaptureNSView: NSView {
    var onCapture: ((UInt32, UInt32) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        var carbonModifiers: UInt32 = 0
        if event.modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if event.modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }

        onCapture?(UInt32(event.keyCode), carbonModifiers)
    }
}

extension HotkeyAction {
    var displayName: String {
        switch self {
        case .togglePopover: return String(localized: "Toggle Popover")
        case .toggleWiFi: return String(localized: "Toggle Wi-Fi")
        case .refreshIP: return String(localized: "Refresh External IP")
        case .copyLocalIP: return String(localized: "Copy Local IP")
        case .copyExternalIP: return String(localized: "Copy External IP")
        }
    }
}
