import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconURL = root.appendingPathComponent("assets/icons/app_icon.png")
let outputDir = root.appendingPathComponent("play-store-assets")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

guard let sourceIcon = NSImage(contentsOf: iconURL) else {
    fatalError("Could not load app icon at \(iconURL.path)")
}

func topRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, canvasHeight: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

func topPoint(_ x: CGFloat, _ y: CGFloat, canvasHeight: CGFloat) -> CGPoint {
    CGPoint(x: x, y: canvasHeight - y)
}

func savePNG(width: Int, height: Int, url: URL, draw: @escaping (CGFloat, CGFloat) -> Void) throws {
    let size = NSSize(width: width, height: height)
    guard let image = NSImage(size: size, flipped: false, drawingHandler: { _ in
        draw(size.width, size.height)
        return true
    }).tiffRepresentation,
          let rep = NSBitmapImageRep(data: image),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(url.lastPathComponent)")
    }
    try png.write(to: url)
}

func drawRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    color.setFill()
    path.fill()
}

func drawText(_ text: String, rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    text.draw(in: rect, withAttributes: attrs)
}

func drawStroke(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: from)
    path.line(to: to)
    path.lineWidth = width
    path.lineCapStyle = .round
    color.setStroke()
    path.stroke()
}

let iconOut = outputDir.appendingPathComponent("pyramid-app-icon-512.png")
try savePNG(width: 512, height: 512, url: iconOut) { width, height in
    NSColor(calibratedRed: 0.043, green: 0.027, blue: 0.075, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    sourceIcon.draw(in: NSRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .sourceOver, fraction: 1)
}

let featureOut = outputDir.appendingPathComponent("pyramid-feature-graphic-1024x500.png")
try savePNG(width: 1024, height: 500, url: featureOut) { width, height in
    let full = NSRect(x: 0, y: 0, width: width, height: height)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.043, green: 0.027, blue: 0.075, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.055, blue: 0.16, alpha: 1),
        NSColor(calibratedRed: 0.025, green: 0.02, blue: 0.045, alpha: 1),
    ])!.draw(in: full, angle: -18)

    drawRoundedRect(topRect(-110, -95, 390, 390, canvasHeight: height), radius: 195, color: NSColor(calibratedRed: 1, green: 0.18, blue: 0.58, alpha: 0.18))
    drawRoundedRect(topRect(780, 205, 340, 340, canvasHeight: height), radius: 170, color: NSColor(calibratedRed: 0, green: 0.90, blue: 1, alpha: 0.13))
    drawRoundedRect(topRect(696, 60, 245, 245, canvasHeight: height), radius: 122, color: NSColor(calibratedRed: 1, green: 0.82, blue: 0.25, alpha: 0.08))

    let iconRect = topRect(66, 124, 148, 148, canvasHeight: height)
    drawRoundedRect(iconRect.insetBy(dx: -10, dy: -10), radius: 34, color: NSColor(calibratedWhite: 0, alpha: 0.22))
    sourceIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)

    let titleFont = NSFont.systemFont(ofSize: 58, weight: .heavy)
    let subtitleFont = NSFont.systemFont(ofSize: 30, weight: .semibold)
    let chipFont = NSFont.systemFont(ofSize: 18, weight: .bold)

    drawText("Pyramid", rect: topRect(252, 128, 420, 66, canvasHeight: height), font: titleFont, color: NSColor.white)
    drawText("Drinking Game", rect: topRect(255, 190, 420, 44, canvasHeight: height), font: subtitleFont, color: NSColor(calibratedRed: 0.86, green: 0.82, blue: 0.96, alpha: 1))
    drawText("Cartas, faroles y reglas de fiesta", rect: topRect(255, 260, 450, 34, canvasHeight: height), font: NSFont.systemFont(ofSize: 23, weight: .medium), color: NSColor(calibratedRed: 0.67, green: 0.62, blue: 0.78, alpha: 1))

    let chips = ["2 barajas", "Grupo", "Sin WiFi"]
    var x: CGFloat = 255
    for chip in chips {
        let chipWidth = CGFloat(chip.count * 10 + 35)
        let rect = topRect(x, 320, chipWidth, 38, canvasHeight: height)
        drawRoundedRect(rect, radius: 19, color: NSColor(calibratedWhite: 1, alpha: 0.08))
        drawText(chip, rect: topRect(x, 327, chipWidth, 22, canvasHeight: height), font: chipFont, color: NSColor(calibratedRed: 0.94, green: 0.90, blue: 1, alpha: 1), alignment: .center)
        x += chipWidth + 12
    }

    let a = topPoint(792, 102, canvasHeight: height)
    let b = topPoint(916, 356, canvasHeight: height)
    let c = topPoint(662, 356, canvasHeight: height)
    drawStroke(from: a, to: b, color: NSColor(calibratedRed: 1, green: 0.20, blue: 0.57, alpha: 0.95), width: 22)
    drawStroke(from: b, to: c, color: NSColor(calibratedRed: 0.02, green: 0.88, blue: 1, alpha: 0.95), width: 22)
    drawStroke(from: c, to: a, color: NSColor(calibratedRed: 1, green: 0.78, blue: 0.26, alpha: 0.95), width: 22)

    for (index, card) in [
        (topRect(678, 305, 62, 90, canvasHeight: height), "#"),
        (topRect(748, 305, 62, 90, canvasHeight: height), "A"),
        (topRect(818, 305, 62, 90, canvasHeight: height), "?"),
    ].enumerated() {
        drawRoundedRect(card.0, radius: 8, color: NSColor(calibratedWhite: 1, alpha: index == 1 ? 0.95 : 0.82))
        drawRoundedRect(card.0.insetBy(dx: 8, dy: 8), radius: 5, color: NSColor(calibratedRed: 0.043, green: 0.027, blue: 0.075, alpha: index == 1 ? 0.08 : 0.16))
        drawText(card.1, rect: card.0.insetBy(dx: 0, dy: 22), font: NSFont.systemFont(ofSize: 30, weight: .black), color: NSColor(calibratedRed: 1, green: 0.20, blue: 0.57, alpha: 0.95), alignment: .center)
    }
}

print(iconOut.path)
print(featureOut.path)
