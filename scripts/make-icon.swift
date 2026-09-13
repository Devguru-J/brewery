import AppKit

let out = CommandLine.arguments[1]
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let inset = rect.insetBy(dx: size * 0.09, dy: size * 0.09)
    let path = NSBezierPath(roundedRect: inset, xRadius: size * 0.22, yRadius: size * 0.22)
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.set()
    NSColor(red: 0.90, green: 0.55, blue: 0.15, alpha: 1).setFill()
    path.fill()
    NSShadow().set()
    let gradient = NSGradient(starting: NSColor(red: 0.99, green: 0.76, blue: 0.30, alpha: 1),
                              ending: NSColor(red: 0.78, green: 0.42, blue: 0.08, alpha: 1))!
    gradient.draw(in: path, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .semibold)
    let symbol = NSImage(systemSymbolName: "mug.fill", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let symbolRect = NSRect(x: (size - symbol.size.width) / 2, y: (size - symbol.size.height) / 2 + size * 0.02,
                            width: symbol.size.width, height: symbol.size.height)
    let tinted = NSImage(size: symbol.size, flipped: false) { r in
        symbol.draw(in: r)
        NSColor(red: 1, green: 0.97, blue: 0.90, alpha: 1).set()
        r.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(in: symbolRect)
    return true
}
let tiff = image.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
rep.size = NSSize(width: size, height: size)
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
