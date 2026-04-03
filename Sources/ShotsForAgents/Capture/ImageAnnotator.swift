import AppKit

enum ImageAnnotator {
    /// Burns a text label onto the bottom of a PNG image, returning new PNG data.
    static func annotate(pngData: Data, text: String) -> Data {
        guard let image = NSImage(data: pngData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return pngData
        }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let fontSize: CGFloat = max(14, imageHeight * 0.028)
        let padding: CGFloat = fontSize * 0.6
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)

        let bannerHeight = textSize.height + padding * 2
        let totalHeight = imageHeight + bannerHeight

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(imageWidth),
            pixelsHigh: Int(totalHeight),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
            let ctx = NSGraphicsContext(bitmapImageRep: rep)
        else {
            return pngData
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx

        // Draw banner background at bottom (origin is bottom-left in AppKit)
        NSColor(white: 0.12, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: imageWidth, height: bannerHeight).fill()

        // Draw annotation text centered in banner
        let textOrigin = NSPoint(
            x: padding,
            y: (bannerHeight - textSize.height) / 2
        )
        (text as NSString).draw(at: textOrigin, withAttributes: attrs)

        // Draw the original image above the banner
        let imageRect = NSRect(x: 0, y: bannerHeight, width: imageWidth, height: imageHeight)
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: imageWidth, height: imageHeight))
        nsImage.draw(in: imageRect)

        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:]) ?? pngData
    }
}
