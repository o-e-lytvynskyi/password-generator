import AppKit

// Generates a clean macOS app icon (squircle with transparent corners,
// VS Code dark palette, a blue key + password asterisks).
//
// Usage: swift tools/make_icon.swift [out.png]

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets/AppIcon-source.png"
let size: CGFloat = 1024

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let accent = color(0x2A93FF)
let accentDeep = color(0x0E63B8)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let radius = size * 0.2237

// Background squircle with a soft vertical gradient (VS Code dark).
let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
let bg = NSGradient(starting: color(0x2C2C2E), ending: color(0x18181A))!
bg.draw(in: squircle, angle: -90)

// Subtle inner highlight stroke.
let stroke = NSBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4),
                          xRadius: radius - 4, yRadius: radius - 4)
stroke.lineWidth = 3
color(0xFFFFFF).withAlphaComponent(0.06).setStroke()
stroke.stroke()

// Key symbol, rotated for a classic look, tinted blue.
let symCfg = NSImage.SymbolConfiguration(pointSize: 560, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [accent]))
let keyBase = NSImage(systemSymbolName: "key.fill", accessibilityDescription: nil)!
let key = keyBase.withSymbolConfiguration(symCfg)!
let ks = key.size

NSGraphicsContext.saveGraphicsState()
let glow = NSShadow()
glow.shadowColor = accentDeep.withAlphaComponent(0.6)
glow.shadowBlurRadius = 36
glow.shadowOffset = NSSize(width: 0, height: -10)
glow.set()

let t = NSAffineTransform()
t.translateX(by: size / 2, yBy: size / 2 + 40)
t.rotate(byDegrees: -45)
t.concat()

let keyRect = NSRect(x: -ks.width / 2, y: -ks.height / 2, width: ks.width, height: ks.height)
key.draw(in: keyRect)
NSGraphicsContext.restoreGraphicsState()

// Password asterisks along the bottom.
let dotFont = NSFont.monospacedSystemFont(ofSize: 150, weight: .heavy)
let dots = NSAttributedString(string: "****", attributes: [
    .font: dotFont,
    .foregroundColor: accent,
    .kern: 30
])
let dsize = dots.size()
dots.draw(at: NSPoint(x: (size - dsize.width) / 2 + 10, y: 150))

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! png.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath) (\(Int(size))x\(Int(size)))")
