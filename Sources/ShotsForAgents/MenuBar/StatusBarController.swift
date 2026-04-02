import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    var onCapture: (() -> Void)?
    var onSettings: (() -> Void)?
    private var recentURLs: [String] = []

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "ShotsForAgents"
            )
        }
        rebuildMenu()
    }

    func addRecentURL(_ url: String) {
        recentURLs.insert(url, at: 0)
        if recentURLs.count > 10 {
            recentURLs.removeLast()
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

        if !recentURLs.isEmpty {
            menu.addItem(NSMenuItem.separator())

            let header = NSMenuItem(title: "Recent Screenshots", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for (index, url) in recentURLs.enumerated() {
                let displayURL = url.count > 50
                    ? "..." + url.suffix(47)
                    : url
                let item = NSMenuItem(
                    title: displayURL,
                    action: #selector(copyURL(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = index
                item.representedObject = url as NSString
                menu.addItem(item)
            }
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
            title: "Quit ShotsForAgents",
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

    @objc private func handleSettings() {
        onSettings?()
    }

    @objc private func copyURL(_ sender: NSMenuItem) {
        if let url = sender.representedObject as? String {
            ClipboardHelper.copy(url)
        }
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
