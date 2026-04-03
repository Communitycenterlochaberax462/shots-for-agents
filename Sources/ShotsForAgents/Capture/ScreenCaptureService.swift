import AppKit
import ScreenCaptureKit

@MainActor
final class ScreenCaptureService {
    private static var overlayWindow: SelectionOverlayWindow?
    private static var hasCheckedPermission = false

    /// Ensures Screen Recording permission is granted before capturing.
    /// Returns false if the user hasn't granted permission.
    private static func ensurePermission() async -> Bool {
        // SCShareableContent.current triggers the permission prompt if needed.
        // We call it once early to avoid double prompts from both
        // SCShareableContent and SCScreenshotManager.
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            hasCheckedPermission = true
            return true
        } catch {
            return false
        }
    }

    static func captureRegion() async -> Data? {
        // 1. Ensure permission (single prompt, cached after first grant)
        if !hasCheckedPermission {
            guard await ensurePermission() else { return nil }
        }

        // 2. Get available displays
        guard let content = try? await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true
        ) else {
            return nil
        }

        // Use the display under the mouse cursor, or fall back to first
        let mouseLocation = NSEvent.mouseLocation
        let display = content.displays.first { display in
            display.frame.contains(mouseLocation)
        } ?? content.displays.first

        guard let display else { return nil }

        // 3. Capture the full display (freeze frame)
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height

        guard let screenshot = try? await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        ) else {
            return nil
        }

        // 4. Show selection overlay on the frozen screenshot
        let selectedRect: CGRect? = await withCheckedContinuation { continuation in
            let window = SelectionOverlayWindow(
                screenshot: screenshot,
                displayFrame: display.frame
            ) { rect in
                continuation.resume(returning: rect)
                Self.overlayWindow?.close()
                Self.overlayWindow = nil
            }
            Self.overlayWindow = window
            window.show()
        }

        guard let rect = selectedRect, rect.width > 0, rect.height > 0 else {
            return nil
        }

        // 5. Crop to selection
        // View coordinates: origin bottom-left (AppKit)
        // CGImage coordinates: origin top-left
        let displayFrame = display.frame
        let scaleX = CGFloat(screenshot.width) / displayFrame.width
        let scaleY = CGFloat(screenshot.height) / displayFrame.height

        let cropRect = CGRect(
            x: rect.origin.x * scaleX,
            y: (displayFrame.height - rect.maxY) * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )

        guard let cropped = screenshot.cropping(to: cropRect) else { return nil }

        // 6. Convert to PNG
        let rep = NSBitmapImageRep(cgImage: cropped)
        return rep.representation(using: .png, properties: [:])
    }
}
