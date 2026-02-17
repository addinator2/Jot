import AppKit
import HotKey
import JotKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenu: NSMenu!
    private var floatingPanel: FloatingPanel?
    private var settingsWindowController: SettingsWindowController?
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        setupMenuBar()
        registerShortcut()

        NotificationCenter.default.addObserver(
            self, selector: #selector(shortcutDidChange),
            name: .shortcutDidChange, object: nil)
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = MenuBarIcon.create()
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        statusMenu = NSMenu()
        statusMenu.addItem(NSMenuItem(title: "New Note", action: #selector(showNotePanel), keyEquivalent: "n"))
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        statusMenu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: ""))
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Quit jot", action: #selector(quitApp), keyEquivalent: "q"))
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            showNotePanel()
        }
    }

    // MARK: - Actions

    @objc func showNotePanel() {
        if let panel = floatingPanel, panel.isVisible {
            panel.close()
            floatingPanel = nil
            return
        }

        let panel = FloatingPanel()
        let editorView = NoteEditorView(onSave: { [weak self] title, body, tags in
            do {
                try NoteService.save(title: title, body: body, tags: tags)
                self?.floatingPanel?.close()
                self?.floatingPanel = nil
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to save note"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }, onCancel: { [weak self] in
            self?.floatingPanel?.close()
            self?.floatingPanel = nil
        })

        let hostingView = NSHostingView(rootView: editorView)
        panel.setContentSwiftUI(hostingView)
        panel.center()
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        panel.makeKeyAndOrderFront(nil)
        floatingPanel = panel
    }

    @objc private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func checkForUpdates() {
        Updater.checkForUpdates()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Global Shortcut

    @objc private func shortcutDidChange() {
        registerShortcut()
    }

    private func registerShortcut() {
        hotKey = nil

        guard let key = Key(string: Preferences.shortcutKey.lowercased()) else { return }
        let modifiers = NSEvent.ModifierFlags(rawValue: Preferences.shortcutModifiers)
            .intersection([.command, .shift, .option, .control])

        hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.showNotePanel()
        }
    }
}

extension Notification.Name {
    static let shortcutDidChange = Notification.Name("JotShortcutDidChange")
}
