import AppKit

@MainActor
final class SelectionOverlayWindow: NSWindow {
    private let completionHandler: (CGRect?) -> Void
    private var didComplete = false
    nonisolated(unsafe) private var globalEscMonitor: Any?

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
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)

        // Global monitor catches ESC even when the window isn't key (e.g. launched from Xcode)
        globalEscMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                DispatchQueue.main.async { self?.complete(nil) }
            }
        }
    }

    func complete(_ rect: CGRect?) {
        guard !didComplete else { return }
        didComplete = true
        if let monitor = globalEscMonitor {
            NSEvent.removeMonitor(monitor)
            globalEscMonitor = nil
        }
        (contentView as? SelectionOverlayView)?.removeKeyMonitors()
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
