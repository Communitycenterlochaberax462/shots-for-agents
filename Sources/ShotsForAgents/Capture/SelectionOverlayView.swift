import AppKit

@MainActor
final class SelectionOverlayView: NSView {
    private let screenshot: CGImage
    private let onComplete: (CGRect?) -> Void
    private var cachedImage: NSImage
    private var startPoint: NSPoint?
    private var currentSelection: NSRect?
    private var mouseLocation: NSPoint?
    private var isSpaceHeld = false
    private var spaceGrabOffset: NSPoint?
    nonisolated(unsafe) private var keyDownMonitor: Any?
    nonisolated(unsafe) private var keyUpMonitor: Any?

    private let closeButton: NSButton

    init(screenshot: CGImage, frame: NSRect, onComplete: @escaping (CGRect?) -> Void) {
        self.screenshot = screenshot
        self.onComplete = onComplete
        self.cachedImage = NSImage(cgImage: screenshot, size: frame.size)

        // Close button — top-left corner
        let button = NSButton(frame: .zero)
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.image = NSImage(
            systemSymbolName: "xmark.circle.fill",
            accessibilityDescription: "Close"
        )?.withSymbolConfiguration(
            .init(pointSize: 20, weight: .medium)
        )
        button.contentTintColor = .white
        button.imagePosition = .imageOnly
        button.setButtonType(.momentaryChange)
        self.closeButton = button

        super.init(frame: frame)

        button.target = self
        button.action = #selector(closeButtonTapped)
        button.sizeToFit()
        // Position in top-left with padding
        let padding: CGFloat = 16
        button.frame.origin = CGPoint(x: padding, y: frame.height - button.frame.height - padding)
        addSubview(button)

        // Tracking area for crosshair guides
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self
        ))
        installKeyMonitors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
        addCursorRect(closeButton.frame, cursor: .arrow)
    }

    @objc private func closeButtonTapped() {
        onComplete(nil)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // 1. Draw the frozen screenshot as background
        cachedImage.draw(in: bounds)

        // 2. Dim everything with semi-transparent overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        // 3. If selection exists, punch through the dimming to show the clear region
        if let selection = currentSelection,
           selection.width > 2, selection.height > 2 {
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
        } else if let mouse = mouseLocation, startPoint == nil {
            // 6. Crosshair guides when no selection is active
            drawCrosshairGuides(at: mouse)
        }
    }

    private func drawCrosshairGuides(at point: NSPoint) {
        let guideColor = NSColor.white.withAlphaComponent(0.4)
        guideColor.setStroke()

        let dash: [CGFloat] = [4, 4]

        // Horizontal line
        let hLine = NSBezierPath()
        hLine.move(to: NSPoint(x: bounds.minX, y: point.y))
        hLine.line(to: NSPoint(x: bounds.maxX, y: point.y))
        hLine.lineWidth = 0.5
        hLine.setLineDash(dash, count: 2, phase: 0)
        hLine.stroke()

        // Vertical line
        let vLine = NSBezierPath()
        vLine.move(to: NSPoint(x: point.x, y: bounds.minY))
        vLine.line(to: NSPoint(x: point.x, y: bounds.maxY))
        vLine.lineWidth = 0.5
        vLine.setLineDash(dash, count: 2, phase: 0)
        vLine.stroke()
    }

    // MARK: - Mouse Events

    override func mouseMoved(with event: NSEvent) {
        mouseLocation = convert(event.locationInWindow, from: nil)
        if startPoint == nil {
            needsDisplay = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        // Don't start a selection when clicking the close button
        if closeButton.frame.contains(point) { return }
        startPoint = point
        currentSelection = nil
        mouseLocation = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        if isSpaceHeld {
            // Move the entire selection
            if let grabOffset = spaceGrabOffset, let selection = currentSelection {
                let dx = current.x - grabOffset.x
                let dy = current.y - grabOffset.y
                currentSelection = NSRect(
                    x: selection.origin.x + dx,
                    y: selection.origin.y + dy,
                    width: selection.width,
                    height: selection.height
                )
                // Update start point so resizing continues from new position
                startPoint = NSPoint(x: start.x + dx, y: start.y + dy)
                spaceGrabOffset = current
            }
        } else {
            currentSelection = NSRect(
                x: min(start.x, current.x),
                y: min(start.y, current.y),
                width: abs(current.x - start.x),
                height: abs(current.y - start.y)
            )
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let selection = currentSelection,
              selection.width > 3, selection.height > 3 else {
            // Too small — treat as accidental click, reset
            startPoint = nil
            currentSelection = nil
            mouseLocation = convert(event.locationInWindow, from: nil)
            needsDisplay = true
            return
        }

        onComplete(selection)
    }

    // MARK: - Key Monitors

    private func installKeyMonitors() {
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 49 { // Space — consume all (including repeats) to prevent beep
                if !event.isARepeat {
                    self.isSpaceHeld = true
                    let mouse = self.window?.mouseLocationOutsideOfEventStream ?? .zero
                    self.spaceGrabOffset = self.convert(mouse, from: nil)
                    NSCursor.closedHand.set()
                }
                return nil
            }
            return event
        }

        keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 49 { // Space
                self.isSpaceHeld = false
                self.spaceGrabOffset = nil
                NSCursor.crosshair.set()
                return nil
            }
            return event
        }
    }

    func removeKeyMonitors() {
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
        if let monitor = keyUpMonitor {
            NSEvent.removeMonitor(monitor)
            keyUpMonitor = nil
        }
    }

    deinit {
        // Monitors must be removed — but deinit is nonisolated,
        // so we capture the references and remove on main actor.
        let down = keyDownMonitor
        let up = keyUpMonitor
        MainActor.assumeIsolated {
            if let down { NSEvent.removeMonitor(down) }
            if let up { NSEvent.removeMonitor(up) }
        }
    }
}
