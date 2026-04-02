import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private let imageStore = ImageStore()
    private var imageServer: ImageServer!
    private var settingsWindowController: SettingsWindowController!
    private var serverTask: Task<Void, any Error>?
    private var sweepTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Constants.registerDefaults()

        // Start HTTP server
        imageServer = ImageServer(store: imageStore)
        serverTask = Task.detached { [server = self.imageServer!] in
            try await server.start()
        }

        // Menu bar
        statusBarController = StatusBarController()
        statusBarController.onCapture = { [weak self] in
            self?.captureAndServe()
        }

        settingsWindowController = SettingsWindowController()
        statusBarController.onSettings = { [weak self] in
            self?.settingsWindowController.show()
        }

        // Global hotkey
        KeyboardShortcuts.onKeyUp(for: .captureScreenshot) { [weak self] in
            self?.captureAndServe()
        }

        // TTL sweep — clean expired screenshots every 30s
        sweepTask = Task { [imageStore] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await imageStore.sweepExpired()
            }
        }
    }

    private func captureAndServe() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let data = await ScreenCaptureService.captureRegion() else { return }
            let id = await imageStore.store(data)
            let filename = "shot-\(id.uuidString.prefix(8)).png"
            let url = "http://localhost:\(Constants.port)/s/\(id.uuidString).png"
            let curlCommand = "curl -s -o /tmp/\(filename) \(url)"
            ClipboardHelper.copy(curlCommand)
            statusBarController.addRecentURL(url)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        serverTask?.cancel()
        sweepTask?.cancel()
    }
}
