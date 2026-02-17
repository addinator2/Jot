#!/usr/bin/env swift
import AppKit

// Required icon sizes for macOS .icns
let iconSizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func renderIcon(pixelSize: Int) -> Data {
    let s = CGFloat(pixelSize)
    let sc = s / 1024.0

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)!
    let ctx = NSGraphicsContext.current!.cgContext

    // --- Background: squircle with warm amber gradient ---
    let inset = s * 0.03
    let bgRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = s * 0.22
    let bg = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGradient(colors: [
        NSColor(calibratedRed: 0.94, green: 0.56, blue: 0.15, alpha: 1.0),  // bottom: deep orange
        NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.36, alpha: 1.0),   // top: warm amber
    ])!.draw(in: bg, angle: 90)

    // Subtle highlight at the top
    let hlRect = bgRect.insetBy(dx: s * 0.04, dy: s * 0.04)
    let hl = NSBezierPath(roundedRect: hlRect, xRadius: cornerRadius * 0.88, yRadius: cornerRadius * 0.88)
    NSGradient(colors: [
        NSColor(calibratedWhite: 1.0, alpha: 0.0),
        NSColor(calibratedWhite: 1.0, alpha: 0.12),
    ])!.draw(in: hl, angle: 90)

    // --- Pencil (drawn upright then rotated -45°) ---
    ctx.saveGState()
    ctx.translateBy(x: s * 0.52, y: s * 0.48)
    ctx.rotate(by: -.pi / 4)

    let bodyW: CGFloat = 120 * sc
    let hw = bodyW / 2

    // Shadow behind pencil
    ctx.setShadow(offset: CGSize(width: 2 * sc, height: -4 * sc), blur: 14 * sc,
                  color: CGColor(gray: 0, alpha: 0.3))

    ctx.setFillColor(CGColor(gray: 1, alpha: 1))

    // Tip (triangle)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 0, y: -340 * sc))
    ctx.addLine(to: CGPoint(x: -hw, y: -200 * sc))
    ctx.addLine(to: CGPoint(x: hw, y: -200 * sc))
    ctx.closePath()
    ctx.fillPath()

    // Collar / ferrule
    ctx.fill(CGRect(x: -hw - 8 * sc, y: -200 * sc, width: bodyW + 16 * sc, height: 36 * sc))

    // Body
    ctx.fill(CGRect(x: -hw, y: -164 * sc, width: bodyW, height: 430 * sc))

    // Eraser ferrule
    ctx.fill(CGRect(x: -hw - 8 * sc, y: 266 * sc, width: bodyW + 16 * sc, height: 30 * sc))

    // Eraser cap (rounded)
    let ecap = CGRect(x: -hw, y: 296 * sc, width: bodyW, height: 60 * sc)
    ctx.addPath(CGPath(roundedRect: ecap, cornerWidth: 14 * sc, cornerHeight: 14 * sc, transform: nil))
    ctx.fillPath()

    // Graphite tip detail (drawn without shadow)
    ctx.setShadow(offset: .zero, blur: 0)
    ctx.setFillColor(CGColor(srgbRed: 0.32, green: 0.32, blue: 0.36, alpha: 1.0))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 0, y: -340 * sc))
    ctx.addLine(to: CGPoint(x: -hw * 0.36, y: -256 * sc))
    ctx.addLine(to: CGPoint(x: hw * 0.36, y: -256 * sc))
    ctx.closePath()
    ctx.fillPath()

    ctx.restoreGState()

    // --- Writing squiggle near pencil tip ---
    let sq = NSBezierPath()
    let sx = s * 0.10
    let sy = s * 0.13
    sq.move(to: NSPoint(x: sx, y: sy))
    sq.curve(to: NSPoint(x: sx + s * 0.22, y: sy + s * 0.06),
             controlPoint1: NSPoint(x: sx + s * 0.07, y: sy + s * 0.10),
             controlPoint2: NSPoint(x: sx + s * 0.15, y: sy - s * 0.03))
    sq.lineWidth = max(8 * sc, 1.0)
    sq.lineCapStyle = .round

    // Subtle shadow on squiggle
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.2)
    shadow.shadowOffset = NSSize(width: 1 * sc, height: -2 * sc)
    shadow.shadowBlurRadius = 4 * sc
    shadow.set()

    NSColor.white.setStroke()
    sq.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// --- Generate iconset and convert to .icns ---
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let iconsetDir = projectDir.appendingPathComponent(".build/AppIcon.iconset")
let icnsPath = projectDir.appendingPathComponent(".build/AppIcon.icns")

try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

for (name, size) in iconSizes {
    let png = renderIcon(pixelSize: size)
    try png.write(to: iconsetDir.appendingPathComponent("\(name).png"))
    print("  \(name).png (\(size)x\(size))")
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]
try proc.run()
proc.waitUntilExit()

guard proc.terminationStatus == 0 else {
    fputs("iconutil failed with status \(proc.terminationStatus)\n", stderr)
    exit(1)
}

print("Created \(icnsPath.path)")
