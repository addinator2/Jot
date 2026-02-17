import AppKit

enum MenuBarIcon {
    /// Creates a custom menu bar icon: a pencil at 45° with a small writing squiggle.
    /// Returned as a template image so macOS auto-tints for light/dark mode.
    static func create() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            NSColor.black.setStroke()

            // --- Pencil (drawn upright then rotated -45°) ---
            NSGraphicsContext.current?.saveGraphicsState()

            let transform = NSAffineTransform()
            transform.translateX(by: 9.5, yBy: 8.5)
            transform.rotate(byDegrees: -45)
            transform.concat()

            let w: CGFloat = 2.6          // body width
            let hw = w / 2

            // Tip (triangle)
            let tip = NSBezierPath()
            tip.move(to: NSPoint(x: 0, y: -7))       // sharp point
            tip.line(to: NSPoint(x: -hw, y: -4.2))
            tip.line(to: NSPoint(x: hw, y: -4.2))
            tip.close()
            tip.fill()

            // Collar / ferrule (slightly wider band)
            let collar = NSRect(x: -hw - 0.25, y: -4.2, width: w + 0.5, height: 0.9)
            NSBezierPath(rect: collar).fill()

            // Body
            let body = NSRect(x: -hw, y: -3.3, width: w, height: 9.3)
            NSBezierPath(rect: body).fill()

            // Eraser ferrule
            let eferrule = NSRect(x: -hw - 0.25, y: 6.0, width: w + 0.5, height: 0.7)
            NSBezierPath(rect: eferrule).fill()

            // Eraser cap (rounded)
            let ecap = NSRect(x: -hw, y: 6.7, width: w, height: 1.5)
            NSBezierPath(roundedRect: ecap, xRadius: 0.8, yRadius: 0.8).fill()

            NSGraphicsContext.current?.restoreGraphicsState()

            // --- Writing squiggle near the pencil tip ---
            let squiggle = NSBezierPath()
            squiggle.move(to: NSPoint(x: 1.0, y: 1.8))
            squiggle.curve(
                to: NSPoint(x: 5.0, y: 3.0),
                controlPoint1: NSPoint(x: 2.2, y: 3.8),
                controlPoint2: NSPoint(x: 3.8, y: 0.8)
            )
            squiggle.lineWidth = 1.1
            squiggle.lineCapStyle = .round
            squiggle.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }
}
