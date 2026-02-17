import AppKit

final class FloatingPanel: NSPanel {
    private let visualEffectView: NSVisualEffectView

    init() {
        visualEffectView = NSVisualEffectView()

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 340),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )

        isFloatingPanel = true
        level = .floating
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Rounded clip container as the window's content view
        let container = NSView(frame: contentRect(forFrameRect: frame))
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.masksToBounds = true
        contentView = container

        // Frosted glass fills the container
        visualEffectView.material = .sidebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(visualEffectView)

        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }

    func setContentSwiftUI(_ view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            view.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
        ])
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
