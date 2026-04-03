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

    // Batch capture state
    private var captures: [CaptureEntry] = []
    private var nextIndex = 1
    private var toastWindow: CaptureToastWindow?
    private var annotationWindow: AnnotationWindow?

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
        statusBarController.onClearBatch = { [weak self] in
            self?.clearBatch()
        }
        statusBarController.onRemoveCapture = { [weak self] id in
            self?.removeCapture(id: id)
        }
        statusBarController.onEditAnnotation = { [weak self] id in
            self?.editAnnotation(id: id)
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
        sweepTask = Task { [imageStore, weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await imageStore.sweepExpired()
                let activeIDs = await imageStore.activeIDs()
                await MainActor.run {
                    self?.syncCaptures(activeIDs: activeIDs)
                }
            }
        }
    }

    private func captureAndServe() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let rawData = await ScreenCaptureService.captureRegion() else { return }

            // Show annotation prompt at screen center
            let annotation: String? = await withCheckedContinuation { continuation in
                let screenCenter = NSEvent.mouseLocation
                let window = AnnotationWindow(anchorPoint: screenCenter) { text in
                    continuation.resume(returning: text)
                }
                self.annotationWindow = window
                window.show()
            }
            self.annotationWindow = nil

            // Burn annotation into image if provided
            let data: Data
            if let annotation, !annotation.isEmpty {
                data = ImageAnnotator.annotate(pngData: rawData, text: annotation)
            } else {
                data = rawData
            }

            let id = await imageStore.store(data)
            let filename = "shot-\(id.uuidString.prefix(8)).png"
            let url = "http://localhost:\(Constants.port)/s/\(id.uuidString).png"
            let curlCommand = "curl -s -o /tmp/\(filename) \(url)"

            // Build entry with thumbnail from raw (unannotated) image
            let thumbnail = StatusBarController.makeThumbnail(from: rawData)
            let index = nextIndex
            nextIndex += 1
            let entry = CaptureEntry(
                id: id,
                index: index,
                rawData: rawData,
                annotation: annotation,
                thumbnail: thumbnail,
                curl: curlCommand
            )
            captures.append(entry)

            copyBatchToClipboard()
            statusBarController.updateCaptures(captures)
            showCaptureToast()
        }
    }

    private func removeCapture(id: UUID) {
        captures.removeAll { $0.id == id }
        Task { await imageStore.remove(id) }

        if captures.isEmpty {
            clearBatch()
        } else {
            copyBatchToClipboard()
            statusBarController.updateCaptures(captures)
        }
    }

    private func editAnnotation(id: UUID) {
        guard let idx = captures.firstIndex(where: { $0.id == id }) else { return }
        let entry = captures[idx]

        Task { @MainActor [weak self] in
            guard let self else { return }

            let newAnnotation: String? = await withCheckedContinuation { continuation in
                let screenCenter = NSPoint(
                    x: NSScreen.main?.frame.midX ?? 500,
                    y: NSScreen.main?.frame.midY ?? 400
                )
                let window = AnnotationWindow(
                    anchorPoint: screenCenter,
                    initialText: entry.annotation
                ) { text in
                    continuation.resume(returning: text)
                }
                self.annotationWindow = window
                window.show()
            }
            self.annotationWindow = nil

            // Re-burn annotation onto the raw image
            let newData: Data
            if let newAnnotation, !newAnnotation.isEmpty {
                newData = ImageAnnotator.annotate(pngData: entry.rawData, text: newAnnotation)
            } else {
                newData = entry.rawData
            }

            // Update store and local entry
            await self.imageStore.replace(id, data: newData)
            if let idx = self.captures.firstIndex(where: { $0.id == id }) {
                self.captures[idx].annotation = newAnnotation
            }
            self.copyBatchToClipboard()
            self.statusBarController.updateCaptures(self.captures)
        }
    }

    /// Remove local entries that the store has swept (read by AI or expired)
    private func syncCaptures(activeIDs: Set<UUID>) {
        let before = captures.count
        captures.removeAll { !activeIDs.contains($0.id) }
        if captures.count != before {
            if captures.isEmpty {
                clearBatch()
            } else {
                copyBatchToClipboard()
                statusBarController.updateCaptures(captures)
            }
        }
    }

    private func copyBatchToClipboard() {
        if captures.count == 1 {
            ClipboardHelper.copy(captures[0].curl)
        } else {
            var table = "| Screenshot | Fetch |\n"
            table += "|------------|-------|\n"
            for entry in captures {
                table += "| shot-\(entry.index) | `\(entry.curl)` |\n"
            }
            ClipboardHelper.copy(table)
        }
    }

    private func showCaptureToast() {
        toastWindow?.dismiss()
        let toast = CaptureToastWindow(shotCount: captures.count) { [weak self] in
            self?.captureAndServe()
        }
        toastWindow = toast
        toast.show()
    }

    private func clearBatch() {
        captures.removeAll()
        nextIndex = 1
        statusBarController.updateCaptures([])
    }

    func applicationWillTerminate(_ notification: Notification) {
        serverTask?.cancel()
        sweepTask?.cancel()
    }
}
