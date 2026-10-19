// Z icon.png (zaoblený štvorec na čiernom pozadí) urobí AppIcon.icns: vyreže štvorec, okolie spraví priehľadné
// a zmenší ho na veľkosť podľa mriežky macOS ikon (824 z 1024 bodov).
//   swift scripts/make_icon.swift icon.png build/AppIcon.icns
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let source = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: args[1])))
else {
    print("Použitie: make_icon.swift vstup.png výstup.icns")
    exit(1)
}

/// Okraj štvorca nájdeme podľa jasu rámčeka na strednom riadku a stĺpci.
func brightness(_ x: Int, _ y: Int) -> CGFloat {
    guard let c = source.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { return 0 }
    return max(c.redComponent, c.greenComponent, c.blueComponent)
}
let width = source.pixelsWide, height = source.pixelsHigh
let columns = (0..<width).filter { brightness($0, height / 2) > 0.5 }
let rows = (0..<height).filter { brightness(width / 2, $0) > 0.5 }
guard let left = columns.first, let right = columns.last, let top = rows.first, let bottom = rows.last else {
    print("Na obrázku sa nenašiel rámček ikony.")
    exit(1)
}
// NSImage má počiatok vľavo dole.
let crop = NSRect(x: left, y: height - bottom - 1, width: right - left + 1, height: bottom - top + 1)
let image = NSImage(size: NSSize(width: width, height: height))
image.addRepresentation(source)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    let scale = CGFloat(pixels) / 1024
    let body = NSRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
    NSBezierPath(roundedRect: body, xRadius: 185 * scale, yRadius: 185 * scale).addClip()
    image.draw(in: body, from: crop, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-\(getpid()).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: iconset) }
for size in [16, 32, 128, 256, 512] {
    try render(pixels: size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(pixels: size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", args[2]]
try iconutil.run()
iconutil.waitUntilExit()
exit(iconutil.terminationStatus)
