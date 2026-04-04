import AppKit
import CoreGraphics
import Foundation

let outputDir = "ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/Assets.xcassets/AppIcon.appiconset"

func createIcon(size: Int) -> NSImage {
    let cgSize = CGSize(width: size, height: size)
    let image = NSImage(size: cgSize)
    
    image.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else {
        fatalError("Failed to get graphics context")
    }
    
    let cornerRadius = CGFloat(size) * 0.2236
    let rect = CGRect(origin: .zero, size: cgSize)
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    context.addPath(path)
    context.clip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1.0),
        CGColor(red: 0.35, green: 0.60, blue: 1.00, alpha: 1.0)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!
    
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )
    
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.55, weight: .medium)
    if let symbolImage = NSImage(systemSymbolName: "gauge.open.with.lines.needle.33percent", accessibilityDescription: "Usage gauge")?
        .withSymbolConfiguration(symbolConfig) {
        
        let tinted = symbolImage.tinted(with: .white)
        let symbolSize = tinted.size
        let symbolRect = CGRect(
            x: (CGFloat(size) - symbolSize.width) / 2,
            y: (CGFloat(size) - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        tinted.draw(in: symbolRect)
    }
    
    image.unlockFocus()
    return image
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        self.draw(in: rect)
        color.set()
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
    
    func pngData() -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = self.size
        return bitmapRep.representation(using: .png, properties: [:])
    }
}

let fm = FileManager.default

if !fm.fileExists(atPath: outputDir) {
    try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
}

let sizeMap: [(size: Int, filenames: [String])] = [
    (16, ["icon_16x16.png"]),
    (32, ["icon_16x16@2x.png", "icon_32x32.png"]),
    (64, ["icon_32x32@2x.png"]),
    (128, ["icon_128x128.png"]),
    (256, ["icon_128x128@2x.png", "icon_256x256.png"]),
    (512, ["icon_512x512.png"]),
    (1024, ["icon_512x512@2x.png"])
]

for entry in sizeMap {
    let icon = createIcon(size: entry.size)
    if let data = icon.pngData() {
        for filename in entry.filenames {
            let outputPath = "\(outputDir)/\(filename)"
            try data.write(to: URL(fileURLWithPath: outputPath))
            print("Generated \(filename)")
        }
    }
}

print("All icons generated in \(outputDir)")
