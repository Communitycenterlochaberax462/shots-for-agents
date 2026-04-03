import AppKit

@MainActor
final class CaptureToastWindow: NSWindow {
    private var dismissTask: Task<Void, Never>?

    init(shotCount: Int, onSnapMore: @escaping () -> Void) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 48),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .transient]
        ignoresMouseEvents = false

        let toastView = CaptureToastView(
            shotCount: shotCount,
            onSnapMore: { [weak self] in
                self?.dismiss()
                onSnapMore()
            }
        )
        contentView = toastView

        // Position at top center of the screen with the mouse
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main
        {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 130
            let y = screenFrame.maxY - 64
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func show() {
        alphaValue = 0
        makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }

        // Auto-dismiss after 3 seconds
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }

    override var canBecomeKey: Bool { true }
}

@MainActor
private final class CaptureToastView: NSView {
    private let shotCount: Int
    private let onSnapMore: () -> Void
    private var snapMoreButton: NSRect = .zero
    private var trackingArea: NSTrackingArea?
    private var isHovering = false

    init(shotCount: Int, onSnapMore: @escaping () -> Void) {
        self.shotCount = shotCount
        self.onSnapMore = onSnapMore
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 48))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 10, yRadius: 10)

        // Background
        NSColor.black.withAlphaComponent(0.85).setFill()
        path.fill()

        // Border
        NSColor.white.withAlphaComponent(0.1).setStroke()
        path.lineWidth = 1
        path.stroke()

        // Checkmark + "Copied" / shot count text
        let shotLabel = shotCount == 1
            ? "✓ Copied to clipboard"
            : "✓ \(shotCount) shots copied"
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let labelSize = (shotLabel as NSString).size(withAttributes: labelAttrs)
        (shotLabel as NSString).draw(
            at: NSPoint(x: 14, y: (bounds.height - labelSize.height) / 2),
            withAttributes: labelAttrs
        )

        // "Snap more" button on the right
        let buttonText = "⌃⇧S more"
        let buttonAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: isHovering
                ? NSColor.white
                : NSColor.white.withAlphaComponent(0.5),
        ]
        let buttonSize = (buttonText as NSString).size(withAttributes: buttonAttrs)
        let buttonX = bounds.width - buttonSize.width - 14
        let buttonY = (bounds.height - buttonSize.height) / 2
        snapMoreButton = NSRect(
            x: buttonX - 6, y: buttonY - 4,
            width: buttonSize.width + 12, height: buttonSize.height + 8
        )
        (buttonText as NSString).draw(
            at: NSPoint(x: buttonX, y: buttonY),
            withAttributes: buttonAttrs
        )
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let wasHovering = isHovering
        isHovering = snapMoreButton.contains(point)
        if wasHovering != isHovering {
            NSCursor.arrow.set()
            if isHovering { NSCursor.pointingHand.set() }
            needsDisplay = true
        }
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if snapMoreButton.contains(point) {
            onSnapMore()
        }
    }
}
