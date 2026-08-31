import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

func ensureDirectory(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

func saveTransparentPNG(width: Int, height: Int, url: URL, draw: @escaping (CGFloat, CGFloat) -> Void) throws {
    let size = NSSize(width: width, height: height)
    guard let tiff = NSImage(size: size, flipped: false, drawingHandler: { rect in
        NSColor.clear.setFill()
        rect.fill()
        draw(size.width, size.height)
        return true
    }).tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(url.lastPathComponent)")
    }
    try png.write(to: url)
}

func cgColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) -> CGColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha).cgColor
}

func addTrianglePath(to ctx: CGContext, top: CGPoint, left: CGPoint, right: CGPoint) {
    ctx.move(to: top)
    ctx.addLine(to: right)
    ctx.addLine(to: left)
    ctx.closePath()
}

func drawTriangleGlow(width: CGFloat, top: CGPoint, left: CGPoint, right: CGPoint, color: CGColor, alpha: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState()
    ctx.setLineJoin(.round)
    ctx.setLineCap(.round)
    ctx.setLineWidth(width)
    ctx.setStrokeColor(color.copy(alpha: alpha) ?? color)
    addTrianglePath(to: ctx, top: top, left: left, right: right)
    ctx.strokePath()
    ctx.restoreGState()
}

func drawGradientStroke(from start: CGPoint, to end: CGPoint, width: CGFloat, colors: [CGColor]) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) else { return }

    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineWidth(width)
    ctx.move(to: start)
    ctx.addLine(to: end)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
    ctx.restoreGState()
}

func drawTriangleLogo(width: CGFloat, height: CGFloat) {
    let side = min(width, height)
    let top = CGPoint(x: width * 0.5, y: height * 0.77)
    let left = CGPoint(x: width * 0.17, y: height * 0.24)
    let right = CGPoint(x: width * 0.83, y: height * 0.24)
    let stroke = side * 0.062

    let pink = cgColor(red: 1.0, green: 0.18, blue: 0.58)
    let coral = cgColor(red: 1.0, green: 0.43, blue: 0.45)
    let yellow = cgColor(red: 1.0, green: 0.82, blue: 0.25)
    let mint = cgColor(red: 0.33, green: 0.86, blue: 0.67)
    let cyan = cgColor(red: 0.0, green: 0.88, blue: 1.0)

    drawTriangleGlow(width: stroke * 1.9, top: top, left: left, right: right, color: pink, alpha: 0.12)

    drawGradientStroke(from: left, to: top, width: stroke, colors: [yellow, coral, pink])
    drawGradientStroke(from: top, to: right, width: stroke, colors: [pink, yellow, cyan])
    drawGradientStroke(from: left, to: right, width: stroke, colors: [yellow, mint, cyan])
}

let iosDir = root.appendingPathComponent("ios/Runner/Assets.xcassets/LaunchImage.imageset")
try ensureDirectory(iosDir)
for (filename, size) in [
    ("LaunchImage.png", 190),
    ("LaunchImage@2x.png", 380),
    ("LaunchImage@3x.png", 570),
] {
    let url = iosDir.appendingPathComponent(filename)
    try saveTransparentPNG(width: size, height: size, url: url) { width, height in
        drawTriangleLogo(width: width, height: height)
    }
    print(url.path)
}

for (directory, size) in [
    ("drawable-mdpi", 190),
    ("drawable-hdpi", 285),
    ("drawable-xhdpi", 380),
    ("drawable-xxhdpi", 570),
    ("drawable-xxxhdpi", 760),
] {
    let dir = root.appendingPathComponent("android/app/src/main/res/\(directory)")
    try ensureDirectory(dir)
    let url = dir.appendingPathComponent("launch_logo.png")
    try saveTransparentPNG(width: size, height: size, url: url) { width, height in
        drawTriangleLogo(width: width, height: height)
    }
    print(url.path)
}
