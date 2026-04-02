import AppKit

@MainActor
final class SelectionOverlayView: NSView {
    private let screenshot: CGImage
    private let onComplete: (CGRect?) -> Void
    private var cachedImage: NSImage
    private var startPoint: NSPoint?
    private var currentSelection: NSRect?

    init(screenshot: CGImage, frame: NSRect, onComplete: @escaping (CGRect?) -> Void) {
        self.screenshot = screenshot
        self.onComplete = onComplete
        self.cachedImage = NSImage(cgImage: screenshot, size: frame.size)
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // 1. Draw the frozen screenshot as background
        cachedImage.draw(in: bounds)

        // 2. Dim everything with semi-transparent overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        // 3. If selection exists, punch through the dimming to show the clear region
        guard let selection = currentSelection,
              selection.width > 2, selection.height > 2 else { return }

        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: selection).setClip()
        cachedImage.draw(in: bounds)
        NSGraphicsContext.current?.restoreGraphicsState()

        // 4. White border around selection
        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selection)
        border.lineWidth = 1.5
        border.stroke()

        // 5. Show selection dimensions
        let width = Int(selection.width)
        let height = Int(selection.height)
        let label = "\(width) × \(height)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.6),
        ]
        let labelSize = (label as NSString).size(withAttributes: attrs)
        let labelOrigin = NSPoint(
            x: selection.midX - labelSize.width / 2,
            y: selection.minY - labelSize.height - 4
        )
        (label as NSString).draw(at: labelOrigin, withAttributes: attrs)
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentSelection = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        currentSelection = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let selection = currentSelection,
              selection.width > 3, selection.height > 3 else {
            // Too small — treat as accidental click, reset
            startPoint = nil
            currentSelection = nil
            needsDisplay = true
            return
        }

        onComplete(selection)
    }
}
