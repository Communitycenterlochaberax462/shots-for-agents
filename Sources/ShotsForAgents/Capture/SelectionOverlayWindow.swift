import AppKit

@MainActor
final class SelectionOverlayWindow: NSWindow {
    private let completionHandler: (CGRect?) -> Void
    private var didComplete = false

    init(screenshot: CGImage, displayFrame: CGRect, onComplete: @escaping (CGRect?) -> Void) {
        self.completionHandler = onComplete

        super.init(
            contentRect: displayFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false

        let overlayView = SelectionOverlayView(
            screenshot: screenshot,
            frame: CGRect(origin: .zero, size: displayFrame.size)
        ) { [weak self] rect in
            self?.complete(rect)
        }

        contentView = overlayView
    }

    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func complete(_ rect: CGRect?) {
        guard !didComplete else { return }
        didComplete = true
        completionHandler(rect)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            complete(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
