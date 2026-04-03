import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    var onCapture: (() -> Void)?
    var onClearBatch: (() -> Void)?
    var onSettings: (() -> Void)?
    private var batchCount = 0

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "Oneshot"
            )
        }
        rebuildMenu()
    }

    func updateBatch(count: Int) {
        batchCount = count

        if let button = statusItem.button {
            if count > 0 {
                button.title = " \(count)"
            } else {
                button.title = ""
            }
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let captureItem = NSMenuItem(
            title: "Take Screenshot",
            action: #selector(handleCapture),
            keyEquivalent: ""
        )
        captureItem.target = self
        menu.addItem(captureItem)

        if batchCount > 0 {
            let batchLabel = NSMenuItem(
                title: "\(batchCount) screenshot\(batchCount == 1 ? "" : "s") in batch — copied to clipboard",
                action: nil,
                keyEquivalent: ""
            )
            batchLabel.isEnabled = false
            menu.addItem(batchLabel)

            let clearItem = NSMenuItem(
                title: "Clear Batch",
                action: #selector(handleClearBatch),
                keyEquivalent: ""
            )
            clearItem.target = self
            menu.addItem(clearItem)
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(handleSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit Oneshot",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func handleCapture() {
        onCapture?()
    }

    @objc private func handleClearBatch() {
        onClearBatch?()
    }

    @objc private func handleSettings() {
        onSettings?()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
