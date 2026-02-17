import JotKit
import ServiceManagement
import SwiftUI

// MARK: - General Tab

struct GeneralSettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .accessibilityLabel("Launch at Login")
                .accessibilityHint("Start jot automatically when you log in")
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                    }
                }

            Section("Global Shortcut") {
                ShortcutRecorder()
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - Notes Tab

struct NotesSettingsView: View {
    @State private var saveDirectory = Preferences.saveDirectory
    @State private var defaultTag = Preferences.defaultTag

    var body: some View {
        Form {
            Section("Save Location") {
                HStack {
                    TextField("Path", text: $saveDirectory)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Preferences.saveDirectory = saveDirectory }
                        .accessibilityLabel("Save directory path")
                        .accessibilityHint("File path where notes are saved")

                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.canCreateDirectories = true
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            saveDirectory = url.path
                            Preferences.saveDirectory = saveDirectory
                        }
                    }
                    .accessibilityLabel("Browse")
                    .accessibilityHint("Choose a folder for saving notes")
                }
            }

            Section("Default Tag") {
                TextField("e.g. quicknote (leave empty for no frontmatter)", text: $defaultTag)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Default tag")
                    .accessibilityHint("Tag automatically added to every note")
                    .onChange(of: defaultTag) { newValue in
                        Preferences.defaultTag = newValue
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shortcut Recorder

struct ShortcutRecorder: View {
    @State private var key = Preferences.shortcutKey
    @State private var modifiers = Preferences.shortcutModifiers
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text(isRecording ? "Press new shortcut..." : displayString)
                .font(.system(size: 13, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(isRecording ? "Cancel" : "Change") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .accessibilityLabel(isRecording ? "Cancel shortcut recording" : "Change global shortcut")
            .accessibilityHint(isRecording ? "Stop recording a new shortcut" : "Record a new global keyboard shortcut")
        }
        .onDisappear { stopRecording() }
    }

    private var displayString: String {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        var s = ""
        if flags.contains(.control) { s += "⌃" }
        if flags.contains(.option) { s += "⌥" }
        if flags.contains(.shift) { s += "⇧" }
        if flags.contains(.command) { s += "⌘" }
        s += key.uppercased()
        return s
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !mods.isEmpty,
                  let chars = event.charactersIgnoringModifiers, !chars.isEmpty else {
                return nil
            }

            key = chars
            modifiers = mods.rawValue
            Preferences.shortcutKey = chars
            Preferences.shortcutModifiers = mods.rawValue
            stopRecording()
            NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }
}
