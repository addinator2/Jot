import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController, NSToolbarDelegate {

    private enum Tab: String, CaseIterable {
        case general
        case notes

        var label: String {
            switch self {
            case .general: return "General"
            case .notes: return "Notes"
            }
        }

        var icon: String {
            switch self {
            case .general: return "gear"
            case .notes: return "doc.text"
            }
        }

        var identifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier(rawValue)
        }
    }

    convenience init() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        self.init(window: window)

        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = Tab.general.identifier
        window.toolbar = toolbar
        window.toolbarStyle = .preference

        selectTab(.general, animate: false)
        window.center()
    }

    private func selectTab(_ tab: Tab, animate: Bool = true) {
        guard let window else { return }
        window.title = tab.label

        let content: NSView
        switch tab {
        case .general:
            content = NSHostingView(rootView: GeneralSettingsView())
        case .notes:
            content = NSHostingView(rootView: NotesSettingsView())
        }

        let contentSize = content.fittingSize
        let titleBarHeight = window.frame.height - window.contentLayoutRect.height
        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: window.frame.maxY - contentSize.height - titleBarHeight,
            width: window.frame.width.isZero ? contentSize.width : window.frame.width,
            height: contentSize.height + titleBarHeight
        )

        window.contentView = content
        window.setFrame(newFrame, display: true, animate: animate)
    }

    // MARK: - NSToolbarDelegate

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let tab = Tab(rawValue: itemIdentifier.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.label
        item.image = NSImage(systemSymbolName: tab.icon, accessibilityDescription: tab.label)
        item.target = self
        item.action = #selector(toolbarItemClicked(_:))
        return item
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Tab.allCases.map(\.identifier)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Tab.allCases.map(\.identifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Tab.allCases.map(\.identifier)
    }

    @objc private func toolbarItemClicked(_ sender: NSToolbarItem) {
        guard let tab = Tab(rawValue: sender.itemIdentifier.rawValue) else { return }
        selectTab(tab)
    }
}
